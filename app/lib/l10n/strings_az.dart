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
  String get stateFailed => 'Qoşulmayıb';

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
  String get connEmpty => 'No connections';

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
  String get errCore => 'Sora xidməti cavab vermir';

  @override
  String get errAuth => 'Sora xidmətinə giriş yoxdur';

  @override
  String get errVersion => 'Sora-ni yeniləyin: proqram və xidmət fərqli versiyalardır';

  @override
  String get errBusy => 'Gözləyin, əvvəlki əmr hələ də işləyir';

  @override
  String get errEngineMissing => 'Bu server üçün heç bir mühərrik tapılmadı';

  @override
  String get errEngineStart => 'Mühərrik işə düşmədi';

  @override
  String get errEngineStopped => 'Mühərrik dayandı';

  @override
  String get errTunnel => 'VPN bağlantısı yaratmaq icazəsi yoxdur';

  @override
  String get errServers => 'Server xəta ilə konfiqurasiya edilib';

  @override
  String get errNetwork => 'Serverə daxil olmaq mümkün deyil';

  @override
  String get errTimeout => 'Server vaxtında cavab vermədi';

  @override
  String get errFirewall => 'VPN xaricində interneti bloklamaq mümkün olmadı';

  @override
  String get errSubFetch => 'Abunəliyi yükləmək mümkün olmadı';

  @override
  String get errSubFormat => 'Bu abunə keçidi deyil';

  @override
  String get errSubEmpty => 'Abunəliyin serverləri yoxdur';

  @override
  String get errSubDuplicate => 'Bu abunəlik artıq əlavə olunub';

  @override
  String get errSubLimit => 'Həddindən artıq abunəlik';

  @override
  String get errSubScheme => 'Link https:// ilə başlamalıdır';

  @override
  String get errSecretStore => 'Sora yaddaşı zədələnib və ya əlçatan deyil';

  @override
  String get errNoServers => 'Qoşulmaq üçün abunə əlavə edin';

  @override
  String get exportText => 'Mətn';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'İşıq';

  @override
  String get themeDark => 'Qaranlıq';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'System';

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
      other: 'abunə # günlərində başa çatır',
      one: 'abunə # günündə başa çatır',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# serverləri öz növbəsində',
      one: '# server, öz növbəsində',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# serverləri, ən sürətli',
      one: '# server, ən sürətli',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Rejim';

  @override
  String get tunnelTun => 'Bütün trafik';

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
  String get currentServer => 'Cari server';

  @override
  String get trafficDown => 'Endirildi';

  @override
  String get trafficUp => 'Yükləndi';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Aktiv qaydalar: $count';
  }

  @override
  String get recentNotifications => 'Son bildirişlər';

  @override
  String get notificationsEmpty => 'Bağlantı və abunə hadisələri burada görünəcək';

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
  String get programsFailed => 'Proqramları yükləmək mümkün olmadı';

  @override
  String get programsEmpty => 'Heç bir tətbiq tapılmadı. Başqa bir ad sınayın.';

  @override
  String get selectExe => '.exe faylı seçin';

  @override
  String get trafficUnavailable => 'Sayğaclar hələ mövcud deyil';

  @override
  String get speedtest => 'Sürət';

  @override
  String get speedtestCheck => 'Sürəti yoxlayın';

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
  String get appCopyright => '© 2026 levvs-one və ianəçilər';

  @override
  String get collapseServers => 'Serverləri yığışdırın';

  @override
  String get expandServers => 'Serverləri genişləndirin';

  @override
  String get hideDescription => 'Təsviri gizlədin';

  @override
  String get showDescription => 'Təsviri göstərin';

  @override
  String get pendingConnectionChanges => 'Bu dəyişiklikləri tətbiq etmək üçün yenidən qoşulun.';

  @override
  String get reconnectNow => 'Tətbiq edin və yenidən qoşulun';

  @override
  String get bypassLimitations =>
      'Bu rejim yalnız HTTP və TLS üçün DPI-dən yan keçir, UDP-ni dəstəkləmir və ya IP-ni dəyişdirmir. Discord səs, zənglər və bloklanmış Telegram ünvanları üçün VPN serverindən istifadə edin.';

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
      'Serverinizin hansı mühərrikə ehtiyacı olduğuna əmin deyilsinizsə, Avtomatik seçin. Sora qoşulmazdan əvvəl profili və parametrləri yoxlayır. Mühərrik planınızın bant genişliyini artıra bilməz: performans serverdən, marşrutdan, protokoldan və şəbəkədən asılıdır.\n\n## Rejimlər\n\n### Bütün trafik (TUN)\n\nSora virtual şəbəkə interfeysi yaradır və TCP və UDP daxil olmaqla proqram trafikini onun vasitəsilə yönləndirir. Telegram, oyunlar və Discord səsi üçün bu rejimi istifadə edin. Qaydalar xüsusi saytları və ya proqramları birbaşa göndərə və ya onları bloklaya bilər. Şəbəkə xidmətinə icazə və tələb olunan protokolu dəstəkləyən server lazımdır.\n\n### System proksi\n\nSora yerli HTTP/SOCKS proksisini konfiqurasiya edir. Sistem proxy parametrlərinə hörmət edən proqramlar ondan istifadə edir. Öz şəbəkə yığını olan proqramlar birbaşa qoşula bilər; UDP və səsli zənglər üçün ümumiyyətlə TUN lazımdır. Bu rejim proxy dəstəyi olan brauzerlər və proqramlar üçün uyğundur.\n\n### Server yoxdur\n\nLinux-də Sora HTTP/TLS sorğularını bölmək və yenidən formalaşdırmaq və bəzi DPI yoxlamalarını keçmək üçün [zapret](https://github.com/bol-van/zapret) istifadə edir. IP-niz eyni qalır və bağlantılar birbaşa vebsayta keçir. Nəticələr provayderinizdən və bloklama metodunuzdan asılıdır.\n\nCari inteqrasiya TCP üzərindən HTTP və TLS üçün tpws istifadə edir. O, IP-nin bloklanmasını və ya UDP-nin ötürülməsini keçmir və Telegram-nin MTProto bağlantılarına zəmanət verə bilməz. Discord səs, Telegram zəngləri və bu cür məhdudiyyətlər üçün TUN ilə VPN serverindən istifadə edin.\n\n## Mühərriklər\n\n### Avtomatik\n\nSora bütün qoşulma planını dəstəkləyən quraşdırılmış mühərriki seçir: server protokolları, daşımalar, qruplar, parçalanma və rejim. Uyğun olmayan əl seçimi cari əlaqəni dayandırmazdan əvvəl rədd edilir. Avtomatik və ya başqa mühərriki seçin və parametrləri yenidən tətbiq edin.\n\n### sing-box\n\nYeni Sora paketlərinə müştəri tərəfi XHTTP və VLESS Encryption əlavə edən [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) çəngəl daxildir. Sora quruluşu və onun imkanlarını tanıyır. XHTTP olmadan yuxarı axın quruluşu bu qabiliyyəti təkcə adından əldə etmir.\n\nDəstəklənən protokollara VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard və ZX0/parametrləri daxildir. Sora idxal edə bilər. Tam Xray JSON profilləri üçün Xray tələb olunur. Yeni AWG 3.x sahələri hələ idxal edilə bilməz. sing-box, kompüterdəki digər proqramların aşkarlaya biləcəyi parolla qorunan yerli idarəetmə portundan istifadə edir.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption və TLS fraqmentasiyasını dəstəkləyir. O, həmçinin marşrutlaşdırma və qruplarını qoruyarkən Xray tam provayder profillərini idarə edir. Bu cür profillər davranışlarını dəyişdirmədən avtomatik olaraq başqa bir mühərrikə çevrilə bilməz.\n\nBirləşdirilmiş Xray TLS sertifikatının doğrulamasını deaktiv edən ayarı sildi (`allowInsecure`). Bu parametri tələb edən adi serverlər üçün avtomatik sing-box və ya mihomo seçir. Xray seçimi cari əlaqəni dayandırmazdan əvvəl uyğunsuzluğu əl ilə bildirir. Köhnə tam JSON profilləri təsdiq edilə bilən sertifikat və ya sertifikat pininə malik yenilənmiş provayder profilinə ehtiyac duyur.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) sifarişli ehtiyat və yük balanslaşdırma qruplarını, XHTTP və AmneziaWG-ni dəstəkləyir. Yedək serverə avtomatik keçid vacib olduqda onu seçin. Sora-nin TLS parçalanma parametri bu mühərriklə əlçatan deyil.\n\n## Sora-də uyğunluq\n\n| Xüsusiyyət | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN və TCP/UDP | Bəli | Bəli | Bəli |\n| XHTTP | Bəli | Bəli | Bəli |\n| VLESS Encryption | Bəli | Bəli | Bəli |\n| Tam Xray profili | Yox | Bəli | Yox |\n| TUIC / AnyTLS | Hər ikisi | Yox | TUIC |\n| TLS parçalanması | Bəli | Bəli | Yox |\n| AmneziaWG 1.x/2.x | Bəli¹ | Yox | Bəli |\n| Sifarişli ehtiyat qrupu | Yox | No² | Bəli |\n\n¹ J1/J2/J3/Itime ilə profillər mihomo istifadə edir; bu sahələr heç vaxt səssizcə atılmamalıdır. ² Tam Xray profilləri qrupu üçün proqram ehtiyat profili seçir. Dəstək quraşdırılmış quruluşdan asılıdır; Haqqında onun versiyasını yoxlayın.\n\n## TUN yığını\n\nYığın virtual interfeys daxilində TCP və UDP-ni idarə edir. Rejimlər panelində Xray və mihomo gVisor, System, Mixed və MIPS təklif edir. Hər bir mühərrik öz üstünlüklərini saxlayır. System proxy və Serversiz rejimlər bu üstünlükdən istifadə etmir.\n\n- **Mixed** — TCP sistem yığınından istifadə edir, gVisor isə UDP-ni idarə edir. Bu, Linux-da mihomo üçün standartdır. Windows-da Xray və mihomo standart olaraq MIPS istifadə edir.\n- **System** — sistem yığınından istifadə edir. Şəbəkə proqramlarında problem yaranarsa, başqa variantı sınayın.\n- **gVisor** — istifadəçi məkanında trafiki idarə edir.\n- **MIPS** — mihomo-nin 1.19.32 paket versiyasında mövcud olan öz IP yığını.\n\nLinux-də Xray standart olaraq daxili gVisor-dən istifadə edir. Linux-də System, Mixed və MIPS TUN mühərriki kimi mihomo-dən istifadə edir, TCP və UDP-ni təsdiqlənmiş yerli SOCKS linki üzərindən Xray-ə yönləndirir. Xray protokolu, provayder profilini və marşrutu saxlayır. Bu üç seçim quraşdırılmış mihomo tələb edir. Windows-də Xray dörd TUN stekinin hamısı üçün mihomo 1.19.32 və ya daha yeni versiyadan istifadə edir. Protokollar və marşrutlaşdırma Xray-də qalır. Bu bağlantıda tətbiq qaydaları yalnız birbaşa əlaqəni və bloklamanı dəstəkləyir; Linux-də bu qaydalar Xray-in daxili gVisor stekini tələb edir.\n\nKörpü ikinci prosesi həyata keçirir. Linux-də üç boş ölçmədə o, yerli Xray TUN-dan təxminən 32-36 MiB daha çox fiziki yaddaş istifadə etdi. Bu, yükləmə yükünü ölçmür: CPU və yaddaş xərcləri bağlantılardan asılıdır. sing-box-də yığın seçicisi yoxdur. Heç bir yığın hər şəbəkədə daha yaxşı performansa zəmanət vermir. Yığın seçin və onu şəbəkənizdə sınamaq üçün Tətbiq edin və yenidən qoşulun seçin.\n\n## Parametrlər tətbiq edilir\n\nServerin seçilməsi avtomatik olaraq yenidən qoşulur. Rejim, mühərrik, DNS və qayda parametrləri dərhal saxlanılır; aktiv əlaqə zamanı Tətbiq et üzərinə klikləyin və onlardan istifadə etmək üçün yenidən qoşulun. Mühərrikin yenidən işə salınması endirmələri və zəngləri dayandıra bilər. Təkrarlanan kliklər paralel əlaqələri başlatmır; əlaqənin kəsilməsi keçidi bitirir və əlaqəni buraxır.\n\nTunel düşdükdə yalnız VPN vasitəsilə İnternet birbaşa trafiki bloklayır. Bütün maşına təsir edir. Açıq-aşkar əlaqənin kəsilməsi Sora qaydalarını aradan qaldırır. Təmizləmə başa çatmazsa, yenidən ayırmağa cəhd edin və jurnalı açın.\n\n## Layihə sənədləri\n\n- [sing-box-lx: konfiqurasiya və dəstək](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box sənədləri](https://sing-box.sagernet.org/)\n- [Xray sənədləri](https://xtls.github.io/)\n- [mihomo sənədləri](https://wiki.metacubex.one/)\n- [zapret: əməliyyat və məhdudiyyətlər](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Serverləri yoxlayın';

  @override
  String get extensions => 'Genişləndiricilər';

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
    return 'Fayla $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diaqnostikası';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Hələ qeydə alınmış sorğu yoxdur. Əvvəlcə sürət testi veb saytını açın.';

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
  String get qrScanHint => 'QR kodlu ekran görüntüsü və ya foto seçin, ya da keçid yapışdırın';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'Bu şəkildə QR kod tapılmadı.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Şəkli aç';

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
  String get customServerShadowsocksCredentials => 'Shadowsocks üçün: üsul:parol, məsələn chacha20-ietf-poly1305:parol';
}
