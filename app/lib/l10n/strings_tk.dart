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
  String get stateFailed => 'Baglanmadyk';

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
  String get connEmpty => 'No connections';

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
  String speedMbps(double value) {
    return '${intl.NumberFormat('0.0', localeName).format(value)} Mbps';
  }

  @override
  String latencyMs(int value) {
    return '$value ms';
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
  String get exportText => 'Tekst';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lightagtylyk';

  @override
  String get themeDark => 'Garaňky';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'System';

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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# serwerleri hem öz gezeginde',
      one: '# serweri hem öz gezeginde',
    );
    return '$_temp0';
  }

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
  String get tunnelTun => 'Traffichli traffik';

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
  String get currentServer => 'Häzirki serwer';

  @override
  String get trafficDown => 'Göçürildi';

  @override
  String get trafficUp => 'Edüklendi';

  @override
  String perSecond(String value) {
    return '$value / s';
  }

  @override
  String activeRules(int count) {
    return 'Işjeň düzgünler: $count';
  }

  @override
  String get recentNotifications => 'Soňky bildirişler';

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
  String get programsFailed => 'Goýmalary ýükläp bolmady';

  @override
  String get programsEmpty => 'Programmalar tapylmady Başga bir at synap görüň.';

  @override
  String get selectExe => '.Exe faýly saýlaň';

  @override
  String get trafficUnavailable => 'Hasaplaýjylar entek elýeterli däl';

  @override
  String get speedtest => 'Tizlik';

  @override
  String get speedtestCheck => 'Tizligi barlaň';

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
  String get appCopyright => '© 2026 levvs-one we goşant goşanlar';

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
  String get bypassLimitations =>
      'Bu re DPim diňe HTTP we TLS üçin DPI-den geçýär, UDP-ni goldamaýar ýa-da IP-ni üýtgetmeýär. Discord sesi, jaňlary we bloklanan Telegram salgylary üçin VPN serwerini ulanyň.';

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
      'Serweriňiziň haýsy motora mätäçdigini bilmeýän bolsaňyz, Awto saýlaň. Sora birikmezden ozal profil we sazlamalary barlaýar. Dwigatel meýilnamaňyzyň geçiriş giňligini artdyryp bilmez: öndürijilik serwere, ugra, protokola we tora baglydyr.\n\n## Reesimler\n\n### traffichli traffik (TUN)\n\nSora wirtual tor interfeýsini döredýär we TCP we UDP ýaly programma trafigini ugrukdyrýar. Bu re modeimi Telegram, oýunlar we Discord sesi üçin ulanyň. Düzgünler belli bir saýtlary ýa-da programmalary gönüden-göni iberip ýa-da blokirläp biler. Tor hyzmaty, zerur protokoly goldaýan serwere we serwere mätäç.\n\n### System proksi\n\nSora ýerli HTTP / SOCKS proksi düzýär. Ulgam proksi sazlamalaryna hormat goýýan programmalar ony ulanýarlar. Öz torlary bilen goýmalar gönüden-göni birigip biler; UDP we sesli jaňlar adatça TUN gerek. Bu re modeim proksi goldawy bilen brauzerlere we programmalara laýyk gelýär.\n\n### Serwer ýok\n\nLinux-de, Sora HTTP / TLS haýyşlaryny bölmek we üýtgetmek we käbir DPI barlaglaryndan aýlanyp geçmek üçin [zapret] (https://github.com/bol-van/zapret) ulanýar. IP-iňiz şol bir ýagdaýda galýar we birikmeler göni web sahypasyna gidýär. Netijeler üpjün edijiňize we blokirleme usulyna baglydyr.\n\nHäzirki integrasiýa, TCP-den HTTP we TLS üçin tpws ulanýar. IP blokirlemesinden ýa-da UDP-den geçmeýär we Telegram-iň MTProto birikmelerini kepillendirip bilmeýär. Discord sesi, Telegram jaňlary we bu hili çäklendirmeler üçin TUN bilen VPN serwerini ulanyň.\n\n## Dwigateller\n\n### Awto\n\nSora ähli birikme meýilnamasyny goldaýan gurnalan hereketlendirijini saýlaýar: serwer protokollary, transportlar, toparlar, böleklere bölüniş we re modeim. Gabat gelmeýän el bilen saýlamak, häzirki baglanyşygy togtatmazdan ozal ret edilýär. Awto ýa-da başga dwigateli saýlaň we sazlamalary täzeden ulanyň.\n\n### sing-box\n\nTäze Sora paketleri [sing-box-lx] (https://github.com/Leadaxe/sing-box-lx), [sing-box] (https://github.com/SagerNet/sing-box), müşderi tarapyna XHTTP we VLESS Encryption goşýar. Sora gurluşy we mümkinçiliklerini ykrar edýär. XHTTP bolmazdan ýokary akym gurmak, diňe öz adyndan bu mümkinçiligi gazanyp bilmez.\n\nGoldaw berlen protokollara VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard we WireGuard we AmneziaWG AmneziaWG Doly Xray JSON profilleri Xray talap edýär. Täze AWG 3.x meýdanlaryny entek import edip bolmaýar. sing-box kompýuterdäki beýleki programmalaryň tapyp bilýän parol bilen goralýan ýerli dolandyryş portuny ulanýar.\n\n### Xray\n\n[Xray-core] (https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption we TLS böleklerini goldaýar. Şeýle hem, marşrutlaryny we toparlaryny gorap saklamak bilen doly üpjün ediji Xray profilini işleýär. Şeýle profilleri özlerini alyp barşyny üýtgetmän awtomatiki usulda başga motora öwrüp bolmaz.\n\nBaglanan Xray TLS şahadatnamasyny tassyklamagy (\"allowInsecure\") ýapýan sazlamany aýyrdy. Awto bu sazlamany talap edýän adaty serwerler üçin sing-box ýa-da mihomo saýlaýar. Xray saýlamak, häzirki birikmäni togtatmazdan ozal gabat gelmeýändigini habar berýär. Has köne JSON profillerinde barlanylýan şahadatnama ýa-da şahadatnama pin bilen täzelenen üpjün ediji profiline mätäç.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) ätiýaçlyk serwere yzygiderli geçiş toparlaryny, ýük paýlaşmagy, XHTTP we AmneziaWG goldaýar. Ätiýaçlyk serwere awtomatik geçmek möhüm bolsa, ony saýlaň. Sora-nyň TLS bölekleme sazlamasy bu ýadro bilen elýeterli däl.\n\n## Sora-de laýyklyk\n\n| Aýratynlyk | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN we TCP / UDP | Hawa | Hawa | Hawa |\n| XHTTP | Hawa | Hawa | Hawa |\n| VLESS Encryption | Hawa | Hawa | Hawa |\n| Doly Xray tertibi | | Ok | Hawa | | Ok |\n| TUIC / AnyTLS | Ikisi | | Ok | TUIC |\n| TLS bölekleri | Hawa | Hawa | | Ok |\n| AmneziaWG 1.x / 2.x | Hawa | | Ok | Hawa |\n| Yza gaýdyp gelen topar | | Ok | ²ok | Hawa |\n\nZ J1/J2/J3/Itime bolan profiller mihomo ulanýar; bu meýdanlar hiç haçan sessiz-üýnsüz taşlanmaly däldir. Complete Doly Xray profilleriniň topary üçin programma ätiýaçlyk profilini saýlaýar. Goldaw gurlan gurna baglydyr; hakda wersiýasyny barlaň.\n\n## TUN ýygyndysy\n\nStack wirtual interfeýsiň içinde TCP we UDP işleýär. Reesimler panelinde Xray we mihomo gVisor, System, Mixed we MIPS hödürleýär. Her hereketlendiriji öz islegini tygşytlaýar. System proksi we Serwersiz reesimler bu ileri tutmany ulanmaýarlar.\n\n- ** Mixed ** - TCP ulgam stakasyny ulanýar, gVisor bolsa UDP işleýär. Bu Linux-da mihomo üçin başlangyç görnüşdir. Windows-da Xray we mihomo başlangyç görnüş hökmünde MIPS ulanýar.\n- ** System ** - ulgam toplumyny ulanýar. Tor programmalarynda kynçylyklar ýüze çyksa, başga bir warianty synap görüň.\n- ** gVisor ** - ulanyjy giňişliginde traffigi dolandyrýar.\n- ** MIPS ** - mihomo-iň öz IP ýygyndysy, birleşdirilen 1.19.32 wersiýasynda bar.\n\nLinux-de, Xray gurnalan gVisor deslapky görnüşde ulanýar. Linux-de System, Mixed we MIPS mihomo-ni TUN hereketlendirijisi hökmünde ulanyp, TCP we UDP-ni tassyklanan ýerli SOCKS baglanyşygy arkaly Xray-e ugradýar. Xray protokoly, üpjün edijiniň profilini we marşrutyny saklaýar. Bu üç wariant gurnalan mihomo talap edýär. Windows-de Xray dört TUN stekiniň hemmesi üçin mihomo 1.19.32 ýa-da has täze wersiýany ulanýar. Protokollar we ugur kesgitlemek Xray-da galýar. Bu birleşmede programma düzgünleri diňe göni birikmäni we bloklamagy goldaýar; Linux-de bu düzgünler Xray-yň içindäki gVisor stekini talap edýär.\n\nKöprü ikinji gezek işleýär. Linux-de üç sany boş ölçegde, ýerli Xray TUN-dan has takmynan 32–36 MiB fiziki ýat ulanyldy. Bu göçürip almak ýüküni ölçemeýär: CPU we ýat çykdajylary birikmelere baglydyr. sing-box-de hiç hili saýlaýjy ýok. Hiç bir stak her ulgamda has gowy işlemegi kepillendirmeýär. Ackygyndy saýlaň we toruňyzda synap görmek üçin “Apply” -y täzeden birikdiriň.\n\n## Sazlamalary ulanmak\n\nSerwer saýlamak awtomatiki birikdirilýär. Reodeim, hereketlendiriji, DNS we düzgün sazlamalary derrew saklanýar; işjeň birikme wagtynda, \"Goý\" düwmesine basyň we olary ulanmak üçin gaýtadan birikdiriň. Dwigateli täzeden açmak ýüklemeleri we jaňlary kesip biler. Gaýtalanyp basmak parallel baglanyşyklara başlamaz; aýyrmak birikmäni tamamlaýar we baglanyşygy boşadýar.\n\nInternet diňe VPN arkaly tunel gaçanda göni traffigi bloklaýar. Tutuş maşyna täsir edýär. Açyk aýyrmak Sora düzgünlerini aýyrýar. Arassalamak gutarmasa, birikmäni täzeden synap görüň we gündeligi açyň.\n\n## Taslama resminamalary\n\n- [sing-box-lx: konfigurasiýa we goldaw] (https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box resminamalary] (https://sing-box.sagernet.org/)\n- [Xray resminamalary] (https://xtls.github.io/)\n- [mihomo resminamalary] (https://wiki.metacubex.one/)\n- [zapret: iş we çäklendirmeler] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Serwerleri barlaň';

  @override
  String get extensions => 'Giňeldişler';
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
    return 'Faýla $name';
  }

  @override
  String get diagnosticHttp => 'HTTP anyklaýyş';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Entek ýazylan haýyş ýok. Ilki bilen tizlik synag web sahypasyny açyň.';

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
