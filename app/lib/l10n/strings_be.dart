// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class SBe extends S {
  SBe([String locale = 'be']) : super(locale);

  @override
  String get stateOff => 'Не падключана';

  @override
  String get stateConnecting => 'Падключэнне';

  @override
  String get stateConnected => 'Падключана';

  @override
  String get stateReconnecting => 'Паўторнае падключэнне';

  @override
  String get stateDisconnecting => 'Адключэнне';

  @override
  String get coreMissing => 'Служба Sora не адказвае';

  @override
  String get serverAuto => 'Самы хуткі';

  @override
  String get serverBypass => 'Няма сервера';

  @override
  String get addSubscription => 'Дадаць падпіску';

  @override
  String get servers => 'Серверы';

  @override
  String get settings => 'Налады';

  @override
  String get subscription => 'Падпіска';

  @override
  String get subscriptionLink => 'Спасылка на падпіску';

  @override
  String get add => 'Дадаць';

  @override
  String get refresh => 'Абнаўленне';

  @override
  String get rename => 'Перайменаваць';

  @override
  String get delete => 'Выдаліць';

  @override
  String get cancel => 'Адмяніць';

  @override
  String get save => 'Захаваць';

  @override
  String get name => 'Імя';

  @override
  String deleteSubscription(String name) {
    return 'Выдаліць “$name”?';
  }

  @override
  String get routes => 'Маршруты';

  @override
  String get presetGlobal => 'Усё праз VPN';

  @override
  String get presetRu => 'Расія прамая';

  @override
  String get presetIr => 'Іран наўпрост';

  @override
  String get presetCn => 'Кітай наўпрост';

  @override
  String get blockAds => 'Блакіраваць рэкламу';

  @override
  String get killSwitch => 'Інтэрнэт толькі праз VPN';

  @override
  String get engine => 'Рухавік';

  @override
  String get engineAuto => 'Аўто';

  @override
  String get animations => 'Анімацыі';

  @override
  String get logs => 'Журнал';

  @override
  String get about => 'Аб';

  @override
  String get logsAll => 'Усе';

  @override
  String get logsImportant => 'Важны';

  @override
  String get logsErrors => 'Памылкі';

  @override
  String get search => 'Пошук';

  @override
  String get export => 'Захаваць у файл';

  @override
  String get clear => 'Ясна';

  @override
  String get logsEmpty => 'Нічога тут';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get notInstalled => 'Не ўстаноўлены';

  @override
  String get sourceCode => 'Зыходны код';

  @override
  String get license => 'Ліцэнзія';

  @override
  String usage(String used, String total) {
    return '$used з $total';
  }

  @override
  String until(String date) {
    return 'да $date';
  }

  @override
  String get expired => 'Пратэрмінаваны';

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
    return '$n Мб';
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
  String get errGeneric => 'Нешта пайшло не так';

  @override
  String get errCore => 'Служба Sora не адказвае';

  @override
  String get errAuth => 'Няма доступу да службы Sora';

  @override
  String get errVersion => 'Абнаўленне Sora: праграма і сэрвіс маюць розныя версіі';

  @override
  String get errBusy => 'Пачакайце, папярэдняя каманда ўсё яшчэ выконваецца';

  @override
  String get errEngineMissing => 'Для гэтага сервера не знойдзены механізм';

  @override
  String get errEngineStart => 'Рухавік не завёўся';

  @override
  String get errEngineStopped => 'Рухавік спыніўся';

  @override
  String get errTunnel => 'Няма дазволу на стварэнне злучэння VPN';

  @override
  String get errServers => 'Сервер наладжаны з памылкай';

  @override
  String get errNetwork => 'Немагчыма падключыцца да сервера';

  @override
  String get errTimeout => 'Сервер не адказаў своечасова';

  @override
  String get errFirewall => 'Немагчыма заблакіраваць інтэрнэт па-за VPN';

  @override
  String get errSubFetch => 'Не атрымалася загрузіць падпіску';

  @override
  String get errSubFormat => 'Гэта не спасылка для падпіскі';

  @override
  String get errSubEmpty => 'Падпіска не мае сервераў';

  @override
  String get errSubDuplicate => 'Гэта падпіска ўжо дададзена';

  @override
  String get errSubLimit => 'Занадта шмат падпісак';

  @override
  String get errSubScheme => 'Спасылка павінна пачынацца з https://';

  @override
  String get errSecretStore => 'Назапашвальнік Sora пашкоджаны або недаступны';

  @override
  String get errNoServers => 'Каб падключыцца, дадайце падпіску';

  @override
  String get connections => 'Сувязі';

  @override
  String get close => 'Блізка';

  @override
  String get chainDirect => 'Прамы';

  @override
  String get chainBlocked => 'Заблакіраваны';

  @override
  String get theme => 'Тэма';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Святло';

  @override
  String get themeDark => 'Цёмны';

  @override
  String get language => 'мова';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Злучэнне';

  @override
  String get sectionNoServer => 'Няма сервера';

  @override
  String get sectionPing => 'Пінг';

  @override
  String get sectionLog => 'Дыягностыка';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Аўто';

  @override
  String get dnsHint => 'Адрасы праз коску';

  @override
  String get fragment => 'Фрагментацыя TLS';

  @override
  String get fragmentPackets => 'Што падзяліць';

  @override
  String get fragmentLength => 'Памер кавалка';

  @override
  String get fragmentInterval => 'Паўза паміж часткамі';

  @override
  String get byDefault => 'Па змаўчанні';

  @override
  String get rangeHint => 'Напрыклад, 100-200';

  @override
  String get splitPos => 'Раздзяленне пазіцый';

  @override
  String get splitPosHint => 'Напрыклад, 1, midsld';

  @override
  String get disorder => 'Змяніць парадак частак';

  @override
  String get tlsRecord => 'Раздзяліць запіс TLS';

  @override
  String get tlsRecordNo => 'няма';

  @override
  String get tlsRecordSni => 'На назву сайта';

  @override
  String get tlsRecordFirst => 'Пасля першага байта';

  @override
  String get hostCase => 'Змяніць рэгістр хаста';

  @override
  String get probeMethod => 'Метад';

  @override
  String get probeAuto => 'Аўто';

  @override
  String get probeEngine => 'Праз рухавік';

  @override
  String get probeConnect => 'Толькі злучэнне';

  @override
  String get probeUrl => 'Тэставы адрас';

  @override
  String get probeTimeout => 'Пачакай';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Падпіскі';

  @override
  String get subscriptionSettings => 'Налады';

  @override
  String get userAgent => 'Карыстальніцкі агент';

  @override
  String get autoUpdate => 'Аўтаматычнае абнаўленне';

  @override
  String get updateInterval => 'Як часта';

  @override
  String get intervalProvider => 'Як просіць правайдэр';

  @override
  String hours(int n) {
    return '$n ч';
  }

  @override
  String get updateNow => 'Абнавіце зараз';

  @override
  String get logLevel => 'Што запісаць';

  @override
  String get levelDebug => 'усё';

  @override
  String get levelInfo => 'Звычайны';

  @override
  String get levelWarning => 'Важны';

  @override
  String get levelError => 'Толькі памылкі';

  @override
  String get recordDestinations => 'Запіс адрасоў сайтаў';

  @override
  String get reset => 'Скінуць налады';

  @override
  String get resetConfirm => 'Скінуць усе налады?';

  @override
  String get resetAction => 'Скінуць';

  @override
  String get invalidValue => 'Гэта значэнне не будзе працаваць';

  @override
  String get website => 'Старонка падпіскі';

  @override
  String get providerWebsite => 'Сайт правайдэра';

  @override
  String get support => 'Падтрымка';

  @override
  String controlPortQuestion(String engine) {
    return '$engine кіруецца праз порт на гэтым кампутары. Іншыя праграмы змогуць вызначыць, што VPN уключаны.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Выберыце $engine';
  }

  @override
  String get rules => 'Індывідуальныя правілы';

  @override
  String get ruleAdd => 'Новае правіла';

  @override
  String get ruleHint => 'Сайт, IP або праграма';

  @override
  String get ruleDirect => 'Прамы';

  @override
  String get ruleProxy => 'Праз VPN';

  @override
  String get ruleBlock => 'Блок';

  @override
  String get failover => 'Збой уключэння';

  @override
  String get connectOnStart => 'Падключэнне пры запуску';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'падпіска заканчваецца праз # дзён',
      one: 'падпіска заканчваецца праз дзень #',
      zero: 'падпіска заканчваецца праз некалькі гадзін',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left злева';
  }

  @override
  String get ruleInvalid => 'Гэта не падобна на сайт, IP або праграму';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серверы #, самыя хуткія',
      one: 'Сервер #, самы хуткі',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Рэжым';

  @override
  String get tunnelProxy => 'System проксі';

  @override
  String get proxyAddress => 'Адрас проксі';

  @override
  String get copied => 'Скапіравана';

  @override
  String get launchAtLogin => 'Пачніце з сістэмы';

  @override
  String get launchAtLoginDetail => 'Sora аўтаматычна запускаецца пры ўваходзе ў сістэму і застаецца ў трэі.';

  @override
  String get closeToTray => 'Захоўваць у латку ў закрытым выглядзе';

  @override
  String get notifications => 'Апавяшчэнні';

  @override
  String get trayOpen => 'Адкрыйце Sora';

  @override
  String get trayConnect => 'Злучыцца';

  @override
  String get trayDisconnect => 'Адключыцца';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Выйсці з Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora усё яшчэ ў трэі';

  @override
  String get noticeInTrayBody => 'Выйдзіце з меню яго значка';

  @override
  String get noticeLost => 'Злучэнне страчана';

  @override
  String get noticeLostBody => 'Sora паўторна падключаецца';

  @override
  String get noticeRestored => 'Зноў падключаны';

  @override
  String get noticeFailed => 'Не ўдалося падключыцца';

  @override
  String get noticeBackup => 'Галоўны сервер не адказваў; рэзервовая копія пераносіць трафік';

  @override
  String get noticeNext => 'Сервер не адказаў; наступны нясе рух';

  @override
  String get noticeMainBack => 'Галоўны сервер зноў адказвае і пераносіць трафік';

  @override
  String get noticeSubscription => 'Падпіска';

  @override
  String get importTitle => 'Дадаць гэту падпіску?';

  @override
  String get importSealed =>
      'Гэта спасылка зашыфравана для Happ, і толькі Happ можа яе прачытаць. Спытайце ў свайго пастаўшчыка простую спасылку для падпіскі.';

  @override
  String get understood => 'добра';

  @override
  String get noAnswer => 'няма адказу';

  @override
  String get home => 'дадому';

  @override
  String get navRules => 'правілы';

  @override
  String get navConnections => 'Сувязі';

  @override
  String get navLogs => 'Лагі';

  @override
  String get navAbout => 'Аб';

  @override
  String get sidebarToggle => 'Пераключыць бакавую панэль';

  @override
  String get more => 'больш';

  @override
  String get less => 'менш';

  @override
  String get notificationsEmpty => 'Тут з\'явяцца падзеі падключэння і падпіскі';

  @override
  String get retryConnect => 'Паўтарыце падключэнне';

  @override
  String get openLogs => 'Адкрытыя лагі';

  @override
  String get tourReplay => 'Зноў паказаць кіраўніцтва';

  @override
  String tourStep(int step) {
    return 'Крок $step з 5';
  }

  @override
  String get tourBack => 'Назад';

  @override
  String get tourNext => 'Далей';

  @override
  String get tourSkip => 'Прапусціць';

  @override
  String get tourFinish => 'Гатова';

  @override
  String get tourAdd => 'Дадайце спасылку на падпіску вашага правайдэра.';

  @override
  String get tourServer => 'Выберыце сервер. «Самы хуткі» выбірае для вас адзін.';

  @override
  String get tourConnect => 'Націсніце тут, каб падключыцца або адключыцца.';

  @override
  String get tourMode => 'Выберыце рэжым. Kill Switch блакуе Інтэрнэт, калі VPN падае.';

  @override
  String get tourSettings => 'Адкрыйце налады. Вы можаце паўтарыць гэта кіраўніцтва там.';

  @override
  String get chooseProgram => 'Выберыце праграму';

  @override
  String get installedApps => 'Усталяваныя прыкладанні';

  @override
  String get runningProcesses => 'Запушчаныя працэсы';

  @override
  String get programsEmpty => 'Праграмы не знойдзены. Паспрабуйце іншую назву.';

  @override
  String get selectExe => 'Выберыце файл .exe';

  @override
  String get speedtest => 'хуткасць';

  @override
  String get speedtestSearch => 'Знайдзіце паслугу';

  @override
  String get speedtestEmpty => 'Супадзенняў няма. Змяніць пошук.';

  @override
  String get speedtestBackToList => 'Вярнуцца да паслуг';

  @override
  String get speedtestOpenBrowser => 'Адкрыць у браўзеры';

  @override
  String get speedtestUnavailable => 'Не атрымалася запусціць убудаваны браўзер. Адкрыйце службу ў сістэмным браўзеры.';

  @override
  String get speedtestPageFailed =>
      'Не атрымалася загрузіць старонку. Перазагрузіце яго або адкрыйце службу ў сістэмным браўзеры.';

  @override
  String get speedtestExternalFailed => 'Не ўдалося адкрыць сістэмны браўзер. Паспрабуйце яшчэ раз.';

  @override
  String get modes => 'Рэжымы';

  @override
  String get proxyShort => 'Проксі';

  @override
  String get tunMode => 'Увесь рух (TUN)';

  @override
  String get checkUpdates => 'Праверце наяўнасць абнаўленняў';

  @override
  String get updates => 'Абнаўленні праграм';

  @override
  String updateAvailable(String version) {
    return 'Даступная версія $version';
  }

  @override
  String get updateOpenAbout => 'Паглядзець абнаўленне';

  @override
  String updateNotes(String version) {
    return 'Змены ў $version';
  }

  @override
  String get updateCheck => 'Праверце наяўнасць абнаўленняў';

  @override
  String get updateChecking => 'Ідзе праверка...';

  @override
  String get updateNoNotes => 'Рэліз не мае заўваг.';

  @override
  String get updateDropWarning =>
      'VPN-злучэнне абарвецца на некалькі секунд, пакуль Sora і яго асноўнае абнаўленне. Працягнуць?';

  @override
  String get updateWaitConnection => 'Пачакайце, пакуль VPN-злучэнне і ядро ​​будуць гатовыя.';

  @override
  String get updateDownloading => 'Ідзе загрузка і праверка файлаў...';

  @override
  String get updateInstalling => 'Падрыхтоўка абнаўлення або чаканне аўтэнтыфікацыі адміністратара...';

  @override
  String get updateNetworkError => 'Не атрымалася спампаваць абнаўленне. Паспрабуйце яшчэ раз.';

  @override
  String get updateReleaseError => 'Даныя выпуску або неабходныя файлы адсутнічаюць або несапраўдныя.';

  @override
  String get updateChecksumError => 'Загрузка не адпавядае SHA256SUMS. Нічога не было ўстаноўлена.';

  @override
  String get updateInstallError => 'Абнаўленне не завершана. Магчыма, аўтэнтыфікацыя была адменена.';

  @override
  String get updateUnsupported =>
      'Гэты выкананы файл не належыць падтрымоўванай пары пакетаў Sora. Выкарыстоўвайце інструкцыі па ўсталёўцы выпуску.';

  @override
  String get updateManual =>
      'Запусціце гэту каманду ў тэрмінале, каб усталяваць абодва правераныя пакеты, затым зноў адкрыйце Sora. Файлы застаюцца ў каталогу загрузкі. VPN-злучэнне абарвецца.';

  @override
  String get updateSignaturePending =>
      'Файлы абнаўлення зверваюцца з кантрольнымі сумамі, апублікаванымі разам з рэлізам.';

  @override
  String get updateManualSigWarning =>
      'Файлы ніжэй супадаюць з кантрольнымі сумамі рэлізу. Выканайце каманду, калі спампавалі іх з афіцыйнага рэлізу.';

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
  String get updateCopyCommand => 'Капіяваць каманду';

  @override
  String get updateChecksDisabled => 'Аўтаматычныя праверкі адключаны ў наладах.';

  @override
  String get updateInstalled => 'Абнаўленне ўстаноўлена. Паўторна адкрыць Sora.';

  @override
  String get projectLinks => 'Праект';

  @override
  String get githubReleases => 'Рэлізы і спампоўкі';

  @override
  String get telegramChannel => 'Канал Telegram';

  @override
  String get licenses => 'Ліцэнзіі';

  @override
  String get componentLicenses => 'Ліцэнзіі на кампаненты';

  @override
  String get collapseServers => 'Згарнуць серверы';

  @override
  String get expandServers => 'Пашырыць серверы';

  @override
  String get hideDescription => 'Схаваць апісанне';

  @override
  String get showDescription => 'Паказаць апісанне';

  @override
  String get pendingConnectionChanges => 'Падключыцеся паўторна, каб прымяніць гэтыя змены.';

  @override
  String get reconnectNow => 'Падайце заяўку і паўторна падключыцеся';

  @override
  String get errEngineUnsupported =>
      'Абраны механізм не падтрымлівае гэты профіль або налады. Выберыце Аўто або сумяшчальны рухавік.';

  @override
  String get errRestore => 'Ачыстка злучэння была няпоўная. Паўтарыць адключэнне; падрабязнасці глядзіце ў журнале.';

  @override
  String get errSessionEnded => 'Гэты сеанс ужо скончыўся. Абнавіць стан злучэння.';

  @override
  String get retryDisconnect => 'Паўтарыце спробу адключэння';

  @override
  String get tunStack => 'Стэк TUN';

  @override
  String get modesInfo => 'Аб рэжымах';

  @override
  String get modesGuideTitle => 'Рэжымы і рухавікі';

  @override
  String get modesGuide =>
      'Выберыце «Аўта», калі вы не ўпэўненыя, які механізм патрэбны вашаму серверу. Sora правярае профіль і налады перад падключэннем. Механізм не можа павялічыць прапускную здольнасць вашага плана: прадукцыйнасць залежыць ад сервера, маршруту, пратакола і сеткі.\n\n## Рэжымы\n\n### Увесь трафік (TUN)\n\nSora стварае віртуальны сеткавы інтэрфейс і накіроўвае праз яго трафік прыкладанняў, уключаючы TCP і UDP. Выкарыстоўвайце гэты рэжым для Telegram, гульняў і голасу Discord. Правілы могуць адпраўляць пэўныя сайты або праграмы непасрэдна або блакіраваць іх. Сеткавай службе патрэбны дазвол і сервер, які падтрымлівае патрэбны пратакол.\n\n### System проксі\n\nSora канфігуруе лакальны проксі HTTP/SOCKS. Праграмы, якія выконваюць сістэмныя налады проксі, выкарыстоўваюць яго. Прыкладанні з уласным сеткавым стэкам могуць падключацца напрамую; UDP і галасавыя выклікі звычайна патрабуюць TUN. Гэты рэжым падыходзіць для браўзераў і праграм з падтрымкай проксі.\n\n### Няма сервера\n\nНа Linux Sora выкарыстоўвае [zapret](https://github.com/bol-van/zapret) для падзелу і змены формы запытаў HTTP/TLS і абыходу некаторых праверак DPI. Ваш IP-адрас застаецца ранейшым, і злучэнне ідзе непасрэдна на вэб-сайт. Вынікі залежаць ад вашага правайдэра і спосабу блакіроўкі.\n\nБягучая інтэграцыя выкарыстоўвае tpws для HTTP і TLS праз TCP. Ён не абыходзіць блакіроўку IP і не рэтранслюе UDP і не можа гарантаваць злучэнні MTProto Telegram. Выкарыстоўвайце сервер VPN з TUN для голасу Discord, выклікаў Telegram і такіх абмежаванняў.\n\n## Рухавікі\n\n### Аўта\n\nSora выбірае ўсталяваны механізм, які падтрымлівае ўвесь план злучэння: пратаколы сервера, транспарты, групы, фрагментацыю і рэжым. Несумяшчальны ручной выбар адхіляецца перад спыненнем бягучага злучэння. Выберыце «Аўта» або іншы механізм і прымяніце налады яшчэ раз.\n\n### sing-box\n\nНовыя пакеты Sora уключаюць [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box), дадаючы на ​​баку кліента XHTTP і VLESS Encryption. Sora распазнае зборку і яе магчымасці. Верхняя зборка без XHTTP не атрымлівае гэтай магчымасці толькі з-за назвы.\n\nПадтрымліваюцца пратаколы VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard і параметры AmneziaWG 1.x/2.x Sora можна імпартаваць. Поўныя профілі Xray JSON патрабуюць Xray. Новыя палі AWG 3.x пакуль нельга імпартаваць. sing-box выкарыстоўвае лакальны порт кіравання, абаронены паролем, які могуць выявіць іншыя прыкладанні на кампутары.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) падтрымлівае VLESS, REALITY, XHTTP, VLESS Encryption і фрагментацыю TLS. Ён таксама запускае поўныя профілі правайдэраў Xray, захоўваючы іх маршрутызацыю і групы. Такія профілі нельга аўтаматычна пераўтварыць у іншы рухавік без змены іх паводзін.\n\nУ камплекце Xray выдалена налада, якая адключае праверку сертыфіката TLS (`allowInsecure`). Аўтаматычна выбірае sing-box або mihomo для звычайных сервераў, якія патрабуюць гэтай налады. Выбар Xray паведамляе аб несумяшчальнасці ўручную перад спыненнем бягучага злучэння. Для старых поўных профіляў JSON патрабуецца абноўлены профіль пастаўшчыка з сертыфікатам, які можна правяраць, або PIN-кодам сертыфіката.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) падтрымлівае ўпарадкаваныя рэзервовыя групы і групы балансавання нагрузкі, XHTTP і AmneziaWG. Выберыце яго, калі важны аўтаматычны пераход на рэзервовы сервер. Налада фрагментацыі TLS Sora недаступная з гэтым рухавіком.\n\n## Сумяшчальнасць у Sora\n\n| Функцыя | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN і TCP/UDP | Так | Так | Так |\n| XHTTP | Так | Так | Так |\n| VLESS Encryption | Так | Так | Так |\n| Поўны профіль Xray | Няма | Так | Няма |\n| TUIC / AnyTLS | Абодва | Няма | TUIC |\n| Фрагментацыя TLS | Так | Так | Няма |\n| AmneziaWG 1.x/2.x | Так¹ | Няма | Так |\n| Упарадкаваная рэзервовая група | Няма | №² | Так |\n\n¹ Профілі з J1/J2/J3/Itime выкарыстоўваюць mihomo; гэтыя палі ніколі не павінны моўчкі адкідвацца. ² Для групы поўных профіляў Xray праграма выбірае рэзервовы профіль. Падтрымка залежыць ад усталяванай зборкі; праверце яго версію ў About.\n\n## Стэк TUN\n\nСтэк апрацоўвае TCP і UDP у віртуальным інтэрфейсе. На панэлі рэжымаў Xray і mihomo прапануюць gVisor, System, Mixed і MIPS. Кожны рухавік захоўвае свае перавагі. Рэжымы System проксі і бессерверны не выкарыстоўваюць гэты параметр.\n\n- **Mixed**: TCP выкарыстоўвае сістэмны стэк, а gVisor апрацоўвае UDP. Гэта варыянт па змаўчанні для mihomo у Linux. У Windows Xray і mihomo па змаўчанні выкарыстоўваюць MIPS.\n- **System**: выкарыстоўвае сістэмны стэк. Паспрабуйце іншы варыянт, калі сеткавыя праграмы сутыкнуцца з праблемамі.\n- **gVisor**: апрацоўвае трафік у карыстальніцкай прасторы.\n- **MIPS**: уласны IP-стэк mihomo, даступны ў камплектаванай версіі 1.19.32.\n\nНа Linux Xray выкарыстоўвае ўбудаваны gVisor па змаўчанні. System, Mixed і MIPS на Linux выкарыстоўваюць mihomo у якасці рухавіка TUN, перанакіроўваючы TCP і UDP на Xray па аўтэнтыфікаванай лакальнай спасылцы SOCKS. Xray захоўвае пратакол, профіль правайдэра і маршрутызацыю. Гэтыя тры варыянты патрабуюць усталяванага mihomo. На Windows Xray выкарыстоўвае mihomo 1.19.32 або навейшы для ўсіх чатырох стэкаў TUN. Пратаколы і маршрутызацыя застаюцца ў Xray. Правілы праграм у гэтай звязцы падтрымліваюць толькі прамое злучэнне і блакіроўку; на Linux яны патрабуюць убудаванага gVisor Xray.\n\nМост запускае другі працэс. У трох вымярэннях без працы на Linux ён выкарыстаў прыблізна на 32–36 МіБ больш фізічнай памяці, чым уласны Xray TUN. Гэта не вымярае загрузку загрузкі: кошт працэсара і памяці залежыць ад злучэнняў. sing-box не мае селектара стэка. Ні адзін стэк не гарантуе лепшай прадукцыйнасці ў любой сетцы. Выберыце стэк і выберыце «Ужыць» і паўторна падключыцеся, каб паспрабаваць яго ў вашай сетцы.\n\n## Прымяненне налад\n\nПры выбары сервера падключэнне адбываецца аўтаматычна. Налады рэжыму, рухавіка, DNS і правіл захоўваюцца неадкладна; падчас актыўнага злучэння націсніце \"Ужыць\" і паўторна падключыцеся, каб выкарыстоўваць іх. Перазапуск рухавіка можа перапыніць загрузку і выклікі. Паўторныя пстрычкі не запускаюць паралельныя злучэнні; адключэнне завяршае пераход і вызваляе злучэнне.\n\nІнтэрнэт толькі праз VPN блакуе прамы трафік пры абрыве тунэля. Гэта ўплывае на ўсю машыну. Яўнае адключэнне выдаляе правілы Sora. Калі ачыстка не завершана, паўтарыце спробу адключэння і адкрыйце журнал.\n\n## Праектная дакументацыя\n\n- [sing-box-lx: канфігурацыя і падтрымка] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box дакументацыя] (https://sing-box.sagernet.org/)\n- [Xray дакументацыя](https://xtls.github.io/)\n- [Дакументацыя mihomo] (https://wiki.metacubex.one/)\n- [zapret: праца і абмежаванні] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Праверце серверы';

  @override
  String get extensions => 'Пашырэнні';

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
      'Гэтыя пашырэнні прэтэндуюць на адно і тое ж. Выберыце, якое будзе працаваць, другое застанецца ўсталяваным.';

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
      'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

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
    return 'Cached catalog, $date';
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
      'Загружае даныя з інтэрнэту праз VPN. Дазволены толькі хасты са спіса ніжэй, астатнія заблакаваны.';

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
      'Задача запускаецца па раскладзе, пакуль Sora адкрыта, у тым ліку згорнутай у трэй. Мінімальны інтэрвал 15 хвілін.';

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
    return 'У $name';
  }

  @override
  String get diagnosticHttp => 'HTTP дыягностыка';

  @override
  String get diagnosticNoData => 'Пакуль няма запісаных запытаў. Спачатку адкрыйце вэб-сайт для праверкі хуткасці.';

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
  String get qrScanHint => 'Выберыце здымак экрана або фота з QR-кодам ці ўстаўце спасылку';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'На выяве не знойдзены QR-код.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Адкрыць выяву';

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
  String get profileSsidsHint => 'Home, Office, comma separated';

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
      'If the selected server slows down a lot or stops answering, Sora switches to the best measured one, at most once every 10 minutes.';

  @override
  String get tunStackMixed => 'Mixed';

  @override
  String get tunStackSystem => 'System';

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
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Add a server manually: address, port and protocol';

  @override
  String get customServerTest => 'Test';

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
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Kill switch is on, run the test again to verify.';

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
  String get noticeDegraded => 'The server slowed down, switched to the best measured one';

  @override
  String get obfs => 'Traffic obfuscation';

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
      'The old device list was never actually paired, so it was cleared. Pair your devices again, for real this time.';

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
    return 'Received $pulled, sent $pushed';
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
  String syncFrom(String name) {
    return 'from $name';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Для Shadowsocks: метад:пароль, напрыклад chacha20-ietf-poly1305:пароль';

  @override
  String get diagnosticPackets => 'Захоп пакета';

  @override
  String get diagnosticEvents => 'Windows падзеі';

  @override
  String get diagnosticCapture => 'Захоп на 10 секунд';

  @override
  String get diagnosticRequiresTun => 'Для захопу пакетаў патрабуецца актыўнае злучэнне Sora TUN.';

  @override
  String get diagnosticUnavailable => 'Гэтая дыягностыка недаступная на гэтай платформе.';

  @override
  String get extErrRevoked => 'Каманда Sora адклікала гэтую версію пашырэння: яна небяспечная або зламаная.';

  @override
  String get extErrRevocationsExpired =>
      'Не ўдалося абнавіць спіс адкліканых пашырэнняў. Усталёўка недаступная, пакуль ён не абновіцца: праверце сетку і паспрабуйце зноў.';

  @override
  String extRevokedDisabled(String names) {
    return 'Адкліканыя пашырэнні выключаны: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Прыватны ключ';

  @override
  String get customServerWgAddresses => 'Адрасы інтэрфейсу';

  @override
  String get customServerWgPeerKey => 'Публічны ключ сервера';

  @override
  String get customServerWgPresharedKey => 'Агульны ключ';

  @override
  String get customServerWgAllowedIps => 'Дазволеныя IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, секунд';

  @override
  String get customServerWgKeyInvalid => 'Ключ павінен быць 32 байтамі ў base64, як выводзіць wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'Пакажыце адрасы праз коску ў выглядзе 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Пакажыце колькасць секунд ад 0 да 65535.';

  @override
  String get strictKillSwitch => 'Строгі kill switch';

  @override
  String get strictKillSwitchWarning =>
      'Пасля падключэння блакуе трафік па-за VPN нават пасля збою, перазапуску ці выхаду з праграмы. Доступ вернецца толькі пасля адключэння VPN або гэтай налады. Пасля перазагрузкі блакаванне аднаўляецца толькі пры ўключаным падключэнні пры запуску.';

  @override
  String get extWorkerFailed => 'Фонавае заданне пашырэння не выканана. Праверце журнал пашырэння.';

  @override
  String get extAssetRejected => 'Файл пашырэння адхілены: неразборлівыя колеры або няправільныя правілы.';
}
