import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../profiles.dart';
import '../sora.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

/// Generates a collision-resistant local id for profiles and chains.
String newLocalId(String prefix) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';

/// Network profiles: triggers plus a settings snapshot applied when the
/// network is joined.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await SoraScope.read(context).refreshFingerprint();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _fingerprintLine(S s, NetworkFingerprint fingerprint) {
    if (!fingerprint.known) return s.networkUnknown;
    final parts = <String>[
      if (fingerprint.ssid != null && fingerprint.ssid!.isNotEmpty) 'SSID ${fingerprint.ssid}',
      if (fingerprint.gateway != null && fingerprint.gateway!.isNotEmpty) fingerprint.gateway!,
      if (fingerprint.asn != null && fingerprint.asn!.isNotEmpty) 'AS${fingerprint.asn}',
    ];
    return s.networkNow(parts.join(' · '));
  }

  String _triggerSummary(NetworkProfile profile) {
    final parts = <String>[...profile.ssids, ...profile.gateways, ...profile.asns.map((a) => 'AS$a')];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final profiles = sora.profiles.profiles;
    return Screen(
      title: s.profiles,
      actions: [
        RoundButton(
          icon: Symbols.add_rounded,
          label: s.profileAdd,
          onTap: () => push<void>(context, const ProfileEditorScreen()),
        ),
      ],
      children: [
        Group(
          children: [
            Tile(
              title: _fingerprintLine(s, sora.networkFingerprint),
              trailing: _refreshing
                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : RoundButton(icon: Symbols.refresh_rounded, label: s.refresh, onTap: _refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (profiles.isEmpty)
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Symbols.wifi_rounded, size: 40, weight: 400, color: palette.ink3),
                    const SizedBox(height: 12),
                    Text(
                      s.profilesEmpty,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          for (final profile in profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Group(
                children: [
                  Tile(
                    title: profile.name.isEmpty ? s.profileAdd : profile.name,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sora.profiles.activeId == profile.id)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(12)),
                            child: Text(s.profileActive, style: Styles.secondary.copyWith(color: palette.ink)),
                          ),
                        RoundButton(
                          icon: Symbols.delete_rounded,
                          label: s.profileDelete,
                          onTap: () => unawaited(_delete(context, profile)),
                        ),
                      ],
                    ),
                    onTap: () => push<void>(context, ProfileEditorScreen(profile: profile)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(_triggerSummary(profile), style: Styles.secondary.copyWith(color: palette.ink2)),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, NetworkProfile profile) async {
    final s = S.of(context);
    if (!await confirm(context, question: s.profileDeleteConfirm(profile.name), action: s.profileDelete)) {
      return;
    }
    if (context.mounted) SoraScope.read(context).profiles.remove(profile.id);
  }
}

/// Creates or edits a network profile.
class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, this.profile});

  final NetworkProfile? profile;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late NetworkProfile _draft;

  @override
  void initState() {
    super.initState();
    final existing = widget.profile;
    _draft = existing == null
        ? NetworkProfile(id: newLocalId('p'), name: '')
        : NetworkProfile.fromJson(existing.toJson());
  }

  List<String> _split(String raw) => [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  /// One-line summary of the captured settings snapshot.
  String _snapshotSummary() {
    final engine = _draft.engine;
    final parts = <String>[
      if (_draft.tunnel != null) _draft.tunnel!,
      if (_draft.preset != null) _draft.preset!,
      if (engine != null && engine.isNotEmpty) engine,
    ];
    return parts.join(' · ');
  }

  Future<void> _editList({
    required String title,
    required String hint,
    required List<String> initial,
    required void Function(List<String>) apply,
  }) async {
    final s = S.of(context);
    await showFieldSheet(
      context,
      title: title,
      hint: hint,
      action: s.save,
      initial: initial.join(', '),
      allowEmpty: true,
      submit: (value) async {
        setState(() => apply(_split(value)));
        return null;
      },
    );
  }

  Future<void> _editName() async {
    final s = S.of(context);
    await showFieldSheet(
      context,
      title: s.profileName,
      hint: s.profileName,
      action: s.save,
      initial: _draft.name,
      submit: (value) async {
        if (value.trim().isEmpty) return s.profileName;
        setState(() => _draft.name = value.trim());
        return null;
      },
    );
  }

  void _snapshot() {
    final sora = SoraScope.read(context);
    final settings = sora.settings;
    setState(() {
      _draft.tunnel = settings.tunnel;
      _draft.preset = settings.preset;
      _draft.dns = List.of(settings.dns);
      _draft.dnsPreset = settings.dnsPreset;
      _draft.engine = settings.engine;
      _draft.serverId = settings.server;
    });
    final s = S.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.profileSnapshotDone)));
  }

  void _save() {
    final sora = SoraScope.read(context);
    final s = S.of(context);
    if (_draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.profileName)));
      return;
    }
    if (!_draft.hasTriggers) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.profileNoTriggers)));
      return;
    }
    if (widget.profile == null) {
      sora.profiles.add(_draft);
    } else {
      sora.profiles.update(_draft);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Screen(
      title: widget.profile == null ? s.profileAdd : s.profileName,
      actions: [RoundButton(icon: Symbols.check_rounded, label: s.save, onTap: _save)],
      children: [
        Group(
          children: [
            LinkTile(title: s.profileName, value: _draft.name.isEmpty ? null : _draft.name, onTap: _editName),
            LinkTile(
              title: s.profileSsids,
              value: _draft.ssids.isEmpty ? null : _draft.ssids.join(', '),
              onTap: () => _editList(
                title: s.profileSsids,
                hint: s.profileSsidsHint,
                initial: _draft.ssids,
                apply: (v) => _draft.ssids = v,
              ),
            ),
            LinkTile(
              title: s.profileGateways,
              value: _draft.gateways.isEmpty ? null : _draft.gateways.join(', '),
              onTap: () => _editList(
                title: s.profileGateways,
                hint: s.profileGateways,
                initial: _draft.gateways,
                apply: (v) => _draft.gateways = v,
              ),
            ),
            LinkTile(
              title: s.profileAsns,
              value: _draft.asns.isEmpty ? null : _draft.asns.join(', '),
              onTap: () => _editList(
                title: s.profileAsns,
                hint: s.profileAsns,
                initial: _draft.asns,
                apply: (v) => _draft.asns = v,
              ),
            ),
            SwitchTile(
              title: s.profileAutoApply,
              info: s.profileAutoApplyHint,
              value: _draft.autoApply,
              onChanged: (v) => setState(() => _draft.autoApply = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Group(
          children: [
            LinkTile(title: s.profileSnapshot, onTap: _snapshot),
            if (_draft.tunnel != null) Tile(title: _snapshotSummary()),
          ],
        ),
      ],
    );
  }
}
