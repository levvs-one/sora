/// Keeps semantics updates valid for the Windows accessibility tree.
///
/// OverlayPortal, which every Tooltip and menu uses, moves its overlay node
/// out of its real parent and lists it under a "traversal parent" instead.
/// That parent is often missing from the update, or lost when two overlays
/// share a semantics node, and then no parent lists the overlay at all.
/// ui::AXTree on Windows rejects an update naming such a node ("X will not be
/// in the tree and is not the new root"). The tree goes stale and Sora crashes
/// shortly after: hovering a sidebar item was enough whenever anything had
/// turned accessibility on.
/// https://github.com/flutter/flutter/issues/182444
///
/// Two steps make every update a valid tree edit. Nodes keep their real
/// parent, which the framework always sends when its children change. A node
/// that still has no parent waits in [SemanticsTreeGuard] until one lists it.
/// A screen reader then reaches a tooltip or menu after the page rather than
/// next to its anchor; a tooltip's text stays on the anchor itself.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The app's binding: on Windows, semantics updates pass the guard.
class SoraBinding extends WidgetsFlutterBinding {
  final _guard = SemanticsTreeGuard();

  @override
  void initInstances() {
    super.initInstances();
    // Turning accessibility off discards the tree on the other side.
    addSemanticsEnabledListener(_guard.reset);
  }

  @override
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    final builder = super.createSemanticsUpdateBuilder();
    return Platform.isWindows ? _guard.wrap(builder) : builder;
  }
}

typedef _Emit = void Function(ui.SemanticsUpdateBuilder builder, Int32List children);

class _Node {
  _Node(this.children, this.emit);
  final List<int> children;
  final _Emit emit;
}

/// Mirrors the tree the engine holds and sends only updates it can apply.
class SemanticsTreeGuard {
  static const _rootId = 0;

  /// Far more than a screen's open overlays; held nodes of closed ones go.
  static const _maxHeld = 512;

  final _sent = <int, List<int>>{};
  final _parent = <int, int>{};
  final _held = <int, _Node>{};

  ui.SemanticsUpdateBuilder wrap(ui.SemanticsUpdateBuilder builder) => _GuardedBuilder(this, builder);

  void reset() {
    _sent.clear();
    _parent.clear();
    _held.clear();
  }

  void _commit(Map<int, _Node> update, ui.SemanticsUpdateBuilder builder) {
    final known = {..._held, ...update};
    final send = <int>{};
    void take(int id) {
      if (!send.add(id)) return;
      for (final child in known[id]!.children) {
        if (known.containsKey(child) && !_sent.containsKey(child)) take(child);
      }
    }

    for (final id in update.keys) {
      if (id == _rootId || _sent.containsKey(id)) take(id);
    }
    final gone = <int>[];
    for (final id in send) {
      final node = known[id]!;
      final children = [
        for (final child in node.children)
          if (send.contains(child) || _sent.containsKey(child)) child,
      ];
      node.emit(builder, Int32List.fromList(children));
      for (final child in _sent[id] ?? const <int>[]) {
        if (_parent[child] == id) {
          _parent.remove(child);
          gone.add(child);
        }
      }
      _sent[id] = children;
      for (final child in children) {
        _parent[child] = id;
      }
    }
    gone.where((id) => !_parent.containsKey(id)).forEach(_forget);
    _held.clear();
    if (known.length - send.length <= _maxHeld) {
      known.removeWhere((id, _) => send.contains(id));
      _held.addAll(known);
    }
  }

  void _forget(int id) {
    for (final child in _sent.remove(id) ?? const <int>[]) {
      if (_parent[child] == id) {
        _parent.remove(child);
        _forget(child);
      }
    }
  }
}

/// [traversal] with its order kept, limited to the node's real children as
/// [hitTest] lists them; the real children it lacks follow in paint order.
Int32List geometricChildren(Int32List traversal, Int32List hitTest) {
  final own = hitTest.toSet();
  if (traversal.length == own.length && traversal.every(own.contains)) return traversal;
  final kept = [
    for (final id in traversal)
      if (own.contains(id)) id,
  ];
  return Int32List.fromList([
    ...kept,
    for (final id in hitTest.reversed)
      if (!kept.contains(id)) id,
  ]);
}

/// Collects an update for the guard, with real children as the child lists.
class _GuardedBuilder implements ui.SemanticsUpdateBuilder {
  _GuardedBuilder(this._guard, this._inner);

  final SemanticsTreeGuard _guard;
  final ui.SemanticsUpdateBuilder _inner;
  final _nodes = <int, _Node>{};

  @override
  ui.SemanticsUpdate build() {
    _guard._commit(_nodes, _inner);
    return _inner.build();
  }

  @override
  void updateCustomAction({required int id, String? label, String? hint, int overrideId = -1}) =>
      _inner.updateCustomAction(id: id, label: label, hint: hint, overrideId: overrideId);

  @override
  void updateNode({
    required int id,
    required ui.SemanticsFlags flags,
    required int actions,
    required int maxValueLength,
    required int currentValueLength,
    required int textSelectionBase,
    required int textSelectionExtent,
    required int platformViewId,
    required int scrollChildren,
    required int scrollIndex,
    required int traversalParent,
    required double scrollPosition,
    required double scrollExtentMax,
    required double scrollExtentMin,
    required ui.Rect rect,
    required String identifier,
    required String label,
    required List<ui.StringAttribute> labelAttributes,
    required String value,
    required List<ui.StringAttribute> valueAttributes,
    required String increasedValue,
    required List<ui.StringAttribute> increasedValueAttributes,
    required String decreasedValue,
    required List<ui.StringAttribute> decreasedValueAttributes,
    required String hint,
    required List<ui.StringAttribute> hintAttributes,
    required String tooltip,
    required ui.TextDirection? textDirection,
    required Float64List transform,
    required Float64List hitTestTransform,
    required Int32List childrenInTraversalOrder,
    required Int32List childrenInHitTestOrder,
    required Int32List additionalActions,
    int headingLevel = 0,
    String linkUrl = '',
    ui.SemanticsRole role = ui.SemanticsRole.none,
    required List<String>? controlsNodes,
    ui.SemanticsValidationResult validationResult = ui.SemanticsValidationResult.none,
    ui.SemanticsHitTestBehavior hitTestBehavior = ui.SemanticsHitTestBehavior.defer,
    required ui.SemanticsInputType inputType,
    required ui.Locale? locale,
    required String minValue,
    required String maxValue,
  }) => _nodes[id] = _Node(
    geometricChildren(childrenInTraversalOrder, childrenInHitTestOrder),
    (builder, children) => builder.updateNode(
      id: id,
      flags: flags,
      actions: actions,
      maxValueLength: maxValueLength,
      currentValueLength: currentValueLength,
      textSelectionBase: textSelectionBase,
      textSelectionExtent: textSelectionExtent,
      platformViewId: platformViewId,
      scrollChildren: scrollChildren,
      scrollIndex: scrollIndex,
      traversalParent: traversalParent,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      rect: rect,
      identifier: identifier,
      label: label,
      labelAttributes: labelAttributes,
      value: value,
      valueAttributes: valueAttributes,
      increasedValue: increasedValue,
      increasedValueAttributes: increasedValueAttributes,
      decreasedValue: decreasedValue,
      decreasedValueAttributes: decreasedValueAttributes,
      hint: hint,
      hintAttributes: hintAttributes,
      tooltip: tooltip,
      textDirection: textDirection,
      transform: transform,
      hitTestTransform: hitTestTransform,
      childrenInTraversalOrder: children,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: additionalActions,
      headingLevel: headingLevel,
      linkUrl: linkUrl,
      role: role,
      controlsNodes: controlsNodes,
      validationResult: validationResult,
      hitTestBehavior: hitTestBehavior,
      inputType: inputType,
      locale: locale,
      minValue: minValue,
      maxValue: maxValue,
    ),
  );
}
