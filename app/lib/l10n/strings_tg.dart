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
  String get connEmpty => 'No connections';

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
    return 'Ба $name';
  }

  @override
  String get diagnosticHttp => 'Ташхиси HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Ҳанӯз ягон дархост сабт нашудааст. Аввал вебсайти санҷиши суръатро кушоед.';

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
  String get qrScanHint => 'Скриншот ё акси дорои рамзи QR-ро интихоб кунед ё истинодро гузоред';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Дар ин тасвир рамзи QR ёфт нашуд.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Кушодани тасвир';

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
}
