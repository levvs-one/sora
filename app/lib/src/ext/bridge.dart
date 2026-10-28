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
  static const channelName = 'SoraExtHost';
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

  /// () -> [{id, name, country, latency_ms}], the documented panel API
  /// shape (docs/extensions-api.md); country is '' and latency_ms is -1
  /// when the app has no value for them, never an invented one.
  final List<Map<String, dynamic>> Function() servers;

  /// Shows a notification attributed to the extension.
  final Future<void> Function(String title, String body) notify;

  final Future<Map<String, dynamic>> Function() getSettings;

  /// Writes settings (merge semantics: unmentioned keys keep their
  /// values). Implementations must surface a schema rejection as
  /// BridgeError('invalid-argument', ...), the documented error
  /// contract, not as a bare store error, which [handle] would report
  /// to the panel as 'internal'.
  final Future<void> Function(Map<String, dynamic>) setSettings;

  /// Handles one JSON message posted to the internal native JavaScript channel.
  /// Always returns a JSON reply: {id, ok, result?} or {id, ok, error}.
  Future<String> handle(String raw) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return _reply(null, false, 'invalid-argument');
    }
    if (decoded is! Map<String, dynamic>) return _reply(null, false, 'invalid-argument');
    final msg = decoded;
    final id = msg['id'];
    final method = msg['method'];
    if (method is! String) return _reply(id, false, 'invalid-argument');
    final rawArgs = msg['args'];
    if (rawArgs != null && rawArgs is! Map<String, dynamic>) return _reply(id, false, 'invalid-argument');
    final need = _methodPermission[method];
    if (need != null && !granted.contains(need)) {
      return _reply(id, false, 'permission-denied');
    }
    final args = (rawArgs as Map<String, dynamic>?) ?? {};
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
          throw BridgeError('invalid-argument', 'bad notification text');
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
        throw BridgeError('invalid-argument', 'unknown method $method');
    }
  }

  /// Machine-readable error codes, matching sora-ext.d.ts SoraExtErrorCode
  /// and the mock (sora-ext serve): 'permission-denied' (the extension was
  /// not granted the method's permission), 'invalid-argument' (malformed
  /// message, unknown method, bad args), 'not-connected' (getConnections
  /// with no VPN session up), 'internal' (the host could not complete the
  /// call). The JS shim rejects with an Error carrying the code on
  /// `.code`, so `catch (e) { e.code }` works identically against the real
  /// host and the mock.
  String _reply(dynamic id, bool ok, String? error, [dynamic result]) {
    return jsonEncode({'id': id, 'ok': ok, 'error': ?error, if (ok) 'result': result});
  }

  /// Capture the private native channel before exposing the public panel API.
  /// Sharing its name with window.soraExt would overwrite postMessage.
  static const String bootstrapJs =
      '''
window.soraExt = ((nativeHost) => {
  let seq = 0;
  const pending = {};
  const listeners = [];
  return {
    call(method, args) {
      return new Promise((resolve, reject) => {
        const id = ++seq;
        pending[id] = {resolve, reject};
        try {
          nativeHost.postMessage(JSON.stringify({id, method, args: args || {}}));
        } catch (_) {
          delete pending[id];
          const error = new Error('Extension host unavailable');
          error.code = 'internal';
          reject(error);
        }
      });
    },
    onEvent(cb) {
      if (typeof cb !== 'function') throw new TypeError('onEvent callback must be a function');
      listeners.push(cb);
      return () => {
        const i = listeners.indexOf(cb);
        if (i >= 0) listeners.splice(i, 1);
      };
    },
    _resolve(id, ok, payload) {
      const p = pending[id];
      if (!p) return;
      delete pending[id];
      if (ok) {
        p.resolve(payload);
      } else {
        // The documented contract (sora-ext.d.ts): rejections are
        // SoraExtError-shaped: an Error whose `code` is the stable
        // machine-readable code, exactly like the mock's deny(). The
        // payload here IS the code the host sent.
        const e = new Error(payload);
        e.code = payload;
        p.reject(e);
      }
    },
    _event(kind, detail) {
      for (const cb of listeners) { try { cb(kind, detail); } catch (e) {} }
    }
  };
})(window.$channelName);
''';
}
