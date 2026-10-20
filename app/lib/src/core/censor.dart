import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'link.dart';

/// What the censorship detector concluded about a connection attempt.
enum CensorVerdictKind {
  unknown,
  notBlocked,
  likelyBlocked,
  blocked;

  static CensorVerdictKind fromName(String name) => switch (name) {
    'notBlocked' => notBlocked,
    'likelyBlocked' => likelyBlocked,
    'blocked' => blocked,
    _ => unknown,
  };
}

/// One machine-readable reason behind a verdict. [code] is a stable key such
/// as "tls.reset"; [detail] is the core's free-form addition, shown when the
/// app knows no human wording for the code.
class CensorReason {
  const CensorReason({required this.code, this.detail = ''});

  final String code;
  final String detail;

  Map<String, Object?> toJson() => {'code': code, if (detail.isNotEmpty) 'detail': detail};

  static CensorReason fromJson(Map<String, dynamic> json) =>
      CensorReason(code: json['code'] as String? ?? '', detail: json['detail'] as String? ?? '');
}

/// A single detector verdict: how confident the core is that the provider is
/// blocking the connection, why it thinks so, and which network profile it
/// recommends as masking.
class CensorVerdict {
  const CensorVerdict({
    required this.id,
    required this.detectedAt,
    required this.confidence,
    required this.kind,
    this.reasons = const [],
    this.recommendedProfileId = '',
  });

  final String id;
  final DateTime detectedAt;

  /// Detector confidence, 0..100.
  final int confidence;
  final CensorVerdictKind kind;
  final List<CensorReason> reasons;

  /// Id of a network profile whose masking fits this verdict, when the core
  /// named one.
  final String recommendedProfileId;

  /// Whether the verdict is worth interrupting the user with. An inconclusive
  /// detector must never claim blocking.
  bool get actionable => kind == CensorVerdictKind.likelyBlocked || kind == CensorVerdictKind.blocked;

  Map<String, Object?> toJson() => {
    'id': id,
    'detectedAt': detectedAt.toIso8601String(),
    'confidence': confidence,
    'kind': kind.name,
    if (reasons.isNotEmpty) 'reasons': [for (final r in reasons) r.toJson()],
    if (recommendedProfileId.isNotEmpty) 'recommendedProfileId': recommendedProfileId,
  };

  /// Detector wire kinds (core/censor Kind.String()) that mean the path
  /// interfered. Anything else the core sends ("no_interference",
  /// "unknown", or a kind this client predates) must not be upgraded to a
  /// blocking claim.
  static const _blockingWireKinds = {
    'rst_injection',
    'handshake_timeout',
    'dns_poisoning',
    'sni_blocking',
    'ip_blocking',
    'data_stall',
  };

  /// Builds a verdict from a pushed `CoreEvent.censorship_detected` payload
  /// (sora.core.v1, field 13): [wireKind] is the detector's Kind spelling,
  /// [wireConfidence] its 0..1 confidence. The grade follows the core's own
  /// wording bands in censor's explain(): below 0.35 the proto contract
  /// pairs the verdict with UNKNOWN, 0.35..0.75 is "likely", and only
  /// 0.75+ is stated plainly — so only 0.75+ maps to [CensorVerdictKind.blocked].
  static CensorVerdict fromWire({
    required String id,
    required DateTime detectedAt,
    required String wireKind,
    required double wireConfidence,
    required String explanation,
    required List<String> evidence,
  }) {
    final kind = switch (wireKind) {
      'no_interference' => CensorVerdictKind.notBlocked,
      _ when !_blockingWireKinds.contains(wireKind) || wireConfidence < 0.35 => CensorVerdictKind.unknown,
      _ when wireConfidence >= 0.75 => CensorVerdictKind.blocked,
      _ => CensorVerdictKind.likelyBlocked,
    };
    return CensorVerdict(
      id: id,
      detectedAt: detectedAt,
      confidence: (wireConfidence * 100).round().clamp(0, 100),
      kind: kind,
      reasons: [
        if (explanation.isNotEmpty) CensorReason(code: wireKind, detail: explanation),
        for (final item in evidence) CensorReason(code: wireKind, detail: item),
      ],
    );
  }

  static CensorVerdict? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) return null;
    final reasons = json['reasons'];
    return CensorVerdict(
      id: id,
      detectedAt: DateTime.tryParse(json['detectedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      confidence: (json['confidence'] as num? ?? 0).clamp(0, 100).toInt(),
      kind: CensorVerdictKind.fromName(json['kind'] as String? ?? ''),
      reasons: reasons is List
          ? [for (final r in reasons) if (r is Map<String, dynamic>) CensorReason.fromJson(r)]
          : const [],
      recommendedProfileId: json['recommendedProfileId'] as String? ?? '',
    );
  }
}

/// Stores detector verdicts and surfaces the one actionable prompt.
///
/// Verdicts arrive from the core: pushed as the `censorship_detected`
/// payload of CoreEvent (sora.core.v1) and ingested by the session watch
/// through [CensorVerdict.fromWire]. The on-demand DetectCensorship RPC
/// (proto/sora/censor/v1/censor.proto) has no Dart client yet, so the
/// injected [fetchVerdict] poll stays null and polling is a graceful
/// no-op; the push path is what feeds the history.
class CensorDetector extends ChangeNotifier {
  CensorDetector(this._read, this._write) {
    _load();
  }

  /// Recent verdicts first, capped at [historyLimit].
  static const historyLimit = 50;

  final String Function() _read;
  final void Function(String) _write;

  /// Asks the core for a fresh verdict. Set by the core integration once the
  /// detector API exists; null means "no detector on this core".
  Future<CensorVerdict?> Function(CoreLink link)? fetchVerdict;

  final List<CensorVerdict> _history = [];

  /// Newest first.
  List<CensorVerdict> get history => List.unmodifiable(_history);

  /// The verdict currently offered to the user, if any. Never persisted: a
  /// prompt must not ambush the user on the next launch (the notification
  /// history keeps the trace).
  CensorVerdict? _prompt;
  CensorVerdict? get prompt => _prompt;

  void _load() {
    final raw = _read();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            // One malformed entry must not wipe the rest of the history.
            try {
              final verdict = CensorVerdict.fromJson(item);
              if (verdict != null) _history.add(verdict);
            } catch (_) {
              // Skip the bad entry; keep everything else.
            }
          }
        }
      }
    } catch (_) {
      // Corrupt history must not break the detector; start empty.
      _history.clear();
    }
  }

  void _persist() => _write(jsonEncode([for (final v in _history) v.toJson()]));

  /// Records [verdict]. Returns true when it is new and actionable, i.e. the
  /// UI should offer the prompt.
  bool ingest(CensorVerdict verdict) {
    if (verdict.id.isEmpty || _history.any((v) => v.id == verdict.id)) return false;
    _history.insert(0, verdict);
    if (_history.length > historyLimit) _history.removeRange(historyLimit, _history.length);
    _persist();
    final offer = verdict.actionable && _prompt?.id != verdict.id;
    if (offer) _prompt = verdict;
    notifyListeners();
    return offer;
  }

  /// Polls the core detector after a failed connection. A missing detector
  /// or a detector miss is not user-actionable — the connection failure
  /// itself is already reported — so failures stay silent here instead of
  /// surfacing as [CoreFailure] noise.
  Future<CensorVerdict?> pollAfterFailure(CoreLink? link) async {
    final fetch = fetchVerdict;
    if (fetch == null || link == null) return null;
    try {
      return await fetch(link);
    } catch (_) {
      return null;
    }
  }

  void dismissPrompt() {
    if (_prompt == null) return;
    _prompt = null;
    notifyListeners();
  }
}
