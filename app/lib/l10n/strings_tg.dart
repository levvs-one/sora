// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Tajik (`tg`).
class STg extends S {
  STg([String locale = 'tg']) : super(locale);

  @override
  String get stateOff => 'Пайваст нест';

  @override
  String get stateConnecting => 'Пайвастшавӣ';

  @override
  String get stateConnected => 'пайваст';

  @override
  String get stateReconnecting => 'Аз нав пайваст шудан';

  @override
  String get stateDisconnecting => 'Хомӯш шудан';

  @override
  String get coreMissing => 'Хидмати Sora ҷавоб намедиҳад';

  @override
  String get serverAuto => 'Тезтарин';

  @override
  String get serverBypass => 'Сервер нест';

  @override
  String get addSubscription => 'Иловаи обуна';

  @override
  String get servers => 'Серверҳо';

  @override
  String get settings => 'Танзимотҳо';

  @override
  String get subscription => 'Обуна';

  @override
  String get subscriptionLink => 'Пайванди обуна';

  @override
  String get add => 'Илова';

  @override
  String get refresh => 'Навсозӣ';

  @override
  String get rename => 'Номи дигар';

  @override
  String get delete => 'Нобуд кунед';

  @override
  String get cancel => 'Бекор кардан';

  @override
  String get save => 'Захира кунед';

  @override
  String get name => 'Ном';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" нест карда шавад?';
  }

  @override
  String get routes => 'Роҳҳо';

  @override
  String get presetGlobal => 'Ҳама чиз тавассути VPN';

  @override
  String get presetRu => 'Русия бевосита';

  @override
  String get presetIr => 'Эрон бевосита';

  @override
  String get presetCn => 'Чин бевосита';

  @override
  String get blockAds => 'Рекламаҳоро манъ кунед';

  @override
  String get killSwitch => 'Интернет танҳо тавассути VPN';

  @override
  String get engine => 'Мотор';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'Аниматсияҳо';

  @override
  String get logs => 'Сабти ном';

  @override
  String get about => 'Дар бораи';

  @override
  String get logsAll => 'Ҳама';

  @override
  String get logsImportant => 'Муҳим';

  @override
  String get logsErrors => 'Хатогиҳо';

  @override
  String get search => 'Ҷустуҷӯ';

  @override
  String get export => 'Ба файл захира кунед';

  @override
  String get clear => 'Тоза';

  @override
  String get logsEmpty => 'Ҳеҷ чиз дар ин ҷо';

  @override
  String get connEmpty => 'Пайвастшавӣ нест';

  @override
  String appVersion(String version) {
    return 'Версияи $version';
  }

  @override
  String get notInstalled => 'Насб карда нашудааст';

  @override
  String get sourceCode => 'Рамзи манбаъ';

  @override
  String get license => 'Иҷозатнома';

  @override
  String usage(String used, String total) {
    return '$used аз $total';
  }

  @override
  String until(String date) {
    return 'то $date';
  }

  @override
  String get expired => 'Муддат гузаштааст';

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
    return '$n сил';
  }

  @override
  String get errGeneric => 'Чизе хато рафт';

  @override
  String get errCore => 'Хидмати Sora ҷавоб намедиҳад';

  @override
  String get errAuth => 'Дастрасӣ ба хидмати Sora нест';

  @override
  String get errVersion => 'Навсозии Sora: барнома ва хидмат версияҳои гуногун мебошанд';

  @override
  String get errBusy => 'Интизор шавед, фармони қаблӣ ҳоло ҳам иҷро мешавад';

  @override
  String get errEngineMissing => 'Барои ин сервер ягон муҳаррик ёфт нашуд';

  @override
  String get errEngineStart => 'Мотор ба кор надаромад';

  @override
  String get errEngineStopped => 'Мотор аз кор монд';

  @override
  String get errTunnel => 'Ин реҷаи VPN дастнорас аст. Реҷаи дигарро интихоб кунед ё иҷозатҳои хидматро санҷед.';

  @override
  String get errNetwork => 'Ба сервер расида наметавонад';

  @override
  String get errTimeout => 'Сервер сари вақт ҷавоб надод';

  @override
  String get errFirewall => 'Интернетро берун аз VPN манъ карда натавонист';

  @override
  String get errSubFetch => 'Обунаро бор карда натавонист';

  @override
  String get errSubFormat => 'Ин пайванди обуна нест';

  @override
  String get errSubEmpty => 'Обуна сервер надорад';

  @override
  String get errSubDuplicate => 'Ин обуна аллакай илова карда шудааст';

  @override
  String get errSubLimit => 'Обунаҳо аз ҳад зиёд';

  @override
  String get errSubScheme => 'Истинод бояд бо https:// оғоз шавад';

  @override
  String get errSecretStore => 'Захираи Sora осеб дидааст ё дастнорас аст';

  @override
  String get errNoServers => 'Барои пайваст шудан обуна илова кунед';

  @override
  String get connections => 'Пайвастшавӣ';

  @override
  String get close => 'Пӯшед';

  @override
  String get chainDirect => 'Бевосита';

  @override
  String get chainBlocked => 'Бастан';

  @override
  String get theme => 'Мавзӯъ';

  @override
  String get themeSystem => 'Мисли система';

  @override
  String get themeLight => 'Нур';

  @override
  String get themeDark => 'Торик';

  @override
  String get language => 'Забон';

  @override
  String get languageSystem => 'Мисли система';

  @override
  String get sectionConnection => 'Пайвастшавӣ';

  @override
  String get sectionNoServer => 'Сервер нест';

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
  String get dnsHint => 'Суроғаҳо, вергул ҷудо';

  @override
  String get fragment => 'Тақсимоти TLS';

  @override
  String get fragmentPackets => 'Чӣ бояд тақсим кард';

  @override
  String get fragmentLength => 'Андозаи порча';

  @override
  String get fragmentInterval => 'Дар байни қисмҳо таваққуф кунед';

  @override
  String get byDefault => 'Пешфарз';

  @override
  String get rangeHint => 'Масалан, 100-200';

  @override
  String get splitPos => 'Ҷойҳои тақсимшуда';

  @override
  String get splitPosHint => 'Масалан, 1, midsld';

  @override
  String get disorder => 'Тартиби дубораи қисмҳо';

  @override
  String get tlsRecord => 'Сабти TLS-ро тақсим кунед';

  @override
  String get tlsRecordNo => 'Не';

  @override
  String get tlsRecordSni => 'Дар номи сайт';

  @override
  String get tlsRecordFirst => 'Пас аз байти аввал';

  @override
  String get hostCase => 'Тағир додани парвандаи мизбон';

  @override
  String get probeMethod => 'Усул';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Ба воситаи мотор';

  @override
  String get probeConnect => 'Танҳо пайвастшавӣ';

  @override
  String get probeUrl => 'Суроғаи санҷиш';

  @override
  String get probeTimeout => 'Интизор шавед';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Обунаҳо';

  @override
  String get subscriptionSettings => 'Танзимотҳо';

  @override
  String get userAgent => 'Корбар-Агенти';

  @override
  String get autoUpdate => 'Навсозии худкор';

  @override
  String get updateInterval => 'Ҳар чанд вақт';

  @override
  String get intervalProvider => 'Тавре ки провайдер мепурсад';

  @override
  String hours(int n) {
    return '$n ч';
  }

  @override
  String get updateNow => 'Ҳоло навсозӣ кунед';

  @override
  String get logLevel => 'Чиро сабт кардан';

  @override
  String get levelDebug => 'Ҳама чиз';

  @override
  String get levelInfo => 'Одатан';

  @override
  String get levelWarning => 'Муҳим';

  @override
  String get levelError => 'Фақат хатолар';

  @override
  String get recordDestinations => 'Суроғаҳои сайтро сабт кунед';

  @override
  String get reset => 'Танзимотҳоро барқарор кунед';

  @override
  String get resetConfirm => 'Ҳама танзимотро аз нав барқарор кунед?';

  @override
  String get resetAction => 'Бозсозӣ';

  @override
  String get invalidValue => 'Ин арзиш кор намекунад';

  @override
  String get website => 'Саҳифаи обуна';

  @override
  String get providerWebsite => 'Вебсайти провайдер';

  @override
  String get support => 'Дастгирӣ';

  @override
  String controlPortQuestion(String engine) {
    return '$engine тавассути порти ин компютер идора карда мешавад. Барномаҳои дигар метавонанд бигӯянд, ки VPN фаъол аст.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine-ро интихоб кунед';
  }

  @override
  String get rules => 'Қоидаҳои фармоишӣ';

  @override
  String get ruleAdd => 'Қоидаи нав';

  @override
  String get ruleHint => 'Сайт, IP ё барнома';

  @override
  String get ruleDirect => 'Бевосита';

  @override
  String get ruleProxy => 'Тавассути VPN';

  @override
  String get ruleBlock => 'Блок';

  @override
  String get failover => 'Нокомиро фурӯзон кунед';

  @override
  String get connectOnStart => 'Дар оғоз пайваст шавед';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'обуна дар рӯзҳои $days ба охир мерасад',
      one: 'обуна дар рӯзи $days ба охир мерасад',
      zero: 'обуна баъди чанд соат ба охир мерасад',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left чап';
  }

  @override
  String get ruleInvalid => 'Ин ба сайт, IP ё барнома монанд нест';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серверҳои $count, зудтарин',
      one: 'Сервери $count, зудтарин',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelProxy => 'Прокси System';

  @override
  String get proxyAddress => 'Суроғаи прокси';

  @override
  String get copied => 'Нусхабардорӣ';

  @override
  String get launchAtLogin => 'Бо система оғоз кунед';

  @override
  String get launchAtLoginDetail => 'Ҳангоми воридшавӣ ба система Sora ба таври худкор оғоз шуда, дар tray мемонад.';

  @override
  String get closeToTray => 'Ҳангоми пӯшидан дар табақ нигоҳ доред';

  @override
  String get notifications => 'Огоҳиномаҳо';

  @override
  String get trayOpen => 'Sora-ро кушоед';

  @override
  String get trayConnect => 'Пайваст кунед';

  @override
  String get trayDisconnect => 'Қатъ кунед';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Аз Sora баромад кунед';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora ҳоло ҳам дар табақи аст';

  @override
  String get noticeInTrayBody => 'Аз менюи тасвири он хориҷ шавед';

  @override
  String get noticeLost => 'Пайвастшавӣ гум шуд';

  @override
  String get noticeLostBody => 'Sora дубора пайваст мешавад';

  @override
  String get noticeRestored => 'Боз пайваст';

  @override
  String get noticeFailed => 'Пайваст шуда натавонист';

  @override
  String get noticeBackup => 'Сервери асосӣ ҷавоб надод; нусхаи эҳтиётӣ трафикро мебарад';

  @override
  String get noticeNext => 'Сервер ҷавоб надод; навбатӣ ҳаракати нақлиётро мебарад';

  @override
  String get noticeMainBack => 'Сервери асосӣ боз ҷавоб медиҳад ва трафикро интиқол медиҳад';

  @override
  String get noticeSubscription => 'Обуна';

  @override
  String get importTitle => 'Ин обунаро илова кунед?';

  @override
  String get importSealed =>
      'Ин пайванд барои Happ рамзгузорӣ шудааст ва танҳо Happ онро хонда метавонад. Аз провайдери худ истиноди оддии обуна пурсед.';

  @override
  String get understood => 'ДУРУСТ';

  @override
  String get noAnswer => 'ҷавоб нест';

  @override
  String get home => 'Хона';

  @override
  String get navRules => 'Қоидаҳо';

  @override
  String get navConnections => 'Пайвастшавӣ';

  @override
  String get navLogs => 'Сабтҳо';

  @override
  String get navAbout => 'Дар бораи';

  @override
  String get sidebarToggle => 'Паҳлӯи паҳлӯро иваз кунед';

  @override
  String get more => 'Бештар';

  @override
  String get less => 'Камтар';

  @override
  String get notificationsEmpty => 'Ҳодисаҳои пайвастшавӣ ва обуна дар ин ҷо пайдо мешаванд';

  @override
  String get retryConnect => 'Пайвастшавӣ аз нав кӯшиш кунед';

  @override
  String get openLogs => 'Сабтҳоро кушоед';

  @override
  String get tourReplay => 'Боз роҳнамо нишон диҳед';

  @override
  String tourStep(int step) {
    return 'Қадами $step аз 5';
  }

  @override
  String get tourBack => 'Бозгашт';

  @override
  String get tourNext => 'Баъдӣ';

  @override
  String get tourSkip => 'Гузаштан';

  @override
  String get tourFinish => 'Иҷро шуд';

  @override
  String get tourAdd => 'Истиноди обунаи провайдери худро илова кунед.';

  @override
  String get tourServer => 'Серверро интихоб кунед. \"Зуртарин\" якеро барои шумо интихоб мекунад.';

  @override
  String get tourConnect => 'Барои пайваст кардан ё ҷудо кардан ин ҷо клик кунед.';

  @override
  String get tourMode => 'Режимро интихоб кунед. Агар VPN афтад, коммутаторро блокҳои интернетро кушед.';

  @override
  String get tourSettings => 'Танзимотҳоро кушоед. Шумо метавонед ин дастурро дар он ҷо такрор кунед.';

  @override
  String get chooseProgram => 'Барномаро интихоб кунед';

  @override
  String get installedApps => 'Барномаҳои насбшуда';

  @override
  String get runningProcesses => 'Равандҳои иҷрошаванда';

  @override
  String get programsEmpty => 'Ягон барнома ёфт нашуд. Номи дигарро санҷед.';

  @override
  String get selectExe => 'Файли .exe-ро интихоб кунед';

  @override
  String get speedtest => 'Суръат';

  @override
  String get speedtestSearch => 'Хидматро пайдо кунед';

  @override
  String get speedtestEmpty => 'Ягон мувофиқат. Ҷустуҷӯро тағир диҳед.';

  @override
  String get speedtestBackToList => 'Бозгашт ба хидматҳо';

  @override
  String get speedtestOpenBrowser => 'Дар браузер кушоед';

  @override
  String get speedtestUnavailable =>
      'Браузери дарунсохт оғоз карда натавонист. Хизматро дар браузери системаи худ кушоед.';

  @override
  String get speedtestPageFailed =>
      'Саҳифа бор карда нашуд. Онро аз нав бор кунед ё хидматро дар браузери системаи худ кушоед.';

  @override
  String get speedtestExternalFailed => 'Браузери система кушода натавонист. Як бори дигар санҷед.';

  @override
  String get modes => 'Модулҳо';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Ҳама трафик (TUN)';

  @override
  String get checkUpdates => 'Барои навсозиҳо санҷед';

  @override
  String get updates => 'Навсозии барномаҳо';

  @override
  String updateAvailable(String version) {
    return 'Версияи $version дастрас аст';
  }

  @override
  String get updateOpenAbout => 'Дидани навсозӣ';

  @override
  String updateNotes(String version) {
    return 'Тағирот дар $version';
  }

  @override
  String get updateCheck => 'Барои навсозиҳо санҷед';

  @override
  String get updateChecking => 'Санҷиш...';

  @override
  String get updateNoNotes => 'Нашрия ягон қайд надорад.';

  @override
  String get updateDropWarning =>
      'Ҳангоми Sora ва навсозии асосии он пайвасти VPN чанд сония қатъ мешавад. Давом додан?';

  @override
  String get updateWaitConnection => 'Интизор шавед, ки пайвасти VPN ва аслӣ омода шаванд.';

  @override
  String get updateDownloading => 'Зеркашӣ ва тасдиқи файлҳо...';

  @override
  String get updateInstalling => 'Омода кардани навсозӣ ё мунтазири аутентификатсияи администратор...';

  @override
  String get updateNetworkError => 'Навсозӣ зеркашӣ карда нашуд. Як бори дигар санҷед.';

  @override
  String get updateReleaseError => 'Маълумоти релиз ё файлҳои зарурӣ нест ё беэътибор аст.';

  @override
  String get updateChecksumError => 'Зеркашӣ ба SHA256SUMS мувофиқат намекунад. Ҳеҷ чиз насб карда нашудааст.';

  @override
  String get updateInstallError => 'Навсозӣ ба охир нарасид. Аутентификатсия метавонад бекор карда шавад.';

  @override
  String get updateUnsupported =>
      'Ин файли иҷрошаванда ба ҷуфти бастаи дастгиришавандаи Sora тааллуқ надорад. Дастурҳои насбкуниро истифода баред.';

  @override
  String get updateManual =>
      'Ин фармонро дар терминал иҷро кунед, то ҳарду бастаи тасдиқшударо насб кунед, пас Sora-ро аз нав кушоед. Файлҳо дар директорияи зеркашӣ мемонанд. Пайвасти VPN қатъ мешавад.';

  @override
  String get updateSignaturePending => 'Файлҳои навсозӣ бо суммаҳои назоратии бо релиз нашршуда муқоиса мешаванд.';

  @override
  String get updateManualSigWarning =>
      'Файлҳои зерин ба суммаҳои назоратии релиз мувофиқанд. Агар онҳоро аз релизи расмӣ боргирӣ карда бошед, фармонро иҷро кунед.';

  @override
  String get updateVersionRevoked => 'Таҳиягар ин версияро бозпас гирифт. Лутфан нашри ислоҳшударо интизор шавед.';

  @override
  String get updateRolloutPending =>
      'Версияи навтар тадриҷан паҳн мешавад ва ба таври худкор ба шумо пешниҳод карда мешавад.';

  @override
  String updateRollbacking(String version) {
    return 'Бозгашт ба версияи $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Навсозӣ ба $version аз санҷиши коршоямӣ нагузашт, бинобар ин Sora ба $fromVersion баргардонида шуд.';
  }

  @override
  String get updateRollbackError =>
      'Бозгашти худкор ноком шуд. Агар версияи нав кор накунад, версияи қаблиро дастӣ аз нав насб кунед.';

  @override
  String get updateRollbackCacheError =>
      'Нусхаи санҷидашудаи версияи ҷорӣ барои бозгашт омода нашуд, бинобар ин навсозӣ насб нашуд.';

  @override
  String get updateCopyCommand => 'Фармони нусхабардорӣ';

  @override
  String get updateChecksDisabled => 'Санҷишҳои худкор дар Танзимот ғайрифаъол карда мешаванд.';

  @override
  String get updateInstalled => 'Навсозии насбшуда. Sora-ро аз нав кушоед.';

  @override
  String get projectLinks => 'Лоиҳа';

  @override
  String get githubReleases => 'Нашрияҳо ва зеркашиҳо';

  @override
  String get telegramChannel => 'Канали Telegram';

  @override
  String get licenses => 'Иҷозатномаҳо';

  @override
  String get componentLicenses => 'Литсензияҳои компонентҳо';

  @override
  String get collapseServers => 'Барҳам додани серверҳо';

  @override
  String get expandServers => 'Серверҳоро васеъ кунед';

  @override
  String get hideDescription => 'Пинҳон кардани тавсиф';

  @override
  String get showDescription => 'Тавсифро нишон диҳед';

  @override
  String get pendingConnectionChanges => 'Барои татбиқи ин тағйирот дубора пайваст шавед.';

  @override
  String get reconnectNow => 'Муроҷиат кунед ва дубора пайваст кунед';

  @override
  String get errEngineUnsupported =>
      'Муҳаррики интихобшуда ин профил ё танзимотро дастгирӣ намекунад. Авто ё муҳаррики мувофиқро интихоб кунед.';

  @override
  String get errRestore =>
      'Тозакунии пайвастшавӣ нопурра буд. Кӯшиш кунед, ки пайвастшавиро қатъ кунед; барои тафсилот ба гузориш нигаред.';

  @override
  String get errSessionEnded => 'Ин сессия аллакай ба охир расид. Ҳолати пайвастшавиро нав кунед.';

  @override
  String get retryDisconnect => 'Кӯшиш кунед, ки пайвастшавиро қатъ кунед';

  @override
  String get tunStack => 'Дастгоҳи TUN';

  @override
  String get modesInfo => 'Дар бораи режимҳо';

  @override
  String get modesGuideTitle => 'Модулҳо ва муҳаррикҳо';

  @override
  String get modesGuide =>
      'Агар шумо боварӣ надошта бошед, ки ба сервери шумо ба кадом муҳаррик ниёз дорад, Auto-ро интихоб кунед. Sora пеш аз пайвастшавӣ профил ва танзимотро тафтиш мекунад. Муҳаррик наметавонад маҷрои нақшаи шуморо зиёд кунад: иҷроиш аз сервер, масир, протокол ва шабака вобаста аст.\n\n## Модҳо\n\n### Ҳама трафик (TUN)\n\nSora интерфейси шабакаи маҷозӣ эҷод мекунад ва трафики барномаҳоро тавассути он, аз ҷумла TCP ва UDP, масир мекунад. Ин режимро барои Telegram, бозиҳо ва овози Discord истифода баред. Қоидаҳо метавонанд сайтҳо ё барномаҳои мушаххасро мустақиман фиристанд ё онҳоро маҳкам кунанд. Хидмати шабака ба иҷозат ва сервере ниёз дорад, ки протоколи лозимиро дастгирӣ мекунад.\n\n### Прокси System\n\nSora прокси маҳаллии HTTP/SOCKS-ро танзим мекунад. Барномаҳое, ки танзимоти прокси системаро эҳтиром мекунанд, онро истифода мебаранд. Барномаҳо бо стеки шабакавии худ метавонанд мустақиман пайваст шаванд; UDP ва зангҳои овозӣ умуман ба TUN ниёз доранд. Ин режим ба браузерҳо ва барномаҳо бо дастгирии прокси мувофиқат мекунад.\n\n### Сервер нест\n\nДар Linux, Sora [zapret](https://github.com/bol-van/zapret) -ро барои тақсим кардан ва тағир додани дархостҳои HTTP/TLS ва гузаштан аз баъзе санҷишҳои DPI истифода мебарад. IP-и шумо бетағйир мемонад ва пайвастҳо мустақиман ба вебсайт мераванд. Натиҷаҳо аз провайдери шумо ва усули басташавӣ вобастаанд.\n\nИнтегратсияи ҷорӣ tpws-ро барои HTTP ва TLS тавассути TCP истифода мебарад. Он масдудкунии IP ё интиқоли UDP-ро фаро намегирад ва пайвастҳои Telegram-и MTProto-ро кафолат дода наметавонад. Сервери VPN-ро бо TUN барои овози Discord, зангҳои Telegram ва ин гуна маҳдудиятҳо истифода баред.\n\n## Моторҳо\n\n### Авто\n\nSora муҳаррики насбшударо интихоб мекунад, ки тамоми нақшаи пайвастшавиро дастгирӣ мекунад: протоколҳои сервер, интиқолҳо, гурӯҳҳо, тақсимот ва режим. Интихоби дастӣ номувофиқ пеш аз қатъ кардани пайвасти ҷорӣ рад карда мешавад. Авто ё муҳаррики дигарро интихоб кунед ва танзимотро дубора татбиқ кунед.\n\n### sing-box\n\nБастаҳои нави Sora иборатанд аз [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), як фардкунандаи [sing-box](https://github.com/SagerNet/sing-box), илова кардани муштарии XHTTP ва VLESS Encryption. Sora сохтмон ва қобилиятҳои онро эътироф мекунад. Сохтмони болооб бидуни XHTTP ин қобилиятро танҳо аз номи худ ба даст намеорад.\n\nПротоколҳои дастгирӣшаванда VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard ва Z8x/parameters. Sora метавонад ворид кунад. Профилҳои пурраи Xray JSON Xray-ро талаб мекунанд. Майдонҳои нави AWG 3.x ҳанӯз ворид карда намешаванд. sing-box порти назорати маҳаллии бо парол ҳифзшударо истифода мебарад, ки дигар замимаҳои компютер метавонанд онро ошкор кунанд.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) пораҳои VLESS, REALITY, XHTTP, VLESS Encryption ва TLS-ро дастгирӣ мекунад. Он инчунин профилҳои пурраи провайдери Xray -ро ҳангоми нигоҳ доштани масир ва гурӯҳҳои онҳо иҷро мекунад. Чунин профилҳоро бидуни тағир додани рафтори худ ба таври худкор ба муҳаррики дигар табдил додан мумкин нест.\n\nXray маҷмӯӣ танзимеро, ки санҷиши сертификати TLS-ро ғайрифаъол мекунад (`allowInsecure`) хориҷ кард. Барои серверҳои оддӣ, ки ин танзимотро талаб мекунанд, худкор sing-box ё mihomo-ро интихоб мекунад. Интихоби Xray пеш аз қатъ кардани пайвасти ҷорӣ дастӣ дар бораи номувофиқатӣ хабар медиҳад. Профилҳои пурраи JSON-и кӯҳна ба профили провайдери навшуда бо шаҳодатномаи тасдиқшаванда ё PIN сертификат ниёз доранд.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) гурӯҳҳои фармоишии бозгашт ва мувозинати сарборӣ, XHTTP ва AmneziaWG -ро дастгирӣ мекунад. Вақте ки интиқоли автоматӣ ба сервери эҳтиётӣ муҳим аст, онро интихоб кунед. Танзими тақсимоти TLS-и Sora бо ин муҳаррик дастнорас аст.\n\n## Мутобиқат дар Sora\n\n| Хусусият | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN ва TCP/UDP | Бале | Бале | Бале |\n| XHTTP | Бале | Бале | Бале |\n| VLESS Encryption | Бале | Бале | Бале |\n| Профили пурраи Xray | Не | Бале | Не |\n| TUIC / AnyTLS | Ҳарду | Не | TUIC |\n| mieru | Не | Не | Бале |\n| NaiveProxy | Бале | Не | Не |\n| Фрагментатсияи TLS | Бале | Бале | Не |\n| AmneziaWG 1.x/2.x | Ҳа¹ | Не | Бале |\n| Гурӯҳи бозгашти фармоишӣ | Не | No² | Бале |\n\n¹ Профилҳо бо J1/J2/J3/Itime mihomo-ро истифода мебаранд; ин майдонхоро хеч гох хомушона партофтан лозим нест. ² Барои як гурӯҳи профилҳои пурраи Xray, барнома профили эҳтиётиро интихоб мекунад. Дастгирӣ аз сохтори насбшуда вобаста аст; версияи онро дар бораи санҷед.\n\n## Стеки TUN\n\nСтек TCP ва UDP-ро дар дохили интерфейси виртуалӣ идора мекунад. Дар панели режимҳо, Xray ва mihomo gVisor, System, Mixed ва MIPS -ро пешниҳод мекунанд. Ҳар як муҳаррик афзалияти худро захира мекунад. System прокси ва режимҳои бе сервер ин афзалиятро истифода намебаранд.\n\n- **Mixed**: TCP стеки системаро истифода мебарад, дар ҳоле ки gVisor UDP-ро идора мекунад. Ин пешфарз барои mihomo дар Linux аст. Дар Windows, Xray ва mihomo ба таври пешфарз MIPS-ро истифода мебаранд.\n- **System**: стеки системаро истифода мебарад. Варианти дигарро санҷед, агар барномаҳои шабакавӣ ба мушкилот дучор шаванд.\n- **gVisor**: трафикро дар фазои корбарон идора мекунад.\n- **MIPS**: стеки IP-и худи mihomo, ки дар версияи маҷмӯии 1.19.32 дастрас аст.\n\nДар Linux, Xray бо нобаёнӣ gVisor-и дарунсохтро истифода мебарад. System, Mixed ва MIPS дар Linux mihomo-ро ҳамчун муҳаррики TUN истифода мебаранд, TCP ва UDP-ро ба Xray тавассути истиноди SOCKS тасдиқшудаи маҳаллӣ интиқол медиҳанд. Xray протокол, профили провайдер ва масирро нигоҳ медорад. Ин се имконоти насбшуда mihomo талаб мекунанд. Дар Windows, Xray барои ҳамаи чор стеки TUN mihomo 1.19.32 ё навтарро истифода мебарад. Протоколҳо ва масирбандӣ дар Xray мемонанд. Қоидаҳои барномаҳо дар ин пайваст танҳо пайвасти мустақим ва бастанро дастгирӣ мекунанд; дар Linux ин қоидаҳо gVisor-и дарунсохти Xray-ро талаб мекунанд.\n\nПул процесси дуюмро пеш мебарад. Дар се андозагирии бекор дар Linux, он нисбат ба Xray TUN-и аслӣ тақрибан 32–36 МБ зиёдтар хотираи физикиро истифода бурд. Ин сарбории зеркаширо чен намекунад: хароҷоти CPU ва хотира аз пайвастшавӣ вобаста аст. sing-box ягон селектори стек надорад. Ягон стек иҷрои беҳтарро дар ҳар як шабака кафолат намедиҳад. Стекро интихоб кунед ва Apply-ро интихоб кунед ва аз нав пайваст шавед, то онро дар шабакаи худ санҷед.\n\n## Татбиқи танзимот\n\nИнтихоби сервер ба таври худкор дубора пайваст мешавад. Режим, муҳаррик, DNS ва танзимоти қоида фавран захира карда мешаванд; ҳангоми пайвасти фаъол, Apply-ро клик кунед ва барои истифодаи онҳо дубора пайваст шавед. Аз нав ба кор андохтани муҳаррик метавонад зеркашиҳо ва зангҳоро қатъ кунад. Кликҳои такрорӣ пайвастҳои мувозиро оғоз намекунанд; ҷудокунӣ гузаришро ба итмом мерасонад ва пайвастро озод мекунад.\n\nИнтернет танҳо тавассути VPN трафики мустақимро ҳангоми фурӯ рафтани нақб манъ мекунад. Он ба тамоми мошин таъсир мерасонад. Қатъи возеҳ қоидаҳои Sora-ро нест мекунад. Агар тозакунӣ анҷом наёбад, аз нав ҷудо кунед ва сабтро кушоед.\n\n## Ҳуҷҷатҳои лоиҳа\n\n- [sing-box-lx: конфигуратсия ва дастгирӣ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Ҳуҷҷатҳои sing-box](https://sing-box.sagernet.org/)\n- [Ҳуҷҷатҳои Xray](https://xtls.github.io/)\n- [Ҳуҷҷатҳои mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: амалиёт ва маҳдудиятҳо](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC трафики TCP-ро тавассути занги видеоии Jitsi, Яндекс Телемост ё WB Stream мегузаронад. Пайванди olcrtc:// ё рамзи QR-ро ворид кунед. Бо sing-box, Xray ва mihomo дар ҳолатҳои прокси ва TUN кор мекунад; UDP дастгирӣ намешавад. Ба ҳар ду тараф сохторҳои мувофиқи OLC2 лозиманд. Лоиҳаи аслӣ бойгонӣ шудааст.\n';

  @override
  String get probeServers => 'Серверҳоро тафтиш кунед';

  @override
  String get extensions => 'Васеъшавӣ';

  @override
  String extRatingLabel(String rating) {
    return 'Рейтинг $rating аз 5';
  }

  @override
  String extByAuthor(String author) {
    return 'аз ҷониби $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Насбкунӣ: $count';
  }

  @override
  String get extInstallOne => '1 насб';

  @override
  String get extSideloadWarning => 'Танҳо агар ба калиди худимзошудаи муаллиф бовар кунед, насб намоед.';

  @override
  String get extPermissionsWidened => 'Навсозӣ иҷозатҳои навро талаб мекунад:';

  @override
  String get extDangerousAck => 'Ман мефаҳмам, ки ин иҷозатҳо ҷиддӣ ҳастанд';

  @override
  String get extInstall => 'Насб кунед';

  @override
  String get extUpdate => 'Навсозӣ';

  @override
  String get extCancel => 'Бекор кардан';

  @override
  String get extConfirm => 'Тасдиқ кунед';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Васеъкуниҳои насбшуда';

  @override
  String get extSearchHint => 'Ҷустуҷӯи васеъшавиҳо';

  @override
  String get extCatAll => 'Ҳама';

  @override
  String get extCatTools => 'Асбобҳо';

  @override
  String get extCatThemes => 'Мавзӯъҳо';

  @override
  String get extCatAutomation => 'Автоматикунонӣ';

  @override
  String get extCatStats => 'Омор';

  @override
  String get extCatNetwork => 'Шабака';

  @override
  String get extSortBy => 'Мураттабсозӣ аз рӯйи';

  @override
  String get extSortPopular => 'Маъмултарин';

  @override
  String get extSortRating => 'Баҳои баландтарин';

  @override
  String get extSortName => 'Ном';

  @override
  String get extCatalogError => 'Каталогро бор кардан муяссар нашуд';

  @override
  String get extRetry => 'Боз кӯшиш кунед';

  @override
  String get extEmptySearch => 'Ҳеҷ чиз ёфт нашуд';

  @override
  String get extEmptyInstalled =>
      'То ҳол ягон васеъкунӣ насб нашудааст.\nЯкеро дар каталог пайдо кунед ё аз файл насб кунед.';

  @override
  String get extInstallFromFile => 'Аз файл насб кунед';

  @override
  String get extInstallFromUrl => 'Аз URL насб кунед';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Зеркашӣ кунед';

  @override
  String get extDownloading => 'Зеркашӣ карда мешавад…';

  @override
  String get extVerifying => 'Тасдиқ карда мешавад…';

  @override
  String get extInstalling => 'Насб карда мешавад…';

  @override
  String get extInstallFailed => 'Насб карда нашуд';

  @override
  String get extErrSignature => 'Санҷиши имзо ноком шуд. Файл метавонад вайрон ё таҳриф карда шавад.';

  @override
  String get extErrManifest => 'Манифести васеъкунӣ беэътибор аст.';

  @override
  String get extErrNetwork => 'Хатои шабака. Пайвасти худро санҷед ва бори дигар кӯшиш кунед.';

  @override
  String get extErrHash => 'Зеркашӣ ба каталог мувофиқат намекунад. Мумкин аст, ки онро вайрон карда бошанд.';

  @override
  String extErrMinApp(String version) {
    return 'Ин васеъшавӣ версияи барнома $version ё навтарро талаб мекунад.';
  }

  @override
  String get extErrHttpsOnly => 'Танҳо https:// истинодҳо иҷозат дода шудаанд';

  @override
  String get extErrGeneric => 'Чизе хато кард. Лутфан бори дигар кӯшиш кунед.';

  @override
  String get extErrAuthorKeyChanged =>
      'Ин навсозӣ бо калиди дигари муаллиф аз версияи насбшуда имзо шудааст, бинобар ин он баста шуд. Агар шумо ба калиди нав бовар кунед, васеъкуниро нест кунед ва онро дубора насб кунед.';

  @override
  String get extDisabled => 'Хомӯш';

  @override
  String extToggleEnabled(String name) {
    return 'Фаъол $name';
  }

  @override
  String get extSearchInstalled => 'Ҷустуҷӯ дар васеъшавиҳои насбшуда';

  @override
  String get extUpdateAll => 'Ҳамаашро нав кунед';

  @override
  String extUpdatesAvailable(int count) {
    return '$count навсозиҳо дастрасанд';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count нав карда шуд';
  }

  @override
  String get extRiskNormal => 'Муқаррарӣ';

  @override
  String get extRiskSensitive => 'Ҳассос';

  @override
  String get extRiskDangerous => 'Хавфи баланд';

  @override
  String get extPermissionsRemoved => 'Дигар дархост карда намешавад:';

  @override
  String get extUpdateFailedKept => 'Версияи қаблӣ ҳанӯз насб карда шудааст.';

  @override
  String get extConflictsTitle => 'Ихтилофоти васеъшавӣ';

  @override
  String get extConflictTheme => 'Мавзӯи барнома';

  @override
  String get extConflictNetHooks => 'Қалмоқҳои шабакавӣ';

  @override
  String extConflictWinner(String name) {
    return 'Афзалият: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count ихтилофҳо ба қарори шумо ниёз доранд';
  }

  @override
  String get extConflictsResolve => 'ихтилофотро ҳал кунед';

  @override
  String extVersionLabel(String version) {
    return 'Версияи $version';
  }

  @override
  String get extPermissionsTitle => 'Иҷозатҳо';

  @override
  String get extNoPermissions => 'Иҷозатҳои махсус надоранд.';

  @override
  String get extSettings => 'Танзимотҳо';

  @override
  String get extSaveSettings => 'Танзимотро захира кунед';

  @override
  String extUpdateTo(String version) {
    return 'Навсозӣ ба $version';
  }

  @override
  String get extEnabled => 'Фаъол';

  @override
  String extRollbackTo(String version) {
    return 'Бозгашт ба $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Бозгашт ба версияи $version?';
  }

  @override
  String get extUninstall => 'Хориҷ кунед';

  @override
  String extUninstallConfirm(String name) {
    return '\"$name\" ва танзимоти онро нест кунед?';
  }

  @override
  String get extPanelUnavailable => 'Панели васеъшавӣ дастнорас аст.';

  @override
  String get extPermConnectionsRead => 'Ба рӯйхати пайвастҳои фаъол нигаред';

  @override
  String get extPermServersRead => 'Рӯйхати серверҳои худро бубинед';

  @override
  String get extPermSettingsRead => 'Танзимоти барномаро хонед';

  @override
  String get extPermSettingsWrite => 'Танзимоти барномаро тағир диҳед';

  @override
  String get extPermNotifications => 'Огоҳиҳоро нишон диҳед';

  @override
  String get extPermTray => 'Ба менюи табақи ҷузъҳо илова кунед';

  @override
  String get extPermUiPanel => 'Панелҳоро дар дохили барнома нишон диҳед';

  @override
  String get extPermThemeApply => 'Мавзӯъҳоро татбиқ кунед';

  @override
  String get extPermRoutingRules => 'Илова кардани қоидаҳои масир (ба куҷо рафтани трафики шабака таъсир мерасонад)';

  @override
  String get extPermNetHooks => 'Интегратсия ба роҳи шабака (DPI модулҳои гузариш)';

  @override
  String get extPermNetFetch => 'Аз рӯйхати иҷозатдодашуда URL дархост кунед';

  @override
  String get extPermBackground => 'Вазифаҳои заминаро иҷро кунед';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Дар замина кор мекунад';

  @override
  String get extCapNetHook => 'Давр задани маҳдудиятҳо ва қалмоқҳои шабака';

  @override
  String get extCapPanel => 'Панелҳои интерфейс';

  @override
  String get extCapRouting => 'Қоидаҳои масирдиҳӣ';

  @override
  String get extCapTheme => 'Мавзӯъҳо';

  @override
  String get extCapWidget => 'Виҷетҳо';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Тағйирот';

  @override
  String get extImageFailed => 'Тасвирро бор карда натавонист';

  @override
  String get extScreenshots => 'Скриншотҳо';

  @override
  String get extSortRelevance => 'Муносибат';

  @override
  String get extPermNetworkDetail => 'Дархостҳои VPN танҳо ба мизбонҳои зерин иҷозат дода мешаванд.';

  @override
  String get extBgTitle => 'Вазифаи пасзамина';

  @override
  String get extBgEnabled => 'Дар замина иҷро кунед';

  @override
  String get extBgInterval => 'Фосилаи иҷро';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count дақиқа');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count соат');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Барои идоракунии вазифаи пасзамина васеъшавиро фаъол кунед.';

  @override
  String get extCapNetwork => 'Дастрасии шабака';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Шабака: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Ба $name';
  }

  @override
  String get diagnosticHttp => 'Ташхиси HTTP';

  @override
  String get diagnosticNoData => 'Ҳанӯз ягон дархост сабт нашудааст. Аввал вебсайти санҷиши суръатро кушоед.';

  @override
  String get qrShareTitle => 'Рамзи QR мубодила кунед';

  @override
  String get qrScanTitle => 'Рамзи QR скан кунед';

  @override
  String get qrCopyLink => 'Истиноди нусхабардорӣ';

  @override
  String get qrWarning => 'Рамзро танҳо ба шахсони боэътимод нишон диҳед.';

  @override
  String get qrScanHint => 'Скриншот ё акси дорои рамзи QR-ро интихоб кунед ё истинодро гузоред';

  @override
  String get qrFromClipboard => 'Аз буфер часбонед';

  @override
  String get qrNoCode => 'Дар ин тасвир рамзи QR ёфт нашуд.';

  @override
  String get qrInvalid => 'Ин рамзи QR дорои истиноди дуруст нест.';

  @override
  String get qrScan => 'Скан QR';

  @override
  String get qrFromImage => 'Кушодани тасвир';

  @override
  String get connGroupByProcess => 'Аз рӯи раванд гурӯҳбандӣ кунед';

  @override
  String get connListView => 'Рӯйхат';

  @override
  String get connCopyHost => 'Хостро нусхабардорӣ кунед';

  @override
  String get connAddRule => 'Илова кардани қоида';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count пайваст');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Пешакӣ';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Шахсӣ';

  @override
  String get dnsCheck => 'ихроҷи маълумотро тафтиш кунед';

  @override
  String get dnsChecking => 'Санҷиш...';

  @override
  String get dnsNoLeak => 'Ягон ихроҷ ёфт нашуд';

  @override
  String get dnsLeakFound => 'Ихроҷ ошкор шуд';

  @override
  String get dnsLastCheck => 'Санҷиши охирин';

  @override
  String get dnsNeverChecked => 'Ҳанӯз санҷида нашудааст';

  @override
  String get dnsLeakCheckTunnelDns => 'Ҳалкунандаҳои DNS-и нақб';

  @override
  String get dnsLeakCheckSystemResolvers => 'Ҳалкунандаҳои номи система';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Ҳифзи DNS бо бастани шабака';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'DNS-ро барои нақб дар танзимоти DNS дар боло танзим кунед.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Санҷед, ки кадом ҳалкунандаҳои системаи шумо берун аз нақб истифода мешавад.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Бастани шабакаро фаъол кунед, то трафики DNS дар нақб бимонад.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS-и рамзгузоришудаи система';

  @override
  String get dnsLeakCheckDnsSpoof => 'Ҷавобҳои қалбакӣ DNS';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Санҷед, ки кадом нуқтаи ниҳоии рамзгузоришудаи DNS системаи шумо берун аз нақб истифода мебарад.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Дар нақб DNS-и рамзгузоришуда (DoT ё DoH) истифода баред, то ҳалкунандаҳои ном ҷавобҳоро сохта натавонанд.';

  @override
  String get dnsCheckNeedsConnection => 'Аввал ба VPN пайваст шавед, сипас ихроҷро тафтиш кунед.';

  @override
  String get dnsExpected => 'Дар назар аст';

  @override
  String get dnsActual => 'мушохида карда шуд';

  @override
  String get measureSpeed => 'Суръатро чен кунед';

  @override
  String get benchmarkStale => 'кӯҳна шудааст';

  @override
  String get autoSelectMode => 'Сервери худкори интихоб';

  @override
  String get autoSelectPing => 'Пинги зудтарин';

  @override
  String get autoSelectSpeed => 'Суръати баландтарин';

  @override
  String get autoSelectSmart => 'Интихоби оқилона';

  @override
  String get coreWatchUnstable => 'Пайвастшавӣ ба ядрои Sora ноустувор аст';

  @override
  String get watchReconnect => 'Аз нав пайваст кунед';

  @override
  String get crashRestoreTitle => 'Сеанси охирин катъ гардид';

  @override
  String get restoreOnCrash => 'Сеансро пас аз садама барқарор кунед';

  @override
  String get crashRestore => 'Барқарор кардан';

  @override
  String get crashDismiss => 'Ҳоло не';

  @override
  String get overrideTitle => 'Таҳрири ман';

  @override
  String get overrideEdit => 'Серверҳоро таҳрир кунед';

  @override
  String get overrideHide => 'Пинҳон кардан';

  @override
  String get overrideUnhide => 'Намоиш';

  @override
  String get overrideClear => 'Таҳрирҳоро аз нав танзим кунед';

  @override
  String get overrideEmpty => 'Ҳанӯз таҳрир нашудааст';

  @override
  String get overrideCustomRules => 'Қоидаҳои худ';

  @override
  String get errBenchmarkUnsupported => 'Андозагирии суръат ба ядрои навтар ниёз дорад';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Андозаи $done аз $total…';
  }

  @override
  String get profiles => 'Профилҳои шабакавӣ';

  @override
  String get profilesEmpty =>
      'Ҳоло профилҳо нест. Барои ба таври худкор татбиқ кардани танзимот дар шабакаҳои маълум якеро эҷод кунед.';

  @override
  String get profileAdd => 'Профил илова кунед';

  @override
  String get profileName => 'Номи профил';

  @override
  String get profileSsids => 'Wi-Fi шабакаҳо (SSID)';

  @override
  String get profileSsidsHint => 'Хона, Офис бо вергул ҷудо карда шудааст';

  @override
  String get profileGateways => 'Шлюзҳои шабакавӣ';

  @override
  String get profileAsns => 'AS рақамҳо';

  @override
  String get profileAutoApply => 'Ба таври худкор татбиқ кардан';

  @override
  String get profileAutoApplyHint => 'Агар хомӯш бошад, пеш аз татбиқи профил тасдиқ пурсида мешавад.';

  @override
  String get profileSnapshot => 'Танзимоти ҷориро дар хотир доред';

  @override
  String get profileSnapshotDone => 'Танзимоти ҷорӣ дар профил захира карда шудаанд';

  @override
  String get profileDelete => 'Профилро нест кунед';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Профили \"$name\" нест карда шавад?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Профили \"$name\"-ро татбиқ кунед?';
  }

  @override
  String get profileApply => 'Татбиқ кардан';

  @override
  String profileApplied(Object name) {
    return 'Профили \"$name\" татбиқ карда шуд';
  }

  @override
  String get profileUndo => 'Бекор кардан';

  @override
  String get profileActive => 'Фаъол';

  @override
  String networkNow(Object info) {
    return 'Ҳоло: $info';
  }

  @override
  String get networkUnknown => 'Маълумот дар бораи шабака дастрас нест';

  @override
  String get profileNoTriggers => 'Ҳадди ақал як триггер илова кунед: SSID, дарвоза ё ASN';

  @override
  String get chains => 'Занҷирҳои прокси';

  @override
  String get chainsEmpty => 'Ҳанӯз занҷир нест. 2–3 серверро пайваст кунед, то трафик тавассути ҳар яки онҳо гузаред.';

  @override
  String get chainAdd => 'занҷири нав';

  @override
  String get chainName => 'Номи занҷир';

  @override
  String get chainPickServers => '2–3 серверро интихоб кунед';

  @override
  String get chainOrderHint =>
      'Барои аз нав тартиб додан кашола кунед: трафик аз боло ворид мешавад ва аз поён мебарояд.';

  @override
  String get chainTooFew => 'Ақаллан 2 серверро интихоб кунед';

  @override
  String get chainTooMany => 'Як занҷир ҳадди аксар 3 серверро дар бар мегирад';

  @override
  String get chainEstimate => 'Вақти тахминии';

  @override
  String get chainSave => 'Занҷираи захира кунед';

  @override
  String get chainDelete => 'Занҷирро нест кунед';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Занҷираи \"$name\" нест карда шавад?';
  }

  @override
  String get chainUnsupported => 'Мотори ҷорӣ занҷир сохта наметавонад';

  @override
  String get chainHopMissing => 'Яке аз серверҳои занҷир дигар дастрас нест';

  @override
  String chainHop(Object n) {
    return 'Гузариш $n';
  }

  @override
  String get chainEntry => 'Вуруд';

  @override
  String get chainExit => 'Баромад';

  @override
  String get sync => 'Синхронизатсияи дастгоҳ';

  @override
  String get syncDevices => 'Дастгоҳҳои ман';

  @override
  String get syncEmpty => 'Ягон дастгоҳҳои ҷуфтшуда. Дастгоҳи дигарро тавассути шабакаи маҳаллӣ пайваст кунед.';

  @override
  String get syncPair => 'Дастгоҳро ҷуфт кунед';

  @override
  String get syncShowCode => 'Рамзи маро нишон диҳед';

  @override
  String get syncScanCode => 'Рамзи скан';

  @override
  String get syncRevoke => 'Бозхонд';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" бекор карда шавад?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Синхронизатсияи охирин: $time';
  }

  @override
  String get syncNever => 'Ҳеҷ гоҳ';

  @override
  String get syncNoLan => 'Дастгоҳҳо бояд дар як шабакаи маҳаллӣ бошанд';

  @override
  String get syncPaired => 'Дастгоҳ ҷуфт карда шуд';

  @override
  String get syncPairingTitle => 'Бо ин дастгоҳ ҷуфт кунед';

  @override
  String get syncWaiting => 'Дастгоҳи дигар интизор аст…';

  @override
  String get syncSecureNote => 'Канали рамзгузоришуда. Не ҳисобҳо, на серверҳои абрӣ.';

  @override
  String get zapretWithVpn => 'Гузаронидани DPI филтр барои трафики мустақими шабака';

  @override
  String get zapretWithVpnHint =>
      'zapret-ро ҳамроҳи нақби VPN иҷро мекунад: трафики нақб аз VPN ва трафики мустақим аз воситаи давр задани маҳдудият мегузарад.';

  @override
  String get chainDuplicate => 'Ҳар як сервер метавонад танҳо як маротиба пайдо шавад';

  @override
  String get edit => 'Таҳрир';

  @override
  String get remove => 'Хориҷ кунед';

  @override
  String get autoSwitchOnDegrade => 'Гузариши худкор дар таназзул';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Агар сервери интихобшуда хеле суст шавад ё ҷавоб надиҳад, Sora ба сервери беҳтарин аз рӯйи ченкунӣ мегузарад, вале на бештар аз як бор дар ҳар 10 дақиқа.';

  @override
  String get tunStackMixed => 'Омехта';

  @override
  String get tunStackSystem => 'Система';

  @override
  String get customServerAdd => 'Илова кардани сервери фармоишӣ';

  @override
  String get customServers => 'Серверҳои ман';

  @override
  String get customServerName => 'Ном';

  @override
  String get customServerNameHint => 'Масалан: VPS-и ман';

  @override
  String get customServerNameRequired => 'Номро ворид кунед';

  @override
  String get customServerAddress => 'Суроға';

  @override
  String get customServerAddressHint => 'example.com ё 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Суроғаи серверро ворид кунед';

  @override
  String get customServerAddressInvalid => 'Суроғаи нодуруст';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Порт бояд аз 1 то 65535 бошад';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Маълумоти воридшавӣ';

  @override
  String get customServerOptional => 'Ихтиёрӣ';

  @override
  String get customServerShowSecret => 'Сиррро нишон диҳед';

  @override
  String get customServerHideSecret => 'Пинҳон кардани асрор';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Сервери \"$name\" нест карда шавад?';
  }

  @override
  String get customServerTest => 'Санҷиш';

  @override
  String get leakTestTitle => 'Санҷиши ихроҷи маълумот';

  @override
  String get leakTestIntro =>
      'Месанҷад, ки трафик метавонад аз дастгоҳ берун аз нақб барояд ё не: дархостҳои мустақими DNS ва ICMP, баромади IPv6 ва ҳалкунандаҳои номи система. Ҳангоми пайвасти фаъол иҷро кунед.';

  @override
  String get leakTestRun => 'Санҷед';

  @override
  String get leakTestCancel => 'Бекор кардан';

  @override
  String get leakTestNeedsConnection => 'Барои санҷидани ихроҷи маълумот ба VPN пайваст шавед.';

  @override
  String leakTestProgress(int count) {
    return 'Санҷишҳо анҷом ёфтанд: $count';
  }

  @override
  String get leakTestAllClear => 'Ягон ихроҷ ёфт нашуд';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ихроҷ ёфт шуд');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Ислоҳ';

  @override
  String get leakTestFixedNote => 'Бастани шабака фаъол аст. Барои санҷидан озмоишро такрор кунед.';

  @override
  String get leakTestCheckDirectDns => 'мустақим DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP акси садо';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Ҳалкунандаҳои номи система';

  @override
  String get leakTestCheckTunnelConnectivity => 'Пайвасти нақб';

  @override
  String get leakTestCheckTunnelDns => 'DNS тавассути нақб';

  @override
  String get noticeDegraded => 'Сервер суст шуд. Sora ба беҳтарин сервере, ки ҳангоми андозагирӣ ёфт шуд, гузашт.';

  @override
  String get obfs => 'Пинҳонкунии трафик';

  @override
  String get syncCodeExpired => 'Рамз ба охир расид';

  @override
  String get syncDaemonFailed => 'Хидмати ҳамоҳангсозиро оғоз карда натавонист';

  @override
  String get syncDaemonMissing =>
      'Ҷузъи sora-sync ёфт нашуд. Барои фаъол кардани ҳамоҳангсозии дастгоҳ барномаро аз нав насб кунед.';

  @override
  String get syncDaemonStarting => 'Оғози хидмати ҳамоҳангсозӣ…';

  @override
  String get syncErrAuth =>
      'Хидмати ҳамоҳангсозӣ аломати дастрасиро рад кард. Барномаро аз нав оғоз кунед ва бори дигар кӯшиш кунед.';

  @override
  String get syncErrNotFound => 'Дастгоҳ дигар ҷуфт карда нашудааст';

  @override
  String get syncErrPairingActive => 'Сеанси ҷуфткунӣ аллакай кушода аст';

  @override
  String get syncErrUnreachable =>
      'Дастгоҳи дигар ҷавоб надод. Боварӣ ҳосил кунед, ки он дар ҳамон шабака аст ва рамзи онро нишон медиҳад.';

  @override
  String get syncError => 'Хатои синхронизатсия';

  @override
  String syncExpiresIn(String duration) {
    return 'Рамз пас аз $duration беэътибор мешавад';
  }

  @override
  String get syncJoining => 'Ҷуфткунӣ бо дастгоҳ…';

  @override
  String get syncLegacyCleared =>
      'Рӯйхати дастгоҳҳои кӯҳна ҳеҷ гоҳ воқеан ҷуфт карда нашудааст, аз ин рӯ тоза карда шуд. Дастгоҳҳои худро дубора ҷуфт кунед, ин дафъа воқеӣ.';

  @override
  String get syncNewCode => 'Рамзи нав';

  @override
  String syncPairedWith(String name) {
    return '$name ҷуфт шуд';
  }

  @override
  String get syncRetry => 'Такрор кунед';

  @override
  String get syncStopShowing => 'Пинҳон кардани рамз';

  @override
  String get syncSyncNow => 'Ҳозир ҳамоҳанг кардан';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Қабул карда шуд $pulled, фиристодашуда $pushed';
  }

  @override
  String get syncResultTitle => 'Натиҷаи ҳамоҳангсозӣ';

  @override
  String get syncPulled => 'гирифта шудааст';

  @override
  String get syncPushed => 'Фиристода шуд';

  @override
  String get syncNoChanges => 'Ягон тағирот ошкор нашудааст';

  @override
  String get syncDocKindSubscriptions => 'Обунаҳо';

  @override
  String get syncDocKindSettings => 'Танзимоти барнома';

  @override
  String get syncDocKindOverrides => 'Тағйироти шахсии обунаҳо';

  @override
  String get syncDocKindProfiles => 'Профилҳои шабакавӣ';

  @override
  String get syncDocKindChains => 'Занҷирҳои прокси';

  @override
  String syncFrom(String name) {
    return 'аз $name';
  }

  @override
  String get syncThisDevice => 'Ин дастгоҳ';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Гирифтани пакет';

  @override
  String get diagnosticEvents => 'Ҳодисаҳои Windows';

  @override
  String get diagnosticCapture => 'Барои 10 сония сабт кунед';

  @override
  String get diagnosticRequiresTun => 'Забти баста ба пайвасти фаъоли Sora TUN ниёз дорад.';

  @override
  String get diagnosticUnavailable => 'Ин ташхис дар ин платформа дастрас нест.';

  @override
  String get extErrRevoked => 'Дастаи Sora ин версияи васеъкуниро бозхонд, зеро он хатарнок ё вайрон аст.';

  @override
  String get extErrRevocationsExpired => 'Насб то навсозии рӯйхати васеъшавиҳои бозхондшуда баста аст.';

  @override
  String extRevokedDisabled(String names) {
    return 'Васеъкуниҳои бозхондашуда хомӯш шуданд: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Калиди махфӣ';

  @override
  String get customServerWgAddresses => 'Суроғаҳои интерфейс';

  @override
  String get customServerWgPeerKey => 'Калиди ошкори сервер';

  @override
  String get customServerWgPresharedKey => 'Калиди умумӣ';

  @override
  String get customServerWgAllowedIps => 'IP-ҳои иҷозатдодашуда';

  @override
  String get customServerWgKeepalive => 'Keepalive, сония';

  @override
  String get customServerWgKeyInvalid => 'Калид бояд 32 байт дар base64 бошад, мисли он ки wg genkey чоп мекунад.';

  @override
  String get customServerWgCidrInvalid => 'Префиксҳоро бо вергул ворид кунед, масалан 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Шумораи сонияҳоро аз 0 то 65535 ворид кунед.';

  @override
  String get strictKillSwitch => 'Бастани қатъии шабака';

  @override
  String get strictKillSwitchWarning =>
      'Пас аз пайвастшавӣ трафики берун аз VPN-ро ҳатто ҳангоми хато, оғози дубора ё баромадан аз барнома мебандад. Дастрасӣ танҳо пас аз қатъи пайваст ё хомӯш кардани ин танзим барқарор мешавад. Пас аз оғози дубораи дастгоҳ бастан танҳо бо фаъол будани пайвастшавӣ ҳангоми оғоз идома меёбад.';

  @override
  String get extWorkerFailed => 'Вазифаи пасзаминаи васеъкунанда иҷро нашуд. Сабтҳои васеъкунандаро санҷед.';

  @override
  String get extAssetRejected => 'Файли васеъкунанда рад шуд: рангҳои нохоно ё қоидаҳои нодуруст.';

  @override
  String get extVerifiedSora => 'Аз ҷониби Sora санҷида шудааст';

  @override
  String extReceivedBytes(String count) {
    return '$count Б';
  }

  @override
  String get extOpen => 'Кушодан';

  @override
  String get customServerOwn => 'Сервери шахсӣ';

  @override
  String get customServerPaste => 'Гузоштани пайванд';

  @override
  String get customServerUser => 'Номи корбар';

  @override
  String get customServerPassword => 'Рамз';

  @override
  String get customServerSecretRequired => 'Қиматро ворид кунед';

  @override
  String get customServerLinkInvalid => 'Пайванди сервер нодуруст аст';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Хатои дохилии Sora. Рӯзномаро захира кунед ва дар бораи хато хабар диҳед.';

  @override
  String get errTls => 'Сертификати сервер рад шуд. Соатро санҷед ё ба провайдер муроҷиат кунед.';

  @override
  String get errFileAccess => 'Дастрасӣ ба файл нест. Иҷозатҳо ва ҷойи холиро санҷед.';

  @override
  String get errDataLimit => 'Маълумот аз ҳад зиёд аст. Унсурҳои камтар интихоб карда, такрор кунед.';

  @override
  String get errCredentials => 'Маълумоти захирашудаи дастрасӣ нест. Серверро аз нав ворид кунед.';

  @override
  String subscriptionStale(String time) {
    return 'Навсозӣ шуд: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Ҳанӯз навсозӣ нашудааст. Такрор кунед.';

  @override
  String get errHttpStatus => 'Сервер дархостро рад кард. Пайвандро санҷед ё ба провайдер муроҷиат кунед.';

  @override
  String get errInvalidServer => 'Танзимоти сервер нопурра аст ё дастгирӣ намешавад. Обунаро навсозӣ кунед.';

  @override
  String get errServerIds => 'Ду сервер як шиноса доранд. Онҳоро аз нав ворид кунед.';

  @override
  String get errRoutingGroup => 'Масир ба серверҳои нестшуда ё гурӯҳи вайрон ишора мекунад. Обунаро навсозӣ кунед.';

  @override
  String get errConnections => 'Рӯйхати пайвастҳо дастнорас аст. Пайваст шавед ё муҳаррики дигарро интихоб кунед.';

  @override
  String get errLogs => 'Ин хидмат рӯзнома намебарад. Sora-ро навсозӣ кунед.';

  @override
  String get errDiagnostics => 'Ҷамъоварии ташхис нашуд. Такрор кунед ё рӯзномаро захира кунед.';

  @override
  String get errMissingItem => 'Унсури дархостшуда дигар вуҷуд надорад. Рӯйхатро навсозӣ кунед.';

  @override
  String get errInvalidRequest => 'Дархост арзишҳои нодуруст дорад. Маълумоти воридшударо санҷида, такрор кунед.';

  @override
  String get errProxyLogin =>
      'Проксии низом ин вурудро дастгирӣ намекунад. Ном ва гузарвожаи проксии маҳаллиро нест кунед.';

  @override
  String get errLogFilter => 'Филтри рӯзнома нодуруст аст. Ҷустуҷӯро тоза карда, такрор кунед.';

  @override
  String get errSubRedirect => 'Сервер ба суроғаи хатарнок равона кард. Аз провайдер пайванди нав пурсед.';

  @override
  String get errProxySetup => 'Танзими проксии низом нашуд. Аз нав пайваст шавед ё рӯзномаро кушоед.';
}
