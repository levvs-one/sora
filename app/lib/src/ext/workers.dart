import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';

import '../core/link.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../generated/sora/ext/v1/ext_host.pbgrpc.dart';
import '../notifications.dart';
import '../sora.dart';
import 'bridge.dart';
import 'store.dart';

/// Owns lifecycle streams for the app's verified registry. The core schedules
/// work and isolates JS; every app API still goes through the panel bridge.
class ExtensionWorkers {
  ExtensionWorkers(this.sora) {
    sora.addListener(_changed);
    sora.extensions.addListener(_changed);
    _changed();
  }
  final Sora sora;
  final _running = <String, _WorkerStream>{};
  final _failedKeys = <String, String>{};
  CoreLink? _link;
  Future<void> _work = Future.value();
  bool _disposed = false;

  void _changed() {
    // Cancellation is synchronous at the registry boundary, before disk I/O
    // or a queued reconciliation can finish.
    for (final id in _running.keys.toList()) {
      if (!sora.extensions.isEnabled(id) || sora.link != _link) {
        unawaited(_running.remove(id)!.stop());
      }
    }
    _work = _work.then((_) => _sync()).catchError((Object error) {
      if (!_disposed) sora.reportFailure(error, source: 'extension-workers');
    });
  }

  Future<void> _sync() async {
    if (_disposed) return;
    final store = sora.extensions, link = sora.link;
    if (_link != link) _failedKeys.clear();
    _link = link;
    for (final inst in store.installed) {
      final task = inst.manifest.backgroundTask;
      if (!inst.enabled || task == null || !inst.granted.contains('background') || link == null) continue;
      final config = await store.getBackgroundTask(inst.id);
      final key = '${inst.version}:${jsonEncode(config.toJson())}:${inst.granted.join(',')}';
      final old = _running[inst.id];
      if (old?.key == key || _failedKeys[inst.id] == key) continue;
      await _running.remove(inst.id)?.stop();
      if (_disposed || !store.isEnabled(inst.id) || sora.link != link || !config.enabled) continue;
      try {
        final script = File('${store.contentDir(inst.id)}/${task.entry}');
        if (await script.length() > 1 << 20) throw const FormatException('worker exceeds 1 MiB');
        final source = await script.readAsString();
        if (_disposed || !store.isEnabled(inst.id) || sora.link != link) continue;
        final bridge = PanelBridge(
          extensionId: inst.id,
          granted: inst.granted.toSet(),
          getConnections: () async {
            final session = sora.sessionId;
            if (session == null) throw BridgeError('not-connected', 'no session');
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
          },
          servers: () => [
            for (final server in sora.servers)
              {'id': server.id, 'name': server.displayName, 'country': '', 'latency_ms': sora.latency[server.id] ?? -1},
          ],
          notify: (title, body) => sora.recordNotification(
            AppNotification(time: DateTime.now(), title: '${inst.manifest.name}: $title', body: body),
          ),
          getSettings: () => store.getSettings(inst.id),
          setSettings: (values) async {
            try {
              await store.setSettings(inst.id, values);
            } on ExtStoreError catch (e) {
              throw BridgeError('invalid-argument', e.message);
            }
          },
        );
        final manifest = inst.manifest.toJson()..['permissions'] = inst.granted;
        final worker = _WorkerStream(key);
        _running[inst.id] = worker;
        worker.start(
          link,
          WorkerClientMessage(
            controlToken: link.token,
            manifestJson: jsonEncode(manifest),
            source: source,
            configJson: jsonEncode(config.toJson()),
          ),
          (message) async {
            if (_disposed || !store.isEnabled(inst.id) || _running[inst.id] != worker) return;
            if (message.log.isNotEmpty) store.appendLog(inst.id, message.log);
            if (message.failed) await _failed(inst);
            if (message.callJson.isNotEmpty) {
              final reply = await bridge.handle(message.callJson);
              if (!worker.stopped && store.isEnabled(inst.id)) worker.input.add(WorkerClientMessage(replyJson: reply));
            }
          },
          (Object error) {
            if (!_disposed && !worker.stopped) {
              store.appendLog(inst.id, 'worker stream failed: $error');
              unawaited(_failed(inst));
            }
          },
        );
      } catch (error) {
        _failedKeys[inst.id] = key;
        store.appendLog(inst.id, 'worker rejected: $error');
        await _failed(inst);
      }
    }
  }

  Future<void> _failed(InstalledExtension inst) => sora.recordNotification(
    AppNotification(time: DateTime.now(), title: inst.manifest.name, body: sora.strings.extWorkerFailed),
  );

  void dispose() {
    _disposed = true;
    sora.removeListener(_changed);
    sora.extensions.removeListener(_changed);
    for (final worker in _running.values) {
      unawaited(worker.stop());
    }
    _running.clear();
  }
}

class _WorkerStream {
  _WorkerStream(this.key);
  final String key;
  final input = StreamController<WorkerClientMessage>();
  ResponseStream<WorkerHostMessage>? _call;
  StreamSubscription<WorkerHostMessage>? _subscription;
  bool stopped = false;

  void start(
    CoreLink link,
    WorkerClientMessage first,
    Future<void> Function(WorkerHostMessage) onData,
    void Function(Object) onError,
  ) {
    input.add(first);
    _call = link.extensions.runWorker(input.stream);
    _subscription = _call!.listen((message) {
      unawaited(onData(message).catchError(onError));
    }, onError: onError);
  }

  Future<void> stop() async {
    stopped = true;
    await _call?.cancel();
    await _subscription?.cancel();
    unawaited(input.close());
  }
}
