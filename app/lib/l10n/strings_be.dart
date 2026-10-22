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
  String get connEmpty => 'Няма сувязяў';

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
  String get themeSystem => 'Як у сістэме';

  @override
  String get themeLight => 'Святло';

  @override
  String get themeDark => 'Цёмны';

  @override
  String get language => 'мова';

  @override
  String get languageSystem => 'Як у сістэме';

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
  String get updateVersionRevoked => 'Распрацоўшчык адклікаў гэтую версію. Дачакайцеся выпраўленага выпуску.';

  @override
  String get updateRolloutPending => 'Новая версія разгортваецца паступова і будзе прапанавана вам аўтаматычна.';

  @override
  String updateRollbacking(String version) {
    return 'Адкат да версіі $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Абнаўленне да $version не прайшло праверку спраўнасці, таму Sora быў адкачаны да $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Збой аўтаматычнага адкату. Калі новая версія не працуе, пераўсталюйце папярэднюю версію ўручную.';

  @override
  String get updateRollbackCacheError =>
      'Не атрымалася падрыхтаваць правераную адкатую копію бягучай версіі, таму абнаўленне не было ўстаноўлена.';

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
      'Выберыце «Аўта», калі вы не ўпэўненыя, які механізм патрэбны вашаму серверу. Sora правярае профіль і налады перад падключэннем. Механізм не можа павялічыць прапускную здольнасць вашага плана: прадукцыйнасць залежыць ад сервера, маршруту, пратакола і сеткі.\n\n## Рэжымы\n\n### Увесь трафік (TUN)\n\nSora стварае віртуальны сеткавы інтэрфейс і накіроўвае праз яго трафік прыкладанняў, уключаючы TCP і UDP. Выкарыстоўвайце гэты рэжым для Telegram, гульняў і голасу Discord. Правілы могуць адпраўляць пэўныя сайты або праграмы непасрэдна або блакіраваць іх. Сеткавай службе патрэбны дазвол і сервер, які падтрымлівае патрэбны пратакол.\n\n### System проксі\n\nSora канфігуруе лакальны проксі HTTP/SOCKS. Праграмы, якія выконваюць сістэмныя налады проксі, выкарыстоўваюць яго. Прыкладанні з уласным сеткавым стэкам могуць падключацца напрамую; UDP і галасавыя выклікі звычайна патрабуюць TUN. Гэты рэжым падыходзіць для браўзераў і праграм з падтрымкай проксі.\n\n### Няма сервера\n\nНа Linux Sora выкарыстоўвае [zapret](https://github.com/bol-van/zapret) для падзелу і змены формы запытаў HTTP/TLS і абыходу некаторых праверак DPI. Ваш IP-адрас застаецца ранейшым, і злучэнне ідзе непасрэдна на вэб-сайт. Вынікі залежаць ад вашага правайдэра і спосабу блакіроўкі.\n\nБягучая інтэграцыя выкарыстоўвае tpws для HTTP і TLS праз TCP. Ён не абыходзіць блакіроўку IP і не рэтранслюе UDP і не можа гарантаваць злучэнні MTProto Telegram. Выкарыстоўвайце сервер VPN з TUN для голасу Discord, выклікаў Telegram і такіх абмежаванняў.\n\n## Рухавікі\n\n### Аўта\n\nSora выбірае ўсталяваны механізм, які падтрымлівае ўвесь план злучэння: пратаколы сервера, транспарты, групы, фрагментацыю і рэжым. Несумяшчальны ручной выбар адхіляецца перад спыненнем бягучага злучэння. Выберыце «Аўта» або іншы механізм і прымяніце налады яшчэ раз.\n\n### sing-box\n\nНовыя пакеты Sora уключаюць [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box), дадаючы на ​​баку кліента XHTTP і VLESS Encryption. Sora распазнае зборку і яе магчымасці. Верхняя зборка без XHTTP не атрымлівае гэтай магчымасці толькі з-за назвы.\n\nПадтрымліваюцца пратаколы VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard і параметры AmneziaWG 1.x/2.x Sora можна імпартаваць. Поўныя профілі Xray JSON патрабуюць Xray. Новыя палі AWG 3.x пакуль нельга імпартаваць. sing-box выкарыстоўвае лакальны порт кіравання, абаронены паролем, які могуць выявіць іншыя прыкладанні на кампутары.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) падтрымлівае VLESS, REALITY, XHTTP, VLESS Encryption і фрагментацыю TLS. Ён таксама запускае поўныя профілі правайдэраў Xray, захоўваючы іх маршрутызацыю і групы. Такія профілі нельга аўтаматычна пераўтварыць у іншы рухавік без змены іх паводзін.\n\nУ камплекце Xray выдалена налада, якая адключае праверку сертыфіката TLS (`allowInsecure`). Аўтаматычна выбірае sing-box або mihomo для звычайных сервераў, якія патрабуюць гэтай налады. Выбар Xray паведамляе аб несумяшчальнасці ўручную перад спыненнем бягучага злучэння. Для старых поўных профіляў JSON патрабуецца абноўлены профіль пастаўшчыка з сертыфікатам, які можна правяраць, або PIN-кодам сертыфіката.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) падтрымлівае ўпарадкаваныя рэзервовыя групы і групы балансавання нагрузкі, XHTTP і AmneziaWG. Выберыце яго, калі важны аўтаматычны пераход на рэзервовы сервер. Налада фрагментацыі TLS Sora недаступная з гэтым рухавіком.\n\n## Сумяшчальнасць у Sora\n\n| Функцыя | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN і TCP/UDP | Так | Так | Так |\n| XHTTP | Так | Так | Так |\n| VLESS Encryption | Так | Так | Так |\n| Поўны профіль Xray | Няма | Так | Няма |\n| TUIC / AnyTLS | Абодва | Няма | TUIC |\n| mieru | Няма | Няма | Так |\n| NaiveProxy | Так | Няма | Няма |\n| Фрагментацыя TLS | Так | Так | Няма |\n| AmneziaWG 1.x/2.x | Так¹ | Няма | Так |\n| Упарадкаваная рэзервовая група | Няма | №² | Так |\n\n¹ Профілі з J1/J2/J3/Itime выкарыстоўваюць mihomo; гэтыя палі ніколі не павінны моўчкі адкідвацца. ² Для групы поўных профіляў Xray праграма выбірае рэзервовы профіль. Падтрымка залежыць ад усталяванай зборкі; праверце яго версію ў About.\n\n## Стэк TUN\n\nСтэк апрацоўвае TCP і UDP у віртуальным інтэрфейсе. На панэлі рэжымаў Xray і mihomo прапануюць gVisor, System, Mixed і MIPS. Кожны рухавік захоўвае свае перавагі. Рэжымы System проксі і бессерверны не выкарыстоўваюць гэты параметр.\n\n- **Mixed**: TCP выкарыстоўвае сістэмны стэк, а gVisor апрацоўвае UDP. Гэта варыянт па змаўчанні для mihomo у Linux. У Windows Xray і mihomo па змаўчанні выкарыстоўваюць MIPS.\n- **System**: выкарыстоўвае сістэмны стэк. Паспрабуйце іншы варыянт, калі сеткавыя праграмы сутыкнуцца з праблемамі.\n- **gVisor**: апрацоўвае трафік у карыстальніцкай прасторы.\n- **MIPS**: уласны IP-стэк mihomo, даступны ў камплектаванай версіі 1.19.32.\n\nНа Linux Xray выкарыстоўвае ўбудаваны gVisor па змаўчанні. System, Mixed і MIPS на Linux выкарыстоўваюць mihomo у якасці рухавіка TUN, перанакіроўваючы TCP і UDP на Xray па аўтэнтыфікаванай лакальнай спасылцы SOCKS. Xray захоўвае пратакол, профіль правайдэра і маршрутызацыю. Гэтыя тры варыянты патрабуюць усталяванага mihomo. На Windows Xray выкарыстоўвае mihomo 1.19.32 або навейшы для ўсіх чатырох стэкаў TUN. Пратаколы і маршрутызацыя застаюцца ў Xray. Правілы праграм у гэтай звязцы падтрымліваюць толькі прамое злучэнне і блакіроўку; на Linux яны патрабуюць убудаванага gVisor Xray.\n\nМост запускае другі працэс. У трох вымярэннях без працы на Linux ён выкарыстаў прыблізна на 32–36 МіБ больш фізічнай памяці, чым уласны Xray TUN. Гэта не вымярае загрузку загрузкі: кошт працэсара і памяці залежыць ад злучэнняў. sing-box не мае селектара стэка. Ні адзін стэк не гарантуе лепшай прадукцыйнасці ў любой сетцы. Выберыце стэк і выберыце «Ужыць» і паўторна падключыцеся, каб паспрабаваць яго ў вашай сетцы.\n\n## Прымяненне налад\n\nПры выбары сервера падключэнне адбываецца аўтаматычна. Налады рэжыму, рухавіка, DNS і правіл захоўваюцца неадкладна; падчас актыўнага злучэння націсніце \"Ужыць\" і паўторна падключыцеся, каб выкарыстоўваць іх. Перазапуск рухавіка можа перапыніць загрузку і выклікі. Паўторныя пстрычкі не запускаюць паралельныя злучэнні; адключэнне завяршае пераход і вызваляе злучэнне.\n\nІнтэрнэт толькі праз VPN блакуе прамы трафік пры абрыве тунэля. Гэта ўплывае на ўсю машыну. Яўнае адключэнне выдаляе правілы Sora. Калі ачыстка не завершана, паўтарыце спробу адключэння і адкрыйце журнал.\n\n## Праектная дакументацыя\n\n- [sing-box-lx: канфігурацыя і падтрымка] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box дакументацыя] (https://sing-box.sagernet.org/)\n- [Xray дакументацыя](https://xtls.github.io/)\n- [Дакументацыя mihomo] (https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: праца і абмежаванні] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC перадае TCP праз відэазванок у Jitsi, Яндэкс Тэлемосце або WB Stream. Імпартуйце спасылку olcrtc:// або QR-код. Пратакол працуе з sing-box, Xray і mihomo ў рэжымах проксі і TUN; UDP не падтрымліваецца. Абодвум бакам патрэбныя сумяшчальныя зборкі OLC2. Зыходны праект архіваваны.\n';

  @override
  String get probeServers => 'Праверце серверы';

  @override
  String get extensions => 'Пашырэнні';

  @override
  String extRatingLabel(String rating) {
    return 'Рэйтынг $rating з 5';
  }

  @override
  String extByAuthor(String author) {
    return 'ад $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Усталёўкі: $count';
  }

  @override
  String get extInstallOne => '1 усталяванне';

  @override
  String get extBadgeVerified => 'Праверана';

  @override
  String get extBadgeTop => 'Самы папулярны на гэтым тыдні';

  @override
  String get extBadgeNew => 'Новы';

  @override
  String get extBadgeStaff => 'Каманда Sora';

  @override
  String get extSideloadShort => 'Не з каталога';

  @override
  String get extSideloadWarning =>
      'Гэта пашырэнне не з каталога каманды. Толькі аўтар ручаўся за свой ключ: усталёўвайце яго толькі ў тым выпадку, калі давяраеце аўтару.';

  @override
  String extInstallTitle(String name) {
    return 'Усталяваць «$name»';
  }

  @override
  String extUpdateTitle(String name) {
    return 'Абнавіць «$name»';
  }

  @override
  String get extPermissionsIntro => 'Гэта пашырэнне зможа:';

  @override
  String get extPermissionsWidened => 'Абнаўленне запытвае новыя дазволы:';

  @override
  String get extDangerousAck => 'Я разумею, што гэтыя дазволы сур\'ёзныя';

  @override
  String get extInstall => 'Усталяваць';

  @override
  String get extUpdate => 'Абнавіць';

  @override
  String get extCancel => 'Адмена';

  @override
  String get extConfirm => 'Пацвердзіць';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Усталяваныя пашырэнні';

  @override
  String get extSearchHint => 'Пошук пашырэнняў';

  @override
  String get extCatAll => 'Усе';

  @override
  String get extCatTools => 'Інструменты';

  @override
  String get extCatThemes => 'Тэмы';

  @override
  String get extCatAutomation => 'Аўтаматызацыя';

  @override
  String get extCatStats => 'Статыстыка';

  @override
  String get extCatNetwork => 'Сетка';

  @override
  String get extSortBy => 'Сартаваць па';

  @override
  String get extSortPopular => 'Самы папулярны';

  @override
  String get extSortRating => 'Самы высокі рэйтынг';

  @override
  String get extSortName => 'Імя';

  @override
  String get extCatalogError => 'Не атрымалася загрузіць каталог';

  @override
  String get extRetry => 'Паўтарыць';

  @override
  String get extEmptySearch => 'Нічога не знойдзена';

  @override
  String get extEmptyInstalled => 'Пашырэнні пакуль не ўсталяваны.\nЗнайдзіце ў каталогу або ўсталюйце з файла.';

  @override
  String get extInstallFromFile => 'Усталяваць з файла';

  @override
  String get extInstallFromUrl => 'Усталяваць з URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Спампаваць';

  @override
  String get extDownloading => 'Спампоўка…';

  @override
  String get extVerifying => 'Ідзе праверка…';

  @override
  String get extInstalling => 'Усталяванне…';

  @override
  String get extInstallFailed => 'Збой усталявання';

  @override
  String get extErrSignature => 'Праверка подпісу не атрымалася. Файл можа быць пашкоджаны або падроблены.';

  @override
  String get extErrManifest => 'Маніфест пашырэння несапраўдны.';

  @override
  String get extErrNetwork => 'Памылка сеткі. Праверце падключэнне і паўтарыце спробу.';

  @override
  String get extErrHash => 'Загрузка не адпавядае каталогу. Магчыма, яго падрабілі.';

  @override
  String extErrMinApp(String version) {
    return 'Для гэтага пашырэння патрэбна праграма версіі $version або навейшай.';
  }

  @override
  String get extErrHttpsOnly => 'Дазваляюцца толькі спасылкі https://';

  @override
  String get extErrGeneric => 'Нешта пайшло не так. Калі ласка, паспрабуйце яшчэ раз.';

  @override
  String get extErrAuthorKeyChanged =>
      'Гэта абнаўленне падпісана іншым ключом аўтара, чым усталяваная версія, таму яно было заблакіравана. Калі вы давяраеце новаму ключу, выдаліце ​​пашырэнне і ўсталюйце яго зноў відавочна.';

  @override
  String get extUpdateAvailable => 'Абнаўленне даступна';

  @override
  String get extDisabled => 'Выключана';

  @override
  String extToggleEnabled(String name) {
    return 'Уключыць $name';
  }

  @override
  String get extSearchInstalled => 'Пошук сярод усталяваных';

  @override
  String get extUpdateAll => 'Абнавіць усё';

  @override
  String extUpdatesAvailable(int count) {
    return 'Даступныя абнаўленні $count';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count абноўлены';
  }

  @override
  String get extRiskNormal => 'Нармальны';

  @override
  String get extRiskSensitive => 'Адчувальны';

  @override
  String get extRiskDangerous => 'Высокая рызыка';

  @override
  String get extPermissionsRemoved => 'Больш не патрабуецца:';

  @override
  String get extUpdateFailedKept => 'Папярэдняя версія ўсё яшчэ ўсталявана.';

  @override
  String get extConflictsTitle => 'Канфлікты пашырэнняў';

  @override
  String get extConflictsIntro =>
      'Гэтыя пашырэнні прэтэндуюць на адно і тое ж. Выберыце, якое будзе працаваць, другое застанецца ўсталяваным.';

  @override
  String get extConflictTheme => 'Тэма прыкладання';

  @override
  String get extConflictNetHooks => 'Сеткавыя хукі';

  @override
  String extConflictWinner(String name) {
    return 'Перавага: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'Канфлікты $count патрабуюць вашага рашэння';
  }

  @override
  String get extConflictsResolve => 'Вырашаць канфлікты';

  @override
  String get extConflictNote =>
      'Выбар захоўваецца на гэтай прыладзе. Тэма пераключаецца адразу, сеткавыя хукі ў гэтай версіі не запускаюцца.';

  @override
  String extVersionLabel(String version) {
    return 'Версія $version';
  }

  @override
  String get extAuthor => 'Аўтар';

  @override
  String get extRating => 'Рэйтынг';

  @override
  String get extInstalls => 'Усталяванні';

  @override
  String get extVersion => 'Версія';

  @override
  String get extAbout => 'Аб гэтым пашырэнні';

  @override
  String get extPermissionsTitle => 'Дазволы';

  @override
  String get extNoPermissions => 'Няма спецыяльных дазволаў.';

  @override
  String get extSettings => 'Налады';

  @override
  String get extSaveSettings => 'Захаваць налады';

  @override
  String get extSaving => 'Захаванне…';

  @override
  String extUpdateTo(String version) {
    return 'Абнавіць да $version';
  }

  @override
  String get extEnabled => 'Уключана';

  @override
  String extRollbackTo(String version) {
    return 'Адкаціць да $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Адкаціць да версіі $version?';
  }

  @override
  String get extUninstall => 'Выдаліць';

  @override
  String extUninstallConfirm(String name) {
    return 'Выдаліць “$name” і яго налады?';
  }

  @override
  String get extPanelUnavailable => 'Панэль недаступная. Магчыма, пашырэнне было адключана або выдалена.';

  @override
  String get extPermConnectionsRead => 'Бачыць спіс актыўных злучэнняў';

  @override
  String get extPermServersRead => 'Бачыць спіс вашых сервераў';

  @override
  String get extPermSettingsRead => 'Чытанне налад праграмы';

  @override
  String get extPermSettingsWrite => 'Змена налад праграмы';

  @override
  String get extPermNotifications => 'Паказаць апавяшчэнні';

  @override
  String get extPermTray => 'Дадаваць пункты ў меню трэя';

  @override
  String get extPermUiPanel => 'Паказаць панэлі ўнутры праграмы';

  @override
  String get extPermThemeApply => 'Ужываць тэмы афармлення';

  @override
  String get extPermRoutingRules => 'Дадаць правілы маршрутызацыі (уплываюць на тое, куды ідзе сеткавы трафік)';

  @override
  String get extPermNetHooks => 'Інтэграцыя ў сеткавы шлях (модулі абыходу DPI)';

  @override
  String get extPermNetFetch => 'Запытваць URL з дазволенага спісу';

  @override
  String get extPermBackground => 'Запуск фонавых задач';

  @override
  String get extPermBackgroundDetail =>
      'Запускае запланаваныя задачы, нават калі панэль закрыта. Вы можаце прыпыніць яго або змяніць частату яго запуску ў наладах пашырэння.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Працуе ў фонавым рэжыме';

  @override
  String get extCapNetHook => 'Абыходы блакаванняў і сеткавыя хукі';

  @override
  String get extCapPanel => 'Інтэрфейсныя панэлі';

  @override
  String get extCapRouting => 'Правілы маршрутызацыі';

  @override
  String get extCapTheme => 'Тэмы';

  @override
  String get extCapWidget => 'Віджэты';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Журнал змяненняў';

  @override
  String get extImageFailed => 'Не ўдалося загрузіць выяву';

  @override
  String get extRatingHow => 'Як працуюць рэйтынгі';

  @override
  String get extRatingHowBody =>
      'У ацэнках выкарыстоўваецца байесаўскае сярэдняе: пашырэнне з невялікай колькасцю ацэнак застаецца каля сярэдзіны, пакуль не прагаласуе больш людзей, таму адна 5-зоркавая рэцэнзія не можа падштурхнуць новае пашырэнне да вяршыні. Нядаўнія рэйтынгі важаць больш, чым старыя, і лічыцца толькі адзін рэйтынг на ўліковы запіс.';

  @override
  String get extScreenshots => 'Скрыншоты';

  @override
  String get extSortRelevance => 'Актуальнасць';

  @override
  String get extPermNetworkDetail =>
      'Загружае даныя з інтэрнэту праз VPN. Дазволены толькі хасты са спіса ніжэй, астатнія заблакаваны.';

  @override
  String get extBgTitle => 'Фонавая задача';

  @override
  String get extBgEnabled => 'Выконваць у фоне';

  @override
  String get extBgInterval => 'Запускаць кожныя';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# хвіліны',
      many: '# хвілін',
      few: '# хвіліны',
      one: '# хвіліна',
    );
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# гадзіны',
      many: '# гадзін',
      few: '# гадзіны',
      one: '# гадзіна',
    );
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'Задача запускаецца па раскладзе, пакуль Sora адкрыта, у тым ліку згорнутай у трэй. Мінімальны інтэрвал 15 хвілін.';

  @override
  String get extBgDisabledNote => 'Уключыце пашырэнне для кіравання фонавымі задачамі.';

  @override
  String get extCapNetwork => 'Доступ да сеткі';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Сетка: $hosts';
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
  String get qrShareTitle => 'Падзяліцца QR-кодам';

  @override
  String get qrScanTitle => 'Сканаваць QR-код';

  @override
  String get qrCopyLink => 'Скапіраваць спасылку';

  @override
  String get qrShowLink => 'Паказаць спасылку';

  @override
  String get qrHideLink => 'Схаваць спасылку';

  @override
  String get qrWarning => 'Гэты код QR змяшчае падрабязнасці злучэння. Не паказвайце староннім.';

  @override
  String get qrScanHint => 'Выберыце здымак экрана або фота з QR-кодам ці ўстаўце спасылку';

  @override
  String get qrFromClipboard => 'Уставіць з буфера абмену';

  @override
  String get qrNoCode => 'На выяве не знойдзены QR-код.';

  @override
  String get qrInvalid => 'Гэты код QR не змяшчае сапраўднай спасылкі.';

  @override
  String get qrScan => 'Сканаваць QR';

  @override
  String get qrFromImage => 'Адкрыць выяву';

  @override
  String get connGroupByProcess => 'Група па працэсе';

  @override
  String get connListView => 'Спісам';

  @override
  String get connCopyHost => 'Капіяваць хост';

  @override
  String get connAddRule => 'Дадаць правіла';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# злучэння',
      many: '# злучэнняў',
      few: '# злучэнні',
      one: '# злучэнне',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Прэсе';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Уласны';

  @override
  String get dnsCheck => 'Праверце наяўнасць уцечак дадзеных';

  @override
  String get dnsChecking => 'Праверка...';

  @override
  String get dnsNoLeak => 'Уцечак не знойдзена';

  @override
  String get dnsLeakFound => 'Выяўленая ўцечка';

  @override
  String get dnsLastCheck => 'Апошняя праверка';

  @override
  String get dnsNeverChecked => 'Яшчэ не правяралася';

  @override
  String get dnsLeakCheckTunnelDns => 'Рэзолверы DNS тунэля';

  @override
  String get dnsLeakCheckSystemResolvers => 'Сістэмныя рэзолверы';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Абарона DNS праз kill switch';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Наладзьце DNS для тунэля ў наладах DNS вышэй.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Праверце, якія рэзолверы ваша сістэма будзе выкарыстоўваць па-за тунэлем.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Уключыце kill switch, каб трафік DNS заставаўся ў тунэлі.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Зашыфраваны DNS сістэмы';

  @override
  String get dnsLeakCheckDnsSpoof => 'Падробленыя адказы DNS';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Праверце, якія зашыфраваныя канечныя кропкі DNS выкарыстоўвае ваша сістэма па-за тунэлем.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Выкарыстоўвайце зашыфраваны DNS (DoT або DoH) у тунэлі, каб рэзолверы не маглі падрабляць адказы.';

  @override
  String get dnsCheckNeedsConnection => 'Спачатку падключыцеся да VPN, потым праверце на ўцечкі.';

  @override
  String get dnsExpected => 'Чакаецца';

  @override
  String get dnsActual => 'Назіраецца';

  @override
  String get sortBy => 'Сартаваць па';

  @override
  String get sortPing => 'Пінг';

  @override
  String get sortSpeed => 'Хуткасць';

  @override
  String get sortName => 'Імя';

  @override
  String get measureSpeed => 'Вымераць хуткасць';

  @override
  String get benchmarkStale => 'састарэлі';

  @override
  String get autoSelectMode => 'Аўтаматычны выбар сервера';

  @override
  String get autoSelectPing => 'Самы хуткі пінг';

  @override
  String get autoSelectSpeed => 'Самая высокая хуткасць';

  @override
  String get autoSelectSmart => 'Разумны выбар';

  @override
  String get coreWatchUnstable => 'Злучэнне з ядром Sora нестабільнае';

  @override
  String get watchReconnect => 'Перападключыць';

  @override
  String get coreRestoringLink => 'Аднаўленне злучэння з ядром Sora…';

  @override
  String get crashRestoreTitle => 'Апошні сеанс быў перапынены';

  @override
  String get restoreOnCrash => 'Аднавіць сеанс пасля збою';

  @override
  String get crashRestore => 'Аднавіць';

  @override
  String get crashDismiss => 'Не цяпер';

  @override
  String get overrideTitle => 'Мае праўкі';

  @override
  String get overrideEdit => 'Рэдагаваць серверы';

  @override
  String get overrideHide => 'Схаваць';

  @override
  String get overrideUnhide => 'Паказаць';

  @override
  String get overrideClear => 'Скінуць праўкі';

  @override
  String get overrideEmpty => 'Пакуль няма правак';

  @override
  String get overrideCustomRules => 'Свае правілы';

  @override
  String get errBenchmarkUnsupported => 'Вымярэнне хуткасці патрабуе больш новага ядра';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Замер $done з $total…';
  }

  @override
  String get profiles => 'Сеткавыя профілі';

  @override
  String get profilesEmpty => 'Профіляў пакуль няма. Стварыце яго для аўтаматычнага прымянення налад у вядомых сетках.';

  @override
  String get profileAdd => 'Дадаць профіль';

  @override
  String get profileName => 'Назва профілю';

  @override
  String get profileSsids => 'Wi-Fi сеткі (SSID)';

  @override
  String get profileSsidsHint => 'Дом, Офіс праз коску';

  @override
  String get profileGateways => 'Сеткавыя шлюзы';

  @override
  String get profileAsns => 'Нумары AS';

  @override
  String get profileAutoApply => 'Ужыць аўтаматычна';

  @override
  String get profileAutoApplyHint => 'Калі выключана, пытацца перад ужываннем профілю.';

  @override
  String get profileSnapshot => 'Запомніць бягучыя наладкі';

  @override
  String get profileSnapshotDone => 'Бягучыя налады захаваны ў профілі';

  @override
  String get profileDelete => 'Выдаліць профіль';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Выдаліць профіль \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Прымяніць профіль \"$name\"?';
  }

  @override
  String get profileApply => 'Ужыць';

  @override
  String profileApplied(Object name) {
    return 'Профіль «$name» ужыты';
  }

  @override
  String get profileUndo => 'Адмяніць';

  @override
  String get profileActive => 'Актыўны';

  @override
  String networkNow(Object info) {
    return 'Зараз: $info';
  }

  @override
  String get networkUnknown => 'Інфармацыя пра сетку недаступная';

  @override
  String get profileNoTriggers => 'Дадайце хаця б адзін трыгер: SSID, шлюз або ASN';

  @override
  String get chains => 'Ланцужкі проксі';

  @override
  String get chainsEmpty => 'Ланцугоў пакуль няма. Звяжыце 2–3 серверы, каб трафік скакаў праз кожны з іх.';

  @override
  String get chainAdd => 'Новы ланцуг';

  @override
  String get chainName => 'Назва ланцуга';

  @override
  String get chainPickServers => 'Выберыце 2–3 серверы';

  @override
  String get chainOrderHint => 'Перацягніце, каб змяніць парадак: трафік уваходзіць зверху і выходзіць знізу.';

  @override
  String get chainTooFew => 'Выберыце як мінімум 2 серверы';

  @override
  String get chainTooMany => 'Ланцужок змяшчае не больш за 3 серверы';

  @override
  String get chainEstimate => 'Разліковая затрымка';

  @override
  String get chainSave => 'Захаваць ланцужок';

  @override
  String get chainDelete => 'Выдаліць ланцужок';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Выдаліць ланцужок \"$name\"?';
  }

  @override
  String get chainUnsupported => 'Цяперашні рухавік не можа будаваць ланцугі';

  @override
  String get chainHopMissing => 'Адзін з сервераў ланцужка больш не даступны';

  @override
  String chainHop(Object n) {
    return 'Пераход $n';
  }

  @override
  String get chainEntry => 'Уваход';

  @override
  String get chainExit => 'Выхад';

  @override
  String get sync => 'Сінхранізацыя прылад';

  @override
  String get syncDevices => 'Мае прылады';

  @override
  String get syncEmpty => 'Няма спалучаных прылад. Спалучэнне іншай прылады праз лакальную сетку.';

  @override
  String get syncPair => 'Спалучыць прыладу';

  @override
  String get syncShowCode => 'Паказаць мой код';

  @override
  String get syncScanCode => 'Сканаваць код';

  @override
  String get syncRevoke => 'Адклікаць';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Адклікаць \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Апошняя сінхранізацыя: $time';
  }

  @override
  String get syncNever => 'Ніколі';

  @override
  String get syncNoLan => 'Прылады павінны знаходзіцца ў адной лакальнай сетцы';

  @override
  String get syncPaired => 'Прылада спаранае';

  @override
  String get syncPairingTitle => 'Спалучыць з гэтай прыладай';

  @override
  String get syncWaiting => 'Чаканне іншай прылады…';

  @override
  String get syncSecureNote => 'Канал са скразным шыфраваннем. Ні ўліковых запісаў, ні хмарных сервераў.';

  @override
  String get zapretWithVpn => 'Абыход фільтрацыі DPI для прамога сеткавага трафіку';

  @override
  String get zapretWithVpnHint =>
      'Запускае zapret разам з VPN-тунэлем: трафік тунэля ідзе праз VPN, а прамы трафік праз сродак абыходу блакаванняў.';

  @override
  String get chainDuplicate => 'Кожны сервер можа з\'явіцца толькі адзін раз';

  @override
  String get edit => 'Рэдагаваць';

  @override
  String get remove => 'Выдаліць';

  @override
  String get autoSwitchOnDegrade => 'Аўтаматычнае пераключэнне пры дэградацыі';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Калі выбраны сервер моцна запавольваецца або перастае адказваць, Sora пераключаецца на найлепшы паводле вымярэнняў, але не часцей за раз на 10 хвілін.';

  @override
  String get tunStackMixed => 'Змешаны';

  @override
  String get tunStackSystem => 'Сістэмны';

  @override
  String get customServerAdd => 'Дадаць уласны сервер';

  @override
  String get customServers => 'Мае серверы';

  @override
  String get customServerName => 'Назва';

  @override
  String get customServerNameHint => 'Напрыклад: мой VPS';

  @override
  String get customServerNameRequired => 'Увядзіце назву';

  @override
  String get customServerAddress => 'Адрас';

  @override
  String get customServerAddressHint => 'example.com або 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Увядзіце адрас сервера';

  @override
  String get customServerAddressInvalid => 'Няправільны адрас';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Порт павінен быць лікам ад 1 да 65535';

  @override
  String get customServerProtocol => 'Пратакол';

  @override
  String get customServerCredentials => 'Даныя для ўваходу';

  @override
  String get customServerOptional => 'Неабавязкова';

  @override
  String get customServerShowSecret => 'Паказаць сакрэт';

  @override
  String get customServerHideSecret => 'Схаваць сакрэт';

  @override
  String get customServerBadge => 'уласны';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Выдаліць сервер “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Дадайце сервер уручную: адрас, порт і пратакол';

  @override
  String get customServerTest => 'Тэст';

  @override
  String get leakTestTitle => 'Тэст на ўцечку даных';

  @override
  String get leakTestIntro =>
      'Правярае, ці можа трафік пакінуць прыладу па-за тунэлем: прамыя запыты DNS і ICMP, выхад IPv6 і сістэмныя рэзолверы. Запускайце пры актыўным злучэнні.';

  @override
  String get leakTestRun => 'Праверыць';

  @override
  String get leakTestCancel => 'Адмена';

  @override
  String get leakTestNeedsConnection => 'Падключыцеся да VPN, каб праверыць наяўнасць уцечак дадзеных.';

  @override
  String leakTestProgress(int count) {
    return 'Выпрабаванні завершаны: $count';
  }

  @override
  String get leakTestAllClear => 'Уцечак не знойдзена';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Знойдзена # уцечкі',
      many: 'Знойдзена # уцечак',
      few: 'Знойдзены # уцечкі',
      one: 'Знойдзена # уцечка',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Выправіць';

  @override
  String get leakTestFixedNote => 'Kill switch уключаны. Паўтарыце праверку.';

  @override
  String get leakTestCheckDirectDns => 'Прамы DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP рэха';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Сістэмныя рэзолверы';

  @override
  String get leakTestCheckTunnelConnectivity => 'Тунэльная сувязь';

  @override
  String get leakTestCheckTunnelDns => 'DNS праз тунэль';

  @override
  String get noticeDegraded => 'Сервер стаў павольным. Sora пераключыўся на лепшы сервер, знойдзены падчас вымярэння.';

  @override
  String get obfs => 'Маскіроўка трафіку';

  @override
  String get syncCodeExpired => 'Тэрмін дзеяння кода скончыўся';

  @override
  String get syncDaemonFailed => 'Не атрымалася запусціць службу сінхранізацыі';

  @override
  String get syncDaemonMissing =>
      'Кампанент sora-sync не знойдзены. Пераўсталюйце праграму, каб уключыць сінхранізацыю прылады.';

  @override
  String get syncDaemonStarting => 'Запуск службы сінхранізацыі…';

  @override
  String get syncErrAuth => 'Служба сінхранізацыі адхіліла маркер доступу. Перазапусціце праграму і паўтарыце спробу.';

  @override
  String get syncErrNotFound => 'Прылада больш не спалучана';

  @override
  String get syncErrPairingActive => 'Сеанс спалучэння ўжо адкрыты';

  @override
  String get syncErrUnreachable =>
      'Іншая прылада не адказвала. Пераканайцеся, што ён знаходзіцца ў той жа сетцы і паказвае яго код.';

  @override
  String get syncError => 'Памылка сінхранізацыі';

  @override
  String syncExpiresIn(String duration) {
    return 'Тэрмін дзеяння кода скончыцца праз $duration';
  }

  @override
  String get syncJoining => 'Спалучэнне з прыладай…';

  @override
  String get syncLegacyCleared =>
      'Стары спіс прылад ніколі не спалучаўся, таму ён быў ачышчаны. Зноў спалучыце прылады, на гэты раз па-сапраўднаму.';

  @override
  String get syncNewCode => 'Новы код';

  @override
  String syncPairedWith(String name) {
    return 'У пары з $name';
  }

  @override
  String get syncRetry => 'Паўтарыць';

  @override
  String get syncStopShowing => 'Схаваць код';

  @override
  String get syncSyncNow => 'Сінхранізаваць';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Атрымана $pulled, адпраўлена $pushed';
  }

  @override
  String get syncResultTitle => 'Вынік сінхранізацыі';

  @override
  String get syncPulled => 'Атрымана';

  @override
  String get syncPushed => 'Адпраўлена';

  @override
  String get syncNoChanges => 'Зменаў не выяўлена';

  @override
  String get syncDocKindSubscriptions => 'Падпіскі';

  @override
  String get syncDocKindSettings => 'Налады праграмы';

  @override
  String get syncDocKindOverrides => 'Перавызначэнні падпісак';

  @override
  String get syncDocKindProfiles => 'Сеткавыя профілі';

  @override
  String get syncDocKindChains => 'Ланцужкі проксі';

  @override
  String syncFrom(String name) {
    return 'з $name';
  }

  @override
  String get syncThisDevice => 'Гэтая прылада';

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
