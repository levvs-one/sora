import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grpc/grpc.dart' show CallOptions, ResponseFuture;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../notifications.dart';
import '../sora.dart';
import 'kit.dart';

/// Streams core and engine logs, displaying newest entries first.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  /// Matches the core's maximum retention; widgets are still built lazily.
  static const _keep = 200000;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _center = UniqueKey();
  int _above = 0;
  LogLevel _level = LogLevel.LOG_LEVEL_DEBUG;
  String _section = 'all';
  List<LogEntry> _entries = [];
  StreamSubscription<LogEntry>? _watch;
  Timer? _debounce;
  bool _loaded = false;
  CoreLink? _link;
  int _revision = 0;
  Int64 _before = Int64.ZERO;
  bool _olderLoading = false;
  ResponseFuture<ExportDiagnosticsResponse>? _capture;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) unawaited(_older());
    });
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _reload);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final link = SoraScope.of(context).link;
    if (_link == link) return;
    _link = link;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _revision++;
    _debounce?.cancel();
    unawaited(_watch?.cancel());
    unawaited(_capture?.cancel());
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  LogFilter get _filter => LogFilter(
    minLevel: _level,
    contains: _search.text.trim(),
    sources: switch (_section) {
      'engine' => ['sing-box', 'xray', 'mihomo', 'zapret'],
      'subscriptions' => ['subscription'],
      'core' => ['core'],
      _ => [],
    },
    pattern: switch (_section) {
      'tun' => r'\b(tun|tunnel|adapter)\b|proxy/tun|inbound/tun',
      'dns' => r'\b(dns|doh|dot|resolver)\b',
      _ => '',
    },
  );

  Future<void> _reload() async {
    if (!mounted) return;
    final revision = ++_revision;
    final link = SoraScope.read(context).link;
    await _watch?.cancel();
    _watch = null;
    if (!mounted || revision != _revision) return;
    if (link == null) {
      return;
    }
    try {
      final page = await link.stub.queryLogs(
        QueryLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, filter: _filter, limit: 500),
      );
      if (page.hasError()) throw CoreFailure(page.error.userMessageKey);
      if (!mounted || revision != _revision || link != SoraScope.read(context).link) return;
      setState(() {
        _entries = page.entries.toList();
        _before = page.beforeSequence;
        _olderLoading = false;
        _above = 0;
        SoraScope.read(context).recovered('logs');
        _loaded = true;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
      final after = _entries.isEmpty ? null : _entries.first.sequence;
      _watch = link.stub
          .watchLogs(
            WatchLogsRequest(
              apiVersion: apiVersion,
              controlAuthenticator: link.token,
              filter: _filter,
              afterSequence: after,
            ),
          )
          .listen(
            (entry) {
              if (mounted && revision == _revision) _arrive(entry);
            },
            onError: (Object e) {
              if (mounted && revision == _revision) SoraScope.read(context).reportFailure(e, source: 'logs');
            },
          );
    } catch (error) {
      if (mounted && revision == _revision) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  Future<void> _older() async {
    if (_olderLoading || _before == Int64.ZERO || _link == null) return;
    final revision = _revision, link = _link!;
    _olderLoading = true;
    try {
      final page = await link.stub.queryLogs(
        QueryLogsRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          filter: _filter,
          beforeSequence: _before,
          limit: 500,
        ),
      );
      if (page.hasError()) throw CoreFailure(page.error.userMessageKey);
      if (!mounted || revision != _revision || _link != link) return;
      final known = _entries.map((e) => e.sequence).toSet();
      setState(() {
        _entries.addAll(page.entries.where((e) => !known.contains(e.sequence)));
        _before = page.beforeSequence;
      });
    } catch (error) {
      if (mounted && revision == _revision) SoraScope.read(context).reportFailure(error, source: 'logs');
    } finally {
      if (revision == _revision) _olderLoading = false;
    }
  }

  String _filename(String extension, [DateTime? at]) =>
      'sora-log_${_section}_${DateFormat('dd_MM_yyyy').format(at ?? DateTime.now())}.$extension';

  void _arrive(LogEntry entry) {
    final atTop = !_scroll.hasClients || _scroll.position.pixels <= _scroll.position.minScrollExtent + 1;
    setState(() {
      if (atTop) _above = 0;
      // Repeated messages retain their sequence number and update the repeat
      // count.
      final index = _entries.indexWhere((e) => e.sequence == entry.sequence);
      if (index >= 0) {
        _entries[index] = entry;
      } else {
        _entries.insert(0, entry);
        if (_entries.length > _keep) _entries.removeLast();
        // New entries grow above the viewport anchor while older text is read.
        _above = atTop ? 0 : (_above + 1).clamp(0, _entries.length);
      }
    });
    if (atTop && _scroll.hasClients && _scroll.offset != 0) _scroll.jumpTo(0);
  }

  Future<void> _export(LogExportFormat format, String extension) async {
    if (!mounted) return;
    final link = SoraScope.read(context).link;
    if (link == null) return;
    if (!SoraScope.read(context).coreCapabilities.contains('log-export-formats') &&
        !const [
          LogExportFormat.LOG_EXPORT_FORMAT_UNSPECIFIED,
          LogExportFormat.LOG_EXPORT_FORMAT_JSON_LINES,
          LogExportFormat.LOG_EXPORT_FORMAT_CSV,
        ].contains(format)) {
      SoraScope.read(context).reportFailure(const CoreFailure('core.api.version_mismatch'), source: 'logs');
      return;
    }
    final name = _filename(extension);
    final filter = _filter, category = _section;
    try {
      final answer = await link.stub.exportLogs(
        ExportLogsRequest(
          apiVersion: apiVersion,
          controlAuthenticator: link.token,
          filter: filter,
          format: format,
          category: category,
        ),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (!mounted) return;
      final place = await getSaveLocation(suggestedName: name);
      if (place == null) return;
      await File(place.path).writeAsBytes(answer.data, flush: true);
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  Future<void> _clear() async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.clearLogs(
        ClearLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      if (mounted) {
        setState(() {
          _entries = [];
          _above = 0;
          _before = Int64.ZERO;
        });
      }
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'logs');
    }
  }

  Future<void> _diagnostic(String extension) async {
    if (!mounted) return;
    final sora = SoraScope.read(context), s = S.of(context);
    final name =
        'sora-log_${switch (extension) {
          'har' => 'http',
          'pcapng' => 'packets',
          _ => 'windows-events',
        }}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.$extension';
    ResponseFuture<ExportDiagnosticsResponse>? request;
    try {
      List<int> data;
      if (extension == 'har') {
        if (sora.browserDiagnostics.length == 0) {
          await sora.recordNotification(
            AppNotification(
              time: DateTime.now(),
              title: s.diagnosticHttp,
              body: s.diagnosticNoData,
              action: 'speedtest',
            ),
          );
          return;
        }
        data = sora.browserDiagnostics.export();
      } else {
        final link = sora.link;
        if (link == null || _capture != null) return;
        if (!sora.coreCapabilities.contains('native-diagnostics')) throw const CoreFailure('core.api.version_mismatch');
        if (extension == 'evtx' && !Platform.isWindows) {
          await sora.recordNotification(
            AppNotification(time: DateTime.now(), title: s.diagnosticEvents, body: s.diagnosticUnavailable),
          );
          return;
        }
        if (extension == 'pcapng' && (sora.phase != Phase.connected || sora.settings.tunnel != 'tun')) {
          await sora.recordNotification(
            AppNotification(time: DateTime.now(), title: s.diagnosticPackets, body: s.diagnosticRequiresTun),
          );
          return;
        }
        request = link.stub.exportDiagnostics(
          ExportDiagnosticsRequest(
            apiVersion: apiVersion,
            controlAuthenticator: link.token,
            sessionId: sora.sessionId,
            format: extension == 'pcapng'
                ? DiagnosticFormat.DIAGNOSTIC_FORMAT_PCAPNG
                : DiagnosticFormat.DIAGNOSTIC_FORMAT_EVTX,
          ),
          options: CallOptions(timeout: const Duration(seconds: 30)),
        );
        setState(() {
          _capture = request;
        });
        final answer = await request;
        if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
        data = answer.archive;
        if (!mounted || _capture != request) return;
      }
      if (!mounted) return;
      final place = await getSaveLocation(suggestedName: name);
      if (place != null) await File(place.path).writeAsBytes(data, flush: true);
    } catch (error) {
      if (mounted && (request == null || _capture == request)) sora.reportFailure(error, source: 'diagnostics');
    } finally {
      if (mounted && _capture == request) setState(() => _capture = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.logs,
      actions: [
        if (_capture != null) ...[
          CupertinoActivityIndicator(color: palette.ink),
          RoundButton(
            icon: Symbols.close_rounded,
            label: s.cancel,
            onTap: () {
              final capture = _capture;
              setState(() => _capture = null);
              unawaited(capture?.cancel());
            },
          ),
        ],
        MenuAnchor(
          onOpen: () => setState(() {}),
          alignmentOffset: const Offset(-150, 4),
          menuChildren: [
            for (final (format, extension) in [
              (LogExportFormat.LOG_EXPORT_FORMAT_LOG, 'log'),
              (LogExportFormat.LOG_EXPORT_FORMAT_UNSPECIFIED, 'txt'),
              (LogExportFormat.LOG_EXPORT_FORMAT_JSON, 'json'),
              (LogExportFormat.LOG_EXPORT_FORMAT_JSON_LINES, 'jsonl'),
              (LogExportFormat.LOG_EXPORT_FORMAT_CSV, 'csv'),
              (LogExportFormat.LOG_EXPORT_FORMAT_XML, 'xml'),
              (LogExportFormat.LOG_EXPORT_FORMAT_ZIP, 'zip'),
              (LogExportFormat.LOG_EXPORT_FORMAT_GZIP, 'gz'),
            ])
              MenuItemButton(
                onPressed: () => unawaited(_export(format, extension)),
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(190, 40)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                  overlayColor: WidgetStatePropertyAll(palette.hover),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                ),
                child: Text(
                  s.exportLogFile(_filename(extension)),
                  style: Styles.secondary.copyWith(color: palette.ink),
                ),
              ),
            const Divider(height: 12),
            for (final (extension, label, icon) in [
              ('har', s.diagnosticHttp, Symbols.language_rounded),
              ('pcapng', s.diagnosticPackets, Symbols.network_check_rounded),
              if (Platform.isWindows) ('evtx', s.diagnosticEvents, Symbols.article_rounded),
            ])
              MenuItemButton(
                onPressed: _capture == null ? () => unawaited(_diagnostic(extension)) : null,
                leadingIcon: Icon(icon, size: 18, color: palette.ink),
                child: Tooltip(
                  message: extension == 'pcapng' ? '${s.diagnosticPackets}: ${s.diagnosticCapture}' : label,
                  child: Text(
                    s.exportLogFile(
                      'sora-log_${switch (extension) {
                        'har' => 'http',
                        'pcapng' => 'packets',
                        _ => 'windows-events',
                      }}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.$extension',
                    ),
                    style: Styles.secondary.copyWith(color: palette.ink),
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) => RoundButton(
            icon: Symbols.ios_share_rounded,
            label: s.export,
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
        const SizedBox(width: 4),
        RoundButton(icon: Symbols.delete_rounded, label: s.clear, onTap: () => unawaited(_clear())),
      ],
      fill: !_loaded
          ? Center(
              child: _link == null
                  ? Text(s.coreMissing, style: Styles.secondary.copyWith(color: palette.ink))
                  : CupertinoActivityIndicator(color: palette.ink),
            )
          : _entries.isEmpty
          ? Center(
              child: Text(s.logsEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
            )
          : SelectionArea(
              child: CustomScrollView(
                controller: _scroll,
                center: _center,
                slivers: [
                  SliverList.builder(
                    itemCount: _above,
                    itemBuilder: (context, i) =>
                        _Entry(key: ValueKey(_entries[_above - i - 1].sequence), entry: _entries[_above - i - 1]),
                  ),
                  SliverList.builder(
                    key: _center,
                    itemCount: _entries.length - _above,
                    itemBuilder: (context, i) =>
                        _Entry(key: ValueKey(_entries[_above + i].sequence), entry: _entries[_above + i]),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
      children: [
        Segments<LogLevel>(
          value: _level,
          choices: {
            LogLevel.LOG_LEVEL_DEBUG: s.logsAll,
            LogLevel.LOG_LEVEL_WARNING: s.logsImportant,
            LogLevel.LOG_LEVEL_ERROR: s.logsErrors,
          },
          onChanged: (level) {
            setState(() => _level = level);
            unawaited(_reload());
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final category in {
              'all': s.logsAll,
              'engine': s.engine,
              'tun': 'TUN',
              'dns': 'DNS',
              'subscriptions': s.subscriptions,
              'core': 'SoraCore',
            }.entries)
              ChoiceChip(
                key: ValueKey('logs-section-${category.key}'),
                label: Text(category.value, style: Styles.secondary.copyWith(color: palette.ink)),
                selected: _section == category.key,
                showCheckmark: false,
                selectedColor: palette.field,
                backgroundColor: palette.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (selected) {
                  setState(() => _section = selected ? category.key : 'all');
                  unawaited(_reload());
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({super.key, required this.entry});

  final LogEntry entry;

  static final _time = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final color = switch (entry.level) {
      LogLevel.LOG_LEVEL_ERROR => palette.ink,
      LogLevel.LOG_LEVEL_WARNING => palette.ink,
      _ => palette.ink2,
    };
    final meta = [
      _time.format(entry.time.toDateTime().toLocal()),
      entry.source,
      if (entry.repeat > 1) '×${entry.repeat}',
    ].join('  ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta, style: Styles.figures(Styles.caption).copyWith(color: palette.ink)),
          const SizedBox(height: 2),
          Text(entry.message, style: Styles.secondary.copyWith(color: color)),
        ],
      ),
    );
  }
}
