// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class SAz extends S {
  SAz([String locale = 'az']) : super(locale);

  @override
  String get stateOff => 'Qoşulmayıb';

  @override
  String get stateConnecting => 'Qoşulur';

  @override
  String get stateConnected => 'Qoşuldu';

  @override
  String get stateReconnecting => 'Yenidən qoşulur';

  @override
  String get stateDisconnecting => 'Bağlantı kəsilir';

  @override
  String get coreMissing => 'Sora xidməti cavab vermir';

  @override
  String get serverAuto => 'Ən sürətli';

  @override
  String get serverBypass => 'Server yoxdur';

  @override
  String get addSubscription => 'Abunəlik əlavə edin';

  @override
  String get servers => 'Serverlər';

  @override
  String get settings => 'Parametrlər';

  @override
  String get subscription => 'Abunəlik';

  @override
  String get subscriptionLink => 'Abunə keçidi';

  @override
  String get add => 'əlavə et';

  @override
  String get refresh => 'Yeniləyin';

  @override
  String get rename => 'Adını dəyişdirin';

  @override
  String get delete => 'Sil';

  @override
  String get cancel => 'Ləğv et';

  @override
  String get save => 'Saxla';

  @override
  String get name => 'ad';

  @override
  String deleteSubscription(String name) {
    return '“$name” silinsin?';
  }

  @override
  String get routes => 'Marşrutlar';

  @override
  String get presetGlobal => 'Hər şey VPN vasitəsilə';

  @override
  String get presetRu => 'Rusiya birbaşa';

  @override
  String get presetIr => 'İran birbaşa';

  @override
  String get presetCn => 'Çin birbaşa';

  @override
  String get blockAds => 'Reklamları bloklayın';

  @override
  String get killSwitch => 'İnternet yalnız VPN vasitəsilə';

  @override
  String get engine => 'Mühərrik';

  @override
  String get engineAuto => 'Avtomatik';

  @override
  String get animations => 'Animasiyalar';

  @override
  String get logs => 'Giriş';

  @override
  String get about => 'Haqqında';

  @override
  String get logsAll => 'Hamısı';

  @override
  String get logsImportant => 'Əhəmiyyətli';

  @override
  String get logsErrors => 'Səhvlər';

  @override
  String get search => 'Axtar';

  @override
  String get export => 'Faylda saxla';

  @override
  String get clear => 'Təmiz';

  @override
  String get logsEmpty => 'Burada heç nə';

  @override
  String get connEmpty => 'Bağlantı yoxdur';

  @override
  String appVersion(String version) {
    return 'Versiya $version';
  }

  @override
  String get notInstalled => 'Quraşdırılmayıb';

  @override
  String get sourceCode => 'Mənbə kodu';

  @override
  String get license => 'Lisenziya';

  @override
  String usage(String used, String total) {
    return '$used və $total';
  }

  @override
  String until(String date) {
    return '$date qədər';
  }

  @override
  String get expired => 'İstifadə müddəti bitdi';

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
    return '$n TB';
  }

  @override
  String get errGeneric => 'Nəsə xəta baş verdi';

  @override
  String get errCore => 'Sora xidməti cavab vermir. Bir az gözləyib yenidən cəhd edin.';

  @override
  String get errAuth => 'Sora xidmətinə giriş rədd edildi. Tətbiqi yenidən başladıb təkrar cəhd edin.';

  @override
  String get errVersion => 'Sora tətbiqi və xidməti fərqli versiyalardadır. Sora-nı yeniləyin.';

  @override
  String get errBusy => 'Əvvəlki əmr hələ icra olunur. Onun tamamlanmasını gözləyin.';

  @override
  String get errEngineMissing => 'Bu server üçün lazım olan mühərrik tapılmadı. Sora yeniləmələrini yoxlayın.';

  @override
  String get errEngineStart => 'Mühərrik işə düşmədi. Səbəbi öyrənmək üçün bağlantı jurnalına baxın.';

  @override
  String get errEngineStopped => 'Mühərrik dayandı. Yenidən qoşulmağa cəhd edin.';

  @override
  String get errTunnel => 'Bu VPN rejimi əlçatan deyil. Başqa rejim seçin və ya xidmət icazələrini yoxlayın.';

  @override
  String get errNetwork => 'Serverə daxil olmaq mümkün deyil';

  @override
  String get errTimeout => 'Server vaxtında cavab vermədi. Bir dəqiqə sonra yenidən cəhd edin.';

  @override
  String get errFirewall =>
      'VPN xaricində internetə girişi bloklamaq mümkün olmadı. Səbəbi öyrənmək üçün bağlantı jurnalına baxın.';

  @override
  String get errSubFetch =>
      'Abunəliyi endirmək mümkün olmadı. İnternet bağlantınızı yoxlayıb bir dəqiqə sonra yenidən cəhd edin.';

  @override
  String get errSubFormat => 'Abunəliyin formatı tanınmadı. Provayderinizdən uyğun abunəlik keçidi istəyin.';

  @override
  String get errSubEmpty => 'Abunəlikdə server yoxdur. Abunəlik provayderinizə müraciət edin.';

  @override
  String get errSubDuplicate => 'Bu abunəlik artıq əlavə edilib. Aktual serverləri almaq üçün onu yeniləyin.';

  @override
  String get errSubLimit =>
      'Abunəlik sayının həddinə çatılıb. Yenisini əlavə etməzdən əvvəl istifadə etmədiyiniz abunəliyi silin.';

  @override
  String get errSubScheme => 'Abunəlik keçidi https:// ilə başlamalıdır. Provayderinizdən təhlükəsiz keçid istəyin.';

  @override
  String get errSecretStore =>
      'Sora yaddaşı zədələnib və ya əlçatan deyil. Giriş icazələrini və jurnaldakı təfərrüatları yoxlayın.';

  @override
  String get errNoServers => 'Qoşulmaq üçün server yoxdur. Abunəlik və ya öz serverinizi əlavə edin.';

  @override
  String get connections => 'Əlaqələr';

  @override
  String get close => 'Bağlayın';

  @override
  String get chainDirect => 'Birbaşa';

  @override
  String get chainBlocked => 'Blok edilib';

  @override
  String get theme => 'Mövzu';

  @override
  String get themeSystem => 'Sistem kimi';

  @override
  String get themeLight => 'İşıq';

  @override
  String get themeDark => 'Qaranlıq';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem kimi';

  @override
  String get sectionConnection => 'Əlaqə';

  @override
  String get sectionNoServer => 'Server yoxdur';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diaqnostika';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Avtomatik';

  @override
  String get dnsHint => 'Ünvanlar, vergüllə ayrılmış';

  @override
  String get fragment => 'TLS parçalanması';

  @override
  String get fragmentPackets => 'Nə bölmək';

  @override
  String get fragmentLength => 'Parça ölçüsü';

  @override
  String get fragmentInterval => 'Parçalar arasında fasilə';

  @override
  String get byDefault => 'Defolt';

  @override
  String get rangeHint => 'Məsələn, 100-200';

  @override
  String get splitPos => 'Bölünmüş mövqelər';

  @override
  String get splitPosHint => 'Məsələn, 1, midsld';

  @override
  String get disorder => 'Parçaları yenidən sıralayın';

  @override
  String get tlsRecord => 'TLS qeydini bölün';

  @override
  String get tlsRecordNo => 'yox';

  @override
  String get tlsRecordSni => 'Saytın adında';

  @override
  String get tlsRecordFirst => 'Birinci baytdan sonra';

  @override
  String get hostCase => 'Host işini dəyişdirin';

  @override
  String get probeMethod => 'Metod';

  @override
  String get probeAuto => 'Avtomatik';

  @override
  String get probeEngine => 'Mühərrik vasitəsilə';

  @override
  String get probeConnect => 'Yalnız əlaqə';

  @override
  String get probeUrl => 'Test ünvanı';

  @override
  String get probeTimeout => 'gözləyin';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Abunəliklər';

  @override
  String get subscriptionSettings => 'Parametrlər';

  @override
  String get userAgent => 'İstifadəçi-Agent';

  @override
  String get autoUpdate => 'Avtomatik olaraq yeniləyin';

  @override
  String get updateInterval => 'Nə qədər tez-tez';

  @override
  String get intervalProvider => 'Provayderin soruşduğu kimi';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'İndi yeniləyin';

  @override
  String get logLevel => 'Nə qeyd etmək';

  @override
  String get levelDebug => 'Hər şey';

  @override
  String get levelInfo => 'Adi';

  @override
  String get levelWarning => 'Əhəmiyyətli';

  @override
  String get levelError => 'Yalnız səhvlər';

  @override
  String get recordDestinations => 'Sayt ünvanlarını qeyd edin';

  @override
  String get reset => 'Parametrləri sıfırlayın';

  @override
  String get resetConfirm => 'Bütün parametrlər sıfırlansın?';

  @override
  String get resetAction => 'Sıfırlayın';

  @override
  String get invalidValue => 'Bu dəyər işləməyəcək';

  @override
  String get website => 'Abunə səhifəsi';

  @override
  String get providerWebsite => 'Provayder veb saytı';

  @override
  String get support => 'Dəstək';

  @override
  String controlPortQuestion(String engine) {
    return '$engine bu kompüterdəki port vasitəsilə idarə olunur. Digər proqramlar VPN-in aktiv olduğunu söyləyə biləcək.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine seçin';
  }

  @override
  String get rules => 'Fərdi qaydalar';

  @override
  String get ruleAdd => 'Yeni qayda';

  @override
  String get ruleHint => 'Sayt, IP və ya proqram';

  @override
  String get ruleDirect => 'Birbaşa';

  @override
  String get ruleProxy => 'VPN vasitəsilə';

  @override
  String get ruleBlock => 'Blok';

  @override
  String get failover => 'Uğursuzluğu yandırın';

  @override
  String get connectOnStart => 'Başlanğıcda qoşulun';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'abunə $days günlərində başa çatır',
      one: 'abunə $days günündə başa çatır',
      zero: 'abunə bir neçə saat ərzində başa çatır',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left sol';
  }

  @override
  String get ruleInvalid => 'Bu sayta, IP-yə və ya proqrama bənzəmir';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serverləri, ən sürətli',
      one: '$count server, ən sürətli',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Rejim';

  @override
  String get tunnelProxy => 'System proxy';

  @override
  String get proxyAddress => 'Proksi ünvanı';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get launchAtLogin => 'Sistemdən başlayın';

  @override
  String get launchAtLoginDetail => 'Daxil olduqda Sora avtomatik işə düşəcək və nimçədə qalacaq.';

  @override
  String get closeToTray => 'Bağlı halda nimçədə saxlayın';

  @override
  String get notifications => 'Bildirişlər';

  @override
  String get trayOpen => 'Sora-ni açın';

  @override
  String get trayConnect => 'Qoşun';

  @override
  String get trayDisconnect => 'Bağlantını kəsin';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Sora-dən çıxın';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora hələ də qabdadır';

  @override
  String get noticeInTrayBody => 'Onun simvolunun menyusundan çıxın';

  @override
  String get noticeLost => 'Bağlantı itdi';

  @override
  String get noticeLostBody => 'Sora yenidən qoşulur';

  @override
  String get noticeRestored => 'Yenidən qoşuldu';

  @override
  String get noticeFailed => 'Qoşulmaq mümkün olmadı';

  @override
  String get noticeBackup => 'Əsas server cavab vermədi; ehtiyat trafiki daşıyır';

  @override
  String get noticeNext => 'Server cavab vermədi; növbətisi trafiki daşıyır';

  @override
  String get noticeMainBack => 'Əsas server yenidən cavab verir və trafiki daşıyır';

  @override
  String get noticeSubscription => 'Abunəlik';

  @override
  String get importTitle => 'Bu abunə əlavə edilsin?';

  @override
  String get importSealed =>
      'Bu keçid Happ üçün şifrələnib və yalnız Happ onu oxuya bilər. Provayderinizdən sadə abunə linkini soruşun.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'cavab yoxdur';

  @override
  String get home => 'Ev';

  @override
  String get navRules => 'Qaydalar';

  @override
  String get navConnections => 'Əlaqələr';

  @override
  String get navLogs => 'Qeydlər';

  @override
  String get navAbout => 'Haqqında';

  @override
  String get sidebarToggle => 'Yan panelə keçin';

  @override
  String get more => 'Daha çox';

  @override
  String get less => 'Daha az';

  @override
  String get notificationsEmpty => 'Bildiriş yoxdur';

  @override
  String get retryConnect => 'Bağlantıya yenidən cəhd edin';

  @override
  String get openLogs => 'Qeydləri açın';

  @override
  String get tourReplay => 'Bələdçini yenidən göstərin';

  @override
  String tourStep(int step) {
    return '5 addımdan $step';
  }

  @override
  String get tourBack => 'Geri';

  @override
  String get tourNext => 'Sonrakı';

  @override
  String get tourSkip => 'Keç';

  @override
  String get tourFinish => 'Bitdi';

  @override
  String get tourAdd => 'Provayderinizin abunə linkini əlavə edin.';

  @override
  String get tourServer => 'Bir server seçin. “Ən sürətli” sizin üçün birini seçir.';

  @override
  String get tourConnect => 'Qoşulmaq və ya əlaqəni kəsmək üçün bura klikləyin.';

  @override
  String get tourMode => 'Bir rejim seçin. VPN düşərsə, keçid bloklarını öldürün.';

  @override
  String get tourSettings => 'Parametrləri açın. Bu təlimatı orada təkrarlaya bilərsiniz.';

  @override
  String get chooseProgram => 'Proqram seçin';

  @override
  String get installedApps => 'Quraşdırılmış proqramlar';

  @override
  String get runningProcesses => 'Çalışan proseslər';

  @override
  String get programsEmpty => 'Heç bir tətbiq tapılmadı. Başqa bir ad sınayın.';

  @override
  String get selectExe => '.exe faylı seçin';

  @override
  String get speedtest => 'Sürət';

  @override
  String get speedtestSearch => 'Xidmət tapın';

  @override
  String get speedtestEmpty => 'Uyğunluq yoxdur. Axtarışı dəyişdirin.';

  @override
  String get speedtestBackToList => 'Xidmətlərə qayıt';

  @override
  String get speedtestOpenBrowser => 'Brauzerdə açın';

  @override
  String get speedtestUnavailable => 'Quraşdırılmış brauzer başlaya bilmədi. Xidməti sistem brauzerinizdə açın.';

  @override
  String get speedtestPageFailed =>
      'Səhifəni yükləmək mümkün olmadı. Onu yenidən yükləyin və ya xidməti sistem brauzerinizdə açın.';

  @override
  String get speedtestExternalFailed => 'Sistem brauzeri aça bilmədi. Yenidən cəhd edin.';

  @override
  String get modes => 'Rejimlər';

  @override
  String get proxyShort => 'Proksi';

  @override
  String get tunMode => 'Bütün trafik (TUN)';

  @override
  String get checkUpdates => 'Yeniləmələri yoxlayın';

  @override
  String get updates => 'Proqram yeniləmələri';

  @override
  String updateAvailable(String version) {
    return '$version versiyası mövcuddur';
  }

  @override
  String get updateOpenAbout => 'Yeniləmə baxın';

  @override
  String updateNotes(String version) {
    return '$version-də dəyişikliklər';
  }

  @override
  String get updateCheck => 'Yeniləmələri yoxlayın';

  @override
  String get updateChecking => 'Yoxlanır...';

  @override
  String get updateNoNotes => 'Buraxılışda qeydlər yoxdur.';

  @override
  String get updateDropWarning =>
      'Sora və onun əsas yeniləməsi zamanı VPN bağlantısı bir neçə saniyə kəsiləcək. Davam edilsin?';

  @override
  String get updateWaitConnection => 'VPN bağlantısı və nüvənin hazır olmasını gözləyin.';

  @override
  String get updateDownloading => 'Fayllar endirilir və təsdiqlənir...';

  @override
  String get updateInstalling => 'Güncəlləmə hazırlanır və ya administrator autentifikasiyası gözlənilir...';

  @override
  String get updateNetworkError => 'Güncəlləməni endirmək mümkün olmadı. Yenidən cəhd edin.';

  @override
  String get updateReleaseError => 'Buraxılış məlumatları və ya tələb olunan fayllar yoxdur və ya etibarsızdır.';

  @override
  String get updateChecksumError => 'Endirmə SHA256SUMS ilə uyğun gəlmir. Heç nə quraşdırılmayıb.';

  @override
  String get updateInstallError => 'Yeniləmə tamamlanmadı. Doğrulama ləğv edilmiş ola bilər.';

  @override
  String get updateUnsupported =>
      'Bu icra olunan fayl dəstəklənən Sora paket cütlüyünə məxsus deyil. Buraxılış quraşdırma təlimatlarından istifadə edin.';

  @override
  String get updateManual =>
      'Hər iki təsdiqlənmiş paketi quraşdırmaq üçün bu əmri terminalda işə salın, sonra Sora-i yenidən açın. Fayllar yükləmə qovluğunda qalır. VPN bağlantısı kəsiləcək.';

  @override
  String get updateSignaturePending => 'Yeniləmə faylları buraxılışla dərc olunan yoxlama cəmləri ilə tutuşdurulur.';

  @override
  String get updateManualSigWarning =>
      'Aşağıdakı fayllar buraxılışın yoxlama cəmlərinə uyğundur. Onları rəsmi buraxılışdan yükləmisinizsə, əmri icra edin.';

  @override
  String get updateVersionRevoked =>
      'Tərtibatçı bu versiyanı geri götürdü. Lütfən, düzəliş edilmiş buraxılışı gözləyin.';

  @override
  String get updateRolloutPending => 'Daha yeni versiya tədricən yayılır və avtomatik olaraq sizə təklif olunacaq.';

  @override
  String updateRollbacking(String version) {
    return '$version versiyasına qayıdır...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version yeniləməsi işləkliyin yoxlanışından keçmədi, buna görə Sora $fromVersion versiyasına qaytarıldı.';
  }

  @override
  String get updateRollbackError =>
      'Avtomatik geri qaytarma uğursuz oldu. Yeni versiya işləmirsə, əvvəlki buraxılışı əl ilə yenidən quraşdırın.';

  @override
  String get updateRollbackCacheError =>
      'Cari versiyanın təsdiqlənmiş geriyə qaytarma nüsxəsini hazırlamaq mümkün olmadı, ona görə də yeniləmə quraşdırılmadı.';

  @override
  String get updateCopyCommand => 'Kopyalama əmri';

  @override
  String get updateChecksDisabled => 'Avtomatik yoxlamalar Parametrlərdə deaktiv edilib.';

  @override
  String get updateInstalled => 'Yeniləmə quraşdırılıb. Sora-ni yenidən açın.';

  @override
  String get projectLinks => 'Layihə';

  @override
  String get githubReleases => 'Buraxılışlar və yükləmələr';

  @override
  String get telegramChannel => 'Telegram kanalı';

  @override
  String get licenses => 'Lisenziyalar';

  @override
  String get componentLicenses => 'Komponent lisenziyaları';

  @override
  String get collapseServers => 'Serverləri yığışdırın';

  @override
  String get expandServers => 'Serverləri genişləndirin';

  @override
  String get hideDescription => 'Təsviri gizlədin';

  @override
  String get showDescription => 'Təsviri göstərin';

  @override
  String get errEngineUnsupported =>
      'Seçilmiş mühərrik bu profili və ya parametrləri dəstəkləmir. Avtomatik və ya uyğun mühərriki seçin.';

  @override
  String get errRestore =>
      'Bağlantının təmizlənməsi tamamlanmadı. Bağlantını kəsməyə yenidən cəhd edin; təfərrüatlar üçün jurnala baxın.';

  @override
  String get errSessionEnded => 'Bu sessiya artıq başa çatıb. Bağlantı vəziyyətini yeniləyin.';

  @override
  String get retryDisconnect => 'Bağlantını kəsməyə yenidən cəhd edin';

  @override
  String get tunStack => 'TUN yığını';

  @override
  String get modesInfo => 'Rejimlər haqqında';

  @override
  String get modesGuideTitle => 'Rejimlər və mühərriklər';

  @override
  String get modesGuide =>
      'Serverinizin hansı mühərrikə ehtiyacı olduğuna əmin deyilsinizsə, Avtomatik seçin. Sora qoşulmazdan əvvəl profili və parametrləri yoxlayır. Mühərrik planınızın bant genişliyini artıra bilməz: performans serverdən, marşrutdan, protokoldan və şəbəkədən asılıdır.\n\n## Rejimlər\n\n### Bütün trafik (TUN)\n\nSora virtual şəbəkə interfeysi yaradır və TCP və UDP daxil olmaqla proqram trafikini onun vasitəsilə yönləndirir. Telegram, oyunlar və Discord səsi üçün bu rejimi istifadə edin. Qaydalar xüsusi saytları və ya proqramları birbaşa göndərə və ya onları bloklaya bilər. Şəbəkə xidmətinə icazə və tələb olunan protokolu dəstəkləyən server lazımdır.\n\n### System proksi\n\nSora yerli HTTP/SOCKS proksisini konfiqurasiya edir. Sistem proxy parametrlərinə hörmət edən proqramlar ondan istifadə edir. Öz şəbəkə yığını olan proqramlar birbaşa qoşula bilər; UDP və səsli zənglər üçün ümumiyyətlə TUN lazımdır. Bu rejim proxy dəstəyi olan brauzerlər və proqramlar üçün uyğundur.\n\n### Server yoxdur\n\nLinux-də Sora HTTP/TLS sorğularını bölmək və yenidən formalaşdırmaq və bəzi DPI yoxlamalarını keçmək üçün [zapret](https://github.com/bol-van/zapret) istifadə edir. IP-niz eyni qalır və bağlantılar birbaşa vebsayta keçir. Nəticələr provayderinizdən və bloklama metodunuzdan asılıdır.\n\nCari inteqrasiya TCP üzərindən HTTP və TLS üçün tpws istifadə edir. O, IP-nin bloklanmasını və ya UDP-nin ötürülməsini keçmir və Telegram-nin MTProto bağlantılarına zəmanət verə bilməz. Discord səs, Telegram zəngləri və bu cür məhdudiyyətlər üçün TUN ilə VPN serverindən istifadə edin.\n\n## Mühərriklər\n\n### Avtomatik\n\nSora bütün qoşulma planını dəstəkləyən quraşdırılmış mühərriki seçir: server protokolları, daşımalar, qruplar, parçalanma və rejim. Uyğun olmayan əl seçimi cari əlaqəni dayandırmazdan əvvəl rədd edilir. Avtomatik və ya başqa mühərriki seçin və parametrləri yenidən tətbiq edin.\n\n### sing-box\n\nYeni Sora paketlərinə müştəri tərəfi XHTTP və VLESS Encryption əlavə edən [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) çəngəl daxildir. Sora quruluşu və onun imkanlarını tanıyır. XHTTP olmadan yuxarı axın quruluşu bu qabiliyyəti təkcə adından əldə etmir.\n\nDəstəklənən protokollara VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard və ZX0/parametrləri daxildir. Sora idxal edə bilər. Tam Xray JSON profilləri üçün Xray tələb olunur. Yeni AWG 3.x sahələri hələ idxal edilə bilməz. sing-box, kompüterdəki digər proqramların aşkarlaya biləcəyi parolla qorunan yerli idarəetmə portundan istifadə edir.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption və TLS fraqmentasiyasını dəstəkləyir. O, həmçinin marşrutlaşdırma və qruplarını qoruyarkən Xray tam provayder profillərini idarə edir. Bu cür profillər davranışlarını dəyişdirmədən avtomatik olaraq başqa bir mühərrikə çevrilə bilməz.\n\nBirləşdirilmiş Xray TLS sertifikatının doğrulamasını deaktiv edən ayarı sildi (`allowInsecure`). Bu parametri tələb edən adi serverlər üçün avtomatik sing-box və ya mihomo seçir. Xray seçimi cari əlaqəni dayandırmazdan əvvəl uyğunsuzluğu əl ilə bildirir. Köhnə tam JSON profilləri təsdiq edilə bilən sertifikat və ya sertifikat pininə malik yenilənmiş provayder profilinə ehtiyac duyur.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) sifarişli ehtiyat və yük balanslaşdırma qruplarını, XHTTP və AmneziaWG-ni dəstəkləyir. Yedək serverə avtomatik keçid vacib olduqda onu seçin. Sora-nin TLS parçalanma parametri bu mühərriklə əlçatan deyil.\n\n## Sora-də uyğunluq\n\n| Xüsusiyyət | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN və TCP/UDP | Bəli | Bəli | Bəli |\n| XHTTP | Bəli | Bəli | Bəli |\n| VLESS Encryption | Bəli | Bəli | Bəli |\n| Tam Xray profili | Yox | Bəli | Yox |\n| TUIC / AnyTLS | Hər ikisi | Yox | TUIC |\n| mieru | Yox | Yox | Bəli |\n| NaiveProxy | Bəli | Yox | Yox |\n| TLS parçalanması | Bəli | Bəli | Yox |\n| AmneziaWG 1.x/2.x | Bəli¹ | Yox | Bəli |\n| Sifarişli ehtiyat qrupu | Yox | No² | Bəli |\n\n¹ J1/J2/J3/Itime ilə profillər mihomo istifadə edir; bu sahələr heç vaxt səssizcə atılmamalıdır. ² Tam Xray profilləri qrupu üçün proqram ehtiyat profili seçir. Dəstək quraşdırılmış quruluşdan asılıdır; Haqqında onun versiyasını yoxlayın.\n\n## TUN yığını\n\nYığın virtual interfeys daxilində TCP və UDP-ni idarə edir. Rejimlər panelində Xray və mihomo gVisor, System, Mixed və MIPS təklif edir. Hər bir mühərrik öz üstünlüklərini saxlayır. System proxy və Serversiz rejimlər bu üstünlükdən istifadə etmir.\n\n- **Mixed**: TCP sistem yığınından istifadə edir, gVisor isə UDP-ni idarə edir. Bu, Linux-da mihomo üçün standartdır. Windows-da Xray və mihomo standart olaraq MIPS istifadə edir.\n- **System**: sistem yığınından istifadə edir. Şəbəkə proqramlarında problem yaranarsa, başqa variantı sınayın.\n- **gVisor**: istifadəçi məkanında trafiki idarə edir.\n- **MIPS**: mihomo-nin 1.19.32 paket versiyasında mövcud olan öz IP yığını.\n\nLinux-də Xray standart olaraq daxili gVisor-dən istifadə edir. Linux-də System, Mixed və MIPS TUN mühərriki kimi mihomo-dən istifadə edir, TCP və UDP-ni təsdiqlənmiş yerli SOCKS linki üzərindən Xray-ə yönləndirir. Xray protokolu, provayder profilini və marşrutu saxlayır. Bu üç seçim quraşdırılmış mihomo tələb edir. Windows-də Xray dörd TUN stekinin hamısı üçün mihomo 1.19.32 və ya daha yeni versiyadan istifadə edir. Protokollar və marşrutlaşdırma Xray-də qalır. Bu bağlantıda tətbiq qaydaları yalnız birbaşa əlaqəni və bloklamanı dəstəkləyir; Linux-də bu qaydalar Xray-in daxili gVisor stekini tələb edir.\n\nKörpü ikinci prosesi həyata keçirir. Linux-də üç boş ölçmədə o, yerli Xray TUN-dan təxminən 32-36 MiB daha çox fiziki yaddaş istifadə etdi. Bu, yükləmə yükünü ölçmür: CPU və yaddaş xərcləri bağlantılardan asılıdır. sing-box-də yığın seçicisi yoxdur. Heç bir yığın hər şəbəkədə daha yaxşı performansa zəmanət vermir. Yığın seçin və onu şəbəkənizdə sınamaq üçün Tətbiq edin və yenidən qoşulun seçin.\n\n## Parametrlər tətbiq edilir\n\nServerin seçilməsi avtomatik olaraq yenidən qoşulur. Rejim, mühərrik, DNS və qayda parametrləri dərhal saxlanılır; aktiv əlaqə zamanı Tətbiq et üzərinə klikləyin və onlardan istifadə etmək üçün yenidən qoşulun. Mühərrikin yenidən işə salınması endirmələri və zəngləri dayandıra bilər. Təkrarlanan kliklər paralel əlaqələri başlatmır; əlaqənin kəsilməsi keçidi bitirir və əlaqəni buraxır.\n\nTunel düşdükdə yalnız VPN vasitəsilə İnternet birbaşa trafiki bloklayır. Bütün maşına təsir edir. Açıq-aşkar əlaqənin kəsilməsi Sora qaydalarını aradan qaldırır. Təmizləmə başa çatmazsa, yenidən ayırmağa cəhd edin və jurnalı açın.\n\n## Layihə sənədləri\n\n- [sing-box-lx: konfiqurasiya və dəstək](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box sənədləri](https://sing-box.sagernet.org/)\n- [Xray sənədləri](https://xtls.github.io/)\n- [mihomo sənədləri](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: əməliyyat və məhdudiyyətlər](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP trafikini Jitsi, Yandex Telemost və ya WB Stream videozəngi vasitəsilə ötürür. olcrtc:// keçidini və ya QR kodunu idxal edin. Proksi və TUN rejimlərində sing-box, Xray və mihomo ilə işləyir; UDP dəstəklənmir. Hər iki tərəfə uyğun OLC2 quruluşları lazımdır. İlkin layihə arxivləşdirilib.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Genişləndiricilər';

  @override
  String extRatingLabel(String rating) {
    return 'Qiymətləndirmə $rating/5';
  }

  @override
  String extByAuthor(String author) {
    return '$author tərəfindən';
  }

  @override
  String extInstallsCount(String count) {
    return 'Quraşdırmalar: $count';
  }

  @override
  String get extInstallOne => '1 quraşdırma';

  @override
  String get extSideloadWarning => 'Yalnız müəllifin özünün imzaladığı açara etibar edirsinizsə quraşdırın.';

  @override
  String get extPermissionsWidened => 'Yeniləmə yeni icazələr tələb edir:';

  @override
  String get extDangerousAck => 'Mən başa düşürəm ki, bu icazələr ciddidir';

  @override
  String get extInstall => 'Quraşdırın';

  @override
  String get extUpdate => 'Yenilə';

  @override
  String get extCancel => 'Ləğv et';

  @override
  String get extConfirm => 'Təsdiq edin';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Kataloq';

  @override
  String get extInstalled => 'Quraşdırılmış genişləndiricilər';

  @override
  String get extSearchHint => 'Genişləndiriciləri axtar';

  @override
  String get extCatAll => 'Hamısı';

  @override
  String get extCatTools => 'Alətlər';

  @override
  String get extCatThemes => 'Mövzular';

  @override
  String get extCatAutomation => 'Avtomatlaşdırma';

  @override
  String get extCatStats => 'Statistika';

  @override
  String get extCatNetwork => 'Şəbəkə';

  @override
  String get extSortBy => 'Sırala';

  @override
  String get extSortPopular => 'Ən məşhur';

  @override
  String get extSortRating => 'Ən yüksək reytinq';

  @override
  String get extSortName => 'Adı';

  @override
  String get extCatalogError => 'Kataloqu yükləmək mümkün olmadı';

  @override
  String get extRetry => 'Yenidən cəhd edin';

  @override
  String get extEmptySearch => 'Heç nə tapılmadı';

  @override
  String get extEmptyInstalled => 'Hələlik əlavələr quraşdırılmayıb.\nKataloqda birini tapın və ya fayldan quraşdırın.';

  @override
  String get extInstallFromFile => 'Fayldan quraşdırın';

  @override
  String get extInstallFromUrl => 'URL-dan quraşdırın';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Yüklə';

  @override
  String get extDownloading => 'Endirilir...';

  @override
  String get extVerifying => 'Doğrulanır...';

  @override
  String get extInstalling => 'Quraşdırılır...';

  @override
  String get extInstallFailed => 'Quraşdırma uğursuz oldu';

  @override
  String get extErrSignature => 'İmza yoxlaması uğursuz oldu. Fayl zədələnmiş və ya dəyişdirilmiş ola bilər.';

  @override
  String get extErrManifest => 'Genişləndirici manifesti etibarsızdır.';

  @override
  String get extErrNetwork => 'Şəbəkə xətası. Bağlantınızı yoxlayın və yenidən cəhd edin.';

  @override
  String get extErrHash => 'Yükləmə kataloqa uyğun gəlmir. Ola bilsin ki, ona müdaxilə edilib.';

  @override
  String extErrMinApp(String version) {
    return 'Bu genişləndirici üçün tətbiqin $version və ya daha yeni versiyası lazımdır.';
  }

  @override
  String get extErrHttpsOnly => 'Yalnız https:// keçidlərə icazə verilir';

  @override
  String get extErrGeneric => 'Nəsə xəta baş verdi. Yenidən cəhd edin.';

  @override
  String get extErrAuthorKeyChanged =>
      'Bu yeniləmə quraşdırılmış versiyadan fərqli müəllif açarı ilə imzalanıb, ona görə də bloklanıb. Yeni açara güvənirsinizsə, genişləndiricini silin və açıq şəkildə yenidən quraşdırın.';

  @override
  String get extDisabled => 'Söndürülüb';

  @override
  String extToggleEnabled(String name) {
    return '$name aktivləşdirin';
  }

  @override
  String get extSearchInstalled => 'Quraşdırılmış genişləndiricilərdə axtar';

  @override
  String get extUpdateAll => 'Hamısını yeniləyin';

  @override
  String extUpdatesAvailable(int count) {
    return '$count yeniləmələr mövcuddur';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count yeniləndi';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Həssas';

  @override
  String get extRiskDangerous => 'Yüksək risk';

  @override
  String get extPermissionsRemoved => 'Artıq tələb olunmur:';

  @override
  String get extUpdateFailedKept => 'Əvvəlki versiya hələ də quraşdırılıb.';

  @override
  String get extConflictsTitle => 'Genişləndirici münaqişələri';

  @override
  String get extConflictTheme => 'Tətbiq mövzusu';

  @override
  String get extConflictNetHooks => 'Şəbəkə qarmaqları';

  @override
  String extConflictWinner(String name) {
    return 'Üstünlük: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count münaqişələr sizin qərarınıza ehtiyac duyur';
  }

  @override
  String get extConflictsResolve => 'Münaqişələri həll edin';

  @override
  String extVersionLabel(String version) {
    return 'Versiya $version';
  }

  @override
  String get extPermissionsTitle => 'İcazələr';

  @override
  String get extNoPermissions => 'Xüsusi icazələr yoxdur.';

  @override
  String get extSettings => 'Parametrlər';

  @override
  String get extSaveSettings => 'Parametrləri yadda saxlayın';

  @override
  String extUpdateTo(String version) {
    return '$version versiyasına yenilə';
  }

  @override
  String get extEnabled => 'Aktivdir';

  @override
  String extRollbackTo(String version) {
    return '$version versiyasına qaytar';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version versiyasına geri qaytarılsın?';
  }

  @override
  String get extUninstall => 'Silin';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” və onun parametrləri silinsin?';
  }

  @override
  String get extPanelUnavailable => 'Genişlənmə paneli əlçatan deyil.';

  @override
  String get extPermConnectionsRead => 'Aktiv qoşulmaların siyahısına baxın';

  @override
  String get extPermServersRead => 'Serverlərinizin siyahısına baxın';

  @override
  String get extPermSettingsRead => 'Proqram parametrlərini oxuyun';

  @override
  String get extPermSettingsWrite => 'Proqram parametrlərini dəyişdirin';

  @override
  String get extPermNotifications => 'Bildirişləri göstərin';

  @override
  String get extPermTray => 'Tepsi menyusuna elementlər əlavə edin';

  @override
  String get extPermUiPanel => 'Proqram daxilində panelləri göstərin';

  @override
  String get extPermThemeApply => 'Mövzuları tətbiq edin';

  @override
  String get extPermRoutingRules => 'Marşrutlaşdırma qaydaları əlavə edin (şəbəkə trafikinin getdiyi yerə təsir edir)';

  @override
  String get extPermNetHooks => 'Şəbəkə yoluna inteqrasiya edin (DPI bypass modulları)';

  @override
  String get extPermNetFetch => 'İcazə verilən siyahıdan URL tələb edin';

  @override
  String get extPermBackground => 'Fon tapşırıqlarını yerinə yetirin';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Arxa fonda çalışır';

  @override
  String get extCapNetHook => 'Bloklamadan yan keçid və şəbəkə müdaxilələri';

  @override
  String get extCapPanel => 'İnterfeys panelləri';

  @override
  String get extCapRouting => 'Marşrutlaşdırma qaydaları';

  @override
  String get extCapTheme => 'Mövzular';

  @override
  String get extCapWidget => 'Vidjetlər';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Dəyişikliklər jurnalı';

  @override
  String get extImageFailed => 'Şəkli yükləmək mümkün olmadı';

  @override
  String get extScreenshots => 'Ekran görüntüləri';

  @override
  String get extSortRelevance => 'Uyğunluq';

  @override
  String get extPermNetworkDetail => 'VPN sorğularına yalnız aşağıdakı hostlar üçün icazə verilir.';

  @override
  String get extBgTitle => 'Fon tapşırığı';

  @override
  String get extBgEnabled => 'Arxa fonda işləyin';

  @override
  String get extBgInterval => 'İcra intervalı';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dəqiqə', one: '$count dəqiqə');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count saat', one: '$count saat');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Fon tapşırığını idarə etmək üçün genişləndiricini aktivləşdirin.';

  @override
  String get extCapNetwork => 'Şəbəkəyə giriş';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Şəbəkə: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Fayla $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diaqnostikası';

  @override
  String get diagnosticNoData => 'Hələ qeydə alınmış sorğu yoxdur. Əvvəlcə sürət testi veb saytını açın.';

  @override
  String get qrShareTitle => 'QR kodunu paylaşın';

  @override
  String get qrScanTitle => 'QR kodunu skan edin';

  @override
  String get qrCopyLink => 'Linki kopyalayın';

  @override
  String get qrWarning => 'Kodu yalnız etibar etdiyiniz şəxslərlə paylaşın.';

  @override
  String get qrScanHint => 'QR kodlu ekran görüntüsü və ya foto seçin, ya da keçid yapışdırın';

  @override
  String get qrFromClipboard => 'Buferdən yapışdırın';

  @override
  String get qrNoCode => 'Bu şəkildə QR kod tapılmadı.';

  @override
  String get qrInvalid => 'Bu QR kodunda etibarlı keçid yoxdur.';

  @override
  String get qrScan => 'Skan QR';

  @override
  String get qrFromImage => 'Şəkli aç';

  @override
  String get connGroupByProcess => 'Prosesə görə qruplaşdırın';

  @override
  String get connListView => 'Siyahı';

  @override
  String get connCopyHost => 'Hostu kopyalayın';

  @override
  String get connAddRule => 'Qayda əlavə edin';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count bağlantı', one: '$count bağlantı');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Əvvəlcədən';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Fərdi';

  @override
  String get dnsCheck => 'Məlumat sızmalarını yoxlayın';

  @override
  String get dnsChecking => 'Yoxlanır...';

  @override
  String get dnsNoLeak => 'Heç bir sızma tapılmadı';

  @override
  String get dnsLeakFound => 'Sızma aşkar edildi';

  @override
  String get dnsLastCheck => 'Son yoxlama';

  @override
  String get dnsNeverChecked => 'Hələ sınaqdan keçirilməyib';

  @override
  String get dnsLeakCheckTunnelDns => 'Tunelin DNS həllediciləri';

  @override
  String get dnsLeakCheckSystemResolvers => 'Sistemin ad həllediciləri';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Şəbəkə kilidinin DNS qoruması';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Yuxarıdakı DNS parametrlərində tunel üçün DNS konfiqurasiya edin.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Sisteminizin tuneldən kənarda hansı həlledicilərdən istifadə edəcəyini yoxlayın.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS trafikinin tuneldə qalması üçün şəbəkə kilidini aktivləşdirin.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Əməliyyat sisteminin şifrələnmiş DNS-i';

  @override
  String get dnsLeakCheckDnsSpoof => 'Saxta DNS cavablar';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Sisteminizin tuneldən kənarda hansı şifrələnmiş DNS son nöqtələrindən istifadə etdiyini yoxlayın.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Tunel üçün şifrələnmiş DNS (DoT və ya DoH) istifadə edin ki, həlledicilər cavabları saxtalaşdırmasın.';

  @override
  String get dnsCheckNeedsConnection => 'Əvvəlcə VPN-ə qoşulun, sonra sızma olub olmadığını yoxlayın.';

  @override
  String get dnsExpected => 'Gözlənilir';

  @override
  String get dnsActual => 'Müşahidə edilmişdir';

  @override
  String get measureSpeed => 'Sürəti ölçün';

  @override
  String get benchmarkStale => 'köhnəlmişdir';

  @override
  String get autoSelectMode => 'Avtomatik server seçin';

  @override
  String get autoSelectPing => 'Ən sürətli ping';

  @override
  String get autoSelectSpeed => 'Ən sürətli sürət';

  @override
  String get autoSelectSmart => 'Ağıllı seçim';

  @override
  String get coreWatchUnstable => 'Nüvə ilə əlaqə qeyri-sabitdir. Bir az gözləyib yenidən qoşulmağa cəhd edin.';

  @override
  String get watchReconnect => 'Yenidən qoşun';

  @override
  String get crashRestoreTitle => 'Son seans yarımçıq kəsildi';

  @override
  String get restoreOnCrash => 'Qəzadan sonra sessiyanı bərpa edin';

  @override
  String get crashRestore => 'Bərpa edin';

  @override
  String get crashDismiss => 'İndi yox';

  @override
  String get overrideTitle => 'Düzəlişlərim';

  @override
  String get overrideEdit => 'Serverləri redaktə edin';

  @override
  String get overrideHide => 'Gizlət';

  @override
  String get overrideUnhide => 'Göstər';

  @override
  String get overrideClear => 'Redaktələri sıfırlayın';

  @override
  String get overrideEmpty => 'Hələ redaktə yoxdur';

  @override
  String get overrideCustomRules => 'Öz qaydaları';

  @override
  String get errBenchmarkUnsupported => 'Sürəti ölçmək üçün daha yeni nüvə lazımdır. Sora-nı yeniləyin.';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total-dən $done ölçülməsi…';
  }

  @override
  String get profiles => 'Şəbəkə profilləri';

  @override
  String get profilesEmpty =>
      'Hələ profil yoxdur. Məlum şəbəkələrdə parametrləri avtomatik tətbiq etmək üçün birini yaradın.';

  @override
  String get profileAdd => 'Profil əlavə edin';

  @override
  String get profileName => 'Profil adı';

  @override
  String get profileSsids => 'Wi-Fi şəbəkələri (SSID)';

  @override
  String get profileSsidsHint => 'Ev, Ofis vergüllə ayrılmışdır';

  @override
  String get profileGateways => 'Şəbəkə şlüzləri';

  @override
  String get profileAsns => 'AS nömrələri';

  @override
  String get profileAutoApply => 'Avtomatik tətbiq et';

  @override
  String get profileAutoApplyHint => 'Söndürülübsə, profil tətbiq edilməzdən əvvəl təsdiq istənilir.';

  @override
  String get profileSnapshot => 'Cari parametrləri yadda saxla';

  @override
  String get profileSnapshotDone => 'Cari parametrlər profildə saxlandı';

  @override
  String get profileDelete => 'Profili silin';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" profili silinsin?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '\"$name\" profili tətbiq edilsin?';
  }

  @override
  String get profileApply => 'Tətbiq et';

  @override
  String profileApplied(Object name) {
    return '“$name” profili tətbiq edildi';
  }

  @override
  String get profileUndo => 'Ləğv et';

  @override
  String get profileActive => 'Aktivdir';

  @override
  String networkNow(Object info) {
    return 'İndi: $info';
  }

  @override
  String get networkUnknown => 'Şəbəkə məlumatı mövcud deyil';

  @override
  String get profileNoTriggers => 'Ən azı bir tətik əlavə edin: SSID, şlüz və ya ASN';

  @override
  String get chains => 'Proksi zəncirləri';

  @override
  String get chainsEmpty => 'Hələ zəncir yoxdur. 2-3 serveri birləşdirin ki, trafik onların hər birindən keçsin.';

  @override
  String get chainAdd => 'Yeni zəncir';

  @override
  String get chainName => 'Zəncir adı';

  @override
  String get chainPickServers => '2-3 server seçin';

  @override
  String get chainOrderHint => 'Yenidən sıralamaq üçün sürükləyin: trafik yuxarıdan daxil olur və aşağıdan çıxır.';

  @override
  String get chainTooFew => 'Zəncir üçün ən azı iki server lazımdır. Daha bir server əlavə edin.';

  @override
  String get chainTooMany => 'Zəncirdə ən çox üç server ola bilər. Artıq serverləri çıxarın.';

  @override
  String get chainEstimate => 'Təxmini gecikmə';

  @override
  String get chainSave => 'Zənciri saxla';

  @override
  String get chainDelete => 'Zənciri silin';

  @override
  String chainDeleteConfirm(Object name) {
    return '\"$name\" zənciri silinsin?';
  }

  @override
  String get chainUnsupported => 'Seçilmiş mühərrik zəncirləri dəstəkləmir. Uyğun mühərrik seçin.';

  @override
  String get chainHopMissing =>
      'Zəncirdəki serverlərdən biri artıq əlçatan deyil. Həmin mərhələ üçün başqa server seçin.';

  @override
  String chainHop(Object n) {
    return 'Keçid $n';
  }

  @override
  String get chainEntry => 'Giriş';

  @override
  String get chainExit => 'Çıxış';

  @override
  String get sync => 'Cihaz sinxronizasiyası';

  @override
  String get syncDevices => 'Cihazlarım';

  @override
  String get syncEmpty => 'Qoşalaşdırılmış cihazlar yoxdur. Yerli şəbəkə üzərindən başqa cihazı cütləşdirin.';

  @override
  String get syncPair => 'Cihazı cütləşdirin';

  @override
  String get syncShowCode => 'Kodumu göstər';

  @override
  String get syncScanCode => 'Skan kodu';

  @override
  String get syncRevoke => 'Geri götürün';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" ləğv edilsin?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Son sinxronizasiya: $time';
  }

  @override
  String get syncNever => 'Heç vaxt';

  @override
  String get syncNoLan => 'Cihazlar eyni lokal şəbəkədə olmalıdır';

  @override
  String get syncPaired => 'Cihaz qoşalaşdırıldı';

  @override
  String get syncPairingTitle => 'Bu cihazla cütləşdirin';

  @override
  String get syncWaiting => 'Digər cihaz gözlənilir...';

  @override
  String get syncSecureNote => 'Uçdan uca şifrələnmiş kanal. Hesab yoxdur, bulud serverləri yoxdur.';

  @override
  String get zapretWithVpn => 'Birbaşa şəbəkə trafiki üçün DPI filtrindən keçin';

  @override
  String get zapretWithVpnHint =>
      'zapret VPN tuneli ilə yanaşı işləyir: tunel trafiki VPN-dən, birbaşa trafik isə bloklamadan yan keçid vasitəsindən keçir.';

  @override
  String get chainDuplicate => 'Zəncirdə eyni server təkrarlanır. Hər mərhələ üçün fərqli server seçin.';

  @override
  String get edit => 'Redaktə et';

  @override
  String get remove => 'Sil';

  @override
  String get autoSwitchOnDegrade => 'Deqradasiyaya avtomatik keçid';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Seçilmiş server xeyli yavaşlayarsa və ya cavab verməzsə, Sora ölçmələrə görə ən yaxşı serverə keçir, lakin 10 dəqiqədə bir dəfədən çox olmayaraq.';

  @override
  String get tunStackMixed => 'Qarışıq';

  @override
  String get tunStackSystem => 'Sistem';

  @override
  String get customServerAdd => 'Fərdi server əlavə edin';

  @override
  String get customServers => 'Mənim serverlərim';

  @override
  String get customServerName => 'Adı';

  @override
  String get customServerNameHint => 'Məsələn: mənim VPS';

  @override
  String get customServerNameRequired => 'Adı daxil edin';

  @override
  String get customServerAddress => 'Ünvan';

  @override
  String get customServerAddressHint => 'example.com və ya 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Server ünvanını daxil edin';

  @override
  String get customServerAddressInvalid => 'Yanlış ünvan';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port 1-dən 65535-ə qədər rəqəm olmalıdır';

  @override
  String get customServerProtocol => 'Protokol';

  @override
  String get customServerCredentials => 'Giriş məlumatı';

  @override
  String get customServerOptional => 'Könüllü';

  @override
  String get customServerShowSecret => 'Sirri göstərin';

  @override
  String get customServerHideSecret => 'Sirri gizlədin';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” server silinsin?';
  }

  @override
  String get customServerTest => 'Test';

  @override
  String get leakTestTitle => 'Məlumat sızması üçün test edin';

  @override
  String get leakTestIntro =>
      'Trafikin cihazdan tuneldən kənar çıxa bilib-bilmədiyini yoxlayır: birbaşa DNS və ICMP sorğuları, IPv6 çıxışı və sistem həllediciləri. Bağlantı aktiv olduqda başladın.';

  @override
  String get leakTestRun => 'Yoxlayın';

  @override
  String get leakTestCancel => 'Ləğv et';

  @override
  String get leakTestNeedsConnection => 'Məlumat sızmasını yoxlamaq üçün VPN-ə qoşulun.';

  @override
  String leakTestProgress(int count) {
    return 'Testlər tamamlandı: $count';
  }

  @override
  String get leakTestAllClear => 'Heç bir sızma tapılmadı';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sızma tapıldı',
      one: '$count sızma tapıldı',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Düzəlt';

  @override
  String get leakTestFixedNote => 'Şəbəkə kilidi aktivdir. Yoxlamaq üçün testi yenidən başladın.';

  @override
  String get leakTestCheckDirectDns => 'Birbaşa DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP əks-səda';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Sistemin ad həllediciləri';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tunel əlaqəsi';

  @override
  String get leakTestCheckTunnelDns => 'DNS tunel vasitəsilə';

  @override
  String get noticeDegraded => 'Server yavaşladı. Sora ölçmə zamanı tapılan ən yaxşı serverə keçdi.';

  @override
  String get obfs => 'Trafikin maskalanması';

  @override
  String get syncCodeExpired => 'Kodun müddəti bitib';

  @override
  String get syncDaemonFailed => 'Sinxronizasiya xidmətini başlatmaq mümkün olmadı';

  @override
  String get syncDaemonMissing =>
      'sora-sync komponenti tapılmadı. Cihaz sinxronizasiyasını aktivləşdirmək üçün proqramı yenidən quraşdırın.';

  @override
  String get syncDaemonStarting => 'Sinxronizasiya xidmətinə start verilir...';

  @override
  String get syncErrAuth =>
      'Sinxronizasiya xidməti giriş nişanını rədd etdi. Proqramı yenidən başladın və yenidən cəhd edin.';

  @override
  String get syncErrNotFound => 'Cihaz artıq qoşalaşdırılmayıb';

  @override
  String get syncErrPairingActive => 'Cütləşdirmə sessiyası artıq açıqdır';

  @override
  String get syncErrUnreachable =>
      'Digər cihaz cavab vermədi. Onun eyni şəbəkədə olduğuna və kodunu göstərdiyinə əmin olun.';

  @override
  String get syncError => 'Sinxronizasiya xətası';

  @override
  String syncExpiresIn(String duration) {
    return 'Kodun etibarlılığı $duration sonra bitir';
  }

  @override
  String get syncJoining => 'Cihazla qoşalaşır...';

  @override
  String get syncLegacyCleared =>
      'Köhnə cihaz siyahısı heç vaxt faktiki olaraq qoşalaşdırılmamışdı, ona görə də təmizləndi. Bu dəfə real olaraq cihazlarınızı yenidən cütləşdirin.';

  @override
  String get syncNewCode => 'Yeni kod';

  @override
  String syncPairedWith(String name) {
    return '$name ilə qoşalaşmışdır';
  }

  @override
  String get syncRetry => 'Təkrarlayın';

  @override
  String get syncStopShowing => 'Kodu gizlət';

  @override
  String get syncSyncNow => 'İndi sinxronlaşdır';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled alındı, göndərildi $pushed';
  }

  @override
  String get syncResultTitle => 'Sinxronizasiya nəticəsi';

  @override
  String get syncPulled => 'Qəbul edildi';

  @override
  String get syncPushed => 'Göndərildi';

  @override
  String get syncNoChanges => 'Heç bir dəyişiklik aşkar edilmədi';

  @override
  String get syncDocKindSubscriptions => 'Abunəliklər';

  @override
  String get syncDocKindSettings => 'Proqram parametrləri';

  @override
  String get syncDocKindOverrides => 'Abunəlik düzəlişləri';

  @override
  String get syncDocKindProfiles => 'Şəbəkə profilləri';

  @override
  String get syncDocKindChains => 'Proksi zəncirləri';

  @override
  String syncFrom(String name) {
    return '$name cihazından';
  }

  @override
  String get syncThisDevice => 'Bu cihaz';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Paket tutma';

  @override
  String get diagnosticEvents => 'Windows hadisələri';

  @override
  String get diagnosticCapture => '10 saniyə çəkin';

  @override
  String get diagnosticRequiresTun => 'Paket ələ keçirmək üçün aktiv Sora TUN bağlantısı lazımdır.';

  @override
  String get diagnosticUnavailable => 'Bu diaqnostika bu platformada əlçatan deyil.';

  @override
  String get extErrRevoked =>
      'Sora komandası bu genişləndirmə versiyasını təhlükəli və ya xarab olduğu üçün geri çağırdı.';

  @override
  String get extErrRevocationsExpired => 'Ləğv edilmiş genişlənmələr siyahısı yenilənənədək quraşdırma bloklanıb.';

  @override
  String extRevokedDisabled(String names) {
    return 'Geri çağırılmış genişləndirmələr söndürüldü: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Gizli açar';

  @override
  String get customServerWgAddresses => 'İnterfeys ünvanları';

  @override
  String get customServerWgPeerKey => 'Serverin açıq açarı';

  @override
  String get customServerWgPresharedKey => 'Ümumi açar';

  @override
  String get customServerWgAllowedIps => 'İcazəli IP-lər';

  @override
  String get customServerWgKeepalive => 'Keepalive, saniyə';

  @override
  String get customServerWgKeyInvalid => 'Açar wg genkey çıxardığı kimi base64-də 32 bayt olmalıdır.';

  @override
  String get customServerWgCidrInvalid => 'Vergüllə ayrılmış prefikslər daxil edin, məsələn 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => '0-dan 65535-ə qədər saniyə sayı daxil edin.';

  @override
  String get strictKillSwitch => 'Sərt şəbəkə kilidi';

  @override
  String get strictKillSwitchWarning =>
      'Qoşulduqdan sonra nasazlıq, yenidən başlatma və ya tətbiqdən çıxış zamanı belə VPN xaricindəki trafiki bloklayır. Giriş yalnız əlaqə kəsildikdə və ya bu seçim söndürüldükdə bərpa olunur. Cihaz yenidən başladıqda bloklama yalnız başlanğıcda qoşulma aktivdirsə davam edir.';

  @override
  String get extWorkerFailed => 'Əlavənin fon tapşırığı uğursuz oldu. Əlavənin jurnalını yoxlayın.';

  @override
  String get extAssetRejected =>
      'Genişlənmə faylında oxunmayan rənglər və ya yanlış qaydalar var. Müəllifdən faylı düzəltməsini istəyin.';

  @override
  String get extVerifiedSora => 'Sora tərəfindən təsdiqlənib';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Aç';

  @override
  String get customServerOwn => 'Şəxsi server';

  @override
  String get customServerPaste => 'Keçid yapışdır';

  @override
  String get customServerUser => 'İstifadəçi adı';

  @override
  String get customServerPassword => 'Parol';

  @override
  String get customServerSecretRequired => 'Dəyər daxil edin';

  @override
  String get customServerLinkInvalid => 'Server keçidi yanlışdır';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Sora daxili xətası. Jurnalı saxlayın və problemi bildirin.';

  @override
  String get errTls => 'Server sertifikatı rədd edildi. Saatı yoxlayın və ya provayderlə əlaqə saxlayın.';

  @override
  String get errFileAccess => 'Fayla giriş yoxdur. İcazələri və boş yeri yoxlayın.';

  @override
  String get errDataLimit => 'Həddindən çox məlumat. Daha az element seçib yenidən cəhd edin.';

  @override
  String get errCredentials => 'Saxlanmış giriş məlumatları yoxdur. Serveri yenidən idxal edin.';

  @override
  String subscriptionStale(String time) {
    return 'Son yenilənmə: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Hələ yenilənməyib. Yenidən cəhd edin.';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Server HTTP $status kodunu qaytardı. Keçidi yoxlayın və ya provayderinizə müraciət edin.',
      zero: 'Server sorğunu rədd etdi. Keçidi yoxlayın və ya provayderinizə müraciət edin.',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Server ayarları natamamdır və ya dəstəklənmir. Abunəliyi yeniləyin.';

  @override
  String get errServerIds => 'İki server eyni identifikatordan istifadə edir. Onları yenidən idxal edin.';

  @override
  String get errRoutingGroup =>
      'Marşrut mövcud olmayan serverlərə və ya zədələnmiş qrupa istinad edir. Abunəliyi yeniləyin.';

  @override
  String get errConnections => 'Bağlantı siyahısı əlçatan deyil. Qoşulun və ya başqa mühərrik seçin.';

  @override
  String get errLogs => 'Bu xidmət jurnal saxlamır. Sora-nı yeniləyin.';

  @override
  String get errDiagnostics => 'Diaqnostika toplana bilmədi. Yenidən cəhd edin və ya jurnalı saxlayın.';

  @override
  String get errMissingItem => 'Sorğulanan element artıq mövcud deyil. Siyahını yeniləyin.';

  @override
  String get errInvalidRequest => 'Sorğuda etibarsız dəyərlər var. Daxil etdiklərinizi yoxlayıb yenidən cəhd edin.';

  @override
  String get errProxyLogin =>
      'Sistem proksisi bu girişi dəstəkləmir. Yerli proksinin istifadəçi adını və parolunu silin.';

  @override
  String get errLogFilter => 'Jurnal filtri etibarsızdır. Axtarışı təmizləyib yenidən cəhd edin.';

  @override
  String get errSubRedirect => 'Server təhlükəli ünvana yönləndirdi. Provayderdən yeni keçid istəyin.';

  @override
  String get errProxySetup => 'Sistem proksisi qurula bilmədi. Yenidən qoşulun və ya jurnalı açın.';

  @override
  String get notificationsToday => 'Bu gün';

  @override
  String get notificationsYesterday => 'Dünən';

  @override
  String get notificationsMarkRead => 'Hamısını oxunmuş say';

  @override
  String get notificationsUnread => 'Oxunmayıb';

  @override
  String get desktopNotifications => 'Masaüstü bildirişləri';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Abunəliyin yenilənmə intervalı yanlışdır. Provayderin tövsiyə etdiyi intervalı seçin.';

  @override
  String get errRule => 'Marşrutlaşdırma qaydası yanlışdır. Qaydadakı domeni, IP ünvanını və ya tətbiqi yoxlayın.';

  @override
  String get errDns => 'DNS parametrləri yanlışdır. DNS serverinin ünvanını yoxlayın.';

  @override
  String get errEndpoint => 'Yoxlanacaq serverin ünvanı yanlışdır. Host adını və portu yoxlayın.';

  @override
  String get errCancelled => 'Sorğu ləğv edildi. Lazım gələrsə, əməliyyatı təkrarlayın.';

  @override
  String get customServerOptions => 'Bağlantı parametrləri';

  @override
  String get customServerTransport => 'Nəqliyyat';

  @override
  String get customServerSecurity => 'Təhlükəsizlik';

  @override
  String get customServerCipher => 'Şifr';

  @override
  String get customServerWgInterface => 'İnterfeys';

  @override
  String get customServerWgPeer => 'Qarşı tərəf';

  @override
  String get customServerOptionsInfo =>
      'Provayderin verdiyi nəqliyyat və TLS parametrlərini daxil edin və ya server keçidini yapışdırın.';

  @override
  String extAvailableOn(String platforms) {
    return 'Bu platformalarda mövcuddur: $platforms.';
  }

  @override
  String get winwsScopeWarning =>
      'Zapret bütün Windows tətbiqləri üçün 80 və 443 portlarında TCP trafikini dəyişir. Bu, VPN deyil. WinDivert drayveri Windows yenidən başladılana qədər yüklənmiş qala bilər.';

  @override
  String get winwsRequirements =>
      'Emulyasiyasız Windows x64, WLANAPI və yoxlanmış WinDivert paketi tələb olunur. Windows drayveri bloklayarsa, bu rejim əlçatan deyil.';
}
