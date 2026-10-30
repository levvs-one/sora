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
  String get connEmpty => 'Туташуулар жок';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get notInstalled => 'Орнотулган эмес';

  @override
  String get sourceCode => 'Булак коду';

  @override
  String get reportProblem => 'Көйгөй тууралуу билдирүү';

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
  String get errAuth => 'Sora кызматына кирүүгө уруксат жок';

  @override
  String get errVersion => 'Sora колдонмосу менен кызматынын версиялары ар башка';

  @override
  String get errBusy => 'Мурунку буйрук дагы эле аткарылып жатат';

  @override
  String get errEngineMissing => 'Бул серверге керектүү өзөк табылган жок';

  @override
  String get errEngineStart => 'Өзөк ишке кирген жок';

  @override
  String get errEngineStopped => 'Өзөк токтоду';

  @override
  String get errTunnel => 'Бул VPN режими жеткиликсиз';

  @override
  String get errTimeout => 'Сервер өз убагында жооп берген жок';

  @override
  String get errFirewall => 'VPN тышындагы интернетке кирүүнү бөгөттөө мүмкүн болгон жок';

  @override
  String get errSubFetch => 'Жазылууну жүктөө мүмкүн болгон жок';

  @override
  String get deviceIdentity => 'Түзмөктүн идентификатору';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Идентификаторду жаңылоо';

  @override
  String get deviceIdentityResetConfirm => 'Түзмөктүн идентификаторун жаңылайсызбы?';

  @override
  String get errSubDeviceLimit => 'Түзмөктөрдүн чеги ашты';

  @override
  String get errSubDeviceRequired => 'Провайдер түзмөктүн идентификаторун талап кылат';

  @override
  String get errSubFormat => 'Жазылуунун форматы таанылган жок';

  @override
  String get errSubEmpty => 'Жазылууда серверлер жок';

  @override
  String get errSubDuplicate => 'Бул жазылуу мурун эле кошулган';

  @override
  String get errSubLimit => 'Жазылуулардын саны чегине жетти';

  @override
  String get errSubScheme => 'Жазылуу шилтемесинин схемасы колдоого алынбайт';

  @override
  String get errSecretStore => 'Sora сактагычы бузулган же жеткиликсиз';

  @override
  String get errNoServers => 'Туташуу үчүн серверлер жок';

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
  String get themeSystem => 'Системадагыдай';

  @override
  String get themeLight => 'Жарык';

  @override
  String get themeDark => 'Караңгы';

  @override
  String get language => 'Тил';

  @override
  String get languageSystem => 'Системадагыдай';

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
  String get splitPos => 'Позицияларды бөлүү';

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
      other: 'жазылуу $days күндөрү аяктайт',
      one: 'жазылуу $days күнү аяктайт',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count серверлери, эң ылдам',
      one: '$count сервери, эң ылдам',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

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
  String get importSealed => 'Бул шилтеме Happ үчүн шифрленген жана аны Happ гана окуй алат';

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
  String get notificationsEmpty => 'Билдирмелер жок';

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
  String get programsEmpty => 'Тиркемелер табылган жок';

  @override
  String get selectExe => '.exe файлын тандаңыз';

  @override
  String get speedtest => 'Ылдамдык';

  @override
  String get speedtestSearch => 'Кызматты табыңыз';

  @override
  String get speedtestEmpty => 'Дал келгендер жок';

  @override
  String get speedtestBackToList => 'Кызматтарга кайтуу';

  @override
  String get speedtestOpenBrowser => 'Браузерде ачуу';

  @override
  String get speedtestUnavailable => 'Кыстарылган браузер башталбай койду';

  @override
  String get speedtestPageFailed => 'Барак жүктөлбөй койду';

  @override
  String get speedtestExternalFailed => 'Системанын браузери ачылбай койду';

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
  String get updateDropWarning => 'Жаңыртуу үчүн туташууну үзөлүбү?';

  @override
  String get updateWaitConnection => 'Туташуу даяр эмес';

  @override
  String get updateDownloading => 'Файлдар жүктөлүп алынууда жана текшерилүүдө...';

  @override
  String get updateInstalling => 'Жаңыртуу даярдалууда же администратордун аутентификациясын күтүүдө...';

  @override
  String get updateNetworkError => 'Жаңыртуу жүктөлүп алынбай койду';

  @override
  String get updateReleaseError => 'Чыгарылган маалыматтар же талап кылынган файлдар жок же жараксыз.';

  @override
  String get updateChecksumError => 'Жүктөп алуу SHA256SUMS менен дал келбейт';

  @override
  String get updateInstallError => 'Жаңыртуу аягына чыккан жок';

  @override
  String get updateUnsupported => 'Бул аткарылуучу файл колдоого алынган Sora пакет жупуна таандык эмес';

  @override
  String get updateManual =>
      'Текшерилген эки пакетти тең орнотуу үчүн бул буйрукту терминалда иштетиңиз, андан кийин Soraди кайра ачыңыз. Файлдар жүктөө каталогунда калат. VPN байланышы үзүлөт.';

  @override
  String get updateVersionRevoked => 'Иштеп чыгуучу бул версияны алып салды';

  @override
  String get updateRolloutPending =>
      'Жаңыраак версия акырындык менен чыгарылып жатат жана сизге автоматтык түрдө сунушталат.';

  @override
  String updateRollbacking(String version) {
    return '$version версиясына кайтуу...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version жаңыртуусу ден соолук текшерүүсүнөн өткөн жок, андыктан Sora кайра $fromVersion га жылдырылды.';
  }

  @override
  String get updateRollbackError => 'Автоматтык артка кайтаруу ишке ашкан жок';

  @override
  String get updateRollbackCacheError =>
      'Учурдагы версиянын текшерилген артка кайтарылган көчүрмөсүн даярдай алган жок, андыктан жаңыртуу орнотулган эмес.';

  @override
  String get updateCopyCommand => 'Көчүрүү буйругу';

  @override
  String get updateChecksDisabled => 'Автоматтык текшерүүлөр Жөндөөлөрдөн өчүрүлгөн.';

  @override
  String get updateInstalled => 'Жаңыртуу орнотулду';

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
  String get collapseServers => 'Серверлерди жыйыштыруу';

  @override
  String get expandServers => 'Серверлерди кеңейтүү';

  @override
  String get hideDescription => 'Сүрөттөмөлөрдү жашыруу';

  @override
  String get showDescription => 'Сүрөттөмөлөрдү көрсөтүү';

  @override
  String get errEngineUnsupported => 'Тандалган кыймылдаткыч бул профилди же жөндөөлөрдү колдоого албайт';

  @override
  String get errRestore => 'Туташуу тазаланбай калды';

  @override
  String get errSessionEnded => 'Бул сессия эбак эле аяктаган';

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
      'Сервериңизге кайсы кыймылдаткыч керек экенин билбей жатсаңыз, Auto тандаңыз. Sora туташуудан мурун профилди жана орнотууларды текшерет. Кыймылдаткыч планыңыздын өткөрүү жөндөмдүүлүгүн жогорулата албайт: аткаруу серверге, маршрутка, протоколго жана тармакка жараша болот.\n\n## Режимдер\n\n### Бардык трафик (TUN)\n\nSora виртуалдык тармак интерфейсин түзөт жана ал аркылуу тиркеме трафигин, анын ичинде TCP жана UDP багыттарын түзөт. Бул режимди Telegram, оюндар жана Discord үнү үчүн колдонуңуз. Эрежелер конкреттүү сайттарды же программаларды түз жөнөтө алат же аларды бөгөттөй алат. Тармак кызматына уруксат жана талап кылынган протоколду колдогон сервер керек.\n\n### System прокси\n\nSora жергиликтүү HTTP/SOCKS проксисин конфигурациялайт. Системанын прокси жөндөөлөрүн сыйлаган колдонмолор аны колдонушат. Өзүнүн тармактык стеки бар тиркемелер түздөн-түз туташа алат; UDP жана үн чалуулар көбүнчө TUN керек. Бул режим прокси колдоосу менен браузерлерге жана тиркемелерге ылайыктуу.\n\n### Сервер жок\n\nLinuxде Sora [zapret](https://github.com/bol-van/zapret) HTTP/TLS сурамдарын бөлүү жана формасын өзгөртүү жана кээ бир DPI текшерүүлөрүн айланып өтүү үчүн колдонот. Сиздин IP ошол эле бойдон калат жана байланыштар түздөн-түз веб-сайтка кирет. Натыйжалар провайдериңизге жана бөгөттөө ыкмасына жараша болот.\n\nУчурдагы интеграция TCP аркылуу HTTP жана TLS үчүн tpws колдонот. Ал IP бөгөттөөнү кыйгап өтпөйт же UDP релесин өткөрбөйт жана Telegramтин MTProto туташууларына кепилдик бере албайт. Discord үн, Telegram чалуулары жана ушул сыяктуу чектөөлөр үчүн TUN менен VPN серверин колдонуңуз.\n\n## Моторлор\n\n### Авто\n\nSora бүт туташуунун планын колдогон орнотулган кыймылдаткычты тандайт: сервердик протоколдор, транспорттор, топтор, фрагментация жана режим. Учурдагы туташууну токтотуунун алдында кол менен шайкеш келбеген тандоо четке кагылат. Авто же башка кыймылдаткычты тандап, орнотууларды кайра колдонуңуз.\n\n### sing-box\n\nЖаңы Sora топтомдору [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) айрысын камтыйт, ага кардар тараптагы XHTTP жана VLESS Encryption кошулат. Sora курууну жана анын мүмкүнчүлүктөрүн тааныйт. XHTTP жок жогорудагы курулуш бул мүмкүнчүлүктү өзүнүн атынан эле ала албайт.\n\nVLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard протоколдору жана Sora импорттой алган AmneziaWG 1.x/2.x параметрлери колдоого алынат. Толук Xray JSON профилдери үчүн Xray керек. Жаңы AWG 3.x талааларын азырынча импорттоо мүмкүн эмес. sing-box сырсөз менен корголгон жергиликтүү башкаруу портун колдонот; компьютердеги башка колдонмолор ал портту аныктай алат.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption жана TLS фрагментациясын колдойт. Ал ошондой эле Xray провайдеринин толук профилдерин иштетип, алардын маршруттарын жана топторун сактап калат. Мындай профилдерди алардын жүрүм-турумун өзгөртпөстөн автоматтык түрдө башка кыймылдаткычка айландыруу мүмкүн эмес.\n\nТоптолгон Xray TLS тастыктамасын текшерүүнү (`allowInsecure`) өчүргөн жөндөөнү алып салды. Бул жөндөөнү талап кылган жөнөкөй серверлер үчүн автоматтык түрдө sing-box же mihomo тандайт. Xray тандалса, учурдагы туташууну токтотуудан мурун дал келбестикти кол менен кабарлайт. Эски толук JSON профилдерине текшерилүүчү тастыктама же тастыктама пин коду менен жаңыртылган провайдер профили керек.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) буйрутмаланган кайра кайтаруу жана жүктү тең салмактоо топторун, XHTTP жана AmneziaWG колдойт. Камдык серверге автоматтык түрдө өтүү маанилүү болгондо аны тандаңыз. Sora анын TLS фрагментация жөндөөсү бул кыймылдаткычта жеткиликсиз.\n\n## Sora ичинде шайкештик\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN жана TCP/UDP | Ооба | Ооба | Ооба |\n| XHTTP | Ооба | Ооба | Ооба |\n| VLESS Encryption | Ооба | Ооба | Ооба |\n| Толук Xray профили | Жок | Ооба | Жок |\n| TUIC / AnyTLS | экөө | Жок | TUIC |\n| mieru | Жок | Жок | Ооба |\n| NaiveProxy | Ооба | Жок | Жок |\n| TLS фрагментация | Ооба | Ооба | Жок |\n| AmneziaWG 1.x/2.x | Ооба¹ | Жок | Ооба |\n| Заказ кылынган кайра топ | Жок | No² | Ооба |\n\n¹ J1/J2/J3/Itime менен профилдер mihomo колдонот; бул талаалар эч качан унчукпай ташталбашы керек. ² Толук Xray профилдер тобу үчүн колдонмо камдык профилди тандайт. Колдоо орнотулган курууга көз каранды; жөнүндө анын версиясын текшерүү.\n\n## TUN стек\n\nСтек виртуалдык интерфейстин ичинде TCP жана UDP иштетет. Режимдер панелинде Xray жана mihomo gVisor, System, Mixed жана MIPS сунуштайт. Ар бир кыймылдаткыч өзүнүн артыкчылыктарын сактайт. System прокси жана серверсиз режимдер бул артыкчылыкты колдонушпайт.\n\n- **Mixed**: TCP тутум стекин колдонот, ал эми gVisor UDP менен иштейт. Бул Linux системасында mihomo үчүн демейки вариант. Windows системасында Xray жана mihomo демейки боюнча MIPS колдонот.\n- **System**: система стекин колдонот. Тармак колдонмолору көйгөйлөргө туш болсо, башка жолду байкап көрүңүз.\n- **gVisor**: колдонуучулар мейкиндигинде трафикти башкарат.\n- **MIPS**: mihomoдин өзүнүн IP стеки, топтомдогу 1.19.32 версиясында жеткиликтүү.\n\nLinuxде, Xray демейки боюнча орнотулган gVisor колдонот. Linuxдеги System, Mixed жана MIPS mihomoди TUN кыймылдаткычы катары колдонушат, TCP жана UDP аныктыгын текшерилген жергиликтүү SOCKS шилтемеси аркылуу Xrayга жөнөтөт. Xray протоколду, провайдердин профилин жана маршрутту сактайт. Бул үч параметр орнотулган mihomo талап кылат. Windows боюнча Xray төрт TUN стегинин баары үчүн mihomo 1.19.32 же жаңы версиясын колдонот. Протоколдор жана маршруттоо Xray ичинде калат. Бул айкалышта колдонмо эрежелери түз туташууну жана бөгөттөөнү гана колдойт; Linux ичинде бул эрежелер Xray камтылган gVisor стегин талап кылат.\n\nКөпүрө экинчи процессти жүргүзөт. Linux боюнча үч ишсиз өлчөөдө ал жергиликтүү Xray TUNга караганда 32–36 МБ көбүрөөк физикалык эстутумду колдонду. Бул жүктөө жүгүн өлчөбөйт: CPU жана эстутум баалары туташуулардан көз каранды. sing-box стек селектору жок. Эч кандай стек ар бир тармакта жакшыраак иштөөгө кепилдик бербейт.\n\n## Орнотуулар колдонулууда\n\nСервер тандалганда байланыш автоматтык түрдө кайра түзүлөт. Режимге, ядрого, DNS же эрежелерге киргизген өзгөртүүлөрүңүз кыска тыныгуудан кийин автоматтык кайра туташуу менен бир жолу колдонулат; фондогу жаңыртуулар VPNди кайра туташтырбайт. Ядрону кайра иштетүү жүктөөлөрдү жана чалууларды үзүшү мүмкүн.\n\nVPN аркылуу гана Интернет туннель кулаганда түз трафикти бөгөттөйт. Бул бүт машинага таасир этет. Ачык ажыратуу Sora эрежелерин алып салат. Тазалоо бүтпөсө, кайра ажыратып көрүңүз жана журналды ачыңыз.\n\n## Долбоордук документтер\n\n- [sing-box-lx: конфигурация жана колдоо](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box документтери](https://sing-box.sagernet.org/)\n- [Xray документтери](https://xtls.github.io/)\n- [mihomo документтери](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: операция жана чектөөлөр](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP трафигин Jitsi, Яндекс Телемост же WB Stream видео чалуусу аркылуу өткөрөт. olcrtc:// шилтемесин же QR кодун импорттоңуз. Прокси жана TUN режимдеринде sing-box, Xray жана mihomo менен иштейт; UDP колдоого алынбайт. Эки тарапка тең шайкеш OLC2 түзүлүштөрү керек. Баштапкы долбоор архивделген.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Кеңейтүүлөр';

  @override
  String extRatingLabel(String rating) {
    return 'Рейтинг $rating ичинен 5';
  }

  @override
  String extByAuthor(String author) {
    return '$author тарабынан';
  }

  @override
  String extInstallsCount(String count) {
    return 'Орнотуулар: $count';
  }

  @override
  String get extInstallOne => '1 орнотуу';

  @override
  String get extSideloadWarning => 'Өзү кол койгон ачкыч';

  @override
  String get extPermissionsWidened => 'Жаңыртуу жаңы уруксаттарды сурайт:';

  @override
  String get extInstall => 'Орнотуу';

  @override
  String get extUpdate => 'Жаңыртуу';

  @override
  String get extCancel => 'Жокко чыгаруу';

  @override
  String get extConfirm => 'Ырастоо';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Орнотулган кеңейтүүлөр';

  @override
  String get extSearchHint => 'Кеңейтүүлөрдү издөө';

  @override
  String get extCatAll => 'Баары';

  @override
  String get extCatTools => 'Куралдар';

  @override
  String get extCatThemes => 'Темалар';

  @override
  String get extCatAutomation => 'Автоматташтыруу';

  @override
  String get extCatStats => 'Статистика';

  @override
  String get extCatNetwork => 'Тармак';

  @override
  String get extSortBy => 'Сорттоо боюнча';

  @override
  String get extSortPopular => 'Эң популярдуу';

  @override
  String get extSortRating => 'Эң жогорку баа';

  @override
  String get extSortName => 'Аты-жөнү';

  @override
  String get extCatalogError => 'Каталог жүктөлгөн жок';

  @override
  String get extRetry => 'Кайталап көрүңүз';

  @override
  String get extEmptySearch => 'Эч нерсе табылган жок';

  @override
  String get extEmptyInstalled => 'Азырынча кеңейтүүлөр орнотулган эмес';

  @override
  String get extInstallFromFile => 'Файлдан орнотуу';

  @override
  String get extInstallFromUrl => 'URL баштап орнотуу';

  @override
  String get extDownload => 'Жүктөп алуу';

  @override
  String get extDownloading => 'Жүктөлүүдө…';

  @override
  String get extVerifying => 'Текшерилүүдө…';

  @override
  String get extInstalling => 'Орнотулууда…';

  @override
  String get extErrSignature => 'Кол коюу текшерилбей калды';

  @override
  String get extErrManifest => 'Кеңейтүү манифести жараксыз.';

  @override
  String get extErrNetwork => 'Тармак катасы';

  @override
  String get extErrHash => 'Жүктөө каталогго дал келбейт';

  @override
  String extErrMinApp(String version) {
    return 'Бул кеңейтүү колдонмонун $version же андан жаңыраак версиясын талап кылат.';
  }

  @override
  String get extErrHttpsOnly => 'https:// шилтемелерге гана уруксат берилет';

  @override
  String get extErrGeneric => 'Бир жерден ката кетти';

  @override
  String get extErrAuthorKeyChanged =>
      'Бул жаңыртууга орнотулган версияга караганда башка автор ачкычы менен кол коюлган, андыктан ал бөгөттөлгөн';

  @override
  String get extDisabled => 'Өчүк';

  @override
  String extToggleEnabled(String name) {
    return 'Иштетүү $name';
  }

  @override
  String get extSearchInstalled => 'Орнотулган кеңейтүүлөрдү издөө';

  @override
  String get extUpdateAll => 'Баарын жаңыртуу';

  @override
  String extUpdatesAvailable(int count) {
    return '$count жаңыртуулар жеткиликтүү';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count жаңыртылды';
  }

  @override
  String get extRiskNormal => 'Кадимки';

  @override
  String get extRiskSensitive => 'Сезимтал';

  @override
  String get extRiskDangerous => 'Жогорку тобокелдик';

  @override
  String get extPermissionsRemoved => 'Мындан ары суралбайт:';

  @override
  String get extUpdateFailedKept => 'Мурунку версия дагы эле орнотулган.';

  @override
  String get extConflictsTitle => 'Кеңейтүү боюнча карама-каршылыктар';

  @override
  String get extConflictTheme => 'Колдонмо темасы';

  @override
  String get extConflictNetHooks => 'Тармак илгичтери';

  @override
  String extConflictWinner(String name) {
    return 'Артыкчылык: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'Кеңейтүү боюнча карама-каршылыктар: $count';
  }

  @override
  String get extConflictsResolve => 'Конфликттерди чечүү';

  @override
  String extVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get extPermissionsTitle => 'Уруксаттар';

  @override
  String get extNoPermissions => 'Атайын уруксаттар жок.';

  @override
  String get extSettings => 'Орнотуулар';

  @override
  String get extSaveSettings => 'Орнотууларды сактоо';

  @override
  String extUpdateTo(String version) {
    return '$version чейин жаңыртуу';
  }

  @override
  String get extEnabled => 'Күйүк';

  @override
  String extRollbackTo(String version) {
    return 'Артка $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version версиясына кайтуубу?';
  }

  @override
  String get extUninstall => 'Uninstall';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” жана анын жөндөөлөрү алынып салынсынбы?';
  }

  @override
  String get extPanelUnavailable => 'Кеңейтүүнүн панели жеткиликсиз.';

  @override
  String get extPermConnectionsRead => 'Жигердүү байланыштардын тизмесин караңыз';

  @override
  String get extPermServersRead => 'Серверлериңиздин тизмесин караңыз';

  @override
  String get extPermSettingsRead => 'Колдонмонун жөндөөлөрүн окуу';

  @override
  String get extPermSettingsWrite => 'Колдонмонун жөндөөлөрүн өзгөртүү';

  @override
  String get extPermNotifications => 'Эскертмелерди көрсөтүү';

  @override
  String get extPermTray => 'Науалар менюсуна нерселерди кошуңуз';

  @override
  String get extPermUiPanel => 'Колдонмонун ичиндеги панелдерди көрсөтүү';

  @override
  String get extPermThemeApply => 'Темаларды колдонуңуз';

  @override
  String get extPermRoutingRules => 'Маршрутизация эрежелерин кошуу';

  @override
  String get extPermNetHooks => 'Тармак жолуна интеграциялоо';

  @override
  String get extPermNetFetch => 'Уруксат берилген тизмеден URL сураңыз';

  @override
  String get extPermBackground => 'Фондук тапшырмаларды иштетүү';

  @override
  String get extPermNotYetActive => 'Өчүк';

  @override
  String get extCapBackground => 'Фондо иштейт';

  @override
  String get extCapNetHook => 'Бөгөттөрдү айланып өтүү жана тармак илгичтери';

  @override
  String get extCapPanel => 'Интерфейс панелдери';

  @override
  String get extCapRouting => 'Маршрутизация эрежелери';

  @override
  String get extCapTheme => 'Темалар';

  @override
  String get extCapWidget => 'Виджеттер';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Өзгөртүү журналы';

  @override
  String get extImageFailed => 'Сүрөт жүктөлгөн жок';

  @override
  String get extScreenshots => 'Скриншоттор';

  @override
  String get extSortRelevance => 'актуалдуулугу';

  @override
  String get extBgTitle => 'Фондук тапшырма';

  @override
  String get extBgEnabled => 'Фондо иштетүү';

  @override
  String get extBgInterval => 'Иштетүү аралыгы';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count мүнөт', one: '$count мүнөт');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count саат', one: '$count саат');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Тармакка кирүү';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Тармак: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Файлга $name';
  }

  @override
  String get diagnosticHttp => 'HTTP диагностикасы';

  @override
  String get diagnosticNoData => 'Жазылган сурамдар азырынча жок';

  @override
  String get qrShareTitle => 'QR кодун бөлүшүү';

  @override
  String get qrScanTitle => 'QR кодун сканерлеңиз';

  @override
  String get qrCopyLink => 'Шилтемени көчүрүү';

  @override
  String get qrWarning => 'Кодду ишенген адамдарга гана көрсөтүңүз.';

  @override
  String get qrFromClipboard => 'Алмашуу буферинен чаптоо';

  @override
  String get qrNoCode => 'Бул сүрөттөн QR код табылган жок.';

  @override
  String get qrInvalid => 'Бул QR кодунда жарактуу шилтеме жок.';

  @override
  String get qrScan => 'Скандоо QR';

  @override
  String get qrFromImage => 'Сүрөттү ачуу';

  @override
  String get connGroupByProcess => 'Процесс боюнча топтоо';

  @override
  String get connListView => 'Тизме';

  @override
  String get connCopyHost => 'Хостту көчүрүү';

  @override
  String get connAddRule => 'Эреже кошуу';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count туташуу', one: '$count туташуу');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Алдын ала коюлган';

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
  String get dnsCheck => 'Маалыматтын агып кетишин текшериңиз';

  @override
  String get dnsChecking => 'Текшерилүүдө...';

  @override
  String get dnsNoLeak => 'Агышуу табылган жок';

  @override
  String get dnsLeakFound => 'агып кетүү аныкталды';

  @override
  String get dnsLastCheck => 'Акыркы текшерүү';

  @override
  String get dnsNeverChecked => 'Азырынча текшериле элек';

  @override
  String get dnsLeakCheckTunnelDns => 'Туннелдин DNS резолверлери';

  @override
  String get dnsLeakCheckSystemResolvers => 'Системалык резолверлер';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Тармак бөгөтүнүн DNS коргоосу';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Туннелдин DNS конфигурациясын жогорудагы DNS жөндөөлөрүндө.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Туннелдин сыртында тутумуңуз кайсы чечүүчүлөрдү колдоноорун текшериңиз.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS трафиги туннелде калышы үчүн тармак бөгөтүн күйгүзүңүз.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Системанын шифрленген DNS кызматы';

  @override
  String get dnsLeakCheckDnsSpoof => 'Жасалма DNS жооптор';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Туннелдин сыртында тутумуңуз кайсы шифрленген DNS акыркы чекиттерин колдоноорун текшериңиз.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Резолверлер жоопторду жасалмалай албашы үчүн туннелде шифрленген DNS (DoT же DoH) колдонуңуз.';

  @override
  String get dnsCheckNeedsConnection => 'Адегенде VPN менен туташып, андан кийин агып кеткендигин текшериңиз.';

  @override
  String get dnsExpected => 'Күтүлгөн';

  @override
  String get dnsActual => 'байкалган';

  @override
  String get measureSpeed => 'Ылдамдыкты өлчөө';

  @override
  String get benchmarkStale => 'эскирген';

  @override
  String get autoSelectMode => 'Серверди автоматтык түрдө тандоо';

  @override
  String get autoSelectPing => 'Эң ылдам пинг';

  @override
  String get autoSelectSpeed => 'Эң ылдам ылдамдык';

  @override
  String get autoSelectSmart => 'Акылдуу тандоо';

  @override
  String get coreWatchUnstable => 'Өзөк менен байланыш туруксуз';

  @override
  String get watchReconnect => 'Кайра туташтыруу';

  @override
  String get crashRestoreTitle => 'Акыркы сессия үзгүлтүккө учурады';

  @override
  String get restoreOnCrash => 'Кырсыктан кийин сессияны калыбына келтирүү';

  @override
  String get crashRestore => 'Калыбына келтирүү';

  @override
  String get crashDismiss => 'Азыр эмес';

  @override
  String get overrideTitle => 'Менин түзөтүүлөрүм';

  @override
  String get overrideEdit => 'Серверлерди түзөтүү';

  @override
  String get overrideHide => 'Жашыруу';

  @override
  String get overrideUnhide => 'Көрсөтүү';

  @override
  String get overrideClear => 'Түзөтүүлөрдү баштапкы абалга келтирүү';

  @override
  String get overrideEmpty => 'Азырынча түзөтүүлөр жок';

  @override
  String get overrideCustomRules => 'Өз эрежелери';

  @override
  String get errBenchmarkUnsupported => 'Ылдамдыкты өлчөө үчүн өзөктүн жаңыраак версиясы керек';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total тартып $done өлчөө…';
  }

  @override
  String get profiles => 'Тармак профилдери';

  @override
  String get profilesEmpty => 'Азырынча профилдер жок';

  @override
  String get profileAdd => 'Профиль кошуу';

  @override
  String get profileName => 'Профилдин аты';

  @override
  String get profileSsids => 'Wi-Fi тармактар (SSID)';

  @override
  String get profileGateways => 'Тармак шлюздары';

  @override
  String get profileAsns => 'AS номерлери';

  @override
  String get profileAutoApply => 'Автоматтык түрдө колдонуу';

  @override
  String get profileSnapshot => 'Учурдагы орнотууларды эстеп көрүңүз';

  @override
  String get profileSnapshotDone => 'Учурдагы орнотуулар профилде сакталган';

  @override
  String get profileDelete => 'Профильди жок кылуу';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" профили жок кылынсынбы?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '\"$name\" профили колдонулсунбу?';
  }

  @override
  String get profileApply => 'Колдонуу';

  @override
  String profileApplied(Object name) {
    return '\"$name\" профили колдонулду';
  }

  @override
  String get profileUndo => 'Жокко чыгаруу';

  @override
  String get profileActive => 'Активдүү';

  @override
  String networkNow(Object info) {
    return 'Азыр: $info';
  }

  @override
  String get networkUnknown => 'Тармак маалыматы жеткиликсиз';

  @override
  String get profileNoTriggers => 'Профилдин шарттары жок';

  @override
  String get chains => 'Прокси чынжырлар';

  @override
  String get chainsEmpty => 'Азырынча чынжыр жок';

  @override
  String get chainAdd => 'Жаңы чынжыр';

  @override
  String get chainName => 'чынжырдын аталышы';

  @override
  String get chainTooFew => 'Чынжырга кеминде эки сервер керек';

  @override
  String get chainTooMany => 'Чынжырда эң көп үч сервер болушу мүмкүн';

  @override
  String get chainEstimate => 'Болжолдуу кечигүү';

  @override
  String get chainSave => 'чынжырды сактоо';

  @override
  String get chainDelete => 'Чынжырды жок кылуу';

  @override
  String chainDeleteConfirm(Object name) {
    return '\"$name\" чынжыр жок кылынсынбы?';
  }

  @override
  String get chainUnsupported => 'Тандалган өзөк чынжырларды колдобойт';

  @override
  String get chainHopMissing => 'Чынжырдагы серверлердин бири эми жеткиликсиз';

  @override
  String chainHop(Object n) {
    return 'Аралык түйүн $n';
  }

  @override
  String get chainEntry => 'Кирүү';

  @override
  String get chainExit => 'Чыгуу';

  @override
  String get sync => 'Түзмөктү синхрондоштуруу';

  @override
  String get syncDevices => 'Менин түзмөктөрүм';

  @override
  String get syncEmpty => 'Жупташтырылган түзмөктөр жок';

  @override
  String get syncPair => 'Түзмөктү жуптаңыз';

  @override
  String get syncShowCode => 'Менин кодумду көрсөт';

  @override
  String get syncScanCode => 'Скандоочу код';

  @override
  String get syncRevoke => 'Алып салуу';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" жокко чыгарылсынбы?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Акыркы синхрондоштуруу: $time';
  }

  @override
  String get syncNever => 'Эч качан';

  @override
  String get syncPaired => 'Түзмөк жупташтырылган';

  @override
  String get syncPairingTitle => 'Бул түзмөк менен жупташтыруу';

  @override
  String get syncWaiting => 'Башка түзмөк күтүлүүдө…';

  @override
  String get zapretWithVpn => 'Түз тармак трафиги үчүн DPI чыпкалоодон өтүңүз';

  @override
  String get chainDuplicate => 'Чынжырда бир сервер кайталанып жатат';

  @override
  String get edit => 'Түзөтүү';

  @override
  String get remove => 'Алып салуу';

  @override
  String get autoSwitchOnDegrade => 'Деградацияны автоматтык түрдө которуу';

  @override
  String get tunStackMixed => 'Аралаш';

  @override
  String get tunStackSystem => 'системасы';

  @override
  String get customServerAdd => 'Ыңгайлаштырылган серверди кошуңуз';

  @override
  String get customServers => 'Менин серверлерим';

  @override
  String get customServerName => 'Аты-жөнү';

  @override
  String get customServerNameRequired => 'Аталыш көрсөтүлгөн эмес';

  @override
  String get customServerAddress => 'Дарек';

  @override
  String get customServerAddressRequired => 'Дарек көрсөтүлгөн эмес';

  @override
  String get customServerAddressInvalid => 'Дарек жараксыз';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortInvalid => 'Порт жараксыз';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Кирүү маалыматы';

  @override
  String get customServerShowSecret => 'Сырды көрсөтүү';

  @override
  String get customServerHideSecret => 'Жашыруун';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” сервери жок кылынсынбы?';
  }

  @override
  String get leakTestTitle => 'Маалыматтын агып кетишин текшерүү';

  @override
  String get leakTestRun => 'Текшерүү';

  @override
  String get leakTestCancel => 'Жокко чыгаруу';

  @override
  String get leakTestNeedsConnection => 'Дайындардын агып кетишин текшерүү үчүн VPN менен туташыңыз.';

  @override
  String leakTestProgress(int count) {
    return 'Сыноолор аяктады: $count';
  }

  @override
  String get leakTestAllClear => 'Агышуу табылган жок';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count маалымат агып кетүүсү табылды',
      one: '$count маалымат агып кетүүсү табылды',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Оңдоо';

  @override
  String get leakTestFixedNote => 'Тармак бөгөтү күйүк. Текшерүү үчүн сыноону кайра иштетиңиз.';

  @override
  String get leakTestCheckDirectDns => 'Түз DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Системалык резолверлер';

  @override
  String get leakTestCheckTunnelConnectivity => 'Туннелдик байланыш';

  @override
  String get leakTestCheckTunnelDns => 'DNS туннель аркылуу';

  @override
  String get noticeDegraded => 'Сервер жайлады. Sora өлчөө учурунда табылган мыкты серверге которулду.';

  @override
  String get obfs => 'Трафикти жашыруу';

  @override
  String get syncCodeExpired => 'Коддун мөөнөтү бүттү';

  @override
  String get syncDaemonFailed => 'Шайкештештирүү кызматы башталбай койду';

  @override
  String get syncDaemonMissing => 'sora-sync компоненти табылган жок';

  @override
  String get syncDaemonStarting => 'Шайкештештирүү кызматы башталууда…';

  @override
  String get syncErrAuth => 'Шайкештештирүү кызматы кирүү белгисин четке какты';

  @override
  String get syncErrNotFound => 'Түзмөк мындан ары жупташкан жок';

  @override
  String get syncErrPairingActive => 'Жупташуу сеансы мурунтан эле ачык';

  @override
  String get syncErrUnreachable => 'Башка түзмөк жооп берген жок';

  @override
  String get syncError => 'Синхрондоштуруу катасы';

  @override
  String syncExpiresIn(String duration) {
    return 'Коддун мөөнөтү $duration кийин бүтөт';
  }

  @override
  String get syncJoining => 'Түзмөк менен жупташуу…';

  @override
  String get syncNewCode => 'Жаңы код';

  @override
  String syncPairedWith(String name) {
    return '$name менен жупташкан';
  }

  @override
  String get syncRetry => 'Кайталоо';

  @override
  String get syncStopShowing => 'Кодду жашыруу';

  @override
  String get syncSyncNow => 'Азыр шайкештирүү';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Кабыл алынган $pulled, жөнөтүлгөн $pushed';
  }

  @override
  String get syncResultTitle => 'Синхрондоштуруу натыйжасы';

  @override
  String get syncPulled => 'Кабыл алынган';

  @override
  String get syncPushed => 'Жөнөтүлдү';

  @override
  String get syncNoChanges => 'Эч кандай өзгөртүүлөр табылган жок';

  @override
  String get syncDocKindSubscriptions => 'Жазылуулар';

  @override
  String get syncDocKindSettings => 'Колдонмонун жөндөөлөрү';

  @override
  String get syncDocKindOverrides => 'Жазылуулардын жеке өзгөртүүлөрү';

  @override
  String get syncDocKindProfiles => 'Тармак профилдери';

  @override
  String get syncDocKindChains => 'Прокси чынжырлар';

  @override
  String syncFrom(String name) {
    return '$name түзмөгүнөн';
  }

  @override
  String get syncThisDevice => 'Бул аппарат';

  @override
  String get syncUnavailableAndroid => 'Android тутумунда шайкештештирүү жеткиликсиз';

  @override
  String get diagnosticPackets => 'Пакетти басып алуу';

  @override
  String get diagnosticEvents => 'Windows окуялары';

  @override
  String get diagnosticCapture => '10 секундга тартыңыз';

  @override
  String get diagnosticRequiresTun => 'Пакетти тартууга активдүү Sora TUN байланышы керек.';

  @override
  String get diagnosticUnavailable => 'Бул диагностика бул платформада жеткиликсиз.';

  @override
  String get extErrRevoked => 'Sora командасы кеңейтүүнүн бул версиясын коопсуз эмес же бузук деп кайтарып алды.';

  @override
  String get extErrRevocationsExpired => 'Жокко чыгарылган кеңейтүүлөрдүн тизмеси жаңырмайынча орнотуу бөгөттөлгөн.';

  @override
  String extRevokedDisabled(String names) {
    return 'Кайтарылган кеңейтүүлөр өчүрүлдү: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Жеке ачкыч';

  @override
  String get customServerWgAddresses => 'Интерфейс даректери';

  @override
  String get customServerWgPeerKey => 'Сервердин ачык ачкычы';

  @override
  String get customServerWgPresharedKey => 'Жалпы ачкыч';

  @override
  String get customServerWgAllowedIps => 'Уруксат берилген IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, секунд';

  @override
  String get customServerWgKeyInvalid => 'WireGuard ачкычы жараксыз';

  @override
  String get customServerWgCidrInvalid => 'CIDR префикси жараксыз';

  @override
  String get customServerWgKeepaliveInvalid => 'Keepalive аралыгы жараксыз';

  @override
  String get strictKillSwitch => 'Катуу тармак бөгөтү';

  @override
  String get strictKillSwitchWarning => 'Чыккандан кийин VPN тышындагы трафик бөгөттөлсүнбү?';

  @override
  String get extWorkerFailed => 'Кеңейтменин фондогу тапшырмасы аткарылган жок';

  @override
  String get extAssetRejected => 'Кеңейтменин файлында окууга кыйын түстөр же жараксыз эрежелер бар';

  @override
  String get extVerifiedSora => 'Sora тарабынан текшерилген';

  @override
  String extReceivedBytes(String count) {
    return '$count Б';
  }

  @override
  String get extOpen => 'Ачуу';

  @override
  String get customServerOwn => 'Жеке сервер';

  @override
  String get customServerPaste => 'Шилтемени чаптоо';

  @override
  String get customServerUser => 'Колдонуучу';

  @override
  String get customServerPassword => 'Сырсөз';

  @override
  String get customServerSecretRequired => 'Маани көрсөтүлгөн эмес';

  @override
  String get customServerLinkInvalid => 'Сервердин шилтемеси туура эмес';

  @override
  String get errInternal => 'Sora ички катасы';

  @override
  String get errTls => 'Сервердин сертификаты кабыл алынган жок';

  @override
  String get errFileAccess => 'Файлга кирүү мүмкүн эмес';

  @override
  String get errDataLimit => 'Маалымат өтө көп';

  @override
  String get errCredentials => 'Сакталган кирүү маалыматтары жок';

  @override
  String subscriptionStale(String time) {
    return 'Жаңыртылган убакыт: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Азырынча жаңыртылган жок';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Сервер HTTP $status кодун кайтарды',
      zero: 'Сервер сурамды четке какты',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Сервер жөндөөлөрү толук эмес же колдоого алынбайт';

  @override
  String get errServerIds => 'Эки сервердин идентификатору бирдей';

  @override
  String get errRoutingGroup => 'Маршрут жок серверлерге же бузулган топко шилтейт';

  @override
  String get errConnections => 'Туташуулар тизмеси жеткиликсиз';

  @override
  String get errLogs => 'Бул кызмат журнал жүргүзбөйт';

  @override
  String get errDiagnostics => 'Диагностика чогултулган жок';

  @override
  String get errMissingItem => 'Суралган нерсе мындан ары жок';

  @override
  String get errInvalidRequest => 'Сурамда жараксыз маанилер бар';

  @override
  String get errProxyLogin => 'Системалык прокси бул кирүүнү колдобойт';

  @override
  String get errLogFilter => 'Журнал чыпкасы жараксыз';

  @override
  String get errSubRedirect => 'Сервер кооптуу дарекке багыттады';

  @override
  String get errProxySetup => 'Системалык прокси жөндөлгөн жок';

  @override
  String get notificationsToday => 'Бүгүн';

  @override
  String get notificationsYesterday => 'Кечээ';

  @override
  String get notificationsMarkRead => 'Баарын окулду деп белгилөө';

  @override
  String get notificationsUnread => 'Окула элек';

  @override
  String get desktopNotifications => 'Тутум билдирмелери';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Жазылууну жаңыртуу аралыгы жараксыз';

  @override
  String get errRule => 'Багыттоо эрежеси жараксыз';

  @override
  String get errDns => 'DNS жөндөөлөрү жараксыз';

  @override
  String get errEndpoint => 'Текшерилүүчү сервердин дареги жараксыз';

  @override
  String get errCancelled => 'Сурам жокко чыгарылды';

  @override
  String get customServerOptions => 'Туташуу параметрлери';

  @override
  String get customServerTransport => 'Транспорт';

  @override
  String get customServerSecurity => 'Коопсуздук';

  @override
  String get customServerCipher => 'Шифр';

  @override
  String get customServerWgInterface => 'Интерфейс';

  @override
  String get customServerWgPeer => 'Пир';

  @override
  String extAvailableOn(String platforms) {
    return 'Жеткиликтүү платформалар: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Бардык колдонмолордун TCP трафиги өзгөртүлсүнбү?';

  @override
  String get winwsRequirements => 'Бул VPN режими жеткиликсиз';

  @override
  String get emptyServersTitle => 'Сервер же жазылуу кошуңуз';

  @override
  String get emptyServersBody =>
      'VPN кызматынын жазылуу шилтемесин коюңуз, өз сервериңизди кошуңуз же QR кодду скандаңыз.';

  @override
  String get qrShort => 'QR код';

  @override
  String get extAboutHello => 'Панелдин үлгүсү: активдүү туташууларды көрсөтөт жана сыноо билдирмесин жөнөтөт.';

  @override
  String get extAboutZapret =>
      'VPN\'сиз бөгөттөрдү айланып өтүү: провайдер сайтты тааныбашы үчүн туташуунун башын өзгөртөт.';

  @override
  String get extAboutByedpi => 'Жергиликтүү ByeDPI прокси аркылуу VPN\'сиз бөгөттөрдү айланып өтүү.';

  @override
  String get modeTunHint => 'Компьютердин бүт трафиги VPN аркылуу өтөт';

  @override
  String get modeProxyHint => 'Системалык проксини колдонгон браузерлер жана программалар гана';

  @override
  String get modeBypassHint => 'VPN серверсиз бөгөттөрдү айланып өтүү';

  @override
  String get modeExtensionHint => 'Кеңейтүүдөн бөгөттөрдү айланып өтүү';

  @override
  String get engineInfo =>
      'Ядро сервер менен туташууну орнотот.\n\nАвто: Sora сервердин протоколун колдогон ядрону өзү тандайт.\nsing-box: тез жана универсалдуу.\nXray: REALITY жана XHTTP менен VLESS үчүн эң жакшы.\nmihomo: Clash жазылуулары жана ийкемдүү эрежелер.\n\nСервер «Авто» режиминде туташпаса гана ядрону алмаштырыңыз.';

  @override
  String get tunStackInfo =>
      'Трафик системадан VPN\'ге кантип түшөт.\n\nСистемалык: эң тез, ОСтун тармак стеги аркылуу.\ngVisor: өз стеги, көпчүлүк программалар менен шайкеш.\nАралаш: TCP система аркылуу, UDP gVisor аркылуу.\n\nСайттар же оюндар начар иштесе, башка стекти сынап көрүңүз.';

  @override
  String get protection => 'Коргоо';

  @override
  String get killSwitchInfo =>
      'VPN ажыраса, трафик туннелден тышкары кетпеши үчүн Sora интернетти бөгөттөйт. Кайра туташканда же VPN өчүрүлгөндө кирүү кайтат.';

  @override
  String get strictKillSwitchInfo =>
      'Бөгөт Sora\'дан чыккандан кийин да, кайра жүктөлгөндөн кийин да бул жерден өчүрмөйүнчө сакталат.';

  @override
  String get zapretWithVpnInfo => 'Эрежелер боюнча VPN\'ди айланып өткөн сайттар Zapret аркылуу бөгөттү айланып өтөт.';

  @override
  String get failoverInfo => 'Сервер жооп бербей калса, Sora кийинки иштеген серверге өзү которулат.';

  @override
  String get ipv6Info => 'IPv6\'ны VPN аркылуу жөнөтүү. Сервер IPv6\'ны колдобосо жана сайттар жай ачылса, өчүрүңүз.';

  @override
  String get fragmentInfo =>
      'Провайдердин чыпкасы сайттын атын көрбөшү үчүн TLS туташуусунун башын бөлүктөргө бөлөт. Сервер SNI боюнча бөгөттөлгөндө жардам берет.';

  @override
  String get splitPosInfo =>
      'Биринчи пакетти кайдан кесүү: байттын номери же белги, мисалы midsld (домендин ортосу). Бир нече маанини үтүр менен бөлүңүз.';

  @override
  String get disorderInfo =>
      'Пакетти ирети менен чогулткан чыпкаларды адаштыруу үчүн пакеттин бөлүктөрүн тескери иретте жөнөтөт.';

  @override
  String get tlsRecordInfo => 'Сайттын аты бир жазууга толук түшпөшү үчүн TLS саламдашуусун бир нече жазууга бөлөт.';

  @override
  String get hostCaseInfo =>
      'HTTP сурамдарындагы Host аталышынын регистрин өзгөртөт (Host → hoSt), эски чыпкалар сурамды тааныбай калат.';

  @override
  String get probeMethodInfo =>
      'Ядро аркылуу: сервер аркылуу сайтка чейинки чыныгы кечигүү, эң так.\nТуташуу гана: серверге TCP туташуу гана, тез, бирок VPN\'ди текшербейт.\nTLS кол алышуу: сервер менен TCP жана TLS.\nICMP: кадимки ping, кээ бир серверлер жооп бербейт.\nАвто: ядро аркылуу, болбосо — туташуу.';

  @override
  String get autoSelectInfo =>
      '«Эң тез» серверди кантип тандайт: пинг боюнча, өлчөнгөн ылдамдык боюнча же экөө боюнча.';

  @override
  String get autoSwitchInfo => 'Учурдагы сервер байкаларлык жайласа, Sora ылдамыраак серверге которулат.';

  @override
  String get probeTls => 'TLS кол алышуу';

  @override
  String get probeIcmp => 'ICMP (ping)';
}
