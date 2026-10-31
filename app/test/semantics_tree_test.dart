// The Windows embedder feeds every semantics update to ui::AXTree, which
// rejects updates that are not valid tree edits. A rejected update leaves the
// tree stale ("Failed to update ui::AXTree") and the process faults soon
// after. Widget tests do not run that code, so this file replays what
// shell/platform/common/accessibility_bridge.cc and ax_tree.cc do with each
// update and fails on the same errors, on any platform.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/semantics_tree.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ui/language.dart';

import 'fixtures/desktop_state.dart';

class _Node {
  _Node(this.id, this.children, this.label);
  final int id;
  final List<int> children;
  final String label;
}

/// ui::AXTree as far as tree edits go, driven the way AccessibilityBridge
/// drives it: reparented nodes are removed in one update and added in a second.
class _AxTree {
  var _kids = <int, List<int>>{};
  final _labels = <int, String>{};
  final errors = <String>[];
  var updates = 0;
  int get size => _kids.length;

  int? _parentOf(int id) {
    for (final entry in _kids.entries) {
      if (entry.value.contains(id)) return entry.key;
    }
    return null;
  }

  void commit(Map<int, _Node> pending) {
    if (errors.isNotEmpty) return;
    updates++;
    for (final node in pending.values) {
      _labels[node.id] = node.label;
    }
    final removals = <int, _Node>{};
    for (final node in pending.values) {
      for (final child in node.children) {
        if (!_kids.containsKey(child)) continue;
        final parent = _parentOf(child);
        if (parent == null || parent == node.id) continue;
        final edited = removals[parent] ??= _Node(parent, List.of(_kids[parent]!), '');
        edited.children.remove(child);
      }
    }
    if (removals.isNotEmpty && !_unserialize(removals.values.toList())) return;
    // GetSubTreeList: parents always come before the children they list.
    final rest = Map.of(pending);
    final subtrees = <List<_Node>>[];
    void collect(_Node node, List<_Node> out) {
      out.add(node);
      for (final child in node.children) {
        final next = rest.remove(child);
        if (next != null) collect(next, out);
      }
    }

    while (rest.isNotEmpty) {
      final first = rest.remove(rest.keys.first)!;
      final out = <_Node>[];
      collect(first, out);
      subtrees.add(out);
    }
    _unserialize([for (final subtree in subtrees.reversed) ...subtree]);
  }

  bool _unserialize(List<_Node> nodes) {
    final kids = {for (final entry in _kids.entries) entry.key: List.of(entry.value)};
    final waiting = <int>{};
    void destroy(int id) {
      for (final child in kids.remove(id) ?? const <int>[]) {
        destroy(child);
      }
    }

    bool fail(String message) {
      errors.add(message);
      return false;
    }

    for (final node in nodes) {
      final root = _kids.isEmpty && node.id == 0;
      if (!kids.containsKey(node.id) && !waiting.contains(node.id) && !root) {
        return fail('${node.id} will not be in the tree and is not the new root (${describe(node.id)})');
      }
      final old = kids[node.id] ?? const <int>[];
      for (final child in old) {
        if (!node.children.contains(child)) destroy(child);
      }
      for (final child in node.children) {
        if (old.contains(child)) continue;
        if (kids.containsKey(child)) {
          return fail('Node $child is not marked for destruction, would be reparented to ${node.id}');
        }
        waiting.add(child);
      }
      kids[node.id] = List.of(node.children);
      waiting.remove(node.id);
    }
    if (waiting.isNotEmpty) {
      return fail('Nodes left pending by the update: ${waiting.map(describe).join(', ')}');
    }
    _kids = kids;
    return true;
  }

  String describe(int id) {
    final label = _labels[id];
    final parent = _parentOf(id);
    return '#$id "${label ?? ''}", in the tree under ${parent == null ? 'nothing' : '#$parent "${_labels[parent] ?? ''}"'}';
  }
}

var _tree = _AxTree();
final _guard = SemanticsTreeGuard();

/// Records Flutter's own lists instead of the workaround's.
var _raw = false;

class _Recorder implements ui.SemanticsUpdateBuilder {
  final _real = ui.SemanticsUpdateBuilder();
  final _nodes = <int, _Node>{};

  @override
  dynamic noSuchMethod(Invocation call) {
    if (call.memberName == #updateNode) {
      final args = call.namedArguments;
      final id = args[#id] as int;
      _nodes[id] = _Node(id, (args[#childrenInTraversalOrder] as Int32List).toList(), args[#label] as String);
      return null;
    }
    if (call.memberName == #build) {
      _tree.commit(_nodes);
      return _real.build();
    }
    if (call.memberName == #updateCustomAction) return null;
    return super.noSuchMethod(call);
  }
}

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() => _raw ? _Recorder() : _guard.wrap(_Recorder());
}

void main() {
  _Binding();
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    _tree = _AxTree();
    _guard.reset();
  });

  Future<Future<void> Function(Finder)> start(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1008, 680);
    addTearDown(tester.view.reset);
    final bytes = File('../extensions/catalog-1.1.3.json').readAsBytesSync();
    final (settings, store) = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('sora-semantics-');
      addTearDown(() => dir.delete(recursive: true));
      final store = ExtensionStore(dir: dir.path);
      await store.catalogCache.store(Uint8List.fromList(bytes));
      await store.load();
      final settings = await Settings.load();
      await settings.completeTour();
      return (settings, store);
    }))!;
    final sora = DesktopState(settings, extensions: store);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pump(const Duration(seconds: 1));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    return (Finder target) async {
      await mouse.moveTo(tester.getCenter(target));
      await tester.pump(const Duration(seconds: 2));
    };
  }

  testWidgets('tooltips and menus keep every update a valid tree edit', (tester) async {
    final semantics = tester.ensureSemantics();
    final hover = await start(tester);
    Future<void> click(Finder target) async {
      await hover(target);
      await tester.tap(target, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
    }

    void valid(String where) => expect(_tree.errors, isEmpty, reason: where);
    expect(_tree.updates, greaterThan(0), reason: 'the recorder must see the updates');

    await hover(find.byKey(const ValueKey('probe-all')));
    valid('a tooltip on the home screen');
    await click(find.byKey(const ValueKey('add-menu')));
    valid('the open add menu');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    valid('the closed add menu');
    await click(find.byType(LanguageButton));
    valid('the open language menu');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    valid('the closed language menu');

    final nav = find.byIcon(Symbols.category_rounded);
    await hover(nav);
    valid('a sidebar tooltip');
    await click(nav);
    for (var i = 0; i < 400 && find.text('Zapret').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Zapret'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    valid('the catalog');
    await click(find.text('Zapret'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ExtensionDetailScreen), findsOneWidget);
    valid('an extension page');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    valid('leaving');
    semantics.dispose();
  });

  testWidgets('without the geometric tree a tooltip breaks the update, or the workaround can go', (tester) async {
    _raw = true;
    addTearDown(() => _raw = false);
    final semantics = tester.ensureSemantics();
    final hover = await start(tester);
    await hover(find.byIcon(Symbols.category_rounded));
    expect(
      _tree.errors,
      isNotEmpty,
      reason: 'Flutter no longer needs SemanticsTreeGuard; drop it (flutter/flutter#182444)',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    semantics.dispose();
  });
}
