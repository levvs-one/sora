import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'sync_api.dart';

/// Lifecycle states of the sora-sync device-sync daemon.
enum SyncDaemonState {
  /// Not started yet.
  idle,

  /// Binary found; spawning and waiting for the HTTP API.
  starting,

  /// The HTTP API answered the health check; [SyncDaemon.client] is usable.
  running,

  /// The daemon cannot run here (Android, or the binary is missing).
  /// Terminal for the session: the screen reports it honestly instead of
  /// faking sync.
  unavailable,

  /// The binary exists but failed to start or answer. Retryable.
  failed,
}

/// Why the daemon is [SyncDaemonState.unavailable].
enum SyncDaemonUnavailableReason {
  /// Android cannot spawn the Go binary as a child process (contract §5).
  android,

  /// No sora-sync binary was found for this platform.
  binaryMissing,
}

/// Thrown when the daemon cannot be started or health-checked. [message]
/// names the failing step; the sync screen shows it as the error detail.
class SyncDaemonException implements Exception {
  SyncDaemonException(this.message);

  final String message;

  @override
  String toString() => 'SyncDaemonException: $message';
}

/// Owns the sora-sync device-sync daemon process.
///
/// The daemon is a separate Go service (`service/sync`, binary `sora-sync`).
/// The app resolves the binary per platform, spawns it on demand with
/// `--data-dir`, waits for `<dataDir>/http_addr`, reads the bearer token
/// from `<dataDir>/api_token`, and health-checks `GET /v1/status` before
/// declaring it running. Exactly one daemon runs per data directory: a
/// `http_addr` whose `/v1/status` answers with the stored token is reused
/// instead of spawning a second process.
///
/// The daemon is stopped when the app quits (SIGTERM, wait, then SIGKILL).
/// A daemon this run did not spawn (reused from a previous run) is left
/// alone — its owner manages it.
///
/// Status (2026-10-20): wired — the sync screen drives pairing, peers and
/// sync through [SyncApiClient], and the app-to-daemon document bridge
/// (`sync_docs.dart`, contract §4) publishes application documents before
/// every sync and applies the pulled ones after it.
class SyncDaemon extends ChangeNotifier {
  SyncDaemonState _state = SyncDaemonState.idle;

  /// Current lifecycle state; notifies listeners on change.
  SyncDaemonState get state => _state;

  SyncDaemonUnavailableReason? _unavailableReason;

  /// Set when [state] is [SyncDaemonState.unavailable].
  SyncDaemonUnavailableReason? get unavailableReason => _unavailableReason;

  String? _errorDetail;

  /// Detail for [SyncDaemonState.failed]: the failing step or the daemon's
  /// stderr tail. Shown verbatim on the sync screen.
  String? get errorDetail => _errorDetail;

  SyncApiClient? _client;

  /// Authenticated API client; non-null only when [state] is running.
  SyncApiClient? get client => _client;

  Process? _process;
  bool _spawnedByUs = false;
  Future<void>? _startWork;

  /// How long to wait for the daemon to publish `<dataDir>/http_addr`.
  static const addrTimeout = Duration(seconds: 10);

  /// How long `stop()` waits for graceful shutdown before SIGKILL.
  static const stopGrace = Duration(seconds: 5);

  void _setState(SyncDaemonState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  /// Resolves the sora-sync binary for this platform, or null when absent.
  /// Linux: `/usr/bin/sora-sync` from the package; Windows: next to the app
  /// executable. Android cannot spawn it (contract §5).
  static String? resolveBinary() {
    if (Platform.isAndroid) return null;
    if (Platform.isWindows) {
      final exe = Platform.resolvedExecutable;
      final sep = exe.lastIndexOf('\\');
      final dir = sep >= 0 ? exe.substring(0, sep) : '.';
      final candidate = '$dir\\sora-sync.exe';
      return File(candidate).existsSync() ? candidate : null;
    }
    if (Platform.isLinux) {
      const candidate = '/usr/bin/sora-sync';
      return File(candidate).existsSync() ? candidate : null;
    }
    return null;
  }

  /// Starts the daemon if needed. Safe to call repeatedly and concurrently;
  /// concurrent callers share one start attempt.
  Future<void> ensureRunning() {
    if (_state == SyncDaemonState.running || _state == SyncDaemonState.unavailable) {
      return Future.value();
    }
    return _startWork ??= _start().whenComplete(() => _startWork = null);
  }

  Future<void> _start() async {
    _errorDetail = null;
    if (Platform.isAndroid) {
      _unavailableReason = SyncDaemonUnavailableReason.android;
      _setState(SyncDaemonState.unavailable);
      return;
    }
    final binary = resolveBinary();
    if (binary == null) {
      _unavailableReason = SyncDaemonUnavailableReason.binaryMissing;
      _setState(SyncDaemonState.unavailable);
      return;
    }
    _setState(SyncDaemonState.starting);
    final dir = Directory(syncDaemonDataDir());
    try {
      await dir.create(recursive: true);
      final reused = await _tryReuse(dir);
      final String addr;
      final String token;
      if (reused != null) {
        addr = reused.addr;
        token = reused.token;
      } else {
        final spawned = await _spawn(binary, dir);
        addr = spawned.addr;
        token = spawned.token;
      }
      _client = SyncApiClient(baseUrl: 'http://$addr', token: token);
      _setState(SyncDaemonState.running);
    } on SyncDaemonException catch (e) {
      await _killSpawned();
      _client?.close();
      _client = null;
      _errorDetail = e.message;
      _setState(SyncDaemonState.failed);
    } catch (e) {
      await _killSpawned();
      _client?.close();
      _client = null;
      _errorDetail = '$e';
      _setState(SyncDaemonState.failed);
    }
  }

  /// Reuses a live daemon when `<dataDir>/http_addr` answers the
  /// token-authenticated `/v1/status`. A 200 with our bearer token proves
  /// the address is ours and alive; a stale file alone proves nothing.
  Future<({String addr, String token})?> _tryReuse(Directory dir) async {
    final addrFile = File('${dir.path}${Platform.pathSeparator}http_addr');
    final tokenFile = File('${dir.path}${Platform.pathSeparator}api_token');
    if (!await addrFile.exists() || !await tokenFile.exists()) return null;
    final addr = (await addrFile.readAsString()).trim();
    final token = (await tokenFile.readAsString()).trim();
    if (addr.isEmpty || token.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('http://$addr/v1/status'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) return (addr: addr, token: token);
    } catch (_) {
      // Not ours or not alive: fall through and spawn a fresh daemon.
    }
    return null;
  }

  /// Spawns the daemon and waits for it to publish its HTTP address, then
  /// health-checks the API before returning.
  Future<({String addr, String token})> _spawn(String binary, Directory dir) async {
    final stderrTail = <String>[];
    final Process process;
    try {
      process = await Process.start(binary, ['--data-dir', dir.path]);
    } catch (e) {
      throw SyncDaemonException('could not launch sora-sync: $e');
    }
    _process = process;
    _spawnedByUs = true;
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(stderrTail.add);
    // Drain stdout so the daemon never blocks on a full pipe.
    unawaited(process.stdout.drain<List<int>>());
    var exited = false;
    int? exitCode;
    unawaited(
      process.exitCode.then((code) {
        exited = true;
        exitCode = code;
      }),
    );

    final addrFile = File('${dir.path}${Platform.pathSeparator}http_addr');
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < addrTimeout) {
      if (exited) {
        final tail = stderrTail.length > 5 ? stderrTail.sublist(stderrTail.length - 5) : stderrTail;
        final detail = tail.join(' ').trim();
        throw SyncDaemonException(
          'sora-sync exited during startup (code $exitCode)${detail.isEmpty ? '' : ': $detail'}',
        );
      }
      if (await addrFile.exists()) {
        final addr = (await addrFile.readAsString()).trim();
        if (addr.isNotEmpty) {
          final token = await _readToken(dir);
          await _healthCheck(addr, token);
          return (addr: addr, token: token);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final tail = stderrTail.length > 5 ? stderrTail.sublist(stderrTail.length - 5) : stderrTail;
    final detail = tail.join(' ').trim();
    throw SyncDaemonException(
      'sora-sync did not publish its address within ${addrTimeout.inSeconds}s'
      '${detail.isEmpty ? '' : ': $detail'}',
    );
  }

  Future<String> _readToken(Directory dir) async {
    final tokenFile = File('${dir.path}${Platform.pathSeparator}api_token');
    if (!await tokenFile.exists()) {
      throw SyncDaemonException('sora-sync published an address but no API token');
    }
    final token = (await tokenFile.readAsString()).trim();
    if (token.isEmpty) throw SyncDaemonException('sora-sync published an empty API token');
    return token;
  }

  Future<void> _healthCheck(String addr, String token) async {
    try {
      final res = await http
          .get(Uri.parse('http://$addr/v1/status'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        throw SyncDaemonException('sora-sync health check failed: HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (e is SyncDaemonException) rethrow;
      throw SyncDaemonException('sora-sync health check failed: $e');
    }
  }

  Future<void> _killSpawned() async {
    final process = _process;
    _process = null;
    _spawnedByUs = false;
    if (process == null) return;
    process.kill(ProcessSignal.sigkill);
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      // The process is already being reaped; nothing more to do.
    }
  }

  /// Stops the daemon this run spawned: SIGTERM, wait [stopGrace], then
  /// SIGKILL. A reused daemon (not spawned by this run) is left alone.
  Future<void> stop() async {
    final process = _process;
    final spawned = _spawnedByUs;
    _process = null;
    _spawnedByUs = false;
    _client?.close();
    _client = null;
    _setState(SyncDaemonState.idle);
    if (process == null || !spawned) return;
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(stopGrace);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
  }
}

/// Per-user data directory for the sora-sync daemon, next to the app's
/// other data (mirrors the extensions directory layout).
String syncDaemonDataDir() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\sora\\sync';
    }
  }
  final home = Platform.environment['HOME'];
  final xdg = Platform.environment['XDG_DATA_HOME'];
  final base = (xdg != null && xdg.isNotEmpty)
      ? xdg
      : (home != null && home.isNotEmpty ? '$home/.local/share' : Directory.systemTemp.path);
  return '$base/sora/sync';
}
