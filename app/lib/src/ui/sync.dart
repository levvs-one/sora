import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import '../sync.dart';
import 'kit.dart';
import 'qr.dart';
import 'subscription_sheet.dart';

/// End-to-end encrypted device sync without cloud (FEATURE-PLAN.md F9).
///
/// Pairing reuses the F1 QR flow: the inviting device's sync service mints
/// the invitation QR (`sora-sync://pair?...`, see [SyncPairing]), this side
/// scans it and decodes it with the same rules as the Go service, so a code
/// the app accepts is a code the service accepts too.
/// Status (2026-10-19): the service is not launched or wired to the app yet,
/// so this screen is a local device registry — no pairing handshake or
/// document sync happens here, and there is no "show my code" until the
/// service mints real invitations. The "what syncs" section below describes
/// the design target, not current behavior.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  Future<void> _scan() async {
    final s = S.of(context);
    await push<void>(
      context,
      QrScanScreen(
        onScanned: (raw) {
          // Strict decode: only a real service invitation registers a
          // device. Anything else is not a pairing code.
          final parsed = SyncPairing.decodePairPayload(raw);
          if (parsed == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(s.qrInvalid)));
            return;
          }
          unawaited(_nameAndAdd(parsed.deviceId));
        },
      ),
    );
  }

  /// Names a freshly scanned device before adding it to the registry.
  Future<void> _nameAndAdd(String deviceId) async {
    final sora = SoraScope.read(context);
    final s = S.of(context);
    final short = deviceId.substring(0, deviceId.length < 6 ? deviceId.length : 6);
    // The registry ignores duplicates; only claim "paired" when the device
    // was actually added, not when the code was scanned before.
    var added = false;
    await showFieldSheet(
      context,
      title: s.syncPair,
      hint: s.syncPair,
      action: s.save,
      initial: short,
      submit: (value) async {
        if (value.trim().isEmpty) return s.syncPair;
        added = !sora.syncDevices.devices.any((d) => d.id == deviceId);
        sora.syncDevices.add(SyncedDevice(id: deviceId, name: value.trim()));
        return null;
      },
    );
    if (mounted && added) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.of(context).syncPaired)));
    }
  }

  Future<void> _revoke(BuildContext context, SyncedDevice device) async {
    final s = S.of(context);
    if (!await confirm(
      context,
      question: s.syncRevokeConfirm(device.name),
      action: s.syncRevoke,
    )) {
      return;
    }
    if (context.mounted) SoraScope.read(context).syncDevices.revoke(device.id);
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final devices = sora.syncDevices.devices;
    return Screen(
      title: s.sync,
      children: [
        Heading(s.syncDevices),
        if (devices.isEmpty)
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Symbols.devices_rounded, size: 40, weight: 400, color: palette.ink3),
                    const SizedBox(height: 12),
                    Text(
                      s.syncEmpty,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Group(
            children: [
              for (final device in devices)
                Tile(
                  title: device.name,
                  detail: device.lastSync == null
                      ? s.syncNever
                      : s.syncLastSync(
                          DateFormat.yMMMd(locale).add_Hm().format(device.lastSync!.toLocal()),
                        ),
                  trailing: RoundButton(
                    icon: Symbols.link_off_rounded,
                    label: s.syncRevoke,
                    onTap: () => unawaited(_revoke(context, device)),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Heading(s.syncPair),
        Group(
          children: [
            // "Show my code" lives here once the sync service mints real
            // invitations; until then the app shows no pairing QR because a
            // code it cannot back with a handshake would be a lie.
            LinkTile(title: s.syncScanCode, onTap: _scan),
          ],
        ),
        const SizedBox(height: 16),
        Heading(s.syncWhat),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.syncWhatBody, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(s.syncNoLan, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(s.syncSecureNote, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
