// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class SFa extends S {
  SFa([String locale = 'fa']) : super(locale);

  @override
  String get stateOff => 'متصل نیست';

  @override
  String get stateConnecting => 'اتصال';

  @override
  String get stateConnected => 'متصل شد';

  @override
  String get stateReconnecting => 'اتصال مجدد';

  @override
  String get stateDisconnecting => 'قطع شدن';

  @override
  String get coreMissing => 'سرویس Sora پاسخ نمی دهد';

  @override
  String get serverAuto => 'سریع ترین';

  @override
  String get serverBypass => 'بدون سرور';

  @override
  String get addSubscription => 'اشتراک اضافه کنید';

  @override
  String get servers => 'سرورها';

  @override
  String get settings => 'تنظیمات';

  @override
  String get subscription => 'اشتراک';

  @override
  String get subscriptionLink => 'لینک اشتراک';

  @override
  String get add => 'اضافه کنید';

  @override
  String get refresh => 'به روز رسانی';

  @override
  String get rename => 'تغییر نام دهید';

  @override
  String get delete => 'حذف کنید';

  @override
  String get cancel => 'لغو کنید';

  @override
  String get save => 'ذخیره کنید';

  @override
  String get name => 'نام';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" حذف شود؟';
  }

  @override
  String get routes => 'مسیرها';

  @override
  String get presetGlobal => 'همه چیز از طریق VPN';

  @override
  String get presetRu => 'روسیه مستقیم';

  @override
  String get presetIr => 'ایران مستقیم';

  @override
  String get presetCn => 'چین مستقیم';

  @override
  String get blockAds => 'مسدود کردن تبلیغات';

  @override
  String get killSwitch => 'اینترنت فقط از طریق VPN';

  @override
  String get engine => 'موتور';

  @override
  String get engineAuto => 'خودکار';

  @override
  String get animations => 'انیمیشن ها';

  @override
  String get logs => 'ورود به سیستم';

  @override
  String get about => 'درباره';

  @override
  String get logsAll => 'همه';

  @override
  String get logsImportant => 'مهم است';

  @override
  String get logsErrors => 'خطاها';

  @override
  String get search => 'جستجو کنید';

  @override
  String get export => 'ذخیره در فایل';

  @override
  String get clear => 'پاک کردن';

  @override
  String get logsEmpty => 'اینجا هیچی';

  @override
  String get connEmpty => 'بدون اتصال';

  @override
  String appVersion(String version) {
    return 'نسخه $version';
  }

  @override
  String get notInstalled => 'نصب نشده است';

  @override
  String get sourceCode => 'کد منبع';

  @override
  String get license => 'مجوز';

  @override
  String usage(String used, String total) {
    return '$used از $total';
  }

  @override
  String until(String date) {
    return 'تا $date';
  }

  @override
  String get expired => 'منقضی شده است';

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
    return '$n کیلوبایت';
  }

  @override
  String bytesMB(String n) {
    return '$n مگابایت';
  }

  @override
  String bytesGB(String n) {
    return '$n گیگابایت';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'مشکلی پیش آمد';

  @override
  String get errCore => 'سرویس Sora پاسخ نمی دهد';

  @override
  String get errAuth => 'دسترسی به سرویس Sora وجود ندارد';

  @override
  String get errVersion => 'به روز رسانی Sora: برنامه و سرویس نسخه های مختلف هستند';

  @override
  String get errBusy => 'صبر کنید، دستور قبلی همچنان در حال اجرا است';

  @override
  String get errEngineMissing => 'هیچ موتوری برای این سرور پیدا نشد';

  @override
  String get errEngineStart => 'موتور روشن نشد';

  @override
  String get errEngineStopped => 'موتور خاموش شد';

  @override
  String get errTunnel => 'هیچ مجوزی برای ایجاد اتصال VPN وجود ندارد';

  @override
  String get errServers => 'سرور با یک خطا پیکربندی شده است';

  @override
  String get errNetwork => 'دسترسی به سرور امکان پذیر نیست';

  @override
  String get errTimeout => 'سرور به موقع جواب نداد';

  @override
  String get errFirewall => 'اینترنت خارج از VPN مسدود نشد';

  @override
  String get errSubFetch => 'اشتراک بارگیری نشد';

  @override
  String get errSubFormat => 'این لینک اشتراک نیست';

  @override
  String get errSubEmpty => 'اشتراک هیچ سروری ندارد';

  @override
  String get errSubDuplicate => 'این اشتراک قبلاً اضافه شده است';

  @override
  String get errSubLimit => 'اشتراک های بسیار زیاد';

  @override
  String get errSubScheme => 'پیوند باید با https:// شروع شود';

  @override
  String get errSecretStore => 'فضای ذخیره سازی Sora آسیب دیده یا در دسترس نیست';

  @override
  String get errNoServers => 'برای اتصال اشتراکی اضافه کنید';

  @override
  String get connections => 'اتصالات';

  @override
  String get close => 'بستن';

  @override
  String get chainDirect => 'مستقیم';

  @override
  String get chainBlocked => 'مسدود شده است';

  @override
  String get theme => 'موضوع';

  @override
  String get themeSystem => 'مطابق سیستم';

  @override
  String get themeLight => 'نور';

  @override
  String get themeDark => 'تاریک';

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'مطابق سیستم';

  @override
  String get sectionConnection => 'اتصال';

  @override
  String get sectionNoServer => 'بدون سرور';

  @override
  String get sectionPing => 'پینگ کنید';

  @override
  String get sectionLog => 'تشخیص';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'خودکار';

  @override
  String get dnsHint => 'آدرس ها، با کاما از هم جدا شده اند';

  @override
  String get fragment => 'تکه تکه شدن TLS';

  @override
  String get fragmentPackets => 'چه چیزی تقسیم شود';

  @override
  String get fragmentLength => 'اندازه قطعه';

  @override
  String get fragmentInterval => 'بین قطعات مکث کنید';

  @override
  String get byDefault => 'پیش فرض';

  @override
  String get rangeHint => 'مثلا 100-200';

  @override
  String get splitPos => 'تقسیم موقعیت ها';

  @override
  String get splitPosHint => 'به عنوان مثال، 1، midsld';

  @override
  String get disorder => 'سفارش مجدد قطعات';

  @override
  String get tlsRecord => 'رکورد TLS را تقسیم کنید';

  @override
  String get tlsRecordNo => 'خیر';

  @override
  String get tlsRecordSni => 'در نام سایت';

  @override
  String get tlsRecordFirst => 'بعد از اولین بایت';

  @override
  String get hostCase => 'Host case را تغییر دهید';

  @override
  String get probeMethod => 'روش';

  @override
  String get probeAuto => 'خودکار';

  @override
  String get probeEngine => 'از طریق موتور';

  @override
  String get probeConnect => 'فقط اتصال';

  @override
  String get probeUrl => 'آدرس تست';

  @override
  String get probeTimeout => 'صبر کن';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'اشتراک ها';

  @override
  String get subscriptionSettings => 'تنظیمات';

  @override
  String get userAgent => 'کاربر-عامل';

  @override
  String get autoUpdate => 'به‌روزرسانی خودکار';

  @override
  String get updateInterval => 'چند وقت یکبار';

  @override
  String get intervalProvider => 'همانطور که ارائه دهنده درخواست می کند';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'اکنون به روز رسانی کنید';

  @override
  String get logLevel => 'چه چیزی ضبط شود';

  @override
  String get levelDebug => 'همه چیز';

  @override
  String get levelInfo => 'معمولی';

  @override
  String get levelWarning => 'مهم است';

  @override
  String get levelError => 'فقط خطاها';

  @override
  String get recordDestinations => 'ثبت آدرس سایت';

  @override
  String get reset => 'تنظیمات را بازنشانی کنید';

  @override
  String get resetConfirm => 'همه تنظیمات بازنشانی شود؟';

  @override
  String get resetAction => 'بازنشانی کنید';

  @override
  String get invalidValue => 'این مقدار کار نخواهد کرد';

  @override
  String get website => 'صفحه اشتراک';

  @override
  String get providerWebsite => 'وب سایت ارائه دهنده';

  @override
  String get support => 'پشتیبانی کنید';

  @override
  String controlPortQuestion(String engine) {
    return '$engine از طریق پورت این کامپیوتر کنترل می شود. سایر برنامه ها می توانند به روشن بودن VPN بگویند.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine را انتخاب کنید';
  }

  @override
  String get rules => 'قوانین سفارشی';

  @override
  String get ruleAdd => 'قانون جدید';

  @override
  String get ruleHint => 'سایت، آی پی یا برنامه';

  @override
  String get ruleDirect => 'مستقیم';

  @override
  String get ruleProxy => 'از طریق VPN';

  @override
  String get ruleBlock => 'مسدود کردن';

  @override
  String get failover => 'شکست را روشن کنید';

  @override
  String get connectOnStart => 'در شروع وصل شوید';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'اشتراک در روزهای # به پایان می رسد',
      one: 'اشتراک در روز # به پایان می رسد',
      zero: 'اشتراک در چند ساعت به پایان می رسد',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left باقی مانده است';
  }

  @override
  String get ruleInvalid => 'این شبیه یک سایت، یک IP یا یک برنامه نیست';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سرورهای #، سریعترین',
      one: 'سرور #، سریعترین',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'حالت';

  @override
  String get tunnelProxy => 'پروکسی System';

  @override
  String get proxyAddress => 'آدرس پروکسی';

  @override
  String get copied => 'کپی شده';

  @override
  String get launchAtLogin => 'با سیستم شروع کنید';

  @override
  String get launchAtLoginDetail => 'Sora هنگام ورود به سیستم به‌طور خودکار اجرا می‌شود و در سینی سیستم باقی می‌ماند.';

  @override
  String get closeToTray => 'وقتی بسته است در سینی نگه دارید';

  @override
  String get notifications => 'اطلاعیه ها';

  @override
  String get trayOpen => 'Sora را باز کنید';

  @override
  String get trayConnect => 'اتصال';

  @override
  String get trayDisconnect => 'قطع کن';

  @override
  String get trayServer => 'سرور';

  @override
  String get trayQuit => 'از Sora خارج شوید';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state، $server';
  }

  @override
  String get noticeInTray => 'Sora هنوز در سینی است';

  @override
  String get noticeInTrayBody => 'از منوی نماد آن خارج شوید';

  @override
  String get noticeLost => 'اتصال قطع شد';

  @override
  String get noticeLostBody => 'Sora دوباره در حال وصل شدن است';

  @override
  String get noticeRestored => 'دوباره وصل شد';

  @override
  String get noticeFailed => 'وصل نشد';

  @override
  String get noticeBackup => 'سرور اصلی جواب نداد. پشتیبان گیری ترافیک را حمل می کند';

  @override
  String get noticeNext => 'سرور جواب نداد. بعدی ترافیک را حمل می کند';

  @override
  String get noticeMainBack => 'سرور اصلی دوباره پاسخ می دهد و ترافیک را حمل می کند';

  @override
  String get noticeSubscription => 'اشتراک';

  @override
  String get importTitle => 'این اشتراک اضافه شود؟';

  @override
  String get importSealed =>
      'این پیوند برای Happ رمزگذاری شده است و فقط Happ می تواند آن را بخواند. از ارائه دهنده خود لینک اشتراک ساده را بخواهید.';

  @override
  String get understood => 'باشه';

  @override
  String get noAnswer => 'بدون پاسخ';

  @override
  String get home => 'صفحه اصلی';

  @override
  String get navRules => 'قوانین';

  @override
  String get navConnections => 'اتصالات';

  @override
  String get navLogs => 'سیاههها';

  @override
  String get navAbout => 'درباره';

  @override
  String get sidebarToggle => 'نوار کناری را تغییر دهید';

  @override
  String get more => 'بیشتر';

  @override
  String get less => 'کمتر';

  @override
  String get notificationsEmpty => 'رویدادهای اتصال و اشتراک در اینجا ظاهر می شوند';

  @override
  String get retryConnect => 'اتصال را دوباره امتحان کنید';

  @override
  String get openLogs => 'لاگ ها را باز کنید';

  @override
  String get tourReplay => 'راهنما را دوباره نشان دهید';

  @override
  String tourStep(int step) {
    return 'مرحله $step از 5';
  }

  @override
  String get tourBack => 'برگشت';

  @override
  String get tourNext => 'بعدی';

  @override
  String get tourSkip => 'پرش کنید';

  @override
  String get tourFinish => 'انجام شد';

  @override
  String get tourAdd => 'پیوند اشتراک ارائه دهنده خود را اضافه کنید.';

  @override
  String get tourServer => 'یک سرور انتخاب کنید \"سریعترین\" یکی را برای شما انتخاب می کند.';

  @override
  String get tourConnect => 'برای اتصال یا قطع ارتباط اینجا را کلیک کنید.';

  @override
  String get tourMode => 'یک حالت را انتخاب کنید. در صورت قطع شدن VPN، سوئیچ Kill اینترنت را مسدود می کند.';

  @override
  String get tourSettings => 'تنظیمات را باز کنید. می توانید این راهنما را دوباره در آنجا پخش کنید.';

  @override
  String get chooseProgram => 'یک برنامه را انتخاب کنید';

  @override
  String get installedApps => 'برنامه های نصب شده';

  @override
  String get runningProcesses => 'فرآیندهای در حال اجرا';

  @override
  String get programsEmpty => 'هیچ برنامه ای یافت نشد نام دیگری را امتحان کنید.';

  @override
  String get selectExe => 'یک فایل exe را انتخاب کنید';

  @override
  String get speedtest => 'سرعت';

  @override
  String get speedtestSearch => 'یک سرویس پیدا کنید';

  @override
  String get speedtestEmpty => 'هیچ مسابقه ای وجود ندارد. جستجو را تغییر دهید';

  @override
  String get speedtestBackToList => 'بازگشت به خدمات';

  @override
  String get speedtestOpenBrowser => 'در مرورگر باز کنید';

  @override
  String get speedtestUnavailable =>
      'مرورگر تعبیه شده نمی تواند راه اندازی شود. سرویس را در مرورگر سیستم خود باز کنید.';

  @override
  String get speedtestPageFailed =>
      'صفحه نمی تواند بارگیری شود. آن را دوباره بارگیری کنید یا سرویس را در مرورگر سیستم خود باز کنید.';

  @override
  String get speedtestExternalFailed => 'مرورگر سیستم باز نشد. دوباره امتحان کنید.';

  @override
  String get modes => 'حالت ها';

  @override
  String get proxyShort => 'پروکسی';

  @override
  String get tunMode => 'تمام ترافیک (TUN)';

  @override
  String get checkUpdates => 'به روز رسانی را بررسی کنید';

  @override
  String get updates => 'به روز رسانی برنامه';

  @override
  String updateAvailable(String version) {
    return 'نسخه $version موجود است';
  }

  @override
  String get updateOpenAbout => 'مشاهده به روز رسانی';

  @override
  String updateNotes(String version) {
    return 'تغییرات در $version';
  }

  @override
  String get updateCheck => 'به روز رسانی را بررسی کنید';

  @override
  String get updateChecking => 'در حال بررسی...';

  @override
  String get updateNoNotes => 'انتشار هیچ یادداشتی ندارد.';

  @override
  String get updateDropWarning =>
      'در حالی که Sora و به روز رسانی اصلی آن، اتصال VPN برای چند ثانیه قطع می شود. ادامه دهید؟';

  @override
  String get updateWaitConnection => 'منتظر بمانید تا اتصال VPN و هسته آماده شود.';

  @override
  String get updateDownloading => 'دانلود و تایید فایل ها...';

  @override
  String get updateInstalling => 'در حال آماده سازی به روز رسانی یا انتظار برای احراز هویت سرپرست...';

  @override
  String get updateNetworkError => 'آپدیت دانلود نشد دوباره امتحان کنید.';

  @override
  String get updateReleaseError => 'داده‌های انتشار یا فایل‌های مورد نیاز وجود ندارد یا نامعتبر است.';

  @override
  String get updateChecksumError => 'دانلود با SHA256SUMS مطابقت ندارد. هیچی نصب نشد';

  @override
  String get updateInstallError => 'آپدیت تمام نشد. احراز هویت ممکن است لغو شده باشد.';

  @override
  String get updateUnsupported =>
      'این فایل اجرایی متعلق به یک جفت بسته پشتیبانی شده Sora نیست. از دستورالعمل های نصب نسخه استفاده کنید.';

  @override
  String get updateManual =>
      'این دستور را در ترمینال اجرا کنید تا هر دو بسته تایید شده نصب شوند، سپس Sora را دوباره باز کنید. فایل ها در دایرکتوری دانلود می مانند. اتصال VPN قطع می شود.';

  @override
  String get updateSignaturePending => 'فایل‌های به‌روزرسانی با چک‌سام‌های منتشرشده همراه نسخه مقایسه می‌شوند.';

  @override
  String get updateManualSigWarning =>
      'فایل‌های زیر با چک‌سام‌های نسخه مطابقت دارند. اگر آن‌ها را از نسخهٔ رسمی دانلود کرده‌اید، فرمان را اجرا کنید.';

  @override
  String get updateVersionRevoked => 'توسعه دهنده این نسخه را پس گرفته است. لطفا منتظر انتشار تصحیح شده باشید.';

  @override
  String get updateRolloutPending => 'نسخه جدیدتر به تدریج در حال انتشار است و به طور خودکار به شما ارائه می شود.';

  @override
  String updateRollbacking(String version) {
    return 'بازگشت به نسخه $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'به‌روزرسانی $version از بررسی سلامت عبور نکرد، بنابراین Sora به $fromVersion بازگشت.';
  }

  @override
  String get updateRollbackError =>
      'بازگشت خودکار شکست خورد. اگر نسخه جدید کار نمی کند، نسخه قبلی را دوباره به صورت دستی نصب کنید.';

  @override
  String get updateRollbackCacheError =>
      'یک کپی بازگشتی تأیید شده از نسخه فعلی تهیه نشد، بنابراین به‌روزرسانی نصب نشد.';

  @override
  String get updateCopyCommand => 'دستور کپی';

  @override
  String get updateChecksDisabled => 'بررسی خودکار در تنظیمات غیرفعال است.';

  @override
  String get updateInstalled => 'آپدیت نصب شد Sora را دوباره باز کنید.';

  @override
  String get projectLinks => 'پروژه';

  @override
  String get githubReleases => 'منتشر و دانلود می شود';

  @override
  String get telegramChannel => 'کانال Telegram';

  @override
  String get licenses => 'مجوزها';

  @override
  String get componentLicenses => 'مجوزهای کامپوننت';

  @override
  String get collapseServers => 'جمع کردن سرورها';

  @override
  String get expandServers => 'سرورها را گسترش دهید';

  @override
  String get hideDescription => 'مخفی کردن توضیحات';

  @override
  String get showDescription => 'نمایش توضیحات';

  @override
  String get pendingConnectionChanges => 'برای اعمال این تغییرات دوباره وصل شوید.';

  @override
  String get reconnectNow => 'درخواست کنید و دوباره وصل شوید';

  @override
  String get errEngineUnsupported =>
      'موتور انتخاب شده از این نمایه یا تنظیمات پشتیبانی نمی کند. Auto یا موتور سازگار را انتخاب کنید.';

  @override
  String get errRestore => 'پاکسازی اتصال ناقص بود. قطع ارتباط مجدد را امتحان کنید. برای جزئیات به لاگ مراجعه کنید';

  @override
  String get errSessionEnded => 'این جلسه قبلاً به پایان رسیده است. وضعیت اتصال را بازخوانی کنید.';

  @override
  String get retryDisconnect => 'دوباره سعی کنید اتصال را قطع کنید';

  @override
  String get tunStack => 'پشته TUN';

  @override
  String get modesInfo => 'درباره حالت ها';

  @override
  String get modesGuideTitle => 'حالت ها و موتورها';

  @override
  String get modesGuide =>
      'اگر مطمئن نیستید که سرور شما به کدام موتور نیاز دارد، Auto را انتخاب کنید. Sora نمایه و تنظیمات را قبل از اتصال بررسی می کند. یک موتور نمی تواند پهنای باند طرح شما را افزایش دهد: عملکرد به سرور، مسیر، پروتکل و شبکه بستگی دارد.\n\n## حالت ها\n\n### همه ترافیک (TUN)\n\nSora یک رابط شبکه مجازی ایجاد می کند و ترافیک برنامه ها از جمله TCP و UDP را از طریق آن هدایت می کند. از این حالت برای Telegram، بازی ها و صدای Discord استفاده کنید. قوانین می توانند سایت ها یا برنامه های خاصی را مستقیما ارسال کنند یا آنها را مسدود کنند. سرویس شبکه به مجوز و سروری نیاز دارد که از پروتکل مورد نیاز پشتیبانی کند.\n\n### پروکسی System\n\nSora یک پروکسی محلی HTTP/SOCKS را پیکربندی می کند. برنامه هایی که به تنظیمات پراکسی سیستم احترام می گذارند از آن استفاده می کنند. برنامه های کاربردی با پشته شبکه خود ممکن است مستقیماً متصل شوند. UDP و تماس های صوتی به طور کلی به TUN نیاز دارند. این حالت برای مرورگرها و برنامه های دارای پشتیبانی از پروکسی مناسب است.\n\n### بدون سرور\n\nدر Linux، Sora از [zapret](https://github.com/bol-van/zapret) برای تقسیم و تغییر شکل درخواست‌های HTTP/TLS و دور زدن برخی از بررسی‌های DPI استفاده می‌کند. IP شما ثابت می ماند و اتصالات مستقیماً به وب سایت می روند. نتایج به ارائه دهنده شما و روش مسدود کردن بستگی دارد.\n\nادغام فعلی از tpws برای HTTP و TLS روی TCP استفاده می کند. از مسدود کردن IP یا رله UDP عبور نمی کند و نمی تواند اتصالات Telegram MTProto را تضمین کند. از یک سرور VPN با TUN برای صدای Discord، تماس های Telegram و این نوع محدودیت ها استفاده کنید.\n\n## موتورها\n\n### خودکار\n\nSora موتور نصب شده ای را انتخاب می کند که از کل طرح اتصال پشتیبانی می کند: پروتکل های سرور، حمل و نقل، گروه ها، تکه تکه شدن و حالت. انتخاب دستی ناسازگار قبل از توقف اتصال فعلی رد می شود. Auto یا موتور دیگری را انتخاب کنید و دوباره تنظیمات را اعمال کنید.\n\n### sing-box\n\nبسته‌های جدید Sora شامل [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)، چنگال [sing-box](https://github.com/SagerNet/sing-box)، اضافه کردن XHTTP و VLESS Encryption سمت مشتری است. Sora ساخت و قابلیت های آن را تشخیص می دهد. یک ساخت بالادستی بدون XHTTP این قابلیت را به تنهایی از نام خود به دست نمی آورد.\n\nپروتکل‌های پشتیبانی‌شده شامل VLESS، VMess، Trojan، Shadowsocks، Hysteria2، TUIC، AnyTLS، WireGuard و پارامترهای AmneziaWG 1.x/2.x هستند که Sora می‌تواند وارد کند. پروفایل کامل Xray JSON به Xray نیاز دارد. وارد کردن فیلدهای جدید AWG 3.x هنوز امکان‌پذیر نیست. sing-box از یک درگاه کنترل محلی محافظت‌شده با گذرواژه استفاده می‌کند که برنامه‌های دیگر روی رایانه می‌توانند آن را شناسایی کنند.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) از تکه تکه شدن VLESS، REALITY، XHTTP، VLESS Encryption و TLS پشتیبانی می کند. همچنین پروفیل های کامل ارائه دهنده Xray را اجرا می کند و در عین حال مسیریابی و گروه های آنها را حفظ می کند. چنین پروفایل هایی را نمی توان بدون تغییر رفتار به طور خودکار به موتور دیگری تبدیل کرد.\n\nXray همراه، تنظیمی را که تأیید گواهی TLS را غیرفعال می‌کرد («allowInsecure») حذف کرد. خودکار sing-box یا mihomo را برای سرورهای معمولی که به این تنظیم نیاز دارند انتخاب می کند. انتخاب Xray به صورت دستی ناسازگاری را قبل از توقف اتصال فعلی گزارش می کند. نمایه‌های کامل JSON قدیمی‌تر به نمایه ارائه‌دهنده به‌روزرسانی شده با گواهی یا پین گواهی قابل تأیید نیاز دارند.\n\n### mihomo\n\n[mihomo] (https://github.com/MetaCubeX/mihomo) از گروه‌های بازگشتی و متعادل‌کننده بار سفارش‌داده‌شده، XHTTP و AmneziaWG پشتیبانی می‌کند. زمانی آن را انتخاب کنید که خطای خودکار به سرور پشتیبان مهم است. تنظیم تکه تکه شدن TLS Sora با این موتور در دسترس نیست.\n\n## سازگاری در Sora\n\n| ویژگی | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN و TCP/UDP | بله | بله | بله |\n| XHTTP | بله | بله | بله |\n| VLESS Encryption | بله | بله | بله |\n| پروفایل کامل Xray | نه | بله | نه |\n| TUIC / AnyTLS | هر دو | نه | TUIC |\n| تکه تکه شدن TLS | بله | بله | نه |\n| AmneziaWG 1.x/2.x | بله¹ | نه | بله |\n| گروه بازگشتی سفارشی | نه | No² | بله |\n\n¹ نمایه‌های دارای J1/J2/J3/Itime از mihomo استفاده می‌کنند. این زمینه ها هرگز نباید بی سر و صدا کنار گذاشته شوند. ² برای گروهی از نمایه‌های کامل Xray، برنامه یک نمایه پشتیبان انتخاب می‌کند. پشتیبانی بستگی به ساخت نصب شده دارد. نسخه آن را در About چک کنید.\n\n## پشته TUN\n\nپشته TCP و UDP را در داخل رابط مجازی کنترل می کند. در پانل حالت ها، Xray و mihomo gVisor، System، Mixed و MIPS را ارائه می دهند. هر موتور اولویت خود را ذخیره می کند. پروکسی System و حالت‌های بدون سرور از این اولویت استفاده نمی‌کنند.\n\n- **Mixed** - TCP از پشته سیستم استفاده می کند، در حالی که gVisor UDP را کنترل می کند. این پیش‌فرض mihomo در Linux است. در Windows، Xray و mihomo به‌طور پیش‌فرض از MIPS استفاده می‌کنند.\n- **System** - از پشته سیستم استفاده می کند. اگر برنامه های شبکه با مشکل مواجه شدند، گزینه دیگری را امتحان کنید.\n- **gVisor** - ترافیک در فضای کاربران را کنترل می کند.\n- **MIPS**: پشته IP اختصاصی mihomo، موجود در نسخه همراه 1.19.32.\n\nدر Linux، Xray به طور پیش فرض از gVisor داخلی خود استفاده می کند. System، Mixed و MIPS در Linux از mihomo به عنوان موتور TUN استفاده می‌کنند و TCP و UDP را به Xray از طریق پیوند محلی SOCKS تأیید شده ارسال می‌کنند. Xray پروتکل، مشخصات ارائه دهنده و مسیریابی را حفظ می کند. این سه گزینه به mihomo نصب شده نیاز دارند. در Windows، Xray برای هر چهار پشته TUN از mihomo 1.19.32 یا جدیدتر استفاده می‌کند. پروتکل‌ها و مسیریابی در Xray باقی می‌مانند. قوانین برنامه‌ها در این ترکیب فقط اتصال مستقیم و مسدودسازی را پشتیبانی می‌کنند؛ در Linux این قوانین به gVisor داخلی Xray نیاز دارند.\n\nپل فرآیند دوم را اجرا می کند. در سه اندازه گیری غیرفعال در Linux، از حافظه فیزیکی 32 تا 36 مگابایت بیشتر از Xray TUN استفاده کرد. این بار دانلود را اندازه نمی‌گیرد: هزینه‌های CPU و حافظه به اتصالات بستگی دارد. sing-box انتخابگر پشته ندارد. هیچ پشته ای عملکرد بهتر را در هر شبکه ای تضمین نمی کند. یک پشته را انتخاب کنید و Apply را انتخاب کنید و دوباره متصل شوید تا آن را در شبکه خود امتحان کنید.\n\n## اعمال تنظیمات\n\nانتخاب سرور به طور خودکار دوباره متصل می شود. تنظیمات حالت، موتور، DNS و قوانین بلافاصله ذخیره می شوند. در طول یک اتصال فعال، روی Apply کلیک کنید و دوباره متصل شوید تا از آنها استفاده کنید. راه اندازی مجدد موتور ممکن است بارگیری ها و تماس ها را قطع کند. کلیک های مکرر اتصالات موازی را شروع نمی کنند. قطع کردن انتقال به پایان می رسد و اتصال آزاد می شود.\n\nاینترنت فقط از طریق VPN ترافیک مستقیم را هنگام سقوط یک تونل مسدود می کند. کل دستگاه را تحت تأثیر قرار می دهد. قطع صریح قوانین Sora را حذف می کند. اگر پاکسازی تمام نشد، دوباره سعی کنید اتصال را قطع کرده و گزارش را باز کنید.\n\n## مستندات پروژه\n\n- [sing-box-lx: پیکربندی و پشتیبانی] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [مستندات sing-box] (https://sing-box.sagernet.org/)\n- [اسناد Xray] (https://xtls.github.io/)\n- [مستندات mihomo] (https://wiki.metacubex.one/)\n- [zapret: عملیات و محدودیت ها] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'سرورها را بررسی کنید';

  @override
  String get extensions => 'برنامه های افزودنی';

  @override
  String extRatingLabel(String rating) {
    return 'رتبه $rating از 5';
  }

  @override
  String extByAuthor(String author) {
    return 'توسط $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'نصب: $count';
  }

  @override
  String get extInstallOne => '1 نصب';

  @override
  String get extBadgeVerified => 'تأیید شد';

  @override
  String get extBadgeTop => 'محبوب ترین این هفته';

  @override
  String get extBadgeNew => 'جدید';

  @override
  String get extBadgeStaff => 'تیم Sora';

  @override
  String get extSideloadShort => 'نه از کاتالوگ';

  @override
  String get extSideloadWarning =>
      'این برنامه افزودنی از کاتالوگ تیم نیست. فقط نویسنده کلید خود را تضمین کرده است: فقط در صورتی آن را نصب کنید که به نویسنده اعتماد دارید.';

  @override
  String extInstallTitle(String name) {
    return 'نصب «$name»';
  }

  @override
  String extUpdateTitle(String name) {
    return 'به‌روزرسانی «$name»';
  }

  @override
  String get extPermissionsIntro => 'این برنامه افزودنی قادر خواهد بود:';

  @override
  String get extPermissionsWidened => 'به روز رسانی مجوزهای جدید را می خواهد:';

  @override
  String get extDangerousAck => 'می‌دانم که این مجوزها جدی هستند';

  @override
  String get extInstall => 'نصب';

  @override
  String get extUpdate => 'به‌روزرسانی';

  @override
  String get extCancel => 'لغو';

  @override
  String get extConfirm => 'تأیید کنید';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'کاتالوگ';

  @override
  String get extInstalled => 'برنامه های افزودنی نصب شده';

  @override
  String get extSearchHint => 'جستجوی برنامه‌های افزودنی';

  @override
  String get extCatAll => 'همه';

  @override
  String get extCatTools => 'ابزار';

  @override
  String get extCatThemes => 'پوسته‌ها';

  @override
  String get extCatAutomation => 'اتوماسیون';

  @override
  String get extCatStats => 'آمار';

  @override
  String get extCatNetwork => 'شبکه';

  @override
  String get extSortBy => 'مرتب سازی بر اساس';

  @override
  String get extSortPopular => 'محبوب ترین';

  @override
  String get extSortRating => 'بالاترین امتیاز';

  @override
  String get extSortName => 'نام';

  @override
  String get extCatalogError => 'کاتالوگ بارگیری نشد';

  @override
  String get extRetry => 'دوباره امتحان کنید';

  @override
  String get extEmptySearch => 'چیزی پیدا نشد';

  @override
  String get extEmptyInstalled =>
      'هنوز هیچ برنامه افزودنی نصب نشده است.\nیکی را در کاتالوگ پیدا کنید یا از یک فایل نصب کنید.';

  @override
  String get extInstallFromFile => 'نصب از فایل';

  @override
  String get extInstallFromUrl => 'نصب از URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'دانلود کنید';

  @override
  String get extDownloading => 'در حال بارگیری…';

  @override
  String get extVerifying => 'در حال تأیید…';

  @override
  String get extInstalling => 'در حال نصب…';

  @override
  String get extInstallFailed => 'نصب انجام نشد';

  @override
  String get extErrSignature => 'بررسی امضا انجام نشد. ممکن است فایل آسیب دیده یا دستکاری شده باشد.';

  @override
  String get extErrManifest => 'مانیفست افزونه نامعتبر است.';

  @override
  String get extErrNetwork => 'خطای شبکه. اتصال خود را بررسی کنید و دوباره امتحان کنید.';

  @override
  String get extErrHash => 'دانلود با کاتالوگ مطابقت ندارد. ممکن است دستکاری شده باشد.';

  @override
  String extErrMinApp(String version) {
    return 'این برنامه افزودنی به نسخه برنامه $version یا جدیدتر نیاز دارد.';
  }

  @override
  String get extErrHttpsOnly => 'فقط پیوندهای https:// مجاز هستند';

  @override
  String get extErrGeneric => 'مشکلی پیش آمد. لطفا دوباره امتحان کنید.';

  @override
  String get extErrAuthorKeyChanged =>
      'این به روز رسانی با یک کلید نویسنده متفاوت از نسخه نصب شده امضا شده است، بنابراین مسدود شد. اگر به کلید جدید اعتماد دارید، برنامه افزودنی را حذف نصب کنید و دوباره آن را به صراحت نصب کنید.';

  @override
  String get extUpdateAvailable => 'به‌روزرسانی موجود است';

  @override
  String get extDisabled => 'غیرفعال';

  @override
  String extToggleEnabled(String name) {
    return '$name را فعال کنید';
  }

  @override
  String get extSearchInstalled => 'جستجوی برنامه‌های افزودنی نصب‌شده';

  @override
  String get extUpdateAll => 'به روز رسانی همه';

  @override
  String extUpdatesAvailable(int count) {
    return '$count به روز رسانی موجود است';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count به روز شد';
  }

  @override
  String get extRiskNormal => 'عادی';

  @override
  String get extRiskSensitive => 'حساس';

  @override
  String get extRiskDangerous => 'ریسک بالا';

  @override
  String get extPermissionsRemoved => 'دیگر درخواست نمی‌شود:';

  @override
  String get extUpdateFailedKept => 'نسخه قبلی هنوز نصب است.';

  @override
  String get extConflictsTitle => 'تعارضات پسوند';

  @override
  String get extConflictsIntro =>
      'این افزونه‌ها یک چیز را می‌خواهند. انتخاب کنید کدام اجرا شود؛ دیگری نصب‌شده می‌ماند.';

  @override
  String get extConflictTheme => 'تم برنامه';

  @override
  String get extConflictNetHooks => 'قلاب های شبکه';

  @override
  String extConflictWinner(String name) {
    return 'اولویت با $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'تعارضات $count به تصمیم شما نیاز دارد';
  }

  @override
  String get extConflictsResolve => 'تعارضات را حل کنید';

  @override
  String get extConflictNote =>
      'انتخاب شما روی این دستگاه ذخیره می‌شود. پوسته فوراً عوض می‌شود، اما هوک‌های شبکه در این نسخه اجرا نمی‌شوند.';

  @override
  String extVersionLabel(String version) {
    return 'نسخه $version';
  }

  @override
  String get extAuthor => 'نویسنده';

  @override
  String get extRating => 'رتبه بندی';

  @override
  String get extInstalls => 'دفعات نصب';

  @override
  String get extVersion => 'نسخه';

  @override
  String get extAbout => 'درباره این پسوند';

  @override
  String get extPermissionsTitle => 'مجوزها';

  @override
  String get extNoPermissions => 'بدون مجوزهای خاص.';

  @override
  String get extSettings => 'تنظیمات';

  @override
  String get extSaveSettings => 'ذخیرهٔ تنظیمات';

  @override
  String get extSaving => 'در حال ذخیره…';

  @override
  String extUpdateTo(String version) {
    return 'ارتقا به $version';
  }

  @override
  String get extEnabled => 'فعال';

  @override
  String extRollbackTo(String version) {
    return 'بازگشت به $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'بازگشت به نسخه $version؟';
  }

  @override
  String get extUninstall => 'حذف نصب کنید';

  @override
  String extUninstallConfirm(String name) {
    return '\"$name\" و تنظیمات آن حذف شود؟';
  }

  @override
  String get extPanelUnavailable => 'پانل در دسترس نیست. پسوند ممکن است غیرفعال یا حذف شده باشد.';

  @override
  String get extPermConnectionsRead => 'لیست اتصالات فعال را ببینید';

  @override
  String get extPermServersRead => 'فهرستی از سرورهای خود را ببینید';

  @override
  String get extPermSettingsRead => 'تنظیمات برنامه را بخوانید';

  @override
  String get extPermSettingsWrite => 'تنظیمات برنامه را تغییر دهید';

  @override
  String get extPermNotifications => 'نمایش اعلان‌ها';

  @override
  String get extPermTray => 'موارد را به منوی سینی اضافه کنید';

  @override
  String get extPermUiPanel => 'نمایش پانل های داخل برنامه';

  @override
  String get extPermThemeApply => 'تم ها را اعمال کنید';

  @override
  String get extPermRoutingRules => 'قوانین مسیریابی را اضافه کنید (بر جایی که ترافیک شبکه می رود تأثیر می گذارد)';

  @override
  String get extPermNetHooks => 'ادغام در مسیر شبکه (DPI ماژول های دور زدن)';

  @override
  String get extPermNetFetch => 'URL را از لیست مجاز درخواست کنید';

  @override
  String get extPermBackground => 'وظایف پس زمینه را اجرا کنید';

  @override
  String get extPermBackgroundDetail =>
      'کارهای برنامه ریزی شده را حتی زمانی که پانل بسته است اجرا می کند. می‌توانید آن را موقتاً متوقف کنید یا تعداد دفعات اجرای آن را در تنظیمات برنامه افزودنی تغییر دهید.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'در پس‌زمینه اجرا می‌شود';

  @override
  String get extCapNetHook => 'دور زدن محدودیت‌ها و قلاب‌های شبکه';

  @override
  String get extCapPanel => 'پانل های رابط';

  @override
  String get extCapRouting => 'قوانین مسیریابی';

  @override
  String get extCapTheme => 'پوسته‌ها';

  @override
  String get extCapWidget => 'ابزارک‌ها';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'تغییرات';

  @override
  String get extImageFailed => 'تصویر بارگیری نشد';

  @override
  String get extRatingHow => 'رتبه بندی چگونه کار می کند';

  @override
  String get extRatingHowBody =>
      'رتبه‌بندی‌ها از میانگین بیزی استفاده می‌کنند: برنامه‌های افزودنی با رتبه‌بندی‌های کم تا زمانی که افراد بیشتری رای دهند، نزدیک به وسط می‌ماند، بنابراین یک بررسی 5 ستاره نمی‌تواند یک برنامه افزودنی جدید را به بالاترین سطح برساند. رتبه‌بندی‌های اخیر بیشتر از رتبه‌بندی‌های قدیمی هستند و تنها یک رتبه برای هر حساب حساب می‌شود.';

  @override
  String get extScreenshots => 'تصاویر';

  @override
  String get extSortRelevance => 'ربط';

  @override
  String get extPermNetworkDetail =>
      'داده‌ها را از طریق VPN از اینترنت دریافت می‌کند. فقط میزبان‌های فهرست زیر مجازند و بقیه مسدودند.';

  @override
  String get extBgTitle => 'کار پس‌زمینه';

  @override
  String get extBgEnabled => 'در پس‌زمینه اجرا شود';

  @override
  String get extBgInterval => 'فاصلهٔ اجرا';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# دقیقه', one: '# دقیقه');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# ساعت', one: '# ساعت');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'وظیفه تا وقتی Sora باز است، حتی در سینی سیستم، طبق زمان‌بندی اجرا می‌شود. کوتاه‌ترین فاصله ۱۵ دقیقه است.';

  @override
  String get extBgDisabledNote => 'برنامه افزودنی را برای مدیریت وظیفه پس‌زمینه خود فعال کنید.';

  @override
  String get extCapNetwork => 'دسترسی به شبکه';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'شبکه: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'در $name';
  }

  @override
  String get diagnosticHttp => 'تشخیص HTTP';

  @override
  String get diagnosticNoData => 'هنوز درخواستی ثبت نشده است. ابتدا یک وب سایت تست سرعت باز کنید.';

  @override
  String get qrShareTitle => 'کد QR را به اشتراک بگذارید';

  @override
  String get qrScanTitle => 'کد QR را اسکن کنید';

  @override
  String get qrCopyLink => 'پیوند را کپی کنید';

  @override
  String get qrShowLink => 'نمایش پیوند';

  @override
  String get qrHideLink => 'پنهان کردن پیوند';

  @override
  String get qrWarning => 'این کد QR حاوی جزئیات اتصال است. آن را به غریبه ها نشان ندهید.';

  @override
  String get qrScanHint => 'یک اسکرین‌شات یا عکس دارای کد QR انتخاب کنید یا پیوندی را جای‌گذاری کنید';

  @override
  String get qrFromClipboard => 'چسباندن از کلیپ بورد';

  @override
  String get qrNoCode => 'در این تصویر کد QR پیدا نشد.';

  @override
  String get qrInvalid => 'این کد QR حاوی پیوند معتبری نیست.';

  @override
  String get qrScan => 'اسکن QR';

  @override
  String get qrFromImage => 'باز کردن تصویر';

  @override
  String get connGroupByProcess => 'گروه بر اساس فرآیند';

  @override
  String get connListView => 'فهرست';

  @override
  String get connCopyHost => 'کپی میزبان';

  @override
  String get connAddRule => 'قانون اضافه کنید';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# اتصال', one: '# اتصال');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'از پیش تنظیم شده';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'سفارشی';

  @override
  String get dnsCheck => 'نشت داده را بررسی کنید';

  @override
  String get dnsChecking => 'در حال بررسی...';

  @override
  String get dnsNoLeak => 'هیچ نشتی یافت نشد';

  @override
  String get dnsLeakFound => 'نشت شناسایی شد';

  @override
  String get dnsLastCheck => 'آخرین بررسی';

  @override
  String get dnsNeverChecked => 'هنوز تست نشده است';

  @override
  String get dnsLeakCheckTunnelDns => 'تحلیلگرهای DNS تونل';

  @override
  String get dnsLeakCheckSystemResolvers => 'تحلیلگرهای نام سیستم';

  @override
  String get dnsLeakCheckKillSwitchDns => 'محافظت DNS با قطع اضطراری';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'DNS را برای تونل در تنظیمات DNS بالا پیکربندی کنید.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'بررسی کنید که سیستم شما از کدام حل کننده ها در خارج از تونل استفاده می کند.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'قطع اضطراری را روشن کنید تا ترافیک DNS درون تونل بماند.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS رمزگذاری‌شدهٔ سیستم‌عامل';

  @override
  String get dnsLeakCheckDnsSpoof => 'پاسخ های جعلی DNS';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'بررسی کنید که سیستم شما از کدام نقاط پایانی DNS رمزگذاری شده در خارج از تونل استفاده می کند.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'از DNS (DoT یا DoH) رمزگذاری شده برای تونل استفاده کنید تا حل‌کننده‌ها نتوانند پاسخ‌ها را جعل کنند.';

  @override
  String get dnsCheckNeedsConnection => 'ابتدا به VPN متصل شوید، سپس نشتی را بررسی کنید.';

  @override
  String get dnsExpected => 'مورد انتظار';

  @override
  String get dnsActual => 'مشاهده شد';

  @override
  String get sortBy => 'مرتب سازی بر اساس';

  @override
  String get sortPing => 'پینگ';

  @override
  String get sortSpeed => 'سرعت';

  @override
  String get sortName => 'نام';

  @override
  String get measureSpeed => 'اندازه گیری سرعت';

  @override
  String get benchmarkStale => 'منسوخ شده است';

  @override
  String get autoSelectMode => 'انتخاب خودکار سرور';

  @override
  String get autoSelectPing => 'سریعترین پینگ';

  @override
  String get autoSelectSpeed => 'سریعترین سرعت';

  @override
  String get autoSelectSmart => 'انتخاب هوشمندانه';

  @override
  String get coreWatchUnstable => 'اتصال به هسته Sora ناپایدار است';

  @override
  String get watchReconnect => 'دوباره وصل شوید';

  @override
  String get coreRestoringLink => 'در حال بازیابی اتصال به هسته Sora…';

  @override
  String get crashRestoreTitle => 'آخرین جلسه قطع شد';

  @override
  String get restoreOnCrash => 'بازیابی جلسه پس از خرابی';

  @override
  String get crashRestore => 'بازیابی';

  @override
  String get crashDismiss => 'اکنون نه';

  @override
  String get overrideTitle => 'ویرایش های من';

  @override
  String get overrideEdit => 'ویرایش سرورها';

  @override
  String get overrideHide => 'پنهان کردن';

  @override
  String get overrideUnhide => 'نمایش';

  @override
  String get overrideClear => 'ویرایش ها را بازنشانی کنید';

  @override
  String get overrideEmpty => 'هنوز هیچ ویرایشی انجام نشده است';

  @override
  String get overrideCustomRules => 'قوانین خود را';

  @override
  String get errBenchmarkUnsupported => 'اندازه گیری سرعت به هسته جدیدتری نیاز دارد';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'اندازه گیری $done از $total…';
  }

  @override
  String get profiles => 'نمایه های شبکه';

  @override
  String get profilesEmpty =>
      'هنوز پروفایلی وجود ندارد. یکی ایجاد کنید تا تنظیمات به طور خودکار در شبکه های شناخته شده اعمال شود.';

  @override
  String get profileAdd => 'افزودن نمایه';

  @override
  String get profileName => 'نام نمایه';

  @override
  String get profileSsids => 'Wi-Fi شبکه (SSID)';

  @override
  String get profileSsidsHint => 'خانه، دفتر با کاما جدا شده است';

  @override
  String get profileGateways => 'دروازه های شبکه';

  @override
  String get profileAsns => 'AS شماره';

  @override
  String get profileAutoApply => 'اعمال خودکار';

  @override
  String get profileAutoApplyHint => 'اگر خاموش باشد، پیش از اعمال نمایه تأیید خواسته می‌شود.';

  @override
  String get profileSnapshot => 'تنظیمات فعلی را به خاطر بسپارید';

  @override
  String get profileSnapshotDone => 'تنظیمات فعلی در نمایه ذخیره شده است';

  @override
  String get profileDelete => 'حذف نمایه';

  @override
  String profileDeleteConfirm(Object name) {
    return 'نمایه \"$name\" حذف شود؟';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'نمایه \"$name\" اعمال شود؟';
  }

  @override
  String get profileApply => 'اعمال';

  @override
  String profileApplied(Object name) {
    return 'نمایه «$name» اعمال شد';
  }

  @override
  String get profileUndo => 'لغو';

  @override
  String get profileActive => 'فعال';

  @override
  String networkNow(Object info) {
    return 'اکنون: $info';
  }

  @override
  String get networkUnknown => 'اطلاعات شبکه در دسترس نیست';

  @override
  String get profileNoTriggers => 'حداقل یک محرک اضافه کنید: SSID، دروازه یا ASN';

  @override
  String get chains => 'زنجیره های پروکسی';

  @override
  String get chainsEmpty =>
      'هنوز زنجیر وجود ندارد. 2-3 سرور را پیوند دهید تا ترافیک از طریق هر یک از آنها افزایش یابد.';

  @override
  String get chainAdd => 'زنجیره جدید';

  @override
  String get chainName => 'نام زنجیر';

  @override
  String get chainPickServers => '2 تا 3 سرور را انتخاب کنید';

  @override
  String get chainOrderHint => 'برای ترتیب مجدد بکشید: ترافیک در بالا وارد می شود و در پایین خارج می شود.';

  @override
  String get chainTooFew => 'حداقل 2 سرور انتخاب کنید';

  @override
  String get chainTooMany => 'یک زنجیره حداکثر 3 سرور را در خود جای می دهد';

  @override
  String get chainEstimate => 'تأخیر تخمینی';

  @override
  String get chainSave => 'ذخیره زنجیره';

  @override
  String get chainDelete => 'حذف زنجیره';

  @override
  String chainDeleteConfirm(Object name) {
    return 'زنجیره \"$name\" حذف شود؟';
  }

  @override
  String get chainUnsupported => 'موتور فعلی نمی تواند زنجیر بسازد';

  @override
  String get chainHopMissing => 'یکی از سرورهای زنجیره ای دیگر در دسترس نیست';

  @override
  String chainHop(Object n) {
    return 'گام $n';
  }

  @override
  String get chainEntry => 'ورود';

  @override
  String get chainExit => 'خروج';

  @override
  String get sync => 'همگام سازی دستگاه';

  @override
  String get syncDevices => 'دستگاه های من';

  @override
  String get syncEmpty => 'هیچ دستگاه جفت شده ای وجود ندارد. دستگاه دیگری را از طریق شبکه محلی جفت کنید.';

  @override
  String get syncPair => 'جفت کردن دستگاه';

  @override
  String get syncShowCode => 'نمایش کد من';

  @override
  String get syncScanCode => 'کد را اسکن کنید';

  @override
  String get syncRevoke => 'برداشت';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" لغو شود؟';
  }

  @override
  String syncLastSync(Object time) {
    return 'آخرین همگام سازی: $time';
  }

  @override
  String get syncNever => 'هرگز';

  @override
  String get syncNoLan => 'دستگاه ها باید در یک شبکه محلی باشند';

  @override
  String get syncPaired => 'دستگاه جفت شد';

  @override
  String get syncPairingTitle => 'با این دستگاه جفت شود';

  @override
  String get syncWaiting => 'در انتظار دستگاه دیگر…';

  @override
  String get syncSecureNote => 'کانال رمزگذاری شده سرتاسر. بدون حساب، بدون سرور ابری.';

  @override
  String get zapretWithVpn => 'برای ترافیک مستقیم شبکه، فیلتر DPI را دور بزنید';

  @override
  String get zapretWithVpnHint =>
      'zapret را در کنار تونل VPN اجرا می‌کند: ترافیک تونل از VPN و ترافیک مستقیم از مسیر دور زدن محدودیت عبور می‌کند.';

  @override
  String get chainDuplicate => 'هر سرور فقط یک بار می تواند ظاهر شود';

  @override
  String get edit => 'ویرایش';

  @override
  String get remove => 'حذف کنید';

  @override
  String get autoSwitchOnDegrade => 'تغییر خودکار در تخریب';

  @override
  String get autoSwitchOnDegradeDetail =>
      'اگر سرور انتخابی بسیار کند شود یا پاسخ ندهد، Sora به بهترین سرور طبق اندازه‌گیری‌ها تغییر می‌کند، اما حداکثر یک بار در هر 10 دقیقه.';

  @override
  String get tunStackMixed => 'مختلط';

  @override
  String get tunStackSystem => 'سیستم';

  @override
  String get customServerAdd => 'افزودن سرور سفارشی';

  @override
  String get customServers => 'سرورهای من';

  @override
  String get customServerName => 'نام';

  @override
  String get customServerNameHint => 'به عنوان مثال: VPS من';

  @override
  String get customServerNameRequired => 'نام را وارد کنید';

  @override
  String get customServerAddress => 'نشانی';

  @override
  String get customServerAddressHint => 'example.com یا 192.0.2.1';

  @override
  String get customServerAddressRequired => 'آدرس سرور را وارد کنید';

  @override
  String get customServerAddressInvalid => 'آدرس نامعتبر است';

  @override
  String get customServerPort => 'درگاه';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'پورت باید از 1 تا 65535 باشد';

  @override
  String get customServerProtocol => 'پروتکل';

  @override
  String get customServerCredentials => 'اطلاعات ورود';

  @override
  String get customServerOptional => 'اختیاری';

  @override
  String get customServerShowSecret => 'نمایش راز';

  @override
  String get customServerHideSecret => 'مخفی کردن راز';

  @override
  String get customServerBadge => 'سفارشی';

  @override
  String customServerDeleteConfirm(String name) {
    return 'سرور \"$name\" حذف شود؟';
  }

  @override
  String get customServerEmptyHint => 'سرور را به صورت دستی اضافه کنید: آدرس، پورت و پروتکل';

  @override
  String get customServerTest => 'آزمایش';

  @override
  String get leakTestTitle => 'تست نشت داده ها';

  @override
  String get leakTestIntro =>
      'بررسی می‌کند آیا ترافیک می‌تواند خارج از تونل از دستگاه خارج شود: درخواست‌های مستقیم DNS و ICMP، خروجی IPv6 و تحلیلگرهای نام سیستم. هنگام اتصال اجرا کنید.';

  @override
  String get leakTestRun => 'بررسی کنید';

  @override
  String get leakTestCancel => 'لغو';

  @override
  String get leakTestNeedsConnection => 'برای آزمایش نشت داده به VPN متصل شوید.';

  @override
  String leakTestProgress(int count) {
    return 'آزمایشات تکمیل شده: $count';
  }

  @override
  String get leakTestAllClear => 'هیچ نشتی یافت نشد';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# نشت پیدا شد', one: '# نشت پیدا شد');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'رفع کنید';

  @override
  String get leakTestFixedNote => 'قطع اضطراری روشن است. برای بررسی، آزمایش را دوباره اجرا کنید.';

  @override
  String get leakTestCheckDirectDns => 'مستقیم DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP اکو';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'تحلیلگرهای نام سیستم';

  @override
  String get leakTestCheckTunnelConnectivity => 'اتصال تونل';

  @override
  String get leakTestCheckTunnelDns => 'DNS از طریق تونل';

  @override
  String get noticeDegraded => 'سرور کند شد. Sora به بهترین سروری که در حین اندازه‌گیری یافت شد تغییر داد.';

  @override
  String get obfs => 'مبهم‌سازی ترافیک';

  @override
  String get syncCodeExpired => 'کد منقضی شده است';

  @override
  String get syncDaemonFailed => 'سرویس همگام‌سازی راه‌اندازی نشد';

  @override
  String get syncDaemonMissing =>
      'مؤلفه sora-sync پیدا نشد. برای فعال کردن همگام سازی دستگاه، برنامه را دوباره نصب کنید.';

  @override
  String get syncDaemonStarting => 'شروع سرویس همگام سازی…';

  @override
  String get syncErrAuth =>
      'سرویس همگام‌سازی رمز دسترسی را رد کرد. برنامه را مجددا راه اندازی کنید و دوباره امتحان کنید.';

  @override
  String get syncErrNotFound => 'دستگاه دیگر جفت نشده است';

  @override
  String get syncErrPairingActive => 'یک جلسه جفت سازی از قبل باز است';

  @override
  String get syncErrUnreachable => 'دستگاه دیگر پاسخ نداد. مطمئن شوید که در همان شبکه است و کد آن را نشان می دهد.';

  @override
  String get syncError => 'خطای همگام سازی';

  @override
  String syncExpiresIn(String duration) {
    return 'کد پس از $duration منقضی می‌شود';
  }

  @override
  String get syncJoining => 'جفت شدن با دستگاه…';

  @override
  String get syncLegacyCleared =>
      'لیست دستگاه های قدیمی هرگز جفت نشد، بنابراین پاک شد. دستگاه های خود را دوباره جفت کنید، این بار به صورت واقعی.';

  @override
  String get syncNewCode => 'کد جدید';

  @override
  String syncPairedWith(String name) {
    return 'جفت شده با $name';
  }

  @override
  String get syncRetry => 'تکرار کنید';

  @override
  String get syncStopShowing => 'پنهان کردن کد';

  @override
  String get syncSyncNow => 'همگام‌سازی اکنون';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled را دریافت کرد، $pushed را ارسال کرد';
  }

  @override
  String get syncResultTitle => 'نتیجه همگام سازی';

  @override
  String get syncPulled => 'دریافت شد';

  @override
  String get syncPushed => 'ارسال شد';

  @override
  String get syncNoChanges => 'بدون تغییر';

  @override
  String get syncDocKindSubscriptions => 'اشتراک ها';

  @override
  String get syncDocKindSettings => 'تنظیمات برنامه';

  @override
  String get syncDocKindOverrides => 'تنظیمات جایگزین اشتراک‌ها';

  @override
  String get syncDocKindProfiles => 'نمایه های شبکه';

  @override
  String get syncDocKindChains => 'زنجیره های پروکسی';

  @override
  String syncFrom(String name) {
    return 'از $name';
  }

  @override
  String get syncThisDevice => 'این دستگاه';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'برای Shadowsocks: روش:گذرواژه، مثلاً chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => 'ضبط بسته';

  @override
  String get diagnosticEvents => 'رویدادهای ویندوز';

  @override
  String get diagnosticCapture => 'به مدت 10 ثانیه عکس بگیرید';

  @override
  String get diagnosticRequiresTun => 'ضبط بسته به یک اتصال فعال Sora TUN نیاز دارد.';

  @override
  String get diagnosticUnavailable => 'این تشخیص در این پلتفرم در دسترس نیست.';

  @override
  String get extErrRevoked => 'تیم Sora این نسخه از افزونه را لغو کرد، چون ناامن یا خراب است.';

  @override
  String get extErrRevocationsExpired =>
      'فهرست افزونه‌های لغوشده به‌روز نشد. تا به‌روز شدن آن نصب ممکن نیست: شبکه را بررسی و دوباره تلاش کنید.';

  @override
  String extRevokedDisabled(String names) {
    return 'افزونه‌های لغوشده خاموش شدند: $names';
  }

  @override
  String get customServerWgPrivateKey => 'کلید خصوصی';

  @override
  String get customServerWgAddresses => 'نشانی‌های رابط';

  @override
  String get customServerWgPeerKey => 'کلید عمومی سرور';

  @override
  String get customServerWgPresharedKey => 'کلید مشترک';

  @override
  String get customServerWgAllowedIps => 'IPهای مجاز';

  @override
  String get customServerWgKeepalive => 'Keepalive، ثانیه';

  @override
  String get customServerWgKeyInvalid => 'کلید باید ۳۲ بایت base64 باشد، مانند خروجی wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'پیشوندها را با ویرگول جدا کنید، مانند 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'عددی بین 0 تا 65535 ثانیه وارد کنید.';

  @override
  String get strictKillSwitch => 'قطع اضطراری سخت‌گیرانه';

  @override
  String get strictKillSwitchWarning =>
      'پس از اتصال، ترافیک خارج از VPN را حتی پس از خرابی، راه‌اندازی مجدد یا خروج از برنامه مسدود می‌کند. دسترسی فقط با قطع اتصال یا خاموش کردن این گزینه برمی‌گردد. پس از راه‌اندازی مجدد دستگاه، مسدودسازی فقط در صورت فعال بودن اتصال هنگام شروع از سر گرفته می‌شود.';

  @override
  String get extWorkerFailed => 'وظیفه پس‌زمینه افزونه ناموفق بود. گزارش افزونه را بررسی کنید.';

  @override
  String get extAssetRejected => 'فایل افزونه رد شد: رنگ‌های ناخوانا یا قوانین نامعتبر.';
}
