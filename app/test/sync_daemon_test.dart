import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/sync_daemon.dart';

void main() {
  late Directory binaries;
  late String binary;
  setUpAll(() async {
    binaries = await Directory.systemTemp.createTemp('sora-syncfix-bin-');
    binary = '${binaries.path}/sora-sync';
    final build = await Process.run('go', [
      'build',
      '-o',
      binary,
      './cmd/sora-sync',
    ], workingDirectory: '../service/sync');
    expect(build.exitCode, 0, reason: '${build.stdout}\n${build.stderr}');
  });
  tearDownAll(() async => binaries.delete(recursive: true));

  Future<Directory> dataDir() async {
    final dir = await Directory.systemTemp.createTemp('sora-syncfix-data-');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
  }

  Future<String> launcher(Directory dir, String beforeExec) async {
    final script = File('${dir.path}/launch');
    await script.writeAsString('#!/bin/sh\n$beforeExec\nexec "$binary" "\$@"\n');
    final chmod = await Process.run('chmod', ['700', script.path]);
    expect(chmod.exitCode, 0);
    return script.path;
  }

  test('real daemon restarts with stale http_addr while child is still starting', () async {
    final dir = await dataDir();
    final first = SyncDaemon(binaryPath: binary, dataDir: dir.path);
    addTearDown(first.stop);
    await first.ensureRunning();
    expect(first.state, SyncDaemonState.running, reason: first.errorDetail);
    await first.stop();
    expect(await File('${dir.path}/http_addr').exists(), isTrue);
    final delayed = await launcher(dir, 'sleep 0.3');
    final restarted = SyncDaemon(binaryPath: delayed, dataDir: dir.path);
    addTearDown(restarted.stop);
    await restarted.ensureRunning();
    expect(restarted.state, SyncDaemonState.running, reason: restarted.errorDetail);
    expect((await restarted.client!.status()).deviceId, isNotEmpty);
  });

  test('startup retries an unready published address until real daemon serves health', () async {
    final dir = await dataDir();
    final delayed = await launcher(
      dir,
      'printf "127.0.0.1:0\\n" > "\$2/http_addr"\nprintf "startup-token\\n" > "\$2/api_token"\nsleep 0.3',
    );
    final daemon = SyncDaemon(binaryPath: delayed, dataDir: dir.path);
    addTearDown(daemon.stop);
    await daemon.ensureRunning();
    expect(daemon.state, SyncDaemonState.running, reason: daemon.errorDetail);
    expect((await daemon.client!.status()).deviceId, isNotEmpty);
  });

  test('child exit during readiness is reported without waiting for deadline', () async {
    final dir = await dataDir();
    final exiting = await launcher(dir, 'exit 23');
    final daemon = SyncDaemon(binaryPath: exiting, dataDir: dir.path);
    addTearDown(daemon.stop);
    final elapsed = Stopwatch()..start();
    await daemon.ensureRunning();
    expect(daemon.state, SyncDaemonState.failed);
    expect(daemon.errorDetail, contains('code 23'));
    expect(elapsed.elapsed, lessThan(SyncDaemon.addrTimeout));
  });
}
