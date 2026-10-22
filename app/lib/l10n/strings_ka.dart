// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Georgian (`ka`).
class SKa extends S {
  SKa([String locale = 'ka']) : super(locale);

  @override
  String get stateOff => 'არ არის დაკავშირებული';

  @override
  String get stateConnecting => 'დაკავშირება';

  @override
  String get stateConnected => 'დაკავშირებულია';

  @override
  String get stateReconnecting => 'ხელახლა დაკავშირება';

  @override
  String get stateDisconnecting => 'გათიშვა';

  @override
  String get coreMissing => 'Sora სერვისი არ პასუხობს';

  @override
  String get serverAuto => 'ყველაზე სწრაფი';

  @override
  String get serverBypass => 'სერვერი არ არის';

  @override
  String get addSubscription => 'დაამატეთ გამოწერა';

  @override
  String get servers => 'სერვერები';

  @override
  String get settings => 'პარამეტრები';

  @override
  String get subscription => 'გამოწერა';

  @override
  String get subscriptionLink => 'გამოწერის ბმული';

  @override
  String get add => 'დამატება';

  @override
  String get refresh => 'განახლება';

  @override
  String get rename => 'გადარქმევა';

  @override
  String get delete => 'წაშლა';

  @override
  String get cancel => 'გაუქმება';

  @override
  String get save => 'შენახვა';

  @override
  String get name => 'სახელი';

  @override
  String deleteSubscription(String name) {
    return 'წაშალოთ „$name“?';
  }

  @override
  String get routes => 'მარშრუტები';

  @override
  String get presetGlobal => 'ყველაფერი VPN-ის საშუალებით';

  @override
  String get presetRu => 'რუსეთი პირდაპირ';

  @override
  String get presetIr => 'პირდაპირი ირანი';

  @override
  String get presetCn => 'პირდაპირი ჩინეთი';

  @override
  String get blockAds => 'რეკლამის დაბლოკვა';

  @override
  String get killSwitch => 'ინტერნეტი მხოლოდ VPN-ის საშუალებით';

  @override
  String get engine => 'ძრავი';

  @override
  String get engineAuto => 'ავტო';

  @override
  String get animations => 'ანიმაციები';

  @override
  String get logs => 'შესვლა';

  @override
  String get about => 'შესახებ';

  @override
  String get logsAll => 'ყველა';

  @override
  String get logsImportant => 'მნიშვნელოვანი';

  @override
  String get logsErrors => 'შეცდომები';

  @override
  String get search => 'ძიება';

  @override
  String get export => 'ფაილში შენახვა';

  @override
  String get clear => 'წმინდა';

  @override
  String get logsEmpty => 'აქ არაფერი';

  @override
  String get connEmpty => 'არანაირი კავშირი';

  @override
  String appVersion(String version) {
    return 'ვერსია $version';
  }

  @override
  String get notInstalled => 'არ არის დაინსტალირებული';

  @override
  String get sourceCode => 'წყაროს კოდი';

  @override
  String get license => 'ლიცენზია';

  @override
  String usage(String used, String total) {
    return '$used $total-დან';
  }

  @override
  String until(String date) {
    return '$date-მდე';
  }

  @override
  String get expired => 'ვადა გაუვიდა';

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
    return '$n კბ';
  }

  @override
  String bytesMB(String n) {
    return '$n მბ';
  }

  @override
  String bytesGB(String n) {
    return '$n GB';
  }

  @override
  String bytesTB(String n) {
    return '$n ტუბერკულოზი';
  }

  @override
  String get errGeneric => 'რაღაც შეფერხდა';

  @override
  String get errCore => 'Sora სერვისი არ პასუხობს';

  @override
  String get errAuth => 'არ არის წვდომა Sora სერვისზე';

  @override
  String get errVersion => 'განაახლეთ Sora: აპლიკაცია და სერვისი განსხვავებული ვერსიებია';

  @override
  String get errBusy => 'დაელოდეთ, წინა ბრძანება ჯერ კიდევ მუშაობს';

  @override
  String get errEngineMissing => 'ამ სერვერისთვის ძრავა ვერ მოიძებნა';

  @override
  String get errEngineStart => 'ძრავა არ დაიწყო';

  @override
  String get errEngineStopped => 'ძრავა გაჩერდა';

  @override
  String get errTunnel => 'VPN კავშირის შექმნის ნებართვა არ არის';

  @override
  String get errServers => 'სერვერი კონფიგურირებულია შეცდომით';

  @override
  String get errNetwork => 'სერვერთან დაკავშირება შეუძლებელია';

  @override
  String get errTimeout => 'სერვერმა დროულად არ უპასუხა';

  @override
  String get errFirewall => 'VPN-ის გარეთ ინტერნეტის დაბლოკვა ვერ მოხერხდა';

  @override
  String get errSubFetch => 'გამოწერა ვერ ჩაიტვირთა';

  @override
  String get errSubFormat => 'ეს არ არის გამოწერის ბმული';

  @override
  String get errSubEmpty => 'გამოწერას არ აქვს სერვერები';

  @override
  String get errSubDuplicate => 'ეს გამოწერა უკვე დამატებულია';

  @override
  String get errSubLimit => 'ძალიან ბევრი გამოწერა';

  @override
  String get errSubScheme => 'ბმული უნდა დაიწყოს https://';

  @override
  String get errSecretStore => 'Sora საცავი დაზიანებულია ან მიუწვდომელია';

  @override
  String get errNoServers => 'დასაკავშირებლად დაამატეთ გამოწერა';

  @override
  String get connections => 'კავშირები';

  @override
  String get close => 'დახურვა';

  @override
  String get chainDirect => 'პირდაპირი';

  @override
  String get chainBlocked => 'დაბლოკილია';

  @override
  String get theme => 'თემა';

  @override
  String get themeSystem => 'სისტემის მიხედვით';

  @override
  String get themeLight => 'სინათლე';

  @override
  String get themeDark => 'ბნელი';

  @override
  String get language => 'ენა';

  @override
  String get languageSystem => 'სისტემის მიხედვით';

  @override
  String get sectionConnection => 'კავშირი';

  @override
  String get sectionNoServer => 'სერვერი არ არის';

  @override
  String get sectionPing => 'პინგი';

  @override
  String get sectionLog => 'დიაგნოსტიკა';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'ავტო';

  @override
  String get dnsHint => 'მისამართები, მძიმით გამოყოფილი';

  @override
  String get fragment => 'TLS ფრაგმენტაცია';

  @override
  String get fragmentPackets => 'რა უნდა გაიყოს';

  @override
  String get fragmentLength => 'ცალი ზომა';

  @override
  String get fragmentInterval => 'პაუზა ნაწილებს შორის';

  @override
  String get byDefault => 'ნაგულისხმევი';

  @override
  String get rangeHint => 'მაგალითად 100-200';

  @override
  String get splitPos => 'პოზიციების გაყოფა';

  @override
  String get splitPosHint => 'მაგალითად, 1, midsld';

  @override
  String get disorder => 'ხელახლა შეკვეთა ცალი';

  @override
  String get tlsRecord => 'გაყავით TLS ჩანაწერი';

  @override
  String get tlsRecordNo => 'არა';

  @override
  String get tlsRecordSni => 'საიტის სახელზე';

  @override
  String get tlsRecordFirst => 'პირველი ბაიტის შემდეგ';

  @override
  String get hostCase => 'ჰოსტის ქეისის შეცვლა';

  @override
  String get probeMethod => 'მეთოდი';

  @override
  String get probeAuto => 'ავტო';

  @override
  String get probeEngine => 'ძრავის მეშვეობით';

  @override
  String get probeConnect => 'მხოლოდ კავშირი';

  @override
  String get probeUrl => 'ტესტის მისამართი';

  @override
  String get probeTimeout => 'მოიცადე';

  @override
  String seconds(int n) {
    return '$n ს';
  }

  @override
  String get subscriptions => 'გამოწერები';

  @override
  String get subscriptionSettings => 'პარამეტრები';

  @override
  String get userAgent => 'მომხმარებელი-აგენტი';

  @override
  String get autoUpdate => 'ავტომატურად განახლება';

  @override
  String get updateInterval => 'რამდენად ხშირად';

  @override
  String get intervalProvider => 'როგორც პროვაიდერი ითხოვს';

  @override
  String hours(int n) {
    return '$n სთ';
  }

  @override
  String get updateNow => 'განაახლეთ ახლა';

  @override
  String get logLevel => 'რა ჩაიწეროს';

  @override
  String get levelDebug => 'ყველაფერი';

  @override
  String get levelInfo => 'ჩვეულებრივი';

  @override
  String get levelWarning => 'მნიშვნელოვანი';

  @override
  String get levelError => 'მხოლოდ შეცდომები';

  @override
  String get recordDestinations => 'ჩაწერეთ საიტის მისამართები';

  @override
  String get reset => 'პარამეტრების გადატვირთვა';

  @override
  String get resetConfirm => 'გსურთ ყველა პარამეტრის გადაყენება?';

  @override
  String get resetAction => 'გადატვირთვა';

  @override
  String get invalidValue => 'ეს მნიშვნელობა არ იმუშავებს';

  @override
  String get website => 'გამოწერის გვერდი';

  @override
  String get providerWebsite => 'პროვაიდერის ვებსაიტი';

  @override
  String get support => 'მხარდაჭერა';

  @override
  String controlPortQuestion(String engine) {
    return '$engine კონტროლდება ამ კომპიუტერის პორტის მეშვეობით. სხვა პროგრამებს შეეძლებათ თქვან, რომ VPN ჩართულია.';
  }

  @override
  String chooseEngine(String engine) {
    return 'აირჩიეთ $engine';
  }

  @override
  String get rules => 'მორგებული წესები';

  @override
  String get ruleAdd => 'ახალი წესი';

  @override
  String get ruleHint => 'საიტი, IP ან პროგრამა';

  @override
  String get ruleDirect => 'პირდაპირი';

  @override
  String get ruleProxy => 'VPN-ის საშუალებით';

  @override
  String get ruleBlock => 'დაბლოკვა';

  @override
  String get failover => 'ჩართეთ წარუმატებლობა';

  @override
  String get connectOnStart => 'დაკავშირება დაწყებისას';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'გამოწერა მთავრდება # დღეში',
      one: 'გამოწერა მთავრდება # დღეში',
      zero: 'გამოწერა მთავრდება რამდენიმე საათში',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left დარჩა';
  }

  @override
  String get ruleInvalid => 'ეს არ ჰგავს საიტს, IP-ს ან პროგრამას';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# სერვერები, ყველაზე სწრაფი',
      one: '# სერვერი, ყველაზე სწრაფი',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'რეჟიმი';

  @override
  String get tunnelProxy => 'System პროქსი';

  @override
  String get proxyAddress => 'პროქსის მისამართი';

  @override
  String get copied => 'კოპირებულია';

  @override
  String get launchAtLogin => 'დაიწყეთ სისტემით';

  @override
  String get launchAtLoginDetail => 'შესვლისას Sora ავტომატურად გაეშვება და დარჩება სისტემურ უჯრაში.';

  @override
  String get closeToTray => 'შეინახეთ უჯრაში დახურვისას';

  @override
  String get notifications => 'შეტყობინებები';

  @override
  String get trayOpen => 'გახსენით Sora';

  @override
  String get trayConnect => 'დაკავშირება';

  @override
  String get trayDisconnect => 'გათიშვა';

  @override
  String get trayServer => 'სერვერი';

  @override
  String get trayQuit => 'გამოდით Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora ჯერ კიდევ უჯრაშია';

  @override
  String get noticeInTrayBody => 'გამოდით მისი ხატის მენიუდან';

  @override
  String get noticeLost => 'კავშირი დაიკარგა';

  @override
  String get noticeLostBody => 'Sora ხელახლა უკავშირდება';

  @override
  String get noticeRestored => 'ისევ დაუკავშირდა';

  @override
  String get noticeFailed => 'დაკავშირება ვერ მოხერხდა';

  @override
  String get noticeBackup => 'მთავარმა სერვერმა არ უპასუხა; სარეზერვო ახორციელებს ტრაფიკს';

  @override
  String get noticeNext => 'სერვერმა არ უპასუხა; შემდეგი ახორციელებს მოძრაობას';

  @override
  String get noticeMainBack => 'მთავარი სერვერი ისევ პასუხობს და ახორციელებს ტრაფიკს';

  @override
  String get noticeSubscription => 'გამოწერა';

  @override
  String get importTitle => 'დაამატეთ ეს გამოწერა?';

  @override
  String get importSealed =>
      'ეს ბმული დაშიფრულია Happ-სთვის და მხოლოდ Happ-ს შეუძლია მისი წაკითხვა. სთხოვეთ თქვენს პროვაიდერს უბრალო გამოწერის ბმული.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'პასუხი არ არის';

  @override
  String get home => 'მთავარი';

  @override
  String get navRules => 'წესები';

  @override
  String get navConnections => 'კავშირები';

  @override
  String get navLogs => 'ჟურნალები';

  @override
  String get navAbout => 'შესახებ';

  @override
  String get sidebarToggle => 'გვერდითი ზოლის გადართვა';

  @override
  String get more => 'მეტი';

  @override
  String get less => 'ნაკლები';

  @override
  String get notificationsEmpty => 'კავშირისა და გამოწერის მოვლენები აქ გამოჩნდება';

  @override
  String get retryConnect => 'ხელახლა სცადეთ კავშირი';

  @override
  String get openLogs => 'გახსენით ჟურნალები';

  @override
  String get tourReplay => 'ხელახლა აჩვენე სახელმძღვანელო';

  @override
  String tourStep(int step) {
    return 'ნაბიჯი $step 5-დან';
  }

  @override
  String get tourBack => 'უკან';

  @override
  String get tourNext => 'შემდეგი';

  @override
  String get tourSkip => 'გამოტოვება';

  @override
  String get tourFinish => 'შესრულებულია';

  @override
  String get tourAdd => 'დაამატეთ თქვენი პროვაიდერის გამოწერის ბმული.';

  @override
  String get tourServer => 'აირჩიეთ სერვერი. „უსწრაფესი“ ირჩევს ერთს თქვენთვის.';

  @override
  String get tourConnect => 'დააწკაპუნეთ აქ დასაკავშირებლად ან გასათიშად.';

  @override
  String get tourMode => 'აირჩიეთ რეჟიმი. Kill switch ბლოკავს ინტერნეტს, თუ VPN ჩამოვარდება.';

  @override
  String get tourSettings => 'გახსენით პარამეტრები. თქვენ შეგიძლიათ გაიმეოროთ ეს სახელმძღვანელო იქ.';

  @override
  String get chooseProgram => 'აირჩიეთ პროგრამა';

  @override
  String get installedApps => 'დაინსტალირებული აპლიკაციები';

  @override
  String get runningProcesses => 'მიმდინარე პროცესები';

  @override
  String get programsEmpty => 'აპლიკაციები ვერ მოიძებნა. სცადეთ სხვა სახელი.';

  @override
  String get selectExe => 'აირჩიეთ .exe ფაილი';

  @override
  String get speedtest => 'სიჩქარე';

  @override
  String get speedtestSearch => 'მოძებნეთ სერვისი';

  @override
  String get speedtestEmpty => 'არანაირი მატჩი. შეცვალეთ ძებნა.';

  @override
  String get speedtestBackToList => 'დაუბრუნდით სერვისებს';

  @override
  String get speedtestOpenBrowser => 'გახსენით ბრაუზერში';

  @override
  String get speedtestUnavailable =>
      'ჩაშენებული ბრაუზერის გაშვება ვერ მოხერხდა. გახსენით სერვისი თქვენი სისტემის ბრაუზერში.';

  @override
  String get speedtestPageFailed =>
      'გვერდი ვერ ჩაიტვირთა. გადატვირთეთ იგი ან გახსენით სერვისი თქვენი სისტემის ბრაუზერში.';

  @override
  String get speedtestExternalFailed => 'სისტემის ბრაუზერი ვერ გაიხსნა. სცადეთ ხელახლა.';

  @override
  String get modes => 'რეჟიმები';

  @override
  String get proxyShort => 'პროქსი';

  @override
  String get tunMode => 'მთელი ტრაფიკი (TUN)';

  @override
  String get checkUpdates => 'შეამოწმეთ განახლებები';

  @override
  String get updates => 'აპლიკაციის განახლებები';

  @override
  String updateAvailable(String version) {
    return 'ვერსია $version ხელმისაწვდომია';
  }

  @override
  String get updateOpenAbout => 'განახლების ნახვა';

  @override
  String updateNotes(String version) {
    return 'ცვლილებები $version-ში';
  }

  @override
  String get updateCheck => 'შეამოწმეთ განახლებები';

  @override
  String get updateChecking => 'მიმდინარეობს შემოწმება...';

  @override
  String get updateNoNotes => 'გამოცემას არ აქვს შენიშვნები.';

  @override
  String get updateDropWarning =>
      'VPN კავშირი შეწყდება რამდენიმე წამით, ხოლო Sora და მისი ძირითადი განახლება. გაგრძელება?';

  @override
  String get updateWaitConnection => 'დაელოდეთ სანამ VPN კავშირი და ბირთვი მზად იქნება.';

  @override
  String get updateDownloading => 'მიმდინარეობს ფაილების ჩამოტვირთვა და დადასტურება...';

  @override
  String get updateInstalling => 'განახლების მომზადება ან ადმინისტრატორის ავტორიზაციის მოლოდინში...';

  @override
  String get updateNetworkError => 'განახლების ჩამოტვირთვა ვერ მოხერხდა. სცადეთ ხელახლა.';

  @override
  String get updateReleaseError => 'გამოშვების მონაცემები ან საჭირო ფაილები აკლია ან არასწორია.';

  @override
  String get updateChecksumError => 'ჩამოტვირთვა არ ემთხვევა SHA256SUMS. არაფერი არ იყო დაინსტალირებული.';

  @override
  String get updateInstallError => 'განახლება არ დასრულებულა. ავთენტიფიკაცია შეიძლება გაუქმდა.';

  @override
  String get updateUnsupported =>
      'ეს შესრულებადი არ ეკუთვნის მხარდაჭერილ Sora პაკეტის წყვილს. გამოიყენეთ გამოშვების ინსტალაციის ინსტრუქციები.';

  @override
  String get updateManual =>
      'გაუშვით ეს ბრძანება ტერმინალში ორივე დამოწმებული პაკეტის დასაყენებლად, შემდეგ ხელახლა გახსენით Sora. ფაილები რჩება ჩამოტვირთვის დირექტორიაში. VPN კავშირი შეწყდება.';

  @override
  String get updateSignaturePending =>
      'განახლების ფაილები მოწმდება გამოშვებასთან ერთად გამოქვეყნებული საკონტროლო ჯამებით.';

  @override
  String get updateManualSigWarning =>
      'ქვემოთ მოცემული ფაილები ემთხვევა გამოშვების საკონტროლო ჯამებს. გაუშვით ბრძანება, თუ ისინი ოფიციალური გამოშვებიდან ჩამოტვირთეთ.';

  @override
  String get updateVersionRevoked => 'დეველოპერმა გააუქმა ეს ვერსია. გთხოვთ, დაელოდოთ შესწორებულ გამოცემას.';

  @override
  String get updateRolloutPending => 'უფრო ახალი ვერსია გამოდის თანდათანობით და შემოგთავაზებთ ავტომატურად.';

  @override
  String updateRollbacking(String version) {
    return 'დაბრუნება ვერსიაზე $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version-ის განახლებამ ვერ გაიარა ჯანმრთელობის შემოწმება, ამიტომ Sora დაბრუნდა $fromVersion-ზე.';
  }

  @override
  String get updateRollbackError =>
      'ავტომატური დაბრუნება ვერ მოხერხდა. თუ ახალი ვერსია არ მუშაობს, ხელახლა დააინსტალირეთ წინა ვერსია ხელით.';

  @override
  String get updateRollbackCacheError =>
      'ვერ მოვამზადე მიმდინარე ვერსიის დადასტურებული ასლი, ამიტომ განახლება არ იყო დაინსტალირებული.';

  @override
  String get updateCopyCommand => 'დააკოპირეთ ბრძანება';

  @override
  String get updateChecksDisabled => 'ავტომატური შემოწმება გამორთულია პარამეტრებში.';

  @override
  String get updateInstalled => 'დაინსტალირებულია განახლება. ხელახლა გახსენით Sora.';

  @override
  String get projectLinks => 'პროექტი';

  @override
  String get githubReleases => 'გამოშვება და ჩამოტვირთვები';

  @override
  String get telegramChannel => 'Telegram არხი';

  @override
  String get licenses => 'ლიცენზიები';

  @override
  String get componentLicenses => 'კომპონენტების ლიცენზიები';

  @override
  String get collapseServers => 'სერვერების ჩაკეცვა';

  @override
  String get expandServers => 'სერვერების გაფართოება';

  @override
  String get hideDescription => 'აღწერილობის დამალვა';

  @override
  String get showDescription => 'აღწერილობის ჩვენება';

  @override
  String get pendingConnectionChanges => 'ხელახლა დაუკავშირდით ამ ცვლილებების გამოსაყენებლად.';

  @override
  String get reconnectNow => 'მიმართეთ და ხელახლა დაუკავშირდით';

  @override
  String get errEngineUnsupported =>
      'არჩეული ძრავა არ უჭერს მხარს ამ პროფილს ან პარამეტრებს. აირჩიეთ ავტო ან თავსებადი ძრავა.';

  @override
  String get errRestore => 'კავშირის გასუფთავება არასრული იყო. ხელახლა სცადეთ გათიშვა; იხილეთ ჟურნალი დეტალებისთვის.';

  @override
  String get errSessionEnded => 'ეს სესია უკვე დასრულდა. განაახლეთ კავშირის მდგომარეობა.';

  @override
  String get retryDisconnect => 'ხელახლა სცადეთ გათიშვა';

  @override
  String get tunStack => 'TUN დასტა';

  @override
  String get modesInfo => 'რეჟიმების შესახებ';

  @override
  String get modesGuideTitle => 'რეჟიმები და ძრავები';

  @override
  String get modesGuide =>
      'აირჩიეთ ავტო, თუ არ ხართ დარწმუნებული, რომელი ძრავა სჭირდება თქვენს სერვერს. Sora ამოწმებს პროფილს და პარამეტრებს დაკავშირებამდე. ძრავას არ შეუძლია გაზარდოს თქვენი გეგმის გამტარუნარიანობა: შესრულება დამოკიდებულია სერვერზე, მარშრუტზე, პროტოკოლზე და ქსელზე.\n\n## რეჟიმები\n\n### მთელი ტრაფიკი (TUN)\n\nSora ქმნის ვირტუალურ ქსელურ ინტერფეისს და მარშრუტებს აპლიკაციის ტრაფიკს, მათ შორის TCP და UDP. გამოიყენეთ ეს რეჟიმი Telegram, თამაშებისთვის და Discord ხმისთვის. წესებს შეუძლიათ გააგზავნონ კონკრეტული საიტები ან პროგრამები პირდაპირ ან დაბლოკონ ისინი. ქსელის სერვისს სჭირდება ნებართვა და სერვერი, რომელიც მხარს უჭერს საჭირო პროტოკოლს.\n\n### System პროქსი\n\nSora აკონფიგურირებს ადგილობრივ HTTP/SOCKS პროქსის. აპლიკაციები, რომლებიც პატივს სცემენ სისტემის პროქსის პარამეტრებს, იყენებენ მას. აპლიკაციები საკუთარი ქსელის სტეკით შეიძლება პირდაპირ დაუკავშირდნენ; UDP და ხმოვანი ზარები ზოგადად საჭიროებენ TUN. ეს რეჟიმი შეესაბამება ბრაუზერებს და აპლიკაციებს პროქსი მხარდაჭერით.\n\n### სერვერი არ არის\n\nLinux-ზე Sora იყენებს [zapret](https://github.com/bol-van/zapret) HTTP/TLS მოთხოვნების გაყოფისა და ფორმის გადასაჭრელად და ზოგიერთი DPI შემოწმების გვერდის ავლით. თქვენი IP იგივე რჩება და კავშირები პირდაპირ ვებსაიტზე მიდის. შედეგები დამოკიდებულია თქვენს პროვაიდერზე და დაბლოკვის მეთოდზე.\n\nმიმდინარე ინტეგრაცია იყენებს tpws-ს HTTP-სთვის და TLS-ისთვის TCP-ზე. ის არ გვერდს უვლის IP ბლოკირებას ან გადასცემს UDP-ს და ვერ უზრუნველყოფს Telegram-ის MTProto კავშირების გარანტიას. გამოიყენეთ VPN სერვერი TUN-ით Discord ხმის, Telegram ზარებისთვის და ამ სახის შეზღუდვებისთვის.\n\n## ძრავები\n\n### ავტო\n\nSora ირჩევს დაყენებულ ძრავას, რომელიც მხარს უჭერს კავშირის მთელ გეგმას: სერვერის პროტოკოლებს, ტრანსპორტებს, ჯგუფებს, ფრაგმენტაციას და რეჟიმს. შეუთავსებელი ხელით არჩევანი უარყოფილია მიმდინარე კავშირის შეწყვეტამდე. აირჩიეთ Auto ან სხვა ძრავა და კვლავ გამოიყენეთ პარამეტრები.\n\n### sing-box\n\nახალი Sora პაკეტები მოიცავს [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), ჩანგალი [sing-box](https://github.com/SagerNet/sing-box), კლიენტის მხარეს XHTTP და VLESS Encryption დამატება. Sora აღიარებს კონსტრუქციას და მის შესაძლებლობებს. ზემოთ ნაგებობა XHTTP-ის გარეშე არ იძენს ამ შესაძლებლობას მხოლოდ მისი სახელიდან.\n\nმხარდაჭერილია VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard და AmneziaWG 1.x/2.x-ის ის პარამეტრები, რომელთა იმპორტიც Sora-ს შეუძლია. სრულ Xray JSON პროფილებს Xray სჭირდება. ახალი AWG 3.x ველების იმპორტი ჯერ შეუძლებელია. sing-box იყენებს პაროლით დაცულ ადგილობრივ მართვის პორტს, რომლის აღმოჩენაც კომპიუტერის სხვა პროგრამებს შეუძლიათ.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) მხარს უჭერს VLESS, REALITY, XHTTP, VLESS Encryption და TLS ფრაგმენტაციას. ის ასევე აწარმოებს სრულ პროვაიდერის Xray პროფილებს მათი მარშრუტიზაციისა და ჯგუფების შენარჩუნებით. ასეთი პროფილები არ შეიძლება ავტომატურად გადაიზარდოს სხვა ძრავზე მათი ქცევის შეცვლის გარეშე.\n\nშეფუთულმა Xray-მ წაშალა პარამეტრი, რომელიც გამორთავს TLS სერტიფიკატის დადასტურებას (`allowInsecure`). ავტომატურად ირჩევს sing-box ან mihomo ჩვეულებრივი სერვერებისთვის, რომლებიც საჭიროებენ ამ პარამეტრს. Xray-ის არჩევა ხელით აცნობებს შეუთავსებლობას მიმდინარე კავშირის შეწყვეტამდე. ძველ სრულ JSON პროფილებს სჭირდებათ განახლებული პროვაიდერის პროფილი დამოწმებადი სერტიფიკატით ან სერტიფიკატის პინით.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) მხარს უჭერს შეკვეთილ სარეზერვო და დატვირთვის დაბალანსების ჯგუფებს, XHTTP და AmneziaWG. აირჩიეთ ის, როდესაც მნიშვნელოვანია სარეზერვო სერვერზე ავტომატური ჩავარდნა. Sora-ის TLS ფრაგმენტაციის პარამეტრი მიუწვდომელია ამ ძრავით.\n\n## თავსებადობა Sora-ში\n\n| თვისება | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN და TCP/UDP | დიახ | დიახ | დიახ |\n| XHTTP | დიახ | დიახ | დიახ |\n| VLESS Encryption | დიახ | დიახ | დიახ |\n| სრული Xray პროფილი | არა | დიახ | არა |\n| TUIC / AnyTLS | ორივე | არა | TUIC |\n| TLS ფრაგმენტაცია | დიახ | დიახ | არა |\n| AmneziaWG 1.x/2.x | დიახ¹ | არა | დიახ |\n| შეკვეთილი სარეზერვო ჯგუფი | არა | No² | დიახ |\n\n¹ პროფილები J1/J2/J3/Itime იყენებენ mihomo; ეს ველები არასოდეს არ უნდა იყოს ჩუმად გაუქმებული. ² სრული Xray პროფილების ჯგუფისთვის აპლიკაცია ირჩევს სარეზერვო პროფილს. მხარდაჭერა დამოკიდებულია დაყენებულ კონსტრუქციაზე; შეამოწმეთ მისი ვერსია შესახებ.\n\n## TUN დასტა\n\nსტეკი ამუშავებს TCP და UDP-ს ვირტუალურ ინტერფეისში. რეჟიმების პანელში Xray და mihomo გვთავაზობენ gVisor, System, Mixed და MIPS. თითოეული ძრავა ინახავს საკუთარ უპირატესობას. System პროქსი და სერვერის რეჟიმი არ იყენებს ამ პარამეტრს.\n\n- **Mixed**: TCP იყენებს სისტემის დასტას, ხოლო gVisor ამუშავებს UDP-ს. ეს არის mihomo-ს ნაგულისხმევი ვარიანტი Linux-ზე. Windows-ზე Xray და mihomo ნაგულისხმევად MIPS-ს იყენებენ.\n- **System**: იყენებს სისტემის დასტას. სცადეთ სხვა ვარიანტი, თუ ქსელის აპლიკაციებს პრობლემები შეექმნათ.\n- **gVisor**: მართავს ტრაფიკს მომხმარებლის სივრცეში.\n- **MIPS**: mihomo-ის საკუთარი IP დასტა, ხელმისაწვდომია შეფუთულ ვერსიაში 1.19.32.\n\nLinux-ზე, Xray ნაგულისხმევად იყენებს ჩაშენებულ gVisor-ს. System, Mixed და MIPS Linux-ზე იყენებენ mihomo, როგორც TUN ძრავას, გადაგზავნის TCP და UDP-ს Xray ავთენტიფიცირებულ ლოკალურ SOCKS ბმულზე. Xray ინარჩუნებს პროტოკოლს, პროვაიდერის პროფილს და მარშრუტიზაციას. ამ სამ ვარიანტს სჭირდება დაინსტალირებული mihomo. Windows-ზე Xray ოთხივე TUN სტეკისთვის იყენებს mihomo 1.19.32-ს ან უფრო ახალ ვერსიას. პროტოკოლები და მარშრუტიზაცია რჩება Xray-ში. ამ კომბინაციაში აპლიკაციების წესები მხარს უჭერს მხოლოდ პირდაპირ კავშირს და დაბლოკვას; Linux-ზე ამ წესებს სჭირდება Xray-ის ჩაშენებული gVisor.\n\nხიდი გადის მეორე პროცესს. სამი უმოქმედო გაზომვისას Linux-ზე, მან გამოიყენა დაახლოებით 32–36 MiB მეტი ფიზიკური მეხსიერება, ვიდრე მშობლიურ Xray TUN. ეს არ ზომავს ჩამოტვირთვის დატვირთვას: CPU და მეხსიერების ხარჯები დამოკიდებულია კავშირებზე. sing-box-ს არ აქვს სტეკის ამომრჩევი. არცერთი დასტა არ იძლევა გარანტიას უკეთესი მუშაობის ყველა ქსელში. აირჩიეთ დასტა და აირჩიეთ მიმართვა და ხელახლა დაკავშირება თქვენს ქსელში საცდელად.\n\n## პარამეტრების გამოყენება\n\nსერვერის არჩევა ხელახლა დაკავშირდება ავტომატურად. რეჟიმი, ძრავა, DNS და წესების პარამეტრები დაუყოვნებლივ ინახება; აქტიური კავშირის დროს დააწკაპუნეთ Apply-ზე და ხელახლა დაუკავშირდით მათ გამოსაყენებლად. ძრავის გადატვირთვამ შეიძლება შეაფერხოს ჩამოტვირთვები და ზარები. განმეორებითი დაწკაპუნება არ იწყებს პარალელურ კავშირებს; გათიშვა წყვეტს გადასვლას და ათავისუფლებს კავშირს.\n\nინტერნეტი მხოლოდ VPN-ის საშუალებით ბლოკავს პირდაპირ ტრაფიკს, როდესაც გვირაბი ჩამოვარდება. ეს გავლენას ახდენს მთელ მანქანაზე. აშკარა გათიშვა შლის Sora-ის წესებს. თუ გასუფთავება არ დასრულებულა, ხელახლა სცადეთ გათიშვა და გახსენით ჟურნალი.\n\n## პროექტის დოკუმენტაცია\n\n- [sing-box-lx: კონფიგურაცია და მხარდაჭერა] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box დოკუმენტაცია] (https://sing-box.sagernet.org/)\n- [Xray დოკუმენტაცია] (https://xtls.github.io/)\n- [mihomo დოკუმენტაცია] (https://wiki.metacubex.one/)\n- [zapret: ოპერაცია და შეზღუდვები] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'შეამოწმეთ სერვერები';

  @override
  String get extensions => 'გაფართოებები';

  @override
  String extRatingLabel(String rating) {
    return 'რეიტინგი $rating 5-დან';
  }

  @override
  String extByAuthor(String author) {
    return '$author-ის მიერ';
  }

  @override
  String extInstallsCount(String count) {
    return 'ინსტალაციები: $count';
  }

  @override
  String get extInstallOne => '1 ინსტალაცია';

  @override
  String get extBadgeVerified => 'დამოწმებულია';

  @override
  String get extBadgeTop => 'ყველაზე პოპულარული ამ კვირაში';

  @override
  String get extBadgeNew => 'ახალი';

  @override
  String get extBadgeStaff => 'Sora გუნდი';

  @override
  String get extSideloadShort => 'არა კატალოგიდან';

  @override
  String get extSideloadWarning =>
      'ეს გაფართოება არ არის გუნდის კატალოგიდან. მხოლოდ ავტორმა დადო გარანტია მათი გასაღებისთვის: დააინსტალირეთ მხოლოდ იმ შემთხვევაში, თუ ენდობით ავტორს.';

  @override
  String extInstallTitle(String name) {
    return '„$name“-ის დაყენება';
  }

  @override
  String extUpdateTitle(String name) {
    return '„$name“-ის განახლება';
  }

  @override
  String get extPermissionsIntro => 'ამ გაფართოებას შეეძლება:';

  @override
  String get extPermissionsWidened => 'განახლება ითხოვს ახალ ნებართვებს:';

  @override
  String get extDangerousAck => 'მესმის, რომ ეს ნებართვები სერიოზულია';

  @override
  String get extInstall => 'დააინსტალირეთ';

  @override
  String get extUpdate => 'განახლება';

  @override
  String get extCancel => 'გაუქმება';

  @override
  String get extConfirm => 'დაადასტურეთ';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'კატალოგი';

  @override
  String get extInstalled => 'დაინსტალირებული გაფართოებები';

  @override
  String get extSearchHint => 'გაფართოებების ძიება';

  @override
  String get extCatAll => 'ყველა';

  @override
  String get extCatTools => 'ხელსაწყოები';

  @override
  String get extCatThemes => 'თემები';

  @override
  String get extCatAutomation => 'ავტომატიზაცია';

  @override
  String get extCatStats => 'სტატისტიკა';

  @override
  String get extCatNetwork => 'ქსელი';

  @override
  String get extSortBy => 'დალაგება';

  @override
  String get extSortPopular => 'ყველაზე პოპულარული';

  @override
  String get extSortRating => 'ყველაზე მაღალი რეიტინგი';

  @override
  String get extSortName => 'დასახელება';

  @override
  String get extCatalogError => 'კატალოგის ჩატვირთვა ვერ მოხერხდა';

  @override
  String get extRetry => 'ხელახლა სცადეთ';

  @override
  String get extEmptySearch => 'ვერაფერი მოიძებნა';

  @override
  String get extEmptyInstalled =>
      'გაფართოებები ჯერ არ არის დაინსტალირებული.\nიპოვეთ ერთი კატალოგში ან დააინსტალირეთ ფაილიდან.';

  @override
  String get extInstallFromFile => 'ინსტალაცია ფაილიდან';

  @override
  String get extInstallFromUrl => 'ინსტალაცია URL-დან';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'ჩამოტვირთვა';

  @override
  String get extDownloading => 'მიმდინარეობს ჩამოტვირთვა…';

  @override
  String get extVerifying => 'დადასტურება…';

  @override
  String get extInstalling => 'ინსტალაცია…';

  @override
  String get extInstallFailed => 'ინსტალაცია ვერ მოხერხდა';

  @override
  String get extErrSignature => 'ხელმოწერის შემოწმება ვერ მოხერხდა. ფაილი შეიძლება იყოს დაზიანებული ან დაზიანებული.';

  @override
  String get extErrManifest => 'გაფართოების manifest არასწორია.';

  @override
  String get extErrNetwork => 'ქსელის შეცდომა. შეამოწმეთ თქვენი კავშირი და სცადეთ ხელახლა.';

  @override
  String get extErrHash => 'ჩამოტვირთვა არ ემთხვევა კატალოგს. შესაძლოა, ის გატეხილი იყო.';

  @override
  String extErrMinApp(String version) {
    return 'ამ გაფართოებას სჭირდება აპის ვერსია $version ან უფრო ახალი.';
  }

  @override
  String get extErrHttpsOnly => 'დასაშვებია მხოლოდ https:// ბმული';

  @override
  String get extErrGeneric => 'რაღაც შეფერხდა. გთხოვთ, სცადოთ ხელახლა.';

  @override
  String get extErrAuthorKeyChanged =>
      'ეს განახლება ხელმოწერილია სხვა ავტორის გასაღებით, ვიდრე დაინსტალირებული ვერსია, ამიტომ დაბლოკილია. თუ ენდობით ახალ გასაღებს, წაშალეთ გაფართოება და ხელახლა დააინსტალირეთ იგი აშკარად.';

  @override
  String get extUpdateAvailable => 'განახლება ხელმისაწვდომია';

  @override
  String get extDisabled => 'გამორთულია';

  @override
  String extToggleEnabled(String name) {
    return 'ჩართეთ $name';
  }

  @override
  String get extSearchInstalled => 'დაყენებული გაფართოებების ძიება';

  @override
  String get extUpdateAll => 'განაახლეთ ყველაფერი';

  @override
  String extUpdatesAvailable(int count) {
    return '$count განახლებები ხელმისაწვდომია';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count განახლებულია';
  }

  @override
  String get extRiskNormal => 'ნორმალური';

  @override
  String get extRiskSensitive => 'მგრძნობიარე';

  @override
  String get extRiskDangerous => 'მაღალი რისკი';

  @override
  String get extPermissionsRemoved => 'აღარ არის მოთხოვნილი:';

  @override
  String get extUpdateFailedKept => 'წინა ვერსია ჯერ კიდევ დაინსტალირებულია.';

  @override
  String get extConflictsTitle => 'გაფართოების კონფლიქტები';

  @override
  String get extConflictsIntro =>
      'ეს გაფართოებები ერთსა და იმავეს ითხოვს. აირჩიეთ, რომელი იმუშავებს, მეორე დაინსტალირებული დარჩება.';

  @override
  String get extConflictTheme => 'აპლიკაციის თემა';

  @override
  String get extConflictNetHooks => 'ქსელის კაკვები';

  @override
  String extConflictWinner(String name) {
    return 'უპირატესობა: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count კონფლიქტებს თქვენი გადაწყვეტილება სჭირდება';
  }

  @override
  String get extConflictsResolve => 'კონფლიქტების მოგვარება';

  @override
  String get extConflictNote =>
      'თქვენი არჩევანი ინახება ამ მოწყობილობაზე. თემა მაშინვე იცვლება, ქსელური ჰუკები კი ამ ვერსიაში არ ეშვება.';

  @override
  String extVersionLabel(String version) {
    return 'ვერსია $version';
  }

  @override
  String get extAuthor => 'ავტორი';

  @override
  String get extRating => 'რეიტინგი';

  @override
  String get extInstalls => 'ინსტალაციები';

  @override
  String get extVersion => 'ვერსია';

  @override
  String get extAbout => 'ამ გაფართოების შესახებ';

  @override
  String get extPermissionsTitle => 'ნებართვები';

  @override
  String get extNoPermissions => 'არ არის სპეციალური ნებართვები.';

  @override
  String get extSettings => 'პარამეტრები';

  @override
  String get extSaveSettings => 'პარამეტრების შენახვა';

  @override
  String get extSaving => 'ინახება…';

  @override
  String extUpdateTo(String version) {
    return 'განახლება $version-ზე';
  }

  @override
  String get extEnabled => 'ჩართულია';

  @override
  String extRollbackTo(String version) {
    return 'დაბრუნება $version-ზე';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'დაბრუნება ვერსიაზე $version?';
  }

  @override
  String get extUninstall => 'დეინსტალაცია';

  @override
  String extUninstallConfirm(String name) {
    return 'წაიშალოს „$name“ და მისი პარამეტრები?';
  }

  @override
  String get extPanelUnavailable => 'პანელი მიუწვდომელია. გაფართოება შესაძლოა გათიშული ან წაშლილი იყოს.';

  @override
  String get extPermConnectionsRead => 'იხილეთ აქტიური კავშირების სია';

  @override
  String get extPermServersRead => 'იხილეთ თქვენი სერვერების სია';

  @override
  String get extPermSettingsRead => 'წაიკითხეთ აპის პარამეტრები';

  @override
  String get extPermSettingsWrite => 'შეცვალეთ აპის პარამეტრები';

  @override
  String get extPermNotifications => 'შეტყობინებების ჩვენება';

  @override
  String get extPermTray => 'დაამატეთ ელემენტები უჯრის მენიუში';

  @override
  String get extPermUiPanel => 'აპის შიგნით პანელების ჩვენება';

  @override
  String get extPermThemeApply => 'თემების გამოყენება';

  @override
  String get extPermRoutingRules => 'მარშრუტიზაციის წესების დამატება (იმოქმედებს სად მიდის ქსელის ტრაფიკი)';

  @override
  String get extPermNetHooks => 'ინტეგრირება ქსელის გზაზე (DPI შემოვლითი მოდულები)';

  @override
  String get extPermNetFetch => 'მოითხოვეთ URL დაშვებული სიიდან';

  @override
  String get extPermBackground => 'გაუშვით ფონური ამოცანები';

  @override
  String get extPermBackgroundDetail =>
      'ასრულებს დაგეგმილ ამოცანებს მაშინაც კი, როდესაც პანელი დახურულია. შეგიძლიათ დააპაუზოთ ან შეცვალოთ მისი გაშვების სიხშირე გაფართოების პარამეტრებში.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'გადის ფონზე';

  @override
  String get extCapNetHook => 'ბლოკირების გვერდის ავლა და ქსელის ჩარევები';

  @override
  String get extCapPanel => 'ინტერფეისის პანელები';

  @override
  String get extCapRouting => 'მარშრუტიზაციის წესები';

  @override
  String get extCapTheme => 'თემები';

  @override
  String get extCapWidget => 'ვიჯეტები';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'ცვლილებები';

  @override
  String get extImageFailed => 'სურათის ჩატვირთვა ვერ მოხერხდა';

  @override
  String get extRatingHow => 'როგორ მუშაობს რეიტინგები';

  @override
  String get extRatingHowBody =>
      'რეიტინგები იყენებს ბაიესის საშუალოს: გაფართოება მცირე რეიტინგით რჩება შუათან ახლოს, სანამ მეტი ადამიანი არ მისცემს ხმას, ასე რომ, ერთი 5 ვარსკვლავიანი მიმოხილვა ვერ აიყვანს ახალ გაფართოებას ზევით. ბოლო რეიტინგები უფრო მეტს იწონის, ვიდრე ძველები და ანგარიშზე მხოლოდ ერთი რეიტინგი ითვლება.';

  @override
  String get extScreenshots => 'ეკრანის ანაბეჭდები';

  @override
  String get extSortRelevance => 'აქტუალობა';

  @override
  String get extPermNetworkDetail =>
      'ტვირთავს მონაცემებს ინტერნეტიდან VPN-ის გავლით. დაშვებულია მხოლოდ ქვემოთ მოცემული ჰოსტები, დანარჩენი დაბლოკილია.';

  @override
  String get extBgTitle => 'ფონური ამოცანა';

  @override
  String get extBgEnabled => 'გაშვება ფონზე';

  @override
  String get extBgInterval => 'გაშვების ინტერვალი';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# წუთი', one: '# წუთი');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# საათი', one: '# საათი');
    return '$_temp0';
  }

  @override
  String get extBgNote => 'დავალება გრაფიკით ეშვება, სანამ Sora ღიაა, მათ შორის უჯრაში. მინიმალური ინტერვალი 15 წუთია.';

  @override
  String get extBgDisabledNote => 'ჩართეთ გაფართოება მისი ფონის ამოცანის მართვისთვის.';

  @override
  String get extCapNetwork => 'ქსელის წვდომა';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'ქსელი: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'ფაილში $name';
  }

  @override
  String get diagnosticHttp => 'HTTP დიაგნოსტიკა';

  @override
  String get diagnosticNoData => 'ჯერ არ არის ჩაწერილი მოთხოვნა. ჯერ გახსენით სიჩქარის ტესტის ვებსაიტი.';

  @override
  String get qrShareTitle => 'გააზიარეთ QR კოდი';

  @override
  String get qrScanTitle => 'QR კოდის სკანირება';

  @override
  String get qrCopyLink => 'დააკოპირეთ ბმული';

  @override
  String get qrWarning => 'კოდი მხოლოდ სანდო ადამიანებს გაუზიარეთ.';

  @override
  String get qrScanHint => 'აირჩიეთ ეკრანის სურათი ან ფოტო QR კოდით, ან ჩასვით ბმული';

  @override
  String get qrFromClipboard => 'ჩასმა ბუფერიდან';

  @override
  String get qrNoCode => 'ამ სურათში QR კოდი ვერ მოიძებნა.';

  @override
  String get qrInvalid => 'ეს QR კოდი არ შეიცავს მოქმედ ბმულს.';

  @override
  String get qrScan => 'სკანირება QR';

  @override
  String get qrFromImage => 'სურათის გახსნა';

  @override
  String get connGroupByProcess => 'დაჯგუფება პროცესის მიხედვით';

  @override
  String get connListView => 'სია';

  @override
  String get connCopyHost => 'დააკოპირეთ მასპინძელი';

  @override
  String get connAddRule => 'დაამატე წესი';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# კავშირი', one: '# კავშირი');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'წინასწარ დაყენებული';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'საკუთარი';

  @override
  String get dnsCheck => 'შეამოწმეთ მონაცემთა გაჟონვა';

  @override
  String get dnsChecking => 'შემოწმება...';

  @override
  String get dnsNoLeak => 'გაჟონვა არ მოიძებნა';

  @override
  String get dnsLeakFound => 'აღმოჩენილია გაჟონვა';

  @override
  String get dnsLastCheck => 'ბოლო შემოწმება';

  @override
  String get dnsNeverChecked => 'ჯერ არ არის გამოცდილი';

  @override
  String get dnsLeakCheckTunnelDns => 'გვირაბის DNS რეზოლვერები';

  @override
  String get dnsLeakCheckSystemResolvers => 'სისტემის რეზოლვერები';

  @override
  String get dnsLeakCheckKillSwitchDns => 'DNS-ის დაცვა ქსელის ბლოკირებით';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'დააკონფიგურირეთ DNS გვირაბისთვის ზემოთ DNS პარამეტრებში.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'შეამოწმეთ, რომელ გადამწყვეტებს გამოიყენებდა თქვენი სისტემა გვირაბის გარეთ.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'ჩართეთ ქსელის ბლოკირება, რათა DNS ტრაფიკი გვირაბში დარჩეს.';

  @override
  String get dnsLeakCheckEncryptedDns => 'სისტემის დაშიფრული DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'ყალბი DNS პასუხი';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'შეამოწმეთ, რომელ დაშიფრულ DNS ბოლო წერტილებს იყენებს თქვენი სისტემა გვირაბის გარეთ.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'გვირაბისთვის გამოიყენეთ დაშიფრული DNS (DoT ან DoH), რათა რეზოლვერებმა პასუხები ვერ გააყალბონ.';

  @override
  String get dnsCheckNeedsConnection => 'ჯერ დაუკავშირდით VPN-ს, შემდეგ შეამოწმეთ გაჟონვა.';

  @override
  String get dnsExpected => 'მოსალოდნელია';

  @override
  String get dnsActual => 'დაფიქსირდა';

  @override
  String get sortBy => 'დალაგება';

  @override
  String get sortSubscription => 'გამოწერის თანმიმდევრობით';

  @override
  String get sortPing => 'პინგი';

  @override
  String get sortSpeed => 'სიჩქარე';

  @override
  String get sortName => 'სახელი';

  @override
  String get measureSpeed => 'გაზომეთ სიჩქარე';

  @override
  String get benchmarkStale => 'მოძველებულია';

  @override
  String get autoSelectMode => 'ავტომატური არჩევის სერვერი';

  @override
  String get autoSelectPing => 'ყველაზე სწრაფი პინგი';

  @override
  String get autoSelectSpeed => 'ყველაზე სწრაფი სიჩქარე';

  @override
  String get autoSelectSmart => 'ჭკვიანი არჩევანი';

  @override
  String get coreWatchUnstable => 'Sora ბირთვთან კავშირი არასტაბილურია';

  @override
  String get watchReconnect => 'ხელახლა დაკავშირება';

  @override
  String get coreRestoringLink => 'მიმდინარეობს კავშირის აღდგენა Sora ბირთვთან…';

  @override
  String get crashRestoreTitle => 'ბოლო სხდომა შეწყდა';

  @override
  String get restoreOnCrash => 'სესიის აღდგენა ავარიის შემდეგ';

  @override
  String get crashRestore => 'აღდგენა';

  @override
  String get crashDismiss => 'ახლა არა';

  @override
  String get overrideTitle => 'ჩემი რედაქტირებები';

  @override
  String get overrideEdit => 'სერვერების რედაქტირება';

  @override
  String get overrideHide => 'დამალვა';

  @override
  String get overrideUnhide => 'ჩვენება';

  @override
  String get overrideClear => 'რედაქტირების გადატვირთვა';

  @override
  String get overrideEmpty => 'ჯერ არ არის შესწორებები';

  @override
  String get overrideCustomRules => 'საკუთარი წესები';

  @override
  String get errBenchmarkUnsupported => 'სიჩქარის გაზომვას უფრო ახალი ბირთვი სჭირდება';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$done-ის გაზომვა $total-დან…';
  }

  @override
  String get profiles => 'ქსელის პროფილები';

  @override
  String get profilesEmpty =>
      'ჯერ არ არის პროფილები. შექმენით ერთი, რომ ავტომატურად გამოიყენოს პარამეტრები ცნობილ ქსელებში.';

  @override
  String get profileAdd => 'პროფილის დამატება';

  @override
  String get profileName => 'პროფილის სახელი';

  @override
  String get profileSsids => 'Wi-Fi ქსელები (SSID)';

  @override
  String get profileSsidsHint => 'სახლი, ოფისი გამოყოფილია მძიმეებით';

  @override
  String get profileGateways => 'ქსელის კარიბჭეები';

  @override
  String get profileAsns => 'AS ნომრები';

  @override
  String get profileAutoApply => 'ავტომატურად გამოყენება';

  @override
  String get profileAutoApplyHint => 'თუ გამორთულია, პროფილის გამოყენებამდე დადასტურებას მოგთხოვთ.';

  @override
  String get profileSnapshot => 'დაიმახსოვრე მიმდინარე პარამეტრები';

  @override
  String get profileSnapshotDone => 'მიმდინარე პარამეტრები შენახულია პროფილში';

  @override
  String get profileDelete => 'პროფილის წაშლა';

  @override
  String profileDeleteConfirm(Object name) {
    return 'წაშალოთ პროფილი „$name“?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'გსურთ პროფილის „$name“ გამოყენება?';
  }

  @override
  String get profileApply => 'გამოყენება';

  @override
  String profileApplied(Object name) {
    return 'პროფილი „$name“ გამოყენებულია';
  }

  @override
  String get profileUndo => 'გაუქმება';

  @override
  String get profileActive => 'აქტიური';

  @override
  String networkNow(Object info) {
    return 'ახლა: $info';
  }

  @override
  String get networkUnknown => 'ქსელის ინფორმაცია მიუწვდომელია';

  @override
  String get profileNoTriggers => 'დაამატეთ მინიმუმ ერთი ტრიგერი: SSID, კარიბჭე ან ASN';

  @override
  String get chains => 'პროქსი ჯაჭვები';

  @override
  String get chainsEmpty => 'ჯაჭვები ჯერ არ არის. დააკავშირეთ 2–3 სერვერი, რათა ტრეფიკი გადაიტანოს თითოეულ მათგანში.';

  @override
  String get chainAdd => 'ახალი ჯაჭვი';

  @override
  String get chainName => 'ჯაჭვის სახელწოდება';

  @override
  String get chainPickServers => 'აირჩიეთ 2–3 სერვერი';

  @override
  String get chainOrderHint => 'გადაათრიეთ ხელახლა შეკვეთისთვის: ტრაფიკი შედის ზევით და გამოდის ქვემოდან.';

  @override
  String get chainTooFew => 'აირჩიეთ მინიმუმ 2 სერვერი';

  @override
  String get chainTooMany => 'ჯაჭვი ინახავს მაქსიმუმ 3 სერვერს';

  @override
  String get chainEstimate => 'სავარაუდო შეყოვნება';

  @override
  String get chainSave => 'ჯაჭვის შენახვა';

  @override
  String get chainDelete => 'ჯაჭვის წაშლა';

  @override
  String chainDeleteConfirm(Object name) {
    return 'წაშალოთ ჯაჭვი \"$name\"?';
  }

  @override
  String get chainUnsupported => 'მიმდინარე ძრავას არ შეუძლია ჯაჭვების აშენება';

  @override
  String get chainHopMissing => 'ერთ-ერთი ჯაჭვის სერვერი აღარ არის ხელმისაწვდომი';

  @override
  String chainHop(Object n) {
    return 'გადასვლა $n';
  }

  @override
  String get chainEntry => 'შესასვლელი';

  @override
  String get chainExit => 'გასასვლელი';

  @override
  String get sync => 'მოწყობილობის სინქრონიზაცია';

  @override
  String get syncDevices => 'ჩემი მოწყობილობები';

  @override
  String get syncEmpty => 'არ არის დაწყვილებული მოწყობილობები. სხვა მოწყობილობის დაწყვილება ლოკალურ ქსელში.';

  @override
  String get syncPair => 'მოწყობილობის დაწყვილება';

  @override
  String get syncShowCode => 'აჩვენე ჩემი კოდი';

  @override
  String get syncScanCode => 'კოდის სკანირება';

  @override
  String get syncRevoke => 'გატანა';

  @override
  String syncRevokeConfirm(Object name) {
    return 'გააუქმოს \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'ბოლო სინქრონიზაცია: $time';
  }

  @override
  String get syncNever => 'არასოდეს';

  @override
  String get syncNoLan => 'მოწყობილობები უნდა იყოს იმავე ლოკალურ ქსელში';

  @override
  String get syncPaired => 'მოწყობილობა დაწყვილებულია';

  @override
  String get syncPairingTitle => 'დაწყვილება ამ მოწყობილობასთან';

  @override
  String get syncWaiting => 'ელოდება სხვა მოწყობილობას…';

  @override
  String get syncSecureNote => 'ბოლოდან ბოლომდე დაშიფრული არხი. არც ანგარიშები, არც ღრუბლოვანი სერვერები.';

  @override
  String get zapretWithVpn => 'გვერდის ავლით DPI ფილტრაცია პირდაპირი ქსელის ტრაფიკისთვის';

  @override
  String get zapretWithVpnHint =>
      'უშვებს zapret-ს VPN გვირაბთან ერთად: გვირაბის ტრაფიკი გადის VPN-ით, პირდაპირი ტრაფიკი კი ბლოკირების გვერდის ავლის მექანიზმით.';

  @override
  String get chainDuplicate => 'თითოეული სერვერი შეიძლება გამოჩნდეს მხოლოდ ერთხელ';

  @override
  String get edit => 'რედაქტირება';

  @override
  String get remove => 'ამოღება';

  @override
  String get autoSwitchOnDegrade => 'ავტომატური ჩართვა დეგრადაციაზე';

  @override
  String get autoSwitchOnDegradeDetail =>
      'თუ არჩეული სერვერი მნიშვნელოვნად შენელდება ან პასუხს შეწყვეტს, Sora გაზომვის შედეგებით საუკეთესო სერვერზე გადაერთვება, მაგრამ არა უმეტეს ერთხელ ყოველ 10 წუთში.';

  @override
  String get tunStackMixed => 'შერეული';

  @override
  String get tunStackSystem => 'სისტემა';

  @override
  String get customServerAdd => 'მორგებული სერვერის დამატება';

  @override
  String get customServers => 'ჩემი სერვერები';

  @override
  String get customServerName => 'სახელი';

  @override
  String get customServerNameHint => 'მაგალითად: ჩემი VPS';

  @override
  String get customServerNameRequired => 'შეიყვანეთ სახელი';

  @override
  String get customServerAddress => 'მისამართი';

  @override
  String get customServerAddressHint => 'example.com ან 192.0.2.1';

  @override
  String get customServerAddressRequired => 'შეიყვანეთ სერვერის მისამართი';

  @override
  String get customServerAddressInvalid => 'არასწორი მისამართი';

  @override
  String get customServerPort => 'პორტი';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'პორტი უნდა იყოს რიცხვი 1-დან 65535-მდე';

  @override
  String get customServerProtocol => 'ოქმი';

  @override
  String get customServerCredentials => 'შესვლის ინფორმაცია';

  @override
  String get customServerOptional => 'სურვილისამებრ';

  @override
  String get customServerShowSecret => 'საიდუმლოს ჩვენება';

  @override
  String get customServerHideSecret => 'საიდუმლოს დამალვა';

  @override
  String get customServerBadge => 'საკუთარი';

  @override
  String customServerDeleteConfirm(String name) {
    return 'წაშალოთ სერვერი „$name“?';
  }

  @override
  String get customServerEmptyHint => 'ხელით დაამატეთ სერვერი: მისამართი, პორტი და პროტოკოლი';

  @override
  String get customServerTest => 'ტესტი';

  @override
  String get leakTestTitle => 'ტესტი მონაცემთა გაჟონვისთვის';

  @override
  String get leakTestIntro =>
      'ამოწმებს, შეუძლია თუ არა ტრაფიკს მოწყობილობიდან გვირაბის გარეთ გასვლა: პირდაპირი DNS და ICMP მოთხოვნები, IPv6 გასასვლელი და სისტემის რეზოლვერები. გაუშვით აქტიური კავშირისას.';

  @override
  String get leakTestRun => 'შეამოწმეთ';

  @override
  String get leakTestCancel => 'გაუქმება';

  @override
  String get leakTestNeedsConnection => 'დაუკავშირდით VPN-ს მონაცემთა გაჟონვის შესამოწმებლად.';

  @override
  String leakTestProgress(int count) {
    return 'დასრულებული ტესტები: $count';
  }

  @override
  String get leakTestAllClear => 'გაჟონვა არ მოიძებნა';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'აღმოჩენილია # გაჟონვა',
      one: 'აღმოჩენილია # გაჟონვა',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'დაფიქსირება';

  @override
  String get leakTestFixedNote => 'ქსელის ბლოკირება ჩართულია. შესამოწმებლად ტესტი ხელახლა გაუშვით.';

  @override
  String get leakTestCheckDirectDns => 'პირდაპირი DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP ექო';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'სისტემის რეზოლვერები';

  @override
  String get leakTestCheckTunnelConnectivity => 'გვირაბის კავშირი';

  @override
  String get leakTestCheckTunnelDns => 'DNS გვირაბით';

  @override
  String get noticeDegraded => 'სერვერი შენელდა. Sora გადაერთო გაზომვის დროს ნაპოვნი საუკეთესო სერვერზე.';

  @override
  String get obfs => 'ტრაფიკის შენიღბვა';

  @override
  String get syncCodeExpired => 'კოდს ვადა გაუვიდა';

  @override
  String get syncDaemonFailed => 'სინქრონიზაციის სერვისის დაწყება ვერ მოხერხდა';

  @override
  String get syncDaemonMissing =>
      'sora-sync კომპონენტი ვერ მოიძებნა. ხელახლა დააინსტალირეთ აპი მოწყობილობის სინქრონიზაციის გასააქტიურებლად.';

  @override
  String get syncDaemonStarting => 'სინქრონიზაციის სერვისის დაწყება…';

  @override
  String get syncErrAuth => 'სინქრონიზაციის სერვისმა უარყო წვდომის ჟეტონი. გადატვირთეთ აპი და სცადეთ ხელახლა.';

  @override
  String get syncErrNotFound => 'მოწყობილობა აღარ არის დაწყვილებული';

  @override
  String get syncErrPairingActive => 'დაწყვილების სესია უკვე ღიაა';

  @override
  String get syncErrUnreachable =>
      'მეორე მოწყობილობამ არ უპასუხა. დარწმუნდით, რომ ის იმავე ქსელშია და აჩვენებს მის კოდს.';

  @override
  String get syncError => 'სინქრონიზაციის შეცდომა';

  @override
  String syncExpiresIn(String duration) {
    return 'კოდის ვადა ამოიწურება $duration-ში';
  }

  @override
  String get syncJoining => 'მოწყობილობასთან დაწყვილება…';

  @override
  String get syncLegacyCleared =>
      'ძველი მოწყობილობების სია ფაქტობრივად არასოდეს ყოფილა დაწყვილებული, ამიტომ ის გასუფთავდა. ხელახლა დააწყვილეთ თქვენი მოწყობილობები, ამჯერად რეალურად.';

  @override
  String get syncNewCode => 'ახალი კოდი';

  @override
  String syncPairedWith(String name) {
    return 'დაწყვილებულია $name-თან';
  }

  @override
  String get syncRetry => 'გაიმეორეთ';

  @override
  String get syncStopShowing => 'კოდის დამალვა';

  @override
  String get syncSyncNow => 'სინქრონიზაცია ახლა';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'მიღებული $pulled, გაგზავნილი $pushed';
  }

  @override
  String get syncResultTitle => 'სინქრონიზაციის შედეგი';

  @override
  String get syncPulled => 'მიღებულია';

  @override
  String get syncPushed => 'გაგზავნილი';

  @override
  String get syncNoChanges => 'ცვლილებები არ გამოვლენილა';

  @override
  String get syncDocKindSubscriptions => 'გამოწერები';

  @override
  String get syncDocKindSettings => 'აპის პარამეტრები';

  @override
  String get syncDocKindOverrides => 'გამოწერების შეცვლილი პარამეტრები';

  @override
  String get syncDocKindProfiles => 'ქსელის პროფილები';

  @override
  String get syncDocKindChains => 'პროქსი ჯაჭვები';

  @override
  String syncFrom(String name) {
    return '$name-დან';
  }

  @override
  String get syncThisDevice => 'ეს მოწყობილობა';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Shadowsocks-ისთვის: მეთოდი:პაროლი, მაგალითად chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => 'პაკეტის დაჭერა';

  @override
  String get diagnosticEvents => 'Windows-ის მოვლენები';

  @override
  String get diagnosticCapture => 'გადაიღეთ 10 წამის განმავლობაში';

  @override
  String get diagnosticRequiresTun => 'პაკეტის დაჭერას სჭირდება აქტიური Sora TUN კავშირი.';

  @override
  String get diagnosticUnavailable => 'ეს დიაგნოსტიკა მიუწვდომელია ამ პლატფორმაზე.';

  @override
  String get extErrRevoked => 'Sora-ს გუნდმა გაფართოების ეს ვერსია გააუქმა, რადგან ის სახიფათო ან გაუმართავია.';

  @override
  String get extErrRevocationsExpired =>
      'გაუქმებული გაფართოებების სია ვერ განახლდა. განახლებამდე ინსტალაცია დაბლოკილია: შეამოწმეთ ქსელი და სცადეთ თავიდან.';

  @override
  String extRevokedDisabled(String names) {
    return 'გაუქმებული გაფართოებები გაითიშა: $names';
  }

  @override
  String get customServerWgPrivateKey => 'პირადი გასაღები';

  @override
  String get customServerWgAddresses => 'ინტერფეისის მისამართები';

  @override
  String get customServerWgPeerKey => 'სერვერის საჯარო გასაღები';

  @override
  String get customServerWgPresharedKey => 'საერთო გასაღები';

  @override
  String get customServerWgAllowedIps => 'დაშვებული IP-ები';

  @override
  String get customServerWgKeepalive => 'Keepalive, წამი';

  @override
  String get customServerWgKeyInvalid => 'გასაღები უნდა იყოს 32 ბაიტი base64-ში, როგორც wg genkey ბეჭდავს.';

  @override
  String get customServerWgCidrInvalid => 'შეიყვანეთ მძიმით გამოყოფილი პრეფიქსები, მაგალითად 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'შეიყვანეთ წამების რაოდენობა 0-დან 65535-მდე.';

  @override
  String get strictKillSwitch => 'ქსელის მკაცრი ბლოკირება';

  @override
  String get strictKillSwitchWarning =>
      'დაკავშირების შემდეგ ბლოკავს VPN-ის გარეთ ტრაფიკს შეფერხების, გადატვირთვის ან აპიდან გასვლის შემდეგაც. წვდომა აღდგება მხოლოდ კავშირის გაწყვეტით ან ამ პარამეტრის გამორთვით. მოწყობილობის გადატვირთვის შემდეგ ბლოკირება განახლდება მხოლოდ გაშვებისას დაკავშირების ჩართვის შემთხვევაში.';

  @override
  String get extWorkerFailed => 'გაფართოების ფონური დავალება ვერ შესრულდა. შეამოწმეთ გაფართოების ჟურნალი.';

  @override
  String get extAssetRejected => 'გაფართოების ფაილი უარყოფილია: წაუკითხავი ფერები ან არასწორი წესები.';
}
