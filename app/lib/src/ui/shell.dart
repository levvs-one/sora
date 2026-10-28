import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'about.dart';
import 'connections.dart';
import 'extensions/store_screen.dart';
import 'home.dart';
import 'logs.dart';
import 'notifications_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'speedtest.dart';
import 'kit.dart';

class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.select, this.nativeContentVisible = true, required super.child});
  final ValueChanged<int> select;
  final bool nativeContentVisible;
  static ShellScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>()!;
  @override
  bool updateShouldNotify(ShellScope oldWidget) => nativeContentVisible != oldWidget.nativeContentVisible;
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  // Connections (2) opens from Settings; About (7) stays last and is pinned
  // at the sidebar bottom.
  static const _sectionOrder = [0, 6, 8, 4, 1, 3, 5, 7];

  // Section widgets by section index. All are const constructors and only
  // the selected one is ever inflated (by the content Navigator below), so
  // the list itself is built once instead of on every shell rebuild, and the
  // shell rebuilds on every Sora notification.
  static const _pages = <Widget>[
    HomeScreen(),
    RulesScreen(),
    ConnectionsScreen(),
    LogsScreen(),
    NotificationsScreen(),
    SettingsScreen(),
    SpeedtestScreen(),
    AboutScreen(),
    ExtensionsScreen(),
  ];
  final _scaffold = GlobalKey<ScaffoldState>();
  final _focus = FocusNode();
  GlobalKey<NavigatorState> _contentNavigator = GlobalKey();
  int _section = 0;
  bool _instantSectionChange = false;
  bool _nativeContentVisible = true;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_keyboard);
  }

  void _select(int value) {
    _scaffold.currentState?.closeDrawer();
    if (_section == value) {
      _contentNavigator.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _instantSectionChange = _section == 6 || value == 6;
        _nativeContentVisible = true;
        _section = value;
        _contentNavigator = GlobalKey();
      });
    }
  }

  void _toggle() {
    if (MediaQuery.sizeOf(context).width < 720) {
      if (_section == 6) {
        setState(() => _nativeContentVisible = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scaffold.currentState?.openDrawer();
        });
      } else {
        _scaffold.currentState?.openDrawer();
      }
    } else {
      final sora = SoraScope.read(context);
      unawaited(sora.change((x) => x.sidebarExpanded = !x.sidebarExpanded, replan: false));
    }
  }

  bool _keyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      final root = Navigator.of(context, rootNavigator: true);
      if (root.canPop()) {
        unawaited(root.maybePop());
      } else if (_scaffold.currentState?.isDrawerOpen ?? false) {
        _scaffold.currentState?.closeDrawer();
      } else {
        unawaited(_contentNavigator.currentState?.maybePop());
      }
      return true;
    }
    if (!HardwareKeyboard.instance.isControlPressed) return false;
    const numbers = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
    ];
    final index = numbers.indexOf(key);
    if (index >= 0) {
      _select(_sectionOrder[index]);
      return true;
    }
    if (key == LogicalKeyboardKey.keyB) {
      _toggle();
      return true;
    }
    if (key == LogicalKeyboardKey.comma) {
      _select(5);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboard);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), palette = Palette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final expanded = width >= 1000 && sora.settings.sidebarExpanded;
    final page = _pages[_section];
    final content = KeyedSubtree(
      key: ObjectKey(_contentNavigator),
      child: Navigator(
        key: _contentNavigator,
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
    // Native views must detach immediately when switching sections.
    final pane = _section == 6 || _instantSectionChange
        ? content
        : AnimatedSwitcher(duration: Motion.of(context, const Duration(milliseconds: 150)), child: content);
    return ShellScope(
      select: _select,
      nativeContentVisible: _nativeContentVisible && (ModalRoute.of(context)?.isCurrent ?? true),
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Scaffold(
          key: _scaffold,
          drawerEnableOpenDragGesture: _section != 6,
          onDrawerChanged: (opened) {
            if (_section == 6 && !opened) setState(() => _nativeContentVisible = true);
          },
          drawer: compact
              ? Drawer(
                  width: 224,
                  backgroundColor: palette.surface,
                  shape: const RoundedRectangleBorder(),
                  child: _sidebar(true, drawer: true),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!compact)
                  AnimatedContainer(
                    key: const ValueKey('sidebar'),
                    width: expanded ? 224 : 56,
                    duration: Motion.of(context, const Duration(milliseconds: 200)),
                    curve: Curves.easeOutCubic,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(color: palette.surface),
                    foregroundDecoration: BoxDecoration(
                      border: Border(right: BorderSide(color: palette.field)),
                    ),
                    child: _sidebar(expanded),
                  ),
                Expanded(
                  child: compact && _section == 6
                      ? Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                key: const ValueKey('speedtest-menu'),
                                icon: Icon(Symbols.left_panel_open_rounded, color: palette.ink, weight: 600),
                                onPressed: _toggle,
                              ),
                            ),
                            Expanded(child: pane),
                          ],
                        )
                      : pane,
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: compact && _section != 6
              ? Builder(
                  builder: (context) => MediaQuery.sizeOf(context).width >= 720
                      ? const SizedBox.shrink()
                      : Material(
                          color: palette.surface,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            key: const ValueKey('drawer-button'),
                            tooltip: S.of(context).sidebarToggle,
                            icon: Icon(Symbols.left_panel_open_rounded, color: palette.ink, weight: 600),
                            onPressed: _toggle,
                          ),
                        ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _sidebar(bool expanded, {bool drawer = false}) {
    final s = S.of(context), sora = SoraScope.of(context), palette = Palette.of(context);
    final labels = [
      s.home,
      s.navRules,
      s.navConnections,
      s.navLogs,
      s.notifications,
      s.settings,
      s.speedtest,
      s.navAbout,
      s.extensions,
    ];
    const icons = [
      Symbols.home_rounded,
      Symbols.rule_rounded,
      Symbols.swap_vert_rounded,
      Symbols.terminal_rounded,
      Symbols.notifications_rounded,
      Symbols.settings_rounded,
      Symbols.speed_rounded,
      Symbols.info_rounded,
      Symbols.category_rounded,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Center(
                  child: Tooltip(
                    message: s.sidebarToggle,
                    child: Semantics(
                      button: true,
                      label: s.sidebarToggle,
                      child: Pressable(
                        key: const ValueKey('sidebar-toggle'),
                        radius: 8,
                        onTap: drawer ? () => _scaffold.currentState?.closeDrawer() : _toggle,
                        child: SizedBox.square(
                          dimension: 36,
                          child: Icon(
                            drawer || expanded ? Symbols.left_panel_close_rounded : Symbols.left_panel_open_rounded,
                            color: palette.ink,
                            size: 22,
                            weight: 600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (expanded)
                Expanded(
                  child: Text('Sora', maxLines: 1, style: Styles.heading.copyWith(color: palette.ink)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // The last section (About) is pinned at the sidebar bottom below.
        for (final index in _sectionOrder.take(_sectionOrder.length - 1))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: _navItem(index, labels[index], icons[index], expanded, sora, palette),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
          child: _navItem(7, labels[7], icons[7], expanded, sora, palette),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SoraMark(size: 20, color: palette.ink3),
        ),
      ],
    );
  }

  Widget _navItem(int index, String label, IconData icon, bool expanded, Sora sora, Palette palette) =>
      TooltipVisibility(
        visible: _section != 6,
        child: Tooltip(
          message: '$label (Ctrl+${_sectionOrder.indexOf(index) + 1})',
          child: Semantics(
            selected: _section == index,
            child: Material(
              color: _section == index ? palette.field : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _select(index),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Center(
                          child: Badge(
                            isLabelVisible: index == 7 && sora.updates.hasUpdate,
                            backgroundColor: palette.ink,
                            textColor: palette.surface,
                            child: Icon(
                              icon,
                              size: 22,
                              color: palette.ink,
                              weight: 600,
                              fill: _section == index ? 1 : 0,
                            ),
                          ),
                        ),
                      ),
                      if (expanded)
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Styles.secondary.copyWith(color: palette.ink),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
