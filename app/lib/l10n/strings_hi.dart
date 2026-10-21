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
  String get stateFailed => 'जुड़े नहीं हैं';

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
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get notInstalled => 'स्थापित नहीं हे';

  @override
  String get sourceCode => 'सोर्स कोड';

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
  String get errCore => 'Sora सेवा प्रतिसाद नहीं दे रही है';

  @override
  String get errAuth => 'Sora सेवा तक पहुंच नहीं है';

  @override
  String get errVersion => 'अद्यतन Sora: ऐप और सेवा अलग-अलग संस्करण हैं';

  @override
  String get errBusy => 'रुको, पिछला आदेश अभी भी चल रहा है';

  @override
  String get errEngineMissing => 'इस सर्वर के लिए कोई इंजन नहीं मिला';

  @override
  String get errOlcrtcInvalid => 'यह olcRTC सर्वर अधूरा है: प्रदाता, ट्रांसपोर्ट, रूम और एन्क्रिप्शन कुंजी जाँचें';

  @override
  String get errOlcrtcCombination => 'यह olcRTC प्रदाता और ट्रांसपोर्ट एक साथ काम नहीं करते';

  @override
  String get errOlcrtcTokenRequired => 'इस olcRTC सर्वर को प्रदाता खाता टोकन चाहिए जो लिंक में नहीं है';

  @override
  String get errOlcrtcNotConnectable => 'इस olcRTC सर्वर से केवल लिंक से कनेक्ट नहीं किया जा सकता';

  @override
  String get errOlcrtcServerMode => 'Sora केवल olcRTC सर्वरों से कनेक्ट होता है, अपना सर्वर नहीं चलाता';

  @override
  String get olcrtcTcpOnly => 'केवल TCP';

  @override
  String get olcrtcIpv4Only => 'केवल IPv4';

  @override
  String get errEngineStart => 'इंजन चालू नहीं हुआ';

  @override
  String get errEngineStopped => 'इंजन बंद हो गया';

  @override
  String get errTunnel => 'वीपीएन कनेक्शन बनाने की अनुमति नहीं';

  @override
  String get errServers => 'सर्वर एक त्रुटि के साथ कॉन्फ़िगर किया गया है';

  @override
  String get errNetwork => 'सर्वर तक नहीं पहुंच सकता';

  @override
  String get errTimeout => 'सर्वर ने समय पर जवाब नहीं दिया';

  @override
  String get errFirewall => 'वीपीएन के बाहर इंटरनेट को ब्लॉक नहीं किया जा सका';

  @override
  String get errSubFetch => 'सदस्यता लोड नहीं हो सकी';

  @override
  String get errSubFormat => 'यह कोई सदस्यता लिंक नहीं है';

  @override
  String get errSubEmpty => 'सदस्यता में कोई सर्वर नहीं है';

  @override
  String get errSubDuplicate => 'यह सदस्यता पहले ही जोड़ी जा चुकी है';

  @override
  String get errSubLimit => 'बहुत अधिक सदस्यताएँ';

  @override
  String get errSubScheme => 'लिंक https:// से शुरू होना चाहिए';

  @override
  String get errSecretStore => 'Sora भंडारण क्षतिग्रस्त या अनुपलब्ध है';

  @override
  String get errNoServers => 'कनेक्ट करने के लिए सदस्यता जोड़ें';

  @override
  String get exportText => 'मूलपाठ';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'रोशनी';

  @override
  String get themeDark => 'अँधेरा';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'System';

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
  String get dnsHint => 'पते, अल्पविराम से अलग';

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
  String get rangeHint => 'उदाहरण के लिए, 100-200';

  @override
  String get splitPos => 'पदों को विभाजित करें';

  @override
  String get splitPosHint => 'उदाहरण के लिए, 1, मिडएसएलडी';

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
  String controlPortQuestion(String engine) {
    return '$engine को इस कंप्यूटर पर एक पोर्ट के माध्यम से नियंत्रित किया जाता है। अन्य प्रोग्राम यह बताने में सक्षम होंगे कि वीपीएन चालू है।';
  }

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
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'विफलता पर स्विच करें';

  @override
  String get connectOnStart => 'प्रारंभ पर कनेक्ट करें';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'सदस्यता # दिनों में समाप्त हो जाती है',
      one: 'सदस्यता # दिन में समाप्त होती है',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# सर्वर, बदले में',
      one: '# सर्वर, बदले में',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# सर्वर, सबसे तेज़',
      one: '# सर्वर, सबसे तेज़',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'तरीका';

  @override
  String get tunnelTun => 'सारा यातायात';

  @override
  String get tunnelProxy => 'System प्रॉक्सी';

  @override
  String get proxyAddress => 'प्रॉक्सी पता';

  @override
  String get copied => 'कॉपी किया गया';

  @override
  String get launchAtLogin => 'सिस्टम से शुरुआत करें';

  @override
  String get launchAtLoginDetail => 'साइन इन करने पर Sora अपने आप शुरू होगा और ट्रे में रहेगा।';

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
  String get noticeInTrayBody => 'इसके आइकन के मेनू से बाहर निकलें';

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
  String get importSealed =>
      'यह लिंक Happ के लिए एन्क्रिप्ट किया गया है, और केवल Happ ही इसे पढ़ सकता है। सादे सदस्यता लिंक के लिए अपने प्रदाता से पूछें।';

  @override
  String get understood => 'ठीक है';

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
  String get currentServer => 'वर्तमान सर्वर';

  @override
  String get trafficDown => 'डाउनलोड';

  @override
  String get trafficUp => 'अपलोड किए गए';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'सक्रिय नियम: $count';
  }

  @override
  String get recentNotifications => 'हाल की सूचनाएं';

  @override
  String get notificationsEmpty => 'कनेक्शन और सदस्यता ईवेंट यहां दिखाई देंगे';

  @override
  String get retryConnect => 'कनेक्शन पुनः प्रयास करें';

  @override
  String get openLogs => 'लॉग खोलें';

  @override
  String get tourReplay => 'गाइड फिर से दिखाएँ';

  @override
  String tourStep(int step) {
    return '5 का चरण $step';
  }

  @override
  String get tourBack => 'पीछे';

  @override
  String get tourNext => 'अगला';

  @override
  String get tourSkip => 'छोडना';

  @override
  String get tourFinish => 'हो गया';

  @override
  String get tourAdd => 'अपने प्रदाता का सदस्यता लिंक जोड़ें.';

  @override
  String get tourServer => 'एक सर्वर चुनें. \"सबसे तेज़\" आपके लिए एक का चयन करता है।';

  @override
  String get tourConnect => 'कनेक्ट या डिस्कनेक्ट करने के लिए यहां क्लिक करें.';

  @override
  String get tourMode => 'एक मोड चुनें. यदि वीपीएन बंद हो जाए तो किल स्विच इंटरनेट को ब्लॉक कर देता है।';

  @override
  String get tourSettings => 'खुली सेटिंग। आप वहां इस गाइड को दोबारा चला सकते हैं।';

  @override
  String get chooseProgram => 'एक प्रोग्राम चुनें';

  @override
  String get installedApps => 'इंस्टॉल किए गए एप्लिकेशन';

  @override
  String get runningProcesses => 'चल रही प्रक्रियाएँ';

  @override
  String get programsFailed => 'एप्लिकेशन लोड नहीं हो सके';

  @override
  String get programsEmpty => 'कोई एप्लिकेशन नहीं मिला. कोई दूसरा नाम आज़माएं.';

  @override
  String get selectExe => 'कोई .exe फ़ाइल चुनें';

  @override
  String get trafficUnavailable => 'अभी तक काउंटर उपलब्ध नहीं हैं';

  @override
  String get speedtest => 'रफ़्तार';

  @override
  String get speedtestCheck => 'गति की जाँच करें';

  @override
  String get speedtestSearch => 'एक सेवा खोजें';

  @override
  String get speedtestEmpty => 'कोई मेल नहीं। खोज बदलें.';

  @override
  String get speedtestBackToList => 'सेवाओं पर वापस जाएँ';

  @override
  String get speedtestOpenBrowser => 'ब्राउज़र में खोलें';

  @override
  String get speedtestUnavailable => 'एम्बेडेड ब्राउज़र प्रारंभ नहीं हो सका. अपने सिस्टम ब्राउज़र में सेवा खोलें.';

  @override
  String get speedtestPageFailed => 'पेज लोड नहीं हो सका. इसे पुनः लोड करें या अपने सिस्टम ब्राउज़र में सेवा खोलें।';

  @override
  String get speedtestExternalFailed => 'सिस्टम ब्राउज़र नहीं खुल सका. पुनः प्रयास करें।';

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
  String get updateDropWarning =>
      'Sora और इसके मुख्य अपडेट के दौरान वीपीएन कनेक्शन कुछ सेकंड के लिए बंद हो जाएगा। जारी रखना?';

  @override
  String get updateWaitConnection => 'वीपीएन कनेक्शन और कोर के तैयार होने की प्रतीक्षा करें।';

  @override
  String get updateDownloading => 'फ़ाइलें डाउनलोड और सत्यापित की जा रही हैं...';

  @override
  String get updateInstalling => 'अद्यतन तैयार किया जा रहा है या व्यवस्थापक प्रमाणीकरण की प्रतीक्षा की जा रही है...';

  @override
  String get updateNetworkError => 'अपडेट डाउनलोड नहीं हो सका. पुनः प्रयास करें।';

  @override
  String get updateReleaseError => 'रिलीज़ डेटा या आवश्यक फ़ाइलें गुम या अमान्य हैं।';

  @override
  String get updateChecksumError => 'डाउनलोड SHA256SUMS से मेल नहीं खाता. कुछ भी स्थापित नहीं किया गया था.';

  @override
  String get updateInstallError => 'अद्यतन समाप्त नहीं हुआ. प्रमाणीकरण रद्द कर दिया गया हो सकता है.';

  @override
  String get updateUnsupported =>
      'यह निष्पादन योग्य समर्थित Sora पैकेज जोड़ी के स्वामित्व में नहीं है। रिलीज़ इंस्टॉलेशन निर्देशों का उपयोग करें.';

  @override
  String get updateManual =>
      'दोनों सत्यापित पैकेजों को स्थापित करने के लिए इस कमांड को टर्मिनल में चलाएँ, फिर Sora को फिर से खोलें। फ़ाइलें डाउनलोड निर्देशिका में रहती हैं। वीपीएन कनेक्शन बंद हो जाएगा.';

  @override
  String get updateSignaturePending =>
      'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';

  @override
  String get updateManualSigWarning =>
      'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';

  @override
  String get updateWindowsSigBlocked =>
      'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';

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
  String get updateCopyCommand => 'आदेश कॉपी करें';

  @override
  String get updateChecksDisabled => 'सेटिंग्स में स्वचालित जाँच अक्षम हैं।';

  @override
  String get updateInstalled => 'अद्यतन स्थापित किया गया. Sora को फिर से खोलें।';

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
  String get appCopyright => '© 2026 लेव्स-वन और योगदानकर्ता';

  @override
  String get collapseServers => 'सर्वर संक्षिप्त करें';

  @override
  String get expandServers => 'सर्वर का विस्तार करें';

  @override
  String get hideDescription => 'विवरण छिपाएँ';

  @override
  String get showDescription => 'विवरण दिखाएँ';

  @override
  String get pendingConnectionChanges => 'इन परिवर्तनों को लागू करने के लिए पुनः कनेक्ट करें।';

  @override
  String get reconnectNow => 'आवेदन करें और पुनः कनेक्ट करें';

  @override
  String get bypassLimitations =>
      'यह मोड केवल HTTP और TLS के लिए DPI को बायपास करता है, UDP का समर्थन नहीं करता है या आपके IP को नहीं बदलता है। Discord आवाज, कॉल और अवरुद्ध Telegram पतों के लिए वीपीएन सर्वर का उपयोग करें।';

  @override
  String get errEngineUnsupported =>
      'चयनित इंजन इस प्रोफ़ाइल या सेटिंग्स का समर्थन नहीं करता है. ऑटो या संगत इंजन चुनें.';

  @override
  String get errRestore => 'कनेक्शन सफ़ाई अधूरी थी. डिस्कनेक्ट करने का पुनः प्रयास करें; विवरण के लिए लॉग देखें.';

  @override
  String get errSessionEnded => 'यह सत्र पहले ही समाप्त हो चुका है. कनेक्शन स्थिति ताज़ा करें.';

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
      'यदि आप अनिश्चित हैं कि आपके सर्वर को किस इंजन की आवश्यकता है तो ऑटो चुनें। Sora कनेक्ट करने से पहले प्रोफ़ाइल और सेटिंग्स की जाँच करता है। कोई इंजन आपके प्लान की बैंडविड्थ नहीं बढ़ा सकता: प्रदर्शन सर्वर, रूट, प्रोटोकॉल और नेटवर्क पर निर्भर करता है।\n\n## मोड\n\n### समस्त ट्रैफ़िक (TUN)\n\nSora एक वर्चुअल नेटवर्क इंटरफ़ेस बनाता है और टीसीपी और यूडीपी सहित इसके माध्यम से एप्लिकेशन ट्रैफ़िक को रूट करता है। इस मोड का उपयोग Telegram, गेम्स और Discord वॉयस के लिए करें। नियम विशिष्ट साइटों या कार्यक्रमों को सीधे भेज सकते हैं या उन्हें ब्लॉक कर सकते हैं। नेटवर्क सेवा को अनुमति और एक सर्वर की आवश्यकता होती है जो आवश्यक प्रोटोकॉल का समर्थन करता हो।\n\n### System प्रॉक्सी\n\nSora एक स्थानीय HTTP/SOCKS प्रॉक्सी को कॉन्फ़िगर करता है। सिस्टम प्रॉक्सी सेटिंग्स का सम्मान करने वाले एप्लिकेशन इसका उपयोग करते हैं। अपने स्वयं के नेटवर्क स्टैक वाले एप्लिकेशन सीधे कनेक्ट हो सकते हैं; यूडीपी और वॉयस कॉल के लिए आम तौर पर TUN की आवश्यकता होती है। यह मोड प्रॉक्सी समर्थन वाले ब्राउज़र और एप्लिकेशन के लिए उपयुक्त है।\n\n### कोई सर्वर नहीं\n\nLinux पर, Sora HTTP/TLS अनुरोधों को विभाजित और नया आकार देने और कुछ DPI जांचों को बायपास करने के लिए [zapret](https://github.com/bol-van/zapret) का उपयोग करता है। आपका आईपी वही रहता है और कनेक्शन सीधे वेबसाइट पर चले जाते हैं। परिणाम आपके प्रदाता और अवरुद्ध करने की विधि पर निर्भर करते हैं।\n\nवर्तमान एकीकरण टीसीपी पर HTTP और TLS के लिए tpws का उपयोग करता है। यह आईपी ब्लॉकिंग या रिले यूडीपी को बायपास नहीं करता है, और Telegram के MTProto कनेक्शन की गारंटी नहीं दे सकता है। Discord वॉयस, Telegram कॉल और इस प्रकार के प्रतिबंधों के लिए TUN वाले वीपीएन सर्वर का उपयोग करें।\n\n## इंजन\n\n### ऑटो\n\nSora एक स्थापित इंजन का चयन करता है जो संपूर्ण कनेक्शन योजना का समर्थन करता है: सर्वर प्रोटोकॉल, ट्रांसपोर्ट, समूह, विखंडन और मोड। वर्तमान कनेक्शन को रोकने से पहले एक असंगत मैन्युअल विकल्प को अस्वीकार कर दिया जाता है। ऑटो या अन्य इंजन चुनें और सेटिंग्स फिर से लागू करें।\n\n### sing-box\n\nनए Sora पैकेज में [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box) का एक कांटा, क्लाइंट-साइड XHTTP और VLESS Encryption शामिल है। Sora निर्माण और उसकी क्षमताओं को पहचानता है। XHTTP के बिना एक अपस्ट्रीम बिल्ड केवल इसके नाम से यह क्षमता हासिल नहीं करता है।\n\nसमर्थित प्रोटोकॉल में VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard और AmneziaWG 1.x/2.x पैरामीटर शामिल हैं। Sora आयात कर सकते हैं. पूर्ण Xray JSON प्रोफाइल के लिए Xray की आवश्यकता होती है। नई AWG 3.x फ़ील्ड अभी तक आयात नहीं की जा सकतीं. sing-box एक पासवर्ड-संरक्षित स्थानीय नियंत्रण पोर्ट का उपयोग करता है, जिसे कंप्यूटर पर अन्य एप्लिकेशन पता लगा सकते हैं।\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) VLESS, REALITY, XHTTP, VLESS Encryption और TLS विखंडन का समर्थन करता है। यह उनकी रूटिंग और समूहों को संरक्षित करते हुए संपूर्ण प्रदाता Xray प्रोफाइल भी चलाता है। ऐसी प्रोफ़ाइलों को उनके व्यवहार को बदले बिना स्वचालित रूप से किसी अन्य इंजन में परिवर्तित नहीं किया जा सकता है।\n\nबंडल किए गए Xray ने उस सेटिंग को हटा दिया जो TLS प्रमाणपत्र सत्यापन (`allowInsecure`) को अक्षम कर देती है। इस सेटिंग की आवश्यकता वाले सामान्य सर्वर के लिए स्वतः sing-box या mihomo का चयन करता है। Xray का चयन वर्तमान कनेक्शन को रोकने से पहले मैन्युअल रूप से असंगतता की रिपोर्ट करता है। पुराने पूर्ण JSON प्रोफाइल को सत्यापन योग्य प्रमाणपत्र या प्रमाणपत्र पिन के साथ एक अद्यतन प्रदाता प्रोफ़ाइल की आवश्यकता होती है।\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) ऑर्डर किए गए फ़ॉलबैक और लोड-बैलेंसिंग समूहों, XHTTP और AmneziaWG का समर्थन करता है। जब बैकअप सर्वर पर स्वचालित विफलता मायने रखती है तो इसे चुनें। इस इंजन के साथ Sora की TLS फ़्रेग्मेंटेशन सेटिंग उपलब्ध नहीं है।\n\n## Sora में अनुकूलता\n\n| फ़ीचर | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows ट्यून और टीसीपी/यूडीपी | हाँ | हाँ | हाँ |\n| XHTTP | हाँ | हाँ | हाँ |\n| VLESS Encryption | हाँ | हाँ | हाँ |\n| पूर्ण Xray प्रोफ़ाइल | नहीं | हाँ | नहीं |\n| TUIC / AnyTLS | दोनों | नहीं | TUIC |\n| टीएलएस विखंडन | हाँ | हाँ | नहीं |\n| AmneziaWG 1.x/2.x | हाँ¹ | नहीं | हाँ |\n| आदेशित फ़ॉलबैक समूह | नहीं | नहीं² | हाँ |\n\n¹ J1/J2/J3/Itime वाली प्रोफ़ाइलें mihomo का उपयोग करती हैं; इन क्षेत्रों को कभी भी चुपचाप नहीं छोड़ा जाना चाहिए। ² संपूर्ण Xray प्रोफाइल के समूह के लिए, ऐप एक बैकअप प्रोफ़ाइल का चयन करता है। समर्थन स्थापित बिल्ड पर निर्भर करता है; अबाउट में इसका संस्करण जांचें।\n\n## ट्यून स्टैक\n\nस्टैक वर्चुअल इंटरफ़ेस के अंदर टीसीपी और यूडीपी को संभालता है। मोड पैनल में, Xray और mihomo gVisor, System, Mixed और MIPS ऑफर करते हैं। प्रत्येक इंजन अपनी प्राथमिकता बचाता है। System प्रॉक्सी और सर्वर रहित मोड इस प्राथमिकता का उपयोग नहीं करते हैं।\n\n- **Mixed** - टीसीपी सिस्टम स्टैक का उपयोग करता है, जबकि gVisor यूडीपी को संभालता है। Linux पर यह mihomo का डिफ़ॉल्ट है। Windows पर Xray और mihomo डिफ़ॉल्ट रूप से MIPS का उपयोग करते हैं।\n- **System** - सिस्टम स्टैक का उपयोग करता है। यदि नेटवर्क अनुप्रयोगों में समस्याएँ आती हैं तो दूसरा विकल्प आज़माएँ।\n- **gVisor** - यूजरस्पेस में ट्रैफिक को संभालता है।\n- **MIPS** - mihomo का अपना आईपी स्टैक, बंडल संस्करण 1.19.32 में उपलब्ध है।\n\nLinux पर, Xray डिफ़ॉल्ट रूप से अपने अंतर्निहित gVisor का उपयोग करता है। System, Mixed और Linux पर MIPS TUN इंजन के रूप में mihomo का उपयोग करते हैं, एक प्रमाणित स्थानीय SOCKS लिंक पर TCP और UDP को Xray पर अग्रेषित करते हैं। Xray प्रोटोकॉल, प्रदाता प्रोफ़ाइल और रूटिंग को बरकरार रखता है। इन तीन विकल्पों के लिए एक स्थापित mihomo की आवश्यकता होती है। Windows पर Xray चारों TUN स्टैक के लिए mihomo 1.19.32 या नया संस्करण उपयोग करता है। प्रोटोकॉल और रूटिंग Xray में रहते हैं। इस संयोजन में ऐप के नियम केवल सीधे कनेक्शन और ब्लॉक करने का समर्थन करते हैं; Linux पर इन नियमों के लिए Xray का अंतर्निहित gVisor आवश्यक है।\n\nब्रिज दूसरी प्रक्रिया चलाता है। Linux पर तीन निष्क्रिय मापों में, इसने मूल Xray TUN की तुलना में लगभग 32-36 MiB अधिक भौतिक मेमोरी का उपयोग किया। यह डाउनलोड लोड को मापता नहीं है: सीपीयू और मेमोरी की लागत कनेक्शन पर निर्भर करती है। sing-box में कोई स्टैक चयनकर्ता नहीं है। कोई भी स्टैक हर नेटवर्क में बेहतर प्रदर्शन की गारंटी नहीं देता। एक स्टैक चुनें और इसे अपने नेटवर्क में आज़माने के लिए लागू करें और पुनः कनेक्ट करें चुनें।\n\n## सेटिंग्स लागू करना\n\nसर्वर का चयन स्वचालित रूप से पुनः कनेक्ट हो जाता है। मोड, इंजन, डीएनएस और नियम सेटिंग्स तुरंत सहेजी जाती हैं; सक्रिय कनेक्शन के दौरान, लागू करें पर क्लिक करें और उनका उपयोग करने के लिए पुनः कनेक्ट करें। इंजन को पुनः आरंभ करने से डाउनलोड और कॉल बाधित हो सकते हैं। बार-बार क्लिक करने से समानांतर कनेक्शन प्रारंभ नहीं होते; डिस्कनेक्ट करने से संक्रमण समाप्त हो जाता है और कनेक्शन रिलीज़ हो जाता है।\n\nसुरंग गिरने पर केवल वीपीएन के माध्यम से इंटरनेट सीधे यातायात को अवरुद्ध करता है। इसका असर पूरी मशीन पर पड़ता है. एक स्पष्ट डिस्कनेक्ट Sora के नियमों को हटा देता है। यदि सफ़ाई समाप्त नहीं होती है, तो डिस्कनेक्ट करने का पुनः प्रयास करें और लॉग खोलें।\n\n## परियोजना दस्तावेज़ीकरण\n\n- [sing-box-lx: कॉन्फ़िगरेशन और समर्थन](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box दस्तावेज़](https://sing-box.sagernet.org/)\n- [Xray दस्तावेज़](https://xtls.github.io/)\n- [mihomo दस्तावेज़](https://wiki.metacubex.one/)\n- [zapret: संचालन और सीमाएं](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'सर्वरों की जाँच करें';

  @override
  String get extensions => 'एक्सटेंशन';

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
  String get extErrRevoked => 'This extension was revoked by the Sora team and cannot be installed or enabled.';

  @override
  String get extErrRevocationStale =>
      'The revocation list is out of date and cannot be refreshed right now, so installing and enabling extensions is blocked until it is renewed.';

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
    return 'फ़ाइल में $name';
  }

  @override
  String get diagnosticHttp => 'HTTP डायग्नोस्टिक्स';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'अभी तक कोई रिकॉर्डेड अनुरोध नहीं. सबसे पहले एक स्पीड टेस्ट वेबसाइट खोलें।';

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
  String get favorites => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorites yet. Tap the star on a server to add it here.';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

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
  String benchmarkProgress(int done, int total) {
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
  String profileDeleteConfirm(String name) {
    return 'Delete profile \"$name\"?';
  }

  @override
  String profileApplyAsk(String name) {
    return 'Apply profile \"$name\"?';
  }

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) {
    return 'Profile \"$name\" applied';
  }

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) {
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
  String chainDeleteConfirm(String name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(String n) {
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
  String syncRevokeConfirm(String name) {
    return 'Revoke \"$name\"?';
  }

  @override
  String syncLastSync(String time) {
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
  String get lanSharing => 'Share connection on the local network';

  @override
  String get lanSharingHint =>
      'Devices on this network can go online through this connection. Access is by password: enter the proxy address, login and password below on the other device.';

  @override
  String get lanSharingLogin => 'Login';

  @override
  String get lanSharingNoAddress =>
      'No local network address yet — the address will appear here when this device is connected to a network.';

  @override
  String get lanSharingPassword => 'Password';

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
  String get obfsPresetLight => 'Light';

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
  String get obfsMux => 'Multiplexing';

  @override
  String get obfsMuxDetail =>
      'Mux sends many streams over one TLS connection to a REALITY server, so the network sees a single handshake. Turn it off only if a server mishandles mux; separate handshakes may stand out more.';

  @override
  String get fragmentPerSessionNote =>
      'Per-session only: the stored obfuscation profile overrides this when connecting. Curated presets live in Traffic obfuscation.';

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
  String get errConnectionsUnavailable => 'The connection list is unavailable right now';

  @override
  String get errDiagnosticsFailed => 'Could not collect diagnostics';

  @override
  String get errDiagnosticsTooLarge => 'The diagnostics archive is too large';

  @override
  String get errEngineStalled => 'The tunnel stopped passing traffic';

  @override
  String get errEngineUnstable => 'The engine is unstable and keeps stopping';

  @override
  String get errNotFound => 'The requested item was not found';

  @override
  String get errProxyFailed => 'Could not set up the system proxy';

  @override
  String get errLogsUnavailable => 'This core does not keep a log';

  @override
  String get errLogFilterInvalid => 'The log filter is not valid: check the expression and the time range';

  @override
  String get errLogExportFailed => 'Could not export the log: it is too large. Narrow the filter and try again.';

  @override
  String get errProbeEndpointInvalid => 'A server address is missing or not valid';

  @override
  String get errProbeNoEndpoints => 'There are no servers to check';

  @override
  String get errProbeTooMany => 'Too many servers to check at once';

  @override
  String get errProbeUnsupported => 'This core does not support checking servers';

  @override
  String get errProbeChainInvalid => 'Invalid server chain: pick 2 or 3 different servers';

  @override
  String get errBypassStrategyInvalid => 'Invalid bypass strategy: check the split positions and desync settings';

  @override
  String get errCancelled => 'The operation was cancelled';

  @override
  String get errRequestTooLarge => 'The request is too large';

  @override
  String get errSecretNotFound => 'A needed secret was not found';

  @override
  String get errSecretReferenceInvalid => 'The secret reference is not valid';

  @override
  String get errSecretTooLarge => 'The secret is too large to store';

  @override
  String get errSubNotFound => 'The subscription was not found';

  @override
  String get errSubIntervalInvalid => 'The update interval must be between one hour and 30 days';

  @override
  String get deviceIdTitle => 'Device identity';

  @override
  String get deviceIdSend => 'Send device identifier to subscription providers';

  @override
  String get deviceIdSendDetail => 'Providers with a device limit require the identifier to return the subscription.';

  @override
  String get deviceIdCurrent => 'Current identifier';

  @override
  String get deviceIdCopy => 'Copy';

  @override
  String get deviceIdReset => 'Reset identifier';

  @override
  String get deviceIdResetConfirm =>
      'Reset the device identifier? The provider will count this as a new device, and the reset may take another slot of its device limit. The old identifier is not kept.';
}
