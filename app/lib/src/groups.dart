import 'generated/sora/core/v1/core_control.pb.dart';

/// Server-name suffixes such as "(main)" or "(запасной)" set failover priority
/// within same-name subscription groups. Without roles, use the fastest
/// reachable member. Names remain compatible with Happ and other clients.
enum Role { main, backup }

/// A server-list entry for one server or a same-name group in a subscription.
class Entry {
  Entry._(this.id, this.name, this.members, this.roles);

  /// The server ID, or `group:<subscription>:<name>` for a group.
  final String id;
  final String name;
  final List<OutboundSpec> members;

  /// Roles parsed from member names; empty when no name specifies a role.
  final Map<String, Role> roles;

  bool get isGroup => members.length > 1;
  bool get ordered => roles.isNotEmpty;

  /// Copy with the user-facing name replaced, keeping the entry id.
  Entry renamed(String name) => Entry._(id, name, members, roles);

  /// Applies [renames] (server id -> display name), returning the entries to
  /// display. A renamed member leaves its group and becomes a standalone
  /// entry right after it: group titles keep the shared provider name so
  /// grouping stays stable, and without the split the rename would be
  /// silently swallowed. Single-member entries are renamed in place, keeping
  /// their id.
  List<Entry> applyRenames(Map<String, String> renames) {
    if (members.length == 1) {
      final name = renames[members.single.id];
      return [name == null ? this : renamed(name)];
    }
    final splits = <Entry>[];
    final rest = <OutboundSpec>[];
    for (final member in members) {
      final name = renames[member.id];
      if (name == null) {
        rest.add(member);
      } else {
        splits.add(Entry._(member.id, name, [member], const {}));
      }
    }
    if (rest.isEmpty) return splits;
    final group = rest.length == members.length
        ? this
        : Entry._(id, name, rest, {
            for (final member in rest)
              if (roles[member.id] != null) member.id: roles[member.id]!,
          });
    return [group, ...splits];
  }

  /// Copy without [hidden] members, or null when none remain.
  Entry? withoutHidden(Set<String> hidden) {
    if (hidden.isEmpty) return this;
    final visible = [
      for (final o in members)
        if (!hidden.contains(o.id)) o,
    ];
    if (visible.isEmpty) return null;
    if (visible.length == members.length) return this;
    return Entry._(id, name, visible, {
      for (final o in visible)
        if (roles[o.id] != null) o.id: roles[o.id]!,
    });
  }

  /// Copy without custom (SW7) members, or null when none remain. INT-1
  /// merges custom servers into every subscription's outbound list so the
  /// plan builder sees them; subscription views drop them because the UI
  /// already shows them in the «Мои серверы» card — keeping them would list
  /// every custom server twice (once per subscription). Entries with no
  /// custom members return [this], so callers can skip rebuilding.
  Entry? withoutCustom() {
    if (id.startsWith(customServerPrefix)) return null;
    final rest = [
      for (final o in members)
        if (!o.id.startsWith(customServerPrefix)) o,
    ];
    if (rest.length == members.length) return this;
    if (rest.isEmpty) return null;
    return Entry._(id, name, rest, {
      for (final o in rest)
        if (roles[o.id] != null) o.id: roles[o.id]!,
    });
  }

  /// Returns main members first, then backups. Unlabelled members of a group
  /// with roles are treated as backups.
  List<OutboundSpec> get byRole => [
    for (final o in members)
      if (roles[o.id] == Role.main) o,
    for (final o in members)
      if (roles[o.id] != Role.main) o,
  ];
}

const groupPrefix = 'group:';

/// Id prefix the core assigns to custom (user-added, SW7) servers when it
/// merges them into subscription outbound lists (INT-1): `custom/<server id>`.
const customServerPrefix = 'custom/';

/// Canonical id for a server selection in the core's outbound namespace.
///
/// INT-1: the core merges custom (user-added, SW7) servers into subscription
/// outbound lists as `custom/<server id>`, but the UI stores custom servers
/// with plain ids. A plain custom id must therefore map to the prefixed form
/// for anything that speaks the outbound namespace — the plan builder, the
/// latency maps, selection comparisons. Everything else (subscription
/// servers, groups, auto/bypass) already uses outbound-namespace ids and
/// passes through unchanged, so existing subscription selections are
/// unaffected.
///
/// [customIds] are the plain ids of the currently stored custom servers.
String canonicalCustomId(String id, Iterable<String> customIds) {
  if (id.startsWith(customServerPrefix)) return id;
  return customIds.contains(id) ? '$customServerPrefix$id' : id;
}

final _role = RegExp(
  r'\s*[\(\[\-–\u2014\u00b7|:,]?\s*(основн(?:ой|ая|ое)|главн(?:ый|ая|ое)|запасн(?:ой|ая|ое)|резерв(?:ный|ная|ное)?|main|primary|backup|reserve|fallback)\s*[\)\]]?\s*$',
  caseSensitive: false,
  unicode: true,
);

/// Splits a trailing role suffix from a server name; returns null for no role.
(String, Role?) splitRole(String name) {
  final m = _role.firstMatch(name);
  if (m == null || m.start == 0) return (name.trim(), null);
  final word = m.group(1)!.toLowerCase();
  final role =
      word.startsWith('запас') || word.startsWith('резерв') || const {'backup', 'reserve', 'fallback'}.contains(word)
      ? Role.backup
      : Role.main;
  return (name.substring(0, m.start).trim(), role);
}

/// Groups subscription servers by name, preserving their list order.
///
/// The grouping depends only on [subscription.outbounds], and subscription
/// states are replaced wholesale (never mutated in place) when they change,
/// so the result is cached per state object. Rebuilding it runs a Unicode
/// regex per server; without the cache every server-list rebuild (probe ticks
/// arrive every 300ms, plus home-screen builds) would redo all of them.
final _groupedEntries = Expando<List<Entry>>('sora.groupedEntries');

List<Entry> entriesOf(SubscriptionState subscription) => _groupedEntries[subscription] ??= _groupEntries(subscription);

List<Entry> _groupEntries(SubscriptionState subscription) {
  final byName = <String, List<OutboundSpec>>{};
  final roles = <String, Role>{};
  for (final o in subscription.outbounds) {
    final (name, role) = splitRole(o.displayName);
    byName.putIfAbsent(name, () => []).add(o);
    if (role != null) roles[o.id] = role;
  }
  return [
    for (final MapEntry(key: name, value: members) in byName.entries)
      members.length == 1
          ? Entry._(members.single.id, members.single.displayName, members, const {})
          : Entry._('$groupPrefix${subscription.settings.id}:$name', name, members, {
              for (final o in members)
                if (roles[o.id] != null) o.id: roles[o.id]!,
            }),
  ];
}

/// Finds the entry matching a selection across subscriptions; null if absent.
Entry? entryOf(String choice, Iterable<SubscriptionState> subscriptions) {
  for (final s in subscriptions) {
    for (final e in entriesOf(s)) {
      if (e.id == choice) return e;
    }
  }
  return null;
}
