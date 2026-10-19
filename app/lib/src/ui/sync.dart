import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import '../sync.dart';
import 'kit.dart';
import 'qr.dart';
import 'subscription_sheet.dart';

/// End-to-end encrypted device sync without cloud (FEATURE-PLAN.md F9).
///
/// Pairing reuses the F1 QR flow: this device shows a code carrying a
/// rendezvous token, the other side scans it. Discovery and the Noise_XX
/// channel live in the Go sync service (`core/sync/sync.go`, a separate
/// service — not a control RPC); the UI below is complete and honest about
/// what is synced and what never is.
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
          final parsed = SyncPairing.decodePairPayload(raw);
          if (parsed == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(s.qrInvalid)));
            return;
          }
          unawaited(_nameAndAdd(parsed.token));
        },
      ),
    );
  }

  /// Names a freshly scanned device before adding it to the registry.
  Future<void> _nameAndAdd(String token) async {
    final sora = SoraScope.read(context);
    final s = S.of(context);
    final short = token.substring(0, token.length < 6 ? token.length : 6);
    // The registry ignores duplicates; only claim "paired" when the device
    // was actually added, not when the token was scanned before.
    var added = false;
    await showFieldSheet(
      context,
      title: s.syncPair,
      hint: s.syncPair,
      action: s.save,
      initial: short,
      submit: (value) async {
        if (value.trim().isEmpty) return s.syncPair;
        added = !sora.syncDevices.devices.any((d) => d.id == token);
        sora.syncDevices.add(SyncedDevice(id: token, name: value.trim()));
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
            LinkTile(
              title: s.syncShowCode,
              onTap: () => push<void>(context, const SyncShowCodeScreen()),
            ),
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

/// Shows this device's pairing code and waits for the other side (F9).
class SyncShowCodeScreen extends StatefulWidget {
  const SyncShowCodeScreen({super.key});

  @override
  State<SyncShowCodeScreen> createState() => _SyncShowCodeScreenState();
}

class _SyncShowCodeScreenState extends State<SyncShowCodeScreen> {
  late final String _token;

  @override
  void initState() {
    super.initState();
    // One token per shown code; rescanning a stale screenshot pairs nothing.
    _token = SyncPairing.newToken();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final payload = SyncPairing.encodePairPayload(token: _token);
    return Screen(
      title: s.syncPairingTitle,
      children: [
        const SizedBox(height: 8),
        Center(
          child: DecoratedBox(
            // White quiet zone keeps the code scannable in both themes.
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              // A QR code carries no meaning for screen readers; the token
              // is intentionally not exposed as text (a screenshot must not
              // be pairable), so the image is hidden from the semantics tree.
              child: ExcludeSemantics(
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  size: 260,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.syncWaiting, style: Styles.secondary.copyWith(color: palette.ink2)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(s.syncSecureNote, style: Styles.secondary.copyWith(color: palette.ink2, height: 1.5)),
            ),
          ],
        ),
      ],
    );
  }
}
