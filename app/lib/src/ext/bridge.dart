/// WebView JS bridge for extension panels.
///
/// The panel page gets `window.soraExt` (see [PanelBridge.bootstrapJs]):
/// a promise-based `call(method, args)` plus `onEvent`. Every method is
/// allow-listed against the extension's granted permissions; anything else
/// rejects. The panel has no other way out: no Node, no dart:ffi, no
/// network from JS.
library;

import 'dart:async';
import 'dart:convert';

/// Method -> required permission. Absent = allowed for every panel
/// (the extension's own settings).
const Map<String, String> _methodPermission = {
  'getConnections': 'connections.read',
  'getServers': 'servers.read',
  'notify': 'notifications',
};

class BridgeError implements Exception {
  BridgeError(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'BridgeError($code): $message';
}

class PanelBridge {
  PanelBridge({
    required this.extensionId,
    required this.granted,
    required this.getConnections,
    required this.servers,
    required this.notify,
    required this.getSettings,
    required this.setSettings,
  });

  final String extensionId;
  final Set<String> granted;

  /// () -> [{id, process, host, up_bytes, down_bytes}]
  final Future<List<Map<String, dynamic>>> Function() getConnections;

  /// () -> [{id, name, protocol}]
  final List<Map<String, dynamic>> Function() servers;

  /// Shows a notification attributed to the extension.
  final Future<void> Function(String title, String body) notify;

  final Future<Map<String, dynamic>> Function() getSettings;
  final Future<void> Function(Map<String, dynamic>) setSettings;

  /// Handles one JSON message posted to the `soraExt` JavaScript channel.
  /// Always returns a JSON reply: {id, ok, result?} or {id, ok, error}.
  Future<String> handle(String raw) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return _reply(null, false, 'bad-request');
    }
    final msg = decoded as Map<String, dynamic>?;
    final id = msg?['id'];
    final method = msg?['method'] as String?;
    if (method == null) return _reply(id, false, 'bad-request');
    final need = _methodPermission[method];
    if (need != null && !granted.contains(need)) {
      return _reply(id, false, 'permission-denied');
    }
    final args = (msg?['args'] as Map<String, dynamic>?) ?? {};
    try {
      final result = await _dispatch(method, args);
      return _reply(id, true, null, result);
    } on BridgeError catch (e) {
      return _reply(id, false, e.code);
    } catch (_) {
      return _reply(id, false, 'internal');
    }
  }

  Future<dynamic> _dispatch(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getConnections':
        return await getConnections();
      case 'getServers':
        return servers();
      case 'notify':
        final title = (args['title'] as String? ?? '').trim();
        final body = (args['body'] as String? ?? '').trim();
        if (title.isEmpty || title.length > 120 || body.length > 500) {
          throw BridgeError('bad-args', 'bad notification text');
        }
        await notify(title, body);
        return null;
      case 'getSettings':
        return await getSettings();
      case 'setSettings':
        final values = (args['settings'] as Map<String, dynamic>?) ?? args;
        await setSettings(values);
        return null;
      default:
        throw BridgeError('unknown-method', 'unknown method $method');
    }
  }

  String _reply(dynamic id, bool ok, String? error, [dynamic result]) {
    return jsonEncode({
      'id': id,
      'ok': ok,
      if (error != null) 'error': error,
      if (ok) 'result': result,
    });
  }

  /// Injected into the panel before any page script runs. `soraExt` here is
  /// the JavaScriptChannel name registered on the WebView controller.
  static const String bootstrapJs = '''
window.soraExt = (() => {
  let seq = 0;
  const pending = {};
  const listeners = [];
  return {
    call(method, args) {
      return new Promise((resolve, reject) => {
        const id = ++seq;
        pending[id] = {resolve, reject};
        try {
          soraExt.postMessage(JSON.stringify({id, method, args: args || {}}));
        } catch (e) { delete pending[id]; reject(e); }
      });
    },
    onEvent(cb) { if (typeof cb === 'function') listeners.push(cb); },
    _resolve(id, ok, payload) {
      const p = pending[id];
      if (!p) return;
      delete pending[id];
      if (ok) p.resolve(payload); else p.reject(new Error(payload));
    },
    _event(kind, detail) {
      for (const cb of listeners) { try { cb(kind, detail); } catch (e) {} }
    }
  };
})();
''';
}
