import 'dart:convert';
import 'dart:io';

import '../rules.dart';

/// Conversion of a Happ routing profile (the Remnawave panel's
/// happRouting document) into sora user rules. This is the Dart mirror
/// of core/happrouting: same reconstructed schema, same classification,
/// same honest notes — a field is either turned into rules or reported
/// as recorded-but-not-applied with the reason, never dropped silently.
///
/// Schema (HappRoutingData in the panel's HAPP Routing Builder):
/// Name, GlobalProxy, FakeDNS, UseChunkFiles, RemoteDNSType /
/// RemoteDNSIP (also spelled RemoteDNSIp), DomesticDNSType /
/// DomesticDNSIP, Geoipurl, Geositeurl, LastUpdated, DirectSites,
/// DirectIp, ProxySites, ProxyIp, BlockSites, BlockIp, DnsHosts,
/// DomainStrategy. Transport: JSON → base64 → happ://routing/add/….

/// How one field of the source document was handled.
class HappRoutingNote {
  const HappRoutingNote(this.field, {required this.applied, this.reason = ''});

  final String field;
  final bool applied;
  final String reason;
}

/// The result of converting one routing profile.
class HappRoutingImport {
  const HappRoutingImport({
    required this.name,
    required this.rules,
    required this.notes,
    required this.globalProxy,
    required this.remoteDns,
    required this.domesticDns,
    required this.skipped,
  });

  /// Profile name from the document ('' when it carries none).
  final String name;

  /// Converted rules, block first, then direct, then proxy — the
  /// order they are merged into the user's rule list.
  final List<UserRule> rules;

  final List<HappRoutingNote> notes;

  /// The document's default-traffic decision, or null when absent.
  final bool? globalProxy;

  /// Provider resolvers verbatim ("DoH https://…"), recorded, not
  /// applied: sora's DNS is one user-owned per-session list with no
  /// remote/domestic split.
  final String remoteDns;
  final String domesticDns;

  /// List entries that could not be classified at all.
  final int skipped;

  int countOf(RuleTarget target) => rules.where((r) => r.target == target).length;
}

/// Decodes and converts the payload of a happ://routing/add/ link.
/// Returns null when the payload is not a Happ routing document at
/// all (bad base64, bad JSON, wrong shape): the import then fails
/// honestly instead of applying a partial profile.
HappRoutingImport? convertHappRouting(String payload) {
  final profile = _decode(payload);
  if (profile == null) return null;
  return _convert(profile);
}

Map<String, dynamic>? _decode(String payload) {
  var text = payload.trim();
  if (text.isEmpty) return null;
  if (text.contains('%')) {
    try {
      text = Uri.decodeComponent(text);
    } on FormatException {
      return null;
    }
  }
  String jsonText;
  if (text.startsWith('{')) {
    jsonText = text;
  } else {
    try {
      var normalized = text.replaceAll(RegExp(r'\s'), '').replaceAll('-', '+').replaceAll('_', '/');
      normalized = normalized.padRight(normalized.length + (4 - normalized.length % 4) % 4, '=');
      jsonText = utf8.decode(base64Decode(normalized));
    } on FormatException {
      return null;
    }
  }
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) return null;
    // Keys match case-insensitively (the builder itself tolerates
    // the RemoteDNSIP / RemoteDNSIp spelling drift).
    return {for (final e in decoded.entries) e.key.toLowerCase(): e.value};
  } on FormatException {
    return null;
  }
}

bool? _boolOf(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' || '' => false,
      _ => null,
    };
  }
  return null;
}

String _stringOf(Object? value) => value is String ? value.trim() : '';

List<String> _listOf(Object? value) {
  if (value is List) {
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
  if (value is String) return value.split(RegExp(r'[\n\r,]'));
  return const [];
}

HappRoutingImport _convert(Map<String, dynamic> doc) {
  final rules = <UserRule>[];
  final seen = <String>{};
  var skipped = 0;
  void add(List<String> entries, RuleTarget target) {
    for (final entry in entries) {
      if (rules.length >= 10000) {
        skipped++;
        continue;
      }
      final destination = _destinationOf(entry);
      if (destination == null) {
        skipped++;
        continue;
      }
      if (seen.add('${target.name} $destination')) {
        rules.add(UserRule(target, destination));
      }
    }
  }

  add(_listOf(doc['blocksites']), RuleTarget.block);
  add(_listOf(doc['blockip']), RuleTarget.block);
  add(_listOf(doc['directsites']), RuleTarget.direct);
  add(_listOf(doc['directip']), RuleTarget.direct);
  add(_listOf(doc['proxysites']), RuleTarget.proxy);
  add(_listOf(doc['proxyip']), RuleTarget.proxy);

  final globalProxy = _boolOf(doc['globalproxy']);
  final remoteType = _stringOf(doc['remotednstype']);
  final remoteIp = _stringOf(doc['remotednsip']);
  final domesticType = _stringOf(doc['domesticdnstype']);
  final domesticIp = _stringOf(doc['domesticdnsip']);
  String dns(String type, String ip) => type.isEmpty ? ip : '$type $ip';

  final notes = <HappRoutingNote>[
    if (rules.isNotEmpty) const HappRoutingNote('Direct/Proxy/Block lists', applied: true),
    if (globalProxy == true)
      const HappRoutingNote(
        'GlobalProxy',
        applied: true,
        reason: "true matches sora's default: unmatched traffic goes to the proxy target",
      ),
    if (globalProxy == false)
      const HappRoutingNote(
        'GlobalProxy',
        applied: false,
        reason: "false asks for a direct default; sora's plan default is the proxy target, so the decision is recorded with the profile but not applied",
      ),
    if (remoteIp.isNotEmpty)
      const HappRoutingNote(
        'RemoteDNS',
        applied: false,
        reason:
            "recorded with the profile; sora DNS is a single user-owned per-session list with no remote/domestic split",
      ),
    if (domesticIp.isNotEmpty)
      const HappRoutingNote(
        'DomesticDNS',
        applied: false,
        reason:
            "recorded with the profile; sora DNS is a single user-owned per-session list with no remote/domestic split",
      ),
    if (_boolOf(doc['fakedns']) == true)
      const HappRoutingNote(
        'FakeDNS',
        applied: false,
        reason: "sora's DNS policy has no fake-IP mode; engines resolve real addresses",
      ),
    if (doc['dnshosts'] != null)
      const HappRoutingNote(
        'DnsHosts',
        applied: false,
        reason: 'kept verbatim with the profile; its exact shape is not established by the open sources and sora has no static-hosts slot',
      ),
    if (_stringOf(doc['domainstrategy']).isNotEmpty)
      const HappRoutingNote(
        'DomainStrategy',
        applied: false,
        reason: 'kept with the profile; sora engines choose the domain strategy, the plan contract has no such knob',
      ),
    if (_stringOf(doc['geoipurl']).isNotEmpty || _stringOf(doc['geositeurl']).isNotEmpty)
      const HappRoutingNote(
        'Geoipurl/Geositeurl',
        applied: false,
        reason: 'sora ships its own geo data with the engines and does not download provider geo files; geosite:/geoip: rules still match against the shipped data',
      ),
    if (_boolOf(doc['usechunkfiles']) == true)
      const HappRoutingNote(
        'UseChunkFiles',
        applied: false,
        reason: 'a Happ geo-loading optimisation with no sora counterpart; no behavioural effect to reproduce',
      ),
    if (skipped > 0)
      HappRoutingNote(
        'list entries',
        applied: false,
        reason: '$skipped entries were neither a domain, an address, a network, nor a geo category and were skipped',
      ),
  ];

  return HappRoutingImport(
    name: _stringOf(doc['name']),
    rules: rules,
    notes: notes,
    globalProxy: globalProxy,
    remoteDns: dns(remoteType, remoteIp),
    domesticDns: dns(domesticType, domesticIp),
    skipped: skipped,
  );
}

/// Classifies one list entry into the core contract's destination
/// form, by shape (not by which list it arrived in), mirroring
/// core/happrouting's destinationOf.
String? _destinationOf(String entry) {
  var text = entry.trim();
  if (text.isEmpty || text.length > 512 || text.contains(RegExp(r'\s'))) return null;
  for (final prefix in ['geosite:', 'geoip:', 'domain:', 'full:', 'ruleset:']) {
    if (text.length > prefix.length && text.toLowerCase().startsWith(prefix)) {
      return '$prefix${text.substring(prefix.length)}';
    }
  }
  final link = Uri.tryParse(text);
  if (link != null && (link.isScheme('http') || link.isScheme('https')) && link.host.isNotEmpty) {
    text = link.host;
  }
  if (text.startsWith('*.')) text = text.substring(2);
  if (text.contains('/')) {
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final ip = InternetAddress.tryParse(parts[0]);
    final bits = int.tryParse(parts[1]);
    if (ip == null || bits == null) return null;
    final max = ip.type == InternetAddressType.IPv6 ? 128 : 32;
    return bits >= 0 && bits <= max ? text : null;
  }
  final ip = InternetAddress.tryParse(text);
  if (ip != null) return '${ip.address}/${ip.type == InternetAddressType.IPv6 ? 128 : 32}';
  if (!text.contains('.') || text.startsWith('.') || text.endsWith('.')) return null;
  final label = RegExp(r'^[\p{L}\p{Nd}](?:[\p{L}\p{M}\p{Nd}-]*[\p{L}\p{M}\p{Nd}])?$', unicode: true);
  final labels = text.split('.');
  if (labels.any((part) => part.isEmpty || part.length > 63 || !label.hasMatch(part))) return null;
  if (text.runes.length > 253) return null;
  return 'domain:${text.toLowerCase()}';
}
