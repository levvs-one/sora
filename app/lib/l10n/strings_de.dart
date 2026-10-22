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
  String get connEmpty => 'Keine Verbindungen';

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
  String get themeSystem => 'Wie im System';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Wie im System';

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
  String get programsEmpty => 'Keine Anwendungen gefunden. Versuchen Sie es mit einem anderen Namen.';

  @override
  String get selectExe => 'Wählen Sie eine .exe-Datei';

  @override
  String get speedtest => 'Geschwindigkeit';

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
      'Update-Dateien werden mit den Prüfsummen abgeglichen, die mit dem Release veröffentlicht werden.';

  @override
  String get updateManualSigWarning =>
      'Die Dateien unten passen zu den Prüfsummen des Releases. Führe den Befehl aus, wenn du sie aus dem offiziellen Release geladen hast.';

  @override
  String get updateVersionRevoked =>
      'Der Entwickler hat diese Version zurückgezogen. Bitte warten Sie auf eine korrigierte Veröffentlichung.';

  @override
  String get updateRolloutPending =>
      'Eine neuere Version wird nach und nach eingeführt und Ihnen automatisch angeboten.';

  @override
  String updateRollbacking(String version) {
    return 'Rollback auf Version $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Das Update auf $version hat die Integritätsprüfung nicht bestanden, daher wurde Sora auf $fromVersion zurückgesetzt.';
  }

  @override
  String get updateRollbackError =>
      'Automatisches Rollback fehlgeschlagen. Wenn die neue Version nicht funktioniert, installieren Sie die vorherige Version manuell neu.';

  @override
  String get updateRollbackCacheError =>
      'Es konnte keine verifizierte Rollback-Kopie der aktuellen Version erstellt werden, daher wurde das Update nicht installiert.';

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
    return 'Bewertung $rating von 5';
  }

  @override
  String extByAuthor(String author) {
    return 'von $author';
  }

  @override
  String extInstallsCount(String count) {
    return '$count Installationen';
  }

  @override
  String get extInstallOne => '1 Installation';

  @override
  String get extBadgeVerified => 'Verifiziert';

  @override
  String get extBadgeTop => 'Diese Woche am beliebtesten';

  @override
  String get extBadgeNew => 'Neu';

  @override
  String get extBadgeStaff => 'Das Sora-Team';

  @override
  String get extSideloadShort => 'Nicht aus dem Katalog';

  @override
  String get extSideloadWarning =>
      'Diese Erweiterung stammt nicht aus dem Teamkatalog. Nur der Autor hat für seinen Schlüssel bürgt: Installieren Sie ihn nur, wenn Sie dem Autor vertrauen.';

  @override
  String extInstallTitle(String name) {
    return '„$name“ installieren';
  }

  @override
  String extUpdateTitle(String name) {
    return '„$name“ aktualisieren';
  }

  @override
  String get extPermissionsIntro => 'Diese Erweiterung kann:';

  @override
  String get extPermissionsWidened => 'Das Update fordert neue Berechtigungen:';

  @override
  String get extDangerousAck => 'Ich verstehe, dass diese Berechtigungen ernst sind';

  @override
  String get extInstall => 'Installieren';

  @override
  String get extUpdate => 'Aktualisieren';

  @override
  String get extCancel => 'Abbrechen';

  @override
  String get extConfirm => 'Bestätigen';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'Installierte Erweiterungen';

  @override
  String get extSearchHint => 'Erweiterungen suchen';

  @override
  String get extCatAll => 'Alle';

  @override
  String get extCatTools => 'Werkzeuge';

  @override
  String get extCatThemes => 'Designs';

  @override
  String get extCatAutomation => 'Automatisierung';

  @override
  String get extCatStats => 'Statistik';

  @override
  String get extCatNetwork => 'Netzwerk';

  @override
  String get extSortBy => 'Sortieren nach';

  @override
  String get extSortPopular => 'Am beliebtesten';

  @override
  String get extSortRating => 'Höchste Bewertung';

  @override
  String get extSortName => 'Name';

  @override
  String get extCatalogError => 'Der Katalog konnte nicht geladen werden';

  @override
  String get extRetry => 'Wiederholen';

  @override
  String get extEmptySearch => 'Nichts gefunden';

  @override
  String get extEmptyInstalled =>
      'Noch keine Erweiterungen installiert.\nWählen Sie eine aus dem Katalog oder installieren Sie sie aus einer Datei.';

  @override
  String get extInstallFromFile => 'Aus Datei installieren';

  @override
  String get extInstallFromUrl => 'Installation von URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Herunterladen';

  @override
  String get extDownloading => 'Herunterladen…';

  @override
  String get extVerifying => 'Überprüfung…';

  @override
  String get extInstalling => 'Installieren…';

  @override
  String get extInstallFailed => 'Installation fehlgeschlagen';

  @override
  String get extErrSignature =>
      'Die Signaturprüfung ist fehlgeschlagen. Die Datei ist möglicherweise beschädigt oder manipuliert.';

  @override
  String get extErrManifest => 'Das Erweiterungsmanifest ist ungültig.';

  @override
  String get extErrNetwork => 'Netzwerkfehler. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get extErrHash =>
      'Die heruntergeladene Datei stimmt nicht mit dem Katalog überein. Sie wurde möglicherweise manipuliert.';

  @override
  String extErrMinApp(String version) {
    return 'Für diese Erweiterung ist die App-Version $version oder neuer erforderlich.';
  }

  @override
  String get extErrHttpsOnly => 'Es sind nur https://-Links zulässig';

  @override
  String get extErrGeneric => 'Etwas ist schief gelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get extErrAuthorKeyChanged =>
      'Dieses Update ist mit einem anderen Autorenschlüssel als die installierte Version signiert und wurde daher blockiert. Wenn Sie dem neuen Schlüssel vertrauen, deinstallieren Sie die Erweiterung und installieren Sie sie explizit erneut.';

  @override
  String get extUpdateAvailable => 'Update verfügbar';

  @override
  String get extDisabled => 'Deaktiviert';

  @override
  String extToggleEnabled(String name) {
    return '$name aktivieren';
  }

  @override
  String get extSearchInstalled => 'Installierte Erweiterungen suchen';

  @override
  String get extUpdateAll => 'Alle aktualisieren';

  @override
  String extUpdatesAvailable(int count) {
    return '$count Updates verfügbar';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count aktualisiert';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Sensibel';

  @override
  String get extRiskDangerous => 'Hohes Risiko';

  @override
  String get extPermissionsRemoved => 'Nicht mehr angefordert:';

  @override
  String get extUpdateFailedKept => 'Die Vorgängerversion ist noch installiert.';

  @override
  String get extConflictsTitle => 'Erweiterungskonflikte';

  @override
  String get extConflictsIntro =>
      'Diese Erweiterungen wollen dasselbe. Wähle, welche läuft; die andere bleibt installiert.';

  @override
  String get extConflictTheme => 'App-Theme';

  @override
  String get extConflictNetHooks => 'Netzwerk-Hooks';

  @override
  String extConflictWinner(String name) {
    return '$name gewinnt';
  }

  @override
  String extConflictsCount(int count) {
    return '$count Konflikte erfordern Ihre Entscheidung';
  }

  @override
  String get extConflictsResolve => 'Konflikte lösen';

  @override
  String get extConflictNote =>
      'Ihre Auswahl wird auf diesem Gerät gespeichert. Ein Design wechselt sofort, Netzwerk-Hooks laufen in dieser Version nicht.';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extAuthor => 'Autor';

  @override
  String get extRating => 'Bewertung';

  @override
  String get extInstalls => 'Installationen';

  @override
  String get extVersion => 'Version';

  @override
  String get extAbout => 'Über diese Erweiterung';

  @override
  String get extPermissionsTitle => 'Berechtigungen';

  @override
  String get extNoPermissions => 'Keine besonderen Berechtigungen.';

  @override
  String get extSettings => 'Einstellungen';

  @override
  String get extSaveSettings => 'Einstellungen speichern';

  @override
  String get extSaving => 'Speichern…';

  @override
  String extUpdateTo(String version) {
    return 'Upgrade auf $version';
  }

  @override
  String get extEnabled => 'Aktiviert';

  @override
  String extRollbackTo(String version) {
    return 'Rollback auf $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Rollback auf Version $version?';
  }

  @override
  String get extUninstall => 'Deinstallieren';

  @override
  String extUninstallConfirm(String name) {
    return '„$name“ und seine Einstellungen entfernen?';
  }

  @override
  String get extPanelUnavailable =>
      'Das Panel ist nicht verfügbar. Die Erweiterung wurde möglicherweise deaktiviert oder entfernt.';

  @override
  String get extPermConnectionsRead => 'Liste aktiver Verbindungen einsehen';

  @override
  String get extPermServersRead => 'Ihre Serverliste einsehen';

  @override
  String get extPermSettingsRead => 'App-Einstellungen lesen';

  @override
  String get extPermSettingsWrite => 'App-Einstellungen ändern';

  @override
  String get extPermNotifications => 'Benachrichtigungen anzeigen';

  @override
  String get extPermTray => 'Elemente zum Taskleistenmenü hinzufügen';

  @override
  String get extPermUiPanel => 'Panels innerhalb der App anzeigen';

  @override
  String get extPermThemeApply => 'Themen anwenden';

  @override
  String get extPermRoutingRules => 'Routing-Regeln hinzufügen (beeinflusst, wohin der Netzwerkverkehr geht)';

  @override
  String get extPermNetHooks => 'In den Netzwerkpfad integrieren (DPI Bypass-Module)';

  @override
  String get extPermNetFetch => 'Fordern Sie URL aus der Zulassungsliste an';

  @override
  String get extPermBackground => 'Hintergrundaufgaben ausführen';

  @override
  String get extPermBackgroundDetail =>
      'Führt geplante Aufgaben aus, auch wenn das Panel geschlossen ist. Sie können es anhalten oder ändern, wie oft es in den Erweiterungseinstellungen ausgeführt wird.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Läuft im Hintergrund';

  @override
  String get extCapNetHook => 'Umgehungen und Netzwerk-Hooks';

  @override
  String get extCapPanel => 'Panels';

  @override
  String get extCapRouting => 'Routing-Regeln';

  @override
  String get extCapTheme => 'Designs';

  @override
  String get extCapWidget => 'Widgets';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Änderungsprotokoll';

  @override
  String get extImageFailed => 'Das Bild konnte nicht geladen werden';

  @override
  String get extRatingHow => 'Wie Bewertungen funktionieren';

  @override
  String get extRatingHowBody =>
      'Die Bewertungen basieren auf einem Bayes\'schen Durchschnitt: Eine Erweiterung mit wenigen Bewertungen bleibt in der Nähe der Mitte, bis mehr Leute abstimmen, sodass eine einzelne 5-Sterne-Bewertung eine neue Erweiterung nicht an die Spitze bringen kann. Aktuelle Bewertungen wiegen mehr als alte und es zählt nur eine Bewertung pro Konto.';

  @override
  String get extScreenshots => 'Screenshots';

  @override
  String get extSortRelevance => 'Relevanz';

  @override
  String get extPermNetworkDetail =>
      'Lädt Daten über das VPN aus dem Internet. Nur die Hosts unten sind erlaubt, alles andere ist gesperrt.';

  @override
  String get extBgTitle => 'Hintergrundaufgabe';

  @override
  String get extBgEnabled => 'Im Hintergrund ausführen';

  @override
  String get extBgInterval => 'Ausführen alle';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# Minuten', one: '# Minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# Stunden', one: '# Stunde');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'Die Aufgabe läuft nach Zeitplan, solange Sora geöffnet ist, auch im Tray. Das kürzeste Intervall sind 15 Minuten.';

  @override
  String get extBgDisabledNote => 'Aktivieren Sie die Erweiterung, um ihre Hintergrundaufgabe zu verwalten.';

  @override
  String get extCapNetwork => 'Netzwerkzugriff';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Netzwerk: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Als $name';
  }

  @override
  String get diagnosticHttp => 'HTTP-Diagnose';

  @override
  String get diagnosticNoData =>
      'Noch keine erfassten Anfragen. Öffnen Sie zunächst eine Website für Geschwindigkeitstests.';

  @override
  String get qrShareTitle => 'Teilen Sie den QR-Code';

  @override
  String get qrScanTitle => 'QR-Code scannen';

  @override
  String get qrCopyLink => 'Link kopieren';

  @override
  String get qrWarning => 'Teile den Code nur mit Personen, denen du vertraust.';

  @override
  String get qrScanHint => 'Wähle einen Screenshot oder ein Foto mit QR-Code oder füge einen Link ein';

  @override
  String get qrFromClipboard => 'Aus der Zwischenablage einfügen';

  @override
  String get qrNoCode => 'In diesem Bild wurde kein QR-Code gefunden.';

  @override
  String get qrInvalid => 'Dieser QR-Code enthält keinen gültigen Link.';

  @override
  String get qrScan => 'Scannen QR';

  @override
  String get qrFromImage => 'Bild öffnen';

  @override
  String get connGroupByProcess => 'Nach Prozess gruppieren';

  @override
  String get connListView => 'Liste';

  @override
  String get connCopyHost => 'Host kopieren';

  @override
  String get connAddRule => 'Regel hinzufügen';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# Verbindungen', one: '# Verbindung');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Voreinstellung';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Benutzerdefiniert';

  @override
  String get dnsCheck => 'Auf Datenlecks prüfen';

  @override
  String get dnsChecking => 'Überprüfen...';

  @override
  String get dnsNoLeak => 'Keine Lecks gefunden';

  @override
  String get dnsLeakFound => 'Leck erkannt';

  @override
  String get dnsLastCheck => 'Letzte Überprüfung';

  @override
  String get dnsNeverChecked => 'Noch nicht getestet';

  @override
  String get dnsLeakCheckTunnelDns => 'DNS-Resolver des Tunnels';

  @override
  String get dnsLeakCheckSystemResolvers => 'Systemresolver';

  @override
  String get dnsLeakCheckKillSwitchDns => 'DNS-Schutz durch Netzwerksperre';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Konfigurieren Sie DNS für den Tunnel in den DNS-Einstellungen oben.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Prüfen Sie, welche Resolver Ihr System außerhalb des Tunnels verwenden würde.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Aktivieren Sie die Netzwerksperre, damit DNS-Verkehr im Tunnel bleibt.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Verschlüsseltes DNS des Betriebssystems';

  @override
  String get dnsLeakCheckDnsSpoof => 'Gefälschte DNS-Antworten';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Überprüfen Sie, welche verschlüsselten DNS-Endpunkte Ihr System außerhalb des Tunnels verwendet.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Verwenden Sie verschlüsseltes DNS (DoT oder DoH) für den Tunnel, damit Resolver keine Antworten fälschen können.';

  @override
  String get dnsCheckNeedsConnection => 'Verbinden Sie sich zuerst mit dem VPN und prüfen Sie dann auf Lecks.';

  @override
  String get dnsExpected => 'Erwartet';

  @override
  String get dnsActual => 'Beobachtet';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortSubscription => 'Wie im Abonnement';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Geschwindigkeit';

  @override
  String get sortName => 'Name';

  @override
  String get measureSpeed => 'Geschwindigkeit messen';

  @override
  String get benchmarkStale => 'veraltet';

  @override
  String get autoSelectMode => 'Server automatisch auswählen';

  @override
  String get autoSelectPing => 'Schnellster Ping';

  @override
  String get autoSelectSpeed => 'Höchste Geschwindigkeit';

  @override
  String get autoSelectSmart => 'Intelligente Wahl';

  @override
  String get coreWatchUnstable => 'Die Verbindung zum Sora-Kern ist instabil';

  @override
  String get watchReconnect => 'Erneut verbinden';

  @override
  String get coreRestoringLink => 'Wiederherstellung der Verbindung zum Sora-Kern…';

  @override
  String get crashRestoreTitle => 'Die letzte Sitzung wurde unterbrochen';

  @override
  String get restoreOnCrash => 'Sitzung nach einem Absturz wiederherstellen';

  @override
  String get crashRestore => 'Wiederherstellen';

  @override
  String get crashDismiss => 'Nicht jetzt';

  @override
  String get overrideTitle => 'Meine Änderungen';

  @override
  String get overrideEdit => 'Server bearbeiten';

  @override
  String get overrideHide => 'Ausblenden';

  @override
  String get overrideUnhide => 'Zeigen';

  @override
  String get overrideClear => 'Änderungen zurücksetzen';

  @override
  String get overrideEmpty => 'Noch keine Änderungen';

  @override
  String get overrideCustomRules => 'Eigene Regeln';

  @override
  String get errBenchmarkUnsupported => 'Geschwindigkeitsmessung benötigt einen neueren Kern';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Messung $done von $total…';
  }

  @override
  String get profiles => 'Netzwerkprofile';

  @override
  String get profilesEmpty =>
      'Noch keine Profile. Erstellen Sie eines, um Einstellungen automatisch auf bekannte Netzwerke anzuwenden.';

  @override
  String get profileAdd => 'Profil hinzufügen';

  @override
  String get profileName => 'Profilname';

  @override
  String get profileSsids => 'Wi-Fi Netzwerke (SSID)';

  @override
  String get profileSsidsHint => 'Privat, Büro durch Kommas getrennt';

  @override
  String get profileGateways => 'Netzwerk-Gateways';

  @override
  String get profileAsns => 'AS Zahlen';

  @override
  String get profileAutoApply => 'Automatisch anwenden';

  @override
  String get profileAutoApplyHint => 'Wenn deaktiviert, vor dem Anwenden des Profils nachfragen.';

  @override
  String get profileSnapshot => 'Aktuelle Einstellungen merken';

  @override
  String get profileSnapshotDone => 'Aktuelle Einstellungen im Profil gespeichert';

  @override
  String get profileDelete => 'Profil löschen';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Profil „$name“ löschen?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Profil „$name“ anwenden?';
  }

  @override
  String get profileApply => 'Anwenden';

  @override
  String profileApplied(Object name) {
    return 'Profil „$name“ angewendet';
  }

  @override
  String get profileUndo => 'Abbrechen';

  @override
  String get profileActive => 'Aktiv';

  @override
  String networkNow(Object info) {
    return 'Jetzt: $info';
  }

  @override
  String get networkUnknown => 'Netzwerkinformationen nicht verfügbar';

  @override
  String get profileNoTriggers => 'Fügen Sie mindestens einen Trigger hinzu: SSID, Gateway oder ASN';

  @override
  String get chains => 'Proxy-Ketten';

  @override
  String get chainsEmpty =>
      'Noch keine Ketten. Verknüpfen Sie zwei bis drei Server, sodass der Datenverkehr über jeden von ihnen läuft.';

  @override
  String get chainAdd => 'Neue Kette';

  @override
  String get chainName => 'Kettenname';

  @override
  String get chainPickServers => 'Wählen Sie 2–3 Server aus';

  @override
  String get chainOrderHint => 'Zum Neuordnen ziehen: Der Verkehr tritt oben ein und verlässt ihn unten.';

  @override
  String get chainTooFew => 'Wählen Sie mindestens 2 Server aus';

  @override
  String get chainTooMany => 'Eine Kette enthält höchstens 3 Server';

  @override
  String get chainEstimate => 'Geschätzte Latenz';

  @override
  String get chainSave => 'Kette speichern';

  @override
  String get chainDelete => 'Kette löschen';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Kette „$name“ löschen?';
  }

  @override
  String get chainUnsupported => 'Der aktuelle Motor kann keine Ketten erstellen';

  @override
  String get chainHopMissing => 'Einer der Kettenserver ist nicht mehr verfügbar';

  @override
  String chainHop(Object n) {
    return 'Hop $n';
  }

  @override
  String get chainEntry => 'Eingang';

  @override
  String get chainExit => 'Ausgang';

  @override
  String get sync => 'Gerätesynchronisierung';

  @override
  String get syncDevices => 'Meine Geräte';

  @override
  String get syncEmpty => 'Keine gekoppelten Geräte. Koppeln Sie ein anderes Gerät über das lokale Netzwerk.';

  @override
  String get syncPair => 'Gerät koppeln';

  @override
  String get syncShowCode => 'Zeige meinen Code';

  @override
  String get syncScanCode => 'Code scannen';

  @override
  String get syncRevoke => 'Zurückziehen';

  @override
  String syncRevokeConfirm(Object name) {
    return '„$name“ widerrufen?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Letzte Synchronisierung: $time';
  }

  @override
  String get syncNever => 'Niemals';

  @override
  String get syncNoLan => 'Geräte müssen sich im selben lokalen Netzwerk befinden';

  @override
  String get syncPaired => 'Gerät gekoppelt';

  @override
  String get syncPairingTitle => 'Mit diesem Gerät koppeln';

  @override
  String get syncWaiting => 'Warten auf das andere Gerät…';

  @override
  String get syncSecureNote => 'Ende-zu-Ende-verschlüsselter Kanal. Keine Konten, keine Cloud-Server.';

  @override
  String get zapretWithVpn => 'DPI-Filterung für direkten Netzwerkverkehr umgehen';

  @override
  String get zapretWithVpnHint =>
      'Führt zapret neben dem VPN-Tunnel aus: Tunnelverkehr nutzt das VPN, direkter Verkehr die Umgehung.';

  @override
  String get chainDuplicate => 'Jeder Server kann nur einmal erscheinen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get remove => 'Entfernen';

  @override
  String get autoSwitchOnDegrade => 'Automatische Umschaltung bei Verschlechterung';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Wenn der gewählte Server deutlich langsamer wird oder nicht mehr antwortet, wechselt Sora zum besten gemessenen Server, höchstens einmal alle 10 Minuten.';

  @override
  String get tunStackMixed => 'Gemischt';

  @override
  String get tunStackSystem => 'System';

  @override
  String get customServerAdd => 'Benutzerdefinierten Server hinzufügen';

  @override
  String get customServers => 'Meine Server';

  @override
  String get customServerName => 'Name';

  @override
  String get customServerNameHint => 'Zum Beispiel: mein VPS';

  @override
  String get customServerNameRequired => 'Geben Sie den Namen ein';

  @override
  String get customServerAddress => 'Adresse';

  @override
  String get customServerAddressHint => 'example.com oder 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Geben Sie die Serveradresse ein';

  @override
  String get customServerAddressInvalid => 'Ungültige Adresse';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port muss eine Zahl zwischen 1 und 65535 sein';

  @override
  String get customServerProtocol => 'Protokoll';

  @override
  String get customServerCredentials => 'Anmeldeinformationen';

  @override
  String get customServerOptional => 'Optional';

  @override
  String get customServerShowSecret => 'Geheimnis anzeigen';

  @override
  String get customServerHideSecret => 'Geheimnis verbergen';

  @override
  String get customServerBadge => 'benutzerdefiniert';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Server „$name“ löschen?';
  }

  @override
  String get customServerEmptyHint => 'Fügen Sie einen Server manuell hinzu: Adresse, Port und Protokoll';

  @override
  String get customServerTest => 'Test';

  @override
  String get leakTestTitle => 'Test auf Datenlecks';

  @override
  String get leakTestIntro =>
      'Prüft, ob Datenverkehr das Gerät am Tunnel vorbei verlassen kann: direkte DNS- und ICMP-Anfragen, IPv6-Ausgang und Systemresolver. Führen Sie den Test bei aktiver Verbindung aus.';

  @override
  String get leakTestRun => 'Prüfen';

  @override
  String get leakTestCancel => 'Abbrechen';

  @override
  String get leakTestNeedsConnection => 'Stellen Sie eine Verbindung zum VPN her, um auf Datenlecks zu testen.';

  @override
  String leakTestProgress(int count) {
    return 'Abgeschlossene Tests: $count';
  }

  @override
  String get leakTestAllClear => 'Keine Lecks gefunden';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# Lecks gefunden', one: '# Leck gefunden');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Beheben';

  @override
  String get leakTestFixedNote => 'Die Netzwerksperre ist aktiv. Führen Sie den Test erneut durch.';

  @override
  String get leakTestCheckDirectDns => 'Direkt DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP Echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Systemresolver';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tunnelkonnektivität';

  @override
  String get leakTestCheckTunnelDns => 'DNS durch den Tunnel';

  @override
  String get noticeDegraded => 'Der Server wurde langsamer. Sora hat zum besten gemessenen Server gewechselt.';

  @override
  String get obfs => 'Datenverkehr verschleiern';

  @override
  String get syncCodeExpired => 'Code ist abgelaufen';

  @override
  String get syncDaemonFailed => 'Der Synchronisierungsdienst konnte nicht gestartet werden';

  @override
  String get syncDaemonMissing =>
      'Die Komponente sora-sync wurde nicht gefunden. Installieren Sie die App neu, um die Gerätesynchronisierung zu aktivieren.';

  @override
  String get syncDaemonStarting => 'Synchronisierungsdienst wird gestartet…';

  @override
  String get syncErrAuth =>
      'Der Synchronisierungsdienst hat das Zugriffstoken abgelehnt. Starten Sie die App neu und versuchen Sie es erneut.';

  @override
  String get syncErrNotFound => 'Das Gerät ist nicht mehr gekoppelt';

  @override
  String get syncErrPairingActive => 'Eine Pairing-Sitzung ist bereits geöffnet';

  @override
  String get syncErrUnreachable =>
      'Das andere Gerät hat nicht geantwortet. Stellen Sie sicher, dass es sich im selben Netzwerk befindet und seinen Code anzeigt.';

  @override
  String get syncError => 'Synchronisierungsfehler';

  @override
  String syncExpiresIn(String duration) {
    return 'Code läuft in $duration ab';
  }

  @override
  String get syncJoining => 'Kopplung mit dem Gerät...';

  @override
  String get syncLegacyCleared =>
      'Die alte Geräteliste wurde nie wirklich gekoppelt und daher gelöscht. Koppeln Sie Ihre Geräte erneut, diesmal wirklich.';

  @override
  String get syncNewCode => 'Neuer Code';

  @override
  String syncPairedWith(String name) {
    return 'Gepaart mit $name';
  }

  @override
  String get syncRetry => 'Wiederholen';

  @override
  String get syncStopShowing => 'Code ausblenden';

  @override
  String get syncSyncNow => 'Jetzt synchronisieren';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled empfangen, $pushed gesendet';
  }

  @override
  String get syncResultTitle => 'Synchronisierungsergebnis';

  @override
  String get syncPulled => 'Empfangen';

  @override
  String get syncPushed => 'Gesendet';

  @override
  String get syncNoChanges => 'Keine Änderungen festgestellt';

  @override
  String get syncDocKindSubscriptions => 'Abonnements';

  @override
  String get syncDocKindSettings => 'App-Einstellungen';

  @override
  String get syncDocKindOverrides => 'Abonnement-Anpassungen';

  @override
  String get syncDocKindProfiles => 'Netzwerkprofile';

  @override
  String get syncDocKindChains => 'Proxy-Ketten';

  @override
  String syncFrom(String name) {
    return 'von $name';
  }

  @override
  String get syncThisDevice => 'Dieses Gerät';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Für Shadowsocks: Methode:Passwort, zum Beispiel chacha20-ietf-poly1305:passwort';

  @override
  String get diagnosticPackets => 'Paketerfassung';

  @override
  String get diagnosticEvents => 'Windows-Ereignisse';

  @override
  String get diagnosticCapture => '10 Sekunden lang einfangen';

  @override
  String get diagnosticRequiresTun => 'Für die Paketerfassung ist eine aktive Sora TUN-Verbindung erforderlich.';

  @override
  String get diagnosticUnavailable => 'Diese Diagnose ist auf dieser Plattform nicht verfügbar.';

  @override
  String get extErrRevoked =>
      'Das Sora-Team hat diese Version der Erweiterung zurückgezogen, weil sie unsicher oder defekt ist.';

  @override
  String get extErrRevocationsExpired =>
      'Die Liste zurückgezogener Erweiterungen konnte nicht erneuert werden. Installationen sind gesperrt, bis das gelingt: Netzwerk prüfen und erneut versuchen.';

  @override
  String extRevokedDisabled(String names) {
    return 'Zurückgezogene Erweiterungen wurden ausgeschaltet: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Privater Schlüssel';

  @override
  String get customServerWgAddresses => 'Schnittstellenadressen';

  @override
  String get customServerWgPeerKey => 'Öffentlicher Schlüssel des Servers';

  @override
  String get customServerWgPresharedKey => 'Gemeinsamer Schlüssel';

  @override
  String get customServerWgAllowedIps => 'Erlaubte IPs';

  @override
  String get customServerWgKeepalive => 'Keepalive, Sekunden';

  @override
  String get customServerWgKeyInvalid => 'Der Schlüssel muss 32 Byte in Base64 sein, wie wg genkey ihn ausgibt.';

  @override
  String get customServerWgCidrInvalid => 'Präfixe kommagetrennt eingeben, etwa 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Eine Sekundenzahl von 0 bis 65535 eingeben.';

  @override
  String get strictKillSwitch => 'Strikte Netzwerksperre';

  @override
  String get strictKillSwitchWarning =>
      'Blockiert nach dem Verbinden Datenverkehr außerhalb des VPN auch bei Absturz, Neustart oder Beenden der App. Nur Trennen oder Ausschalten dieser Option gibt den Zugriff frei. Nach einem Systemneustart greift die Sperre nur bei aktivierter Verbindung beim Start.';

  @override
  String get extWorkerFailed =>
      'Die Hintergrundaufgabe der Erweiterung ist fehlgeschlagen. Prüfe das Erweiterungsprotokoll.';

  @override
  String get extAssetRejected => 'Erweiterungsdatei abgelehnt: unlesbare Farben oder ungültige Regeln.';
}
