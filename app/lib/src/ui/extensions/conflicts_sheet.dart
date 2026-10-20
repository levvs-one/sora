/// Conflict resolution sheet: when two enabled extensions are granted the
/// same exclusive permission (routing rules, theme, network hooks), the
/// user picks the winner instead of suffering a quiet last-write-wins.
///
/// The choice is persisted per conflict key ([ExtConflict.key]) so it
/// survives reinstalls of the same contender set. It is the user's declared
/// intent: the engine will apply the stored winner once it gains support
/// for these capabilities; until then nothing is applied silently — the
/// install prompt and the conflict texts say so explicitly.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../kit.dart';
import '../../ext/conflicts.dart';
import '../../ext/store.dart';

/// Shows the resolution sheet. Returns true when the user saved decisions.
Future<bool> showConflictsSheet(
  BuildContext context, {
  required List<ExtConflict> conflicts,
  required ExtensionStore store,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ConflictsSheet(conflicts: conflicts, store: store),
  );
  return saved == true;
}

String _kindLabel(BuildContext context, ExtConflictKind kind) {
  final s = S.of(context);
  return switch (kind) {
    ExtConflictKind.routingRules => s.extConflictRoutingRules,
    ExtConflictKind.themeApply => s.extConflictTheme,
    ExtConflictKind.netHooks => s.extConflictNetHooks,
  };
}

class _ConflictsSheet extends StatefulWidget {
  const _ConflictsSheet({required this.conflicts, required this.store});
  final List<ExtConflict> conflicts;
  final ExtensionStore store;

  @override
  State<_ConflictsSheet> createState() => _ConflictsSheetState();
}

class _ConflictsSheetState extends State<_ConflictsSheet> {
  final _winners = <String, String>{};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in widget.conflicts) {
      final current = widget.store.conflictWinnerSync(c.key);
      if (current != null && c.extensionIds.contains(current)) {
        _winners[c.key] = current;
      }
    }
  }

  bool get _complete =>
      widget.conflicts.every((c) => _winners.containsKey(c.key));

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (final c in widget.conflicts) {
        await widget.store.setConflictWinner(c.key, _winners[c.key]!);
      }
    } catch (_) {
      // The store already rolled the in-memory write back; say the choice
      // was not saved instead of closing the sheet in silence.
      if (mounted) {
        setState(() {
          _saving = false;
          _error = S.of(context).extErrGeneric;
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Dialog(
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Symbols.warning_rounded, color: palette.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.extConflictsTitle,
                        style: Styles.title.copyWith(color: palette.ink)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(s.extConflictsIntro,
                  style: Styles.body.copyWith(color: palette.ink2)),
              const SizedBox(height: 16),
              for (final c in widget.conflicts) ...[
                _ConflictBlock(
                  conflict: c,
                  store: widget.store,
                  winner: _winners[c.key],
                  onPick: (id) => setState(() => _winners[c.key] = id),
                ),
                const SizedBox(height: 12),
              ],
              Text(s.extConflictNote,
                  style: Styles.caption.copyWith(color: palette.ink3)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: Styles.body.copyWith(color: palette.danger)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: s.extConfirm,
                busy: _saving,
                onTap: _complete && !_saving ? _save : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: Text(s.extCancel, style: TextStyle(color: palette.ink2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictBlock extends StatelessWidget {
  const _ConflictBlock({
    required this.conflict,
    required this.store,
    required this.winner,
    required this.onPick,
  });
  final ExtConflict conflict;
  final ExtensionStore store;
  final String? winner;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.field),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_kindLabel(context, conflict.kind),
              style: Styles.bodyStrong.copyWith(color: palette.ink)),
          const SizedBox(height: 8),
          for (final id in conflict.extensionIds)
            _ContenderRow(
              name: store.get(id)?.manifest.name ?? id,
              detail: _detail(context, id),
              selected: winner == id,
              onTap: () => onPick(id),
            ),
        ],
      ),
    );
  }

  String _detail(BuildContext context, String id) {
    final inst = store.get(id);
    if (inst == null) return id;
    return '${S.of(context).extVersionLabel(inst.version)} · ${inst.manifest.author.name}';
  }
}

class _ContenderRow extends StatelessWidget {
  const _ContenderRow({
    required this.name,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Semantics(
      button: true,
      checked: selected,
      label: s.extConflictWinner(name),
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Symbols.radio_button_checked_rounded
                    : Symbols.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? palette.ink : palette.ink3,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Styles.body.copyWith(color: palette.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(detail,
                        style: Styles.caption.copyWith(color: palette.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
