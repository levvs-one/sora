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
import '../notifications.dart';
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
    // list, not the toolbar, search field and custom group.
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
    final empty = sora.subscriptions.isEmpty && sora.customServers.isEmpty;
    final search = TextField(
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
    );
    final automatic = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _tourTarget(
        1,
        DecoratedBox(
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _ServerRow(id: 'auto', name: s.serverAuto),
          ),
        ),
      ),
    );
    // Search and the list's actions share one row, in the same round buttons
    // as each subscription's header. Ping keeps its place while it works.
    final toolbar = Row(
      children: [
        if (!widget.embedded)
          RoundButton(
            icon: Symbols.chevron_left_rounded,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        Expanded(child: sora.subscriptions.isNotEmpty ? search : const SizedBox.shrink()),
        const SizedBox(width: 4),
        Tooltip(
          message: s.probeServers,
          child: BusyRoundButton(
            key: const ValueKey('probe-all'),
            icon: Symbols.signal_cellular_alt_rounded,
            label: s.probeServers,
            busy: sora.probing,
            onTap: sora.canProbe && !sora.probing && sora.servers.isNotEmpty ? () => unawaited(sora.probe()) : null,
          ),
        ),
        _tourTarget(0, const _AddMenu()),
      ],
    );
    final separator = palette.ink3.withValues(alpha: 0.28);
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Column(
          children: [
            const BackgroundFailureState(source: 'probe'),
            const BackgroundFailureState(source: 'benchmark'),
            const BackgroundFailureState(source: 'custom-servers'),
            if (empty)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _EmptyServers(tour: widget.embedded && !sora.bypassSelected),
                ),
              )
            else ...[
              toolbar,
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      if (sora.servers.isNotEmpty) SliverToBoxAdapter(child: automatic),
      // Typing filters the subscription sections only: the toolbar, search
      // field and custom group keep their state instead of the whole screen
      // rebuilding on every keystroke.
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _search,
        builder: (context, value, _) {
          final query = value.text.trim().toLowerCase();
          final sections = <Widget>[];
          for (final subscription in sora.subscriptions) {
            final entries = _matching(_visibleEntries(subscription, sora), query);
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
                              return _ServerRow(key: ValueKey(entry.id), id: entry.id, name: entry.name, entry: entry);
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
      if (sora.customServers.isNotEmpty) const SliverToBoxAdapter(child: _CustomServersGroup()),
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

  Widget _tourTarget(int step, Widget child) => widget.embedded && SoraScope.of(context).subscriptions.isNotEmpty
      ? TourTarget(step: step, radius: step == 0 ? 18 : 12, child: child)
      : child;
}

List<Entry> _matching(List<Entry> entries, String query) => query.isEmpty
    ? entries
    : [
        for (final e in entries)
          if (e.name.toLowerCase().contains(query)) e,
      ];

/// Applies subscription overrides: hides servers the user hid and renames the
/// ones they renamed. A renamed group member splits out
/// of its group so the rename stays visible instead of being swallowed by the
/// shared group title.
///
/// Custom servers are dropped everywhere below: the core merges them into
/// each subscription's outbound list so the plan builder sees them, but in
/// the UI they already live in the «Мои серверы» card, and keeping them here
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
  // A split or hidden first member moves a group to its first visible member.
  final byMember = {
    for (final entry in out)
      for (final member in entry.members) member.id: entry,
  };
  final emitted = <String>{};
  return [
    for (final member in subscription.outbounds)
      if (byMember[member.id] case final entry?)
        if (emitted.add(entry.id)) entry,
  ];
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
  const _ServerRow({super.key, required this.id, required this.name, this.entry});

  final String id;
  final String name;

  /// Group data when multiple servers share a name.
  final Entry? entry;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final palette = Palette.of(context);
    final s = S.of(context);
    final chosen = sora.selected == id;
    final OutboundSpec? shown = entry == null
        ? null
        : entry!.isGroup
        ? pickMember(entry!, sora.latency, bandwidth: sora.bandwidth, autoSelect: sora.settings.autoSelectMode)
        : entry!.members.single;
    final pinging = entry == null
        ? sora.pendingProbes.contains(id)
        : entry!.members.any((o) => sora.pendingProbes.contains(o.id));
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
                        if (detail != null && detail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                if (detail.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Styles.caption.copyWith(color: palette.ink3),
                                    ),
                                  ),
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
                        if (pinging)
                          CupertinoActivityIndicator(key: ValueKey('ping-row-$id'), radius: 8, color: palette.ink)
                        else
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
                            style: Styles.figures(Styles.caption)
                                .copyWith(color: bps != null ? palette.ink2 : palette.ink3),
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
              Tooltip(
                message: '${s.probeServers}: ${state.displayName}',
                child: BusyRoundButton(
                  key: ValueKey('probe-subscription-${state.settings.id}'),
                  icon: Symbols.signal_cellular_alt_rounded,
                  label: '${s.probeServers}: ${state.displayName}',
                  busy:
                      sora.probing &&
                      (sora.probingSubscription == null || sora.probingSubscription == state.settings.id),
                  onTap: !sora.canProbe || state.outbounds.isEmpty
                      ? null
                      : () => unawaited(sora.probe(subscriptionId: state.settings.id)),
                ),
              ),
              Tooltip(
                message: '${s.refresh}: ${state.displayName}',
                child: BusyRoundButton(
                  key: ValueKey('refresh-subscription-${state.settings.id}'),
                  icon: Symbols.refresh_rounded,
                  label: '${s.refresh}: ${state.displayName}',
                  busy: state.updating,
                  onTap: () => unawaited(sora.refreshSubscription(state.settings.id)),
                ),
              ),
              Tooltip(
                message: s.qrShareTitle,
                child: RoundButton(
                  key: ValueKey('share-subscription-${state.settings.id}'),
                  icon: Symbols.qr_code_rounded,
                  label: s.qrShareTitle,
                  onTap: () => unawaited(shareSubscriptionQr(context, state)),
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
                  if (sora.canBenchmark && state.outbounds.isNotEmpty)
                    _item(
                      context,
                      s.measureSpeed,
                      () => unawaited(
                        push<void>(context, BenchmarkScreen(serverIds: [for (final o in state.outbounds) o.id])),
                      ),
                    ),
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
          if (state.hasLastError()) SubscriptionUpdateState(state: state),
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
Future<void> shareSubscriptionQr(BuildContext context, SubscriptionState state) async {
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

/// One "Add" button for every way to get servers: a subscription link, an
/// own server or a QR code.
class _AddMenu extends StatelessWidget {
  const _AddMenu();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    MenuItemButton item(Key key, IconData icon, String label, VoidCallback onTap) => MenuItemButton(
      key: key,
      onPressed: onTap,
      leadingIcon: Icon(icon, size: 18, color: palette.ink),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(220, 40)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        overlayColor: WidgetStatePropertyAll(palette.hover),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      ),
      child: Text(label, style: Styles.secondary.copyWith(color: palette.ink)),
    );
    return MenuAnchor(
      alignmentOffset: const Offset(-184, 4),
      menuChildren: [
        item(
          const ValueKey('add-subscription'),
          Symbols.link_rounded,
          s.addSubscription,
          () => unawaited(showSubscriptionSheet(context)),
        ),
        item(
          const ValueKey('add-menu-own-server'),
          Symbols.dns_rounded,
          s.customServerAdd,
          () => unawaited(showAddServerSheet(context)),
        ),
        item(
          const ValueKey('add-qr'),
          Symbols.qr_code_scanner_rounded,
          s.qrScan,
          () => unawaited(push<void>(context, const QrScanScreen())),
        ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: s.add,
        child: RoundButton(
          key: const ValueKey('add-menu'),
          icon: Symbols.add_rounded,
          label: s.add,
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// No subscriptions and no own servers yet: say what to do, with the three
/// ways to do it right here instead of an unlabeled toolbar.
class _EmptyServers extends StatelessWidget {
  const _EmptyServers({required this.tour});

  /// Whether this card is the onboarding tour's target (the home pane).
  final bool tour;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    Widget add = PrimaryButton(
      key: const ValueKey('empty-add-subscription'),
      label: s.addSubscription,
      onTap: () => unawaited(showSubscriptionSheet(context)),
    );
    // The tour points at the button itself: it stays on screen without
    // scrolling, so the highlight never has to chase a moving card.
    if (tour) add = TourTarget(step: 1, radius: 26, child: TourTarget(step: 0, radius: 26, child: add));
    return Container(
      key: const ValueKey('servers-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(12)),
                child: Icon(Symbols.dns_rounded, size: 21, fill: 1, color: palette.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.emptyServersTitle, style: Styles.bodyStrong.copyWith(color: palette.ink, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(s.emptyServersBody, style: Styles.secondary.copyWith(color: palette.ink, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          add,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlineAction(
                  key: const ValueKey('add-own-server'),
                  icon: Symbols.dns_rounded,
                  label: s.customServerOwn,
                  onTap: () => unawaited(showAddServerSheet(context)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlineAction(
                  key: const ValueKey('empty-qr'),
                  icon: Symbols.qr_code_scanner_rounded,
                  label: s.qrShort,
                  onTap: () => unawaited(push<void>(context, const QrScanScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomServersGroup extends StatelessWidget {
  const _CustomServersGroup();

  @override
  Widget build(BuildContext context) {
    final servers = SoraScope.of(context).customServers;
    final palette = Palette.of(context);
    final separator = palette.ink3.withValues(alpha: 0.28);
    return Padding(
      key: const ValueKey('own-servers-group'),
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: separator),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(S.of(context).customServers, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                    ),
                    RoundButton(
                      key: const ValueKey('add-own-server'),
                      icon: Symbols.add_rounded,
                      label: S.of(context).customServerAdd,
                      onTap: () => unawaited(showAddServerSheet(context)),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < servers.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, indent: 8, endIndent: 8, color: separator),
                _CustomServerRow(key: ValueKey(servers[i].id), server: servers[i]),
              ],
            ],
          ),
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
    // custom servers are `custom/<id>`; the card's CustomServer
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
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Styles.row.copyWith(color: palette.ink),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${customServerProtocol(server).toUpperCase()} | ${server.address}:${server.port}',
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
                    width: 64,
                    child: sora.pendingProbes.contains(customId)
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoActivityIndicator(
                              key: ValueKey('ping-row-$customId'),
                              radius: 8,
                              color: palette.ink,
                            ),
                          )
                        : Text(
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
                    message: s.probeServers,
                    child: Pressable(
                      onTap: _testing || sora.probing ? null : () => unawaited(_test()),
                      radius: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _testing
                            ? const SizedBox(width: 18, height: 18, child: CupertinoActivityIndicator(radius: 9))
                            : Icon(Symbols.signal_cellular_alt_rounded, size: 18, color: palette.ink2),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: s.edit,
                    child: RoundButton(
                      key: ValueKey('edit-own-server-${server.id}'),
                      icon: Symbols.edit_rounded,
                      label: s.edit,
                      onTap: () => unawaited(showAddServerSheet(context, server: server)),
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
AppNotification? subscriptionWarning(S s, SubscriptionState sub, String locale, {DateTime? at}) {
  const soon = Duration(days: 3);
  const little = 0.1;
  final time = at ?? DateTime.now();
  final info = sub.info;
  String? body, key;
  final args = <String, String>{'name': sub.displayName};
  if (info.hasExpire()) {
    final left = info.expire.toDateTime().difference(time);
    if (left.isNegative) {
      body = '${sub.displayName}: ${s.expired.toLowerCase()}';
      key = 'notice.expired';
    } else if (left < soon) {
      body = s.expiresIn(sub.displayName, left.inDays);
      key = 'notice.expiring';
      args['days'] = '${left.inDays}';
    }
  }
  if (body == null && info.hasUsage && info.totalBytes > Int64.ZERO) {
    final rest = info.totalBytes - info.uploadBytes - info.downloadBytes;
    if (rest.toDouble() < info.totalBytes.toDouble() * little) {
      final remaining = rest < Int64.ZERO ? Int64.ZERO : rest;
      body = s.trafficLow(sub.displayName, formatBytes(s, remaining, locale));
      key = 'notice.traffic';
      final (amount, unit) = Sora.scaleBytes(remaining);
      args['amount'] = NumberFormat(amount >= 100 || unit == 0 ? '0' : '0.#', 'en').format(amount);
      args['unit'] = '$unit';
    }
  }
  if (body == null) return null;
  return AppNotification(
    time: time,
    title: s.noticeSubscription,
    body: body,
    action: 'subscription',
    argument: sub.settings.id,
    messageKey: key!,
    messageArgs: args,
  );
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
