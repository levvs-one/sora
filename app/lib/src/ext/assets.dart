import 'dart:convert';

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../rules.dart';

/// Flutter consumes color tokens only; CSS stylesheets are deliberately ignored.
class ExtensionTheme {
  const ExtensionTheme(this.name, this.brightness, this.palette);
  final String name;
  final Brightness brightness;
  final Palette palette;

  static ExtensionTheme parse(String source) {
    final doc = jsonDecode(source) as Map<String, dynamic>;
    if (doc.keys.any((k) => !const {'name', 'variant', 'css_variables', 'stylesheet'}.contains(k))) {
      throw const FormatException('unknown theme field');
    }
    final name = doc['name'];
    if (name is! String || name.trim().isEmpty || name.length > 80) throw const FormatException('invalid theme name');
    final brightness = switch (doc['variant']) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => throw const FormatException('variant must be light or dark'),
    };
    final base = brightness == Brightness.dark ? Palette.dark : Palette.light;
    final defaults = <String, Color>{
      '--sora-background': base.background,
      '--sora-surface': base.surface,
      '--sora-field': base.field,
      '--sora-text': base.ink,
      '--sora-text-secondary': base.ink2,
      '--sora-text-muted': base.ink3,
      '--sora-danger': base.danger,
      '--sora-on-danger': base.onDanger,
      '--sora-raised': base.raised,
      '--sora-raised-field': base.raisedField,
    };
    final colors = Map.of(defaults);
    for (final e in (doc['css_variables'] as Map<String, dynamic>).entries) {
      if ((!defaults.containsKey(e.key) && e.key != '--sora-accent') ||
          e.value is! String ||
          !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(e.value as String)) {
        throw FormatException('invalid color token ${e.key}');
      }
      colors[e.key] = Color(0xff000000 | int.parse((e.value as String).substring(1), radix: 16));
    }
    final palette = Palette(
      background: colors['--sora-background']!,
      surface: colors['--sora-surface']!,
      field: colors['--sora-field']!,
      ink: colors['--sora-text']!,
      ink2: colors['--sora-text-secondary']!,
      ink3: colors['--sora-text-muted']!,
      danger: colors['--sora-danger']!,
      onDanger: colors['--sora-on-danger']!,
      raised: colors['--sora-raised']!,
      raisedField: colors['--sora-raised-field']!,
      shadow: base.shadow,
      scrim: base.scrim,
      accent: colors['--sora-accent'],
    );
    for (final bg in [palette.background, palette.surface, palette.raised]) {
      for (final fg in [palette.ink, palette.ink2, palette.ink3, palette.danger]) {
        if (_contrast(fg, bg) < 4.5) throw const FormatException('theme text contrast below 4.5:1');
      }
    }
    for (final bg in [palette.field, palette.raisedField]) {
      if (_contrast(palette.ink, bg) < 4.5) throw const FormatException('theme field contrast below 4.5:1');
    }
    if (_contrast(palette.onDanger, palette.danger) < 4.5) {
      throw const FormatException('theme error label contrast below 4.5:1');
    }
    return ExtensionTheme(name, brightness, palette);
  }

  static double _contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
  }
}

class ExtensionRoutingRule {
  const ExtensionRoutingRule(this.extensionId, this.rule, this.comment);
  final String extensionId;
  final UserRule rule;
  final String comment;
}

class ExtensionRouting {
  const ExtensionRouting(this.priority, this.rules);
  final int priority;
  final List<ExtensionRoutingRule> rules;

  static ExtensionRouting parse(String id, String source) {
    final doc = jsonDecode(source) as Map<String, dynamic>;
    if (doc.keys.any((k) => !const {'rules', 'priority'}.contains(k))) {
      throw const FormatException('unknown routing field');
    }
    final priority = doc['priority'] ?? 0;
    if (priority is! int || priority < -1000 || priority > 1000) {
      throw const FormatException('invalid routing priority');
    }
    final rows = doc['rules'] as List;
    if (rows.length > 256) throw const FormatException('too many routing rules');
    final rules = <ExtensionRoutingRule>[];
    for (final row in rows) {
      final r = row as Map<String, dynamic>;
      if (r.keys.any((k) => !const {'match', 'action', 'comment'}.contains(k))) {
        throw const FormatException('unknown rule field');
      }
      final target = RuleTarget.values.where((t) => t.name == r['action']).firstOrNull;
      final match = r['match'];
      final comment = r['comment'] ?? '';
      if (target == null || match is! String || comment is! String || comment.length > 500) {
        throw const FormatException('invalid routing rule');
      }
      final destination = UserRule.destinationOf(match);
      if (destination == null) throw const FormatException('invalid routing match');
      rules.add(ExtensionRoutingRule(id, UserRule(target, destination), comment));
    }
    return ExtensionRouting(priority, rules);
  }
}

/// Overlaps are logged even when the two actions agree. A suffix domain and
/// its subdomain, or intersecting CIDRs, still obey the same first-match order.
bool routingMatchesOverlap(String a, String b) {
  if (a == b) return true;
  final aDomain = a.startsWith('domain:'), bDomain = b.startsWith('domain:');
  final aFull = a.startsWith('full:'), bFull = b.startsWith('full:');
  if ((aDomain || aFull) && (bDomain || bFull)) {
    final x = a.substring(a.indexOf(':') + 1), y = b.substring(b.indexOf(':') + 1);
    return x == y || (aDomain && y.endsWith('.$x')) || (bDomain && x.endsWith('.$y'));
  }
  return UserRule.networksOverlap(a, b);
}
