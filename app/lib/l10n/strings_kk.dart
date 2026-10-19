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
  String get stateFailed => 'Қосылмаған';

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
  String speedMbps(double value) {
    return '${intl.NumberFormat('0.0', localeName).format(value)} Mbps';
  }

  @override
  String latencyMs(int value) {
    return '$value ms';
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
  String get errCore => 'Sora қызметі жауап бермейді';

  @override
  String get errAuth => 'Sora қызметіне кіру мүмкін емес';

  @override
  String get errVersion => 'Sora жаңарту: қолданба мен қызмет әртүрлі нұсқалар';

  @override
  String get errBusy => 'Күте тұрыңыз, алдыңғы пәрмен әлі жұмыс істейді';

  @override
  String get errEngineMissing => 'Бұл сервер үшін ешқандай қозғалтқыш табылмады';

  @override
  String get errEngineStart => 'Қозғалтқыш іске қосылмады';

  @override
  String get errEngineStopped => 'Қозғалтқыш тоқтады';

  @override
  String get errTunnel => 'VPN қосылымын жасауға рұқсат жоқ';

  @override
  String get errServers => 'Сервер қатемен конфигурацияланған';

  @override
  String get errNetwork => 'Серверге қол жеткізу мүмкін емес';

  @override
  String get errTimeout => 'Сервер уақытында жауап бермеді';

  @override
  String get errFirewall => 'VPN-ден тыс интернетті блоктау мүмкін болмады';

  @override
  String get errSubFetch => 'Жазылым жүктелмеді';

  @override
  String get errSubFormat => 'Бұл жазылым сілтемесі емес';

  @override
  String get errSubEmpty => 'Жазылымда серверлер жоқ';

  @override
  String get errSubDuplicate => 'Бұл жазылым әлдеқашан қосылған';

  @override
  String get errSubLimit => 'Жазылымдар тым көп';

  @override
  String get errSubScheme => 'Сілтеме https:// деп басталуы керек';

  @override
  String get errSecretStore => 'Sora жады зақымдалған немесе қолжетімсіз';

  @override
  String get errNoServers => 'Қосылу үшін жазылым қосыңыз';

  @override
  String get exportText => 'Мәтін';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Жарық';

  @override
  String get themeDark => 'Қараңғы';

  @override
  String get language => 'Тіл';

  @override
  String get languageSystem => 'System';

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
      other: 'жазылым # күндері аяқталады',
      one: 'жазылым # күні аяқталады',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверлері өз кезегінде',
      one: '# сервері өз кезегінде',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверлері, ең жылдам',
      one: '# сервері, ең жылдам',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelTun => 'Барлық трафик';

  @override
  String get tunnelProxy => 'System прокси';

  @override
  String get proxyAddress => 'Прокси мекенжайы';

  @override
  String get copied => 'Көшірілген';

  @override
  String get launchAtLogin => 'Жүйеден бастаңыз';

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
  String get currentServer => 'Ағымдағы сервер';

  @override
  String get trafficDown => 'Жүктеп алынды';

  @override
  String get trafficUp => 'Жүктеп салынды';

  @override
  String perSecond(String value) {
    return '$value/с';
  }

  @override
  String activeRules(int count) {
    return 'Белсенді ережелер: $count';
  }

  @override
  String get recentNotifications => 'Соңғы хабарландырулар';

  @override
  String get notificationsEmpty => 'Қосылым және жазылым оқиғалары осы жерде пайда болады';

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
  String get programsFailed => 'Қолданбалар жүктелмеді';

  @override
  String get programsEmpty => 'Қолданбалар табылмады. Басқа атауды қолданып көріңіз.';

  @override
  String get selectExe => 'exe файлын таңдаңыз';

  @override
  String get trafficUnavailable => 'Есептегіштер әлі қол жетімді емес';

  @override
  String get speedtest => 'Жылдамдық';

  @override
  String get speedtestCheck => 'Жылдамдықты тексеріңіз';

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
  String get updateSignaturePending => 'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';
  String get updateManualSigWarning => 'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

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
  String get appCopyright => '© 2026 levvs-one және салымшылар';

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
  String get bypassLimitations =>
      'Бұл режим тек HTTP және TLS үшін DPI мәнін айналып өтеді, UDP қолдамайды немесе IP мекенжайын өзгертпейді. Discord дауыс, қоңыраулар және блокталған Telegram мекенжайлары үшін VPN серверін пайдаланыңыз.';

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
      'Серверге қандай қозғалтқыш қажет екенін білмесеңіз, Авто опциясын таңдаңыз. Sora қосылу алдында профиль мен параметрлерді тексереді. Қозғалтқыш жоспарыңыздың өткізу қабілеттілігін арттыра алмайды: өнімділік серверге, маршрутқа, протоколға және желіге байланысты.\n\n## Режимдер\n\n### Барлық трафик (TUN)\n\nSora виртуалды желі интерфейсін жасайды және ол арқылы TCP және UDP қоса, қолданба трафигін бағыттайды. Бұл режимді Telegram, ойындар және Discord дауысы үшін пайдаланыңыз. Ережелер нақты сайттарды немесе бағдарламаларды тікелей жібере алады немесе оларды блоктай алады. Желі қызметіне рұқсат және қажетті протоколды қолдайтын сервер қажет.\n\n### System прокси\n\nSora жергілікті HTTP/SOCKS проксиін конфигурациялайды. Жүйенің прокси параметрлерін құрметтейтін қолданбалар оны пайдаланады. Өз желілік стегі бар қолданбалар тікелей қосыла алады; UDP және дауыстық қоңырауларға әдетте TUN қажет. Бұл режим прокси қолдауы бар браузерлер мен қолданбаларға сәйкес келеді.\n\n### Сервер жоқ\n\nLinux жүйесінде Sora HTTP/TLS сұрауларын бөлу және пішінін өзгерту және кейбір DPI тексерулерін айналып өту үшін [zapret](https://github.com/bol-van/zapret) пайдаланады. IP мекенжайыңыз өзгеріссіз қалады және қосылымдар тікелей веб-сайтқа өтеді. Нәтижелер провайдеріңізге және блоктау әдісіне байланысты.\n\nАғымдағы біріктіру TCP арқылы HTTP және TLS үшін tpws пайдаланады. Ол IP блоктауын немесе UDP релесін айналып өтпейді және Telegram MTProto қосылымдарына кепілдік бере алмайды. Discord дауысы, Telegram қоңыраулары және осындай шектеулер үшін TUN бар VPN серверін пайдаланыңыз.\n\n## Қозғалтқыштар\n\n### Авто\n\nSora барлық қосылу жоспарын қолдайтын орнатылған қозғалтқышты таңдайды: сервер протоколдары, тасымалдаулар, топтар, фрагментация және режим. Сәйкес келмейтін қолмен таңдау ағымдағы қосылымды тоқтатудан бұрын қабылданбайды. Автоматты немесе басқа қозғалтқышты таңдап, параметрлерді қайта қолданыңыз.\n\n### sing-box\n\nЖаңа Sora пакеттеріне клиенттік XHTTP және VLESS Encryption қосатын [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) шанышқысы кіреді. Sora құрастыруды және оның мүмкіндіктерін таниды. XHTTP жоқ жоғары ағынды құрастыру бұл мүмкіндікті тек оның атынан ғана ала алмайды.\n\nVLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard протоколдары және Sora импорттай алатын AmneziaWG 1.x/2.x параметрлері қолдау табады. Толық Xray JSON профильдері үшін Xray қажет. Жаңа AWG 3.x өрістерін әзірше импорттау мүмкін емес. sing-box құпиясөзбен қорғалған жергілікті басқару портын пайдаланады; компьютердегі басқа қолданбалар оны анықтай алады.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption және TLS фрагментациясын қолдайды. Ол сонымен қатар Xray провайдерінің толық профильдерін олардың маршруттары мен топтарын сақтай отырып іске қосады. Мұндай профильдерді мінез-құлқын өзгертпестен автоматты түрде басқа қозғалтқышқа түрлендіру мүмкін емес.\n\nЖинақтағы Xray TLS сертификатын тексеруді өшіретін параметрді жойды (`allowInsecure`). Бұл параметрді қажет ететін қарапайым серверлер үшін sing-box немесе mihomo опциясын автоматты түрде таңдайды. Xray таңдау ағымдағы қосылымды тоқтату алдында сәйкессіздікті қолмен хабарлайды. Ескі толық JSON профильдері тексерілетін сертификат немесе сертификат PIN коды бар жаңартылған провайдер профилін қажет етеді.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) реттелген қалпына келтіру және жүктемені теңестіру топтарын, XHTTP және AmneziaWG қолдайды. Сақтық көшірме серверіне автоматты ауыстыру маңызды болғанда оны таңдаңыз. Sora TLS фрагментация параметрі бұл қозғалтқышта қолжетімсіз.\n\n## Sora ішіндегі үйлесімділік\n\n| Ерекшелігі | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN және TCP/UDP | Иә | Иә | Иә |\n| XHTTP | Иә | Иә | Иә |\n| VLESS Encryption | Иә | Иә | Иә |\n| Толық Xray профилі | Жоқ | Иә | Жоқ |\n| TUIC / AnyTLS | Екеуі де | Жоқ | TUIC |\n| TLS фрагментациясы | Иә | Иә | Жоқ |\n| AmneziaWG 1.x/2.x | Иә¹ | Жоқ | Иә |\n| Тапсырыс берілген резервтік топ | Жоқ | No² | Иә |\n\n¹ J1/J2/J3/Itime профильдері mihomo пайдаланады; бұл өрістерді ешқашан үнсіз тастауға болмайды. ² Толық Xray профильдерінің тобы үшін қолданба сақтық көшірме профилін таңдайды. Қолдау орнатылған құрылымға байланысты; туралы нұсқасын тексеріңіз.\n\n## TUN стек\n\nСтек виртуалды интерфейстің ішінде TCP және UDP өңдейді. Режимдер панелінде Xray және mihomo gVisor, System, Mixed және MIPS ұсынады. Әрбір қозғалтқыш өз таңдауын сақтайды. System прокси және серверсіз режимдері бұл теңшеуді пайдаланбайды.\n\n- **Mixed** — TCP жүйелік стекті пайдаланады, ал gVisor UDP өңдейді. Бұл Linux жүйесіндегі mihomo үшін әдепкі нұсқа. Windows жүйесінде Xray және mihomo әдепкі бойынша MIPS пайдаланады.\n- **System** — жүйелік стек пайдаланады. Желілік қолданбаларда ақаулықтар туындаса, басқа опцияны қолданып көріңіз.\n- **gVisor** — пайдаланушылар кеңістігіндегі трафикті өңдейді.\n- **MIPS** — mihomo жеке IP стегі, жинақталған 1.19.32 нұсқасында қолжетімді.\n\nLinux жүйесінде Xray әдепкі бойынша кірістірілген gVisor пайдаланады. Linux жүйесіндегі System, Mixed және MIPS TUN қозғалтқышы ретінде mihomo пайдаланады, TCP және UDP аутентификацияланған жергілікті SOCKS сілтемесі арқылы Xray файлына бағыттайды. Xray протоколды, провайдер профилін және маршруттауды сақтайды. Бұл үш опция орнатылған mihomo қажет. Windows жүйесінде Xray барлық төрт TUN стегі үшін mihomo 1.19.32 немесе жаңасын пайдаланады. Протоколдар мен маршруттау Xray жүйесінде қалады. Бұл тіркесімде қолданба ережелері тек тікелей қосылуды және бұғаттауды қолдайды; Linux жүйесінде бұл ережелер Xray кірістірілген gVisor стегін қажет етеді.\n\nКөпір екінші процесті жүргізеді. Linux құрылғысындағы үш бос өлшеу кезінде ол жергілікті Xray TUN-ға қарағанда 32–36 МБ артық физикалық жадты пайдаланды. Бұл жүктеу жүктемесін өлшемейді: процессор мен жад құны қосылымдарға байланысты. sing-box стек селекторы жоқ. Ешбір стек әрбір желіде жақсы өнімділікке кепілдік бермейді. Стекті таңдап, оны желіде сынап көру үшін Қолдану және қайта қосылу опциясын таңдаңыз.\n\n## Параметрлерді қолдану\n\nСерверді таңдау автоматты түрде қайта қосылады. Режим, қозғалтқыш, DNS және ереже параметрлері бірден сақталады; белсенді қосылым кезінде оларды пайдалану үшін Қолдану түймесін басып, қайта қосылыңыз. Қозғалтқышты қайта іске қосу жүктеп алулар мен қоңырауларды тоқтатуы мүмкін. Қайталанатын шертулер параллель қосылымдарды бастамайды; ажырату ауысуды аяқтайды және қосылымды босатады.\n\nТек VPN арқылы Интернет туннель құлаған кезде тікелей трафикті блоктайды. Бұл бүкіл машинаға әсер етеді. Айқын ажырату Sora ережелерін жояды. Тазалау аяқталмаса, қайта ажыратып көріңіз және журналды ашыңыз.\n\n## Жобалық құжаттама\n\n- [sing-box-lx: конфигурация және қолдау](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box құжаттамасы](https://sing-box.sagernet.org/)\n- [Xray құжаттамасы](https://xtls.github.io/)\n- [mihomo құжаттамасы](https://wiki.metacubex.one/)\n- [zapret: жұмыс және шектеулер](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Серверлерді тексеріңіз';

  @override
  String get extensions => 'Кеңейтімдер';
  @override
  String extRatingLabel(String rating) => 'Rating $rating of 5';
  @override
  String extByAuthor(String author) => 'by $author';
  @override
  String extInstallsCount(String count) => '$count installs';
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
  String get extSideloadWarning => 'Not from the team catalog. The author\'s key is self-attested: install only if you trust the author.';
  @override
  String extInstallTitle(String name) => 'Install $name';
  @override
  String extUpdateTitle(String name) => 'Update $name';
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
  String get extEmptyInstalled => 'No extensions installed yet.
Find one in the catalog or install from a file.';
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
  String extErrMinApp(String version) => 'This extension needs app version $version or newer.';
  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';
  @override
  String get extErrGeneric => 'Something went wrong. Please try again.';
  @override
  String get extUpdateAvailable => 'Update available';
  @override
  String get extDisabled => 'Disabled';
  @override
  String extVersionLabel(String version) => 'Version $version';
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
  String get extOpenPanel => 'Open panel';
  @override
  String extUpdateTo(String version) => 'Update to $version';
  @override
  String get extEnabled => 'Enabled';
  @override
  String extRollbackTo(String version) => 'Roll back to $version';
  @override
  String extRollbackConfirm(String version) => 'Roll back to version $version?';
  @override
  String get extUninstall => 'Uninstall';
  @override
  String extUninstallConfirm(String name) => 'Remove “$name” and its settings?';
  @override
  String get extPanelUnavailable => 'The panel is unavailable. The extension may have been disabled or removed.';
  @override
  String get extCatalogSoonTitle => 'The team catalog is coming soon';
  @override
  String get extCatalogSoonBody => 'Until then, you can install extensions from a file or a link — every package is still signature-checked.';
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
      'Can wake up on a schedule and run code in the background.';

  @override
  String get extCapBackground => 'Background tasks';
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
  String extCatalogCached(String date) => 'Cached catalog · ${date}';
  @override
  String get extChangelog => 'Changelog';
  @override
  String get extImageFailed => 'Couldn\'t load the image';
  @override
  String get extRatingHow => 'How ratings work';
  @override
  String get extRatingHowBody => 'Ratings use a Bayesian average: an extension with few ratings stays near the middle until more people vote, so a single 5-star review cannot push a new extension to the top. Recent ratings weigh more than old ones, and only one rating per account counts.';
  @override
  String get extScreenshots => 'Screenshots';
  @override
  String get extSortRelevance => 'Relevance';
  @override
  String get extPermNetworkDetail => 'Internet access is limited to these hosts:';
  @override
  String get extBgTitle => 'Background task';
  @override
  String get extBgEnabled => 'Run in background';
  @override
  String get extBgInterval => 'Run interval';
  @override
  String extBgMinutes(int minutes) => '$minutes min';
  @override
  String extBgHours(int hours) => '$hours h';
  @override
  String get extBgNote =>
      'Applies immediately. The shortest allowed interval is 15 minutes.';
  @override
  String get extBgDisabledNote =>
      'Enable the extension to manage its background task.';
  @override
  String get extCapNetwork => 'Can reach the internet';
  @override
  String extCapNetworkHosts(String hosts) => 'Can reach: $hosts';

  @override
  String exportLogFile(String name) {
    return 'Файлға $name';
  }

  @override
  String get diagnosticHttp => 'HTTP диагностикасы';

  @override
  String get diagnosticPackets => 'Пакетті түсіру';

  @override
  String get diagnosticEvents => 'Windows оқиғалары';

  @override
  String get diagnosticCapture => '10 секундқа түсіріңіз';

  @override
  String get diagnosticNoData => 'Жазылған сұраулар әлі жоқ. Алдымен жылдамдықты тексеру веб-сайтын ашыңыз.';

  @override
  String get diagnosticRequiresTun => 'Пакеттерді түсіру үшін белсенді Sora TUN қосылымы қажет.';

  @override
  String get diagnosticUnavailable => 'Бұл диагностика бұл платформада қолжетімді емес.';
  @override
  String get dnsExpected => 'Expected';
  @override
  String get dnsActual => 'Observed';
  @override
  String get dnsCheckNeedsConnection => 'Connect to the VPN first, then check for leaks.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# connections',
      one: '# connection',
    );
    return _temp0;
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
  String benchmarkProgress(int done, int total) => 'Measuring $done of $total…';
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
  String profileDeleteConfirm(String name) => 'Delete profile "${name}"?';

  @override
  String profileApplyAsk(String name) => 'Apply profile "${name}"?';

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) => 'Profile "${name}" applied';

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) => 'Now: ${info}';

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
  String chainDeleteConfirm(String name) => 'Delete chain "${name}"?';

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(String n) => 'Hop ${n}';

  @override
  String get chainEntry => 'Entry';

  @override
  String get chainExit => 'Exit';

  @override
  String get sync => 'Device sync';

  @override
  String get syncDevices => 'My devices';

  @override
  String get syncEmpty => 'No paired devices. Pair another device to keep subscriptions, rules and settings in sync.';

  @override
  String get syncPair => 'Pair a device';

  @override
  String get syncShowCode => 'Show my code';

  @override
  String get syncScanCode => 'Scan a code';

  @override
  String get syncRevoke => 'Revoke';

  @override
  String syncRevokeConfirm(String name) => 'Revoke "${name}"?';

  @override
  String syncLastSync(String time) => 'Last sync: ${time}';

  @override
  String get syncNever => 'Never';

  @override
  String get syncWhat => 'What syncs';

  @override
  String get syncWhatBody => 'Subscriptions, rules, settings and network profiles. Never synced: local logs, IPC tokens.';

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
  String get zapretWithVpnHint => 'Runs zapret next to the VPN tunnel: tunneled traffic uses the VPN, direct traffic goes through the bypass.';
  @override
  String get chainDuplicate => 'Each server can appear only once';
  @override
  String get edit => 'Edit';
  @override
  String get remove => 'Remove';
}
