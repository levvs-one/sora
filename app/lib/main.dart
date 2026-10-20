import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'src/design/theme.dart';
import 'src/desktop/desktop.dart';
import 'src/settings.dart';
import 'src/sora.dart';
import 'src/ui/shell.dart';
import 'src/ui/toasts.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final sora = Sora(await Settings.load());
  unawaited(sora.run());
  final navigator = GlobalKey<NavigatorState>();
  // A link passed on the command line launches the app (cold start).
  // app_links only reports links received while the app runs, so the launch
  // argument is extracted here and delivered after startup.
  final launchLink = _launchLink(args);
  final desktop = Platform.isLinux || Platform.isWindows ? Desktop(sora, navigator) : null;
  await desktop?.start(hidden: args.contains('--hidden'));
  runApp(SoraApp(sora: sora, navigator: navigator, desktop: desktop));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    sora.updates.start();
    // S11b: post-update health check / automatic rollback. No-op unless a
    // pending-update marker was written by the previous build (Linux only).
    if (desktop != null) {
      unawaited(
        sora.updates.checkPendingUpdate(
          coreHealthy: () => sora.coreHandshakeDone,
          restart: desktop.restartAfterUpdate,
          quit: desktop.quit,
        ),
      );
    }
  });
  await desktop?.handleInitialLinks(launchLink);
}

/// First command-line argument that looks like a link; option flags are
/// skipped. Mirrors the native runners' find_link_arg.
String? _launchLink(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('-')) continue;
    if (arg.contains('://')) return arg;
  }
  return null;
}

class SoraApp extends StatefulWidget {
  const SoraApp({super.key, required this.sora, this.navigator, this.desktop});

  final Sora sora;
  final GlobalKey<NavigatorState>? navigator;
  final Desktop? desktop;

  @override
  State<SoraApp> createState() => _SoraAppState();
}

class _SoraAppState extends State<SoraApp> {
  static bool _licensesRegistered = false;
  late final _navigator = widget.navigator ?? GlobalKey<NavigatorState>();

  // buildTheme is a pure function of brightness (fixed palettes), but
  // SoraApp rebuilds on every Sora notification — probe ticks, state
  // changes — and used to construct both ThemeData trees (ColorScheme,
  // component themes) on every rebuild. Build each once per app run.
  late final _lightTheme = buildTheme(Brightness.light);
  late final _darkTheme = buildTheme(Brightness.dark);

  @override
  void initState() {
    super.initState();
    if (!_licensesRegistered) {
      _licensesRegistered = true;
      LicenseRegistry.addLicense(() async* {
        final entries = jsonDecode(await rootBundle.loadString('assets/licenses.json')) as Map<String, dynamic>;
        for (final entry in entries.entries) {
          yield LicenseEntryWithLineBreaks([entry.key], entry.value as String);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sora = widget.sora;
    final desktop = widget.desktop;
    final app = SoraScope(
      sora: sora,
      child: ListenableBuilder(
        listenable: sora,
        builder: (context, _) => MotionScope(
          enabled: sora.settings.animations,
          child: MaterialApp(
            title: 'Sora',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: switch (sora.settings.theme) {
              'light' => ThemeMode.light,
              'dark' => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            locale: sora.settings.locale,
            themeAnimationDuration:
                sora.settings.animations &&
                    !WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations
                ? const Duration(milliseconds: 150)
                : Duration.zero,
            localizationsDelegates: const [
              S.delegate,
              _LanguageDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
              _LanguageDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            navigatorKey: _navigator,
            builder: (_, child) => NotificationToasts(
              sora: sora,
              navigator: _navigator,
              child: child!,
            ),
            home: const DesktopShell(),
          ),
        ),
      ),
    );
    return desktop == null ? app : DesktopScope(desktop: desktop, child: app);
  }
}

// Flutter has no built-in Material/Cupertino translations for Tajik and
// Turkmen. Only those system controls fall back; Sora's strings stay localized.
class _LanguageDelegate<T> extends LocalizationsDelegate<T> {
  const _LanguageDelegate(this.delegate);
  final LocalizationsDelegate<T> delegate;
  @override
  bool isSupported(Locale locale) => S.supportedLocales.any((x) => x.languageCode == locale.languageCode);
  @override
  Future<T> load(Locale locale) => delegate.load(delegate.isSupported(locale) ? locale : const Locale('en'));
  @override
  bool shouldReload(_LanguageDelegate<T> old) => false;
}
