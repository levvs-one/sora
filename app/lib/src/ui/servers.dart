import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pb.dart';
import '../generated/sora/custom/v1/custom.pbgrpc.dart';
import '../groups.dart';
import '../sora.dart';
import 'addserver.dart';
import 'benchmark.dart';
import 'kit.dart';
import 'qr.dart';
import 'subscription.dart';
import 'subscription_sheet.dart';
import 'tour.dart';
import 'announcement.dart';

/// Keeps subscription order while building only visible server rows.
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key, this.embedded = false, this.scrollable = true});

  final bool embedded;
  final bool scrollable;

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final _search = TextEditingController();
  bool _probed = false;
  final _collapsed = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // No setState listener on [_search]: the subscription sections below
    // listen through ValueListenableBuilder, so typing rebuilds only the
    // list, not the toolbar, search field and custom card.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sora = SoraScope.of(context);
    if (!_probed && sora.canProbe && sora.phase == Phase.off && sora.servers.isNotEmpty) {
      // The desktop pane opens before the subscription stream arrives.
      _probed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(sora.probe());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    if (widget.embedded && sora.subscriptions.isEmpty && sora.customServers.isEmpty) {
      return widget.scrollable ? const SizedBox.expand() : const SliverToBoxAdapter();
    }
    final sortMode = sora.settings.serverSortMode;
    String sortLabel(String mode) => switch (mode) {
      'speed' => s.sortSpeed,
      'name' => s.sortName,
      _ => s.sortPing,
    };
    final actions = [
      if (sora.probing)
        SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink))
      else
        RoundButton(
          icon: Symbols.speed_rounded,
          label: s.probeServers,
          onTap: sora.canProbe ? () => unawaited(sora.probe()) : null,
        ),
      if (sora.benchmarking)
        SizedBox.square(dimension: 36, child: CupertinoActivityIndicator(color: palette.ink))
      else
        RoundButton(
          icon: Symbols.gauge_rounded,
          label: s.measureSpeed,
          onTap: sora.canBenchmark ? () => push<void>(context, const BenchmarkScreen()) : null,
        ),
      MenuAnchor(
        menuChildren: [
          for (final mode in ['ping', 'speed', 'name'])
            MenuItemButton(
              onPressed: () => unawaited(sora.change((x) => x.serverSortMode = mode, replan: false)),
              leadingIcon: sortMode == mode
                  ? Icon(Symbols.check_rounded, size: 18, color: palette.ink)
                  : const SizedBox(width: 18),
              child: Text(sortLabel(mode)),
            ),
        ],
        builder: (context, controller, child) => RoundButton(
          icon: Symbols.sort_rounded,
          label: '${s.sortBy}: ${sortLabel(sortMode)}',
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
      _tourTarget(
        0,
        RoundButton(icon: Symbols.add_rounded, label: s.addSubscription, onTap: () => showSubscriptionSheet(context)),
      ),
      RoundButton(
        icon: Symbols.qr_code_scanner_rounded,
        label: s.qrScan,
        onTap: () => push<void>(context, const QrScanScreen()),
      ),
    ];
    final search = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: const ValueKey('server-search'),
        controller: _search,
        style: Styles.secondary.copyWith(color: palette.ink),
        decoration: InputDecoration(
          hintText: s.search,
          hintStyle: Styles.secondary.copyWith(color: palette.ink3),
          prefixIcon: Icon(Symbols.search_rounded, size: 18, color: palette.ink3),
          isDense: true,
          filled: true,
          fillColor: palette.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
    final automatic = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _tourTarget(
        1,
        DecoratedBox(
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: sora.servers.isNotEmpty
                ? _ServerRow(id: 'auto', name: s.serverAuto)
                : Tile(
                    title: s.addSubscription,
                    onTap: () => showSubscriptionSheet(context),
                    trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
                  ),
          ),
        ),
      ),
    );
    final toolbar = Row(
      children: [
        if (!widget.embedded)
          RoundButton(
            icon: Symbols.chevron_left_rounded,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        const Spacer(),
        ...actions,
      ],
    );
    final separator = palette.ink3.withValues(alpha: 0.28);
    final slivers = <Widget>[
      SliverToBoxAdapter(child: Column(children: [toolbar, const SizedBox(height: 8), search])),
      SliverToBoxAdapter(child: automatic),
      const SliverToBoxAdapter(child: _CustomServersCard()),
      // Typing filters the subscription sections only: the toolbar, search
      // field and custom card keep their state instead of the whole screen
      // rebuilding on every keystroke.
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _search,
        builder: (context, value, _) {
          final query = value.text.trim().toLowerCase();
          // One shared cache per build pass: the sort step and the rows both
          // need each group entry's prospective active member (see
          // _sortEntries), so it is computed once, not per comparison and
          // again per row.
          final shownCache = <Entry, OutboundSpec?>{};
          final sections = <Widget>[];
          for (final subscription in sora.subscriptions) {
            final entries = _sortEntries(_matching(_visibleEntries(subscription, sora), query), sora, shownCache);
            if (query.isNotEmpty && entries.isEmpty) continue;
            sections.add(
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: separator),
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SubscriptionHeader(
                          key: ValueKey(subscription.settings.id),
                          state: subscription,
                          expanded: !_collapsed.contains(subscription.settings.id),
                          onToggle: () => setState(() {
                            final id = subscription.settings.id;
                            if (!_collapsed.remove(id)) _collapsed.add(id);
                          }),
                        ),
                      ),
                      if (!_collapsed.contains(subscription.settings.id))
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                          sliver: SliverList.separated(
                            itemCount: entries.length,
                            itemBuilder: (_, index) {
                              final entry = entries[index];
                              // Keyed by entry id: rows re-sort on every
                              // probe tick and sort-mode change, and the
                              // row's Pressable/Image state must follow the
                              // server, not the position it lands in.
                              return _ServerRow(
                                key: ValueKey(entry.id),
                                id: entry.id,
                                name: entry.name,
                                entry: entry,
                                shownCache: shownCache,
                              );
                            },
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, thickness: 1, indent: 8, endIndent: 8, color: separator),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          return SliverMainAxisGroup(slivers: sections);
        },
      ),
    ];
    if (!widget.scrollable) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverMainAxisGroup(slivers: slivers),
      );
    }
    final list = CustomScrollView(
      key: const PageStorageKey('servers-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
    return widget.embedded ? list : Scaffold(backgroundColor: palette.background, body: list);
  }

  Widget _tourTarget(int step, Widget child) =>
      widget.embedded ? TourTarget(step: step, radius: step == 0 ? 18 : 12, child: child) : child;
}

List<Entry> _matching(List<Entry> entries, String query) => query.isEmpty
    ? entries
    : [
        for (final e in entries)
          if (e.name.toLowerCase().contains(query)) e,
      ];

/// Applies subscription overrides: hides servers the user hid and renames the
/// ones they renamed (FEATURE-PLAN.md F6). A renamed group member splits out
/// of its group so the rename stays visible instead of being swallowed by the
/// shared group title.
///
/// Custom servers (SW7) are dropped everywhere below: INT-1 merges them into
/// each subscription's outbound list so the plan builder sees them, but in
/// the UI they already live in the «Мои серверы» card — keeping them here
/// would show every custom server again inside each subscription. The drop
/// runs before overrides: overrides apply to subscription servers only, and
/// a renamed custom member must not slip back in through [Entry.applyRenames].
List<Entry> _visibleEntries(SubscriptionState subscription, Sora sora) {
  final override = sora.overrides.of(subscription.settings.id);
  final out = <Entry>[];
  for (final entry in entriesOf(subscription)) {
    final deduped = entry.withoutCustom();
    if (deduped == null) continue;
    if (override.isEmpty) {
      out.add(deduped);
      continue;
    }
    final visible = deduped.withoutHidden(override.hidden);
    if (visible == null) continue;
    out.addAll(visible.applyRenames(override.renames));
  }
  return out;
}

/// Sorts server entries by the user's sort mode (FEATURE-PLAN.md F2).
///
/// [shownCache] optionally collects each group entry's prospective active
/// member: the sort keys and the rows below both need it, and [pickMember]
/// scans every member — computing it once per entry per build pass instead
/// of once per sort comparison plus once per row removes the probe-tick
/// hotspot (latency ticks rebuild this screen about three times a second).
List<Entry> _sortEntries(List<Entry> entries, Sora sora, [Map<Entry, OutboundSpec?>? shownCache]) {
  final mode = sora.settings.serverSortMode;
  if (mode == 'name') {
    entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entries;
  }
  // Groups are represented by the prospective active member — the same one
  // whose metrics the row shows — so the visible numbers match the sort order.
  // Keys are computed once per entry: keyOf used to call pickMember on every
  // comparison (O(n log n) member scans per build).
  String keyOf(Entry e) {
    if (!e.isGroup) return e.id;
    final shown = pickMember(e, sora.latency, bandwidth: sora.bandwidth, autoSelect: sora.settings.autoSelectMode);
    shownCache?[e] = shown;
    return shown.id;
  }

  final keys = {for (final e in entries) e: keyOf(e)};
  entries.sort((a, b) => sora.compareServers(keys[a]!, keys[b]!, mode));
  return entries;
}

final _flagPrefix = RegExp(r'^([\u{1F1E6}-\u{1F1FF}]{2})\s*', unicode: true);

InlineSpan serverNameSpan(String name) {
  final flag = _flagPrefix.firstMatch(name);
  if (flag == null) return TextSpan(text: name);
  final code = String.fromCharCodes(flag.group(1)!.runes.map((r) => r - 0x1F1E6 + 97));
  return TextSpan(
    children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(
              'assets/flags/$code.png',
              width: 22,
              height: 14,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => SizedBox(width: 22, child: Text(code.toUpperCase(), style: Styles.caption)),
            ),
          ),
        ),
      ),
      TextSpan(text: name.substring(flag.end)),
    ],
  );
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({super.key, required this.id, required this.name, this.entry, this.shownCache});

  final String id;
  final String name;

  /// Group data when multiple servers share a name.
  final Entry? entry;

  /// Prospective active members computed during sorting in the same build
  /// pass; consulted before recomputing [pickMember].
  final Map<Entry, OutboundSpec?>? shownCache;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final chosen = sora.selected == id;
    // Use the prospective active member's latency for a group row. The same
    // member supplies the wire-level flow shown in the badge below. The sort
    // step already computed it for this build pass (see _sortEntries).
    final OutboundSpec? shown = entry == null || !entry!.isGroup
        ? null
        : shownCache?[entry!] ??
              pickMember(entry!, sora.latency, bandwidth: sora.bandwidth, autoSelect: sora.settings.autoSelectMode);
    final measuredId = shown?.id ?? id;
    final measured = sora.latency.containsKey(measuredId);
    final ms = sora.latency[measuredId];
    final bps = sora.freshBandwidth(measuredId);
    final staleBps = bps == null ? sora.bandwidth[measuredId]?.bps : null;
    final group = entry;
    final detail = group?.members.map(protocolLine).toSet().join(' | ');
    return Semantics(
      selected: chosen,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chosen ? palette.field : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Pressable(
          onTap: () => unawaited(sora.select(id)),
          radius: 8,
          give: 1,
          child: SizedBox(
            height: entry == null ? 48 : 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          serverNameSpan(name),
                          semanticsLabel: name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.row.copyWith(color: palette.ink),
                        ),
                        if (detail != null && detail.isNotEmpty || (shown?.flow.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                if (detail != null && detail.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Styles.caption.copyWith(color: palette.ink3),
                                    ),
                                  ),
                                if (shown != null && shown.flow.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  _FlowBadge(flow: shown.flow, auto: shown.flowAuto),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          !measured
                              ? ''
                              : ms == null
                              ? s.noAnswer
                              : s.milliseconds(ms),
                          textAlign: TextAlign.right,
                          style: Styles.figures(Styles.caption).copyWith(color: palette.ink2),
                        ),
                        if (bps != null || staleBps != null)
                          Text(
                            s.speedMbps(mbpsOf(bps ?? staleBps!)),
                            textAlign: TextAlign.right,
                            style: Styles.figures(
                              Styles.caption,
                            ).copyWith(color: bps != null ? palette.ink2 : palette.ink3),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionHeader extends StatefulWidget {
  const _SubscriptionHeader({super.key, required this.state, required this.expanded, required this.onToggle});

  final SubscriptionState state;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_SubscriptionHeader> createState() => _SubscriptionHeaderState();
}

class _SubscriptionHeaderState extends State<_SubscriptionHeader> {
  SubscriptionState get state => widget.state;
  bool _descriptionVisible = true;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final info = state.info;
    final facts = <String>[];
    if (info.hasUsage) {
      final used = formatBytes(s, info.uploadBytes + info.downloadBytes, locale);
      facts.add(info.totalBytes == Int64.ZERO ? used : s.usage(used, formatBytes(s, info.totalBytes, locale)));
    }
    if (info.hasExpire()) {
      final expire = info.expire.toDateTime().toLocal();
      if (expire.isBefore(DateTime.now())) {
        facts.add(s.expired);
      } else {
        // Include the year for expiry dates outside the current year to avoid
        // ambiguous dates.
        final dateLocale = Intl.verifiedLocale(locale, DateFormat.localeExists, onFailure: (_) => 'en');
        final format = expire.year == DateTime.now().year
            ? DateFormat.MMMMd(dateLocale)
            : DateFormat.yMMMMd(dateLocale);
        facts.add(s.until(format.format(expire)));
      }
    }
    final factStyle = Styles.caption.copyWith(color: palette.ink3);

    final used = (info.uploadBytes + info.downloadBytes).toDouble();
    final share = info.hasUsage && info.totalBytes > Int64.ZERO
        ? (used / info.totalBytes.toDouble()).clamp(0.0, 1.0)
        : null;
    final announce = info.announce.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                expanded: widget.expanded,
                child: RoundButton(
                  key: ValueKey('collapse-subscription-${state.settings.id}'),
                  icon: widget.expanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded,
                  label: widget.expanded ? s.collapseServers : s.expandServers,
                  onTap: widget.onToggle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.bodyStrong.copyWith(color: palette.ink),
                    ),
                    if (facts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(spacing: 14, children: [for (final f in facts) Text(f, style: factStyle)]),
                      ),
                  ],
                ),
              ),
              if (sora.probing && (sora.probingSubscription == null || sora.probingSubscription == state.settings.id))
                SizedBox.square(
                  key: ValueKey('probe-subscription-${state.settings.id}'),
                  dimension: 36,
                  child: CupertinoActivityIndicator(color: palette.ink),
                )
              else
                Tooltip(
                  message: '${s.probeServers}: ${state.displayName}',
                  child: RoundButton(
                    key: ValueKey('probe-subscription-${state.settings.id}'),
                    icon: Symbols.speed_rounded,
                    label: '${s.probeServers}: ${state.displayName}',
                    onTap: !sora.canProbe || state.outbounds.isEmpty
                        ? null
                        : () => unawaited(sora.probe(subscriptionId: state.settings.id)),
                  ),
                ),
              if (state.updating)
                SizedBox.square(
                  key: ValueKey('refresh-subscription-${state.settings.id}'),
                  dimension: 36,
                  child: CupertinoActivityIndicator(color: palette.ink),
                )
              else
                Tooltip(
                  message: '${s.refresh}: ${state.displayName}',
                  child: RoundButton(
                    key: ValueKey('refresh-subscription-${state.settings.id}'),
                    icon: Symbols.refresh_rounded,
                    label: '${s.refresh}: ${state.displayName}',
                    onTap: () => unawaited(sora.refreshSubscription(state.settings.id)),
                  ),
                ),
              MenuAnchor(
                alignmentOffset: const Offset(-150, 4),
                menuChildren: [
                  _item(context, s.website, () => unawaited(sora.openSubscriptionPage(state.settings.id))),
                  if (info.webPageUrl.isNotEmpty)
                    _item(context, s.providerWebsite, () => unawaited(openLink(context, info.webPageUrl))),
                  if (info.supportUrl.isNotEmpty)
                    _item(context, s.support, () => unawaited(openLink(context, info.supportUrl))),
                  _item(context, s.qrShareTitle, () => unawaited(_shareQr(context, state))),
                  _item(
                    context,
                    s.subscriptionSettings,
                    () => unawaited(push<void>(context, SubscriptionScreen(id: state.settings.id))),
                  ),
                  _item(context, s.delete, () => unawaited(deleteSubscription(context, state)), danger: true),
                ],
                builder: (context, controller, _) => RoundButton(
                  icon: Symbols.more_horiz_rounded,
                  label: state.displayName,
                  onTap: () => controller.isOpen ? controller.close() : controller.open(),
                ),
              ),
            ],
          ),
          if (share != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 10, 0),
              child: UsageBar(share: share),
            ),
          if (announce.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Column(
                children: [
                  Center(
                    child: Semantics(
                      expanded: _descriptionVisible,
                      child: RoundButton(
                        key: ValueKey('description-subscription-${state.settings.id}'),
                        icon: _descriptionVisible
                            ? Symbols.keyboard_arrow_up_rounded
                            : Symbols.keyboard_arrow_down_rounded,
                        label: _descriptionVisible ? s.hideDescription : s.showDescription,
                        onTap: () => setState(() => _descriptionVisible = !_descriptionVisible),
                      ),
                    ),
                  ),
                  if (_descriptionVisible)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Announcement(announce)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String label, VoidCallback onTap, {bool danger = false}) {
    final palette = Palette.of(context);
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        overlayColor: WidgetStatePropertyAll(palette.hover),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      ),
      child: Text(label, style: Styles.secondary.copyWith(color: danger ? palette.danger : palette.ink)),
    );
  }
}

/// Fetches the subscription link and shows it as a QR code. Failures are
/// reported through the standard failure pipeline; nothing raw is shown.
Future<void> _shareQr(BuildContext context, SubscriptionState state) async {
  final sora = SoraScope.read(context);
  final url = await sora.fetchSubscriptionLink(state.settings.id);
  if (url != null && context.mounted) {
    await push<void>(context, QrShareScreen(payload: url, title: state.displayName));
  }
}

/// Confirms deletion, then removes the subscription and its servers.
Future<void> deleteSubscription(BuildContext context, SubscriptionState state) async {
  final sora = SoraScope.read(context);
  final s = S.of(context);
  if (await confirm(context, question: s.deleteSubscription(state.displayName), action: s.delete)) {
    await sora.deleteSubscription(state.settings.id);
  }
}

/// Confirms deletion, then removes the user-added server.
Future<void> _deleteCustomServer(BuildContext context, CustomServer server) async {
  final sora = SoraScope.read(context);
  final s = S.of(context);
  if (await confirm(context, question: s.customServerDeleteConfirm(server.name), action: s.delete)) {
    await sora.deleteCustomServer(server.id);
  }
}

/// The user's own servers, stored by the core outside subscriptions. Always
/// visible: the empty state is the discovery path to the add form.
class _CustomServersCard extends StatelessWidget {
  const _CustomServersCard();

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final servers = sora.customServers;
    final separator = palette.ink3.withValues(alpha: 0.28);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: separator),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.customServers,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.bodyStrong.copyWith(color: palette.ink),
                    ),
                  ),
                  RoundButton(
                    icon: Symbols.add_rounded,
                    label: s.customServerAdd,
                    onTap: () => unawaited(push<void>(context, const AddServerScreen())),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: servers.isEmpty
                  ? Tile(
                      title: s.customServerAdd,
                      detail: s.customServerEmptyHint,
                      onTap: () => unawaited(push<void>(context, const AddServerScreen())),
                      trailing: Icon(Symbols.add_rounded, size: 18, color: palette.ink),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < servers.length; i++) ...[
                          if (i > 0) Divider(height: 1, thickness: 1, indent: 8, endIndent: 8, color: separator),
                          // Keyed by server id: the row is stateful (its
                          // in-flight test spinner), so a deletion must not
                          // shift that state onto the next server.
                          _CustomServerRow(key: ValueKey(servers[i].id), server: servers[i]),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomServerRow extends StatefulWidget {
  const _CustomServerRow({super.key, required this.server});

  final CustomServer server;

  @override
  State<_CustomServerRow> createState() => _CustomServerRowState();
}

class _CustomServerRowState extends State<_CustomServerRow> {
  bool _testing = false;

  /// Runs the core reachability test for this saved server. The outcome
  /// lands in [Sora.latency] (null when unreachable) and the row rebuilds
  /// from it; RPC failures surface through the notification stream.
  Future<void> _test() async {
    if (_testing) return;
    final sora = SoraScope.read(context);
    setState(() => _testing = true);
    await sora.testCustomServer(widget.server.id);
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final server = widget.server;
    // Selection and latency live in the core's outbound namespace, where
    // custom servers are `custom/<id>` (INT-1); the card's CustomServer
    // carries the plain id, so it is canonicalized once here.
    final customId = sora.canonicalServerId(server.id);
    final chosen = sora.selected == customId;
    final ms = sora.latency[customId];
    final measured = sora.latency.containsKey(customId);
    return Semantics(
      selected: chosen,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chosen ? palette.field : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Pressable(
          onTap: () => unawaited(sora.select(server.id)),
          radius: 8,
          give: 1,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                server.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Styles.row.copyWith(color: palette.ink),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CustomBadge(label: s.customServerBadge),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${customProtocolLabel(server.protocol)} | ${server.address}:${server.port}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Styles.caption.copyWith(color: palette.ink3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: Text(
                      !measured
                          ? ''
                          : ms == null
                          ? s.noAnswer
                          : s.milliseconds(ms),
                      textAlign: TextAlign.right,
                      style: Styles.figures(Styles.caption).copyWith(color: palette.ink2),
                    ),
                  ),
                  Tooltip(
                    message: s.customServerTest,
                    child: Pressable(
                      onTap: _testing ? null : () => unawaited(_test()),
                      radius: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _testing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CupertinoActivityIndicator(radius: 9),
                              )
                            : Icon(Symbols.network_check_rounded, size: 18, color: palette.ink2),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: s.delete,
                    child: Pressable(
                      onTap: () => unawaited(_deleteCustomServer(context, server)),
                      radius: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Symbols.delete_rounded, size: 18, color: palette.ink2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small outlined pill marking a user-added server.
class _CustomBadge extends StatelessWidget {
  const _CustomBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: palette.ink3.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(label, style: Styles.caption.copyWith(color: palette.ink2)),
      ),
    );
  }
}

/// A small outlined pill showing the flow a server actually uses on the wire.
/// When [auto] is true the core assigned the flow itself (auto-vision) rather
/// than the import link, and a calm localized "auto" marker is appended.
class _FlowBadge extends StatelessWidget {
  const _FlowBadge({required this.flow, required this.auto});

  final String flow;
  final bool auto;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final s = S.of(context);
    final label = auto ? '$flow · ${s.flowAuto}' : flow;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.ink3.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(label, style: Styles.caption.copyWith(color: palette.ink2)),
        ),
      ),
    );
  }
}

/// Formats a localized byte count with a unit and up to one decimal place.
String formatBytes(S s, Int64 bytes, String locale) {
  final (value, unit) = Sora.scaleBytes(bytes);
  final supported = Intl.verifiedLocale(locale, NumberFormat.localeExists, onFailure: (_) => 'en');
  final number = NumberFormat(value >= 100 || unit == 0 ? '0' : '0.#', supported).format(value);
  return switch (unit) {
    0 => s.bytesB(number),
    1 => s.bytesKB(number),
    2 => s.bytesMB(number),
    3 => s.bytesGB(number),
    _ => s.bytesTB(number),
  };
}

/// Returns a warning for expired subscriptions, expiry within three days or
/// less than 10% traffic remaining. Returns null otherwise.
String? subscriptionWarning(S s, SubscriptionState sub, String locale) {
  const soon = Duration(days: 3);
  const little = 0.1;
  final info = sub.info;
  if (info.hasExpire()) {
    final left = info.expire.toDateTime().difference(DateTime.now());
    if (left.isNegative) return '${sub.displayName}: ${s.expired.toLowerCase()}';
    if (left < soon) return s.expiresIn(sub.displayName, left.inDays);
  }
  if (info.hasUsage && info.totalBytes > Int64.ZERO) {
    final rest = info.totalBytes - info.uploadBytes - info.downloadBytes;
    if (rest.toDouble() < info.totalBytes.toDouble() * little) {
      return s.trafficLow(sub.displayName, formatBytes(s, rest < Int64.ZERO ? Int64.ZERO : rest, locale));
    }
  }
  return null;
}

String protocolLine(OutboundSpec server) => [
  if (server.displayProtocol.isNotEmpty)
    server.displayProtocol.toUpperCase()
  else if (server.protocol.isNotEmpty)
    server.protocol == 'xray-profile' ? 'XRAY' : server.protocol.toUpperCase(),
  if (server.transport.isNotEmpty) server.transport.toUpperCase(),
  if (server.security.isNotEmpty && server.security.toLowerCase() != 'none') server.security.toUpperCase(),
  if (isProfile(server)) 'JSON',
].join(' | ');
