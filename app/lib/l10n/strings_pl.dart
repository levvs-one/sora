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
  String get connEmpty => 'Brak połączeń';

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
  String get errAuth => 'Odmówiono dostępu do usługi Sora';

  @override
  String get errVersion => 'Aplikacja i usługa Sora mają różne wersje';

  @override
  String get errBusy => 'Poprzednie polecenie jest nadal wykonywane';

  @override
  String get errEngineMissing => 'Brakuje silnika wymaganego przez ten serwer';

  @override
  String get errEngineStart => 'Nie udało się uruchomić silnika';

  @override
  String get errEngineStopped => 'Silnik został zatrzymany';

  @override
  String get errTunnel => 'Ten tryb VPN jest niedostępny';

  @override
  String get errTimeout => 'Serwer nie odpowiedział na czas';

  @override
  String get errFirewall => 'Nie udało się zablokować dostępu do Internetu poza VPN';

  @override
  String get errSubFetch => 'Nie udało się pobrać subskrypcji';

  @override
  String get deviceIdentity => 'Identyfikator urządzenia';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Zresetuj identyfikator';

  @override
  String get deviceIdentityResetConfirm => 'Zresetować identyfikator urządzenia?';

  @override
  String get errSubDeviceLimit => 'Osiągnięto limit urządzeń';

  @override
  String get errSubDeviceRequired => 'Dostawca wymaga identyfikatora urządzenia';

  @override
  String get errSubFormat => 'Nie rozpoznano formatu subskrypcji';

  @override
  String get errSubEmpty => 'Subskrypcja nie zawiera serwerów';

  @override
  String get errSubDuplicate => 'Ta subskrypcja została już dodana';

  @override
  String get errSubLimit => 'Osiągnięto limit subskrypcji';

  @override
  String get errSubScheme => 'Nieobsługiwany schemat linku subskrypcji';

  @override
  String get errSecretStore => 'Magazyn danych Sora jest uszkodzony lub niedostępny';

  @override
  String get errNoServers => 'Brak serwerów, z którymi można się połączyć';

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
  String get themeSystem => 'Jak w systemie';

  @override
  String get themeLight => 'Światło';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'Jak w systemie';

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
  String get splitPos => 'Podzielone pozycje';

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
      other: 'subskrypcja kończy się za $days dni',
      one: 'subskrypcja kończy się w dniu $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serwery $count, najszybsze',
      one: 'Serwer $count, najszybszy',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Tryb';

  @override
  String get tunnelProxy => 'Serwer proxy System';

  @override
  String get proxyAddress => 'Adres proxy';

  @override
  String get copied => 'Skopiowano';

  @override
  String get launchAtLogin => 'Zacznij od systemu';

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
  String get importSealed => 'To łącze jest zaszyfrowane dla Happ i tylko Happ może je odczytać';

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
  String get notificationsEmpty => 'Brak powiadomień';

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
  String get programsEmpty => 'Nie znaleziono żadnych aplikacji';

  @override
  String get selectExe => 'Wybierz plik .exe';

  @override
  String get speedtest => 'Prędkość';

  @override
  String get speedtestSearch => 'Znajdź usługę';

  @override
  String get speedtestEmpty => 'Brak dopasowań';

  @override
  String get speedtestBackToList => 'Wracając do usług';

  @override
  String get speedtestOpenBrowser => 'Otwórz w przeglądarce';

  @override
  String get speedtestUnavailable => 'Nie można uruchomić wbudowanej przeglądarki';

  @override
  String get speedtestPageFailed => 'Nie udało się załadować strony';

  @override
  String get speedtestExternalFailed => 'Nie można otworzyć przeglądarki systemowej';

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
  String get updateDropWarning => 'Rozłączyć, aby zaktualizować?';

  @override
  String get updateWaitConnection => 'Połączenie nie jest gotowe';

  @override
  String get updateNetworkError => 'Nie można pobrać aktualizacji';

  @override
  String get updateReleaseError => 'Brakuje danych wersji lub wymaganych plików lub są one nieprawidłowe.';

  @override
  String get updateChecksumError => 'Pobieranie nie jest zgodne z SHA256SUMS';

  @override
  String get updateInstallError => 'Aktualizacja nie została zakończona';

  @override
  String get updateUnsupported => 'Ten plik wykonywalny nie jest własnością obsługiwanej pary pakietów Sora';

  @override
  String get updateVersionRevoked => 'Deweloper wycofał tę wersję';

  @override
  String updateRollbacking(String version) {
    return 'Wycofywanie do wersji $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Aktualizacja $version nie przeszła kontroli stanu, więc Sora została przywrócona do $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Automatyczne przywracanie nie powiodło się';

  @override
  String get updateRollbackCacheError =>
      'Nie można przygotować zweryfikowanej kopii przywracającej bieżącej wersji, więc aktualizacja nie została zainstalowana.';

  @override
  String get updateCopyCommand => 'Kopiuj polecenie';

  @override
  String get updateInstalled => 'Aktualizacja zainstalowana';

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
  String get collapseServers => 'Zwiń serwery';

  @override
  String get expandServers => 'Rozwiń serwery';

  @override
  String get hideDescription => 'Ukryj opis';

  @override
  String get showDescription => 'Pokaż opis';

  @override
  String get errEngineUnsupported => 'Wybrany silnik nie obsługuje tego profilu lub ustawień';

  @override
  String get errRestore => 'Czyszczenie połączenia było niekompletne';

  @override
  String get errSessionEnded => 'Ta sesja już się zakończyła';

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
      'Wybierz opcję Auto, jeśli nie masz pewności, jakiego silnika potrzebuje Twój serwer. Sora sprawdza profil i ustawienia przed połączeniem. Silnik nie może zwiększyć przepustowości Twojego planu: wydajność zależy od serwera, trasy, protokołu i sieci.\n\n## Tryby\n\n### Cały ruch (TUN)\n\nSora tworzy wirtualny interfejs sieciowy i kieruje przez niego ruch aplikacji, w tym TCP i UDP. Użyj tego trybu dla Telegram, gier i głosu Discord. Reguły mogą bezpośrednio wysyłać określone witryny lub programy lub je blokować. Usługa sieciowa wymaga pozwolenia i serwera obsługującego wymagany protokół.\n\n### Serwer proxy System\n\nSora konfiguruje lokalny serwer proxy HTTP/SOCKS. Używają go aplikacje, które respektują systemowe ustawienia proxy. Aplikacje posiadające własny stos sieciowy mogą łączyć się bezpośrednio; Połączenia UDP i głosowe zazwyczaj wymagają TUN. Ten tryb jest odpowiedni dla przeglądarek i aplikacji obsługujących proxy.\n\n### Brak serwera\n\nW przypadku Linux Sora używa [zapret](https://github.com/bol-van/zapret) do dzielenia i przekształcania żądań HTTP/TLS oraz omijania niektórych kontroli DPI. Twój adres IP pozostaje taki sam, a połączenia przechodzą bezpośrednio na stronę internetową. Wyniki zależą od dostawcy i metody blokowania.\n\nObecna integracja wykorzystuje tpws dla HTTP i TLS przez TCP. Nie omija blokowania IP ani przekazywania UDP i nie może zagwarantować połączeń MTProto Telegram. Użyj serwera VPN z TUN dla głosu Discord, połączeń Telegram i tego rodzaju ograniczeń.\n\n## Silniki\n\n### Automatycznie\n\nSora wybiera zainstalowany silnik, który obsługuje cały plan połączeń: protokoły serwera, transporty, grupy, fragmentację i tryb. Niezgodny wybór ręczny zostanie odrzucony przed zatrzymaniem bieżącego połączenia. Wybierz Auto lub inny silnik i ponownie zastosuj ustawienia.\n\n### sing-box\n\nNowe pakiety Sora obejmują [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), rozwidlenie [sing-box](https://github.com/SagerNet/sing-box), dodanie XHTTP i VLESS Encryption po stronie klienta. Sora rozpoznaje konstrukcję i jej możliwości. Wersja wcześniejsza bez XHTTP nie zyskuje tej możliwości dzięki samej nazwie.\n\nObsługiwane protokoły obejmują parametry VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard i AmneziaWG 1.x/2.x Sora może importować. Pełne profile JSON Xray wymagają Xray. Nie można jeszcze importować nowych pól AWG 3.x. sing-box wykorzystuje chroniony hasłem port sterowania lokalnego, który mogą wykryć inne aplikacje na komputerze.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) obsługuje fragmentację VLESS, REALITY, XHTTP, VLESS Encryption i TLS. Obsługuje również kompletne profile dostawców Xray, zachowując jednocześnie ich routing i grupy. Takich profili nie można automatycznie przekonwertować na inny silnik bez zmiany ich zachowania.\n\nW zestawie Xray usunięto ustawienie wyłączające weryfikację certyfikatu TLS („allowInsecure”). Automatycznie wybiera sing-box lub mihomo dla zwykłych serwerów wymagających tego ustawienia. Wybranie Xray powoduje ręczne zgłoszenie niezgodności przed zatrzymaniem bieżącego połączenia. Starsze pełne profile JSON wymagają zaktualizowanego profilu dostawcy z weryfikowalnym certyfikatem lub kodem PIN certyfikatu.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) obsługuje uporządkowane grupy awaryjne i równoważące obciążenie, XHTTP i AmneziaWG. Wybierz tę opcję, gdy liczy się automatyczne przełączanie awaryjne na serwer zapasowy. Ustawienie fragmentacji TLS w Sora jest niedostępne w tym silniku.\n\n## Zgodność z Sora\n\n| Funkcja | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN i TCP/UDP | Tak | Tak | Tak |\n| XHTTP | Tak | Tak | Tak |\n| VLESS Encryption | Tak | Tak | Tak |\n| Pełny profil Xray | Nie | Tak | Nie |\n| TUIC / AnyTLS | Obydwa | Nie | TUIC |\n| mieru | Nie | Nie | Tak |\n| NaiveProxy | Tak | Nie | Nie |\n| Fragmentacja TLS | Tak | Tak | Nie |\n| AmneziaWG 1.x/2.x | Tak¹ | Nie | Tak |\n| Zamówiona grupa rezerwowa | Nie | Nie² | Tak |\n\n¹ Profile z J1/J2/J3/Itime wykorzystują mihomo; tych pól nie można nigdy po cichu odrzucić. ² Dla grupy kompletnych profili Xray aplikacja wybiera profil zapasowy. Wsparcie zależy od zainstalowanej kompilacji; sprawdź jego wersję w About.\n\n## Stos TUN\n\nStos obsługuje protokoły TCP i UDP wewnątrz interfejsu wirtualnego. W panelu trybów Xray i mihomo oferują gVisor, System, Mixed i MIPS. Każdy silnik zapisuje swoje własne preferencje. Tryby proxy i bezserwerowe System nie korzystają z tej preferencji.\n\n- **Mixed**: TCP korzysta ze stosu systemowego, natomiast gVisor obsługuje UDP. Jest to domyślne ustawienie mihomo w systemie Linux. W systemie Windows Xray i mihomo domyślnie używają MIPS.\n- **System**: używa stosu systemowego. Wypróbuj inną opcję, jeśli aplikacje sieciowe napotykają problemy.\n- **gVisor**: obsługuje ruch w przestrzeni użytkownika.\n- **MIPS**: własny stos IP mihomo, dostępny w dołączonej wersji 1.19.32.\n\nW Linux Xray domyślnie używa wbudowanego gVisor. System, Mixed i MIPS w Linux używają mihomo jako silnika TUN, przekazując TCP i UDP do Xray przez uwierzytelnione lokalne łącze SOCKS. Xray zachowuje protokół, profil dostawcy i routing. Te trzy opcje wymagają zainstalowanego mihomo. W przypadku Windows Xray używa mihomo 1.19.32 lub nowszego dla wszystkich czterech stosów TUN. Protokoły i routing pozostają w Xray. Reguły aplikacji w tym połączeniu obsługują tylko połączenia bezpośrednie i blokowanie; w Linux wymagają wbudowanego gVisor Xray.\n\nMost uruchamia drugi proces. W trzech pomiarach bezczynności Linux zużywał on około 32–36 MiB więcej pamięci fizycznej niż natywny Xray TUN. Nie mierzy to obciążenia pobierania: koszty procesora i pamięci zależą od połączeń. sing-box nie ma selektora stosu. Brak stosu gwarantuje lepszą wydajność w każdej sieci.\n\n## Stosowanie ustawień\n\nWybranie serwera automatycznie nawiązuje połączenie ponownie. Twoje zmiany trybu, silnika, DNS lub reguł są stosowane raz po krótkiej przerwie z automatycznym ponownym połączeniem; aktualizacje w tle nie łączą VPN ponownie. Ponowne uruchomienie silnika może przerwać pobieranie i rozmowy.\n\nInternet tylko przez VPN blokuje bezpośredni ruch w przypadku opadnięcia tunelu. Ma to wpływ na całą maszynę. Wyraźne rozłączenie usuwa reguły Sora. Jeśli czyszczenie nie zakończy się, spróbuj ponownie rozłączyć się i otwórz dziennik.\n\n## Dokumentacja projektu\n\n- [sing-box-lx: konfiguracja i wsparcie](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Dokumentacja sing-box](https://sing-box.sagernet.org/)\n- [Dokumentacja Xray](https://xtls.github.io/)\n- [Dokumentacja mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: działanie i ograniczenia](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC przesyła TCP przez rozmowę wideo w Jitsi, Yandex Telemost lub WB Stream. Zaimportuj link olcrtc:// lub kod QR. Działa z sing-box, Xray i mihomo w trybach proxy i TUN; UDP nie jest obsługiwany. Obie strony wymagają zgodnych wersji OLC2. Projekt źródłowy został zarchiwizowany.\n';

  @override
  String get probeServers => 'Świst';

  @override
  String get extensions => 'Rozszerzenia';

  @override
  String extRatingLabel(String rating) {
    return 'Ocena $rating z 5';
  }

  @override
  String extByAuthor(String author) {
    return 'autor: $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Instalacje: $count';
  }

  @override
  String get extInstallOne => '1 instalacja';

  @override
  String get extSideloadWarning => 'Klucz z własnym podpisem';

  @override
  String get extPermissionsWidened => 'Aktualizacja prosi o nowe uprawnienia:';

  @override
  String get extInstall => 'Zainstaluj';

  @override
  String get extUpdate => 'Aktualizuj';

  @override
  String get extCancel => 'Anuluj';

  @override
  String get extConfirm => 'Potwierdź';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'Zainstalowane rozszerzenia';

  @override
  String get extSearchHint => 'Szukaj rozszerzeń';

  @override
  String get extCatAll => 'Wszystko';

  @override
  String get extCatTools => 'Narzędzia';

  @override
  String get extCatThemes => 'Motywy';

  @override
  String get extCatAutomation => 'Automatyzacja';

  @override
  String get extCatStats => 'Statystyki';

  @override
  String get extCatNetwork => 'Sieć';

  @override
  String get extSortBy => 'Sortuj według';

  @override
  String get extSortPopular => 'Najpopularniejszy';

  @override
  String get extSortRating => 'Najwyżej oceniane';

  @override
  String get extSortName => 'Imię';

  @override
  String get extCatalogError => 'Nie można załadować katalogu';

  @override
  String get extRetry => 'Spróbuj ponownie';

  @override
  String get extEmptySearch => 'Nic nie znaleziono';

  @override
  String get extEmptyInstalled => 'Nie zainstalowano jeszcze żadnych rozszerzeń';

  @override
  String get extInstallFromFile => 'Zainstaluj z pliku';

  @override
  String get extInstallFromUrl => 'Zainstaluj z URL';

  @override
  String get extDownload => 'Pobierz';

  @override
  String get extDownloading => 'Pobieranie…';

  @override
  String get extVerifying => 'Sprawdzam…';

  @override
  String get extInstalling => 'Instalowanie…';

  @override
  String get extErrSignature => 'Sprawdzanie podpisu nie powiodło się';

  @override
  String get extErrManifest => 'Manifest rozszerzenia jest nieprawidłowy.';

  @override
  String get extErrNetwork => 'Błąd sieci';

  @override
  String get extErrHash => 'Pobrany plik nie jest zgodny z katalogiem';

  @override
  String extErrMinApp(String version) {
    return 'To rozszerzenie wymaga aplikacji w wersji $version lub nowszej.';
  }

  @override
  String get extErrHttpsOnly => 'Dozwolone są tylko linki https://';

  @override
  String get extErrGeneric => 'Coś poszło nie tak';

  @override
  String get extErrAuthorKeyChanged =>
      'Ta aktualizacja jest podpisana innym kluczem autora niż wersja zainstalowana, więc została zablokowana';

  @override
  String get extDisabled => 'Wyłączone';

  @override
  String extToggleEnabled(String name) {
    return 'Włącz $name';
  }

  @override
  String get extSearchInstalled => 'Szukaj w zainstalowanych rozszerzeniach';

  @override
  String get extUpdateAll => 'Zaktualizuj wszystko';

  @override
  String extUpdatesAvailable(int count) {
    return '$count dostępne aktualizacje';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count zaktualizowano';
  }

  @override
  String get extRiskNormal => 'Normalny';

  @override
  String get extRiskSensitive => 'Wrażliwe';

  @override
  String get extRiskDangerous => 'Wysokie ryzyko';

  @override
  String get extPermissionsRemoved => 'Nie jest już wymagane:';

  @override
  String get extUpdateFailedKept => 'Poprzednia wersja jest nadal zainstalowana.';

  @override
  String get extConflictsTitle => 'Konflikty rozszerzeń';

  @override
  String get extConflictTheme => 'Motyw aplikacji';

  @override
  String get extConflictNetHooks => 'Haki sieciowe';

  @override
  String extConflictWinner(String name) {
    return '$name wygrywa';
  }

  @override
  String extConflictsCount(int count) {
    return 'Konflikty rozszerzeń: $count';
  }

  @override
  String get extConflictsResolve => 'Rozwiązuj konflikty';

  @override
  String extVersionLabel(String version) {
    return 'Wersja $version';
  }

  @override
  String get extPermissionsTitle => 'Uprawnienia';

  @override
  String get extNoPermissions => 'Brak specjalnych uprawnień.';

  @override
  String get extSettings => 'Ustawienia';

  @override
  String get extSaveSettings => 'Zapisz ustawienia';

  @override
  String extUpdateTo(String version) {
    return 'Aktualizacja do $version';
  }

  @override
  String get extEnabled => 'Włączone';

  @override
  String extRollbackTo(String version) {
    return 'Przywróć do $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Przywrócić wersję $version?';
  }

  @override
  String get extUninstall => 'Odinstaluj';

  @override
  String extUninstallConfirm(String name) {
    return 'Usunąć „$name” i jego ustawienia?';
  }

  @override
  String get extPanelUnavailable => 'Panel rozszerzenia jest niedostępny.';

  @override
  String get extPermConnectionsRead => 'Zobacz listę aktywnych połączeń';

  @override
  String get extPermServersRead => 'Zobacz listę swoich serwerów';

  @override
  String get extPermSettingsRead => 'Przeczytaj ustawienia aplikacji';

  @override
  String get extPermSettingsWrite => 'Zmień ustawienia aplikacji';

  @override
  String get extPermNotifications => 'Pokaż powiadomienia';

  @override
  String get extPermTray => 'Dodaj elementy do menu zasobnika';

  @override
  String get extPermUiPanel => 'Pokaż panele w aplikacji';

  @override
  String get extPermThemeApply => 'Zastosuj motywy';

  @override
  String get extPermRoutingRules => 'Dodaj reguły routingu';

  @override
  String get extPermNetHooks => 'Integracja ze ścieżką sieciową';

  @override
  String get extPermNetFetch => 'Żądanie URL z listy dozwolonych';

  @override
  String get extPermBackground => 'Uruchom zadania w tle';

  @override
  String get extPermNotYetActive => 'Wyłączone';

  @override
  String get extCapBackground => 'Działa w tle';

  @override
  String get extCapNetHook => 'Obchodzenie blokad i haki sieciowe';

  @override
  String get extCapPanel => 'Panele interfejsu';

  @override
  String get extCapRouting => 'Reguły routingu';

  @override
  String get extCapTheme => 'Motywy';

  @override
  String get extCapWidget => 'Widżety';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Dziennik zmian';

  @override
  String get extImageFailed => 'Nie można załadować obrazu';

  @override
  String get extScreenshots => 'Zrzuty ekranu';

  @override
  String get extSortRelevance => 'Trafność';

  @override
  String get extBgTitle => 'Zadanie w tle';

  @override
  String get extBgEnabled => 'Uruchom w tle';

  @override
  String get extBgInterval => 'Uruchamiaj co';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuty',
      many: '$count minut',
      few: '$count minuty',
      one: '$count minuta',
    );
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godziny',
      many: '$count godzin',
      few: '$count godziny',
      one: '$count godzina',
    );
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Dostęp do sieci';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Sieć: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Do $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostyka HTTP';

  @override
  String get diagnosticNoData => 'Nie ma jeszcze zarejestrowanych żądań';

  @override
  String get qrShareTitle => 'Udostępnij kod QR';

  @override
  String get qrScanTitle => 'Zeskanuj kod QR';

  @override
  String get qrCopyLink => 'Skopiuj link';

  @override
  String get qrFromClipboard => 'Wklej ze schowka';

  @override
  String get qrNoCode => 'Na tym obrazie nie znaleziono kodu QR.';

  @override
  String get qrInvalid => 'Ten kod QR nie zawiera prawidłowego łącza.';

  @override
  String get qrScan => 'Skanuj QR';

  @override
  String get qrFromImage => 'Otwórz obraz';

  @override
  String get connGroupByProcess => 'Grupuj według procesu';

  @override
  String get connListView => 'Lista';

  @override
  String get connCopyHost => 'Skopiuj hosta';

  @override
  String get connAddRule => 'Dodaj regułę';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count połączenia',
      many: '$count połączeń',
      few: '$count połączenia',
      one: '$count połączenie',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Ustawienie wstępne';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Własne';

  @override
  String get dnsCheck => 'Sprawdź, czy nie ma wycieków danych';

  @override
  String get dnsChecking => 'Sprawdzam...';

  @override
  String get dnsNoLeak => 'Nie stwierdzono wycieków';

  @override
  String get dnsLeakFound => 'Wykryto wyciek';

  @override
  String get dnsLastCheck => 'Ostatnia kontrola';

  @override
  String get dnsNeverChecked => 'Jeszcze nie testowano';

  @override
  String get dnsLeakCheckTunnelDns => 'Resolwery DNS tunelu';

  @override
  String get dnsLeakCheckSystemResolvers => 'Systemowe resolwery';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Ochrona DNS przez blokadę sieci';

  @override
  String get dnsLeakCheckEncryptedDns => 'Szyfrowany DNS systemu';

  @override
  String get dnsLeakCheckDnsSpoof => 'Sfałszowane odpowiedzi DNS';

  @override
  String get dnsExpected => 'Oczekiwano';

  @override
  String get dnsActual => 'Zaobserwowano';

  @override
  String get measureSpeed => 'Zmierz prędkość';

  @override
  String get benchmarkStale => 'nieaktualny';

  @override
  String get autoSelectMode => 'Automatycznie wybierz serwer';

  @override
  String get autoSelectPing => 'Najszybszy ping';

  @override
  String get autoSelectSpeed => 'Największa prędkość';

  @override
  String get autoSelectSmart => 'Mądry wybór';

  @override
  String get coreWatchUnstable => 'Połączenie z rdzeniem jest niestabilne';

  @override
  String get watchReconnect => 'Połącz ponownie';

  @override
  String get crashRestoreTitle => 'Ostatnia sesja została przerwana';

  @override
  String get restoreOnCrash => 'Przywróć sesję po awarii';

  @override
  String get crashRestore => 'Przywróć';

  @override
  String get crashDismiss => 'Nie teraz';

  @override
  String get overrideTitle => 'Moje zmiany';

  @override
  String get overrideEdit => 'Edytuj serwery';

  @override
  String get overrideHide => 'Ukryj';

  @override
  String get overrideUnhide => 'Pokaż';

  @override
  String get overrideClear => 'Zresetuj zmiany';

  @override
  String get overrideEmpty => 'Nie ma jeszcze żadnych zmian';

  @override
  String get overrideCustomRules => 'Własne zasady';

  @override
  String get errBenchmarkUnsupported => 'Pomiar prędkości wymaga nowszego rdzenia';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Pomiar $done z $total…';
  }

  @override
  String get profiles => 'Profile sieciowe';

  @override
  String get profilesEmpty => 'Nie ma jeszcze profili';

  @override
  String get profileAdd => 'Dodaj profil';

  @override
  String get profileName => 'Nazwa profilu';

  @override
  String get profileSsids => 'Wi-Fi sieci (SSID)';

  @override
  String get profileGateways => 'Bramy sieciowe';

  @override
  String get profileAsns => 'AS numery';

  @override
  String get profileAutoApply => 'Zastosuj automatycznie';

  @override
  String get profileSnapshot => 'Zapamiętaj bieżące ustawienia';

  @override
  String get profileSnapshotDone => 'Bieżące ustawienia zapisane w profilu';

  @override
  String get profileDelete => 'Usuń profil';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Usunąć profil „$name”?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Zastosować profil „$name”?';
  }

  @override
  String get profileApply => 'Zastosuj';

  @override
  String profileApplied(Object name) {
    return 'Zastosowano profil „$name”.';
  }

  @override
  String get profileUndo => 'Anuluj';

  @override
  String get profileActive => 'Aktywny';

  @override
  String networkNow(Object info) {
    return 'Teraz: $info';
  }

  @override
  String get networkUnknown => 'Informacje o sieci są niedostępne';

  @override
  String get profileNoTriggers => 'Brak warunków profilu';

  @override
  String get chains => 'Łańcuchy proxy';

  @override
  String get chainsEmpty => 'Nie ma jeszcze łańcuchów';

  @override
  String get chainAdd => 'Nowy łańcuch';

  @override
  String get chainName => 'Nazwa łańcucha';

  @override
  String get chainTooFew => 'Łańcuch wymaga co najmniej dwóch serwerów';

  @override
  String get chainTooMany => 'Łańcuch może zawierać najwyżej trzy serwery';

  @override
  String get chainEstimate => 'Szacowane opóźnienie';

  @override
  String get chainSave => 'Zapisz łańcuch';

  @override
  String get chainDelete => 'Usuń łańcuch';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Usunąć łańcuch „$name”?';
  }

  @override
  String get chainUnsupported => 'Wybrany silnik nie obsługuje łańcuchów';

  @override
  String get chainHopMissing => 'Jeden z serwerów łańcucha nie jest już dostępny';

  @override
  String chainHop(Object n) {
    return 'Skok $n';
  }

  @override
  String get chainEntry => 'Wejście';

  @override
  String get chainExit => 'Wyjście';

  @override
  String get sync => 'Synchronizacja urządzenia';

  @override
  String get syncDevices => 'Moje urządzenia';

  @override
  String get syncEmpty => 'Brak sparowanych urządzeń';

  @override
  String get syncPair => 'Sparuj urządzenie';

  @override
  String get syncShowCode => 'Pokaż mój kod';

  @override
  String get syncScanCode => 'Zeskanuj kod';

  @override
  String get syncRevoke => 'Wypłata';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Unieważnić „$name”?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Ostatnia synchronizacja: $time';
  }

  @override
  String get syncNever => 'Nigdy';

  @override
  String get syncPaired => 'Urządzenie sparowane';

  @override
  String get syncPairingTitle => 'Sparuj z tym urządzeniem';

  @override
  String get syncWaiting => 'Oczekiwanie na drugie urządzenie…';

  @override
  String get zapretWithVpn => 'Pomiń filtrowanie DPI dla bezpośredniego ruchu sieciowego';

  @override
  String get chainDuplicate => 'Serwer występuje w łańcuchu więcej niż raz';

  @override
  String get edit => 'Edytuj';

  @override
  String get remove => 'Usuń';

  @override
  String get autoSwitchOnDegrade => 'Automatyczne włączenie degradacji';

  @override
  String get tunStackMixed => 'Mieszane';

  @override
  String get tunStackSystem => 'Systemu';

  @override
  String get customServerAdd => 'Dodaj serwer niestandardowy';

  @override
  String get customServers => 'Moje serwery';

  @override
  String get customServerName => 'Imię';

  @override
  String get customServerNameRequired => 'Brak nazwy';

  @override
  String get customServerAddress => 'Adres';

  @override
  String get customServerAddressRequired => 'Brak adresu';

  @override
  String get customServerAddressInvalid => 'Nieprawidłowy adres';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Nieprawidłowy port';

  @override
  String get customServerProtocol => 'Protokół';

  @override
  String get customServerCredentials => 'Dane logowania';

  @override
  String get customServerShowSecret => 'Pokaż sekret';

  @override
  String get customServerHideSecret => 'Ukryj sekret';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Usunąć serwer „$name”?';
  }

  @override
  String get leakTestTitle => 'Test pod kątem wycieków danych';

  @override
  String get leakTestRun => 'Sprawdź';

  @override
  String get leakTestCancel => 'Anuluj';

  @override
  String leakTestProgress(int count) {
    return 'Ukończone testy: $count';
  }

  @override
  String get leakTestAllClear => 'Nie stwierdzono wycieków';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wykryto $count wycieku',
      many: 'Wykryto $count wycieków',
      few: 'Wykryto $count wycieki',
      one: 'Wykryto $count wyciek',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Poprawka';

  @override
  String get leakTestCheckDirectDns => 'Bezpośrednio DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Systemowe resolwery';

  @override
  String get leakTestCheckTunnelConnectivity => 'Łączność tunelowa';

  @override
  String get leakTestCheckTunnelDns => 'DNS przez tunel';

  @override
  String get noticeDegraded =>
      'Serwer stał się powolny. Sora przełączył się na najlepszy serwer znaleziony podczas pomiaru.';

  @override
  String get obfs => 'Maskowanie ruchu';

  @override
  String get syncCodeExpired => 'Kod wygasł';

  @override
  String get syncDaemonFailed => 'Nie można uruchomić usługi synchronizacji';

  @override
  String get syncDaemonMissing => 'Nie znaleziono komponentu sora-sync';

  @override
  String get syncDaemonStarting => 'Uruchamiam usługę synchronizacji…';

  @override
  String get syncErrAuth => 'Usługa synchronizacji odrzuciła token dostępu';

  @override
  String get syncErrNotFound => 'Urządzenie nie jest już sparowane';

  @override
  String get syncErrPairingActive => 'Sesja parowania jest już otwarta';

  @override
  String get syncErrUnreachable => 'Drugie urządzenie nie odpowiedziało';

  @override
  String get syncError => 'Błąd synchronizacji';

  @override
  String syncExpiresIn(String duration) {
    return 'Kod wygaśnie za $duration';
  }

  @override
  String get syncJoining => 'Parowanie z urządzeniem…';

  @override
  String get syncNewCode => 'Nowy kod';

  @override
  String syncPairedWith(String name) {
    return 'W połączeniu z $name';
  }

  @override
  String get syncRetry => 'Powtórz';

  @override
  String get syncStopShowing => 'Ukryj kod';

  @override
  String get syncSyncNow => 'Synchronizuj teraz';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Odebrane $pulled, wysłane $pushed';
  }

  @override
  String get syncResultTitle => 'Wynik synchronizacji';

  @override
  String get syncPulled => 'Otrzymano';

  @override
  String get syncPushed => 'Wysłano';

  @override
  String get syncNoChanges => 'Nie wykryto żadnych zmian';

  @override
  String get syncDocKindSubscriptions => 'Prenumeraty';

  @override
  String get syncDocKindSettings => 'Ustawienia aplikacji';

  @override
  String get syncDocKindOverrides => 'Modyfikacje prenumerat';

  @override
  String get syncDocKindProfiles => 'Profile sieciowe';

  @override
  String get syncDocKindChains => 'Łańcuchy proxy';

  @override
  String syncFrom(String name) {
    return 'z $name';
  }

  @override
  String get syncThisDevice => 'To urządzenie';

  @override
  String get syncUnavailableAndroid => 'Synchronizacja niedostępna w Androidzie';

  @override
  String get diagnosticPackets => 'Przechwytywanie pakietów';

  @override
  String get diagnosticEvents => 'Zdarzenia Windowsa';

  @override
  String get diagnosticCapture => 'Przechwytuj przez 10 sekund';

  @override
  String get diagnosticRequiresTun => 'Przechwytywanie pakietów wymaga aktywnego połączenia Sora TUN.';

  @override
  String get diagnosticUnavailable => 'Ta diagnostyka jest niedostępna na tej platformie.';

  @override
  String get extErrRevoked => 'Zespół Sora wycofał tę wersję rozszerzenia, ponieważ jest niebezpieczna lub uszkodzona.';

  @override
  String get extErrRevocationsExpired => 'Instalacja jest zablokowana do czasu odświeżenia listy unieważnień.';

  @override
  String extRevokedDisabled(String names) {
    return 'Wyłączono wycofane rozszerzenia: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Klucz prywatny';

  @override
  String get customServerWgAddresses => 'Adresy interfejsu';

  @override
  String get customServerWgPeerKey => 'Klucz publiczny serwera';

  @override
  String get customServerWgPresharedKey => 'Klucz współdzielony';

  @override
  String get customServerWgAllowedIps => 'Dozwolone IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, sekundy';

  @override
  String get customServerWgKeyInvalid => 'Nieprawidłowy klucz WireGuard';

  @override
  String get customServerWgCidrInvalid => 'Nieprawidłowy prefiks CIDR';

  @override
  String get customServerWgKeepaliveInvalid => 'Nieprawidłowy interwał keepalive';

  @override
  String get strictKillSwitch => 'Ścisła blokada sieci';

  @override
  String get strictKillSwitchWarning => 'Blokować ruch poza VPN po zamknięciu aplikacji?';

  @override
  String get extWorkerFailed => 'Zadanie rozszerzenia w tle nie powiodło się';

  @override
  String get extAssetRejected => 'Plik rozszerzenia zawiera nieczytelne kolory lub nieprawidłowe reguły';

  @override
  String get extVerifiedSora => 'Zweryfikowano przez Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Otwórz';

  @override
  String get customServerOwn => 'Własny serwer';

  @override
  String get customServerPaste => 'Wklej link';

  @override
  String get customServerUser => 'Użytkownik';

  @override
  String get customServerPassword => 'Hasło';

  @override
  String get customServerSecretRequired => 'Brak wartości';

  @override
  String get customServerLinkInvalid => 'Nieprawidłowy link serwera';

  @override
  String get errInternal => 'Wewnętrzny błąd Sora';

  @override
  String get errTls => 'Odrzucono certyfikat serwera';

  @override
  String get errFileAccess => 'Brak dostępu do pliku';

  @override
  String get errDataLimit => 'Za dużo danych';

  @override
  String get errCredentials => 'Brakuje zapisanych danych logowania';

  @override
  String subscriptionStale(String time) {
    return 'Ostatnia aktualizacja: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Jeszcze nie zaktualizowano';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Serwer zwrócił kod HTTP $status',
      zero: 'Serwer odrzucił żądanie',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Ustawienia serwera są niepełne lub nieobsługiwane';

  @override
  String get errServerIds => 'Dwa serwery mają ten sam identyfikator';

  @override
  String get errRoutingGroup => 'Trasa wskazuje brakujące serwery lub uszkodzoną grupę';

  @override
  String get errConnections => 'Lista połączeń jest niedostępna';

  @override
  String get errLogs => 'Ta usługa nie prowadzi dziennika';

  @override
  String get errDiagnostics => 'Nie udało się zebrać diagnostyki';

  @override
  String get errMissingItem => 'Żądany element już nie istnieje';

  @override
  String get errInvalidRequest => 'Żądanie zawiera nieprawidłowe wartości';

  @override
  String get errProxyLogin => 'Serwer proxy systemu nie obsługuje tego logowania';

  @override
  String get errLogFilter => 'Nieprawidłowy filtr dziennika';

  @override
  String get errSubRedirect => 'Serwer przekierował na niebezpieczny adres';

  @override
  String get errProxySetup => 'Nie udało się ustawić serwera proxy systemu';

  @override
  String get notificationsToday => 'Dzisiaj';

  @override
  String get notificationsYesterday => 'Wczoraj';

  @override
  String get notificationsMarkRead => 'Oznacz wszystko jako przeczytane';

  @override
  String get notificationsUnread => 'Nieprzeczytane';

  @override
  String get desktopNotifications => 'Powiadomienia na pulpicie';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Interwał aktualizacji subskrypcji jest nieprawidłowy';

  @override
  String get errRule => 'Reguła routingu jest nieprawidłowa';

  @override
  String get errDns => 'Ustawienia DNS są nieprawidłowe';

  @override
  String get errEndpoint => 'Adres sprawdzanego serwera jest nieprawidłowy';

  @override
  String get errCancelled => 'Żądanie zostało anulowane';

  @override
  String get customServerOptions => 'Ustawienia połączenia';

  @override
  String get customServerTransport => 'Transport';

  @override
  String get customServerSecurity => 'Zabezpieczenia';

  @override
  String get customServerCipher => 'Szyfr';

  @override
  String get customServerWgInterface => 'Interfejs';

  @override
  String get customServerWgPeer => 'Peer';

  @override
  String extAvailableOn(String platforms) {
    return 'Dostępne na: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Zmienić ruch TCP wszystkich aplikacji?';

  @override
  String get winwsRequirements => 'Ten tryb VPN jest niedostępny';
}
