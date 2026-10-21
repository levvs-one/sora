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
  String get stateFailed => 'არ არის დაკავშირებული';

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
  String get connEmpty => 'No connections';

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
  String get exportText => 'ტექსტი';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'სინათლე';

  @override
  String get themeDark => 'ბნელი';

  @override
  String get language => 'ენა';

  @override
  String get languageSystem => 'System';

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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'თავის მხრივ, # სერვერები',
      one: 'თავის მხრივ, # სერვერი',
    );
    return '$_temp0';
  }

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
  String get tunnelTun => 'მთელი მოძრაობა';

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
  String get currentServer => 'მიმდინარე სერვერი';

  @override
  String get trafficDown => 'ჩამოტვირთულია';

  @override
  String get trafficUp => 'ატვირთულია';

  @override
  String perSecond(String value) {
    return '$value/წმ';
  }

  @override
  String activeRules(int count) {
    return 'აქტიური წესები: $count';
  }

  @override
  String get recentNotifications => 'ბოლო შეტყობინებები';

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
  String get programsFailed => 'აპლიკაციების ჩატვირთვა ვერ მოხერხდა';

  @override
  String get programsEmpty => 'აპლიკაციები ვერ მოიძებნა. სცადეთ სხვა სახელი.';

  @override
  String get selectExe => 'აირჩიეთ .exe ფაილი';

  @override
  String get trafficUnavailable => 'მრიცხველები ჯერ არ არის ხელმისაწვდომი';

  @override
  String get speedtest => 'სიჩქარე';

  @override
  String get speedtestCheck => 'შეამოწმეთ სიჩქარე';

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
      'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';

  @override
  String get updateManualSigWarning =>
      'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

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
  String get appCopyright => '© 2026 levvs-one და კონტრიბუტორები';

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
  String get bypassLimitations =>
      'ეს რეჟიმი გვერდს უვლის DPI-ს მხოლოდ HTTP-სთვის და TLS-ისთვის, არ უჭერს მხარს UDP-ს და არ ცვლის თქვენს IP-ს. გამოიყენეთ VPN სერვერი Discord ხმისთვის, ზარებისთვის და დაბლოკილი Telegram მისამართებისთვის.';

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
      'აირჩიეთ ავტო, თუ არ ხართ დარწმუნებული, რომელი ძრავა სჭირდება თქვენს სერვერს. Sora ამოწმებს პროფილს და პარამეტრებს დაკავშირებამდე. ძრავას არ შეუძლია გაზარდოს თქვენი გეგმის გამტარუნარიანობა: შესრულება დამოკიდებულია სერვერზე, მარშრუტზე, პროტოკოლზე და ქსელზე.\n\n## რეჟიმები\n\n### მთელი ტრაფიკი (TUN)\n\nSora ქმნის ვირტუალურ ქსელურ ინტერფეისს და მარშრუტებს აპლიკაციის ტრაფიკს, მათ შორის TCP და UDP. გამოიყენეთ ეს რეჟიმი Telegram, თამაშებისთვის და Discord ხმისთვის. წესებს შეუძლიათ გააგზავნონ კონკრეტული საიტები ან პროგრამები პირდაპირ ან დაბლოკონ ისინი. ქსელის სერვისს სჭირდება ნებართვა და სერვერი, რომელიც მხარს უჭერს საჭირო პროტოკოლს.\n\n### System პროქსი\n\nSora აკონფიგურირებს ადგილობრივ HTTP/SOCKS პროქსის. აპლიკაციები, რომლებიც პატივს სცემენ სისტემის პროქსის პარამეტრებს, იყენებენ მას. აპლიკაციები საკუთარი ქსელის სტეკით შეიძლება პირდაპირ დაუკავშირდნენ; UDP და ხმოვანი ზარები ზოგადად საჭიროებენ TUN. ეს რეჟიმი შეესაბამება ბრაუზერებს და აპლიკაციებს პროქსი მხარდაჭერით.\n\n### სერვერი არ არის\n\nLinux-ზე Sora იყენებს [zapret](https://github.com/bol-van/zapret) HTTP/TLS მოთხოვნების გაყოფისა და ფორმის გადასაჭრელად და ზოგიერთი DPI შემოწმების გვერდის ავლით. თქვენი IP იგივე რჩება და კავშირები პირდაპირ ვებსაიტზე მიდის. შედეგები დამოკიდებულია თქვენს პროვაიდერზე და დაბლოკვის მეთოდზე.\n\nმიმდინარე ინტეგრაცია იყენებს tpws-ს HTTP-სთვის და TLS-ისთვის TCP-ზე. ის არ გვერდს უვლის IP ბლოკირებას ან გადასცემს UDP-ს და ვერ უზრუნველყოფს Telegram-ის MTProto კავშირების გარანტიას. გამოიყენეთ VPN სერვერი TUN-ით Discord ხმის, Telegram ზარებისთვის და ამ სახის შეზღუდვებისთვის.\n\n## ძრავები\n\n### ავტო\n\nSora ირჩევს დაყენებულ ძრავას, რომელიც მხარს უჭერს კავშირის მთელ გეგმას: სერვერის პროტოკოლებს, ტრანსპორტებს, ჯგუფებს, ფრაგმენტაციას და რეჟიმს. შეუთავსებელი ხელით არჩევანი უარყოფილია მიმდინარე კავშირის შეწყვეტამდე. აირჩიეთ Auto ან სხვა ძრავა და კვლავ გამოიყენეთ პარამეტრები.\n\n### sing-box\n\nახალი Sora პაკეტები მოიცავს [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), ჩანგალი [sing-box](https://github.com/SagerNet/sing-box), კლიენტის მხარეს XHTTP და VLESS Encryption დამატება. Sora აღიარებს კონსტრუქციას და მის შესაძლებლობებს. ზემოთ ნაგებობა XHTTP-ის გარეშე არ იძენს ამ შესაძლებლობას მხოლოდ მისი სახელიდან.\n\nმხარდაჭერილია VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard და AmneziaWG 1.x/2.x-ის ის პარამეტრები, რომელთა იმპორტიც Sora-ს შეუძლია. სრულ Xray JSON პროფილებს Xray სჭირდება. ახალი AWG 3.x ველების იმპორტი ჯერ შეუძლებელია. sing-box იყენებს პაროლით დაცულ ადგილობრივ მართვის პორტს, რომლის აღმოჩენაც კომპიუტერის სხვა პროგრამებს შეუძლიათ.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) მხარს უჭერს VLESS, REALITY, XHTTP, VLESS Encryption და TLS ფრაგმენტაციას. ის ასევე აწარმოებს სრულ პროვაიდერის Xray პროფილებს მათი მარშრუტიზაციისა და ჯგუფების შენარჩუნებით. ასეთი პროფილები არ შეიძლება ავტომატურად გადაიზარდოს სხვა ძრავზე მათი ქცევის შეცვლის გარეშე.\n\nშეფუთულმა Xray-მ წაშალა პარამეტრი, რომელიც გამორთავს TLS სერტიფიკატის დადასტურებას (`allowInsecure`). ავტომატურად ირჩევს sing-box ან mihomo ჩვეულებრივი სერვერებისთვის, რომლებიც საჭიროებენ ამ პარამეტრს. Xray-ის არჩევა ხელით აცნობებს შეუთავსებლობას მიმდინარე კავშირის შეწყვეტამდე. ძველ სრულ JSON პროფილებს სჭირდებათ განახლებული პროვაიდერის პროფილი დამოწმებადი სერტიფიკატით ან სერტიფიკატის პინით.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) მხარს უჭერს შეკვეთილ სარეზერვო და დატვირთვის დაბალანსების ჯგუფებს, XHTTP და AmneziaWG. აირჩიეთ ის, როდესაც მნიშვნელოვანია სარეზერვო სერვერზე ავტომატური ჩავარდნა. Sora-ის TLS ფრაგმენტაციის პარამეტრი მიუწვდომელია ამ ძრავით.\n\n## თავსებადობა Sora-ში\n\n| თვისება | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN და TCP/UDP | დიახ | დიახ | დიახ |\n| XHTTP | დიახ | დიახ | დიახ |\n| VLESS Encryption | დიახ | დიახ | დიახ |\n| სრული Xray პროფილი | არა | დიახ | არა |\n| TUIC / AnyTLS | ორივე | არა | TUIC |\n| TLS ფრაგმენტაცია | დიახ | დიახ | არა |\n| AmneziaWG 1.x/2.x | დიახ¹ | არა | დიახ |\n| შეკვეთილი სარეზერვო ჯგუფი | არა | No² | დიახ |\n\n¹ პროფილები J1/J2/J3/Itime იყენებენ mihomo; ეს ველები არასოდეს არ უნდა იყოს ჩუმად გაუქმებული. ² სრული Xray პროფილების ჯგუფისთვის აპლიკაცია ირჩევს სარეზერვო პროფილს. მხარდაჭერა დამოკიდებულია დაყენებულ კონსტრუქციაზე; შეამოწმეთ მისი ვერსია შესახებ.\n\n## TUN დასტა\n\nსტეკი ამუშავებს TCP და UDP-ს ვირტუალურ ინტერფეისში. რეჟიმების პანელში Xray და mihomo გვთავაზობენ gVisor, System, Mixed და MIPS. თითოეული ძრავა ინახავს საკუთარ უპირატესობას. System პროქსი და სერვერის რეჟიმი არ იყენებს ამ პარამეტრს.\n\n- **Mixed** — TCP იყენებს სისტემის დასტას, ხოლო gVisor ამუშავებს UDP-ს. ეს არის mihomo-ს ნაგულისხმევი ვარიანტი Linux-ზე. Windows-ზე Xray და mihomo ნაგულისხმევად MIPS-ს იყენებენ.\n- **System** — იყენებს სისტემის დასტას. სცადეთ სხვა ვარიანტი, თუ ქსელის აპლიკაციებს პრობლემები შეექმნათ.\n- **gVisor** — მართავს ტრაფიკს მომხმარებლის სივრცეში.\n- **MIPS** — mihomo-ის საკუთარი IP დასტა, ხელმისაწვდომია შეფუთულ ვერსიაში 1.19.32.\n\nLinux-ზე, Xray ნაგულისხმევად იყენებს ჩაშენებულ gVisor-ს. System, Mixed და MIPS Linux-ზე იყენებენ mihomo, როგორც TUN ძრავას, გადაგზავნის TCP და UDP-ს Xray ავთენტიფიცირებულ ლოკალურ SOCKS ბმულზე. Xray ინარჩუნებს პროტოკოლს, პროვაიდერის პროფილს და მარშრუტიზაციას. ამ სამ ვარიანტს სჭირდება დაინსტალირებული mihomo. Windows-ზე Xray ოთხივე TUN სტეკისთვის იყენებს mihomo 1.19.32-ს ან უფრო ახალ ვერსიას. პროტოკოლები და მარშრუტიზაცია რჩება Xray-ში. ამ კომბინაციაში აპლიკაციების წესები მხარს უჭერს მხოლოდ პირდაპირ კავშირს და დაბლოკვას; Linux-ზე ამ წესებს სჭირდება Xray-ის ჩაშენებული gVisor.\n\nხიდი გადის მეორე პროცესს. სამი უმოქმედო გაზომვისას Linux-ზე, მან გამოიყენა დაახლოებით 32–36 MiB მეტი ფიზიკური მეხსიერება, ვიდრე მშობლიურ Xray TUN. ეს არ ზომავს ჩამოტვირთვის დატვირთვას: CPU და მეხსიერების ხარჯები დამოკიდებულია კავშირებზე. sing-box-ს არ აქვს სტეკის ამომრჩევი. არცერთი დასტა არ იძლევა გარანტიას უკეთესი მუშაობის ყველა ქსელში. აირჩიეთ დასტა და აირჩიეთ მიმართვა და ხელახლა დაკავშირება თქვენს ქსელში საცდელად.\n\n## პარამეტრების გამოყენება\n\nსერვერის არჩევა ხელახლა დაკავშირდება ავტომატურად. რეჟიმი, ძრავა, DNS და წესების პარამეტრები დაუყოვნებლივ ინახება; აქტიური კავშირის დროს დააწკაპუნეთ Apply-ზე და ხელახლა დაუკავშირდით მათ გამოსაყენებლად. ძრავის გადატვირთვამ შეიძლება შეაფერხოს ჩამოტვირთვები და ზარები. განმეორებითი დაწკაპუნება არ იწყებს პარალელურ კავშირებს; გათიშვა წყვეტს გადასვლას და ათავისუფლებს კავშირს.\n\nინტერნეტი მხოლოდ VPN-ის საშუალებით ბლოკავს პირდაპირ ტრაფიკს, როდესაც გვირაბი ჩამოვარდება. ეს გავლენას ახდენს მთელ მანქანაზე. აშკარა გათიშვა შლის Sora-ის წესებს. თუ გასუფთავება არ დასრულებულა, ხელახლა სცადეთ გათიშვა და გახსენით ჟურნალი.\n\n## პროექტის დოკუმენტაცია\n\n- [sing-box-lx: კონფიგურაცია და მხარდაჭერა] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box დოკუმენტაცია] (https://sing-box.sagernet.org/)\n- [Xray დოკუმენტაცია] (https://xtls.github.io/)\n- [mihomo დოკუმენტაცია] (https://wiki.metacubex.one/)\n- [zapret: ოპერაცია და შეზღუდვები] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'შეამოწმეთ სერვერები';

  @override
  String get extensions => 'გაფართოებები';

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
    return 'ფაილში $name';
  }

  @override
  String get diagnosticHttp => 'HTTP დიაგნოსტიკა';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'ჯერ არ არის ჩაწერილი მოთხოვნა. ჯერ გახსენით სიჩქარის ტესტის ვებსაიტი.';

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
  String get qrScanHint => 'აირჩიეთ ეკრანის სურათი ან ფოტო QR კოდით, ან ჩასვით ბმული';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'ამ სურათში QR კოდი ვერ მოიძებნა.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'სურათის გახსნა';

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
  String get strictKillSwitch => 'ქსელის მკაცრი ბლოკირება';

  @override
  String get strictKillSwitchWarning =>
      'დაკავშირების შემდეგ ბლოკავს VPN-ის გარეთ ტრაფიკს შეფერხების, გადატვირთვის ან აპიდან გასვლის შემდეგაც. წვდომა აღდგება მხოლოდ კავშირის გაწყვეტით ან ამ პარამეტრის გამორთვით. მოწყობილობის გადატვირთვის შემდეგ ბლოკირება განახლდება მხოლოდ გაშვებისას დაკავშირების ჩართვის შემთხვევაში.';
}
