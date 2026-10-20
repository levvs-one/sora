// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get stateOff => 'Nicht verbunden';

  @override
  String get stateConnecting => 'Verbinden';

  @override
  String get stateConnected => 'Verbunden';

  @override
  String get stateReconnecting => 'Wieder verbinden';

  @override
  String get stateDisconnecting => 'Trennen';

  @override
  String get stateFailed => 'Nicht verbunden';

  @override
  String get coreMissing => 'Der Sora-Dienst antwortet nicht';

  @override
  String get serverAuto => 'Am schnellsten';

  @override
  String get serverBypass => 'Kein Server';

  @override
  String get addSubscription => 'Abonnement hinzufügen';

  @override
  String get servers => 'Server';

  @override
  String get settings => 'Einstellungen';

  @override
  String get subscription => 'Abonnement';

  @override
  String get subscriptionLink => 'Abo-Link';

  @override
  String get add => 'Hinzufügen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Stornieren';

  @override
  String get save => 'Speichern';

  @override
  String get name => 'Name';

  @override
  String deleteSubscription(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get routes => 'Routen';

  @override
  String get presetGlobal => 'Alles über VPN';

  @override
  String get presetRu => 'Russland direkt';

  @override
  String get presetIr => 'Iran direkt';

  @override
  String get presetCn => 'China direkt';

  @override
  String get blockAds => 'Werbung blockieren';

  @override
  String get killSwitch => 'Internet nur über VPN';

  @override
  String get engine => 'Motor';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animationen';

  @override
  String get logs => 'Protokoll';

  @override
  String get about => 'Um';

  @override
  String get logsAll => 'Alle';

  @override
  String get logsImportant => 'Wichtig';

  @override
  String get logsErrors => 'Fehler';

  @override
  String get search => 'Suchen';

  @override
  String get export => 'In Datei speichern';

  @override
  String get clear => 'Klar';

  @override
  String get logsEmpty => 'Nichts hier';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Nicht installiert';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get license => 'Lizenz';

  @override
  String usage(String used, String total) {
    return '$used von $total';
  }

  @override
  String until(String date) {
    return 'bis $date';
  }

  @override
  String get expired => 'Abgelaufen';

  @override
  String milliseconds(int n) {
    return '$n ms';
  }

  @override
  String latencyMs(int value) {
    return '$value ms';
  }

  @override
  String speedMbps(double value) {
    return '$value Mbps';
  }

  @override
  String bytesB(String n) {
    return '$n B';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n GB';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'Etwas ist schief gelaufen';

  @override
  String get errCore => 'Der Sora-Dienst antwortet nicht';

  @override
  String get errAuth => 'Kein Zugriff auf den Sora-Dienst';

  @override
  String get errVersion => 'Update Sora: Die App und der Dienst sind unterschiedliche Versionen';

  @override
  String get errBusy => 'Warten Sie, der vorherige Befehl wird noch ausgeführt';

  @override
  String get errEngineMissing => 'Für diesen Server wurde keine Engine gefunden';

  @override
  String get errEngineStart => 'Der Motor sprang nicht an';

  @override
  String get errEngineStopped => 'Der Motor blieb stehen';

  @override
  String get errTunnel => 'Keine Berechtigung zum Erstellen der VPN-Verbindung';

  @override
  String get errServers => 'Der Server ist mit einem Fehler konfiguriert';

  @override
  String get errNetwork => 'Der Server kann nicht erreicht werden';

  @override
  String get errTimeout => 'Der Server antwortete nicht rechtzeitig';

  @override
  String get errFirewall => 'Das Internet außerhalb des VPN konnte nicht blockiert werden';

  @override
  String get errSubFetch => 'Das Abonnement konnte nicht geladen werden';

  @override
  String get errSubFormat => 'Dies ist kein Abonnement-Link';

  @override
  String get errSubEmpty => 'Das Abonnement enthält keine Server';

  @override
  String get errSubDuplicate => 'Dieses Abonnement ist bereits hinzugefügt';

  @override
  String get errSubLimit => 'Zu viele Abonnements';

  @override
  String get errSubScheme => 'Der Link muss mit https:// beginnen.';

  @override
  String get errSecretStore => 'Der Sora-Speicher ist beschädigt oder nicht verfügbar';

  @override
  String get errNoServers => 'Fügen Sie ein Abonnement hinzu, um eine Verbindung herzustellen';

  @override
  String get exportText => 'Text';

  @override
  String get connections => 'Verbindungen';

  @override
  String get close => 'Schließen';

  @override
  String get chainDirect => 'Direkt';

  @override
  String get chainBlocked => 'Blockiert';

  @override
  String get theme => 'Thema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Verbindung';

  @override
  String get sectionNoServer => 'Kein Server';

  @override
  String get sectionPing => 'Klingeln';

  @override
  String get sectionLog => 'Diagnose';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Adressen, durch Kommas getrennt';

  @override
  String get fragment => 'TLS-Fragmentierung';

  @override
  String get fragmentPackets => 'Was soll geteilt werden?';

  @override
  String get fragmentLength => 'Stückgröße';

  @override
  String get fragmentInterval => 'Pause zwischen den Stücken';

  @override
  String get byDefault => 'Standard';

  @override
  String get rangeHint => 'Zum Beispiel 100-200';

  @override
  String get splitPos => 'Geteilte Positionen';

  @override
  String get splitPosHint => 'Beispiel: 1, Mittelsld';

  @override
  String get disorder => 'Teile neu anordnen';

  @override
  String get tlsRecord => 'Teilen Sie den TLS-Eintrag auf';

  @override
  String get tlsRecordNo => 'NEIN';

  @override
  String get tlsRecordSni => 'Beim Site-Namen';

  @override
  String get tlsRecordFirst => 'Nach dem ersten Byte';

  @override
  String get hostCase => 'Host-Fall ändern';

  @override
  String get probeMethod => 'Verfahren';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Durch den Motor';

  @override
  String get probeConnect => 'Nur Verbindung';

  @override
  String get probeUrl => 'Testadresse';

  @override
  String get probeTimeout => 'Warten';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get subscriptionSettings => 'Einstellungen';

  @override
  String get userAgent => 'Benutzeragent';

  @override
  String get autoUpdate => 'Automatisch aktualisieren';

  @override
  String get updateInterval => 'Wie oft';

  @override
  String get intervalProvider => 'Wie der Anbieter verlangt';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get logLevel => 'Was soll aufgezeichnet werden?';

  @override
  String get levelDebug => 'Alles';

  @override
  String get levelInfo => 'Üblich';

  @override
  String get levelWarning => 'Wichtig';

  @override
  String get levelError => 'Nur Fehler';

  @override
  String get recordDestinations => 'Erfassen Sie Standortadressen';

  @override
  String get reset => 'Einstellungen zurücksetzen';

  @override
  String get resetConfirm => 'Alle Einstellungen zurücksetzen?';

  @override
  String get resetAction => 'Zurücksetzen';

  @override
  String get invalidValue => 'Dieser Wert wird nicht funktionieren';

  @override
  String get website => 'Abonnementseite';

  @override
  String get providerWebsite => 'Website des Anbieters';

  @override
  String get support => 'Unterstützung';

  @override
  String controlPortQuestion(String engine) {
    return '$engine wird über einen Port an diesem Computer gesteuert. Andere Programme können erkennen, dass ein VPN aktiviert ist.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Wählen Sie $engine';
  }

  @override
  String get rules => 'Benutzerdefinierte Regeln';

  @override
  String get ruleAdd => 'Neue Regel';

  @override
  String get ruleHint => 'Site, IP oder Programm';

  @override
  String get ruleDirect => 'Direkt';

  @override
  String get ruleProxy => 'Über VPN';

  @override
  String get ruleBlock => 'Block';

  @override
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'Einschaltfehler';

  @override
  String get connectOnStart => 'Beim Start verbinden';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Das Abonnement endet in # Tagen',
      one: 'Das Abonnement endet am Tag #',
      zero: 'Das Abonnement endet in wenigen Stunden',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left links';
  }

  @override
  String get ruleInvalid => 'Dies sieht nicht nach einer Site, einer IP oder einem Programm aus';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#-Server wiederum',
      one: '#-Server wiederum',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#-Server, die schnellsten',
      one: '#-Server, der schnellste',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Modus';

  @override
  String get tunnelTun => 'Der gesamte Verkehr';

  @override
  String get tunnelProxy => 'System-Proxy';

  @override
  String get proxyAddress => 'Proxy-Adresse';

  @override
  String get copied => 'Kopiert';

  @override
  String get launchAtLogin => 'Beginnen Sie mit dem System';

  @override
  String get launchAtLoginDetail => 'Sora wird beim Anmelden automatisch gestartet und bleibt im Infobereich.';

  @override
  String get closeToTray => 'Im geschlossenen Zustand im Fach aufbewahren';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get trayOpen => 'Öffnen Sie Sora';

  @override
  String get trayConnect => 'Verbinden';

  @override
  String get trayDisconnect => 'Trennen';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Beenden Sie Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora befindet sich noch im Fach';

  @override
  String get noticeInTrayBody => 'Beenden Sie das Menü mit seinem Symbol';

  @override
  String get noticeLost => 'Verbindung verloren';

  @override
  String get noticeLostBody => 'Sora stellt die Verbindung wieder her';

  @override
  String get noticeRestored => 'Wieder verbunden';

  @override
  String get noticeFailed => 'Es konnte keine Verbindung hergestellt werden';

  @override
  String get noticeBackup => 'Der Hauptserver antwortete nicht; Das Backup überträgt den Datenverkehr';

  @override
  String get noticeNext => 'Der Server antwortete nicht; der nächste trägt den Verkehr';

  @override
  String get noticeMainBack => 'Der Hauptserver antwortet erneut und leitet den Datenverkehr';

  @override
  String get noticeSubscription => 'Abonnement';

  @override
  String get importTitle => 'Dieses Abonnement hinzufügen?';

  @override
  String get importSealed =>
      'Dieser Link ist für Happ verschlüsselt und kann nur von Happ gelesen werden. Fragen Sie Ihren Anbieter nach dem einfachen Abonnement-Link.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'keine Antwort';

  @override
  String get home => 'Heim';

  @override
  String get navRules => 'Regeln';

  @override
  String get navConnections => 'Verbindungen';

  @override
  String get navLogs => 'Protokolle';

  @override
  String get navAbout => 'Um';

  @override
  String get sidebarToggle => 'Seitenleiste umschalten';

  @override
  String get more => 'Mehr';

  @override
  String get less => 'Weniger';

  @override
  String get currentServer => 'Aktueller Server';

  @override
  String get trafficDown => 'Heruntergeladen';

  @override
  String get trafficUp => 'Hochgeladen';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Aktive Regeln: $count';
  }

  @override
  String get recentNotifications => 'Aktuelle Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Hier werden Verbindungs- und Abonnementereignisse angezeigt';

  @override
  String get retryConnect => 'Verbindung erneut versuchen';

  @override
  String get openLogs => 'Protokolle öffnen';

  @override
  String get tourReplay => 'Guide erneut anzeigen';

  @override
  String tourStep(int step) {
    return 'Schritt $step von 5';
  }

  @override
  String get tourBack => 'Zurück';

  @override
  String get tourNext => 'Nächste';

  @override
  String get tourSkip => 'Überspringen';

  @override
  String get tourFinish => 'Erledigt';

  @override
  String get tourAdd => 'Fügen Sie den Abonnementlink Ihres Anbieters hinzu.';

  @override
  String get tourServer => 'Wählen Sie einen Server. „Am schnellsten“ wählt eines für Sie aus.';

  @override
  String get tourConnect => 'Klicken Sie hier, um eine Verbindung herzustellen oder zu trennen.';

  @override
  String get tourMode => 'Wählen Sie einen Modus. Der Kill-Switch blockiert das Internet, wenn das VPN ausfällt.';

  @override
  String get tourSettings => 'Einstellungen öffnen. Sie können diesen Leitfaden dort noch einmal ansehen.';

  @override
  String get chooseProgram => 'Wählen Sie ein Programm';

  @override
  String get installedApps => 'Installierte Anwendungen';

  @override
  String get runningProcesses => 'Laufende Prozesse';

  @override
  String get programsFailed => 'Anwendungen konnten nicht geladen werden';

  @override
  String get programsEmpty => 'Keine Anwendungen gefunden. Versuchen Sie es mit einem anderen Namen.';

  @override
  String get selectExe => 'Wählen Sie eine .exe-Datei';

  @override
  String get trafficUnavailable => 'Zähler sind noch nicht verfügbar';

  @override
  String get speedtest => 'Geschwindigkeit';

  @override
  String get speedtestCheck => 'Geschwindigkeit prüfen';

  @override
  String get speedtestSearch => 'Finden Sie einen Dienst';

  @override
  String get speedtestEmpty => 'Keine Übereinstimmungen. Ändern Sie die Suche.';

  @override
  String get speedtestBackToList => 'Zurück zu den Dienstleistungen';

  @override
  String get speedtestOpenBrowser => 'Im Browser öffnen';

  @override
  String get speedtestUnavailable =>
      'Der eingebettete Browser konnte nicht gestartet werden. Öffnen Sie den Dienst in Ihrem Systembrowser.';

  @override
  String get speedtestPageFailed =>
      'Die Seite konnte nicht geladen werden. Laden Sie es neu oder öffnen Sie den Dienst in Ihrem Systembrowser.';

  @override
  String get speedtestExternalFailed => 'Der Systembrowser konnte nicht geöffnet werden. Versuchen Sie es erneut.';

  @override
  String get modes => 'Modi';

  @override
  String get proxyShort => 'Stellvertreterin';

  @override
  String get tunMode => 'Gesamter Datenverkehr (TUN)';

  @override
  String get checkUpdates => 'Suchen Sie nach Updates';

  @override
  String get updates => 'App-Updates';

  @override
  String updateAvailable(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get updateOpenAbout => 'Update anzeigen';

  @override
  String updateNotes(String version) {
    return 'Änderungen in $version';
  }

  @override
  String get updateCheck => 'Suchen Sie nach Updates';

  @override
  String get updateChecking => 'Überprüfung...';

  @override
  String get updateNoNotes => 'Die Veröffentlichung enthält keine Notizen.';

  @override
  String get updateDropWarning =>
      'Die VPN-Verbindung wird für einige Sekunden unterbrochen, während Sora und sein Kernupdate durchgeführt werden. Weitermachen?';

  @override
  String get updateWaitConnection => 'Warten Sie, bis die VPN-Verbindung und der Kern bereit sind.';

  @override
  String get updateDownloading => 'Dateien werden heruntergeladen und überprüft...';

  @override
  String get updateInstalling => 'Das Update wird vorbereitet oder auf die Administratorauthentifizierung gewartet ...';

  @override
  String get updateNetworkError => 'Das Update konnte nicht heruntergeladen werden. Versuchen Sie es erneut.';

  @override
  String get updateReleaseError => 'Die Release-Daten oder erforderlichen Dateien fehlen oder sind ungültig.';

  @override
  String get updateChecksumError => 'Der Download stimmt nicht mit SHA256SUMS überein. Es wurde nichts installiert.';

  @override
  String get updateInstallError =>
      'Das Update wurde nicht abgeschlossen. Möglicherweise wurde die Authentifizierung abgebrochen.';

  @override
  String get updateUnsupported =>
      'Diese ausführbare Datei gehört keinem unterstützten Sora-Paketpaar. Verwenden Sie die Installationsanweisungen für das Release.';

  @override
  String get updateManual =>
      'Führen Sie diesen Befehl in einem Terminal aus, um beide verifizierten Pakete zu installieren, und öffnen Sie dann Sora erneut. Die Dateien bleiben im Download-Verzeichnis. Die VPN-Verbindung wird unterbrochen.';

  @override
  String get updateSignaturePending =>
      'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';

  @override
  String get updateManualSigWarning =>
      'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

  @override
  String get updateWindowsSigBlocked =>
      'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';

  @override
  String get updateVersionRevoked =>
      'This version has been recalled by the developer. Please wait for a fixed release.';

  @override
  String get updateRolloutPending =>
      'A newer version is rolling out gradually and will be offered to you automatically.';

  @override
  String updateRollbacking(String version) {
    return 'Rolling back to version $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'The update to $version did not pass the health check, so Sora was rolled back to $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Automatic rollback failed. If the new version does not work, reinstall the previous release manually.';

  @override
  String get updateRollbackCacheError =>
      'Could not prepare a verified rollback copy of the current version, so the update was not installed.';

  @override
  String get updateCopyCommand => 'Befehl kopieren';

  @override
  String get updateChecksDisabled => 'Automatische Prüfungen sind in den Einstellungen deaktiviert.';

  @override
  String get updateInstalled => 'Update installiert. Öffnen Sie Sora erneut.';

  @override
  String get projectLinks => 'Projekt';

  @override
  String get githubReleases => 'Veröffentlichungen und Downloads';

  @override
  String get telegramChannel => 'Telegram-Kanal';

  @override
  String get licenses => 'Lizenzen';

  @override
  String get componentLicenses => 'Komponentenlizenzen';

  @override
  String get appCopyright => '© 2026 levvs-one und Mitwirkende';

  @override
  String get collapseServers => 'Server zusammenbrechen lassen';

  @override
  String get expandServers => 'Erweitern Sie Server';

  @override
  String get hideDescription => 'Beschreibung ausblenden';

  @override
  String get showDescription => 'Beschreibung anzeigen';

  @override
  String get pendingConnectionChanges => 'Stellen Sie die Verbindung erneut her, um diese Änderungen zu übernehmen.';

  @override
  String get reconnectNow => 'Anwenden und erneut verbinden';

  @override
  String get bypassLimitations =>
      'Dieser Modus umgeht DPI nur für HTTP und TLS, unterstützt kein UDP und ändert Ihre IP nicht. Verwenden Sie einen VPN-Server für Discord-Sprache, Anrufe und blockierte Telegram-Adressen.';

  @override
  String get errEngineUnsupported =>
      'Die ausgewählte Engine unterstützt dieses Profil oder diese Einstellungen nicht. Wählen Sie „Auto“ oder eine kompatible Engine.';

  @override
  String get errRestore =>
      'Die Verbindungsbereinigung war unvollständig. Versuchen Sie erneut, die Verbindung zu trennen. Einzelheiten finden Sie im Protokoll.';

  @override
  String get errSessionEnded => 'Diese Sitzung ist bereits beendet. Aktualisieren Sie den Verbindungsstatus.';

  @override
  String get retryDisconnect => 'Versuchen Sie erneut, die Verbindung zu trennen';

  @override
  String get tunStack => 'TUN-Stapel';

  @override
  String get modesInfo => 'Über Modi';

  @override
  String get modesGuideTitle => 'Modi und Motoren';

  @override
  String get modesGuide =>
      'Wählen Sie „Auto“, wenn Sie nicht sicher sind, welche Engine Ihr Server benötigt. Sora überprüft das Profil und die Einstellungen vor der Verbindung. Eine Engine kann die Bandbreite Ihres Plans nicht erhöhen: Die Leistung hängt vom Server, der Route, dem Protokoll und dem Netzwerk ab.\n\n## Modi\n\n### Gesamter Datenverkehr (TUN)\n\nSora erstellt eine virtuelle Netzwerkschnittstelle und leitet den Anwendungsverkehr darüber weiter, einschließlich TCP und UDP. Verwenden Sie diesen Modus für Telegram, Spiele und Discord-Sprache. Regeln können bestimmte Websites oder Programme direkt senden oder blockieren. Der Netzwerkdienst benötigt eine Erlaubnis und einen Server, der das erforderliche Protokoll unterstützt.\n\n### System-Proxy\n\nSora konfiguriert einen lokalen HTTP/SOCKS-Proxy. Es wird von Anwendungen verwendet, die die Proxy-Einstellungen des Systems berücksichtigen. Anwendungen mit eigenem Netzwerk-Stack können sich direkt verbinden; UDP und Sprachanrufe benötigen im Allgemeinen TUN. Dieser Modus eignet sich für Browser und Anwendungen mit Proxy-Unterstützung.\n\n### Kein Server\n\nAuf Linux verwendet Sora [zapret](https://github.com/bol-van/zapret), um HTTP/TLS-Anfragen aufzuteilen und umzuformen und einige DPI-Prüfungen zu umgehen. Ihre IP bleibt gleich und Verbindungen gehen direkt zur Website. Die Ergebnisse hängen von Ihrem Anbieter und der Blockierungsmethode ab.\n\nDie aktuelle Integration verwendet tpws für HTTP und TLS über TCP. Es umgeht weder die IP-Blockierung noch leitet es UDP weiter und kann die MTProto-Verbindungen von Telegram nicht garantieren. Verwenden Sie einen VPN-Server mit TUN für Discord-Sprache, Telegram-Anrufe und solche Einschränkungen.\n\n## Motoren\n\n### Automatisch\n\nSora wählt eine installierte Engine aus, die den gesamten Verbindungsplan unterstützt: Serverprotokolle, Transporte, Gruppen, Fragmentierung und Modus. Eine inkompatible manuelle Auswahl wird abgelehnt, bevor die aktuelle Verbindung beendet wird. Wählen Sie „Auto“ oder eine andere Engine und wenden Sie die Einstellungen erneut an.\n\n### sing-box\n\nZu den neuen Sora-Paketen gehören [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), ein Zweig von [sing-box](https://github.com/SagerNet/sing-box), der clientseitige XHTTP und VLESS Encryption hinzufügt. Sora erkennt den Build und seine Fähigkeiten. Ein Upstream-Build ohne XHTTP erhält diese Fähigkeit nicht allein durch seinen Namen.\n\nZu den unterstützten Protokollen gehören VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard und die AmneziaWG 1.x/2.x-Parameter, die Sora importieren kann. Für vollständige Xray-JSON-Profile ist Xray erforderlich. Neue AWG 3.x-Felder können noch nicht importiert werden. sing-box verwendet einen passwortgeschützten lokalen Steuerungsport, den andere Anwendungen auf dem Computer erkennen können.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) unterstützt VLESS, REALITY, XHTTP, VLESS Encryption und TLS-Fragmentierung. Es führt auch vollständige Provider-Profile Xray aus und behält dabei deren Routing und Gruppen bei. Solche Profile können nicht automatisch in eine andere Engine konvertiert werden, ohne ihr Verhalten zu ändern.\n\nIm Paket Xray wurde die Einstellung entfernt, die die TLS-Zertifikatsüberprüfung deaktiviert („allowInsecure“). Bei normalen Servern, die diese Einstellung erfordern, wird automatisch sing-box oder mihomo ausgewählt. Wenn Sie Xray manuell auswählen, wird die Inkompatibilität gemeldet, bevor die aktuelle Verbindung beendet wird. Ältere vollständige JSON-Profile benötigen ein aktualisiertes Anbieterprofil mit einem überprüfbaren Zertifikat oder einer Zertifikats-PIN.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) unterstützt geordnete Fallback- und Lastausgleichsgruppen, XHTTP und AmneziaWG. Wählen Sie diese Option, wenn ein automatisches Failover auf einen Backup-Server wichtig ist. Die TLS-Fragmentierungseinstellung von Sora ist mit dieser Engine nicht verfügbar.\n\n## Kompatibilität in Sora\n\n| Funktion | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN und TCP/UDP | Ja | Ja | Ja |\n| XHTTP | Ja | Ja | Ja |\n| VLESS Encryption | Ja | Ja | Ja |\n| Vollständiges Xray-Profil | Nein | Ja | Nein |\n| TUIC / AnyTLS | Beide | Nein | TUIC |\n| TLS-Fragmentierung | Ja | Ja | Nein |\n| AmneziaWG 1.x/2.x | Ja¹ | Nein | Ja |\n| Geordnete Fallback-Gruppe | Nein | Nein² | Ja |\n\n¹ Profile mit J1/J2/J3/Itime verwenden mihomo; Diese Felder dürfen niemals stillschweigend verworfen werden. ² Für eine Gruppe vollständiger Xray-Profile wählt die App ein Backup-Profil aus. Die Unterstützung hängt vom installierten Build ab. Überprüfen Sie die Version unter „Info“.\n\n## TUN-Stapel\n\nDer Stack verarbeitet TCP und UDP innerhalb der virtuellen Schnittstelle. Im Modi-Panel bieten Xray und mihomo gVisor, System, Mixed und MIPS an. Jede Engine speichert ihre eigene Präferenz. System-Proxy- und serverlose Modi verwenden diese Einstellung nicht.\n\n- **Mixed** – TCP verwendet den System-Stack, während gVisor UDP verarbeitet. Dies ist die Standardeinstellung für mihomo unter Linux. Unter Windows verwenden Xray und mihomo standardmäßig MIPS.\n- **System** – verwendet den System-Stack. Versuchen Sie eine andere Option, wenn bei Netzwerkanwendungen Probleme auftreten.\n- **gVisor** – verarbeitet den Datenverkehr im Userspace.\n- **MIPS** – mihomos eigener IP-Stack, verfügbar in der gebündelten Version 1.19.32.\n\nAuf Linux verwendet Xray standardmäßig seinen integrierten gVisor. System, Mixed und MIPS auf Linux verwenden mihomo als TUN-Engine und leiten TCP und UDP über eine authentifizierte lokale SOCKS-Verbindung an Xray weiter. Xray behält das Protokoll, das Anbieterprofil und das Routing bei. Für diese drei Optionen ist ein installierter mihomo erforderlich. Auf Windows verwendet Xray für alle vier TUN-Stacks mihomo 1.19.32 oder neuer. Protokolle und Routing bleiben in Xray. Anwendungsregeln unterstützen in dieser Kombination nur direkte Verbindungen und Blockieren; unter Linux benötigen diese Regeln den integrierten gVisor von Xray.\n\nDie Brücke führt einen zweiten Prozess aus. Bei drei Leerlaufmessungen auf dem Linux verbrauchte er etwa 32–36 MiB mehr physischen Speicher als der native Xray TUN. Dies misst nicht die Download-Last: CPU- und Speicherkosten hängen von den Verbindungen ab. sing-box hat keinen Stack-Selektor. Kein Stack garantiert eine bessere Leistung in jedem Netzwerk. Wählen Sie einen Stack aus und wählen Sie „Anwenden und erneut verbinden“, um ihn in Ihrem Netzwerk auszuprobieren.\n\n## Einstellungen übernehmen\n\nWenn Sie einen Server auswählen, wird die Verbindung automatisch wiederhergestellt. Modus-, Engine-, DNS- und Regeleinstellungen werden sofort gespeichert; Klicken Sie während einer aktiven Verbindung auf „Übernehmen“ und stellen Sie die Verbindung erneut her, um sie zu verwenden. Der Neustart einer Engine kann Downloads und Anrufe unterbrechen. Wiederholte Klicks starten keine Parallelverbindungen; Durch das Trennen wird der Übergang beendet und die Verbindung freigegeben.\n\nDas Internet nur über VPN blockiert den direkten Datenverkehr, wenn ein Tunnel unterbrochen wird. Es betrifft die gesamte Maschine. Durch eine explizite Trennung werden die Regeln von Sora entfernt. Wenn die Bereinigung nicht abgeschlossen ist, versuchen Sie erneut, die Verbindung zu trennen, und öffnen Sie das Protokoll.\n\n## Projektdokumentation\n\n- [sing-box-lx: Konfiguration und Support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box-Dokumentation](https://sing-box.sagernet.org/)\n- [Xray-Dokumentation](https://xtls.github.io/)\n- [mihomo-Dokumentation](https://wiki.metacubex.one/)\n- [zapret: Betrieb und Einschränkungen](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Überprüfen Sie die Server';

  @override
  String get extensions => 'Erweiterungen';

  @override
  String extRatingLabel(String rating) {
    return 'Rating $rating of 5';
  }

  @override
  String extByAuthor(String author) {
    return 'by $author';
  }

  @override
  String extInstallsCount(String count) {
    return '$count installs';
  }

  @override
  String get extInstallOne => '1 install';

  @override
  String get extBadgeVerified => 'Verified';

  @override
  String get extBadgeTop => 'Top this week';

  @override
  String get extBadgeNew => 'New';

  @override
  String get extBadgeStaff => 'Sora team';

  @override
  String get extSideloadShort => 'Not from catalog';

  @override
  String get extSideloadWarning =>
      'Not from the team catalog. The author\'s key is self-attested: install only if you trust the author.';

  @override
  String extInstallTitle(String name) {
    return 'Install $name';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Update $name';
  }

  @override
  String get extPermissionsIntro => 'This extension will be able to:';

  @override
  String get extPermissionsWidened => 'The update asks for new permissions:';

  @override
  String get extDangerousAck => 'I understand these permissions are powerful';

  @override
  String get extInstall => 'Install';

  @override
  String get extUpdate => 'Update';

  @override
  String get extCancel => 'Cancel';

  @override
  String get extConfirm => 'Confirm';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Catalog';

  @override
  String get extInstalled => 'Installed';

  @override
  String get extSearchHint => 'Search extensions';

  @override
  String get extCatAll => 'All';

  @override
  String get extCatTools => 'Tools';

  @override
  String get extCatThemes => 'Themes';

  @override
  String get extCatAutomation => 'Automation';

  @override
  String get extCatStats => 'Statistics';

  @override
  String get extCatNetwork => 'Network';

  @override
  String get extSortBy => 'Sort by';

  @override
  String get extSortPopular => 'Most popular';

  @override
  String get extSortRating => 'Highest rated';

  @override
  String get extSortName => 'Name';

  @override
  String get extCatalogError => 'Could not load the catalog';

  @override
  String get extRetry => 'Retry';

  @override
  String get extEmptySearch => 'Nothing found';

  @override
  String get extEmptyInstalled => 'No extensions installed yet.\nFind one in the catalog or install from a file.';

  @override
  String get extInstallFromFile => 'Install from file';

  @override
  String get extInstallFromUrl => 'Install from URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Download';

  @override
  String get extDownloading => 'Downloading…';

  @override
  String get extVerifying => 'Verifying…';

  @override
  String get extInstalling => 'Installing…';

  @override
  String get extInstallFailed => 'Install failed';

  @override
  String get extErrSignature => 'The signature check failed. The file may be damaged or tampered with.';

  @override
  String get extErrManifest => 'The extension manifest is invalid.';

  @override
  String get extErrNetwork => 'Network error. Check your connection and try again.';

  @override
  String get extErrHash => 'The download does not match the catalog. It may have been tampered with.';

  @override
  String extErrMinApp(String version) {
    return 'This extension needs app version $version or newer.';
  }

  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';

  @override
  String get extErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get extErrAuthorKeyChanged =>
      'This update is signed with a different author key than the installed version, so it was blocked. If you trust the new key, uninstall the extension and install it again explicitly.';

  @override
  String get extErrRevoked => 'This extension was revoked by the Sora team and cannot be installed or enabled.';

  @override
  String get extErrRevocationStale =>
      'The revocation list is out of date and cannot be refreshed right now, so installing and enabling extensions is blocked until it is renewed.';

  @override
  String get extUpdateAvailable => 'Update available';

  @override
  String get extDisabled => 'Disabled';

  @override
  String extToggleEnabled(String name) {
    return 'Enable $name';
  }

  @override
  String get extSearchInstalled => 'Search installed';

  @override
  String get extUpdateAll => 'Update all';

  @override
  String extUpdatesAvailable(int count) {
    return '$count updates available';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count updated';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Sensitive';

  @override
  String get extRiskDangerous => 'High risk';

  @override
  String get extPermissionsRemoved => 'No longer requested:';

  @override
  String get extUpdateFailedKept => 'The previous version is still installed.';

  @override
  String get extConflictsTitle => 'Extension conflicts';

  @override
  String get extConflictsIntro =>
      'These extensions want the same thing. Choose which one wins — the other stays installed. When the contested capability is wired into the engine, only the winner will run.';

  @override
  String get extConflictRoutingRules => 'Routing rules';

  @override
  String get extConflictTheme => 'App theme';

  @override
  String get extConflictNetHooks => 'Network hooks';

  @override
  String extConflictWinner(String name) {
    return '$name wins';
  }

  @override
  String extConflictsCount(int count) {
    return '$count conflicts need your decision';
  }

  @override
  String get extConflictsResolve => 'Resolve';

  @override
  String get extConflictNote =>
      'Your choice is saved on this device and will be applied once the engine supports these capabilities.';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extAuthor => 'Author';

  @override
  String get extRating => 'Rating';

  @override
  String get extInstalls => 'Installs';

  @override
  String get extVersion => 'Version';

  @override
  String get extAbout => 'About';

  @override
  String get extPermissionsTitle => 'Permissions';

  @override
  String get extNoPermissions => 'No special permissions.';

  @override
  String get extSettings => 'Settings';

  @override
  String get extSaveSettings => 'Save settings';

  @override
  String get extSaving => 'Saving…';

  @override
  String extUpdateTo(String version) {
    return 'Update to $version';
  }

  @override
  String get extEnabled => 'Enabled';

  @override
  String extRollbackTo(String version) {
    return 'Roll back to $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Roll back to version $version?';
  }

  @override
  String get extUninstall => 'Uninstall';

  @override
  String extUninstallConfirm(String name) {
    return 'Remove “$name” and its settings?';
  }

  @override
  String get extPanelUnavailable => 'The panel is unavailable. The extension may have been disabled or removed.';

  @override
  String get extCatalogSoonTitle => 'The team catalog is coming soon';

  @override
  String get extCatalogSoonBody =>
      'Until then, you can install extensions from a file or a link — every package is still signature-checked.';

  @override
  String get extPermConnectionsRead => 'See the list of active connections';

  @override
  String get extPermServersRead => 'See your server list';

  @override
  String get extPermSettingsRead => 'Read app settings';

  @override
  String get extPermSettingsWrite => 'Change app settings';

  @override
  String get extPermNotifications => 'Show notifications';

  @override
  String get extPermTray => 'Add tray menu entries';

  @override
  String get extPermUiPanel => 'Show panels inside the app';

  @override
  String get extPermThemeApply => 'Apply themes to the app';

  @override
  String get extPermRoutingRules => 'Add routing rules (affects where traffic goes)';

  @override
  String get extPermNetHooks => 'Hook into the network path (DPI bypass modules)';

  @override
  String get extPermNetFetch => 'Fetch URLs from an allowlist';

  @override
  String get extPermBackground => 'Run background tasks';

  @override
  String get extPermBackgroundDetail =>
      'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings. Background execution is not available in this version of Sora yet.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet — granting it changes nothing today.';

  @override
  String get extCapBackground => 'Runs in the background';

  @override
  String get extCapFilterTitle => 'Capabilities';

  @override
  String get extCapNetHook => 'Bypasses & network hooks';

  @override
  String get extCapPanel => 'Panels';

  @override
  String get extCapRouting => 'Routing rules';

  @override
  String get extCapTheme => 'Themes';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog · $date';
  }

  @override
  String get extChangelog => 'Changelog';

  @override
  String get extImageFailed => 'Couldn\'t load the image';

  @override
  String get extRatingHow => 'How ratings work';

  @override
  String get extRatingHowBody =>
      'Ratings use a Bayesian average: an extension with few ratings stays near the middle until more people vote, so a single 5-star review cannot push a new extension to the top. Recent ratings weigh more than old ones, and only one rating per account counts.';

  @override
  String get extScreenshots => 'Screenshots';

  @override
  String get extSortRelevance => 'Relevance';

  @override
  String get extPermNetworkDetail =>
      'Fetches data from the internet. Only the hosts below are allowed — everything else is blocked. Network fetch is not available in this version of Sora yet.';

  @override
  String get extBgTitle => 'Background task';

  @override
  String get extBgEnabled => 'Run in the background';

  @override
  String get extBgInterval => 'Run every';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minutes', one: '# minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# hours', one: '# hour');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'Background execution is not available in this version of Sora. Your schedule is saved and will apply automatically once the background runtime ships. The shortest interval is 15 minutes.';

  @override
  String get extBgRuntimeBadge => 'Not available yet';

  @override
  String get extBgDisabledNote => 'Enable the extension to manage its background task.';

  @override
  String get extCapNetwork => 'Network access';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Network: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Als $name';
  }

  @override
  String get diagnosticHttp => 'HTTP-Diagnose';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData =>
      'Noch keine erfassten Anfragen. Öffnen Sie zunächst eine Website für Geschwindigkeitstests.';

  @override
  String get qrShareTitle => 'Share via QR';

  @override
  String get qrScanTitle => 'Scan QR code';

  @override
  String get qrCopyLink => 'Copy link';

  @override
  String get qrShowLink => 'Show link';

  @override
  String get qrHideLink => 'Hide link';

  @override
  String get qrWarning => 'This QR code contains connection details. Do not show it to strangers.';

  @override
  String get qrScanHint => 'Point the camera at a QR code';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCamera => 'Camera is unavailable. Paste the link from the clipboard instead.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrTorch => 'Flashlight';

  @override
  String get connGroupByProcess => 'By process';

  @override
  String get connListView => 'As list';

  @override
  String get connCopyHost => 'Copy host';

  @override
  String get connAddRule => 'Add rule';

  @override
  String connConnectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# connections', one: '# connection');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Preset';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Custom';

  @override
  String get dnsCheck => 'Check for leaks';

  @override
  String get dnsChecking => 'Checking...';

  @override
  String get dnsNoLeak => 'No leaks found';

  @override
  String get dnsLeakFound => 'Leak detected';

  @override
  String get dnsLastCheck => 'Last check';

  @override
  String get dnsNeverChecked => 'Not checked yet';

  @override
  String get dnsLeakCheckTunnelDns => 'Tunnel DNS resolvers';

  @override
  String get dnsLeakCheckSystemResolvers => 'System resolvers';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Kill switch DNS cover';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Set the tunnel DNS in the DNS settings above.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Check which resolvers your system would use outside the tunnel.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Enable the kill switch so DNS stays inside the tunnel.';

  @override
  String get dnsLeakCheckEncryptedDns => 'OS encrypted DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS answer spoofing';

  @override
  String get dnsLeakFixReviewEncryptedDns => 'Check which encrypted DNS endpoints your system uses outside the tunnel.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Use encrypted DNS (DoT or DoH) for the tunnel so resolvers cannot forge answers.';

  @override
  String get dnsCheckNeedsConnection => 'Connect to the VPN first, then check for leaks.';

  @override
  String get dnsExpected => 'Expected';

  @override
  String get dnsActual => 'Observed';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Speed';

  @override
  String get sortName => 'Name';

  @override
  String get favorites => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorites yet. Tap the star on a server to add it here.';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get measureSpeed => 'Measure speed';

  @override
  String get benchmarkStale => 'outdated';

  @override
  String get autoSelectMode => 'Auto-select server';

  @override
  String get autoSelectPing => 'Fastest ping';

  @override
  String get autoSelectSpeed => 'Fastest speed';

  @override
  String get autoSelectSmart => 'Smart choice';

  @override
  String get coreWatchUnstable => 'The link to the core is unstable';

  @override
  String get watchReconnect => 'Reconnect';

  @override
  String get coreRestoringLink => 'Restoring the link to the core…';

  @override
  String get crashRestoreTitle => 'The last session was interrupted';

  @override
  String get restoreOnCrash => 'Restore session after a crash';

  @override
  String get crashRestore => 'Restore';

  @override
  String get crashDismiss => 'Not now';

  @override
  String get overrideTitle => 'My edits';

  @override
  String get overrideEdit => 'Edit servers';

  @override
  String get overrideHide => 'Hide';

  @override
  String get overrideUnhide => 'Show';

  @override
  String get overrideClear => 'Clear edits';

  @override
  String get overrideEmpty => 'No edits yet';

  @override
  String get overrideCustomRules => 'Custom rules';

  @override
  String get errBenchmarkUnsupported => 'Speed measurement needs a newer core';

  @override
  String benchmarkProgress(int done, int total) {
    return 'Measuring $done of $total…';
  }

  @override
  String get profiles => 'Network profiles';

  @override
  String get profilesEmpty => 'No profiles yet. Create one to apply settings automatically on known networks.';

  @override
  String get profileAdd => 'Add profile';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileSsids => 'Wi-Fi networks (SSID)';

  @override
  String get profileSsidsHint => 'Home, Office — comma separated';

  @override
  String get profileGateways => 'Gateways';

  @override
  String get profileAsns => 'AS numbers';

  @override
  String get profileAutoApply => 'Apply automatically';

  @override
  String get profileAutoApplyHint => 'Ask before applying when off';

  @override
  String get profileSnapshot => 'Remember current settings';

  @override
  String get profileSnapshotDone => 'Current settings saved into the profile';

  @override
  String get profileDelete => 'Delete profile';

  @override
  String profileDeleteConfirm(String name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String profileApplyAsk(String name) {
    return 'Apply profile \"$name\"?';
  }

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) {
    return 'Profile \"$name\" applied';
  }

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) {
    return 'Now: $info';
  }

  @override
  String get networkUnknown => 'Network info unavailable';

  @override
  String get profileNoTriggers => 'Add at least one trigger: SSID, gateway or ASN';

  @override
  String get chains => 'Proxy chains';

  @override
  String get chainsEmpty => 'No chains yet. Link 2–3 servers so traffic hops through each of them.';

  @override
  String get chainAdd => 'New chain';

  @override
  String get chainName => 'Chain name';

  @override
  String get chainPickServers => 'Pick 2–3 servers';

  @override
  String get chainOrderHint => 'Drag to reorder: traffic enters at the top and exits at the bottom.';

  @override
  String get chainTooFew => 'Pick at least 2 servers';

  @override
  String get chainTooMany => 'A chain holds at most 3 servers';

  @override
  String get chainEstimate => 'Estimated latency';

  @override
  String get chainSave => 'Save chain';

  @override
  String get chainDelete => 'Delete chain';

  @override
  String chainDeleteConfirm(String name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(String n) {
    return 'Hop $n';
  }

  @override
  String get chainEntry => 'Entry';

  @override
  String get chainExit => 'Exit';

  @override
  String get sync => 'Device sync';

  @override
  String get syncDevices => 'My devices';

  @override
  String get syncEmpty => 'No paired devices. Pair another device over the local network.';

  @override
  String get syncPair => 'Pair a device';

  @override
  String get syncShowCode => 'Show my code';

  @override
  String get syncScanCode => 'Scan a code';

  @override
  String get syncRevoke => 'Revoke';

  @override
  String syncRevokeConfirm(String name) {
    return 'Revoke \"$name\"?';
  }

  @override
  String syncLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get syncNever => 'Never';

  @override
  String get syncWhat => 'What syncs';

  @override
  String get syncWhatBody =>
      'Subscriptions, rules, settings and network profiles. Never synced: local logs, IPC tokens.';

  @override
  String get syncNoLan => 'Devices must be on the same local network';

  @override
  String get syncPaired => 'Device paired';

  @override
  String get syncPairingTitle => 'Pair with this device';

  @override
  String get syncWaiting => 'Waiting for the other device…';

  @override
  String get syncSecureNote => 'End-to-end encrypted channel. No accounts, no cloud servers.';

  @override
  String get zapretWithVpn => 'DPI bypass for direct traffic';

  @override
  String get zapretWithVpnHint =>
      'Runs zapret next to the VPN tunnel: tunneled traffic uses the VPN, direct traffic goes through the bypass.';

  @override
  String get lanSharing => 'Share connection on the local network';

  @override
  String get lanSharingHint =>
      'Devices on this network can go online through this connection. Access is by password: enter the proxy address, login and password below on the other device.';

  @override
  String get lanSharingLogin => 'Login';

  @override
  String get lanSharingPassword => 'Password';

  @override
  String get chainDuplicate => 'Each server can appear only once';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';

  @override
  String get autoSwitchOnDegradeDetail =>
      'If the selected server slows down a lot or stops answering, Sora switches to the best measured one — at most once every 10 minutes.';

  @override
  String get tunStackMixed => 'Mixed';

  @override
  String get tunStackSystem => 'System';

  @override
  String get censorTitle => 'Blocking diagnostics';

  @override
  String get censorHistory => 'Check history';

  @override
  String get censorEmpty =>
      'No checks yet. If a connection fails, the detector will check whether your provider is blocking it.';

  @override
  String get censorExplainer =>
      'This is not an app error: your provider seems to be limiting the connection. Masking changes how the app connects and often helps.';

  @override
  String get censorNoProfile => 'No suitable profile for this verdict';

  @override
  String get censorApplyProfile => 'Apply recommended profile';

  @override
  String get censorEnable => 'Enable';

  @override
  String get censorDetails => 'Details';

  @override
  String get censorNotNow => 'Not now';

  @override
  String get censorPromptTitle => 'Connection may be blocked';

  @override
  String censorPromptBody(int confidence) {
    return 'It looks like your provider is blocking the connection (confidence $confidence%). Try masking?';
  }

  @override
  String censorConfidence(int confidence) {
    return 'Confidence: $confidence%';
  }

  @override
  String get censorKindBlocked => 'Blocking detected';

  @override
  String get censorKindLikely => 'Looks like blocking';

  @override
  String get censorKindClear => 'No blocking detected';

  @override
  String get censorKindUnknown => 'Could not determine';

  @override
  String get censorReasonTlsReset => 'TLS connections are being reset — a typical sign of filtering';

  @override
  String get censorReasonHttpBlock => 'HTTP requests are being blocked';

  @override
  String get censorReasonDnsSpoofed => 'DNS responses are being spoofed';

  @override
  String get censorReasonConnectTimeout => 'Connections keep timing out';

  @override
  String get customServerAdd => 'Add custom server';

  @override
  String get customServers => 'My servers';

  @override
  String get customServerName => 'Name';

  @override
  String get customServerNameHint => 'E.g. My VPS';

  @override
  String get customServerNameRequired => 'Enter a name';

  @override
  String get customServerAddress => 'Address';

  @override
  String get customServerAddressHint => 'example.com or 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Enter the server address';

  @override
  String get customServerAddressInvalid => 'Invalid address';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port must be a number from 1 to 65535';

  @override
  String get customServerProtocol => 'Protocol';

  @override
  String get customServerCredentials => 'Credentials';

  @override
  String get customServerOptional => 'Optional';

  @override
  String get customServerShowSecret => 'Show secret';

  @override
  String get customServerHideSecret => 'Hide secret';

  @override
  String get customServerBadge => 'custom';

  @override
  String get flowAuto => 'auto';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Add a server manually: address, port and protocol';

  @override
  String get customServerTest => 'Test';

  @override
  String get errObfsUnsupported => 'The installed core is too old for obfuscation profiles. Update Sora to apply them.';

  @override
  String get leakTestTitle => 'Leak test';

  @override
  String get leakTestIntro =>
      'Probes whether traffic can leave the device outside the tunnel: direct DNS and ICMP, IPv6 egress, and the system resolvers. Run it while connected.';

  @override
  String get leakTestRun => 'Run test';

  @override
  String get leakTestCancel => 'Cancel';

  @override
  String get leakTestNeedsConnection => 'Connect to run the leak test.';

  @override
  String leakTestProgress(int count) {
    return 'Tests completed: $count';
  }

  @override
  String get leakTestAllClear => 'No leaks found';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# leaks found', one: '# leak found');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped — not applicable in this session';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Kill switch is on — run the test again to verify.';

  @override
  String get leakTestCheckDirectDns => 'Direct DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'System resolvers';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tunnel connectivity';

  @override
  String get leakTestCheckTunnelDns => 'Tunnel DNS';

  @override
  String get noticeDegraded => 'The server slowed down — switched to the best measured one';

  @override
  String get obfs => 'Traffic obfuscation';

  @override
  String get obfsPreset => 'Preset';

  @override
  String get obfsPresetAggressive => 'Maximum obfuscation';

  @override
  String get obfsPresetBalanced => 'Balanced';

  @override
  String get obfsPresetOff => 'Speed';

  @override
  String get obfsPresetLight => 'Light';

  @override
  String get obfsPresetCustom => 'Custom';

  @override
  String get obfsManual => 'Manual settings';

  @override
  String get obfsUtls => 'uTLS profile';

  @override
  String get obfsUtlsAuto => 'Auto';

  @override
  String get obfsJitter => 'Timing jitter';

  @override
  String get obfsJitterNeedsFragment => 'Jitter only works with fragmentation enabled.';

  @override
  String get obfsFineTune => 'Sizes and delays';

  @override
  String get obfsDetecting => 'Detecting capabilities…';

  @override
  String get obfsCapabilities => 'Engine capabilities';

  @override
  String obfsCompatibleEngines(String engines) {
    return 'Compatible engines: $engines';
  }

  @override
  String get obfsSupported => 'Supported';

  @override
  String get obfsUnsupported => 'Not supported';

  @override
  String get obfsUnknown => 'Capabilities are still being detected.';

  @override
  String get obfsMux => 'Multiplexing';

  @override
  String get obfsMuxDetail =>
      'Mux sends many streams over one TLS connection to a REALITY server, so the network sees a single handshake. Turn it off only if a server mishandles mux; separate handshakes may stand out more.';

  @override
  String get fragmentPerSessionNote =>
      'Per-session only: the stored obfuscation profile overrides this when connecting. Curated presets live in Traffic obfuscation.';

  @override
  String get syncCodeExpired => 'The code expired';

  @override
  String get syncDaemonFailed => 'Couldn\'t start the sync service';

  @override
  String get syncDaemonMissing => 'The sora-sync component wasn\'t found. Reinstall the app to enable device sync.';

  @override
  String get syncDaemonStarting => 'Starting the sync service…';

  @override
  String get syncErrAuth => 'The sync service rejected the access token. Restart the app and try again.';

  @override
  String get syncErrNotFound => 'The device is no longer paired';

  @override
  String get syncErrPairingActive => 'A pairing session is already open';

  @override
  String get syncErrUnreachable =>
      'The other device didn\'t answer. Make sure it\'s on the same network and showing its code.';

  @override
  String get syncError => 'Sync error';

  @override
  String syncExpiresIn(String duration) {
    return 'Code expires in $duration';
  }

  @override
  String get syncJoining => 'Pairing with the device…';

  @override
  String get syncLegacyCleared =>
      'The old device list was never actually paired, so it was cleared. Pair your devices again — for real this time.';

  @override
  String get syncNewCode => 'New code';

  @override
  String syncPairedWith(String name) {
    return '$name paired';
  }

  @override
  String get syncRetry => 'Try again';

  @override
  String get syncStopShowing => 'Stop showing';

  @override
  String get syncSyncNow => 'Sync now';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Received $pulled · sent $pushed';
  }

  @override
  String get syncResultTitle => 'Sync result';

  @override
  String get syncPulled => 'Received';

  @override
  String get syncPushed => 'Sent';

  @override
  String get syncNoChanges => 'No changes';

  @override
  String get syncDocKindSubscriptions => 'Subscriptions';

  @override
  String get syncDocKindSettings => 'App settings';

  @override
  String get syncDocKindOverrides => 'Subscription overrides';

  @override
  String get syncDocKindProfiles => 'Network profiles';

  @override
  String get syncDocKindChains => 'Proxy chains';

  @override
  String get syncDocKindObfs => 'Traffic obfuscation';

  @override
  String syncFrom(String name) {
    return 'from $name';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet — the sync service can\'t run there.';

  @override
  String smartPickReason(String ping, String speed) {
    return 'Picked by smart mode: ping $ping, speed $speed';
  }

  @override
  String serverReliability(int pct) {
    return 'Reliability $pct%';
  }

  @override
  String get errConnectionsUnavailable => 'The connection list is unavailable right now';

  @override
  String get errDiagnosticsFailed => 'Could not collect diagnostics';

  @override
  String get errDiagnosticsTooLarge => 'The diagnostics archive is too large';

  @override
  String get errEngineStalled => 'The tunnel stopped passing traffic';

  @override
  String get errEngineUnstable => 'The engine is unstable and keeps stopping';

  @override
  String get errNotFound => 'The requested item was not found';

  @override
  String get errProxyFailed => 'Could not set up the system proxy';

  @override
  String get errLogsUnavailable => 'This core does not keep a log';

  @override
  String get errLogFilterInvalid => 'The log filter is not valid: check the expression and the time range';

  @override
  String get errLogExportFailed => 'Could not export the log: it is too large. Narrow the filter and try again.';

  @override
  String get errProbeEndpointInvalid => 'A server address is missing or not valid';

  @override
  String get errProbeNoEndpoints => 'There are no servers to check';

  @override
  String get errProbeTooMany => 'Too many servers to check at once';

  @override
  String get errCancelled => 'The operation was cancelled';

  @override
  String get errRequestTooLarge => 'The request is too large';

  @override
  String get errSecretNotFound => 'A needed secret was not found';

  @override
  String get errSecretReferenceInvalid => 'The secret reference is not valid';

  @override
  String get errSecretTooLarge => 'The secret is too large to store';

  @override
  String get errSubNotFound => 'The subscription was not found';

  @override
  String get errSubIntervalInvalid => 'The update interval must be between one hour and 30 days';

  @override
  String get deviceIdTitle => 'Device identity';

  @override
  String get deviceIdSend => 'Send device identifier to subscription providers';

  @override
  String get deviceIdSendDetail => 'Providers with a device limit require the identifier to return the subscription.';

  @override
  String get deviceIdCurrent => 'Current identifier';

  @override
  String get deviceIdCopy => 'Copy';

  @override
  String get deviceIdReset => 'Reset identifier';

  @override
  String get deviceIdResetConfirm =>
      'Reset the device identifier? The provider will count this as a new device, and the reset may take another slot of its device limit. The old identifier is not kept.';
}
