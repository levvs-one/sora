import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart' show CallOptions, ResponseFuture;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';
import 'rules_screen.dart';
import 'servers.dart';

/// Lists live session connections with destination, process, outbound and byte
/// counters. Supports closing individual connections, grouping by process and
/// per-connection actions (copy host, add a routing rule).
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  /// Polls engine-owned counters once per second without resetting the list.
  static const _every = Duration(seconds: 1);

  final _search = TextEditingController();
  Timer? _timer;
  List<Connection> _list = [];
  bool _loaded = false;
  bool _grouped = false;
  bool _reading = false;
  CoreFailure? _failure;
  CoreLink? _sourceLink;
  String? _sourceSession;
  ResponseFuture<ListConnectionsResponse>? _request;
  final _collapsedGroups = <String>{};

  @override
  void initState() {
    super.initState();
    // No setState listener on [_search]: the list below listens through
    // ValueListenableBuilder, so typing rebuilds only the list, not the
    // stats bar, search field and view switch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_read());
      _timer = Timer.periodic(_every, (_) => unawaited(_read()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final request = _request;
    if (request != null) unawaited(request.cancel());
    _search.dispose();
    super.dispose();
  }

  Future<void> _read({FailureMode mode = FailureMode.background}) async {
    if (!mounted || _reading) return;
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link != _sourceLink || session != _sourceSession) {
      setState(() {
        _sourceLink = link;
        _sourceSession = session;
        _list = [];
        _failure = null;
        _loaded = false;
      });
    }
    if (link == null || session == null) {
      setState(() => _loaded = true);
      return;
    }
    unawaited(sora.readStats());
    setState(() => _reading = true);
    try {
      final request = link.stub.listConnections(
        ListConnectionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: session),
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );
      _request = request;
      final answer = await request;
      if (!mounted || sora.link != link || sora.sessionId != session) return;
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      setState(() {
        _list = answer.connections.toList()..sort((a, b) => b.start.seconds.compareTo(a.start.seconds));
        _failure = null;
        _loaded = true;
      });
      sora.recovered('connections');
    } catch (error) {
      if (!mounted || sora.link != link || sora.sessionId != session) return;
      setState(() {
        _list = [];
        _failure = CoreFailure.from(error);
        _loaded = true;
      });
      sora.reportFailure(error, source: 'connections', mode: mode);
    } finally {
      _request = null;
      if (mounted) {
        setState(() => _reading = false);
        if (sora.link != link || sora.sessionId != session) unawaited(_read());
      }
    }
  }

  Future<void> _close(Connection c) async {
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) return;
    setState(
      () => _list = [
        for (final x in _list)
          if (x.id != c.id) x,
      ],
    );
    try {
      final answer = await link.stub.closeConnection(
        CloseConnectionRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          sessionId: session,
          connectionId: c.id,
        ),
      );
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'connections', mode: FailureMode.action);
    }
  }

  Future<void> _copyHost(Connection c) => Clipboard.setData(ClipboardData(text: c.host));

  void _addRule(Connection c) => addRuleSheet(context, initialDestination: c.host);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final sora = SoraScope.of(context);
    final active = sora.link != null && sora.sessionId != null;
    final current = sora.link == _sourceLink && sora.sessionId == _sourceSession;
    final usable = active && current && _loaded && _failure == null;
    return Screen(
      title: s.connections,
      actions: [
        if (active && _failure == null)
          SizedBox.square(
            dimension: 44,
            child: RoundButton(
              icon: Symbols.refresh_rounded,
              label: s.refresh,
              onTap: _reading ? null : () => unawaited(_read(mode: FailureMode.action)),
            ),
          ),
      ],
      fill: !active
          ? Center(
              child: Text(s.stateOff, style: Styles.body.copyWith(color: palette.ink)),
            )
          : !current || !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _failure != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      describe(s, _failure!),
                      style: Styles.body.copyWith(color: palette.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _reading ? null : () => unawaited(_read(mode: FailureMode.action)),
                      icon: const Icon(Symbols.refresh_rounded),
                      label: Text(s.refresh),
                    ),
                  ],
                ),
              ),
            )
          : ValueListenableBuilder<TextEditingValue>(
              valueListenable: _search,
              builder: (context, value, _) {
                final query = value.text.trim().toLowerCase();
                final shown = query.isEmpty
                    ? _list
                    : [
                        for (final c in _list)
                          if ('${c.host} ${c.process} ${c.chain.join(' ')}'.toLowerCase().contains(query)) c,
                      ];
                if (shown.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty ? s.connEmpty : s.speedtestEmpty,
                      style: Styles.secondary.copyWith(color: palette.ink),
                    ),
                  );
                }
                return _grouped
                    ? _groupedList(shown)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _Row(
                          connection: shown[i],
                          onClose: () => unawaited(_close(shown[i])),
                          onCopyHost: () => unawaited(_copyHost(shown[i])),
                          onAddRule: () => _addRule(shown[i]),
                        ),
                      );
              },
            ),
      children: [
        if (active) _statsBar(context),
        if (usable && _list.isNotEmpty) ...[
          CupertinoSearchTextField(
            controller: _search,
            placeholder: s.search,
            style: Styles.body.copyWith(color: palette.ink),
            placeholderStyle: Styles.body.copyWith(color: palette.ink3),
            backgroundColor: palette.field,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            itemColor: palette.ink3,
          ),
          const SizedBox(height: 12),
          Segments<bool>(
            value: _grouped,
            choices: {false: s.connListView, true: s.connGroupByProcess},
            onChanged: (v) => setState(() => _grouped = v),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  /// Live throughput and connection count, polled only while this screen is
  /// open.
  Widget _statsBar(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final up = sora.speedUp, down = sora.speedDown;
    final active = _loaded && _failure == null && sora.link == _sourceLink && sora.sessionId == _sourceSession
        ? _list.length
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              up == null || down == null ? '-' : '↑ ${_speed(s, up, locale)}  ↓ ${_speed(s, down, locale)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.figures(Styles.body).copyWith(color: palette.ink),
            ),
          ),
          if (active != null) Text(s.connConnectionsCount(active), style: Styles.caption.copyWith(color: palette.ink2)),
        ],
      ),
    );
  }

  String _speed(S s, double bps, String locale) => '${formatBytes(s, Int64(bps.round()), locale)}/s';

  /// Groups connections by process, heaviest first, with collapsible headers.
  Widget _groupedList(List<Connection> shown) {
    final groups = <String, List<Connection>>{};
    for (final c in shown) {
      groups.putIfAbsent(c.process.isEmpty ? '-' : c.process, () => []).add(c);
    }
    // Traffic totals are the sort keys: compute them once per build pass,
    // not per comparison: _traffic sums every connection in the group, so
    // the comparator made grouping O(g log g × group size) on every poll
    // tick and search keystroke (the benchmark screen's sort-keys
    // pattern). The totals cannot change during the sort, so the order is
    // identical.
    final traffic = {for (final key in groups.keys) key: _traffic(groups[key]!)};
    final keys = groups.keys.toList()..sort((a, b) => traffic[b]!.compareTo(traffic[a]!));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final name = keys[i];
        final items = groups[name]!;
        final collapsed = _collapsedGroups.contains(name);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupHeader(
              name: name,
              count: items.length,
              collapsed: collapsed,
              onToggle: () => setState(() => collapsed ? _collapsedGroups.remove(name) : _collapsedGroups.add(name)),
            ),
            if (!collapsed)
              for (final c in items)
                _Row(
                  connection: c,
                  onClose: () => unawaited(_close(c)),
                  onCopyHost: () => unawaited(_copyHost(c)),
                  onAddRule: () => _addRule(c),
                ),
          ],
        );
      },
    );
  }

  static int _traffic(List<Connection> items) {
    var total = 0;
    for (final c in items) {
      total += c.upload.toInt() + c.download.toInt();
    }
    return total;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.name, required this.count, required this.collapsed, required this.onToggle});

  final String name;
  final int count;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tile(
        title: name,
        titleStyle: Styles.bodyStrong,
        detail: s.connConnectionsCount(count),
        onTap: onToggle,
        trailing: Icon(
          collapsed
              ? (Directionality.of(context) == TextDirection.rtl
                    ? Symbols.keyboard_arrow_left_rounded
                    : Symbols.keyboard_arrow_right_rounded)
              : Symbols.keyboard_arrow_down_rounded,
          size: 18,
          color: palette.ink3,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.connection, required this.onClose, required this.onCopyHost, required this.onAddRule});

  final Connection connection;
  final VoidCallback onClose;
  final VoidCallback onCopyHost;
  final VoidCallback onAddRule;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = connection;
    final where = c.port == 0 ? c.host : '${c.host}:${c.port}';
    final detail = [
      if (c.process.isNotEmpty) c.process,
      if (c.chain.isNotEmpty) _carrier(s, SoraScope.read(context), c.chain.last),
      if (c.closable || c.upload != 0 || c.download != 0)
        '↑ ${formatBytes(s, c.upload, locale)}  ↓ ${formatBytes(s, c.download, locale)}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Styles.body.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 14,
                    children: [
                      for (final fact in detail)
                        Text(fact, style: Styles.figures(Styles.caption).copyWith(color: palette.ink)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          MenuAnchor(
            alignmentOffset: const Offset(-140, 4),
            menuChildren: [
              if (c.closable) _menuItem(context, s.close, onClose),
              _menuItem(context, s.connCopyHost, onCopyHost),
              _menuItem(context, s.connAddRule, onAddRule),
            ],
            builder: (context, controller, _) => RoundButton(
              icon: Symbols.more_vert_rounded,
              label: s.more,
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
          if (c.closable) RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: onClose),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String label, VoidCallback onTap) {
    final palette = Palette.of(context);
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        overlayColor: WidgetStatePropertyAll(palette.hover),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      ),
      child: Text(label, style: Styles.secondary.copyWith(color: palette.ink)),
    );
  }
}

/// Resolves an outbound hop to its localized or configured display name.
String _carrier(S s, Sora sora, String hop) => switch (hop) {
  'direct' || 'DIRECT' => s.chainDirect,
  'reject' || 'REJECT' || 'block' => s.chainBlocked,
  Sora.autoGroup => s.serverAuto,
  Sora.entryGroup => sora.displayNameOf(sora.selected),
  Sora.bypassId => s.serverBypass,
  'sora-zapret-direct' => s.chainDirect,
  _ => sora.displayNameOf(hop),
};
