// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class SHi extends S {
  SHi([String locale = 'hi']) : super(locale);

  @override
  String get stateOff => 'जुड़े नहीं हैं';

  @override
  String get stateConnecting => 'कनेक्ट';

  @override
  String get stateConnected => 'जुड़े हुए';

  @override
  String get stateReconnecting => 'पुनः कनेक्ट हो';

  @override
  String get stateDisconnecting => 'डिस्कनेक्ट कर रहा है';

  @override
  String get coreMissing => 'Sora सेवा प्रतिसाद नहीं दे रही है';

  @override
  String get serverAuto => 'सबसे तेजी से';

  @override
  String get serverBypass => 'कोई सर्वर नहीं';

  @override
  String get addSubscription => 'सदस्यता जोड़ें';

  @override
  String get servers => 'सर्वर';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get subscription => 'सदस्यता';

  @override
  String get subscriptionLink => 'सदस्यता लिंक';

  @override
  String get add => 'जोड़ना';

  @override
  String get refresh => 'अद्यतन';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get delete => 'मिटाना';

  @override
  String get cancel => 'रद्द करना';

  @override
  String get save => 'बचाना';

  @override
  String get name => 'नाम';

  @override
  String deleteSubscription(String name) {
    return '\"$name\" हटाएं?';
  }

  @override
  String get routes => 'मार्गों';

  @override
  String get presetGlobal => 'वीपीएन के माध्यम से सब कुछ';

  @override
  String get presetRu => 'रूस प्रत्यक्ष';

  @override
  String get presetIr => 'ईरान प्रत्यक्ष';

  @override
  String get presetCn => 'चीन प्रत्यक्ष';

  @override
  String get blockAds => 'विज्ञापन अवरोधित करें';

  @override
  String get killSwitch => 'इंटरनेट केवल वीपीएन के माध्यम से';

  @override
  String get engine => 'इंजन';

  @override
  String get engineAuto => 'ऑटो';

  @override
  String get animations => 'एनिमेशन';

  @override
  String get logs => 'लकड़ी का लट्ठा';

  @override
  String get about => 'के बारे में';

  @override
  String get logsAll => 'सभी';

  @override
  String get logsImportant => 'महत्वपूर्ण';

  @override
  String get logsErrors => 'त्रुटियाँ';

  @override
  String get search => 'खोज';

  @override
  String get export => 'फाइल को बचाएं';

  @override
  String get clear => 'स्पष्ट';

  @override
  String get logsEmpty => 'यहाँ कुछ भी नहीं है';

  @override
  String get connEmpty => 'कोई कनेक्शन नहीं';

  @override
  String appVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get notInstalled => 'स्थापित नहीं हे';

  @override
  String get sourceCode => 'सोर्स कोड';

  @override
  String get reportProblem => 'समस्या की रिपोर्ट करें';

  @override
  String get license => 'लाइसेंस';

  @override
  String usage(String used, String total) {
    return '$used का $total';
  }

  @override
  String until(String date) {
    return '$date तक';
  }

  @override
  String get expired => 'खत्म हो चुका';

  @override
  String milliseconds(int n) {
    return '$n एमएस';
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
    return '$n बी';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n एमबी';
  }

  @override
  String bytesGB(String n) {
    return '$n जीबी';
  }

  @override
  String bytesTB(String n) {
    return '$n टीबी';
  }

  @override
  String get errGeneric => 'कुछ गलत हो गया';

  @override
  String get errCore => 'Sora सेवा जवाब नहीं दे रही है';

  @override
  String get errAuth => 'Sora सेवा का ऐक्सेस नहीं मिला';

  @override
  String get errVersion => 'Sora ऐप और सेवा के वर्शन अलग हैं';

  @override
  String get errBusy => 'पिछला निर्देश अभी चल रहा है';

  @override
  String get errEngineMissing => 'इस सर्वर के लिए ज़रूरी इंजन नहीं मिला';

  @override
  String get errEngineStart => 'इंजन शुरू नहीं हो सका';

  @override
  String get errEngineStopped => 'इंजन बंद हो गया';

  @override
  String get errTunnel => 'यह VPN मोड उपलब्ध नहीं है';

  @override
  String get errTimeout => 'सर्वर ने समय पर जवाब नहीं दिया';

  @override
  String get errFirewall => 'VPN के बाहर इंटरनेट ऐक्सेस बंद नहीं किया जा सका';

  @override
  String get errSubFetch => 'सदस्यता डाउनलोड नहीं हो सकी';

  @override
  String get deviceIdentity => 'डिवाइस पहचानकर्ता';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'पहचानकर्ता रीसेट करें';

  @override
  String get deviceIdentityResetConfirm => 'डिवाइस पहचानकर्ता रीसेट करें?';

  @override
  String get errSubDeviceLimit => 'डिवाइस सीमा पूरी हो गई';

  @override
  String get errSubDeviceRequired => 'प्रदाता को डिवाइस पहचानकर्ता चाहिए';

  @override
  String get errSubFormat => 'सदस्यता का फ़ॉर्मैट पहचाना नहीं जा सका';

  @override
  String get errSubEmpty => 'सदस्यता में कोई सर्वर नहीं है';

  @override
  String get errSubDuplicate => 'यह सदस्यता पहले से जुड़ी है';

  @override
  String get errSubLimit => 'सदस्यताओं की अधिकतम संख्या पूरी हो गई है';

  @override
  String get errSubScheme => 'सदस्यता लिंक की स्कीम समर्थित नहीं है';

  @override
  String get errSecretStore => 'Sora का स्टोरेज खराब है या उस तक पहुँच नहीं है';

  @override
  String get errNoServers => 'कनेक्ट करने के लिए कोई सर्वर नहीं है';

  @override
  String get connections => 'कनेक्शन';

  @override
  String get close => 'बंद करना';

  @override
  String get chainDirect => 'प्रत्यक्ष';

  @override
  String get chainBlocked => 'अवरोधित';

  @override
  String get theme => 'विषय';

  @override
  String get themeSystem => 'सिस्टम के अनुसार';

  @override
  String get themeLight => 'रोशनी';

  @override
  String get themeDark => 'अँधेरा';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम के अनुसार';

  @override
  String get sectionConnection => 'संबंध';

  @override
  String get sectionNoServer => 'कोई सर्वर नहीं';

  @override
  String get sectionPing => 'गुनगुनाहट';

  @override
  String get sectionLog => 'निदान';

  @override
  String get ipv6 => 'आईपीवी6';

  @override
  String get dns => 'डीएनएस';

  @override
  String get dnsAuto => 'ऑटो';

  @override
  String get fragment => 'टीएलएस विखंडन';

  @override
  String get fragmentPackets => 'क्या बांटना है';

  @override
  String get fragmentLength => 'टुकड़े का आकार';

  @override
  String get fragmentInterval => 'टुकड़ों के बीच रुकें';

  @override
  String get byDefault => 'गलती करना';

  @override
  String get splitPos => 'पदों को विभाजित करें';

  @override
  String get disorder => 'टुकड़ों को पुनः व्यवस्थित करें';

  @override
  String get tlsRecord => 'टीएलएस रिकॉर्ड को विभाजित करें';

  @override
  String get tlsRecordNo => 'नहीं';

  @override
  String get tlsRecordSni => 'साइट के नाम पर';

  @override
  String get tlsRecordFirst => 'पहली बाइट के बाद';

  @override
  String get hostCase => 'होस्ट केस बदलें';

  @override
  String get probeMethod => 'तरीका';

  @override
  String get probeAuto => 'ऑटो';

  @override
  String get probeEngine => 'इंजन के माध्यम से';

  @override
  String get probeConnect => 'केवल कनेक्शन';

  @override
  String get probeUrl => 'परीक्षण का पता';

  @override
  String get probeTimeout => 'इंतज़ार';

  @override
  String seconds(int n) {
    return '$n एस';
  }

  @override
  String get subscriptions => 'सदस्यता';

  @override
  String get subscriptionSettings => 'सेटिंग्स';

  @override
  String get userAgent => 'उपयोगकर्ता एजेंट';

  @override
  String get autoUpdate => 'स्वचालित रूप से अपडेट करें';

  @override
  String get updateInterval => 'कितनी बार';

  @override
  String get intervalProvider => 'जैसा कि प्रदाता पूछता है';

  @override
  String hours(int n) {
    return '$n एच';
  }

  @override
  String get updateNow => 'अभी अद्यतन करें';

  @override
  String get logLevel => 'क्या रिकार्ड करना है';

  @override
  String get levelDebug => 'सब कुछ';

  @override
  String get levelInfo => 'साधारण';

  @override
  String get levelWarning => 'महत्वपूर्ण';

  @override
  String get levelError => 'केवल त्रुटियाँ';

  @override
  String get recordDestinations => 'साइट पते रिकॉर्ड करें';

  @override
  String get reset => 'सेटिंग्स फिर से करिए';

  @override
  String get resetConfirm => 'सभी सेटिंग्स रीसेट करें?';

  @override
  String get resetAction => 'रीसेट करें';

  @override
  String get invalidValue => 'यह मान काम नहीं करेगा';

  @override
  String get website => 'सदस्यता पृष्ठ';

  @override
  String get providerWebsite => 'प्रदाता वेबसाइट';

  @override
  String get support => 'सहायता';

  @override
  String chooseEngine(String engine) {
    return '$engine चुनें';
  }

  @override
  String get rules => 'कस्टम नियम';

  @override
  String get ruleAdd => 'नया नियम';

  @override
  String get ruleHint => 'साइट, आईपी या प्रोग्राम';

  @override
  String get ruleDirect => 'प्रत्यक्ष';

  @override
  String get ruleProxy => 'वीपीएन के माध्यम से';

  @override
  String get ruleBlock => 'अवरोध पैदा करना';

  @override
  String get failover => 'विफलता पर स्विच करें';

  @override
  String get connectOnStart => 'प्रारंभ पर कनेक्ट करें';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'सदस्यता $days दिनों में समाप्त हो जाती है',
      one: 'सदस्यता $days दिन में समाप्त होती है',
      zero: 'सदस्यता कुछ ही घंटों में समाप्त हो जाती है',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left बाएँ';
  }

  @override
  String get ruleInvalid => 'यह किसी साइट, आईपी या प्रोग्राम जैसा नहीं दिखता है';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सर्वर, सबसे तेज़',
      one: '$count सर्वर, सबसे तेज़',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'तरीका';

  @override
  String get tunnelProxy => 'System प्रॉक्सी';

  @override
  String get proxyAddress => 'प्रॉक्सी पता';

  @override
  String get copied => 'कॉपी किया गया';

  @override
  String get launchAtLogin => 'सिस्टम से शुरुआत करें';

  @override
  String get closeToTray => 'बंद होने पर ट्रे में रखें';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get trayOpen => 'Sora खोलें';

  @override
  String get trayConnect => 'जोड़ना';

  @override
  String get trayDisconnect => 'डिस्कनेक्ट';

  @override
  String get trayServer => 'सर्वर';

  @override
  String get trayQuit => 'Sora से बाहर निकलें';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora अभी भी ट्रे में है';

  @override
  String get noticeLost => 'कनेक्शन टूट गया';

  @override
  String get noticeLostBody => 'Sora पुनः कनेक्ट हो रहा है';

  @override
  String get noticeRestored => 'फिर से जुड़ा';

  @override
  String get noticeFailed => 'कनेक्ट नहीं हो सका';

  @override
  String get noticeBackup => 'मुख्य सर्वर ने उत्तर नहीं दिया; बैकअप ट्रैफ़िक को वहन करता है';

  @override
  String get noticeNext => 'सर्वर ने उत्तर नहीं दिया; अगला वाला यातायात वहन करता है';

  @override
  String get noticeMainBack => 'मुख्य सर्वर फिर से उत्तर देता है और ट्रैफ़िक ले जाता है';

  @override
  String get noticeSubscription => 'सदस्यता';

  @override
  String get importTitle => 'यह सदस्यता जोड़ें?';

  @override
  String get importSealed => 'यह लिंक Happ के लिए एन्क्रिप्ट किया गया है, और केवल Happ ही इसे पढ़ सकता है';

  @override
  String get noAnswer => 'कोई जवाब नहीं';

  @override
  String get home => 'घर';

  @override
  String get navRules => 'नियम';

  @override
  String get navConnections => 'कनेक्शन';

  @override
  String get navLogs => 'लॉग्स';

  @override
  String get navAbout => 'के बारे में';

  @override
  String get sidebarToggle => 'साइडबार टॉगल करें';

  @override
  String get more => 'अधिक';

  @override
  String get less => 'कम';

  @override
  String get notificationsEmpty => 'कोई सूचना नहीं';

  @override
  String get retryConnect => 'कनेक्शन पुनः प्रयास करें';

  @override
  String get openLogs => 'लॉग खोलें';

  @override
  String get tourBack => 'पीछे';

  @override
  String get tourNext => 'अगला';

  @override
  String get chooseProgram => 'एक प्रोग्राम चुनें';

  @override
  String get installedApps => 'इंस्टॉल किए गए एप्लिकेशन';

  @override
  String get runningProcesses => 'चल रही प्रक्रियाएँ';

  @override
  String get programsEmpty => 'कोई एप्लिकेशन नहीं मिला';

  @override
  String get selectExe => 'कोई .exe फ़ाइल चुनें';

  @override
  String get speedtest => 'रफ़्तार';

  @override
  String get speedtestSearch => 'एक सेवा खोजें';

  @override
  String get speedtestEmpty => 'कोई मेल नहीं';

  @override
  String get speedtestBackToList => 'सेवाओं पर वापस जाएँ';

  @override
  String get speedtestOpenBrowser => 'ब्राउज़र में खोलें';

  @override
  String get speedtestUnavailable => 'एम्बेडेड ब्राउज़र प्रारंभ नहीं हो सका';

  @override
  String get speedtestPageFailed => 'पेज लोड नहीं हो सका';

  @override
  String get speedtestExternalFailed => 'सिस्टम ब्राउज़र नहीं खुल सका';

  @override
  String get modes => 'मोड';

  @override
  String get proxyShort => 'प्रतिनिधि';

  @override
  String get tunMode => 'संपूर्ण ट्रैफ़िक (TUN)';

  @override
  String get checkUpdates => 'अद्यतन के लिए जाँच';

  @override
  String get updates => 'ऐप अपडेट';

  @override
  String updateAvailable(String version) {
    return 'संस्करण $version उपलब्ध है';
  }

  @override
  String get updateOpenAbout => 'अद्यतन देखें';

  @override
  String updateNotes(String version) {
    return '$version में परिवर्तन';
  }

  @override
  String get updateCheck => 'अद्यतन के लिए जाँच';

  @override
  String get updateChecking => 'जाँच हो रही है...';

  @override
  String get updateNoNotes => 'रिलीज़ में कोई नोट नहीं है.';

  @override
  String get updateDropWarning => 'अपडेट के लिए कनेक्शन तोड़ें?';

  @override
  String get updateWaitConnection => 'कनेक्शन तैयार नहीं है';

  @override
  String get updateNetworkError => 'अपडेट डाउनलोड नहीं हो सका';

  @override
  String get updateReleaseError => 'रिलीज़ डेटा या आवश्यक फ़ाइलें गुम या अमान्य हैं।';

  @override
  String get updateChecksumError => 'डाउनलोड SHA256SUMS से मेल नहीं खाता';

  @override
  String get updateInstallError => 'अद्यतन समाप्त नहीं हुआ';

  @override
  String get updateUnsupported => 'यह निष्पादन योग्य समर्थित Sora पैकेज जोड़ी के स्वामित्व में नहीं है';

  @override
  String get updateVersionRevoked => 'डेवलपर ने इस संस्करण को वापस ले लिया है';

  @override
  String updateRollbacking(String version) {
    return 'संस्करण $version... पर वापस जा रहा हूं';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version का अपडेट स्वास्थ्य जांच में खरा नहीं उतरा, इसलिए Sora को वापस $fromVersion पर रोल कर दिया गया।';
  }

  @override
  String get updateRollbackError => 'स्वचालित रोलबैक विफल रहा';

  @override
  String get updateRollbackCacheError =>
      'वर्तमान संस्करण की सत्यापित रोलबैक प्रतिलिपि तैयार नहीं की जा सकी, इसलिए अद्यतन स्थापित नहीं किया गया।';

  @override
  String get updateCopyCommand => 'आदेश कॉपी करें';

  @override
  String get updateInstalled => 'अद्यतन स्थापित किया गया';

  @override
  String get projectLinks => 'परियोजना';

  @override
  String get githubReleases => 'रिलीज़ और डाउनलोड';

  @override
  String get telegramChannel => 'Telegram चैनल';

  @override
  String get licenses => 'लाइसेंस';

  @override
  String get componentLicenses => 'घटक लाइसेंस';

  @override
  String get collapseServers => 'सर्वर संक्षिप्त करें';

  @override
  String get expandServers => 'सर्वर का विस्तार करें';

  @override
  String get hideDescription => 'विवरण छिपाएँ';

  @override
  String get showDescription => 'विवरण दिखाएँ';

  @override
  String get errEngineUnsupported => 'चयनित इंजन इस प्रोफ़ाइल या सेटिंग्स का समर्थन नहीं करता है';

  @override
  String get errRestore => 'कनेक्शन सफ़ाई अधूरी थी';

  @override
  String get errSessionEnded => 'यह सत्र पहले ही समाप्त हो चुका है';

  @override
  String get retryDisconnect => 'डिस्कनेक्ट करने का पुनः प्रयास करें';

  @override
  String get tunStack => 'ट्यून स्टैक';

  @override
  String get modesInfo => 'मोड के बारे में';

  @override
  String get modesGuideTitle => 'मोड और इंजन';

  @override
  String get modesGuide =>
      'यदि आप अनिश्चित हैं कि आपके सर्वर को किस इंजन की आवश्यकता है तो ऑटो चुनें। Sora कनेक्ट करने से पहले प्रोफ़ाइल और सेटिंग्स की जाँच करता है। कोई इंजन आपके प्लान की बैंडविड्थ नहीं बढ़ा सकता: प्रदर्शन सर्वर, रूट, प्रोटोकॉल और नेटवर्क पर निर्भर करता है।\n\n## मोड\n\n### समस्त ट्रैफ़िक (TUN)\n\nSora एक वर्चुअल नेटवर्क इंटरफ़ेस बनाता है और टीसीपी और यूडीपी सहित इसके माध्यम से एप्लिकेशन ट्रैफ़िक को रूट करता है। इस मोड का उपयोग Telegram, गेम्स और Discord वॉयस के लिए करें। नियम विशिष्ट साइटों या कार्यक्रमों को सीधे भेज सकते हैं या उन्हें ब्लॉक कर सकते हैं। नेटवर्क सेवा को अनुमति और एक सर्वर की आवश्यकता होती है जो आवश्यक प्रोटोकॉल का समर्थन करता हो।\n\n### System प्रॉक्सी\n\nSora एक स्थानीय HTTP/SOCKS प्रॉक्सी को कॉन्फ़िगर करता है। सिस्टम प्रॉक्सी सेटिंग्स का सम्मान करने वाले एप्लिकेशन इसका उपयोग करते हैं। अपने स्वयं के नेटवर्क स्टैक वाले एप्लिकेशन सीधे कनेक्ट हो सकते हैं; यूडीपी और वॉयस कॉल के लिए आम तौर पर TUN की आवश्यकता होती है। यह मोड प्रॉक्सी समर्थन वाले ब्राउज़र और एप्लिकेशन के लिए उपयुक्त है।\n\n### कोई सर्वर नहीं\n\nLinux पर, Sora HTTP/TLS अनुरोधों को विभाजित और नया आकार देने और कुछ DPI जांचों को बायपास करने के लिए [zapret](https://github.com/bol-van/zapret) का उपयोग करता है। आपका आईपी वही रहता है और कनेक्शन सीधे वेबसाइट पर चले जाते हैं। परिणाम आपके प्रदाता और अवरुद्ध करने की विधि पर निर्भर करते हैं।\n\nवर्तमान एकीकरण टीसीपी पर HTTP और TLS के लिए tpws का उपयोग करता है। यह आईपी ब्लॉकिंग या रिले यूडीपी को बायपास नहीं करता है, और Telegram के MTProto कनेक्शन की गारंटी नहीं दे सकता है। Discord वॉयस, Telegram कॉल और इस प्रकार के प्रतिबंधों के लिए TUN वाले वीपीएन सर्वर का उपयोग करें।\n\n## इंजन\n\n### ऑटो\n\nSora एक स्थापित इंजन का चयन करता है जो संपूर्ण कनेक्शन योजना का समर्थन करता है: सर्वर प्रोटोकॉल, ट्रांसपोर्ट, समूह, विखंडन और मोड। वर्तमान कनेक्शन को रोकने से पहले एक असंगत मैन्युअल विकल्प को अस्वीकार कर दिया जाता है। ऑटो या अन्य इंजन चुनें और सेटिंग्स फिर से लागू करें।\n\n### sing-box\n\nनए Sora पैकेज में [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) का एक कांटा, क्लाइंट-साइड XHTTP और VLESS Encryption शामिल है। Sora निर्माण और उसकी क्षमताओं को पहचानता है। XHTTP के बिना एक अपस्ट्रीम बिल्ड केवल इसके नाम से यह क्षमता हासिल नहीं करता है।\n\nसमर्थित प्रोटोकॉल में VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard और AmneziaWG 1.x/2.x पैरामीटर शामिल हैं। Sora आयात कर सकते हैं. पूर्ण Xray JSON प्रोफाइल के लिए Xray की आवश्यकता होती है। नई AWG 3.x फ़ील्ड अभी तक आयात नहीं की जा सकतीं. sing-box एक पासवर्ड-संरक्षित स्थानीय नियंत्रण पोर्ट का उपयोग करता है, जिसे कंप्यूटर पर अन्य एप्लिकेशन पता लगा सकते हैं।\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption और TLS विखंडन का समर्थन करता है। यह उनकी रूटिंग और समूहों को संरक्षित करते हुए संपूर्ण प्रदाता Xray प्रोफाइल भी चलाता है। ऐसी प्रोफ़ाइलों को उनके व्यवहार को बदले बिना स्वचालित रूप से किसी अन्य इंजन में परिवर्तित नहीं किया जा सकता है।\n\nबंडल किए गए Xray ने उस सेटिंग को हटा दिया जो TLS प्रमाणपत्र सत्यापन (`allowInsecure`) को अक्षम कर देती है। इस सेटिंग की आवश्यकता वाले सामान्य सर्वर के लिए स्वतः sing-box या mihomo का चयन करता है। Xray का चयन वर्तमान कनेक्शन को रोकने से पहले मैन्युअल रूप से असंगतता की रिपोर्ट करता है। पुराने पूर्ण JSON प्रोफाइल को सत्यापन योग्य प्रमाणपत्र या प्रमाणपत्र पिन के साथ एक अद्यतन प्रदाता प्रोफ़ाइल की आवश्यकता होती है।\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) ऑर्डर किए गए फ़ॉलबैक और लोड-बैलेंसिंग समूहों, XHTTP और AmneziaWG का समर्थन करता है। जब बैकअप सर्वर पर स्वचालित विफलता मायने रखती है तो इसे चुनें। इस इंजन के साथ Sora की TLS फ़्रेग्मेंटेशन सेटिंग उपलब्ध नहीं है।\n\n## Sora में अनुकूलता\n\n| फ़ीचर | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows ट्यून और टीसीपी/यूडीपी | हाँ | हाँ | हाँ |\n| XHTTP | हाँ | हाँ | हाँ |\n| VLESS Encryption | हाँ | हाँ | हाँ |\n| पूर्ण Xray प्रोफ़ाइल | नहीं | हाँ | नहीं |\n| TUIC / AnyTLS | दोनों | नहीं | TUIC |\n| mieru | नहीं | नहीं | हाँ |\n| NaiveProxy | हाँ | नहीं | नहीं |\n| टीएलएस विखंडन | हाँ | हाँ | नहीं |\n| AmneziaWG 1.x/2.x | हाँ¹ | नहीं | हाँ |\n| आदेशित फ़ॉलबैक समूह | नहीं | नहीं² | हाँ |\n\n¹ J1/J2/J3/Itime वाली प्रोफ़ाइलें mihomo का उपयोग करती हैं; इन क्षेत्रों को कभी भी चुपचाप नहीं छोड़ा जाना चाहिए। ² संपूर्ण Xray प्रोफाइल के समूह के लिए, ऐप एक बैकअप प्रोफ़ाइल का चयन करता है। समर्थन स्थापित बिल्ड पर निर्भर करता है; अबाउट में इसका संस्करण जांचें।\n\n## ट्यून स्टैक\n\nस्टैक वर्चुअल इंटरफ़ेस के अंदर टीसीपी और यूडीपी को संभालता है। मोड पैनल में, Xray और mihomo gVisor, System, Mixed और MIPS ऑफर करते हैं। प्रत्येक इंजन अपनी प्राथमिकता बचाता है। System प्रॉक्सी और सर्वर रहित मोड इस प्राथमिकता का उपयोग नहीं करते हैं।\n\n- **Mixed** - टीसीपी सिस्टम स्टैक का उपयोग करता है, जबकि gVisor यूडीपी को संभालता है। Linux पर यह mihomo का डिफ़ॉल्ट है। Windows पर Xray और mihomo डिफ़ॉल्ट रूप से MIPS का उपयोग करते हैं।\n- **System** - सिस्टम स्टैक का उपयोग करता है। यदि नेटवर्क अनुप्रयोगों में समस्याएँ आती हैं तो दूसरा विकल्प आज़माएँ।\n- **gVisor** - यूजरस्पेस में ट्रैफिक को संभालता है।\n- **MIPS** - mihomo का अपना आईपी स्टैक, बंडल संस्करण 1.19.32 में उपलब्ध है।\n\nLinux पर, Xray डिफ़ॉल्ट रूप से अपने अंतर्निहित gVisor का उपयोग करता है। System, Mixed और Linux पर MIPS TUN इंजन के रूप में mihomo का उपयोग करते हैं, एक प्रमाणित स्थानीय SOCKS लिंक पर TCP और UDP को Xray पर अग्रेषित करते हैं। Xray प्रोटोकॉल, प्रदाता प्रोफ़ाइल और रूटिंग को बरकरार रखता है। इन तीन विकल्पों के लिए एक स्थापित mihomo की आवश्यकता होती है। Windows पर Xray चारों TUN स्टैक के लिए mihomo 1.19.32 या नया संस्करण उपयोग करता है। प्रोटोकॉल और रूटिंग Xray में रहते हैं। इस संयोजन में ऐप के नियम केवल सीधे कनेक्शन और ब्लॉक करने का समर्थन करते हैं; Linux पर इन नियमों के लिए Xray का अंतर्निहित gVisor आवश्यक है।\n\nब्रिज दूसरी प्रक्रिया चलाता है। Linux पर तीन निष्क्रिय मापों में, इसने मूल Xray TUN की तुलना में लगभग 32-36 MiB अधिक भौतिक मेमोरी का उपयोग किया। यह डाउनलोड लोड को मापता नहीं है: सीपीयू और मेमोरी की लागत कनेक्शन पर निर्भर करती है। sing-box में कोई स्टैक चयनकर्ता नहीं है। कोई भी स्टैक हर नेटवर्क में बेहतर प्रदर्शन की गारंटी नहीं देता।\n\n## सेटिंग्स लागू करना\n\nसर्वर चुनने पर कनेक्शन अपने आप दोबारा बनता है। मोड, इंजन, DNS और नियमों में बदलाव अपने आप सहेजे जाते हैं और अगले कनेक्शन पर लागू होते हैं। इंजन दोबारा शुरू करने से डाउनलोड और कॉल बाधित हो सकते हैं।. मोड, इंजन, DNS या नियमों में आपके बदलाव थोड़े विराम के बाद अपने आप दोबारा कनेक्ट होकर एक बार लागू होते हैं; पृष्ठभूमि के अपडेट VPN को दोबारा कनेक्ट नहीं करते।\n\nसुरंग गिरने पर केवल वीपीएन के माध्यम से इंटरनेट सीधे यातायात को अवरुद्ध करता है। इसका असर पूरी मशीन पर पड़ता है. एक स्पष्ट डिस्कनेक्ट Sora के नियमों को हटा देता है। यदि सफ़ाई समाप्त नहीं होती है, तो डिस्कनेक्ट करने का पुनः प्रयास करें और लॉग खोलें।\n\n## परियोजना दस्तावेज़ीकरण\n\n- [sing-box-lx: कॉन्फ़िगरेशन और समर्थन](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box दस्तावेज़](https://sing-box.sagernet.org/)\n- [Xray दस्तावेज़](https://xtls.github.io/)\n- [mihomo दस्तावेज़](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: संचालन और सीमाएं](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC, Jitsi, Yandex Telemost या WB Stream की वीडियो कॉल के ज़रिए TCP ट्रैफ़िक भेजता है। olcrtc:// लिंक या QR कोड आयात करें। यह प्रॉक्सी और TUN मोड में sing-box, Xray और mihomo के साथ काम करता है; UDP समर्थित नहीं है। दोनों सिरों पर OLC2 के संगत बिल्ड चाहिए। मूल परियोजना संग्रहित कर दी गई है।\n';

  @override
  String get probeServers => 'गुनगुनाहट';

  @override
  String get extensions => 'एक्सटेंशन';

  @override
  String extRatingLabel(String rating) {
    return 'रेटिंग 5 में से $rating';
  }

  @override
  String extByAuthor(String author) {
    return '$author द्वारा';
  }

  @override
  String extInstallsCount(String count) {
    return 'इंस्टालेशन: $count';
  }

  @override
  String get extInstallOne => '1 इंस्टॉल';

  @override
  String get extSideloadWarning => 'स्वयं हस्ताक्षरित कुंजी';

  @override
  String get extPermissionsWidened => 'अपडेट नई अनुमतियां मांगता है:';

  @override
  String get extInstall => 'इंस्टॉल करें';

  @override
  String get extUpdate => 'अपडेट करें';

  @override
  String get extCancel => 'रद्द करें';

  @override
  String get extConfirm => 'पुष्टि करें';

  @override
  String get extCatalog => 'कैटलॉग';

  @override
  String get extInstalled => 'इंस्टॉल किए गए एक्सटेंशन';

  @override
  String get extSearchHint => 'एक्सटेंशन खोजें';

  @override
  String get extCatAll => 'सभी';

  @override
  String get extCatTools => 'उपकरण';

  @override
  String get extCatThemes => 'थीम';

  @override
  String get extCatAutomation => 'स्वचालन';

  @override
  String get extCatStats => 'सांख्यिकी';

  @override
  String get extCatNetwork => 'नेटवर्क';

  @override
  String get extSortBy => 'क्रमबद्ध करें';

  @override
  String get extSortPopular => 'सर्वाधिक लोकप्रिय';

  @override
  String get extSortRating => 'उच्चतम रेटिंग';

  @override
  String get extSortName => 'नाम';

  @override
  String get extCatalogError => 'कैटलॉग लोड नहीं हो सका';

  @override
  String get extRetry => 'पुनः प्रयास करें';

  @override
  String get extEmptySearch => 'कुछ नहीं मिला';

  @override
  String get extEmptyInstalled => 'अभी तक कोई एक्सटेंशन इंस्टॉल नहीं हुआ है';

  @override
  String get extInstallFromFile => 'फ़ाइल से इंस्टॉल करें';

  @override
  String get extInstallFromUrl => 'URL से इंस्टॉल करें';

  @override
  String get extDownload => 'डाउनलोड करें';

  @override
  String get extDownloading => 'डाउनलोड हो रहा है...';

  @override
  String get extVerifying => 'सत्यापन किया जा रहा है...';

  @override
  String get extInstalling => 'स्थापित किया जा रहा है…';

  @override
  String get extErrSignature => 'हस्ताक्षर जांच विफल रही';

  @override
  String get extErrManifest => 'एक्सटेंशन मेनिफ़ेस्ट अमान्य है।';

  @override
  String get extErrNetwork => 'नेटवर्क त्रुटि';

  @override
  String get extErrHash => 'डाउनलोड कैटलॉग से मेल नहीं खाता';

  @override
  String extErrMinApp(String version) {
    return 'इस एक्सटेंशन के लिए ऐप संस्करण $version या नया चाहिए।';
  }

  @override
  String get extErrHttpsOnly => 'केवल https:// लिंक की अनुमति है';

  @override
  String get extErrGeneric => 'कुछ गलत हो गया';

  @override
  String get extErrAuthorKeyChanged =>
      'यह अद्यतन स्थापित संस्करण की तुलना में एक अलग लेखक कुंजी के साथ हस्ताक्षरित है, इसलिए इसे अवरुद्ध कर दिया गया था';

  @override
  String get extDisabled => 'बंद';

  @override
  String extToggleEnabled(String name) {
    return '$name सक्षम करें';
  }

  @override
  String get extSearchInstalled => 'इंस्टॉल किए गए एक्सटेंशन खोजें';

  @override
  String get extUpdateAll => 'सभी को अपडेट करें';

  @override
  String extUpdatesAvailable(int count) {
    return '$count अपडेट उपलब्ध हैं';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count अपडेट किया गया';
  }

  @override
  String get extRiskNormal => 'सामान्य';

  @override
  String get extRiskSensitive => 'संवेदनशील';

  @override
  String get extRiskDangerous => 'उच्च जोखिम';

  @override
  String get extPermissionsRemoved => 'अब नहीं माँगी जातीं:';

  @override
  String get extUpdateFailedKept => 'पिछला संस्करण अभी भी स्थापित है।';

  @override
  String get extConflictsTitle => 'विस्तार संघर्ष';

  @override
  String get extConflictTheme => 'ऐप थीम';

  @override
  String get extConflictNetHooks => 'नेटवर्क हुक';

  @override
  String extConflictWinner(String name) {
    return 'प्राथमिकता: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'विस्तार संघर्ष: $count';
  }

  @override
  String get extConflictsResolve => 'विवादों का समाधान करें';

  @override
  String extVersionLabel(String version) {
    return 'संस्करण $version';
  }

  @override
  String get extPermissionsTitle => 'अनुमतियाँ';

  @override
  String get extNoPermissions => 'कोई विशेष अनुमति नहीं।';

  @override
  String get extSettings => 'सेटिंग्स';

  @override
  String get extSaveSettings => 'सेटिंग्स सहेजें';

  @override
  String extUpdateTo(String version) {
    return '$version में अपग्रेड करें';
  }

  @override
  String get extEnabled => 'चालू';

  @override
  String extRollbackTo(String version) {
    return '$version पर रोलबैक';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'संस्करण $version पर रोलबैक?';
  }

  @override
  String get extUninstall => 'अनइंस्टॉल करें';

  @override
  String extUninstallConfirm(String name) {
    return '\"$name\" और इसकी सेटिंग्स हटाएं?';
  }

  @override
  String get extPanelUnavailable => 'एक्सटेंशन पैनल उपलब्ध नहीं है।';

  @override
  String get extPermConnectionsRead => 'सक्रिय कनेक्शनों की सूची देखें';

  @override
  String get extPermServersRead => 'अपने सर्वर की सूची देखें';

  @override
  String get extPermSettingsRead => 'ऐप सेटिंग पढ़ें';

  @override
  String get extPermSettingsWrite => 'ऐप सेटिंग बदलें';

  @override
  String get extPermNotifications => 'सूचनाएं दिखाएं';

  @override
  String get extPermTray => 'ट्रे मेनू में आइटम जोड़ें';

  @override
  String get extPermUiPanel => 'ऐप के अंदर पैनल दिखाएं';

  @override
  String get extPermThemeApply => 'थीम लागू करें';

  @override
  String get extPermRoutingRules => 'रूटिंग नियम जोड़ें';

  @override
  String get extPermNetHooks => 'नेटवर्क पथ में एकीकृत करें';

  @override
  String get extPermNetFetch => 'अनुमत सूची से URL का अनुरोध करें';

  @override
  String get extPermBackground => 'पृष्ठभूमि कार्य चलाएँ';

  @override
  String get extPermNotYetActive => 'बंद';

  @override
  String get extCapBackground => 'पृष्ठभूमि में चलता है';

  @override
  String get extCapNetHook => 'ब्लॉक से बचाव और नेटवर्क हुक';

  @override
  String get extCapPanel => 'इंटरफ़ेस पैनल';

  @override
  String get extCapRouting => 'रूटिंग नियम';

  @override
  String get extCapTheme => 'थीम';

  @override
  String get extCapWidget => 'विजेट';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'चेंजलॉग';

  @override
  String get extImageFailed => 'छवि लोड नहीं हो सकी';

  @override
  String get extScreenshots => 'स्क्रीनशॉट';

  @override
  String get extSortRelevance => 'प्रासंगिकता';

  @override
  String get extBgTitle => 'पृष्ठभूमि कार्य';

  @override
  String get extBgEnabled => 'पृष्ठभूमि में चलाएँ';

  @override
  String get extBgInterval => 'चलाने का अंतराल';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count मिनट', one: '$count मिनट');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count घंटे', one: '$count घंटा');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'नेटवर्क पहुंच';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'नेटवर्क: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'फ़ाइल में $name';
  }

  @override
  String get diagnosticHttp => 'HTTP डायग्नोस्टिक्स';

  @override
  String get diagnosticNoData => 'अभी तक कोई रिकॉर्डेड अनुरोध नहीं';

  @override
  String get qrShareTitle => 'QR कोड साझा करें';

  @override
  String get qrScanTitle => 'QR कोड स्कैन करें';

  @override
  String get qrCopyLink => 'लिंक कॉपी करें';

  @override
  String get qrFromClipboard => 'क्लिपबोर्ड से चिपकाएँ';

  @override
  String get qrNoCode => 'इस छवि में कोई QR कोड नहीं मिला।';

  @override
  String get qrInvalid => 'इस QR कोड में कोई वैध लिंक नहीं है।';

  @override
  String get qrScan => 'स्कैन QR';

  @override
  String get qrFromImage => 'छवि खोलें';

  @override
  String get connGroupByProcess => 'प्रक्रिया के अनुसार समूह बनाएं';

  @override
  String get connListView => 'सूची';

  @override
  String get connCopyHost => 'कॉपी होस्ट';

  @override
  String get connAddRule => 'नियम जोड़ें';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count कनेक्शन', one: '$count कनेक्शन');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'प्रीसेट';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'कस्टम';

  @override
  String get dnsCheck => 'डेटा लीक की जांच करें';

  @override
  String get dnsChecking => 'जाँच हो रही है...';

  @override
  String get dnsNoLeak => 'कोई लीक नहीं मिला';

  @override
  String get dnsLeakFound => 'रिसाव का पता चला';

  @override
  String get dnsLastCheck => 'अंतिम जांच';

  @override
  String get dnsNeverChecked => 'अभी तक परीक्षण नहीं किया गया';

  @override
  String get dnsLeakCheckTunnelDns => 'टनल के DNS रिज़ॉल्वर';

  @override
  String get dnsLeakCheckSystemResolvers => 'सिस्टम रिज़ॉल्वर';

  @override
  String get dnsLeakCheckKillSwitchDns => 'नेटवर्क अवरोध से DNS सुरक्षा';

  @override
  String get dnsLeakCheckEncryptedDns => 'सिस्टम का एन्क्रिप्टेड DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS जवाबों की जालसाज़ी';

  @override
  String get dnsExpected => 'अपेक्षित';

  @override
  String get dnsActual => 'अवलोकन किया गया';

  @override
  String get measureSpeed => 'गति मापें';

  @override
  String get benchmarkStale => 'पुराना';

  @override
  String get autoSelectMode => 'स्वतः-चयन सर्वर';

  @override
  String get autoSelectPing => 'सबसे तेज़ पिंग';

  @override
  String get autoSelectSpeed => 'सबसे तेज़ गति';

  @override
  String get autoSelectSmart => 'स्मार्ट विकल्प';

  @override
  String get coreWatchUnstable => 'कोर से कनेक्शन अस्थिर है';

  @override
  String get watchReconnect => 'पुनः कनेक्ट करें';

  @override
  String get crashRestoreTitle => 'पिछला सत्र बाधित हुआ था';

  @override
  String get restoreOnCrash => 'दुर्घटना के बाद सत्र बहाल करें';

  @override
  String get crashRestore => 'पुनर्स्थापित करें';

  @override
  String get crashDismiss => 'अभी नहीं';

  @override
  String get overrideTitle => 'मेरे संपादन';

  @override
  String get overrideEdit => 'सर्वर संपादित करें';

  @override
  String get overrideHide => 'छुपाएं';

  @override
  String get overrideUnhide => 'दिखाएँ';

  @override
  String get overrideClear => 'संपादन रीसेट करें';

  @override
  String get overrideEmpty => 'अभी तक कोई संपादन नहीं';

  @override
  String get overrideCustomRules => 'अपने नियम';

  @override
  String get errBenchmarkUnsupported => 'गति मापने के लिए कोर का नया वर्शन चाहिए';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total से $done का माप…';
  }

  @override
  String get profiles => 'नेटवर्क प्रोफाइल';

  @override
  String get profilesEmpty => 'अभी तक कोई प्रोफ़ाइल नहीं';

  @override
  String get profileAdd => 'प्रोफ़ाइल जोड़ें';

  @override
  String get profileName => 'प्रोफ़ाइल नाम';

  @override
  String get profileSsids => 'Wi-Fi नेटवर्क (SSID)';

  @override
  String get profileGateways => 'नेटवर्क गेटवे';

  @override
  String get profileAsns => 'AS संख्याएँ';

  @override
  String get profileAutoApply => 'अपने आप लागू करें';

  @override
  String get profileSnapshot => 'वर्तमान सेटिंग्स याद रखें';

  @override
  String get profileSnapshotDone => 'वर्तमान सेटिंग्स प्रोफ़ाइल में सहेजी गईं';

  @override
  String get profileDelete => 'प्रोफ़ाइल हटाएं';

  @override
  String profileDeleteConfirm(Object name) {
    return 'प्रोफ़ाइल \"$name\" हटाएं?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'प्रोफ़ाइल \"$name\" लागू करें?';
  }

  @override
  String get profileApply => 'लागू करें';

  @override
  String profileApplied(Object name) {
    return 'प्रोफ़ाइल \"$name\" लागू की गई';
  }

  @override
  String get profileUndo => 'रद्द करें';

  @override
  String get profileActive => 'सक्रिय';

  @override
  String networkNow(Object info) {
    return 'अब: $info';
  }

  @override
  String get networkUnknown => 'नेटवर्क जानकारी अनुपलब्ध है';

  @override
  String get profileNoTriggers => 'प्रोफ़ाइल की शर्तें नहीं हैं';

  @override
  String get chains => 'प्रॉक्सी चेन';

  @override
  String get chainsEmpty => 'अभी तक कोई जंजीर नहीं';

  @override
  String get chainAdd => 'नई श्रृंखला';

  @override
  String get chainName => 'श्रृंखला का नाम';

  @override
  String get chainTooFew => 'चेन के लिए कम से कम दो सर्वर चाहिए';

  @override
  String get chainTooMany => 'चेन में अधिकतम तीन सर्वर हो सकते हैं';

  @override
  String get chainEstimate => 'अनुमानित विलंबता';

  @override
  String get chainSave => 'श्रृंखला सहेजें';

  @override
  String get chainDelete => 'श्रृंखला हटाएं';

  @override
  String chainDeleteConfirm(Object name) {
    return 'श्रृंखला \"$name\" हटाएं?';
  }

  @override
  String get chainUnsupported => 'चुना गया इंजन सर्वर चेन का समर्थन नहीं करता';

  @override
  String get chainHopMissing => 'चेन का एक सर्वर अब उपलब्ध नहीं है';

  @override
  String chainHop(Object n) {
    return 'हॉप $n';
  }

  @override
  String get chainEntry => 'प्रवेश';

  @override
  String get chainExit => 'निकास';

  @override
  String get sync => 'डिवाइस सिंक्रनाइज़ेशन';

  @override
  String get syncDevices => 'मेरे उपकरण';

  @override
  String get syncEmpty => 'कोई युग्मित डिवाइस नहीं';

  @override
  String get syncPair => 'डिवाइस पेयर करें';

  @override
  String get syncShowCode => 'मेरा कोड दिखाएँ';

  @override
  String get syncScanCode => 'कोड स्कैन करें';

  @override
  String get syncRevoke => 'वापस लें';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\" को रद्द करें?';
  }

  @override
  String syncLastSync(Object time) {
    return 'अंतिम सिंक: $time';
  }

  @override
  String get syncNever => 'कभी नहीं';

  @override
  String get syncPaired => 'डिवाइस युग्मित';

  @override
  String get syncPairingTitle => 'इस डिवाइस के साथ युग्मित करें';

  @override
  String get syncWaiting => 'दूसरे डिवाइस की प्रतीक्षा है...';

  @override
  String get zapretWithVpn => 'सीधे नेटवर्क ट्रैफ़िक के लिए बाईपास DPI फ़िल्टरिंग';

  @override
  String get chainDuplicate => 'चेन में कोई सर्वर एक से ज़्यादा बार है';

  @override
  String get edit => 'संपादित करें';

  @override
  String get remove => 'हटाओ';

  @override
  String get autoSwitchOnDegrade => 'गिरावट पर ऑटो-स्विच';

  @override
  String get tunStackMixed => 'मिश्रित';

  @override
  String get tunStackSystem => 'सिस्टम';

  @override
  String get customServerAdd => 'कस्टम सर्वर जोड़ें';

  @override
  String get customServers => 'मेरे सर्वर';

  @override
  String get customServerName => 'नाम';

  @override
  String get customServerNameRequired => 'नाम नहीं दिया गया';

  @override
  String get customServerAddress => 'पता';

  @override
  String get customServerAddressRequired => 'पता नहीं दिया गया';

  @override
  String get customServerAddressInvalid => 'अमान्य पता';

  @override
  String get customServerPort => 'पोर्ट';

  @override
  String get customServerPortInvalid => 'अमान्य पोर्ट';

  @override
  String get customServerProtocol => 'प्रोटोकॉल';

  @override
  String get customServerCredentials => 'लॉगिन जानकारी';

  @override
  String get customServerShowSecret => 'रहस्य दिखाएँ';

  @override
  String get customServerHideSecret => 'रहस्य छुपाएं';

  @override
  String customServerDeleteConfirm(String name) {
    return 'सर्वर \"$name\" हटाएं?';
  }

  @override
  String get leakTestTitle => 'डेटा लीक के लिए परीक्षण';

  @override
  String get leakTestRun => 'जांचें';

  @override
  String get leakTestCancel => 'रद्द करें';

  @override
  String leakTestProgress(int count) {
    return 'परीक्षण पूर्ण: $count';
  }

  @override
  String get leakTestAllClear => 'कोई लीक नहीं मिला';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count लीक मिले', one: '$count लीक मिला');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'ठीक करें';

  @override
  String get leakTestCheckDirectDns => 'प्रत्यक्ष DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP प्रतिध्वनि';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'सिस्टम रिज़ॉल्वर';

  @override
  String get leakTestCheckTunnelConnectivity => 'सुरंग कनेक्टिविटी';

  @override
  String get leakTestCheckTunnelDns => 'DNS सुरंग के माध्यम से';

  @override
  String get noticeDegraded => 'सर्वर धीमा हो गया। Sora माप के दौरान पाए गए सर्वोत्तम सर्वर पर स्विच किया गया।';

  @override
  String get obfs => 'ट्रैफ़िक छिपाना';

  @override
  String get syncCodeExpired => 'कोड समाप्त हो गया है';

  @override
  String get syncDaemonFailed => 'सिंक सेवा प्रारंभ नहीं हो सकी';

  @override
  String get syncDaemonMissing => 'sora-sync घटक नहीं मिला';

  @override
  String get syncDaemonStarting => 'सिंक सेवा शुरू हो रही है...';

  @override
  String get syncErrAuth => 'सिंक सेवा ने एक्सेस टोकन को अस्वीकार कर दिया';

  @override
  String get syncErrNotFound => 'डिवाइस अब युग्मित नहीं है';

  @override
  String get syncErrPairingActive => 'एक युग्मन सत्र पहले से ही खुला है';

  @override
  String get syncErrUnreachable => 'दूसरे उपकरण ने उत्तर नहीं दिया';

  @override
  String get syncError => 'तुल्यकालन त्रुटि';

  @override
  String syncExpiresIn(String duration) {
    return 'कोड $duration बाद समाप्त होगा';
  }

  @override
  String get syncJoining => 'डिवाइस के साथ युग्मित करना...';

  @override
  String get syncNewCode => 'नया कोड';

  @override
  String syncPairedWith(String name) {
    return '$name के साथ युग्मित';
  }

  @override
  String get syncRetry => 'दोहराएँ';

  @override
  String get syncStopShowing => 'कोड छिपाएँ';

  @override
  String get syncSyncNow => 'अभी सिंक करें';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled प्राप्त हुआ, $pushed भेजा गया';
  }

  @override
  String get syncResultTitle => 'तुल्यकालन परिणाम';

  @override
  String get syncPulled => 'प्राप्त हुआ';

  @override
  String get syncPushed => 'भेजा गया';

  @override
  String get syncNoChanges => 'कोई बदलाव नहीं';

  @override
  String get syncDocKindSubscriptions => 'सदस्यताएँ';

  @override
  String get syncDocKindSettings => 'ऐप सेटिंग्स';

  @override
  String get syncDocKindOverrides => 'सदस्यता के कस्टम बदलाव';

  @override
  String get syncDocKindProfiles => 'नेटवर्क प्रोफाइल';

  @override
  String get syncDocKindChains => 'प्रॉक्सी चेन';

  @override
  String syncFrom(String name) {
    return '$name से';
  }

  @override
  String get syncThisDevice => 'यह उपकरण';

  @override
  String get syncUnavailableAndroid => 'Android पर सिंक उपलब्ध नहीं है';

  @override
  String get diagnosticPackets => 'पैकेट पर कब्जा';

  @override
  String get diagnosticEvents => 'विंडोज़ घटनाएँ';

  @override
  String get diagnosticCapture => '10 सेकंड के लिए कैप्चर करें';

  @override
  String get diagnosticRequiresTun => 'पैकेट कैप्चर के लिए एक सक्रिय सोरा ट्यून कनेक्शन की आवश्यकता होती है।';

  @override
  String get diagnosticUnavailable => 'यह निदान इस प्लेटफ़ॉर्म पर उपलब्ध नहीं है.';

  @override
  String get extErrRevoked => 'Sora टीम ने इस एक्सटेंशन संस्करण को वापस ले लिया है, क्योंकि यह असुरक्षित या खराब है।';

  @override
  String get extErrRevocationsExpired => 'निरस्त एक्सटेंशन की सूची अपडेट होने तक इंस्टॉलेशन बंद है।';

  @override
  String extRevokedDisabled(String names) {
    return 'वापस लिए गए एक्सटेंशन बंद किए गए: $names';
  }

  @override
  String get customServerWgPrivateKey => 'प्राइवेट की';

  @override
  String get customServerWgAddresses => 'इंटरफ़ेस पते';

  @override
  String get customServerWgPeerKey => 'सर्वर की पब्लिक की';

  @override
  String get customServerWgPresharedKey => 'प्री-शेयर्ड की';

  @override
  String get customServerWgAllowedIps => 'अनुमत IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, सेकंड';

  @override
  String get customServerWgKeyInvalid => 'अमान्य WireGuard कुंजी';

  @override
  String get customServerWgCidrInvalid => 'अमान्य CIDR प्रीफ़िक्स';

  @override
  String get customServerWgKeepaliveInvalid => 'अमान्य keepalive अंतराल';

  @override
  String get strictKillSwitch => 'सख्त नेटवर्क अवरोध';

  @override
  String get strictKillSwitchWarning => 'बाहर निकलने के बाद VPN के बाहर का ट्रैफ़िक रोकें?';

  @override
  String get extWorkerFailed => 'एक्सटेंशन का बैकग्राउंड कार्य विफल हुआ';

  @override
  String get extAssetRejected => 'एक्सटेंशन की फ़ाइल में अपठनीय रंग या अमान्य नियम हैं';

  @override
  String get extVerifiedSora => 'Sora द्वारा सत्यापित';

  @override
  String extReceivedBytes(String count) {
    return '$count बाइट';
  }

  @override
  String get extOpen => 'खोलें';

  @override
  String get customServerOwn => 'अपना सर्वर';

  @override
  String get customServerPaste => 'लिंक पेस्ट करें';

  @override
  String get customServerUser => 'उपयोगकर्ता नाम';

  @override
  String get customServerPassword => 'पासवर्ड';

  @override
  String get customServerSecretRequired => 'मान नहीं दिया गया';

  @override
  String get customServerLinkInvalid => 'सर्वर लिंक अमान्य है';

  @override
  String get errInternal => 'Sora में आंतरिक त्रुटि';

  @override
  String get errTls => 'सर्वर का प्रमाणपत्र अस्वीकार हुआ';

  @override
  String get errFileAccess => 'फ़ाइल तक पहुँच नहीं है';

  @override
  String get errDataLimit => 'बहुत ज़्यादा डेटा है';

  @override
  String get errCredentials => 'सहेजी गई लॉगिन जानकारी नहीं मिली';

  @override
  String subscriptionStale(String time) {
    return 'अंतिम अपडेट: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'अभी अपडेट नहीं हुआ';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'सर्वर ने HTTP $status कोड लौटाया',
      zero: 'सर्वर ने अनुरोध अस्वीकार कर दिया',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'सर्वर की सेटिंग अधूरी या असमर्थित हैं';

  @override
  String get errServerIds => 'दो सर्वर का पहचानकर्ता एक है';

  @override
  String get errRoutingGroup => 'मार्ग लापता सर्वर या खराब समूह की ओर है';

  @override
  String get errConnections => 'कनेक्शन सूची उपलब्ध नहीं है';

  @override
  String get errLogs => 'यह सेवा लॉग नहीं रखती';

  @override
  String get errDiagnostics => 'निदान एकत्र नहीं हुआ';

  @override
  String get errMissingItem => 'माँगा गया आइटम अब मौजूद नहीं है';

  @override
  String get errInvalidRequest => 'अनुरोध में अमान्य मान हैं';

  @override
  String get errProxyLogin => 'सिस्टम प्रॉक्सी इस लॉगिन का समर्थन नहीं करती';

  @override
  String get errLogFilter => 'लॉग फ़िल्टर अमान्य है';

  @override
  String get errSubRedirect => 'सर्वर ने असुरक्षित पते पर भेजा';

  @override
  String get errProxySetup => 'सिस्टम प्रॉक्सी कॉन्फ़िगर नहीं हुई';

  @override
  String get notificationsToday => 'आज';

  @override
  String get notificationsYesterday => 'कल';

  @override
  String get notificationsMarkRead => 'सभी को पढ़ा हुआ चिह्नित करें';

  @override
  String get notificationsUnread => 'अपठित';

  @override
  String get desktopNotifications => 'डेस्कटॉप सूचनाएँ';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'सदस्यता अपडेट करने का अंतराल अमान्य है';

  @override
  String get errRule => 'रूटिंग के किसी नियम में गलती है';

  @override
  String get errDns => 'DNS सेटिंग अमान्य हैं';

  @override
  String get errEndpoint => 'जाँच के लिए सर्वर का पता अमान्य है';

  @override
  String get errCancelled => 'अनुरोध रद्द कर दिया गया';

  @override
  String get customServerOptions => 'कनेक्शन सेटिंग';

  @override
  String get customServerTransport => 'ट्रांसपोर्ट';

  @override
  String get customServerSecurity => 'सुरक्षा';

  @override
  String get customServerCipher => 'साइफ़र';

  @override
  String get customServerWgInterface => 'इंटरफ़ेस';

  @override
  String get customServerWgPeer => 'पीयर';

  @override
  String extAvailableOn(String platforms) {
    return 'इन पर उपलब्ध: $platforms।';
  }

  @override
  String get winwsScopeWarning => 'सभी ऐप का TCP ट्रैफ़िक बदलें?';

  @override
  String get winwsRequirements => 'यह VPN मोड उपलब्ध नहीं है';
}
