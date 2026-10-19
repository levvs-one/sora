/// Extension panel host: a WebView showing one extension panel.
///
/// The panel directory is served over a loopback HTTP server (127.0.0.1,
/// ephemeral port) so relative asset paths resolve on every platform and
/// `file://` quirks are avoided. Navigation is locked to that origin.
/// The page gets `window.soraExt` (see [PanelBridge.bootstrapJs]); the
/// `soraExt` JavaScript channel is the panel's only way out.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../kit.dart';
import '../sora.dart';
import '../../ext/bridge.dart';
import '../../ext/manifest.dart';
import '../../ext/store.dart';
import '../../notifications.dart';
import '../../core/link.dart';
import '../../generated/sora/core/v1/core_control.pbgrpc.dart';

/// Serves one directory over loopback HTTP. Bound to 127.0.0.1 with an
/// ephemeral port; shut down when the panel closes.
///
/// The panel entry HTML gets the soraExt bootstrap injected right after
/// <head>, so `window.soraExt` exists before any page script runs.
class _LocalPanelServer {
  _LocalPanelServer(this.root, {required this.entry, required this.bootstrap});
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
      var path = req.uri.path;
      if (path == '/' || path.isEmpty) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final file = File('$root${path.replaceAll('/', Platform.pathSeparator)}');
      final canonical = file.absolute.path;
      final rootCanonical = Directory(root).absolute.path;
      if (!canonical.startsWith('$rootCanonical${Platform.pathSeparator}')) {
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
    final want = File('$root${entry.replaceAll('/', Platform.pathSeparator)}').absolute.path;
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
  _LocalPanelServer? _server;
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
        : _manifest.panels.firstWhere((p) => p.id == widget.panelId,
            orElse: () => _manifest.panels.first);
    _bridge = PanelBridge(
      extensionId: widget.extensionId,
      granted: inst.granted.toSet(),
      getConnections: _getConnections,
      servers: _servers,
      notify: _notify,
      getSettings: () => store.getSettings(widget.extensionId),
      setSettings: (v) => store.setSettings(widget.extensionId, v),
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
    _controller?.clearCache();
    unawaited(_server?.stop());
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getConnections() async {
    final sora = SoraScope.read(context);
    final link = sora.link, session = sora.sessionId;
    if (link == null || session == null) throw BridgeError('not-connected', 'no session');
    final answer = await link.stub.listConnections(
      ListConnectionsRequest(
          apiVersion: apiVersion, controlAuthenticator: link.token, sessionId: session),
    );
    return [
      for (final c in answer.connections)
        {
          'id': c.id,
          'process': c.process,
          'host': c.host,
          'up_bytes': c.upload.toInt(),
          'down_bytes': c.download.toInt(),
        }
    ];
  }

  List<Map<String, dynamic>> _servers() {
    final sora = SoraScope.read(context);
    return [
      for (final s in sora.servers)
        {'id': s.id, 'name': s.displayName, 'protocol': s.protocol}
    ];
  }

  Future<void> _notify(String title, String body) async {
    final sora = SoraScope.read(context);
    await sora.recordNotification(AppNotification(
      time: DateTime.now(),
      title: '${_manifest.name}: $title',
      body: body,
    ));
  }

  Future<void> _start() async {
    if (_starting || !mounted || _failure != null) return;
    _starting = true;
    final generation = ++_generation;
    try {
      final store = ExtScope.of(context);
      final dir = store.contentDir(widget.extensionId);
      if (dir.isEmpty) throw StateError('gone');
      _server = _LocalPanelServer(dir, entry: _panel.entry, bootstrap: PanelBridge.bootstrapJs);
      _origin = await _server!.start();
      if (!mounted || generation != _generation) return;
      final controller = _controller ??= WebViewPlatform.instance is LinuxWebViewPlatform
          ? WebViewController.fromPlatformCreationParams(
              const LinuxWebViewControllerCreationParams(
                pageCacheEnabled: false,
                mediaPlaybackRequiresUserGesture: true,
                javascriptCanOpenWindowsAutomatically: false,
              ),
            )
          : WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      if (!mounted || generation != _generation) return;
      await controller.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          final ok = uri != null &&
              uri.scheme == 'http' &&
              uri.host == '127.0.0.1' &&
              uri.port == _origin!.port;
          return ok ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
        onPageFinished: (url) async {
          if (!mounted || generation != _generation) return;
          // The bootstrap is injected by the local server, so window.soraExt
          // already exists; just announce readiness.
          await _pushEvent('panel.ready', '');
        },
      ));
      if (!mounted || generation != _generation) return;
      await controller.addJavaScriptChannel('soraExt',
          onMessageReceived: (message) async {
        if (!mounted || generation != _generation) return;
        String reply;
        try {
          reply = await _bridge.handle(message.message);
        } catch (_) {
          reply = '{"ok":false,"error":"internal"}';
        }
        dynamic decoded;
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
              'window.soraExt && window.soraExt._resolve(${jsonEncode(id)}, ${ok ? 'true' : 'false'}, ${jsonEncode(payload)})');
        } catch (_) {}
      });
      if (!mounted || generation != _generation) return;
      await controller.loadRequest(_origin!.resolve(_panel.entry));
      _watchSora();
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failure = 'load');
      }
    } finally {
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
      await c.runJavaScript(
          'window.soraExt && window.soraExt._event(${jsonEncode(kind)}, ${jsonEncode(detail)})');
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
                  Text(s.extPanelUnavailable,
                      style: Styles.body.copyWith(color: palette.ink2),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _controller!),
    );
  }
}
