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
  String get stateFailed => 'Пайваст нест';

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
  String speedMbps(double value) {
    return '${value.toStringAsFixed(1)} Mbps';
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
  String get errTunnel => 'Иҷозат барои эҷоди пайвасти VPN нест';

  @override
  String get errServers => 'Сервер бо хатогӣ танзим шудааст';

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
  String get exportText => 'Матн';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Нур';

  @override
  String get themeDark => 'Торик';

  @override
  String get language => 'Забон';

  @override
  String get languageSystem => 'System';

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
      other: 'обуна дар рӯзҳои # ба охир мерасад',
      one: 'обуна дар рӯзи # ба охир мерасад',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серверҳои #, дар навбати худ',
      one: 'Сервери #, дар навбати худ',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серверҳои #, зудтарин',
      one: 'Сервери #, зудтарин',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelTun => 'Ҳама трафик';

  @override
  String get tunnelProxy => 'Прокси System';

  @override
  String get proxyAddress => 'Суроғаи прокси';

  @override
  String get copied => 'Нусхабардорӣ';

  @override
  String get launchAtLogin => 'Бо система оғоз кунед';

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
  String get currentServer => 'Сервери ҷорӣ';

  @override
  String get trafficDown => 'Боргиришуда';

  @override
  String get trafficUp => 'Бор карда шуд';

  @override
  String perSecond(String value) {
    return '$value/с';
  }

  @override
  String activeRules(int count) {
    return 'Қоидаҳои фаъол: $count';
  }

  @override
  String get recentNotifications => 'Огоҳиҳои охирин';

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
  String get programsFailed => 'Барномаҳо бор карда нашуд';

  @override
  String get programsEmpty => 'Ягон барнома ёфт нашуд. Номи дигарро санҷед.';

  @override
  String get selectExe => 'Файли .exe-ро интихоб кунед';

  @override
  String get trafficUnavailable => 'Ҳисобкунакҳо ҳанӯз дастрас нестанд';

  @override
  String get speedtest => 'Суръат';

  @override
  String get speedtestCheck => 'Суръатро тафтиш кунед';

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
  String get appCopyright => '© 2026 levvs-one ва саҳмгузорон';

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
  String get bypassLimitations =>
      'Ин режим DPI-ро танҳо барои HTTP ва TLS мегузарад, UDP-ро дастгирӣ намекунад ё IP-и шуморо тағир намедиҳад. Барои садои Discord, зангҳо ва суроғаҳои басташудаи Telegram сервери VPN-ро истифода баред.';

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
      'Агар шумо боварӣ надошта бошед, ки ба сервери шумо ба кадом муҳаррик ниёз дорад, Auto-ро интихоб кунед. Sora пеш аз пайвастшавӣ профил ва танзимотро тафтиш мекунад. Муҳаррик наметавонад маҷрои нақшаи шуморо зиёд кунад: иҷроиш аз сервер, масир, протокол ва шабака вобаста аст.\n\n## Модҳо\n\n### Ҳама трафик (TUN)\n\nSora интерфейси шабакаи маҷозӣ эҷод мекунад ва трафики барномаҳоро тавассути он, аз ҷумла TCP ва UDP, масир мекунад. Ин режимро барои Telegram, бозиҳо ва овози Discord истифода баред. Қоидаҳо метавонанд сайтҳо ё барномаҳои мушаххасро мустақиман фиристанд ё онҳоро маҳкам кунанд. Хидмати шабака ба иҷозат ва сервере ниёз дорад, ки протоколи лозимиро дастгирӣ мекунад.\n\n### Прокси System\n\nSora прокси маҳаллии HTTP/SOCKS-ро танзим мекунад. Барномаҳое, ки танзимоти прокси системаро эҳтиром мекунанд, онро истифода мебаранд. Барномаҳо бо стеки шабакавии худ метавонанд мустақиман пайваст шаванд; UDP ва зангҳои овозӣ умуман ба TUN ниёз доранд. Ин режим ба браузерҳо ва барномаҳо бо дастгирии прокси мувофиқат мекунад.\n\n### Сервер нест\n\nДар Linux, Sora [zapret](https://github.com/bol-van/zapret) -ро барои тақсим кардан ва тағир додани дархостҳои HTTP/TLS ва гузаштан аз баъзе санҷишҳои DPI истифода мебарад. IP-и шумо бетағйир мемонад ва пайвастҳо мустақиман ба вебсайт мераванд. Натиҷаҳо аз провайдери шумо ва усули басташавӣ вобастаанд.\n\nИнтегратсияи ҷорӣ tpws-ро барои HTTP ва TLS тавассути TCP истифода мебарад. Он масдудкунии IP ё интиқоли UDP-ро фаро намегирад ва пайвастҳои Telegram-и MTProto-ро кафолат дода наметавонад. Сервери VPN-ро бо TUN барои овози Discord, зангҳои Telegram ва ин гуна маҳдудиятҳо истифода баред.\n\n## Моторҳо\n\n### Авто\n\nSora муҳаррики насбшударо интихоб мекунад, ки тамоми нақшаи пайвастшавиро дастгирӣ мекунад: протоколҳои сервер, интиқолҳо, гурӯҳҳо, тақсимот ва режим. Интихоби дастӣ номувофиқ пеш аз қатъ кардани пайвасти ҷорӣ рад карда мешавад. Авто ё муҳаррики дигарро интихоб кунед ва танзимотро дубора татбиқ кунед.\n\n### sing-box\n\nБастаҳои нави Sora иборатанд аз [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), як фардкунандаи [sing-box](https://github.com/SagerNet/sing-box), илова кардани муштарии XHTTP ва VLESS Encryption. Sora сохтмон ва қобилиятҳои онро эътироф мекунад. Сохтмони болооб бидуни XHTTP ин қобилиятро танҳо аз номи худ ба даст намеорад.\n\nПротоколҳои дастгирӣшаванда VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard ва Z8x/parameters. Sora метавонад ворид кунад. Профилҳои пурраи Xray JSON Xray-ро талаб мекунанд. Майдонҳои нави AWG 3.x ҳанӯз ворид карда намешаванд. sing-box порти назорати маҳаллии бо парол ҳифзшударо истифода мебарад, ки дигар замимаҳои компютер метавонанд онро ошкор кунанд.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) пораҳои VLESS, REALITY, XHTTP, VLESS Encryption ва TLS-ро дастгирӣ мекунад. Он инчунин профилҳои пурраи провайдери Xray -ро ҳангоми нигоҳ доштани масир ва гурӯҳҳои онҳо иҷро мекунад. Чунин профилҳоро бидуни тағир додани рафтори худ ба таври худкор ба муҳаррики дигар табдил додан мумкин нест.\n\nXray маҷмӯӣ танзимеро, ки санҷиши сертификати TLS-ро ғайрифаъол мекунад (`allowInsecure`) хориҷ кард. Барои серверҳои оддӣ, ки ин танзимотро талаб мекунанд, худкор sing-box ё mihomo-ро интихоб мекунад. Интихоби Xray пеш аз қатъ кардани пайвасти ҷорӣ дастӣ дар бораи номувофиқатӣ хабар медиҳад. Профилҳои пурраи JSON-и кӯҳна ба профили провайдери навшуда бо шаҳодатномаи тасдиқшаванда ё PIN сертификат ниёз доранд.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) гурӯҳҳои фармоишии бозгашт ва мувозинати сарборӣ, XHTTP ва AmneziaWG -ро дастгирӣ мекунад. Вақте ки интиқоли автоматӣ ба сервери эҳтиётӣ муҳим аст, онро интихоб кунед. Танзими тақсимоти TLS-и Sora бо ин муҳаррик дастнорас аст.\n\n## Мутобиқат дар Sora\n\n| Хусусият | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN ва TCP/UDP | Бале | Бале | Бале |\n| XHTTP | Бале | Бале | Бале |\n| VLESS Encryption | Бале | Бале | Бале |\n| Профили пурраи Xray | Не | Бале | Не |\n| TUIC / AnyTLS | Ҳарду | Не | TUIC |\n| Фрагментатсияи TLS | Бале | Бале | Не |\n| AmneziaWG 1.x/2.x | Ҳа¹ | Не | Бале |\n| Гурӯҳи бозгашти фармоишӣ | Не | No² | Бале |\n\n¹ Профилҳо бо J1/J2/J3/Itime mihomo-ро истифода мебаранд; ин майдонхоро хеч гох хомушона партофтан лозим нест. ² Барои як гурӯҳи профилҳои пурраи Xray, барнома профили эҳтиётиро интихоб мекунад. Дастгирӣ аз сохтори насбшуда вобаста аст; версияи онро дар бораи санҷед.\n\n## Стеки TUN\n\nСтек TCP ва UDP-ро дар дохили интерфейси виртуалӣ идора мекунад. Дар панели режимҳо, Xray ва mihomo gVisor, System, Mixed ва MIPS -ро пешниҳод мекунанд. Ҳар як муҳаррик афзалияти худро захира мекунад. System прокси ва режимҳои бе сервер ин афзалиятро истифода намебаранд.\n\n- **Mixed** — TCP стеки системаро истифода мебарад, дар ҳоле ки gVisor UDP-ро идора мекунад. Ин пешфарз барои mihomo дар Linux аст. Дар Windows, Xray ва mihomo ба таври пешфарз MIPS-ро истифода мебаранд.\n- **System** — стеки системаро истифода мебарад. Варианти дигарро санҷед, агар барномаҳои шабакавӣ ба мушкилот дучор шаванд.\n- **gVisor** — трафикро дар фазои корбарон идора мекунад.\n- **MIPS** — стеки IP-и худи mihomo, ки дар версияи маҷмӯии 1.19.32 дастрас аст.\n\nДар Linux, Xray бо нобаёнӣ gVisor-и дарунсохтро истифода мебарад. System, Mixed ва MIPS дар Linux mihomo-ро ҳамчун муҳаррики TUN истифода мебаранд, TCP ва UDP-ро ба Xray тавассути истиноди SOCKS тасдиқшудаи маҳаллӣ интиқол медиҳанд. Xray протокол, профили провайдер ва масирро нигоҳ медорад. Ин се имконоти насбшуда mihomo талаб мекунанд. Дар Windows, Xray барои ҳамаи чор стеки TUN mihomo 1.19.32 ё навтарро истифода мебарад. Протоколҳо ва масирбандӣ дар Xray мемонанд. Қоидаҳои барномаҳо дар ин пайваст танҳо пайвасти мустақим ва бастанро дастгирӣ мекунанд; дар Linux ин қоидаҳо gVisor-и дарунсохти Xray-ро талаб мекунанд.\n\nПул процесси дуюмро пеш мебарад. Дар се андозагирии бекор дар Linux, он нисбат ба Xray TUN-и аслӣ тақрибан 32–36 МБ зиёдтар хотираи физикиро истифода бурд. Ин сарбории зеркаширо чен намекунад: хароҷоти CPU ва хотира аз пайвастшавӣ вобаста аст. sing-box ягон селектори стек надорад. Ягон стек иҷрои беҳтарро дар ҳар як шабака кафолат намедиҳад. Стекро интихоб кунед ва Apply-ро интихоб кунед ва аз нав пайваст шавед, то онро дар шабакаи худ санҷед.\n\n## Татбиқи танзимот\n\nИнтихоби сервер ба таври худкор дубора пайваст мешавад. Режим, муҳаррик, DNS ва танзимоти қоида фавран захира карда мешаванд; ҳангоми пайвасти фаъол, Apply-ро клик кунед ва барои истифодаи онҳо дубора пайваст шавед. Аз нав ба кор андохтани муҳаррик метавонад зеркашиҳо ва зангҳоро қатъ кунад. Кликҳои такрорӣ пайвастҳои мувозиро оғоз намекунанд; ҷудокунӣ гузаришро ба итмом мерасонад ва пайвастро озод мекунад.\n\nИнтернет танҳо тавассути VPN трафики мустақимро ҳангоми фурӯ рафтани нақб манъ мекунад. Он ба тамоми мошин таъсир мерасонад. Қатъи возеҳ қоидаҳои Sora-ро нест мекунад. Агар тозакунӣ анҷом наёбад, аз нав ҷудо кунед ва сабтро кушоед.\n\n## Ҳуҷҷатҳои лоиҳа\n\n- [sing-box-lx: конфигуратсия ва дастгирӣ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Ҳуҷҷатҳои sing-box](https://sing-box.sagernet.org/)\n- [Ҳуҷҷатҳои Xray](https://xtls.github.io/)\n- [Ҳуҷҷатҳои mihomo](https://wiki.metacubex.one/)\n- [zapret: амалиёт ва маҳдудиятҳо](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Серверҳоро тафтиш кунед';

  @override
  String get extensions => 'Васеъшавӣ';

  @override
  String get extensionsSoon => 'Ба зудӣ';

  @override
  String exportLogFile(String name) {
    return 'Ба $name';
  }

  @override
  String get diagnosticHttp => 'Ташхиси HTTP';

  @override
  String get diagnosticPackets => 'Гирифтани пакет';

  @override
  String get diagnosticEvents => 'Ҳодисаҳои Windows';

  @override
  String get diagnosticCapture => 'Барои 10 сония сабт кунед';

  @override
  String get diagnosticNoData => 'Ҳанӯз ягон дархост сабт нашудааст. Аввал вебсайти санҷиши суръатро кушоед.';

  @override
  String get diagnosticRequiresTun => 'Забти баста ба пайвасти фаъоли Sora TUN ниёз дорад.';

  @override
  String get diagnosticUnavailable => 'Ин ташхис дар ин платформа дастрас нест.';
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
  String get connConnections => 'connections';
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
