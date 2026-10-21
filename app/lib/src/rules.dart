import 'dart:io';

/// The action applied to traffic matching a rule.
enum RuleTarget { direct, proxy, block }

/// A user routing rule with a target and a core-contract destination.
class UserRule {
  const UserRule(this.target, this.destination);

  final RuleTarget target;

  /// For example "domain:bank.ru", "203.0.113.0/24" or "process:telegram".
  final String destination;

  /// Parses a stored rule; returns null for unsupported or invalid formats,
  /// including those from newer releases.
  static UserRule? parse(String stored) {
    final space = stored.indexOf(' ');
    if (space <= 0) return null;
    final target = RuleTarget.values.where((t) => t.name == stored.substring(0, space)).firstOrNull;
    final destination = stored.substring(space + 1).trim();
    if (target == null || destination.isEmpty) return null;
    return UserRule(target, destination);
  }

  /// Shared CIDR overlap check for extension diagnostics; parsing remains in
  /// destinationOf, which is also used by the user rule editor.
  static bool networksOverlap(String a, String b) {
    List<int>? network(String value) {
      final parts = value.split('/');
      if (parts.length != 2) return null;
      final ip = InternetAddress.tryParse(parts[0]), bits = int.tryParse(parts[1]);
      if (ip == null || bits == null || bits < 0 || bits > ip.rawAddress.length * 8) return null;
      return [bits, ...ip.rawAddress];
    }

    final x = network(a), y = network(b);
    if (x == null || y == null || x.length != y.length) return false;
    final bits = x.first < y.first ? x.first : y.first;
    for (var i = 0; i < bits; i++) {
      final mask = 1 << (7 - i % 8);
      if (x[1 + i ~/ 8] & mask != y[1 + i ~/ 8] & mask) return false;
    }
    return true;
  }

  String get stored => '${target.name} $destination';

  /// The destination text with its core-contract prefix removed.
  String get shown => destination.replaceFirst(RegExp(r'^(domain|full|process):'), '');

  /// Converts input to a core destination: IPs and CIDRs become networks,
  /// dotted names match domains and subdomains, and bare names match processes.
  /// URLs use their host; invalid input returns null.
  static String? destinationOf(String input) {
    var text = input.trim();
    if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
    for (final prefix in ['domain:', 'full:', 'process:']) {
      if (!text.startsWith(prefix)) continue;
      final value = text.substring(prefix.length);
      if (prefix == 'process:') {
        return RegExp(r'^[A-Za-z0-9._+-]{1,64}$').hasMatch(value) ? text : null;
      }
      final parsed = destinationOf(value);
      return parsed != null && parsed.startsWith('domain:') ? '$prefix${parsed.substring(7)}' : null;
    }
    final link = Uri.tryParse(text);
    if (link != null && link.hasScheme && link.host.isNotEmpty) text = link.host;
    if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length != 2) return null;
      final [address, bits] = parts;
      final ip = InternetAddress.tryParse(address);
      final n = int.tryParse(bits);
      final max = ip?.type == InternetAddressType.IPv6 ? 128 : 32;
      return ip != null && n != null && n >= 0 && n <= max ? '${ip.address}/$n' : null;
    }
    final ip = InternetAddress.tryParse(text);
    if (ip != null) return '${ip.address}/${ip.type == InternetAddressType.IPv6 ? 128 : 32}';
    // Recognize Windows .exe process names before treating dotted names as
    // domains.
    if (RegExp(r'^[A-Za-z0-9._+-]{1,64}\.exe$', caseSensitive: false).hasMatch(text)) return 'process:$text';
    text = text.replaceFirst(RegExp(r'^\*?\.'), '');
    if (RegExp(r'^[\x00-\x7f]+$').hasMatch(text)) text = text.toLowerCase();
    if (text.contains('.')) {
      final labels = text.split('.');
      final label = RegExp(r'^[\p{L}\p{Nd}](?:[\p{L}\p{M}\p{Nd}-]*[\p{L}\p{M}\p{Nd}])?$', unicode: true);
      return text.runes.length <= 253 && labels.every((part) => part.runes.length <= 63 && label.hasMatch(part))
          ? 'domain:$text'
          : null;
    }
    return RegExp(r'^[A-Za-z0-9._+-]{1,64}$').hasMatch(input.trim()) ? 'process:${input.trim()}' : null;
  }
}
