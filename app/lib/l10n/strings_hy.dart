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
  String get stateFailed => 'Միացված չէ';

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
  String get connEmpty => 'No connections';

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
  String get errOlcrtcInvalid =>
      'Այս olcRTC սերվերը թերի է. ստուգեք մատակարարին, տրանսպորտը, սենյակը և գաղտնագրման բանալին';

  @override
  String get errOlcrtcCombination => 'Այս olcRTC մատակարարն ու տրանսպորտը միասին չեն աշխատում';

  @override
  String get errOlcrtcTokenRequired =>
      'Այս olcRTC սերվերին անհրաժեշտ է մատակարարի հաշվի թոքեն, որը հղումը չի պարունակում';

  @override
  String get errOlcrtcNotConnectable => 'Այս olcRTC սերվերին չի կարելի միանալ միայն հղումով';

  @override
  String get errOlcrtcServerMode => 'Sora-ն միայն միանում է olcRTC սերվերներին և սեփական սերվեր չի գործարկում';

  @override
  String get olcrtcTcpOnly => 'Միայն TCP';

  @override
  String get olcrtcIpv4Only => 'Միայն IPv4';

  @override
  String get errEngineStart => 'Շարժիչը չի գործարկվել';

  @override
  String get errEngineStopped => 'Շարժիչը կանգ առավ';

  @override
  String get errTunnel => 'VPN կապ ստեղծելու թույլտվություն չկա';

  @override
  String get errServers => 'Սերվերը կազմաձևված է սխալով';

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
  String get exportText => 'Տեքստ';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Լույս';

  @override
  String get themeDark => 'Մութ';

  @override
  String get language => 'Լեզու';

  @override
  String get languageSystem => 'System';

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
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'Միացնել ձախողումը';

  @override
  String get connectOnStart => 'Միացեք մեկնարկին';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'բաժանորդագրությունն ավարտվում է # օրից',
      one: 'բաժանորդագրությունն ավարտվում է # օրը',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# սերվերները, իր հերթին',
      one: '# սերվերը, իր հերթին',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# սերվերներ, ամենաարագը',
      one: '# սերվեր, ամենաարագը',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Ռեժիմ';

  @override
  String get tunnelTun => 'Ամբողջ երթեւեկությունը';

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
  String get currentServer => 'Ընթացիկ սերվեր';

  @override
  String get trafficDown => 'Ներբեռնված';

  @override
  String get trafficUp => 'Վերբեռնված է';

  @override
  String perSecond(String value) {
    return '$value/վ';
  }

  @override
  String activeRules(int count) {
    return 'Ակտիվ կանոններ՝ $count';
  }

  @override
  String get recentNotifications => 'Վերջին ծանուցումները';

  @override
  String get notificationsEmpty => 'Կապի և բաժանորդագրության իրադարձությունները կհայտնվեն այստեղ';

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
  String get programsFailed => 'Չհաջողվեց բեռնել հավելվածները';

  @override
  String get programsEmpty => 'Հայտեր չեն գտնվել: Փորձեք մեկ այլ անուն:';

  @override
  String get selectExe => 'Ընտրեք .exe ֆայլ';

  @override
  String get trafficUnavailable => 'Հաշվիչները դեռ հասանելի չեն';

  @override
  String get speedtest => 'Արագություն';

  @override
  String get speedtestCheck => 'Ստուգեք արագությունը';

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
  String get appCopyright => '© 2026 levvs-one և ներդրողներ';

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
  String get bypassLimitations =>
      'Այս ռեժիմը շրջանցում է DPI-ն միայն HTTP-ի և TLS-ի համար, չի աջակցում UDP և չի փոխում ձեր IP-ն: Օգտագործեք VPN սերվեր Discord ձայնի, զանգերի և արգելափակված Telegram հասցեների համար:';

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
      'Ընտրեք Ավտոմատ, եթե վստահ չեք, թե որ շարժիչն է անհրաժեշտ ձեր սերվերին: Sora-ը ստուգում է պրոֆիլը և կարգավորումները միանալուց առաջ: Շարժիչը չի կարող մեծացնել ձեր պլանի թողունակությունը. կատարումը կախված է սերվերից, երթուղուց, արձանագրությունից և ցանցից:\n\n## ռեժիմներ\n\n### Ամբողջ երթևեկությունը (TUN)\n\nSora-ը ստեղծում է վիրտուալ ցանցային ինտերֆեյս և երթուղավորում է հավելվածների տրաֆիկը դրա միջով, ներառյալ TCP և UDP: Օգտագործեք այս ռեժիմը Telegram, խաղերի և Discord ձայնի համար: Կանոնները կարող են ուղղակիորեն ուղարկել կոնկրետ կայքեր կամ ծրագրեր կամ արգելափակել դրանք: Ցանցային ծառայությանը անհրաժեշտ է թույլտվություն և սերվեր, որն աջակցում է պահանջվող արձանագրությանը:\n\n### System վստահված անձ\n\nSora-ը կարգավորում է տեղական HTTP/SOCKS վստահված անձը: Այն օգտագործում են այն հավելվածները, որոնք հարգում են համակարգի վստահված անձի կարգավորումները: Ծրագրերն իրենց սեփական ցանցային փաթեթով կարող են ուղղակիորեն միանալ. UDP-ին և ձայնային զանգերին ընդհանուր առմամբ անհրաժեշտ է TUN: Այս ռեժիմը համապատասխանում է պրոքսի աջակցությամբ բրաուզերներին և հավելվածներին:\n\n### Սերվեր չկա\n\nLinux-ում Sora-ն օգտագործում է [zapret](https://github.com/bol-van/zapret) HTTP/TLS հարցումները բաժանելու և ձևափոխելու և որոշ DPI ստուգումներ շրջանցելու համար: Ձեր IP-ն մնում է նույնը, և կապերն անմիջապես գնում են դեպի կայք: Արդյունքները կախված են ձեր մատակարարից և արգելափակման եղանակից:\n\nԸնթացիկ ինտեգրումն օգտագործում է tpws HTTP-ի և TLS-ի համար TCP-ի միջոցով: Այն չի շրջանցում IP արգելափակումը կամ փոխանցում UDP-ն և չի կարող երաշխավորել Telegram-ի MTProto կապերը: Օգտագործեք VPN սերվեր TUN-ով Discord ձայնի, Telegram զանգերի և այս տեսակի սահմանափակումների համար:\n\n## Շարժիչներ\n\n### Ավտո\n\nSora-ն ընտրում է տեղադրված շարժիչ, որն աջակցում է կապի ամբողջ պլանին՝ սերվերի արձանագրություններ, փոխադրումներ, խմբեր, մասնատում և ռեժիմ: Անհամատեղելի ձեռքով ընտրությունը մերժվում է մինչ ընթացիկ կապը դադարեցնելը: Ընտրեք Ավտո կամ մեկ այլ շարժիչ և նորից կիրառեք կարգավորումները:\n\n### sing-box\n\nSora նոր փաթեթները ներառում են [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), մի պատառաքաղ [sing-box] (https://github.com/SagerNet/sing-box), ավելացնելով հաճախորդի կողմից XHTTP և VLESS Encryption: Sora-ը ճանաչում է կառուցվածքը և դրա հնարավորությունները: Առանց XHTTP-ի վերին հոսանքով կառուցված սարքը միայն իր անունից չի ստանում այս հնարավորությունը:\n\nԱջակցվող արձանագրություններն են VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard և AmneziaWG 1.x/2.x-ի այն պարամետրերը, որոնք Sora-ն կարող է ներմուծել։ Ամբողջական Xray JSON պրոֆիլների համար անհրաժեշտ է Xray։ Նոր AWG 3.x դաշտերը դեռ հնարավոր չէ ներմուծել։ sing-box-ն օգտագործում է գաղտնաբառով պաշտպանված տեղային կառավարման պորտ, որը համակարգչի մյուս ծրագրերը կարող են հայտնաբերել։\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) աջակցում է VLESS, REALITY, XHTTP, VLESS Encryption և TLS մասնատումը: Այն նաև գործարկում է ամբողջական մատակարար Xray պրոֆիլները՝ պահպանելով դրանց երթուղին և խմբերը: Նման պրոֆիլները չեն կարող ավտոմատ կերպով փոխակերպվել մեկ այլ շարժիչի՝ առանց դրանց վարքագիծը փոխելու:\n\nՄիավորված Xray-ը հեռացրեց TLS վկայագրի ստուգումն անջատող կարգավորումը («allowInsecure»): Այս պարամետրը պահանջող սովորական սերվերների համար ավտոմատ ընտրում է sing-box կամ mihomo: Xray ընտրելը ձեռքով հայտնում է անհամատեղելիության մասին՝ մինչ ընթացիկ կապը դադարեցնելը: Ավելի հին ամբողջական JSON պրոֆիլներին անհրաժեշտ է թարմացված մատակարարի պրոֆիլ՝ ստուգելի վկայականով կամ վկայագրի փինով:\n\n### mihomo\n\n[mihomo] (https://github.com/MetaCubeX/mihomo) աջակցում է պատվիրված հետադարձ և բեռը հավասարակշռող խմբեր, XHTTP և AmneziaWG: Ընտրեք այն, երբ պահուստային սերվերի ավտոմատ ձախողումը կարևոր է: Sora-ի TLS մասնատման կարգավորումն անհասանելի է այս շարժիչով:\n\n## Համատեղելիություն Sora-ում\n\n| Առանձնահատկություն | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN և TCP/UDP | Այո | Այո | Այո |\n| XHTTP | Այո | Այո | Այո |\n| VLESS Encryption | Այո | Այո | Այո |\n| Ամբողջական Xray պրոֆիլը | Ոչ | Այո | Ոչ |\n| TUIC / AnyTLS | Երկուսն էլ | Ոչ | TUIC |\n| TLS մասնատում | Այո | Այո | Ոչ |\n| AmneziaWG 1.x/2.x | Այո¹ | Ոչ | Այո |\n| Պատվիրված հետադարձ խումբ | Ոչ | No² | Այո |\n\n¹ J1/J2/J3/Itime-ով պրոֆիլներն օգտագործում են mihomo; այս դաշտերը երբեք չպետք է լուռ անտեսվեն: ² Ամբողջական Xray պրոֆիլների խմբի համար հավելվածն ընտրում է պահուստային պրոֆիլ: Աջակցությունը կախված է տեղադրված կառուցվածքից; ստուգեք դրա տարբերակը About-ում:\n\n## TUN կույտ\n\nԿույտը մշակում է TCP և UDP վիրտուալ ինտերֆեյսի ներսում: Ռեժիմների վահանակում Xray և mihomo առաջարկում են gVisor, System, Mixed և MIPS: Յուրաքանչյուր շարժիչ պահպանում է իր նախապատվությունը: System վստահված անձը և առանց սերվերի ռեժիմները չեն օգտագործում այս նախապատվությունը:\n\n- **Mixed** — TCP-ն օգտագործում է համակարգի կույտը, մինչդեռ gVisor-ը մշակում է UDP-ն: Սա mihomo-ի կանխադրված տարբերակն է Linux-ում։ Windows-ում Xray-ն և mihomo-ն լռելյայն օգտագործում են MIPS։\n- **System** — օգտագործում է համակարգի կույտը: Փորձեք մեկ այլ տարբերակ, եթե ցանցային հավելվածները խնդիրներ ունենան:\n- **gVisor** — կարգավորում է երթևեկությունը օգտվողների տարածքում:\n- **MIPS** — mihomo-ի սեփական IP փաթեթը, հասանելի է փաթեթավորված 1.19.32 տարբերակում:\n\nLinux-ում Xray-ն օգտագործում է իր ներկառուցված gVisor լռելյայն: System, Mixed և MIPS Linux-ում օգտագործում են mihomo որպես TUN շարժիչ՝ TCP-ն և UDP-ն փոխանցելով Xray-ին վավերացված տեղական SOCKS հղման միջոցով: Xray-ը պահպանում է արձանագրությունը, մատակարարի պրոֆիլը և երթուղին: Այս երեք տարբերակները պահանջում են տեղադրված mihomo: Windows-ում Xray-ը բոլոր չորս TUN ստեկերի համար օգտագործում է mihomo 1.19.32 կամ ավելի նոր տարբերակ։ Արձանագրություններն ու երթուղավորումը մնում են Xray-ում։ Այս համակցությունում հավելվածների կանոնները աջակցում են միայն ուղիղ միացմանը և արգելափակմանը․ Linux-ում այդ կանոնները պահանջում են Xray-ի ներկառուցված gVisor-ը։\n\nԿամուրջն իրականացնում է երկրորդ գործընթացը: Linux-ի երեք անգործուն չափումների ժամանակ այն օգտագործել է մոտ 32–36 ՄԲ-ով ավելի ֆիզիկական հիշողություն, քան բնիկ Xray TUN-ը: Սա չի չափում ներբեռնման բեռը. պրոցեսորի և հիշողության ծախսերը կախված են միացումներից: sing-box չունի կույտերի ընտրիչ: Ոչ մի կույտ չի երաշխավորում ավելի լավ կատարում յուրաքանչյուր ցանցում: Ընտրեք կույտ և ընտրեք Դիմել և նորից միացեք՝ այն ձեր ցանցում փորձելու համար:\n\n## Կարգավորումների կիրառում\n\nՍերվեր ընտրելը ավտոմատ կերպով նորից միանում է: Ռեժիմը, շարժիչը, DNS-ը և կանոնների կարգավորումները անմիջապես պահվում են. ակտիվ կապի ժամանակ սեղմեք Դիմել և նորից միացեք դրանք օգտագործելու համար: Շարժիչի վերագործարկումը կարող է ընդհատել ներբեռնումները և զանգերը: Կրկնվող սեղմումները չեն սկսում զուգահեռ կապեր; անջատումը ավարտում է անցումը և ազատում կապը:\n\nԻնտերնետը միայն VPN-ի միջոցով արգելափակում է ուղիղ երթևեկությունը, երբ թունելն ընկնում է: Այն ազդում է ամբողջ մեքենայի վրա: Հստակ անջատումը վերացնում է Sora-ի կանոնները: Եթե ​​մաքրումը չի ավարտվում, նորից փորձեք անջատել և բացել գրանցամատյանը:\n\n## Ծրագրի փաստաթղթեր\n\n- [sing-box-lx. կոնֆիգուրացիա և աջակցություն] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box փաստաթղթեր] (https://sing-box.sagernet.org/)\n- [Xray փաստաթղթեր] (https://xtls.github.io/)\n- [mihomo փաստաթղթեր] (https://wiki.metacubex.one/)\n- [zapret. գործողություն և սահմանափակումներ] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Ստուգեք սերվերները';

  @override
  String get extensions => 'Ընդլայնումներ';

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
  String get extErrRevoked => 'This extension was revoked by the Sora team and cannot be installed or enabled.';

  @override
  String get extErrRevocationStale =>
      'The revocation list is out of date and cannot be refreshed right now, so installing and enabling extensions is blocked until it is renewed.';

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
  String get extPermBypassRead => 'See the DPI-bypass state and capabilities';

  @override
  String get extPermBypassWrite => 'Change the DPI-bypass strategy (affects how traffic is reshaped)';

  @override
  String get extPermBypassTune => 'Run automatic DPI-bypass tuning (probes the network)';

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
    return 'Դեպի $name';
  }

  @override
  String get diagnosticHttp => 'HTTP ախտորոշում';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Դեռևս գրանցված հարցումներ չկան: Սկզբում բացեք արագության թեստավորման կայք:';

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
  String get favorites => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorites yet. Tap the star on a server to add it here.';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

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
  String benchmarkProgress(int done, int total) {
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
  String profileDeleteConfirm(String name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String profileApplyAsk(String name) {
    return 'Apply profile \"$name\"?';
  }

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) {
    return 'Profile \"$name\" applied';
  }

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) {
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
  String chainDeleteConfirm(String name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(String n) {
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
  String syncRevokeConfirm(String name) {
    return 'Revoke \"$name\"?';
  }

  @override
  String syncLastSync(String time) {
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
  String get lanSharing => 'Share connection on the local network';

  @override
  String get lanSharingHint =>
      'Devices on this network can go online through this connection. Access is by password: enter the proxy address, login and password below on the other device.';

  @override
  String get lanSharingLogin => 'Login';

  @override
  String get lanSharingNoAddress =>
      'No local network address yet — the address will appear here when this device is connected to a network.';

  @override
  String get lanSharingPassword => 'Password';

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
  String get obfsPresetLight => 'Light';

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
  String get obfsMux => 'Multiplexing';

  @override
  String get obfsMuxDetail =>
      'Mux sends many streams over one TLS connection to a REALITY server, so the network sees a single handshake. Turn it off only if a server mishandles mux; separate handshakes may stand out more.';

  @override
  String get fragmentPerSessionNote =>
      'Per-session only: the stored obfuscation profile overrides this when connecting. Curated presets live in Traffic obfuscation.';

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

  @override
  String get errConnectionsUnavailable => 'The connection list is unavailable right now';

  @override
  String get errDiagnosticsFailed => 'Could not collect diagnostics';

  @override
  String get errDiagnosticsTooLarge => 'The diagnostics archive is too large';

  @override
  String get errEngineStalled => 'The tunnel stopped passing traffic';

  @override
  String get errEngineUnstable => 'The engine is unstable and keeps stopping';

  @override
  String get errNotFound => 'The requested item was not found';

  @override
  String get errProxyFailed => 'Could not set up the system proxy';

  @override
  String get errLogsUnavailable => 'This core does not keep a log';

  @override
  String get errLogFilterInvalid => 'The log filter is not valid: check the expression and the time range';

  @override
  String get errLogExportFailed => 'Could not export the log: it is too large. Narrow the filter and try again.';

  @override
  String get errProbeEndpointInvalid => 'A server address is missing or not valid';

  @override
  String get errProbeNoEndpoints => 'There are no servers to check';

  @override
  String get errProbeTooMany => 'Too many servers to check at once';

  @override
  String get errProbeUnsupported => 'This core does not support checking servers';

  @override
  String get errProbeChainInvalid => 'Invalid server chain: pick 2 or 3 different servers';

  @override
  String get errBypassStrategyInvalid => 'Invalid bypass strategy: check the split positions and desync settings';

  @override
  String get errCancelled => 'The operation was cancelled';

  @override
  String get errRequestTooLarge => 'The request is too large';

  @override
  String get errSecretNotFound => 'A needed secret was not found';

  @override
  String get errSecretReferenceInvalid => 'The secret reference is not valid';

  @override
  String get errSecretTooLarge => 'The secret is too large to store';

  @override
  String get errSubNotFound => 'The subscription was not found';

  @override
  String get errSubIntervalInvalid => 'The update interval must be between one hour and 30 days';

  @override
  String get deviceIdTitle => 'Device identity';

  @override
  String get deviceIdSend => 'Send device identifier to subscription providers';

  @override
  String get deviceIdSendDetail => 'Providers with a device limit require the identifier to return the subscription.';

  @override
  String get deviceIdCurrent => 'Current identifier';

  @override
  String get deviceIdCopy => 'Copy';

  @override
  String get deviceIdReset => 'Reset identifier';

  @override
  String get deviceIdResetConfirm =>
      'Reset the device identifier? The provider will count this as a new device, and the reset may take another slot of its device limit. The old identifier is not kept.';
}
