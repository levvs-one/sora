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
  String get tunnelProxy => 'System прокси';

  @override
  String get proxyAddress => 'Прокси дареги';

  @override
  String get copied => 'Көчүрүлгөн';

  @override
  String get launchAtLogin => 'Системадан баштаңыз';

  @override
  String get launchAtLoginDetail => 'Системага киргенде Sora автоматтык түрдө ишке кирип, лотокто калат.';

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
  String get programsEmpty => 'Тиркемелер табылган жок. Башка ат колдонуп көрүңүз.';

  @override
  String get selectExe => '.exe файлын тандаңыз';

  @override
  String get speedtest => 'Ылдамдык';

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
  String get updateSignaturePending =>
      'Жаңыртуу файлдары чыгарылыш менен кошо жарыяланган текшерүү суммалары менен салыштырылат.';

  @override
  String get updateManualSigWarning =>
      'Төмөнкү файлдар чыгарылыштын текшерүү суммаларына дал келет. Аларды расмий чыгарылыштан жүктөсөңүз, буйрукту аткарыңыз.';

  @override
  String get updateVersionRevoked => 'Иштеп чыгуучу бул версияны алып салды. Сураныч, оңдолгон чыгарууну күтүңүз.';

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
  String get updateRollbackError =>
      'Автоматтык артка кайтаруу ишке ашкан жок. Жаңы версия иштебесе, мурунку версияны кол менен кайра орнотуңуз.';

  @override
  String get updateRollbackCacheError =>
      'Учурдагы версиянын текшерилген артка кайтарылган көчүрмөсүн даярдай алган жок, андыктан жаңыртуу орнотулган эмес.';

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
      'Сервериңизге кайсы кыймылдаткыч керек экенин билбей жатсаңыз, Auto тандаңыз. Sora туташуудан мурун профилди жана орнотууларды текшерет. Кыймылдаткыч планыңыздын өткөрүү жөндөмдүүлүгүн жогорулата албайт: аткаруу серверге, маршрутка, протоколго жана тармакка жараша болот.\n\n## Режимдер\n\n### Бардык трафик (TUN)\n\nSora виртуалдык тармак интерфейсин түзөт жана ал аркылуу тиркеме трафигин, анын ичинде TCP жана UDP багыттарын түзөт. Бул режимди Telegram, оюндар жана Discord үнү үчүн колдонуңуз. Эрежелер конкреттүү сайттарды же программаларды түз жөнөтө алат же аларды бөгөттөй алат. Тармак кызматына уруксат жана талап кылынган протоколду колдогон сервер керек.\n\n### System прокси\n\nSora жергиликтүү HTTP/SOCKS проксисин конфигурациялайт. Системанын прокси жөндөөлөрүн сыйлаган колдонмолор аны колдонушат. Өзүнүн тармактык стеки бар тиркемелер түздөн-түз туташа алат; UDP жана үн чалуулар көбүнчө TUN керек. Бул режим прокси колдоосу менен браузерлерге жана тиркемелерге ылайыктуу.\n\n### Сервер жок\n\nLinuxде Sora [zapret](https://github.com/bol-van/zapret) HTTP/TLS сурамдарын бөлүү жана формасын өзгөртүү жана кээ бир DPI текшерүүлөрүн айланып өтүү үчүн колдонот. Сиздин IP ошол эле бойдон калат жана байланыштар түздөн-түз веб-сайтка кирет. Натыйжалар провайдериңизге жана бөгөттөө ыкмасына жараша болот.\n\nУчурдагы интеграция TCP аркылуу HTTP жана TLS үчүн tpws колдонот. Ал IP бөгөттөөнү кыйгап өтпөйт же UDP релесин өткөрбөйт жана Telegramтин MTProto туташууларына кепилдик бере албайт. Discord үн, Telegram чалуулары жана ушул сыяктуу чектөөлөр үчүн TUN менен VPN серверин колдонуңуз.\n\n## Моторлор\n\n### Авто\n\nSora бүт туташуунун планын колдогон орнотулган кыймылдаткычты тандайт: сервердик протоколдор, транспорттор, топтор, фрагментация жана режим. Учурдагы туташууну токтотуунун алдында кол менен шайкеш келбеген тандоо четке кагылат. Авто же башка кыймылдаткычты тандап, орнотууларды кайра колдонуңуз.\n\n### sing-box\n\nЖаңы Sora топтомдору [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) айрысын камтыйт, ага кардар тараптагы XHTTP жана VLESS Encryption кошулат. Sora курууну жана анын мүмкүнчүлүктөрүн тааныйт. XHTTP жок жогорудагы курулуш бул мүмкүнчүлүктү өзүнүн атынан эле ала албайт.\n\nVLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard протоколдору жана Sora импорттой алган AmneziaWG 1.x/2.x параметрлери колдоого алынат. Толук Xray JSON профилдери үчүн Xray керек. Жаңы AWG 3.x талааларын азырынча импорттоо мүмкүн эмес. sing-box сырсөз менен корголгон жергиликтүү башкаруу портун колдонот; компьютердеги башка колдонмолор ал портту аныктай алат.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption жана TLS фрагментациясын колдойт. Ал ошондой эле Xray провайдеринин толук профилдерин иштетип, алардын маршруттарын жана топторун сактап калат. Мындай профилдерди алардын жүрүм-турумун өзгөртпөстөн автоматтык түрдө башка кыймылдаткычка айландыруу мүмкүн эмес.\n\nТоптолгон Xray TLS тастыктамасын текшерүүнү (`allowInsecure`) өчүргөн жөндөөнү алып салды. Бул жөндөөнү талап кылган жөнөкөй серверлер үчүн автоматтык түрдө sing-box же mihomo тандайт. Xray тандалса, учурдагы туташууну токтотуудан мурун дал келбестикти кол менен кабарлайт. Эски толук JSON профилдерине текшерилүүчү тастыктама же тастыктама пин коду менен жаңыртылган провайдер профили керек.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) буйрутмаланган кайра кайтаруу жана жүктү тең салмактоо топторун, XHTTP жана AmneziaWG колдойт. Камдык серверге автоматтык түрдө өтүү маанилүү болгондо аны тандаңыз. Sora анын TLS фрагментация жөндөөсү бул кыймылдаткычта жеткиликсиз.\n\n## Sora ичинде шайкештик\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN жана TCP/UDP | Ооба | Ооба | Ооба |\n| XHTTP | Ооба | Ооба | Ооба |\n| VLESS Encryption | Ооба | Ооба | Ооба |\n| Толук Xray профили | Жок | Ооба | Жок |\n| TUIC / AnyTLS | экөө | Жок | TUIC |\n| TLS фрагментация | Ооба | Ооба | Жок |\n| AmneziaWG 1.x/2.x | Ооба¹ | Жок | Ооба |\n| Заказ кылынган кайра топ | Жок | No² | Ооба |\n\n¹ J1/J2/J3/Itime менен профилдер mihomo колдонот; бул талаалар эч качан унчукпай ташталбашы керек. ² Толук Xray профилдер тобу үчүн колдонмо камдык профилди тандайт. Колдоо орнотулган курууга көз каранды; жөнүндө анын версиясын текшерүү.\n\n## TUN стек\n\nСтек виртуалдык интерфейстин ичинде TCP жана UDP иштетет. Режимдер панелинде Xray жана mihomo gVisor, System, Mixed жана MIPS сунуштайт. Ар бир кыймылдаткыч өзүнүн артыкчылыктарын сактайт. System прокси жана серверсиз режимдер бул артыкчылыкты колдонушпайт.\n\n- **Mixed**: TCP тутум стекин колдонот, ал эми gVisor UDP менен иштейт. Бул Linux системасында mihomo үчүн демейки вариант. Windows системасында Xray жана mihomo демейки боюнча MIPS колдонот.\n- **System**: система стекин колдонот. Тармак колдонмолору көйгөйлөргө туш болсо, башка жолду байкап көрүңүз.\n- **gVisor**: колдонуучулар мейкиндигинде трафикти башкарат.\n- **MIPS**: mihomoдин өзүнүн IP стеки, топтомдогу 1.19.32 версиясында жеткиликтүү.\n\nLinuxде, Xray демейки боюнча орнотулган gVisor колдонот. Linuxдеги System, Mixed жана MIPS mihomoди TUN кыймылдаткычы катары колдонушат, TCP жана UDP аныктыгын текшерилген жергиликтүү SOCKS шилтемеси аркылуу Xrayга жөнөтөт. Xray протоколду, провайдердин профилин жана маршрутту сактайт. Бул үч параметр орнотулган mihomo талап кылат. Windows боюнча Xray төрт TUN стегинин баары үчүн mihomo 1.19.32 же жаңы версиясын колдонот. Протоколдор жана маршруттоо Xray ичинде калат. Бул айкалышта колдонмо эрежелери түз туташууну жана бөгөттөөнү гана колдойт; Linux ичинде бул эрежелер Xray камтылган gVisor стегин талап кылат.\n\nКөпүрө экинчи процессти жүргүзөт. Linux боюнча үч ишсиз өлчөөдө ал жергиликтүү Xray TUNга караганда 32–36 МБ көбүрөөк физикалык эстутумду колдонду. Бул жүктөө жүгүн өлчөбөйт: CPU жана эстутум баалары туташуулардан көз каранды. sing-box стек селектору жок. Эч кандай стек ар бир тармакта жакшыраак иштөөгө кепилдик бербейт. Стекти тандап, аны тармагыңызда сынап көрүү үчүн Колдонуу жана кайра туташууну тандаңыз.\n\n## Орнотуулар колдонулууда\n\nСерверди тандоо автоматтык түрдө кайра туташат. Режим, кыймылдаткыч, DNS жана эреже жөндөөлөрү дароо сакталат; активдүү туташуу учурунда Колдонуу баскычын чыкылдатып, аларды колдонуу үчүн кайра туташуу. Кыймылдаткычты кайра иштетүү жүктөп алууларды жана чалууларды үзгүлтүккө учуратышы мүмкүн. Кайталанган чыкылдатуулар параллелдүү байланыштарды баштабайт; ажыратуу өтүүнү аяктайт жана байланышты бошотот.\n\nVPN аркылуу гана Интернет туннель кулаганда түз трафикти бөгөттөйт. Бул бүт машинага таасир этет. Ачык ажыратуу Sora эрежелерин алып салат. Тазалоо бүтпөсө, кайра ажыратып көрүңүз жана журналды ачыңыз.\n\n## Долбоордук документтер\n\n- [sing-box-lx: конфигурация жана колдоо](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box документтери](https://sing-box.sagernet.org/)\n- [Xray документтери](https://xtls.github.io/)\n- [mihomo документтери](https://wiki.metacubex.one/)\n- [zapret: операция жана чектөөлөр](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Серверлерди текшерүү';

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
  String get extBadgeVerified => 'Текшерилди';

  @override
  String get extBadgeTop => 'Бул аптада эң популярдуу';

  @override
  String get extBadgeNew => 'Жаңы';

  @override
  String get extBadgeStaff => 'Sora командасы';

  @override
  String get extSideloadShort => 'Каталогдон эмес';

  @override
  String get extSideloadWarning =>
      'Бул кеңейтүү команда каталогунан эмес. Алардын ачкычына автор гана кепилдик берди: аны авторго ишенсеңиз гана орнотуңуз.';

  @override
  String extInstallTitle(String name) {
    return '«$name» орнотуу';
  }

  @override
  String extUpdateTitle(String name) {
    return '«$name» жаңыртуу';
  }

  @override
  String get extPermissionsIntro => 'Бул кеңейтүү төмөнкүлөрдү жасай алат:';

  @override
  String get extPermissionsWidened => 'Жаңыртуу жаңы уруксаттарды сурайт:';

  @override
  String get extDangerousAck => 'Бул уруксаттар олуттуу экенин түшүнөм';

  @override
  String get extInstall => 'Орнотуу';

  @override
  String get extUpdate => 'Жаңыртуу';

  @override
  String get extCancel => 'Жокко чыгаруу';

  @override
  String get extConfirm => 'Ырастоо';

  @override
  String get extOk => 'OK';

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
  String get extEmptyInstalled =>
      'Азырынча кеңейтүүлөр орнотулган эмес.\nКаталогдон бирөөнү табыңыз же файлдан орнотуңуз.';

  @override
  String get extInstallFromFile => 'Файлдан орнотуу';

  @override
  String get extInstallFromUrl => 'URL баштап орнотуу';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Жүктөп алуу';

  @override
  String get extDownloading => 'Жүктөлүүдө…';

  @override
  String get extVerifying => 'Текшерилүүдө…';

  @override
  String get extInstalling => 'Орнотулууда…';

  @override
  String get extInstallFailed => 'Орнотуу ишке ашкан жок';

  @override
  String get extErrSignature => 'Кол коюу текшерилбей калды. Файл бузулган же бурмаланган болушу мүмкүн.';

  @override
  String get extErrManifest => 'Кеңейтүү манифести жараксыз.';

  @override
  String get extErrNetwork => 'Тармак катасы. Туташууңузду текшерип, кайра аракет кылыңыз.';

  @override
  String get extErrHash => 'Жүктөө каталогго дал келбейт. Ал бурмаланган болушу мүмкүн.';

  @override
  String extErrMinApp(String version) {
    return 'Бул кеңейтүү колдонмонун $version же андан жаңыраак версиясын талап кылат.';
  }

  @override
  String get extErrHttpsOnly => 'https:// шилтемелерге гана уруксат берилет';

  @override
  String get extErrGeneric => 'Бир жерден ката кетти. Сураныч, кайра аракет кылыңыз.';

  @override
  String get extErrAuthorKeyChanged =>
      'Бул жаңыртууга орнотулган версияга караганда башка автор ачкычы менен кол коюлган, андыктан ал бөгөттөлгөн. Эгер жаңы ачкычка ишенсеңиз, кеңейтүүнү чыгарып салып, аны кайра орнотуңуз.';

  @override
  String get extUpdateAvailable => 'Жаңыртуу жеткиликтүү';

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
  String get extConflictsIntro =>
      'Бул кеңейтүүлөр бир эле нерсени каалайт. Кайсынысы иштей турганын тандаңыз, экинчиси орнотулган бойдон калат.';

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
    return '$count чыр-чатактар сиздин чечимиңизди талап кылат';
  }

  @override
  String get extConflictsResolve => 'Конфликттерди чечүү';

  @override
  String get extConflictNote =>
      'Тандооңуз ушул түзмөктө сакталат. Тема дароо которулат, тармактык хуктар бул версияда иштебейт.';

  @override
  String extVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get extAuthor => 'Автор';

  @override
  String get extRating => 'Рейтинг';

  @override
  String get extInstalls => 'Орнотуулар';

  @override
  String get extVersion => 'Версия';

  @override
  String get extAbout => 'Бул кеңейтүү жөнүндө';

  @override
  String get extPermissionsTitle => 'Уруксаттар';

  @override
  String get extNoPermissions => 'Атайын уруксаттар жок.';

  @override
  String get extSettings => 'Орнотуулар';

  @override
  String get extSaveSettings => 'Орнотууларды сактоо';

  @override
  String get extSaving => 'Сактоо…';

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
  String get extPanelUnavailable => 'Панел жеткиликсиз. Кеңейтүү өчүрүлгөн же өчүрүлгөн болушу мүмкүн.';

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
  String get extPermRoutingRules => 'Маршрутизация эрежелерин кошуу (тармак трафигинин кеткен жерине таасир этет)';

  @override
  String get extPermNetHooks => 'Тармак жолуна интеграциялоо (DPI айланып өтүү модулдары)';

  @override
  String get extPermNetFetch => 'Уруксат берилген тизмеден URL сураңыз';

  @override
  String get extPermBackground => 'Фондук тапшырмаларды иштетүү';

  @override
  String get extPermBackgroundDetail =>
      'Панел жабык болгондо да пландаштырылган тапшырмаларды аткарат. Сиз аны тындыра аласыз же кеңейтүү жөндөөлөрүнөн анын канчалык көп иштешин өзгөртө аласыз.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

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
  String get extRatingHow => 'Рейтингдер кантип иштейт';

  @override
  String get extRatingHowBody =>
      'Рейтингдер Байесиялык орточо көрсөткүчтү колдонушат: бир нече рейтинги бар кеңейтүү көбүрөөк адам добуш бергенге чейин ортого жакын калат, андыктан бир 5 жылдыздуу карап чыгуу жаңы кеңейтүүнү эң жогору көтөрө албайт. Акыркы рейтингдер эскилерге караганда көбүрөөк жана ар бир эсепке бир гана рейтинг эсептелет.';

  @override
  String get extScreenshots => 'Скриншоттор';

  @override
  String get extSortRelevance => 'актуалдуулугу';

  @override
  String get extPermNetworkDetail =>
      'Интернеттен маалыматты VPN аркылуу жүктөйт. Төмөнкү тизмедеги хосттор гана уруксат, калганы бөгөттөлгөн.';

  @override
  String get extBgTitle => 'Фондук тапшырма';

  @override
  String get extBgEnabled => 'Фондо иштетүү';

  @override
  String get extBgInterval => 'Иштетүү аралыгы';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# мүнөт', one: '# мүнөт');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# саат', one: '# саат');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'Тапшырма Sora ачык турганда, анын ичинде трейде турганда да, график боюнча иштейт. Эң кыска аралык 15 мүнөт.';

  @override
  String get extBgDisabledNote => 'Фондук тапшырманы башкаруу үчүн кеңейтүүнү иштетиңиз.';

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
  String get diagnosticNoData => 'Жазылган сурамдар азырынча жок. Адегенде ылдамдыкты текшерүү вебсайтын ачыңыз.';

  @override
  String get qrShareTitle => 'QR кодун бөлүшүү';

  @override
  String get qrScanTitle => 'QR кодун сканерлеңиз';

  @override
  String get qrCopyLink => 'Шилтемени көчүрүү';

  @override
  String get qrWarning => 'Кодду ишенген адамдарга гана көрсөтүңүз.';

  @override
  String get qrScanHint => 'QR коду бар скриншотту же сүрөттү тандаңыз, же шилтемени коюңуз';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# туташуу', one: '# туташуу');
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
  String get sortBy => 'Сорттоо боюнча';

  @override
  String get sortSubscription => 'Жазылуудагы тартипте';

  @override
  String get sortPing => 'Пинг';

  @override
  String get sortSpeed => 'Ылдамдык';

  @override
  String get sortName => 'Аты-жөнү';

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
  String get coreWatchUnstable => 'Sora өзөгүнө туташуу туруксуз';

  @override
  String get watchReconnect => 'Кайра туташтыруу';

  @override
  String get coreRestoringLink => 'Sora өзөгү менен байланыш калыбына келтирилүүдө…';

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
  String get errBenchmarkUnsupported => 'Ылдамдыкты өлчөө үчүн жаңы өзөк керек';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total тартып $done өлчөө…';
  }

  @override
  String get profiles => 'Тармак профилдери';

  @override
  String get profilesEmpty =>
      'Азырынча профилдер жок. Белгилүү тармактарда автоматтык түрдө орнотууларды колдонуу үчүн бирөөсүн түзүңүз.';

  @override
  String get profileAdd => 'Профиль кошуу';

  @override
  String get profileName => 'Профилдин аты';

  @override
  String get profileSsids => 'Wi-Fi тармактар (SSID)';

  @override
  String get profileSsidsHint => 'Үй, Кеңсе үтүр менен бөлүнгөн';

  @override
  String get profileGateways => 'Тармак шлюздары';

  @override
  String get profileAsns => 'AS номерлери';

  @override
  String get profileAutoApply => 'Автоматтык түрдө колдонуу';

  @override
  String get profileAutoApplyHint => 'Өчүк болсо, профилди колдонуудан мурун ырастоо суралат.';

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
  String get profileNoTriggers => 'Кеминде бир триггерди кошуңуз: SSID, шлюз же ASN';

  @override
  String get chains => 'Прокси чынжырлар';

  @override
  String get chainsEmpty =>
      'Азырынча чынжыр жок. Трафик алардын ар бири аркылуу өтүшү үчүн 2–3 серверди байланыштырыңыз.';

  @override
  String get chainAdd => 'Жаңы чынжыр';

  @override
  String get chainName => 'чынжырдын аталышы';

  @override
  String get chainPickServers => '2–3 серверди тандаңыз';

  @override
  String get chainOrderHint => 'Кайра иреттөө үчүн сүйрөңүз: трафик жогору жактан кирип, ылдый жактан чыгат.';

  @override
  String get chainTooFew => 'Кеминде 2 серверди тандаңыз';

  @override
  String get chainTooMany => 'Чынжыр эң көп дегенде 3 серверди камтыйт';

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
  String get chainUnsupported => 'Учурдагы мотор чынжырларды түзө албайт';

  @override
  String get chainHopMissing => 'чынжыр серверлеринин бири мындан ары жеткиликтүү эмес';

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
  String get syncEmpty => 'Жупташтырылган түзмөктөр жок. Жергиликтүү тармак аркылуу башка түзмөктү жупташтырыңыз.';

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
  String get syncNoLan => 'Түзмөктөр бир локалдык тармакта болушу керек';

  @override
  String get syncPaired => 'Түзмөк жупташтырылган';

  @override
  String get syncPairingTitle => 'Бул түзмөк менен жупташтыруу';

  @override
  String get syncWaiting => 'Башка түзмөк күтүлүүдө…';

  @override
  String get syncSecureNote => 'Ичтен аягына чейин шифрленген канал. Эч кандай аккаунттар, булут серверлери жок.';

  @override
  String get zapretWithVpn => 'Түз тармак трафиги үчүн DPI чыпкалоодон өтүңүз';

  @override
  String get zapretWithVpnHint =>
      'zapret VPN туннели менен катар иштейт: туннель трафиги VPN аркылуу, түз трафик бөгөттү айланып өтүү каражаты аркылуу өтөт.';

  @override
  String get chainDuplicate => 'Ар бир сервер бир гана жолу пайда болот';

  @override
  String get edit => 'Түзөтүү';

  @override
  String get remove => 'Алып салуу';

  @override
  String get autoSwitchOnDegrade => 'Деградацияны автоматтык түрдө которуу';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Тандалган сервер катуу жайласа же жооп бербей калса, Sora өлчөө жыйынтыгы эң жакшы серверге которулат, бирок 10 мүнөттө бир жолудан көп эмес.';

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
  String get customServerNameHint => 'Мисалы: менин VPS';

  @override
  String get customServerNameRequired => 'Атын киргизиңиз';

  @override
  String get customServerAddress => 'Дарек';

  @override
  String get customServerAddressHint => 'example.com же 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Сервердин дарегин киргизиңиз';

  @override
  String get customServerAddressInvalid => 'Дарек жараксыз';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Порт 1ден 65535ке чейинки сан болушу керек';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Кирүү маалыматы';

  @override
  String get customServerOptional => 'Кошумча';

  @override
  String get customServerShowSecret => 'Сырды көрсөтүү';

  @override
  String get customServerHideSecret => 'Жашыруун';

  @override
  String get customServerBadge => 'жеке';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” сервери жок кылынсынбы?';
  }

  @override
  String get customServerEmptyHint => 'Серверди кол менен кошуңуз: дарек, порт жана протокол';

  @override
  String get customServerTest => 'Сыноо';

  @override
  String get leakTestTitle => 'Маалыматтын агып кетишин текшерүү';

  @override
  String get leakTestIntro =>
      'Трафик түзмөктөн туннелден тышкары чыга аларын текшерет: түз DNS жана ICMP сурамдары, IPv6 чыгышы жана системалык резолверлер. Туташуу активдүү кезде иштетиңиз.';

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
      other: '# маалымат агып кетүүсү табылды',
      one: '# маалымат агып кетүүсү табылды',
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
  String get syncDaemonMissing =>
      'sora-sync компоненти табылган жок. Түзмөктү синхрондоштурууну иштетүү үчүн колдонмону кайра орнотуңуз.';

  @override
  String get syncDaemonStarting => 'Шайкештештирүү кызматы башталууда…';

  @override
  String get syncErrAuth =>
      'Шайкештештирүү кызматы кирүү белгисин четке какты. Колдонмону өчүрүп күйгүзүп, кайра аракет кылыңыз.';

  @override
  String get syncErrNotFound => 'Түзмөк мындан ары жупташкан жок';

  @override
  String get syncErrPairingActive => 'Жупташуу сеансы мурунтан эле ачык';

  @override
  String get syncErrUnreachable =>
      'Башка түзмөк жооп берген жок. Анын бир тармакта экенин жана анын кодун көрсөтүп жатканын текшериңиз.';

  @override
  String get syncError => 'Синхрондоштуруу катасы';

  @override
  String syncExpiresIn(String duration) {
    return 'Коддун мөөнөтү $duration кийин бүтөт';
  }

  @override
  String get syncJoining => 'Түзмөк менен жупташуу…';

  @override
  String get syncLegacyCleared =>
      'Эски түзмөк тизмеси эч качан жупташкан эмес, андыктан ал тазаланган. Түзмөктөрүңүздү бул жолу чындап кайра жупташтырыңыз.';

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
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Shadowsocks үчүн: ыкма:сырсөз, мисалы chacha20-ietf-poly1305:password';

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
  String get extErrRevocationsExpired =>
      'Кайтарылган кеңейтүүлөрдүн тизмесин жаңыртуу мүмкүн болгон жок. Жаңыртылганча орнотуу бөгөттөлгөн: тармакты текшерип, кайра аракет кылыңыз.';

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
  String get customServerWgKeyInvalid => 'Ачкыч wg genkey чыгаргандай base64 түрүндөгү 32 байт болушу керек.';

  @override
  String get customServerWgCidrInvalid => 'Үтүр менен бөлүнгөн префикстерди киргизиңиз, мисалы 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => '0дөн 65535ке чейинки секунд санын киргизиңиз.';

  @override
  String get strictKillSwitch => 'Катуу тармак бөгөтү';

  @override
  String get strictKillSwitchWarning =>
      'Туташкандан кийин ката, кайра иштетүү же колдонмодон чыгуу учурунда да VPN тышындагы трафикти бөгөттөйт. Жеткиликтүүлүк байланышты үзгөндө же бул жөндөөнү өчүргөндө гана калыбына келет. Түзмөк кайра жүктөлгөндө бөгөттөө ишке киргенде туташуу күйгүзүлгөн болсо гана уланат.';

  @override
  String get extWorkerFailed => 'Кеңейтменин фондогу тапшырмасы аткарылган жок. Кеңейтменин журналын текшериңиз.';

  @override
  String get extAssetRejected => 'Кеңейтменин файлы четке кагылды: окулбаган түстөр же жараксыз эрежелер.';
}
