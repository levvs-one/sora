// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class STr extends S {
  STr([String locale = 'tr']) : super(locale);

  @override
  String get stateOff => 'Bağlı değil';

  @override
  String get stateConnecting => 'Bağlanıyor';

  @override
  String get stateConnected => 'Bağlı';

  @override
  String get stateReconnecting => 'Yeniden bağlanılıyor';

  @override
  String get stateDisconnecting => 'Bağlantı kesiliyor';

  @override
  String get stateFailed => 'Bağlı değil';

  @override
  String get coreMissing => 'Sora hizmeti yanıt vermiyor';

  @override
  String get serverAuto => 'En hızlı';

  @override
  String get serverBypass => 'Sunucu yok';

  @override
  String get addSubscription => 'Abonelik ekle';

  @override
  String get servers => 'Sunucular';

  @override
  String get settings => 'Ayarlar';

  @override
  String get subscription => 'Abonelik';

  @override
  String get subscriptionLink => 'Abonelik bağlantısı';

  @override
  String get add => 'Eklemek';

  @override
  String get refresh => 'Güncelleme';

  @override
  String get rename => 'Yeniden isimlendirmek';

  @override
  String get delete => 'Silmek';

  @override
  String get cancel => 'İptal etmek';

  @override
  String get save => 'Kaydetmek';

  @override
  String get name => 'İsim';

  @override
  String deleteSubscription(String name) {
    return '“$name” silinsin mi?';
  

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
  String get syncErrUnreachable => 'The other device didn\'t answer. Make sure it\'s on the same network and showing its code.';
  @override
  String get syncError => 'Sync error';

  @override
  String syncExpiresIn(String duration) {
    return 'Code expires in $duration';
  }

  @override
  String get syncJoining => 'Pairing with the device…';

  @override
  String get syncLegacyCleared => 'The old device list was never actually paired, so it was cleared. Pair your devices again — for real this time.';

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
  String get syncUnavailableAndroid => 'Device sync isn\'t available on Android yet — the sync service can\'t run there.';
}

  @override
  String get routes => 'Rotalar';

  @override
  String get presetGlobal => 'Her şey VPN aracılığıyla';

  @override
  String get presetRu => 'Rusya doğrudan';

  @override
  String get presetIr => 'İran doğrudan';

  @override
  String get presetCn => 'Çin doğrudan';

  @override
  String get blockAds => 'Reklamları engelle';

  @override
  String get killSwitch => 'İnternet yalnızca VPN aracılığıyla';

  @override
  String get engine => 'Motor';

  @override
  String get engineAuto => 'Otomatik';

  @override
  String get animations => 'Animasyonlar';

  @override
  String get logs => 'Kayıt';

  @override
  String get about => 'Hakkında';

  @override
  String get logsAll => 'Tüm';

  @override
  String get logsImportant => 'Önemli';

  @override
  String get logsErrors => 'Hatalar';

  @override
  String get search => 'Aramak';

  @override
  String get export => 'Dosyaya kaydet';

  @override
  String get clear => 'Temizlemek';

  @override
  String get logsEmpty => 'Burada hiçbir şey yok';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get notInstalled => 'Kurulu değil';

  @override
  String get sourceCode => 'Kaynak kodu';

  @override
  String get license => 'Lisans';

  @override
  String usage(String used, String total) {
    return '$used veya $total';
  }

  @override
  String until(String date) {
    return '$date\'ye kadar';
  }

  @override
  String get expired => 'Günü geçmiş';

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
    return '$n TR';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'Bir şeyler ters gitti';

  @override
  String get errCore => 'Sora hizmeti yanıt vermiyor';

  @override
  String get errAuth => 'Sora hizmetine erişim yok';

  @override
  String get errVersion => 'Sora\'yi güncelleyin: uygulama ve hizmet farklı sürümlerdir';

  @override
  String get errBusy => 'Bekle, önceki komut hala çalışıyor';

  @override
  String get errEngineMissing => 'Bu sunucu için motor bulunamadı';

  @override
  String get errEngineStart => 'Motor çalışmadı';

  @override
  String get errEngineStopped => 'Motor durdu';

  @override
  String get errTunnel => 'VPN bağlantısı oluşturma izni yok';

  @override
  String get errServers => 'Sunucu bir hatayla yapılandırıldı';

  @override
  String get errNetwork => 'Sunucuya ulaşılamıyor';

  @override
  String get errTimeout => 'Sunucu zamanında yanıt vermedi';

  @override
  String get errFirewall => 'VPN dışında internet engellenemedi';

  @override
  String get errSubFetch => 'Abonelik yüklenemedi';

  @override
  String get errSubFormat => 'Bu bir abonelik bağlantısı değil';

  @override
  String get errSubEmpty => 'Aboneliğin sunucusu yok';

  @override
  String get errSubDuplicate => 'Bu abonelik zaten eklenmiş';

  @override
  String get errSubLimit => 'Çok fazla abonelik';

  @override
  String get errSubScheme => 'Bağlantı https:// ile başlamalıdır';

  @override
  String get errSecretStore => 'Sora depolama alanı hasarlı veya kullanılamıyor';

  @override
  String get errNoServers => 'Bağlanmak için bir abonelik ekleyin';

  @override
  String get exportText => 'Metin';

  @override
  String get connections => 'Bağlantılar';

  @override
  String get close => 'Kapalı';

  @override
  String get chainDirect => 'Doğrudan';

  @override
  String get chainBlocked => 'Engellendi';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Işık';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Bağlantı';

  @override
  String get sectionNoServer => 'Sunucu yok';

  @override
  String get sectionPing => 'ping';

  @override
  String get sectionLog => 'Teşhis';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Otomatik';

  @override
  String get dnsHint => 'Adresler, virgülle ayrılmış';

  @override
  String get fragment => 'TLS parçalanması';

  @override
  String get fragmentPackets => 'Ne bölünecek';

  @override
  String get fragmentLength => 'Parça boyutu';

  @override
  String get fragmentInterval => 'Parçalar arasında duraklama';

  @override
  String get byDefault => 'Varsayılan';

  @override
  String get rangeHint => 'Örneğin 100-200';

  @override
  String get splitPos => 'Bölünmüş konumlar';

  @override
  String get splitPosHint => 'Örneğin, 1, midsld';

  @override
  String get disorder => 'Parçaları yeniden sırala';

  @override
  String get tlsRecord => 'TLS kaydını bölme';

  @override
  String get tlsRecordNo => 'HAYIR';

  @override
  String get tlsRecordSni => 'Site adında';

  @override
  String get tlsRecordFirst => 'İlk bayttan sonra';

  @override
  String get hostCase => 'Ana Bilgisayar vakasını değiştir';

  @override
  String get probeMethod => 'Yöntem';

  @override
  String get probeAuto => 'Otomatik';

  @override
  String get probeEngine => 'Motor aracılığıyla';

  @override
  String get probeConnect => 'Yalnızca bağlantı';

  @override
  String get probeUrl => 'Test adresi';

  @override
  String get probeTimeout => 'Beklemek';

  @override
  String seconds(int n) {
    return '$n\'ler';
  }

  @override
  String get subscriptions => 'Abonelikler';

  @override
  String get subscriptionSettings => 'Ayarlar';

  @override
  String get userAgent => 'Kullanıcı Aracısı';

  @override
  String get autoUpdate => 'Otomatik olarak güncelle';

  @override
  String get updateInterval => 'Ne sıklıkta';

  @override
  String get intervalProvider => 'Sağlayıcının sorduğu gibi';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Şimdi güncelle';

  @override
  String get logLevel => 'Ne kaydedilmeli';

  @override
  String get levelDebug => 'Her şey';

  @override
  String get levelInfo => 'Olağan';

  @override
  String get levelWarning => 'Önemli';

  @override
  String get levelError => 'Yalnızca hatalar';

  @override
  String get recordDestinations => 'Site adreslerini kaydedin';

  @override
  String get reset => 'Ayarları sıfırla';

  @override
  String get resetConfirm => 'Tüm ayarlar sıfırlansın mı?';

  @override
  String get resetAction => 'Sıfırla';

  @override
  String get invalidValue => 'Bu değer çalışmayacak';

  @override
  String get website => 'Abonelik sayfası';

  @override
  String get providerWebsite => 'Sağlayıcı web sitesi';

  @override
  String get support => 'Destek';

  @override
  String controlPortQuestion(String engine) {
    return '$engine bu bilgisayardaki bir bağlantı noktası aracılığıyla kontrol ediliyor. Diğer programlar bir VPN\'in açık olduğunu anlayacaktır.';
  }

  @override
  String chooseEngine(String engine) {
    return '$engine\'yi seçin';
  }

  @override
  String get rules => 'Özel kurallar';

  @override
  String get ruleAdd => 'Yeni kural';

  @override
  String get ruleHint => 'Site, IP veya program';

  @override
  String get ruleDirect => 'Doğrudan';

  @override
  String get ruleProxy => 'VPN aracılığıyla';

  @override
  String get ruleBlock => 'Engellemek';

  @override
  String get failover => 'Arızayı açma';

  @override
  String get connectOnStart => 'Başlangıçta bağlanın';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'abonelik # gün içinde sona eriyor',
      one: 'abonelik # gününde sona eriyor',
      zero: 'abonelik birkaç saat içinde bitiyor',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left sol';
  }

  @override
  String get ruleInvalid => 'Bu bir siteye, IP\'ye veya programa benzemiyor';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# sunucuları sırasıyla',
      one: '# sunucusu sırasıyla',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# sunucuları, en hızlısı',
      one: '# sunucusu, en hızlısı',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mod';

  @override
  String get tunnelTun => 'Tüm trafik';

  @override
  String get tunnelProxy => 'System proxy';

  @override
  String get proxyAddress => 'Proxy adresi';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get launchAtLogin => 'Sistemle başlayın';

  @override
  String get launchAtLoginDetail => 'Oturum açtığınızda Sora otomatik olarak başlatılacak ve tepside kalacak.';

  @override
  String get closeToTray => 'Kapalıyken tepside saklayın';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get trayOpen => 'Sora\'yi açın';

  @override
  String get trayConnect => 'Bağlamak';

  @override
  String get trayDisconnect => 'Bağlantıyı kes';

  @override
  String get trayServer => 'Sunucu';

  @override
  String get trayQuit => 'Sora\'den çık';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora hâlâ tepside';

  @override
  String get noticeInTrayBody => 'Simgesinin menüsünden çık';

  @override
  String get noticeLost => 'Bağlantı kesildi';

  @override
  String get noticeLostBody => 'Sora yeniden bağlanıyor';

  @override
  String get noticeRestored => 'Tekrar bağlanıldı';

  @override
  String get noticeFailed => 'Bağlanılamadı';

  @override
  String get noticeBackup => 'Ana sunucu yanıt vermedi; yedekleme trafiği taşır';

  @override
  String get noticeNext => 'Sunucu yanıt vermedi; bir sonraki trafiği taşıyor';

  @override
  String get noticeMainBack => 'Ana sunucu tekrar cevap verir ve trafiği taşır';

  @override
  String get noticeSubscription => 'Abonelik';

  @override
  String get importTitle => 'Bu abonelik eklensin mi?';

  @override
  String get importSealed =>
      'Bu bağlantı Happ için şifrelenmiştir ve onu yalnızca Happ okuyabilir. Sağlayıcınızdan düz abonelik bağlantısını isteyin.';

  @override
  String get understood => 'TAMAM';

  @override
  String get noAnswer => 'cevap yok';

  @override
  String get home => 'Ev';

  @override
  String get navRules => 'Tüzük';

  @override
  String get navConnections => 'Bağlantılar';

  @override
  String get navLogs => 'Günlükler';

  @override
  String get navAbout => 'Hakkında';

  @override
  String get sidebarToggle => 'Kenar çubuğunu aç/kapat';

  @override
  String get more => 'Daha';

  @override
  String get less => 'Az';

  @override
  String get currentServer => 'Mevcut sunucu';

  @override
  String get trafficDown => 'İndirildi';

  @override
  String get trafficUp => 'Yüklendi';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Aktif kurallar: $count';
  }

  @override
  String get recentNotifications => 'Son bildirimler';

  @override
  String get notificationsEmpty => 'Bağlantı ve abonelik etkinlikleri burada görünecek';

  @override
  String get retryConnect => 'Bağlantıyı yeniden dene';

  @override
  String get openLogs => 'Günlükleri aç';

  @override
  String get tourReplay => 'Kılavuzu tekrar göster';

  @override
  String tourStep(int step) {
    return 'Adım $step/5';
  }

  @override
  String get tourBack => 'Geri';

  @override
  String get tourNext => 'Sonraki';

  @override
  String get tourSkip => 'Atlamak';

  @override
  String get tourFinish => 'Tamamlamak';

  @override
  String get tourAdd => 'Sağlayıcınızın abonelik bağlantısını ekleyin.';

  @override
  String get tourServer => 'Bir sunucu seçin. “En Hızlı” sizin için birini seçer.';

  @override
  String get tourConnect => 'Bağlanmak veya bağlantıyı kesmek için burayı tıklayın.';

  @override
  String get tourMode => 'Bir mod seçin. VPN düşerse Kill Switch interneti engeller.';

  @override
  String get tourSettings => 'Ayarları açın. Bu kılavuzu orada tekrar oynatabilirsiniz.';

  @override
  String get chooseProgram => 'Bir program seçin';

  @override
  String get installedApps => 'Yüklü uygulamalar';

  @override
  String get runningProcesses => 'Çalışan işlemler';

  @override
  String get programsFailed => 'Uygulamalar yüklenemedi';

  @override
  String get programsEmpty => 'Hiçbir uygulama bulunamadı. Başka bir ad deneyin.';

  @override
  String get selectExe => 'Bir .exe dosyası seçin';

  @override
  String get trafficUnavailable => 'Sayaçlar henüz kullanılamıyor';

  @override
  String get speedtest => 'Hız';

  @override
  String get speedtestCheck => 'Hızı kontrol edin';

  @override
  String get speedtestSearch => 'Bir hizmet bulun';

  @override
  String get speedtestEmpty => 'Eşleşme yok. Aramayı değiştirin.';

  @override
  String get speedtestBackToList => 'Hizmetlere geri dön';

  @override
  String get speedtestOpenBrowser => 'Tarayıcıda aç';

  @override
  String get speedtestUnavailable => 'Katıştırılmış tarayıcı başlatılamadı. Hizmeti sistem tarayıcınızda açın.';

  @override
  String get speedtestPageFailed => 'Sayfa yüklenemedi. Yeniden yükleyin veya hizmeti sistem tarayıcınızda açın.';

  @override
  String get speedtestExternalFailed => 'Sistem tarayıcısı açılamadı. Tekrar deneyin.';

  @override
  String get modes => 'Modlar';

  @override
  String get proxyShort => 'vekil';

  @override
  String get tunMode => 'Tüm trafik (TUN)';

  @override
  String get checkUpdates => 'Güncellemeleri kontrol edin';

  @override
  String get updates => 'Uygulama güncellemeleri';

  @override
  String updateAvailable(String version) {
    return 'Sürüm $version mevcut';
  }

  @override
  String get updateOpenAbout => 'Güncellemeyi görüntüle';

  @override
  String updateNotes(String version) {
    return '$version\'deki değişiklikler';
  }

  @override
  String get updateCheck => 'Güncellemeleri kontrol edin';

  @override
  String get updateChecking => 'Kontrol ediliyor...';

  @override
  String get updateNoNotes => 'Sürümde not yok.';

  @override
  String get updateDropWarning =>
      'Sora ve çekirdeği güncellenirken VPN bağlantısı birkaç saniyeliğine kesilecektir. Devam etmek?';

  @override
  String get updateWaitConnection => 'VPN bağlantısının ve çekirdeğin hazır olmasını bekleyin.';

  @override
  String get updateDownloading => 'Dosyalar indiriliyor ve doğrulanıyor...';

  @override
  String get updateInstalling => 'Güncelleme hazırlanıyor veya yönetici kimlik doğrulaması bekleniyor...';

  @override
  String get updateNetworkError => 'Güncelleme indirilemedi. Tekrar deneyin.';

  @override
  String get updateReleaseError => 'Sürüm verileri veya gerekli dosyalar eksik veya geçersiz.';

  @override
  String get updateChecksumError => 'İndirme SHA256SUMS ile eşleşmiyor. Hiçbir şey yüklenmedi.';

  @override
  String get updateInstallError => 'Güncelleme tamamlanmadı. Kimlik doğrulama iptal edilmiş olabilir.';

  @override
  String get updateUnsupported =>
      'Bu yürütülebilir dosya, desteklenen bir Sora paket çiftine ait değil. Sürüm kurulum talimatlarını kullanın.';

  @override
  String get updateManual =>
      'Her iki doğrulanmış paketi de yüklemek için bu komutu bir terminalde çalıştırın, ardından Sora\'yi yeniden açın. Dosyalar indirme dizininde kalır. VPN bağlantısı kesilecek.';
  String get updateSignaturePending => 'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';
  String get updateManualSigWarning => 'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';
  String get updateWindowsSigBlocked => 'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';
  String get updateVersionRevoked => 'This version has been recalled by the developer. Please wait for a fixed release.';
  String get updateRolloutPending => 'A newer version is rolling out gradually and will be offered to you automatically.';

  @override
  String updateRollbacking(String version) {
    return 'Rolling back to version $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'The update to $version did not pass the health check, so Sora was rolled back to $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Automatic rollback failed. If the new version does not work, reinstall the previous release manually.';

  @override
  String get updateRollbackCacheError => 'Could not prepare a verified rollback copy of the current version, so the update was not installed.';

  @override
  String get updateCopyCommand => 'Komutu kopyala';

  @override
  String get updateChecksDisabled => 'Otomatik kontroller Ayarlar\'da devre dışı bırakıldı.';

  @override
  String get updateInstalled => 'Güncelleme yüklendi. Sora\'yi yeniden açın.';

  @override
  String get projectLinks => 'Proje';

  @override
  String get githubReleases => 'Sürümler ve indirmeler';

  @override
  String get telegramChannel => 'Telegram kanalı';

  @override
  String get licenses => 'Lisanslar';

  @override
  String get componentLicenses => 'Bileşen lisansları';

  @override
  String get appCopyright => '© 2026 levvs-one ve katkıda bulunanlar';

  @override
  String get collapseServers => 'Sunucuları daralt';

  @override
  String get expandServers => 'Sunucuları genişlet';

  @override
  String get hideDescription => 'Açıklamayı gizle';

  @override
  String get showDescription => 'Açıklamayı göster';

  @override
  String get pendingConnectionChanges => 'Bu değişiklikleri uygulamak için yeniden bağlanın.';

  @override
  String get reconnectNow => 'Uygula ve yeniden bağlan';

  @override
  String get bypassLimitations =>
      'Bu mod DPI\'yi yalnızca HTTP ve TLS için atlar, UDP\'yi desteklemez veya IP\'nizi değiştirmez. Discord sesleri, aramaları ve engellenen Telegram adresleri için bir VPN sunucusu kullanın.';

  @override
  String get errEngineUnsupported =>
      'Seçilen motor bu profili veya ayarları desteklemiyor. Otomatik\'i veya uyumlu bir motoru seçin.';

  @override
  String get errRestore =>
      'Bağlantı temizliği tamamlanmadı. Bağlantıyı kesmeyi yeniden deneyin; ayrıntılar için günlüğe bakın.';

  @override
  String get errSessionEnded => 'Bu oturum zaten sona erdi. Bağlantı durumunu yenileyin.';

  @override
  String get retryDisconnect => 'Bağlantıyı kesmeyi yeniden dene';

  @override
  String get tunStack => 'TUN yığını';

  @override
  String get modesInfo => 'Modlar hakkında';

  @override
  String get modesGuideTitle => 'Modlar ve motorlar';

  @override
  String get modesGuide =>
      'Sunucunuzun hangi motora ihtiyacı olduğundan emin değilseniz Otomatik\'i seçin. Sora bağlanmadan önce profili ve ayarları kontrol eder. Bir motor planınızın bant genişliğini artıramaz: performans sunucuya, rotaya, protokole ve ağa bağlıdır.\n\n## Modlar\n\n### Tüm trafik (TUN)\n\nSora bir sanal ağ arayüzü oluşturur ve TCP ve UDP dahil olmak üzere uygulama trafiğini bu arayüz üzerinden yönlendirir. Bu modu Telegram, oyunlar ve Discord ses için kullanın. Kurallar belirli siteleri veya programları doğrudan gönderebilir veya engelleyebilir. Ağ hizmetinin izne ve gerekli protokolü destekleyen bir sunucuya ihtiyacı vardır.\n\n### System proxy\n\nSora, yerel bir HTTP/SOCKS proxy\'sini yapılandırır. Sistem proxy ayarlarına saygı duyan uygulamalar bunu kullanır. Kendi ağ yığınına sahip uygulamalar doğrudan bağlanabilir; UDP ve sesli aramalar genellikle TUN\'a ihtiyaç duyar. Bu mod, proxy desteği olan tarayıcılara ve uygulamalara uygundur.\n\n### Sunucu yok\n\nLinux\'de Sora, HTTP/TLS isteklerini bölmek ve yeniden şekillendirmek ve bazı DPI kontrollerini atlamak için [zapret](https://github.com/bol-van/zapret) kullanır. IP\'niz aynı kalır ve bağlantılar doğrudan web sitesine gider. Sonuçlar sağlayıcınıza ve engelleme yöntemine bağlıdır.\n\nMevcut entegrasyon HTTP için tpws ve TCP üzerinden TLS kullanıyor. IP engellemeyi veya aktarma UDP\'sini atlamaz ve Telegram\'nin MTProto bağlantılarını garanti edemez. Discord ses, Telegram aramaları ve bu tür kısıtlamalar için TUN\'lu bir VPN sunucusu kullanın.\n\n## Motorlar\n\n### Otomatik\n\nSora, bağlantı planının tamamını destekleyen kurulu bir motoru seçer: sunucu protokolleri, aktarımlar, gruplar, parçalanma ve mod. Uyumsuz bir manuel seçim, mevcut bağlantı durdurulmadan önce reddedilir. Otomatik veya başka bir motoru seçin ve ayarları tekrar uygulayın.\n\n### sing-box\n\nYeni Sora paketleri, istemci tarafı XHTTP ve VLESS Encryption\'yi ekleyen [sing-box](https://github.com/SagerNet/sing-box) çatalı olan [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)\'yi içerir. Sora, yapıyı ve yeteneklerini tanır. XHTTP\'siz bir yukarı akış yapısı bu yeteneği yalnızca adından kazanmaz.\n\nDesteklenen protokoller arasında VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard ve AmneziaWG 1.x/2.x parametreleri bulunur Sora içe aktarabilir. Tam Xray JSON profilleri Xray gerektirir. Yeni AWG 3.x alanları henüz içe aktarılamıyor. sing-box, bilgisayardaki diğer uygulamaların algılayabileceği, parola korumalı bir yerel kontrol bağlantı noktası kullanır.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core), VLESS, REALITY, XHTTP, VLESS Encryption ve TLS parçalanmasını destekler. Ayrıca yönlendirmelerini ve gruplarını korurken sağlayıcı Xray profillerinin tamamını çalıştırır. Bu tür profiller, davranışları değiştirilmeden otomatik olarak başka bir motora dönüştürülemez.\n\nBirlikte verilen Xray, TLS sertifika doğrulamasını devre dışı bırakan ayarı (\"allowInsecure\") kaldırdı. Otomatik, bu ayarı gerektiren sıradan sunucular için sing-box veya mihomo\'yi seçer. Xray seçildiğinde, mevcut bağlantı durdurulmadan önce uyumsuzluk manuel olarak raporlanır. Daha eski tam JSON profilleri, doğrulanabilir bir sertifikaya veya sertifika pinine sahip güncellenmiş bir sağlayıcı profiline ihtiyaç duyar.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo), sıralı geri dönüş ve yük dengeleme grupları olan XHTTP ve AmneziaWG\'yi destekler. Yedekleme sunucusuna otomatik yük devretme önemli olduğunda bunu seçin. Sora\'nin TLS parçalanma ayarı bu motorda kullanılamaz.\n\n## Sora ile uyumluluk\n\n| Özellik | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN ve TCP/UDP | Evet | Evet | Evet |\n| XHTTP | Evet | Evet | Evet |\n| VLESS Encryption | Evet | Evet | Evet |\n| Tam Xray profili | Hayır | Evet | Hayır |\n| TUIC / AnyTLS | Her ikisi de | Hayır | TUIC |\n| TLS parçalanması | Evet | Evet | Hayır |\n| AmneziaWG 1.x/2.x | Evet¹ | Hayır | Evet |\n| Sıralı yedek grup | Hayır | No² | Evet |\n\n¹ J1/J2/J3/Itime içeren profiller mihomo kullanır; bu alanlar asla sessizce atılmamalıdır. ² Tam Xray profillerinden oluşan bir grup için uygulama bir yedekleme profili seçer. Destek, kurulu yapıya bağlıdır; Hakkında bölümünden sürümünü kontrol edin.\n\n## TUN yığını\n\nYığın, sanal arabirim içindeki TCP ve UDP\'yi yönetir. Modlar panelinde Xray ve mihomo, gVisor, System, Mixed ve MIPS\'yi sunar. Her motor kendi tercihini kaydeder. System proxy ve Sunucusuz modları bu tercihi kullanmaz.\n\n- **Mixed** — TCP sistem yığınını kullanırken gVisor UDP\'yi yönetir. Bu, Linux üzerinde mihomo için varsayılandır. Windows üzerinde Xray ve mihomo varsayılan olarak MIPS kullanır.\n- **System** — sistem yığınını kullanır. Ağ uygulamaları sorunlarla karşılaşırsa başka bir seçeneği deneyin.\n- **gVisor** — kullanıcı alanındaki trafiği yönetir.\n- **MIPS** — mihomo\'nin kendi IP yığını, paket halindeki 1.19.32 sürümünde mevcuttur.\n\nLinux\'de Xray, varsayılan olarak yerleşik gVisor\'yi kullanır. Linux üzerindeki System, Mixed ve MIPS, TUN motoru olarak mihomo\'yi kullanır ve kimliği doğrulanmış bir yerel SOCKS bağlantısı üzerinden TCP ve UDP\'yi Xray\'ye iletir. Xray protokolü, sağlayıcı profilini ve yönlendirmeyi korur. Bu üç seçenek mihomo\'nin kurulu olmasını gerektirir. Windows üzerinde Xray, dört TUN yığınının tümü için mihomo 1.19.32 veya daha yenisini kullanır. Protokoller ve yönlendirme Xray içinde kalır. Bu birleşimde uygulama kuralları yalnızca doğrudan bağlantı ve engellemeyi destekler; Linux üzerinde bu kurallar Xray’ın yerleşik gVisor yığınını gerektirir.\n\nKöprü ikinci bir süreci yürütür. Linux üzerindeki üç boşta ölçümde, yerel Xray TUN\'dan yaklaşık 32-36 MiB daha fazla fiziksel bellek kullandı. Bu, indirme yükünü ölçmez: CPU ve bellek maliyetleri bağlantılara bağlıdır. sing-box\'de yığın seçici yoktur. Hiçbir yığın her ağda daha iyi performansı garanti etmez. Bir yığın seçin ve ağınızda denemek için Uygula ve yeniden bağlan\'ı seçin.\n\n## Ayarları uygulama\n\nBir sunucu seçildiğinde otomatik olarak yeniden bağlanır. Mod, motor, DNS ve kural ayarları anında kaydedilir; etkin bir bağlantı sırasında bunları kullanmak için Uygula ve yeniden bağlan\'a tıklayın. Motorun yeniden başlatılması indirme ve çağrıların kesintiye uğramasına neden olabilir. Tekrarlanan tıklamalar paralel bağlantıları başlatmaz; bağlantıyı kesmek geçişi sonlandırır ve bağlantıyı serbest bırakır.\n\nYalnızca VPN aracılığıyla İnternet, bir tünel kapandığında doğrudan trafiği engeller. Tüm makineyi etkiler. Açık bir bağlantı kesilmesi Sora\'nin kurallarını kaldırır. Temizleme işlemi bitmezse bağlantıyı kesmeyi ve günlüğü açmayı yeniden deneyin.\n\n## Proje dokümantasyonu\n\n- [sing-box-lx: yapılandırma ve destek](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box belgeleri](https://sing-box.sagernet.org/)\n- [Xray belgeleri](https://xtls.github.io/)\n- [mihomo belgeleri](https://wiki.metacubex.one/)\n- [zapret: çalışma ve sınırlamalar](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Sunucuları kontrol edin';

  @override
  String get extensions => 'Uzantılar';
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
  String get extErrAuthorKeyChanged => 'This update is signed with a different author key than the installed version, so it was blocked. If you trust the new key, uninstall the extension and install it again explicitly.';
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
  String get extConflictsIntro => 'These extensions want the same thing. Choose which one wins — the other stays installed. When the contested capability is wired into the engine, only the winner will run.';
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
  String get extConflictNote => 'Your choice is saved on this device and will be applied once the engine supports these capabilities.';
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
  String get extPermBackgroundDetail => 'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings. Background execution is not available in this version of Sora yet.';
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
  String get extPermNetworkDetail => 'Fetches data from the internet. Only the hosts below are allowed — everything else is blocked. Network fetch is not available in this version of Sora yet.';
  @override
  String get extBgTitle => 'Background task';
  @override
  String get extBgEnabled => 'Run in the background';
  @override
  String get extBgInterval => 'Run every';
  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minutes',
      one: '# minute',
    );
    return _temp0;
  }
  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours',
      one: '# hour',
    );
    return _temp0;
  }
  @override
  String get extBgNote => 'Background execution is not available in this version of Sora. Your schedule is saved and will apply automatically once the background runtime ships. The shortest interval is 15 minutes.';
  @override
  String get extBgDisabledNote => 'Enable the extension to manage its background task.';
  @override
  String get extBgRuntimeBadge => 'Not available yet';
  @override
  String get extCapNetwork => 'Network access';
  @override
  String extCapNetworkHosts(String hosts) {
    return 'Network: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Dosyaya $name';
  }

  @override
  String get diagnosticHttp => 'HTTP teşhisi';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Henüz kayıtlı istek yok. Önce bir hız testi web sitesi açın.';

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
  String get dnsLeakCheckEncryptedDns => 'OS encrypted DNS';
  @override
  String get dnsLeakCheckDnsSpoof => 'DNS answer spoofing';
  @override
  String get dnsLeakFixReviewEncryptedDns => 'Check which encrypted DNS endpoints your system uses outside the tunnel.';
  @override
  String get dnsLeakFixUseEncryptedDns => 'Use encrypted DNS (DoT or DoH) for the tunnel so resolvers cannot forge answers.';
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
  String get autoSwitchOnDegradeDetail => 'If the selected server slows down a lot or stops answering, Sora switches to the best measured one — at most once every 10 minutes.';
  @override
  String get tunStackMixed => 'Mixed';
  @override
  String get tunStackSystem => 'System';

  @override
  String get censorTitle => 'Blocking diagnostics';

  @override
  String get censorHistory => 'Check history';

  @override
  String get censorEmpty => 'No checks yet. If a connection fails, the detector will check whether your provider is blocking it.';

  @override
  String get censorExplainer => 'This is not an app error: your provider seems to be limiting the connection. Masking changes how the app connects and often helps.';

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
  String get leakTestIntro => 'Probes whether traffic can leave the device outside the tunnel: direct DNS and ICMP, IPv6 egress, and the system resolvers. Run it while connected.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# leaks found',
      one: '# leak found',
    );
    return _temp0;
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
  String smartPickReason(String ping, String speed) {
    return 'Picked by smart mode: ping $ping, speed $speed';
  }

  @override
  String serverReliability(int pct) {
    return 'Reliability $pct%';
  }
}
