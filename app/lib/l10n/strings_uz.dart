// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class SUz extends S {
  SUz([String locale = 'uz']) : super(locale);

  @override
  String get stateOff => 'Ulanmagan';

  @override
  String get stateConnecting => 'Ulanmoqda';

  @override
  String get stateConnected => 'Ulangan';

  @override
  String get stateReconnecting => 'Qayta ulanmoqda';

  @override
  String get stateDisconnecting => 'Aloqa uzilmoqda';

  @override
  String get coreMissing => 'Sora xizmati javob bermayapti';

  @override
  String get serverAuto => 'Eng tez';

  @override
  String get serverBypass => 'Server yo\'q';

  @override
  String get addSubscription => 'Obuna qo\'shing';

  @override
  String get servers => 'Serverlar';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get subscription => 'Obuna';

  @override
  String get subscriptionLink => 'Obuna havolasi';

  @override
  String get add => 'Qo\'shish';

  @override
  String get refresh => 'Yangilash';

  @override
  String get rename => 'Nomini o\'zgartirish';

  @override
  String get delete => 'Oʻchirish';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get save => 'Saqlash';

  @override
  String get name => 'Ism';

  @override
  String deleteSubscription(String name) {
    return '“$name” oʻchirilsinmi?';
  }

  @override
  String get routes => 'Marshrutlar';

  @override
  String get presetGlobal => 'Hammasi VPN orqali';

  @override
  String get presetRu => 'Rossiya to\'g\'ridan-to\'g\'ri';

  @override
  String get presetIr => 'Eron to\'g\'ridan-to\'g\'ri';

  @override
  String get presetCn => 'Xitoy to\'g\'ridan-to\'g\'ri';

  @override
  String get blockAds => 'Reklamalarni bloklash';

  @override
  String get killSwitch => 'Internet faqat VPN orqali';

  @override
  String get engine => 'Dvigatel';

  @override
  String get engineAuto => 'Avtomatik';

  @override
  String get animations => 'Animatsiyalar';

  @override
  String get logs => 'Jurnal';

  @override
  String get about => 'Haqida';

  @override
  String get logsAll => 'Hammasi';

  @override
  String get logsImportant => 'Muhim';

  @override
  String get logsErrors => 'Xatolar';

  @override
  String get search => 'Qidiruv';

  @override
  String get export => 'Faylga saqlang';

  @override
  String get clear => 'Toza';

  @override
  String get logsEmpty => 'Bu yerda hech narsa';

  @override
  String get connEmpty => 'Ulanish yo‘q';

  @override
  String appVersion(String version) {
    return '$version versiyasi';
  }

  @override
  String get notInstalled => 'Oʻrnatilmagan';

  @override
  String get sourceCode => 'Manba kodi';

  @override
  String get license => 'Litsenziya';

  @override
  String usage(String used, String total) {
    return '$used, $total';
  }

  @override
  String until(String date) {
    return '$date gacha';
  }

  @override
  String get expired => 'Muddati tugagan';

  @override
  String milliseconds(int n) {
    return '$n milodiy';
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
    return '$n TB';
  }

  @override
  String get errGeneric => 'Nimadir xato ketdi';

  @override
  String get errCore => 'Sora xizmati javob bermayapti. Biroz kutib, qayta urinib koʻring.';

  @override
  String get errAuth => 'Sora xizmatiga kirish rad etildi. Ilovani qayta ishga tushirib, yana urinib koʻring.';

  @override
  String get errVersion => 'Sora ilovasi va xizmati turli versiyalarda. Sora’ni yangilang.';

  @override
  String get errBusy => 'Oldingi buyruq hali bajarilmoqda. Uning tugashini kuting.';

  @override
  String get errEngineMissing => 'Bu server uchun kerakli yadro topilmadi. Sora yangilanishlarini tekshiring.';

  @override
  String get errEngineStart => 'Yadro ishga tushmadi. Sababini ulanish jurnalidan koʻring.';

  @override
  String get errEngineStopped => 'Yadro toʻxtadi. Qayta ulanishga urinib koʻring.';

  @override
  String get errTunnel => 'Bu VPN rejimi mavjud emas. Boshqa rejimni tanlang yoki xizmat ruxsatlarini tekshiring.';

  @override
  String get errNetwork => 'Serverga ulanib boʻlmadi';

  @override
  String get errTimeout => 'Server vaqtida javob bermadi. Bir daqiqadan keyin qayta urinib koʻring.';

  @override
  String get errFirewall =>
      'VPN tashqarisidagi internetga kirishni bloklab boʻlmadi. Sababini ulanish jurnalidan koʻring.';

  @override
  String get errSubFetch => 'Obunani yuklab boʻlmadi. Internetni tekshirib, bir daqiqadan keyin qayta urinib koʻring.';

  @override
  String get errSubFormat => 'Obuna formati tanilmadi. Provayderdan mos obuna havolasini soʻrang.';

  @override
  String get errSubEmpty => 'Obunada serverlar yoʻq. Obuna provayderiga murojaat qiling.';

  @override
  String get errSubDuplicate => 'Bu obuna allaqachon qoʻshilgan. Eng soʻnggi serverlarni olish uchun uni yangilang.';

  @override
  String get errSubLimit =>
      'Obunalar soni chegarasiga yetildi. Yangisini qoʻshishdan oldin keraksiz obunani oʻchiring.';

  @override
  String get errSubScheme => 'Obuna havolasi https:// bilan boshlanishi kerak. Provayderdan xavfsiz havola soʻrang.';

  @override
  String get errSecretStore =>
      'Sora xotirasi buzilgan yoki unga kirib boʻlmayapti. Kirish ruxsatlari va jurnaldagi tafsilotlarni tekshiring.';

  @override
  String get errNoServers => 'Ulanish uchun serverlar yoʻq. Obuna yoki oʻz serveringizni qoʻshing.';

  @override
  String get connections => 'Ulanishlar';

  @override
  String get close => 'Yopish';

  @override
  String get chainDirect => 'To\'g\'ridan-to\'g\'ri';

  @override
  String get chainBlocked => 'Bloklangan';

  @override
  String get theme => 'Mavzu';

  @override
  String get themeSystem => 'Tizimdagidek';

  @override
  String get themeLight => 'Nur';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get language => 'Til';

  @override
  String get languageSystem => 'Tizimdagidek';

  @override
  String get sectionConnection => 'Ulanish';

  @override
  String get sectionNoServer => 'Server yo\'q';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostika';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Avtomatik';

  @override
  String get dnsHint => 'Manzillar, vergul bilan ajratilgan';

  @override
  String get fragment => 'TLS parchalanishi';

  @override
  String get fragmentPackets => 'Nimani ajratish kerak';

  @override
  String get fragmentLength => 'Parcha o\'lchami';

  @override
  String get fragmentInterval => 'Parchalar orasida pauza qiling';

  @override
  String get byDefault => 'Standart';

  @override
  String get rangeHint => 'Masalan, 100-200';

  @override
  String get splitPos => 'Bo\'lingan pozitsiyalar';

  @override
  String get splitPosHint => 'Masalan, 1, midsld';

  @override
  String get disorder => 'Parchalarni qayta tartiblash';

  @override
  String get tlsRecord => 'TLS yozuvini ajrating';

  @override
  String get tlsRecordNo => 'Yo\'q';

  @override
  String get tlsRecordSni => 'Sayt nomida';

  @override
  String get tlsRecordFirst => 'Birinchi baytdan keyin';

  @override
  String get hostCase => 'Xost holatini o\'zgartiring';

  @override
  String get probeMethod => 'Usul';

  @override
  String get probeAuto => 'Avtomatik';

  @override
  String get probeEngine => 'Dvigatel orqali';

  @override
  String get probeConnect => 'Faqat ulanish';

  @override
  String get probeUrl => 'Sinov manzili';

  @override
  String get probeTimeout => 'Kutib turing';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Obunalar';

  @override
  String get subscriptionSettings => 'Sozlamalar';

  @override
  String get userAgent => 'Foydalanuvchi-Agent';

  @override
  String get autoUpdate => 'Avtomatik yangilash';

  @override
  String get updateInterval => 'Qancha vaqtda';

  @override
  String get intervalProvider => 'Provayder so\'raganidek';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Hozir yangilang';

  @override
  String get logLevel => 'Nima yozish kerak';

  @override
  String get levelDebug => 'Hamma narsa';

  @override
  String get levelInfo => 'Odatdagidek';

  @override
  String get levelWarning => 'Muhim';

  @override
  String get levelError => 'Faqat xatolar';

  @override
  String get recordDestinations => 'Sayt manzillarini yozib oling';

  @override
  String get reset => 'Sozlamalarni tiklash';

  @override
  String get resetConfirm => 'Barcha sozlamalar qayta tiklansinmi?';

  @override
  String get resetAction => 'Qayta tiklash';

  @override
  String get invalidValue => 'Bu qiymat ishlamaydi';

  @override
  String get website => 'Obuna sahifasi';

  @override
  String get providerWebsite => 'Provayder veb-sayti';

  @override
  String get support => 'Qo\'llab-quvvatlash';

  @override
  String controlPortQuestion(String engine) {
    return '$engine ushbu kompyuterdagi port orqali boshqariladi. Boshqa dasturlar VPN yoqilganligini aniqlay oladi.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine ni tanlang';
  }

  @override
  String get rules => 'Maxsus qoidalar';

  @override
  String get ruleAdd => 'Yangi qoida';

  @override
  String get ruleHint => 'Sayt, IP yoki dastur';

  @override
  String get ruleDirect => 'To\'g\'ridan-to\'g\'ri';

  @override
  String get ruleProxy => 'VPN orqali';

  @override
  String get ruleBlock => 'Bloklash';

  @override
  String get failover => 'Muvaffaqiyatsizlikni yoqing';

  @override
  String get connectOnStart => 'Boshida ulaning';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'obuna $days kunlarda tugaydi',
      one: 'obuna $days kunida tugaydi',
      zero: 'obuna bir necha soat ichida tugaydi',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left qoldi';
  }

  @override
  String get ruleInvalid => 'Bu sayt, IP yoki dasturga o\'xshamaydi';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serverlari, eng tez',
      one: '$count server, eng tezkor',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Rejim';

  @override
  String get tunnelProxy => 'System proksi-server';

  @override
  String get proxyAddress => 'Proksi manzili';

  @override
  String get copied => 'Ko‘chirildi';

  @override
  String get launchAtLogin => 'Tizimdan boshlang';

  @override
  String get launchAtLoginDetail => 'Tizimga kirganingizda Sora avtomatik ishga tushadi va laganda qoladi.';

  @override
  String get closeToTray => 'Yopiq holatda patnisda saqlang';

  @override
  String get notifications => 'Bildirishnomalar';

  @override
  String get trayOpen => 'Sora ni oching';

  @override
  String get trayConnect => 'Ulanish';

  @override
  String get trayDisconnect => 'Ulanishni uzing';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Sora-dan chiqing';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora hali ham tagida';

  @override
  String get noticeInTrayBody => 'Uning belgisi menyusidan chiqing';

  @override
  String get noticeLost => 'Ulanish uzildi';

  @override
  String get noticeLostBody => 'Sora qayta ulanmoqda';

  @override
  String get noticeRestored => 'Qayta ulandi';

  @override
  String get noticeFailed => 'Ulanib bo‘lmadi';

  @override
  String get noticeBackup => 'Asosiy server javob bermadi; zaxira trafikni olib yuradi';

  @override
  String get noticeNext => 'Server javob bermadi; keyingisi transportni olib boradi';

  @override
  String get noticeMainBack => 'Asosiy server yana javob beradi va trafikni olib boradi';

  @override
  String get noticeSubscription => 'Obuna';

  @override
  String get importTitle => 'Bu obuna qo‘shilsinmi?';

  @override
  String get importSealed =>
      'Bu havola Happ uchun shifrlangan va uni faqat Happ o‘qiy oladi. Provayderingizdan oddiy obuna havolasini so\'rang.';

  @override
  String get understood => 'KELISHDIKMI';

  @override
  String get noAnswer => 'javob yo\'q';

  @override
  String get home => 'Uy';

  @override
  String get navRules => 'Qoidalar';

  @override
  String get navConnections => 'Ulanishlar';

  @override
  String get navLogs => 'Jurnallar';

  @override
  String get navAbout => 'Haqida';

  @override
  String get sidebarToggle => 'Yon panelni almashtirish';

  @override
  String get more => 'Ko\'proq';

  @override
  String get less => 'Ozroq';

  @override
  String get notificationsEmpty => 'Bildirishnomalar yoʻq';

  @override
  String get retryConnect => 'Qayta ulanishni sinab ko\'ring';

  @override
  String get openLogs => 'Jurnallarni oching';

  @override
  String get tourReplay => 'Yo‘riqnomani yana ko‘rsatish';

  @override
  String tourStep(int step) {
    return '$step/5 qadam';
  }

  @override
  String get tourBack => 'Orqaga';

  @override
  String get tourNext => 'Keyingisi';

  @override
  String get tourSkip => 'Oʻtkazib yuborish';

  @override
  String get tourFinish => 'Bajarildi';

  @override
  String get tourAdd => 'Provayderingizning obuna havolasini qo\'shing.';

  @override
  String get tourServer => 'Serverni tanlang. “Eng tez” siz uchun birini tanlaydi.';

  @override
  String get tourConnect => 'Ulanish yoki uzish uchun shu yerni bosing.';

  @override
  String get tourMode => 'Tartibni tanlang. Agar VPN tushib qolsa, o\'chirish kaliti internetni bloklaydi.';

  @override
  String get tourSettings => 'Sozlamalarni oching. Siz ushbu qo\'llanmani u erda takrorlashingiz mumkin.';

  @override
  String get chooseProgram => 'Dasturni tanlang';

  @override
  String get installedApps => 'O\'rnatilgan ilovalar';

  @override
  String get runningProcesses => 'Ishlayotgan jarayonlar';

  @override
  String get programsEmpty => 'Hech qanday ilova topilmadi. Boshqa nomni sinab ko\'ring.';

  @override
  String get selectExe => 'exe faylini tanlang';

  @override
  String get speedtest => 'Tezlik';

  @override
  String get speedtestSearch => 'Xizmat toping';

  @override
  String get speedtestEmpty => 'Mos kelmadi. Qidiruvni o\'zgartiring.';

  @override
  String get speedtestBackToList => 'Xizmatlarga qaytish';

  @override
  String get speedtestOpenBrowser => 'Brauzerda oching';

  @override
  String get speedtestUnavailable => 'O\'rnatilgan brauzer ishga tushmadi. Tizim brauzerida xizmatni oching.';

  @override
  String get speedtestPageFailed => 'Sahifa yuklanmadi. Uni qayta yuklang yoki tizim brauzerida xizmatni oching.';

  @override
  String get speedtestExternalFailed => 'Tizim brauzeri ochilmadi. Qayta urinib ko\'ring.';

  @override
  String get modes => 'Tartiblar';

  @override
  String get proxyShort => 'Proksi';

  @override
  String get tunMode => 'Barcha trafik (TUN)';

  @override
  String get checkUpdates => 'Yangilanishlarni tekshiring';

  @override
  String get updates => 'Ilova yangilanishlari';

  @override
  String updateAvailable(String version) {
    return '$version versiyasi mavjud';
  }

  @override
  String get updateOpenAbout => 'Yangilanishni ko\'rish';

  @override
  String updateNotes(String version) {
    return '$version dagi o\'zgarishlar';
  }

  @override
  String get updateCheck => 'Yangilanishlarni tekshiring';

  @override
  String get updateChecking => 'Tekshirilmoqda...';

  @override
  String get updateNoNotes => 'Relizda hech qanday eslatma yo\'q.';

  @override
  String get updateDropWarning =>
      'Sora va uning asosiy yangilanishi vaqtida VPN ulanishi bir necha soniyaga uziladi. Davom ettirilsinmi?';

  @override
  String get updateWaitConnection => 'VPN ulanishi va yadro tayyor bo\'lishini kuting.';

  @override
  String get updateDownloading => 'Fayllar yuklab olinmoqda va tekshirilmoqda...';

  @override
  String get updateInstalling => 'Yangilanish tayyorlanmoqda yoki administrator autentifikatsiyasi kutilmoqda...';

  @override
  String get updateNetworkError => 'Yangilanishni yuklab boʻlmadi. Qayta urinib ko\'ring.';

  @override
  String get updateReleaseError => 'Chiqarish ma\'lumotlari yoki kerakli fayllar etishmayotgan yoki yaroqsiz.';

  @override
  String get updateChecksumError => 'Yuklab olish SHA256SUMSga mos kelmaydi. Hech narsa o\'rnatilmagan.';

  @override
  String get updateInstallError => 'Yangilash tugamadi. Autentifikatsiya bekor qilingan bo\'lishi mumkin.';

  @override
  String get updateUnsupported =>
      'Bu bajariladigan fayl qoʻllab-quvvatlanadigan Sora paketlar juftligiga tegishli emas. Chiqarishni o\'rnatish ko\'rsatmalaridan foydalaning.';

  @override
  String get updateManual =>
      'Ikkala tasdiqlangan paketni o\'rnatish uchun ushbu buyruqni terminalda ishga tushiring, so\'ngra Sora ni qayta oching. Fayllar yuklab olish katalogida qoladi. VPN ulanishi uziladi.';

  @override
  String get updateSignaturePending =>
      'Yangilanish fayllari reliz bilan e’lon qilingan nazorat yig‘indilari bilan solishtiriladi.';

  @override
  String get updateManualSigWarning =>
      'Quyidagi fayllar relizning nazorat yig‘indilariga mos keladi. Ularni rasmiy relizdan yuklab olgan bo‘lsangiz, buyruqni bajaring.';

  @override
  String get updateVersionRevoked =>
      'Ishlab chiquvchi ushbu versiyani bekor qildi. Iltimos, tuzatilgan nashrni kuting.';

  @override
  String get updateRolloutPending =>
      'Yangiroq versiya asta-sekin chiqarilmoqda va sizga avtomatik ravishda taklif qilinadi.';

  @override
  String updateRollbacking(String version) {
    return '$version versiyasiga qaytarilmoqda...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version yangilanishi ishlash tekshiruvidan oʻtmadi, shuning uchun Sora $fromVersion versiyasiga qaytarildi.';
  }

  @override
  String get updateRollbackError =>
      'Avtomatik orqaga qaytarish amalga oshmadi. Agar yangi versiya ishlamasa, oldingi versiyani qo\'lda qayta o\'rnating.';

  @override
  String get updateRollbackCacheError =>
      'Joriy versiyaning qaytarish uchun tekshirilgan nusxasini tayyorlab boʻlmadi, shuning uchun yangilanish oʻrnatilmadi.';

  @override
  String get updateCopyCommand => 'Nusxa ko\'chirish buyrug\'i';

  @override
  String get updateChecksDisabled => 'Avtomatik tekshirish sozlamalarida o\'chirib qo\'yilgan.';

  @override
  String get updateInstalled => 'Yangilash oʻrnatildi. Sora-ni qayta oching.';

  @override
  String get projectLinks => 'Loyiha';

  @override
  String get githubReleases => 'Chiqarishlar va yuklab olishlar';

  @override
  String get telegramChannel => 'Telegram kanali';

  @override
  String get licenses => 'Litsenziyalar';

  @override
  String get componentLicenses => 'Komponent litsenziyalari';

  @override
  String get collapseServers => 'Serverlarni yig\'ish';

  @override
  String get expandServers => 'Serverlarni kengaytiring';

  @override
  String get hideDescription => 'Tavsifni yashirish';

  @override
  String get showDescription => 'Tavsifni ko\'rsatish';

  @override
  String get errEngineUnsupported =>
      'Tanlangan vosita ushbu profil yoki sozlamalarni qo\'llab-quvvatlamaydi. Avtomatik yoki mos dvigatelni tanlang.';

  @override
  String get errRestore =>
      'Ulanishni tozalash tugallanmadi. Ulanishni qaytadan urinish; tafsilotlar uchun jurnalga qarang.';

  @override
  String get errSessionEnded => 'Bu seans allaqachon tugagan. Ulanish holatini yangilang.';

  @override
  String get retryDisconnect => 'Qaytadan uzib ko‘ring';

  @override
  String get tunStack => 'TUN to\'plami';

  @override
  String get modesInfo => 'Rejimlar haqida';

  @override
  String get modesGuideTitle => 'Dvigatellar va rejimlar';

  @override
  String get modesGuide =>
      'Agar serveringizga qaysi dvigatel kerakligini bilmasangiz, Auto-ni tanlang. Sora ulanishdan oldin profil va sozlamalarni tekshiradi. Dvigatel rejangizning tarmoqli kengligini oshira olmaydi: ishlash server, marshrut, protokol va tarmoqqa bog\'liq.\n\n## rejimlar\n\n### Barcha trafik (TUN)\n\nSora virtual tarmoq interfeysini yaratadi va u orqali dastur trafigini, jumladan TCP va UDP ni yo\'naltiradi. Telegram, o\'yinlar va Discord ovozi uchun ushbu rejimdan foydalaning. Qoidalar aniq saytlar yoki dasturlarni bevosita yuborishi yoki ularni bloklashi mumkin. Tarmoq xizmatiga ruxsat va kerakli protokolni qo\'llab-quvvatlaydigan server kerak.\n\n### System proksi-server\n\nSora mahalliy HTTP/SOCKS proksi-serverini sozlaydi. Tizim proksi-server sozlamalarini hurmat qiladigan ilovalar undan foydalanadi. O\'z tarmoq stekiga ega ilovalar to\'g\'ridan-to\'g\'ri ulanishi mumkin; UDP va ovozli qo\'ng\'iroqlar uchun odatda TUN kerak. Ushbu rejim proksi-serverni qo\'llab-quvvatlaydigan brauzerlar va ilovalarga mos keladi.\n\n### Server yo\'q\n\nLinux da Sora HTTP/TLS soʻrovlarini boʻlish va qayta shakllantirish hamda baʼzi DPI tekshiruvlarini chetlab oʻtish uchun [zapret](https://github.com/bol-van/zapret) dan foydalanadi. Sizning IP-manzilingiz bir xil bo\'lib qoladi va ulanishlar to\'g\'ridan-to\'g\'ri veb-saytga o\'tadi. Natijalar provayderingizga va blokirovka usuliga bog\'liq.\n\nJoriy integratsiya TCP orqali HTTP va TLS uchun tpws dan foydalanadi. U IP blokirovkasini chetlab o\'tmaydi yoki UDP o\'tkazmaydi va Telegram MTProto ulanishlarini kafolatlay olmaydi. Discord ovozli, Telegram qo\'ng\'iroqlari va bunday cheklovlar uchun TUN bilan VPN serveridan foydalaning.\n\n## Dvigatellar\n\n### Avtomatik\n\nSora butun ulanish rejasini qo\'llab-quvvatlaydigan o\'rnatilgan dvigatelni tanlaydi: server protokollari, transportlar, guruhlar, parchalanish va rejim. Mos kelmaydigan qo\'lda tanlov joriy ulanishni to\'xtatishdan oldin rad etiladi. Avtomatik yoki boshqa dvigatelni tanlang va sozlamalarni qaytadan qo\'llang.\n\n### sing-box\n\nYangi Sora paketlariga mijoz tomoni XHTTP va VLESS Encryption qo‘shilgan [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) vilkalari kiradi. Sora qurilish va uning imkoniyatlarini tan oladi. XHTTP bo\'lmagan yuqori oqim bu imkoniyatni faqat o\'z nomidan olmaydi.\n\nQo‘llab-quvvatlanadigan protokollar: VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard va Sora import qila oladigan AmneziaWG 1.x/2.x parametrlari. To‘liq Xray JSON profillari uchun Xray kerak. Yangi AWG 3.x maydonlarini hozircha import qilib bo‘lmaydi. sing-box parol bilan himoyalangan mahalliy boshqaruv portidan foydalanadi; kompyuterdagi boshqa ilovalar bu portni aniqlashi mumkin.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption va TLS parchalanishini qoʻllab-quvvatlaydi. Shuningdek, u Xray provayderi profillarini marshrutlash va guruhlarini saqlab qolgan holda boshqaradi. Bunday profillarni xatti-harakatlarini o\'zgartirmasdan avtomatik ravishda boshqa dvigatelga aylantirib bo\'lmaydi.\n\nTo‘plamdagi Xray TLS sertifikatini tekshirishni o‘chirib qo‘yuvchi sozlamani olib tashladi (`allowInsecure`). Ushbu sozlamani talab qiladigan oddiy serverlar uchun avtomatik sing-box yoki mihomo ni tanlaydi. Xray ni tanlash joriy ulanishni to\'xtatishdan oldin nomuvofiqlik haqida qo\'lda xabar beradi. Eski toʻliq JSON profillari tasdiqlanishi mumkin boʻlgan sertifikat yoki sertifikat PIN-kodi bilan yangilangan provayder profiliga muhtoj.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) buyurtma qilingan qayta tiklash va yukni muvozanatlash guruhlarini, XHTTP va AmneziaWGni qo\'llab-quvvatlaydi. Zaxira serverga avtomatik o\'tish muhim bo\'lganda uni tanlang. Sora ning TLS parchalanish sozlamalari ushbu dvigatelda mavjud emas.\n\n## Sora da moslik\n\n| Xususiyat | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN va TCP/UDP | Ha | Ha | Ha |\n| XHTTP | Ha | Ha | Ha |\n| VLESS Encryption | Ha | Ha | Ha |\n| To\'liq Xray profili | Yo\'q | Ha | Yo\'q |\n| TUIC / AnyTLS | Ikkala | Yo\'q | TUIC |\n| mieru | Yo\'q | Yo\'q | Ha |\n| NaiveProxy | Ha | Yo\'q | Yo\'q |\n| TLS parchalanishi | Ha | Ha | Yo\'q |\n| AmneziaWG 1.x/2.x | Ha¹ | Yo\'q | Ha |\n| Buyurtma qilingan zaxira guruh | Yo\'q | No² | Ha |\n\n¹ J1/J2/J3/Itime profillari mihomo dan foydalanadi; bu maydonlar hech qachon jimgina tashlanmasligi kerak. ² To‘liq Xray profillari guruhi uchun ilova zaxira profilini tanlaydi. Qo\'llab-quvvatlash o\'rnatilgan tuzilishga bog\'liq; Haqida uning versiyasini tekshiring.\n\n## TUN to\'plami\n\nStack virtual interfeys ichida TCP va UDP bilan ishlaydi. Tartiblar panelida Xray va mihomo gVisor, System, Mixed va MIPS ni taklif qiladi. Har bir dvigatel o\'z afzalliklarini saqlaydi. System proksi-server va Serversiz rejimlar bu afzallikdan foydalanmaydi.\n\n- **Mixed**: TCP tizim stekidan foydalanadi, gVisor esa UDP bilan ishlaydi. Bu Linux tizimida mihomo uchun standart variant. Windows tizimida Xray va mihomo odatda MIPS dan foydalanadi.\n- **System**: tizim stekidan foydalanadi. Agar tarmoq ilovalari muammolarga duch kelsa, boshqa variantni sinab ko\'ring.\n- **gVisor**: foydalanuvchilar maydonidagi trafikni boshqaradi.\n- **MIPS**: mihomo ning shaxsiy IP-stacki, 1.19.32. paketli versiyasida mavjud.\n\nLinux da Xray sukut bo\'yicha o\'rnatilgan gVisor dan foydalanadi. Linux da System, Mixed va MIPS TUN dvigateli sifatida mihomo dan foydalanadi, TCP va UDPni autentifikatsiya qilingan mahalliy SOCKS havolasi orqali Xray ga yo‘naltiradi. Xray protokol, provayder profili va marshrutni saqlab qoladi. Ushbu uchta variant o\'rnatilgan mihomo ni talab qiladi. Windows da Xray barcha to‘rtta TUN steki uchun mihomo 1.19.32 yoki yangi versiyasidan foydalanadi. Protokollar va yo‘naltirish Xray ichida qoladi. Bu birikmada ilova qoidalari faqat to‘g‘ridan-to‘g‘ri ulanish va bloklashni qo‘llaydi; Linux da bu qoidalar Xray ichki gVisor stekini talab qiladi.\n\nKo\'prik ikkinchi jarayonni amalga oshiradi. Linuxda uchta bo\'sh o\'lchovda u mahalliy Xray TUNga qaraganda 32–36 MiB ko\'proq jismoniy xotira ishlatgan. Bu yuklab olish yukini o\'lchamaydi: CPU va xotira narxi ulanishlarga bog\'liq. sing-box da stek selektori yo\'q. Hech qanday stek har bir tarmoqda yaxshiroq ishlashni kafolatlamaydi. Uni tarmoqda sinab ko\'rish uchun stekni tanlang va Qo\'llash va qayta ulanishni tanlang.\n\n## Sozlamalarni qo\'llash\n\nServerni tanlash avtomatik ravishda qayta ulanadi. Rejim, vosita, DNS va qoida sozlamalari darhol saqlanadi; faol ulanish vaqtida ulardan foydalanish uchun Ilova tugmasini bosing va qayta ulaning. Dvigatelni qayta ishga tushirish yuklab olish va qo\'ng\'iroqlarni to\'xtatishi mumkin. Takroriy bosish parallel ulanishlarni boshlamaydi; o\'chirish o\'tishni tugatadi va ulanishni bo\'shatadi.\n\nTunnel qulaganda faqat VPN orqali Internet to\'g\'ridan-to\'g\'ri trafikni bloklaydi. Bu butun mashinaga ta\'sir qiladi. Aniq uzilish Sora qoidalarini olib tashlaydi. Agar tozalash tugamasa, qaytadan uzib ko\'ring va jurnalni oching.\n\n## Loyiha hujjatlari\n\n- [sing-box-lx: konfiguratsiya va qo\'llab-quvvatlash](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box hujjatlari](https://sing-box.sagernet.org/)\n- [Xray hujjatlari](https://xtls.github.io/)\n- [mihomo hujjatlari](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: ishlash va cheklovlar](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP trafikini Jitsi, Yandex Telemost yoki WB Stream videoqo‘ng‘irog‘i orqali uzatadi. olcrtc:// havolasini yoki QR kodini import qiling. Proksi va TUN rejimlarida sing-box, Xray va mihomo bilan ishlaydi; UDP qo‘llab-quvvatlanmaydi. Har ikki tomonga mos OLC2 yig‘ilmalari kerak. Asl loyiha arxivlangan.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Kengaytmalar';

  @override
  String extRatingLabel(String rating) {
    return 'Reyting $rating / 5';
  }

  @override
  String extByAuthor(String author) {
    return 'Muallif: $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'O\'rnatishlar: $count';
  }

  @override
  String get extInstallOne => '1 ta oʻrnatish';

  @override
  String get extSideloadWarning => 'Faqat muallif o‘zi imzolagan kalitga ishonsangiz o‘rnating.';

  @override
  String get extPermissionsWidened => 'Yangilanish yangi ruxsatlarni talab qiladi:';

  @override
  String get extDangerousAck => 'Men bu ruxsatlar jiddiy ekanligini tushunaman';

  @override
  String get extInstall => 'O\'rnatish';

  @override
  String get extUpdate => 'Yangilash';

  @override
  String get extCancel => 'Bekor qilish';

  @override
  String get extConfirm => 'Tasdiqlash';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'O‘rnatilgan kengaytmalar';

  @override
  String get extSearchHint => 'Kengaytmalarni qidirish';

  @override
  String get extCatAll => 'Hammasi';

  @override
  String get extCatTools => 'Asboblar';

  @override
  String get extCatThemes => 'Mavzular';

  @override
  String get extCatAutomation => 'Avtomatlashtirish';

  @override
  String get extCatStats => 'Statistika';

  @override
  String get extCatNetwork => 'Tarmoq';

  @override
  String get extSortBy => 'Saralash';

  @override
  String get extSortPopular => 'Eng mashhur';

  @override
  String get extSortRating => 'Eng yuqori baho';

  @override
  String get extSortName => 'Nomi';

  @override
  String get extCatalogError => 'Katalogni yuklab bo‘lmadi';

  @override
  String get extRetry => 'Qayta urinib ko‘ring';

  @override
  String get extEmptySearch => 'Hech narsa topilmadi';

  @override
  String get extEmptyInstalled => 'Kengaytmalar hali oʻrnatilmagan.\nKatalogdan birini toping yoki fayldan o\'rnating.';

  @override
  String get extInstallFromFile => 'Fayldan oʻrnating';

  @override
  String get extInstallFromUrl => 'URL dan oʻrnating';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Yuklab olish';

  @override
  String get extDownloading => 'Yuklab olinmoqda…';

  @override
  String get extVerifying => 'Tekshirilmoqda…';

  @override
  String get extInstalling => 'O‘rnatilmoqda…';

  @override
  String get extInstallFailed => 'O‘rnatish amalga oshmadi';

  @override
  String get extErrSignature =>
      'Imzo tekshiruvi muvaffaqiyatsiz tugadi. Fayl shikastlangan yoki oʻzgartirilgan boʻlishi mumkin.';

  @override
  String get extErrManifest => 'Kengaytma manifesti yaroqsiz.';

  @override
  String get extErrNetwork => 'Tarmoq xatosi. Ulanishingizni tekshiring va qaytadan urining.';

  @override
  String get extErrHash => 'Yuklash katalogga mos kelmaydi. Bu o\'zgartirilgan bo\'lishi mumkin.';

  @override
  String extErrMinApp(String version) {
    return 'Bu kengaytmaga ilovaning $version yoki yangiroq versiyasi kerak.';
  }

  @override
  String get extErrHttpsOnly => 'Faqat https:// havolalarga ruxsat berilgan';

  @override
  String get extErrGeneric => 'Nimadir xato ketdi. Iltimos, qayta urinib koʻring.';

  @override
  String get extErrAuthorKeyChanged =>
      'Ushbu yangilanish o\'rnatilgan versiyadan boshqa muallif kaliti bilan imzolangan, shuning uchun u bloklangan. Agar siz yangi kalitga ishonsangiz, kengaytmani o\'chirib tashlang va uni qayta o\'rnating.';

  @override
  String get extDisabled => 'Oʻchirilgan';

  @override
  String extToggleEnabled(String name) {
    return 'Yoqish $name';
  }

  @override
  String get extSearchInstalled => 'Oʻrnatilgan kengaytmalardan qidirish';

  @override
  String get extUpdateAll => 'Hammasini yangilang';

  @override
  String extUpdatesAvailable(int count) {
    return '$count yangilanishlari mavjud';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count yangilandi';
  }

  @override
  String get extRiskNormal => 'Oddiy';

  @override
  String get extRiskSensitive => 'Maxfiy';

  @override
  String get extRiskDangerous => 'Yuqori xavf';

  @override
  String get extPermissionsRemoved => 'Endi talab qilinmaydi:';

  @override
  String get extUpdateFailedKept => 'Oldingi versiya hali ham o\'rnatilgan.';

  @override
  String get extConflictsTitle => 'Kengaytma ziddiyati';

  @override
  String get extConflictTheme => 'Ilova mavzusi';

  @override
  String get extConflictNetHooks => 'Tarmoq ilgaklari';

  @override
  String extConflictWinner(String name) {
    return 'Ustuvorlik: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count ziddiyatlar sizning qaroringizga muhtoj';
  }

  @override
  String get extConflictsResolve => 'Mojarolarni hal qilish';

  @override
  String extVersionLabel(String version) {
    return 'Versiya $version';
  }

  @override
  String get extPermissionsTitle => 'Ruxsatlar';

  @override
  String get extNoPermissions => 'Maxsus ruxsatlar yo\'q.';

  @override
  String get extSettings => 'Sozlamalar';

  @override
  String get extSaveSettings => 'Sozlamalarni saqlang';

  @override
  String extUpdateTo(String version) {
    return '$version ga yangilang';
  }

  @override
  String get extEnabled => 'Yoqilgan';

  @override
  String extRollbackTo(String version) {
    return '$version ga qaytish';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version versiyasiga qaytarilsinmi?';
  }

  @override
  String get extUninstall => 'O‘chirish';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” va uning sozlamalari olib tashlansinmi?';
  }

  @override
  String get extPanelUnavailable => 'Kengaytma paneli mavjud emas.';

  @override
  String get extPermConnectionsRead => 'Faol ulanishlar roʻyxatiga qarang';

  @override
  String get extPermServersRead => 'Serverlaringiz roʻyxatini koʻring';

  @override
  String get extPermSettingsRead => 'Ilova sozlamalarini o‘qing';

  @override
  String get extPermSettingsWrite => 'Ilova sozlamalarini o‘zgartiring';

  @override
  String get extPermNotifications => 'Bildirishnomalarni ko‘rsatish';

  @override
  String get extPermTray => 'Tizim treyi menyusiga bandlar qoʻshish';

  @override
  String get extPermUiPanel => 'Ilova ichidagi panellarni ko‘rsatish';

  @override
  String get extPermThemeApply => 'Mavzularni qo\'llash';

  @override
  String get extPermRoutingRules =>
      'Marshrutlash qoidalarini qo\'shing (tarmoq trafigining qayerga ketishiga ta\'sir qiladi)';

  @override
  String get extPermNetHooks => 'Tarmoq yoʻliga integratsiyalash (DPI chetlab oʻtish modullari)';

  @override
  String get extPermNetFetch => 'Ruxsat berilgan roʻyxatdan URL soʻrovi';

  @override
  String get extPermBackground => 'Fon vazifalarini bajaring';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Orqa fonda ishlaydi';

  @override
  String get extCapNetHook => 'Cheklovni chetlab oʻtish va tarmoq ilgaklari';

  @override
  String get extCapPanel => 'Interfeys panellari';

  @override
  String get extCapRouting => 'Marshrutlash qoidalari';

  @override
  String get extCapTheme => 'Mavzular';

  @override
  String get extCapWidget => 'Vidjetlar';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'O\'zgarishlar jurnali';

  @override
  String get extImageFailed => 'Tasvirni yuklab bo‘lmadi';

  @override
  String get extScreenshots => 'Skrinshotlar';

  @override
  String get extSortRelevance => 'Tegishlilik';

  @override
  String get extPermNetworkDetail => 'VPN so‘rovlariga faqat quyidagi xostlarga ruxsat beriladi.';

  @override
  String get extBgTitle => 'Fon vazifasi';

  @override
  String get extBgEnabled => 'Orqa fonda ishga tushirish';

  @override
  String get extBgInterval => 'Ishga tushirish oraligʻi';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count daqiqa', one: '$count daqiqa');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count soat', one: '$count soat');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Fon vazifasini boshqarish uchun kengaytmani yoqing.';

  @override
  String get extCapNetwork => 'Tarmoqqa kirish';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Tarmoq: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Faylga $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diagnostikasi';

  @override
  String get diagnosticNoData =>
      'Hozircha hech qanday soʻrov qayd etilmagan. Avval tezlikni tekshirish veb-saytini oching.';

  @override
  String get qrShareTitle => 'QR kodini ulashing';

  @override
  String get qrScanTitle => 'QR kodini skanerlang';

  @override
  String get qrCopyLink => 'Havolani nusxalash';

  @override
  String get qrWarning => 'Kodni faqat ishonchli odamlarga ko‘rsating.';

  @override
  String get qrScanHint => 'QR kodli skrinshot yoki rasmni tanlang yoki havolani joylang';

  @override
  String get qrFromClipboard => 'Buferdan joylashtirish';

  @override
  String get qrNoCode => 'Bu rasmda QR kod topilmadi.';

  @override
  String get qrInvalid => 'Ushbu QR kodida yaroqli havola mavjud emas.';

  @override
  String get qrScan => 'Skanerlash QR';

  @override
  String get qrFromImage => 'Rasmni ochish';

  @override
  String get connGroupByProcess => 'Jarayon bo\'yicha guruhlash';

  @override
  String get connListView => 'Roʻyxat';

  @override
  String get connCopyHost => 'Xostni nusxalash';

  @override
  String get connAddRule => 'Qoida qoʻshish';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ulanish', one: '$count ulanish');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Oldindan o\'rnatilgan';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Shaxsiy';

  @override
  String get dnsCheck => 'Ma\'lumotlar sizib chiqishini tekshiring';

  @override
  String get dnsChecking => 'Tekshirilmoqda...';

  @override
  String get dnsNoLeak => 'Sizib chiqish aniqlanmadi';

  @override
  String get dnsLeakFound => 'Sizib chiqish aniqlandi';

  @override
  String get dnsLastCheck => 'Oxirgi tekshirish';

  @override
  String get dnsNeverChecked => 'Hali tekshirilmagan';

  @override
  String get dnsLeakCheckTunnelDns => 'Tunnelning DNS nom yechuvchilari';

  @override
  String get dnsLeakCheckSystemResolvers => 'Tizim nom yechuvchilari';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Tarmoq qulfi orqali DNS himoyasi';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Yuqoridagi DNS sozlamalarida tunnel uchun DNS ni sozlang.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Tizim tunnel tashqarisida qaysi nom yechuvchilardan foydalanishini tekshiring.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS trafigi tunnelda qolishi uchun tarmoq qulfini yoqing.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Tizimning shifrlangan DNS xizmati';

  @override
  String get dnsLeakCheckDnsSpoof => 'Soxta DNS javoblar';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Tizimingiz tunneldan tashqarida qaysi shifrlangan DNS so‘nggi nuqtalardan foydalanishini tekshiring.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Nom yechuvchilar javoblarni soxtalashtira olmasligi uchun tunnelda shifrlangan DNS (DoT yoki DoH) ishlating.';

  @override
  String get dnsCheckNeedsConnection => 'Avval VPN ga ulaning, keyin sizib chiqmasligini tekshiring.';

  @override
  String get dnsExpected => 'kutilmoqda';

  @override
  String get dnsActual => 'Kuzatilgan';

  @override
  String get measureSpeed => 'Tezlikni o\'lchash';

  @override
  String get benchmarkStale => 'eskirgan';

  @override
  String get autoSelectMode => 'Serverni avtomatik tanlash';

  @override
  String get autoSelectPing => 'Eng tez ping';

  @override
  String get autoSelectSpeed => 'Eng tez tezlik';

  @override
  String get autoSelectSmart => 'Aqlli tanlov';

  @override
  String get coreWatchUnstable => 'Yadro bilan aloqa beqaror. Biroz kutib, qayta ulanishga urinib koʻring.';

  @override
  String get watchReconnect => 'Qayta ulaning';

  @override
  String get crashRestoreTitle => 'Oxirgi seans uzildi';

  @override
  String get restoreOnCrash => 'Buzilishdan keyin seansni tiklash';

  @override
  String get crashRestore => 'Qayta tiklash';

  @override
  String get crashDismiss => 'Hozir emas';

  @override
  String get overrideTitle => 'Mening tahrirlarim';

  @override
  String get overrideEdit => 'Serverlarni tahrirlash';

  @override
  String get overrideHide => 'Yashirish';

  @override
  String get overrideUnhide => 'Ko\'rsatish';

  @override
  String get overrideClear => 'Tahrirlarni tiklash';

  @override
  String get overrideEmpty => 'Hozircha tahrirlar yo‘q';

  @override
  String get overrideCustomRules => 'O\'z qoidalari';

  @override
  String get errBenchmarkUnsupported => 'Tezlikni oʻlchash uchun yangiroq yadro kerak. Sora’ni yangilang.';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total dan $done o‘lchovi…';
  }

  @override
  String get profiles => 'Tarmoq profillari';

  @override
  String get profilesEmpty =>
      'Hozircha profillar yo‘q. Ma\'lum tarmoqlarda sozlamalarni avtomatik qo\'llash uchun bitta yarating.';

  @override
  String get profileAdd => 'Profil qo‘shish';

  @override
  String get profileName => 'Profil nomi';

  @override
  String get profileSsids => 'Wi-Fi tarmoqlari (SSID)';

  @override
  String get profileSsidsHint => 'Uy, Ofis vergul bilan ajratilgan';

  @override
  String get profileGateways => 'Tarmoq shlyuzlari';

  @override
  String get profileAsns => 'AS raqamlari';

  @override
  String get profileAutoApply => 'Avtomatik qoʻllash';

  @override
  String get profileAutoApplyHint => 'Oʻchirilgan boʻlsa, profilni qoʻllashdan oldin tasdiq soʻraladi.';

  @override
  String get profileSnapshot => 'Joriy sozlamalarni eslab qoling';

  @override
  String get profileSnapshotDone => 'Joriy sozlamalar profilga saqlangan';

  @override
  String get profileDelete => 'Profilni oʻchirish';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" profili o‘chirilsinmi?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '“$name” profili qo‘llanilsinmi?';
  }

  @override
  String get profileApply => 'Qoʻllash';

  @override
  String profileApplied(Object name) {
    return '“$name” profili qo‘llanildi';
  }

  @override
  String get profileUndo => 'Bekor qilish';

  @override
  String get profileActive => 'Faol';

  @override
  String networkNow(Object info) {
    return 'Hozir: $info';
  }

  @override
  String get networkUnknown => 'Tarmoq maʼlumotlari mavjud emas';

  @override
  String get profileNoTriggers => 'Kamida bitta trigger qo‘shing: SSID, shlyuz yoki ASN';

  @override
  String get chains => 'Proksi zanjirlar';

  @override
  String get chainsEmpty =>
      'Hali zanjir yo\'q. 2–3 serverni bog\'lang, shunda trafik ularning har biri orqali o\'tadi.';

  @override
  String get chainAdd => 'Yangi zanjir';

  @override
  String get chainName => 'zanjir nomi';

  @override
  String get chainPickServers => '2–3 ta serverni tanlang';

  @override
  String get chainOrderHint => 'Qayta tartiblash uchun torting: trafik tepadan kiradi va pastdan chiqadi.';

  @override
  String get chainTooFew => 'Zanjirga kamida ikkita server kerak. Yana bir server qoʻshing.';

  @override
  String get chainTooMany => 'Zanjirda koʻpi bilan uchta server boʻlishi mumkin. Ortiqcha serverlarni olib tashlang.';

  @override
  String get chainEstimate => 'Taxminiy kechikish';

  @override
  String get chainSave => 'Zanjirni saqlash';

  @override
  String get chainDelete => 'Zanjirni o\'chirish';

  @override
  String chainDeleteConfirm(Object name) {
    return '“$name” zanjiri o‘chirilsinmi?';
  }

  @override
  String get chainUnsupported => 'Tanlangan yadro zanjirlarni qoʻllamaydi. Mos yadroni tanlang.';

  @override
  String get chainHopMissing =>
      'Zanjirdagi serverlardan biri endi mavjud emas. Shu bosqich uchun boshqa server tanlang.';

  @override
  String chainHop(Object n) {
    return 'Oraliq tugun $n';
  }

  @override
  String get chainEntry => 'Kirish';

  @override
  String get chainExit => 'Chiqish';

  @override
  String get sync => 'Qurilmani sinxronlashtirish';

  @override
  String get syncDevices => 'Mening qurilmalarim';

  @override
  String get syncEmpty => 'Juftlangan qurilmalar yoʻq. Mahalliy tarmoq orqali boshqa qurilmani juftlang.';

  @override
  String get syncPair => 'Qurilmani juftlash';

  @override
  String get syncShowCode => 'Kodimni ko\'rsating';

  @override
  String get syncScanCode => 'Kodni skanerlash';

  @override
  String get syncRevoke => 'Olib tashlash';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" bekor qilinsinmi?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Oxirgi sinxronlash: $time';
  }

  @override
  String get syncNever => 'Hech qachon';

  @override
  String get syncNoLan => 'Qurilmalar bir xil mahalliy tarmoqda bo‘lishi kerak';

  @override
  String get syncPaired => 'Qurilma juftlandi';

  @override
  String get syncPairingTitle => 'Ushbu qurilma bilan juftlash';

  @override
  String get syncWaiting => 'Boshqa qurilma kutilmoqda…';

  @override
  String get syncSecureNote => 'Kanal uchdan uchgacha shifrlangan. Hisoblar va bulut serverlari kerak emas.';

  @override
  String get zapretWithVpn => 'To\'g\'ridan-to\'g\'ri tarmoq trafigi uchun DPI filtrlashni chetlab o\'ting';

  @override
  String get zapretWithVpnHint =>
      'zapret VPN tunneli bilan birga ishlaydi: tunnel trafigi VPN orqali, toʻgʻridan-toʻgʻri trafik esa cheklovni chetlab oʻtish vositasi orqali oʻtadi.';

  @override
  String get chainDuplicate => 'Zanjirda bir server takrorlangan. Har bir bosqich uchun boshqa server tanlang.';

  @override
  String get edit => 'Tahrirlash';

  @override
  String get remove => 'O\'chirish';

  @override
  String get autoSwitchOnDegrade => 'Sifat pasayganda avtomatik almashtirish';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Tanlangan server juda sekinlashsa yoki javob bermay qolsa, Sora oʻlchovlarga koʻra eng yaxshi serverga oʻtadi, ammo har 10 daqiqada bir martadan koʻp emas.';

  @override
  String get tunStackMixed => 'Aralash';

  @override
  String get tunStackSystem => 'Tizim';

  @override
  String get customServerAdd => 'Maxsus server qo‘shing';

  @override
  String get customServers => 'Mening serverlarim';

  @override
  String get customServerName => 'Nomi';

  @override
  String get customServerNameHint => 'Masalan: mening VPS';

  @override
  String get customServerNameRequired => 'Nomini kiriting';

  @override
  String get customServerAddress => 'Manzil';

  @override
  String get customServerAddressHint => 'example.com yoki 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Server manzilini kiriting';

  @override
  String get customServerAddressInvalid => 'Manzil noto‘g‘ri';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port 1 dan 65535 gacha bo\'lgan raqam bo\'lishi kerak';

  @override
  String get customServerProtocol => 'Protokol';

  @override
  String get customServerCredentials => 'Kirish ma\'lumotlari';

  @override
  String get customServerOptional => 'Majburiy emas';

  @override
  String get customServerShowSecret => 'Sirni ko\'rsatish';

  @override
  String get customServerHideSecret => 'Sirni yashirish';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” serveri o‘chirilsinmi?';
  }

  @override
  String get customServerTest => 'Sinov';

  @override
  String get leakTestTitle => 'Ma\'lumotlar sizib chiqishi uchun sinov';

  @override
  String get leakTestIntro =>
      'Trafik qurilmadan tunnel tashqarisida chiqa olishini tekshiradi: bevosita DNS va ICMP soʻrovlari, IPv6 chiqishi va tizim nom yechuvchilari. Ulanish faol boʻlganda ishga tushiring.';

  @override
  String get leakTestRun => 'Tekshiring';

  @override
  String get leakTestCancel => 'Bekor qilish';

  @override
  String get leakTestNeedsConnection => 'Ma\'lumotlar sizib chiqishini tekshirish uchun VPN ga ulaning.';

  @override
  String leakTestProgress(int count) {
    return 'Testlar yakunlandi: $count';
  }

  @override
  String get leakTestAllClear => 'Sizib chiqish aniqlanmadi';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta sizib chiqish aniqlandi',
      one: '$count ta sizib chiqish aniqlandi',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Tuzatish';

  @override
  String get leakTestFixedNote => 'Tarmoq qulfi yoqilgan. Tekshirish uchun sinovni qayta ishga tushiring.';

  @override
  String get leakTestCheckDirectDns => 'Toʻgʻridan-toʻgʻri DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP aks-sado';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Tizim nom yechuvchilari';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tunnel ulanishi';

  @override
  String get leakTestCheckTunnelDns => 'DNS tunnel orqali';

  @override
  String get noticeDegraded => 'Server sekinlashdi. Sora oʻlchov davomida topilgan eng yaxshi serverga oʻtdi.';

  @override
  String get obfs => 'Trafikni yashirish';

  @override
  String get syncCodeExpired => 'Kod muddati tugagan';

  @override
  String get syncDaemonFailed => 'Sinxronizatsiya xizmatini ishga tushirib bo‘lmadi';

  @override
  String get syncDaemonMissing =>
      'sora-sync komponenti topilmadi. Qurilmani sinxronlashni yoqish uchun ilovani qayta oʻrnating.';

  @override
  String get syncDaemonStarting => 'Sinxronizatsiya xizmati ishga tushirilmoqda…';

  @override
  String get syncErrAuth =>
      'Sinxronizatsiya xizmati kirish tokenini rad etdi. Ilovani qayta ishga tushiring va qaytadan urinib ko\'ring.';

  @override
  String get syncErrNotFound => 'Qurilma endi juftlanmagan';

  @override
  String get syncErrPairingActive => 'Juftlash seansi allaqachon ochiq';

  @override
  String get syncErrUnreachable =>
      'Boshqa qurilma javob bermadi. U bir xil tarmoqda ekanligiga va uning kodini ko\'rsatayotganiga ishonch hosil qiling.';

  @override
  String get syncError => 'Sinxronizatsiya xatosi';

  @override
  String syncExpiresIn(String duration) {
    return 'Kodning amal qilish muddati $duration dan keyin tugaydi';
  }

  @override
  String get syncJoining => 'Qurilma bilan juftlanmoqda…';

  @override
  String get syncLegacyCleared =>
      'Eski qurilmalar roʻyxati amalda juftlanmagan edi, shu sababli tozalandi. Qurilmalaringizni qayta juftlang, bu safar haqiqiy juftlik yaratiladi.';

  @override
  String get syncNewCode => 'Yangi kod';

  @override
  String syncPairedWith(String name) {
    return '$name juftlandi';
  }

  @override
  String get syncRetry => 'Takrorlang';

  @override
  String get syncStopShowing => 'Kodni yashirish';

  @override
  String get syncSyncNow => 'Hozir sinxronlash';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Qabul qilindi $pulled, yuborildi $pushed';
  }

  @override
  String get syncResultTitle => 'Sinxronizatsiya natijasi';

  @override
  String get syncPulled => 'Qabul qilindi';

  @override
  String get syncPushed => 'Yuborildi';

  @override
  String get syncNoChanges => 'O‘zgarishlar aniqlanmadi';

  @override
  String get syncDocKindSubscriptions => 'Obunalar';

  @override
  String get syncDocKindSettings => 'Ilova sozlamalari';

  @override
  String get syncDocKindOverrides => 'Obunalarning shaxsiy oʻzgartirishlari';

  @override
  String get syncDocKindProfiles => 'Tarmoq profillari';

  @override
  String get syncDocKindChains => 'Proksi zanjirlar';

  @override
  String syncFrom(String name) {
    return '$name qurilmasidan';
  }

  @override
  String get syncThisDevice => 'Ushbu qurilma';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Paketni suratga olish';

  @override
  String get diagnosticEvents => 'Windows voqealari';

  @override
  String get diagnosticCapture => '10 soniya davomida suratga oling';

  @override
  String get diagnosticRequiresTun => 'Paketlarni yozib olish uchun faol Sora TUN ulanishi kerak.';

  @override
  String get diagnosticUnavailable => 'Ushbu diagnostika ushbu platformada mavjud emas.';

  @override
  String get extErrRevoked => 'Sora jamoasi bu kengaytma versiyasini xavfli yoki buzuq bo‘lgani uchun qaytarib oldi.';

  @override
  String get extErrRevocationsExpired => 'Bekor qilingan kengaytmalar ro‘yxati yangilanguncha o‘rnatish bloklangan.';

  @override
  String extRevokedDisabled(String names) {
    return 'Qaytarib olingan kengaytmalar o‘chirildi: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Maxfiy kalit';

  @override
  String get customServerWgAddresses => 'Interfeys manzillari';

  @override
  String get customServerWgPeerKey => 'Serverning ochiq kaliti';

  @override
  String get customServerWgPresharedKey => 'Umumiy kalit';

  @override
  String get customServerWgAllowedIps => 'Ruxsat etilgan IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, soniya';

  @override
  String get customServerWgKeyInvalid => 'Kalit wg genkey chiqargandek base64’da 32 bayt bo‘lishi kerak.';

  @override
  String get customServerWgCidrInvalid => 'Vergul bilan ajratilgan prefikslarni kiriting, masalan 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => '0 dan 65535 gacha soniya sonini kiriting.';

  @override
  String get strictKillSwitch => 'Qatʼiy tarmoq qulfi';

  @override
  String get strictKillSwitchWarning =>
      'Ulangandan keyin nosozlik, qayta ishga tushirish yoki ilovadan chiqishda ham VPN tashqarisidagi trafikni bloklaydi. Kirish faqat ulanish uzilganda yoki bu sozlama oʻchirilganda tiklanadi. Qurilma qayta yoqilganda bloklash faqat ishga tushishda ulanish yoqilgan boʻlsa davom etadi.';

  @override
  String get extWorkerFailed => 'Kengaytmaning fon vazifasi bajarilmadi. Kengaytma jurnalini tekshiring.';

  @override
  String get extAssetRejected =>
      'Kengaytma faylida oʻqishni qiyinlashtiradigan ranglar yoki notoʻgʻri qoidalar bor. Kengaytma muallifidan faylni tuzatishni soʻrang.';

  @override
  String get extVerifiedSora => 'Sora tomonidan tasdiqlangan';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Ochish';

  @override
  String get customServerOwn => 'Shaxsiy server';

  @override
  String get customServerPaste => 'Havolani joylash';

  @override
  String get customServerUser => 'Foydalanuvchi';

  @override
  String get customServerPassword => 'Parol';

  @override
  String get customServerSecretRequired => 'Qiymat kiriting';

  @override
  String get customServerLinkInvalid => 'Server havolasi noto‘g‘ri';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Sora ichki xatosi. Jurnalni saqlang va muammo haqida xabar bering.';

  @override
  String get errTls => 'Server sertifikati rad etildi. Soatni tekshiring yoki provayderga murojaat qiling.';

  @override
  String get errFileAccess => 'Faylga kirib bo‘lmaydi. Ruxsatlar va bo‘sh joyni tekshiring.';

  @override
  String get errDataLimit => 'Ma’lumot juda ko‘p. Kamroq element tanlab, qayta urinib ko‘ring.';

  @override
  String get errCredentials => 'Saqlangan kirish ma’lumotlari yo‘q. Serverni qayta import qiling.';

  @override
  String subscriptionStale(String time) {
    return 'Yangilangan vaqt: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Hali yangilanmagan. Qayta urinib ko‘ring.';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Server HTTP $status kodini qaytardi. Havolani tekshiring yoki provayderga murojaat qiling.',
      zero: 'Server soʻrovni rad etdi. Havolani tekshiring yoki provayderga murojaat qiling.',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Server sozlamalari to‘liq emas yoki qo‘llanmaydi. Obunani yangilang.';

  @override
  String get errServerIds => 'Ikki server bir xil identifikatorga ega. Ularni qayta import qiling.';

  @override
  String get errRoutingGroup => 'Yo‘nalish yo‘q serverlarga yoki buzilgan guruhga ishora qilmoqda. Obunani yangilang.';

  @override
  String get errConnections => 'Ulanishlar ro‘yxati mavjud emas. Ulaning yoki boshqa mexanizmni tanlang.';

  @override
  String get errLogs => 'Bu xizmat jurnal yuritmaydi. Sora’ni yangilang.';

  @override
  String get errDiagnostics => 'Diagnostika yig‘ilmadi. Qayta urining yoki jurnalni saqlang.';

  @override
  String get errMissingItem => 'So‘ralgan element endi mavjud emas. Ro‘yxatni yangilang.';

  @override
  String get errInvalidRequest =>
      'So‘rovda noto‘g‘ri qiymatlar bor. Kiritilgan ma’lumotlarni tekshirib, qayta urining.';

  @override
  String get errProxyLogin =>
      'Tizim proksisi bu kirishni qo‘llamaydi. Mahalliy proksi foydalanuvchi nomi va parolini o‘chiring.';

  @override
  String get errLogFilter => 'Jurnal filtri noto‘g‘ri. Qidiruvni tozalab, qayta urining.';

  @override
  String get errSubRedirect => 'Server xavfli manzilga yo‘naltirdi. Provayderdan yangi havola so‘rang.';

  @override
  String get errProxySetup => 'Tizim proksisi sozlanmadi. Qayta ulaning yoki jurnalni oching.';

  @override
  String get notificationsToday => 'Bugun';

  @override
  String get notificationsYesterday => 'Kecha';

  @override
  String get notificationsMarkRead => 'Barchasini oʻqilgan deb belgilash';

  @override
  String get notificationsUnread => 'Oʻqilmagan';

  @override
  String get desktopNotifications => 'Ish stoli bildirishnomalari';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Obunani yangilash oraligʻi notoʻgʻri. Provayder tavsiya qilgan oraliqni tanlang.';

  @override
  String get errRule =>
      'Yoʻnaltirish qoidasida xato bor. Qoidada koʻrsatilgan domen, IP manzil yoki ilovani tekshiring.';

  @override
  String get errDns => 'DNS sozlamalari notoʻgʻri. DNS serverining manzilini tekshiring.';

  @override
  String get errEndpoint => 'Tekshiriladigan server manzili notoʻgʻri. Xost nomi va portini tekshiring.';

  @override
  String get errCancelled => 'Soʻrov bekor qilindi. Kerak boʻlsa, amalni takrorlang.';

  @override
  String get customServerOptions => 'Ulanish sozlamalari';

  @override
  String get customServerTransport => 'Transport';

  @override
  String get customServerSecurity => 'Xavfsizlik';

  @override
  String get customServerCipher => 'Shifr';

  @override
  String get customServerWgInterface => 'Interfeys';

  @override
  String get customServerWgPeer => 'Tengdosh';

  @override
  String get customServerOptionsInfo =>
      'Provayder bergan transport va TLS sozlamalarini kiriting yoki server havolasini joylashtiring.';
}
