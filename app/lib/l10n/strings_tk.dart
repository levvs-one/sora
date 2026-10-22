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
  String get errAuth => 'Sora hyzmatyna girip bolmaýar';

  @override
  String get errVersion => 'Sora täzeläň: programma we hyzmat dürli wersiýalar';

  @override
  String get errBusy => 'Duruň, öňki buýruk henizem işleýär';

  @override
  String get errEngineMissing => 'Bu serwer üçin motor tapylmady';

  @override
  String get errEngineStart => 'Motor başlamady';

  @override
  String get errEngineStopped => 'Motor saklandy';

  @override
  String get errTunnel => 'VPN birikmesini döretmäge rugsat ýok';

  @override
  String get errServers => 'Serwer ýalňyşlyk bilen düzüldi';

  @override
  String get errNetwork => 'Serwere baryp bolmaýar';

  @override
  String get errTimeout => 'Serwer wagtynda jogap bermedi';

  @override
  String get errFirewall => 'VPN-den başga internedi ýapyp bolmady';

  @override
  String get errSubFetch => 'Abuna ýazylmady';

  @override
  String get errSubFormat => 'Bu abuna ýazgy däl';

  @override
  String get errSubEmpty => 'Abuna ýazylanda serwer ýok';

  @override
  String get errSubDuplicate => 'Bu abuna ýazyldy';

  @override
  String get errSubLimit => 'Abunalar gaty köp';

  @override
  String get errSubScheme => 'Baglanyşyk https: // bilen başlamaly';

  @override
  String get errSecretStore => 'Sora ammary zaýalanýar ýa-da elýeterli däl';

  @override
  String get errNoServers => 'Birikdirmek üçin abuna ýazyň';

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
  String get rangeHint => 'Mysal üçin, 100-200';

  @override
  String get splitPos => 'Positionerleşýän ýerleri';

  @override
  String get splitPosHint => 'Mysal üçin, 1, orta';

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
  String controlPortQuestion(String engine) {
    return '$engine bu kompýuterdäki port arkaly dolandyrylýar. Beýleki programmalar bir VPN-iň açykdygyny aýdyp bilerler.';
  }

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
      other: 'abunalyk # günlerinde tamamlanýar',
      one: 'abunalyk # güni tamamlanýar',
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
      other: '# serwerleri, iň çalt',
      one: '# serweri, iň çalt',
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
  String get launchAtLoginDetail => 'Ulgama gireniňizde Sora awtomatiki işe girizer we lotoqda galar.';

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
  String get noticeInTrayBody => 'Nyşanasynyň menýusyndan çykyň';

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
  String get importSealed =>
      'Bu baglanyşyk Happ üçin kodlanýar we ony diňe Happ okap biler. Adaty abuna baglanyşygy üçin üpjün edijiňizden soraň.';

  @override
  String get understood => 'Bolýar';

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
  String get notificationsEmpty => 'Baglanyşyk we abuna wakalary şu ýerde peýda bolar';

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
  String get programsEmpty => 'Programmalar tapylmady Başga bir at synap görüň.';

  @override
  String get selectExe => '.Exe faýly saýlaň';

  @override
  String get speedtest => 'Tizlik';

  @override
  String get speedtestSearch => 'Hyzmat tapyň';

  @override
  String get speedtestEmpty => 'Gabat gelenok. Gözlegi üýtgediň.';

  @override
  String get speedtestBackToList => 'Hyzmatlara dolan';

  @override
  String get speedtestOpenBrowser => 'Brauzerde açyň';

  @override
  String get speedtestUnavailable => 'Içerki brauzer başlap bilmedi. Hyzmaty ulgam brauzeriňizde açyň.';

  @override
  String get speedtestPageFailed => 'Sahypa ýükläp bilmedi. Ony täzeden ýükläň ýa-da ulgam brauzeriňizde hyzmaty açyň.';

  @override
  String get speedtestExternalFailed => 'Ulgam brauzeri açyp bilmedi. Gaýtadan synanyşyň.';

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
  String get updateDropWarning =>
      'Sora we esasy täzelenmesi bilen VPN birikmesi birnäçe sekuntlap ​​pese gaçar. Dowam et?';

  @override
  String get updateWaitConnection => 'VPN birikmesiniň we ýadrosynyň taýýar bolmagyna garaşyň.';

  @override
  String get updateDownloading => 'Faýllary göçürip almak we barlamak ...';

  @override
  String get updateInstalling => 'Täzelenmäni taýýarlamak ýa-da administratoryň tassyklanmagyna garaşmak ...';

  @override
  String get updateNetworkError => 'Täzelenmäni göçürip alyp bolmady Gaýtadan synanyşyň.';

  @override
  String get updateReleaseError => 'Goýberilýän maglumatlar ýa-da zerur faýllar ýok ýa-da nädogry.';

  @override
  String get updateChecksumError => 'Göçürip almak SHA256SUMS bilen gabat gelenok. Hiç zat gurulmady';

  @override
  String get updateInstallError => 'Täzelenme gutarmady. Hakyky tanamaklyk ýatyrylan bolmagy mümkin.';

  @override
  String get updateUnsupported =>
      'Bu ýerine ýetirip boljak, goldanýan Sora paket jübütine degişli däl. Goýberiş gurnama görkezmelerini ulanyň.';

  @override
  String get updateManual =>
      'Barlanylan paketleri gurmak üçin bu buýrugy terminalda işlediň, soňra Sora açyň. Faýllar göçürip almak katalogynda galýarlar. VPN birikmesi peseler.';

  @override
  String get updateSignaturePending =>
      'Täzelenme faýllary goýberiliş bilen çap edilen barlag jemleri bilen deňeşdirilýär.';

  @override
  String get updateManualSigWarning =>
      'Aşakdaky faýllar goýberilişiň barlag jemlerine laýyk gelýär. Olary resmi goýberilişden ýükläp alan bolsaňyz, buýrugy ýerine ýetiriň.';

  @override
  String get updateVersionRevoked =>
      'Dörediji bu wersiýany yzyna aldy. Düzedilen goýberilişine garaşmagyňyzy haýyş edýäris.';

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
  String get updateRollbackError =>
      'Awtomatiki yza gaýtmak şowsuz. Täze wersiýa işlemese, öňki goýberilişi el bilen täzeden guruň.';

  @override
  String get updateRollbackCacheError =>
      'Häzirki wersiýanyň tassyklanan yzyna gaýtarylan nusgasyny taýýarlap bolmady, şonuň üçin täzelenme gurulmady.';

  @override
  String get updateCopyCommand => 'Buýrugy göçüriň';

  @override
  String get updateChecksDisabled => 'Sazlamalarda awtomatiki barlaglar ýapylýar.';

  @override
  String get updateInstalled => 'Täzelenme guruldy Sora açyň.';

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
  String get pendingConnectionChanges => 'Bu üýtgeşmeleri ulanmak üçin gaýtadan birikdiriň.';

  @override
  String get reconnectNow => 'Goşuň we gaýtadan birikdiriň';

  @override
  String get errEngineUnsupported =>
      'Saýlanan hereketlendiriji bu profili ýa-da sazlamalary goldamaýar. Awto ýa-da gabat gelýän dwigateli saýlaň.';

  @override
  String get errRestore =>
      'Baglanyşygy arassalamak doly däldi. Aýyrmak üçin gaýtadan synanyşyň; jikme-jiklikler üçin gündelige serediň.';

  @override
  String get errSessionEnded => 'Bu sessiýa eýýäm tamamlandy. Baglanyş ýagdaýyny täzeläň.';

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
      'Serweriňiziň haýsy motora mätäçdigini bilmeýän bolsaňyz, Awto saýlaň. Sora birikmezden ozal profil we sazlamalary barlaýar. Dwigatel meýilnamaňyzyň geçiriş giňligini artdyryp bilmez: öndürijilik serwere, ugra, protokola we tora baglydyr.\n\n## Reesimler\n\n### traffichli traffik (TUN)\n\nSora wirtual tor interfeýsini döredýär we TCP we UDP ýaly programma trafigini ugrukdyrýar. Bu re modeimi Telegram, oýunlar we Discord sesi üçin ulanyň. Düzgünler belli bir saýtlary ýa-da programmalary gönüden-göni iberip ýa-da blokirläp biler. Tor hyzmaty, zerur protokoly goldaýan serwere we serwere mätäç.\n\n### System proksi\n\nSora ýerli HTTP / SOCKS proksi düzýär. Ulgam proksi sazlamalaryna hormat goýýan programmalar ony ulanýarlar. Öz torlary bilen goýmalar gönüden-göni birigip biler; UDP we sesli jaňlar adatça TUN gerek. Bu re modeim proksi goldawy bilen brauzerlere we programmalara laýyk gelýär.\n\n### Serwer ýok\n\nLinux-de, Sora HTTP / TLS haýyşlaryny bölmek we üýtgetmek we käbir DPI barlaglaryndan aýlanyp geçmek üçin [zapret] (https://github.com/bol-van/zapret) ulanýar. IP-iňiz şol bir ýagdaýda galýar we birikmeler göni web sahypasyna gidýär. Netijeler üpjün edijiňize we blokirleme usulyna baglydyr.\n\nHäzirki integrasiýa, TCP-den HTTP we TLS üçin tpws ulanýar. IP blokirlemesinden ýa-da UDP-den geçmeýär we Telegram-iň MTProto birikmelerini kepillendirip bilmeýär. Discord sesi, Telegram jaňlary we bu hili çäklendirmeler üçin TUN bilen VPN serwerini ulanyň.\n\n## Dwigateller\n\n### Awto\n\nSora ähli birikme meýilnamasyny goldaýan gurnalan hereketlendirijini saýlaýar: serwer protokollary, transportlar, toparlar, böleklere bölüniş we re modeim. Gabat gelmeýän el bilen saýlamak, häzirki baglanyşygy togtatmazdan ozal ret edilýär. Awto ýa-da başga dwigateli saýlaň we sazlamalary täzeden ulanyň.\n\n### sing-box\n\nTäze Sora paketleri [sing-box-lx] (https://github.com/Leadaxe/sing-box-lx), [sing-box] (https://github.com/SagerNet/sing-box), müşderi tarapyna XHTTP we VLESS Encryption goşýar. Sora gurluşy we mümkinçiliklerini ykrar edýär. XHTTP bolmazdan ýokary akym gurmak, diňe öz adyndan bu mümkinçiligi gazanyp bilmez.\n\nGoldaw berlen protokollara VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard we WireGuard we AmneziaWG AmneziaWG Doly Xray JSON profilleri Xray talap edýär. Täze AWG 3.x meýdanlaryny entek import edip bolmaýar. sing-box kompýuterdäki beýleki programmalaryň tapyp bilýän parol bilen goralýan ýerli dolandyryş portuny ulanýar.\n\n### Xray\n\n[Xray-core] (https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption we TLS böleklerini goldaýar. Şeýle hem, marşrutlaryny we toparlaryny gorap saklamak bilen doly üpjün ediji Xray profilini işleýär. Şeýle profilleri özlerini alyp barşyny üýtgetmän awtomatiki usulda başga motora öwrüp bolmaz.\n\nBaglanan Xray TLS şahadatnamasyny tassyklamagy (\"allowInsecure\") ýapýan sazlamany aýyrdy. Awto bu sazlamany talap edýän adaty serwerler üçin sing-box ýa-da mihomo saýlaýar. Xray saýlamak, häzirki birikmäni togtatmazdan ozal gabat gelmeýändigini habar berýär. Has köne JSON profillerinde barlanylýan şahadatnama ýa-da şahadatnama pin bilen täzelenen üpjün ediji profiline mätäç.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) ätiýaçlyk serwere yzygiderli geçiş toparlaryny, ýük paýlaşmagy, XHTTP we AmneziaWG goldaýar. Ätiýaçlyk serwere awtomatik geçmek möhüm bolsa, ony saýlaň. Sora-nyň TLS bölekleme sazlamasy bu ýadro bilen elýeterli däl.\n\n## Sora-de laýyklyk\n\n| Aýratynlyk | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN we TCP / UDP | Hawa | Hawa | Hawa |\n| XHTTP | Hawa | Hawa | Hawa |\n| VLESS Encryption | Hawa | Hawa | Hawa |\n| Doly Xray tertibi | | Ok | Hawa | | Ok |\n| TUIC / AnyTLS | Ikisi | | Ok | TUIC |\n| mieru | Ýok | Ýok | Hawa |\n| NaiveProxy | Hawa | Ýok | Ýok |\n| TLS bölekleri | Hawa | Hawa | | Ok |\n| AmneziaWG 1.x / 2.x | Hawa | | Ok | Hawa |\n| Yza gaýdyp gelen topar | | Ok | ²ok | Hawa |\n\nZ J1/J2/J3/Itime bolan profiller mihomo ulanýar; bu meýdanlar hiç haçan sessiz-üýnsüz taşlanmaly däldir. Complete Doly Xray profilleriniň topary üçin programma ätiýaçlyk profilini saýlaýar. Goldaw gurlan gurna baglydyr; hakda wersiýasyny barlaň.\n\n## TUN ýygyndysy\n\nStack wirtual interfeýsiň içinde TCP we UDP işleýär. Reesimler panelinde Xray we mihomo gVisor, System, Mixed we MIPS hödürleýär. Her hereketlendiriji öz islegini tygşytlaýar. System proksi we Serwersiz reesimler bu ileri tutmany ulanmaýarlar.\n\n- ** Mixed ** - TCP ulgam stakasyny ulanýar, gVisor bolsa UDP işleýär. Bu Linux-da mihomo üçin başlangyç görnüşdir. Windows-da Xray we mihomo başlangyç görnüş hökmünde MIPS ulanýar.\n- ** System ** - ulgam toplumyny ulanýar. Tor programmalarynda kynçylyklar ýüze çyksa, başga bir warianty synap görüň.\n- ** gVisor ** - ulanyjy giňişliginde traffigi dolandyrýar.\n- ** MIPS ** - mihomo-iň öz IP ýygyndysy, birleşdirilen 1.19.32 wersiýasynda bar.\n\nLinux-de, Xray gurnalan gVisor deslapky görnüşde ulanýar. Linux-de System, Mixed we MIPS mihomo-ni TUN hereketlendirijisi hökmünde ulanyp, TCP we UDP-ni tassyklanan ýerli SOCKS baglanyşygy arkaly Xray-e ugradýar. Xray protokoly, üpjün edijiniň profilini we marşrutyny saklaýar. Bu üç wariant gurnalan mihomo talap edýär. Windows-de Xray dört TUN stekiniň hemmesi üçin mihomo 1.19.32 ýa-da has täze wersiýany ulanýar. Protokollar we ugur kesgitlemek Xray-da galýar. Bu birleşmede programma düzgünleri diňe göni birikmäni we bloklamagy goldaýar; Linux-de bu düzgünler Xray-yň içindäki gVisor stekini talap edýär.\n\nKöprü ikinji gezek işleýär. Linux-de üç sany boş ölçegde, ýerli Xray TUN-dan has takmynan 32–36 MiB fiziki ýat ulanyldy. Bu göçürip almak ýüküni ölçemeýär: CPU we ýat çykdajylary birikmelere baglydyr. sing-box-de hiç hili saýlaýjy ýok. Hiç bir stak her ulgamda has gowy işlemegi kepillendirmeýär. Ackygyndy saýlaň we toruňyzda synap görmek üçin “Apply” -y täzeden birikdiriň.\n\n## Sazlamalary ulanmak\n\nSerwer saýlamak awtomatiki birikdirilýär. Reodeim, hereketlendiriji, DNS we düzgün sazlamalary derrew saklanýar; işjeň birikme wagtynda, \"Goý\" düwmesine basyň we olary ulanmak üçin gaýtadan birikdiriň. Dwigateli täzeden açmak ýüklemeleri we jaňlary kesip biler. Gaýtalanyp basmak parallel baglanyşyklara başlamaz; aýyrmak birikmäni tamamlaýar we baglanyşygy boşadýar.\n\nInternet diňe VPN arkaly tunel gaçanda göni traffigi bloklaýar. Tutuş maşyna täsir edýär. Açyk aýyrmak Sora düzgünlerini aýyrýar. Arassalamak gutarmasa, birikmäni täzeden synap görüň we gündeligi açyň.\n\n## Taslama resminamalary\n\n- [sing-box-lx: konfigurasiýa we goldaw] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box resminamalary] (https://sing-box.sagernet.org/)\n- [Xray resminamalary] (https://xtls.github.io/)\n- [mihomo resminamalary] (https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: iş we çäklendirmeler] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC TCP trafikini Jitsi, Yandex Telemost ýa-da WB Stream wideo jaňynyň üsti bilen geçirýär. olcrtc:// baglanyşygyny ýa-da QR koduny import ediň. Proksi we TUN režimlerinde sing-box, Xray we mihomo bilen işleýär; UDP goldanylmaýar. Iki tarapa-da gabat gelýän OLC2 ýygyndylary gerek. Başlangyç taslama arhiwlenen.\n';

  @override
  String get probeServers => 'Serwerleri barlaň';

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
  String get extBadgeVerified => 'Barlandy';

  @override
  String get extBadgeTop => 'Şu hepde iň meşhur';

  @override
  String get extBadgeNew => 'Täze';

  @override
  String get extBadgeStaff => 'Sora topary';

  @override
  String get extSideloadShort => 'Katalogdan däl';

  @override
  String get extSideloadWarning =>
      'Bu giňeldiş toparyň katalogyndan däl. Awtor öz açaryny diňe özi tassyklaýar: diňe awtora ynanýan bolsaňyz gurnaň.';

  @override
  String extInstallTitle(String name) {
    return '«$name» gurna';
  }

  @override
  String extUpdateTitle(String name) {
    return '«$name» täzele';
  }

  @override
  String get extPermissionsIntro => 'Bu giňeldiş aşakdakylary edip biler:';

  @override
  String get extPermissionsWidened => 'Täzelenme täze rugsatlar soraýar:';

  @override
  String get extDangerousAck => 'Bu rugsatlaryň çynlakaýdygyna düşünýärin';

  @override
  String get extInstall => 'Gurna';

  @override
  String get extUpdate => 'Täzele';

  @override
  String get extCancel => 'Ýatyr';

  @override
  String get extConfirm => 'Tassykla';

  @override
  String get extOk => 'OK';

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
  String get extEmptyInstalled => 'Entek giňeltmeler ýok.\nKatalogdan birini tapyň ýa-da bir faýldan guruň.';

  @override
  String get extInstallFromFile => 'Faýldan guruň';

  @override
  String get extInstallFromUrl => 'URL-dan guruň';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Göçürip al';

  @override
  String get extDownloading => 'Göçürilip alynýar…';

  @override
  String get extVerifying => 'Barlanylýar…';

  @override
  String get extInstalling => 'Gurnalýar…';

  @override
  String get extInstallFailed => 'Gurmak şowsuz';

  @override
  String get extErrSignature => 'Gol barlagy şowsuz boldy. Faýl zaýalanan ýa-da üýtgedilen bolup biler.';

  @override
  String get extErrManifest => 'Giňeldiş manifesti nädogry.';

  @override
  String get extErrNetwork => 'Tor ýalňyşlygy. Baglanyşygyňyzy barlaň we gaýtadan synanyşyň.';

  @override
  String get extErrHash => 'Göçürilen faýl katalogdakysyna gabat gelmeýär. Ol üýtgedilen bolup biler.';

  @override
  String extErrMinApp(String version) {
    return 'Bu giňeltme $version ýa-da has täze programma wersiýasy gerek.';
  }

  @override
  String get extErrHttpsOnly => 'Diňe https:// baglanyşyklara rugsat berilýär';

  @override
  String get extErrGeneric => 'Bir zat nädogry boldy. Gaýtadan synanyşmagyňyzy haýyş edýäris.';

  @override
  String get extErrAuthorKeyChanged =>
      'Bu täzelenme, gurnalan wersiýadan başga awtor açary bilen gol çekildi, şonuň üçin ol petiklendi. Täze açara ynanýan bolsaňyz, giňeltmäni aýyryň we aç-açan guruň.';

  @override
  String get extUpdateAvailable => 'Täzelenme elýeterli';

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
  String get extConflictsIntro =>
      'Bu giňeltmeler şol bir zady isleýär. Haýsysynyň işlejegini saýlaň, beýlekisi gurnalgy galar.';

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
    return '$count dawalary siziň kararyňyza mätäç';
  }

  @override
  String get extConflictsResolve => 'Dawa-jenjelleri çözüň';

  @override
  String get extConflictNote =>
      'Saýlawyňyz şu enjamda saklanýar. Tema derrew çalşýar, tor hook-lary bu wersiýada işlemeýär.';

  @override
  String extVersionLabel(String version) {
    return 'Wersiýa $version';
  }

  @override
  String get extAuthor => 'Awtory';

  @override
  String get extRating => 'Reýting';

  @override
  String get extInstalls => 'Gurnamalar';

  @override
  String get extVersion => 'Wersiýa';

  @override
  String get extAbout => 'Bu giňeltme hakda';

  @override
  String get extPermissionsTitle => 'Rugsatlar';

  @override
  String get extNoPermissions => 'Ýörite rugsatlar gerek däl.';

  @override
  String get extSettings => 'Sazlamalar';

  @override
  String get extSaveSettings => 'Sazlamalary ýazdyryň';

  @override
  String get extSaving => 'Saklanylýar…';

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
  String get extPanelUnavailable => 'Panel elýeterli däl. Giňeldiş öçürilen ýa-da aýrylan bolmagy mümkin.';

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
  String get extPermRoutingRules => 'Ugurlandyryş düzgünlerini goşmak (tor trafiginiň ugruna täsir edýär)';

  @override
  String get extPermNetHooks => 'Tor ýoluna goşulyň (DPI aýlaw modullary)';

  @override
  String get extPermNetFetch => 'Rugsat berlen sanawdan URL haýyş';

  @override
  String get extPermBackground => 'Fon meselelerini işlediň';

  @override
  String get extPermBackgroundDetail =>
      'Panel ýapylanda-da meýilleşdirilen işleri ýerine ýetirýär. Ony duruzyp ýa-da giňeltme sazlamalarynda näçe gezek işleýändigini üýtgedip bilersiňiz.';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

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
  String get extRatingHow => 'Reýtingleriň nähili işleýändigi';

  @override
  String get extRatingHowBody =>
      'Reýtingler Baýziýanyň ortaça derejesini ulanýar: az bahaly giňeltme, köp adam ses berýänçä ortada galar, şonuň üçin 5 ýyldyzly ýekeje syn täze uzaldyşy ýokarsyna çykaryp bilmez. Soňky reýtingleriň agramy köne bahalardan has köp we hasap üçin diňe bir reýting hasaplanýar.';

  @override
  String get extScreenshots => 'Ekran suratlary';

  @override
  String get extSortRelevance => 'Degişlilik';

  @override
  String get extPermNetworkDetail =>
      'Internetden VPN arkaly maglumat alýar. Diňe aşakdaky sanawdaky hostlara rugsat berilýär, galanlary bloklanýar.';

  @override
  String get extBgTitle => 'Fon işi';

  @override
  String get extBgEnabled => 'Fonda işletmek';

  @override
  String get extBgInterval => 'Işletmek aralygy';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# minut', one: '# minut');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# sagat', one: '# sagat');
    return '$_temp0';
  }

  @override
  String get extBgNote =>
      'Sora açyk wagty, şol sanda traýda wagty hem, tabşyryk meýilnama boýunça işleýär. Iň gysga aralyk 15 minut.';

  @override
  String get extBgDisabledNote => 'Fon işini dolandyrmak üçin giňeldişi işjeňleşdiriň.';

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
  String get diagnosticNoData => 'Entek ýazylan haýyş ýok. Ilki bilen tizlik synag web sahypasyny açyň.';

  @override
  String get qrShareTitle => 'QR kody paýlaşyň';

  @override
  String get qrScanTitle => 'QR kody skanirläň';

  @override
  String get qrCopyLink => 'Baglanyşygy göçüriň';

  @override
  String get qrShowLink => 'Baglanyşyk görkeziň';

  @override
  String get qrHideLink => 'Baglanyşygy gizläň';

  @override
  String get qrWarning => 'Bu QR kody birikme maglumatlaryny öz içine alýar. Nätanyş adamlara görkezmäň.';

  @override
  String get qrScanHint => 'QR kodly ekran suratyny ýa-da suraty saýlaň, ýa-da salgyny goýuň';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# birikme', one: '# birikme');
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
  String get sortBy => 'tertipläň';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Tizlik';

  @override
  String get sortName => 'Ady';

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
  String get coreWatchUnstable => 'Sora ýadrosyna birikmek durnuksyz';

  @override
  String get watchReconnect => 'Täzeden birik';

  @override
  String get coreRestoringLink => 'Sora ýadrosyna birikmäni dikeltmek…';

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
  String get errBenchmarkUnsupported => 'Tizligi ölçemek has täze ýadro gerek';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total-den $done ölçemek…';
  }

  @override
  String get profiles => 'Tor profilleri';

  @override
  String get profilesEmpty => 'Entek profil ýok. Belli ulgamlarda sazlamalary awtomatiki ulanmak üçin birini dörediň.';

  @override
  String get profileAdd => 'Profil goşuň';

  @override
  String get profileName => 'Profiliň ady';

  @override
  String get profileSsids => 'Wi-Fi torlary (SSID)';

  @override
  String get profileSsidsHint => 'Öý, ofis vergul bilen bölünýär';

  @override
  String get profileGateways => 'Tor şlýuzalary';

  @override
  String get profileAsns => 'AS sanlar';

  @override
  String get profileAutoApply => 'Awtomatiki ulanmak';

  @override
  String get profileAutoApplyHint => 'Öçürilen bolsa, profili ulanmazdan öň tassyklama soralýar.';

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
  String get profileNoTriggers => 'Iň azyndan bir trigger goşuň: SSID, şlýuz ýa-da ASN';

  @override
  String get chains => 'Proksi zynjyrlary';

  @override
  String get chainsEmpty => 'Entek zynjyr ýok. 2-3 serweri baglanyşdyryň, şonuň üçin olaryň hersinden trafik çykýar.';

  @override
  String get chainAdd => 'Täze zynjyr';

  @override
  String get chainName => 'Zynjyryň ady';

  @override
  String get chainPickServers => '2-3 serwer saýlaň';

  @override
  String get chainOrderHint => 'Tertibe salmak üçin süýräň: traffik ýokarsyna girýär we aşagyndan çykýar.';

  @override
  String get chainTooFew => 'Iň azyndan 2 serwer saýlaň';

  @override
  String get chainTooMany => 'Zynjyr iň köp 3 serwerde saklanýar';

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
  String get chainUnsupported => 'Häzirki motor zynjyr gurup bilmeýär';

  @override
  String get chainHopMissing => 'Zynjyr serwerlerinden biri indi elýeterli däl';

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
  String get syncEmpty => 'Jübütlenen enjam ýok. Ýerli tor arkaly başga enjamy jübütläň.';

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
  String get syncNoLan => 'Enjamlar şol bir ýerli ulgamda bolmaly';

  @override
  String get syncPaired => 'Enjam jübütlendi';

  @override
  String get syncPairingTitle => 'Bu enjam bilen jübütläň';

  @override
  String get syncWaiting => 'Beýleki enjama garaşmak…';

  @override
  String get syncSecureNote => 'Kanal uçdan-uja şifrlenen. Hasap we bulut serwerleri gerek däl.';

  @override
  String get zapretWithVpn => 'Göni tor trafigi üçin süzgüçden DPI aýlaň';

  @override
  String get zapretWithVpnHint =>
      'zapret VPN tuneli bilen bir wagtda işleýär: tuneliň trafigi VPN arkaly, göni trafik bolsa böwetden aýlanyp geçiş serişdesi arkaly geçýär.';

  @override
  String get chainDuplicate => 'Her serwer diňe bir gezek peýda bolup biler';

  @override
  String get edit => 'Redaktirläň';

  @override
  String get remove => 'Aýyr';

  @override
  String get autoSwitchOnDegrade => 'Hil pese düşende awtomatiki geçmek';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Saýlanan serwer ep-esli haýallasa ýa-da jogap bermese, Sora ölçeg boýunça iň gowy serwere geçýär, ýöne her 10 minutda bir gezekden köp däl.';

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
  String get customServerNameHint => 'Mysal üçin: meniň VPS';

  @override
  String get customServerNameRequired => 'Adyny giriziň';

  @override
  String get customServerAddress => 'Salgysy';

  @override
  String get customServerAddressHint => 'example.com ýa-da 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Serweriň salgysyny giriziň';

  @override
  String get customServerAddressInvalid => 'Nädogry salgy';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Port 1-den 65535-e çenli san bolmaly';

  @override
  String get customServerProtocol => 'Protokol';

  @override
  String get customServerCredentials => 'Giriş maglumatlary';

  @override
  String get customServerOptional => 'Hökmany däl';

  @override
  String get customServerShowSecret => 'Gizlin maglumaty görkez';

  @override
  String get customServerHideSecret => 'Gizlin maglumaty gizle';

  @override
  String get customServerBadge => 'şahsy';

  @override
  String customServerDeleteConfirm(String name) {
    return '“$name” serwerini pozuň?';
  }

  @override
  String get customServerEmptyHint => 'Serweri el bilen goşuň: salgy, port we protokol';

  @override
  String get customServerTest => 'Synag';

  @override
  String get leakTestTitle => 'Maglumatlaryň syzmagy üçin synag';

  @override
  String get leakTestIntro =>
      'Trafigiň enjamdan tuneliň daşyndan çykyp bilýändigini barlaýar: göni DNS we ICMP talaplary, IPv6 çykyşy we ulgamyň at çözüjileri. Birikme işjeň wagty işlediň.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# syzma tapyldy', one: '# syzma tapyldy');
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
  String get syncDaemonMissing => 'sora-sync komponenti tapylmady. Enjamy sinhronlamak üçin programmany täzeden guruň.';

  @override
  String get syncDaemonStarting => 'Sinhronlamak hyzmatyna başlamak…';

  @override
  String get syncErrAuth =>
      'Sinhronlamak hyzmaty giriş belligini ret etdi. Programmany täzeden açyň we gaýtadan synanyşyň.';

  @override
  String get syncErrNotFound => 'Enjam indi jübütlenenok';

  @override
  String get syncErrPairingActive => 'Jübütlemek sessiýasy eýýäm açyk';

  @override
  String get syncErrUnreachable => 'Beýleki enjam jogap bermedi. Şol bir torda we koduny görkezýändigine göz ýetiriň.';

  @override
  String get syncError => 'Sinhronizasiýa säwligi';

  @override
  String syncExpiresIn(String duration) {
    return 'Kodyň möhleti $duration soň gutarýar';
  }

  @override
  String get syncJoining => 'Enjam bilen jübütlemek…';

  @override
  String get syncLegacyCleared =>
      'Köne enjamlaryň sanawy aslynda jübütlenmedi, şonuň üçin arassalandy. Enjamlaryňyzy täzeden jübütläň, bu gezek hakyky.';

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
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Shadowsocks üçin: usul:açar sözi, mysal üçin chacha20-ietf-poly1305:password';

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
  String get extErrRevocationsExpired =>
      'Yzyna alnan giňeltmeleriň sanawyny täzeläp bolmady. Täzelenýänçä gurnamak ýapyk: tory barlaň we täzeden synanyşyň.';

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
  String get customServerWgKeyInvalid => 'Açar wg genkey çykarşy ýaly base64-de 32 baýt bolmaly.';

  @override
  String get customServerWgCidrInvalid => 'Otur bilen bölünen prefiksleri giriziň, meselem 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => '0-dan 65535-e çenli sekunt sanyny giriziň.';

  @override
  String get strictKillSwitch => 'Berk tor gulpy';

  @override
  String get strictKillSwitchWarning =>
      'Birikdirilenden soň näsazlyk, gaýtadan başlatmak ýa-da programmadan çykmak wagtynda hem VPN-den daşarky traffigi petikleýär. Giriş diňe baglanyşyk kesilende ýa-da bu sazlama öçürilende dikeldilýär. Enjam gaýtadan açylanda petikleme diňe başlangyçda birikmek işjeň bolsa dowam edýär.';

  @override
  String get extWorkerFailed => 'Giňeltmäniň fon işi şowsuz boldy. Giňeltmäniň ýazgylaryny barlaň.';

  @override
  String get extAssetRejected => 'Giňeltmäniň faýly ret edildi: okalmaýan reňkler ýa-da nädogry düzgünler.';
}
