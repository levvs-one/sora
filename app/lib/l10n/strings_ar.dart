// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SAr extends S {
  SAr([String locale = 'ar']) : super(locale);

  @override
  String get stateOff => 'غير متصل';

  @override
  String get stateConnecting => 'الاتصال';

  @override
  String get stateConnected => 'متصل';

  @override
  String get stateReconnecting => 'إعادة الاتصال';

  @override
  String get stateDisconnecting => 'قطع الاتصال';

  @override
  String get stateFailed => 'غير متصل';

  @override
  String get coreMissing => 'خدمة Sora لا تستجيب';

  @override
  String get serverAuto => 'الأسرع';

  @override
  String get serverBypass => 'لا يوجد خادم';

  @override
  String get addSubscription => 'إضافة الاشتراك';

  @override
  String get servers => 'الخوادم';

  @override
  String get settings => 'إعدادات';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get subscriptionLink => 'رابط الاشتراك';

  @override
  String get add => 'يضيف';

  @override
  String get refresh => 'تحديث';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get delete => 'يمسح';

  @override
  String get cancel => 'يلغي';

  @override
  String get save => 'يحفظ';

  @override
  String get name => 'اسم';

  @override
  String deleteSubscription(String name) {
    return 'هل تريد حذف \"$name\"؟';
  }

  @override
  String get routes => 'الطرق';

  @override
  String get presetGlobal => 'كل شيء من خلال VPN';

  @override
  String get presetRu => 'روسيا مباشرة';

  @override
  String get presetIr => 'إيران مباشرة';

  @override
  String get presetCn => 'الصين مباشرة';

  @override
  String get blockAds => 'منع الإعلانات';

  @override
  String get killSwitch => 'الإنترنت فقط من خلال VPN';

  @override
  String get engine => 'محرك';

  @override
  String get engineAuto => 'آلي';

  @override
  String get animations => 'الرسوم المتحركة';

  @override
  String get logs => 'سجل';

  @override
  String get about => 'عن';

  @override
  String get logsAll => 'الجميع';

  @override
  String get logsImportant => 'مهم';

  @override
  String get logsErrors => 'أخطاء';

  @override
  String get search => 'يبحث';

  @override
  String get export => 'حفظ إلى ملف';

  @override
  String get clear => 'واضح';

  @override
  String get logsEmpty => 'لا شيء هنا';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get notInstalled => 'غير مثبت';

  @override
  String get sourceCode => 'كود المصدر';

  @override
  String get license => 'رخصة';

  @override
  String usage(String used, String total) {
    return '$used من $total';
  }

  @override
  String until(String date) {
    return 'حتى $date';
  }

  @override
  String get expired => 'منتهي الصلاحية';

  @override
  String milliseconds(int n) {
    return '$n مللي';
  }

  @override
  String speedMbps(double value) {
    return '${value.toStringAsFixed(1)} Mbps';
  }

  @override
  String bytesB(String n) {
    return '$n ب';
  }

  @override
  String bytesKB(String n) {
    return '$n كيلوبايت';
  }

  @override
  String bytesMB(String n) {
    return '$n ميغابايت';
  }

  @override
  String bytesGB(String n) {
    return '$n جيجابايت';
  }

  @override
  String bytesTB(String n) {
    return '$n السل';
  }

  @override
  String get errGeneric => 'حدث خطأ ما';

  @override
  String get errCore => 'خدمة Sora لا تستجيب';

  @override
  String get errAuth => 'لا يمكن الوصول إلى خدمة Sora';

  @override
  String get errVersion => 'تحديث Sora: التطبيق والخدمة إصداران مختلفان';

  @override
  String get errBusy => 'انتظر، الأمر السابق لا يزال قيد التشغيل';

  @override
  String get errEngineMissing => 'لم يتم العثور على محرك لهذا الخادم';

  @override
  String get errEngineStart => 'المحرك لم يبدأ';

  @override
  String get errEngineStopped => 'توقف المحرك';

  @override
  String get errTunnel => 'لا يوجد إذن لإنشاء اتصال VPN';

  @override
  String get errServers => 'تم تكوين الخادم مع وجود خطأ';

  @override
  String get errNetwork => 'لا يمكن الوصول إلى الخادم';

  @override
  String get errTimeout => 'الخادم لم يرد في الوقت المناسب';

  @override
  String get errFirewall => 'لا يمكن حظر الإنترنت خارج VPN';

  @override
  String get errSubFetch => 'تعذر تحميل الاشتراك';

  @override
  String get errSubFormat => 'هذا ليس رابط الاشتراك';

  @override
  String get errSubEmpty => 'الاشتراك ليس لديه خوادم';

  @override
  String get errSubDuplicate => 'تمت إضافة هذا الاشتراك بالفعل';

  @override
  String get errSubLimit => 'عدد كبير جدًا من الاشتراكات';

  @override
  String get errSubScheme => 'الرابط يجب أن يبدأ ب https://';

  @override
  String get errSecretStore => 'وحدة تخزين Sora تالفة أو غير متوفرة';

  @override
  String get errNoServers => 'إضافة اشتراك للاتصال';

  @override
  String get exportText => 'نص';

  @override
  String get connections => 'اتصالات';

  @override
  String get close => 'يغلق';

  @override
  String get chainDirect => 'مباشر';

  @override
  String get chainBlocked => 'محظور';

  @override
  String get theme => 'سمة';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'ضوء';

  @override
  String get themeDark => 'مظلم';

  @override
  String get language => 'لغة';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'اتصال';

  @override
  String get sectionNoServer => 'لا يوجد خادم';

  @override
  String get sectionPing => 'بينغ';

  @override
  String get sectionLog => 'التشخيص';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'آلي';

  @override
  String get dnsHint => 'العناوين مفصولة بفواصل';

  @override
  String get fragment => 'تجزئة TLS';

  @override
  String get fragmentPackets => 'ما لتقسيم';

  @override
  String get fragmentLength => 'حجم القطعة';

  @override
  String get fragmentInterval => 'وقفة بين القطع';

  @override
  String get byDefault => 'تقصير';

  @override
  String get rangeHint => 'على سبيل المثال، 100-200';

  @override
  String get splitPos => 'تقسيم المواقف';

  @override
  String get splitPosHint => 'على سبيل المثال، 1، ميدسلد';

  @override
  String get disorder => 'إعادة ترتيب القطع';

  @override
  String get tlsRecord => 'قم بتقسيم سجل TLS';

  @override
  String get tlsRecordNo => 'لا';

  @override
  String get tlsRecordSni => 'على اسم الموقع';

  @override
  String get tlsRecordFirst => 'بعد البايت الأول';

  @override
  String get hostCase => 'تغيير حالة المضيف';

  @override
  String get probeMethod => 'طريقة';

  @override
  String get probeAuto => 'آلي';

  @override
  String get probeEngine => 'من خلال المحرك';

  @override
  String get probeConnect => 'اتصال فقط';

  @override
  String get probeUrl => 'عنوان الاختبار';

  @override
  String get probeTimeout => 'انتظر';

  @override
  String seconds(int n) {
    return '$n ق';
  }

  @override
  String get subscriptions => 'الاشتراكات';

  @override
  String get subscriptionSettings => 'إعدادات';

  @override
  String get userAgent => 'وكيل المستخدم';

  @override
  String get autoUpdate => 'التحديث تلقائيا';

  @override
  String get updateInterval => 'عدد المرات';

  @override
  String get intervalProvider => 'كما يطلب المزود';

  @override
  String hours(int n) {
    return '$n ح';
  }

  @override
  String get updateNow => 'قم بالتحديث الآن';

  @override
  String get logLevel => 'ما لتسجيل';

  @override
  String get levelDebug => 'كل شئ';

  @override
  String get levelInfo => 'المعتاد';

  @override
  String get levelWarning => 'مهم';

  @override
  String get levelError => 'الأخطاء فقط';

  @override
  String get recordDestinations => 'تسجيل عناوين المواقع';

  @override
  String get reset => 'إعادة ضبط الإعدادات';

  @override
  String get resetConfirm => 'إعادة ضبط كافة الإعدادات؟';

  @override
  String get resetAction => 'إعادة ضبط';

  @override
  String get invalidValue => 'هذه القيمة لن تعمل';

  @override
  String get website => 'صفحة الاشتراك';

  @override
  String get providerWebsite => 'موقع المزود';

  @override
  String get support => 'يدعم';

  @override
  String controlPortQuestion(String engine) {
    return 'يتم التحكم في $engine من خلال منفذ موجود على هذا الكمبيوتر. ستكون البرامج الأخرى قادرة على معرفة أن VPN قيد التشغيل.';
  }

  @override
  String chooseEngine(String engine) {
    return 'اختر $engine';
  }

  @override
  String get rules => 'القواعد المخصصة';

  @override
  String get ruleAdd => 'قاعدة جديدة';

  @override
  String get ruleHint => 'الموقع أو IP أو البرنامج';

  @override
  String get ruleDirect => 'مباشر';

  @override
  String get ruleProxy => 'من خلال VPN';

  @override
  String get ruleBlock => 'حاجز';

  @override
  String get failover => 'التبديل على الفشل';

  @override
  String get connectOnStart => 'الاتصال في البداية';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ينتهي الاشتراك بعد أيام #',
      one: 'ينتهي الاشتراك في يوم #',
      zero: 'ينتهي الاشتراك في غضون ساعات قليلة',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left يسار';
  }

  @override
  String get ruleInvalid => 'لا يبدو هذا كموقع أو عنوان IP أو برنامج';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'خوادم # بدورها', one: 'خادم # بدوره');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'خوادم #، الأسرع', one: 'خادم #، الأسرع');
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'وضع';

  @override
  String get tunnelTun => 'كل حركة المرور';

  @override
  String get tunnelProxy => 'وكيل System';

  @override
  String get proxyAddress => 'عنوان الوكيل';

  @override
  String get copied => 'منقول';

  @override
  String get launchAtLogin => 'ابدأ بالنظام';

  @override
  String get closeToTray => 'احتفظ بها في الدرج عند إغلاقها';

  @override
  String get notifications => 'إشعارات';

  @override
  String get trayOpen => 'افتح Sora';

  @override
  String get trayConnect => 'يتصل';

  @override
  String get trayDisconnect => 'قطع الاتصال';

  @override
  String get trayServer => 'الخادم';

  @override
  String get trayQuit => 'قم بإنهاء Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state، $server';
  }

  @override
  String get noticeInTray => 'Sora لا يزال في الدرج';

  @override
  String get noticeInTrayBody => 'قم بالخروج من قائمة الأيقونة الخاصة به';

  @override
  String get noticeLost => 'تم فقدان الاتصال';

  @override
  String get noticeLostBody => 'يتم إعادة الاتصال Sora';

  @override
  String get noticeRestored => 'متصل مرة أخرى';

  @override
  String get noticeFailed => 'تعذر الاتصال';

  @override
  String get noticeBackup => 'الخادم الرئيسي لم يرد؛ النسخ الاحتياطي يحمل حركة المرور';

  @override
  String get noticeNext => 'الخادم لم يرد؛ التالي يحمل حركة المرور';

  @override
  String get noticeMainBack => 'يجيب الخادم الرئيسي مرة أخرى ويحمل حركة المرور';

  @override
  String get noticeSubscription => 'الاشتراك';

  @override
  String get importTitle => 'إضافة هذا الاشتراك؟';

  @override
  String get importSealed =>
      'هذا الرابط مشفر لـ Happ، ولا يمكن قراءته إلا لـ Happ. اطلب من مزود الخدمة الخاص بك رابط الاشتراك العادي.';

  @override
  String get understood => 'نعم';

  @override
  String get noAnswer => 'لا إجابة';

  @override
  String get home => 'بيت';

  @override
  String get navRules => 'قواعد';

  @override
  String get navConnections => 'اتصالات';

  @override
  String get navLogs => 'سجلات';

  @override
  String get navAbout => 'عن';

  @override
  String get sidebarToggle => 'تبديل الشريط الجانبي';

  @override
  String get more => 'أكثر';

  @override
  String get less => 'أقل';

  @override
  String get currentServer => 'الخادم الحالي';

  @override
  String get trafficDown => 'تم التنزيل';

  @override
  String get trafficUp => 'تم الرفع';

  @override
  String perSecond(String value) {
    return '$value/ث';
  }

  @override
  String activeRules(int count) {
    return 'القواعد النشطة: $count';
  }

  @override
  String get recentNotifications => 'الإخطارات الأخيرة';

  @override
  String get notificationsEmpty => 'ستظهر أحداث الاتصال والاشتراك هنا';

  @override
  String get retryConnect => 'أعد محاولة الاتصال';

  @override
  String get openLogs => 'فتح السجلات';

  @override
  String get tourReplay => 'أظهر الدليل مرة أخرى';

  @override
  String tourStep(int step) {
    return 'الخطوة $step من 5';
  }

  @override
  String get tourBack => 'خلف';

  @override
  String get tourNext => 'التالي';

  @override
  String get tourSkip => 'يتخطى';

  @override
  String get tourFinish => 'منتهي';

  @override
  String get tourAdd => 'أضف رابط اشتراك المزود الخاص بك.';

  @override
  String get tourServer => 'اختر خادمًا. \"الأسرع\" يختار واحدًا لك.';

  @override
  String get tourConnect => 'انقر هنا للاتصال أو قطع الاتصال.';

  @override
  String get tourMode => 'اختر الوضع. يقوم Kill Switch بحظر الإنترنت في حالة انقطاع VPN.';

  @override
  String get tourSettings => 'افتح الإعدادات. يمكنك إعادة تشغيل هذا الدليل هناك.';

  @override
  String get chooseProgram => 'اختر برنامجا';

  @override
  String get installedApps => 'التطبيقات المثبتة';

  @override
  String get runningProcesses => 'العمليات الجارية';

  @override
  String get programsFailed => 'لا يمكن تحميل التطبيقات';

  @override
  String get programsEmpty => 'لم يتم العثور على أي تطبيقات. حاول اسم آخر.';

  @override
  String get selectExe => 'اختر ملف .exe';

  @override
  String get trafficUnavailable => 'العدادات غير متوفرة بعد';

  @override
  String get speedtest => 'سرعة';

  @override
  String get speedtestCheck => 'تحقق من السرعة';

  @override
  String get speedtestSearch => 'ابحث عن خدمة';

  @override
  String get speedtestEmpty => 'لا توجد مباريات. تغيير البحث.';

  @override
  String get speedtestBackToList => 'العودة إلى الخدمات';

  @override
  String get speedtestOpenBrowser => 'فتح في المتصفح';

  @override
  String get speedtestUnavailable => 'تعذر بدء تشغيل المتصفح المضمن. افتح الخدمة في متصفح النظام الخاص بك.';

  @override
  String get speedtestPageFailed => 'تعذر تحميل الصفحة. أعد تحميله أو افتح الخدمة في متصفح النظام لديك.';

  @override
  String get speedtestExternalFailed => 'تعذر فتح متصفح النظام. حاول ثانية.';

  @override
  String get modes => 'وسائط';

  @override
  String get proxyShort => 'الوكيل';

  @override
  String get tunMode => 'كل حركة المرور (TUN)';

  @override
  String get checkUpdates => 'التحقق من وجود تحديثات';

  @override
  String get updates => 'تحديثات التطبيق';

  @override
  String updateAvailable(String version) {
    return 'الإصدار $version متاح';
  }

  @override
  String get updateOpenAbout => 'عرض التحديث';

  @override
  String updateNotes(String version) {
    return 'التغييرات في $version';
  }

  @override
  String get updateCheck => 'التحقق من وجود تحديثات';

  @override
  String get updateChecking => 'جارٍ التحقق...';

  @override
  String get updateNoNotes => 'الإصدار ليس لديه ملاحظات.';

  @override
  String get updateDropWarning => 'سوف ينقطع اتصال VPN لبضع ثوان أثناء Sora وتحديثه الأساسي. يكمل؟';

  @override
  String get updateWaitConnection => 'انتظر حتى يصبح اتصال VPN والمركز جاهزًا.';

  @override
  String get updateDownloading => 'جارٍ تنزيل الملفات والتحقق منها...';

  @override
  String get updateInstalling => 'جارٍ تحضير التحديث أو انتظار مصادقة المسؤول...';

  @override
  String get updateNetworkError => 'تعذر تنزيل التحديث. حاول ثانية.';

  @override
  String get updateReleaseError => 'بيانات الإصدار أو الملفات المطلوبة مفقودة أو غير صالحة.';

  @override
  String get updateChecksumError => 'التنزيل لا يتطابق مع SHA256SUMS. لم يتم تثبيت أي شيء.';

  @override
  String get updateInstallError => 'التحديث لم ينته. ربما تم إلغاء المصادقة.';

  @override
  String get updateUnsupported =>
      'هذا الملف القابل للتنفيذ ليس مملوكًا لزوج حزمة Sora المدعوم. استخدم تعليمات تثبيت الإصدار.';

  @override
  String get updateManual =>
      'قم بتشغيل هذا الأمر في الوحدة الطرفية لتثبيت الحزمتين اللتين تم التحقق منهما، ثم أعد فتح Sora. تبقى الملفات في دليل التنزيل. سينقطع اتصال VPN.';

  @override
  String get updateCopyCommand => 'أمر النسخ';

  @override
  String get updateChecksDisabled => 'تم تعطيل عمليات التحقق التلقائية في الإعدادات.';

  @override
  String get updateInstalled => 'تم تثبيت التحديث. أعد فتح Sora.';

  @override
  String get projectLinks => 'مشروع';

  @override
  String get githubReleases => 'الإصدارات والتنزيلات';

  @override
  String get telegramChannel => 'قناة Telegram';

  @override
  String get licenses => 'التراخيص';

  @override
  String get componentLicenses => 'تراخيص المكونات';

  @override
  String get appCopyright => '© 2026 levvs-one والمساهمين';

  @override
  String get collapseServers => 'طي الخوادم';

  @override
  String get expandServers => 'قم بتوسيع الخوادم';

  @override
  String get hideDescription => 'إخفاء الوصف';

  @override
  String get showDescription => 'إظهار الوصف';

  @override
  String get pendingConnectionChanges => 'أعد الاتصال لتطبيق هذه التغييرات.';

  @override
  String get reconnectNow => 'تطبيق وإعادة الاتصال';

  @override
  String get bypassLimitations =>
      'يتجاوز هذا الوضع DPI فقط لـ HTTP وTLS، ولا يدعم UDP أو يغير عنوان IP الخاص بك. استخدم خادم VPN للصوت والمكالمات وعناوين Telegram المحظورة.';

  @override
  String get errEngineUnsupported => 'المحرك المحدد لا يدعم ملف التعريف هذا أو الإعدادات. اختر تلقائي أو محرك متوافق.';

  @override
  String get errRestore => 'لم تكن عملية تنظيف الاتصال كاملة. أعد محاولة قطع الاتصال؛ راجع السجل للحصول على التفاصيل.';

  @override
  String get errSessionEnded => 'لقد انتهت هذه الجلسة بالفعل. قم بتحديث حالة الاتصال.';

  @override
  String get retryDisconnect => 'أعد محاولة قطع الاتصال';

  @override
  String get tunStack => 'كومة تون';

  @override
  String get modesInfo => 'حول الأوضاع';

  @override
  String get modesGuideTitle => 'الأوضاع والمحركات';

  @override
  String get modesGuide =>
      'اختر تلقائي إذا لم تكن متأكدًا من المحرك الذي يحتاجه خادمك. يقوم Sora بالتحقق من ملف التعريف والإعدادات قبل الاتصال. لا يمكن للمحرك زيادة النطاق الترددي لخطتك: يعتمد الأداء على الخادم والمسار والبروتوكول والشبكة.\n\n## وسائط\n\n### كل حركة المرور (TUN)\n\nيقوم Sora بإنشاء واجهة شبكة افتراضية وتوجيه حركة مرور التطبيقات من خلالها، بما في ذلك TCP وUDP. استخدم هذا الوضع لـ Telegram والألعاب وصوت Discord. يمكن للقواعد إرسال مواقع أو برامج محددة مباشرة أو حظرها. تحتاج خدمة الشبكة إلى إذن وخادم يدعم البروتوكول المطلوب.\n\n### وكيل System\n\nيقوم Sora بتكوين وكيل HTTP/SOCKS محلي. تستخدمه التطبيقات التي تحترم إعدادات وكيل النظام. قد تتصل التطبيقات التي تحتوي على مكدس الشبكة الخاص بها مباشرةً؛ تحتاج UDP والمكالمات الصوتية عمومًا إلى TUN. يناسب هذا الوضع المتصفحات والتطبيقات التي تدعم الوكيل.\n\n### لا يوجد خادم\n\nفي Linux، يستخدم Sora [zapret](https://github.com/bol-van/zapret) لتقسيم طلبات HTTP/TLS وإعادة تشكيلها وتجاوز بعض عمليات فحص DPI. يظل عنوان IP الخاص بك كما هو وتنتقل الاتصالات مباشرة إلى موقع الويب. تعتمد النتائج على المزود الخاص بك وطريقة الحظر.\n\nيستخدم التكامل الحالي tpws لـ HTTP وTLS عبر TCP. فهو لا يتجاوز حظر IP أو يقوم بترحيل UDP، ولا يمكنه ضمان اتصالات Telegram الخاصة بـ MTProto. استخدم خادم VPN مع TUN للصوت Discord ومكالمات Telegram وهذه الأنواع من القيود.\n\n## المحركات\n\n### آلي\n\nيختار Sora محركًا مثبتًا يدعم خطة الاتصال بأكملها: بروتوكولات الخادم ووسائل النقل والمجموعات والتجزئة والوضع. يتم رفض الاختيار اليدوي غير المتوافق قبل إيقاف الاتصال الحالي. اختر Auto أو محرك آخر وقم بتطبيق الإعدادات مرة أخرى.\n\n### sing-box\n\nتشتمل حزم Sora الجديدة على [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)، وشوكة [sing-box](https://github.com/SagerNet/sing-box)، وإضافة XHTTP وVLESS Encryption من جانب العميل. يتعرف Sora على البنية وقدراتها. لا يكتسب الإصدار الأولي بدون XHTTP هذه الإمكانية من اسمه وحده.\n\nتتضمن البروتوكولات المدعومة VLESS، وVMess، وTrojan، وShadowsocks، وHysteria2، وTUIC، وAnyTLS، وWireGuard ومعلمات AmneziaWG 1.x/2.x يمكن استيراد Sora. تتطلب ملفات تعريف Xray JSON الكاملة Xray. لا يمكن استيراد حقول AWG 3.x الجديدة بعد. يستخدم sing-box منفذ تحكم محلي محمي بكلمة مرور، والذي يمكن للتطبيقات الأخرى الموجودة على الكمبيوتر اكتشافه.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) يدعم تجزئة VLESS وREALITY وXHTTP وVLESS Encryption وTLS. كما أنه يدير ملفات تعريف Xray الكاملة للموفر مع الحفاظ على التوجيه والمجموعات الخاصة بهم. لا يمكن تحويل ملفات التعريف هذه تلقائيًا إلى محرك آخر دون تغيير سلوكها.\n\nقام Xray المجمّع بإزالة الإعداد الذي يعطل التحقق من شهادة TLS (\'allowInsecure`). يقوم Auto بتحديد sing-box أو mihomo للخوادم العادية التي تتطلب هذا الإعداد. يؤدي تحديد Xray يدويًا إلى الإبلاغ عن عدم التوافق قبل إيقاف الاتصال الحالي. تحتاج ملفات تعريف JSON الكاملة الأقدم إلى ملف تعريف موفر محدث مع شهادة أو دبوس شهادة يمكن التحقق منه.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) يدعم المجموعات الاحتياطية وموازنة التحميل المرتبة، XHTTP وAmneziaWG. اختره عندما يكون تجاوز الفشل التلقائي إلى خادم النسخ الاحتياطي مهمًا. لا يتوفر إعداد تجزئة TLS الخاص بـ Sora مع هذا المحرك.\n\n## التوافق في Sora\n\n| ميزة | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN وTCP/UDP | نعم | نعم | نعم |\n| XHTTP | نعم | نعم | نعم |\n| VLESS Encryption | نعم | نعم | نعم |\n| الملف الشخصي الكامل لـ Xray | لا | نعم | لا |\n| TUIC / AnyTLS | كلاهما | لا | TUIC |\n| تجزئة TLS | نعم | نعم | لا |\n| AmneziaWG 1.x/2.x | نعم¹ | لا | نعم |\n| أمرت مجموعة احتياطية | لا | رقم² | نعم |\n\n¹ تستخدم ملفات التعريف ذات J1/J2/J3/Itime mihomo؛ لا يجب أبدًا التخلص من هذه الحقول بصمت. ² بالنسبة لمجموعة ملفات تعريف Xray الكاملة، يقوم التطبيق بتحديد ملف تعريف احتياطي. يعتمد الدعم على البنية المثبتة؛ تحقق من نسخته في حول.\n\n## مكدس TUN\n\nيتعامل المكدس مع TCP وUDP داخل الواجهة الافتراضية. في لوحة الأوضاع، تقدم Xray وmihomo gVisor، وSystem، وMixed، وMIPS. يحفظ كل محرك تفضيلاته الخاصة. لا يستخدم الوكيل System والأوضاع بدون خادم هذا التفضيل.\n\n- **Mixed** — يستخدم TCP مكدس النظام، بينما يتعامل gVisor مع UDP. هذا هو الإعداد الافتراضي لـ mihomo على Linux. في Windows، يستخدم Xray وmihomo مكدس MIPS افتراضيًا.\n- **System** — يستخدم مكدس النظام. جرب خيارًا آخر إذا واجهت تطبيقات الشبكة مشكلات.\n- **gVisor** — يتعامل مع حركة المرور في مساحة المستخدمين.\n- **MIPS** — حزمة IP الخاصة بـ mihomo، المتوفرة في الإصدار المجمع 1.19.32.\n\nفي Linux، يستخدم Xray gVisor المدمج بشكل افتراضي. تستخدم System وMixed وMIPS على Linux mihomo كمحرك TUN، حيث تقوم بإعادة توجيه TCP وUDP إلى Xray عبر رابط SOCKS محلي معتمد. يحتفظ Xray بالبروتوكول وملف تعريف الموفر والتوجيه. تتطلب هذه الخيارات الثلاثة تثبيت mihomo. في Windows، يستخدم Xray المحرك mihomo 1.19.32 أو أحدث لجميع مكدسات TUN الأربعة. تبقى البروتوكولات والتوجيه في Xray. تدعم قواعد التطبيقات في هذا الربط الاتصال المباشر والحظر فقط؛ على Linux تتطلب هذه القواعد gVisor المدمج في Xray.\n\nيدير الجسر عملية ثانية. في ثلاثة قياسات خاملة على Linux، استخدمت حوالي 32-36 ميجابايت من الذاكرة الفعلية أكثر من Xray TUN الأصلي. هذا لا يقيس حمل التنزيل: تعتمد تكاليف وحدة المعالجة المركزية والذاكرة على الاتصالات. لا يحتوي sing-box على محدد المكدس. لا يضمن عدم وجود مكدس أداءً أفضل في كل شبكة. اختر مكدسًا وحدد تطبيق وأعد الاتصال لتجربته في شبكتك.\n\n## تطبيق الإعدادات\n\nيؤدي تحديد الخادم إلى إعادة الاتصال تلقائيًا. يتم حفظ إعدادات الوضع والمحرك وDNS والقاعدة على الفور؛ أثناء الاتصال النشط، انقر فوق \"تطبيق\" ثم أعد الاتصال لاستخدامها. قد تؤدي إعادة تشغيل المحرك إلى مقاطعة التنزيلات والمكالمات. النقرات المتكررة لا تؤدي إلى بدء اتصالات متوازية؛ يؤدي قطع الاتصال إلى إنهاء عملية النقل وتحرير الاتصال.\n\nالإنترنت فقط من خلال VPN يحظر حركة المرور المباشرة عند انقطاع النفق. إنه يؤثر على الجهاز بأكمله. يؤدي قطع الاتصال الصريح إلى إزالة قواعد Sora. إذا لم تنتهي عملية التنظيف، أعد محاولة قطع الاتصال وافتح السجل.\n\n## وثائق المشروع\n\n- [sing-box-lx: التكوين والدعم](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [وثائق sing-box](https://sing-box.sagernet.org/)\n- [وثائق Xray](https://xtls.github.io/)\n- [وثائق mihomo](https://wiki.metacubex.one/)\n- [zapret: التشغيل والقيود](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'فحص الخوادم';

  @override
  String get extensions => 'ملحقات';
  @override
  String extRatingLabel(String rating) => 'Rating $rating of 5';
  @override
  String extByAuthor(String author) => 'by $author';
  @override
  String extInstallsCount(String count) => '$count installs';
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
  String get extSideloadWarning => 'Not from the team catalog. The author\'s key is self-attested: install only if you trust the author.';
  @override
  String extInstallTitle(String name) => 'Install $name';
  @override
  String extUpdateTitle(String name) => 'Update $name';
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
  String get extEmptyInstalled => 'No extensions installed yet.
Find one in the catalog or install from a file.';
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
  String extErrMinApp(String version) => 'This extension needs app version $version or newer.';
  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';
  @override
  String get extErrGeneric => 'Something went wrong. Please try again.';
  @override
  String get extUpdateAvailable => 'Update available';
  @override
  String get extDisabled => 'Disabled';
  @override
  String extVersionLabel(String version) => 'Version $version';
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
  String get extOpenPanel => 'Open panel';
  @override
  String extUpdateTo(String version) => 'Update to $version';
  @override
  String get extEnabled => 'Enabled';
  @override
  String extRollbackTo(String version) => 'Roll back to $version';
  @override
  String extRollbackConfirm(String version) => 'Roll back to version $version?';
  @override
  String get extUninstall => 'Uninstall';
  @override
  String extUninstallConfirm(String name) => 'Remove “$name” and its settings?';
  @override
  String get extPanelUnavailable => 'The panel is unavailable. The extension may have been disabled or removed.';
  @override
  String get extCatalogSoonTitle => 'The team catalog is coming soon';
  @override
  String get extCatalogSoonBody => 'Until then, you can install extensions from a file or a link — every package is still signature-checked.';
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
  String exportLogFile(String name) {
    return 'إلى $name';
  }

  @override
  String get diagnosticHttp => 'تشخيصات HTTP';

  @override
  String get diagnosticPackets => 'التقاط الحزمة';

  @override
  String get diagnosticEvents => 'أحداث ويندوز';

  @override
  String get diagnosticCapture => 'التقاط لمدة 10 ثانية';

  @override
  String get diagnosticNoData => 'لا توجد طلبات مسجلة حتى الآن. افتح موقع اختبار السرعة أولاً.';

  @override
  String get diagnosticRequiresTun => 'يحتاج التقاط الحزم إلى اتصال Sora TUN نشط.';

  @override
  String get diagnosticUnavailable => 'هذا التشخيص غير متوفر على هذا النظام الأساسي.';
  @override
  String get dnsExpected => 'Expected';
  @override
  String get dnsActual => 'Observed';
  @override
  String get dnsCheckNeedsConnection => 'Connect to the VPN first, then check for leaks.';
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
  String get connConnections => 'connections';
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
  String get updateStageVerify => 'Verifying';
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
  String benchmarkProgress(int done, int total) => 'Measuring $done of $total…';
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
  String profileDeleteConfirm(String name) => 'Delete profile "${name}"?';

  @override
  String profileApplyAsk(String name) => 'Apply profile "${name}"?';

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) => 'Profile "${name}" applied';

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) => 'Now: ${info}';

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
  String chainDeleteConfirm(String name) => 'Delete chain "${name}"?';

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String chainHop(String n) => 'Hop ${n}';

  @override
  String get chainEntry => 'Entry';

  @override
  String get chainExit => 'Exit';

  @override
  String get sync => 'Device sync';

  @override
  String get syncDevices => 'My devices';

  @override
  String get syncEmpty => 'No paired devices. Pair another device to keep subscriptions, rules and settings in sync.';

  @override
  String get syncPair => 'Pair a device';

  @override
  String get syncShowCode => 'Show my code';

  @override
  String get syncScanCode => 'Scan a code';

  @override
  String get syncRevoke => 'Revoke';

  @override
  String syncRevokeConfirm(String name) => 'Revoke "${name}"?';

  @override
  String syncLastSync(String time) => 'Last sync: ${time}';

  @override
  String get syncNever => 'Never';

  @override
  String get syncWhat => 'What syncs';

  @override
  String get syncWhatBody => 'Subscriptions, rules, settings and network profiles. Never synced: local logs, IPC tokens.';

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
  String get zapretWithVpnHint => 'Runs zapret next to the VPN tunnel: tunneled traffic uses the VPN, direct traffic goes through the bypass.';
  @override
  String get chainDuplicate => 'Each server can appear only once';
  @override
  String get edit => 'Edit';
  @override
  String get remove => 'Remove';
}
