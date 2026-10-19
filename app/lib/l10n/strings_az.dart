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
  

  @override
  String get syncCodeExpired => 'The pairing code expired';

  @override
  String get syncDaemonFailed => 'Sync service failed to start';

  @override
  String get syncDaemonMissing => 'Sync service not found';

  @override
  String get syncDaemonStarting => 'Starting sync service…';

  @override
  String syncExpiresIn(String expires) {
    return 'Expires in $expires';
  }

  @override
  String get syncJoining => 'Joining…';

  @override
  String get syncLegacyCleared => 'Old sync data cleared';

  @override
  String get syncNewCode => 'New code';

  @override
  String syncPairedWith(String name) {
    return 'Paired with $name';
  }

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncStopShowing => 'Stop showing';

  @override
  String get syncSyncNow => 'Sync now';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Pulled $pulled, pushed $pushed';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid => 'Sync is not available on Android';
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
  String speedMbps(double value) {
    return '${intl.NumberFormat('0.0', localeName).format(value)} Mbps';
  }

  @override
  String latencyMs(int value) {
    return '$value ms';
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
  String get updateSignaturePending => 'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';
  String get updateManualSigWarning => 'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

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
  String extRatingLabel(String rating) => 'Rating $rating of 5';
  @override
  String extByAuthor(String author) => 'by $author';
  @override
  String extInstallsCount(String count) => '$count installs';
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
  String extToggleEnabled(String name) => 'Enable ${name}';
  @override
  String get extSearchInstalled => 'Search installed';
  @override
  String get extUpdateAll => 'Update all';
  @override
  String extUpdatesAvailable(int count) => '${count} updates available';
  @override
  String extUpdatedCount(int count) => '${count} updated';
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
  String get extConflictsIntro => 'These extensions want the same thing. Choose which one wins — the other stays installed, but its contested capability is paused.';
  @override
  String get extConflictRoutingRules => 'Routing rules';
  @override
  String get extConflictTheme => 'App theme';
  @override
  String get extConflictNetHooks => 'Network hooks';
  @override
  String extConflictWinner(String name) => '${name} wins';
  @override
  String extConflictsCount(int count) => '${count} conflicts need your decision';
  @override
  String get extConflictsResolve => 'Resolve';
  @override
  String get extConflictNote => 'Your choice is saved on this device and applied by the engine.';
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
  String get extPermBackgroundDetail =>
      'Can wake up on a schedule and run code in the background.';

  @override
  String get extCapBackground => 'Background tasks';
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
  String extCatalogCached(String date) => 'Cached catalog · ${date}';
  @override
  String get extChangelog => 'Changelog';
  @override
  String get extImageFailed => 'Couldn\'t load the image';
  @override
  String get extRatingHow => 'How ratings work';
  @override
  String get extRatingHowBody => 'Ratings use a Bayesian average: an extension with few ratings stays near the middle until more people vote, so a single 5-star review cannot push a new extension to the top. Recent ratings weigh more than old ones, and only one rating per account counts.';
  @override
  String get extScreenshots => 'Screenshots';
  @override
  String get extSortRelevance => 'Relevance';
  @override
  String get extPermNetworkDetail => 'Internet access is limited to these hosts:';
  @override
  String get extBgTitle => 'Background task';
  @override
  String get extBgEnabled => 'Run in background';
  @override
  String get extBgInterval => 'Run interval';
  @override
  String extBgMinutes(int minutes) => '$minutes min';
  @override
  String extBgHours(int hours) => '$hours h';
  @override
  String get extBgNote =>
      'Applies immediately. The shortest allowed interval is 15 minutes.';
  @override
  String get extBgDisabledNote =>
      'Enable the extension to manage its background task.';
  @override
  String get extCapNetwork => 'Can reach the internet';
  @override
  String extCapNetworkHosts(String hosts) => 'Can reach: $hosts';

  @override
  String exportLogFile(String name) {
    return 'Fayla $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diaqnostikası';

  @override
  String get diagnosticPackets => 'Paket tutma';

  @override
  String get diagnosticEvents => 'Windows hadisələri';

  @override
  String get diagnosticCapture => '10 saniyə çəkin';

  @override
  String get diagnosticNoData => 'Hələ qeydə alınmış sorğu yoxdur. Əvvəlcə sürət testi veb saytını açın.';

  @override
  String get diagnosticRequiresTun => 'Paket ələ keçirmək üçün aktiv Sora TUN bağlantısı lazımdır.';

  @override
  String get diagnosticUnavailable => 'Bu diaqnostika bu platformada əlçatan deyil.';
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
  String connConnectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# connections',
      one: '# connection',
    );
    return _temp0;
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
  String get chainHopMissing => 'One of the chain servers is no longer available';

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
  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';
  @override
  String get autoSwitchOnDegradeDetail => 'If the pinned server stops answering or gets clearly slower, switch to the best measured alternative — at most once every 10 minutes.';
  @override
  String get tunStackMixed => 'Mixed';
  @override
  String get tunStackSystem => 'System';

  @override
  String get censorTitle => 'Censorship detector';

  @override
  String get censorHistory => 'History';

  @override
  String get censorEmpty => 'No censorship checks yet';

  @override
  String get censorExplainer => 'Your provider seems to be interfering with the connection. Applying the recommended profile may restore access.';

  @override
  String get censorNoProfile => 'No recommended profile for this network yet';

  @override
  String get censorApplyProfile => 'Apply recommended profile';

  @override
  String get censorEnable => 'Enable';

  @override
  String get censorDetails => 'Details';

  @override
  String get censorNotNow => 'Not now';

  @override
  String get censorPromptTitle => 'Possible censorship detected';

  @override
  String censorPromptBody(int confidence) {
    return 'Detected with $confidence% confidence';
  }

  @override
  String censorConfidence(int confidence) {
    return '$confidence% confidence';
  }

  @override
  String get censorKindBlocked => 'Blocked';

  @override
  String get censorKindLikely => 'Likely blocked';

  @override
  String get censorKindClear => 'Not blocked';

  @override
  String get censorKindUnknown => 'Unknown';

  @override
  String get censorReasonTlsReset => 'TLS reset';

  @override
  String get censorReasonHttpBlock => 'HTTP block';

  @override
  String get censorReasonDnsSpoofed => 'DNS spoofing';

  @override
  String get censorReasonConnectTimeout => 'Connection timeout';

  @override
  String get customServerAdd => 'Add custom server';

  @override
  String get customServers => 'Custom servers';

  @override
  String get customServerName => 'Name';

  @override
  String get customServerNameHint => 'My server';

  @override
  String get customServerNameRequired => 'Enter a name';

  @override
  String get customServerAddress => 'Address';

  @override
  String get customServerAddressHint => 'example.com or 1.2.3.4';

  @override
  String get customServerAddressRequired => 'Enter the server address';

  @override
  String get customServerAddressInvalid => 'This address does not look valid';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Enter a port between 1 and 65535';

  @override
  String get customServerProtocol => 'Protocol';

  @override
  String get customServerCredentials => 'Credentials';

  @override
  String get customServerOptional => 'Optional';

  @override
  String get customServerShowSecret => 'Show';

  @override
  String get customServerHideSecret => 'Hide';

  @override
  String get customServerBadge => 'Custom';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get customServerEmptyHint => 'No custom servers yet';

  @override
  String get customServerTest => 'Test connection';

  @override
  String get errObfsUnsupported => 'Traffic obfuscation is not supported here';

  @override
  String get leakTestTitle => 'Leak test';

  @override
  String get leakTestIntro => 'Check whether traffic leaks outside the tunnel: direct DNS, ICMP echo, IPv6 and system resolvers.';

  @override
  String get leakTestRun => 'Run test';

  @override
  String get leakTestCancel => 'Cancel';

  @override
  String get leakTestNeedsConnection => 'Connect first to run the leak test';

  @override
  String leakTestProgress(int count) {
    return 'Checked $count…';
  }

  @override
  String get leakTestAllClear => 'No leaks found';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# leaks found', one: '# leak found',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Fixed';

  @override
  String get leakTestCheckDirectDns => 'Direct DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'System resolvers';

  @override
  String get noticeDegraded => 'Current server is degraded';

  @override
  String get obfs => 'Obfuscation';

  @override
  String get obfsPreset => 'Preset';

  @override
  String get obfsPresetAggressive => 'Aggressive';

  @override
  String get obfsPresetBalanced => 'Balanced';

  @override
  String get obfsPresetOff => 'Off';

  @override
  String get obfsPresetCustom => 'Custom';

  @override
  String get obfsManual => 'Manual settings';

  @override
  String get obfsUtls => 'uTLS fingerprint';

  @override
  String get obfsUtlsAuto => 'Auto';

  @override
  String get obfsJitter => 'Jitter';

  @override
  String get obfsJitterNeedsFragment => 'Jitter needs fragmentation enabled';

  @override
  String get obfsFineTune => 'Fine-tuning supported';

  @override
  String get obfsDetecting => 'Detecting capabilities…';

  @override
  String get obfsCapabilities => 'Capabilities';

  @override
  String obfsCompatibleEngines(String engines) {
    return 'Compatible engines: $engines';
  }

  @override
  String get obfsSupported => 'Supported';

  @override
  String get obfsUnsupported => 'Not supported';

  @override
  String get obfsUnknown => 'Not detected yet';
}
