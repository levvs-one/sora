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
  String get connEmpty => 'کوئی کنکشن نہیں ہے۔';

  @override
  String appVersion(String version) {
    return 'ورژن $version';
  }

  @override
  String get notInstalled => 'انسٹال نہیں ہے۔';

  @override
  String get sourceCode => 'سورس کوڈ';

  @override
  String get reportProblem => 'مسئلے کی اطلاع دیں';

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
  String get errCore => 'Sora سروس جواب نہیں دے رہی';

  @override
  String get errAuth => 'Sora سروس تک رسائی مسترد ہو گئی';

  @override
  String get errVersion => 'Sora ایپ اور سروس کے ورژن مختلف ہیں';

  @override
  String get errBusy => 'پچھلی کمانڈ ابھی چل رہی ہے';

  @override
  String get errEngineMissing => 'اس سرور کے لیے درکار انجن نہیں ملا';

  @override
  String get errEngineStart => 'انجن شروع نہیں ہو سکا';

  @override
  String get errEngineStopped => 'انجن بند ہو گیا';

  @override
  String get errTunnel => 'یہ VPN موڈ دستیاب نہیں';

  @override
  String get errTimeout => 'سرور نے وقت پر جواب نہیں دیا';

  @override
  String get errFirewall => 'VPN سے باہر انٹرنیٹ تک رسائی بند نہیں کی جا سکی';

  @override
  String get errSubFetch => 'سبسکرپشن ڈاؤن لوڈ نہیں ہو سکی';

  @override
  String get deviceIdentity => 'ڈیوائس شناخت کنندہ';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'شناخت کنندہ ری سیٹ کریں';

  @override
  String get deviceIdentityResetConfirm => 'ڈیوائس شناخت کنندہ ری سیٹ کریں؟';

  @override
  String get errSubDeviceLimit => 'ڈیوائسز کی حد پوری ہو گئی';

  @override
  String get errSubDeviceRequired => 'فراہم کنندہ کو ڈیوائس شناخت کنندہ درکار ہے';

  @override
  String get errSubFormat => 'سبسکرپشن کا فارمیٹ پہچانا نہیں جا سکا';

  @override
  String get errSubEmpty => 'سبسکرپشن میں کوئی سرور نہیں ہے';

  @override
  String get errSubDuplicate => 'یہ سبسکرپشن پہلے سے شامل ہے';

  @override
  String get errSubLimit => 'سبسکرپشنز کی حد پوری ہو گئی ہے';

  @override
  String get errSubScheme => 'سبسکرپشن لنک کی اسکیم معاون نہیں';

  @override
  String get errSecretStore => 'Sora کا ذخیرہ خراب ہے یا اس تک رسائی ممکن نہیں';

  @override
  String get errNoServers => 'کنکٹ کرنے کے لیے کوئی سرور نہیں ہے';

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
  String get themeSystem => 'سسٹم کے مطابق';

  @override
  String get themeLight => 'روشنی';

  @override
  String get themeDark => 'اندھیرا';

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'سسٹم کے مطابق';

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
  String get splitPos => 'پوزیشنیں تقسیم کریں۔';

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
      other: 'سبسکرپشن $days دنوں میں ختم ہو جاتی ہے۔',
      one: 'رکنیت $days دن میں ختم ہو جاتی ہے۔',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سرورز، تیز ترین',
      one: '$count سرور، تیز ترین',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'موڈ';

  @override
  String get tunnelProxy => 'System پراکسی';

  @override
  String get proxyAddress => 'پراکسی ایڈریس';

  @override
  String get copied => 'کاپی';

  @override
  String get launchAtLogin => 'سسٹم کے ساتھ شروع کریں۔';

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
  String get importSealed => 'یہ لنک Happ کے لیے خفیہ کردہ ہے، اور صرف Happ اسے پڑھ سکتا ہے';

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
  String get notificationsEmpty => 'کوئی اطلاع نہیں';

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
  String get programsEmpty => 'کوئی درخواستیں نہیں ملی';

  @override
  String get selectExe => 'ایک .exe فائل کا انتخاب کریں۔';

  @override
  String get speedtest => 'رفتار';

  @override
  String get speedtestSearch => 'ایک سروس تلاش کریں۔';

  @override
  String get speedtestEmpty => 'کوئی میچ نہیں تلاش کو تبدیل کریں';

  @override
  String get speedtestBackToList => 'خدمات پر واپس جائیں۔';

  @override
  String get speedtestOpenBrowser => 'براؤزر میں کھولیں۔';

  @override
  String get speedtestUnavailable => 'سرایت شدہ براؤزر شروع نہیں ہو سکا';

  @override
  String get speedtestPageFailed => 'صفحہ لوڈ نہیں ہو سکا';

  @override
  String get speedtestExternalFailed => 'سسٹم براؤزر نہیں کھل سکا';

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
  String get updateDropWarning => 'اپ ڈیٹ کے لیے کنکشن منقطع کریں؟';

  @override
  String get updateWaitConnection => 'کنکشن تیار نہیں';

  @override
  String get updateDownloading => 'فائلیں ڈاؤن لوڈ اور تصدیق کی جا رہی ہیں...';

  @override
  String get updateInstalling => 'اپ ڈیٹ کی تیاری ہو رہی ہے یا ایڈمنسٹریٹر کی تصدیق کا انتظار کر رہا ہے...';

  @override
  String get updateNetworkError => 'اپ ڈیٹ ڈاؤن لوڈ نہیں ہو سکا';

  @override
  String get updateReleaseError => 'ریلیز ڈیٹا یا مطلوبہ فائلیں غائب یا غلط ہیں۔';

  @override
  String get updateChecksumError => 'ڈاؤن لوڈ SHA256SUMS سے مماثل نہیں ہے';

  @override
  String get updateInstallError => 'اپ ڈیٹ ختم نہیں ہوا';

  @override
  String get updateUnsupported => 'یہ قابل عمل Sora پیکیج جوڑے کی ملکیت نہیں ہے';

  @override
  String get updateManual =>
      'دونوں تصدیق شدہ پیکیجز کو انسٹال کرنے کے لیے اس کمانڈ کو ٹرمینل میں چلائیں، پھر Sora کو دوبارہ کھولیں۔ فائلیں ڈاؤن لوڈ ڈائرکٹری میں رہتی ہیں۔ VPN کنکشن ختم ہو جائے گا۔';

  @override
  String get updateVersionRevoked => 'ڈویلپر نے یہ ورژن واپس لے لیا ہے';

  @override
  String get updateRolloutPending => 'ایک نیا ورژن بتدریج شروع ہو رہا ہے اور خود بخود آپ کو پیش کیا جائے گا۔';

  @override
  String updateRollbacking(String version) {
    return 'ورژن $version پر واپس جا رہا ہے...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version کی تازہ کاری نے ہیلتھ چیک پاس نہیں کیا، لہذا Sora کو $fromVersion پر واپس کر دیا گیا۔';
  }

  @override
  String get updateRollbackError => 'خودکار رول بیک ناکام ہوگیا';

  @override
  String get updateRollbackCacheError =>
      'موجودہ ورژن کی تصدیق شدہ رول بیک کاپی تیار نہیں کر سکا، اس لیے اپ ڈیٹ انسٹال نہیں ہوا۔';

  @override
  String get updateCopyCommand => 'کمانڈ کاپی کریں۔';

  @override
  String get updateChecksDisabled => 'خودکار چیک سیٹنگز میں غیر فعال ہیں۔';

  @override
  String get updateInstalled => 'اپ ڈیٹ انسٹال ہو گیا';

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
  String get collapseServers => 'سرورز کو سمیٹیں۔';

  @override
  String get expandServers => 'سرورز کو پھیلائیں۔';

  @override
  String get hideDescription => 'تفصیل چھپائیں۔';

  @override
  String get showDescription => 'تفصیل دکھائیں۔';

  @override
  String get errEngineUnsupported => 'منتخب انجن اس پروفائل یا سیٹنگز کو سپورٹ نہیں کرتا ہے';

  @override
  String get errRestore => 'کنکشن کی صفائی نامکمل تھی';

  @override
  String get errSessionEnded => 'یہ سیشن پہلے ہی ختم ہو چکا ہے';

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
      'اگر آپ کو یقین نہیں ہے کہ آپ کے سرور کو کس انجن کی ضرورت ہے تو آٹو کا انتخاب کریں۔ Sora کنیکٹ کرنے سے پہلے پروفائل اور سیٹنگز کو چیک کرتا ہے۔ ایک انجن آپ کے پلان کی بینڈوتھ کو نہیں بڑھا سکتا: کارکردگی کا انحصار سرور، روٹ، پروٹوکول اور نیٹ ورک پر ہوتا ہے۔\n\n## موڈز\n\n### تمام ٹریفک (TUN)\n\nSora ایک ورچوئل نیٹ ورک انٹرفیس بناتا ہے اور اس کے ذریعے ایپلیکیشن ٹریفک کو روٹ کرتا ہے، بشمول TCP اور UDP۔ اس موڈ کو Telegram، گیمز اور Discord آواز کے لیے استعمال کریں۔ قواعد مخصوص سائٹوں یا پروگراموں کو براہ راست بھیج سکتے ہیں یا انہیں بلاک کر سکتے ہیں۔ نیٹ ورک سروس کو اجازت اور سرور کی ضرورت ہے جو مطلوبہ پروٹوکول کو سپورٹ کرتا ہو۔\n\n### System پراکسی\n\nSora ایک مقامی HTTP/SOCKS پراکسی کو ترتیب دیتا ہے۔ وہ ایپلیکیشنز جو سسٹم پراکسی سیٹنگز کا احترام کرتی ہیں اسے استعمال کرتی ہیں۔ ان کے اپنے نیٹ ورک اسٹیک والی درخواستیں براہ راست جڑ سکتی ہیں۔ UDP اور وائس کالز کو عام طور پر TUN کی ضرورت ہوتی ہے۔ یہ موڈ پراکسی سپورٹ والے براؤزرز اور ایپلیکیشنز کے لیے موزوں ہے۔\n\n### کوئی سرور نہیں۔\n\nLinux پر، Sora HTTP/TLS درخواستوں کو تقسیم کرنے اور نئی شکل دینے اور کچھ DPI چیکس کو نظرانداز کرنے کے لیے [zapret](https://github.com/bol-van/zapret) کا استعمال کرتا ہے۔ آپ کا IP وہی رہتا ہے اور کنکشن براہ راست ویب سائٹ پر جاتے ہیں۔ نتائج کا انحصار آپ کے فراہم کنندہ اور بلاک کرنے کے طریقہ پر ہے۔\n\nموجودہ انضمام TCP پر HTTP اور TLS کے لیے tpws استعمال کرتا ہے۔ یہ IP بلاکنگ یا ریلے UDP کو نظرانداز نہیں کرتا ہے، اور Telegram کے MTProto کنکشن کی ضمانت نہیں دے سکتا ہے۔ Discord آواز، Telegram کالز اور اس قسم کی پابندیوں کے لیے TUN کے ساتھ VPN سرور استعمال کریں۔\n\n## انجن\n\n### آٹو\n\nSora ایک انسٹال شدہ انجن کا انتخاب کرتا ہے جو پورے کنکشن پلان کو سپورٹ کرتا ہے: سرور پروٹوکول، ٹرانسپورٹ، گروپس، فریگمنٹیشن اور موڈ۔ موجودہ کنکشن کو روکنے سے پہلے ایک غیر موازن دستی انتخاب کو مسترد کر دیا جاتا ہے۔ آٹو یا دوسرا انجن منتخب کریں اور سیٹنگز کو دوبارہ لاگو کریں۔\n\n### sing-box\n\nنئے Sora پیکیجز میں [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) شامل ہیں، [sing-box](https://github.com/SagerNet/sing-box) کا ایک کانٹا، کلائنٹ سائیڈ XHTTP اور VLESS Encryption شامل کرنا۔ Sora تعمیر اور اس کی صلاحیتوں کو تسلیم کرتا ہے۔ XHTTP کے بغیر اپ اسٹریم کی تعمیر صرف اپنے نام سے یہ صلاحیت حاصل نہیں کرتی ہے۔\n\nمعاون پروٹوکول میں VLESS، VMess، Trojan، Shadowsocks، Hysteria2، TUIC، AnyTLS، WireGuard اور AmneziaWG 1.x/2.x کے وہ پیرامیٹر شامل ہیں جنہیں Sora درآمد کر سکتا ہے۔ مکمل Xray JSON پروفائل کے لیے Xray درکار ہے۔ نئے AWG 3.x فیلڈ ابھی درآمد نہیں کیے جا سکتے۔ sing-box پاس ورڈ سے محفوظ مقامی کنٹرول پورٹ استعمال کرتا ہے، جسے کمپیوٹر کی دوسری ایپلیکیشنز تلاش کر سکتی ہیں۔\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption اور TLS فریگمنٹیشن کو سپورٹ کرتا ہے۔ یہ مکمل فراہم کنندہ Xray پروفائلز کو بھی چلاتا ہے جبکہ ان کی روٹنگ اور گروپس کو محفوظ رکھتا ہے۔ ایسے پروفائلز کو ان کے رویے کو تبدیل کیے بغیر خود بخود دوسرے انجن میں تبدیل نہیں کیا جا سکتا۔\n\nبنڈل شدہ Xray نے اس ترتیب کو ہٹا دیا جو TLS سرٹیفکیٹ کی تصدیق کو غیر فعال کرتی ہے (`allowInsecure`)۔ آٹو sing-box یا mihomo کو اس ترتیب کی ضرورت والے عام سرورز کے لیے منتخب کرتا ہے۔ موجودہ کنکشن کو روکنے سے پہلے Xray کو منتخب کرنا دستی طور پر عدم مطابقت کی اطلاع دیتا ہے۔ پرانے مکمل JSON پروفائلز کو قابل تصدیق سرٹیفکیٹ یا سرٹیفکیٹ پن کے ساتھ ایک اپ ڈیٹ فراہم کنندہ پروفائل کی ضرورت ہے۔\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) آرڈر شدہ فال بیک اور لوڈ بیلنسنگ گروپس، XHTTP اور AmneziaWG کو سپورٹ کرتا ہے۔ اسے منتخب کریں جب بیک اپ سرور میں خودکار طور پر ناکام ہو جائے۔ Sora کی TLS فریگمنٹیشن سیٹنگ اس انجن کے ساتھ دستیاب نہیں ہے۔\n\n## Sora میں مطابقت\n\n| خصوصیت | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN اور TCP/UDP | جی ہاں | جی ہاں | جی ہاں |\n| XHTTP | جی ہاں | جی ہاں | جی ہاں |\n| VLESS Encryption | جی ہاں | جی ہاں | جی ہاں |\n| مکمل Xray پروفائل | نہیں | جی ہاں | نہیں |\n| TUIC / AnyTLS | دونوں | نہیں | TUIC |\n| mieru | نہیں | نہیں | جی ہاں |\n| NaiveProxy | جی ہاں | نہیں | نہیں |\n| TLS فریگمنٹیشن | جی ہاں | جی ہاں | نہیں |\n| AmneziaWG 1.x/2.x | ہاں¹ | نہیں | جی ہاں |\n| حکم دیا فال بیک گروپ | نہیں | No² | جی ہاں |\n\nJ1/J2/J3/Itime والے پروفائلز mihomo استعمال کرتے ہیں؛ ان شعبوں کو کبھی بھی خاموشی سے ضائع نہیں کیا جانا چاہیے۔ ² مکمل Xray پروفائلز کے گروپ کے لیے، ایپ بیک اپ پروفائل کا انتخاب کرتی ہے۔ سپورٹ نصب شدہ تعمیر پر منحصر ہے؛ اس کا ورژن About میں چیک کریں۔\n\n## TUN اسٹیک\n\nاسٹیک ورچوئل انٹرفیس کے اندر TCP اور UDP کو ہینڈل کرتا ہے۔ موڈز پینل میں، Xray اور mihomo gVisor، System، Mixed اور MIPS پیش کرتے ہیں۔ ہر انجن اپنی ترجیح بچاتا ہے۔ System پراکسی اور سرور لیس موڈز اس ترجیح کو استعمال نہیں کرتے ہیں۔\n\n- **Mixed**: TCP سسٹم اسٹیک کا استعمال کرتا ہے، جبکہ gVisor UDP کو ہینڈل کرتا ہے۔ Linux پر یہ mihomo کے لیے ڈیفالٹ ہے۔ Windows پر Xray اور mihomo ڈیفالٹ طور پر MIPS استعمال کرتے ہیں۔\n- **System**: سسٹم اسٹیک استعمال کرتا ہے۔ اگر نیٹ ورک ایپلیکیشنز کو مسائل کا سامنا کرنا پڑتا ہے تو دوسرا آپشن آزمائیں۔\n- **gVisor**: یوزر اسپیس میں ٹریفک کو ہینڈل کرتا ہے۔\n- **MIPS**: mihomo کا اپنا IP اسٹیک، بنڈل ورژن 1.19.32 میں دستیاب ہے۔\n\nLinux پر، Xray اپنے بلٹ ان gVisor کو بطور ڈیفالٹ استعمال کرتا ہے۔ System، Mixed اور MIPS Linux پر mihomo کو TUN انجن کے طور پر استعمال کرتے ہیں، TCP اور UDP کو ایک مستند مقامی SOCKS لنک کے ذریعے Xray کو فارورڈ کرتے ہیں۔ Xray پروٹوکول، فراہم کنندہ پروفائل اور روٹنگ کو برقرار رکھتا ہے۔ ان تینوں اختیارات کے لیے انسٹال mihomo کی ضرورت ہے۔ Windows پر Xray چاروں TUN اسٹیکس کے لیے mihomo 1.19.32 یا نیا ورژن استعمال کرتا ہے۔ پروٹوکول اور روٹنگ Xray میں رہتے ہیں۔ اس امتزاج میں ایپ کے قواعد صرف براہ راست کنکشن اور بلاک کرنے کی حمایت کرتے ہیں؛ Linux پر ان قواعد کے لیے Xray کا بلٹ ان gVisor درکار ہے۔\n\nپل ایک دوسرا عمل چلاتا ہے۔ Linux پر تین بیکار پیمائشوں میں، اس نے مقامی Xray TUN سے تقریباً 32–36 MiB زیادہ جسمانی میموری استعمال کی۔ یہ ڈاؤن لوڈ لوڈ کی پیمائش نہیں کرتا ہے: CPU اور میموری کے اخراجات کنکشن پر منحصر ہیں۔ sing-box میں کوئی اسٹیک سلیکٹر نہیں ہے۔ کوئی اسٹیک ہر نیٹ ورک میں بہتر کارکردگی کی ضمانت نہیں دیتا۔\n\n## ترتیبات کا اطلاق کرنا\n\nسرور منتخب کرنے پر کنکشن خود بخود دوبارہ قائم ہو جاتا ہے۔ موڈ، انجن، DNS یا قواعد میں آپ کی تبدیلیاں مختصر وقفے کے بعد خودکار دوبارہ اتصال کے ساتھ ایک بار لاگو ہوتی ہیں؛ پس منظر کی تازہ کاریاں VPN کو دوبارہ متصل نہیں کرتیں۔ انجن دوبارہ شروع کرنے سے ڈاؤن لوڈز اور کالز میں خلل پڑ سکتا ہے۔\n\nسرنگ گرنے پر صرف VPN کے ذریعے انٹرنیٹ براہ راست ٹریفک کو روکتا ہے۔ یہ پوری مشین کو متاثر کرتا ہے۔ واضح طور پر منقطع ہونا Sora کے قواعد کو ہٹا دیتا ہے۔ اگر کلین اپ ختم نہیں ہوتا ہے تو دوبارہ رابطہ منقطع کرنے کی کوشش کریں اور لاگ کو کھولیں۔\n\n## پروجیکٹ کی دستاویزات\n\n- [sing-box-lx: کنفیگریشن اور سپورٹ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box دستاویزات](https://sing-box.sagernet.org/)\n- [Xray دستاویزات](https://xtls.github.io/)\n- [mihomo دستاویزات](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: آپریشن اور حدود](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC، Jitsi، Yandex Telemost یا WB Stream کی ویڈیو کال کے ذریعے TCP ٹریفک منتقل کرتا ہے۔ olcrtc:// لنک یا QR کوڈ درآمد کریں۔ یہ پراکسی اور TUN موڈ میں sing-box، Xray اور mihomo کے ساتھ کام کرتا ہے؛ UDP کی معاونت نہیں ہے۔ دونوں سروں پر OLC2 کے ہم آہنگ نسخے درکار ہیں۔ اصل منصوبہ آرکائیو کر دیا گیا ہے۔\n';

  @override
  String get probeServers => 'پنگ';

  @override
  String get extensions => 'ایکسٹینشنز';

  @override
  String extRatingLabel(String rating) {
    return 'درجہ بندی $rating از 5';
  }

  @override
  String extByAuthor(String author) {
    return 'بذریعہ $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'تنصیبات: $count';
  }

  @override
  String get extInstallOne => '1 انسٹال کریں۔';

  @override
  String get extSideloadWarning => 'خود دستخط شدہ کلید';

  @override
  String get extPermissionsWidened => 'اپ ڈیٹ نئی اجازتیں مانگتا ہے:';

  @override
  String get extInstall => 'انسٹال کریں۔';

  @override
  String get extUpdate => 'اپ ڈیٹ کریں';

  @override
  String get extCancel => 'منسوخ کریں۔';

  @override
  String get extConfirm => 'تصدیق کریں۔';

  @override
  String get extCatalog => 'کیٹلاگ';

  @override
  String get extInstalled => 'انسٹال شدہ ایکسٹینشنز';

  @override
  String get extSearchHint => 'ایکسٹینشنز تلاش کریں';

  @override
  String get extCatAll => 'سبھی';

  @override
  String get extCatTools => 'ٹولز';

  @override
  String get extCatThemes => 'تھیمز';

  @override
  String get extCatAutomation => 'آٹومیشن';

  @override
  String get extCatStats => 'شماریات';

  @override
  String get extCatNetwork => 'نیٹ ورک';

  @override
  String get extSortBy => 'ترتیب دیں';

  @override
  String get extSortPopular => 'سب سے زیادہ مقبول';

  @override
  String get extSortRating => 'سب سے زیادہ درجہ بندی';

  @override
  String get extSortName => 'نام';

  @override
  String get extCatalogError => 'کیٹلاگ لوڈ نہیں ہو سکا';

  @override
  String get extRetry => 'دوبارہ کوشش کریں۔';

  @override
  String get extEmptySearch => 'کچھ نہیں ملا';

  @override
  String get extEmptyInstalled => 'ابھی تک کوئی ایکسٹینشن انسٹال نہیں ہے';

  @override
  String get extInstallFromFile => 'فائل سے انسٹال کریں۔';

  @override
  String get extInstallFromUrl => 'URL سے انسٹال کریں';

  @override
  String get extDownload => 'ڈاؤن لوڈ کریں۔';

  @override
  String get extDownloading => 'ڈاؤن لوڈ ہو رہا ہے…';

  @override
  String get extVerifying => 'تصدیق ہو رہی ہے…';

  @override
  String get extInstalling => 'انسٹال ہو رہا ہے…';

  @override
  String get extErrSignature => 'دستخطی چیک ناکام ہو گیا';

  @override
  String get extErrManifest => 'ایکسٹینشن مینی فیسٹ غلط ہے۔';

  @override
  String get extErrNetwork => 'نیٹ ورک کی خرابی';

  @override
  String get extErrHash => 'ڈاؤن لوڈ کیٹلاگ سے میل نہیں کھاتا';

  @override
  String extErrMinApp(String version) {
    return 'اس ایکسٹینشن کو ایپ ورژن کی ضرورت ہے $version یا جدید تر۔';
  }

  @override
  String get extErrHttpsOnly => 'صرف https:// لنکس کی اجازت ہے۔';

  @override
  String get extErrGeneric => 'کچھ غلط ہو گیا';

  @override
  String get extErrAuthorKeyChanged =>
      'اس اپ ڈیٹ پر انسٹال شدہ ورژن سے مختلف مصنف کی کلید کے ساتھ دستخط کیے گئے ہیں، اس لیے اسے بلاک کر دیا گیا تھا';

  @override
  String get extDisabled => 'غیر فعال';

  @override
  String extToggleEnabled(String name) {
    return 'فعال کریں $name';
  }

  @override
  String get extSearchInstalled => 'نصب شدہ ایکسٹینشنز تلاش کریں';

  @override
  String get extUpdateAll => 'سبھی کو اپ ڈیٹ کریں۔';

  @override
  String extUpdatesAvailable(int count) {
    return '$count اپ ڈیٹس دستیاب ہیں۔';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count اپ ڈیٹ ہو گیا۔';
  }

  @override
  String get extRiskNormal => 'نارمل';

  @override
  String get extRiskSensitive => 'حساس';

  @override
  String get extRiskDangerous => 'زیادہ خطرہ';

  @override
  String get extPermissionsRemoved => 'مزید درخواست نہیں کی گئی:';

  @override
  String get extUpdateFailedKept => 'پچھلا ورژن اب بھی انسٹال ہے۔';

  @override
  String get extConflictsTitle => 'توسیع کے تنازعات';

  @override
  String get extConflictTheme => 'ایپ تھیم';

  @override
  String get extConflictNetHooks => 'نیٹ ورک ہکس';

  @override
  String extConflictWinner(String name) {
    return 'ترجیح: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'توسیع کے تنازعات: $count';
  }

  @override
  String get extConflictsResolve => 'تنازعات کو حل کریں۔';

  @override
  String extVersionLabel(String version) {
    return 'ورژن $version';
  }

  @override
  String get extPermissionsTitle => 'اجازتیں۔';

  @override
  String get extNoPermissions => 'کوئی خاص اجازت نہیں ہے۔';

  @override
  String get extSettings => 'ترتیبات';

  @override
  String get extSaveSettings => 'ترتیبات کو محفوظ کریں۔';

  @override
  String extUpdateTo(String version) {
    return '$version میں اپ گریڈ کریں';
  }

  @override
  String get extEnabled => 'فعال';

  @override
  String extRollbackTo(String version) {
    return '$version پر رول بیک';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'ورژن $version پر رول بیک؟';
  }

  @override
  String get extUninstall => 'ان انسٹال کریں۔';

  @override
  String extUninstallConfirm(String name) {
    return '\"$name\" اور اس کی ترتیبات کو ہٹائیں؟';
  }

  @override
  String get extPanelUnavailable => 'ایکسٹینشن پینل دستیاب نہیں ہے۔';

  @override
  String get extPermConnectionsRead => 'فعال رابطوں کی فہرست دیکھیں';

  @override
  String get extPermServersRead => 'اپنے سرورز کی فہرست دیکھیں';

  @override
  String get extPermSettingsRead => 'ایپ کی ترتیبات پڑھیں';

  @override
  String get extPermSettingsWrite => 'ایپ کی ترتیبات تبدیل کریں۔';

  @override
  String get extPermNotifications => 'اطلاعات دکھائیں۔';

  @override
  String get extPermTray => 'ٹرے مینو میں آئٹمز شامل کریں۔';

  @override
  String get extPermUiPanel => 'ایپ کے اندر پینلز دکھائیں۔';

  @override
  String get extPermThemeApply => 'تھیمز کا اطلاق کریں۔';

  @override
  String get extPermRoutingRules => 'روٹنگ کے اصول شامل کریں';

  @override
  String get extPermNetHooks => 'نیٹ ورک پاتھ میں ضم کریں';

  @override
  String get extPermNetFetch => 'URL کی اجازت دی گئی فہرست سے درخواست کریں۔';

  @override
  String get extPermBackground => 'پس منظر کے کام چلائیں۔';

  @override
  String get extPermNotYetActive => 'غیر فعال';

  @override
  String get extCapBackground => 'پس منظر میں چلتا ہے۔';

  @override
  String get extCapNetHook => 'پابندی سے بچاؤ اور نیٹ ورک ہکس';

  @override
  String get extCapPanel => 'انٹرفیس پینلز';

  @override
  String get extCapRouting => 'روٹنگ کے اصول';

  @override
  String get extCapTheme => 'تھیمز';

  @override
  String get extCapWidget => 'وجیٹس';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'چینج لاگ';

  @override
  String get extImageFailed => 'تصویر کو لوڈ نہیں کیا جا سکا';

  @override
  String get extScreenshots => 'اسکرین شاٹس';

  @override
  String get extSortRelevance => 'مطابقت';

  @override
  String get extBgTitle => 'پس منظر کا کام';

  @override
  String get extBgEnabled => 'پس منظر میں چلائیں۔';

  @override
  String get extBgInterval => 'چلانے کا وقفہ';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count منٹ', one: '$count منٹ');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count گھنٹے', one: '$count گھنٹہ');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'نیٹ ورک تک رسائی';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'نیٹ ورک: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'فائل میں $name';
  }

  @override
  String get diagnosticHttp => 'HTTP تشخیص';

  @override
  String get diagnosticNoData => 'ابھی تک کوئی ریکارڈ شدہ درخواستیں نہیں ہیں';

  @override
  String get qrShareTitle => 'شیئر کریں QR کوڈ';

  @override
  String get qrScanTitle => 'اسکین کریں QR کوڈ';

  @override
  String get qrCopyLink => 'لنک کاپی کریں۔';

  @override
  String get qrWarning => 'یہ کوڈ صرف قابل اعتماد لوگوں کو دکھائیں۔';

  @override
  String get qrFromClipboard => 'کلپ بورڈ سے پیسٹ کریں۔';

  @override
  String get qrNoCode => 'اس تصویر میں کوئی QR کوڈ نہیں ملا۔';

  @override
  String get qrInvalid => 'اس QR کوڈ میں درست لنک نہیں ہے۔';

  @override
  String get qrScan => 'اسکین QR';

  @override
  String get qrFromImage => 'تصویر کھولیں';

  @override
  String get connGroupByProcess => 'عمل کے لحاظ سے گروپ کریں۔';

  @override
  String get connListView => 'فہرست';

  @override
  String get connCopyHost => 'میزبان کاپی کریں۔';

  @override
  String get connAddRule => 'اصول شامل کریں۔';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count کنکشن', one: '$count کنکشن');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'پیش سیٹ';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'ذاتی';

  @override
  String get dnsCheck => 'ڈیٹا لیک کی جانچ کریں۔';

  @override
  String get dnsChecking => 'چیک ہو رہا ہے...';

  @override
  String get dnsNoLeak => 'کوئی لیک نہیں ملا';

  @override
  String get dnsLeakFound => 'لیک کا پتہ چلا';

  @override
  String get dnsLastCheck => 'آخری چیک';

  @override
  String get dnsNeverChecked => 'ابھی تک ٹیسٹ نہیں کیا گیا۔';

  @override
  String get dnsLeakCheckTunnelDns => 'ٹنل کے DNS ریزولورز';

  @override
  String get dnsLeakCheckSystemResolvers => 'سسٹم ریزولورز';

  @override
  String get dnsLeakCheckKillSwitchDns => 'نیٹ ورک بندش سے DNS کا تحفظ';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'اوپر دی گئی DNS ترتیبات میں سرنگ کے لئے DNS کو ترتیب دیں۔';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'چیک کریں کہ آپ کا سسٹم سرنگ کے باہر کون سے ریزولورز استعمال کرے گا۔';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS ٹریفک کو ٹنل کے اندر رکھنے کے لیے نیٹ ورک بندش فعال کریں۔';

  @override
  String get dnsLeakCheckEncryptedDns => 'سسٹم کا خفیہ کردہ DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'جعلی DNS جوابات';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'چیک کریں کہ کون سے خفیہ کردہ DNS اینڈ پوائنٹس کو آپ کا سسٹم ٹنل کے باہر استعمال کرتا ہے۔';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'ٹنل کے لیے خفیہ کردہ DNS (DoT یا DoH) استعمال کریں تاکہ ریزولورز جعلی جواب نہ دے سکیں۔';

  @override
  String get dnsCheckNeedsConnection => 'پہلے VPN سے جڑیں، پھر لیک کی جانچ کریں۔';

  @override
  String get dnsExpected => 'متوقع';

  @override
  String get dnsActual => 'مشاہدہ کیا گیا۔';

  @override
  String get measureSpeed => 'رفتار کی پیمائش کریں۔';

  @override
  String get benchmarkStale => 'پرانا';

  @override
  String get autoSelectMode => 'سرور کو خودکار طور پر منتخب کریں۔';

  @override
  String get autoSelectPing => 'تیز ترین پنگ';

  @override
  String get autoSelectSpeed => 'تیز ترین رفتار';

  @override
  String get autoSelectSmart => 'سمارٹ انتخاب';

  @override
  String get coreWatchUnstable => 'کور سے رابطہ غیر مستحکم ہے';

  @override
  String get watchReconnect => 'دوبارہ جڑیں۔';

  @override
  String get crashRestoreTitle => 'آخری سیشن میں خلل پڑا تھا۔';

  @override
  String get restoreOnCrash => 'کریش کے بعد سیشن بحال کریں۔';

  @override
  String get crashRestore => 'بحال کریں۔';

  @override
  String get crashDismiss => 'ابھی نہیں۔';

  @override
  String get overrideTitle => 'میری ترامیم';

  @override
  String get overrideEdit => 'سرورز میں ترمیم کریں۔';

  @override
  String get overrideHide => 'چھپائیں۔';

  @override
  String get overrideUnhide => 'دکھائیں۔';

  @override
  String get overrideClear => 'ترامیم کو دوبارہ ترتیب دیں۔';

  @override
  String get overrideEmpty => 'ابھی تک کوئی ترمیم نہیں۔';

  @override
  String get overrideCustomRules => 'اپنے اصول';

  @override
  String get errBenchmarkUnsupported => 'رفتار کی پیمائش کے لیے کور کا نیا ورژن درکار ہے';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total سے $done کی پیمائش…';
  }

  @override
  String get profiles => 'نیٹ ورک پروفائلز';

  @override
  String get profilesEmpty => 'ابھی تک کوئی پروفائل نہیں ہے';

  @override
  String get profileAdd => 'پروفائل شامل کریں۔';

  @override
  String get profileName => 'پروفائل کا نام';

  @override
  String get profileSsids => 'Wi-Fi نیٹ ورکس (SSID)';

  @override
  String get profileGateways => 'نیٹ ورک گیٹ ویز';

  @override
  String get profileAsns => 'AS نمبرز';

  @override
  String get profileAutoApply => 'خود بخود لاگو کریں';

  @override
  String get profileSnapshot => 'موجودہ ترتیبات کو یاد رکھیں';

  @override
  String get profileSnapshotDone => 'موجودہ ترتیبات کو پروفائل میں محفوظ کیا گیا۔';

  @override
  String get profileDelete => 'پروفائل حذف کریں۔';

  @override
  String profileDeleteConfirm(Object name) {
    return 'پروفائل \"$name\" کو حذف کریں؟';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'پروفائل \"$name\" کا اطلاق کریں؟';
  }

  @override
  String get profileApply => 'لاگو کریں';

  @override
  String profileApplied(Object name) {
    return 'پروفائل \"$name\" لاگو کیا گیا۔';
  }

  @override
  String get profileUndo => 'منسوخ کریں۔';

  @override
  String get profileActive => 'فعال';

  @override
  String networkNow(Object info) {
    return 'ابھی: $info';
  }

  @override
  String get networkUnknown => 'نیٹ ورک کی معلومات دستیاب نہیں ہے۔';

  @override
  String get profileNoTriggers => 'پروفائل کی شرائط موجود نہیں';

  @override
  String get chains => 'پراکسی چینز';

  @override
  String get chainsEmpty => 'ابھی تک کوئی زنجیر نہیں ہے';

  @override
  String get chainAdd => 'نیا سلسلہ';

  @override
  String get chainName => 'سلسلہ کا نام';

  @override
  String get chainTooFew => 'چین کے لیے کم از کم دو سرور درکار ہیں';

  @override
  String get chainTooMany => 'چین میں زیادہ سے زیادہ تین سرور ہو سکتے ہیں';

  @override
  String get chainEstimate => 'تخمینی تاخیر';

  @override
  String get chainSave => 'سیو چین';

  @override
  String get chainDelete => 'سلسلہ حذف کریں۔';

  @override
  String chainDeleteConfirm(Object name) {
    return 'چین \"$name\" کو حذف کریں؟';
  }

  @override
  String get chainUnsupported => 'منتخب انجن سرور چین کی سہولت نہیں دیتا';

  @override
  String get chainHopMissing => 'چین کا ایک سرور اب دستیاب نہیں';

  @override
  String chainHop(Object n) {
    return 'ہاپ $n';
  }

  @override
  String get chainEntry => 'داخلہ';

  @override
  String get chainExit => 'اخراج';

  @override
  String get sync => 'ڈیوائس کی مطابقت پذیری';

  @override
  String get syncDevices => 'میرے آلات';

  @override
  String get syncEmpty => 'کوئی جوڑا بنائے گئے آلات نہیں ہیں';

  @override
  String get syncPair => 'ڈیوائس جوڑیں';

  @override
  String get syncShowCode => 'میرا کوڈ دکھائیں۔';

  @override
  String get syncScanCode => 'کوڈ اسکین کریں۔';

  @override
  String get syncRevoke => 'واپس لینا';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" کو منسوخ کریں؟';
  }

  @override
  String syncLastSync(Object time) {
    return 'آخری مطابقت پذیری: $time';
  }

  @override
  String get syncNever => 'کبھی نہیں۔';

  @override
  String get syncPaired => 'ڈیوائس کا جوڑا بنایا گیا۔';

  @override
  String get syncPairingTitle => 'اس آلہ کے ساتھ جوڑا بنائیں';

  @override
  String get syncWaiting => 'دوسرے آلے کا انتظار کر رہا ہے…';

  @override
  String get zapretWithVpn => 'بائی پاس DPI فلٹرنگ';

  @override
  String get chainDuplicate => 'چین میں ایک سرور دہرایا گیا ہے';

  @override
  String get edit => 'ترمیم کریں۔';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get autoSwitchOnDegrade => 'انحطاط پر آٹو سوئچ';

  @override
  String get tunStackMixed => 'مخلوط';

  @override
  String get tunStackSystem => 'سسٹم';

  @override
  String get customServerAdd => 'حسب ضرورت سرور شامل کریں۔';

  @override
  String get customServers => 'میرے سرورز';

  @override
  String get customServerName => 'نام';

  @override
  String get customServerNameRequired => 'نام درج نہیں';

  @override
  String get customServerAddress => 'پتہ';

  @override
  String get customServerAddressRequired => 'پتہ درج نہیں';

  @override
  String get customServerAddressInvalid => 'غلط پتہ';

  @override
  String get customServerPort => 'پورٹ';

  @override
  String get customServerPortInvalid => 'غلط پورٹ';

  @override
  String get customServerProtocol => 'پروٹوکول';

  @override
  String get customServerCredentials => 'لاگ ان کی معلومات';

  @override
  String get customServerShowSecret => 'راز دکھائیں۔';

  @override
  String get customServerHideSecret => 'راز چھپائیں۔';

  @override
  String customServerDeleteConfirm(String name) {
    return 'سرور \"$name\" کو حذف کریں؟';
  }

  @override
  String get leakTestTitle => 'ڈیٹا لیک کے لیے ٹیسٹ';

  @override
  String get leakTestRun => 'چیک کریں۔';

  @override
  String get leakTestCancel => 'منسوخ کریں۔';

  @override
  String get leakTestNeedsConnection => 'لیک ٹیسٹ چلانے کے لیے جڑیں۔';

  @override
  String leakTestProgress(int count) {
    return 'ٹیسٹ مکمل ہوئے: $count';
  }

  @override
  String get leakTestAllClear => 'کوئی لیک نہیں ملا';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count لیک ملے', one: '$count لیک ملا');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'درست کریں۔';

  @override
  String get leakTestFixedNote => 'نیٹ ورک بندش فعال ہے۔ تصدیق کے لیے دوبارہ ٹیسٹ چلائیں۔';

  @override
  String get leakTestCheckDirectDns => 'براہ راست DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP بازگشت';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'سسٹم ریزولورز';

  @override
  String get leakTestCheckTunnelConnectivity => 'ٹنل کنیکٹیویٹی';

  @override
  String get leakTestCheckTunnelDns => 'DNS سرنگ کے ذریعے';

  @override
  String get noticeDegraded => 'سرور سست ہو گیا۔ Sora پیمائش کے دوران پائے جانے والے بہترین سرور پر تبدیل ہو گیا۔';

  @override
  String get obfs => 'ٹریفک چھپانا';

  @override
  String get syncCodeExpired => 'کوڈ کی میعاد ختم ہو گئی ہے۔';

  @override
  String get syncDaemonFailed => 'مطابقت پذیری سروس شروع نہیں کی جا سکی';

  @override
  String get syncDaemonMissing => 'sora-sync جزو نہیں ملا';

  @override
  String get syncDaemonStarting => 'مطابقت پذیری سروس شروع ہو رہی ہے…';

  @override
  String get syncErrAuth => 'مطابقت پذیری سروس نے رسائی ٹوکن کو مسترد کر دیا';

  @override
  String get syncErrNotFound => 'آلہ اب جوڑا نہیں ہے۔';

  @override
  String get syncErrPairingActive => 'جوڑا بنانے کا سیشن پہلے ہی کھلا ہوا ہے۔';

  @override
  String get syncErrUnreachable => 'دوسرے آلے نے جواب نہیں دیا';

  @override
  String get syncError => 'مطابقت پذیری کی خرابی۔';

  @override
  String syncExpiresIn(String duration) {
    return 'کوڈ $duration بعد ختم ہوگا';
  }

  @override
  String get syncJoining => 'آلہ کے ساتھ جوڑا بنایا جا رہا ہے…';

  @override
  String get syncNewCode => 'نیا کوڈ';

  @override
  String syncPairedWith(String name) {
    return '$name کے ساتھ جوڑا بنایا';
  }

  @override
  String get syncRetry => 'دہرائیں۔';

  @override
  String get syncStopShowing => 'کوڈ چھپائیں';

  @override
  String get syncSyncNow => 'ابھی ہم آہنگ کریں';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'موصول ہوا $pulled، بھیجا گیا $pushed';
  }

  @override
  String get syncResultTitle => 'مطابقت پذیری کا نتیجہ';

  @override
  String get syncPulled => 'موصول ہوا۔';

  @override
  String get syncPushed => 'بھیجا گیا۔';

  @override
  String get syncNoChanges => 'کوئی تبدیلی نہیں ملی';

  @override
  String get syncDocKindSubscriptions => 'رکنیتیں';

  @override
  String get syncDocKindSettings => 'ایپ کی ترتیبات';

  @override
  String get syncDocKindOverrides => 'رکنیت کی ذاتی تبدیلیاں';

  @override
  String get syncDocKindProfiles => 'نیٹ ورک پروفائلز';

  @override
  String get syncDocKindChains => 'پراکسی چینز';

  @override
  String syncFrom(String name) {
    return '$name سے';
  }

  @override
  String get syncThisDevice => 'یہ آلہ';

  @override
  String get syncUnavailableAndroid => 'Android پر مطابقت پذیری دستیاب نہیں';

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
  String get extErrRevoked => 'Sora ٹیم نے یہ ایکسٹینشن ورژن واپس لے لیا ہے کیونکہ یہ غیر محفوظ یا خراب ہے۔';

  @override
  String get extErrRevocationsExpired => 'منسوخ ایکسٹینشنز کی فہرست اپ ڈیٹ ہونے تک انسٹالیشن مسدود ہے۔';

  @override
  String extRevokedDisabled(String names) {
    return 'واپس لیے گئے ایکسٹینشنز بند کر دیے گئے: $names';
  }

  @override
  String get customServerWgPrivateKey => 'نجی کلید';

  @override
  String get customServerWgAddresses => 'انٹرفیس پتے';

  @override
  String get customServerWgPeerKey => 'سرور کی عوامی کلید';

  @override
  String get customServerWgPresharedKey => 'پہلے سے مشترکہ کلید';

  @override
  String get customServerWgAllowedIps => 'اجازت یافتہ IP';

  @override
  String get customServerWgKeepalive => 'Keepalive، سیکنڈ';

  @override
  String get customServerWgKeyInvalid => 'غلط WireGuard کلید';

  @override
  String get customServerWgCidrInvalid => 'غلط CIDR سابقہ';

  @override
  String get customServerWgKeepaliveInvalid => 'غلط keepalive وقفہ';

  @override
  String get strictKillSwitch => 'سخت نیٹ ورک بندش';

  @override
  String get strictKillSwitchWarning => 'باہر نکلنے کے بعد VPN سے باہر کی ٹریفک بند رکھیں؟';

  @override
  String get extWorkerFailed => 'ایکسٹینشن کا پس منظر کا کام ناکام ہوگیا';

  @override
  String get extAssetRejected => 'ایکسٹینشن کی فائل میں ایسے رنگ ہیں جن سے پڑھنا مشکل ہے یا اصول درست نہیں';

  @override
  String get extVerifiedSora => 'Sora سے تصدیق شدہ';

  @override
  String extReceivedBytes(String count) {
    return '$count بائٹس';
  }

  @override
  String get extOpen => 'کھولیں';

  @override
  String get customServerOwn => 'ذاتی سرور';

  @override
  String get customServerPaste => 'لنک پیسٹ کریں';

  @override
  String get customServerUser => 'صارف کا نام';

  @override
  String get customServerPassword => 'پاس ورڈ';

  @override
  String get customServerSecretRequired => 'قدر درج نہیں';

  @override
  String get customServerLinkInvalid => 'سرور کا لنک درست نہیں';

  @override
  String get errInternal => 'Sora میں اندرونی خرابی';

  @override
  String get errTls => 'سرور کا سرٹیفکیٹ مسترد ہو گیا';

  @override
  String get errFileAccess => 'فائل تک رسائی نہیں';

  @override
  String get errDataLimit => 'ڈیٹا بہت زیادہ ہے';

  @override
  String get errCredentials => 'محفوظ لاگ ان معلومات موجود نہیں';

  @override
  String subscriptionStale(String time) {
    return 'آخری اپ ڈیٹ: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'ابھی اپ ڈیٹ نہیں ہوا';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'سرور نے HTTP $status کوڈ واپس کیا',
      zero: 'سرور نے درخواست مسترد کر دی',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'سرور کی ترتیبات نامکمل یا غیر معاون ہیں';

  @override
  String get errServerIds => 'دو سروروں کا شناخت کنندہ ایک ہے';

  @override
  String get errRoutingGroup => 'راستہ غیر موجود سروروں یا خراب گروپ کی طرف ہے';

  @override
  String get errConnections => 'کنکشن کی فہرست دستیاب نہیں';

  @override
  String get errLogs => 'یہ سروس لاگ نہیں رکھتی';

  @override
  String get errDiagnostics => 'تشخیص جمع نہیں ہو سکی';

  @override
  String get errMissingItem => 'مطلوبہ آئٹم اب موجود نہیں';

  @override
  String get errInvalidRequest => 'درخواست میں غلط قدریں ہیں';

  @override
  String get errProxyLogin => 'سسٹم پراکسی اس لاگ ان کی معاونت نہیں کرتی';

  @override
  String get errLogFilter => 'لاگ فلٹر غلط ہے';

  @override
  String get errSubRedirect => 'سرور نے غیر محفوظ پتے پر بھیج دیا';

  @override
  String get errProxySetup => 'سسٹم پراکسی ترتیب نہیں دی جا سکی';

  @override
  String get notificationsToday => 'آج';

  @override
  String get notificationsYesterday => 'کل';

  @override
  String get notificationsMarkRead => 'سب کو پڑھا ہوا نشان لگائیں';

  @override
  String get notificationsUnread => 'بغیر پڑھا ہوا';

  @override
  String get desktopNotifications => 'ڈیسک ٹاپ اطلاعات';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'سبسکرپشن اپ ڈیٹ کرنے کا وقفہ درست نہیں';

  @override
  String get errRule => 'روٹنگ کا ایک اصول درست نہیں';

  @override
  String get errDns => 'DNS کی ترتیبات درست نہیں';

  @override
  String get errEndpoint => 'جانچ کے لیے سرور کا پتہ درست نہیں';

  @override
  String get errCancelled => 'درخواست منسوخ ہو گئی';

  @override
  String get customServerOptions => 'کنکشن کی ترتیبات';

  @override
  String get customServerTransport => 'ٹرانسپورٹ';

  @override
  String get customServerSecurity => 'سیکیورٹی';

  @override
  String get customServerCipher => 'خفیہ کاری';

  @override
  String get customServerWgInterface => 'انٹرفیس';

  @override
  String get customServerWgPeer => 'پیئر';

  @override
  String extAvailableOn(String platforms) {
    return 'ان پلیٹ فارمز پر دستیاب: $platforms۔';
  }

  @override
  String get winwsScopeWarning => 'تمام ایپس کی TCP ٹریفک تبدیل کریں؟';

  @override
  String get winwsRequirements => 'یہ VPN موڈ دستیاب نہیں';

  @override
  String get emptyServersTitle => 'سرور یا سبسکرپشن شامل کریں';

  @override
  String get emptyServersBody => 'اپنی VPN سروس کا سبسکرپشن لنک چسپاں کریں، اپنا سرور شامل کریں یا QR کوڈ اسکین کریں۔';

  @override
  String get qrShort => 'QR کوڈ';

  @override
  String get extAboutHello => 'مثالی پینل: فعال کنکشن دکھاتا ہے اور آزمائشی اطلاع بھیجتا ہے۔';

  @override
  String get extAboutZapret =>
      'VPN کے بغیر پابندیوں سے بچاؤ: کنکشن کا آغاز بدلتا ہے تاکہ فراہم کنندہ سائٹ نہ پہچانے۔ «بغیر سرور» موڈ میں کام کرتا ہے۔';

  @override
  String get extAboutByedpi =>
      'مقامی ByeDPI پراکسی کے ذریعے VPN کے بغیر پابندیوں سے بچاؤ۔ «بغیر سرور» موڈ میں کام کرتا ہے۔';

  @override
  String get modeTunHint => 'کمپیوٹر کا سارا ٹریفک VPN سے گزرتا ہے';

  @override
  String get modeProxyHint => 'صرف وہ براؤزر اور ایپس جو سسٹم پراکسی استعمال کرتی ہیں';

  @override
  String get modeBypassHint => 'VPN سرور کے بغیر پابندیوں سے بچاؤ';

  @override
  String get modeExtensionHint => 'ایکسٹینشن سے پابندیوں سے بچاؤ';

  @override
  String get engineInfo =>
      'انجن سرور سے کنکشن بناتا ہے۔\n\nخودکار: Sora خود ایسا انجن چنتا ہے جو سرور کا پروٹوکول سپورٹ کرے۔\nsing-box: تیز اور ہمہ گیر۔\nXray: REALITY اور XHTTP والے VLESS کے لیے بہترین۔\nmihomo: Clash سبسکرپشنز اور لچکدار اصول۔\n\nانجن صرف تب بدلیں جب سرور خودکار پر نہ جڑے۔';

  @override
  String get tunStackInfo =>
      'ٹریفک سسٹم سے VPN تک کیسے پہنچتا ہے۔\n\nسسٹم: سب سے تیز، OS نیٹ ورک اسٹیک سے۔\ngVisor: اپنا اسٹیک، زیادہ تر ایپس کے ساتھ ہم آہنگ۔\nملا جلا: TCP سسٹم سے، UDP ‏gVisor سے۔\n\nاگر سائٹیں یا گیمز ٹھیک نہ چلیں تو دوسرا اسٹیک آزمائیں۔';

  @override
  String get protection => 'حفاظت';

  @override
  String get killSwitchInfo =>
      'اگر VPN منقطع ہو جائے تو Sora انٹرنیٹ بند کر دیتا ہے تاکہ ٹریفک سرنگ سے باہر نہ جائے۔ دوبارہ جڑنے یا VPN بند کرنے پر رسائی واپس آتی ہے۔';

  @override
  String get strictKillSwitchInfo =>
      'یہ بندش Sora سے باہر نکلنے اور ری اسٹارٹ کے بعد بھی رہتی ہے، جب تک آپ اسے یہاں بند نہ کریں۔';

  @override
  String get zapretWithVpnInfo =>
      'جو سائٹیں اصولوں کے مطابق VPN سے باہر جاتی ہیں انہیں Zapret سے پابندیوں سے بچاؤ ملتا ہے۔';

  @override
  String get failoverInfo => 'اگر سرور جواب دینا بند کر دے تو Sora خود اگلے کام کرنے والے سرور پر چلا جاتا ہے۔';

  @override
  String get ipv6Info => 'IPv6 کو VPN سے بھیجیں۔ اگر سرور IPv6 سپورٹ نہیں کرتا اور سائٹیں آہستہ کھلتی ہیں تو بند کریں۔';

  @override
  String get fragmentInfo =>
      'TLS کنکشن کے آغاز کو ٹکڑوں میں بانٹتا ہے تاکہ فراہم کنندہ کا فلٹر سائٹ کا نام نہ دیکھے۔ SNI سے بلاک ہونے پر مدد کرتا ہے۔';

  @override
  String get splitPosInfo =>
      'پہلا پیکٹ کہاں سے کاٹنا ہے: بائٹ نمبر یا نشان جیسے midsld (ڈومین کا درمیان)۔ کئی قدریں کوما سے الگ کریں۔';

  @override
  String get disorderInfo => 'پیکٹ کے حصے الٹی ترتیب میں بھیجتا ہے تاکہ ترتیب سے جوڑنے والے فلٹر الجھ جائیں۔';

  @override
  String get tlsRecordInfo => 'TLS سلام کو کئی ریکارڈز میں بانٹتا ہے تاکہ سائٹ کا نام ایک ریکارڈ میں پورا نہ ہو۔';

  @override
  String get hostCaseInfo =>
      'HTTP درخواستوں میں Host ہیڈر کے حروف کی شکل بدلتا ہے (Host → hoSt) تاکہ پرانے فلٹر درخواست نہ پہچانیں۔';

  @override
  String get probeMethodInfo =>
      'انجن کے ذریعے: سرور سے کسی سائٹ تک اصل تاخیر، سب سے درست۔\nصرف کنکشن: سرور سے صرف TCP کنکشن، تیز مگر VPN کو نہیں جانچتا۔\nTLS ہینڈ شیک: سرور کے ساتھ TCP اور TLS۔\nICMP: عام ping، کچھ سرور جواب نہیں دیتے۔\nخودکار: انجن کے ذریعے، جہاں ممکن نہ ہو وہاں کنکشن۔';

  @override
  String get autoSelectInfo => '«سب سے تیز» سرور کیسے چنتا ہے: ping سے، ناپی گئی رفتار سے یا دونوں سے۔';

  @override
  String get autoSwitchInfo => 'اگر موجودہ سرور واضح طور پر سست ہو جائے تو Sora تیز سرور پر چلا جاتا ہے۔';

  @override
  String get probeTls => 'TLS ہینڈ شیک';

  @override
  String get probeIcmp => 'ICMP (ping)';
}
