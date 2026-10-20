import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:pub_semver/pub_semver.dart';

import 'settings.dart';

const appVersion = String.fromEnvironment('SORA_VERSION', defaultValue: 'dev');
const releaseRepository = 'https://github.com/levvs-one/sora';
const updateHelper = '/usr/lib/sora/sora-update';
const updatePolicy = '/usr/share/polkit-1/actions/io.github.levvs-one.sora.update.policy';

/// Staged-rollout policy feed (S11a): `updates/releases.json` at the repo
/// root on the default branch, fetched over plain HTTPS on every update
/// check. The feed carries POLICY ONLY — which installs are offered a
/// release. Artifacts, hashes and signatures always come from the GitHub
/// release API; the feed can never substitute artifact URLs or hashes.
/// Documented in docs/update-rollout.md.
const rolloutPolicyUrl = 'https://raw.githubusercontent.com/levvs-one/sora/main/updates/releases.json';

enum UpdateConnection { idle, connected, changing, unknown }

enum UpdateError { network, release, checksum, installation, connecting, unsupported, signatureRequired, rollback, rollbackCache }

/// Visible phase of an in-flight update flow (FEATURE-PLAN.md F7).
/// There is deliberately no "verifying" stage: file hashes are checked
/// against the manifest, but the manifest signature itself is not verified
/// in-app (the release-signing key ceremony is still pending), so the UI
/// must not claim verification.
enum UpdateStage { idle, checking, downloading, installing }

class UpdateFailure implements Exception {
  const UpdateFailure(this.reason);
  final UpdateError reason;
}

/// Build metadata does not describe a different installed release.
Version? releaseVersion(String text) {
  try {
    final version = Version.parse(text.replaceFirst(RegExp(r'^v'), ''));
    return Version(
      version.major,
      version.minor,
      version.patch,
      pre: version.preRelease.join('.').isEmpty ? null : version.preRelease.join('.'),
    );
  } on FormatException {
    return null;
  }
}

bool newerRelease(String candidate, String installed) {
  final next = releaseVersion(candidate), current = releaseVersion(installed);
  return next != null && !next.isPreRelease && current != null && next > current;
}

/// Normalizes a version string the way release tags are normalized
/// ("v1.2.3" -> "1.2.3"); null when it is not a usable version.
String? normalizedVersion(Object? text) => text is String ? releaseVersion(text)?.toString() : null;

/// Parsed `updates/releases.json` (format v1). Strict parsing: any deviation
/// from the schema yields null and the feed is ignored (fail-closed) — a
/// half-understood policy must never steer updates.
class RolloutPolicy {
  const RolloutPolicy({required this.version, required this.percent, required this.blockedVersions});

  /// Release this policy applies to, normalized. The policy is ignored unless
  /// it names exactly the release reported by the GitHub API.
  final String version;

  /// Share of the install base (by cohort) offered this release, 0..100.
  final int percent;

  /// Recalled versions, normalized. A listed candidate is never offered;
  /// a listed installed version triggers a persistent honest warning.
  final Set<String> blockedVersions;

  static RolloutPolicy? parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> || json['format'] != 1) return null;
      final rollout = json['rollout'];
      if (rollout is! Map<String, dynamic>) return null;
      final version = normalizedVersion(rollout['version']);
      final percent = rollout['percent'];
      if (version == null || percent is! int || percent < 0 || percent > 100) return null;
      final blocked = json['blocked_versions'];
      final blockedVersions = <String>{};
      if (blocked != null) {
        if (blocked is! List) return null;
        for (final entry in blocked) {
          final normalized = normalizedVersion(entry);
          if (normalized == null) return null;
          blockedVersions.add(normalized);
        }
      }
      return RolloutPolicy(version: version, percent: percent, blockedVersions: blockedVersions);
    } catch (_) {
      return null;
    }
  }
}

/// Staged-rollout cohort of this install: SHA-256 of the stable install
/// UUID, mod 100. Deterministic across checks and uniformly distributed, so
/// a rollout at N% reaches roughly N% of installs. The cohort never changes
/// unless the stored UUID is wiped.
int updateCohort(String installUuid) {
  final digest = sha256.convert(utf8.encode(installUuid)).bytes;
  var head = 0;
  for (var i = 0; i < 8; i++) {
    head = (head << 8) | digest[i];
  }
  return head % 100;
}

class ReleaseAsset {
  const ReleaseAsset(this.name, this.url, this.size);
  final String name;
  final Uri url;
  final int size;
}

class SoraRelease {
  const SoraRelease(this.version, this.notes, this.assets);
  final String version;
  final String notes;
  final Map<String, ReleaseAsset> assets;

  static SoraRelease parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String;
      final version = tag.replaceFirst(RegExp(r'^v'), '');
      // Published Sora packages use a three-part stable version in filenames.
      if (json['draft'] != false ||
          json['prerelease'] != false ||
          !RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$').hasMatch(version)) {
        throw const UpdateFailure(UpdateError.release);
      }
      final assets = <String, ReleaseAsset>{};
      for (final entry in json['assets'] as List) {
        final item = entry as Map<String, dynamic>;
        final name = item['name'] as String;
        final url = Uri.parse(item['browser_download_url'] as String);
        final size = item['size'] as int;
        final expected = Uri.parse('$releaseRepository/releases/download/$tag/$name');
        if (name.contains('/') || name.contains('\\') || size < 1 || assets.containsKey(name) || url != expected) {
          throw const UpdateFailure(UpdateError.release);
        }
        assets[name] = ReleaseAsset(name, url, size);
      }
      return SoraRelease(version, json['body'] as String? ?? '', Map.unmodifiable(assets));
    } on UpdateFailure {
      rethrow;
    } catch (_) {
      throw const UpdateFailure(UpdateError.release);
    }
  }

  ReleaseAsset asset(String name) => assets[name] ?? (throw const UpdateFailure(UpdateError.release));
}

String expectedHash(String manifest, String name) {
  final hashes = <String>[];
  for (final line in const LineSplitter().convert(manifest)) {
    final match = RegExp(r'^([a-fA-F0-9]{64}) [ *](.+)$').firstMatch(line);
    if (match != null && match[2] == name) hashes.add(match[1]!.toLowerCase());
  }
  if (hashes.length != 1) throw const UpdateFailure(UpdateError.checksum);
  return hashes.single;
}

Future<void> verifyUpdateFile(File file, String manifest, String name) async {
  final expected = expectedHash(manifest, name);
  final actual = await sha256.bind(file.openRead()).first;
  if (actual.toString() != expected) throw const UpdateFailure(UpdateError.checksum);
}

/// Marker written to settings before a Linux update hands off to the
/// privileged helper (S11b). After the restart the new build sees it and
/// runs the post-update health check: the marker is cleared only when the
/// core answers the control channel within 60 s; otherwise the install
/// rolls back to [from].
class PendingUpdate {
  const PendingUpdate({required this.from, required this.to, required this.atMs});

  final String from;
  final String to;
  final int atMs;

  String encode() => jsonEncode({'from': from, 'to': to, 'atMs': atMs});

  /// Strict parsing: anything unexpected yields null and the marker is
  /// ignored — a half-understood marker must never trigger a downgrade.
  static PendingUpdate? parse(String raw) {
    try {
      if (raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final from = normalizedVersion(json['from']);
      final to = normalizedVersion(json['to']);
      final atMs = json['atMs'];
      if (from == null || to == null || atMs is! int || atMs < 0) return null;
      return PendingUpdate(from: from, to: to, atMs: atMs);
    } catch (_) {
      return null;
    }
  }
}

enum PackageFormat { deb, rpm, arch }

typedef UpdateProcess = Future<ProcessResult> Function(String executable, List<String> arguments);

class LinuxInstallation {
  const LinuxInstallation(this.format, this.manager);
  final PackageFormat format;
  final String manager;

  List<String> filenames(String version) => switch (format) {
    PackageFormat.deb => ['sora-core_${version}_amd64.deb', 'sora_${version}_amd64.deb'],
    PackageFormat.rpm => ['sora-core-$version-1.x86_64.rpm', 'sora-$version-1.x86_64.rpm'],
    PackageFormat.arch => ['sora-core-$version-1-x86_64.pkg.tar.zst', 'sora-$version-1-x86_64.pkg.tar.zst'],
  };

  List<String> installArguments(List<String> files) => switch (manager) {
    'apt-get' => ['install', '-y', ...files],
    'dnf' => ['install', '-y', ...files],
    'zypper' => ['--non-interactive', 'install', '--allow-unsigned-rpm', ...files],
    'pacman' => ['-U', '--noconfirm', ...files],
    _ => throw const UpdateFailure(UpdateError.unsupported),
  };

  String manualCommand(List<String> files) {
    final arguments = installArguments(files);
    final command = [
      'sudo',
      manager,
      ...arguments.take(arguments.length - files.length),
      ...files.map(shellQuote),
    ].join(' ');
    return manager == 'pacman' ? 'sudo pacman -S --needed gst-plugins-good && $command' : command;
  }

  /// Query ownership of this executable, not merely which managers are present.
  static Future<LinuxInstallation?> detect(UpdateProcess run, String executable) async {
    Future<String?> query(String command, List<String> args) async {
      try {
        final result = await run(command, args).timeout(const Duration(seconds: 5));
        return result.exitCode == 0 ? (result.stdout as String).trim() : null;
      } on Object {
        return null;
      }
    }

    final debOwner = await query('dpkg-query', ['-S', executable]);
    if (debOwner == 'sora: $executable' || debOwner == 'sora:amd64: $executable') {
      final status = await query('dpkg-query', ['-W', '-f=\${Package}\t\${db:Status-Status}\n', 'sora', 'sora-core']);
      if (status != null && status.split('\n').toSet().containsAll({'sora\tinstalled', 'sora-core\tinstalled'})) {
        return const LinuxInstallation(PackageFormat.deb, 'apt-get');
      }
    }
    if (await query('rpm', ['-qf', '--qf', '%{NAME}\n', executable]) == 'sora') {
      final names = await query('rpm', ['-q', '--qf', '%{NAME}\n', 'sora', 'sora-core']);
      if (names != null && names.split('\n').toSet().containsAll({'sora', 'sora-core'})) {
        for (final manager in ['dnf', 'zypper']) {
          if (await query(manager, ['--version']) != null) return LinuxInstallation(PackageFormat.rpm, manager);
        }
      }
    }
    if (await query('pacman', ['-Qoq', executable]) == 'sora') {
      final packages = await query('pacman', ['-Qq', 'sora', 'sora-core']);
      if (packages != null && packages.split('\n').toSet().containsAll({'sora', 'sora-core'})) {
        return const LinuxInstallation(PackageFormat.arch, 'pacman');
      }
    }
    return null;
  }
}

String shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

class AppUpdater extends ChangeNotifier {
  AppUpdater(
    this.settings, {
    required this.connection,
    required this.available,
    this.version = appVersion,
    http.Client Function()? client,
    UpdateProcess? run,
    String? executable,
    bool? windows,
    Future<bool> Function()? canElevate,
    Directory Function(String fromVersion)? rollbackDir,
  }) : _client = client ?? (() => IOClient(HttpClient()..findProxy = HttpClient.findProxyFromEnvironment)),
       _run = run ?? ((exe, args) => Process.run(exe, args)),
       _executable = executable ?? Platform.resolvedExecutable,
       _windows = windows ?? Platform.isWindows,
       _rollbackDirOverride = rollbackDir,
       _canElevate =
           canElevate ??
           (() async =>
               await File(updateHelper).exists() &&
               await File(updatePolicy).exists() &&
               await File('/usr/bin/pkexec').exists());

  final Settings settings;
  final String version;
  final UpdateConnection Function() connection;
  final Future<void> Function(SoraRelease release) available;
  final http.Client Function() _client;
  final UpdateProcess _run;
  final String _executable;
  final bool _windows;

  /// Test seam for the rollback cache location (S11b): production uses the
  /// XDG cache dir, tests point it at a temp directory.
  final Directory Function(String fromVersion)? _rollbackDirOverride;
  final Future<bool> Function() _canElevate;
  Timer? _timer;
  bool _disposed = false;
  bool _started = false;
  bool checking = false;
  bool busy = false;
  bool installed = false;
  double? progress;
  UpdateError? error;
  SoraRelease? latest;
  String? manualCommand;
  Directory? _work;
  final _clients = <http.Client>{};

  /// Kill-switch / staged-rollout state from the policy feed (S11a),
  /// recomputed on every successful release check:
  /// - [versionRevoked] — the INSTALLED version is listed in the feed's
  ///   blocked_versions: the UI shows a persistent, non-alarming warning.
  /// - [rolloutPending] — a newer release exists but this install's cohort
  ///   is not included in the staged rollout yet.
  bool versionRevoked = false;
  bool rolloutPending = false;
  bool _updateWithheld = false;

  /// Post-update health-check state (S11b). [_healthCheckArmed] while the
  /// 60-second window after an update is open; [noteCoreHealthy] disarms it.
  /// [rollbackBusy]/[rollbackTarget] while the automatic rollback runs.
  static const healthCheckWindow = Duration(seconds: 60);
  Timer? _healthTimer;
  bool _healthCheckArmed = false;
  bool Function()? _coreHealthy;
  bool rollbackBusy = false;
  String? rollbackTarget;

  bool get hasUpdate =>
      !installed &&
      latest != null &&
      newerRelease(latest!.version, version) &&
      !_updateWithheld &&
      !rolloutPending;

  /// Visible phase of the update flow; idle when nothing is in flight.
  UpdateStage stage = UpdateStage.idle;

  Completer<void>? _abort;
  bool _cancelled = false;

  /// Cancels an in-flight update check or download. The install handoff
  /// itself (package manager / setup launch) cannot be cancelled.
  void cancel() {
    if (_disposed) return;
    _cancelled = true;
    final abort = _abort;
    if (abort != null && !abort.isCompleted) abort.complete();
    notifyListeners();
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!settings.checkUpdates || !_started || _disposed) return;
    _timer = Timer.periodic(const Duration(hours: 12), (_) => unawaited(check()));
    unawaited(check());
  }

  Future<void> setChecking(bool enabled) async {
    await settings.saveCheckUpdates(enabled);
    if (_disposed) return;
    _schedule();
    notifyListeners();
  }

  /// Applies the staged-rollout policy feed to [release] (S11a), setting
  /// [versionRevoked], [rolloutPending] and [_updateWithheld]. Decision
  /// table (every branch is logged with the `[updates]` tag):
  /// - feed unreachable (network error, 404, timeout) -> legacy behavior:
  ///   the update is offered to everyone; a missing feed must not brick
  ///   updates;
  /// - feed fetched but malformed -> fail-closed: the update is NOT offered
  ///   this round; a corrupt policy channel must not silently degrade to
  ///   "offer to all" and bypass an intended kill-switch;
  /// - feed parsed but naming another version -> ignored (fail-closed): the
  ///   feed must not steer a release it does not name, so the update is NOT
  ///   offered until the feed names it;
  /// - feed parsed and version matches -> a candidate in blocked_versions
  ///   is never offered (kill-switch); otherwise the update is offered iff
  ///   this install's cohort is below rollout.percent.
  /// The installed version being listed in blocked_versions sets
  /// [versionRevoked] independently of the candidate decision.
  Future<void> _applyRolloutPolicy(SoraRelease release) async {
    versionRevoked = false;
    rolloutPending = false;
    _updateWithheld = false;
    final List<int> body;
    try {
      body = await _fetch(Uri.parse(rolloutPolicyUrl), limit: 64 * 1024);
    } catch (e) {
      if (_cancelled) {
        // The check was cancelled mid-fetch: withhold rather than fall
        // back to legacy offer-all on a possibly-aborted fetch.
        _updateWithheld = true;
        return;
      }
      // Transport failure (DNS, TLS, 404, timeout): keep the legacy
      // behavior so an unreachable policy host cannot brick updates.
      debugPrint('[updates] rollout feed unreachable ($e); falling back to offering the update to everyone');
      return;
    }
    // Decode failures are content failures, not transport failures: an
    // undecodable body is malformed (fail-closed below), never "unreachable".
    final String text;
    try {
      text = utf8.decode(body);
    } on FormatException {
      text = '';
    }
    final policy = RolloutPolicy.parse(text);
    if (policy == null) {
      debugPrint('[updates] rollout feed is malformed; ignoring it (fail-closed: update withheld this round)');
      _updateWithheld = true;
      return;
    }
    if (policy.version != release.version) {
      debugPrint(
        '[updates] rollout policy targets ${policy.version} but the latest release is ${release.version}; '
        'ignoring the policy (fail-closed: update withheld until the feed names this release)',
      );
      _updateWithheld = true;
      return;
    }
    final installedVersion = normalizedVersion(version);
    if (installedVersion != null && policy.blockedVersions.contains(installedVersion)) {
      versionRevoked = true;
      debugPrint('[updates] installed version $installedVersion is recalled by the rollout policy');
    }
    if (policy.blockedVersions.contains(release.version)) {
      debugPrint('[updates] release ${release.version} is blocked by the rollout policy (kill-switch); not offering it');
      _updateWithheld = true;
      return;
    }
    final cohort = updateCohort(settings.installUuid);
    if (cohort >= policy.percent) {
      debugPrint(
        '[updates] install cohort $cohort is not included in the ${policy.percent}% rollout '
        'of ${release.version}; withholding the update for now',
      );
      // Surface the "pending" note only when a newer release actually exists:
      // if this install is already on (or ahead of) the rolled-out version —
      // e.g. the user updated while percent was 100 and the owner later
      // lowered it — the note would falsely claim a newer version is on its
      // way. hasUpdate stays false either way.
      rolloutPending = newerRelease(release.version, version);
      return;
    }
    debugPrint('[updates] install cohort $cohort is included in the ${policy.percent}% rollout of ${release.version}');
  }

  Future<void> check({bool manual = false}) async {
    if (_disposed || checking || busy || (!manual && !settings.checkUpdates)) return;
    checking = true;
    stage = UpdateStage.checking;
    _cancelled = false;
    if (manual) error = null;
    notifyListeners();
    try {
      final bytes = await _fetch(
        Uri.parse('https://api.github.com/repos/levvs-one/sora/releases/latest'),
        limit: 2 * 1024 * 1024,
      );
      final release = SoraRelease.parse(utf8.decode(bytes));
      if (_disposed || (!manual && !settings.checkUpdates)) return;
      latest = release;
      error = null;
      await _applyRolloutPolicy(release);
      if (hasUpdate && settings.notifiedUpdate != release.version) {
        await settings.saveNotifiedUpdate(release.version);
        if (!_disposed) await available(release);
      }
    } catch (e) {
      if (_cancelled) {
        error = null;
      } else if (manual) {
        error = e is UpdateFailure ? e.reason : UpdateError.network;
      }
    } finally {
      checking = false;
      stage = UpdateStage.idle;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<int>> _fetch(Uri uri, {required int limit, File? target, int? size}) async {
    final client = _client();
    _clients.add(client);
    IOSink? sink;
    final bytes = <int>[];
    final abort = _abort = Completer<void>();
    final deadline = Timer(
      target == null ? const Duration(seconds: 20) : const Duration(minutes: 30),
      () => abort.complete(),
    );
    try {
      final request = http.AbortableRequest('GET', uri, abortTrigger: abort.future)
        ..headers.addAll({
          'Accept': uri.host == 'api.github.com' ? 'application/vnd.github+json' : 'application/octet-stream',
          'User-Agent': 'Sora/$version',
          'X-GitHub-Api-Version': '2022-11-28',
        });
      final response = await client.send(request);
      if (response.statusCode != 200 || (response.contentLength ?? 0) > limit) {
        throw const UpdateFailure(UpdateError.network);
      }
      sink = target?.openWrite();
      var received = 0;
      await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
        if (_disposed) throw const UpdateFailure(UpdateError.network);
        received += chunk.length;
        if (received > limit) throw const UpdateFailure(UpdateError.network);
        if (sink == null) {
          bytes.addAll(chunk);
        } else {
          sink.add(chunk);
          // Flush each chunk to bound memory while fetching large core packages.
          await sink.flush();
          final next = size == null ? null : received / size;
          if (next != null && (progress == null || (next * 100).floor() != (progress! * 100).floor())) {
            progress = next;
            notifyListeners();
          }
        }
      }
      if (size != null && received != size) throw const UpdateFailure(UpdateError.network);
      return bytes;
    } on UpdateFailure {
      rethrow;
    } on Object {
      throw const UpdateFailure(UpdateError.network);
    } finally {
      deadline.cancel();
      client.close();
      _clients.remove(client);
      if (identical(_abort, abort)) _abort = null;
      await sink?.close();
    }
  }

  void _guard() {
    if (_disposed || connection() == UpdateConnection.changing || connection() == UpdateConnection.unknown) {
      throw const UpdateFailure(UpdateError.connecting);
    }
  }

  /// The caller provides desktop launch/quit operations so tests never elevate.
  Future<void> install({
    required Future<bool> Function() confirmDrop,
    required Future<void> Function(File installer) launchWindows,
    required Future<void> Function() restartLinux,
    required Future<void> Function() quit,
  }) async {
    if (busy || !hasUpdate || _disposed) return;
    error = null;
    manualCommand = null;
    busy = true;
    progress = null;
    stage = UpdateStage.checking;
    _cancelled = false;
    notifyListeners();
    bool handedOff = false;
    try {
      if (_windows) {
        // Fail closed (analysis-20 U1): the Windows in-app path would install
        // an elevated .exe trusting only TLS plus a SHA256 against a manifest
        // fetched from the same host. The SHA256SUMS.minisig signature is not
        // verified in-app: ext/verifier.dart implements the .soraext
        // trusted-comment scheme ("timestamp:..\tfile:..\tsha256:.."), not
        // the stock minisign scheme the release is signed with (signature over
        // trusted-comment || file, plus a global signature), so it cannot be
        // reused 1:1; and the release key is still a placeholder (key ceremony
        // pending). Installing here would silently downgrade the documented
        // fail-closed policy, so refuse with an honest error instead of
        // proceeding. This also removes the Windows verify->exec TOCTOU
        // window (analysis-20 U3): launchWindows is never reached from here.
        throw const UpdateFailure(UpdateError.signatureRequired);
      }
      _guard();
      final release = latest!;
      final installation = _windows ? null : await LinuxInstallation.detect(_run, _executable);
      if (!_windows && installation == null) throw const UpdateFailure(UpdateError.unsupported);
      final names = _windows ? ['Sora-Setup-${release.version}-x64.exe'] : installation!.filenames(release.version);
      // Resolve the whole pair before downloading or invoking any installer.
      final assets = [for (final name in names) release.asset(name)];
      final sums = release.asset('SHA256SUMS');
      // The privileged helper re-verifies the SHA256SUMS signature as root
      // before trusting any hash in it (SORA-H1); it refuses to run when the
      // signature file is missing from the download directory, so the app
      // must fetch it alongside the manifest.
      final sumsSig = release.asset('SHA256SUMS.minisig');
      if (_work != null) await _work!.delete(recursive: true);
      final work = _work = await Directory.systemTemp.createTemp('sora-update-');
      final manifest = utf8.decode(await _fetch(sums.url, limit: 1024 * 1024, size: sums.size));
      final sigBytes = await _fetch(sumsSig.url, limit: 64 * 1024, size: sumsSig.size);
      for (final asset in assets) {
        expectedHash(manifest, asset.name);
      }
      await File('${work.path}/SHA256SUMS').writeAsString(manifest, flush: true);
      await File('${work.path}/SHA256SUMS.minisig').writeAsBytes(sigBytes, flush: true);
      for (final asset in assets) {
        final file = File('${work.path}/${asset.name}');
        stage = UpdateStage.downloading;
        notifyListeners();
        await _fetch(asset.url, limit: asset.size, target: file, size: asset.size);
        // Integrity check only: the file hash must match the manifest, but
        // the manifest signature (.minisig) is not verified in-app — the
        // release-signing key ceremony is still pending, so only the TLS
        // transport to GitHub authenticates it. The Linux privileged helper
        // re-checks the signature as root before installing (SORA-H1); the
        // UI must not present this step as signature verification.
        await verifyUpdateFile(file, manifest, asset.name);
      }
      _guard();
      if (connection() == UpdateConnection.connected && !await confirmDrop()) return;
      _guard();
      if (_windows) {
        await settings.saveResumeAfterUpdate(connection() == UpdateConnection.connected);
        _guard();
        stage = UpdateStage.installing;
        notifyListeners();
        await launchWindows(File('${work.path}/${names.single}'));
        handedOff = true;
        await quit();
      } else {
        final paths = [for (final name in names) '${work.path}/$name'];
        if (!await _canElevate()) {
          manualCommand = installation!.manualCommand(paths);
          return;
        }
        _guard();
        await settings.saveResumeAfterUpdate(connection() == UpdateConnection.connected);
        _guard();
        // S11b: the rollback safety net is prepared BEFORE the handoff —
        // verified copies of the currently installed packages, so a broken
        // update can be reverted offline without trusting the new build.
        // Fail-closed: without the cache the update does not proceed.
        await _prepareRollbackCache(installation!);
        _guard();
        await settings.savePendingUpdate(
          PendingUpdate(
            from: version,
            to: release.version,
            atMs: DateTime.now().millisecondsSinceEpoch,
          ).encode(),
        );
        stage = UpdateStage.installing;
        notifyListeners();
        final result = await _run('/usr/bin/pkexec', [
          updateHelper,
          installation!.format.name,
          release.version,
          work.path,
        ]);
        if (result.exitCode != 0) {
          // The handoff failed: nothing was installed, the marker must not
          // survive to arm a health check for an update that never landed.
          await settings.clearPendingUpdate();
          manualCommand = installation.manualCommand(paths);
          throw const UpdateFailure(UpdateError.installation);
        }
        installed = true;
        await restartLinux();
        await quit();
      }
    } catch (e) {
      error = _cancelled ? null : (e is UpdateFailure ? e.reason : UpdateError.installation);
    } finally {
      busy = false;
      progress = null;
      stage = UpdateStage.idle;
      if (!handedOff && !installed) await settings.saveResumeAfterUpdate(false);
      // The marker survives only when the new packages were actually handed
      // to the installer: any earlier failure leaves the old build running,
      // and a stale marker must never arm a health check for it.
      if (!installed) await settings.clearPendingUpdate();
      // Keep verified files for the manual command or a launched Windows setup.
      if (!handedOff && manualCommand == null && _work != null) {
        await _work!.delete(recursive: true);
        _work = null;
      }
      if (!_disposed) notifyListeners();
    }
  }

  /// Post-update health check (S11b). Call once at startup with desktop
  /// restart/quit operations. When a [PendingUpdate] marker from an update
  /// installed by this app is present and names the running build:
  /// - core already answered this launch ([coreHealthy]) → the update is
  ///   healthy; the marker is cleared immediately;
  /// - otherwise a 60-second window opens: [noteCoreHealthy] (called when
  ///   the core answers the control channel) clears the marker;
  /// - if the window expires — or the marker is already stale because the
  ///   app crashed before clearing it — the install rolls back to the
  ///   pre-update version via the privileged helper with --allow-downgrade,
  ///   using the verified rollback cache (fail-closed: no cache or a hash
  ///   mismatch → no rollback, error + manual command instead).
  /// A marker naming any other build, or a corrupt one, is cleared
  /// silently: its premise is void and it must never trigger a downgrade.
  /// No-op on Windows: the in-app path is blocked fail-closed there (A2),
  /// so a marker can never exist.
  Future<void> checkPendingUpdate({
    required bool Function() coreHealthy,
    required Future<void> Function() restart,
    required Future<void> Function() quit,
  }) async {
    if (_disposed || _windows || _healthCheckArmed) return;
    final marker = PendingUpdate.parse(settings.pendingUpdate);
    if (marker == null) return;
    if (marker.to != version) {
      debugPrint('[updates] pending-update marker targets ${marker.to} but this is $version; clearing it');
      await settings.clearPendingUpdate();
      return;
    }
    _coreHealthy = coreHealthy;
    if (coreHealthy()) {
      debugPrint('[updates] core already answered; post-update health check passed immediately');
      await settings.clearPendingUpdate();
      return;
    }
    final age = DateTime.now().millisecondsSinceEpoch - marker.atMs;
    if (age >= healthCheckWindow.inMilliseconds) {
      debugPrint('[updates] pending-update marker is stale (age ${age}ms); rolling back to ${marker.from}');
      await _rollback(marker, restart: restart, quit: quit);
      return;
    }
    _healthCheckArmed = true;
    final remaining = healthCheckWindow - Duration(milliseconds: age.clamp(0, healthCheckWindow.inMilliseconds));
    _healthTimer = Timer(remaining, () {
      _healthCheckArmed = false;
      _healthTimer = null;
      debugPrint('[updates] post-update health check timed out; rolling back to ${marker.from}');
      unawaited(_rollback(marker, restart: restart, quit: quit));
    });
    debugPrint('[updates] post-update health check armed for ${remaining.inMilliseconds}ms');
  }

  /// Called when the core answers the control channel (Sora.run, after the
  /// getStatus/getAbout handshake). Clears a pending post-update marker:
  /// the update is healthy. Idempotent; a no-op outside the health window.
  Future<void> noteCoreHealthy() async {
    if (!_healthCheckArmed) return;
    _healthCheckArmed = false;
    _healthTimer?.cancel();
    _healthTimer = null;
    debugPrint('[updates] core answered the control channel; post-update health check passed');
    await settings.clearPendingUpdate();
    if (!_disposed) notifyListeners();
  }

  /// Rolls back to [marker.from] using the verified rollback cache (S11b).
  /// Fail-closed at every step: missing cache, hash mismatch, no elevation
  /// or a failed helper run → no downgrade happens; the error and a manual
  /// reinstall command stay visible in About instead.
  Future<void> _rollback(
    PendingUpdate marker, {
    required Future<void> Function() restart,
    required Future<void> Function() quit,
  }) async {
    if (_disposed || _windows || rollbackBusy) return;
    // Final gate against races (e.g. the core answered between arming the
    // timer and its expiry): never downgrade a healthy install.
    final healthy = _coreHealthy;
    if (healthy != null && healthy()) {
      debugPrint('[updates] core answered before the rollback; clearing the marker instead');
      await settings.clearPendingUpdate();
      return;
    }
    rollbackBusy = true;
    rollbackTarget = marker.from;
    error = null;
    manualCommand = null;
    notifyListeners();
    try {
      final installation = await LinuxInstallation.detect(_run, _executable);
      if (installation == null) throw const UpdateFailure(UpdateError.unsupported);
      final dir = _rollbackDir(marker.from);
      if (dir == null || !await dir.exists()) {
        debugPrint('[updates] no rollback cache for ${marker.from}; cannot roll back');
        throw const UpdateFailure(UpdateError.rollback);
      }
      // Re-verify against the cached manifest: the cache was hash-verified
      // at download time, but it lived on user-writable disk since. The
      // privileged helper additionally verifies the manifest signature as
      // root before installing (SORA-H1).
      final manifestFile = File('${dir.path}/SHA256SUMS');
      if (!await manifestFile.exists() || !await File('${dir.path}/SHA256SUMS.minisig').exists()) {
        throw const UpdateFailure(UpdateError.rollback);
      }
      final manifest = await manifestFile.readAsString();
      final names = installation.filenames(marker.from);
      final paths = <String>[];
      for (final name in names) {
        final file = File('${dir.path}/$name');
        if (!await file.exists()) throw const UpdateFailure(UpdateError.rollback);
        try {
          await verifyUpdateFile(file, manifest, name);
        } on UpdateFailure {
          debugPrint('[updates] rollback cache hash mismatch for $name; refusing to roll back');
          throw const UpdateFailure(UpdateError.rollback);
        }
        paths.add(file.path);
      }
      debugPrint('[updates] rollback cache verified for ${marker.from}; invoking the privileged helper');
      if (!await _canElevate()) {
        manualCommand = installation.manualCommand(paths);
        throw const UpdateFailure(UpdateError.rollback);
      }
      final result = await _run('/usr/bin/pkexec', [
        updateHelper,
        installation.format.name,
        marker.from,
        dir.path,
        '--allow-downgrade',
      ]);
      if (result.exitCode != 0) {
        manualCommand = installation.manualCommand(paths);
        throw const UpdateFailure(UpdateError.rollback);
      }
      await settings.clearPendingUpdate();
      await settings.saveLastRollback(marker.from, marker.to);
      debugPrint('[updates] rolled back to ${marker.from}');
      await restart();
      await quit();
    } catch (e) {
      error = e is UpdateFailure ? e.reason : UpdateError.rollback;
      // Fail-closed: never retry a failed rollback automatically (no pkexec
      // prompt loop on every launch). The marker is cleared so a broken
      // updater cannot keep downgrading; the error and the manual command
      // stay visible in About.
      await settings.clearPendingUpdate();
      debugPrint('[updates] automatic rollback failed: $e');
    } finally {
      rollbackBusy = false;
      rollbackTarget = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// Persistent cache of the pre-update packages (S11b). Outside the temp
  /// work dir: it must survive the restart the update performs.
  Directory? _rollbackDir(String fromVersion) {
    final override = _rollbackDirOverride;
    if (override != null) return override(fromVersion);
    final env = Platform.environment;
    final base = env['XDG_CACHE_HOME'] ?? (env['HOME'] == null ? null : '${env['HOME']}/.cache');
    if (base == null || base.isEmpty) return null;
    return Directory('$base/sora/rollback/$fromVersion');
  }

  /// Downloads and hash-verifies the currently installed release's packages
  /// into the rollback cache, so a broken update can be reverted offline.
  /// Any failure (network, missing release assets, hash mismatch) aborts the
  /// whole update (fail-closed): installing without a rollback path is not
  /// an option once the safety net is promised.
  Future<void> _prepareRollbackCache(LinuxInstallation installation) async {
    // hasUpdate is false on dev builds (releaseVersion('dev') is null), so
    // the from-version is always a real release here.
    final from = releaseVersion(version)?.toString();
    final dir = from == null ? null : _rollbackDir(from);
    if (dir == null) throw const UpdateFailure(UpdateError.rollbackCache);
    try {
      final parent = dir.parent;
      if (await parent.exists()) await parent.delete(recursive: true);
      final bytes = await _fetch(
        Uri.parse('https://api.github.com/repos/levvs-one/sora/releases/tags/v$from'),
        limit: 2 * 1024 * 1024,
      );
      final previous = SoraRelease.parse(utf8.decode(bytes));
      if (previous.version != from) throw const UpdateFailure(UpdateError.release);
      final names = installation.filenames(previous.version);
      final assets = [for (final name in names) previous.asset(name)];
      final sums = previous.asset('SHA256SUMS');
      final sumsSig = previous.asset('SHA256SUMS.minisig');
      await dir.create(recursive: true);
      final manifest = utf8.decode(await _fetch(sums.url, limit: 1024 * 1024, size: sums.size));
      final sigBytes = await _fetch(sumsSig.url, limit: 64 * 1024, size: sumsSig.size);
      for (final asset in assets) {
        expectedHash(manifest, asset.name);
      }
      await File('${dir.path}/SHA256SUMS').writeAsString(manifest, flush: true);
      await File('${dir.path}/SHA256SUMS.minisig').writeAsBytes(sigBytes, flush: true);
      for (final asset in assets) {
        final file = File('${dir.path}/${asset.name}');
        await _fetch(asset.url, limit: asset.size, target: file, size: asset.size);
        await verifyUpdateFile(file, manifest, asset.name);
      }
      debugPrint('[updates] rollback cache ready for $from (${assets.length} packages, hashes verified)');
    } on UpdateFailure catch (e) {
      debugPrint('[updates] rollback cache failed (${e.reason}); aborting the update');
      if (await dir.exists()) await dir.delete(recursive: true);
      throw const UpdateFailure(UpdateError.rollbackCache);
    }
  }

  /// The last automatic rollback notice, parsed from settings (S11b).
  /// Survives the restart the rollback performs so About can report it.
  ({String from, String to})? get lastRollback {
    try {
      final json = jsonDecode(settings.lastRollback);
      if (json is! Map<String, dynamic>) return null;
      final from = normalizedVersion(json['from']);
      final to = normalizedVersion(json['to']);
      if (from == null || to == null) return null;
      return (from: from, to: to);
    } catch (_) {
      return null;
    }
  }

  Future<void> dismissRollbackNotice() async {
    await settings.clearLastRollback();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _healthTimer?.cancel();
    for (final client in _clients.toList()) {
      client.close();
    }
    super.dispose();
  }
}
