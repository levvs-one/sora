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
  String get stateFailed => 'متصل نیست';

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
  String speedMbps(double value) {
    return '${value.toStringAsFixed(1)} Mbps';
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
  String get exportText => 'متن';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'نور';

  @override
  String get themeDark => 'تاریک';

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'System';

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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سرورهای # به نوبه خود',
      one: 'سرور # به نوبه خود',
    );
    return '$_temp0';
  }

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
  String get tunnelTun => 'تمام ترافیک';

  @override
  String get tunnelProxy => 'پروکسی System';

  @override
  String get proxyAddress => 'آدرس پروکسی';

  @override
  String get copied => 'کپی شده';

  @override
  String get launchAtLogin => 'با سیستم شروع کنید';

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
  String get currentServer => 'سرور فعلی';

  @override
  String get trafficDown => 'دانلود شد';

  @override
  String get trafficUp => 'آپلود شد';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'قوانین فعال: $count';
  }

  @override
  String get recentNotifications => 'اطلاعیه های اخیر';

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
  String get programsFailed => 'برنامه ها بارگیری نشد';

  @override
  String get programsEmpty => 'هیچ برنامه ای یافت نشد نام دیگری را امتحان کنید.';

  @override
  String get selectExe => 'یک فایل exe را انتخاب کنید';

  @override
  String get trafficUnavailable => 'شمارنده ها هنوز در دسترس نیستند';

  @override
  String get speedtest => 'سرعت';

  @override
  String get speedtestCheck => 'سرعت را بررسی کنید';

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
  String get appCopyright => '© 2026 levvs-one و همکاران';

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
  String get bypassLimitations =>
      'این حالت DPI را فقط برای HTTP و TLS دور می‌زند، از UDP پشتیبانی نمی‌کند یا IP شما را تغییر نمی‌دهد. از سرور VPN برای صدای Discord، تماس ها و آدرس های مسدود شده Telegram استفاده کنید.';

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
      'اگر مطمئن نیستید که سرور شما به کدام موتور نیاز دارد، Auto را انتخاب کنید. Sora نمایه و تنظیمات را قبل از اتصال بررسی می کند. یک موتور نمی تواند پهنای باند طرح شما را افزایش دهد: عملکرد به سرور، مسیر، پروتکل و شبکه بستگی دارد.\n\n## حالت ها\n\n### همه ترافیک (TUN)\n\nSora یک رابط شبکه مجازی ایجاد می کند و ترافیک برنامه ها از جمله TCP و UDP را از طریق آن هدایت می کند. از این حالت برای Telegram، بازی ها و صدای Discord استفاده کنید. قوانین می توانند سایت ها یا برنامه های خاصی را مستقیما ارسال کنند یا آنها را مسدود کنند. سرویس شبکه به مجوز و سروری نیاز دارد که از پروتکل مورد نیاز پشتیبانی کند.\n\n### پروکسی System\n\nSora یک پروکسی محلی HTTP/SOCKS را پیکربندی می کند. برنامه هایی که به تنظیمات پراکسی سیستم احترام می گذارند از آن استفاده می کنند. برنامه های کاربردی با پشته شبکه خود ممکن است مستقیماً متصل شوند. UDP و تماس های صوتی به طور کلی به TUN نیاز دارند. این حالت برای مرورگرها و برنامه های دارای پشتیبانی از پروکسی مناسب است.\n\n### بدون سرور\n\nدر Linux، Sora از [zapret](https://github.com/bol-van/zapret) برای تقسیم و تغییر شکل درخواست‌های HTTP/TLS و دور زدن برخی از بررسی‌های DPI استفاده می‌کند. IP شما ثابت می ماند و اتصالات مستقیماً به وب سایت می روند. نتایج به ارائه دهنده شما و روش مسدود کردن بستگی دارد.\n\nادغام فعلی از tpws برای HTTP و TLS روی TCP استفاده می کند. از مسدود کردن IP یا رله UDP عبور نمی کند و نمی تواند اتصالات Telegram MTProto را تضمین کند. از یک سرور VPN با TUN برای صدای Discord، تماس های Telegram و این نوع محدودیت ها استفاده کنید.\n\n## موتورها\n\n### خودکار\n\nSora موتور نصب شده ای را انتخاب می کند که از کل طرح اتصال پشتیبانی می کند: پروتکل های سرور، حمل و نقل، گروه ها، تکه تکه شدن و حالت. انتخاب دستی ناسازگار قبل از توقف اتصال فعلی رد می شود. Auto یا موتور دیگری را انتخاب کنید و دوباره تنظیمات را اعمال کنید.\n\n### sing-box\n\nبسته‌های جدید Sora شامل [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)، چنگال [sing-box](https://github.com/SagerNet/sing-box)، اضافه کردن XHTTP و VLESS Encryption سمت مشتری است. Sora ساخت و قابلیت های آن را تشخیص می دهد. یک ساخت بالادستی بدون XHTTP این قابلیت را به تنهایی از نام خود به دست نمی آورد.\n\nپروتکل‌های پشتیبانی‌شده شامل VLESS، VMess، Trojan، Shadowsocks، Hysteria2، TUIC، AnyTLS، WireGuard و پارامترهای AmneziaWG 1.x/2.x هستند که Sora می‌تواند وارد کند. پروفایل کامل Xray JSON به Xray نیاز دارد. وارد کردن فیلدهای جدید AWG 3.x هنوز امکان‌پذیر نیست. sing-box از یک درگاه کنترل محلی محافظت‌شده با گذرواژه استفاده می‌کند که برنامه‌های دیگر روی رایانه می‌توانند آن را شناسایی کنند.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) از تکه تکه شدن VLESS، REALITY، XHTTP، VLESS Encryption و TLS پشتیبانی می کند. همچنین پروفیل های کامل ارائه دهنده Xray را اجرا می کند و در عین حال مسیریابی و گروه های آنها را حفظ می کند. چنین پروفایل هایی را نمی توان بدون تغییر رفتار به طور خودکار به موتور دیگری تبدیل کرد.\n\nXray همراه، تنظیمی را که تأیید گواهی TLS را غیرفعال می‌کرد («allowInsecure») حذف کرد. خودکار sing-box یا mihomo را برای سرورهای معمولی که به این تنظیم نیاز دارند انتخاب می کند. انتخاب Xray به صورت دستی ناسازگاری را قبل از توقف اتصال فعلی گزارش می کند. نمایه‌های کامل JSON قدیمی‌تر به نمایه ارائه‌دهنده به‌روزرسانی شده با گواهی یا پین گواهی قابل تأیید نیاز دارند.\n\n### mihomo\n\n[mihomo] (https://github.com/MetaCubeX/mihomo) از گروه‌های بازگشتی و متعادل‌کننده بار سفارش‌داده‌شده، XHTTP و AmneziaWG پشتیبانی می‌کند. زمانی آن را انتخاب کنید که خطای خودکار به سرور پشتیبان مهم است. تنظیم تکه تکه شدن TLS Sora با این موتور در دسترس نیست.\n\n## سازگاری در Sora\n\n| ویژگی | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN و TCP/UDP | بله | بله | بله |\n| XHTTP | بله | بله | بله |\n| VLESS Encryption | بله | بله | بله |\n| پروفایل کامل Xray | نه | بله | نه |\n| TUIC / AnyTLS | هر دو | نه | TUIC |\n| تکه تکه شدن TLS | بله | بله | نه |\n| AmneziaWG 1.x/2.x | بله¹ | نه | بله |\n| گروه بازگشتی سفارشی | نه | No² | بله |\n\n¹ نمایه‌های دارای J1/J2/J3/Itime از mihomo استفاده می‌کنند. این زمینه ها هرگز نباید بی سر و صدا کنار گذاشته شوند. ² برای گروهی از نمایه‌های کامل Xray، برنامه یک نمایه پشتیبان انتخاب می‌کند. پشتیبانی بستگی به ساخت نصب شده دارد. نسخه آن را در About چک کنید.\n\n## پشته TUN\n\nپشته TCP و UDP را در داخل رابط مجازی کنترل می کند. در پانل حالت ها، Xray و mihomo gVisor، System، Mixed و MIPS را ارائه می دهند. هر موتور اولویت خود را ذخیره می کند. پروکسی System و حالت‌های بدون سرور از این اولویت استفاده نمی‌کنند.\n\n- **Mixed** - TCP از پشته سیستم استفاده می کند، در حالی که gVisor UDP را کنترل می کند. این پیش‌فرض mihomo در Linux است. در Windows، Xray و mihomo به‌طور پیش‌فرض از MIPS استفاده می‌کنند.\n- **System** - از پشته سیستم استفاده می کند. اگر برنامه های شبکه با مشکل مواجه شدند، گزینه دیگری را امتحان کنید.\n- **gVisor** - ترافیک در فضای کاربران را کنترل می کند.\n- **MIPS** — پشته IP اختصاصی mihomo، موجود در نسخه همراه 1.19.32.\n\nدر Linux، Xray به طور پیش فرض از gVisor داخلی خود استفاده می کند. System، Mixed و MIPS در Linux از mihomo به عنوان موتور TUN استفاده می‌کنند و TCP و UDP را به Xray از طریق پیوند محلی SOCKS تأیید شده ارسال می‌کنند. Xray پروتکل، مشخصات ارائه دهنده و مسیریابی را حفظ می کند. این سه گزینه به mihomo نصب شده نیاز دارند. در Windows، Xray برای هر چهار پشته TUN از mihomo 1.19.32 یا جدیدتر استفاده می‌کند. پروتکل‌ها و مسیریابی در Xray باقی می‌مانند. قوانین برنامه‌ها در این ترکیب فقط اتصال مستقیم و مسدودسازی را پشتیبانی می‌کنند؛ در Linux این قوانین به gVisor داخلی Xray نیاز دارند.\n\nپل فرآیند دوم را اجرا می کند. در سه اندازه گیری غیرفعال در Linux، از حافظه فیزیکی 32 تا 36 مگابایت بیشتر از Xray TUN استفاده کرد. این بار دانلود را اندازه نمی‌گیرد: هزینه‌های CPU و حافظه به اتصالات بستگی دارد. sing-box انتخابگر پشته ندارد. هیچ پشته ای عملکرد بهتر را در هر شبکه ای تضمین نمی کند. یک پشته را انتخاب کنید و Apply را انتخاب کنید و دوباره متصل شوید تا آن را در شبکه خود امتحان کنید.\n\n## اعمال تنظیمات\n\nانتخاب سرور به طور خودکار دوباره متصل می شود. تنظیمات حالت، موتور، DNS و قوانین بلافاصله ذخیره می شوند. در طول یک اتصال فعال، روی Apply کلیک کنید و دوباره متصل شوید تا از آنها استفاده کنید. راه اندازی مجدد موتور ممکن است بارگیری ها و تماس ها را قطع کند. کلیک های مکرر اتصالات موازی را شروع نمی کنند. قطع کردن انتقال به پایان می رسد و اتصال آزاد می شود.\n\nاینترنت فقط از طریق VPN ترافیک مستقیم را هنگام سقوط یک تونل مسدود می کند. کل دستگاه را تحت تأثیر قرار می دهد. قطع صریح قوانین Sora را حذف می کند. اگر پاکسازی تمام نشد، دوباره سعی کنید اتصال را قطع کرده و گزارش را باز کنید.\n\n## مستندات پروژه\n\n- [sing-box-lx: پیکربندی و پشتیبانی] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [مستندات sing-box] (https://sing-box.sagernet.org/)\n- [اسناد Xray] (https://xtls.github.io/)\n- [مستندات mihomo] (https://wiki.metacubex.one/)\n- [zapret: عملیات و محدودیت ها] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'سرورها را بررسی کنید';

  @override
  String get extensions => 'برنامه های افزودنی';

  @override
  String get extensionsSoon => 'به زودی';

  @override
  String exportLogFile(String name) {
    return 'در $name';
  }

  @override
  String get diagnosticHttp => 'تشخیص HTTP';

  @override
  String get diagnosticPackets => 'ضبط بسته';

  @override
  String get diagnosticEvents => 'رویدادهای ویندوز';

  @override
  String get diagnosticCapture => 'به مدت 10 ثانیه عکس بگیرید';

  @override
  String get diagnosticNoData => 'هنوز درخواستی ثبت نشده است. ابتدا یک وب سایت تست سرعت باز کنید.';

  @override
  String get diagnosticRequiresTun => 'ضبط بسته به یک اتصال فعال Sora TUN نیاز دارد.';

  @override
  String get diagnosticUnavailable => 'این تشخیص در این پلتفرم در دسترس نیست.';
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
