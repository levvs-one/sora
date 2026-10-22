// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Armenian (`hy`).
class SHy extends S {
  SHy([String locale = 'hy']) : super(locale);

  @override
  String get stateOff => 'Միացված չէ';

  @override
  String get stateConnecting => 'Միացում';

  @override
  String get stateConnected => 'Միացված է';

  @override
  String get stateReconnecting => 'Վերամիացում';

  @override
  String get stateDisconnecting => 'Անջատում';

  @override
  String get coreMissing => 'Sora ծառայությունը չի արձագանքում';

  @override
  String get serverAuto => 'Ամենաարագ';

  @override
  String get serverBypass => 'Սերվեր չկա';

  @override
  String get addSubscription => 'Ավելացնել բաժանորդագրություն';

  @override
  String get servers => 'Սերվերներ';

  @override
  String get settings => 'Կարգավորումներ';

  @override
  String get subscription => 'Բաժանորդագրություն';

  @override
  String get subscriptionLink => 'Բաժանորդագրության հղում';

  @override
  String get add => 'Ավելացնել';

  @override
  String get refresh => 'Թարմացնել';

  @override
  String get rename => 'Վերանվանել';

  @override
  String get delete => 'Ջնջել';

  @override
  String get cancel => 'Չեղարկել';

  @override
  String get save => 'Պահպանել';

  @override
  String get name => 'Անուն';

  @override
  String deleteSubscription(String name) {
    return 'Ջնջե՞լ «$name»-ը:';
  }

  @override
  String get routes => 'Երթուղիներ';

  @override
  String get presetGlobal => 'Ամեն ինչ VPN-ի միջոցով';

  @override
  String get presetRu => 'Ռուսաստան ուղիղ';

  @override
  String get presetIr => 'Իրան ուղիղ';

  @override
  String get presetCn => 'Չինաստան ուղիղ';

  @override
  String get blockAds => 'Արգելափակել գովազդը';

  @override
  String get killSwitch => 'Ինտերնետ միայն VPN-ի միջոցով';

  @override
  String get engine => 'Շարժիչ';

  @override
  String get engineAuto => 'Ավտոմատ';

  @override
  String get animations => 'Անիմացիաներ';

  @override
  String get logs => 'Մատյան';

  @override
  String get about => 'Մոտ';

  @override
  String get logsAll => 'Բոլորը';

  @override
  String get logsImportant => 'Կարևոր';

  @override
  String get logsErrors => 'Սխալներ';

  @override
  String get search => 'Որոնում';

  @override
  String get export => 'Պահել ֆայլում';

  @override
  String get clear => 'Պարզ';

  @override
  String get logsEmpty => 'Այստեղ ոչինչ';

  @override
  String get connEmpty => 'Կապ չկա';

  @override
  String appVersion(String version) {
    return 'Տարբերակ $version';
  }

  @override
  String get notInstalled => 'Տեղադրված չէ';

  @override
  String get sourceCode => 'Աղբյուրի կոդը';

  @override
  String get license => 'Լիցենզիա';

  @override
  String usage(String used, String total) {
    return '$used $total-ից';
  }

  @override
  String until(String date) {
    return 'մինչև $date';
  }

  @override
  String get expired => 'Ժամկետանց';

  @override
  String milliseconds(int n) {
    return '$n ms';
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
    return '$n ԿԲ';
  }

  @override
  String bytesMB(String n) {
    return '$n ՄԲ';
  }

  @override
  String bytesGB(String n) {
    return '$n ԳԲ';
  }

  @override
  String bytesTB(String n) {
    return '$n ՏԲ';
  }

  @override
  String get errGeneric => 'Սխալ առաջացավ';

  @override
  String get errCore => 'Sora ծառայությունը չի արձագանքում';

  @override
  String get errAuth => 'Sora ծառայության հասանելիություն չկա';

  @override
  String get errVersion => 'Թարմացրեք Sora. հավելվածը և ծառայությունը տարբեր տարբերակներ են';

  @override
  String get errBusy => 'Սպասեք, նախորդ հրամանը դեռ աշխատում է';

  @override
  String get errEngineMissing => 'Այս սերվերի համար շարժիչ չի գտնվել';

  @override
  String get errEngineStart => 'Շարժիչը չի գործարկվել';

  @override
  String get errEngineStopped => 'Շարժիչը կանգ առավ';

  @override
  String get errTunnel => 'Այս VPN ռեժիմն անհասանելի է։ Ընտրեք այլ ռեժիմ կամ ստուգեք ծառայության թույլտվությունները։';

  @override
  String get errNetwork => 'Հնարավոր չէ հասնել սերվերին';

  @override
  String get errTimeout => 'Սերվերը ժամանակին չպատասխանեց';

  @override
  String get errFirewall => 'Չհաջողվեց արգելափակել ինտերնետը VPN-ից դուրս';

  @override
  String get errSubFetch => 'Չհաջողվեց բեռնել բաժանորդագրությունը';

  @override
  String get errSubFormat => 'Սա բաժանորդագրության հղում չէ';

  @override
  String get errSubEmpty => 'Բաժանորդագրությունը սերվեր չունի';

  @override
  String get errSubDuplicate => 'Այս բաժանորդագրությունն արդեն ավելացված է';

  @override
  String get errSubLimit => 'Չափազանց շատ բաժանորդագրություններ';

  @override
  String get errSubScheme => 'Հղումը պետք է սկսվի https://-ով';

  @override
  String get errSecretStore => 'Sora պահեստը վնասված է կամ անհասանելի է';

  @override
  String get errNoServers => 'Միանալու համար ավելացրեք բաժանորդագրություն';

  @override
  String get connections => 'Միացումներ';

  @override
  String get close => 'Փակել';

  @override
  String get chainDirect => 'Ուղղակի';

  @override
  String get chainBlocked => 'Արգելափակված';

  @override
  String get theme => 'Թեմա';

  @override
  String get themeSystem => 'Ինչպես համակարգում';

  @override
  String get themeLight => 'Լույս';

  @override
  String get themeDark => 'Մութ';

  @override
  String get language => 'Լեզու';

  @override
  String get languageSystem => 'Ինչպես համակարգում';

  @override
  String get sectionConnection => 'Միացում';

  @override
  String get sectionNoServer => 'Սերվեր չկա';

  @override
  String get sectionPing => 'Պինգ';

  @override
  String get sectionLog => 'Ախտորոշում';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Ավտոմատ';

  @override
  String get dnsHint => 'Հասցեներ՝ բաժանված ստորակետերով';

  @override
  String get fragment => 'TLS մասնատում';

  @override
  String get fragmentPackets => 'Ինչ բաժանել';

  @override
  String get fragmentLength => 'Կտորի չափը';

  @override
  String get fragmentInterval => 'Դադարեք կտորների միջև';

  @override
  String get byDefault => 'Կանխադրված';

  @override
  String get rangeHint => 'Օրինակ՝ 100-200';

  @override
  String get splitPos => 'Պառակտել դիրքերը';

  @override
  String get splitPosHint => 'Օրինակ, 1, midsld';

  @override
  String get disorder => 'Պատվիրեք կտորներ';

  @override
  String get tlsRecord => 'Բաժանեք TLS ռեկորդը';

  @override
  String get tlsRecordNo => 'Ոչ';

  @override
  String get tlsRecordSni => 'Կայքի անունով';

  @override
  String get tlsRecordFirst => 'Առաջին բայթից հետո';

  @override
  String get hostCase => 'Փոխել հյուրընկալող գործը';

  @override
  String get probeMethod => 'Մեթոդ';

  @override
  String get probeAuto => 'Ավտոմատ';

  @override
  String get probeEngine => 'Շարժիչի միջոցով';

  @override
  String get probeConnect => 'Միայն միացում';

  @override
  String get probeUrl => 'Փորձարկման հասցե';

  @override
  String get probeTimeout => 'Սպասեք';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Բաժանորդագրություններ';

  @override
  String get subscriptionSettings => 'Կարգավորումներ';

  @override
  String get userAgent => 'Օգտատեր-Գործակալ';

  @override
  String get autoUpdate => 'Թարմացնել ավտոմատ կերպով';

  @override
  String get updateInterval => 'Որքան հաճախ';

  @override
  String get intervalProvider => 'Ինչպես մատակարարը հարցնում է';

  @override
  String hours(int n) {
    return '$n ժ';
  }

  @override
  String get updateNow => 'Թարմացրեք հիմա';

  @override
  String get logLevel => 'Ինչ արձանագրել';

  @override
  String get levelDebug => 'Ամեն ինչ';

  @override
  String get levelInfo => 'Սովորական';

  @override
  String get levelWarning => 'Կարևոր';

  @override
  String get levelError => 'Միայն սխալներ';

  @override
  String get recordDestinations => 'Գրանցեք կայքի հասցեները';

  @override
  String get reset => 'Վերականգնել կարգավորումները';

  @override
  String get resetConfirm => 'Վերակայե՞լ բոլոր կարգավորումները:';

  @override
  String get resetAction => 'Վերականգնել';

  @override
  String get invalidValue => 'Այս արժեքը չի աշխատի';

  @override
  String get website => 'Բաժանորդագրության էջ';

  @override
  String get providerWebsite => 'Մատակարարի կայք';

  @override
  String get support => 'Աջակցություն';

  @override
  String controlPortQuestion(String engine) {
    return '$engine-ը կառավարվում է այս համակարգչի պորտի միջոցով: Այլ ծրագրերը կկարողանան ասել, որ VPN-ը միացված է:';
  }

  @override
  String chooseEngine(String engine) {
    return 'Ընտրեք $engine';
  }

  @override
  String get rules => 'Պատվերով կանոններ';

  @override
  String get ruleAdd => 'Նոր կանոն';

  @override
  String get ruleHint => 'Կայք, IP կամ ծրագիր';

  @override
  String get ruleDirect => 'Ուղղակի';

  @override
  String get ruleProxy => 'VPN-ի միջոցով';

  @override
  String get ruleBlock => 'Արգելափակել';

  @override
  String get failover => 'Միացնել ձախողումը';

  @override
  String get connectOnStart => 'Միացեք մեկնարկին';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'բաժանորդագրությունն ավարտվում է $days օրից',
      one: 'բաժանորդագրությունն ավարտվում է $days օրը',
      zero: 'բաժանորդագրությունն ավարտվում է մի քանի ժամից',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left մնացել է';
  }

  @override
  String get ruleInvalid => 'Սա նման չէ կայքի, IP-ի կամ ծրագրի';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count սերվերներ, ամենաարագը',
      one: '$count սերվեր, ամենաարագը',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Ռեժիմ';

  @override
  String get tunnelProxy => 'System վստահված անձ';

  @override
  String get proxyAddress => 'Վստահված անձի հասցե';

  @override
  String get copied => 'Պատճենվել է';

  @override
  String get launchAtLogin => 'Սկսեք համակարգից';

  @override
  String get launchAtLoginDetail => 'Մուտք գործելիս Sora-ն կգործարկվի ավտոմատ և կմնա համակարգային սկուտեղում։';

  @override
  String get closeToTray => 'Փակված վիճակում պահել սկուտեղի մեջ';

  @override
  String get notifications => 'Ծանուցումներ';

  @override
  String get trayOpen => 'Բացեք Sora';

  @override
  String get trayConnect => 'Միացնել';

  @override
  String get trayDisconnect => 'Անջատել';

  @override
  String get trayServer => 'Սերվեր';

  @override
  String get trayQuit => 'Դուրս գալ Sora-ից';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora՝ $state, $server';
  }

  @override
  String get noticeInTray => 'Sora դեռևս սկուտեղի մեջ է';

  @override
  String get noticeInTrayBody => 'Դուրս գալ իր պատկերակի մենյուից';

  @override
  String get noticeLost => 'Կապը կորել է';

  @override
  String get noticeLostBody => 'Sora-ը նորից միանում է';

  @override
  String get noticeRestored => 'Կրկին միացված է';

  @override
  String get noticeFailed => 'Չհաջողվեց միանալ';

  @override
  String get noticeBackup => 'Հիմնական սերվերը չպատասխանեց. կրկնօրինակն իրականացնում է երթևեկությունը';

  @override
  String get noticeNext => 'Սերվերը չպատասխանեց. հաջորդը կրում է երթեւեկությունը';

  @override
  String get noticeMainBack => 'Հիմնական սերվերը կրկին պատասխանում է և տեղափոխում է տրաֆիկը';

  @override
  String get noticeSubscription => 'Բաժանորդագրություն';

  @override
  String get importTitle => 'Ավելացնե՞լ այս բաժանորդագրությունը:';

  @override
  String get importSealed =>
      'Այս հղումը կոդավորված է Happ-ի համար, և միայն Happ-ն կարող է կարդալ այն: Խնդրեք ձեր մատակարարին պարզ բաժանորդագրության հղումը:';

  @override
  String get understood => 'Լավ';

  @override
  String get noAnswer => 'ոչ մի պատասխան';

  @override
  String get home => 'Տուն';

  @override
  String get navRules => 'Կանոններ';

  @override
  String get navConnections => 'Միացումներ';

  @override
  String get navLogs => 'Տեղեկամատյաններ';

  @override
  String get navAbout => 'Մոտ';

  @override
  String get sidebarToggle => 'Միացնել կողագոտին';

  @override
  String get more => 'Ավելին';

  @override
  String get less => 'Ավելի քիչ';

  @override
  String get notificationsEmpty => 'Ծանուցումներ չկան';

  @override
  String get retryConnect => 'Կրկին փորձեք կապը';

  @override
  String get openLogs => 'Բացեք տեղեկամատյանները';

  @override
  String get tourReplay => 'Կրկին ցուցադրեք ուղեցույցը';

  @override
  String tourStep(int step) {
    return 'Քայլ $step 5-ից';
  }

  @override
  String get tourBack => 'Ետ';

  @override
  String get tourNext => 'Հաջորդը';

  @override
  String get tourSkip => 'Բաց թողնել';

  @override
  String get tourFinish => 'Կատարված է';

  @override
  String get tourAdd => 'Ավելացրեք ձեր մատակարարի բաժանորդագրության հղումը:';

  @override
  String get tourServer => 'Ընտրեք սերվեր: «Ամենաարագ»-ը ձեզ համար ընտրում է մեկը:';

  @override
  String get tourConnect => 'Սեղմեք այստեղ՝ միանալու կամ անջատելու համար:';

  @override
  String get tourMode => 'Ընտրեք ռեժիմ: Kill switch-ը արգելափակում է ինտերնետը, եթե VPN-ն ընկնի։';

  @override
  String get tourSettings => 'Բացեք կարգավորումները: Դուք կարող եք վերարտադրել այս ուղեցույցը այնտեղ:';

  @override
  String get chooseProgram => 'Ընտրեք ծրագիր';

  @override
  String get installedApps => 'Տեղադրված հավելվածներ';

  @override
  String get runningProcesses => 'Գործող գործընթացներ';

  @override
  String get programsEmpty => 'Հայտեր չեն գտնվել: Փորձեք մեկ այլ անուն:';

  @override
  String get selectExe => 'Ընտրեք .exe ֆայլ';

  @override
  String get speedtest => 'Արագություն';

  @override
  String get speedtestSearch => 'Գտեք ծառայություն';

  @override
  String get speedtestEmpty => 'Համընկնումներ չկան: Փոխեք որոնումը:';

  @override
  String get speedtestBackToList => 'Վերադարձ դեպի ծառայություններ';

  @override
  String get speedtestOpenBrowser => 'Բացեք բրաուզերում';

  @override
  String get speedtestUnavailable =>
      'Ներկառուցված դիտարկիչը չհաջողվեց գործարկել: Բացեք ծառայությունը ձեր համակարգի բրաուզերում:';

  @override
  String get speedtestPageFailed =>
      'Էջը չհաջողվեց բեռնել: Վերբեռնեք այն կամ բացեք ծառայությունը ձեր համակարգի բրաուզերում:';

  @override
  String get speedtestExternalFailed => 'Համակարգի զննարկիչը չկարողացավ բացել: Նորից փորձեք:';

  @override
  String get modes => 'Ռեժիմներ';

  @override
  String get proxyShort => 'Վստահված անձ';

  @override
  String get tunMode => 'Ամբողջ երթևեկությունը (TUN)';

  @override
  String get checkUpdates => 'Ստուգեք թարմացումների համար';

  @override
  String get updates => 'Հավելվածի թարմացումներ';

  @override
  String updateAvailable(String version) {
    return '$version տարբերակը հասանելի է';
  }

  @override
  String get updateOpenAbout => 'Դիտել թարմացումը';

  @override
  String updateNotes(String version) {
    return 'Փոփոխություններ $version-ում';
  }

  @override
  String get updateCheck => 'Ստուգեք թարմացումների համար';

  @override
  String get updateChecking => 'Ստուգվում է...';

  @override
  String get updateNoNotes => 'Թողարկումը նշումներ չունի:';

  @override
  String get updateDropWarning =>
      'VPN կապը մի քանի վայրկյանով կնվազի, մինչ Sora-ը և դրա հիմնական թարմացումը: Շարունակե՞լ';

  @override
  String get updateWaitConnection => 'Սպասեք, մինչև VPN կապը և միջուկը պատրաստ լինեն:';

  @override
  String get updateDownloading => 'Ֆայլերի ներբեռնում և հաստատում...';

  @override
  String get updateInstalling => 'Թարմացումը պատրաստվում է կամ սպասում է ադմինիստրատորի նույնականացմանը...';

  @override
  String get updateNetworkError => 'Չհաջողվեց ներբեռնել թարմացումը: Նորից փորձեք:';

  @override
  String get updateReleaseError => 'Թողարկման տվյալները կամ պահանջվող ֆայլերը բացակայում են կամ անվավեր են:';

  @override
  String get updateChecksumError => 'Ներբեռնումը չի համապատասխանում SHA256SUMS-ին: Ոչինչ չի տեղադրվել։';

  @override
  String get updateInstallError => 'Թարմացումը չի ավարտվել: Նույնականացումը կարող է չեղարկվել:';

  @override
  String get updateUnsupported =>
      'Այս գործարկիչը չի պատկանում աջակցվող Sora փաթեթի զույգին: Օգտագործեք թողարկման տեղադրման հրահանգները:';

  @override
  String get updateManual =>
      'Գործարկեք այս հրամանը տերմինալում՝ երկու ստուգված փաթեթները տեղադրելու համար, այնուհետև նորից բացեք Sora: Ֆայլերը մնում են ներբեռնման գրացուցակում: VPN կապը կդադարի:';

  @override
  String get updateSignaturePending =>
      'Թարմացման ֆայլերը համեմատվում են թողարկման հետ հրապարակված ստուգիչ գումարների հետ։';

  @override
  String get updateManualSigWarning =>
      'Ստորև նշված ֆայլերը համապատասխանում են թողարկման ստուգիչ գումարներին։ Գործարկեք հրամանը, եթե դրանք ներբեռնել եք պաշտոնական թողարկումից։';

  @override
  String get updateVersionRevoked => 'Մշակողը հանել է այս տարբերակը: Խնդրում ենք սպասել շտկված թողարկման:';

  @override
  String get updateRolloutPending => 'Ավելի նոր տարբերակ է տարածվում աստիճանաբար և ավտոմատ կերպով կառաջարկվի ձեզ:';

  @override
  String updateRollbacking(String version) {
    return 'Վերադառնալ $version տարբերակին...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version-ի թարմացումը չի անցել առողջության ստուգումը, ուստի Sora-ը հետ է վերադարձվել $fromVersion:';
  }

  @override
  String get updateRollbackError =>
      'Ավտոմատ հետ վերադարձը ձախողվեց: Եթե ​​նոր տարբերակը չի աշխատում, ձեռքով նորից տեղադրեք նախորդ թողարկումը:';

  @override
  String get updateRollbackCacheError =>
      'Չհաջողվեց պատրաստել ընթացիկ տարբերակի հաստատված հետադարձ պատճենը, ուստի թարմացումը չի տեղադրվել:';

  @override
  String get updateCopyCommand => 'Պատճենել հրամանը';

  @override
  String get updateChecksDisabled => 'Ավտոմատ ստուգումները անջատված են Կարգավորումներում:';

  @override
  String get updateInstalled => 'Տեղադրված է թարմացում: Վերաբացեք Sora:';

  @override
  String get projectLinks => 'Նախագիծ';

  @override
  String get githubReleases => 'Թողարկումներ և ներբեռնումներ';

  @override
  String get telegramChannel => 'Telegram ալիք';

  @override
  String get licenses => 'Լիցենզիաներ';

  @override
  String get componentLicenses => 'Բաղադրիչների լիցենզիաներ';

  @override
  String get collapseServers => 'Ծալել սերվերները';

  @override
  String get expandServers => 'Ընդլայնել սերվերները';

  @override
  String get hideDescription => 'Թաքցնել նկարագրությունը';

  @override
  String get showDescription => 'Ցույց տալ նկարագրությունը';

  @override
  String get pendingConnectionChanges => 'Այս փոփոխությունները կիրառելու համար նորից միացեք:';

  @override
  String get reconnectNow => 'Դիմեք և նորից միացեք';

  @override
  String get errEngineUnsupported =>
      'Ընտրված շարժիչը չի աջակցում այս պրոֆիլը կամ կարգավորումները: Ընտրեք Ավտո կամ համատեղելի շարժիչ:';

  @override
  String get errRestore => 'Կապի մաքրումը թերի էր: Կրկին փորձեք անջատել; մանրամասների համար տես գրանցամատյանը:';

  @override
  String get errSessionEnded => 'Այս նիստն արդեն ավարտվել է։ Թարմացրեք կապի վիճակը:';

  @override
  String get retryDisconnect => 'Նորից փորձեք անջատել';

  @override
  String get tunStack => 'TUN բուրգ';

  @override
  String get modesInfo => 'Ռեժիմների մասին';

  @override
  String get modesGuideTitle => 'Ռեժիմներ և շարժիչներ';

  @override
  String get modesGuide =>
      'Ընտրեք Ավտոմատ, եթե վստահ չեք, թե որ շարժիչն է անհրաժեշտ ձեր սերվերին: Sora-ը ստուգում է պրոֆիլը և կարգավորումները միանալուց առաջ: Շարժիչը չի կարող մեծացնել ձեր պլանի թողունակությունը. կատարումը կախված է սերվերից, երթուղուց, արձանագրությունից և ցանցից:\n\n## ռեժիմներ\n\n### Ամբողջ երթևեկությունը (TUN)\n\nSora-ը ստեղծում է վիրտուալ ցանցային ինտերֆեյս և երթուղավորում է հավելվածների տրաֆիկը դրա միջով, ներառյալ TCP և UDP: Օգտագործեք այս ռեժիմը Telegram, խաղերի և Discord ձայնի համար: Կանոնները կարող են ուղղակիորեն ուղարկել կոնկրետ կայքեր կամ ծրագրեր կամ արգելափակել դրանք: Ցանցային ծառայությանը անհրաժեշտ է թույլտվություն և սերվեր, որն աջակցում է պահանջվող արձանագրությանը:\n\n### System վստահված անձ\n\nSora-ը կարգավորում է տեղական HTTP/SOCKS վստահված անձը: Այն օգտագործում են այն հավելվածները, որոնք հարգում են համակարգի վստահված անձի կարգավորումները: Ծրագրերն իրենց սեփական ցանցային փաթեթով կարող են ուղղակիորեն միանալ. UDP-ին և ձայնային զանգերին ընդհանուր առմամբ անհրաժեշտ է TUN: Այս ռեժիմը համապատասխանում է պրոքսի աջակցությամբ բրաուզերներին և հավելվածներին:\n\n### Սերվեր չկա\n\nLinux-ում Sora-ն օգտագործում է [zapret](https://github.com/bol-van/zapret) HTTP/TLS հարցումները բաժանելու և ձևափոխելու և որոշ DPI ստուգումներ շրջանցելու համար: Ձեր IP-ն մնում է նույնը, և կապերն անմիջապես գնում են դեպի կայք: Արդյունքները կախված են ձեր մատակարարից և արգելափակման եղանակից:\n\nԸնթացիկ ինտեգրումն օգտագործում է tpws HTTP-ի և TLS-ի համար TCP-ի միջոցով: Այն չի շրջանցում IP արգելափակումը կամ փոխանցում UDP-ն և չի կարող երաշխավորել Telegram-ի MTProto կապերը: Օգտագործեք VPN սերվեր TUN-ով Discord ձայնի, Telegram զանգերի և այս տեսակի սահմանափակումների համար:\n\n## Շարժիչներ\n\n### Ավտո\n\nSora-ն ընտրում է տեղադրված շարժիչ, որն աջակցում է կապի ամբողջ պլանին՝ սերվերի արձանագրություններ, փոխադրումներ, խմբեր, մասնատում և ռեժիմ: Անհամատեղելի ձեռքով ընտրությունը մերժվում է մինչ ընթացիկ կապը դադարեցնելը: Ընտրեք Ավտո կամ մեկ այլ շարժիչ և նորից կիրառեք կարգավորումները:\n\n### sing-box\n\nSora նոր փաթեթները ներառում են [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), մի պատառաքաղ [sing-box] (https://github.com/SagerNet/sing-box), ավելացնելով հաճախորդի կողմից XHTTP և VLESS Encryption: Sora-ը ճանաչում է կառուցվածքը և դրա հնարավորությունները: Առանց XHTTP-ի վերին հոսանքով կառուցված սարքը միայն իր անունից չի ստանում այս հնարավորությունը:\n\nԱջակցվող արձանագրություններն են VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard և AmneziaWG 1.x/2.x-ի այն պարամետրերը, որոնք Sora-ն կարող է ներմուծել։ Ամբողջական Xray JSON պրոֆիլների համար անհրաժեշտ է Xray։ Նոր AWG 3.x դաշտերը դեռ հնարավոր չէ ներմուծել։ sing-box-ն օգտագործում է գաղտնաբառով պաշտպանված տեղային կառավարման պորտ, որը համակարգչի մյուս ծրագրերը կարող են հայտնաբերել։\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) աջակցում է VLESS, REALITY, XHTTP, VLESS Encryption և TLS մասնատումը: Այն նաև գործարկում է ամբողջական մատակարար Xray պրոֆիլները՝ պահպանելով դրանց երթուղին և խմբերը: Նման պրոֆիլները չեն կարող ավտոմատ կերպով փոխակերպվել մեկ այլ շարժիչի՝ առանց դրանց վարքագիծը փոխելու:\n\nՄիավորված Xray-ը հեռացրեց TLS վկայագրի ստուգումն անջատող կարգավորումը («allowInsecure»): Այս պարամետրը պահանջող սովորական սերվերների համար ավտոմատ ընտրում է sing-box կամ mihomo: Xray ընտրելը ձեռքով հայտնում է անհամատեղելիության մասին՝ մինչ ընթացիկ կապը դադարեցնելը: Ավելի հին ամբողջական JSON պրոֆիլներին անհրաժեշտ է թարմացված մատակարարի պրոֆիլ՝ ստուգելի վկայականով կամ վկայագրի փինով:\n\n### mihomo\n\n[mihomo] (https://github.com/MetaCubeX/mihomo) աջակցում է պատվիրված հետադարձ և բեռը հավասարակշռող խմբեր, XHTTP և AmneziaWG: Ընտրեք այն, երբ պահուստային սերվերի ավտոմատ ձախողումը կարևոր է: Sora-ի TLS մասնատման կարգավորումն անհասանելի է այս շարժիչով:\n\n## Համատեղելիություն Sora-ում\n\n| Առանձնահատկություն | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN և TCP/UDP | Այո | Այո | Այո |\n| XHTTP | Այո | Այո | Այո |\n| VLESS Encryption | Այո | Այո | Այո |\n| Ամբողջական Xray պրոֆիլը | Ոչ | Այո | Ոչ |\n| TUIC / AnyTLS | Երկուսն էլ | Ոչ | TUIC |\n| mieru | Ոչ | Ոչ | Այո |\n| NaiveProxy | Այո | Ոչ | Ոչ |\n| TLS մասնատում | Այո | Այո | Ոչ |\n| AmneziaWG 1.x/2.x | Այո¹ | Ոչ | Այո |\n| Պատվիրված հետադարձ խումբ | Ոչ | No² | Այո |\n\n¹ J1/J2/J3/Itime-ով պրոֆիլներն օգտագործում են mihomo; այս դաշտերը երբեք չպետք է լուռ անտեսվեն: ² Ամբողջական Xray պրոֆիլների խմբի համար հավելվածն ընտրում է պահուստային պրոֆիլ: Աջակցությունը կախված է տեղադրված կառուցվածքից; ստուգեք դրա տարբերակը About-ում:\n\n## TUN կույտ\n\nԿույտը մշակում է TCP և UDP վիրտուալ ինտերֆեյսի ներսում: Ռեժիմների վահանակում Xray և mihomo առաջարկում են gVisor, System, Mixed և MIPS: Յուրաքանչյուր շարժիչ պահպանում է իր նախապատվությունը: System վստահված անձը և առանց սերվերի ռեժիմները չեն օգտագործում այս նախապատվությունը:\n\n- **Mixed**: TCP-ն օգտագործում է համակարգի կույտը, մինչդեռ gVisor-ը մշակում է UDP-ն: Սա mihomo-ի կանխադրված տարբերակն է Linux-ում։ Windows-ում Xray-ն և mihomo-ն լռելյայն օգտագործում են MIPS։\n- **System**: օգտագործում է համակարգի կույտը: Փորձեք մեկ այլ տարբերակ, եթե ցանցային հավելվածները խնդիրներ ունենան:\n- **gVisor**: կարգավորում է երթևեկությունը օգտվողների տարածքում:\n- **MIPS**: mihomo-ի սեփական IP փաթեթը, հասանելի է փաթեթավորված 1.19.32 տարբերակում:\n\nLinux-ում Xray-ն օգտագործում է իր ներկառուցված gVisor լռելյայն: System, Mixed և MIPS Linux-ում օգտագործում են mihomo որպես TUN շարժիչ՝ TCP-ն և UDP-ն փոխանցելով Xray-ին վավերացված տեղական SOCKS հղման միջոցով: Xray-ը պահպանում է արձանագրությունը, մատակարարի պրոֆիլը և երթուղին: Այս երեք տարբերակները պահանջում են տեղադրված mihomo: Windows-ում Xray-ը բոլոր չորս TUN ստեկերի համար օգտագործում է mihomo 1.19.32 կամ ավելի նոր տարբերակ։ Արձանագրություններն ու երթուղավորումը մնում են Xray-ում։ Այս համակցությունում հավելվածների կանոնները աջակցում են միայն ուղիղ միացմանը և արգելափակմանը․ Linux-ում այդ կանոնները պահանջում են Xray-ի ներկառուցված gVisor-ը։\n\nԿամուրջն իրականացնում է երկրորդ գործընթացը: Linux-ի երեք անգործուն չափումների ժամանակ այն օգտագործել է մոտ 32–36 ՄԲ-ով ավելի ֆիզիկական հիշողություն, քան բնիկ Xray TUN-ը: Սա չի չափում ներբեռնման բեռը. պրոցեսորի և հիշողության ծախսերը կախված են միացումներից: sing-box չունի կույտերի ընտրիչ: Ոչ մի կույտ չի երաշխավորում ավելի լավ կատարում յուրաքանչյուր ցանցում: Ընտրեք կույտ և ընտրեք Դիմել և նորից միացեք՝ այն ձեր ցանցում փորձելու համար:\n\n## Կարգավորումների կիրառում\n\nՍերվեր ընտրելը ավտոմատ կերպով նորից միանում է: Ռեժիմը, շարժիչը, DNS-ը և կանոնների կարգավորումները անմիջապես պահվում են. ակտիվ կապի ժամանակ սեղմեք Դիմել և նորից միացեք դրանք օգտագործելու համար: Շարժիչի վերագործարկումը կարող է ընդհատել ներբեռնումները և զանգերը: Կրկնվող սեղմումները չեն սկսում զուգահեռ կապեր; անջատումը ավարտում է անցումը և ազատում կապը:\n\nԻնտերնետը միայն VPN-ի միջոցով արգելափակում է ուղիղ երթևեկությունը, երբ թունելն ընկնում է: Այն ազդում է ամբողջ մեքենայի վրա: Հստակ անջատումը վերացնում է Sora-ի կանոնները: Եթե ​​մաքրումը չի ավարտվում, նորից փորձեք անջատել և բացել գրանցամատյանը:\n\n## Ծրագրի փաստաթղթեր\n\n- [sing-box-lx. կոնֆիգուրացիա և աջակցություն] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box փաստաթղթեր] (https://sing-box.sagernet.org/)\n- [Xray փաստաթղթեր] (https://xtls.github.io/)\n- [mihomo փաստաթղթեր] (https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret. գործողություն և սահմանափակումներ] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC-ն TCP երթևեկությունը փոխանցում է Jitsi, Yandex Telemost կամ WB Stream տեսազանգի միջոցով։ Ներմուծեք olcrtc:// հղում կամ QR կոդ։ Այն աշխատում է sing-box, Xray և mihomo շարժիչներով՝ պրոքսի և TUN ռեժիմներում, UDP-ն չի աջակցվում։ Երկու կողմին էլ անհրաժեշտ են OLC2-ի համատեղելի հավաքածուներ։ Սկզբնական նախագիծն արխիվացված է։\n';

  @override
  String get probeServers => 'Ստուգեք սերվերները';

  @override
  String get extensions => 'Ընդլայնումներ';

  @override
  String extRatingLabel(String rating) {
    return 'Վարկանիշ $rating 5-ից';
  }

  @override
  String extByAuthor(String author) {
    return '$author-ի կողմից';
  }

  @override
  String extInstallsCount(String count) {
    return 'Տեղադրումներ՝ $count';
  }

  @override
  String get extInstallOne => '1 տեղադրում';

  @override
  String get extSideloadWarning => 'Տեղադրեք միայն, եթե վստահում եք հեղինակի ինքնաստորագրված բանալուն։';

  @override
  String get extPermissionsWidened => 'Թարմացումը պահանջում է նոր թույլտվություններ.';

  @override
  String get extDangerousAck => 'Ես հասկանում եմ, որ այս թույլտվությունները լուրջ են';

  @override
  String get extInstall => 'Տեղադրել';

  @override
  String get extUpdate => 'Թարմացնել';

  @override
  String get extCancel => 'Չեղարկել';

  @override
  String get extConfirm => 'Հաստատել';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Կատալոգ';

  @override
  String get extInstalled => 'Տեղադրված ընդլայնումներ';

  @override
  String get extSearchHint => 'Որոնել ընդլայնումներ';

  @override
  String get extCatAll => 'Բոլոր';

  @override
  String get extCatTools => 'Գործիքներ';

  @override
  String get extCatThemes => 'Թեմաներ';

  @override
  String get extCatAutomation => 'Ավտոմատացում';

  @override
  String get extCatStats => 'Վիճակագրություն';

  @override
  String get extCatNetwork => 'Ցանց';

  @override
  String get extSortBy => 'Դասավորել ըստ';

  @override
  String get extSortPopular => 'Ամենատարածված';

  @override
  String get extSortRating => 'Ամենաբարձր վարկանիշը';

  @override
  String get extSortName => 'Անուն';

  @override
  String get extCatalogError => 'Չհաջողվեց բեռնել կատալոգը';

  @override
  String get extRetry => 'Կրկին փորձեք';

  @override
  String get extEmptySearch => 'Ոչինչ չի գտնվել';

  @override
  String get extEmptyInstalled => 'Դեռևս տեղադրված ընդլայնումներ չկան:\nԳտեք մեկը կատալոգում կամ տեղադրեք ֆայլից:';

  @override
  String get extInstallFromFile => 'Տեղադրել ֆայլից';

  @override
  String get extInstallFromUrl => 'Տեղադրել URL-ից';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Ներբեռնեք';

  @override
  String get extDownloading => 'Ներբեռնվում է…';

  @override
  String get extVerifying => 'Ստուգվում է…';

  @override
  String get extInstalling => 'Տեղադրվում է…';

  @override
  String get extInstallFailed => 'Չհաջողվեց տեղադրել';

  @override
  String get extErrSignature => 'Ստորագրության ստուգումը ձախողվեց։ Ֆայլը կարող է վնասվել կամ կեղծվել:';

  @override
  String get extErrManifest => 'Ընդլայնման մանիֆեստն անվավեր է:';

  @override
  String get extErrNetwork => 'Ցանցի սխալ. Ստուգեք ձեր կապը և նորից փորձեք:';

  @override
  String get extErrHash => 'Ներբեռնումը չի համապատասխանում կատալոգին։ Հնարավոր է, որ այն կեղծվել է:';

  @override
  String extErrMinApp(String version) {
    return 'Այս ընդլայնման համար անհրաժեշտ է հավելվածի $version կամ ավելի նոր տարբերակը:';
  }

  @override
  String get extErrHttpsOnly => 'Միայն https:// հղումներ են թույլատրվում';

  @override
  String get extErrGeneric => 'Սխալ առաջացավ: Խնդրում ենք կրկին փորձել:';

  @override
  String get extErrAuthorKeyChanged =>
      'Այս թարմացումը ստորագրված է այլ հեղինակային բանալիով, քան տեղադրված տարբերակը, ուստի այն արգելափակված է: Եթե ​​վստահում եք նոր բանալին, ապատեղադրեք ընդլայնումը և նորից տեղադրեք այն հստակորեն:';

  @override
  String get extDisabled => 'Անջատված է';

  @override
  String extToggleEnabled(String name) {
    return 'Միացնել $name';
  }

  @override
  String get extSearchInstalled => 'Որոնել տեղադրված ընդլայնումները';

  @override
  String get extUpdateAll => 'Թարմացրեք բոլորը';

  @override
  String extUpdatesAvailable(int count) {
    return '$count թարմացումները հասանելի են';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count թարմացվել է';
  }

  @override
  String get extRiskNormal => 'Նորմալ';

  @override
  String get extRiskSensitive => 'Զգայուն';

  @override
  String get extRiskDangerous => 'Բարձր ռիսկ';

  @override
  String get extPermissionsRemoved => 'Այլևս չի պահանջվում.';

  @override
  String get extUpdateFailedKept => 'Նախորդ տարբերակը դեռ տեղադրված է։';

  @override
  String get extConflictsTitle => 'Ընդլայնման կոնֆլիկտներ';

  @override
  String get extConflictTheme => 'Հավելվածի թեմա';

  @override
  String get extConflictNetHooks => 'Ցանցային կեռիկներ';

  @override
  String extConflictWinner(String name) {
    return 'Առաջնահերթություն՝ $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count կոնֆլիկտները ձեր որոշման կարիքն ունեն';
  }

  @override
  String get extConflictsResolve => 'Լուծել հակամարտությունները';

  @override
  String extVersionLabel(String version) {
    return 'Տարբերակ $version';
  }

  @override
  String get extPermissionsTitle => 'Թույլտվություններ';

  @override
  String get extNoPermissions => 'Հատուկ թույլտվություններ չկան:';

  @override
  String get extSettings => 'Կարգավորումներ';

  @override
  String get extSaveSettings => 'Պահպանել կարգավորումները';

  @override
  String extUpdateTo(String version) {
    return 'Թարմացրեք $version';
  }

  @override
  String get extEnabled => 'Միացված է';

  @override
  String extRollbackTo(String version) {
    return 'Վերադարձ դեպի $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Վերադառնալ $version տարբերակին:';
  }

  @override
  String get extUninstall => 'Տեղահանել';

  @override
  String extUninstallConfirm(String name) {
    return 'Հեռացնե՞լ «$name»-ն ու դրա կարգավորումները:';
  }

  @override
  String get extPanelUnavailable => 'Ընդլայնման վահանակն անհասանելի է։';

  @override
  String get extPermConnectionsRead => 'Տես ակտիվ կապերի ցանկը';

  @override
  String get extPermServersRead => 'Տեսեք ձեր սերվերների ցանկը';

  @override
  String get extPermSettingsRead => 'Կարդացեք հավելվածի կարգավորումները';

  @override
  String get extPermSettingsWrite => 'Փոխեք հավելվածի կարգավորումները';

  @override
  String get extPermNotifications => 'Ցույց տալ ծանուցումները';

  @override
  String get extPermTray => 'Ավելացնել տարրեր սկուտեղի ընտրացանկում';

  @override
  String get extPermUiPanel => 'Ցուցադրել վահանակները հավելվածի ներսում';

  @override
  String get extPermThemeApply => 'Կիրառել թեմաներ';

  @override
  String get extPermRoutingRules => 'Ավելացնել երթուղային կանոններ (ազդում է ցանցի երթևեկության վրա)';

  @override
  String get extPermNetHooks => 'Ինտեգրվել ցանցի ուղու մեջ (DPI շրջանցող մոդուլներ)';

  @override
  String get extPermNetFetch => 'Խնդրեք URL-ը թույլատրված ցանկից';

  @override
  String get extPermBackground => 'Գործարկել ֆոնային առաջադրանքները';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Աշխատում է հետին պլանում';

  @override
  String get extCapNetHook => 'Շրջանցումներ և ցանցային միջամտություններ';

  @override
  String get extCapPanel => 'Ինտերֆեյսի վահանակներ';

  @override
  String get extCapRouting => 'Երթուղային կանոններ';

  @override
  String get extCapTheme => 'Թեմաներ';

  @override
  String get extCapWidget => 'Վիջեթներ';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Փոփոխություններ';

  @override
  String get extImageFailed => 'Չհաջողվեց բեռնել պատկերը';

  @override
  String get extScreenshots => 'Սքրինշոթներ';

  @override
  String get extSortRelevance => 'Համապատասխանություն';

  @override
  String get extPermNetworkDetail => 'VPN հարցումները թույլատրված են միայն ստորև նշված հոսթերին։';

  @override
  String get extBgTitle => 'Ֆոնային առաջադրանք';

  @override
  String get extBgEnabled => 'Գործարկել հետին պլանում';

  @override
  String get extBgInterval => 'Գործարկման պարբերականություն';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count րոպե', one: '$count րոպե');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ժամ', one: '$count ժամ');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Միացրեք ընդլայնումը իր ֆոնային առաջադրանքը կառավարելու համար:';

  @override
  String get extCapNetwork => 'Ցանցի հասանելիություն';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Ցանց՝ $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Դեպի $name';
  }

  @override
  String get diagnosticHttp => 'HTTP ախտորոշում';

  @override
  String get diagnosticNoData => 'Դեռևս գրանցված հարցումներ չկան: Սկզբում բացեք արագության թեստավորման կայք:';

  @override
  String get qrShareTitle => 'Համօգտագործեք QR կոդը';

  @override
  String get qrScanTitle => 'Սկան QR կոդը';

  @override
  String get qrCopyLink => 'Պատճենել հղումը';

  @override
  String get qrWarning => 'Կոդը ցույց տվեք միայն վստահելի մարդկանց։';

  @override
  String get qrScanHint => 'Ընտրեք QR կոդով էկրանի պատկեր կամ լուսանկար, կամ տեղադրեք հղում';

  @override
  String get qrFromClipboard => 'Կպցնել սեղմատախտակից';

  @override
  String get qrNoCode => 'Այս պատկերում QR կոդ չի գտնվել։';

  @override
  String get qrInvalid => 'Այս QR կոդը վավեր հղում չի պարունակում:';

  @override
  String get qrScan => 'Սկան QR';

  @override
  String get qrFromImage => 'Բացել պատկերը';

  @override
  String get connGroupByProcess => 'Խմբավորում ըստ գործընթացի';

  @override
  String get connListView => 'Ցուցակ';

  @override
  String get connCopyHost => 'Պատճենել հաղորդավարը';

  @override
  String get connAddRule => 'Ավելացնել կանոն';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count կապ', one: '$count կապ');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Նախադրված';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Սեփական';

  @override
  String get dnsCheck => 'Ստուգեք տվյալների արտահոսքի համար';

  @override
  String get dnsChecking => 'Ստուգում...';

  @override
  String get dnsNoLeak => 'Արտահոսքեր չեն հայտնաբերվել';

  @override
  String get dnsLeakFound => 'Հայտնաբերվել է արտահոսք';

  @override
  String get dnsLastCheck => 'Վերջին ստուգումը';

  @override
  String get dnsNeverChecked => 'Դեռ փորձարկված չէ';

  @override
  String get dnsLeakCheckTunnelDns => 'Թունելի DNS լուծիչներ';

  @override
  String get dnsLeakCheckSystemResolvers => 'Համակարգային անվան լուծիչներ';

  @override
  String get dnsLeakCheckKillSwitchDns => 'DNS-ի պաշտպանություն ցանցի արգելափակմամբ';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Կազմաձևեք DNS թունելի համար վերը նշված DNS կարգավորումներում:';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Ստուգեք, թե որ լուծիչները կօգտագործի ձեր համակարգը թունելից դուրս:';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Միացրեք ցանցի արգելափակումը, որպեսզի DNS տրաֆիկը մնա թունելի ներսում։';

  @override
  String get dnsLeakCheckEncryptedDns => 'Համակարգի գաղտնագրված DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'Կեղծված DNS պատասխաններ';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Ստուգեք, թե որ կոդավորված DNS վերջնակետերն է օգտագործում ձեր համակարգը թունելից դուրս:';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Թունելի համար օգտագործեք գաղտնագրված DNS (DoT կամ DoH), որպեսզի անվան լուծիչները չկարողանան կեղծել պատասխանները։';

  @override
  String get dnsCheckNeedsConnection => 'Նախ միացեք VPN-ին, ապա ստուգեք արտահոսքի համար:';

  @override
  String get dnsExpected => 'Ակնկալվում էր';

  @override
  String get dnsActual => 'Դիտարկված';

  @override
  String get measureSpeed => 'Չափել արագությունը';

  @override
  String get benchmarkStale => 'հնացած';

  @override
  String get autoSelectMode => 'Ավտո-ընտրության սերվեր';

  @override
  String get autoSelectPing => 'Ամենաարագ պինգ';

  @override
  String get autoSelectSpeed => 'Ամենաարագ արագությունը';

  @override
  String get autoSelectSmart => 'Խելացի ընտրություն';

  @override
  String get coreWatchUnstable => 'Կապը Sora միջուկին անկայուն է';

  @override
  String get watchReconnect => 'Նորից միացեք';

  @override
  String get crashRestoreTitle => 'Վերջին նիստն ընդհատվեց';

  @override
  String get restoreOnCrash => 'Վերականգնել նիստը վթարից հետո';

  @override
  String get crashRestore => 'Վերականգնել';

  @override
  String get crashDismiss => 'Ոչ հիմա';

  @override
  String get overrideTitle => 'Իմ խմբագրումները';

  @override
  String get overrideEdit => 'Խմբագրել սերվերները';

  @override
  String get overrideHide => 'Թաքցնել';

  @override
  String get overrideUnhide => 'Ցուցադրել';

  @override
  String get overrideClear => 'Վերականգնել խմբագրումները';

  @override
  String get overrideEmpty => 'Դեռ ոչ մի խմբագրում';

  @override
  String get overrideCustomRules => 'Սեփական կանոններ';

  @override
  String get errBenchmarkUnsupported => 'Արագության չափման համար անհրաժեշտ է ավելի նոր միջուկ';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$done-ի չափում $total-ից…';
  }

  @override
  String get profiles => 'Ցանցային պրոֆիլներ';

  @override
  String get profilesEmpty =>
      'Դեռևս պրոֆիլներ չկան։ Ստեղծեք մեկը՝ հայտնի ցանցերում ավտոմատ կերպով կարգավորումներ կիրառելու համար:';

  @override
  String get profileAdd => 'Ավելացնել պրոֆիլ';

  @override
  String get profileName => 'Պրոֆիլի անուն';

  @override
  String get profileSsids => 'Wi-Fi ցանցեր (SSID)';

  @override
  String get profileSsidsHint => 'Տուն, գրասենյակ՝ բաժանված ստորակետերով';

  @override
  String get profileGateways => 'Ցանցային դարպասներ';

  @override
  String get profileAsns => 'AS համարներ';

  @override
  String get profileAutoApply => 'Ինքնաբերաբար կիրառել';

  @override
  String get profileAutoApplyHint => 'Եթե անջատված է, պրոֆիլը կիրառելուց առաջ հաստատում կպահանջվի։';

  @override
  String get profileSnapshot => 'Հիշեք ընթացիկ կարգավորումները';

  @override
  String get profileSnapshotDone => 'Ընթացիկ կարգավորումները պահված են պրոֆիլում';

  @override
  String get profileDelete => 'Ջնջել պրոֆիլը';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Ջնջե՞լ «$name» պրոֆիլը:';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Կիրառե՞լ «$name» պրոֆիլը:';
  }

  @override
  String get profileApply => 'Կիրառել';

  @override
  String profileApplied(Object name) {
    return '«$name» պրոֆիլը կիրառվեց';
  }

  @override
  String get profileUndo => 'Չեղարկել';

  @override
  String get profileActive => 'Ակտիվ';

  @override
  String networkNow(Object info) {
    return 'Այժմ՝ $info';
  }

  @override
  String get networkUnknown => 'Ցանցի մասին տեղեկությունները անհասանելի են';

  @override
  String get profileNoTriggers => 'Ավելացրեք առնվազն մեկ ձգան՝ SSID, gateway կամ ASN';

  @override
  String get chains => 'Պրոքսի շղթաներ';

  @override
  String get chainsEmpty =>
      'Շղթաներ դեռ չկան։ Կապեք 2–3 սերվեր, որպեսզի երթևեկությունը անցնի դրանցից յուրաքանչյուրի միջով:';

  @override
  String get chainAdd => 'Նոր շղթա';

  @override
  String get chainName => 'Շղթայի անվանումը';

  @override
  String get chainPickServers => 'Ընտրեք 2–3 սերվեր';

  @override
  String get chainOrderHint => 'Քաշեք՝ վերադասավորելու համար. երթևեկությունը մտնում է վերևից և դուրս գալիս ներքևից:';

  @override
  String get chainTooFew => 'Ընտրեք առնվազն 2 սերվեր';

  @override
  String get chainTooMany => 'Շղթան պահում է առավելագույնը 3 սերվեր';

  @override
  String get chainEstimate => 'Մոտավոր ուշացում';

  @override
  String get chainSave => 'Պահպանել շղթան';

  @override
  String get chainDelete => 'Ջնջել շղթան';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Ջնջե՞լ «$name» շղթան:';
  }

  @override
  String get chainUnsupported => 'Ներկայիս շարժիչը չի կարող շղթաներ կառուցել';

  @override
  String get chainHopMissing => 'Շղթայական սերվերներից մեկն այլևս հասանելի չէ';

  @override
  String chainHop(Object n) {
    return 'Անցում $n';
  }

  @override
  String get chainEntry => 'Մուտք';

  @override
  String get chainExit => 'Ելք';

  @override
  String get sync => 'Սարքի համաժամացում';

  @override
  String get syncDevices => 'Իմ սարքերը';

  @override
  String get syncEmpty => 'Զուգակցված սարքեր չկան: Զուգակցել մեկ այլ սարք տեղական ցանցի միջոցով:';

  @override
  String get syncPair => 'Զուգավորել սարքը';

  @override
  String get syncShowCode => 'Ցույց տալ իմ կոդը';

  @override
  String get syncScanCode => 'Սկանավորել կոդը';

  @override
  String get syncRevoke => 'հանել';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Չեղարկե՞լ «$name»-ը:';
  }

  @override
  String syncLastSync(Object time) {
    return 'Վերջին համաժամացումը՝ $time';
  }

  @override
  String get syncNever => 'Երբեք';

  @override
  String get syncNoLan => 'Սարքերը պետք է լինեն նույն տեղական ցանցում';

  @override
  String get syncPaired => 'Սարքը զուգակցված է';

  @override
  String get syncPairingTitle => 'Զուգակցել այս սարքի հետ';

  @override
  String get syncWaiting => 'Սպասում է մյուս սարքին…';

  @override
  String get syncSecureNote => 'End-to-end ծածկագրված ալիք: Ոչ հաշիվներ, ոչ ամպային սերվերներ:';

  @override
  String get zapretWithVpn => 'Շրջանցեք DPI զտումը ուղիղ ցանցային տրաֆիկի համար';

  @override
  String get zapretWithVpnHint =>
      'Գործարկում է zapret-ը VPN թունելի հետ միասին․ թունելի տրաֆիկն անցնում է VPN-ով, իսկ ուղիղ տրաֆիկը՝ շրջանցման միջոցով։';

  @override
  String get chainDuplicate => 'Յուրաքանչյուր սերվեր կարող է հայտնվել միայն մեկ անգամ';

  @override
  String get edit => 'Խմբագրել';

  @override
  String get remove => 'Հեռացնել';

  @override
  String get autoSwitchOnDegrade => 'Ավտոմատ անջատում դեգրադացիայի վրա';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Եթե ընտրված սերվերը զգալիորեն դանդաղում է կամ դադարում է պատասխանել, Sora-ն անցնում է չափումների արդյունքով լավագույն սերվերին, բայց ոչ ավելի հաճախ, քան 10 րոպեն մեկ։';

  @override
  String get tunStackMixed => 'Խառը';

  @override
  String get tunStackSystem => 'Համակարգ';

  @override
  String get customServerAdd => 'Ավելացնել հատուկ սերվեր';

  @override
  String get customServers => 'Իմ սերվերները';

  @override
  String get customServerName => 'Անուն';

  @override
  String get customServerNameHint => 'Օրինակ՝ իմ VPS-ը';

  @override
  String get customServerNameRequired => 'Մուտքագրեք անունը';

  @override
  String get customServerAddress => 'Հասցե';

  @override
  String get customServerAddressHint => 'example.com կամ 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Մուտքագրեք սերվերի հասցեն';

  @override
  String get customServerAddressInvalid => 'Անվավեր հասցե';

  @override
  String get customServerPort => 'Պորտ';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Նավահանգիստը պետք է լինի 1-ից մինչև 65535 համար';

  @override
  String get customServerProtocol => 'Արձանագրություն';

  @override
  String get customServerCredentials => 'Մուտքի տվյալներ';

  @override
  String get customServerOptional => 'Ըստ ցանկության';

  @override
  String get customServerShowSecret => 'Ցույց տալ գաղտնիքը';

  @override
  String get customServerHideSecret => 'Թաքցնել գաղտնիքը';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Ջնջե՞լ «$name» սերվերը:';
  }

  @override
  String get customServerTest => 'Թեստ';

  @override
  String get leakTestTitle => 'Տվյալների արտահոսքի ստուգում';

  @override
  String get leakTestIntro =>
      'Ստուգում է՝ արդյոք տրաֆիկը կարող է սարքից դուրս գալ թունելից դուրս ուղով․ ուղիղ DNS և ICMP հարցումներ, IPv6 ելք և համակարգային անվան լուծիչներ։ Գործարկեք ակտիվ կապի ժամանակ։';

  @override
  String get leakTestRun => 'Ստուգեք';

  @override
  String get leakTestCancel => 'Չեղարկել';

  @override
  String get leakTestNeedsConnection => 'Միացեք VPN-ին՝ տվյալների արտահոսքի ստուգման համար:';

  @override
  String leakTestProgress(int count) {
    return 'Կատարված թեստեր՝ $count';
  }

  @override
  String get leakTestAllClear => 'Արտահոսքեր չեն հայտնաբերվել';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Հայտնաբերվել է $count արտահոսք',
      one: 'Հայտնաբերվել է $count արտահոսք',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Ամրագրել';

  @override
  String get leakTestFixedNote => 'Ցանցի արգելափակումը միացված է։ Ստուգելու համար կրկին գործարկեք թեստը։';

  @override
  String get leakTestCheckDirectDns => 'Ուղիղ DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP արձագանք';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Համակարգային անվան լուծիչներ';

  @override
  String get leakTestCheckTunnelConnectivity => 'Թունելի միացում';

  @override
  String get leakTestCheckTunnelDns => 'DNS թունելի միջով';

  @override
  String get noticeDegraded => 'Սերվերը դանդաղեց: Sora-ն անցել է չափման ընթացքում հայտնաբերված լավագույն սերվերին:';

  @override
  String get obfs => 'Տրաֆիկի քողարկում';

  @override
  String get syncCodeExpired => 'Կոդը սպառվել է';

  @override
  String get syncDaemonFailed => 'Չհաջողվեց գործարկել համաժամացման ծառայությունը';

  @override
  String get syncDaemonMissing =>
      'sora-sync բաղադրիչը չի գտնվել: Սարքի համաժամացումը միացնելու համար նորից տեղադրեք հավելվածը:';

  @override
  String get syncDaemonStarting => 'Համաժամացման ծառայության գործարկում…';

  @override
  String get syncErrAuth => 'Համաժամացման ծառայությունը մերժեց մուտքի նշանը: Վերագործարկեք հավելվածը և նորից փորձեք:';

  @override
  String get syncErrNotFound => 'Սարքն այլևս զուգակցված չէ';

  @override
  String get syncErrPairingActive => 'Զույգավորման նիստն արդեն բաց է';

  @override
  String get syncErrUnreachable => 'Մյուս սարքը չպատասխանեց։ Համոզվեք, որ այն նույն ցանցում է և ցուցադրում է իր կոդը:';

  @override
  String get syncError => 'Համաժամացման սխալ';

  @override
  String syncExpiresIn(String duration) {
    return 'Կոդի ժամկետը կլրանա $duration անց';
  }

  @override
  String get syncJoining => 'Սարքի հետ զուգակցում…';

  @override
  String get syncLegacyCleared =>
      'Հին սարքերի ցանկը իրականում երբեք չի զուգակցվել, ուստի այն մաքրվել է: Նորից զուգակցեք ձեր սարքերը, այս անգամ իրականում:';

  @override
  String get syncNewCode => 'Նոր կոդ';

  @override
  String syncPairedWith(String name) {
    return 'Զուգտկված է $name-ի հետ';
  }

  @override
  String get syncRetry => 'Կրկնել';

  @override
  String get syncStopShowing => 'Թաքցնել կոդը';

  @override
  String get syncSyncNow => 'Համաժամացնել հիմա';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Ստացվեց $pulled, ուղարկվեց $pushed';
  }

  @override
  String get syncResultTitle => 'Համաժամացման արդյունք';

  @override
  String get syncPulled => 'Ստացվել է';

  @override
  String get syncPushed => 'Ուղարկված է';

  @override
  String get syncNoChanges => 'Փոփոխություններ չեն հայտնաբերվել';

  @override
  String get syncDocKindSubscriptions => 'Բաժանորդագրություններ';

  @override
  String get syncDocKindSettings => 'Հավելվածի կարգավորումներ';

  @override
  String get syncDocKindOverrides => 'Բաժանորդագրությունների վերասահմանումներ';

  @override
  String get syncDocKindProfiles => 'Ցանցային պրոֆիլներ';

  @override
  String get syncDocKindChains => 'Պրոքսի շղթաներ';

  @override
  String syncFrom(String name) {
    return '$name-ից';
  }

  @override
  String get syncThisDevice => 'Այս սարքը';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Փաթեթի գրավում';

  @override
  String get diagnosticEvents => 'Windows-ի իրադարձություններ';

  @override
  String get diagnosticCapture => 'Լուսանկարեք 10 վայրկյան';

  @override
  String get diagnosticRequiresTun => 'Փաթեթների գրավման համար անհրաժեշտ է ակտիվ Sora TUN կապ:';

  @override
  String get diagnosticUnavailable => 'Այս ախտորոշումն անհասանելի է այս հարթակում:';

  @override
  String get extErrRevoked => 'Sora թիմը հետ է կանչել ընդլայնման այս տարբերակը, քանի որ այն անվտանգ չէ կամ անսարք է։';

  @override
  String get extErrRevocationsExpired => 'Տեղադրումն արգելափակված է մինչև չեղարկված ընդլայնումների ցանկի թարմացումը։';

  @override
  String extRevokedDisabled(String names) {
    return 'Հետ կանչված ընդլայնումներն անջատվեցին՝ $names';
  }

  @override
  String get customServerWgPrivateKey => 'Գաղտնի բանալի';

  @override
  String get customServerWgAddresses => 'Ինտերֆեյսի հասցեներ';

  @override
  String get customServerWgPeerKey => 'Սերվերի հանրային բանալի';

  @override
  String get customServerWgPresharedKey => 'Ընդհանուր բանալի';

  @override
  String get customServerWgAllowedIps => 'Թույլատրված IP-ներ';

  @override
  String get customServerWgKeepalive => 'Keepalive, վայրկյան';

  @override
  String get customServerWgKeyInvalid => 'Բանալին պետք է լինի 32 բայթ base64-ով, ինչպես տպում է wg genkey-ը։';

  @override
  String get customServerWgCidrInvalid => 'Մուտքագրեք ստորակետով բաժանված նախածանցներ, օրինակ 10.0.0.2/32։';

  @override
  String get customServerWgKeepaliveInvalid => 'Մուտքագրեք վայրկյանների թիվ 0-ից 65535։';

  @override
  String get strictKillSwitch => 'Ցանցի խիստ արգելափակում';

  @override
  String get strictKillSwitchWarning =>
      'Միանալուց հետո արգելափակում է VPN-ից դուրս երթևեկությունը նույնիսկ խափանումից, վերագործարկումից կամ հավելվածից դուրս գալուց հետո։ Մուտքը վերականգնվում է միայն կապն անջատելիս կամ այս կարգավորումն անջատելիս։ Սարքը վերագործարկելիս արգելափակումը վերսկսվում է միայն մեկնարկին միանալու միացված տարբերակի դեպքում։';

  @override
  String get extWorkerFailed => 'Ընդլայնման ֆոնային առաջադրանքը ձախողվեց։ Ստուգեք ընդլայնման մատյանը։';

  @override
  String get extAssetRejected => 'Ընդլայնման ֆայլը մերժվել է․ անընթեռնելի գույներ կամ անվավեր կանոններ։';

  @override
  String get extVerifiedSora => 'Ստուգված է Sora-ի կողմից';

  @override
  String extReceivedBytes(String count) {
    return '$count Բ';
  }

  @override
  String get extOpen => 'Բացել';

  @override
  String get customServerOwn => 'Սեփական սերվեր';

  @override
  String get customServerPaste => 'Տեղադրել հղում';

  @override
  String get customServerUser => 'Օգտանուն';

  @override
  String get customServerPassword => 'Գաղտնաբառ';

  @override
  String get customServerSecretRequired => 'Մուտքագրեք արժեք';

  @override
  String get customServerLinkInvalid => 'Սերվերի հղումը սխալ է';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Sora-ի ներքին սխալ։ Պահպանեք մատյանը և հայտնեք խնդրի մասին։';

  @override
  String get errTls => 'Սերվերի վկայագիրը մերժվել է։ Ստուգեք ժամացույցը կամ դիմեք մատակարարին։';

  @override
  String get errFileAccess => 'Ֆայլը հասանելի չէ։ Ստուգեք թույլտվությունները և ազատ տարածքը։';

  @override
  String get errDataLimit => 'Տվյալները շատ են։ Ընտրեք ավելի քիչ տարրեր և կրկին փորձեք։';

  @override
  String get errCredentials => 'Պահպանված մուտքի տվյալները բացակայում են։ Կրկին ներմուծեք սերվերը։';

  @override
  String subscriptionStale(String time) {
    return 'Թարմացվել է՝ $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Դեռ չի թարմացվել։ Կրկին փորձեք։';

  @override
  String get errHttpStatus => 'Սերվերը մերժել է հարցումը։ Ստուգեք հղումը կամ դիմեք մատակարարին։';

  @override
  String get errInvalidServer => 'Սերվերի կարգավորումները թերի են կամ չեն աջակցվում։ Թարմացրեք բաժանորդագրությունը։';

  @override
  String get errServerIds => 'Երկու սերվեր ունեն նույն նույնացուցիչը։ Կրկին ներմուծեք դրանք։';

  @override
  String get errRoutingGroup =>
      'Երթուղին հղվում է բացակայող սերվերների կամ վնասված խմբի։ Թարմացրեք բաժանորդագրությունը։';

  @override
  String get errConnections => 'Միացումների ցանկն անհասանելի է։ Միացեք կամ ընտրեք այլ շարժիչ։';

  @override
  String get errLogs => 'Այս ծառայությունը մատյան չի պահում։ Թարմացրեք Sora-ն։';

  @override
  String get errDiagnostics => 'Չհաջողվեց հավաքել ախտորոշումը։ Կրկին փորձեք կամ պահպանեք մատյանը։';

  @override
  String get errMissingItem => 'Հարցված տարրն այլևս գոյություն չունի։ Թարմացրեք ցանկը։';

  @override
  String get errInvalidRequest => 'Հարցումը սխալ արժեքներ է պարունակում։ Ստուգեք մուտքագրածը և կրկին փորձեք։';

  @override
  String get errProxyLogin =>
      'Համակարգի պրոքսին չի աջակցում այս մուտքը։ Հեռացրեք տեղային պրոքսիի օգտանունն ու գաղտնաբառը։';

  @override
  String get errLogFilter => 'Մատյանի զտիչը սխալ է։ Մաքրեք որոնումը և կրկին փորձեք։';

  @override
  String get errSubRedirect => 'Սերվերը վերահղել է վտանգավոր հասցեի։ Մատակարարից նոր հղում խնդրեք։';

  @override
  String get errProxySetup => 'Չհաջողվեց կարգավորել համակարգի պրոքսին։ Վերամիացեք կամ բացեք մատյանը։';

  @override
  String get notificationsToday => 'Այսօր';

  @override
  String get notificationsYesterday => 'Երեկ';

  @override
  String get notificationsMarkRead => 'Բոլորը նշել որպես կարդացված';

  @override
  String get notificationsUnread => 'Չկարդացված';

  @override
  String get desktopNotifications => 'Համակարգային ծանուցումներ';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }
}
