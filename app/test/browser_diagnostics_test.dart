import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/browser_diagnostics.dart';

void main() {
  test('native browser events produce HAR metadata with credentials removed', () {
    final diagnostics = BrowserDiagnostics();
    diagnostics.webkit({
      'started': DateTime.utc(2026, 10, 10).microsecondsSinceEpoch,
      'elapsed': 23.5,
      'url': 'https://user:secret@example.com/endpoint?token=secret#fragment',
      'method': 'POST',
      'status': 404,
      'requestHeaders': {'Authorization': 'Bearer secret', 'Cookie': 'session=secret'},
      'headers': {'Set-Cookie': 'session=secret', 'Content-Type': 'text/plain'},
      'mimeType': 'text/plain',
      'size': 12,
    });
    final text = utf8.decode(diagnostics.export());
    expect(text, isNot(contains('secret')));
    final log = (jsonDecode(text) as Map)['log'] as Map;
    expect(log['version'], '1.2');
    final entry = (log['entries'] as List).single as Map;
    expect((entry['request'] as Map)['method'], 'POST');
    expect((entry['response'] as Map)['status'], 404);
    expect(entry['time'], 23.5);
    expect((entry['timings'] as Map).values.cast<num>().reduce((a, b) => a + b), entry['time']);
  });

  test('WebView2 records redirects, actual responses and transport failures', () {
    final diagnostics = BrowserDiagnostics();
    void event(String method, Map<String, Object> params) => diagnostics.webview2('one', {
      'method': method,
      'params': {'requestId': 'request', ...params},
    });
    Map<String, Object> request(String url, num time) => {
      'wallTime': 1000000000 + time,
      'timestamp': time,
      'request': {'url': url, 'method': 'GET', 'headers': <String, String>{}},
    };
    event('Network.requestWillBeSent', request('https://example.com/', 1));
    event('Network.requestWillBeSent', {
      ...request('https://example.com/final', 2),
      'redirectResponse': {'status': 302, 'mimeType': 'text/html'},
    });
    event('Network.responseReceived', {
      'response': {'status': 200, 'mimeType': 'text/html', 'protocol': 'h2'},
    });
    event('Network.loadingFinished', {'timestamp': 3});
    event('Network.requestWillBeSent', request('https://example.com/fail', 4));
    event('Network.loadingFailed', {'timestamp': 4.5, 'errorText': 'net::ERR_CONNECTION_RESET'});
    final entries = (((jsonDecode(utf8.decode(diagnostics.export())) as Map)['log'] as Map)['entries'] as List)
        .cast<Map<dynamic, dynamic>>();
    expect(entries.map((e) => (e['response'] as Map)['status']), [302, 200, 0]);
    expect(entries.last['_error'], 'net::ERR_CONNECTION_RESET');
    expect(entries.map((e) => e['time']), [1000, 1000, 500]);
  });

  test('history stays bounded and detached controllers leave no pending requests', () {
    final diagnostics = BrowserDiagnostics();
    for (var i = 0; i < 1000; i++) {
      diagnostics.webkit({
        'started': 1000000 + i,
        'elapsed': 1,
        'url': 'https://example.com/$i',
        'method': 'GET',
        'status': 200,
      });
    }
    expect(diagnostics.length, 500);
    expect(diagnostics.export().length, lessThan(3 * 1024 * 1024));
    diagnostics.webview2('gone', {
      'method': 'Network.requestWillBeSent',
      'params': {
        'requestId': 'one',
        'wallTime': 1,
        'timestamp': 1,
        'request': {'url': 'https://example.com/pending', 'method': 'GET'},
      },
    });
    diagnostics.detach('gone');
    diagnostics.webview2('gone', {
      'method': 'Network.loadingFailed',
      'params': {'requestId': 'one', 'timestamp': 2, 'errorText': 'closed'},
    });
    expect(diagnostics.length, 500);
    diagnostics.clear();
    expect(diagnostics.length, 0);
  });
}
