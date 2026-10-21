/// JSON conversion for the Anti-DPI bypass contract (bridge methods
/// `getBypassLayer` / `applyBypassLayer` / `tuneDesync`).
///
/// This is the single place where a [BypassStrategy] crosses between its
/// proto form (sora.core.v1, generated) and the snake_case JSON shape the
/// panel bridge contract fixes. The field list is exactly the 29 fields
/// of the proto message, in proto order; the parity test in
/// app/test/antidpi_bridge_test.dart round-trips all of them so a proto
/// field added later cannot silently drop out of the panel API.
library;

import '../generated/sora/core/v1/core_control.pb.dart';

/// Serializes [s] with every field present (proto defaults included), so
/// the panel always sees the full strategy shape and a round-trip
/// through [bypassStrategyFromJson] is lossless.
Map<String, dynamic> bypassStrategyToJson(BypassStrategy s) => {
  'split_pos': List<String>.of(s.splitPos),
  'disorder': s.disorder,
  'oob': s.oob,
  'tls_record': s.tlsRecord,
  'host_case': s.hostCase,
  'domain_case': s.domainCase,
  'method_eol': s.methodEol,
  'disorder_scope': s.disorderScope,
  'oob_scope': s.oobScope,
  'host_dot': s.hostDot,
  'host_tab': s.hostTab,
  'host_no_space': s.hostNoSpace,
  'method_space': s.methodSpace,
  'unix_eol': s.unixEol,
  'split_any_protocol': s.splitAnyProtocol,
  'tamper_start': s.tamperStart,
  'tamper_cutoff': s.tamperCutoff,
  'oob_data': s.oobData,
  'mss': s.mss,
  'desync': List<String>.of(s.desync),
  'fake_tls': s.fakeTls,
  'fake_quic': s.fakeQuic,
  'fooling': s.fooling,
  'ttl': s.ttl,
  'auto_ttl': s.autoTtl,
  'repeats': s.repeats,
  'filter_tcp': s.filterTcp,
  'filter_udp': s.filterUdp,
  'filter_l7': s.filterL7,
};

const _strategyFields = {
  'split_pos',
  'disorder',
  'oob',
  'tls_record',
  'host_case',
  'domain_case',
  'method_eol',
  'disorder_scope',
  'oob_scope',
  'host_dot',
  'host_tab',
  'host_no_space',
  'method_space',
  'unix_eol',
  'split_any_protocol',
  'tamper_start',
  'tamper_cutoff',
  'oob_data',
  'mss',
  'desync',
  'fake_tls',
  'fake_quic',
  'fooling',
  'ttl',
  'auto_ttl',
  'repeats',
  'filter_tcp',
  'filter_udp',
  'filter_l7',
};

List<String> _strList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return const [];
  if (v is List && v.every((e) => e is String)) return List<String>.of(v.cast<String>());
  throw FormatException('bypass strategy field "$key" must be a list of strings');
}

bool _bool(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return false;
  if (v is bool) return v;
  throw FormatException('bypass strategy field "$key" must be a boolean');
}

String _str(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return '';
  if (v is String) return v;
  throw FormatException('bypass strategy field "$key" must be a string');
}

int _int(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num && v == v.roundToDouble()) return v.toInt();
  throw FormatException('bypass strategy field "$key" must be an integer');
}

/// Parses the bridge JSON shape into a [BypassStrategy]. Missing fields
/// take proto defaults; unknown fields and wrong types throw
/// [FormatException] (the panel host maps that to
/// BridgeError('invalid-argument')) — a panel typo must fail loudly, not
/// silently drop half a strategy.
BypassStrategy bypassStrategyFromJson(Map<String, dynamic> j) {
  for (final k in j.keys) {
    if (!_strategyFields.contains(k)) {
      throw FormatException('unknown bypass strategy field "$k"');
    }
  }
  return BypassStrategy(
    splitPos: _strList(j, 'split_pos'),
    disorder: _bool(j, 'disorder'),
    oob: _bool(j, 'oob'),
    tlsRecord: _str(j, 'tls_record'),
    hostCase: _bool(j, 'host_case'),
    domainCase: _bool(j, 'domain_case'),
    methodEol: _bool(j, 'method_eol'),
    disorderScope: _str(j, 'disorder_scope'),
    oobScope: _str(j, 'oob_scope'),
    hostDot: _bool(j, 'host_dot'),
    hostTab: _bool(j, 'host_tab'),
    hostNoSpace: _bool(j, 'host_no_space'),
    methodSpace: _bool(j, 'method_space'),
    unixEol: _bool(j, 'unix_eol'),
    splitAnyProtocol: _bool(j, 'split_any_protocol'),
    tamperStart: _str(j, 'tamper_start'),
    tamperCutoff: _str(j, 'tamper_cutoff'),
    oobData: _str(j, 'oob_data'),
    mss: _str(j, 'mss'),
    desync: _strList(j, 'desync'),
    fakeTls: _str(j, 'fake_tls'),
    fakeQuic: _str(j, 'fake_quic'),
    fooling: _str(j, 'fooling'),
    ttl: _int(j, 'ttl'),
    autoTtl: _bool(j, 'auto_ttl'),
    repeats: _int(j, 'repeats'),
    filterTcp: _str(j, 'filter_tcp'),
    filterUdp: _str(j, 'filter_udp'),
    filterL7: _str(j, 'filter_l7'),
  );
}

/// One per-destination binding of a bypass layer: destinations matching
/// [match] (the core's destination form, e.g. "domain:example.com") use
/// [strategy] instead of the layer's global strategy.
typedef BypassBinding = ({String match, BypassStrategy strategy});

Map<String, dynamic> bypassBindingToJson(BypassBinding b) => {
  'match': b.match,
  'strategy': bypassStrategyToJson(b.strategy),
};

/// Serializes a whole bypass layer in the bridge shape:
/// `{global: {...}|null, bindings: [{match, strategy}], updated_at}`.
/// [updatedAt] renders as an RFC 3339 UTC string; null omits the key
/// (a layer that was never applied has no timestamp to show).
Map<String, dynamic> bypassLayerToJson({
  required BypassStrategy? global,
  required List<BypassBinding> bindings,
  DateTime? updatedAt,
}) => {
  'global': global == null ? null : bypassStrategyToJson(global),
  'bindings': [for (final b in bindings) bypassBindingToJson(b)],
  if (updatedAt != null) 'updated_at': updatedAt.toUtc().toIso8601String(),
};

/// Parses and validates a layer in the bridge shape (the argument of
/// `applyBypassLayer`, also the result shape of `getBypassLayer` minus
/// `updated_at`). Throws [FormatException] on any shape violation.
({BypassStrategy? global, List<BypassBinding> bindings}) bypassLayerFromJson(Map<String, dynamic> j) {
  for (final k in j.keys) {
    if (k != 'global' && k != 'bindings' && k != 'updated_at') {
      throw FormatException('unknown bypass layer field "$k"');
    }
  }
  final rawGlobal = j['global'];
  final BypassStrategy? global;
  if (rawGlobal == null) {
    global = null;
  } else if (rawGlobal is Map<String, dynamic>) {
    global = bypassStrategyFromJson(rawGlobal);
  } else {
    throw const FormatException('bypass layer "global" must be an object or null');
  }
  final bindings = <BypassBinding>[];
  final rawBindings = j['bindings'];
  if (rawBindings != null) {
    if (rawBindings is! List) {
      throw const FormatException('bypass layer "bindings" must be a list');
    }
    for (final e in rawBindings) {
      if (e is! Map<String, dynamic>) {
        throw const FormatException('bypass binding must be an object');
      }
      final match = e['match'];
      if (match is! String || match.isEmpty) {
        throw const FormatException('bypass binding "match" must be a non-empty string');
      }
      final rawStrategy = e['strategy'];
      if (rawStrategy is! Map<String, dynamic>) {
        throw const FormatException('bypass binding "strategy" must be an object');
      }
      bindings.add((match: match, strategy: bypassStrategyFromJson(rawStrategy)));
    }
  }
  return (global: global, bindings: bindings);
}
