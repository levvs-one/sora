import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'updates.dart' show appVersion;

/// Bounded metadata from the native browser; never retains response bodies.
class BrowserDiagnostics {
  final _entries = Queue<Map<String, Object?>>();
  final _pending = <String, Map<String, dynamic>>{};
  int _bytes = 0;
  int get length => _entries.length;

  static String _short(Object? value, [int limit = 2048]) {
    final text = value?.toString() ?? '';
    return text.length > limit ? text.substring(0, limit) : text;
  }

  static String _url(Object? value) {
    final uri = Uri.tryParse(_short(value));
    if (uri == null) return '';
    return uri
        .replace(
          userInfo: '',
          fragment: '',
          query: uri.hasQuery
              ? uri.queryParameters.keys.map((key) => '${Uri.encodeQueryComponent(key)}=[redacted]').join('&')
              : null,
        )
        .toString();
  }

  static List<Map<String, String>> _headers(Object? value) => value is Map
      ? value.entries
            .take(24)
            .map(
              (header) => {
                'name': _short(header.key, 128),
                'value':
                    const {
                      'authorization',
                      'proxy-authorization',
                      'cookie',
                      'set-cookie',
                    }.contains('${header.key}'.toLowerCase())
                    ? '[redacted]'
                    : _short(header.value, 512),
              },
            )
            .toList()
      : [];

  static Map<String, Object?> _request(Object? url, Object? method, Object? headers, [String protocol = '']) => {
    'method': _short(method, 16),
    'url': _url(url),
    'httpVersion': protocol,
    'headers': _headers(headers),
    'cookies': <Object>[],
    'queryString': <Object>[],
    'headersSize': -1,
    'bodySize': -1,
  };

  static Map<String, Object?> _response(Map<dynamic, dynamic> value) => {
    'status': (value['status'] as num?)?.toInt() ?? 0,
    'statusText': _short(value['statusText'], 128),
    'httpVersion': _short(value['protocol'], 32),
    'headers': _headers(value['headers']),
    'cookies': <Object>[],
    'content': {'size': (value['size'] as num?)?.toInt() ?? 0, 'mimeType': _short(value['mimeType'], 128)},
    'redirectURL': '',
    'headersSize': -1,
    'bodySize': -1,
  };

  void _add(
    DateTime started,
    num elapsed,
    Map<String, Object?> request,
    Map<String, Object?> response, {
    Object? error,
  }) {
    final entry = <String, Object?>{
      'startedDateTime': started.toUtc().toIso8601String(), 'time': elapsed < 0 ? 0 : elapsed,
      'request': request, 'response': response, 'cache': <String, Object>{},
      // HAR requires these three stages to be non-negative. Native WebKit
      // supplies only resource elapsed time, so display it as a single span.
      'timings': {'send': 0, 'wait': 0, 'receive': elapsed < 0 ? 0 : elapsed},
      'comment': 'Only total resource time is available; receive represents that entire observed span, not a transport-stage breakdown.',
      if (error != null) '_error': _short(error, 512),
    };
    final size = utf8.encode(jsonEncode(entry)).length;
    _entries.addLast(entry);
    _bytes += size;
    while (_entries.length > 500 || _bytes > 2 * 1024 * 1024) {
      _bytes -= utf8.encode(jsonEncode(_entries.removeFirst())).length;
    }
  }

  void webkit(Map<String, dynamic> event) {
    final started = event['started'];
    if (started is! int || event['url'] is! String || event['method'] is! String) return;
    _add(
      DateTime.fromMicrosecondsSinceEpoch(started, isUtc: true),
      (event['elapsed'] as num?) ?? 0,
      _request(event['url'], event['method'], event['requestHeaders']),
      _response(event),
      error: event['error'],
    );
  }

  void webview2(String owner, Map<String, dynamic> event) {
    final params = event['params'];
    if (params is! Map || params['requestId'] is! String) return;
    final key = '$owner:${params['requestId']}';
    switch (event['method']) {
      case 'Network.requestWillBeSent':
        if (params['redirectResponse'] case final Map<dynamic, dynamic> redirect) {
          final previous = _pending.remove(key);
          if (previous != null) _finish(previous, params['timestamp'], redirect);
        }
        final request = params['request'];
        if (request is! Map || params['wallTime'] is! num || params['timestamp'] is! num) return;
        _pending[key] = {
          'started': (params['wallTime'] as num).toDouble(),
          'timestamp': params['timestamp'],
          'clock': Stopwatch()..start(),
          'type': params['type'],
          'request': _request(request['url'], request['method'], request['headers']),
        };
        while (_pending.length > 256) {
          _pending.remove(_pending.keys.first);
        }
      case 'Network.responseReceived':
        final pending = _pending[key], response = params['response'];
        if (pending != null && response is Map) pending['response'] = _response(response);
      case 'Network.loadingFinished':
      case 'Network.loadingFailed':
        final pending = _pending.remove(key);
        if (pending != null) _finish(pending, params['timestamp'], null, error: params['errorText']);
    }
  }

  void _finish(Map<String, dynamic> pending, Object? timestamp, Map<dynamic, dynamic>? redirect, {Object? error}) {
    if (timestamp is! num || pending['timestamp'] is! num) return;
    final response = redirect == null ? pending['response'] : _response(redirect);
    // A failed request has no HTTP response. Status 0 is HAR's failure marker.
    if (response == null && error == null) return;
    _add(
      DateTime.fromMicrosecondsSinceEpoch(((pending['started'] as double) * 1000000).round(), isUtc: true),
      (timestamp - (pending['timestamp'] as num)) * 1000,
      pending['request'] as Map<String, Object?>,
      response as Map<String, Object?>? ?? _response({}),
      error: error,
    );
  }

  void completeNavigation(String owner, String url, {Object? error, Map<String, Object?>? response}) {
    for (final key in _pending.keys.where((key) => key.startsWith('$owner:')).toList()) {
      final pending = _pending[key]!;
      if (pending['type'] != 'Document' || (pending['request'] as Map)['url'] != _url(url)) continue;
      final clock = pending['clock'] as Stopwatch;
      _pending.remove(key);
      _finish(pending, (pending['timestamp'] as num) + clock.elapsedMicroseconds / 1000000, response, error: error);
    }
  }

  void detach(String owner) => _pending.removeWhere((key, _) => key.startsWith('$owner:'));
  void clear() {
    _entries.clear();
    _pending.clear();
    _bytes = 0;
  }

  Uint8List export() => Uint8List.fromList(
    utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'log': {
          'version': '1.2',
          'creator': {'name': 'Sora', 'version': appVersion},
          'entries': _entries.toList()
            ..sort((a, b) => (a['startedDateTime'] as String).compareTo(b['startedDateTime'] as String)),
          'comment': 'Native browser metadata only. Bodies, cookie values, authorization and query values are omitted. Unknown sizes use -1; timing spans show observed total resource time.',
        },
      }),
    ),
  );
}
