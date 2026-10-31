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
  String get connEmpty => 'Bağlantı yok';

  @override
  String appVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get notInstalled => 'Kurulu değil';

  @override
  String get sourceCode => 'Kaynak kodu';

  @override
  String get reportProblem => 'Sorun bildir';

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
  String get errAuth => 'Sora hizmetine erişim reddedildi';

  @override
  String get errVersion => 'Sora uygulamasının ve hizmetinin sürümleri farklı';

  @override
  String get errBusy => 'Önceki komut hâlâ çalışıyor';

  @override
  String get errEngineMissing => 'Bu sunucu için gereken motor bulunamadı';

  @override
  String get errEngineStart => 'Motor başlatılamadı';

  @override
  String get errEngineStopped => 'Motor durdu';

  @override
  String get errTunnel => 'Bu VPN modu kullanılamıyor';

  @override
  String get errTimeout => 'Sunucu zamanında yanıt vermedi';

  @override
  String get errFirewall => 'VPN dışındaki internet erişimi engellenemedi';

  @override
  String get errSubFetch => 'Abonelik indirilemedi';

  @override
  String get deviceIdentity => 'Cihaz kimliği';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Kimliği sıfırla';

  @override
  String get deviceIdentityResetConfirm => 'Cihaz kimliği sıfırlansın mı?';

  @override
  String get errSubDeviceLimit => 'Cihaz sınırına ulaşıldı';

  @override
  String get errSubDeviceRequired => 'Sağlayıcı bir cihaz kimliği istiyor';

  @override
  String get errSubFormat => 'Abonelik biçimi tanınmadı';

  @override
  String get errSubEmpty => 'Abonelikte sunucu yok';

  @override
  String get errSubDuplicate => 'Bu abonelik zaten eklenmiş';

  @override
  String get errSubLimit => 'Abonelik sınırına ulaşıldı';

  @override
  String get errSubScheme => 'Desteklenmeyen abonelik bağlantısı şeması';

  @override
  String get errSecretStore => 'Sora depolama alanı hasarlı veya erişilemiyor';

  @override
  String get errNoServers => 'Bağlanılabilecek sunucu yok';

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
  String get themeSystem => 'Sistemdeki gibi';

  @override
  String get themeLight => 'Işık';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistemdeki gibi';

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
  String get splitPos => 'Bölünmüş konumlar';

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
      other: 'abonelik $days gün içinde sona eriyor',
      one: 'abonelik $days gününde sona eriyor',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sunucuları, en hızlısı',
      one: '$count sunucusu, en hızlısı',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mod';

  @override
  String get tunnelProxy => 'System proxy';

  @override
  String get proxyAddress => 'Proxy adresi';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get launchAtLogin => 'Sistemle başlayın';

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
  String get importSealed => 'Bu bağlantı Happ için şifrelenmiştir ve onu yalnızca Happ okuyabilir';

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
  String get notificationsEmpty => 'Bildirim yok';

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
  String get programsEmpty => 'Hiçbir uygulama bulunamadı';

  @override
  String get selectExe => 'Bir .exe dosyası seçin';

  @override
  String get speedtest => 'Hız';

  @override
  String get speedtestSearch => 'Bir hizmet bulun';

  @override
  String get speedtestEmpty => 'Eşleşme yok';

  @override
  String get speedtestBackToList => 'Hizmetlere geri dön';

  @override
  String get speedtestOpenBrowser => 'Tarayıcıda aç';

  @override
  String get speedtestUnavailable => 'Katıştırılmış tarayıcı başlatılamadı';

  @override
  String get speedtestPageFailed => 'Sayfa yüklenemedi';

  @override
  String get speedtestExternalFailed => 'Sistem tarayıcısı açılamadı';

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
  String get updateDropWarning => 'Güncellemek için bağlantı kesilsin mi?';

  @override
  String get updateWaitConnection => 'Bağlantı hazır değil';

  @override
  String get updateDownloading => 'Dosyalar indiriliyor ve doğrulanıyor...';

  @override
  String get updateInstalling => 'Güncelleme hazırlanıyor veya yönetici kimlik doğrulaması bekleniyor...';

  @override
  String get updateNetworkError => 'Güncelleme indirilemedi';

  @override
  String get updateReleaseError => 'Sürüm verileri veya gerekli dosyalar eksik veya geçersiz.';

  @override
  String get updateChecksumError => 'İndirme SHA256SUMS ile eşleşmiyor';

  @override
  String get updateInstallError => 'Güncelleme tamamlanmadı';

  @override
  String get updateUnsupported => 'Bu yürütülebilir dosya, desteklenen bir Sora paket çiftine ait değil';

  @override
  String get updateManual =>
      'Her iki doğrulanmış paketi de yüklemek için bu komutu bir terminalde çalıştırın, ardından Sora\'yi yeniden açın. Dosyalar indirme dizininde kalır. VPN bağlantısı kesilecek.';

  @override
  String get updateVersionRevoked => 'Geliştirici bu sürümü geri çekti';

  @override
  String get updateRolloutPending =>
      'Daha yeni bir sürüm yavaş yavaş kullanıma sunuluyor ve size otomatik olarak sunulacak.';

  @override
  String updateRollbacking(String version) {
    return '$version sürümüne geri dönülüyor...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version güncellemesi durum denetimini geçemediği için Sora, $fromVersion sürümüne geri alındı.';
  }

  @override
  String get updateRollbackError => 'Otomatik geri alma başarısız oldu';

  @override
  String get updateRollbackCacheError =>
      'Geçerli sürümün doğrulanmış geri alma kopyası hazırlanamadığından güncelleme yüklenmedi.';

  @override
  String get updateCopyCommand => 'Komutu kopyala';

  @override
  String get updateChecksDisabled => 'Otomatik kontroller Ayarlar\'da devre dışı bırakıldı.';

  @override
  String get updateInstalled => 'Güncelleme yüklendi';

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
  String get collapseServers => 'Sunucuları daralt';

  @override
  String get expandServers => 'Sunucuları genişlet';

  @override
  String get hideDescription => 'Açıklamayı gizle';

  @override
  String get showDescription => 'Açıklamayı göster';

  @override
  String get errEngineUnsupported => 'Seçilen motor bu profili veya ayarları desteklemiyor';

  @override
  String get errRestore => 'Bağlantı temizliği tamamlanmadı';

  @override
  String get errSessionEnded => 'Bu oturum zaten sona erdi';

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
      'Sunucunuzun hangi motora ihtiyacı olduğundan emin değilseniz Otomatik\'i seçin. Sora bağlanmadan önce profili ve ayarları kontrol eder. Bir motor planınızın bant genişliğini artıramaz: performans sunucuya, rotaya, protokole ve ağa bağlıdır.\n\n## Modlar\n\n### Tüm trafik (TUN)\n\nSora bir sanal ağ arayüzü oluşturur ve TCP ve UDP dahil olmak üzere uygulama trafiğini bu arayüz üzerinden yönlendirir. Bu modu Telegram, oyunlar ve Discord ses için kullanın. Kurallar belirli siteleri veya programları doğrudan gönderebilir veya engelleyebilir. Ağ hizmetinin izne ve gerekli protokolü destekleyen bir sunucuya ihtiyacı vardır.\n\n### System proxy\n\nSora, yerel bir HTTP/SOCKS proxy\'sini yapılandırır. Sistem proxy ayarlarına saygı duyan uygulamalar bunu kullanır. Kendi ağ yığınına sahip uygulamalar doğrudan bağlanabilir; UDP ve sesli aramalar genellikle TUN\'a ihtiyaç duyar. Bu mod, proxy desteği olan tarayıcılara ve uygulamalara uygundur.\n\n### Sunucu yok\n\nLinux\'de Sora, HTTP/TLS isteklerini bölmek ve yeniden şekillendirmek ve bazı DPI kontrollerini atlamak için [zapret](https://github.com/bol-van/zapret) kullanır. IP\'niz aynı kalır ve bağlantılar doğrudan web sitesine gider. Sonuçlar sağlayıcınıza ve engelleme yöntemine bağlıdır.\n\nMevcut entegrasyon HTTP için tpws ve TCP üzerinden TLS kullanıyor. IP engellemeyi veya aktarma UDP\'sini atlamaz ve Telegram\'nin MTProto bağlantılarını garanti edemez. Discord ses, Telegram aramaları ve bu tür kısıtlamalar için TUN\'lu bir VPN sunucusu kullanın.\n\n## Motorlar\n\n### Otomatik\n\nSora, bağlantı planının tamamını destekleyen kurulu bir motoru seçer: sunucu protokolleri, aktarımlar, gruplar, parçalanma ve mod. Uyumsuz bir manuel seçim, mevcut bağlantı durdurulmadan önce reddedilir. Otomatik veya başka bir motoru seçin ve ayarları tekrar uygulayın.\n\n### sing-box\n\nYeni Sora paketleri, istemci tarafı XHTTP ve VLESS Encryption\'yi ekleyen [sing-box](https://github.com/SagerNet/sing-box) çatalı olan [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)\'yi içerir. Sora, yapıyı ve yeteneklerini tanır. XHTTP\'siz bir yukarı akış yapısı bu yeteneği yalnızca adından kazanmaz.\n\nDesteklenen protokoller arasında VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard ve AmneziaWG 1.x/2.x parametreleri bulunur Sora içe aktarabilir. Tam Xray JSON profilleri Xray gerektirir. Yeni AWG 3.x alanları henüz içe aktarılamıyor. sing-box, bilgisayardaki diğer uygulamaların algılayabileceği, parola korumalı bir yerel kontrol bağlantı noktası kullanır.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core), VLESS, REALITY, XHTTP, VLESS Encryption ve TLS parçalanmasını destekler. Ayrıca yönlendirmelerini ve gruplarını korurken sağlayıcı Xray profillerinin tamamını çalıştırır. Bu tür profiller, davranışları değiştirilmeden otomatik olarak başka bir motora dönüştürülemez.\n\nBirlikte verilen Xray, TLS sertifika doğrulamasını devre dışı bırakan ayarı (\"allowInsecure\") kaldırdı. Otomatik, bu ayarı gerektiren sıradan sunucular için sing-box veya mihomo\'yi seçer. Xray seçildiğinde, mevcut bağlantı durdurulmadan önce uyumsuzluk manuel olarak raporlanır. Daha eski tam JSON profilleri, doğrulanabilir bir sertifikaya veya sertifika pinine sahip güncellenmiş bir sağlayıcı profiline ihtiyaç duyar.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo), sıralı geri dönüş ve yük dengeleme grupları olan XHTTP ve AmneziaWG\'yi destekler. Yedekleme sunucusuna otomatik yük devretme önemli olduğunda bunu seçin. Sora\'nin TLS parçalanma ayarı bu motorda kullanılamaz.\n\n## Sora ile uyumluluk\n\n| Özellik | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN ve TCP/UDP | Evet | Evet | Evet |\n| XHTTP | Evet | Evet | Evet |\n| VLESS Encryption | Evet | Evet | Evet |\n| Tam Xray profili | Hayır | Evet | Hayır |\n| TUIC / AnyTLS | Her ikisi de | Hayır | TUIC |\n| mieru | Hayır | Hayır | Evet |\n| NaiveProxy | Evet | Hayır | Hayır |\n| TLS parçalanması | Evet | Evet | Hayır |\n| AmneziaWG 1.x/2.x | Evet¹ | Hayır | Evet |\n| Sıralı yedek grup | Hayır | No² | Evet |\n\n¹ J1/J2/J3/Itime içeren profiller mihomo kullanır; bu alanlar asla sessizce atılmamalıdır. ² Tam Xray profillerinden oluşan bir grup için uygulama bir yedekleme profili seçer. Destek, kurulu yapıya bağlıdır; Hakkında bölümünden sürümünü kontrol edin.\n\n## TUN yığını\n\nYığın, sanal arabirim içindeki TCP ve UDP\'yi yönetir. Modlar panelinde Xray ve mihomo, gVisor, System, Mixed ve MIPS\'yi sunar. Her motor kendi tercihini kaydeder. System proxy ve Sunucusuz modları bu tercihi kullanmaz.\n\n- **Mixed**: TCP sistem yığınını kullanırken gVisor UDP\'yi yönetir. Bu, Linux üzerinde mihomo için varsayılandır. Windows üzerinde Xray ve mihomo varsayılan olarak MIPS kullanır.\n- **System**: sistem yığınını kullanır. Ağ uygulamaları sorunlarla karşılaşırsa başka bir seçeneği deneyin.\n- **gVisor**: kullanıcı alanındaki trafiği yönetir.\n- **MIPS**: mihomo\'nin kendi IP yığını, paket halindeki 1.19.32 sürümünde mevcuttur.\n\nLinux\'de Xray, varsayılan olarak yerleşik gVisor\'yi kullanır. Linux üzerindeki System, Mixed ve MIPS, TUN motoru olarak mihomo\'yi kullanır ve kimliği doğrulanmış bir yerel SOCKS bağlantısı üzerinden TCP ve UDP\'yi Xray\'ye iletir. Xray protokolü, sağlayıcı profilini ve yönlendirmeyi korur. Bu üç seçenek mihomo\'nin kurulu olmasını gerektirir. Windows üzerinde Xray, dört TUN yığınının tümü için mihomo 1.19.32 veya daha yenisini kullanır. Protokoller ve yönlendirme Xray içinde kalır. Bu birleşimde uygulama kuralları yalnızca doğrudan bağlantı ve engellemeyi destekler; Linux üzerinde bu kurallar Xray’ın yerleşik gVisor yığınını gerektirir.\n\nKöprü ikinci bir süreci yürütür. Linux üzerindeki üç boşta ölçümde, yerel Xray TUN\'dan yaklaşık 32-36 MiB daha fazla fiziksel bellek kullandı. Bu, indirme yükünü ölçmez: CPU ve bellek maliyetleri bağlantılara bağlıdır. sing-box\'de yığın seçici yoktur. Hiçbir yığın her ağda daha iyi performansı garanti etmez.\n\n## Ayarları uygulama\n\nBir sunucu seçildiğinde bağlantı otomatik olarak yeniden kurulur. Mod, motor, DNS veya kurallarda yaptığınız değişiklikler kısa bir aradan sonra otomatik yeniden bağlantıyla bir kez uygulanır; arka plan yenilemeleri VPN’i yeniden bağlamaz. Motoru yeniden başlatmak indirmeleri ve aramaları kesintiye uğratabilir.\n\nYalnızca VPN aracılığıyla İnternet, bir tünel kapandığında doğrudan trafiği engeller. Tüm makineyi etkiler. Açık bir bağlantı kesilmesi Sora\'nin kurallarını kaldırır. Temizleme işlemi bitmezse bağlantıyı kesmeyi ve günlüğü açmayı yeniden deneyin.\n\n## Proje dokümantasyonu\n\n- [sing-box-lx: yapılandırma ve destek](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box belgeleri](https://sing-box.sagernet.org/)\n- [Xray belgeleri](https://xtls.github.io/)\n- [mihomo belgeleri](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: çalışma ve sınırlamalar](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC, TCP trafiğini Jitsi, Yandex Telemost veya WB Stream görüntülü araması üzerinden taşır. Bir olcrtc:// bağlantısı veya QR kodu içe aktarın. Proxy ve TUN kiplerinde sing-box, Xray ve mihomo ile çalışır; UDP desteklenmez. Her iki uçta uyumlu OLC2 derlemeleri gerekir. Kaynak proje arşivlenmiştir.\n';

  @override
  String get probeServers => 'ping';

  @override
  String get extensions => 'Uzantılar';

  @override
  String extRatingLabel(String rating) {
    return 'Derecelendirme $rating / 5';
  }

  @override
  String extByAuthor(String author) {
    return 'yazan: $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Kurulumlar: $count';
  }

  @override
  String get extInstallOne => '1 yükleme';

  @override
  String get extSideloadWarning => 'Kendinden imzalı anahtar';

  @override
  String get extPermissionsWidened => 'Güncelleme yeni izinler istiyor:';

  @override
  String get extInstall => 'Yükle';

  @override
  String get extUpdate => 'Güncelle';

  @override
  String get extCancel => 'İptal';

  @override
  String get extConfirm => 'Onayla';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'Yüklü uzantılar';

  @override
  String get extSearchHint => 'Uzantı ara';

  @override
  String get extCatAll => 'Hepsi';

  @override
  String get extCatTools => 'Araçlar';

  @override
  String get extCatThemes => 'Temalar';

  @override
  String get extCatAutomation => 'Otomasyon';

  @override
  String get extCatStats => 'İstatistikler';

  @override
  String get extCatNetwork => 'Ağ';

  @override
  String get extSortBy => 'Sıralama ölçütü';

  @override
  String get extSortPopular => 'En popüler';

  @override
  String get extSortRating => 'En yüksek puan';

  @override
  String get extSortName => 'Ad';

  @override
  String get extCatalogError => 'Katalog yüklenemedi';

  @override
  String get extRetry => 'Tekrar dene';

  @override
  String get extEmptySearch => 'Hiçbir şey bulunamadı';

  @override
  String get extEmptyInstalled => 'Henüz yüklü uzantı yok';

  @override
  String get extInstallFromFile => 'Dosyadan yükle';

  @override
  String get extInstallFromUrl => 'URL adresinden yükle';

  @override
  String get extDownload => 'İndir';

  @override
  String get extDownloading => 'İndiriliyor…';

  @override
  String get extVerifying => 'Doğrulanıyor…';

  @override
  String get extInstalling => 'Yükleniyor…';

  @override
  String get extErrSignature => 'İmza kontrolü başarısız oldu';

  @override
  String get extErrManifest => 'Uzantının bildirimi geçersiz.';

  @override
  String get extErrNetwork => 'Ağ hatası';

  @override
  String get extErrHash => 'İndirme işlemi katalogla eşleşmiyor';

  @override
  String extErrMinApp(String version) {
    return 'Bu uzantının $version veya daha yeni bir uygulama sürümüne ihtiyacı var.';
  }

  @override
  String get extErrHttpsOnly => 'Yalnızca https:// bağlantılarına izin verilir';

  @override
  String get extErrGeneric => 'Bir şeyler ters gitti';

  @override
  String get extErrAuthorKeyChanged =>
      'Bu güncelleme, yüklü sürümden farklı bir yazar anahtarıyla imzalandığından engellendi';

  @override
  String get extDisabled => 'Devre dışı';

  @override
  String extToggleEnabled(String name) {
    return 'Etkinleştir $name';
  }

  @override
  String get extSearchInstalled => 'Yüklü uzantılarda ara';

  @override
  String get extUpdateAll => 'Tümünü güncelle';

  @override
  String extUpdatesAvailable(int count) {
    return '$count güncellemeleri mevcut';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count güncellendi';
  }

  @override
  String get extRiskNormal => 'Normal';

  @override
  String get extRiskSensitive => 'Hassas';

  @override
  String get extRiskDangerous => 'Yüksek risk';

  @override
  String get extPermissionsRemoved => 'Artık talep edilmiyor:';

  @override
  String get extUpdateFailedKept => 'Önceki sürüm hâlâ yüklü.';

  @override
  String get extConflictsTitle => 'Uzantı çakışmaları';

  @override
  String get extConflictTheme => 'Uygulama teması';

  @override
  String get extConflictNetHooks => 'Ağ kancaları';

  @override
  String extConflictWinner(String name) {
    return '$name kazanır';
  }

  @override
  String extConflictsCount(int count) {
    return 'Uzantı çakışmaları: $count';
  }

  @override
  String get extConflictsResolve => 'Çakışmaları çözme';

  @override
  String extVersionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String get extPermissionsTitle => 'İzinler';

  @override
  String get extNoPermissions => 'Özel izin yok.';

  @override
  String get extSettings => 'Ayarlar';

  @override
  String get extSaveSettings => 'Ayarları kaydet';

  @override
  String extUpdateTo(String version) {
    return '$version\'ye yükseltme';
  }

  @override
  String get extEnabled => 'Etkin';

  @override
  String extRollbackTo(String version) {
    return '$version\'e geri dönme';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version sürümüne geri dönülsün mü?';
  }

  @override
  String get extUninstall => 'Kaldırma';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” ve ayarları kaldırılsın mı?';
  }

  @override
  String get extPanelUnavailable => 'Eklenti paneli kullanılamıyor.';

  @override
  String get extPermConnectionsRead => 'Etkin bağlantıların listesine bakın';

  @override
  String get extPermServersRead => 'Sunucularınızın listesini görün';

  @override
  String get extPermSettingsRead => 'Uygulama ayarlarını oku';

  @override
  String get extPermSettingsWrite => 'Uygulama ayarlarını değiştir';

  @override
  String get extPermNotifications => 'Bildirimleri göster';

  @override
  String get extPermTray => 'Tepsi menüsüne öğe ekleme';

  @override
  String get extPermUiPanel => 'Panelleri uygulama içinde göster';

  @override
  String get extPermThemeApply => 'Temaları uygula';

  @override
  String get extPermRoutingRules => 'Yönlendirme kuralları ekleyin';

  @override
  String get extPermNetHooks => 'Ağ yoluna entegre edin';

  @override
  String get extPermNetFetch => 'İzin verilenler listesinden URL isteğinde bulunun';

  @override
  String get extPermBackground => 'Arka plan görevlerini çalıştır';

  @override
  String get extPermNotYetActive => 'Devre dışı';

  @override
  String get extCapBackground => 'Arka planda çalışır';

  @override
  String get extCapNetHook => 'Engel aşma ve ağ kancaları';

  @override
  String get extCapPanel => 'Arayüz panelleri';

  @override
  String get extCapRouting => 'Yönlendirme kuralları';

  @override
  String get extCapTheme => 'Temalar';

  @override
  String get extCapWidget => 'Widget\'lar';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Değişiklik Günlüğü';

  @override
  String get extImageFailed => 'Resim yüklenemedi';

  @override
  String get extScreenshots => 'Ekran Görüntüleri';

  @override
  String get extSortRelevance => 'Alaka düzeyi';

  @override
  String get extBgTitle => 'Arka plan görevi';

  @override
  String get extBgEnabled => 'Arka planda çalıştır';

  @override
  String get extBgInterval => 'Çalıştırma aralığı';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count dakika', one: '$count dakika');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count saat', one: '$count saat');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Ağ erişimi';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Ağ: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Dosyaya $name';
  }

  @override
  String get diagnosticHttp => 'HTTP teşhisi';

  @override
  String get diagnosticNoData => 'Henüz kayıtlı istek yok';

  @override
  String get qrShareTitle => 'QR kodunu paylaş';

  @override
  String get qrScanTitle => 'QR kodunu tarayın';

  @override
  String get qrCopyLink => 'Bağlantıyı kopyala';

  @override
  String get qrWarning => 'Kodu yalnızca güvendiğiniz kişilerle paylaşın.';

  @override
  String get qrFromClipboard => 'Panodan yapıştır';

  @override
  String get qrNoCode => 'Bu görselde QR kod bulunamadı.';

  @override
  String get qrInvalid => 'Bu QR kodu geçerli bir bağlantı içermiyor.';

  @override
  String get qrScan => 'Tara QR';

  @override
  String get qrFromImage => 'Görsel aç';

  @override
  String get connGroupByProcess => 'İşleme göre gruplandırma';

  @override
  String get connListView => 'Liste';

  @override
  String get connCopyHost => 'Ana bilgisayarı kopyala';

  @override
  String get connAddRule => 'Kural ekle';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count bağlantı', one: '$count bağlantı');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Ön Ayar';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Özel';

  @override
  String get dnsCheck => 'Veri sızıntılarını kontrol edin';

  @override
  String get dnsChecking => 'Kontrol ediliyor...';

  @override
  String get dnsNoLeak => 'Sızıntı bulunamadı';

  @override
  String get dnsLeakFound => 'Sızıntı algılandı';

  @override
  String get dnsLastCheck => 'Son kontrol';

  @override
  String get dnsNeverChecked => 'Henüz test edilmedi';

  @override
  String get dnsLeakCheckTunnelDns => 'Tünelin DNS çözümleyicileri';

  @override
  String get dnsLeakCheckSystemResolvers => 'Sistem çözümleyicileri';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Ağ kilidi ile DNS koruması';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Yukarıdaki DNS ayarlarında tünel için DNS yapılandırın.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Sisteminizin tünel dışında hangi çözümleyicileri kullanacağını kontrol edin.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS trafiğinin tünelde kalması için ağ kilidini etkinleştirin.';

  @override
  String get dnsLeakCheckEncryptedDns => 'İşletim sisteminin şifreli DNS\'i';

  @override
  String get dnsLeakCheckDnsSpoof => 'Sahte DNS yanıtları';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Sisteminizin tünel dışında hangi şifrelenmiş DNS uç noktalarını kullandığını kontrol edin.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Çözümleyicilerin yanıtları taklit edememesi için tünel için şifrelenmiş DNS (DoT veya DoH) kullanın.';

  @override
  String get dnsCheckNeedsConnection => 'Önce VPN\'ye bağlanın, ardından sızıntı olup olmadığını kontrol edin.';

  @override
  String get dnsExpected => 'Beklenen';

  @override
  String get dnsActual => 'Gözlemlendi';

  @override
  String get measureSpeed => 'Hızı ölç';

  @override
  String get benchmarkStale => 'güncel değil';

  @override
  String get autoSelectMode => 'Sunucuyu otomatik seç';

  @override
  String get autoSelectPing => 'En hızlı ping';

  @override
  String get autoSelectSpeed => 'En yüksek hız';

  @override
  String get autoSelectSmart => 'Akıllı seçim';

  @override
  String get coreWatchUnstable => 'Çekirdekle bağlantı kararsız';

  @override
  String get watchReconnect => 'Yeniden bağlan';

  @override
  String get crashRestoreTitle => 'Son oturum kesintiye uğradı';

  @override
  String get restoreOnCrash => 'Bir kilitlenme sonrasında oturumu geri yükleme';

  @override
  String get crashRestore => 'Geri Yükle';

  @override
  String get crashDismiss => 'Şimdi değil';

  @override
  String get overrideTitle => 'Düzenlemelerim';

  @override
  String get overrideEdit => 'Sunucuları düzenle';

  @override
  String get overrideHide => 'Gizle';

  @override
  String get overrideUnhide => 'Göster';

  @override
  String get overrideClear => 'Düzenlemeleri sıfırla';

  @override
  String get overrideEmpty => 'Henüz düzenleme yok';

  @override
  String get overrideCustomRules => 'Kendi kuralları';

  @override
  String get errBenchmarkUnsupported => 'Hız ölçümü daha yeni bir çekirdek gerektiriyor';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total\'dan $done ölçümü…';
  }

  @override
  String get profiles => 'Ağ profilleri';

  @override
  String get profilesEmpty => 'Henüz profil yok';

  @override
  String get profileAdd => 'Profil ekle';

  @override
  String get profileName => 'Profil adı';

  @override
  String get profileSsids => 'Wi-Fi ağları (SSID)';

  @override
  String get profileGateways => 'Ağ ağ geçitleri';

  @override
  String get profileAsns => 'AS sayılar';

  @override
  String get profileAutoApply => 'Otomatik uygula';

  @override
  String get profileSnapshot => 'Geçerli ayarları hatırla';

  @override
  String get profileSnapshotDone => 'Profile kaydedilen mevcut ayarlar';

  @override
  String get profileDelete => 'Profili sil';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" profili silinsin mi?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '\"$name\" profili uygulansın mı?';
  }

  @override
  String get profileApply => 'Uygula';

  @override
  String profileApplied(Object name) {
    return '“$name” profili uygulandı';
  }

  @override
  String get profileUndo => 'İptal';

  @override
  String get profileActive => 'Etkin';

  @override
  String networkNow(Object info) {
    return 'Şimdi: $info';
  }

  @override
  String get networkUnknown => 'Ağ bilgisi mevcut değil';

  @override
  String get profileNoTriggers => 'Profil koşulu yok';

  @override
  String get chains => 'Proxy zincirleri';

  @override
  String get chainsEmpty => 'Henüz zincir yok';

  @override
  String get chainAdd => 'Yeni zincir';

  @override
  String get chainName => 'Zincir adı';

  @override
  String get chainTooFew => 'Bir zincir için en az iki sunucu gerekir';

  @override
  String get chainTooMany => 'Bir zincirde en fazla üç sunucu olabilir';

  @override
  String get chainEstimate => 'Tahmini gecikme';

  @override
  String get chainSave => 'Zinciri kaydet';

  @override
  String get chainDelete => 'Zinciri sil';

  @override
  String chainDeleteConfirm(Object name) {
    return '\"$name\" zinciri silinsin mi?';
  }

  @override
  String get chainUnsupported => 'Seçilen motor zincirleri desteklemiyor';

  @override
  String get chainHopMissing => 'Zincirdeki bir sunucu artık kullanılamıyor';

  @override
  String chainHop(Object n) {
    return 'Atlama $n';
  }

  @override
  String get chainEntry => 'Giriş';

  @override
  String get chainExit => 'Çıkış';

  @override
  String get sync => 'Cihaz senkronizasyonu';

  @override
  String get syncDevices => 'Cihazlarım';

  @override
  String get syncEmpty => 'Eşleştirilmiş cihaz yok';

  @override
  String get syncPair => 'Cihazı eşleştir';

  @override
  String get syncShowCode => 'Kodumu göster';

  @override
  String get syncScanCode => 'Tarama kodu';

  @override
  String get syncRevoke => 'Çekilme';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" iptal edilsin mi?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Son senkronizasyon: $time';
  }

  @override
  String get syncNever => 'Hiçbir zaman';

  @override
  String get syncPaired => 'Cihaz eşlendi';

  @override
  String get syncPairingTitle => 'Bu cihazla eşleştir';

  @override
  String get syncWaiting => 'Diğer cihaz bekleniyor…';

  @override
  String get zapretWithVpn => 'Doğrudan ağ trafiği için DPI filtrelemeyi atlayın';

  @override
  String get chainDuplicate => 'Zincirde aynı sunucu birden fazla kez kullanılıyor';

  @override
  String get edit => 'Düzenle';

  @override
  String get remove => 'Kaldır';

  @override
  String get autoSwitchOnDegrade => 'Bozulma durumunda otomatik geçiş';

  @override
  String get tunStackMixed => 'Karışık';

  @override
  String get tunStackSystem => 'Sistem';

  @override
  String get customServerAdd => 'Özel sunucu ekle';

  @override
  String get customServers => 'Sunucularım';

  @override
  String get customServerName => 'Ad';

  @override
  String get customServerNameRequired => 'Ad belirtilmedi';

  @override
  String get customServerAddress => 'Adres';

  @override
  String get customServerAddressRequired => 'Adres belirtilmedi';

  @override
  String get customServerAddressInvalid => 'Geçersiz adres';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Geçersiz bağlantı noktası';

  @override
  String get customServerProtocol => 'Protokolü';

  @override
  String get customServerCredentials => 'Giriş bilgileri';

  @override
  String get customServerShowSecret => 'Sırrı göster';

  @override
  String get customServerHideSecret => 'Sırrı gizle';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” sunucusu silinsin mi?';
  }

  @override
  String get leakTestTitle => 'Veri sızıntılarını test edin';

  @override
  String get leakTestRun => 'Kontrol et';

  @override
  String get leakTestCancel => 'İptal';

  @override
  String get leakTestNeedsConnection => 'Veri sızıntılarını test etmek için VPN\'ye bağlanın.';

  @override
  String leakTestProgress(int count) {
    return 'Tamamlanan testler: $count';
  }

  @override
  String get leakTestAllClear => 'Sızıntı bulunamadı';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sızıntı bulundu',
      one: '$count sızıntı bulundu',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Düzelt';

  @override
  String get leakTestFixedNote => 'Ağ kilidi etkin. Doğrulamak için testi yeniden çalıştırın.';

  @override
  String get leakTestCheckDirectDns => 'Doğrudan DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP yankı';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Sistem çözümleyicileri';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tünel bağlantısı';

  @override
  String get leakTestCheckTunnelDns => 'DNS tünelden';

  @override
  String get noticeDegraded => 'Sunucu yavaşladı. Sora ölçüm sırasında bulunan en iyi sunucuya geçti.';

  @override
  String get obfs => 'Trafiği gizleme';

  @override
  String get syncCodeExpired => 'Kodun süresi doldu';

  @override
  String get syncDaemonFailed => 'Senkronizasyon hizmeti başlatılamadı';

  @override
  String get syncDaemonMissing => 'sora-sync bileşeni bulunamadı';

  @override
  String get syncDaemonStarting => 'Senkronizasyon hizmeti başlatılıyor…';

  @override
  String get syncErrAuth => 'Eşitleme hizmeti erişim belirtecini reddetti';

  @override
  String get syncErrNotFound => 'Cihaz artık eşlenmemiş';

  @override
  String get syncErrPairingActive => 'Bir eşleştirme oturumu zaten açık';

  @override
  String get syncErrUnreachable => 'Diğer cihaz yanıt vermedi';

  @override
  String get syncError => 'Senkronizasyon hatası';

  @override
  String syncExpiresIn(String duration) {
    return 'Kodun süresi $duration sonra dolar';
  }

  @override
  String get syncJoining => 'Cihazla eşleştiriliyor…';

  @override
  String get syncNewCode => 'Yeni kod';

  @override
  String syncPairedWith(String name) {
    return '$name ile eşlendi';
  }

  @override
  String get syncRetry => 'Tekrarla';

  @override
  String get syncStopShowing => 'Kodu gizle';

  @override
  String get syncSyncNow => 'Şimdi eşitle';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Alındı $pulled, gönderildi $pushed';
  }

  @override
  String get syncResultTitle => 'Senkronizasyon sonucu';

  @override
  String get syncPulled => 'Alındı';

  @override
  String get syncPushed => 'Gönderildi';

  @override
  String get syncNoChanges => 'Hiçbir değişiklik algılanmadı';

  @override
  String get syncDocKindSubscriptions => 'Abonelikler';

  @override
  String get syncDocKindSettings => 'Uygulama ayarları';

  @override
  String get syncDocKindOverrides => 'Abonelik özelleştirmeleri';

  @override
  String get syncDocKindProfiles => 'Ağ profilleri';

  @override
  String get syncDocKindChains => 'Proxy zincirleri';

  @override
  String syncFrom(String name) {
    return '$name cihazından';
  }

  @override
  String get syncThisDevice => 'Bu cihaz';

  @override
  String get syncUnavailableAndroid => 'Android\'de eşitleme kullanılamıyor';

  @override
  String get diagnosticPackets => 'Paket yakalama';

  @override
  String get diagnosticEvents => 'Windows etkinlikleri';

  @override
  String get diagnosticCapture => '10 saniye boyunca çekim yapın';

  @override
  String get diagnosticRequiresTun => 'Paket yakalama, etkin bir Sora TUN bağlantısına ihtiyaç duyar.';

  @override
  String get diagnosticUnavailable => 'Bu teşhis bu platformda kullanılamıyor.';

  @override
  String get extErrRevoked => 'Sora ekibi bu uzantı sürümünü güvensiz ya da bozuk olduğu için geri çekti.';

  @override
  String get extErrRevocationsExpired => 'İptal listesi yenilenene kadar yükleme engellendi.';

  @override
  String extRevokedDisabled(String names) {
    return 'Geri çekilen uzantılar kapatıldı: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Özel anahtar';

  @override
  String get customServerWgAddresses => 'Arayüz adresleri';

  @override
  String get customServerWgPeerKey => 'Sunucu ortak anahtarı';

  @override
  String get customServerWgPresharedKey => 'Ön paylaşımlı anahtar';

  @override
  String get customServerWgAllowedIps => 'İzin verilen IP’ler';

  @override
  String get customServerWgKeepalive => 'Keepalive, saniye';

  @override
  String get customServerWgKeyInvalid => 'Geçersiz WireGuard anahtarı';

  @override
  String get customServerWgCidrInvalid => 'Geçersiz CIDR öneki';

  @override
  String get customServerWgKeepaliveInvalid => 'Geçersiz keepalive aralığı';

  @override
  String get strictKillSwitch => 'Katı ağ kilidi';

  @override
  String get strictKillSwitchWarning => 'Çıkıştan sonra VPN dışındaki trafik engellensin mi?';

  @override
  String get extWorkerFailed => 'Uzantının arka plan görevi başarısız oldu';

  @override
  String get extAssetRejected => 'Uzantı dosyası okunması zor renkler veya geçersiz kurallar içeriyor';

  @override
  String get extVerifiedSora => 'Sora tarafından doğrulandı';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Aç';

  @override
  String get customServerOwn => 'Kendi sunucun';

  @override
  String get customServerPaste => 'Bağlantı yapıştır';

  @override
  String get customServerUser => 'Kullanıcı adı';

  @override
  String get customServerPassword => 'Parola';

  @override
  String get customServerSecretRequired => 'Değer belirtilmedi';

  @override
  String get customServerLinkInvalid => 'Geçersiz sunucu bağlantısı';

  @override
  String get errInternal => 'Sora iç hatası';

  @override
  String get errTls => 'Sunucu sertifikası reddedildi';

  @override
  String get errFileAccess => 'Dosyaya erişilemiyor';

  @override
  String get errDataLimit => 'Çok fazla veri';

  @override
  String get errCredentials => 'Kayıtlı kimlik bilgileri eksik';

  @override
  String subscriptionStale(String time) {
    return 'Son güncelleme: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Henüz güncellenmedi';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Sunucu HTTP $status kodunu döndürdü',
      zero: 'Sunucu isteği reddetti',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Sunucu ayarları eksik veya desteklenmiyor';

  @override
  String get errServerIds => 'İki sunucu aynı kimliği kullanıyor';

  @override
  String get errRoutingGroup => 'Yönlendirme eksik sunuculara veya bozuk bir gruba başvuruyor';

  @override
  String get errConnections => 'Bağlantı listesi kullanılamıyor';

  @override
  String get errLogs => 'Bu hizmet günlük tutmuyor';

  @override
  String get errDiagnostics => 'Tanılama toplanamadı';

  @override
  String get errMissingItem => 'İstenen öğe artık yok';

  @override
  String get errInvalidRequest => 'İstek geçersiz değerler içeriyor';

  @override
  String get errProxyLogin => 'Sistem vekili bu girişi desteklemiyor';

  @override
  String get errLogFilter => 'Günlük filtresi geçersiz';

  @override
  String get errSubRedirect => 'Sunucu güvenli olmayan bir adrese yönlendirdi';

  @override
  String get errProxySetup => 'Sistem vekili yapılandırılamadı';

  @override
  String get notificationsToday => 'Bugün';

  @override
  String get notificationsYesterday => 'Dün';

  @override
  String get notificationsMarkRead => 'Tümünü okundu işaretle';

  @override
  String get notificationsUnread => 'Okunmadı';

  @override
  String get desktopNotifications => 'Masaüstü bildirimleri';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Abonelik güncelleme aralığı geçersiz';

  @override
  String get errRule => 'Bir yönlendirme kuralı geçersiz';

  @override
  String get errDns => 'DNS ayarları geçersiz';

  @override
  String get errEndpoint => 'Test edilecek sunucunun adresi geçersiz';

  @override
  String get errCancelled => 'İstek iptal edildi';

  @override
  String get customServerOptions => 'Bağlantı ayarları';

  @override
  String get customServerTransport => 'Taşıma';

  @override
  String get customServerSecurity => 'Güvenlik';

  @override
  String get customServerCipher => 'Şifreleme';

  @override
  String get customServerWgInterface => 'Arayüz';

  @override
  String get customServerWgPeer => 'Eş';

  @override
  String extAvailableOn(String platforms) {
    return 'Kullanılabilir platformlar: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Tüm uygulamaların TCP trafiği değiştirilsin mi?';

  @override
  String get winwsRequirements => 'Bu VPN modu kullanılamıyor';

  @override
  String get emptyServersTitle => 'Sunucu veya abonelik ekleyin';

  @override
  String get emptyServersBody =>
      'VPN hizmetinizden abonelik bağlantısını yapıştırın, kendi sunucunuzu ekleyin veya bir QR kodu tarayın.';

  @override
  String get qrShort => 'QR kodu';

  @override
  String get extAboutHello => 'Örnek panel: etkin bağlantıları gösterir ve deneme bildirimi gönderir.';

  @override
  String get extAboutZapret =>
      'VPN olmadan engelleri aşar: sağlayıcı siteyi tanımasın diye bağlantıların başını değiştirir.';

  @override
  String get extAboutByedpi => 'Yerel ByeDPI proxy\'si ile VPN olmadan engelleri aşar.';

  @override
  String get modeTunHint => 'Bilgisayarın tüm trafiği VPN\'den geçer';

  @override
  String get modeProxyHint => 'Yalnızca sistem proxy\'sini kullanan tarayıcılar ve uygulamalar';

  @override
  String get modeBypassHint => 'VPN sunucusu olmadan engelleri aşma';

  @override
  String get modeExtensionHint => 'Bir uzantıdan engel aşma';

  @override
  String get engineInfo =>
      'Çekirdek sunucuyla bağlantıyı kurar.\n\nOtomatik: Sora, sunucunun protokolünü destekleyen çekirdeği kendisi seçer.\nsing-box: hızlı ve çok yönlü.\nXray: REALITY ve XHTTP ile VLESS için en iyisi.\nmihomo: Clash abonelikleri ve esnek kurallar.\n\nÇekirdeği yalnızca bir sunucu Otomatik ile bağlanmıyorsa değiştirin.';

  @override
  String get tunStackInfo =>
      'Trafiğin sistemden VPN\'e nasıl geçtiği.\n\nSistem: en hızlısı, işletim sisteminin ağ yığınını kullanır.\ngVisor: kendi yığını, çoğu uygulamayla uyumlu.\nKarma: TCP sistemden, UDP gVisor\'dan.\n\nSiteler veya oyunlar sorun çıkarırsa başka bir yığın deneyin.';

  @override
  String get protection => 'Koruma';

  @override
  String get killSwitchInfo =>
      'VPN koparsa Sora, trafik tünelin dışına çıkmasın diye interneti engeller. VPN yeniden bağlanınca veya kapatılınca erişim geri gelir.';

  @override
  String get strictKillSwitchInfo =>
      'Engel, Sora\'dan çıktıktan ve yeniden başlattıktan sonra da siz burada kapatana kadar sürer.';

  @override
  String get zapretWithVpnInfo => 'Kurallarınızın VPN dışından gönderdiği siteler Zapret engel aşmasını kullanır.';

  @override
  String get failoverInfo => 'Bir sunucu yanıt vermeyi keserse Sora kendiliğinden sonraki çalışan sunucuya geçer.';

  @override
  String get ipv6Info => 'IPv6\'yı VPN üzerinden gönderir. Sunucuda IPv6 yoksa ve siteler yavaş açılıyorsa kapatın.';

  @override
  String get fragmentInfo =>
      'Sağlayıcının filtresi site adını göremesin diye TLS bağlantısının başını parçalara böler. Sunucu SNI ile engellendiğinde işe yarar.';

  @override
  String get splitPosInfo =>
      'İlk paketin nereden kesileceği: bir bayt numarası veya midsld (alan adının ortası) gibi bir işaret. Birden çok değeri virgülle ayırın.';

  @override
  String get disorderInfo =>
      'Paketin parçalarını ters sırayla gönderir; paketi sırayla birleştiren filtreleri şaşırtır.';

  @override
  String get tlsRecordInfo => 'TLS selamlamasını birkaç kayda böler, böylece site adı tek parça hâlinde bulunmaz.';

  @override
  String get hostCaseInfo =>
      'HTTP isteklerinde Host başlığının büyük/küçük harfini değiştirir (Host → hoSt); eski filtreler isteği tanımaz.';

  @override
  String get probeMethodInfo =>
      'Çekirdek üzerinden: sunucu üzerinden bir siteye gerçek gecikme, en doğrusu.\nYalnızca bağlantı: sunucuya sadece TCP bağlantısı; hızlı ama VPN\'i sınamaz.\nTLS el sıkışması: sunucuyla TCP ve TLS.\nICMP: sıradan ping; bazı sunucular yanıt vermez.\nOtomatik: çekirdek üzerinden, olmuyorsa bağlantı.';

  @override
  String get autoSelectInfo => 'En hızlı seçeneğinin sunucuyu nasıl seçtiği: pinge, ölçülen hıza ya da ikisine göre.';

  @override
  String get autoSwitchInfo => 'Geçerli sunucu belirgin biçimde yavaşlarsa Sora daha hızlı bir sunucuya geçer.';

  @override
  String get probeTls => 'TLS el sıkışması';

  @override
  String get probeIcmp => 'ICMP (ping)';
}
