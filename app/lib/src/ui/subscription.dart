import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart' as pb;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../sora.dart';
import 'kit.dart';
import 'rules_screen.dart';
import 'servers.dart';
import 'subscription_sheet.dart';
import 'announcement.dart';

/// Lists subscriptions with links to their settings.
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.subscriptions,
      children: [
        Group(
          children: [
            for (final state in sora.subscriptions)
              LinkTile(
                title: state.displayName,
                onTap: () => push<void>(context, SubscriptionScreen(id: state.settings.id)),
              ),
            Tile(
              title: s.addSubscription,
              onTap: () => showSubscriptionSheet(context),
              trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
            ),
          ],
        ),
      ],
    );
  }
}

/// Edits one subscription without retaining its bearer link in screen state.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.id});

  final String id;

  /// Available update intervals in hours; zero uses the provider interval.
  static const _intervals = [0, 1, 3, 6, 12, 24];

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final state = sora.subscriptions.where((x) => x.settings.id == id).firstOrNull;
    if (state == null) {
      return Screen(title: s.subscriptions, children: const []);
    }
    final chosen = state.settings;
    Future<String?> save(void Function(SubscriptionSettings) apply) async {
      final next = chosen.deepCopy();
      apply(next);
      final failure = await sora.saveSubscription(next);
      return failure == null ? null : '';
    }

    final hours = chosen.hasUpdateInterval() ? chosen.updateInterval.seconds.toInt() ~/ 3600 : 0;
    return Screen(
      title: state.displayName,
      children: [
        Group(
          children: [
            LinkTile(
              title: s.name,
              value: chosen.name.isEmpty ? state.displayName : chosen.name,
              onTap: () => showFieldSheet(
                context,
                title: s.name,
                hint: state.displayName,
                action: s.save,
                initial: chosen.name,
                allowEmpty: true,
                submit: (v) => save((x) => x.name = v),
              ),
            ),
            LinkTile(
              title: s.userAgent,
              value: chosen.userAgent.isEmpty ? s.byDefault : chosen.userAgent,
              onTap: () => showFieldSheet(
                context,
                title: s.userAgent,
                hint: s.byDefault,
                action: s.save,
                initial: chosen.userAgent,
                allowEmpty: true,
                submit: (v) => save((x) => x.userAgent = v),
              ),
            ),
            SwitchTile(
              title: s.autoUpdate,
              value: chosen.autoUpdate,
              onChanged: (v) => unawaited(save((x) => x.autoUpdate = v)),
            ),
            if (chosen.autoUpdate)
              ChoiceTile<int>(
                title: s.updateInterval,
                value: _intervals.contains(hours) ? hours : 0,
                choices: {for (final h in _intervals) h: h == 0 ? s.intervalProvider : s.hours(h)},
                onChanged: (h) => unawaited(
                  save((x) {
                    if (h == 0) {
                      x.clearUpdateInterval();
                    } else {
                      x.updateInterval = pb.Duration(seconds: Int64(h * 3600));
                    }
                  }),
                ),
              ),
          ],
        ),
        if (state.info.announce.trim().isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), child: Announcement(state.info.announce.trim())),
        Group(
          children: [
            LinkTile(title: s.website, onTap: () => unawaited(sora.openSubscriptionPage(id))),
            if (state.info.webPageUrl.isNotEmpty)
              LinkTile(
                title: s.providerWebsite,
                value: Uri.tryParse(state.info.webPageUrl)?.host,
                onTap: () => openLink(context, state.info.webPageUrl),
              ),
            if (state.info.supportUrl.isNotEmpty)
              LinkTile(title: s.support, onTap: () => openLink(context, state.info.supportUrl)),
          ],
        ),
        _OverrideSection(subscriptionId: id),
        Group(
          children: [
            Tile(
              title: s.updateNow,
              onTap: state.updating ? null : () => unawaited(sora.refreshSubscription(id)),
              trailing: state.updating ? CupertinoActivityIndicator(color: palette.ink) : null,
            ),
            Tile(
              title: s.delete,
              titleColor: palette.danger,
              onTap: () async {
                await deleteSubscription(context, state);
                if (context.mounted && !sora.subscriptions.any((x) => x.settings.id == id)) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// "My edits" — user overrides layered over a subscription (FEATURE-PLAN.md F6).
///
/// Edits are stored locally (settings) until the core implements override
/// RPCs, and survive subscription refreshes: they key off server IDs, not
/// list positions.
class _OverrideSection extends StatelessWidget {
  const _OverrideSection({required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final state = sora.subscriptions.where((x) => x.settings.id == subscriptionId).firstOrNull;
    if (state == null) return const SizedBox.shrink();
    final override = sora.overrides.of(subscriptionId);
    final names = {for (final o in state.outbounds) o.id: o.displayName};
    final edited = {...override.renames.keys, ...override.hidden}.where(names.containsKey).toList()
      ..sort((a, b) => names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Heading(s.overrideTitle),
        Group(
          children: [
            if (edited.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(s.overrideEmpty, style: Styles.secondary.copyWith(color: palette.ink2)),
              )
            else
              for (final serverId in edited)
                _OverrideRow(subscriptionId: subscriptionId, serverId: serverId, name: names[serverId]!),
            Tile(
              title: s.overrideEdit,
              trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
              onTap: () => _pickServer(context, subscriptionId),
            ),
            LinkTile(
              title: s.overrideCustomRules,
              onTap: () => push<void>(context, const RulesScreen()),
            ),
            if (!override.isEmpty)
              Tile(
                title: s.overrideClear,
                titleColor: palette.danger,
                onTap: () async {
                  if (await confirm(context, question: s.overrideClear, action: s.overrideClear)) {
                    sora.overrides.drop(subscriptionId);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _OverrideRow extends StatelessWidget {
  const _OverrideRow({required this.subscriptionId, required this.serverId, required this.name});

  final String subscriptionId;
  final String serverId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final override = sora.overrides.of(subscriptionId);
    final rename = override.renames[serverId];
    final hidden = override.hidden.contains(serverId);
    return Tile(
      title: rename ?? name,
      detail: rename != null ? name : (hidden ? s.overrideHide : null),
      titleColor: hidden && rename == null ? palette.ink3 : null,
      onTap: () => _renameServer(context, sora, subscriptionId, serverId, name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: hidden ? s.overrideUnhide : s.overrideHide,
            child: Pressable(
              onTap: () {
                final next = Set<String>.of(override.hidden);
                if (hidden) {
                  next.remove(serverId);
                } else {
                  next.add(serverId);
                }
                sora.overrides.put(subscriptionId, override.copyWith(hidden: next));
              },
              radius: 8,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  hidden ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
                  size: 18,
                  color: palette.ink2,
                ),
              ),
            ),
          ),
          if (rename != null)
            Pressable(
              onTap: () {
                final next = Map<String, String>.of(override.renames)..remove(serverId);
                sora.overrides.put(subscriptionId, override.copyWith(renames: next));
              },
              radius: 8,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Symbols.close_rounded, size: 18, color: palette.ink2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the rename sheet for [serverId]; an empty value removes the rename.
Future<void> _renameServer(BuildContext context, Sora sora, String subscriptionId, String serverId, String name) {
  final s = S.of(context);
  final override = sora.overrides.of(subscriptionId);
  return showFieldSheet(
    context,
    title: s.rename,
    hint: name,
    action: s.save,
    initial: override.renames[serverId] ?? '',
    allowEmpty: true,
    submit: (value) async {
      final trimmed = value.trim();
      final next = Map<String, String>.of(override.renames);
      if (trimmed.isEmpty) {
        next.remove(serverId);
      } else {
        next[serverId] = trimmed;
      }
      sora.overrides.put(subscriptionId, override.copyWith(renames: next));
      return null;
    },
  );
}

/// Server picker for adding an override: tap to rename, eye icon to hide.
Future<void> _pickServer(BuildContext context, String subscriptionId) {
  return showDialog<void>(context: context, builder: (_) => _ServerPicker(subscriptionId: subscriptionId));
}

class _ServerPicker extends StatefulWidget {
  const _ServerPicker({required this.subscriptionId});

  final String subscriptionId;

  @override
  State<_ServerPicker> createState() => _ServerPickerState();
}

class _ServerPickerState extends State<_ServerPicker> {
  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final state = sora.subscriptions.where((x) => x.settings.id == widget.subscriptionId).firstOrNull;
    final servers = state == null ? const <OutboundSpec>[] : state.outbounds;
    final override = sora.overrides.of(widget.subscriptionId);
    return Dialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(s.overrideEdit, style: Styles.bodyStrong.copyWith(color: palette.ink)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: servers.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, thickness: 1, indent: 12, endIndent: 12, color: palette.field),
                  itemBuilder: (_, index) {
                    final server = servers[index];
                    final hidden = override.hidden.contains(server.id);
                    final rename = override.renames[server.id];
                    return Tile(
                      title: rename ?? server.displayName,
                      detail: rename != null ? server.displayName : (hidden ? s.overrideHide : null),
                      titleColor: hidden && rename == null ? palette.ink3 : null,
                      onTap: () async {
                        await _renameServer(context, sora, widget.subscriptionId, server.id, server.displayName);
                        if (mounted) setState(() {});
                      },
                      trailing: Tooltip(
                        message: hidden ? s.overrideUnhide : s.overrideHide,
                        child: Pressable(
                          onTap: () {
                            final next = Set<String>.of(sora.overrides.of(widget.subscriptionId).hidden);
                            if (hidden) {
                              next.remove(server.id);
                            } else {
                              next.add(server.id);
                            }
                            sora.overrides.put(
                              widget.subscriptionId,
                              sora.overrides.of(widget.subscriptionId).copyWith(hidden: next),
                            );
                            setState(() {});
                          },
                          radius: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              hidden ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
                              size: 18,
                              color: palette.ink2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  radius: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(s.close, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
