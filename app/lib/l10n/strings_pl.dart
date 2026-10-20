// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class SPl extends S {
  SPl([String locale = 'pl']) : super(locale);

  @override
  String get stateOff => 'Nie podłączony';

  @override
  String get stateConnecting => 'Złączony';

  @override
  String get stateConnected => 'Połączony';

  @override
  String get stateReconnecting => 'Ponowne łączenie';

  @override
  String get stateDisconnecting => 'Rozłączanie';

  @override
  String get stateFailed => 'Nie podłączony';

  @override
  String get coreMissing => 'Usługa Sora nie odpowiada';

  @override
  String get serverAuto => 'Najszybszy';

  @override
  String get serverBypass => 'Brak serwera';

  @override
  String get addSubscription => 'Dodaj subskrypcję';

  @override
  String get servers => 'Serwery';

  @override
  String get settings => 'Ustawienia';

  @override
  String get subscription => 'Prenumerata';

  @override
  String get subscriptionLink => 'Link do subskrypcji';

  @override
  String get add => 'Dodać';

  @override
  String get refresh => 'Aktualizacja';

  @override
  String get rename => 'Przemianować';

  @override
  String get delete => 'Usuwać';

  @override
  String get cancel => 'Anulować';

  @override
  String get save => 'Ratować';

  @override
  String get name => 'Nazwa';

  @override
  String deleteSubscription(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get routes => 'Trasy';

  @override
  String get presetGlobal => 'Wszystko przez VPN';

  @override
  String get presetRu => 'Bezpośrednio Rosja';

  @override
  String get presetIr => 'Iran bezpośrednio';

  @override
  String get presetCn => 'Bezpośrednio w Chinach';

  @override
  String get blockAds => 'Blokuj reklamy';

  @override
  String get killSwitch => 'Internet tylko poprzez VPN';

  @override
  String get engine => 'Silnik';

  @override
  String get engineAuto => 'Automatyczny';

  @override
  String get animations => 'Animacje';

  @override
  String get logs => 'Dziennik';

  @override
  String get about => 'O';

  @override
  String get logsAll => 'Wszystko';

  @override
  String get logsImportant => 'Ważny';

  @override
  String get logsErrors => 'Błędy';

  @override
  String get search => 'Szukaj';

  @override
  String get export => 'Zapisz do pliku';

  @override
  String get clear => 'Jasne';

  @override
  String get logsEmpty => 'Nic tutaj';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get notInstalled => 'Nie zainstalowano';

  @override
  String get sourceCode => 'Kod źródłowy';

  @override
  String get license => 'Licencja';

  @override
  String usage(String used, String total) {
    return '$used z $total';
  }

  @override
  String until(String date) {
    return 'aż do $date';
  }

  @override
  String get expired => 'Wygasły';

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
    return '${n}MB';
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
  String get errGeneric => 'Coś poszło nie tak';

  @override
  String get errCore => 'Usługa Sora nie odpowiada';

  @override
  String get errAuth => 'Brak dostępu do usługi Sora';

  @override
  String get errVersion => 'Aktualizacja Sora: aplikacja i usługa to różne wersje';

  @override
  String get errBusy => 'Czekaj, poprzednie polecenie nadal działa';

  @override
  String get errEngineMissing => 'Nie znaleziono silnika dla tego serwera';

  @override
  String get errEngineStart => 'Silnik nie został uruchomiony';

  @override
  String get errEngineStopped => 'Silnik zatrzymał się';

  @override
  String get errTunnel => 'Brak uprawnień do utworzenia połączenia VPN';

  @override
  String get errServers => 'Serwer jest skonfigurowany z błędem';

  @override
  String get errNetwork => 'Nie można połączyć się z serwerem';

  @override
  String get errTimeout => 'Serwer nie odpowiedział na czas';

  @override
  String get errFirewall => 'Nie można zablokować Internetu poza VPN';

  @override
  String get errSubFetch => 'Nie można wczytać subskrypcji';

  @override
  String get errSubFormat => 'To nie jest link do subskrypcji';

  @override
  String get errSubEmpty => 'Subskrypcja nie ma serwerów';

  @override
  String get errSubDuplicate => 'Ta subskrypcja została już dodana';

  @override
  String get errSubLimit => 'Za dużo subskrypcji';

  @override
  String get errSubScheme => 'Link musi zaczynać się od https://';

  @override
  String get errSecretStore => 'Pamięć Sora jest uszkodzona lub niedostępna';

  @override
  String get errNoServers => 'Dodaj subskrypcję, aby się połączyć';

  @override
  String get exportText => 'Tekst';

  @override
  String get connections => 'Znajomości';

  @override
  String get close => 'Zamknąć';

  @override
  String get chainDirect => 'Bezpośredni';

  @override
  String get chainBlocked => 'Zablokowany';

  @override
  String get theme => 'Temat';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Światło';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Połączenie';

  @override
  String get sectionNoServer => 'Brak serwera';

  @override
  String get sectionPing => 'Świst';

  @override
  String get sectionLog => 'Diagnostyka';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Automatyczny';

  @override
  String get dnsHint => 'Adresy, oddzielone przecinkami';

  @override
  String get fragment => 'Fragmentacja TLS';

  @override
  String get fragmentPackets => 'Co podzielić';

  @override
  String get fragmentLength => 'Rozmiar kawałka';

  @override
  String get fragmentInterval => 'Pauza między kawałkami';

  @override
  String get byDefault => 'Domyślny';

  @override
  String get rangeHint => 'Na przykład 100-200';

  @override
  String get splitPos => 'Podzielone pozycje';

  @override
  String get splitPosHint => 'Na przykład 1, midsld';

  @override
  String get disorder => 'Zmień kolejność sztuk';

  @override
  String get tlsRecord => 'Podziel rekord TLS';

  @override
  String get tlsRecordNo => 'NIE';

  @override
  String get tlsRecordSni => 'Pod nazwą witryny';

  @override
  String get tlsRecordFirst => 'Po pierwszym bajcie';

  @override
  String get hostCase => 'Zmień przypadek hosta';

  @override
  String get probeMethod => 'Metoda';

  @override
  String get probeAuto => 'Automatyczny';

  @override
  String get probeEngine => 'Przez silnik';

  @override
  String get probeConnect => 'Tylko połączenie';

  @override
  String get probeUrl => 'Adres testowy';

  @override
  String get probeTimeout => 'Czekać';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Subskrypcje';

  @override
  String get subscriptionSettings => 'Ustawienia';

  @override
  String get userAgent => 'Agent użytkownika';

  @override
  String get autoUpdate => 'Aktualizuj automatycznie';

  @override
  String get updateInterval => 'Jak często';

  @override
  String get intervalProvider => 'Jak prosi dostawca';

  @override
  String hours(int n) {
    return '$n godz';
  }

  @override
  String get updateNow => 'Zaktualizuj teraz';

  @override
  String get logLevel => 'Co nagrać';

  @override
  String get levelDebug => 'Wszystko';

  @override
  String get levelInfo => 'Zwykły';

  @override
  String get levelWarning => 'Ważny';

  @override
  String get levelError => 'Tylko błędy';

  @override
  String get recordDestinations => 'Zapisz adresy witryn';

  @override
  String get reset => 'Zresetuj ustawienia';

  @override
  String get resetConfirm => 'Zresetować wszystkie ustawienia?';

  @override
  String get resetAction => 'Nastawić';

  @override
  String get invalidValue => 'Ta wartość nie będzie działać';

  @override
  String get website => 'Strona subskrypcji';

  @override
  String get providerWebsite => 'Strona internetowa dostawcy';

  @override
  String get support => 'Wsparcie';

  @override
  String controlPortQuestion(String engine) {
    return 'Sterowanie $engine odbywa się poprzez port tego komputera. Inne programy będą w stanie stwierdzić, że VPN jest włączony.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Wybierz $engine';
  }

  @override
  String get rules => 'Niestandardowe zasady';

  @override
  String get ruleAdd => 'Nowa zasada';

  @override
  String get ruleHint => 'Witryna, adres IP lub program';

  @override
  String get ruleDirect => 'Bezpośredni';

  @override
  String get ruleProxy => 'Przez VPN';

  @override
  String get ruleBlock => 'Blok';

  @override
  String get failover => 'Włącz awarię';

  @override
  String get connectOnStart => 'Połącz na starcie';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'subskrypcja kończy się za # dni',
      one: 'subskrypcja kończy się w dniu #',
      zero: 'subskrypcja kończy się za kilka godzin',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left lewy';
  }

  @override
  String get ruleInvalid => 'To nie wygląda na witrynę, adres IP ani program';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Z kolei serwery #',
      one: 'Z kolei serwer #',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serwery #, najszybsze',
      one: 'Serwer #, najszybszy',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Tryb';

  @override
  String get tunnelTun => 'Cały ruch';

  @override
  String get tunnelProxy => 'Serwer proxy System';

  @override
  String get proxyAddress => 'Adres proxy';

  @override
  String get copied => 'Skopiowano';

  @override
  String get launchAtLogin => 'Zacznij od systemu';

  @override
  String get launchAtLoginDetail =>
      'Sora będzie automatycznie uruchamiana przy logowaniu i pozostanie w zasobniku systemowym.';

  @override
  String get closeToTray => 'Przechowywać na tacy po zamknięciu';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get trayOpen => 'Otwórz Sora';

  @override
  String get trayConnect => 'Łączyć';

  @override
  String get trayDisconnect => 'Odłączyć';

  @override
  String get trayServer => 'Serwer';

  @override
  String get trayQuit => 'Wyjdź z Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora nadal znajduje się na tacy';

  @override
  String get noticeInTrayBody => 'Wyjdź z menu jego ikony';

  @override
  String get noticeLost => 'Połączenie utracone';

  @override
  String get noticeLostBody => 'Sora ponownie się łączy';

  @override
  String get noticeRestored => 'Połączono ponownie';

  @override
  String get noticeFailed => 'Nie udało się połączyć';

  @override
  String get noticeBackup => 'Główny serwer nie odpowiedział; kopia zapasowa przenosi ruch';

  @override
  String get noticeNext => 'Serwer nie odpowiedział; następny obsługuje ruch';

  @override
  String get noticeMainBack => 'Główny serwer ponownie odpowiada i przenosi ruch';

  @override
  String get noticeSubscription => 'Prenumerata';

  @override
  String get importTitle => 'Dodać tę subskrypcję?';

  @override
  String get importSealed =>
      'To łącze jest zaszyfrowane dla Happ i tylko Happ może je odczytać. Poproś swojego dostawcę o zwykły link do subskrypcji.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'brak odpowiedzi';

  @override
  String get home => 'Dom';

  @override
  String get navRules => 'Zasady';

  @override
  String get navConnections => 'Znajomości';

  @override
  String get navLogs => 'Dzienniki';

  @override
  String get navAbout => 'O';

  @override
  String get sidebarToggle => 'Przełącz pasek boczny';

  @override
  String get more => 'Więcej';

  @override
  String get less => 'Mniej';

  @override
  String get currentServer => 'Obecny serwer';

  @override
  String get trafficDown => 'Pobrano';

  @override
  String get trafficUp => 'Załadowany';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Aktywne reguły: $count';
  }

  @override
  String get recentNotifications => 'Najnowsze powiadomienia';

  @override
  String get notificationsEmpty => 'Tutaj pojawią się zdarzenia połączenia i subskrypcji';

  @override
  String get retryConnect => 'Ponów próbę połączenia';

  @override
  String get openLogs => 'Otwórz logi';

  @override
  String get tourReplay => 'Pokaż przewodnik ponownie';

  @override
  String tourStep(int step) {
    return 'Krok $step z 5';
  }

  @override
  String get tourBack => 'Z powrotem';

  @override
  String get tourNext => 'Następny';

  @override
  String get tourSkip => 'Pominąć';

  @override
  String get tourFinish => 'Zrobione';

  @override
  String get tourAdd => 'Dodaj link do subskrypcji swojego dostawcy.';

  @override
  String get tourServer => 'Wybierz serwer. „Najszybszy” wybierze jeden za Ciebie.';

  @override
  String get tourConnect => 'Kliknij tutaj, aby połączyć lub rozłączyć.';

  @override
  String get tourMode => 'Wybierz tryb. Przełącznik Kill blokuje Internet, jeśli VPN spadnie.';

  @override
  String get tourSettings => 'Otwórz ustawienia. Możesz tam odtworzyć ten przewodnik.';

  @override
  String get chooseProgram => 'Wybierz program';

  @override
  String get installedApps => 'Zainstalowane aplikacje';

  @override
  String get runningProcesses => 'Uruchomione procesy';

  @override
  String get programsFailed => 'Nie można załadować aplikacji';

  @override
  String get programsEmpty => 'Nie znaleziono żadnych aplikacji. Spróbuj innej nazwy.';

  @override
  String get selectExe => 'Wybierz plik .exe';

  @override
  String get trafficUnavailable => 'Liczniki nie są jeszcze dostępne';

  @override
  String get speedtest => 'Prędkość';

  @override
  String get speedtestCheck => 'Sprawdź prędkość';

  @override
  String get speedtestSearch => 'Znajdź usługę';

  @override
  String get speedtestEmpty => 'Brak dopasowań. Zmień wyszukiwanie.';

  @override
  String get speedtestBackToList => 'Wracając do usług';

  @override
  String get speedtestOpenBrowser => 'Otwórz w przeglądarce';

  @override
  String get speedtestUnavailable =>
      'Nie można uruchomić wbudowanej przeglądarki. Otwórz usługę w przeglądarce systemowej.';

  @override
  String get speedtestPageFailed =>
      'Nie udało się załadować strony. Załaduj go ponownie lub otwórz usługę w przeglądarce systemowej.';

  @override
  String get speedtestExternalFailed => 'Nie można otworzyć przeglądarki systemowej. Spróbuj ponownie.';

  @override
  String get modes => 'Tryby';

  @override
  String get proxyShort => 'Pełnomocnik';

  @override
  String get tunMode => 'Cały ruch (TUN)';

  @override
  String get checkUpdates => 'Sprawdź aktualizacje';

  @override
  String get updates => 'Aktualizacje aplikacji';

  @override
  String updateAvailable(String version) {
    return 'Dostępna jest wersja $version';
  }

  @override
  String get updateOpenAbout => 'Zobacz aktualizację';

  @override
  String updateNotes(String version) {
    return 'Zmiany w $version';
  }

  @override
  String get updateCheck => 'Sprawdź aktualizacje';

  @override
  String get updateChecking => 'Kontrola...';

  @override
  String get updateNoNotes => 'Wydanie nie posiada żadnych notatek.';

  @override
  String get updateDropWarning =>
      'Połączenie VPN zostanie zerwane na kilka sekund podczas aktualizacji Sora i jego podstawowej wersji. Kontynuować?';

  @override
  String get updateWaitConnection => 'Poczekaj, aż połączenie VPN i rdzeń będą gotowe.';

  @override
  String get updateDownloading => 'Pobieranie i weryfikacja plików...';

  @override
  String get updateInstalling => 'Przygotowywanie aktualizacji lub oczekiwanie na autoryzację administratora...';

  @override
  String get updateNetworkError => 'Nie można pobrać aktualizacji. Spróbuj ponownie.';

  @override
  String get updateReleaseError => 'Brakuje danych wersji lub wymaganych plików lub są one nieprawidłowe.';

  @override
  String get updateChecksumError => 'Pobieranie nie jest zgodne z SHA256SUMS. Nic nie zostało zainstalowane.';

  @override
  String get updateInstallError => 'Aktualizacja nie została zakończona. Uwierzytelnianie mogło zostać anulowane.';

  @override
  String get updateUnsupported =>
      'Ten plik wykonywalny nie jest własnością obsługiwanej pary pakietów Sora. Skorzystaj z instrukcji instalacji wersji.';

  @override
  String get updateManual =>
      'Uruchom to polecenie w terminalu, aby zainstalować oba zweryfikowane pakiety, a następnie otwórz ponownie Sora. Pliki pozostają w katalogu pobierania. Połączenie VPN zostanie zerwane.';

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
  String get updateCopyCommand => 'Kopiuj polecenie';

  @override
  String get updateChecksDisabled => 'Automatyczne sprawdzanie jest wyłączone w Ustawieniach.';

  @override
  String get updateInstalled => 'Aktualizacja zainstalowana. Otwórz ponownie Sora.';

  @override
  String get projectLinks => 'Projekt';

  @override
  String get githubReleases => 'Wydania i pliki do pobrania';

  @override
  String get telegramChannel => 'Kanał Telegram';

  @override
  String get licenses => 'Licencje';

  @override
  String get componentLicenses => 'Licencje na komponenty';

  @override
  String get appCopyright => '© 2026 levvs-one i współautorzy';

  @override
  String get collapseServers => 'Zwiń serwery';

  @override
  String get expandServers => 'Rozwiń serwery';

  @override
  String get hideDescription => 'Ukryj opis';

  @override
  String get showDescription => 'Pokaż opis';

  @override
  String get pendingConnectionChanges => 'Połącz się ponownie, aby zastosować te zmiany.';

  @override
  String get reconnectNow => 'Zastosuj i połącz ponownie';

  @override
  String get bypassLimitations =>
      'Ten tryb omija DPI tylko dla HTTP i TLS, nie obsługuje UDP ani nie zmienia adresu IP. Użyj serwera VPN dla głosu, połączeń i zablokowanych adresów Telegram Discord.';

  @override
  String get errEngineUnsupported =>
      'Wybrany silnik nie obsługuje tego profilu lub ustawień. Wybierz opcję Auto lub kompatybilny silnik.';

  @override
  String get errRestore =>
      'Czyszczenie połączenia było niekompletne. Spróbuj ponownie rozłączyć; szczegóły znajdziesz w logu.';

  @override
  String get errSessionEnded => 'Ta sesja już się zakończyła. Odśwież stan połączenia.';

  @override
  String get retryDisconnect => 'Spróbuj ponownie rozłączyć';

  @override
  String get tunStack => 'Stos TUN';

  @override
  String get modesInfo => 'O trybach';

  @override
  String get modesGuideTitle => 'Tryby i silniki';

  @override
  String get modesGuide =>
      'Wybierz opcję Auto, jeśli nie masz pewności, jakiego silnika potrzebuje Twój serwer. Sora sprawdza profil i ustawienia przed połączeniem. Silnik nie może zwiększyć przepustowości Twojego planu: wydajność zależy od serwera, trasy, protokołu i sieci.\n\n## Tryby\n\n### Cały ruch (TUN)\n\nSora tworzy wirtualny interfejs sieciowy i kieruje przez niego ruch aplikacji, w tym TCP i UDP. Użyj tego trybu dla Telegram, gier i głosu Discord. Reguły mogą bezpośrednio wysyłać określone witryny lub programy lub je blokować. Usługa sieciowa wymaga pozwolenia i serwera obsługującego wymagany protokół.\n\n### Serwer proxy System\n\nSora konfiguruje lokalny serwer proxy HTTP/SOCKS. Używają go aplikacje, które respektują systemowe ustawienia proxy. Aplikacje posiadające własny stos sieciowy mogą łączyć się bezpośrednio; Połączenia UDP i głosowe zazwyczaj wymagają TUN. Ten tryb jest odpowiedni dla przeglądarek i aplikacji obsługujących proxy.\n\n### Brak serwera\n\nW przypadku Linux Sora używa [zapret](https://github.com/bol-van/zapret) do dzielenia i przekształcania żądań HTTP/TLS oraz omijania niektórych kontroli DPI. Twój adres IP pozostaje taki sam, a połączenia przechodzą bezpośrednio na stronę internetową. Wyniki zależą od dostawcy i metody blokowania.\n\nObecna integracja wykorzystuje tpws dla HTTP i TLS przez TCP. Nie omija blokowania IP ani przekazywania UDP i nie może zagwarantować połączeń MTProto Telegram. Użyj serwera VPN z TUN dla głosu Discord, połączeń Telegram i tego rodzaju ograniczeń.\n\n## Silniki\n\n### Automatycznie\n\nSora wybiera zainstalowany silnik, który obsługuje cały plan połączeń: protokoły serwera, transporty, grupy, fragmentację i tryb. Niezgodny wybór ręczny zostanie odrzucony przed zatrzymaniem bieżącego połączenia. Wybierz Auto lub inny silnik i ponownie zastosuj ustawienia.\n\n### sing-box\n\nNowe pakiety Sora obejmują [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), rozwidlenie [sing-box](https://github.com/SagerNet/sing-box), dodanie XHTTP i VLESS Encryption po stronie klienta. Sora rozpoznaje konstrukcję i jej możliwości. Wersja wcześniejsza bez XHTTP nie zyskuje tej możliwości dzięki samej nazwie.\n\nObsługiwane protokoły obejmują parametry VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard i AmneziaWG 1.x/2.x Sora może importować. Pełne profile JSON Xray wymagają Xray. Nie można jeszcze importować nowych pól AWG 3.x. sing-box wykorzystuje chroniony hasłem port sterowania lokalnego, który mogą wykryć inne aplikacje na komputerze.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) obsługuje fragmentację VLESS, REALITY, XHTTP, VLESS Encryption i TLS. Obsługuje również kompletne profile dostawców Xray, zachowując jednocześnie ich routing i grupy. Takich profili nie można automatycznie przekonwertować na inny silnik bez zmiany ich zachowania.\n\nW zestawie Xray usunięto ustawienie wyłączające weryfikację certyfikatu TLS („allowInsecure”). Automatycznie wybiera sing-box lub mihomo dla zwykłych serwerów wymagających tego ustawienia. Wybranie Xray powoduje ręczne zgłoszenie niezgodności przed zatrzymaniem bieżącego połączenia. Starsze pełne profile JSON wymagają zaktualizowanego profilu dostawcy z weryfikowalnym certyfikatem lub kodem PIN certyfikatu.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) obsługuje uporządkowane grupy awaryjne i równoważące obciążenie, XHTTP i AmneziaWG. Wybierz tę opcję, gdy liczy się automatyczne przełączanie awaryjne na serwer zapasowy. Ustawienie fragmentacji TLS w Sora jest niedostępne w tym silniku.\n\n## Zgodność z Sora\n\n| Funkcja | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN i TCP/UDP | Tak | Tak | Tak |\n| XHTTP | Tak | Tak | Tak |\n| VLESS Encryption | Tak | Tak | Tak |\n| Pełny profil Xray | Nie | Tak | Nie |\n| TUIC / AnyTLS | Obydwa | Nie | TUIC |\n| Fragmentacja TLS | Tak | Tak | Nie |\n| AmneziaWG 1.x/2.x | Tak¹ | Nie | Tak |\n| Zamówiona grupa rezerwowa | Nie | Nie² | Tak |\n\n¹ Profile z J1/J2/J3/Itime wykorzystują mihomo; tych pól nie można nigdy po cichu odrzucić. ² Dla grupy kompletnych profili Xray aplikacja wybiera profil zapasowy. Wsparcie zależy od zainstalowanej kompilacji; sprawdź jego wersję w About.\n\n## Stos TUN\n\nStos obsługuje protokoły TCP i UDP wewnątrz interfejsu wirtualnego. W panelu trybów Xray i mihomo oferują gVisor, System, Mixed i MIPS. Każdy silnik zapisuje swoje własne preferencje. Tryby proxy i bezserwerowe System nie korzystają z tej preferencji.\n\n- **Mixed** — TCP korzysta ze stosu systemowego, natomiast gVisor obsługuje UDP. Jest to domyślne ustawienie mihomo w systemie Linux. W systemie Windows Xray i mihomo domyślnie używają MIPS.\n- **System** — używa stosu systemowego. Wypróbuj inną opcję, jeśli aplikacje sieciowe napotykają problemy.\n- **gVisor** — obsługuje ruch w przestrzeni użytkownika.\n- **MIPS** — własny stos IP mihomo, dostępny w dołączonej wersji 1.19.32.\n\nW Linux Xray domyślnie używa wbudowanego gVisor. System, Mixed i MIPS w Linux używają mihomo jako silnika TUN, przekazując TCP i UDP do Xray przez uwierzytelnione lokalne łącze SOCKS. Xray zachowuje protokół, profil dostawcy i routing. Te trzy opcje wymagają zainstalowanego mihomo. W przypadku Windows Xray używa mihomo 1.19.32 lub nowszego dla wszystkich czterech stosów TUN. Protokoły i routing pozostają w Xray. Reguły aplikacji w tym połączeniu obsługują tylko połączenia bezpośrednie i blokowanie; w Linux wymagają wbudowanego gVisor Xray.\n\nMost uruchamia drugi proces. W trzech pomiarach bezczynności Linux zużywał on około 32–36 MiB więcej pamięci fizycznej niż natywny Xray TUN. Nie mierzy to obciążenia pobierania: koszty procesora i pamięci zależą od połączeń. sing-box nie ma selektora stosu. Brak stosu gwarantuje lepszą wydajność w każdej sieci. Wybierz stos, a następnie wybierz Zastosuj i połącz ponownie, aby wypróbować go w swojej sieci.\n\n## Stosowanie ustawień\n\nWybranie serwera powoduje automatyczne ponowne połączenie. Ustawienia trybu, silnika, DNS i reguł są zapisywane natychmiast; podczas aktywnego połączenia kliknij Zastosuj i połącz się ponownie, aby z nich skorzystać. Ponowne uruchomienie silnika może przerwać pobieranie i połączenia. Powtarzające się kliknięcia nie uruchamiają połączeń równoległych; rozłączenie kończy przejście i zwalnia połączenie.\n\nInternet tylko przez VPN blokuje bezpośredni ruch w przypadku opadnięcia tunelu. Ma to wpływ na całą maszynę. Wyraźne rozłączenie usuwa reguły Sora. Jeśli czyszczenie nie zakończy się, spróbuj ponownie rozłączyć się i otwórz dziennik.\n\n## Dokumentacja projektu\n\n- [sing-box-lx: konfiguracja i wsparcie](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Dokumentacja sing-box](https://sing-box.sagernet.org/)\n- [Dokumentacja Xray](https://xtls.github.io/)\n- [Dokumentacja mihomo](https://wiki.metacubex.one/)\n- [zapret: działanie i ograniczenia](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Sprawdź serwery';

  @override
  String get extensions => 'Rozszerzenia';

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
    return 'Do $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostyka HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Nie ma jeszcze zarejestrowanych żądań. Najpierw otwórz witrynę z testami prędkości.';

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
  String get qrScanHint => 'Wybierz zrzut ekranu lub zdjęcie z kodem QR albo wklej link';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Na tym obrazie nie znaleziono kodu QR.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Otwórz obraz';

  @override
  String get connGroupByProcess => 'By process';

  @override
  String get connListView => 'As list';

  @override
  String get connCopyHost => 'Copy host';

  @override
  String get connAddRule => 'Add rule';

  @override
  String connConnectionsCount(num count) {
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
  String benchmarkProgress(Object done, Object total) {
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
  String profileDeleteConfirm(Object name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Apply profile \"$name\"?';
  }

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(Object name) {
    return 'Profile \"$name\" applied';
  }

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(Object info) {
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
  String chainDeleteConfirm(Object name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(Object n) {
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
  String syncRevokeConfirm(Object name) {
    return 'Revoke \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
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
  String get customServerShadowsocksCredentials =>
      'Dla Shadowsocks: metoda:hasło, na przykład chacha20-ietf-poly1305:haslo';
}
