// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class SKy extends S {
  SKy([String locale = 'ky']) : super(locale);

  @override
  String get stateOff => 'Туташкан эмес';

  @override
  String get stateConnecting => 'Туташуу';

  @override
  String get stateConnected => 'Туташкан';

  @override
  String get stateReconnecting => 'Кайра туташуу';

  @override
  String get stateDisconnecting => 'Ажыратууда';

  @override
  String get stateFailed => 'Туташкан эмес';

  @override
  String get coreMissing => 'Sora кызматы жооп бербей жатат';

  @override
  String get serverAuto => 'Эң тез';

  @override
  String get serverBypass => 'Сервер жок';

  @override
  String get addSubscription => 'Жазылууну кошуу';

  @override
  String get servers => 'Серверлер';

  @override
  String get settings => 'Орнотуулар';

  @override
  String get subscription => 'Жазылуу';

  @override
  String get subscriptionLink => 'Жазылуу шилтемеси';

  @override
  String get add => 'кошуу';

  @override
  String get refresh => 'Жаңыртуу';

  @override
  String get rename => 'Атын өзгөртүү';

  @override
  String get delete => 'Жок кылуу';

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get save => 'Сактоо';

  @override
  String get name => 'аты';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" жок кылынсынбы?';
  }

  @override
  String get routes => 'Маршруттар';

  @override
  String get presetGlobal => 'Баары VPN аркылуу';

  @override
  String get presetRu => 'Россия түз';

  @override
  String get presetIr => 'Иран түз';

  @override
  String get presetCn => 'Кытай түз';

  @override
  String get blockAds => 'Жарнамаларды бөгөттөө';

  @override
  String get killSwitch => 'Интернет VPN аркылуу гана';

  @override
  String get engine => 'Мотор';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'Анимациялар';

  @override
  String get logs => 'Log';

  @override
  String get about => 'Жөнүндө';

  @override
  String get logsAll => 'Баары';

  @override
  String get logsImportant => 'Маанилүү';

  @override
  String get logsErrors => 'Каталар';

  @override
  String get search => 'Издөө';

  @override
  String get export => 'Файлга сактоо';

  @override
  String get clear => 'Таза';

  @override
  String get logsEmpty => 'Бул жерде эч нерсе';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get notInstalled => 'Орнотулган эмес';

  @override
  String get sourceCode => 'Булак коду';

  @override
  String get license => 'Лицензия';

  @override
  String usage(String used, String total) {
    return '$total ичинен $used';
  }

  @override
  String until(String date) {
    return '$date чейин';
  }

  @override
  String get expired => 'Мөөнөтү бүттү';

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
    return '$n KB';
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
  String get errGeneric => 'Бир жерден ката кетти';

  @override
  String get errCore => 'Sora кызматы жооп бербей жатат';

  @override
  String get errAuth => 'Sora кызматына кирүү жок';

  @override
  String get errVersion => 'Sora жаңыртуу: колдонмо жана кызмат башка версиялар';

  @override
  String get errBusy => 'Күтө туруңуз, мурунку буйрук дагы эле иштеп жатат';

  @override
  String get errEngineMissing => 'Бул сервер үчүн эч кандай кыймылдаткыч табылган жок';

  @override
  String get errEngineStart => 'Мотор иштебей калды';

  @override
  String get errEngineStopped => 'Мотор токтоп калды';

  @override
  String get errTunnel => 'VPN туташуусун түзүүгө уруксат жок';

  @override
  String get errServers => 'Сервер ката менен конфигурацияланган';

  @override
  String get errNetwork => 'Серверге жете албай жатат';

  @override
  String get errTimeout => 'Сервер өз убагында жооп берген жок';

  @override
  String get errFirewall => 'VPN\'ден тышкары интернетти бөгөттөй алган жок';

  @override
  String get errSubFetch => 'Жазылуу жүктөлгөн жок';

  @override
  String get errSubFormat => 'Бул жазылуу шилтемеси эмес';

  @override
  String get errSubEmpty => 'Жазылуунун серверлери жок';

  @override
  String get errSubDuplicate => 'Бул жазылуу мурунтан эле кошулган';

  @override
  String get errSubLimit => 'Өтө көп жазылуулар';

  @override
  String get errSubScheme => 'Шилтеме https:// менен башталышы керек';

  @override
  String get errSecretStore => 'Sora сактагычы бузулган же жеткиликсиз';

  @override
  String get errNoServers => 'Туташуу үчүн жазылууну кошуңуз';

  @override
  String get exportText => 'Текст';

  @override
  String get connections => 'Байланыштар';

  @override
  String get close => 'Жабуу';

  @override
  String get chainDirect => 'Түз';

  @override
  String get chainBlocked => 'Бөгөттөлгөн';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Жарык';

  @override
  String get themeDark => 'Караңгы';

  @override
  String get language => 'Тил';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Байланыш';

  @override
  String get sectionNoServer => 'Сервер жок';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Диагностика';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Авто';

  @override
  String get dnsHint => 'Даректер, үтүр менен бөлүнгөн';

  @override
  String get fragment => 'TLS фрагментациясы';

  @override
  String get fragmentPackets => 'Эмне бөлүү керек';

  @override
  String get fragmentLength => 'Даана өлчөмү';

  @override
  String get fragmentInterval => 'Бөлүмдөрдүн ортосунда тыныгуу';

  @override
  String get byDefault => 'Демейки';

  @override
  String get rangeHint => 'Мисалы, 100-200';

  @override
  String get splitPos => 'Позицияларды бөлүү';

  @override
  String get splitPosHint => 'Мисалы, 1, midsld';

  @override
  String get disorder => 'Бөлүмдөрдү кайра иреттөө';

  @override
  String get tlsRecord => 'TLS жазуусун бөлүңүз';

  @override
  String get tlsRecordNo => 'Жок';

  @override
  String get tlsRecordSni => 'Сайттын аталышында';

  @override
  String get tlsRecordFirst => 'Биринчи байттан кийин';

  @override
  String get hostCase => 'Хосттун кейпин өзгөртүү';

  @override
  String get probeMethod => 'Метод';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Мотор аркылуу';

  @override
  String get probeConnect => 'Туташуу гана';

  @override
  String get probeUrl => 'Сыноо дареги';

  @override
  String get probeTimeout => 'Күтө тур';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Жазылуулар';

  @override
  String get subscriptionSettings => 'Орнотуулар';

  @override
  String get userAgent => 'Колдонуучу-агент';

  @override
  String get autoUpdate => 'Автоматтык түрдө жаңыртуу';

  @override
  String get updateInterval => 'Канча жолу';

  @override
  String get intervalProvider => 'Провайдер сурагандай';

  @override
  String hours(int n) {
    return '$n ч';
  }

  @override
  String get updateNow => 'Азыр жаңыртыңыз';

  @override
  String get logLevel => 'Эмне жазыш керек';

  @override
  String get levelDebug => 'Баары';

  @override
  String get levelInfo => 'Кадимки';

  @override
  String get levelWarning => 'Маанилүү';

  @override
  String get levelError => 'Каталар гана';

  @override
  String get recordDestinations => 'Сайттын даректерин жазыңыз';

  @override
  String get reset => 'Жөндөөлөрдү баштапкы абалга келтирүү';

  @override
  String get resetConfirm => 'Бардык жөндөөлөр баштапкы абалга келтирилсинби?';

  @override
  String get resetAction => 'Калыбына келтирүү';

  @override
  String get invalidValue => 'Бул маани иштебейт';

  @override
  String get website => 'Жазылуу бети';

  @override
  String get providerWebsite => 'Провайдердин веб-сайты';

  @override
  String get support => 'Колдоо';

  @override
  String controlPortQuestion(String engine) {
    return '$engine бул компьютердеги порт аркылуу башкарылат. Башка программалар VPN күйгүзүлгөнүн айта алышат.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine тандаңыз';
  }

  @override
  String get rules => 'Ыңгайлаштырылган эрежелер';

  @override
  String get ruleAdd => 'Жаңы эреже';

  @override
  String get ruleHint => 'Сайт, IP же программа';

  @override
  String get ruleDirect => 'Түз';

  @override
  String get ruleProxy => 'VPN аркылуу';

  @override
  String get ruleBlock => 'Блок';

  @override
  String get failover => 'Ката күйгүзүү';

  @override
  String get connectOnStart => 'Башында туташуу';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'жазылуу # күндөрү аяктайт',
      one: 'жазылуу # күнү аяктайт',
      zero: 'жазылуу бир нече саатта аяктайт',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left калды';
  }

  @override
  String get ruleInvalid => 'Бул сайтка, IP же программага окшош эмес';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверлери, өз кезегинде',
      one: '# сервери өз кезегинде',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# серверлери, эң ылдам',
      one: '# сервери, эң ылдам',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelTun => 'Бардык трафик';

  @override
  String get tunnelProxy => 'System прокси';

  @override
  String get proxyAddress => 'Прокси дареги';

  @override
  String get copied => 'Көчүрүлгөн';

  @override
  String get launchAtLogin => 'Системадан баштаңыз';

  @override
  String get closeToTray => 'Жабык болгондо лотокто сактаңыз';

  @override
  String get notifications => 'Эскертмелер';

  @override
  String get trayOpen => 'Sora ачыңыз';

  @override
  String get trayConnect => 'Туташуу';

  @override
  String get trayDisconnect => 'Ажыратуу';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Sora чыгуу';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora дагы эле лотокто';

  @override
  String get noticeInTrayBody => 'Анын сөлөкөтүнүн менюсунан чык';

  @override
  String get noticeLost => 'Туташуу үзүлдү';

  @override
  String get noticeLostBody => 'Sora кайра туташып жатат';

  @override
  String get noticeRestored => 'Кайра туташты';

  @override
  String get noticeFailed => 'Туташкан жок';

  @override
  String get noticeBackup => 'Негизги сервер жооп берген жок; камдык трафикти алып барат';

  @override
  String get noticeNext => 'Сервер жооп берген жок; кийинкиси трафикти алып барат';

  @override
  String get noticeMainBack => 'Негизги сервер кайра жооп берип, трафикти алып барат';

  @override
  String get noticeSubscription => 'Жазылуу';

  @override
  String get importTitle => 'Бул жазылууну кошосузбу?';

  @override
  String get importSealed =>
      'Бул шилтеме Happ үчүн шифрленген жана аны Happ гана окуй алат. Провайдериңизден жөнөкөй жазылуу шилтемесин сураңыз.';

  @override
  String get understood => 'макул';

  @override
  String get noAnswer => 'жооп жок';

  @override
  String get home => 'Үй';

  @override
  String get navRules => 'Эрежелер';

  @override
  String get navConnections => 'Байланыштар';

  @override
  String get navLogs => 'Журналдар';

  @override
  String get navAbout => 'Жөнүндө';

  @override
  String get sidebarToggle => 'Каптал тилкесин которуштуруу';

  @override
  String get more => 'Дагы';

  @override
  String get less => 'Азыраак';

  @override
  String get currentServer => 'Учурдагы сервер';

  @override
  String get trafficDown => 'Жүктөлүп алынды';

  @override
  String get trafficUp => 'Жүктөлгөн';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Активдүү эрежелер: $count';
  }

  @override
  String get recentNotifications => 'Акыркы эскертмелер';

  @override
  String get notificationsEmpty => 'Туташуу жана жазылуу окуялары бул жерде көрүнөт';

  @override
  String get retryConnect => 'Кайталануу';

  @override
  String get openLogs => 'Ачык журналдар';

  @override
  String get tourReplay => 'Жолду кайра көрсөтүү';

  @override
  String tourStep(int step) {
    return '5тин ичинен $step кадамы';
  }

  @override
  String get tourBack => 'Артка';

  @override
  String get tourNext => 'Кийинки';

  @override
  String get tourSkip => 'Өткөрүп жибер';

  @override
  String get tourFinish => 'Бүттү';

  @override
  String get tourAdd => 'Провайдериңиздин жазылуу шилтемесин кошуңуз.';

  @override
  String get tourServer => 'Серверди тандаңыз. \"Эң ылдам\" сиз үчүн бирин тандайт.';

  @override
  String get tourConnect => 'Туташуу же ажыратуу үчүн бул жерди басыңыз.';

  @override
  String get tourMode => 'Режимди тандаңыз. VPN түшүп калса, өчүрүү блокторун өлтүрүңүз.';

  @override
  String get tourSettings => 'Жөндөөлөрдү ачыңыз. Бул колдонмону ошол жерден кайталай аласыз.';

  @override
  String get chooseProgram => 'Программаны тандаңыз';

  @override
  String get installedApps => 'Орнотулган колдонмолор';

  @override
  String get runningProcesses => 'Иштеп жаткан процесстер';

  @override
  String get programsFailed => 'Тиркемелер жүктөлгөн жок';

  @override
  String get programsEmpty => 'Тиркемелер табылган жок. Башка ат колдонуп көрүңүз.';

  @override
  String get selectExe => '.exe файлын тандаңыз';

  @override
  String get trafficUnavailable => 'Эсептегичтер азырынча жеткиликтүү эмес';

  @override
  String get speedtest => 'Ылдамдык';

  @override
  String get speedtestCheck => 'Ылдамдыкты текшерүү';

  @override
  String get speedtestSearch => 'Кызматты табыңыз';

  @override
  String get speedtestEmpty => 'Дал келгендер жок. Издөөнү өзгөртүү.';

  @override
  String get speedtestBackToList => 'Кызматтарга кайтуу';

  @override
  String get speedtestOpenBrowser => 'Браузерде ачуу';

  @override
  String get speedtestUnavailable => 'Кыстарылган браузер башталбай койду. Кызматты системаңыздын браузеринде ачыңыз.';

  @override
  String get speedtestPageFailed =>
      'Барак жүктөлбөй койду. Аны кайра жүктөңүз же системаңыздын браузеринде кызматты ачыңыз.';

  @override
  String get speedtestExternalFailed => 'Системанын браузери ачылбай койду. Кайра аракет кыл.';

  @override
  String get modes => 'Режимдер';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Бардык трафик (TUN)';

  @override
  String get checkUpdates => 'Жаңыртууларды текшериңиз';

  @override
  String get updates => 'Колдонмо жаңыртуулары';

  @override
  String updateAvailable(String version) {
    return '$version версиясы жеткиликтүү';
  }

  @override
  String get updateOpenAbout => 'Жаңыртууну көрүү';

  @override
  String updateNotes(String version) {
    return '$version өзгөртүүлөр';
  }

  @override
  String get updateCheck => 'Жаңыртууларды текшериңиз';

  @override
  String get updateChecking => 'Текшерилүүдө...';

  @override
  String get updateNoNotes => 'Чыгармада эскертүүлөр жок.';

  @override
  String get updateDropWarning =>
      'Sora жана анын негизги жаңыртылышы учурунда VPN туташуусу бир нече секундага үзүлөт. Улантасызбы?';

  @override
  String get updateWaitConnection => 'VPN туташуусу жана өзөгү даяр болгуча күтө туруңуз.';

  @override
  String get updateDownloading => 'Файлдар жүктөлүп алынууда жана текшерилүүдө...';

  @override
  String get updateInstalling => 'Жаңыртуу даярдалууда же администратордун аутентификациясын күтүүдө...';

  @override
  String get updateNetworkError => 'Жаңыртуу жүктөлүп алынбай койду. Кайра аракет кыл.';

  @override
  String get updateReleaseError => 'Чыгарылган маалыматтар же талап кылынган файлдар жок же жараксыз.';

  @override
  String get updateChecksumError => 'Жүктөп алуу SHA256SUMS менен дал келбейт. Эч нерсе орнотулган эмес.';

  @override
  String get updateInstallError => 'Жаңыртуу аягына чыккан жок. Аутентификация жокко чыгарылган болушу мүмкүн.';

  @override
  String get updateUnsupported =>
      'Бул аткарылуучу файл колдоого алынган Sora пакет жупуна таандык эмес. Чыгарууну орнотуу нускамаларын колдонуңуз.';

  @override
  String get updateManual =>
      'Текшерилген эки пакетти тең орнотуу үчүн бул буйрукту терминалда иштетиңиз, андан кийин Soraди кайра ачыңыз. Файлдар жүктөө каталогунда калат. VPN байланышы үзүлөт.';

  @override
  String get updateCopyCommand => 'Көчүрүү буйругу';

  @override
  String get updateChecksDisabled => 'Автоматтык текшерүүлөр Жөндөөлөрдөн өчүрүлгөн.';

  @override
  String get updateInstalled => 'Жаңыртуу орнотулду. Sora кайра ачыңыз.';

  @override
  String get projectLinks => 'Долбоор';

  @override
  String get githubReleases => 'Чыгуулар жана жүктөөлөр';

  @override
  String get telegramChannel => 'Telegram каналы';

  @override
  String get licenses => 'Лицензиялар';

  @override
  String get componentLicenses => 'Компоненттик лицензиялар';

  @override
  String get appCopyright => '© 2026 levvs-one жана салым кошкондор';

  @override
  String get collapseServers => 'Серверлерди жыйыштыруу';

  @override
  String get expandServers => 'Серверлерди кеңейтүү';

  @override
  String get hideDescription => 'Сүрөттөмөлөрдү жашыруу';

  @override
  String get showDescription => 'Сүрөттөмөлөрдү көрсөтүү';

  @override
  String get pendingConnectionChanges => 'Бул өзгөртүүлөрдү колдонуу үчүн кайра туташыңыз.';

  @override
  String get reconnectNow => 'Колдонуу жана кайра туташтыруу';

  @override
  String get bypassLimitations =>
      'Бул режим DPI\'ди HTTP жана TLS үчүн гана айланып өтөт, UDP\'ди колдобойт же IPиңизди өзгөртпөйт. Discord үн, чалуулар жана бөгөттөлгөн Telegram даректери үчүн VPN серверин колдонуңуз.';

  @override
  String get errEngineUnsupported =>
      'Тандалган кыймылдаткыч бул профилди же жөндөөлөрдү колдоого албайт. Авто же туура келген кыймылдаткычты тандаңыз.';

  @override
  String get errRestore => 'Туташуу тазаланбай калды. Кайра ажыратып көрүңүз; чоо-жайын билүү үчүн журналды карагыла.';

  @override
  String get errSessionEnded => 'Бул сессия эбак эле аяктаган. Туташуу абалын жаңыртуу.';

  @override
  String get retryDisconnect => 'Ажыратып көрүңүз';

  @override
  String get tunStack => 'TUN стек';

  @override
  String get modesInfo => 'Режимдер жөнүндө';

  @override
  String get modesGuideTitle => 'Режимдер жана кыймылдаткычтар';

  @override
  String get modesGuide =>
      'Сервериңизге кайсы кыймылдаткыч керек экенин билбей жатсаңыз, Auto тандаңыз. Sora туташуудан мурун профилди жана орнотууларды текшерет. Кыймылдаткыч планыңыздын өткөрүү жөндөмдүүлүгүн жогорулата албайт: аткаруу серверге, маршрутка, протоколго жана тармакка жараша болот.\n\n## Режимдер\n\n### Бардык трафик (TUN)\n\nSora виртуалдык тармак интерфейсин түзөт жана ал аркылуу тиркеме трафигин, анын ичинде TCP жана UDP багыттарын түзөт. Бул режимди Telegram, оюндар жана Discord үнү үчүн колдонуңуз. Эрежелер конкреттүү сайттарды же программаларды түз жөнөтө алат же аларды бөгөттөй алат. Тармак кызматына уруксат жана талап кылынган протоколду колдогон сервер керек.\n\n### System прокси\n\nSora жергиликтүү HTTP/SOCKS проксисин конфигурациялайт. Системанын прокси жөндөөлөрүн сыйлаган колдонмолор аны колдонушат. Өзүнүн тармактык стеки бар тиркемелер түздөн-түз туташа алат; UDP жана үн чалуулар көбүнчө TUN керек. Бул режим прокси колдоосу менен браузерлерге жана тиркемелерге ылайыктуу.\n\n### Сервер жок\n\nLinuxде Sora [zapret](https://github.com/bol-van/zapret) HTTP/TLS сурамдарын бөлүү жана формасын өзгөртүү жана кээ бир DPI текшерүүлөрүн айланып өтүү үчүн колдонот. Сиздин IP ошол эле бойдон калат жана байланыштар түздөн-түз веб-сайтка кирет. Натыйжалар провайдериңизге жана бөгөттөө ыкмасына жараша болот.\n\nУчурдагы интеграция TCP аркылуу HTTP жана TLS үчүн tpws колдонот. Ал IP бөгөттөөнү кыйгап өтпөйт же UDP релесин өткөрбөйт жана Telegramтин MTProto туташууларына кепилдик бере албайт. Discord үн, Telegram чалуулары жана ушул сыяктуу чектөөлөр үчүн TUN менен VPN серверин колдонуңуз.\n\n## Моторлор\n\n### Авто\n\nSora бүт туташуунун планын колдогон орнотулган кыймылдаткычты тандайт: сервердик протоколдор, транспорттор, топтор, фрагментация жана режим. Учурдагы туташууну токтотуунун алдында кол менен шайкеш келбеген тандоо четке кагылат. Авто же башка кыймылдаткычты тандап, орнотууларды кайра колдонуңуз.\n\n### sing-box\n\nЖаңы Sora топтомдору [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) айрысын камтыйт, ага кардар тараптагы XHTTP жана VLESS Encryption кошулат. Sora курууну жана анын мүмкүнчүлүктөрүн тааныйт. XHTTP жок жогорудагы курулуш бул мүмкүнчүлүктү өзүнүн атынан эле ала албайт.\n\nVLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard протоколдору жана Sora импорттой алган AmneziaWG 1.x/2.x параметрлери колдоого алынат. Толук Xray JSON профилдери үчүн Xray керек. Жаңы AWG 3.x талааларын азырынча импорттоо мүмкүн эмес. sing-box сырсөз менен корголгон жергиликтүү башкаруу портун колдонот; компьютердеги башка колдонмолор ал портту аныктай алат.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption жана TLS фрагментациясын колдойт. Ал ошондой эле Xray провайдеринин толук профилдерин иштетип, алардын маршруттарын жана топторун сактап калат. Мындай профилдерди алардын жүрүм-турумун өзгөртпөстөн автоматтык түрдө башка кыймылдаткычка айландыруу мүмкүн эмес.\n\nТоптолгон Xray TLS тастыктамасын текшерүүнү (`allowInsecure`) өчүргөн жөндөөнү алып салды. Бул жөндөөнү талап кылган жөнөкөй серверлер үчүн автоматтык түрдө sing-box же mihomo тандайт. Xray тандалса, учурдагы туташууну токтотуудан мурун дал келбестикти кол менен кабарлайт. Эски толук JSON профилдерине текшерилүүчү тастыктама же тастыктама пин коду менен жаңыртылган провайдер профили керек.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) буйрутмаланган кайра кайтаруу жана жүктү тең салмактоо топторун, XHTTP жана AmneziaWG колдойт. Камдык серверге автоматтык түрдө өтүү маанилүү болгондо аны тандаңыз. Sora анын TLS фрагментация жөндөөсү бул кыймылдаткычта жеткиликсиз.\n\n## Sora ичинде шайкештик\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN жана TCP/UDP | Ооба | Ооба | Ооба |\n| XHTTP | Ооба | Ооба | Ооба |\n| VLESS Encryption | Ооба | Ооба | Ооба |\n| Толук Xray профили | Жок | Ооба | Жок |\n| TUIC / AnyTLS | экөө | Жок | TUIC |\n| TLS фрагментация | Ооба | Ооба | Жок |\n| AmneziaWG 1.x/2.x | Ооба¹ | Жок | Ооба |\n| Заказ кылынган кайра топ | Жок | No² | Ооба |\n\n¹ J1/J2/J3/Itime менен профилдер mihomo колдонот; бул талаалар эч качан унчукпай ташталбашы керек. ² Толук Xray профилдер тобу үчүн колдонмо камдык профилди тандайт. Колдоо орнотулган курууга көз каранды; жөнүндө анын версиясын текшерүү.\n\n## TUN стек\n\nСтек виртуалдык интерфейстин ичинде TCP жана UDP иштетет. Режимдер панелинде Xray жана mihomo gVisor, System, Mixed жана MIPS сунуштайт. Ар бир кыймылдаткыч өзүнүн артыкчылыктарын сактайт. System прокси жана серверсиз режимдер бул артыкчылыкты колдонушпайт.\n\n- **Mixed** — TCP тутум стекин колдонот, ал эми gVisor UDP менен иштейт. Бул Linux системасында mihomo үчүн демейки вариант. Windows системасында Xray жана mihomo демейки боюнча MIPS колдонот.\n- **System** — система стекин колдонот. Тармак колдонмолору көйгөйлөргө туш болсо, башка жолду байкап көрүңүз.\n- **gVisor** — колдонуучулар мейкиндигинде трафикти башкарат.\n- **MIPS** — mihomoдин өзүнүн IP стеки, топтомдогу 1.19.32 версиясында жеткиликтүү.\n\nLinuxде, Xray демейки боюнча орнотулган gVisor колдонот. Linuxдеги System, Mixed жана MIPS mihomoди TUN кыймылдаткычы катары колдонушат, TCP жана UDP аныктыгын текшерилген жергиликтүү SOCKS шилтемеси аркылуу Xrayга жөнөтөт. Xray протоколду, провайдердин профилин жана маршрутту сактайт. Бул үч параметр орнотулган mihomo талап кылат. Windows боюнча Xray төрт TUN стегинин баары үчүн mihomo 1.19.32 же жаңы версиясын колдонот. Протоколдор жана маршруттоо Xray ичинде калат. Бул айкалышта колдонмо эрежелери түз туташууну жана бөгөттөөнү гана колдойт; Linux ичинде бул эрежелер Xray камтылган gVisor стегин талап кылат.\n\nКөпүрө экинчи процессти жүргүзөт. Linux боюнча үч ишсиз өлчөөдө ал жергиликтүү Xray TUNга караганда 32–36 МБ көбүрөөк физикалык эстутумду колдонду. Бул жүктөө жүгүн өлчөбөйт: CPU жана эстутум баалары туташуулардан көз каранды. sing-box стек селектору жок. Эч кандай стек ар бир тармакта жакшыраак иштөөгө кепилдик бербейт. Стекти тандап, аны тармагыңызда сынап көрүү үчүн Колдонуу жана кайра туташууну тандаңыз.\n\n## Орнотуулар колдонулууда\n\nСерверди тандоо автоматтык түрдө кайра туташат. Режим, кыймылдаткыч, DNS жана эреже жөндөөлөрү дароо сакталат; активдүү туташуу учурунда Колдонуу баскычын чыкылдатып, аларды колдонуу үчүн кайра туташуу. Кыймылдаткычты кайра иштетүү жүктөп алууларды жана чалууларды үзгүлтүккө учуратышы мүмкүн. Кайталанган чыкылдатуулар параллелдүү байланыштарды баштабайт; ажыратуу өтүүнү аяктайт жана байланышты бошотот.\n\nVPN аркылуу гана Интернет туннель кулаганда түз трафикти бөгөттөйт. Бул бүт машинага таасир этет. Ачык ажыратуу Sora эрежелерин алып салат. Тазалоо бүтпөсө, кайра ажыратып көрүңүз жана журналды ачыңыз.\n\n## Долбоордук документтер\n\n- [sing-box-lx: конфигурация жана колдоо](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box документтери](https://sing-box.sagernet.org/)\n- [Xray документтери](https://xtls.github.io/)\n- [mihomo документтери](https://wiki.metacubex.one/)\n- [zapret: операция жана чектөөлөр](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Серверлерди текшерүү';

  @override
  String get extensions => 'Кеңейтүүлөр';
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
    return 'Файлга $name';
  }

  @override
  String get diagnosticHttp => 'HTTP диагностикасы';

  @override
  String get diagnosticPackets => 'Пакетти басып алуу';

  @override
  String get diagnosticEvents => 'Windows окуялары';

  @override
  String get diagnosticCapture => '10 секундга тартыңыз';

  @override
  String get diagnosticNoData => 'Жазылган сурамдар азырынча жок. Адегенде ылдамдыкты текшерүү вебсайтын ачыңыз.';

  @override
  String get diagnosticRequiresTun => 'Пакетти тартууга активдүү Sora TUN байланышы керек.';

  @override
  String get diagnosticUnavailable => 'Бул диагностика бул платформада жеткиликсиз.';
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
  String get updateStageVerify => 'Verifying';
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
  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';
  @override
  String get autoSwitchOnDegradeDetail => 'If the pinned server stops answering or gets clearly slower, switch to the best measured alternative — at most once every 10 minutes.';
  @override
  String get tunStackMixed => 'Mixed';
  @override
  String get tunStackSystem => 'System';
}
