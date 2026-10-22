// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class SKk extends S {
  SKk([String locale = 'kk']) : super(locale);

  @override
  String get stateOff => 'Қосылмаған';

  @override
  String get stateConnecting => 'Қосылуда';

  @override
  String get stateConnected => 'Қосылды';

  @override
  String get stateReconnecting => 'Қайта қосылуда';

  @override
  String get stateDisconnecting => 'Ажыратылуда';

  @override
  String get coreMissing => 'Sora қызметі жауап бермейді';

  @override
  String get serverAuto => 'Ең жылдам';

  @override
  String get serverBypass => 'Сервер жоқ';

  @override
  String get addSubscription => 'Жазылым қосу';

  @override
  String get servers => 'Серверлер';

  @override
  String get settings => 'Параметрлер';

  @override
  String get subscription => 'Жазылым';

  @override
  String get subscriptionLink => 'Жазылым сілтемесі';

  @override
  String get add => 'қосу';

  @override
  String get refresh => 'Жаңарту';

  @override
  String get rename => 'Атын өзгерту';

  @override
  String get delete => 'Жою';

  @override
  String get cancel => 'Болдырмау';

  @override
  String get save => 'Сақтау';

  @override
  String get name => 'Аты';

  @override
  String deleteSubscription(String name) {
    return '“$name” жою керек пе?';
  }

  @override
  String get routes => 'Маршруттар';

  @override
  String get presetGlobal => 'Барлығы VPN арқылы';

  @override
  String get presetRu => 'Ресей тікелей';

  @override
  String get presetIr => 'Иран тікелей';

  @override
  String get presetCn => 'Қытай тікелей';

  @override
  String get blockAds => 'Жарнамаларды блоктау';

  @override
  String get killSwitch => 'Интернет тек VPN арқылы';

  @override
  String get engine => 'Қозғалтқыш';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'Анимациялар';

  @override
  String get logs => 'Журнал';

  @override
  String get about => 'туралы';

  @override
  String get logsAll => 'Барлығы';

  @override
  String get logsImportant => 'Маңызды';

  @override
  String get logsErrors => 'Қателер';

  @override
  String get search => 'Іздеу';

  @override
  String get export => 'Файлға сақтаңыз';

  @override
  String get clear => 'Таза';

  @override
  String get logsEmpty => 'Мұнда ештеңе жоқ';

  @override
  String get connEmpty => 'Қосылымдар жоқ';

  @override
  String appVersion(String version) {
    return '$version нұсқасы';
  }

  @override
  String get notInstalled => 'Орнатылмаған';

  @override
  String get sourceCode => 'Бастапқы код';

  @override
  String get license => 'Лицензия';

  @override
  String usage(String used, String total) {
    return '$used $total';
  }

  @override
  String until(String date) {
    return '$date дейін';
  }

  @override
  String get expired => 'Мерзімі бітті';

  @override
  String milliseconds(int n) {
    return '$n мс';
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
    return '$n КБ';
  }

  @override
  String bytesMB(String n) {
    return '$n МБ';
  }

  @override
  String bytesGB(String n) {
    return '$n ГБ';
  }

  @override
  String bytesTB(String n) {
    return '$n ТБ';
  }

  @override
  String get errGeneric => 'Бірдеңе дұрыс болмады';

  @override
  String get errCore => 'Sora қызметі жауап бермейді. Сәл күтіп, қайталап көріңіз.';

  @override
  String get errAuth => 'Sora қызметіне кіруге рұқсат жоқ. Қолданбаны қайта іске қосып, қайталап көріңіз.';

  @override
  String get errVersion => 'Sora қолданбасы мен қызметінің нұсқалары әртүрлі. Sora-ны жаңартыңыз.';

  @override
  String get errBusy => 'Алдыңғы пәрмен әлі орындалып жатыр. Аяқталғанша күтіңіз.';

  @override
  String get errEngineMissing => 'Бұл серверге қажетті ядро табылмады. Sora жаңартуларын тексеріңіз.';

  @override
  String get errEngineStart => 'Ядро іске қосылмады. Себебін қосылым журналынан қараңыз.';

  @override
  String get errEngineStopped => 'Ядро тоқтады. Қайта қосылып көріңіз.';

  @override
  String get errTunnel => 'Бұл VPN режимі қолжетімсіз. Басқа режимді таңдаңыз немесе қызмет рұқсаттарын тексеріңіз.';

  @override
  String get errNetwork => 'Серверге қол жеткізу мүмкін емес';

  @override
  String get errTimeout => 'Сервер уақытында жауап бермеді. Бір минуттан кейін қайталап көріңіз.';

  @override
  String get errFirewall =>
      'VPN-нен тыс интернетке кіруді бұғаттау мүмкін болмады. Себебін қосылым журналынан қараңыз.';

  @override
  String get errSubFetch =>
      'Жазылымды жүктеу мүмкін болмады. Интернетті тексеріп, бір минуттан кейін қайталап көріңіз.';

  @override
  String get errSubFormat => 'Жазылым пішімі танылмады. Провайдерден үйлесімді жазылым сілтемесін сұраңыз.';

  @override
  String get errSubEmpty => 'Жазылымда серверлер жоқ. Жазылым провайдеріне хабарласыңыз.';

  @override
  String get errSubDuplicate => 'Бұл жазылым қосылған. Соңғы серверлерді алу үшін оны жаңартыңыз.';

  @override
  String get errSubLimit => 'Жазылым санының шегіне жеттіңіз. Жаңасын қоспас бұрын пайдаланылмайтын жазылымды жойыңыз.';

  @override
  String get errSubScheme => 'Жазылым сілтемесі https:// деп басталуы керек. Провайдерден қауіпсіз сілтеме сұраңыз.';

  @override
  String get errSecretStore =>
      'Sora қоймасы зақымдалған немесе қолжетімсіз. Кіру рұқсаттарын және журналдағы мәліметтерді тексеріңіз.';

  @override
  String get errNoServers => 'Қосылуға арналған серверлер жоқ. Жазылым немесе өз серверіңізді қосыңыз.';

  @override
  String get connections => 'Қосылымдар';

  @override
  String get close => 'Жабу';

  @override
  String get chainDirect => 'Тікелей';

  @override
  String get chainBlocked => 'Блокталған';

  @override
  String get theme => 'Тақырып';

  @override
  String get themeSystem => 'Жүйедегідей';

  @override
  String get themeLight => 'Жарық';

  @override
  String get themeDark => 'Қараңғы';

  @override
  String get language => 'Тіл';

  @override
  String get languageSystem => 'Жүйедегідей';

  @override
  String get sectionConnection => 'Байланыс';

  @override
  String get sectionNoServer => 'Сервер жоқ';

  @override
  String get sectionPing => 'Пинг';

  @override
  String get sectionLog => 'Диагностика';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Авто';

  @override
  String get dnsHint => 'Мекенжайлар, үтірмен бөлінген';

  @override
  String get fragment => 'TLS фрагментациясы';

  @override
  String get fragmentPackets => 'Нені бөлу керек';

  @override
  String get fragmentLength => 'Бөлшек өлшемі';

  @override
  String get fragmentInterval => 'Бөлшектердің арасында үзіліс жасаңыз';

  @override
  String get byDefault => 'Әдепкі';

  @override
  String get rangeHint => 'Мысалы, 100-200';

  @override
  String get splitPos => 'Позицияларды бөлу';

  @override
  String get splitPosHint => 'Мысалы, 1, midsld';

  @override
  String get disorder => 'Бөлшектердің ретін өзгерту';

  @override
  String get tlsRecord => 'TLS жазбасын бөліңіз';

  @override
  String get tlsRecordNo => 'Жоқ';

  @override
  String get tlsRecordSni => 'Сайт атауында';

  @override
  String get tlsRecordFirst => 'Бірінші байттан кейін';

  @override
  String get hostCase => 'Хост регистрін өзгерту';

  @override
  String get probeMethod => 'Әдіс';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Қозғалтқыш арқылы';

  @override
  String get probeConnect => 'Тек қосылым';

  @override
  String get probeUrl => 'Сынақ мекенжайы';

  @override
  String get probeTimeout => 'Күте тұрыңыз';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Жазылымдар';

  @override
  String get subscriptionSettings => 'Параметрлер';

  @override
  String get userAgent => 'Пайдаланушы-агент';

  @override
  String get autoUpdate => 'Автоматты түрде жаңарту';

  @override
  String get updateInterval => 'Қаншалықты жиі';

  @override
  String get intervalProvider => 'Провайдер сұрағандай';

  @override
  String hours(int n) {
    return '$n сағ';
  }

  @override
  String get updateNow => 'Қазір жаңартыңыз';

  @override
  String get logLevel => 'Не жазу керек';

  @override
  String get levelDebug => 'Барлығы';

  @override
  String get levelInfo => 'Әдеттегі';

  @override
  String get levelWarning => 'Маңызды';

  @override
  String get levelError => 'Тек қателер';

  @override
  String get recordDestinations => 'Сайт мекенжайларын жазыңыз';

  @override
  String get reset => 'Параметрлерді қалпына келтіру';

  @override
  String get resetConfirm => 'Барлық параметрлерді қалпына келтіру керек пе?';

  @override
  String get resetAction => 'Қалпына келтіру';

  @override
  String get invalidValue => 'Бұл мән жұмыс істемейді';

  @override
  String get website => 'Жазылым беті';

  @override
  String get providerWebsite => 'Провайдердің веб-сайты';

  @override
  String get support => 'Қолдау';

  @override
  String controlPortQuestion(String engine) {
    return '$engine осы компьютердегі порт арқылы басқарылады. Басқа бағдарламалар VPN қосулы екенін айта алады.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine таңдаңыз';
  }

  @override
  String get rules => 'Арнаулы ережелер';

  @override
  String get ruleAdd => 'Жаңа ереже';

  @override
  String get ruleHint => 'Сайт, IP немесе бағдарлама';

  @override
  String get ruleDirect => 'Тікелей';

  @override
  String get ruleProxy => 'VPN арқылы';

  @override
  String get ruleBlock => 'Блоктау';

  @override
  String get failover => 'Сәтсіздікті қосу';

  @override
  String get connectOnStart => 'Бастапқыда қосылыңыз';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'жазылым $days күндері аяқталады',
      one: 'жазылым $days күні аяқталады',
      zero: 'жазылым бірнеше сағатта аяқталады',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left қалды';
  }

  @override
  String get ruleInvalid => 'Бұл сайтқа, IP мекенжайына немесе бағдарламаға ұқсамайды';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count серверлері, ең жылдам',
      one: '$count сервері, ең жылдам',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelProxy => 'System прокси';

  @override
  String get proxyAddress => 'Прокси мекенжайы';

  @override
  String get copied => 'Көшірілген';

  @override
  String get launchAtLogin => 'Жүйеден бастаңыз';

  @override
  String get launchAtLoginDetail => 'Жүйеге кіргенде Sora автоматты түрде іске қосылып, науада қалады.';

  @override
  String get closeToTray => 'Жабылған кезде науада ұстаңыз';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get trayOpen => 'Sora ашыңыз';

  @override
  String get trayConnect => 'Қосылу';

  @override
  String get trayDisconnect => 'Ажырату';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Sora шығыңыз';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora әлі науада';

  @override
  String get noticeInTrayBody => 'Оның белгішесінің мәзірінен шығыңыз';

  @override
  String get noticeLost => 'Байланыс жоғалды';

  @override
  String get noticeLostBody => 'Sora қайта қосылуда';

  @override
  String get noticeRestored => 'Қайта қосылды';

  @override
  String get noticeFailed => 'Қосылу мүмкін болмады';

  @override
  String get noticeBackup => 'Негізгі сервер жауап бермеді; резервтік көшірме трафикті тасымалдайды';

  @override
  String get noticeNext => 'Сервер жауап бермеді; келесісі қозғалысты жүзеге асырады';

  @override
  String get noticeMainBack => 'Негізгі сервер қайтадан жауап береді және трафикті тасымалдайды';

  @override
  String get noticeSubscription => 'Жазылым';

  @override
  String get importTitle => 'Осы жазылымды қосу керек пе?';

  @override
  String get importSealed =>
      'Бұл сілтеме Happ үшін шифрланған және оны тек Happ оқи алады. Провайдеріңізден қарапайым жазылым сілтемесін сұраңыз.';

  @override
  String get understood => 'Жарайды';

  @override
  String get noAnswer => 'жауап жоқ';

  @override
  String get home => 'Үй';

  @override
  String get navRules => 'Ережелер';

  @override
  String get navConnections => 'Қосылымдар';

  @override
  String get navLogs => 'Журналдар';

  @override
  String get navAbout => 'туралы';

  @override
  String get sidebarToggle => 'Бүйірлік тақтаны ауыстыру';

  @override
  String get more => 'Көбірек';

  @override
  String get less => 'Аздау';

  @override
  String get notificationsEmpty => 'Хабарландырулар жоқ';

  @override
  String get retryConnect => 'Қосылымды қайталап көріңіз';

  @override
  String get openLogs => 'Журналдарды ашыңыз';

  @override
  String get tourReplay => 'Нұсқаулықты қайта көрсетіңіз';

  @override
  String tourStep(int step) {
    return '$step/5 қадамы';
  }

  @override
  String get tourBack => 'Артқа';

  @override
  String get tourNext => 'Келесі';

  @override
  String get tourSkip => 'Өткізіп жіберу';

  @override
  String get tourFinish => 'Дайын';

  @override
  String get tourAdd => 'Провайдеріңіздің жазылым сілтемесін қосыңыз.';

  @override
  String get tourServer => 'Серверді таңдаңыз. «Ең жылдам» сіз үшін біреуін таңдайды.';

  @override
  String get tourConnect => 'Қосылу немесе ажырату үшін осы жерді басыңыз.';

  @override
  String get tourMode => 'Режимді таңдаңыз. VPN өшірілсе, коммутаторды өшіріңіз.';

  @override
  String get tourSettings => 'Параметрлерді ашыңыз. Сіз бұл нұсқаулықты сол жерде қайталай аласыз.';

  @override
  String get chooseProgram => 'Бағдарламаны таңдаңыз';

  @override
  String get installedApps => 'Орнатылған қолданбалар';

  @override
  String get runningProcesses => 'Орындалатын процестер';

  @override
  String get programsEmpty => 'Қолданбалар табылмады. Басқа атауды қолданып көріңіз.';

  @override
  String get selectExe => 'exe файлын таңдаңыз';

  @override
  String get speedtest => 'Жылдамдық';

  @override
  String get speedtestSearch => 'Қызметті табыңыз';

  @override
  String get speedtestEmpty => 'Сәйкестік жоқ. Іздеуді өзгертіңіз.';

  @override
  String get speedtestBackToList => 'Қызметтерге оралу';

  @override
  String get speedtestOpenBrowser => 'Браузерде ашыңыз';

  @override
  String get speedtestUnavailable => 'Енгізілген браузер іске қосылмады. Жүйе шолғышында қызметті ашыңыз.';

  @override
  String get speedtestPageFailed => 'Бет жүктелмеді. Оны қайта жүктеңіз немесе жүйе шолғышында қызметті ашыңыз.';

  @override
  String get speedtestExternalFailed => 'Жүйе браузері ашылмайды. Қайтадан байқап көріңіз.';

  @override
  String get modes => 'Режимдер';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Барлық трафик (TUN)';

  @override
  String get checkUpdates => 'Жаңартуларды тексеріңіз';

  @override
  String get updates => 'Қолданба жаңартулары';

  @override
  String updateAvailable(String version) {
    return '$version нұсқасы қол жетімді';
  }

  @override
  String get updateOpenAbout => 'Жаңартуды көру';

  @override
  String updateNotes(String version) {
    return '$version өзгертулері';
  }

  @override
  String get updateCheck => 'Жаңартуларды тексеріңіз';

  @override
  String get updateChecking => 'Тексерілуде...';

  @override
  String get updateNoNotes => 'Шығарылымда ескертулер жоқ.';

  @override
  String get updateDropWarning =>
      'Sora және оның негізгі жаңартылуы кезінде VPN қосылымы бірнеше секундқа үзіледі. Жалғастыру керек пе?';

  @override
  String get updateWaitConnection => 'VPN қосылымы мен ядросы дайын болғанша күтіңіз.';

  @override
  String get updateDownloading => 'Файлдар жүктелуде және тексерілуде...';

  @override
  String get updateInstalling => 'Жаңарту дайындалуда немесе әкімшінің аутентификациясын күтуде...';

  @override
  String get updateNetworkError => 'Жаңартуды жүктеп алу мүмкін болмады. Қайтадан байқап көріңіз.';

  @override
  String get updateReleaseError => 'Шығарылым деректері немесе қажетті файлдар жоқ немесе жарамсыз.';

  @override
  String get updateChecksumError => 'Жүктеп алу SHA256SUMS сәйкес емес. Ештеңе орнатылмады.';

  @override
  String get updateInstallError => 'Жаңарту аяқталмады. Аутентификация жойылған болуы мүмкін.';

  @override
  String get updateUnsupported =>
      'Бұл орындалатын файл қолдау көрсетілетін Sora бума жұбына тиесілі емес. Шығаруды орнату нұсқауларын пайдаланыңыз.';

  @override
  String get updateManual =>
      'Тексерілген екі буманы орнату үшін осы пәрменді терминалда іске қосыңыз, содан кейін Sora қайта ашыңыз. Файлдар жүктеп алу каталогында қалады. VPN байланысы үзіледі.';

  @override
  String get updateSignaturePending =>
      'Жаңарту файлдары шығарылыммен бірге жарияланған бақылау сомаларымен салыстырылады.';

  @override
  String get updateManualSigWarning =>
      'Төмендегі файлдар шығарылымның бақылау сомаларына сәйкес келеді. Оларды ресми шығарылымнан жүктесеңіз, пәрменді орындаңыз.';

  @override
  String get updateVersionRevoked => 'Әзірлеуші бұл нұсқаны қайтарып алды. Түзетілген шығарылымды күтіңіз.';

  @override
  String get updateRolloutPending => 'Жаңарақ нұсқасы бірте-бірте шығарылады және сізге автоматты түрде ұсынылады.';

  @override
  String updateRollbacking(String version) {
    return '$version нұсқасына оралу...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version жаңартуы денсаулық тексеруінен өтпеді, сондықтан Sora $fromVersion нұсқасына қайтарылды.';
  }

  @override
  String get updateRollbackError =>
      'Автоматты кері қайтару сәтсіз аяқталды. Жаңа нұсқа жұмыс істемесе, алдыңғы шығарылымды қолмен қайта орнатыңыз.';

  @override
  String get updateRollbackCacheError =>
      'Ағымдағы нұсқаның расталған кері қайтару көшірмесін дайындау мүмкін болмады, сондықтан жаңарту орнатылмады.';

  @override
  String get updateCopyCommand => 'Көшіру пәрмені';

  @override
  String get updateChecksDisabled => 'Параметрлерде автоматты тексерулер өшірілген.';

  @override
  String get updateInstalled => 'Жаңарту орнатылды. Sora қайта ашыңыз.';

  @override
  String get projectLinks => 'Жоба';

  @override
  String get githubReleases => 'Шығарылымдар мен жүктеулер';

  @override
  String get telegramChannel => 'Telegram арнасы';

  @override
  String get licenses => 'Лицензиялар';

  @override
  String get componentLicenses => 'Құрамдас лицензиялар';

  @override
  String get collapseServers => 'Серверлерді жию';

  @override
  String get expandServers => 'Серверлерді кеңейту';

  @override
  String get hideDescription => 'Сипаттаманы жасыру';

  @override
  String get showDescription => 'Сипаттаманы көрсету';

  @override
  String get pendingConnectionChanges => 'Бұл өзгертулерді қолдану үшін қайта қосылыңыз.';

  @override
  String get reconnectNow => 'Қолданыңыз және қайта қосыңыз';

  @override
  String get errEngineUnsupported =>
      'Таңдалған қозғалтқыш бұл профильді немесе параметрлерді қолдамайды. Автоматты немесе үйлесімді қозғалтқышты таңдаңыз.';

  @override
  String get errRestore =>
      'Байланысты тазалау аяқталмады. Ажыратуды қайталап көріңіз; мәліметтер алу үшін журналды қараңыз.';

  @override
  String get errSessionEnded => 'Бұл сеанс әлдеқашан аяқталды. Қосылым күйін жаңартыңыз.';

  @override
  String get retryDisconnect => 'Ажыратуды қайталап көріңіз';

  @override
  String get tunStack => 'TUN стек';

  @override
  String get modesInfo => 'Режимдер туралы';

  @override
  String get modesGuideTitle => 'Режимдер мен қозғалтқыштар';

  @override
  String get modesGuide =>
      'Серверге қандай қозғалтқыш қажет екенін білмесеңіз, Авто опциясын таңдаңыз. Sora қосылу алдында профиль мен параметрлерді тексереді. Қозғалтқыш жоспарыңыздың өткізу қабілеттілігін арттыра алмайды: өнімділік серверге, маршрутқа, протоколға және желіге байланысты.\n\n## Режимдер\n\n### Барлық трафик (TUN)\n\nSora виртуалды желі интерфейсін жасайды және ол арқылы TCP және UDP қоса, қолданба трафигін бағыттайды. Бұл режимді Telegram, ойындар және Discord дауысы үшін пайдаланыңыз. Ережелер нақты сайттарды немесе бағдарламаларды тікелей жібере алады немесе оларды блоктай алады. Желі қызметіне рұқсат және қажетті протоколды қолдайтын сервер қажет.\n\n### System прокси\n\nSora жергілікті HTTP/SOCKS проксиін конфигурациялайды. Жүйенің прокси параметрлерін құрметтейтін қолданбалар оны пайдаланады. Өз желілік стегі бар қолданбалар тікелей қосыла алады; UDP және дауыстық қоңырауларға әдетте TUN қажет. Бұл режим прокси қолдауы бар браузерлер мен қолданбаларға сәйкес келеді.\n\n### Сервер жоқ\n\nLinux жүйесінде Sora HTTP/TLS сұрауларын бөлу және пішінін өзгерту және кейбір DPI тексерулерін айналып өту үшін [zapret](https://github.com/bol-van/zapret) пайдаланады. IP мекенжайыңыз өзгеріссіз қалады және қосылымдар тікелей веб-сайтқа өтеді. Нәтижелер провайдеріңізге және блоктау әдісіне байланысты.\n\nАғымдағы біріктіру TCP арқылы HTTP және TLS үшін tpws пайдаланады. Ол IP блоктауын немесе UDP релесін айналып өтпейді және Telegram MTProto қосылымдарына кепілдік бере алмайды. Discord дауысы, Telegram қоңыраулары және осындай шектеулер үшін TUN бар VPN серверін пайдаланыңыз.\n\n## Қозғалтқыштар\n\n### Авто\n\nSora барлық қосылу жоспарын қолдайтын орнатылған қозғалтқышты таңдайды: сервер протоколдары, тасымалдаулар, топтар, фрагментация және режим. Сәйкес келмейтін қолмен таңдау ағымдағы қосылымды тоқтатудан бұрын қабылданбайды. Автоматты немесе басқа қозғалтқышты таңдап, параметрлерді қайта қолданыңыз.\n\n### sing-box\n\nЖаңа Sora пакеттеріне клиенттік XHTTP және VLESS Encryption қосатын [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) шанышқысы кіреді. Sora құрастыруды және оның мүмкіндіктерін таниды. XHTTP жоқ жоғары ағынды құрастыру бұл мүмкіндікті тек оның атынан ғана ала алмайды.\n\nVLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard протоколдары және Sora импорттай алатын AmneziaWG 1.x/2.x параметрлері қолдау табады. Толық Xray JSON профильдері үшін Xray қажет. Жаңа AWG 3.x өрістерін әзірше импорттау мүмкін емес. sing-box құпиясөзбен қорғалған жергілікті басқару портын пайдаланады; компьютердегі басқа қолданбалар оны анықтай алады.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption және TLS фрагментациясын қолдайды. Ол сонымен қатар Xray провайдерінің толық профильдерін олардың маршруттары мен топтарын сақтай отырып іске қосады. Мұндай профильдерді мінез-құлқын өзгертпестен автоматты түрде басқа қозғалтқышқа түрлендіру мүмкін емес.\n\nЖинақтағы Xray TLS сертификатын тексеруді өшіретін параметрді жойды (`allowInsecure`). Бұл параметрді қажет ететін қарапайым серверлер үшін sing-box немесе mihomo опциясын автоматты түрде таңдайды. Xray таңдау ағымдағы қосылымды тоқтату алдында сәйкессіздікті қолмен хабарлайды. Ескі толық JSON профильдері тексерілетін сертификат немесе сертификат PIN коды бар жаңартылған провайдер профилін қажет етеді.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) реттелген қалпына келтіру және жүктемені теңестіру топтарын, XHTTP және AmneziaWG қолдайды. Сақтық көшірме серверіне автоматты ауыстыру маңызды болғанда оны таңдаңыз. Sora TLS фрагментация параметрі бұл қозғалтқышта қолжетімсіз.\n\n## Sora ішіндегі үйлесімділік\n\n| Ерекшелігі | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN және TCP/UDP | Иә | Иә | Иә |\n| XHTTP | Иә | Иә | Иә |\n| VLESS Encryption | Иә | Иә | Иә |\n| Толық Xray профилі | Жоқ | Иә | Жоқ |\n| TUIC / AnyTLS | Екеуі де | Жоқ | TUIC |\n| mieru | Жоқ | Жоқ | Иә |\n| NaiveProxy | Иә | Жоқ | Жоқ |\n| TLS фрагментациясы | Иә | Иә | Жоқ |\n| AmneziaWG 1.x/2.x | Иә¹ | Жоқ | Иә |\n| Тапсырыс берілген резервтік топ | Жоқ | No² | Иә |\n\n¹ J1/J2/J3/Itime профильдері mihomo пайдаланады; бұл өрістерді ешқашан үнсіз тастауға болмайды. ² Толық Xray профильдерінің тобы үшін қолданба сақтық көшірме профилін таңдайды. Қолдау орнатылған құрылымға байланысты; туралы нұсқасын тексеріңіз.\n\n## TUN стек\n\nСтек виртуалды интерфейстің ішінде TCP және UDP өңдейді. Режимдер панелінде Xray және mihomo gVisor, System, Mixed және MIPS ұсынады. Әрбір қозғалтқыш өз таңдауын сақтайды. System прокси және серверсіз режимдері бұл теңшеуді пайдаланбайды.\n\n- **Mixed**: TCP жүйелік стекті пайдаланады, ал gVisor UDP өңдейді. Бұл Linux жүйесіндегі mihomo үшін әдепкі нұсқа. Windows жүйесінде Xray және mihomo әдепкі бойынша MIPS пайдаланады.\n- **System**: жүйелік стек пайдаланады. Желілік қолданбаларда ақаулықтар туындаса, басқа опцияны қолданып көріңіз.\n- **gVisor**: пайдаланушылар кеңістігіндегі трафикті өңдейді.\n- **MIPS**: mihomo жеке IP стегі, жинақталған 1.19.32 нұсқасында қолжетімді.\n\nLinux жүйесінде Xray әдепкі бойынша кірістірілген gVisor пайдаланады. Linux жүйесіндегі System, Mixed және MIPS TUN қозғалтқышы ретінде mihomo пайдаланады, TCP және UDP аутентификацияланған жергілікті SOCKS сілтемесі арқылы Xray файлына бағыттайды. Xray протоколды, провайдер профилін және маршруттауды сақтайды. Бұл үш опция орнатылған mihomo қажет. Windows жүйесінде Xray барлық төрт TUN стегі үшін mihomo 1.19.32 немесе жаңасын пайдаланады. Протоколдар мен маршруттау Xray жүйесінде қалады. Бұл тіркесімде қолданба ережелері тек тікелей қосылуды және бұғаттауды қолдайды; Linux жүйесінде бұл ережелер Xray кірістірілген gVisor стегін қажет етеді.\n\nКөпір екінші процесті жүргізеді. Linux құрылғысындағы үш бос өлшеу кезінде ол жергілікті Xray TUN-ға қарағанда 32–36 МБ артық физикалық жадты пайдаланды. Бұл жүктеу жүктемесін өлшемейді: процессор мен жад құны қосылымдарға байланысты. sing-box стек селекторы жоқ. Ешбір стек әрбір желіде жақсы өнімділікке кепілдік бермейді. Стекті таңдап, оны желіде сынап көру үшін Қолдану және қайта қосылу опциясын таңдаңыз.\n\n## Параметрлерді қолдану\n\nСерверді таңдау автоматты түрде қайта қосылады. Режим, қозғалтқыш, DNS және ереже параметрлері бірден сақталады; белсенді қосылым кезінде оларды пайдалану үшін Қолдану түймесін басып, қайта қосылыңыз. Қозғалтқышты қайта іске қосу жүктеп алулар мен қоңырауларды тоқтатуы мүмкін. Қайталанатын шертулер параллель қосылымдарды бастамайды; ажырату ауысуды аяқтайды және қосылымды босатады.\n\nТек VPN арқылы Интернет туннель құлаған кезде тікелей трафикті блоктайды. Бұл бүкіл машинаға әсер етеді. Айқын ажырату Sora ережелерін жояды. Тазалау аяқталмаса, қайта ажыратып көріңіз және журналды ашыңыз.\n\n## Жобалық құжаттама\n\n- [sing-box-lx: конфигурация және қолдау](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box құжаттамасы](https://sing-box.sagernet.org/)\n- [Xray құжаттамасы](https://xtls.github.io/)\n- [mihomo құжаттамасы](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: жұмыс және шектеулер](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP трафигін Jitsi, Яндекс Телемост немесе WB Stream бейнеқоңырауы арқылы өткізеді. olcrtc:// сілтемесін немесе QR кодын импорттаңыз. Прокси және TUN режимдерінде sing-box, Xray және mihomo арқылы жұмыс істейді; UDP қолдау көрсетілмейді. Екі жаққа да үйлесімді OLC2 жинақтары қажет. Бастапқы жоба мұрағатталған.\n';

  @override
  String get probeServers => 'Серверлерді тексеріңіз';

  @override
  String get extensions => 'Кеңейтімдер';

  @override
  String extRatingLabel(String rating) {
    return 'Бағалау $rating/5';
  }

  @override
  String extByAuthor(String author) {
    return 'авторы $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Орнатулар: $count';
  }

  @override
  String get extInstallOne => '1 орнату';

  @override
  String get extSideloadWarning => 'Автордың өзі қол қойған кілтіне сенсеңіз ғана орнатыңыз.';

  @override
  String get extPermissionsWidened => 'Жаңарту жаңа рұқсаттарды сұрайды:';

  @override
  String get extDangerousAck => 'Мен бұл рұқсаттардың маңызды екенін түсінемін';

  @override
  String get extInstall => 'Орнату';

  @override
  String get extUpdate => 'Жаңарту';

  @override
  String get extCancel => 'Болдырмау';

  @override
  String get extConfirm => 'Растау';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Орнатылған кеңейтімдер';

  @override
  String get extSearchHint => 'Кеңейтімдерді іздеу';

  @override
  String get extCatAll => 'Барлығы';

  @override
  String get extCatTools => 'Құралдар';

  @override
  String get extCatThemes => 'Тақырыптар';

  @override
  String get extCatAutomation => 'Автоматтандыру';

  @override
  String get extCatStats => 'Статистика';

  @override
  String get extCatNetwork => 'Желі';

  @override
  String get extSortBy => 'Сұрыптау';

  @override
  String get extSortPopular => 'Ең танымал';

  @override
  String get extSortRating => 'Ең жоғары баға';

  @override
  String get extSortName => 'Аты';

  @override
  String get extCatalogError => 'Каталогты жүктеу мүмкін болмады';

  @override
  String get extRetry => 'Қайталап көріңіз';

  @override
  String get extEmptySearch => 'Ештеңе табылмады';

  @override
  String get extEmptyInstalled =>
      'Әлі ешқандай кеңейтімдер орнатылмаған.\nКаталогтан біреуін табыңыз немесе файлдан орнатыңыз.';

  @override
  String get extInstallFromFile => 'Файлдан орнату';

  @override
  String get extInstallFromUrl => 'URL бастап орнату';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Жүктеп алу';

  @override
  String get extDownloading => 'Жүктеп алынуда…';

  @override
  String get extVerifying => 'Тексерілуде…';

  @override
  String get extInstalling => 'Орнатуда…';

  @override
  String get extInstallFailed => 'Орнату сәтсіз аяқталды';

  @override
  String get extErrSignature => 'Қолтаңбаны тексеру сәтсіз аяқталды. Файл зақымдалған немесе бұрмаланған болуы мүмкін.';

  @override
  String get extErrManifest => 'Кеңейтім манифесті жарамсыз.';

  @override
  String get extErrNetwork => 'Желі қатесі. Байланысты тексеріп, әрекетті қайталаңыз.';

  @override
  String get extErrHash => 'Жүктеп алу каталогқа сәйкес келмейді. Ол бұрмаланған болуы мүмкін.';

  @override
  String extErrMinApp(String version) {
    return 'Бұл кеңейтім қолданбаның $version немесе одан жаңа нұсқасын қажет етеді.';
  }

  @override
  String get extErrHttpsOnly => 'Тек https:// сілтемелерге рұқсат етілген';

  @override
  String get extErrGeneric => 'Бірдеңе дұрыс болмады. Қайталап көріңіз.';

  @override
  String get extErrAuthorKeyChanged =>
      'Бұл жаңарту орнатылған нұсқаға қарағанда басқа автор кілтімен қол қойылған, сондықтан ол бұғатталды. Жаңа кілтке сенсеңіз, кеңейтімді жойып, оны қайта орнатыңыз.';

  @override
  String get extDisabled => 'Өшірулі';

  @override
  String extToggleEnabled(String name) {
    return '$name қосу';
  }

  @override
  String get extSearchInstalled => 'Орнатылған кеңейтімдерді іздеу';

  @override
  String get extUpdateAll => 'Барлығын жаңарту';

  @override
  String extUpdatesAvailable(int count) {
    return '$count жаңартулар қолжетімді';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count жаңартылды';
  }

  @override
  String get extRiskNormal => 'Қалыпты';

  @override
  String get extRiskSensitive => 'Сезімтал';

  @override
  String get extRiskDangerous => 'Жоғары тәуекел';

  @override
  String get extPermissionsRemoved => 'Енді сұралмаған:';

  @override
  String get extUpdateFailedKept => 'Алдыңғы нұсқа әлі де орнатылған.';

  @override
  String get extConflictsTitle => 'Кеңейтім қайшылықтары';

  @override
  String get extConflictTheme => 'Қолданба тақырыбы';

  @override
  String get extConflictNetHooks => 'Желі ілмектері';

  @override
  String extConflictWinner(String name) {
    return 'Басымдық: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count қақтығыстар сіздің шешіміңізді қажет етеді';
  }

  @override
  String get extConflictsResolve => 'Қайшылықтарды шешу';

  @override
  String extVersionLabel(String version) {
    return 'Нұсқа $version';
  }

  @override
  String get extPermissionsTitle => 'Рұқсаттар';

  @override
  String get extNoPermissions => 'Арнайы рұқсаттар жоқ.';

  @override
  String get extSettings => 'Параметрлер';

  @override
  String get extSaveSettings => 'Параметрлерді сақтау';

  @override
  String extUpdateTo(String version) {
    return '$version дейін жаңарту';
  }

  @override
  String get extEnabled => 'Қосулы';

  @override
  String extRollbackTo(String version) {
    return '$version қалпына қайтару';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version нұсқасына қайтару керек пе?';
  }

  @override
  String get extUninstall => 'Жою';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” және оның параметрлерін жою керек пе?';
  }

  @override
  String get extPanelUnavailable => 'Кеңейтім панелі қолжетімсіз.';

  @override
  String get extPermConnectionsRead => 'Белсенді қосылымдар тізімін қараңыз';

  @override
  String get extPermServersRead => 'Серверлер тізімін қараңыз';

  @override
  String get extPermSettingsRead => 'Қолданба параметрлерін оқыңыз';

  @override
  String get extPermSettingsWrite => 'Қолданба параметрлерін өзгерту';

  @override
  String get extPermNotifications => 'Хабарландыруларды көрсету';

  @override
  String get extPermTray => 'Науа мәзіріне элементтерді қосыңыз';

  @override
  String get extPermUiPanel => 'Қолданбаның ішіндегі панельдерді көрсету';

  @override
  String get extPermThemeApply => 'Тақырыптарды қолдану';

  @override
  String get extPermRoutingRules => 'Маршруттау ережелерін қосу (желі трафигі қай жерде жүретініне әсер етеді)';

  @override
  String get extPermNetHooks => 'Желі жолына біріктіру (DPI айналып өту модульдері)';

  @override
  String get extPermNetFetch => 'Рұқсат етілген тізімнен URL сұрау';

  @override
  String get extPermBackground => 'Фондық тапсырмаларды іске қосыңыз';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Фондық режимде жұмыс істейді';

  @override
  String get extCapNetHook => 'Бұғаттауды айналып өту және желілік ілмектер';

  @override
  String get extCapPanel => 'Интерфейс тақталары';

  @override
  String get extCapRouting => 'Маршруттау ережелері';

  @override
  String get extCapTheme => 'Тақырыптар';

  @override
  String get extCapWidget => 'Виджеттер';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Өзгеріс журналы';

  @override
  String get extImageFailed => 'Кескінді жүктеу мүмкін болмады';

  @override
  String get extScreenshots => 'Скриншоттар';

  @override
  String get extSortRelevance => 'Сәйкестік';

  @override
  String get extPermNetworkDetail => 'VPN сұрауларына тек төмендегі хосттарға рұқсат етіледі.';

  @override
  String get extBgTitle => 'Фондық тапсырма';

  @override
  String get extBgEnabled => 'Фондық режимде іске қосу';

  @override
  String get extBgInterval => 'Іске қосу аралығы';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count минут', one: '$count минут');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count сағат', one: '$count сағат');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Фондық тапсырманы басқару үшін кеңейтімді қосыңыз.';

  @override
  String get extCapNetwork => 'Желіге кіру';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Желі: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Файлға $name';
  }

  @override
  String get diagnosticHttp => 'HTTP диагностикасы';

  @override
  String get diagnosticNoData => 'Жазылған сұраулар әлі жоқ. Алдымен жылдамдықты тексеру веб-сайтын ашыңыз.';

  @override
  String get qrShareTitle => 'QR кодын бөлісіңіз';

  @override
  String get qrScanTitle => 'QR кодын сканерлеңіз';

  @override
  String get qrCopyLink => 'Сілтемені көшіру';

  @override
  String get qrWarning => 'Кодты тек сенімді адамдармен бөлісіңіз.';

  @override
  String get qrScanHint => 'QR коды бар скриншотты не фотоны таңдаңыз немесе сілтемені қойыңыз';

  @override
  String get qrFromClipboard => 'Буферден қою';

  @override
  String get qrNoCode => 'Бұл суреттен QR код табылмады.';

  @override
  String get qrInvalid => 'Бұл QR кодында жарамды сілтеме жоқ.';

  @override
  String get qrScan => 'Сканерлеу QR';

  @override
  String get qrFromImage => 'Суретті ашу';

  @override
  String get connGroupByProcess => 'Процесс бойынша топтастыру';

  @override
  String get connListView => 'Тізім';

  @override
  String get connCopyHost => 'Хостты көшіру';

  @override
  String get connAddRule => 'Ереже қосу';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count қосылым', one: '$count қосылым');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Алдын ала орнатылған';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Жеке';

  @override
  String get dnsCheck => 'Деректердің ағып кетуін тексеріңіз';

  @override
  String get dnsChecking => 'Тексерілуде...';

  @override
  String get dnsNoLeak => 'Ағып кету табылмады';

  @override
  String get dnsLeakFound => 'Ағып кету анықталды';

  @override
  String get dnsLastCheck => 'Соңғы тексеру';

  @override
  String get dnsNeverChecked => 'Әлі тексерілмеген';

  @override
  String get dnsLeakCheckTunnelDns => 'Туннельдің DNS резолверлері';

  @override
  String get dnsLeakCheckSystemResolvers => 'Жүйелік резолверлер';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Желі бұғаттауының DNS қорғанысы';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Жоғарыдағы DNS параметрлерінде туннель үшін DNS конфигурациялаңыз.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Жүйе туннельден тыс қандай шешушілерді пайдаланатынын тексеріңіз.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS трафигі туннельде қалуы үшін желі бұғаттауын қосыңыз.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Жүйенің шифрланған DNS қызметі';

  @override
  String get dnsLeakCheckDnsSpoof => 'Жалған DNS жауаптар';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Жүйе туннельден тыс қандай шифрланған DNS соңғы нүктелерді пайдаланатынын тексеріңіз.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Резолверлер жауаптарды қолдан жасай алмауы үшін туннельде шифрланған DNS (DoT немесе DoH) пайдаланыңыз.';

  @override
  String get dnsCheckNeedsConnection => 'Алдымен VPN желісіне қосылыңыз, содан кейін ағып кетуді тексеріңіз.';

  @override
  String get dnsExpected => 'Күтілетін';

  @override
  String get dnsActual => 'Бақыланады';

  @override
  String get measureSpeed => 'Жылдамдықты өлшеңіз';

  @override
  String get benchmarkStale => 'ескірген';

  @override
  String get autoSelectMode => 'Серверді автоматты түрде таңдау';

  @override
  String get autoSelectPing => 'Ең жылдам пинг';

  @override
  String get autoSelectSpeed => 'Ең жылдам жылдамдық';

  @override
  String get autoSelectSmart => 'Ақылды таңдау';

  @override
  String get coreWatchUnstable => 'Ядромен байланыс тұрақсыз. Сәл күтіп, қайта қосылып көріңіз.';

  @override
  String get watchReconnect => 'Қайта қосыңыз';

  @override
  String get crashRestoreTitle => 'Соңғы сессия үзілді';

  @override
  String get restoreOnCrash => 'Бұзылудан кейін сеансты қалпына келтіру';

  @override
  String get crashRestore => 'Қалпына келтіру';

  @override
  String get crashDismiss => 'Қазір емес';

  @override
  String get overrideTitle => 'Менің өңдеулерім';

  @override
  String get overrideEdit => 'Серверлерді өңдеу';

  @override
  String get overrideHide => 'Жасыру';

  @override
  String get overrideUnhide => 'Көрсету';

  @override
  String get overrideClear => 'Өңдеулерді қалпына келтіріңіз';

  @override
  String get overrideEmpty => 'Әзірге өңдеулер жоқ';

  @override
  String get overrideCustomRules => 'Жеке ережелер';

  @override
  String get errBenchmarkUnsupported => 'Жылдамдықты өлшеу үшін ядроның жаңарақ нұсқасы қажет. Sora-ны жаңартыңыз.';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total бастап $done өлшеуі…';
  }

  @override
  String get profiles => 'Желі профильдері';

  @override
  String get profilesEmpty =>
      'Әзірге профильдер жоқ. Белгілі желілерде параметрлерді автоматты түрде қолдану үшін біреуін жасаңыз.';

  @override
  String get profileAdd => 'Профиль қосу';

  @override
  String get profileName => 'Профиль атауы';

  @override
  String get profileSsids => 'Wi-Fi желілер (SSID)';

  @override
  String get profileSsidsHint => 'Үй, кеңсе үтірмен бөлінген';

  @override
  String get profileGateways => 'Желілік шлюздер';

  @override
  String get profileAsns => 'AS сандар';

  @override
  String get profileAutoApply => 'Автоматты түрде қолдану';

  @override
  String get profileAutoApplyHint => 'Өшірулі болса, профильді қолдану алдында растау сұралады.';

  @override
  String get profileSnapshot => 'Ағымдағы параметрлерді есте сақтаңыз';

  @override
  String get profileSnapshotDone => 'Ағымдағы параметрлер профильге сақталған';

  @override
  String get profileDelete => 'Профильді жою';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" профилін жою керек пе?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '\"$name\" профилін қолдану керек пе?';
  }

  @override
  String get profileApply => 'Қолдану';

  @override
  String profileApplied(Object name) {
    return '\"$name\" профилі қолданылды';
  }

  @override
  String get profileUndo => 'Болдырмау';

  @override
  String get profileActive => 'Белсенді';

  @override
  String networkNow(Object info) {
    return 'Қазір: $info';
  }

  @override
  String get networkUnknown => 'Желі туралы ақпарат қолжетімді емес';

  @override
  String get profileNoTriggers => 'Кем дегенде бір триггерді қосыңыз: SSID, шлюз немесе ASN';

  @override
  String get chains => 'Прокси-тізбектер';

  @override
  String get chainsEmpty =>
      'Әлі тізбектер жоқ. 2–3 серверді байланыстырыңыз, осылайша олардың әрқайсысы арқылы трафик өтеді.';

  @override
  String get chainAdd => 'Жаңа тізбек';

  @override
  String get chainName => 'Тізбек атауы';

  @override
  String get chainPickServers => '2–3 серверді таңдаңыз';

  @override
  String get chainOrderHint => 'Қайта реттеу үшін сүйреңіз: трафик жоғарғы жағынан кіреді және төменгі жағынан шығады.';

  @override
  String get chainTooFew => 'Тізбекке кемінде екі сервер қажет. Тағы бір сервер қосыңыз.';

  @override
  String get chainTooMany => 'Тізбекте ең көбі үш сервер болуы мүмкін. Артық серверлерді алып тастаңыз.';

  @override
  String get chainEstimate => 'Болжалды кідіріс';

  @override
  String get chainSave => 'Тізбекті сақтау';

  @override
  String get chainDelete => 'Тізбекті жою';

  @override
  String chainDeleteConfirm(Object name) {
    return '\"$name\" тізбегін жою керек пе?';
  }

  @override
  String get chainUnsupported => 'Таңдалған ядро тізбектерді қолдамайды. Үйлесімді ядроны таңдаңыз.';

  @override
  String get chainHopMissing => 'Тізбектегі бір сервер енді қолжетімсіз. Сол буын үшін басқа сервер таңдаңыз.';

  @override
  String chainHop(Object n) {
    return 'Аралық торап $n';
  }

  @override
  String get chainEntry => 'Кіру';

  @override
  String get chainExit => 'Шығу';

  @override
  String get sync => 'Құрылғыны синхрондау';

  @override
  String get syncDevices => 'Менің құрылғыларым';

  @override
  String get syncEmpty => 'Жұптастырылған құрылғылар жоқ. Жергілікті желі арқылы басқа құрылғыны жұптаңыз.';

  @override
  String get syncPair => 'Құрылғыны жұптаңыз';

  @override
  String get syncShowCode => 'Менің кодты көрсетіңіз';

  @override
  String get syncScanCode => 'Кодты сканерлеу';

  @override
  String get syncRevoke => 'Алып тастау';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" күшін жою керек пе?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Соңғы синхрондау: $time';
  }

  @override
  String get syncNever => 'Ешқашан';

  @override
  String get syncNoLan => 'Құрылғылар бір жергілікті желіде болуы керек';

  @override
  String get syncPaired => 'Құрылғы жұпталған';

  @override
  String get syncPairingTitle => 'Осы құрылғымен жұптаңыз';

  @override
  String get syncWaiting => 'Басқа құрылғы күтілуде…';

  @override
  String get syncSecureNote => 'Шифрланған арна. Есептік жазбалар, бұлттық серверлер жоқ.';

  @override
  String get zapretWithVpn => 'Тікелей желі трафигі үшін DPI сүзгісін айналып өтіңіз';

  @override
  String get zapretWithVpnHint =>
      'zapret VPN туннелімен қатар іске қосылады: туннель трафигі VPN арқылы, тікелей трафик бұғаттауды айналып өту құралы арқылы өтеді.';

  @override
  String get chainDuplicate => 'Тізбекте бір сервер қайталанған. Әр буын үшін бөлек сервер таңдаңыз.';

  @override
  String get edit => 'Өңдеу';

  @override
  String get remove => 'Жою';

  @override
  String get autoSwitchOnDegrade => 'Тозуды автоматты түрде қосу';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Таңдалған сервер қатты баяуласа немесе жауап бермесе, Sora өлшеу нәтижесі ең жақсы серверге ауысады, бірақ 10 минутта бір реттен жиі емес.';

  @override
  String get tunStackMixed => 'Аралас';

  @override
  String get tunStackSystem => 'Жүйе';

  @override
  String get customServerAdd => 'Теңшелетін серверді қосыңыз';

  @override
  String get customServers => 'Менің серверлерім';

  @override
  String get customServerName => 'Аты';

  @override
  String get customServerNameHint => 'Мысалы: менің VPS';

  @override
  String get customServerNameRequired => 'Атын енгізіңіз';

  @override
  String get customServerAddress => 'Мекенжай';

  @override
  String get customServerAddressHint => 'example.com немесе 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Сервер мекенжайын енгізіңіз';

  @override
  String get customServerAddressInvalid => 'Жарамсыз мекенжай';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Порт 1-ден 65535-ке дейінгі сан болуы керек';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Жүйеге кіру ақпараты';

  @override
  String get customServerOptional => 'Қосымша';

  @override
  String get customServerShowSecret => 'Құпияны көрсету';

  @override
  String get customServerHideSecret => 'Құпияны жасыру';

  @override
  String customServerDeleteConfirm(String name) {
    return '\"$name\" серверін жою керек пе?';
  }

  @override
  String get customServerTest => 'Сынақ';

  @override
  String get leakTestTitle => 'Деректердің ағып кетуіне сынақ';

  @override
  String get leakTestIntro =>
      'Трафиктің құрылғыдан туннельден тыс шыға алатынын тексереді: тікелей DNS және ICMP сұраулары, IPv6 шығысы және жүйелік резолверлер. Қосылым белсенді кезде іске қосыңыз.';

  @override
  String get leakTestRun => 'Тексеріңіз';

  @override
  String get leakTestCancel => 'Болдырмау';

  @override
  String get leakTestNeedsConnection => 'Деректердің ағып кетуін тексеру үшін VPN желісіне қосылыңыз.';

  @override
  String leakTestProgress(int count) {
    return 'Тестілеу аяқталды: $count';
  }

  @override
  String get leakTestAllClear => 'Ағып кету табылмады';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дерек ағуы анықталды',
      one: '$count дерек ағуы анықталды',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Түзету';

  @override
  String get leakTestFixedNote => 'Желі бұғаттауы қосулы. Тексеру үшін сынақты қайта іске қосыңыз.';

  @override
  String get leakTestCheckDirectDns => 'Тікелей DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP жаңғырық';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Жүйелік резолверлер';

  @override
  String get leakTestCheckTunnelConnectivity => 'Туннель қосылымы';

  @override
  String get leakTestCheckTunnelDns => 'DNS туннель арқылы';

  @override
  String get noticeDegraded => 'Сервер баяулады. Sora өлшеу кезінде табылған ең жақсы серверге ауысты.';

  @override
  String get obfs => 'Трафикті бүркемелеу';

  @override
  String get syncCodeExpired => 'Кодтың мерзімі аяқталды';

  @override
  String get syncDaemonFailed => 'Синхрондау қызметін бастау мүмкін болмады';

  @override
  String get syncDaemonMissing =>
      'sora-sync компоненті табылмады. Құрылғыны синхрондауды қосу үшін қолданбаны қайта орнатыңыз.';

  @override
  String get syncDaemonStarting => 'Синхрондау қызметін бастау…';

  @override
  String get syncErrAuth =>
      'Синхрондау қызметі кіру таңбалауышын қабылдамады. Қолданбаны қайта іске қосып, әрекетті қайталаңыз.';

  @override
  String get syncErrNotFound => 'Құрылғы енді жұпталмаған';

  @override
  String get syncErrPairingActive => 'Жұптастыру сеансы әлдеқашан ашық';

  @override
  String get syncErrUnreachable =>
      'Басқа құрылғы жауап бермеді. Оның бір желіде екеніне және оның кодын көрсететініне көз жеткізіңіз.';

  @override
  String get syncError => 'Синхрондау қатесі';

  @override
  String syncExpiresIn(String duration) {
    return 'Кодтың мерзімі $duration кейін аяқталады';
  }

  @override
  String get syncJoining => 'Құрылғымен жұптастыру…';

  @override
  String get syncLegacyCleared =>
      'Ескі құрылғылар тізімі ешқашан шынымен жұпталмаған, сондықтан ол тазартылды. Құрылғыларыңызды қайта жұптаңыз, бұл жолы нақты.';

  @override
  String get syncNewCode => 'Жаңа код';

  @override
  String syncPairedWith(String name) {
    return '$name жұптастырылған';
  }

  @override
  String get syncRetry => 'Қайталау';

  @override
  String get syncStopShowing => 'Кодты жасыру';

  @override
  String get syncSyncNow => 'Қазір синхрондау';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled алынды, $pushed жіберілді';
  }

  @override
  String get syncResultTitle => 'Синхрондау нәтижесі';

  @override
  String get syncPulled => 'алынды';

  @override
  String get syncPushed => 'Жіберілді';

  @override
  String get syncNoChanges => 'Ешқандай өзгерістер анықталмады';

  @override
  String get syncDocKindSubscriptions => 'Жазылымдар';

  @override
  String get syncDocKindSettings => 'Қолданба параметрлері';

  @override
  String get syncDocKindOverrides => 'Жазылымдардың жеке түзетулері';

  @override
  String get syncDocKindProfiles => 'Желі профильдері';

  @override
  String get syncDocKindChains => 'Прокси-тізбектер';

  @override
  String syncFrom(String name) {
    return '$name құрылғысынан';
  }

  @override
  String get syncThisDevice => 'Бұл құрылғы';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Пакетті түсіру';

  @override
  String get diagnosticEvents => 'Windows оқиғалары';

  @override
  String get diagnosticCapture => '10 секундқа түсіріңіз';

  @override
  String get diagnosticRequiresTun => 'Пакеттерді түсіру үшін белсенді Sora TUN қосылымы қажет.';

  @override
  String get diagnosticUnavailable => 'Бұл диагностика бұл платформада қолжетімді емес.';

  @override
  String get extErrRevoked => 'Sora командасы кеңейтудің бұл нұсқасын қауіпті немесе бұзылған деп кері қайтарды.';

  @override
  String get extErrRevocationsExpired => 'Күші жойылған кеңейтімдер тізімі жаңартылғанша орнату бұғатталған.';

  @override
  String extRevokedDisabled(String names) {
    return 'Кері қайтарылған кеңейтулер өшірілді: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Жеке кілт';

  @override
  String get customServerWgAddresses => 'Интерфейс мекенжайлары';

  @override
  String get customServerWgPeerKey => 'Сервердің ашық кілті';

  @override
  String get customServerWgPresharedKey => 'Ортақ кілт';

  @override
  String get customServerWgAllowedIps => 'Рұқсат етілген IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, секунд';

  @override
  String get customServerWgKeyInvalid => 'Кілт wg genkey шығаратындай base64 түріндегі 32 байт болуы керек.';

  @override
  String get customServerWgCidrInvalid => 'Үтірмен бөлінген префикстерді енгізіңіз, мысалы 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => '0-ден 65535-ке дейінгі секунд санын енгізіңіз.';

  @override
  String get strictKillSwitch => 'Қатаң желі бұғаттауы';

  @override
  String get strictKillSwitchWarning =>
      'Қосылғаннан кейін ақау, қайта іске қосу немесе қолданбадан шығу кезінде де VPN сыртындағы трафикті бұғаттайды. Қолжетімділік тек қосылымды үзгенде немесе осы параметрді өшіргенде қалпына келеді. Құрылғы қайта жүктелген соң бұғаттау іске қосылғанда қосылу қосулы болса ғана жалғасады.';

  @override
  String get extWorkerFailed => 'Кеңейтімнің фондық тапсырмасы орындалмады. Кеңейтім журналын тексеріңіз.';

  @override
  String get extAssetRejected =>
      'Кеңейтім файлында оқылмайтын түстер немесе жарамсыз ережелер бар. Кеңейтім авторынан файлды түзетуді сұраңыз.';

  @override
  String get extVerifiedSora => 'Sora тексерген';

  @override
  String extReceivedBytes(String count) {
    return '$count Б';
  }

  @override
  String get extOpen => 'Ашу';

  @override
  String get customServerOwn => 'Жеке сервер';

  @override
  String get customServerPaste => 'Сілтемені қою';

  @override
  String get customServerUser => 'Пайдаланушы';

  @override
  String get customServerPassword => 'Құпиясөз';

  @override
  String get customServerSecretRequired => 'Мән енгізіңіз';

  @override
  String get customServerLinkInvalid => 'Сервер сілтемесі жарамсыз';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Sora ішкі қатесі. Журналды сақтап, ақау туралы хабарлаңыз.';

  @override
  String get errTls => 'Сервер сертификаты қабылданбады. Сағатты тексеріңіз немесе провайдерге хабарласыңыз.';

  @override
  String get errFileAccess => 'Файлға қолжетімсіз. Рұқсаттар мен бос орынды тексеріңіз.';

  @override
  String get errDataLimit => 'Дерек тым көп. Азырақ элемент таңдап, қайталап көріңіз.';

  @override
  String get errCredentials => 'Сақталған кіру деректері жоқ. Серверді қайта импорттаңыз.';

  @override
  String subscriptionStale(String time) {
    return 'Жаңартылған уақыты: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Әлі жаңартылмады. Қайталап көріңіз.';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Сервер HTTP $status кодын қайтарды. Сілтемені тексеріңіз немесе провайдерге хабарласыңыз.',
      zero: 'Сервер сұрауды қабылдамады. Сілтемені тексеріңіз немесе провайдерге хабарласыңыз.',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Сервер баптаулары толық емес немесе қолдау көрсетілмейді. Жазылымды жаңартыңыз.';

  @override
  String get errServerIds => 'Екі сервердің идентификаторы бірдей. Оларды қайта импорттаңыз.';

  @override
  String get errRoutingGroup => 'Бағыт жоқ серверлерге немесе бүлінген топқа сілтейді. Жазылымды жаңартыңыз.';

  @override
  String get errConnections => 'Қосылымдар тізімі қолжетімсіз. Қосылыңыз немесе басқа қозғалтқыш таңдаңыз.';

  @override
  String get errLogs => 'Бұл қызмет журнал жүргізбейді. Sora-ны жаңартыңыз.';

  @override
  String get errDiagnostics => 'Диагностика жиналмады. Қайталап көріңіз немесе журналды сақтаңыз.';

  @override
  String get errMissingItem => 'Сұралған элемент енді жоқ. Тізімді жаңартыңыз.';

  @override
  String get errInvalidRequest => 'Сұрауда жарамсыз мәндер бар. Енгізілген деректерді тексеріп, қайталаңыз.';

  @override
  String get errProxyLogin =>
      'Жүйелік прокси бұл кіруді қолдамайды. Жергілікті проксидің пайдаланушы аты мен құпиясөзін өшіріңіз.';

  @override
  String get errLogFilter => 'Журнал сүзгісі жарамсыз. Іздеуді тазалап, қайталаңыз.';

  @override
  String get errSubRedirect => 'Сервер қауіпті мекенжайға бағыттады. Провайдерден жаңа сілтеме сұраңыз.';

  @override
  String get errProxySetup => 'Жүйелік прокси бапталмады. Қайта қосылыңыз немесе журналды ашыңыз.';

  @override
  String get notificationsToday => 'Бүгін';

  @override
  String get notificationsYesterday => 'Кеше';

  @override
  String get notificationsMarkRead => 'Барлығын оқылған деп белгілеу';

  @override
  String get notificationsUnread => 'Оқылмаған';

  @override
  String get desktopNotifications => 'Жүйелік хабарландырулар';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Жазылымды жаңарту аралығы жарамсыз. Провайдер ұсынған аралықты таңдаңыз.';

  @override
  String get errRule => 'Бағыттау ережесі жарамсыз. Ережедегі доменді, IP мекенжайын немесе қолданбаны тексеріңіз.';

  @override
  String get errDns => 'DNS баптаулары жарамсыз. DNS серверінің мекенжайын тексеріңіз.';

  @override
  String get errEndpoint => 'Тексерілетін сервердің мекенжайы жарамсыз. Хост атауы мен портты тексеріңіз.';

  @override
  String get errCancelled => 'Сұрау тоқтатылды. Қажет болса, әрекетті қайталаңыз.';
}
