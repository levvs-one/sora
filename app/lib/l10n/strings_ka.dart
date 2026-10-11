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
      'აირჩიეთ ავტო, თუ არ ხართ დარწმუნებული, რომელი ძრავა სჭირდება თქვენს სერვერს. Sora ამოწმებს პროფილს და პარამეტრებს დაკავშირებამდე. ძრავას არ შეუძლია გაზარდოს თქვენი გეგმის გამტარუნარიანობა: შესრულება დამოკიდებულია სერვერზე, მარშრუტზე, პროტოკოლზე და ქსელზე.\n\n## რეჟიმები\n\n### მთელი ტრაფიკი (TUN)\n\nSora ქმნის ვირტუალურ ქსელურ ინტერფეისს და მარშრუტებს აპლიკაციის ტრაფიკს, მათ შორის TCP და UDP. გამოიყენეთ ეს რეჟიმი Telegram, თამაშებისთვის და Discord ხმისთვის. წესებს შეუძლიათ გააგზავნონ კონკრეტული საიტები ან პროგრამები პირდაპირ ან დაბლოკონ ისინი. ქსელის სერვისს სჭირდება ნებართვა და სერვერი, რომელიც მხარს უჭერს საჭირო პროტოკოლს.\n\n### System პროქსი\n\nSora აკონფიგურირებს ადგილობრივ HTTP/SOCKS პროქსის. აპლიკაციები, რომლებიც პატივს სცემენ სისტემის პროქსის პარამეტრებს, იყენებენ მას. აპლიკაციები საკუთარი ქსელის სტეკით შეიძლება პირდაპირ დაუკავშირდნენ; UDP და ხმოვანი ზარები ზოგადად საჭიროებენ TUN. ეს რეჟიმი შეესაბამება ბრაუზერებს და აპლიკაციებს პროქსი მხარდაჭერით.\n\n### სერვერი არ არის\n\nLinux-ზე Sora იყენებს [zapret](https://github.com/bol-van/zapret) HTTP/TLS მოთხოვნების გაყოფისა და ფორმის გადასაჭრელად და ზოგიერთი DPI შემოწმების გვერდის ავლით. თქვენი IP იგივე რჩება და კავშირები პირდაპირ ვებსაიტზე მიდის. შედეგები დამოკიდებულია თქვენს პროვაიდერზე და დაბლოკვის მეთოდზე.\n\nმიმდინარე ინტეგრაცია იყენებს tpws-ს HTTP-სთვის და TLS-ისთვის TCP-ზე. ის არ გვერდს უვლის IP ბლოკირებას ან გადასცემს UDP-ს და ვერ უზრუნველყოფს Telegram-ის MTProto კავშირების გარანტიას. გამოიყენეთ VPN სერვერი TUN-ით Discord ხმის, Telegram ზარებისთვის და ამ სახის შეზღუდვებისთვის.\n\n## ძრავები\n\n### ავტო\n\nSora ირჩევს დაყენებულ ძრავას, რომელიც მხარს უჭერს კავშირის მთელ გეგმას: სერვერის პროტოკოლებს, ტრანსპორტებს, ჯგუფებს, ფრაგმენტაციას და რეჟიმს. შეუთავსებელი ხელით არჩევანი უარყოფილია მიმდინარე კავშირის შეწყვეტამდე. აირჩიეთ Auto ან სხვა ძრავა და კვლავ გამოიყენეთ პარამეტრები.\n\n### sing-box\n\nახალი Sora პაკეტები მოიცავს [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), ჩანგალი [sing-box](https://github.com/SagerNet/sing-box), კლიენტის მხარეს XHTTP და VLESS Encryption დამატება. Sora აღიარებს კონსტრუქციას და მის შესაძლებლობებს. ზემოთ ნაგებობა XHTTP-ის გარეშე არ იძენს ამ შესაძლებლობას მხოლოდ მისი სახელიდან.\n\nმხარდაჭერილია VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard და AmneziaWG 1.x/2.x-ის ის პარამეტრები, რომელთა იმპორტიც Sora-ს შეუძლია. სრულ Xray JSON პროფილებს Xray სჭირდება. ახალი AWG 3.x ველების იმპორტი ჯერ შეუძლებელია. sing-box იყენებს პაროლით დაცულ ადგილობრივ მართვის პორტს, რომლის აღმოჩენაც კომპიუტერის სხვა პროგრამებს შეუძლიათ.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) მხარს უჭერს VLESS, REALITY, XHTTP, VLESS Encryption და TLS ფრაგმენტაციას. ის ასევე აწარმოებს სრულ პროვაიდერის Xray პროფილებს მათი მარშრუტიზაციისა და ჯგუფების შენარჩუნებით. ასეთი პროფილები არ შეიძლება ავტომატურად გადაიზარდოს სხვა ძრავზე მათი ქცევის შეცვლის გარეშე.\n\nშეფუთულმა Xray-მ წაშალა პარამეტრი, რომელიც გამორთავს TLS სერტიფიკატის დადასტურებას (`allowInsecure`). ავტომატურად ირჩევს sing-box ან mihomo ჩვეულებრივი სერვერებისთვის, რომლებიც საჭიროებენ ამ პარამეტრს. Xray-ის არჩევა ხელით აცნობებს შეუთავსებლობას მიმდინარე კავშირის შეწყვეტამდე. ძველ სრულ JSON პროფილებს სჭირდებათ განახლებული პროვაიდერის პროფილი დამოწმებადი სერტიფიკატით ან სერტიფიკატის პინით.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) მხარს უჭერს შეკვეთილ სარეზერვო და დატვირთვის დაბალანსების ჯგუფებს, XHTTP და AmneziaWG. აირჩიეთ ის, როდესაც მნიშვნელოვანია სარეზერვო სერვერზე ავტომატური ჩავარდნა. Sora-ის TLS ფრაგმენტაციის პარამეტრი მიუწვდომელია ამ ძრავით.\n\n## თავსებადობა Sora-ში\n\n| თვისება | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN და TCP/UDP | დიახ | დიახ | დიახ |\n| XHTTP | დიახ | დიახ | დიახ |\n| VLESS Encryption | დიახ | დიახ | დიახ |\n| სრული Xray პროფილი | არა | დიახ | არა |\n| TUIC / AnyTLS | ორივე | არა | TUIC |\n| TLS ფრაგმენტაცია | დიახ | დიახ | არა |\n| AmneziaWG 1.x/2.x | დიახ¹ | არა | დიახ |\n| შეკვეთილი სარეზერვო ჯგუფი | არა | No² | დიახ |\n\n¹ პროფილები J1/J2/J3/Itime იყენებენ mihomo; ეს ველები არასოდეს არ უნდა იყოს ჩუმად გაუქმებული. ² სრული Xray პროფილების ჯგუფისთვის აპლიკაცია ირჩევს სარეზერვო პროფილს. მხარდაჭერა დამოკიდებულია დაყენებულ კონსტრუქციაზე; შეამოწმეთ მისი ვერსია შესახებ.\n\n## TUN დასტა\n\nსტეკი ამუშავებს TCP და UDP-ს ვირტუალურ ინტერფეისში. რეჟიმების პანელში Xray და mihomo გვთავაზობენ gVisor, System, Mixed და MIPS. თითოეული ძრავა ინახავს საკუთარ უპირატესობას. System პროქსი და სერვერის რეჟიმი არ იყენებს ამ პარამეტრს.\n\n- **Mixed** — TCP იყენებს სისტემის დასტას, ხოლო gVisor ამუშავებს UDP-ს. ეს არის ნაგულისხმევი mihomo.\n- **System** — იყენებს სისტემის დასტას. სცადეთ სხვა ვარიანტი, თუ ქსელის აპლიკაციებს პრობლემები შეექმნათ.\n- **gVisor** — მართავს ტრაფიკს მომხმარებლის სივრცეში.\n- **MIPS** — mihomo-ის საკუთარი IP დასტა, ხელმისაწვდომია შეფუთულ ვერსიაში 1.19.32.\n\nLinux-ზე, Xray ნაგულისხმევად იყენებს ჩაშენებულ gVisor-ს. System, Mixed და MIPS Linux-ზე იყენებენ mihomo, როგორც TUN ძრავას, გადაგზავნის TCP და UDP-ს Xray ავთენტიფიცირებულ ლოკალურ SOCKS ბმულზე. Xray ინარჩუნებს პროტოკოლს, პროვაიდერის პროფილს და მარშრუტიზაციას. ამ სამ ვარიანტს სჭირდება დაინსტალირებული mihomo. Windows-ზე Xray ოთხივე TUN სტეკისთვის იყენებს mihomo 1.19.32-ს ან უფრო ახალ ვერსიას. პროტოკოლები და მარშრუტიზაცია რჩება Xray-ში. ამ კომბინაციაში აპლიკაციების წესები მხარს უჭერს მხოლოდ პირდაპირ კავშირს და დაბლოკვას; Linux-ზე ამ წესებს სჭირდება Xray-ის ჩაშენებული gVisor.\n\nხიდი გადის მეორე პროცესს. სამი უმოქმედო გაზომვისას Linux-ზე, მან გამოიყენა დაახლოებით 32–36 MiB მეტი ფიზიკური მეხსიერება, ვიდრე მშობლიურ Xray TUN. ეს არ ზომავს ჩამოტვირთვის დატვირთვას: CPU და მეხსიერების ხარჯები დამოკიდებულია კავშირებზე. შეინახეთ gVisor, თუ სხვა დასტა არ დაგჭირდებათ. sing-box-ს არ აქვს სტეკის ამომრჩევი. არცერთი დასტა არ იძლევა გარანტიას უკეთესი მუშაობის ყველა ქსელში. აირჩიეთ დასტა და აირჩიეთ მიმართვა და ხელახლა დაკავშირება თქვენს ქსელში საცდელად.\n\n## პარამეტრების გამოყენება\n\nსერვერის არჩევა ხელახლა დაკავშირდება ავტომატურად. რეჟიმი, ძრავა, DNS და წესების პარამეტრები დაუყოვნებლივ ინახება; აქტიური კავშირის დროს დააწკაპუნეთ Apply-ზე და ხელახლა დაუკავშირდით მათ გამოსაყენებლად. ძრავის გადატვირთვამ შეიძლება შეაფერხოს ჩამოტვირთვები და ზარები. განმეორებითი დაწკაპუნება არ იწყებს პარალელურ კავშირებს; გათიშვა წყვეტს გადასვლას და ათავისუფლებს კავშირს.\n\nინტერნეტი მხოლოდ VPN-ის საშუალებით ბლოკავს პირდაპირ ტრაფიკს, როდესაც გვირაბი ჩამოვარდება. ეს გავლენას ახდენს მთელ მანქანაზე. აშკარა გათიშვა შლის Sora-ის წესებს. თუ გასუფთავება არ დასრულებულა, ხელახლა სცადეთ გათიშვა და გახსენით ჟურნალი.\n\n## პროექტის დოკუმენტაცია\n\n- [sing-box-lx: კონფიგურაცია და მხარდაჭერა] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box დოკუმენტაცია] (https://sing-box.sagernet.org/)\n- [Xray დოკუმენტაცია] (https://xtls.github.io/)\n- [mihomo დოკუმენტაცია] (https://wiki.metacubex.one/)\n- [zapret: ოპერაცია და შეზღუდვები] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'შეამოწმეთ სერვერები';

  @override
  String get extensions => 'გაფართოებები';

  @override
  String get extensionsSoon => 'მალე მოვა';

  @override
  String exportLogFile(String name) {
    return 'ფაილში $name';
  }

  @override
  String get diagnosticHttp => 'HTTP დიაგნოსტიკა';

  @override
  String get diagnosticPackets => 'პაკეტის დაჭერა';

  @override
  String get diagnosticEvents => 'Windows-ის მოვლენები';

  @override
  String get diagnosticCapture => 'გადაიღეთ 10 წამის განმავლობაში';

  @override
  String get diagnosticNoData => 'ჯერ არ არის ჩაწერილი მოთხოვნა. ჯერ გახსენით სიჩქარის ტესტის ვებსაიტი.';

  @override
  String get diagnosticRequiresTun => 'პაკეტის დაჭერას სჭირდება აქტიური Sora TUN კავშირი.';

  @override
  String get diagnosticUnavailable => 'ეს დიაგნოსტიკა მიუწვდომელია ამ პლატფორმაზე.';
}
