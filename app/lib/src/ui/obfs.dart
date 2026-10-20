import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart' show CoreFailure;
import '../design/theme.dart';
import '../obfs.dart';
import '../sora.dart';
import 'kit.dart';
import 'modes.dart' show ConnectionChanges;

/// Localized name of an obfuscation preset id. Shared with the settings
/// entry tile.
String obfsPresetLabel(S s, String preset) => switch (preset) {
      obfsPresetAggressive => s.obfsPresetAggressive,
      obfsPresetBalanced => s.obfsPresetBalanced,
      obfsPresetLight => s.obfsPresetLight,
      obfsPresetOff => s.obfsPresetOff,
      _ => s.obfsPresetCustom,
    };

/// Traffic obfuscation: presets, manual uTLS/fragmentation/jitter controls
/// and the honest per-engine capability report from GetObfsCapabilities.
///
/// Edits persist immediately and are pushed to the core via
/// ApplyObfsProfile; while connected the reconnect banner takes over. When
/// the core has no ObfsControl service yet, settings stay local and the
/// capability section reads "detecting".
class ObfsScreen extends StatefulWidget {
  const ObfsScreen({super.key});

  @override
  State<ObfsScreen> createState() => _ObfsScreenState();
}

class _ObfsScreenState extends State<ObfsScreen> {
  bool _loading = false;
  bool _applying = false;

  /// Null until the capabilities are known: no link, an older core, or a
  /// core without the ObfsControl service.
  List<EngineObfsCapabilities>? _engines;
  CoreFailure? _capsFailure;
  CoreFailure? _applyFailure;
  ObfsApplyResult? _lastApply;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _capsFailure = null;
    });
    final sora = SoraScope.read(context);
    final result = await sora.getObfsCapabilities();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _engines = result.engines;
      _capsFailure = result.failure;
    });
  }

  Future<void> _update({String? preset, String? utls, bool? fragment, bool? jitter, bool? muxDisabled}) async {
    if (_applying) return;
    setState(() {
      _applying = true;
      _applyFailure = null;
      _lastApply = null;
    });
    final sora = SoraScope.read(context);
    try {
      final result = await sora.updateObfs(
          preset: preset, utls: utls, fragment: fragment, jitter: jitter, muxDisabled: muxDisabled);
      if (!mounted) return;
      setState(() => _lastApply = result);
    } on CoreFailure catch (failure) {
      if (!mounted) return;
      setState(() => _applyFailure = failure);
    } catch (error) {
      if (!mounted) return;
      setState(() => _applyFailure = CoreFailure.from(error));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  /// Whether the feature is usable. Unknown capabilities (no RPC yet) allow
  /// the setting: the core validates the profile on apply. A pinned engine
  /// scopes the check to that engine; auto requires any engine.
  bool _featureAvailable(Sora sora, bool Function(EngineObfsCapabilities) test) {
    final engines = _engines;
    if (engines == null || engines.isEmpty) return true;
    final pinned = sora.settings.engine;
    final scoped = pinned.isEmpty ? engines : engines.where((e) => e.engine == pinned);
    return (scoped.isEmpty ? engines : scoped).any(test);
  }

  /// uTLS profile ids offered in the manual choice, intersected with what
  /// the engines advertise when known.
  List<String> _utlsChoices() {
    final engines = _engines;
    if (engines == null || engines.isEmpty) return [obfsUtlsAuto, ...obfsUtlsProfiles];
    final offered = <String>{};
    for (final e in engines) {
      if (e.utls) offered.addAll(e.utlsProfiles);
    }
    final names =
        offered.isEmpty ? obfsUtlsProfiles : [for (final p in obfsUtlsProfiles) if (offered.contains(p)) p];
    return [obfsUtlsAuto, ...names];
  }

  /// A neutral note: info, not an error. Failures are localized through
  /// [describe] and never shown raw or in red.
  Widget _note(BuildContext context, IconData icon, String text) {
    final palette = Palette.of(context);
    return Group(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: palette.ink2),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Styles.secondary.copyWith(color: palette.ink2))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capRow(BuildContext context, String title, bool supported, String? detail) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Tile(
      title: title,
      detail: detail,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (supported) ...[
            Icon(Symbols.check_rounded, size: 18, color: palette.ink2),
            const SizedBox(width: 6),
          ],
          Text(
            supported ? s.obfsSupported : s.obfsUnsupported,
            style: Styles.secondary.copyWith(color: supported ? palette.ink2 : palette.ink3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final obfs = sora.obfs;
    final utlsSupported = _featureAvailable(sora, (e) => e.utls);
    final fragmentSupported = _featureAvailable(sora, (e) => e.fragmentation);
    final jitterSupported = _featureAvailable(sora, (e) => e.jitter);
    final lastApply = _lastApply;
    return Screen(
      title: s.obfs,
      children: [
        if (sora.needsReconnect) ...[const ConnectionChanges(), const SizedBox(height: 16)],
        if (_applyFailure != null) _note(context, Symbols.info_rounded, describe(s, _applyFailure!)),
        Group(
          children: [
            ChoiceTile<String>(
              title: s.obfsPreset,
              value: obfs.preset,
              choices: {
                obfsPresetAggressive: s.obfsPresetAggressive,
                obfsPresetBalanced: s.obfsPresetBalanced,
                obfsPresetLight: s.obfsPresetLight,
                obfsPresetOff: s.obfsPresetOff,
                obfsPresetCustom: s.obfsPresetCustom,
              },
              onChanged: (v) {
                if (!_applying) unawaited(_update(preset: v));
              },
            ),
          ],
        ),
        Heading(s.obfsManual),
        Group(
          children: [
            if (utlsSupported)
              ChoiceTile<String>(
                title: s.obfsUtls,
                value: obfs.utls,
                choices: {for (final p in _utlsChoices()) p: p.isEmpty ? s.obfsUtlsAuto : p},
                onChanged: (v) {
                  if (!_applying) unawaited(_update(utls: v));
                },
              )
            else
              Tile(title: s.obfsUtls, detail: s.obfsUnsupported),
            if (fragmentSupported)
              SwitchTile(
                title: s.fragment,
                value: obfs.fragment,
                onChanged: _applying ? null : (v) => unawaited(_update(fragment: v)),
              )
            else
              Tile(title: s.fragment, detail: s.obfsUnsupported),
            if (jitterSupported)
              SwitchTile(
                title: s.obfsJitter,
                value: obfs.jitter,
                onChanged: obfs.fragment && !_applying ? (v) => unawaited(_update(jitter: v)) : null,
              )
            else
              Tile(title: s.obfsJitter, detail: s.obfsUnsupported),
            // Mux is a plan-level policy every engine renderer honors via
            // the shared RealityMux gate, so no capability row gates it.
            SwitchTile(
              title: s.obfsMux,
              detail: s.obfsMuxDetail,
              value: !obfs.muxDisabled,
              onChanged: _applying ? null : (v) => unawaited(_update(muxDisabled: !v)),
            ),
          ],
        ),
        if (!obfs.fragment && jitterSupported) _note(context, Symbols.info_rounded, s.obfsJitterNeedsFragment),
        if (lastApply != null &&
            (lastApply.warnings.isNotEmpty || lastApply.compatibleEngines.isNotEmpty))
          _note(
            context,
            Symbols.info_rounded,
            [
              if (lastApply.compatibleEngines.isNotEmpty)
                s.obfsCompatibleEngines(lastApply.compatibleEngines.join(', ')),
              ...lastApply.warnings,
            ].join('\n'),
          ),
        Heading(s.obfsCapabilities),
        if (_loading)
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CupertinoActivityIndicator(color: palette.ink),
                    const SizedBox(height: 12),
                    Text(s.obfsDetecting, style: Styles.secondary.copyWith(color: palette.ink2)),
                  ],
                ),
              ),
            ],
          )
        else if (_capsFailure != null) ...[
          _note(context, Symbols.info_rounded, describe(s, _capsFailure!)),
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: PrimaryButton(
                  label: s.refresh,
                  busy: _loading,
                  onTap: _loading ? null : () => unawaited(_load()),
                ),
              ),
            ],
          ),
        ] else if (_engines == null || _engines!.isEmpty)
          _note(context, Symbols.info_rounded, s.obfsUnknown)
        else
          for (final e in _engines!)
            Group(
              children: [
                Tile(title: e.engine, titleStyle: Styles.bodyStrong),
                _capRow(context, s.obfsUtls, e.utls,
                    e.utlsProfiles.isEmpty ? null : e.utlsProfiles.join(', ')),
                _capRow(context, s.fragment, e.fragmentation,
                    e.fragmentParams ? s.obfsFineTune : null),
                _capRow(context, s.obfsJitter, e.jitter, null),
              ],
            ),
      ],
    );
  }
}
