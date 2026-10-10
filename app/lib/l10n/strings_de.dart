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
      'Wählen Sie „Auto“, wenn Sie nicht sicher sind, welche Engine Ihr Server benötigt. Sora überprüft das Profil und die Einstellungen vor der Verbindung. Eine Engine kann die Bandbreite Ihres Plans nicht erhöhen: Die Leistung hängt vom Server, der Route, dem Protokoll und dem Netzwerk ab.\n\n## Modi\n\n### Gesamter Datenverkehr (TUN)\n\nSora erstellt eine virtuelle Netzwerkschnittstelle und leitet den Anwendungsverkehr darüber weiter, einschließlich TCP und UDP. Verwenden Sie diesen Modus für Telegram, Spiele und Discord-Sprache. Regeln können bestimmte Websites oder Programme direkt senden oder blockieren. Der Netzwerkdienst benötigt eine Erlaubnis und einen Server, der das erforderliche Protokoll unterstützt.\n\n### System-Proxy\n\nSora konfiguriert einen lokalen HTTP/SOCKS-Proxy. Es wird von Anwendungen verwendet, die die Proxy-Einstellungen des Systems berücksichtigen. Anwendungen mit eigenem Netzwerk-Stack können sich direkt verbinden; UDP und Sprachanrufe benötigen im Allgemeinen TUN. Dieser Modus eignet sich für Browser und Anwendungen mit Proxy-Unterstützung.\n\n### Kein Server\n\nAuf Linux verwendet Sora [zapret](https://github.com/bol-van/zapret), um HTTP/TLS-Anfragen aufzuteilen und umzuformen und einige DPI-Prüfungen zu umgehen. Ihre IP bleibt gleich und Verbindungen gehen direkt zur Website. Die Ergebnisse hängen von Ihrem Anbieter und der Blockierungsmethode ab.\n\nDie aktuelle Integration verwendet tpws für HTTP und TLS über TCP. Es umgeht weder die IP-Blockierung noch leitet es UDP weiter und kann die MTProto-Verbindungen von Telegram nicht garantieren. Verwenden Sie einen VPN-Server mit TUN für Discord-Sprache, Telegram-Anrufe und solche Einschränkungen.\n\n## Motoren\n\n### Automatisch\n\nSora wählt eine installierte Engine aus, die den gesamten Verbindungsplan unterstützt: Serverprotokolle, Transporte, Gruppen, Fragmentierung und Modus. Eine inkompatible manuelle Auswahl wird abgelehnt, bevor die aktuelle Verbindung beendet wird. Wählen Sie „Auto“ oder eine andere Engine und wenden Sie die Einstellungen erneut an.\n\n### sing-box\n\nZu den neuen Sora-Paketen gehören [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), ein Zweig von [sing-box](https://github.com/SagerNet/sing-box), der clientseitige XHTTP und VLESS Encryption hinzufügt. Sora erkennt den Build und seine Fähigkeiten. Ein Upstream-Build ohne XHTTP erhält diese Fähigkeit nicht allein durch seinen Namen.\n\nZu den unterstützten Protokollen gehören VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard und die AmneziaWG 1.x/2.x-Parameter, die Sora importieren kann. Für vollständige Xray-JSON-Profile ist Xray erforderlich. Neue AWG 3.x-Felder können noch nicht importiert werden. sing-box verwendet einen passwortgeschützten lokalen Steuerungsport, den andere Anwendungen auf dem Computer erkennen können.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) unterstützt VLESS, REALITY, XHTTP, VLESS Encryption und TLS-Fragmentierung. Es führt auch vollständige Provider-Profile Xray aus und behält dabei deren Routing und Gruppen bei. Solche Profile können nicht automatisch in eine andere Engine konvertiert werden, ohne ihr Verhalten zu ändern.\n\nIm Paket Xray wurde die Einstellung entfernt, die die TLS-Zertifikatsüberprüfung deaktiviert („allowInsecure“). Bei normalen Servern, die diese Einstellung erfordern, wird automatisch sing-box oder mihomo ausgewählt. Wenn Sie Xray manuell auswählen, wird die Inkompatibilität gemeldet, bevor die aktuelle Verbindung beendet wird. Ältere vollständige JSON-Profile benötigen ein aktualisiertes Anbieterprofil mit einem überprüfbaren Zertifikat oder einer Zertifikats-PIN.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) unterstützt geordnete Fallback- und Lastausgleichsgruppen, XHTTP und AmneziaWG. Wählen Sie diese Option, wenn ein automatisches Failover auf einen Backup-Server wichtig ist. Die TLS-Fragmentierungseinstellung von Sora ist mit dieser Engine nicht verfügbar.\n\n## Kompatibilität in Sora\n\n| Funktion | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux TUN und TCP/UDP | Ja | Ja | Ja |\n| XHTTP | Ja | Ja | Ja |\n| VLESS Encryption | Ja | Ja | Ja |\n| Vollständiges Xray-Profil | Nein | Ja | Nein |\n| TUIC / AnyTLS | Beide | Nein | TUIC |\n| TLS-Fragmentierung | Ja | Ja | Nein |\n| AmneziaWG 1.x/2.x | Ja¹ | Nein | Ja |\n| Geordnete Fallback-Gruppe | Nein | Nein² | Ja |\n\n¹ Profile mit J1/J2/J3/Itime verwenden mihomo; Diese Felder dürfen niemals stillschweigend verworfen werden. ² Für eine Gruppe vollständiger Xray-Profile wählt die App ein Backup-Profil aus. Die Unterstützung hängt vom installierten Build ab. Überprüfen Sie die Version unter „Info“.\n\n## TUN-Stapel\n\nDer Stack verarbeitet TCP und UDP innerhalb der virtuellen Schnittstelle. Im Modi-Panel bieten Xray und mihomo gVisor, System, Mixed und MIPS an. Jede Engine speichert ihre eigene Präferenz. System-Proxy- und serverlose Modi verwenden diese Einstellung nicht.\n\n- **Mixed** – TCP verwendet den System-Stack, während gVisor UDP verarbeitet. Dies ist die Standardeinstellung für mihomo.\n- **System** – verwendet den System-Stack. Versuchen Sie eine andere Option, wenn bei Netzwerkanwendungen Probleme auftreten.\n- **gVisor** – verarbeitet den Datenverkehr im Userspace.\n- **MIPS** – mihomos eigener IP-Stack, verfügbar in der gebündelten Version 1.19.32.\n\nAuf Linux verwendet Xray standardmäßig seinen integrierten gVisor. System, Mixed und MIPS auf Linux verwenden mihomo als TUN-Engine und leiten TCP und UDP über eine authentifizierte lokale SOCKS-Verbindung an Xray weiter. Xray behält das Protokoll, das Anbieterprofil und das Routing bei. Für diese drei Optionen ist ein installierter mihomo erforderlich. Auf Windows verwendet TUN derzeit sing-box oder mihomo; Xray wird im System-Proxy-Modus ausgeführt.\n\nDie Brücke führt einen zweiten Prozess aus. Bei drei Leerlaufmessungen auf dem Linux verbrauchte er etwa 32–36 MiB mehr physischen Speicher als der native Xray TUN. Dies misst nicht die Download-Last: CPU- und Speicherkosten hängen von den Verbindungen ab. Behalten Sie gVisor, es sei denn, Sie benötigen einen weiteren Stapel. sing-box hat keinen Stack-Selektor. Kein Stack garantiert eine bessere Leistung in jedem Netzwerk. Wählen Sie einen Stack aus und wählen Sie „Anwenden und erneut verbinden“, um ihn in Ihrem Netzwerk auszuprobieren.\n\n## Einstellungen übernehmen\n\nWenn Sie einen Server auswählen, wird die Verbindung automatisch wiederhergestellt. Modus-, Engine-, DNS- und Regeleinstellungen werden sofort gespeichert; Klicken Sie während einer aktiven Verbindung auf „Übernehmen“ und stellen Sie die Verbindung erneut her, um sie zu verwenden. Der Neustart einer Engine kann Downloads und Anrufe unterbrechen. Wiederholte Klicks starten keine Parallelverbindungen; Durch das Trennen wird der Übergang beendet und die Verbindung freigegeben.\n\nDas Internet nur über VPN blockiert den direkten Datenverkehr, wenn ein Tunnel unterbrochen wird. Es betrifft die gesamte Maschine. Durch eine explizite Trennung werden die Regeln von Sora entfernt. Wenn die Bereinigung nicht abgeschlossen ist, versuchen Sie erneut, die Verbindung zu trennen, und öffnen Sie das Protokoll.\n\n## Projektdokumentation\n\n- [sing-box-lx: Konfiguration und Support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box-Dokumentation](https://sing-box.sagernet.org/)\n- [Xray-Dokumentation](https://xtls.github.io/)\n- [mihomo-Dokumentation](https://wiki.metacubex.one/)\n- [zapret: Betrieb und Einschränkungen](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Überprüfen Sie die Server';

  @override
  String get extensions => 'Erweiterungen';

  @override
  String get extensionsSoon => 'Kommt bald';

  @override
  String exportLogFile(String name) {
    return 'Als $name';
  }

  @override
  String get diagnosticHttp => 'HTTP-Diagnose';

  @override
  String get diagnosticPackets => 'Paketerfassung';

  @override
  String get diagnosticEvents => 'Windows-Ereignisse';

  @override
  String get diagnosticCapture => '10 Sekunden lang einfangen';

  @override
  String get diagnosticNoData =>
      'Noch keine erfassten Anfragen. Öffnen Sie zunächst eine Website für Geschwindigkeitstests.';

  @override
  String get diagnosticRequiresTun => 'Für die Paketerfassung ist eine aktive Sora TUN-Verbindung erforderlich.';

  @override
  String get diagnosticUnavailable => 'Diese Diagnose ist auf dieser Plattform nicht verfügbar.';
}
