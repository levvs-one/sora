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
  String get connEmpty => 'لا توجد اتصالات';

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
  String latencyMs(int value) {
    return '$value ms';
  }

  @override
  String speedMbps(double value) {
    return '$value Mbps';
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
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'ضوء';

  @override
  String get themeDark => 'مظلم';

  @override
  String get language => 'لغة';

  @override
  String get languageSystem => 'حسب النظام';

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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'خوادم #، الأسرع', one: 'خادم #، الأسرع');
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'وضع';

  @override
  String get tunnelProxy => 'وكيل System';

  @override
  String get proxyAddress => 'عنوان الوكيل';

  @override
  String get copied => 'منقول';

  @override
  String get launchAtLogin => 'ابدأ بالنظام';

  @override
  String get launchAtLoginDetail => 'سيبدأ Sora تلقائيًا عند تسجيل الدخول ويبقى في علبة النظام.';

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
  String get programsEmpty => 'لم يتم العثور على أي تطبيقات. حاول اسم آخر.';

  @override
  String get selectExe => 'اختر ملف .exe';

  @override
  String get speedtest => 'سرعة';

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
  String get updateSignaturePending => 'تُطابَق ملفات التحديث مع المجاميع الاختبارية المنشورة مع الإصدار.';

  @override
  String get updateManualSigWarning =>
      'الملفات أدناه تطابق المجاميع الاختبارية للإصدار. شغّل الأمر إذا نزّلتها من الإصدار الرسمي.';

  @override
  String get updateVersionRevoked => 'قام المطور بسحب هذا الإصدار. يرجى الانتظار لإصدار مصحح.';

  @override
  String get updateRolloutPending => 'يتم طرح إصدار أحدث تدريجيًا وسيتم تقديمه لك تلقائيًا.';

  @override
  String updateRollbacking(String version) {
    return 'العودة إلى الإصدار $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'لم ينجح التحديث إلى $version في اجتياز فحص الصحة، لذا تم إرجاع Sora إلى $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'فشل التراجع التلقائي. إذا لم يعمل الإصدار الجديد، فأعد تثبيت الإصدار السابق يدويًا.';

  @override
  String get updateRollbackCacheError =>
      'تعذر إعداد نسخة التراجع التي تم التحقق منها من الإصدار الحالي، لذلك لم يتم تثبيت التحديث.';

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
      'اختر تلقائي إذا لم تكن متأكدًا من المحرك الذي يحتاجه خادمك. يقوم Sora بالتحقق من ملف التعريف والإعدادات قبل الاتصال. لا يمكن للمحرك زيادة النطاق الترددي لخطتك: يعتمد الأداء على الخادم والمسار والبروتوكول والشبكة.\n\n## وسائط\n\n### كل حركة المرور (TUN)\n\nيقوم Sora بإنشاء واجهة شبكة افتراضية وتوجيه حركة مرور التطبيقات من خلالها، بما في ذلك TCP وUDP. استخدم هذا الوضع لـ Telegram والألعاب وصوت Discord. يمكن للقواعد إرسال مواقع أو برامج محددة مباشرة أو حظرها. تحتاج خدمة الشبكة إلى إذن وخادم يدعم البروتوكول المطلوب.\n\n### وكيل System\n\nيقوم Sora بتكوين وكيل HTTP/SOCKS محلي. تستخدمه التطبيقات التي تحترم إعدادات وكيل النظام. قد تتصل التطبيقات التي تحتوي على مكدس الشبكة الخاص بها مباشرةً؛ تحتاج UDP والمكالمات الصوتية عمومًا إلى TUN. يناسب هذا الوضع المتصفحات والتطبيقات التي تدعم الوكيل.\n\n### لا يوجد خادم\n\nفي Linux، يستخدم Sora [zapret](https://github.com/bol-van/zapret) لتقسيم طلبات HTTP/TLS وإعادة تشكيلها وتجاوز بعض عمليات فحص DPI. يظل عنوان IP الخاص بك كما هو وتنتقل الاتصالات مباشرة إلى موقع الويب. تعتمد النتائج على المزود الخاص بك وطريقة الحظر.\n\nيستخدم التكامل الحالي tpws لـ HTTP وTLS عبر TCP. فهو لا يتجاوز حظر IP أو يقوم بترحيل UDP، ولا يمكنه ضمان اتصالات Telegram الخاصة بـ MTProto. استخدم خادم VPN مع TUN للصوت Discord ومكالمات Telegram وهذه الأنواع من القيود.\n\n## المحركات\n\n### آلي\n\nيختار Sora محركًا مثبتًا يدعم خطة الاتصال بأكملها: بروتوكولات الخادم ووسائل النقل والمجموعات والتجزئة والوضع. يتم رفض الاختيار اليدوي غير المتوافق قبل إيقاف الاتصال الحالي. اختر Auto أو محرك آخر وقم بتطبيق الإعدادات مرة أخرى.\n\n### sing-box\n\nتشتمل حزم Sora الجديدة على [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)، وشوكة [sing-box](https://github.com/SagerNet/sing-box)، وإضافة XHTTP وVLESS Encryption من جانب العميل. يتعرف Sora على البنية وقدراتها. لا يكتسب الإصدار الأولي بدون XHTTP هذه الإمكانية من اسمه وحده.\n\nتتضمن البروتوكولات المدعومة VLESS، وVMess، وTrojan، وShadowsocks، وHysteria2، وTUIC، وAnyTLS، وWireGuard ومعلمات AmneziaWG 1.x/2.x يمكن استيراد Sora. تتطلب ملفات تعريف Xray JSON الكاملة Xray. لا يمكن استيراد حقول AWG 3.x الجديدة بعد. يستخدم sing-box منفذ تحكم محلي محمي بكلمة مرور، والذي يمكن للتطبيقات الأخرى الموجودة على الكمبيوتر اكتشافه.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) يدعم تجزئة VLESS وREALITY وXHTTP وVLESS Encryption وTLS. كما أنه يدير ملفات تعريف Xray الكاملة للموفر مع الحفاظ على التوجيه والمجموعات الخاصة بهم. لا يمكن تحويل ملفات التعريف هذه تلقائيًا إلى محرك آخر دون تغيير سلوكها.\n\nقام Xray المجمّع بإزالة الإعداد الذي يعطل التحقق من شهادة TLS (\'allowInsecure`). يقوم Auto بتحديد sing-box أو mihomo للخوادم العادية التي تتطلب هذا الإعداد. يؤدي تحديد Xray يدويًا إلى الإبلاغ عن عدم التوافق قبل إيقاف الاتصال الحالي. تحتاج ملفات تعريف JSON الكاملة الأقدم إلى ملف تعريف موفر محدث مع شهادة أو دبوس شهادة يمكن التحقق منه.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) يدعم المجموعات الاحتياطية وموازنة التحميل المرتبة، XHTTP وAmneziaWG. اختره عندما يكون تجاوز الفشل التلقائي إلى خادم النسخ الاحتياطي مهمًا. لا يتوفر إعداد تجزئة TLS الخاص بـ Sora مع هذا المحرك.\n\n## التوافق في Sora\n\n| ميزة | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN وTCP/UDP | نعم | نعم | نعم |\n| XHTTP | نعم | نعم | نعم |\n| VLESS Encryption | نعم | نعم | نعم |\n| الملف الشخصي الكامل لـ Xray | لا | نعم | لا |\n| TUIC / AnyTLS | كلاهما | لا | TUIC |\n| تجزئة TLS | نعم | نعم | لا |\n| AmneziaWG 1.x/2.x | نعم¹ | لا | نعم |\n| أمرت مجموعة احتياطية | لا | رقم² | نعم |\n\n¹ تستخدم ملفات التعريف ذات J1/J2/J3/Itime mihomo؛ لا يجب أبدًا التخلص من هذه الحقول بصمت. ² بالنسبة لمجموعة ملفات تعريف Xray الكاملة، يقوم التطبيق بتحديد ملف تعريف احتياطي. يعتمد الدعم على البنية المثبتة؛ تحقق من نسخته في حول.\n\n## مكدس TUN\n\nيتعامل المكدس مع TCP وUDP داخل الواجهة الافتراضية. في لوحة الأوضاع، تقدم Xray وmihomo gVisor، وSystem، وMixed، وMIPS. يحفظ كل محرك تفضيلاته الخاصة. لا يستخدم الوكيل System والأوضاع بدون خادم هذا التفضيل.\n\n- **Mixed**: يستخدم TCP مكدس النظام، بينما يتعامل gVisor مع UDP. هذا هو الإعداد الافتراضي لـ mihomo على Linux. في Windows، يستخدم Xray وmihomo مكدس MIPS افتراضيًا.\n- **System**: يستخدم مكدس النظام. جرب خيارًا آخر إذا واجهت تطبيقات الشبكة مشكلات.\n- **gVisor**: يتعامل مع حركة المرور في مساحة المستخدمين.\n- **MIPS**: حزمة IP الخاصة بـ mihomo، المتوفرة في الإصدار المجمع 1.19.32.\n\nفي Linux، يستخدم Xray gVisor المدمج بشكل افتراضي. تستخدم System وMixed وMIPS على Linux mihomo كمحرك TUN، حيث تقوم بإعادة توجيه TCP وUDP إلى Xray عبر رابط SOCKS محلي معتمد. يحتفظ Xray بالبروتوكول وملف تعريف الموفر والتوجيه. تتطلب هذه الخيارات الثلاثة تثبيت mihomo. في Windows، يستخدم Xray المحرك mihomo 1.19.32 أو أحدث لجميع مكدسات TUN الأربعة. تبقى البروتوكولات والتوجيه في Xray. تدعم قواعد التطبيقات في هذا الربط الاتصال المباشر والحظر فقط؛ على Linux تتطلب هذه القواعد gVisor المدمج في Xray.\n\nيدير الجسر عملية ثانية. في ثلاثة قياسات خاملة على Linux، استخدمت حوالي 32-36 ميجابايت من الذاكرة الفعلية أكثر من Xray TUN الأصلي. هذا لا يقيس حمل التنزيل: تعتمد تكاليف وحدة المعالجة المركزية والذاكرة على الاتصالات. لا يحتوي sing-box على محدد المكدس. لا يضمن عدم وجود مكدس أداءً أفضل في كل شبكة. اختر مكدسًا وحدد تطبيق وأعد الاتصال لتجربته في شبكتك.\n\n## تطبيق الإعدادات\n\nيؤدي تحديد الخادم إلى إعادة الاتصال تلقائيًا. يتم حفظ إعدادات الوضع والمحرك وDNS والقاعدة على الفور؛ أثناء الاتصال النشط، انقر فوق \"تطبيق\" ثم أعد الاتصال لاستخدامها. قد تؤدي إعادة تشغيل المحرك إلى مقاطعة التنزيلات والمكالمات. النقرات المتكررة لا تؤدي إلى بدء اتصالات متوازية؛ يؤدي قطع الاتصال إلى إنهاء عملية النقل وتحرير الاتصال.\n\nالإنترنت فقط من خلال VPN يحظر حركة المرور المباشرة عند انقطاع النفق. إنه يؤثر على الجهاز بأكمله. يؤدي قطع الاتصال الصريح إلى إزالة قواعد Sora. إذا لم تنتهي عملية التنظيف، أعد محاولة قطع الاتصال وافتح السجل.\n\n## وثائق المشروع\n\n- [sing-box-lx: التكوين والدعم](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [وثائق sing-box](https://sing-box.sagernet.org/)\n- [وثائق Xray](https://xtls.github.io/)\n- [وثائق mihomo](https://wiki.metacubex.one/)\n- [zapret: التشغيل والقيود](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nينقل OLCRTC حركة TCP عبر مكالمة فيديو في Jitsi أو Yandex Telemost أو WB Stream. استورد رابط olcrtc:// أو رمز QR. يعمل مع sing-box وXray وmihomo في وضعي الوكيل وTUN؛ لا يدعم UDP. يحتاج الطرفان إلى إصدارات OLC2 متوافقة. المشروع الأصلي مؤرشف.\n';

  @override
  String get probeServers => 'فحص الخوادم';

  @override
  String get extensions => 'ملحقات';

  @override
  String extRatingLabel(String rating) {
    return 'التقييم $rating من 5';
  }

  @override
  String extByAuthor(String author) {
    return 'بواسطة $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'عدد التثبيتات: $count';
  }

  @override
  String get extInstallOne => 'تثبيت واحد';

  @override
  String get extBadgeVerified => 'تم التحقق منه';

  @override
  String get extBadgeTop => 'الأكثر شعبية هذا الأسبوع';

  @override
  String get extBadgeNew => 'جديد';

  @override
  String get extBadgeStaff => 'فريق Sora';

  @override
  String get extSideloadShort => 'ليس من الكتالوج';

  @override
  String get extSideloadWarning =>
      'هذا الملحق ليس من كتالوج الفريق. لقد كفل المؤلف فقط مفتاحه: قم بتثبيته فقط إذا كنت تثق في المؤلف.';

  @override
  String extInstallTitle(String name) {
    return 'تثبيت «$name»';
  }

  @override
  String extUpdateTitle(String name) {
    return 'تحديث «$name»';
  }

  @override
  String get extPermissionsIntro => 'سيتمكن هذا الملحق من:';

  @override
  String get extPermissionsWidened => 'التحديث يطلب أذونات جديدة:';

  @override
  String get extDangerousAck => 'أدرك أن هذه الأذونات خطيرة';

  @override
  String get extInstall => 'تثبيت';

  @override
  String get extUpdate => 'تحديث';

  @override
  String get extCancel => 'إلغاء';

  @override
  String get extConfirm => 'تأكيد';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'الكتالوج';

  @override
  String get extInstalled => 'الملحقات المثبتة';

  @override
  String get extSearchHint => 'البحث عن ملحقات';

  @override
  String get extCatAll => 'الكل';

  @override
  String get extCatTools => 'الأدوات';

  @override
  String get extCatThemes => 'السمات';

  @override
  String get extCatAutomation => 'الأتمتة';

  @override
  String get extCatStats => 'الإحصائيات';

  @override
  String get extCatNetwork => 'الشبكة';

  @override
  String get extSortBy => 'الترتيب حسب';

  @override
  String get extSortPopular => 'الأكثر شعبية';

  @override
  String get extSortRating => 'الأعلى تقييمًا';

  @override
  String get extSortName => 'الاسم';

  @override
  String get extCatalogError => 'تعذر تحميل الكتالوج';

  @override
  String get extRetry => 'إعادة المحاولة';

  @override
  String get extEmptySearch => 'لم يتم العثور على شيء';

  @override
  String get extEmptyInstalled => 'لم يتم تثبيت أي ملحقات بعد.\nابحث عن واحد في الكتالوج أو قم بتثبيته من ملف.';

  @override
  String get extInstallFromFile => 'التثبيت من الملف';

  @override
  String get extInstallFromUrl => 'التثبيت من URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'تحميل';

  @override
  String get extDownloading => 'جارٍ التحميل...';

  @override
  String get extVerifying => 'التحقق…';

  @override
  String get extInstalling => 'التثبيت...';

  @override
  String get extInstallFailed => 'فشل التثبيت';

  @override
  String get extErrSignature => 'فشل فحص التوقيع. قد يكون الملف تالفًا أو تم العبث به.';

  @override
  String get extErrManifest => 'ملف تعريف الملحق غير صالح.';

  @override
  String get extErrNetwork => 'خطأ في الشبكة. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get extErrHash => 'التنزيل لا يطابق الكتالوج. ربما تم العبث بها.';

  @override
  String extErrMinApp(String version) {
    return 'يحتاج هذا الملحق إلى إصدار التطبيق $version أو أحدث.';
  }

  @override
  String get extErrHttpsOnly => 'يُسمح فقط بروابط https://';

  @override
  String get extErrGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get extErrAuthorKeyChanged =>
      'تم توقيع هذا التحديث باستخدام مفتاح مؤلف مختلف عن الإصدار المثبت، لذلك تم حظره. إذا كنت تثق في المفتاح الجديد، فقم بإلغاء تثبيت الملحق وتثبيته مرة أخرى بشكل صريح.';

  @override
  String get extUpdateAvailable => 'التحديث متاح';

  @override
  String get extDisabled => 'معطل';

  @override
  String extToggleEnabled(String name) {
    return 'تمكين $name';
  }

  @override
  String get extSearchInstalled => 'البحث في الملحقات المثبتة';

  @override
  String get extUpdateAll => 'تحديث الكل';

  @override
  String extUpdatesAvailable(int count) {
    return '$count التحديثات متاحة';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count محدث';
  }

  @override
  String get extRiskNormal => 'عادي';

  @override
  String get extRiskSensitive => 'حساس';

  @override
  String get extRiskDangerous => 'مخاطر عالية';

  @override
  String get extPermissionsRemoved => 'لم يعد مطلوبًا:';

  @override
  String get extUpdateFailedKept => 'لا يزال الإصدار السابق مثبتًا.';

  @override
  String get extConflictsTitle => 'تعارضات الملحق';

  @override
  String get extConflictsIntro => 'تريد هذه الإضافات الشيء نفسه. اختر أيّها يعمل، وستبقى الأخرى مثبّتة.';

  @override
  String get extConflictTheme => 'سمة التطبيق';

  @override
  String get extConflictNetHooks => 'خطافات الشبكة';

  @override
  String extConflictWinner(String name) {
    return 'الأولوية لـ $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'تعارضات تتطلب قرارك: $count';
  }

  @override
  String get extConflictsResolve => 'حل النزاعات';

  @override
  String get extConflictNote =>
      'يُحفظ اختيارك على هذا الجهاز. يتغيّر المظهر فورًا، أما خطافات الشبكة فلا تعمل في هذا الإصدار.';

  @override
  String extVersionLabel(String version) {
    return 'النسخة $version';
  }

  @override
  String get extAuthor => 'المؤلف';

  @override
  String get extRating => 'التقييم';

  @override
  String get extInstalls => 'عمليات التثبيت';

  @override
  String get extVersion => 'النسخة';

  @override
  String get extAbout => 'حول هذا الملحق';

  @override
  String get extPermissionsTitle => 'الأذونات';

  @override
  String get extNoPermissions => 'لا توجد أذونات خاصة.';

  @override
  String get extSettings => 'الإعدادات';

  @override
  String get extSaveSettings => 'حفظ الإعدادات';

  @override
  String get extSaving => 'الحفظ...';

  @override
  String extUpdateTo(String version) {
    return 'الترقية إلى $version';
  }

  @override
  String get extEnabled => 'مفعّل';

  @override
  String extRollbackTo(String version) {
    return 'العودة إلى $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'العودة إلى الإصدار $version؟';
  }

  @override
  String get extUninstall => 'إلغاء التثبيت';

  @override
  String extUninstallConfirm(String name) {
    return 'إزالة \"$name\" وإعداداته؟';
  }

  @override
  String get extPanelUnavailable => 'اللوحة غير متوفرة. ربما تم تعطيل الملحق أو إزالته.';

  @override
  String get extPermConnectionsRead => 'راجع قائمة الاتصالات النشطة';

  @override
  String get extPermServersRead => 'عرض قائمة خوادمك';

  @override
  String get extPermSettingsRead => 'قراءة إعدادات التطبيق';

  @override
  String get extPermSettingsWrite => 'تغيير إعدادات التطبيق';

  @override
  String get extPermNotifications => 'إظهار الإشعارات';

  @override
  String get extPermTray => 'إضافة عناصر إلى قائمة الدرج';

  @override
  String get extPermUiPanel => 'إظهار اللوحات داخل التطبيق';

  @override
  String get extPermThemeApply => 'تطبيق السمات';

  @override
  String get extPermRoutingRules => 'إضافة قواعد التوجيه (تؤثر على المكان الذي تنتقل إليه حركة مرور الشبكة)';

  @override
  String get extPermNetHooks => 'التدخل في مسار الشبكة (وحدات تجاوز DPI)';

  @override
  String get extPermNetFetch => 'اطلب URL من القائمة المسموح بها';

  @override
  String get extPermBackground => 'تشغيل المهام الخلفية';

  @override
  String get extPermBackgroundDetail =>
      'يقوم بتشغيل المهام المجدولة حتى عندما تكون اللوحة مغلقة. يمكنك إيقافه مؤقتًا أو تغيير عدد مرات تشغيله في إعدادات الملحق.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'يعمل في الخلفية';

  @override
  String get extCapNetHook => 'تجاوز الحجب واعتراضات الشبكة';

  @override
  String get extCapPanel => 'اللوحات';

  @override
  String get extCapRouting => 'قواعد التوجيه';

  @override
  String get extCapTheme => 'السمات';

  @override
  String get extCapWidget => 'عناصر واجهة';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'سجل التغيير';

  @override
  String get extImageFailed => 'تعذر تحميل الصورة';

  @override
  String get extRatingHow => 'كيفية عمل التقييمات';

  @override
  String get extRatingHowBody =>
      'تستخدم التقييمات متوسط بايزي: يظل الملحق الذي يحتوي على عدد قليل من التقييمات بالقرب من المنتصف حتى يصوت المزيد من الأشخاص، لذلك لا يمكن لمراجعة واحدة من فئة 5 نجوم دفع الملحق الجديد إلى الأعلى. التقييمات الحديثة لها وزن أكبر من التقييمات القديمة، ويتم احتساب تقييم واحد فقط لكل حساب.';

  @override
  String get extScreenshots => 'لقطات الشاشة';

  @override
  String get extSortRelevance => 'الصلة';

  @override
  String get extPermNetworkDetail =>
      'تجلب بيانات من الإنترنت عبر VPN. يُسمح فقط بالمضيفين في القائمة أدناه، وكل ما عداهم محظور.';

  @override
  String get extBgTitle => 'مهمة في الخلفية';

  @override
  String get extBgEnabled => 'تشغيل في الخلفية';

  @override
  String get extBgInterval => 'التشغيل كل';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# دقيقة',
      many: '# دقيقة',
      few: '# دقائق',
      two: 'دقيقتان (#)',
      one: 'دقيقة واحدة (#)',
      zero: '# دقيقة',
    );
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# ساعة',
      many: '# ساعة',
      few: '# ساعات',
      two: 'ساعتان (#)',
      one: 'ساعة واحدة (#)',
      zero: '# ساعة',
    );
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'تعمل المهمة وفق الجدول ما دام Sora مفتوحًا، بما في ذلك عند وجوده في علبة النظام. أقصر فاصل 15 دقيقة.';

  @override
  String get extBgDisabledNote => 'قم بتمكين الملحق لإدارة مهمة الخلفية الخاصة به.';

  @override
  String get extCapNetwork => 'الوصول إلى الشبكة';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'الشبكة: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'إلى $name';
  }

  @override
  String get diagnosticHttp => 'تشخيصات HTTP';

  @override
  String get diagnosticNoData => 'لا توجد طلبات مسجلة حتى الآن. افتح موقع اختبار السرعة أولاً.';

  @override
  String get qrShareTitle => 'شارك كود QR';

  @override
  String get qrScanTitle => 'مسح الكود QR';

  @override
  String get qrCopyLink => 'نسخ الرابط';

  @override
  String get qrShowLink => 'إظهار الرابط';

  @override
  String get qrHideLink => 'إخفاء الرابط';

  @override
  String get qrWarning => 'يحتوي هذا الرمز QR على تفاصيل الاتصال. لا تظهر ذلك للغرباء.';

  @override
  String get qrScanHint => 'اختر لقطة شاشة أو صورة تحتوي على رمز QR، أو الصق رابطًا';

  @override
  String get qrFromClipboard => 'لصق من الحافظة';

  @override
  String get qrNoCode => 'لم يتم العثور على رمز QR في هذه الصورة.';

  @override
  String get qrInvalid => 'لا يحتوي رمز QR هذا على رابط صالح.';

  @override
  String get qrScan => 'مسح QR';

  @override
  String get qrFromImage => 'فتح صورة';

  @override
  String get connGroupByProcess => 'التجميع حسب العملية';

  @override
  String get connListView => 'القائمة';

  @override
  String get connCopyHost => 'نسخ المضيف';

  @override
  String get connAddRule => 'أضف القاعدة';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# اتصال',
      many: '# اتصالًا',
      few: '# اتصالات',
      two: 'اتصالان (#)',
      one: 'اتصال واحد (#)',
      zero: '# اتصالات',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'إعداد مسبق';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'مخصص';

  @override
  String get dnsCheck => 'التحقق من عدم وجود تسرب للبيانات';

  @override
  String get dnsChecking => 'التحقق...';

  @override
  String get dnsNoLeak => 'لم يتم العثور على أي تسريبات';

  @override
  String get dnsLeakFound => 'تم اكتشاف تسرب';

  @override
  String get dnsLastCheck => 'آخر فحص';

  @override
  String get dnsNeverChecked => 'لم يتم اختباره بعد';

  @override
  String get dnsLeakCheckTunnelDns => 'محللات DNS للنفق';

  @override
  String get dnsLeakCheckSystemResolvers => 'محللات أسماء النظام';

  @override
  String get dnsLeakCheckKillSwitchDns => 'حماية DNS بمفتاح الإيقاف';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'قم بتكوين DNS للنفق في إعدادات DNS أعلاه.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'تحقق من وحدات الحل التي سيستخدمها نظامك خارج النفق.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'فعّل مفتاح الإيقاف لإبقاء حركة DNS داخل النفق.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS المشفّر في نظام التشغيل';

  @override
  String get dnsLeakCheckDnsSpoof => 'ردود DNS مزورة';

  @override
  String get dnsLeakFixReviewEncryptedDns => 'تحقق من نقاط النهاية المشفرة DNS التي يستخدمها نظامك خارج النفق.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'استخدم DNS (DoT أو DoH) المشفر للنفق حتى لا تتمكن أدوات الحل من تزوير الإجابات.';

  @override
  String get dnsCheckNeedsConnection => 'اتصل بـ VPN أولاً، ثم تحقق من عدم وجود تسربات.';

  @override
  String get dnsExpected => 'المنتظر';

  @override
  String get dnsActual => 'ملاحظ';

  @override
  String get sortBy => 'الترتيب حسب';

  @override
  String get sortPing => 'بينغ';

  @override
  String get sortSpeed => 'السرعة';

  @override
  String get sortName => 'الاسم';

  @override
  String get measureSpeed => 'قياس السرعة';

  @override
  String get benchmarkStale => 'عفا عليه الزمن';

  @override
  String get autoSelectMode => 'خادم التحديد التلقائي';

  @override
  String get autoSelectPing => 'أسرع بينغ';

  @override
  String get autoSelectSpeed => 'السرعة القصوى';

  @override
  String get autoSelectSmart => 'الاختيار الذكي';

  @override
  String get coreWatchUnstable => 'الاتصال بالنواة غير مستقر';

  @override
  String get watchReconnect => 'أعد الاتصال';

  @override
  String get coreRestoringLink => 'جارٍ استعادة الاتصال بالنواة…';

  @override
  String get crashRestoreTitle => 'تمت مقاطعة الجلسة الأخيرة';

  @override
  String get restoreOnCrash => 'استعادة الجلسة بعد حدوث عطل';

  @override
  String get crashRestore => 'إعادة';

  @override
  String get crashDismiss => 'ليس الآن';

  @override
  String get overrideTitle => 'تعديلاتي';

  @override
  String get overrideEdit => 'تحرير الخوادم';

  @override
  String get overrideHide => 'إخفاء';

  @override
  String get overrideUnhide => 'عرض';

  @override
  String get overrideClear => 'إعادة ضبط التعديلات';

  @override
  String get overrideEmpty => 'لم يتم التعديل بعد';

  @override
  String get overrideCustomRules => 'القواعد الخاصة';

  @override
  String get errBenchmarkUnsupported => 'يحتاج قياس السرعة إلى نواة أحدث';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'قياس $done من $total…';
  }

  @override
  String get profiles => 'ملفات تعريف الشبكة';

  @override
  String get profilesEmpty =>
      'لا توجد ملفات شخصية بعد. قم بإنشاء واحدة لتطبيق الإعدادات تلقائيًا على الشبكات المعروفة.';

  @override
  String get profileAdd => 'إضافة ملف شخصي';

  @override
  String get profileName => 'اسم الملف الشخصي';

  @override
  String get profileSsids => 'شبكات Wi-Fi (SSID)';

  @override
  String get profileSsidsHint => 'المنزل، المكتب مفصولة بفواصل';

  @override
  String get profileGateways => 'بوابات الشبكة';

  @override
  String get profileAsns => 'أرقام AS';

  @override
  String get profileAutoApply => 'التطبيق تلقائيًا';

  @override
  String get profileAutoApplyHint => 'عند إيقاف هذا الخيار، يُطلب التأكيد قبل تطبيق ملف التعريف.';

  @override
  String get profileSnapshot => 'تذكر الإعدادات الحالية تم تطبيق الملف الشخصي';

  @override
  String get profileSnapshotDone => 'تم حفظ الإعدادات الحالية في ملف التعريف';

  @override
  String get profileDelete => 'حذف الملف الشخصي';

  @override
  String profileDeleteConfirm(Object name) {
    return 'حذف الملف الشخصي \"$name\"؟';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'تطبيق الملف الشخصي \"$name\"؟';
  }

  @override
  String get profileApply => 'تطبيق';

  @override
  String profileApplied(Object name) {
    return '\"$name\".';
  }

  @override
  String get profileUndo => 'إلغاء';

  @override
  String get profileActive => 'نشط';

  @override
  String networkNow(Object info) {
    return 'الآن: $info';
  }

  @override
  String get networkUnknown => 'معلومات الشبكة غير متاحة';

  @override
  String get profileNoTriggers => 'أضف مشغلًا واحدًا على الأقل: SSID أو البوابة أو ASN';

  @override
  String get chains => 'سلاسل الوكيل';

  @override
  String get chainsEmpty => 'لا توجد سلاسل بعد. قم بربط 2-3 خوادم بحيث تنتقل حركة المرور عبر كل منها.';

  @override
  String get chainAdd => 'السلسلة الجديدة';

  @override
  String get chainName => 'اسم السلسلة';

  @override
  String get chainPickServers => 'اختر 2-3 خوادم';

  @override
  String get chainOrderHint => 'اسحب لإعادة الترتيب: تدخل حركة المرور من الأعلى وتخرج من الأسفل.';

  @override
  String get chainTooFew => 'اختر خادمين على الأقل';

  @override
  String get chainTooMany => 'تحتوي السلسلة على 3 خوادم على الأكثر';

  @override
  String get chainEstimate => 'الكمون المقدر';

  @override
  String get chainSave => 'حفظ السلسلة';

  @override
  String get chainDelete => 'حذف السلسلة';

  @override
  String chainDeleteConfirm(Object name) {
    return 'حذف السلسلة \"$name\"؟';
  }

  @override
  String get chainUnsupported => 'لا يستطيع المحرك الحالي بناء السلاسل';

  @override
  String get chainHopMissing => 'أحد خوادم السلسلة لم يعد متاحًا';

  @override
  String chainHop(Object n) {
    return 'القفزة $n';
  }

  @override
  String get chainEntry => 'الدخول';

  @override
  String get chainExit => 'الخروج';

  @override
  String get sync => 'مزامنة الجهاز';

  @override
  String get syncDevices => 'أجهزتي';

  @override
  String get syncEmpty => 'لا توجد أجهزة مقترنة. قم بإقران جهاز آخر عبر الشبكة المحلية.';

  @override
  String get syncPair => 'إقران الجهاز';

  @override
  String get syncShowCode => 'أظهر الكود الخاص بي';

  @override
  String get syncScanCode => 'رمز المسح';

  @override
  String get syncRevoke => 'انسحاب';

  @override
  String syncRevokeConfirm(Object name) {
    return 'إلغاء \"$name\"؟';
  }

  @override
  String syncLastSync(Object time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get syncNever => 'أبدًا';

  @override
  String get syncNoLan => 'يجب أن تكون الأجهزة على نفس الشبكة المحلية';

  @override
  String get syncPaired => 'تم إقران الجهاز';

  @override
  String get syncPairingTitle => 'إقران مع هذا الجهاز';

  @override
  String get syncWaiting => 'في انتظار الجهاز الآخر...';

  @override
  String get syncSecureNote => 'قناة مشفرة من طرف إلى طرف. لا حسابات ولا خوادم سحابية.';

  @override
  String get zapretWithVpn => 'تجاوز تصفية DPI لحركة مرور الشبكة المباشرة';

  @override
  String get zapretWithVpnHint =>
      'يشغّل zapret إلى جانب نفق VPN: تمر حركة النفق عبر VPN، وتمر الحركة المباشرة عبر مسار تجاوز الحجب.';

  @override
  String get chainDuplicate => 'يمكن لكل خادم أن يظهر مرة واحدة فقط';

  @override
  String get edit => 'تحرير';

  @override
  String get remove => 'إزالة';

  @override
  String get autoSwitchOnDegrade => 'التبديل التلقائي عند التدهور';

  @override
  String get autoSwitchOnDegradeDetail =>
      'إذا تباطأ الخادم المحدد كثيرًا أو توقف عن الاستجابة، ينتقل Sora إلى أفضل خادم حسب القياسات، بما لا يزيد عن مرة واحدة كل 10 دقائق.';

  @override
  String get tunStackMixed => 'مختلط';

  @override
  String get tunStackSystem => 'النظام';

  @override
  String get customServerAdd => 'إضافة خادم مخصص';

  @override
  String get customServers => 'خوادمي';

  @override
  String get customServerName => 'الاسم';

  @override
  String get customServerNameHint => 'على سبيل المثال: خادم VPS الخاص بي';

  @override
  String get customServerNameRequired => 'أدخل الاسم';

  @override
  String get customServerAddress => 'العنوان';

  @override
  String get customServerAddressHint => 'example.com أو 192.0.2.1';

  @override
  String get customServerAddressRequired => 'أدخل عنوان الخادم';

  @override
  String get customServerAddressInvalid => 'عنوان غير صالح';

  @override
  String get customServerPort => 'المنفذ';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'يجب أن يكون المنفذ رقمًا من 1 إلى 65535';

  @override
  String get customServerProtocol => 'البروتوكول';

  @override
  String get customServerCredentials => 'معلومات تسجيل الدخول';

  @override
  String get customServerOptional => 'اختياري';

  @override
  String get customServerShowSecret => 'إظهار السر';

  @override
  String get customServerHideSecret => 'إخفاء السر';

  @override
  String get customServerBadge => 'مخصص';

  @override
  String customServerDeleteConfirm(String name) {
    return 'حذف الخادم \"$name\"؟';
  }

  @override
  String get customServerEmptyHint => 'إضافة خادم يدويًا: العنوان والمنفذ والبروتوكول';

  @override
  String get customServerTest => 'الاختبار';

  @override
  String get leakTestTitle => 'اختبار تسرب البيانات';

  @override
  String get leakTestIntro =>
      'يتحقق مما إذا كانت حركة البيانات قد تغادر الجهاز خارج النفق: طلبات DNS وICMP المباشرة، وخروج IPv6، ومحللات النظام. شغّل الاختبار أثناء الاتصال.';

  @override
  String get leakTestRun => 'تحقق';

  @override
  String get leakTestCancel => 'إلغاء';

  @override
  String get leakTestNeedsConnection => 'اتصل بـ VPN لاختبار تسرب البيانات.';

  @override
  String leakTestProgress(int count) {
    return 'الاختبارات المنجزة: $count';
  }

  @override
  String get leakTestAllClear => 'لم يتم العثور على أي تسريبات';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عُثر على # تسرب',
      many: 'عُثر على # تسربًا',
      few: 'عُثر على # تسربات',
      two: 'عُثر على تسربين (#)',
      one: 'عُثر على تسرب واحد (#)',
      zero: 'لم يُعثر على تسربات (#)',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'الإصلاح';

  @override
  String get leakTestFixedNote => 'مفتاح الإيقاف مفعّل. أعد الاختبار للتحقق.';

  @override
  String get leakTestCheckDirectDns => 'مباشر DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP الصدى';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'محللات أسماء النظام';

  @override
  String get leakTestCheckTunnelConnectivity => 'اتصال النفق';

  @override
  String get leakTestCheckTunnelDns => 'DNS عبر النفق';

  @override
  String get noticeDegraded => 'تباطأ الخادم، فانتقل Sora إلى أفضل خادم حسب القياسات';

  @override
  String get obfs => 'تمويه حركة البيانات';

  @override
  String get syncCodeExpired => 'انتهت صلاحية الرمز';

  @override
  String get syncDaemonFailed => 'لا يمكن بدء خدمة المزامنة';

  @override
  String get syncDaemonMissing => 'لم يتم العثور على المكون sora-sync. أعد تثبيت التطبيق لتمكين مزامنة الجهاز.';

  @override
  String get syncDaemonStarting => 'بدء خدمة المزامنة...';

  @override
  String get syncErrAuth => 'رفضت خدمة المزامنة رمز الوصول. أعد تشغيل التطبيق وحاول مرة أخرى.';

  @override
  String get syncErrNotFound => 'لم يعد الجهاز مقترنًا';

  @override
  String get syncErrPairingActive => 'جلسة الاقتران مفتوحة بالفعل';

  @override
  String get syncErrUnreachable => 'الجهاز الآخر لم يرد. تأكد من وجوده على نفس الشبكة وإظهار الكود الخاص به.';

  @override
  String get syncError => 'خطأ في المزامنة';

  @override
  String syncExpiresIn(String duration) {
    return 'تنتهي صلاحية الرمز بعد $duration';
  }

  @override
  String get syncJoining => 'الاقتران بالجهاز...';

  @override
  String get syncLegacyCleared =>
      'لم يتم إقران قائمة الأجهزة القديمة مطلقًا، لذلك تمت محوها. قم بإقران أجهزتك مرة أخرى، بشكل حقيقي هذه المرة.';

  @override
  String get syncNewCode => 'كود جديد';

  @override
  String syncPairedWith(String name) {
    return 'مقترن بـ $name';
  }

  @override
  String get syncRetry => 'كرر';

  @override
  String get syncStopShowing => 'إخفاء الرمز';

  @override
  String get syncSyncNow => 'مزامنة الآن';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'تم استلام $pulled، إرسال $pushed';
  }

  @override
  String get syncResultTitle => 'نتيجة المزامنة';

  @override
  String get syncPulled => 'تم الاستلام';

  @override
  String get syncPushed => 'تم الإرسال';

  @override
  String get syncNoChanges => 'لم يتم اكتشاف أي تغييرات';

  @override
  String get syncDocKindSubscriptions => 'الاشتراكات';

  @override
  String get syncDocKindSettings => 'إعدادات التطبيق';

  @override
  String get syncDocKindOverrides => 'تجاوزات إعدادات الاشتراكات';

  @override
  String get syncDocKindProfiles => 'ملفات تعريف الشبكة';

  @override
  String get syncDocKindChains => 'سلاسل الوكيل';

  @override
  String syncFrom(String name) {
    return 'من $name';
  }

  @override
  String get syncThisDevice => 'هذا الجهاز';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'لـ Shadowsocks: الطريقة:كلمة المرور، مثل chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => 'التقاط الحزمة';

  @override
  String get diagnosticEvents => 'أحداث ويندوز';

  @override
  String get diagnosticCapture => 'التقاط لمدة 10 ثانية';

  @override
  String get diagnosticRequiresTun => 'يحتاج التقاط الحزم إلى اتصال Sora TUN نشط.';

  @override
  String get diagnosticUnavailable => 'هذا التشخيص غير متوفر على هذا النظام الأساسي.';

  @override
  String get extErrRevoked => 'سحب فريق Sora هذا الإصدار من الإضافة لأنه غير آمن أو معطّل.';

  @override
  String get extErrRevocationsExpired =>
      'تعذّر تحديث قائمة الإضافات المسحوبة. التثبيت متوقف حتى تُحدَّث: تحقّق من الشبكة وحاول مجددًا.';

  @override
  String extRevokedDisabled(String names) {
    return 'تم إيقاف الإضافات المسحوبة: $names';
  }

  @override
  String get customServerWgPrivateKey => 'المفتاح الخاص';

  @override
  String get customServerWgAddresses => 'عناوين الواجهة';

  @override
  String get customServerWgPeerKey => 'المفتاح العام للخادم';

  @override
  String get customServerWgPresharedKey => 'المفتاح المشترك';

  @override
  String get customServerWgAllowedIps => 'عناوين IP المسموح بها';

  @override
  String get customServerWgKeepalive => 'Keepalive بالثواني';

  @override
  String get customServerWgKeyInvalid => 'يجب أن يكون المفتاح 32 بايت بترميز base64 كما يطبعه wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'أدخل بادئات مفصولة بفواصل مثل 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'أدخل عدد ثوانٍ من 0 إلى 65535.';

  @override
  String get strictKillSwitch => 'مفتاح إيقاف صارم';

  @override
  String get strictKillSwitchWarning =>
      'بعد الاتصال، يحظر حركة البيانات خارج VPN حتى بعد التعطل أو إعادة التشغيل أو إغلاق التطبيق. لا تعود إمكانية الوصول إلا بقطع الاتصال أو تعطيل هذا الخيار. بعد إعادة تشغيل الجهاز، يُستأنف الحظر فقط إذا كان الاتصال عند بدء التشغيل مفعّلاً.';

  @override
  String get extWorkerFailed => 'فشلت المهمة الخلفية للإضافة. راجع سجل الإضافة.';

  @override
  String get extAssetRejected => 'تم رفض ملف الإضافة: ألوان غير مقروءة أو قواعد غير صالحة.';
}
