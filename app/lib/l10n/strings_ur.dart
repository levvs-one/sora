// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class SUr extends S {
  SUr([String locale = 'ur']) : super(locale);

  @override
  String get stateOff => 'منسلک نہیں';

  @override
  String get stateConnecting => 'جڑ رہا ہے۔';

  @override
  String get stateConnected => 'جڑا ہوا';

  @override
  String get stateReconnecting => 'دوبارہ جڑ رہا ہے۔';

  @override
  String get stateDisconnecting => 'منقطع ہو رہا ہے۔';

  @override
  String get stateFailed => 'منسلک نہیں';

  @override
  String get coreMissing => 'Sora سروس جواب نہیں دے رہی ہے۔';

  @override
  String get serverAuto => 'تیز ترین';

  @override
  String get serverBypass => 'کوئی سرور نہیں۔';

  @override
  String get addSubscription => 'سبسکرپشن شامل کریں۔';

  @override
  String get servers => 'سرورز';

  @override
  String get settings => 'ترتیبات';

  @override
  String get subscription => 'رکنیت';

  @override
  String get subscriptionLink => 'سبسکرپشن لنک';

  @override
  String get add => 'شامل کریں۔';

  @override
  String get refresh => 'اپ ڈیٹ کریں۔';

  @override
  String get rename => 'نام تبدیل کریں۔';

  @override
  String get delete => 'حذف کریں۔';

  @override
  String get cancel => 'منسوخ کریں۔';

  @override
  String get save => 'محفوظ کریں۔';

  @override
  String get name => 'نام';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" کو حذف کریں؟';
  }

  @override
  String get routes => 'راستے';

  @override
  String get presetGlobal => 'وی پی این کے ذریعے سب کچھ';

  @override
  String get presetRu => 'روس براہ راست';

  @override
  String get presetIr => 'ایران براہ راست';

  @override
  String get presetCn => 'چین براہ راست';

  @override
  String get blockAds => 'اشتہارات کو مسدود کریں۔';

  @override
  String get killSwitch => 'انٹرنیٹ صرف VPN کے ذریعے';

  @override
  String get engine => 'انجن';

  @override
  String get engineAuto => 'آٹو';

  @override
  String get animations => 'متحرک تصاویر';

  @override
  String get logs => 'لاگ';

  @override
  String get about => 'کے بارے میں';

  @override
  String get logsAll => 'تمام';

  @override
  String get logsImportant => 'اہم';

  @override
  String get logsErrors => 'غلطیاں';

  @override
  String get search => 'تلاش کریں۔';

  @override
  String get export => 'فائل میں محفوظ کریں۔';

  @override
  String get clear => 'صاف';

  @override
  String get logsEmpty => 'یہاں کچھ نہیں۔';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'ورژن $version';
  }

  @override
  String get notInstalled => 'انسٹال نہیں ہے۔';

  @override
  String get sourceCode => 'سورس کوڈ';

  @override
  String get license => 'لائسنس';

  @override
  String usage(String used, String total) {
    return '$total کا $used';
  }

  @override
  String until(String date) {
    return '$date تک';
  }

  @override
  String get expired => 'میعاد ختم';

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
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n GB';
  }

  @override
  String bytesTB(String n) {
    return '$n ٹی بی';
  }

  @override
  String get errGeneric => 'کچھ غلط ہو گیا۔';

  @override
  String get errCore => 'Sora سروس جواب نہیں دے رہی ہے۔';

  @override
  String get errAuth => 'Sora سروس تک رسائی نہیں ہے۔';

  @override
  String get errVersion => 'Sora اپ ڈیٹ کریں: ایپ اور سروس مختلف ورژن ہیں۔';

  @override
  String get errBusy => 'انتظار کرو، پچھلی کمانڈ اب بھی چل رہی ہے۔';

  @override
  String get errEngineMissing => 'اس سرور کے لیے کوئی انجن نہیں ملا';

  @override
  String get errEngineStart => 'انجن اسٹارٹ نہیں ہوا۔';

  @override
  String get errEngineStopped => 'انجن رک گیا۔';

  @override
  String get errTunnel => 'VPN کنکشن بنانے کی اجازت نہیں ہے۔';

  @override
  String get errServers => 'سرور ایک خرابی کے ساتھ ترتیب دیا گیا ہے۔';

  @override
  String get errNetwork => 'سرور تک نہیں پہنچ سکتا';

  @override
  String get errTimeout => 'سرور نے بروقت جواب نہیں دیا۔';

  @override
  String get errFirewall => 'VPN کے باہر انٹرنیٹ کو بلاک نہیں کیا جا سکا';

  @override
  String get errSubFetch => 'سبسکرپشن لوڈ نہیں ہو سکی';

  @override
  String get errSubFormat => 'یہ سبسکرپشن لنک نہیں ہے۔';

  @override
  String get errSubEmpty => 'سبسکرپشن میں کوئی سرور نہیں ہے۔';

  @override
  String get errSubDuplicate => 'یہ رکنیت پہلے ہی شامل ہے۔';

  @override
  String get errSubLimit => 'بہت زیادہ سبسکرپشنز';

  @override
  String get errSubScheme => 'لنک https:// سے شروع ہونا چاہیے';

  @override
  String get errSecretStore => 'Sora اسٹوریج خراب ہے یا دستیاب نہیں ہے۔';

  @override
  String get errNoServers => 'جڑنے کے لیے سبسکرپشن شامل کریں۔';

  @override
  String get exportText => 'متن';

  @override
  String get connections => 'کنکشنز';

  @override
  String get close => 'بند';

  @override
  String get chainDirect => 'براہ راست';

  @override
  String get chainBlocked => 'مسدود';

  @override
  String get theme => 'تھیم';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'روشنی';

  @override
  String get themeDark => 'اندھیرا';

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'کنکشن';

  @override
  String get sectionNoServer => 'کوئی سرور نہیں۔';

  @override
  String get sectionPing => 'پنگ';

  @override
  String get sectionLog => 'تشخیص';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'ڈی این ایس';

  @override
  String get dnsAuto => 'آٹو';

  @override
  String get dnsHint => 'پتے، کوما سے الگ';

  @override
  String get fragment => 'TLS فریگمنٹیشن';

  @override
  String get fragmentPackets => 'کیا تقسیم کرنا ہے';

  @override
  String get fragmentLength => 'ٹکڑا سائز';

  @override
  String get fragmentInterval => 'ٹکڑوں کے درمیان وقفہ کریں۔';

  @override
  String get byDefault => 'طے شدہ';

  @override
  String get rangeHint => 'مثال کے طور پر، 100-200';

  @override
  String get splitPos => 'پوزیشنیں تقسیم کریں۔';

  @override
  String get splitPosHint => 'مثال کے طور پر، 1، midsld';

  @override
  String get disorder => 'ٹکڑوں کو دوبارہ ترتیب دیں۔';

  @override
  String get tlsRecord => 'TLS ریکارڈ کو تقسیم کریں۔';

  @override
  String get tlsRecordNo => 'نہیں';

  @override
  String get tlsRecordSni => 'سائٹ کے نام پر';

  @override
  String get tlsRecordFirst => 'پہلے بائٹ کے بعد';

  @override
  String get hostCase => 'میزبان کیس تبدیل کریں۔';

  @override
  String get probeMethod => 'طریقہ';

  @override
  String get probeAuto => 'آٹو';

  @override
  String get probeEngine => 'انجن کے ذریعے';

  @override
  String get probeConnect => 'صرف کنکشن';

  @override
  String get probeUrl => 'ٹیسٹ ایڈریس';

  @override
  String get probeTimeout => 'انتظار کرو';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'سبسکرپشنز';

  @override
  String get subscriptionSettings => 'ترتیبات';

  @override
  String get userAgent => 'صارف ایجنٹ';

  @override
  String get autoUpdate => 'خود بخود اپ ڈیٹ کریں۔';

  @override
  String get updateInterval => 'کتنی بار';

  @override
  String get intervalProvider => 'جیسا کہ فراہم کنندہ پوچھتا ہے۔';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'ابھی اپ ڈیٹ کریں۔';

  @override
  String get logLevel => 'کیا ریکارڈ کرنا ہے۔';

  @override
  String get levelDebug => 'سب کچھ';

  @override
  String get levelInfo => 'معمول';

  @override
  String get levelWarning => 'اہم';

  @override
  String get levelError => 'صرف غلطیاں';

  @override
  String get recordDestinations => 'سائٹ کے پتے ریکارڈ کریں۔';

  @override
  String get reset => 'ترتیبات کو دوبارہ ترتیب دیں۔';

  @override
  String get resetConfirm => 'تمام ترتیبات کو دوبارہ ترتیب دیں؟';

  @override
  String get resetAction => 'دوبارہ ترتیب دیں۔';

  @override
  String get invalidValue => 'یہ قدر کام نہیں کرے گی۔';

  @override
  String get website => 'رکنیت کا صفحہ';

  @override
  String get providerWebsite => 'فراہم کنندہ کی ویب سائٹ';

  @override
  String get support => 'حمایت';

  @override
  String controlPortQuestion(String engine) {
    return '$engine کو اس کمپیوٹر پر ایک پورٹ کے ذریعے کنٹرول کیا جاتا ہے۔ دوسرے پروگرام یہ بتا سکیں گے کہ VPN آن ہے۔';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine کا انتخاب کریں۔';
  }

  @override
  String get rules => 'اپنی مرضی کے قوانین';

  @override
  String get ruleAdd => 'نیا اصول';

  @override
  String get ruleHint => 'سائٹ، آئی پی یا پروگرام';

  @override
  String get ruleDirect => 'براہ راست';

  @override
  String get ruleProxy => 'وی پی این کے ذریعے';

  @override
  String get ruleBlock => 'بلاک';

  @override
  String get failover => 'ناکامی پر سوئچ کریں۔';

  @override
  String get connectOnStart => 'شروع پر جڑیں۔';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'سبسکرپشن # دنوں میں ختم ہو جاتی ہے۔',
      one: 'رکنیت # دن میں ختم ہو جاتی ہے۔',
      zero: 'رکنیت چند گھنٹوں میں ختم ہو جاتی ہے۔',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left چھوڑ دیا۔';
  }

  @override
  String get ruleInvalid => 'یہ کسی سائٹ، آئی پی یا پروگرام کی طرح نہیں لگتا ہے۔';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# سرورز، بدلے میں',
      one: '# سرور، بدلے میں',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# سرورز، تیز ترین',
      one: '# سرور، تیز ترین',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'موڈ';

  @override
  String get tunnelTun => 'تمام ٹریفک';

  @override
  String get tunnelProxy => 'System پراکسی';

  @override
  String get proxyAddress => 'پراکسی ایڈریس';

  @override
  String get copied => 'کاپی';

  @override
  String get launchAtLogin => 'سسٹم کے ساتھ شروع کریں۔';

  @override
  String get launchAtLoginDetail => 'سائن ان کرنے پر Sora خودکار طور پر شروع ہوگا اور ٹرے میں رہے گا۔';

  @override
  String get closeToTray => 'بند ہونے پر ٹرے میں رکھیں';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get trayOpen => 'Sora کھولیں۔';

  @override
  String get trayConnect => 'جڑیں۔';

  @override
  String get trayDisconnect => 'منقطع کرنا';

  @override
  String get trayServer => 'سرور';

  @override
  String get trayQuit => 'Sora چھوڑیں۔';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora ابھی بھی ٹرے میں ہے۔';

  @override
  String get noticeInTrayBody => 'اس کے آئیکن کے مینو سے باہر نکلیں۔';

  @override
  String get noticeLost => 'کنکشن ٹوٹ گیا۔';

  @override
  String get noticeLostBody => 'Sora دوبارہ منسلک ہو رہا ہے۔';

  @override
  String get noticeRestored => 'دوبارہ جڑ گیا۔';

  @override
  String get noticeFailed => 'رابطہ نہیں ہو سکا';

  @override
  String get noticeBackup => 'مرکزی سرور نے جواب نہیں دیا۔ بیک اپ ٹریفک لے جاتا ہے';

  @override
  String get noticeNext => 'سرور نے جواب نہیں دیا۔ اگلا ٹریفک لے جاتا ہے۔';

  @override
  String get noticeMainBack => 'مرکزی سرور دوبارہ جواب دیتا ہے اور ٹریفک لے جاتا ہے۔';

  @override
  String get noticeSubscription => 'رکنیت';

  @override
  String get importTitle => 'اس سبسکرپشن کو شامل کریں؟';

  @override
  String get importSealed =>
      'یہ لنک Happ کے لیے خفیہ کردہ ہے، اور صرف Happ اسے پڑھ سکتا ہے۔ اپنے فراہم کنندہ سے سادہ سبسکرپشن لنک طلب کریں۔';

  @override
  String get understood => 'ٹھیک ہے';

  @override
  String get noAnswer => 'کوئی جواب نہیں';

  @override
  String get home => 'گھر';

  @override
  String get navRules => 'قواعد';

  @override
  String get navConnections => 'کنکشنز';

  @override
  String get navLogs => 'نوشتہ جات';

  @override
  String get navAbout => 'کے بارے میں';

  @override
  String get sidebarToggle => 'سائڈبار کو ٹوگل کریں۔';

  @override
  String get more => 'مزید';

  @override
  String get less => 'کم';

  @override
  String get currentServer => 'موجودہ سرور';

  @override
  String get trafficDown => 'ڈاؤن لوڈ کیا گیا۔';

  @override
  String get trafficUp => 'اپ لوڈ کیا گیا';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'فعال قوانین: $count';
  }

  @override
  String get recentNotifications => 'حالیہ اطلاعات';

  @override
  String get notificationsEmpty => 'کنکشن اور سبسکرپشن ایونٹس یہاں ظاہر ہوں گے۔';

  @override
  String get retryConnect => 'کنکشن کی دوبارہ کوشش کریں۔';

  @override
  String get openLogs => 'نوشتہ جات کھولیں۔';

  @override
  String get tourReplay => 'دوبارہ گائیڈ دکھائیں۔';

  @override
  String tourStep(int step) {
    return '5 میں سے $step مرحلہ';
  }

  @override
  String get tourBack => 'پیچھے';

  @override
  String get tourNext => 'اگلا';

  @override
  String get tourSkip => 'چھوڑیں۔';

  @override
  String get tourFinish => 'ہو گیا';

  @override
  String get tourAdd => 'اپنے فراہم کنندہ کی رکنیت کا لنک شامل کریں۔';

  @override
  String get tourServer => 'ایک سرور چنیں۔ \"تیز ترین\" آپ کے لیے ایک کا انتخاب کرتا ہے۔';

  @override
  String get tourConnect => 'جڑنے یا منقطع کرنے کے لیے یہاں کلک کریں۔';

  @override
  String get tourMode => 'ایک موڈ کا انتخاب کریں۔ VPN گرنے پر Kill سوئچ انٹرنیٹ کو بلاک کر دیتا ہے۔';

  @override
  String get tourSettings => 'ترتیبات کھولیں۔ آپ وہاں اس گائیڈ کو دوبارہ چلا سکتے ہیں۔';

  @override
  String get chooseProgram => 'ایک پروگرام کا انتخاب کریں۔';

  @override
  String get installedApps => 'انسٹال کردہ ایپلیکیشنز';

  @override
  String get runningProcesses => 'چلنے والے عمل';

  @override
  String get programsFailed => 'ایپلیکیشنز کو لوڈ نہیں کیا جا سکا';

  @override
  String get programsEmpty => 'کوئی درخواستیں نہیں ملی۔ دوسرا نام آزمائیں۔';

  @override
  String get selectExe => 'ایک .exe فائل کا انتخاب کریں۔';

  @override
  String get trafficUnavailable => 'کاؤنٹر ابھی تک دستیاب نہیں ہیں۔';

  @override
  String get speedtest => 'رفتار';

  @override
  String get speedtestCheck => 'رفتار چیک کریں۔';

  @override
  String get speedtestSearch => 'ایک سروس تلاش کریں۔';

  @override
  String get speedtestEmpty => 'کوئی میچ نہیں تلاش کو تبدیل کریں۔';

  @override
  String get speedtestBackToList => 'خدمات پر واپس جائیں۔';

  @override
  String get speedtestOpenBrowser => 'براؤزر میں کھولیں۔';

  @override
  String get speedtestUnavailable => 'سرایت شدہ براؤزر شروع نہیں ہو سکا۔ اپنے سسٹم براؤزر میں سروس کھولیں۔';

  @override
  String get speedtestPageFailed => 'صفحہ لوڈ نہیں ہو سکا۔ اسے دوبارہ لوڈ کریں یا اپنے سسٹم براؤزر میں سروس کھولیں۔';

  @override
  String get speedtestExternalFailed => 'سسٹم براؤزر نہیں کھل سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get modes => 'موڈز';

  @override
  String get proxyShort => 'پراکسی';

  @override
  String get tunMode => 'تمام ٹریفک (TUN)';

  @override
  String get checkUpdates => 'اپ ڈیٹس کے لیے چیک کریں۔';

  @override
  String get updates => 'ایپ اپ ڈیٹس';

  @override
  String updateAvailable(String version) {
    return 'ورژن $version دستیاب ہے۔';
  }

  @override
  String get updateOpenAbout => 'اپ ڈیٹ دیکھیں';

  @override
  String updateNotes(String version) {
    return '$version میں تبدیلیاں';
  }

  @override
  String get updateCheck => 'اپ ڈیٹس کے لیے چیک کریں۔';

  @override
  String get updateChecking => 'چیک کر رہا ہے...';

  @override
  String get updateNoNotes => 'ریلیز میں کوئی نوٹ نہیں ہے۔';

  @override
  String get updateDropWarning =>
      'VPN کنکشن چند سیکنڈز کے لیے گر جائے گا جبکہ Sora اور اس کی بنیادی اپ ڈیٹ۔ جاری رکھیں؟';

  @override
  String get updateWaitConnection => 'VPN کنکشن اور کور کے تیار ہونے کا انتظار کریں۔';

  @override
  String get updateDownloading => 'فائلیں ڈاؤن لوڈ اور تصدیق کی جا رہی ہیں...';

  @override
  String get updateInstalling => 'اپ ڈیٹ کی تیاری ہو رہی ہے یا ایڈمنسٹریٹر کی تصدیق کا انتظار کر رہا ہے...';

  @override
  String get updateNetworkError => 'اپ ڈیٹ ڈاؤن لوڈ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get updateReleaseError => 'ریلیز ڈیٹا یا مطلوبہ فائلیں غائب یا غلط ہیں۔';

  @override
  String get updateChecksumError => 'ڈاؤن لوڈ SHA256SUMS سے مماثل نہیں ہے۔ کچھ بھی انسٹال نہیں تھا۔';

  @override
  String get updateInstallError => 'اپ ڈیٹ ختم نہیں ہوا۔ ہو سکتا ہے توثیق منسوخ کر دی گئی ہو۔';

  @override
  String get updateUnsupported =>
      'یہ قابل عمل Sora پیکیج جوڑے کی ملکیت نہیں ہے۔ ریلیز کی تنصیب کی ہدایات کا استعمال کریں۔';

  @override
  String get updateManual =>
      'دونوں تصدیق شدہ پیکیجز کو انسٹال کرنے کے لیے اس کمانڈ کو ٹرمینل میں چلائیں، پھر Sora کو دوبارہ کھولیں۔ فائلیں ڈاؤن لوڈ ڈائرکٹری میں رہتی ہیں۔ VPN کنکشن ختم ہو جائے گا۔';

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
  String get updateCopyCommand => 'کمانڈ کاپی کریں۔';

  @override
  String get updateChecksDisabled => 'خودکار چیک سیٹنگز میں غیر فعال ہیں۔';

  @override
  String get updateInstalled => 'اپ ڈیٹ انسٹال ہو گیا۔ Sora دوبارہ کھولیں۔';

  @override
  String get projectLinks => 'پروجیکٹ';

  @override
  String get githubReleases => 'ریلیز اور ڈاؤن لوڈز';

  @override
  String get telegramChannel => 'Telegram چینل';

  @override
  String get licenses => 'لائسنس';

  @override
  String get componentLicenses => 'اجزاء کے لائسنس';

  @override
  String get appCopyright => '© 2026 levvs-one اور تعاون کنندگان';

  @override
  String get collapseServers => 'سرورز کو سمیٹیں۔';

  @override
  String get expandServers => 'سرورز کو پھیلائیں۔';

  @override
  String get hideDescription => 'تفصیل چھپائیں۔';

  @override
  String get showDescription => 'تفصیل دکھائیں۔';

  @override
  String get pendingConnectionChanges => 'ان تبدیلیوں کو لاگو کرنے کے لیے دوبارہ جڑیں۔';

  @override
  String get reconnectNow => 'لاگو کریں اور دوبارہ جڑیں۔';

  @override
  String get bypassLimitations =>
      'یہ موڈ صرف HTTP اور TLS کے لیے DPI کو نظرانداز کرتا ہے، نہ UDP کو سپورٹ کرتا ہے اور نہ ہی آپ کے IP کو تبدیل کرتا ہے۔ Discord آواز، کالز اور بلاک شدہ Telegram پتوں کے لیے VPN سرور استعمال کریں۔';

  @override
  String get errEngineUnsupported =>
      'منتخب انجن اس پروفائل یا سیٹنگز کو سپورٹ نہیں کرتا ہے۔ آٹو یا ہم آہنگ انجن کا انتخاب کریں۔';

  @override
  String get errRestore => 'کنکشن کی صفائی نامکمل تھی۔ منقطع کرنے کی دوبارہ کوشش کریں؛ تفصیلات کے لیے لاگ دیکھیں۔';

  @override
  String get errSessionEnded => 'یہ سیشن پہلے ہی ختم ہو چکا ہے۔ کنکشن کی حالت کو تازہ کریں۔';

  @override
  String get retryDisconnect => 'منقطع کرنے کی دوبارہ کوشش کریں۔';

  @override
  String get tunStack => 'TUN اسٹیک';

  @override
  String get modesInfo => 'طریقوں کے بارے میں';

  @override
  String get modesGuideTitle => 'موڈز اور انجن';

  @override
  String get modesGuide =>
      'اگر آپ کو یقین نہیں ہے کہ آپ کے سرور کو کس انجن کی ضرورت ہے تو آٹو کا انتخاب کریں۔ Sora کنیکٹ کرنے سے پہلے پروفائل اور سیٹنگز کو چیک کرتا ہے۔ ایک انجن آپ کے پلان کی بینڈوتھ کو نہیں بڑھا سکتا: کارکردگی کا انحصار سرور، روٹ، پروٹوکول اور نیٹ ورک پر ہوتا ہے۔\n\n## موڈز\n\n### تمام ٹریفک (TUN)\n\nSora ایک ورچوئل نیٹ ورک انٹرفیس بناتا ہے اور اس کے ذریعے ایپلیکیشن ٹریفک کو روٹ کرتا ہے، بشمول TCP اور UDP۔ اس موڈ کو Telegram، گیمز اور Discord آواز کے لیے استعمال کریں۔ قواعد مخصوص سائٹوں یا پروگراموں کو براہ راست بھیج سکتے ہیں یا انہیں بلاک کر سکتے ہیں۔ نیٹ ورک سروس کو اجازت اور سرور کی ضرورت ہے جو مطلوبہ پروٹوکول کو سپورٹ کرتا ہو۔\n\n### System پراکسی\n\nSora ایک مقامی HTTP/SOCKS پراکسی کو ترتیب دیتا ہے۔ وہ ایپلیکیشنز جو سسٹم پراکسی سیٹنگز کا احترام کرتی ہیں اسے استعمال کرتی ہیں۔ ان کے اپنے نیٹ ورک اسٹیک والی درخواستیں براہ راست جڑ سکتی ہیں۔ UDP اور وائس کالز کو عام طور پر TUN کی ضرورت ہوتی ہے۔ یہ موڈ پراکسی سپورٹ والے براؤزرز اور ایپلیکیشنز کے لیے موزوں ہے۔\n\n### کوئی سرور نہیں۔\n\nLinux پر، Sora HTTP/TLS درخواستوں کو تقسیم کرنے اور نئی شکل دینے اور کچھ DPI چیکس کو نظرانداز کرنے کے لیے [zapret](https://github.com/bol-van/zapret) کا استعمال کرتا ہے۔ آپ کا IP وہی رہتا ہے اور کنکشن براہ راست ویب سائٹ پر جاتے ہیں۔ نتائج کا انحصار آپ کے فراہم کنندہ اور بلاک کرنے کے طریقہ پر ہے۔\n\nموجودہ انضمام TCP پر HTTP اور TLS کے لیے tpws استعمال کرتا ہے۔ یہ IP بلاکنگ یا ریلے UDP کو نظرانداز نہیں کرتا ہے، اور Telegram کے MTProto کنکشن کی ضمانت نہیں دے سکتا ہے۔ Discord آواز، Telegram کالز اور اس قسم کی پابندیوں کے لیے TUN کے ساتھ VPN سرور استعمال کریں۔\n\n## انجن\n\n### آٹو\n\nSora ایک انسٹال شدہ انجن کا انتخاب کرتا ہے جو پورے کنکشن پلان کو سپورٹ کرتا ہے: سرور پروٹوکول، ٹرانسپورٹ، گروپس، فریگمنٹیشن اور موڈ۔ موجودہ کنکشن کو روکنے سے پہلے ایک غیر موازن دستی انتخاب کو مسترد کر دیا جاتا ہے۔ آٹو یا دوسرا انجن منتخب کریں اور سیٹنگز کو دوبارہ لاگو کریں۔\n\n### sing-box\n\nنئے Sora پیکیجز میں [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) شامل ہیں، [sing-box](https://github.com/SagerNet/sing-box) کا ایک کانٹا، کلائنٹ سائیڈ XHTTP اور VLESS Encryption شامل کرنا۔ Sora تعمیر اور اس کی صلاحیتوں کو تسلیم کرتا ہے۔ XHTTP کے بغیر اپ اسٹریم کی تعمیر صرف اپنے نام سے یہ صلاحیت حاصل نہیں کرتی ہے۔\n\nمعاون پروٹوکول میں VLESS، VMess، Trojan، Shadowsocks، Hysteria2، TUIC، AnyTLS، WireGuard اور AmneziaWG 1.x/2.x کے وہ پیرامیٹر شامل ہیں جنہیں Sora درآمد کر سکتا ہے۔ مکمل Xray JSON پروفائل کے لیے Xray درکار ہے۔ نئے AWG 3.x فیلڈ ابھی درآمد نہیں کیے جا سکتے۔ sing-box پاس ورڈ سے محفوظ مقامی کنٹرول پورٹ استعمال کرتا ہے، جسے کمپیوٹر کی دوسری ایپلیکیشنز تلاش کر سکتی ہیں۔\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption اور TLS فریگمنٹیشن کو سپورٹ کرتا ہے۔ یہ مکمل فراہم کنندہ Xray پروفائلز کو بھی چلاتا ہے جبکہ ان کی روٹنگ اور گروپس کو محفوظ رکھتا ہے۔ ایسے پروفائلز کو ان کے رویے کو تبدیل کیے بغیر خود بخود دوسرے انجن میں تبدیل نہیں کیا جا سکتا۔\n\nبنڈل شدہ Xray نے اس ترتیب کو ہٹا دیا جو TLS سرٹیفکیٹ کی تصدیق کو غیر فعال کرتی ہے (`allowInsecure`)۔ آٹو sing-box یا mihomo کو اس ترتیب کی ضرورت والے عام سرورز کے لیے منتخب کرتا ہے۔ موجودہ کنکشن کو روکنے سے پہلے Xray کو منتخب کرنا دستی طور پر عدم مطابقت کی اطلاع دیتا ہے۔ پرانے مکمل JSON پروفائلز کو قابل تصدیق سرٹیفکیٹ یا سرٹیفکیٹ پن کے ساتھ ایک اپ ڈیٹ فراہم کنندہ پروفائل کی ضرورت ہے۔\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) آرڈر شدہ فال بیک اور لوڈ بیلنسنگ گروپس، XHTTP اور AmneziaWG کو سپورٹ کرتا ہے۔ اسے منتخب کریں جب بیک اپ سرور میں خودکار طور پر ناکام ہو جائے۔ Sora کی TLS فریگمنٹیشن سیٹنگ اس انجن کے ساتھ دستیاب نہیں ہے۔\n\n## Sora میں مطابقت\n\n| خصوصیت | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN اور TCP/UDP | جی ہاں | جی ہاں | جی ہاں |\n| XHTTP | جی ہاں | جی ہاں | جی ہاں |\n| VLESS Encryption | جی ہاں | جی ہاں | جی ہاں |\n| مکمل Xray پروفائل | نہیں | جی ہاں | نہیں |\n| TUIC / AnyTLS | دونوں | نہیں | TUIC |\n| TLS فریگمنٹیشن | جی ہاں | جی ہاں | نہیں |\n| AmneziaWG 1.x/2.x | ہاں¹ | نہیں | جی ہاں |\n| حکم دیا فال بیک گروپ | نہیں | No² | جی ہاں |\n\nJ1/J2/J3/Itime والے پروفائلز mihomo استعمال کرتے ہیں؛ ان شعبوں کو کبھی بھی خاموشی سے ضائع نہیں کیا جانا چاہیے۔ ² مکمل Xray پروفائلز کے گروپ کے لیے، ایپ بیک اپ پروفائل کا انتخاب کرتی ہے۔ سپورٹ نصب شدہ تعمیر پر منحصر ہے؛ اس کا ورژن About میں چیک کریں۔\n\n## TUN اسٹیک\n\nاسٹیک ورچوئل انٹرفیس کے اندر TCP اور UDP کو ہینڈل کرتا ہے۔ موڈز پینل میں، Xray اور mihomo gVisor، System، Mixed اور MIPS پیش کرتے ہیں۔ ہر انجن اپنی ترجیح بچاتا ہے۔ System پراکسی اور سرور لیس موڈز اس ترجیح کو استعمال نہیں کرتے ہیں۔\n\n- **Mixed** — TCP سسٹم اسٹیک کا استعمال کرتا ہے، جبکہ gVisor UDP کو ہینڈل کرتا ہے۔ Linux پر یہ mihomo کے لیے ڈیفالٹ ہے۔ Windows پر Xray اور mihomo ڈیفالٹ طور پر MIPS استعمال کرتے ہیں۔\n- **System** — سسٹم اسٹیک استعمال کرتا ہے۔ اگر نیٹ ورک ایپلیکیشنز کو مسائل کا سامنا کرنا پڑتا ہے تو دوسرا آپشن آزمائیں۔\n- **gVisor** — یوزر اسپیس میں ٹریفک کو ہینڈل کرتا ہے۔\n- **MIPS** — mihomo کا اپنا IP اسٹیک، بنڈل ورژن 1.19.32 میں دستیاب ہے۔\n\nLinux پر، Xray اپنے بلٹ ان gVisor کو بطور ڈیفالٹ استعمال کرتا ہے۔ System، Mixed اور MIPS Linux پر mihomo کو TUN انجن کے طور پر استعمال کرتے ہیں، TCP اور UDP کو ایک مستند مقامی SOCKS لنک کے ذریعے Xray کو فارورڈ کرتے ہیں۔ Xray پروٹوکول، فراہم کنندہ پروفائل اور روٹنگ کو برقرار رکھتا ہے۔ ان تینوں اختیارات کے لیے انسٹال mihomo کی ضرورت ہے۔ Windows پر Xray چاروں TUN اسٹیکس کے لیے mihomo 1.19.32 یا نیا ورژن استعمال کرتا ہے۔ پروٹوکول اور روٹنگ Xray میں رہتے ہیں۔ اس امتزاج میں ایپ کے قواعد صرف براہ راست کنکشن اور بلاک کرنے کی حمایت کرتے ہیں؛ Linux پر ان قواعد کے لیے Xray کا بلٹ ان gVisor درکار ہے۔\n\nپل ایک دوسرا عمل چلاتا ہے۔ Linux پر تین بیکار پیمائشوں میں، اس نے مقامی Xray TUN سے تقریباً 32–36 MiB زیادہ جسمانی میموری استعمال کی۔ یہ ڈاؤن لوڈ لوڈ کی پیمائش نہیں کرتا ہے: CPU اور میموری کے اخراجات کنکشن پر منحصر ہیں۔ sing-box میں کوئی اسٹیک سلیکٹر نہیں ہے۔ کوئی اسٹیک ہر نیٹ ورک میں بہتر کارکردگی کی ضمانت نہیں دیتا۔ ایک اسٹیک کا انتخاب کریں اور اسے اپنے نیٹ ورک میں آزمانے کے لیے اپلائی کریں اور دوبارہ جڑیں کو منتخب کریں۔\n\n## ترتیبات کا اطلاق کرنا\n\nسرور کا انتخاب خود بخود دوبارہ جڑ جاتا ہے۔ موڈ، انجن، DNS اور اصول کی ترتیبات فوری طور پر محفوظ ہو جاتی ہیں۔ ایک فعال کنکشن کے دوران، لاگو کریں پر کلک کریں اور انہیں استعمال کرنے کے لیے دوبارہ جڑیں۔ انجن کو دوبارہ شروع کرنے سے ڈاؤن لوڈز اور کالز میں خلل پڑ سکتا ہے۔ بار بار کلک کرنے سے متوازی کنکشن شروع نہیں ہوتے ہیں۔ منقطع ہونے سے منتقلی ختم ہوجاتی ہے اور کنکشن جاری ہوجاتا ہے۔\n\nسرنگ گرنے پر صرف VPN کے ذریعے انٹرنیٹ براہ راست ٹریفک کو روکتا ہے۔ یہ پوری مشین کو متاثر کرتا ہے۔ واضح طور پر منقطع ہونا Sora کے قواعد کو ہٹا دیتا ہے۔ اگر کلین اپ ختم نہیں ہوتا ہے تو دوبارہ رابطہ منقطع کرنے کی کوشش کریں اور لاگ کو کھولیں۔\n\n## پروجیکٹ کی دستاویزات\n\n- [sing-box-lx: کنفیگریشن اور سپورٹ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box دستاویزات](https://sing-box.sagernet.org/)\n- [Xray دستاویزات](https://xtls.github.io/)\n- [mihomo دستاویزات](https://wiki.metacubex.one/)\n- [zapret: آپریشن اور حدود](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'سرورز کو چیک کریں۔';

  @override
  String get extensions => 'ایکسٹینشنز';

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
    return 'فائل میں $name';
  }

  @override
  String get diagnosticHttp => 'HTTP تشخیص';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'ابھی تک کوئی ریکارڈ شدہ درخواستیں نہیں ہیں۔ پہلے اسپیڈ ٹیسٹ کی ویب سائٹ کھولیں۔';

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
  String get qrScanHint => 'QR کوڈ والا اسکرین شاٹ یا تصویر منتخب کریں، یا لنک پیسٹ کریں';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'اس تصویر میں کوئی QR کوڈ نہیں ملا۔';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'تصویر کھولیں';

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
      'Shadowsocks کے لیے: method:password، مثلاً chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => 'پیکٹ کی گرفتاری';

  @override
  String get diagnosticEvents => 'ونڈوز کے واقعات';

  @override
  String get diagnosticCapture => '10 سیکنڈ کے لیے کیپچر کریں۔';

  @override
  String get diagnosticRequiresTun => 'پیکٹ کیپچر کو ایک فعال Sora TUN کنکشن کی ضرورت ہے۔';

  @override
  String get diagnosticUnavailable => 'یہ تشخیص اس پلیٹ فارم پر دستیاب نہیں ہے۔';

  @override
  String get extWorkerFailed => 'ایکسٹینشن کا پس منظر کا کام ناکام ہوگیا۔ ایکسٹینشن کا لاگ دیکھیں۔';

  @override
  String get extAssetRejected => 'ایکسٹینشن کی فائل مسترد: ناقابلِ مطالعہ رنگ یا غلط قواعد۔';
}
