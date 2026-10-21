/// ExtensionHost transport for the Anti-DPI bypass API.
///
/// The panel bridge (bridge.dart) speaks JSON maps; this seam speaks the
/// same maps on the app side of the ExtensionHost gRPC service
/// (sora.ext.v1, contract 1.14), so the panel screen wires bridge
/// callbacks straight to these methods and all JSON↔proto conversion
/// lives in bypass.dart.
library;

import 'package:grpc/grpc.dart';

import '../generated/sora/ext/v1/ext_host.pb.dart' as extpb;
import '../generated/sora/ext/v1/ext_host.pbgrpc.dart' hide BypassBinding;
import 'bridge.dart';
import 'bypass.dart';

/// One censorship event from WatchBypassEvents, in the shape the panel
/// contract fixes for the `bypass.event` push: the event detail is the
/// JSON encoding of {kind, censorship_kind, explanation, at}.
class BypassCensorshipEvent {
  const BypassCensorshipEvent({required this.censorshipKind, required this.explanation, required this.at});

  /// The detector's classification, e.g. "sni_blocking".
  final String censorshipKind;

  /// Plain-language account from the detector; may be empty.
  final String explanation;

  /// When the core observed it.
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'kind': 'censorship',
    'censorship_kind': censorshipKind,
    'explanation': explanation,
    'at': at.toUtc().toIso8601String(),
  };
}

/// The bypass surface of ExtensionHost, scoped to one extension's minted
/// token. All shapes are the bridge JSON shapes (see bypass.dart and
/// docs/extensions-api.md).
abstract class BypassHostApi {
  /// {} -> {platform, backends: [{kind, available, reason}]}
  Future<Map<String, dynamic>> getCapabilities();

  /// {} -> {platform, global_source, global_from, session_active,
  /// pending_apply, bindings_count}
  Future<Map<String, dynamic>> getState();

  /// {} -> {global, bindings, updated_at} (bypass.dart layer shape)
  Future<Map<String, dynamic>> getLayer();

  /// {global, bindings} -> {updated_at}
  Future<Map<String, dynamic>> applyLayer(Map<String, dynamic> layer);

  /// {engine} -> {winner_id, winner_describe, score, attempts, strategy}
  Future<Map<String, dynamic>> tuneDesync(String engine);

  /// Censorship events for the lifetime of one panel.
  Stream<BypassCensorshipEvent> watchEvents();
}

/// Maps a bypass-host failure to the bridge error contract:
/// PermissionDenied (and Unauthenticated — a revoked or out-of-scope
/// token) -> 'permission-denied', InvalidArgument -> 'invalid-argument'
/// with the core's message, Unavailable / Unimplemented (a core without
/// the bypass API) and anything else -> 'internal'.
BridgeError mapBypassHostError(Object e) {
  if (e is BridgeError) return e;
  if (e is GrpcError) {
    return switch (e.code) {
      StatusCode.permissionDenied ||
      StatusCode.unauthenticated => BridgeError('permission-denied', e.message ?? 'permission denied'),
      StatusCode.invalidArgument => BridgeError('invalid-argument', e.message ?? 'invalid argument'),
      _ => BridgeError('internal', e.message ?? 'bypass host failed'),
    };
  }
  if (e is FormatException) return BridgeError('invalid-argument', e.message);
  return BridgeError('internal', 'bypass host failed');
}

/// [BypassHostApi] over the generated ExtensionHost client and one
/// extension's minted token. The proto renders layer timestamps as
/// unix seconds; the bridge contract carries RFC 3339 strings, so the
/// conversion happens here (zero — no layer stored — omits the key).
class GrpcBypassHostApi implements BypassHostApi {
  GrpcBypassHostApi(this._client, this._token);

  final ExtensionHostClient _client;
  final List<int> _token;

  static String _isoFromUnix(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toIso8601String();

  @override
  Future<Map<String, dynamic>> getCapabilities() async {
    final r = await _client.getBypassCapabilities(GetBypassCapabilitiesRequest(extensionToken: _token));
    return {
      'platform': r.platform,
      'backends': [
        for (final b in r.backends) {'kind': b.kind, 'available': b.available, 'reason': b.reason},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    final r = await _client.getBypassState(GetBypassStateRequest(extensionToken: _token));
    return {
      'platform': r.platform,
      'global_source': r.globalSource,
      'global_from': r.globalFrom,
      'session_active': r.sessionActive,
      'pending_apply': r.pendingApply,
      'bindings_count': r.bindingsCount,
    };
  }

  @override
  Future<Map<String, dynamic>> getLayer() async {
    final r = await _client.getBypassLayer(GetBypassLayerRequest(extensionToken: _token));
    final unix = r.updatedAtUnix.toInt();
    return bypassLayerToJson(
      // hasGlobal_2 is the generated name (protoc-gen-dart escaping for
      // the has_global field next to the global message field).
      global: r.hasGlobal_2 ? r.global : null,
      bindings: [for (final b in r.bindings) (match: b.match, strategy: b.strategy)],
      updatedAt: unix > 0 ? DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true) : null,
    );
  }

  @override
  Future<Map<String, dynamic>> applyLayer(Map<String, dynamic> layer) async {
    final parsed = bypassLayerFromJson(layer);
    final r = await _client.applyBypassLayer(
      ApplyBypassLayerRequest(
        extensionToken: _token,
        hasGlobal: parsed.global != null,
        // global_3 is the generated name for the request's global field.
        global_3: parsed.global,
        bindings: [for (final b in parsed.bindings) extpb.BypassBinding(match: b.match, strategy: b.strategy)],
      ),
    );
    return {'updated_at': _isoFromUnix(r.updatedAtUnix.toInt())};
  }

  @override
  Future<Map<String, dynamic>> tuneDesync(String engine) async {
    final r = await _client.tuneDesync(TuneDesyncRequest(extensionToken: _token, engine: engine));
    return {
      'winner_id': r.winnerId,
      'winner_describe': r.winnerDescribe,
      'score': r.score,
      'attempts': r.attempts,
      // strategy_6 is the generated name for the response's strategy.
      'strategy': r.hasStrategy ? bypassStrategyToJson(r.strategy_6) : null,
    };
  }

  @override
  Stream<BypassCensorshipEvent> watchEvents() {
    return _client
        .watchBypassEvents(WatchBypassEventsRequest(extensionToken: _token))
        // The panel contract carries censorship verdicts only; session
        // and (reserved) strategy events on this stream are not pushed.
        .where((e) => e.kind == 'censorship')
        .map(
          (e) => BypassCensorshipEvent(
            censorshipKind: e.censorshipKind,
            explanation: e.explanation,
            at: e.hasAt() ? e.at.toDateTime() : DateTime.now().toUtc(),
          ),
        );
  }
}
