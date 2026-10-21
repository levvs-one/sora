// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class SBn extends S {
  SBn([String locale = 'bn']) : super(locale);

  @override
  String get stateOff => 'সংযুক্ত নয়';

  @override
  String get stateConnecting => 'সংযোগ করা হচ্ছে';

  @override
  String get stateConnected => 'সংযুক্ত';

  @override
  String get stateReconnecting => 'পুনরায় সংযোগ করা হচ্ছে';

  @override
  String get stateDisconnecting => 'সংযোগ বিচ্ছিন্ন করা হচ্ছে';

  @override
  String get stateFailed => 'সংযুক্ত নয়';

  @override
  String get coreMissing => 'Sora পরিষেবা সাড়া দিচ্ছে না৷';

  @override
  String get serverAuto => 'দ্রুততম';

  @override
  String get serverBypass => 'সার্ভার নেই';

  @override
  String get addSubscription => 'সদস্যতা যোগ করুন';

  @override
  String get servers => 'সার্ভার';

  @override
  String get settings => 'সেটিংস';

  @override
  String get subscription => 'সাবস্ক্রিপশন';

  @override
  String get subscriptionLink => 'সাবস্ক্রিপশন লিঙ্ক';

  @override
  String get add => 'যোগ করুন';

  @override
  String get refresh => 'আপডেট';

  @override
  String get rename => 'নাম পরিবর্তন করুন';

  @override
  String get delete => 'মুছে দিন';

  @override
  String get cancel => 'বাতিল করুন';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get name => 'নাম';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" মুছবেন?';
  }

  @override
  String get routes => 'রুট';

  @override
  String get presetGlobal => 'VPN এর মাধ্যমে সবকিছু';

  @override
  String get presetRu => 'সরাসরি রাশিয়া';

  @override
  String get presetIr => 'সরাসরি ইরান';

  @override
  String get presetCn => 'চীন সরাসরি';

  @override
  String get blockAds => 'বিজ্ঞাপন ব্লক করুন';

  @override
  String get killSwitch => 'শুধুমাত্র VPN এর মাধ্যমে ইন্টারনেট';

  @override
  String get engine => 'ইঞ্জিন';

  @override
  String get engineAuto => 'অটো';

  @override
  String get animations => 'অ্যানিমেশন';

  @override
  String get logs => 'লগ';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get logsAll => 'সব';

  @override
  String get logsImportant => 'গুরুত্বপূর্ণ';

  @override
  String get logsErrors => 'ত্রুটি';

  @override
  String get search => 'অনুসন্ধান করুন';

  @override
  String get export => 'ফাইলে সংরক্ষণ করুন';

  @override
  String get clear => 'পরিষ্কার';

  @override
  String get logsEmpty => 'এখানে কিছুই নেই';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get notInstalled => 'ইনস্টল করা হয়নি';

  @override
  String get sourceCode => 'সোর্স কোড';

  @override
  String get license => 'লাইসেন্স';

  @override
  String usage(String used, String total) {
    return '$total এর $used';
  }

  @override
  String until(String date) {
    return '$date পর্যন্ত';
  }

  @override
  String get expired => 'মেয়াদ শেষ';

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
    return '$n বি';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n জিবি';
  }

  @override
  String bytesTB(String n) {
    return '$n টিবি';
  }

  @override
  String get errGeneric => 'কিছু ভুল হয়েছে';

  @override
  String get errCore => 'Sora পরিষেবা সাড়া দিচ্ছে না৷';

  @override
  String get errAuth => 'Sora পরিষেবাতে কোনও অ্যাক্সেস নেই৷';

  @override
  String get errVersion => 'Sora আপডেট করুন: অ্যাপ এবং পরিষেবাটি ভিন্ন সংস্করণ';

  @override
  String get errBusy => 'অপেক্ষা করুন, আগের কমান্ডটি এখনও চলছে';

  @override
  String get errEngineMissing => 'এই সার্ভারের জন্য কোনো ইঞ্জিন পাওয়া যায়নি';

  @override
  String get errOlcrtcInvalid =>
      'এই olcRTC সার্ভারটি অসম্পূর্ণ: প্রদানকারী, ট্রান্সপোর্ট, রুম এবং এনক্রিপশন কী যাচাই করুন';

  @override
  String get errOlcrtcCombination => 'এই olcRTC প্রদানকারী ও ট্রান্সপোর্ট একসাথে কাজ করে না';

  @override
  String get errOlcrtcTokenRequired => 'এই olcRTC সার্ভারের একটি প্রদানকারী অ্যাকাউন্ট টোকেন দরকার যা লিঙ্কে নেই';

  @override
  String get errOlcrtcNotConnectable => 'শুধু লিঙ্ক দিয়ে এই olcRTC সার্ভারে সংযোগ করা যায় না';

  @override
  String get errOlcrtcServerMode => 'Sora শুধু olcRTC সার্ভারে সংযোগ করে, নিজে সার্ভার চালায় না';

  @override
  String get olcrtcTcpOnly => 'শুধু TCP';

  @override
  String get olcrtcIpv4Only => 'শুধু IPv4';

  @override
  String get errEngineStart => 'ইঞ্জিন চালু হয়নি';

  @override
  String get errEngineStopped => 'ইঞ্জিন থেমে গেল';

  @override
  String get errTunnel => 'ভিপিএন সংযোগ তৈরি করার অনুমতি নেই';

  @override
  String get errServers => 'সার্ভারটি একটি ত্রুটির সাথে কনফিগার করা হয়েছে৷';

  @override
  String get errNetwork => 'সার্ভারে পৌঁছানো যাচ্ছে না';

  @override
  String get errTimeout => 'সার্ভার সময়মত উত্তর দেয়নি';

  @override
  String get errFirewall => 'VPN এর বাইরে ইন্টারনেট ব্লক করা যায়নি';

  @override
  String get errSubFetch => 'সদস্যতা লোড করা যায়নি';

  @override
  String get errSubFormat => 'এটি একটি সাবস্ক্রিপশন লিঙ্ক নয়';

  @override
  String get errSubEmpty => 'সাবস্ক্রিপশনের কোনো সার্ভার নেই';

  @override
  String get errSubDuplicate => 'এই সদস্যতা ইতিমধ্যে যোগ করা হয়েছে';

  @override
  String get errSubLimit => 'অনেক বেশি সদস্যতা';

  @override
  String get errSubScheme => 'লিঙ্কটি অবশ্যই https:// দিয়ে শুরু হবে';

  @override
  String get errSecretStore => 'Sora স্টোরেজ ক্ষতিগ্রস্ত বা অনুপলব্ধ';

  @override
  String get errNoServers => 'সংযোগ করতে একটি সদস্যতা যোগ করুন';

  @override
  String get exportText => 'পাঠ্য';

  @override
  String get connections => 'সংযোগ';

  @override
  String get close => 'বন্ধ';

  @override
  String get chainDirect => 'সরাসরি';

  @override
  String get chainBlocked => 'অবরুদ্ধ';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'আলো';

  @override
  String get themeDark => 'অন্ধকার';

  @override
  String get language => 'ভাষা';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'সংযোগ';

  @override
  String get sectionNoServer => 'সার্ভার নেই';

  @override
  String get sectionPing => 'পিং';

  @override
  String get sectionLog => 'ডায়াগনস্টিকস';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'ডিএনএস';

  @override
  String get dnsAuto => 'অটো';

  @override
  String get dnsHint => 'ঠিকানা, কমা পৃথক';

  @override
  String get fragment => 'TLS ফ্র্যাগমেন্টেশন';

  @override
  String get fragmentPackets => 'কি বিভক্ত করা';

  @override
  String get fragmentLength => 'টুকরা আকার';

  @override
  String get fragmentInterval => 'টুকরা মধ্যে বিরতি';

  @override
  String get byDefault => 'ডিফল্ট';

  @override
  String get rangeHint => 'উদাহরণস্বরূপ, 100-200';

  @override
  String get splitPos => 'বিভক্ত অবস্থান';

  @override
  String get splitPosHint => 'উদাহরণস্বরূপ, 1, midsld';

  @override
  String get disorder => 'টুকরা পুনর্বিন্যাস';

  @override
  String get tlsRecord => 'TLS রেকর্ড বিভক্ত করুন';

  @override
  String get tlsRecordNo => 'না';

  @override
  String get tlsRecordSni => 'সাইটের নামে';

  @override
  String get tlsRecordFirst => 'প্রথম বাইট পরে';

  @override
  String get hostCase => 'হোস্ট কেস পরিবর্তন করুন';

  @override
  String get probeMethod => 'পদ্ধতি';

  @override
  String get probeAuto => 'অটো';

  @override
  String get probeEngine => 'ইঞ্জিনের মাধ্যমে';

  @override
  String get probeConnect => 'শুধুমাত্র সংযোগ';

  @override
  String get probeUrl => 'পরীক্ষার ঠিকানা';

  @override
  String get probeTimeout => 'অপেক্ষা করুন';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'সদস্যতা';

  @override
  String get subscriptionSettings => 'সেটিংস';

  @override
  String get userAgent => 'ব্যবহারকারী-এজেন্ট';

  @override
  String get autoUpdate => 'স্বয়ংক্রিয়ভাবে আপডেট করুন';

  @override
  String get updateInterval => 'কত ঘন ঘন';

  @override
  String get intervalProvider => 'প্রদানকারী জিজ্ঞাসা হিসাবে';

  @override
  String hours(int n) {
    return '$n জ';
  }

  @override
  String get updateNow => 'এখনই আপডেট করুন';

  @override
  String get logLevel => 'কি রেকর্ড করতে হবে';

  @override
  String get levelDebug => 'সবকিছু';

  @override
  String get levelInfo => 'স্বাভাবিক';

  @override
  String get levelWarning => 'গুরুত্বপূর্ণ';

  @override
  String get levelError => 'শুধুমাত্র ত্রুটি';

  @override
  String get recordDestinations => 'সাইটের ঠিকানা রেকর্ড করুন';

  @override
  String get reset => 'সেটিংস রিসেট করুন';

  @override
  String get resetConfirm => 'সব সেটিংস রিসেট করবেন?';

  @override
  String get resetAction => 'রিসেট করুন';

  @override
  String get invalidValue => 'এই মান কাজ করবে না';

  @override
  String get website => 'সদস্যতা পৃষ্ঠা';

  @override
  String get providerWebsite => 'প্রদানকারী ওয়েবসাইট';

  @override
  String get support => 'সমর্থন';

  @override
  String controlPortQuestion(String engine) {
    return '$engine এই কম্পিউটারে একটি পোর্টের মাধ্যমে নিয়ন্ত্রিত হয়। অন্যান্য প্রোগ্রাম বলতে সক্ষম হবে যে একটি VPN চালু আছে।';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine বেছে নিন';
  }

  @override
  String get rules => 'কাস্টম নিয়ম';

  @override
  String get ruleAdd => 'নতুন নিয়ম';

  @override
  String get ruleHint => 'সাইট, আইপি বা প্রোগ্রাম';

  @override
  String get ruleDirect => 'সরাসরি';

  @override
  String get ruleProxy => 'ভিপিএন এর মাধ্যমে';

  @override
  String get ruleBlock => 'ব্লক';

  @override
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'ব্যর্থতা চালু করুন';

  @override
  String get connectOnStart => 'শুরুতে সংযোগ করুন';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'সদস্যতা # দিনের মধ্যে শেষ হয়',
      one: 'সদস্যতা # দিনে শেষ হয়',
      zero: 'সাবস্ক্রিপশন কয়েক ঘন্টার মধ্যে শেষ হয়',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left বাকি';
  }

  @override
  String get ruleInvalid => 'এটি একটি সাইট, একটি আইপি বা একটি প্রোগ্রাম মত দেখায় না';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# সার্ভার, ঘুরে', one: '# সার্ভার, ঘুরে');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# সার্ভার, দ্রুততম',
      one: '# সার্ভার, দ্রুততম',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'মোড';

  @override
  String get tunnelTun => 'সমস্ত ট্রাফিক';

  @override
  String get tunnelProxy => 'System প্রক্সি';

  @override
  String get proxyAddress => 'প্রক্সি ঠিকানা';

  @override
  String get copied => 'কপি করা হয়েছে';

  @override
  String get launchAtLogin => 'সিস্টেম দিয়ে শুরু করুন';

  @override
  String get launchAtLoginDetail => 'সাইন ইন করলে Sora স্বয়ংক্রিয়ভাবে চালু হবে এবং ট্রেতে থাকবে।';

  @override
  String get closeToTray => 'বন্ধ হয়ে গেলে ট্রেতে রাখুন';

  @override
  String get notifications => 'বিজ্ঞপ্তি';

  @override
  String get trayOpen => 'Sora খুলুন';

  @override
  String get trayConnect => 'সংযোগ করুন';

  @override
  String get trayDisconnect => 'সংযোগ বিচ্ছিন্ন করুন';

  @override
  String get trayServer => 'সার্ভার';

  @override
  String get trayQuit => 'Sora প্রস্থান করুন';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora এখনও ট্রেতে আছে';

  @override
  String get noticeInTrayBody => 'এর আইকনের মেনু থেকে প্রস্থান করুন';

  @override
  String get noticeLost => 'সংযোগ বিচ্ছিন্ন';

  @override
  String get noticeLostBody => 'Sora পুনরায় সংযোগ করা হচ্ছে৷';

  @override
  String get noticeRestored => 'আবার সংযুক্ত';

  @override
  String get noticeFailed => 'সংযোগ করা যায়নি';

  @override
  String get noticeBackup => 'প্রধান সার্ভার উত্তর দেয়নি; ব্যাকআপ ট্রাফিক বহন করে';

  @override
  String get noticeNext => 'সার্ভার উত্তর দেয়নি; পরেরটি ট্রাফিক বহন করে';

  @override
  String get noticeMainBack => 'প্রধান সার্ভার আবার উত্তর দেয় এবং ট্রাফিক বহন করে';

  @override
  String get noticeSubscription => 'সাবস্ক্রিপশন';

  @override
  String get importTitle => 'এই সদস্যতা যোগ করবেন?';

  @override
  String get importSealed =>
      'এই লিঙ্কটি Happ এর জন্য এনক্রিপ্ট করা হয়েছে এবং শুধুমাত্র Happ এটি পড়তে পারে৷ প্লেইন সাবস্ক্রিপশন লিঙ্কের জন্য আপনার প্রদানকারীকে জিজ্ঞাসা করুন।';

  @override
  String get understood => 'ঠিক আছে';

  @override
  String get noAnswer => 'কোন উত্তর নেই';

  @override
  String get home => 'বাড়ি';

  @override
  String get navRules => 'নিয়ম';

  @override
  String get navConnections => 'সংযোগ';

  @override
  String get navLogs => 'লগ';

  @override
  String get navAbout => 'সম্পর্কে';

  @override
  String get sidebarToggle => 'সাইডবার টগল করুন';

  @override
  String get more => 'আরও';

  @override
  String get less => 'কম';

  @override
  String get currentServer => 'বর্তমান সার্ভার';

  @override
  String get trafficDown => 'ডাউনলোড করা হয়েছে';

  @override
  String get trafficUp => 'আপলোড করা হয়েছে';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'সক্রিয় নিয়ম: $count';
  }

  @override
  String get recentNotifications => 'সাম্প্রতিক বিজ্ঞপ্তি';

  @override
  String get notificationsEmpty => 'সংযোগ এবং সদস্যতা ইভেন্ট এখানে প্রদর্শিত হবে';

  @override
  String get retryConnect => 'সংযোগ পুনরায় চেষ্টা করুন';

  @override
  String get openLogs => 'লগ খুলুন';

  @override
  String get tourReplay => 'আবার গাইড দেখান';

  @override
  String tourStep(int step) {
    return '5 এর মধ্যে $step ধাপ';
  }

  @override
  String get tourBack => 'ব্যাক';

  @override
  String get tourNext => 'পরবর্তী';

  @override
  String get tourSkip => 'এড়িয়ে যান';

  @override
  String get tourFinish => 'সম্পন্ন';

  @override
  String get tourAdd => 'আপনার প্রদানকারীর সদস্যতা লিঙ্ক যোগ করুন.';

  @override
  String get tourServer => 'একটি সার্ভার চয়ন করুন। \"দ্রুততম\" আপনার জন্য একটি নির্বাচন করে।';

  @override
  String get tourConnect => 'সংযোগ বা সংযোগ বিচ্ছিন্ন করতে এখানে ক্লিক করুন.';

  @override
  String get tourMode => 'একটি মোড চয়ন করুন. VPN কমে গেলে কিল সুইচ ইন্টারনেট ব্লক করে।';

  @override
  String get tourSettings => 'সেটিংস খুলুন। আপনি সেখানে এই নির্দেশিকা পুনরায় চালাতে পারেন।';

  @override
  String get chooseProgram => 'একটি প্রোগ্রাম চয়ন করুন';

  @override
  String get installedApps => 'ইনস্টল করা অ্যাপ্লিকেশন';

  @override
  String get runningProcesses => 'চলমান প্রক্রিয়া';

  @override
  String get programsFailed => 'অ্যাপ্লিকেশন লোড করা যায়নি';

  @override
  String get programsEmpty => 'কোন অ্যাপ্লিকেশন পাওয়া যায়নি. অন্য নাম চেষ্টা করুন.';

  @override
  String get selectExe => 'একটি .exe ফাইল নির্বাচন করুন';

  @override
  String get trafficUnavailable => 'কাউন্টার এখনও উপলব্ধ নেই';

  @override
  String get speedtest => 'গতি';

  @override
  String get speedtestCheck => 'গতি পরীক্ষা করুন';

  @override
  String get speedtestSearch => 'একটি পরিষেবা খুঁজুন';

  @override
  String get speedtestEmpty => 'কোন মিল নেই। অনুসন্ধান পরিবর্তন করুন.';

  @override
  String get speedtestBackToList => 'পরিষেবাগুলিতে ফিরে যান';

  @override
  String get speedtestOpenBrowser => 'ব্রাউজারে খুলুন';

  @override
  String get speedtestUnavailable => 'এমবেড করা ব্রাউজারটি শুরু করা যায়নি। আপনার সিস্টেম ব্রাউজারে পরিষেবাটি খুলুন।';

  @override
  String get speedtestPageFailed =>
      'পৃষ্ঠাটি লোড করা যায়নি। এটি পুনরায় লোড করুন বা আপনার সিস্টেম ব্রাউজারে পরিষেবাটি খুলুন।';

  @override
  String get speedtestExternalFailed => 'সিস্টেম ব্রাউজার খুলতে পারেনি. আবার চেষ্টা করুন';

  @override
  String get modes => 'মোড';

  @override
  String get proxyShort => 'প্রক্সি';

  @override
  String get tunMode => 'সমস্ত ট্রাফিক (TUN)';

  @override
  String get checkUpdates => 'আপডেটের জন্য চেক করুন';

  @override
  String get updates => 'অ্যাপ আপডেট';

  @override
  String updateAvailable(String version) {
    return '$version সংস্করণ উপলব্ধ';
  }

  @override
  String get updateOpenAbout => 'আপডেট দেখুন';

  @override
  String updateNotes(String version) {
    return '$version এ পরিবর্তন';
  }

  @override
  String get updateCheck => 'আপডেটের জন্য চেক করুন';

  @override
  String get updateChecking => 'পরীক্ষা করা হচ্ছে...';

  @override
  String get updateNoNotes => 'রিলিজ কোন নোট আছে.';

  @override
  String get updateDropWarning =>
      'Sora এবং এর মূল আপডেটের সময় VPN সংযোগটি কয়েক সেকেন্ডের জন্য নেমে যাবে। চালিয়ে যান?';

  @override
  String get updateWaitConnection => 'ভিপিএন সংযোগ এবং কোর প্রস্তুত হওয়ার জন্য অপেক্ষা করুন।';

  @override
  String get updateDownloading => 'ফাইল ডাউনলোড এবং যাচাই করা হচ্ছে...';

  @override
  String get updateInstalling => 'আপডেট প্রস্তুত করা হচ্ছে বা প্রশাসকের প্রমাণীকরণের জন্য অপেক্ষা করা হচ্ছে...';

  @override
  String get updateNetworkError => 'আপডেট ডাউনলোড করা যায়নি. আবার চেষ্টা করুন';

  @override
  String get updateReleaseError => 'রিলিজ ডেটা বা প্রয়োজনীয় ফাইলগুলি অনুপস্থিত বা অবৈধ৷';

  @override
  String get updateChecksumError => 'ডাউনলোডটি SHA256SUMS-এর সাথে মেলে না৷ কিছুই ইনস্টল করা হয়নি।';

  @override
  String get updateInstallError => 'আপডেট শেষ হয়নি। প্রমাণীকরণ বাতিল করা হতে পারে.';

  @override
  String get updateUnsupported =>
      'এই এক্সিকিউটেবল একটি সমর্থিত Sora প্যাকেজ জোড়ার মালিকানাধীন নয়। রিলিজ ইনস্টলেশন নির্দেশাবলী ব্যবহার করুন.';

  @override
  String get updateManual =>
      'উভয় যাচাইকৃত প্যাকেজ ইনস্টল করতে একটি টার্মিনালে এই কমান্ডটি চালান, তারপর Sora পুনরায় খুলুন। ফাইলগুলি ডাউনলোড ডিরেক্টরিতে থাকে। ভিপিএন কানেকশন বন্ধ হয়ে যাবে।';

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
  String get updateCopyCommand => 'কমান্ড অনুলিপি করুন';

  @override
  String get updateChecksDisabled => 'সেটিংসে স্বয়ংক্রিয় চেক অক্ষম করা হয়েছে৷';

  @override
  String get updateInstalled => 'আপডেট ইনস্টল করা হয়েছে। Sora আবার খুলুন।';

  @override
  String get projectLinks => 'প্রকল্প';

  @override
  String get githubReleases => 'রিলিজ এবং ডাউনলোড';

  @override
  String get telegramChannel => 'Telegram চ্যানেল';

  @override
  String get licenses => 'লাইসেন্স';

  @override
  String get componentLicenses => 'কম্পোনেন্ট লাইসেন্স';

  @override
  String get appCopyright => '© 2026 levvs-one এবং অবদানকারী';

  @override
  String get collapseServers => 'সার্ভার সঙ্কুচিত করুন';

  @override
  String get expandServers => 'সার্ভার প্রসারিত করুন';

  @override
  String get hideDescription => 'বর্ণনা লুকান';

  @override
  String get showDescription => 'বর্ণনা দেখান';

  @override
  String get pendingConnectionChanges => 'এই পরিবর্তনগুলি প্রয়োগ করতে পুনরায় সংযোগ করুন৷';

  @override
  String get reconnectNow => 'আবেদন করুন এবং পুনরায় সংযোগ করুন';

  @override
  String get bypassLimitations =>
      'এই মোডটি শুধুমাত্র HTTP এবং TLS-এর জন্য DPI বাইপাস করে, UDP সমর্থন করে না বা আপনার IP পরিবর্তন করে না। Discord ভয়েস, কল এবং ব্লক করা Telegram ঠিকানাগুলির জন্য একটি VPN সার্ভার ব্যবহার করুন৷';

  @override
  String get errEngineUnsupported =>
      'নির্বাচিত ইঞ্জিন এই প্রোফাইল বা সেটিংস সমর্থন করে না। অটো বা একটি সামঞ্জস্যপূর্ণ ইঞ্জিন চয়ন করুন.';

  @override
  String get errRestore =>
      'সংযোগ পরিষ্কার অসম্পূর্ণ ছিল. সংযোগ বিচ্ছিন্ন করার পুনরায় চেষ্টা করুন; বিস্তারিত জানার জন্য লগ দেখুন।';

  @override
  String get errSessionEnded => 'এই অধিবেশন ইতিমধ্যে শেষ হয়েছে. সংযোগের অবস্থা রিফ্রেশ করুন।';

  @override
  String get retryDisconnect => 'সংযোগ বিচ্ছিন্ন করার পুনরায় চেষ্টা করুন';

  @override
  String get tunStack => 'TUN স্ট্যাক';

  @override
  String get modesInfo => 'মোড সম্পর্কে';

  @override
  String get modesGuideTitle => 'মোড এবং ইঞ্জিন';

  @override
  String get modesGuide =>
      'আপনার সার্ভারের কোন ইঞ্জিনের প্রয়োজন তা আপনি নিশ্চিত না হলে অটো বেছে নিন। Sora সংযোগ করার আগে প্রোফাইল এবং সেটিংস পরীক্ষা করে। একটি ইঞ্জিন আপনার পরিকল্পনার ব্যান্ডউইথ বাড়াতে পারে না: কর্মক্ষমতা সার্ভার, রুট, প্রোটোকল এবং নেটওয়ার্কের উপর নির্ভর করে।\n\n## মোড\n\n### সমস্ত ট্রাফিক (TUN)\n\nSora একটি ভার্চুয়াল নেটওয়ার্ক ইন্টারফেস তৈরি করে এবং TCP এবং UDP সহ এর মাধ্যমে অ্যাপ্লিকেশন ট্র্যাফিককে রুট করে। Telegram, গেমস এবং Discord ভয়েসের জন্য এই মোডটি ব্যবহার করুন। নিয়ম নির্দিষ্ট সাইট বা প্রোগ্রাম সরাসরি পাঠাতে বা তাদের ব্লক করতে পারে। নেটওয়ার্ক পরিষেবার অনুমতি প্রয়োজন এবং একটি সার্ভার যা প্রয়োজনীয় প্রোটোকল সমর্থন করে৷\n\n### System প্রক্সি\n\nSora একটি স্থানীয় HTTP/SOCKS প্রক্সি কনফিগার করে। যে অ্যাপ্লিকেশনগুলি সিস্টেম প্রক্সি সেটিংসকে সম্মান করে তারা এটি ব্যবহার করে। তাদের নিজস্ব নেটওয়ার্ক স্ট্যাকের সাথে অ্যাপ্লিকেশন সরাসরি সংযুক্ত হতে পারে; UDP এবং ভয়েস কলের জন্য সাধারণত TUN প্রয়োজন। এই মোডটি প্রক্সি সমর্থন সহ ব্রাউজার এবং অ্যাপ্লিকেশনগুলির জন্য উপযুক্ত৷\n\n### সার্ভার নেই\n\nLinux-এ, Sora HTTP/TLS অনুরোধগুলিকে বিভক্ত ও পুনরায় আকার দিতে এবং কিছু DPI চেক বাইপাস করতে [zapret](https://github.com/bol-van/zapret) ব্যবহার করে। আপনার আইপি একই থাকে এবং সংযোগগুলি সরাসরি ওয়েবসাইটে যায়। ফলাফল আপনার প্রদানকারী এবং ব্লকিং পদ্ধতির উপর নির্ভর করে।\n\nবর্তমান ইন্টিগ্রেশন টিসিপির উপর HTTP এবং TLS এর জন্য tpws ব্যবহার করে। এটি আইপি ব্লকিং বা রিলে ইউডিপি বাইপাস করে না এবং Telegram এর MTProto সংযোগের গ্যারান্টি দিতে পারে না। Discord ভয়েস, Telegram কল এবং এই ধরনের বিধিনিষেধের জন্য TUN সহ একটি VPN সার্ভার ব্যবহার করুন৷\n\n## ইঞ্জিন\n\n### অটো\n\nSora একটি ইনস্টল করা ইঞ্জিন নির্বাচন করে যা সম্পূর্ণ সংযোগ পরিকল্পনা সমর্থন করে: সার্ভার প্রোটোকল, পরিবহন, গ্রুপ, ফ্র্যাগমেন্টেশন এবং মোড। বর্তমান সংযোগ বন্ধ করার আগে একটি বেমানান ম্যানুয়াল পছন্দ প্রত্যাখ্যান করা হয়। অটো বা অন্য ইঞ্জিন নির্বাচন করুন এবং সেটিংস আবার প্রয়োগ করুন।\n\n### sing-box\n\nনতুন Sora প্যাকেজগুলির মধ্যে রয়েছে [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) এর একটি কাঁটা, ক্লায়েন্ট-সাইড XHTTP এবং VLESS Encryption যোগ করা। Sora বিল্ড এবং এর ক্ষমতাকে স্বীকৃতি দেয়। XHTTP ছাড়া একটি আপস্ট্রিম বিল্ড শুধুমাত্র তার নাম থেকে এই ক্ষমতা অর্জন করে না।\n\nসমর্থিত প্রোটোকলগুলির মধ্যে রয়েছে VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard এবং AmneziaWG 1.x/2.x-এর সেই প্যারামিটারগুলি যা Sora আমদানি করতে পারে। সম্পূর্ণ Xray JSON প্রোফাইলের জন্য Xray প্রয়োজন। নতুন AWG 3.x ফিল্ড এখনও আমদানি করা যায় না। sing-box একটি পাসওয়ার্ড-সুরক্ষিত স্থানীয় নিয়ন্ত্রণ পোর্ট ব্যবহার করে, যা কম্পিউটারের অন্য অ্যাপ্লিকেশনগুলি শনাক্ত করতে পারে।\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption এবং TLS ফ্র্যাগমেন্টেশন সমর্থন করে। এটি সম্পূর্ণ প্রদানকারী Xray প্রোফাইলগুলিকে তাদের রাউটিং এবং গোষ্ঠীগুলি সংরক্ষণ করে চালায়। এই ধরনের প্রোফাইলগুলি তাদের আচরণ পরিবর্তন না করে স্বয়ংক্রিয়ভাবে অন্য ইঞ্জিনে রূপান্তরিত হতে পারে না।\n\nবান্ডেল করা Xray সেটিংটি সরিয়ে দিয়েছে যা TLS শংসাপত্র যাচাইকরণ (`allowInsecure`) অক্ষম করে। স্বয়ংক্রিয়ভাবে sing-box বা mihomo সাধারণ সার্ভারগুলির জন্য এই সেটিং প্রয়োজন। Xray নির্বাচন করা বর্তমান সংযোগ বন্ধ করার আগে ম্যানুয়ালি অসামঞ্জস্যতার প্রতিবেদন করে। পুরানো সম্পূর্ণ JSON প্রোফাইলগুলির একটি যাচাইযোগ্য শংসাপত্র বা শংসাপত্র পিন সহ একটি আপডেট প্রদানকারী প্রোফাইল প্রয়োজন৷\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) অর্ডার করা ফলব্যাক এবং লোড-ব্যালেন্সিং গ্রুপ, XHTTP এবং AmneziaWG সমর্থন করে। ব্যাকআপ সার্ভারে স্বয়ংক্রিয়ভাবে ব্যর্থ হলে এটি নির্বাচন করুন। Sora এর TLS ফ্র্যাগমেন্টেশন সেটিং এই ইঞ্জিনের সাথে অনুপলব্ধ৷\n\n## Sora এ সামঞ্জস্যপূর্ণ\n\n| বৈশিষ্ট্য | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN এবং TCP/UDP | হ্যাঁ | হ্যাঁ | হ্যাঁ |\n| XHTTP | হ্যাঁ | হ্যাঁ | হ্যাঁ |\n| VLESS Encryption | হ্যাঁ | হ্যাঁ | হ্যাঁ |\n| সম্পূর্ণ Xray প্রোফাইল | না | হ্যাঁ | না |\n| TUIC / AnyTLS | উভয় | না | TUIC |\n| TLS ফ্র্যাগমেন্টেশন | হ্যাঁ | হ্যাঁ | না |\n| AmneziaWG 1.x/2.x | হ্যাঁ¹ | না | হ্যাঁ |\n| অর্ডার ফলব্যাক গ্রুপ | না | No² | হ্যাঁ |\n\nJ1/J2/J3/Itime সহ প্রোফাইল mihomo ব্যবহার করে; এই ক্ষেত্রগুলি কখনই নীরবে বাতিল করা উচিত নয়। ² সম্পূর্ণ Xray প্রোফাইলের একটি গোষ্ঠীর জন্য, অ্যাপটি একটি ব্যাকআপ প্রোফাইল নির্বাচন করে। সমর্থন ইনস্টল করা বিল্ড উপর নির্ভর করে; সম্পর্কে এর সংস্করণ পরীক্ষা করুন।\n\n## TUN স্ট্যাক\n\nস্ট্যাক ভার্চুয়াল ইন্টারফেসের ভিতরে TCP এবং UDP পরিচালনা করে। মোড প্যানেলে, Xray এবং mihomo gVisor, System, Mixed এবং MIPS অফার করে। প্রতিটি ইঞ্জিন তার নিজস্ব পছন্দ সংরক্ষণ করে। System প্রক্সি এবং সার্ভারহীন মোড এই পছন্দ ব্যবহার করে না।\n\n- **Mixed** — TCP সিস্টেম স্ট্যাক ব্যবহার করে, যখন gVisor UDP পরিচালনা করে। Linux-এ এটি mihomo-এর ডিফল্ট। Windows-এ Xray এবং mihomo ডিফল্ট হিসেবে MIPS ব্যবহার করে।\n- **System** — সিস্টেম স্ট্যাক ব্যবহার করে। নেটওয়ার্ক অ্যাপ্লিকেশন সমস্যা সম্মুখীন হলে অন্য বিকল্প চেষ্টা করুন.\n- **gVisor** — ইউজারস্পেসে ট্রাফিক পরিচালনা করে।\n- **MIPS** — mihomo এর নিজস্ব আইপি স্ট্যাক, বান্ডেল করা সংস্করণ 1.19.32-এ উপলব্ধ৷\n\nLinux-এ, Xray ডিফল্টরূপে এর অন্তর্নির্মিত gVisor ব্যবহার করে। System, Mixed এবং Linux-এ MIPS TUN ইঞ্জিন হিসাবে mihomo ব্যবহার করে, একটি প্রমাণীকৃত স্থানীয় SOCKS লিঙ্কের মাধ্যমে TCP এবং UDPকে Xray-এ ফরওয়ার্ড করে৷ Xray প্রোটোকল, প্রদানকারীর প্রোফাইল এবং রাউটিং ধরে রাখে। এই তিনটি বিকল্পের জন্য একটি ইনস্টল করা mihomo প্রয়োজন৷ Windows-এ Xray চারটি TUN স্ট্যাকের জন্য mihomo 1.19.32 বা নতুন সংস্করণ ব্যবহার করে। প্রোটোকল ও রাউটিং Xray-তে থাকে। এই সংযোগে অ্যাপের নিয়ম শুধু সরাসরি সংযোগ ও ব্লক করা সমর্থন করে; Linux-এ এই নিয়মগুলির জন্য Xray-এর অন্তর্নির্মিত gVisor প্রয়োজন।\n\nসেতুটি একটি দ্বিতীয় প্রক্রিয়া চালায়। Linux-এ তিনটি নিষ্ক্রিয় পরিমাপে, এটি নেটিভ Xray TUN থেকে প্রায় 32-36 MiB বেশি শারীরিক মেমরি ব্যবহার করেছে। এটি ডাউনলোড লোড পরিমাপ করে না: CPU এবং মেমরি খরচ সংযোগের উপর নির্ভর করে। sing-box কোনো স্ট্যাক নির্বাচক নেই। কোনও স্ট্যাক প্রতিটি নেটওয়ার্কে আরও ভাল পারফরম্যান্সের গ্যারান্টি দেয় না। একটি স্ট্যাক চয়ন করুন এবং আপনার নেটওয়ার্কে চেষ্টা করতে প্রয়োগ করুন এবং পুনরায় সংযোগ করুন নির্বাচন করুন৷\n\n## সেটিংস প্রয়োগ করা হচ্ছে\n\nএকটি সার্ভার নির্বাচন স্বয়ংক্রিয়ভাবে পুনরায় সংযোগ. মোড, ইঞ্জিন, DNS এবং নিয়ম সেটিংস অবিলম্বে সংরক্ষিত হয়; একটি সক্রিয় সংযোগের সময়, প্রয়োগ ক্লিক করুন এবং সেগুলি ব্যবহার করতে পুনরায় সংযোগ করুন৷ একটি ইঞ্জিন রিস্টার্ট করলে ডাউনলোড এবং কল বাধাগ্রস্ত হতে পারে। বারবার ক্লিক সমান্তরাল সংযোগ শুরু করে না; সংযোগ বিচ্ছিন্ন করা রূপান্তর শেষ করে এবং সংযোগটি ছেড়ে দেয়।\n\nএকটি টানেল নেমে গেলে শুধুমাত্র VPN এর মাধ্যমে ইন্টারনেট সরাসরি ট্রাফিক ব্লক করে। এটি পুরো মেশিনকে প্রভাবিত করে। একটি সুস্পষ্ট সংযোগ বিচ্ছিন্ন হলে Sora এর নিয়মগুলি সরিয়ে দেওয়া হয়। যদি ক্লিনআপ শেষ না হয়, আবার সংযোগ বিচ্ছিন্ন করার চেষ্টা করুন এবং লগটি খুলুন।\n\n## প্রকল্প ডকুমেন্টেশন\n\n- [sing-box-lx: কনফিগারেশন এবং সমর্থন](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box ডকুমেন্টেশন](https://sing-box.sagernet.org/)\n- [Xray ডকুমেন্টেশন](https://xtls.github.io/)\n- [mihomo ডকুমেন্টেশন](https://wiki.metacubex.one/)\n- [zapret: অপারেশন এবং সীমাবদ্ধতা](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'সার্ভার চেক করুন';

  @override
  String get extensions => 'এক্সটেনশন';

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
    return 'ফাইলে $name';
  }

  @override
  String get diagnosticHttp => 'HTTP ডায়াগনস্টিকস';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'এখনও কোন রেকর্ড করা অনুরোধ. প্রথমে একটি গতি পরীক্ষার ওয়েবসাইট খুলুন।';

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
