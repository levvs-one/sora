import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _collapsedGroups = <String>{};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_read());
      _timer = Timer.periodic(_every, (_) => unawaited(_read()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    if (!mounted) return;
    final sora = SoraScope.read(context);
    // Speed counters are polled on demand only while this screen is open;
    // there is intentionally no global polling (audit M17).
    unawaited(sora.readStats());
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) {
      setState(() {
        _list = [];
        _loaded = true;
      });
      return;
    }
    try {
      final answer = await link.stub.listConnections(
        ListConnectionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: session),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (!mounted) return;
      setState(() {
        // Show recent connections first to help locate newly opened traffic.
        _list = answer.connections.toList()..sort((a, b) => b.start.seconds.compareTo(a.start.seconds));
        SoraScope.read(context).recovered('connections');
        _loaded = true;
      });
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'connections');
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
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'connections');
    }
  }

  Future<void> _copyHost(Connection c) => Clipboard.setData(ClipboardData(text: c.host));

  void _addRule(Connection c) => addRuleSheet(context, initialDestination: c.host);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final query = _search.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? _list
        : [
            for (final c in _list)
              if ('${c.host} ${c.process} ${c.chain.join(' ')}'.toLowerCase().contains(query)) c,
          ];
    return Screen(
      title: s.connections,
      fill: !_loaded
          ? const SizedBox()
          : shown.isEmpty
          ? Center(
              child: Text(s.logsEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
            )
          : _grouped
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
            ),
      children: [
        _statsBar(context),
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
    final active = sora.stats?.activeConnections.toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              up == null || down == null ? '—' : '↑ ${_speed(s, up, locale)}  ↓ ${_speed(s, down, locale)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Styles.figures(Styles.body).copyWith(color: palette.ink),
            ),
          ),
          if (active != null)
            Text(s.connConnectionsCount(active), style: Styles.caption.copyWith(color: palette.ink2)),
        ],
      ),
    );
  }

  String _speed(S s, double bps, String locale) => '${formatBytes(s, Int64(bps.round()), locale)}/s';

  /// Groups connections by process, heaviest first, with collapsible headers.
  Widget _groupedList(List<Connection> shown) {
    final s = S.of(context);
    final groups = <String, List<Connection>>{};
    for (final c in shown) {
      groups.putIfAbsent(c.process.isEmpty ? '—' : c.process, () => []).add(c);
    }
    final keys = groups.keys.toList()..sort((a, b) => _traffic(groups[b]!).compareTo(_traffic(groups[a]!)));
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
              onToggle: () => setState(
                () => collapsed ? _collapsedGroups.remove(name) : _collapsedGroups.add(name),
              ),
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
              _menuItem(context, s.close, onClose),
              _menuItem(context, s.connCopyHost, onCopyHost),
              _menuItem(context, s.connAddRule, onAddRule),
            ],
            builder: (context, controller, _) => RoundButton(
              icon: Symbols.more_vert_rounded,
              label: s.more,
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
          RoundButton(icon: Symbols.close_rounded, label: s.close, onTap: onClose),
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
  _ => sora.displayNameOf(hop),
};
