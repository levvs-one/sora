// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class STk extends S {
  STk([String locale = 'tk']) : super(locale);

  @override
  String get stateOff => 'Baglanmadyk';

  @override
  String get stateConnecting => 'Birikdirmek';

  @override
  String get stateConnected => 'Birikdirildi';

  @override
  String get stateReconnecting => 'Birikdirmek';

  @override
  String get stateDisconnecting => 'Aýyrmak';

  @override
  String get coreMissing => 'Sora hyzmaty jogap bermeýär';

  @override
  String get serverAuto => 'Iň çalt';

  @override
  String get serverBypass => 'Serwer ýok';

  @override
  String get addSubscription => 'Abuna ýazyň';

  @override
  String get servers => 'Serwerler';

  @override
  String get settings => 'Sazlamalar';

  @override
  String get subscription => 'Abuna ýazylmak';

  @override
  String get subscriptionLink => 'Abunalyk baglanyşygy';

  @override
  String get add => 'Goş';

  @override
  String get refresh => 'Täzelen';

  @override
  String get rename => 'Adyny üýtgetmek';

  @override
  String get delete => 'Öçür';

  @override
  String get cancel => 'Elatyr';

  @override
  String get save => 'Saklaň';

  @override
  String get name => 'Ady';

  @override
  String deleteSubscription(String name) {
    return '“$name” pozuň?';
  }

  @override
  String get routes => '.Ollar';

  @override
  String get presetGlobal => 'Hemme zat VPN arkaly';

  @override
  String get presetRu => 'Russiýa göni';

  @override
  String get presetIr => 'Eýran göni';

  @override
  String get presetCn => 'Hytaý göni';

  @override
  String get blockAds => 'Mahabatlary blokirläň';

  @override
  String get killSwitch => 'Internet diňe VPN arkaly';

  @override
  String get engine => 'Motor';

  @override
  String get engineAuto => 'Awto';

  @override
  String get animations => 'Animasiýa';

  @override
  String get logs => 'Hasaba gir';

  @override
  String get about => 'Takmynan';

  @override
  String get logsAll => 'Hemmesi';

  @override
  String get logsImportant => 'Möhüm';

  @override
  String get logsErrors => 'Rorsalňyşlyklar';

  @override
  String get search => 'Gözlemek';

  @override
  String get export => 'Faýl ýazdyryň';

  @override
  String get clear => 'Arassala';

  @override
  String get logsEmpty => 'Bu ýerde hiç zat ýok';

  @override
  String get connEmpty => 'Baglanyşyk ýok';

  @override
  String appVersion(String version) {
    return '$version wersiýasy';
  }

  @override
  String get notInstalled => 'Gurulmady';

  @override
  String get sourceCode => 'Çeşme kody';

  @override
  String get license => 'Ygtyýarnama';

  @override
  String usage(String used, String total) {
    return '$total-iň $used';
  }

  @override
  String until(String date) {
    return '$date çenli';
  }

  @override
  String get expired => 'Möhleti gutardy';

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
    return '$n B.';
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
    return '$n inçekeseli';
  }

  @override
  String get errGeneric => 'Bir zat nädogry boldy';

  @override
  String get errCore => 'Sora hyzmaty jogap bermeýär';

  @override
  String get errAuth => 'Sora hyzmatyna giriş ret edildi';

  @override
  String get errVersion => 'Sora programmasynyň we hyzmatynyň wersiýalary tapawutly';

  @override
  String get errBusy => 'Öňki buýruk henizem ýerine ýetirilýär';

  @override
  String get errEngineMissing => 'Bu serwer üçin zerur hereketlendiriji tapylmady';

  @override
  String get errEngineStart => 'Hereketlendiriji işe başlamady';

  @override
  String get errEngineStopped => 'Hereketlendiriji togtady';

  @override
  String get errTunnel => 'Bu VPN tertibi elýeterli däl';

  @override
  String get errTimeout => 'Serwer wagtynda jogap bermedi';

  @override
  String get errFirewall => 'VPN-den daşarda internete girişi petikläp bolmady';

  @override
  String get errSubFetch => 'Abunalygy ýükläp bolmady';

  @override
  String get deviceIdentity => 'Enjamyň identifikatory';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Identifikatory täzelemek';

  @override
  String get deviceIdentityResetConfirm => 'Enjamyň identifikatory täzelensinmi?';

  @override
  String get errSubDeviceLimit => 'Enjamlaryň çägi geçildi';

  @override
  String get errSubDeviceRequired => 'Üpjün ediji enjamyň identifikatoryny talap edýär';

  @override
  String get errSubFormat => 'Abunalygyň formaty tanalmady';

  @override
  String get errSubEmpty => 'Abunalykda serwer ýok';

  @override
  String get errSubDuplicate => 'Bu abunalyk eýýäm goşulan';

  @override
  String get errSubLimit => 'Abunalyklaryň sany çägine ýetdi';

  @override
  String get errSubScheme => 'Abuna baglanyşygynyň shemasy goldanylmaýar';

  @override
  String get errSecretStore => 'Sora ammary zaýalanan ýa-da elýeterli däl';

  @override
  String get errNoServers => 'Birikmek üçin serwer ýok';

  @override
  String get connections => 'Baglanyşyklar';

  @override
  String get close => '.Akyn';

  @override
  String get chainDirect => 'Göni';

  @override
  String get chainBlocked => 'Bloklandy';

  @override
  String get theme => 'Mowzuk';

  @override
  String get themeSystem => 'Ulgamdaky ýaly';

  @override
  String get themeLight => 'Lightagtylyk';

  @override
  String get themeDark => 'Garaňky';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Ulgamdaky ýaly';

  @override
  String get sectionConnection => 'Baglanyşyk';

  @override
  String get sectionNoServer => 'Serwer ýok';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostika';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Awto';

  @override
  String get dnsHint => 'Salgylar, vergul aýry';

  @override
  String get fragment => 'TLS bölekleri';

  @override
  String get fragmentPackets => 'Näme bölmeli?';

  @override
  String get fragmentLength => 'Bölümiň ululygy';

  @override
  String get fragmentInterval => 'Bölekleriň arasynda duruň';

  @override
  String get byDefault => 'Bellenen';

  @override
  String get splitPos => 'Positionerleşýän ýerleri';

  @override
  String get disorder => 'Bölekleri tertipläň';

  @override
  String get tlsRecord => 'TLS ýazgysyny bölüň';

  @override
  String get tlsRecordNo => '.Ok';

  @override
  String get tlsRecordSni => 'Sahypanyň adynda';

  @override
  String get tlsRecordFirst => 'Birinji baýtdan soň';

  @override
  String get hostCase => 'Host ýagdaýyny üýtgediň';

  @override
  String get probeMethod => 'Usul';

  @override
  String get probeAuto => 'Awto';

  @override
  String get probeEngine => 'Motor arkaly';

  @override
  String get probeConnect => 'Diňe birikme';

  @override
  String get probeUrl => 'Synag salgysy';

  @override
  String get probeTimeout => 'Garaş';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Abunalar';

  @override
  String get subscriptionSettings => 'Sazlamalar';

  @override
  String get userAgent => 'Ulanyjy-agent';

  @override
  String get autoUpdate => 'Awtomatiki täzelen';

  @override
  String get updateInterval => 'Näçe ýygy';

  @override
  String get intervalProvider => 'Üpjün edijiniň soraşy ýaly';

  @override
  String hours(int n) {
    return '$n sag';
  }

  @override
  String get updateNow => 'Häzir täzeläň';

  @override
  String get logLevel => 'Näme ýazmaly';

  @override
  String get levelDebug => 'Hemme zat';

  @override
  String get levelInfo => 'Adaty';

  @override
  String get levelWarning => 'Möhüm';

  @override
  String get levelError => 'Diňe ýalňyşlyklar';

  @override
  String get recordDestinations => 'Sahypanyň salgylaryny ýazga alyň';

  @override
  String get reset => 'Sazlamalary täzeden düzmek';

  @override
  String get resetConfirm => 'Settingshli sazlamalary täzeläňmi?';

  @override
  String get resetAction => 'Täzeden düzmek';

  @override
  String get invalidValue => 'Bu baha işlemez';

  @override
  String get website => 'Abunalyk sahypasy';

  @override
  String get providerWebsite => 'Üpjün edijiniň web sahypasy';

  @override
  String get support => 'Goldaw';

  @override
  String chooseEngine(String engine) {
    return '$engine saýlaň';
  }

  @override
  String get rules => 'Omörite düzgünler';

  @override
  String get ruleAdd => 'Täze düzgün';

  @override
  String get ruleHint => 'Saýt, IP ýa-da programma';

  @override
  String get ruleDirect => 'Göni';

  @override
  String get ruleProxy => 'VPN arkaly';

  @override
  String get ruleBlock => 'Blok';

  @override
  String get failover => 'Şowsuzlygy açyň';

  @override
  String get connectOnStart => 'Başda birikdiriň';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'abunalyk $days günlerinde tamamlanýar',
      one: 'abunalyk $days güni tamamlanýar',
      zero: 'abuna ýazylmak birnäçe sagatdan soň tamamlanýar',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left galdy';
  }

  @override
  String get ruleInvalid => 'Bu sahypa, IP ýa-da programma ýaly däl';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serwerleri, iň çalt',
      one: '$count serweri, iň çalt',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Reodeim';

  @override
  String get tunnelProxy => 'System proksi';

  @override
  String get proxyAddress => 'Proksi salgysy';

  @override
  String get copied => 'Göçürildi';

  @override
  String get launchAtLogin => 'Ulgamdan başlaň';

  @override
  String get closeToTray => 'Closedapylanda tarelde saklaň';

  @override
  String get notifications => 'Duýduryşlar';

  @override
  String get trayOpen => 'Sora açyň';

  @override
  String get trayConnect => 'Birikdiriň';

  @override
  String get trayDisconnect => 'Aýyr';

  @override
  String get trayServer => 'Serwer';

  @override
  String get trayQuit => 'Sora-den çykyň';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora henizem lagada';

  @override
  String get noticeLost => 'Baglanyşyk ýitdi';

  @override
  String get noticeLostBody => 'Sora täzeden birikýär';

  @override
  String get noticeRestored => 'Againene birikdirildi';

  @override
  String get noticeFailed => 'Birikip bilmedim';

  @override
  String get noticeBackup => 'Esasy serwer jogap bermedi; ätiýaçlyk trafigi alyp barýar';

  @override
  String get noticeNext => 'Serwer jogap bermedi; indiki ulag gatnawyny amala aşyrýar';

  @override
  String get noticeMainBack => 'Esasy serwer ýene jogap berýär we traffigi göterýär';

  @override
  String get noticeSubscription => 'Abuna ýazylmak';

  @override
  String get importTitle => 'Bu abuna ýazyňmy?';

  @override
  String get importSealed => 'Bu baglanyşyk Happ üçin kodlanýar we ony diňe Happ okap biler';

  @override
  String get noAnswer => 'Jogap ýok';

  @override
  String get home => 'Öý';

  @override
  String get navRules => 'Düzgünler';

  @override
  String get navConnections => 'Baglanyşyklar';

  @override
  String get navLogs => 'Surnallar';

  @override
  String get navAbout => 'Takmynan';

  @override
  String get sidebarToggle => 'Gapdal paneli çalyşyň';

  @override
  String get more => 'Has köp';

  @override
  String get less => 'Az';

  @override
  String get notificationsEmpty => 'Habarnama ýok';

  @override
  String get retryConnect => 'Birikdirmek';

  @override
  String get openLogs => 'Surnallary açyň';

  @override
  String get tourReplay => 'Guideene-de gollanma görkez';

  @override
  String tourStep(int step) {
    return '5-nji ädim $step';
  }

  @override
  String get tourBack => 'Yzyna';

  @override
  String get tourNext => 'Indiki';

  @override
  String get tourSkip => 'Geçmek';

  @override
  String get tourFinish => 'Boldy';

  @override
  String get tourAdd => 'Üpjün edijiňiziň abuna baglanyşygyny goşuň.';

  @override
  String get tourServer => 'Serwer saýlaň. “Iň çalt” siziň üçin birini saýlaýar.';

  @override
  String get tourConnect => 'Birikdirmek ýa-da aýyrmak üçin şu ýere basyň.';

  @override
  String get tourMode => 'Re modeimi saýlaň. VPN düşse, wyklýuçatel interneti bloklaýar.';

  @override
  String get tourSettings => 'Sazlamalary açyň. Bu gollanmany şol ýerde gaýtadan ulanyp bilersiňiz.';

  @override
  String get chooseProgram => 'Programma saýlaň';

  @override
  String get installedApps => 'Gurlan programmalar';

  @override
  String get runningProcesses => 'Işleýiş amallary';

  @override
  String get programsEmpty => 'Programmalar tapylmady Başga bir at synap görüň';

  @override
  String get selectExe => '.Exe faýly saýlaň';

  @override
  String get speedtest => 'Tizlik';

  @override
  String get speedtestSearch => 'Hyzmat tapyň';

  @override
  String get speedtestEmpty => 'Gabat gelenok';

  @override
  String get speedtestBackToList => 'Hyzmatlara dolan';

  @override
  String get speedtestOpenBrowser => 'Brauzerde açyň';

  @override
  String get speedtestUnavailable => 'Içerki brauzer başlap bilmedi';

  @override
  String get speedtestPageFailed => 'Sahypa ýükläp bilmedi';

  @override
  String get speedtestExternalFailed => 'Ulgam brauzeri açyp bilmedi';

  @override
  String get modes => 'Reesimler';

  @override
  String get proxyShort => 'Proksi';

  @override
  String get tunMode => 'Traffichli traffik (TUN)';

  @override
  String get checkUpdates => 'Täzelenmeleri barlaň';

  @override
  String get updates => 'Programma täzelenmeleri';

  @override
  String updateAvailable(String version) {
    return '$version wersiýasy bar';
  }

  @override
  String get updateOpenAbout => 'Täzelenmäni görüň';

  @override
  String updateNotes(String version) {
    return '$version-de üýtgeşmeler';
  }

  @override
  String get updateCheck => 'Täzelenmeleri barlaň';

  @override
  String get updateChecking => 'Barlamak ...';

  @override
  String get updateNoNotes => 'Neşirde hiç hili bellik ýok.';

  @override
  String get updateDropWarning => 'Täzelemek üçin birikmäni kesmelimi?';

  @override
  String get updateWaitConnection => 'Birikme taýýar däl';

  @override
  String get updateDownloading => 'Faýllary göçürip almak we barlamak ...';

  @override
  String get updateInstalling => 'Täzelenmäni taýýarlamak ýa-da administratoryň tassyklanmagyna garaşmak ...';

  @override
  String get updateNetworkError => 'Täzelenmäni göçürip alyp bolmady Gaýtadan synanyşyň';

  @override
  String get updateReleaseError => 'Goýberilýän maglumatlar ýa-da zerur faýllar ýok ýa-da nädogry.';

  @override
  String get updateChecksumError => 'Göçürip almak SHA256SUMS bilen gabat gelenok';

  @override
  String get updateInstallError => 'Täzelenme gutarmady';

  @override
  String get updateUnsupported => 'Bu ýerine ýetirip boljak, goldanýan Sora paket jübütine degişli däl';

  @override
  String get updateManual =>
      'Barlanylan paketleri gurmak üçin bu buýrugy terminalda işlediň, soňra Sora açyň. Faýllar göçürip almak katalogynda galýarlar. VPN birikmesi peseler.';

  @override
  String get updateVersionRevoked => 'Dörediji bu wersiýany yzyna aldy';

  @override
  String get updateRolloutPending => 'Täze wersiýa kem-kemden çykýar we size awtomatiki usulda hödürlener.';

  @override
  String updateRollbacking(String version) {
    return '$version wersiýasyna gaýtarylýar...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version täzelenmesi işleýiş barlagyndan geçmedi, şonuň üçin Sora $fromVersion wersiýasyna gaýtaryldy.';
  }

  @override
  String get updateRollbackError => 'Awtomatiki yza gaýtmak şowsuz';

  @override
  String get updateRollbackCacheError =>
      'Häzirki wersiýanyň tassyklanan yzyna gaýtarylan nusgasyny taýýarlap bolmady, şonuň üçin täzelenme gurulmady.';

  @override
  String get updateCopyCommand => 'Buýrugy göçüriň';

  @override
  String get updateChecksDisabled => 'Sazlamalarda awtomatiki barlaglar ýapylýar.';

  @override
  String get updateInstalled => 'Täzelenme guruldy Sora açyň';

  @override
  String get projectLinks => 'Taslama';

  @override
  String get githubReleases => 'Çykarýar we göçürip alýar';

  @override
  String get telegramChannel => 'Telegram kanaly';

  @override
  String get licenses => 'Ygtyýarnamalar';

  @override
  String get componentLicenses => 'Komponent ygtyýarnamalary';

  @override
  String get collapseServers => 'Serwerleri ýykyň';

  @override
  String get expandServers => 'Serwerleri giňeltmek';

  @override
  String get hideDescription => 'Düşündirişi gizläň';

  @override
  String get showDescription => 'Düşündiriş görkez';

  @override
  String get errEngineUnsupported => 'Saýlanan hereketlendiriji bu profili ýa-da sazlamalary goldamaýar';

  @override
  String get errRestore => 'Baglanyşygy arassalamak doly däldi';

  @override
  String get errSessionEnded => 'Bu sessiýa eýýäm tamamlandy';

  @override
  String get retryDisconnect => 'Aýyrmagy gaýtadan synanyşyň';

  @override
  String get tunStack => 'TUN stack';

  @override
  String get modesInfo => 'Rejeler hakda';

  @override
  String get modesGuideTitle => 'Reesimler we hereketlendirijiler';

  @override
  String get modesGuide =>
      'Serweriňiziň haýsy motora mätäçdigini bilmeýän bolsaňyz, Awto saýlaň. Sora birikmezden ozal profil we sazlamalary barlaýar. Dwigatel meýilnamaňyzyň geçiriş giňligini artdyryp bilmez: öndürijilik serwere, ugra, protokola we tora baglydyr.\n\n## Reesimler\n\n### traffichli traffik (TUN)\n\nSora wirtual tor interfeýsini döredýär we TCP we UDP ýaly programma trafigini ugrukdyrýar. Bu re modeimi Telegram, oýunlar we Discord sesi üçin ulanyň. Düzgünler belli bir saýtlary ýa-da programmalary gönüden-göni iberip ýa-da blokirläp biler. Tor hyzmaty, zerur protokoly goldaýan serwere we serwere mätäç.\n\n### System proksi\n\nSora ýerli HTTP / SOCKS proksi düzýär. Ulgam proksi sazlamalaryna hormat goýýan programmalar ony ulanýarlar. Öz torlary bilen goýmalar gönüden-göni birigip biler; UDP we sesli jaňlar adatça TUN gerek. Bu re modeim proksi goldawy bilen brauzerlere we programmalara laýyk gelýär.\n\n### Serwer ýok\n\nLinux-de, Sora HTTP / TLS haýyşlaryny bölmek we üýtgetmek we käbir DPI barlaglaryndan aýlanyp geçmek üçin [zapret] (https://github.com/bol-van/zapret) ulanýar. IP-iňiz şol bir ýagdaýda galýar we birikmeler göni web sahypasyna gidýär. Netijeler üpjün edijiňize we blokirleme usulyna baglydyr.\n\nHäzirki integrasiýa, TCP-den HTTP we TLS üçin tpws ulanýar. IP blokirlemesinden ýa-da UDP-den geçmeýär we Telegram-iň MTProto birikmelerini kepillendirip bilmeýär. Discord sesi, Telegram jaňlary we bu hili çäklendirmeler üçin TUN bilen VPN serwerini ulanyň.\n\n## Dwigateller\n\n### Awto\n\nSora ähli birikme meýilnamasyny goldaýan gurnalan hereketlendirijini saýlaýar: serwer protokollary, transportlar, toparlar, böleklere bölüniş we re modeim. Gabat gelmeýän el bilen saýlamak, häzirki baglanyşygy togtatmazdan ozal ret edilýär. Awto ýa-da başga dwigateli saýlaň we sazlamalary täzeden ulanyň.\n\n### sing-box\n\nTäze Sora paketleri [sing-box-lx] (https://github.com/Leadaxe/sing-box-lx), [sing-box] (https://github.com/SagerNet/sing-box), müşderi tarapyna XHTTP we VLESS Encryption goşýar. Sora gurluşy we mümkinçiliklerini ykrar edýär. XHTTP bolmazdan ýokary akym gurmak, diňe öz adyndan bu mümkinçiligi gazanyp bilmez.\n\nGoldaw berlen protokollara VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard we WireGuard we AmneziaWG AmneziaWG Doly Xray JSON profilleri Xray talap edýär. Täze AWG 3.x meýdanlaryny entek import edip bolmaýar. sing-box kompýuterdäki beýleki programmalaryň tapyp bilýän parol bilen goralýan ýerli dolandyryş portuny ulanýar.\n\n### Xray\n\n[Xray-core] (https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption we TLS böleklerini goldaýar. Şeýle hem, marşrutlaryny we toparlaryny gorap saklamak bilen doly üpjün ediji Xray profilini işleýär. Şeýle profilleri özlerini alyp barşyny üýtgetmän awtomatiki usulda başga motora öwrüp bolmaz.\n\nBaglanan Xray TLS şahadatnamasyny tassyklamagy (\"allowInsecure\") ýapýan sazlamany aýyrdy. Awto bu sazlamany talap edýän adaty serwerler üçin sing-box ýa-da mihomo saýlaýar. Xray saýlamak, häzirki birikmäni togtatmazdan ozal gabat gelmeýändigini habar berýär. Has köne JSON profillerinde barlanylýan şahadatnama ýa-da şahadatnama pin bilen täzelenen üpjün ediji profiline mätäç.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) ätiýaçlyk serwere yzygiderli geçiş toparlaryny, ýük paýlaşmagy, XHTTP we AmneziaWG goldaýar. Ätiýaçlyk serwere awtomatik geçmek möhüm bolsa, ony saýlaň. Sora-nyň TLS bölekleme sazlamasy bu ýadro bilen elýeterli däl.\n\n## Sora-de laýyklyk\n\n| Aýratynlyk | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN we TCP / UDP | Hawa | Hawa | Hawa |\n| XHTTP | Hawa | Hawa | Hawa |\n| VLESS Encryption | Hawa | Hawa | Hawa |\n| Doly Xray tertibi | | Ok | Hawa | | Ok |\n| TUIC / AnyTLS | Ikisi | | Ok | TUIC |\n| mieru | Ýok | Ýok | Hawa |\n| NaiveProxy | Hawa | Ýok | Ýok |\n| TLS bölekleri | Hawa | Hawa | | Ok |\n| AmneziaWG 1.x / 2.x | Hawa | | Ok | Hawa |\n| Yza gaýdyp gelen topar | | Ok | ²ok | Hawa |\n\nZ J1/J2/J3/Itime bolan profiller mihomo ulanýar; bu meýdanlar hiç haçan sessiz-üýnsüz taşlanmaly däldir. Complete Doly Xray profilleriniň topary üçin programma ätiýaçlyk profilini saýlaýar. Goldaw gurlan gurna baglydyr; hakda wersiýasyny barlaň.\n\n## TUN ýygyndysy\n\nStack wirtual interfeýsiň içinde TCP we UDP işleýär. Reesimler panelinde Xray we mihomo gVisor, System, Mixed we MIPS hödürleýär. Her hereketlendiriji öz islegini tygşytlaýar. System proksi we Serwersiz reesimler bu ileri tutmany ulanmaýarlar.\n\n- ** Mixed ** - TCP ulgam stakasyny ulanýar, gVisor bolsa UDP işleýär. Bu Linux-da mihomo üçin başlangyç görnüşdir. Windows-da Xray we mihomo başlangyç görnüş hökmünde MIPS ulanýar.\n- ** System ** - ulgam toplumyny ulanýar. Tor programmalarynda kynçylyklar ýüze çyksa, başga bir warianty synap görüň.\n- ** gVisor ** - ulanyjy giňişliginde traffigi dolandyrýar.\n- ** MIPS ** - mihomo-iň öz IP ýygyndysy, birleşdirilen 1.19.32 wersiýasynda bar.\n\nLinux-de, Xray gurnalan gVisor deslapky görnüşde ulanýar. Linux-de System, Mixed we MIPS mihomo-ni TUN hereketlendirijisi hökmünde ulanyp, TCP we UDP-ni tassyklanan ýerli SOCKS baglanyşygy arkaly Xray-e ugradýar. Xray protokoly, üpjün edijiniň profilini we marşrutyny saklaýar. Bu üç wariant gurnalan mihomo talap edýär. Windows-de Xray dört TUN stekiniň hemmesi üçin mihomo 1.19.32 ýa-da has täze wersiýany ulanýar. Protokollar we ugur kesgitlemek Xray-da galýar. Bu birleşmede programma düzgünleri diňe göni birikmäni we bloklamagy goldaýar; Linux-de bu düzgünler Xray-yň içindäki gVisor stekini talap edýär.\n\nKöprü ikinji gezek işleýär. Linux-de üç sany boş ölçegde, ýerli Xray TUN-dan has takmynan 32–36 MiB fiziki ýat ulanyldy. Bu göçürip almak ýüküni ölçemeýär: CPU we ýat çykdajylary birikmelere baglydyr. sing-box-de hiç hili saýlaýjy ýok. Hiç bir stak her ulgamda has gowy işlemegi kepillendirmeýär.\n\n## Sazlamalary ulanmak\n\nSerwer saýlananda birikme awtomatik täzeden gurulýar. Režime, ýadroga, DNS-e ýa-da düzgünlere girizen üýtgeşmeleriňiz gysga arakesmeden soň awtomatik gaýtadan birikmek bilen bir gezek ulanylýar; fondaky täzelenmeler VPN-i gaýtadan birikdirmeýär. Ýadrony täzeden başlatmak ýüklemeleri we jaňlary kesip biler.\n\nInternet diňe VPN arkaly tunel gaçanda göni traffigi bloklaýar. Tutuş maşyna täsir edýär. Açyk aýyrmak Sora düzgünlerini aýyrýar. Arassalamak gutarmasa, birikmäni täzeden synap görüň we gündeligi açyň.\n\n## Taslama resminamalary\n\n- [sing-box-lx: konfigurasiýa we goldaw] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box resminamalary] (https://sing-box.sagernet.org/)\n- [Xray resminamalary] (https://xtls.github.io/)\n- [mihomo resminamalary] (https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: iş we çäklendirmeler] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP trafikini Jitsi, Yandex Telemost ýa-da WB Stream wideo jaňynyň üsti bilen geçirýär. olcrtc:// baglanyşygyny ýa-da QR koduny import ediň. Proksi we TUN režimlerinde sing-box, Xray we mihomo bilen işleýär; UDP goldanylmaýar. Iki tarapa-da gabat gelýän OLC2 ýygyndylary gerek. Başlangyç taslama arhiwlenen.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Giňeldişler';

  @override
  String extRatingLabel(String rating) {
    return '5-den baha $rating';
  }

  @override
  String extByAuthor(String author) {
    return '$author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Gurnamalar: $count';
  }

  @override
  String get extInstallOne => '1 gurmak';

  @override
  String get extSideloadWarning => 'Özi gol çeken açar';

  @override
  String get extPermissionsWidened => 'Täzelenme täze rugsatlar soraýar:';

  @override
  String get extInstall => 'Gurna';

  @override
  String get extUpdate => 'Täzele';

  @override
  String get extCancel => 'Ýatyr';

  @override
  String get extConfirm => 'Tassykla';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'Gurlan giňeltmeler';

  @override
  String get extSearchHint => 'Giňeldişleri gözle';

  @override
  String get extCatAll => 'Hemmesi';

  @override
  String get extCatTools => 'Gurallar';

  @override
  String get extCatThemes => 'Temalar';

  @override
  String get extCatAutomation => 'Awtomatlaşdyryş';

  @override
  String get extCatStats => 'Statistika';

  @override
  String get extCatNetwork => 'Tor';

  @override
  String get extSortBy => 'tertipläň';

  @override
  String get extSortPopular => 'Iň meşhur';

  @override
  String get extSortRating => 'Iň ýokary baha';

  @override
  String get extSortName => 'Ady';

  @override
  String get extCatalogError => 'Katalogy ýükläp bolmady';

  @override
  String get extRetry => 'Gaýtadan synanyş';

  @override
  String get extEmptySearch => 'Hiç zat tapylmady';

  @override
  String get extEmptyInstalled => 'Entek giňeltmeler ýok';

  @override
  String get extInstallFromFile => 'Faýldan guruň';

  @override
  String get extInstallFromUrl => 'URL-dan guruň';

  @override
  String get extDownload => 'Göçürip al';

  @override
  String get extDownloading => 'Göçürilip alynýar…';

  @override
  String get extVerifying => 'Barlanylýar…';

  @override
  String get extInstalling => 'Gurnalýar…';

  @override
  String get extErrSignature => 'Gol barlagy şowsuz boldy';

  @override
  String get extErrManifest => 'Giňeldiş manifesti nädogry.';

  @override
  String get extErrNetwork => 'Tor ýalňyşlygy';

  @override
  String get extErrHash => 'Göçürilen faýl katalogdakysyna gabat gelmeýär';

  @override
  String extErrMinApp(String version) {
    return 'Bu giňeltme $version ýa-da has täze programma wersiýasy gerek.';
  }

  @override
  String get extErrHttpsOnly => 'Diňe https:// baglanyşyklara rugsat berilýär';

  @override
  String get extErrGeneric => 'Bir zat nädogry boldy';

  @override
  String get extErrAuthorKeyChanged =>
      'Bu täzelenme, gurnalan wersiýadan başga awtor açary bilen gol çekildi, şonuň üçin ol petiklendi';

  @override
  String get extDisabled => 'Öçürilen';

  @override
  String extToggleEnabled(String name) {
    return '$name işlediň';
  }

  @override
  String get extSearchInstalled => 'Gurnalan giňeldişleri gözle';

  @override
  String get extUpdateAll => 'Hemmesini täzeläň';

  @override
  String extUpdatesAvailable(int count) {
    return '$count täzelenmeler bar';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count täzelendi';
  }

  @override
  String get extRiskNormal => 'Adaty';

  @override
  String get extRiskSensitive => 'Duýgur';

  @override
  String get extRiskDangerous => 'Ýokary töwekgelçilik';

  @override
  String get extPermissionsRemoved => 'Indi soralmaýar:';

  @override
  String get extUpdateFailedKept => 'Öňki wersiýasy henizem gurnalan.';

  @override
  String get extConflictsTitle => 'Giňeldiş gapma-garşylyklary';

  @override
  String get extConflictTheme => 'Programma mowzugy';

  @override
  String get extConflictNetHooks => 'Tor çeňňekleri';

  @override
  String extConflictWinner(String name) {
    return 'Ileri tutulýar: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'Giňeldiş gapma-garşylyklary: $count';
  }

  @override
  String get extConflictsResolve => 'Dawa-jenjelleri çözüň';

  @override
  String extVersionLabel(String version) {
    return 'Wersiýa $version';
  }

  @override
  String get extPermissionsTitle => 'Rugsatlar';

  @override
  String get extNoPermissions => 'Ýörite rugsatlar gerek däl.';

  @override
  String get extSettings => 'Sazlamalar';

  @override
  String get extSaveSettings => 'Sazlamalary ýazdyryň';

  @override
  String extUpdateTo(String version) {
    return '$version wersiýasyna täzele';
  }

  @override
  String get extEnabled => 'Işjeň';

  @override
  String extRollbackTo(String version) {
    return '$version wersiýasyna gaýtar';
  }

  @override
  String extRollbackConfirm(String version) {
    return '$version wersiýasyna gaýdyp gelmek?';
  }

  @override
  String get extUninstall => 'Aýyr';

  @override
  String extUninstallConfirm(String name) {
    return '“$name” we onuň sazlamalaryny aýyryň?';
  }

  @override
  String get extPanelUnavailable => 'Giňeltmäniň paneli elýeterli däl.';

  @override
  String get extPermConnectionsRead => 'Işjeň birikmeleriň sanawyna serediň';

  @override
  String get extPermServersRead => 'Serwerleriňiziň sanawyna serediň';

  @override
  String get extPermSettingsRead => 'Programma sazlamalaryny okaň';

  @override
  String get extPermSettingsWrite => 'Programma sazlamalaryny üýtgediň';

  @override
  String get extPermNotifications => 'Duýduryşlary görkeziň';

  @override
  String get extPermTray => 'Ulgam treýiniň menýusyna element goşmak';

  @override
  String get extPermUiPanel => 'Programmanyň içinde panelleri görkeziň';

  @override
  String get extPermThemeApply => 'Mowzuklary ulanyň';

  @override
  String get extPermRoutingRules => 'Ugurlandyryş düzgünlerini goşmak';

  @override
  String get extPermNetHooks => 'Tor ýoluna goşulyň';

  @override
  String get extPermNetFetch => 'Rugsat berlen sanawdan URL haýyş';

  @override
  String get extPermBackground => 'Fon meselelerini işlediň';

  @override
  String get extPermNotYetActive => 'Öçürilen';

  @override
  String get extCapBackground => 'Fonda işleýär';

  @override
  String get extCapNetHook => 'Böwetden aýlanyp geçiş we tor hook-lary';

  @override
  String get extCapPanel => 'Interfeýs panelleri';

  @override
  String get extCapRouting => 'Ugurlandyryş düzgünleri';

  @override
  String get extCapTheme => 'Temalar';

  @override
  String get extCapWidget => 'Widjetler';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Üýtgeşmeleriň taryhy';

  @override
  String get extImageFailed => 'Suraty ýükläp bolmady';

  @override
  String get extScreenshots => 'Ekran suratlary';

  @override
  String get extSortRelevance => 'Degişlilik';

  @override
  String get extBgTitle => 'Fon işi';

  @override
  String get extBgEnabled => 'Fonda işletmek';

  @override
  String get extBgInterval => 'Işletmek aralygy';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minut', one: '$count minut');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sagat', one: '$count sagat');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Tora giriş';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Tor: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Faýla $name';
  }

  @override
  String get diagnosticHttp => 'HTTP anyklaýyş';

  @override
  String get diagnosticNoData => 'Entek ýazylan haýyş ýok';

  @override
  String get qrShareTitle => 'QR kody paýlaşyň';

  @override
  String get qrScanTitle => 'QR kody skanirläň';

  @override
  String get qrCopyLink => 'Baglanyşygy göçüriň';

  @override
  String get qrWarning => 'Kody diňe ynanýan adamlaryňyz bilen paýlaşyň.';

  @override
  String get qrFromClipboard => 'Buferden goýuň';

  @override
  String get qrNoCode => 'Bu suratda QR kod tapylmady.';

  @override
  String get qrInvalid => 'Bu QR kody dogry baglanyşyk ýok.';

  @override
  String get qrScan => 'Skaner QR';

  @override
  String get qrFromImage => 'Suraty aç';

  @override
  String get connGroupByProcess => 'Amal boýunça topar';

  @override
  String get connListView => 'Sanaw görnüşinde';

  @override
  String get connCopyHost => 'Host adyny göçür';

  @override
  String get connAddRule => 'Düzgün goşuň';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count birikme', one: '$count birikme');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Öňünden bellemek';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Şahsy';

  @override
  String get dnsCheck => 'Maglumatlaryň syzýandygyny barlaň';

  @override
  String get dnsChecking => 'Barlamak ...';

  @override
  String get dnsNoLeak => 'Syzdyrmalar tapylmady';

  @override
  String get dnsLeakFound => 'Syzma tapyldy';

  @override
  String get dnsLastCheck => 'Soňky barlag';

  @override
  String get dnsNeverChecked => 'Entek synagdan geçirilmedi';

  @override
  String get dnsLeakCheckTunnelDns => 'Tuneliň DNS çözüjileri';

  @override
  String get dnsLeakCheckSystemResolvers => 'Ulgamyň at çözüjileri';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Tor gulpynyň DNS goragy';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Ýokardaky DNS sazlamalarynda tuneliň DNS-ini belläň.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Ulgamyňyzyň tunelden daşarda haýsy çözgütleri ulanjakdygyny barlaň.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'DNS trafiginiň tunelde galmagy üçin tor gulpyny açyň.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Ulgamyň şifrlenen DNS-i';

  @override
  String get dnsLeakCheckDnsSpoof => 'Galp DNS jogaplar';

  @override
  String get dnsLeakFixReviewEncryptedDns => 'Ulgamyň tuneliň daşynda ulanýan haýsy kodlanan DNS nokatlaryny barlaň.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'At çözüjiler jogaplary galplaşdyryp bilmez ýaly, tunelde şifrlenen DNS (DoT ýa-da DoH) ulanyň.';

  @override
  String get dnsCheckNeedsConnection => 'Ilki VPN birikdiriň, soňra syzyşlary barlaň.';

  @override
  String get dnsExpected => 'Garaşylýar';

  @override
  String get dnsActual => 'Syn edildi';

  @override
  String get measureSpeed => 'Tizligi ölçäň';

  @override
  String get benchmarkStale => 'köne';

  @override
  String get autoSelectMode => 'Serweri awtomatiki saýlaň';

  @override
  String get autoSelectPing => 'Iň çalt ping';

  @override
  String get autoSelectSpeed => 'Iň çalt tizlik';

  @override
  String get autoSelectSmart => 'Akylly saýlaw';

  @override
  String get coreWatchUnstable => 'Ýadro bilen aragatnaşyk durnuksyz';

  @override
  String get watchReconnect => 'Täzeden birik';

  @override
  String get crashRestoreTitle => 'Soňky sessiýa kesildi';

  @override
  String get restoreOnCrash => 'Näsazlykdan soň sessiýany dikeltmek';

  @override
  String get crashRestore => 'Dikelt';

  @override
  String get crashDismiss => 'Häzir däl';

  @override
  String get overrideTitle => 'Düzedişlerim';

  @override
  String get overrideEdit => 'Serwerleri redaktirläň';

  @override
  String get overrideHide => 'Gizle';

  @override
  String get overrideUnhide => 'Görkez';

  @override
  String get overrideClear => 'Üýtgetmeleri täzeden düzüň';

  @override
  String get overrideEmpty => 'Entek redaktirleme ýok';

  @override
  String get overrideCustomRules => 'Öz düzgünleriňiz';

  @override
  String get errBenchmarkUnsupported => 'Tizligi ölçemek üçin ýadronyň has täze wersiýasy gerek';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total-den $done ölçemek…';
  }

  @override
  String get profiles => 'Tor profilleri';

  @override
  String get profilesEmpty => 'Entek profil ýok';

  @override
  String get profileAdd => 'Profil goşuň';

  @override
  String get profileName => 'Profiliň ady';

  @override
  String get profileSsids => 'Wi-Fi torlary (SSID)';

  @override
  String get profileGateways => 'Tor şlýuzalary';

  @override
  String get profileAsns => 'AS sanlar';

  @override
  String get profileAutoApply => 'Awtomatiki ulanmak';

  @override
  String get profileSnapshot => 'Häzirki sazlamalary ýadyňyzda saklaň';

  @override
  String get profileSnapshotDone => 'Häzirki sazlamalar profilde saklanýar';

  @override
  String get profileDelete => 'Profili pozuň';

  @override
  String profileDeleteConfirm(Object name) {
    return '\"$name\" profilini pozuň?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '\"$name\" profilini ulanyň?';
  }

  @override
  String get profileApply => 'Ulan';

  @override
  String profileApplied(Object name) {
    return '“$name” profil ulanylýar';
  }

  @override
  String get profileUndo => 'Yza al';

  @override
  String get profileActive => 'Işjeň';

  @override
  String networkNow(Object info) {
    return 'Indi: $info';
  }

  @override
  String get networkUnknown => 'Ulgam maglumatlary elýeterli däl';

  @override
  String get profileNoTriggers => 'Profil şertleri ýok';

  @override
  String get chains => 'Proksi zynjyrlary';

  @override
  String get chainsEmpty => 'Entek zynjyr ýok';

  @override
  String get chainAdd => 'Täze zynjyr';

  @override
  String get chainName => 'Zynjyryň ady';

  @override
  String get chainTooFew => 'Zynjyr üçin azyndan iki serwer gerek';

  @override
  String get chainTooMany => 'Zynjyrda iň köp üç serwer bolup biler';

  @override
  String get chainEstimate => 'Takmynan gijä galmak';

  @override
  String get chainSave => 'Zynjyry sakla';

  @override
  String get chainDelete => 'Zynjyry pozuň';

  @override
  String chainDeleteConfirm(Object name) {
    return '\"$name\" zynjyry pozuň?';
  }

  @override
  String get chainUnsupported => 'Saýlanan hereketlendiriji zynjyrlary goldamaýar';

  @override
  String get chainHopMissing => 'Zynjyrdaky serwerleriň biri indi elýeterli däl';

  @override
  String chainHop(Object n) {
    return 'Geçiş $n';
  }

  @override
  String get chainEntry => 'Giriş';

  @override
  String get chainExit => 'Çykyş';

  @override
  String get sync => 'Enjamyň sinhronizasiýasy';

  @override
  String get syncDevices => 'Enjamlarym';

  @override
  String get syncEmpty => 'Jübütlenen enjam ýok';

  @override
  String get syncPair => 'Enjamy jübütle';

  @override
  String get syncShowCode => 'Kody görkez';

  @override
  String get syncScanCode => 'Kody skanirle';

  @override
  String get syncRevoke => 'Ygtyýaryny ýatyr';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" ýatyryň?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Soňky sinhronlamak: $time';
  }

  @override
  String get syncNever => 'Hiç haçan';

  @override
  String get syncPaired => 'Enjam jübütlendi';

  @override
  String get syncPairingTitle => 'Bu enjam bilen jübütläň';

  @override
  String get syncWaiting => 'Beýleki enjama garaşmak…';

  @override
  String get zapretWithVpn => 'Göni tor trafigi üçin süzgüçden DPI aýlaň';

  @override
  String get chainDuplicate => 'Zynjyrda şol bir serwer gaýtalanýar';

  @override
  String get edit => 'Redaktirläň';

  @override
  String get remove => 'Aýyr';

  @override
  String get autoSwitchOnDegrade => 'Hil pese düşende awtomatiki geçmek';

  @override
  String get tunStackMixed => 'Garyşyk';

  @override
  String get tunStackSystem => 'Ulgam';

  @override
  String get customServerAdd => 'Şahsy serwer goş';

  @override
  String get customServers => 'Serwerlerim';

  @override
  String get customServerName => 'Ady';

  @override
  String get customServerNameRequired => 'At görkezilmedi';

  @override
  String get customServerAddress => 'Salgysy';

  @override
  String get customServerAddressRequired => 'Salgy görkezilmedi';

  @override
  String get customServerAddressInvalid => 'Nädogry salgy';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Port nädogry';

  @override
  String get customServerProtocol => 'Protokol';

  @override
  String get customServerCredentials => 'Giriş maglumatlary';

  @override
  String get customServerShowSecret => 'Gizlin maglumaty görkez';

  @override
  String get customServerHideSecret => 'Gizlin maglumaty gizle';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” serwerini pozuň?';
  }

  @override
  String get leakTestTitle => 'Maglumatlaryň syzmagy üçin synag';

  @override
  String get leakTestRun => 'Barlaň';

  @override
  String get leakTestCancel => 'Ýatyr';

  @override
  String get leakTestNeedsConnection => 'Maglumatlaryň syzmagyny barlamak üçin VPN birikdiriň.';

  @override
  String leakTestProgress(int count) {
    return 'Synaglar tamamlandy: $count';
  }

  @override
  String get leakTestAllClear => 'Syzdyrmalar tapylmady';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count syzma tapyldy',
      one: '$count syzma tapyldy',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'düzediň';

  @override
  String get leakTestFixedNote => 'Tor gulpy açyk. Barlamak üçin synagy gaýtadan işlediň.';

  @override
  String get leakTestCheckDirectDns => 'Göni DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP ýaňlanýar';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Ulgamyň at çözüjileri';

  @override
  String get leakTestCheckTunnelConnectivity => 'Tuneliň birikmesi';

  @override
  String get leakTestCheckTunnelDns => 'DNS tuneliň üsti bilen';

  @override
  String get noticeDegraded => 'Serwer haýal boldy. Sora ölçeg wagtynda tapylan iň gowy serwere geçdi.';

  @override
  String get obfs => 'Trafigi gizlemek';

  @override
  String get syncCodeExpired => 'Kodyň möhleti gutardy';

  @override
  String get syncDaemonFailed => 'Sinhronlamak hyzmatyny başlap bolmady';

  @override
  String get syncDaemonMissing => 'sora-sync komponenti tapylmady';

  @override
  String get syncDaemonStarting => 'Sinhronlamak hyzmatyna başlamak…';

  @override
  String get syncErrAuth => 'Sinhronlamak hyzmaty giriş belligini ret etdi';

  @override
  String get syncErrNotFound => 'Enjam indi jübütlenenok';

  @override
  String get syncErrPairingActive => 'Jübütlemek sessiýasy eýýäm açyk';

  @override
  String get syncErrUnreachable => 'Beýleki enjam jogap bermedi';

  @override
  String get syncError => 'Sinhronizasiýa säwligi';

  @override
  String syncExpiresIn(String duration) {
    return 'Kodyň möhleti $duration soň gutarýar';
  }

  @override
  String get syncJoining => 'Enjam bilen jübütlemek…';

  @override
  String get syncNewCode => 'Täze kod';

  @override
  String syncPairedWith(String name) {
    return '$name bilen jübüt';
  }

  @override
  String get syncRetry => 'Gaýtadan synanyş';

  @override
  String get syncStopShowing => 'Kody gizle';

  @override
  String get syncSyncNow => 'Häzir sinhronla';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Alyndy: $pulled, iberildi: $pushed';
  }

  @override
  String get syncResultTitle => 'Sinhronizasiýa netijesi';

  @override
  String get syncPulled => 'Alyndy';

  @override
  String get syncPushed => 'Iberildi';

  @override
  String get syncNoChanges => 'Hiç hili üýtgeşme tapylmady';

  @override
  String get syncDocKindSubscriptions => 'Abunalar';

  @override
  String get syncDocKindSettings => 'Programma sazlamalary';

  @override
  String get syncDocKindOverrides => 'Abunalaryň şahsy üýtgetmeleri';

  @override
  String get syncDocKindProfiles => 'Tor profilleri';

  @override
  String get syncDocKindChains => 'Proksi zynjyrlary';

  @override
  String syncFrom(String name) {
    return '$name enjamyndan';
  }

  @override
  String get syncThisDevice => 'Bu enjam';

  @override
  String get syncUnavailableAndroid => 'Android-de sinhronizasiýa elýeterli däl';

  @override
  String get diagnosticPackets => 'Paket almak';

  @override
  String get diagnosticEvents => 'Windows wakalary';

  @override
  String get diagnosticCapture => '10 sekuntlap ​​surata düşüriň';

  @override
  String get diagnosticRequiresTun => 'Paket almak üçin işjeň Sora TUN birikmesi gerek.';

  @override
  String get diagnosticUnavailable => 'Bu anyklaýyş bu platformada elýeterli däl.';

  @override
  String get extErrRevoked => 'Sora topary bu giňeltmäniň wersiýasyny howply ýa-da bozuk bolany üçin yzyna aldy.';

  @override
  String get extErrRevocationsExpired => 'Ýatyrylan giňeltmeleriň sanawy täzelenýänçä gurnama petiklenen.';

  @override
  String extRevokedDisabled(String names) {
    return 'Yzyna alnan giňeltmeler öçürildi: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Gizlin açar';

  @override
  String get customServerWgAddresses => 'Interfeýs salgylary';

  @override
  String get customServerWgPeerKey => 'Serweriň açyk açary';

  @override
  String get customServerWgPresharedKey => 'Umumy açar';

  @override
  String get customServerWgAllowedIps => 'Rugsat berlen IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, sekunt';

  @override
  String get customServerWgKeyInvalid => 'WireGuard açary nädogry';

  @override
  String get customServerWgCidrInvalid => 'CIDR prefiksi nädogry';

  @override
  String get customServerWgKeepaliveInvalid => 'Keepalive aralygy nädogry';

  @override
  String get strictKillSwitch => 'Berk tor gulpy';

  @override
  String get strictKillSwitchWarning => 'Çykandan soň VPN daşyndaky traffigi blokirlemelimi?';

  @override
  String get extWorkerFailed => 'Giňeltmäniň fon işi şowsuz boldy';

  @override
  String get extAssetRejected => 'Giňeltme faýlynda okamagy kynlaşdyrýan reňkler ýa-da nädogry düzgünler bar';

  @override
  String get extVerifiedSora => 'Sora tarapyndan barlanan';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Aç';

  @override
  String get customServerOwn => 'Şahsy serwer';

  @override
  String get customServerPaste => 'Salgyny goý';

  @override
  String get customServerUser => 'Ulanyjy ady';

  @override
  String get customServerPassword => 'Açar sözi';

  @override
  String get customServerSecretRequired => 'Baha görkezilmedi';

  @override
  String get customServerLinkInvalid => 'Serwer salgysy nädogry';

  @override
  String get errInternal => 'Sora içki ýalňyşlygy';

  @override
  String get errTls => 'Serweriň sertifikaty ret edildi';

  @override
  String get errFileAccess => 'Faýla girip bolmaýar';

  @override
  String get errDataLimit => 'Maglumat aşa köp';

  @override
  String get errCredentials => 'Ýatda saklanan giriş maglumatlary ýok';

  @override
  String subscriptionStale(String time) {
    return 'Täzelenen wagty: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Entek täzelenmedi';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Serwer HTTP $status koduny gaýtardy',
      zero: 'Serwer talaby ret etdi',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Serwer sazlamalary doly däl ýa-da goldanylmaýar';

  @override
  String get errServerIds => 'Iki serweriň kesgitleýjisi birmeňzeş';

  @override
  String get errRoutingGroup => 'Marşrut ýok serwerlere ýa-da bozulan topara salgylanýar';

  @override
  String get errConnections => 'Birikmeleriň sanawy elýeterli däl';

  @override
  String get errLogs => 'Bu hyzmat žurnal ýöretmeýär';

  @override
  String get errDiagnostics => 'Diagnostikany ýygnap bolmady';

  @override
  String get errMissingItem => 'Soralan element indi ýok';

  @override
  String get errInvalidRequest => 'Haýyşda nädogry bahalar bar';

  @override
  String get errProxyLogin => 'Ulgam proksisi bu girişi goldamaýar';

  @override
  String get errLogFilter => 'Žurnal süzgüji nädogry';

  @override
  String get errSubRedirect => 'Serwer howply salga gönükdirdi';

  @override
  String get errProxySetup => 'Ulgam proksisini sazlap bolmady';

  @override
  String get notificationsToday => 'Şu gün';

  @override
  String get notificationsYesterday => 'Düýn';

  @override
  String get notificationsMarkRead => 'Ählisini okalan diýip belle';

  @override
  String get notificationsUnread => 'Okalmadyk';

  @override
  String get desktopNotifications => 'Iş stoly habarnamalary';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Abunalygyň täzelenme aralygy nädogry';

  @override
  String get errRule => 'Ugurlama düzgüninde ýalňyşlyk bar';

  @override
  String get errDns => 'DNS sazlamalary nädogry';

  @override
  String get errEndpoint => 'Barlanjak serweriň salgysy nädogry';

  @override
  String get errCancelled => 'Talap ýatyryldy';

  @override
  String get customServerOptions => 'Birikme sazlamalary';

  @override
  String get customServerTransport => 'Geçiriş';

  @override
  String get customServerSecurity => 'Howpsuzlyk';

  @override
  String get customServerCipher => 'Şifr';

  @override
  String get customServerWgInterface => 'Interfeýs';

  @override
  String get customServerWgPeer => 'Deňdeş';

  @override
  String extAvailableOn(String platforms) {
    return 'Elýeterli platformalar: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Ähli programmalaryň TCP traffigini üýtgetmelimi?';

  @override
  String get winwsRequirements => 'Bu VPN tertibi elýeterli däl';
}
