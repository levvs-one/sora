// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get stateOff => 'Not connected';

  @override
  String get stateConnecting => 'Connecting';

  @override
  String get stateConnected => 'Connected';

  @override
  String get stateReconnecting => 'Reconnecting';

  @override
  String get stateDisconnecting => 'Disconnecting';

  @override
  String get coreMissing => 'The Sora service is not responding';

  @override
  String get serverAuto => 'Fastest';

  @override
  String get serverBypass => 'No server';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get servers => 'Servers';

  @override
  String get settings => 'Settings';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionLink => 'Subscription link';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Update';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String deleteSubscription(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get routes => 'Routes';

  @override
  String get presetGlobal => 'Everything through VPN';

  @override
  String get presetRu => 'Russia direct';

  @override
  String get presetIr => 'Iran direct';

  @override
  String get presetCn => 'China direct';

  @override
  String get blockAds => 'Block ads';

  @override
  String get killSwitch => 'Internet only through VPN';

  @override
  String get engine => 'Engine';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animations';

  @override
  String get logs => 'Log';

  @override
  String get about => 'About';

  @override
  String get logsAll => 'All';

  @override
  String get logsImportant => 'Important';

  @override
  String get logsErrors => 'Errors';

  @override
  String get search => 'Search';

  @override
  String get export => 'Save to file';

  @override
  String get clear => 'Clear';

  @override
  String get logsEmpty => 'Nothing here';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Not installed';

  @override
  String get sourceCode => 'Source code';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get license => 'License';

  @override
  String usage(String used, String total) {
    return '$used of $total';
  }

  @override
  String until(String date) {
    return 'until $date';
  }

  @override
  String get expired => 'Expired';

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
  String get errGeneric => 'Something went wrong';

  @override
  String get errCore => 'The Sora service is not responding';

  @override
  String get errAuth => 'Access to the Sora service was denied';

  @override
  String get errVersion => 'The Sora app and service have different versions';

  @override
  String get errBusy => 'The previous command is still running';

  @override
  String get errEngineMissing => 'The engine for this server is missing';

  @override
  String get errEngineStart => 'The engine could not start';

  @override
  String get errEngineStopped => 'The engine stopped';

  @override
  String get errTunnel => 'This VPN mode is unavailable';

  @override
  String get errTimeout => 'The server did not respond in time';

  @override
  String get errFirewall => 'Internet access outside the VPN could not be blocked';

  @override
  String get errSubFetch => 'The subscription could not be downloaded';

  @override
  String get deviceIdentity => 'Device identifier';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Reset identifier';

  @override
  String get deviceIdentityResetConfirm => 'Reset the device identifier?';

  @override
  String get errSubDeviceLimit => 'Device limit reached';

  @override
  String get errSubDeviceRequired => 'The provider requires a device identifier';

  @override
  String get errSubFormat => 'The subscription format was not recognized';

  @override
  String get errSubEmpty => 'The subscription has no servers';

  @override
  String get errSubDuplicate => 'This subscription has already been added';

  @override
  String get errSubLimit => 'The subscription limit has been reached';

  @override
  String get errSubScheme => 'Unsupported subscription link scheme';

  @override
  String get errSecretStore => 'Sora storage is damaged or inaccessible';

  @override
  String get errNoServers => 'There are no servers to connect to';

  @override
  String get connections => 'Connections';

  @override
  String get close => 'Close';

  @override
  String get chainDirect => 'Direct';

  @override
  String get chainBlocked => 'Blocked';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Connection';

  @override
  String get sectionNoServer => 'No server';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostics';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Addresses, comma separated';

  @override
  String get fragment => 'TLS fragmentation';

  @override
  String get fragmentPackets => 'What to split';

  @override
  String get fragmentLength => 'Piece size';

  @override
  String get fragmentInterval => 'Pause between pieces';

  @override
  String get byDefault => 'Default';

  @override
  String get splitPos => 'Split positions';

  @override
  String get disorder => 'Reorder pieces';

  @override
  String get tlsRecord => 'Split the TLS record';

  @override
  String get tlsRecordNo => 'No';

  @override
  String get tlsRecordSni => 'At the site name';

  @override
  String get tlsRecordFirst => 'After the first byte';

  @override
  String get hostCase => 'Change Host case';

  @override
  String get probeMethod => 'Method';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Through the engine';

  @override
  String get probeConnect => 'Connection only';

  @override
  String get probeUrl => 'Test address';

  @override
  String get probeTimeout => 'Wait';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get subscriptionSettings => 'Settings';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get autoUpdate => 'Update automatically';

  @override
  String get updateInterval => 'How often';

  @override
  String get intervalProvider => 'As the provider asks';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get logLevel => 'What to record';

  @override
  String get levelDebug => 'Everything';

  @override
  String get levelInfo => 'Usual';

  @override
  String get levelWarning => 'Important';

  @override
  String get levelError => 'Errors only';

  @override
  String get recordDestinations => 'Record site addresses';

  @override
  String get reset => 'Reset settings';

  @override
  String get resetConfirm => 'Reset all settings?';

  @override
  String get resetAction => 'Reset';

  @override
  String get invalidValue => 'This value will not work';

  @override
  String get website => 'Subscription page';

  @override
  String get providerWebsite => 'Provider website';

  @override
  String get support => 'Support';

  @override
  String chooseEngine(String engine) {
    return 'Choose $engine';
  }

  @override
  String get rules => 'Custom rules';

  @override
  String get ruleAdd => 'New rule';

  @override
  String get ruleHint => 'Site, IP or program';

  @override
  String get ruleDirect => 'Direct';

  @override
  String get ruleProxy => 'Through VPN';

  @override
  String get ruleBlock => 'Block';

  @override
  String get failover => 'Switch on failure';

  @override
  String get connectOnStart => 'Connect on start';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
      zero: 'a few hours',
    );
    return '$name: the subscription ends in $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left left';
  }

  @override
  String get ruleInvalid => 'This does not look like a site, an IP or a program';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count servers', one: '$count server');
    return '$_temp0, the fastest';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelProxy => 'System proxy';

  @override
  String get proxyAddress => 'Proxy address';

  @override
  String get copied => 'Copied';

  @override
  String get launchAtLogin => 'Start with the system';

  @override
  String get closeToTray => 'Keep in the tray when closed';

  @override
  String get notifications => 'Notifications';

  @override
  String get trayOpen => 'Open Sora';

  @override
  String get trayConnect => 'Connect';

  @override
  String get trayDisconnect => 'Disconnect';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Quit Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora is still in the tray';

  @override
  String get noticeLost => 'Connection lost';

  @override
  String get noticeLostBody => 'Sora is reconnecting';

  @override
  String get noticeRestored => 'Connected again';

  @override
  String get noticeFailed => 'Couldn\'t connect';

  @override
  String get noticeBackup => 'The main server didn\'t answer; the backup carries the traffic';

  @override
  String get noticeNext => 'The server didn\'t answer; the next one carries the traffic';

  @override
  String get noticeMainBack => 'The main server answers again and carries the traffic';

  @override
  String get noticeSubscription => 'Subscription';

  @override
  String get importTitle => 'Add this subscription?';

  @override
  String get importSealed => 'This link is encrypted for Happ, and only Happ can read it';

  @override
  String get noAnswer => 'no answer';

  @override
  String get home => 'Home';

  @override
  String get navRules => 'Rules';

  @override
  String get navConnections => 'Connections';

  @override
  String get navLogs => 'Logs';

  @override
  String get navAbout => 'About';

  @override
  String get sidebarToggle => 'Toggle sidebar';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get retryConnect => 'Retry connection';

  @override
  String get openLogs => 'Open logs';

  @override
  String get tourReplay => 'Show guide again';

  @override
  String tourStep(int step) {
    return 'Step $step of 5';
  }

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourFinish => 'Done';

  @override
  String get tourAdd => 'Add your provider’s subscription link.';

  @override
  String get tourServer => 'Pick a server. “Fastest” selects one for you.';

  @override
  String get tourConnect => 'Click here to connect or disconnect.';

  @override
  String get tourMode => 'Choose a mode. Kill switch blocks internet if the VPN drops.';

  @override
  String get tourSettings => 'Open settings. You can replay this guide there.';

  @override
  String get chooseProgram => 'Choose a program';

  @override
  String get installedApps => 'Installed applications';

  @override
  String get runningProcesses => 'Running processes';

  @override
  String get programsEmpty => 'No applications found';

  @override
  String get selectExe => 'Choose an .exe file';

  @override
  String get speedtest => 'Speed';

  @override
  String get speedtestSearch => 'Find a service';

  @override
  String get speedtestEmpty => 'No matches';

  @override
  String get speedtestBackToList => 'Back to services';

  @override
  String get speedtestOpenBrowser => 'Open in browser';

  @override
  String get speedtestUnavailable => 'The embedded browser could not start';

  @override
  String get speedtestPageFailed => 'The page could not load';

  @override
  String get speedtestExternalFailed => 'The system browser could not open';

  @override
  String get modes => 'Modes';

  @override
  String get proxyShort => 'Proxy';

  @override
  String get tunMode => 'All traffic (TUN)';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get updates => 'App updates';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateOpenAbout => 'View update';

  @override
  String updateNotes(String version) {
    return 'Changes in $version';
  }

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateChecking => 'Checking...';

  @override
  String get updateNoNotes => 'The release has no notes.';

  @override
  String get updateDropWarning => 'Disconnect to update?';

  @override
  String get updateWaitConnection => 'Connection is not ready';

  @override
  String get updateDownloading => 'Downloading and verifying files...';

  @override
  String get updateInstalling => 'Preparing the update or waiting for administrator authentication...';

  @override
  String get updateNetworkError => 'Could not download the update';

  @override
  String get updateReleaseError => 'The release data or required files are missing or invalid.';

  @override
  String get updateChecksumError => 'The download does not match SHA256SUMS';

  @override
  String get updateInstallError => 'The update did not finish';

  @override
  String get updateUnsupported => 'This executable is not owned by a supported Sora package pair';

  @override
  String get updateManual =>
      'Run this command in a terminal to install both verified packages, then reopen Sora. The files stay in the download directory. The VPN connection will drop.';

  @override
  String get updateVersionRevoked => 'This version has been recalled by the developer';

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
  String get updateRollbackError => 'Automatic rollback failed';

  @override
  String get updateRollbackCacheError =>
      'Could not prepare a verified rollback copy of the current version, so the update was not installed.';

  @override
  String get updateCopyCommand => 'Copy command';

  @override
  String get updateChecksDisabled => 'Automatic checks are disabled in Settings.';

  @override
  String get updateInstalled => 'Update installed';

  @override
  String get projectLinks => 'Project';

  @override
  String get githubReleases => 'Releases and downloads';

  @override
  String get telegramChannel => 'Telegram channel';

  @override
  String get licenses => 'Licenses';

  @override
  String get componentLicenses => 'Component licenses';

  @override
  String get collapseServers => 'Collapse servers';

  @override
  String get expandServers => 'Expand servers';

  @override
  String get hideDescription => 'Hide description';

  @override
  String get showDescription => 'Show description';

  @override
  String get errEngineUnsupported => 'The selected engine does not support this profile or settings';

  @override
  String get errRestore => 'Connection cleanup was incomplete';

  @override
  String get errSessionEnded => 'This session has already ended';

  @override
  String get retryDisconnect => 'Retry disconnecting';

  @override
  String get tunStack => 'TUN stack';

  @override
  String get modesInfo => 'About modes';

  @override
  String get modesGuideTitle => 'Modes and engines';

  @override
  String get modesGuide =>
      'Choose Auto if you are unsure which engine your server needs. Sora checks the profile and settings before connecting. An engine cannot increase your plan’s bandwidth: performance depends on the server, route, protocol and network.\n\n## Modes\n\n### All traffic (TUN)\n\nSora creates a virtual network interface and routes application traffic through it, including TCP and UDP. Use this mode for Telegram, games and Discord voice. Rules can send specific sites or programs directly or block them. The network service needs permission and a server that supports the required protocol.\n\n### System proxy\n\nSora configures a local HTTP/SOCKS proxy. Applications that respect system proxy settings use it. Applications with their own network stack may connect directly; UDP and voice calls generally need TUN. This mode suits browsers and applications with proxy support.\n\n### No server\n\nOn Linux, Sora uses [zapret](https://github.com/bol-van/zapret) to split and reshape HTTP/TLS requests and bypass some DPI checks. Your IP stays the same and connections go directly to the website. Results depend on your provider and the blocking method.\n\nThe current integration uses tpws for HTTP and TLS over TCP. It does not bypass IP blocking or relay UDP, and cannot guarantee Telegram’s MTProto connections. Use a VPN server with TUN for Discord voice, Telegram calls and these kinds of restrictions.\n\n## Engines\n\n### Auto\n\nSora selects an installed engine that supports the entire connection plan: server protocols, transports, groups, fragmentation and mode. An incompatible manual choice is rejected before stopping the current connection. Choose Auto or another engine and apply the settings again.\n\n### sing-box\n\nNew Sora packages include [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), a fork of [sing-box](https://github.com/SagerNet/sing-box), adding client-side XHTTP and VLESS Encryption. Sora recognizes the build and its capabilities. An upstream build without XHTTP does not gain this capability from its name alone.\n\nSupported protocols include VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard and the AmneziaWG 1.x/2.x parameters Sora can import. Full Xray JSON profiles require Xray. New AWG 3.x fields cannot be imported yet. sing-box uses a password-protected local control port, which other applications on the computer can detect.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) supports VLESS, REALITY, XHTTP, VLESS Encryption and TLS fragmentation. It also runs complete provider Xray profiles while preserving their routing and groups. Such profiles cannot be automatically converted to another engine without changing their behavior.\n\nThe bundled Xray removed the setting that disables TLS certificate verification (`allowInsecure`). Auto selects sing-box or mihomo for ordinary servers requiring this setting. Selecting Xray manually reports incompatibility before stopping the current connection. Older full JSON profiles need an updated provider profile with a verifiable certificate or certificate pin.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) supports ordered fallback and load-balancing groups, XHTTP and AmneziaWG. Choose it when automatic failover to a backup server matters. Sora’s TLS fragmentation setting is unavailable with this engine.\n\n## Compatibility in Sora\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN and TCP/UDP | Yes | Yes | Yes |\n| XHTTP | Yes | Yes | Yes |\n| VLESS Encryption | Yes | Yes | Yes |\n| Full Xray profile | No | Yes | No |\n| TUIC / AnyTLS | Both | No | TUIC |\n| mieru | No | No | Yes |\n| NaiveProxy | Yes | No | No |\n| TLS fragmentation | Yes | Yes | No |\n| AmneziaWG 1.x/2.x | Yes¹ | No | Yes |\n| Ordered fallback group | No | No² | Yes |\n\n¹ Profiles with J1/J2/J3/Itime use mihomo; these fields must never be silently discarded. ² For a group of complete Xray profiles, the app selects a backup profile. Support depends on the installed build; check its version in About.\n\n## TUN stack\n\nThe stack handles TCP and UDP inside the virtual interface. In the modes panel, Xray and mihomo offer gVisor, System, Mixed and MIPS. Each engine saves its own preference. System proxy and Serverless modes do not use this preference.\n\n- **Mixed**: TCP uses the system stack, while gVisor handles UDP. This is the default for mihomo on Linux. On Windows, Xray and mihomo default to MIPS.\n- **System**: uses the system stack. Try another option if network applications encounter problems.\n- **gVisor**: handles traffic in userspace.\n- **MIPS**: mihomo’s own IP stack, available in the bundled version 1.19.32.\n\nOn Linux, Xray uses its built-in gVisor by default. System, Mixed and MIPS on Linux use mihomo as the TUN engine, forwarding TCP and UDP to Xray over an authenticated local SOCKS link. Xray retains the protocol, provider profile and routing. These three options require an installed mihomo. On Windows, Xray uses mihomo 1.19.32 or newer for all four TUN stacks. Protocols and routing remain in Xray. Application rules in this combination support only direct connections and blocking; on Linux these rules require Xray’s built-in gVisor.\n\nThe bridge runs a second process. In three idle measurements on Linux, it used about 32–36 MiB more physical memory than native Xray TUN. This does not measure download load: CPU and memory costs depend on connections. sing-box has no stack selector. No stack guarantees better performance in every network.\n\n## Applying settings\n\nSelecting a server reconnects automatically. Your changes to mode, engine, DNS or rules apply once after a short pause, reconnecting automatically; background refreshes do not reconnect. Restarting an engine may interrupt downloads and calls.\n\nInternet only through VPN blocks direct traffic when a tunnel drops. It affects the whole machine. An explicit disconnect removes Sora’s rules. If cleanup does not finish, retry disconnecting and open the log.\n\n## Project documentation\n\n- [sing-box-lx: configuration and support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box documentation](https://sing-box.sagernet.org/)\n- [Xray documentation](https://xtls.github.io/)\n- [mihomo documentation](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: operation and limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC carries TCP through a video call in Jitsi, Yandex Telemost or WB Stream. Import an olcrtc:// link or QR code. It works with sing-box, Xray and mihomo in proxy and TUN modes; UDP is not supported. Both ends need compatible OLC2 builds. The upstream project is archived.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Extensions';

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
  String get extSideloadWarning => 'Self-signed key';

  @override
  String get extPermissionsWidened => 'The update asks for new permissions:';

  @override
  String get extInstall => 'Install';

  @override
  String get extUpdate => 'Update';

  @override
  String get extCancel => 'Cancel';

  @override
  String get extConfirm => 'Confirm';

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
  String get extEmptyInstalled => 'No extensions installed yet';

  @override
  String get extInstallFromFile => 'Install from file';

  @override
  String get extInstallFromUrl => 'Install from URL';

  @override
  String get extDownload => 'Download';

  @override
  String get extDownloading => 'Downloading…';

  @override
  String get extVerifying => 'Verifying…';

  @override
  String get extInstalling => 'Installing…';

  @override
  String get extErrSignature => 'The signature check failed';

  @override
  String get extErrManifest => 'The extension manifest is invalid.';

  @override
  String get extErrNetwork => 'Network error';

  @override
  String get extErrHash => 'The download does not match the catalog';

  @override
  String extErrMinApp(String version) {
    return 'This extension needs app version $version or newer.';
  }

  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';

  @override
  String get extErrGeneric => 'Something went wrong';

  @override
  String get extErrAuthorKeyChanged =>
      'This update is signed with a different author key than the installed version, so it was blocked';

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
  String get extConflictTheme => 'App theme';

  @override
  String get extConflictNetHooks => 'Network hooks';

  @override
  String extConflictWinner(String name) {
    return '$name wins';
  }

  @override
  String extConflictsCount(int count) {
    return 'Extension conflicts: $count';
  }

  @override
  String get extConflictsResolve => 'Resolve';

  @override
  String extVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get extPermissionsTitle => 'Permissions';

  @override
  String get extNoPermissions => 'No special permissions.';

  @override
  String get extSettings => 'Settings';

  @override
  String get extSaveSettings => 'Save settings';

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
  String get extPanelUnavailable => 'The extension panel is unavailable.';

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
  String get extPermRoutingRules => 'Add routing rules';

  @override
  String get extPermNetHooks => 'Hook into the network path';

  @override
  String get extPermNetFetch => 'Fetch URLs from an allowlist';

  @override
  String get extPermBackground => 'Run background tasks';

  @override
  String get extPermNotYetActive => 'Disabled';

  @override
  String get extCapBackground => 'Runs in the background';

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
    return 'Catalog cached $date';
  }

  @override
  String get extChangelog => 'Changelog';

  @override
  String get extImageFailed => 'Couldn\'t load the image';

  @override
  String get extScreenshots => 'Screenshots';

  @override
  String get extSortRelevance => 'Relevance';

  @override
  String get extBgTitle => 'Background task';

  @override
  String get extBgEnabled => 'Run in the background';

  @override
  String get extBgInterval => 'Run every';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutes', one: '$count minute');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours', one: '$count hour');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Network access';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Network: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'To $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diagnostics';

  @override
  String get diagnosticNoData => 'No recorded requests yet';

  @override
  String get qrShareTitle => 'Share via QR';

  @override
  String get qrScanTitle => 'Scan QR code';

  @override
  String get qrCopyLink => 'Copy link';

  @override
  String get qrWarning => 'Only share this code with people you trust.';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => 'No QR code found in this image.';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => 'Open image';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connections',
      one: '$count connection',
    );
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
  String get coreWatchUnstable => 'The connection to the core is unstable';

  @override
  String get watchReconnect => 'Reconnect';

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
  String get errBenchmarkUnsupported => 'Speed measurement requires a newer core';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Measuring $done of $total…';
  }

  @override
  String get profiles => 'Network profiles';

  @override
  String get profilesEmpty => 'No profiles yet';

  @override
  String get profileAdd => 'Add profile';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileSsids => 'Wi-Fi networks (SSID)';

  @override
  String get profileGateways => 'Gateways';

  @override
  String get profileAsns => 'AS numbers';

  @override
  String get profileAutoApply => 'Apply automatically';

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
  String get profileNoTriggers => 'No profile conditions';

  @override
  String get chains => 'Proxy chains';

  @override
  String get chainsEmpty => 'No chains yet';

  @override
  String get chainAdd => 'New chain';

  @override
  String get chainName => 'Chain name';

  @override
  String get chainTooFew => 'A chain needs at least two servers';

  @override
  String get chainTooMany => 'A chain can have at most three servers';

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
  String get chainUnsupported => 'The selected engine does not support chains';

  @override
  String get chainHopMissing => 'A server in the chain is no longer available';

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
  String get syncEmpty => 'No paired devices';

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
  String get syncPaired => 'Device paired';

  @override
  String get syncPairingTitle => 'Pair with this device';

  @override
  String get syncWaiting => 'Waiting for the other device…';

  @override
  String get zapretWithVpn => 'DPI bypass for direct traffic';

  @override
  String get chainDuplicate => 'A server appears more than once in the chain';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';

  @override
  String get tunStackMixed => 'Mixed';

  @override
  String get tunStackSystem => 'System';

  @override
  String get customServerAdd => 'Add custom server';

  @override
  String get customServers => 'My servers';

  @override
  String get customServerName => 'Name';

  @override
  String get customServerNameRequired => 'Name is missing';

  @override
  String get customServerAddress => 'Address';

  @override
  String get customServerAddressRequired => 'Address is missing';

  @override
  String get customServerAddressInvalid => 'Invalid address';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Invalid port';

  @override
  String get customServerProtocol => 'Protocol';

  @override
  String get customServerCredentials => 'Credentials';

  @override
  String get customServerShowSecret => 'Show secret';

  @override
  String get customServerHideSecret => 'Hide secret';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get leakTestTitle => 'Leak test';

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
      other: '$count leaks found',
      one: '$count leak found',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped: not applicable in this session';

  @override
  String get leakTestFix => 'Fix';

  @override
  String get leakTestFixedNote => 'Kill switch is on, run the test again to verify.';

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
  String get noticeDegraded => 'The server slowed down, switched to the best measured one';

  @override
  String get obfs => 'Traffic obfuscation';

  @override
  String get syncCodeExpired => 'The code expired';

  @override
  String get syncDaemonFailed => 'Couldn\'t start the sync service';

  @override
  String get syncDaemonMissing => 'The sora-sync component wasn\'t found';

  @override
  String get syncDaemonStarting => 'Starting the sync service…';

  @override
  String get syncErrAuth => 'The sync service rejected the access token';

  @override
  String get syncErrNotFound => 'The device is no longer paired';

  @override
  String get syncErrPairingActive => 'A pairing session is already open';

  @override
  String get syncErrUnreachable => 'The other device didn\'t answer';

  @override
  String get syncError => 'Sync error';

  @override
  String syncExpiresIn(String duration) {
    return 'Code expires in $duration';
  }

  @override
  String get syncJoining => 'Pairing with the device…';

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
    return 'Received $pulled, sent $pushed';
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
  String syncFrom(String name) {
    return 'from $name';
  }

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid => 'Sync is unavailable on Android';

  @override
  String get diagnosticPackets => 'Packet capture';

  @override
  String get diagnosticEvents => 'Windows events';

  @override
  String get diagnosticCapture => 'Capture for 10 seconds';

  @override
  String get diagnosticRequiresTun => 'Packet capture needs an active Sora TUN connection.';

  @override
  String get diagnosticUnavailable => 'This diagnostic is unavailable on this platform.';

  @override
  String get extErrRevoked => 'The Sora team revoked this extension version because it is unsafe or broken.';

  @override
  String get extErrRevocationsExpired => 'Installation is blocked until the revocation list is refreshed.';

  @override
  String extRevokedDisabled(String names) {
    return 'Revoked extensions were turned off: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Private key';

  @override
  String get customServerWgAddresses => 'Interface addresses';

  @override
  String get customServerWgPeerKey => 'Server public key';

  @override
  String get customServerWgPresharedKey => 'Preshared key';

  @override
  String get customServerWgAllowedIps => 'Allowed IPs';

  @override
  String get customServerWgKeepalive => 'Keepalive, seconds';

  @override
  String get customServerWgKeyInvalid => 'Invalid WireGuard key';

  @override
  String get customServerWgCidrInvalid => 'Invalid CIDR prefix';

  @override
  String get customServerWgKeepaliveInvalid => 'Invalid keepalive interval';

  @override
  String get strictKillSwitch => 'Strict kill switch';

  @override
  String get strictKillSwitchWarning => 'Block traffic outside the VPN after exiting?';

  @override
  String get extWorkerFailed => 'The extension background task failed';

  @override
  String get extAssetRejected => 'The extension file contains unreadable colors or invalid rules';

  @override
  String get extVerifiedSora => 'Verified by Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Open';

  @override
  String get customServerOwn => 'Own server';

  @override
  String get customServerPaste => 'Paste a link';

  @override
  String get customServerUser => 'Username';

  @override
  String get customServerPassword => 'Password';

  @override
  String get customServerSecretRequired => 'Value is missing';

  @override
  String get customServerLinkInvalid => 'Invalid server link';

  @override
  String get errInternal => 'Sora hit an internal error';

  @override
  String get errTls => 'Server certificate rejected';

  @override
  String get errFileAccess => 'Cannot access the file';

  @override
  String get errDataLimit => 'Too much data';

  @override
  String get errCredentials => 'Saved credentials are missing';

  @override
  String subscriptionStale(String time) {
    return 'Last updated: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Not updated yet';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'The server returned HTTP $status',
      zero: 'The server rejected the request',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Server settings are incomplete or unsupported';

  @override
  String get errServerIds => 'Two servers share an identifier';

  @override
  String get errRoutingGroup => 'Routing refers to missing servers or a broken group';

  @override
  String get errConnections => 'Connections are unavailable';

  @override
  String get errLogs => 'This service has no log record';

  @override
  String get errDiagnostics => 'Could not collect diagnostics';

  @override
  String get errMissingItem => 'The requested item no longer exists';

  @override
  String get errInvalidRequest => 'The request contains invalid values';

  @override
  String get errProxyLogin => 'The system proxy cannot use this login';

  @override
  String get errLogFilter => 'The log filter is invalid';

  @override
  String get errSubRedirect => 'The server redirected to an unsafe address';

  @override
  String get errProxySetup => 'Could not configure the system proxy';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String get notificationsMarkRead => 'Mark all as read';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String get desktopNotifications => 'Desktop notifications';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'The subscription update interval is invalid';

  @override
  String get errRule => 'A routing rule is invalid';

  @override
  String get errDns => 'The DNS settings are invalid';

  @override
  String get errEndpoint => 'The server address for the check is invalid';

  @override
  String get errCancelled => 'The request was cancelled';

  @override
  String get customServerOptions => 'Connection settings';

  @override
  String get customServerTransport => 'Transport';

  @override
  String get customServerSecurity => 'Security';

  @override
  String get customServerCipher => 'Cipher';

  @override
  String get customServerWgInterface => 'Interface';

  @override
  String get customServerWgPeer => 'Peer';

  @override
  String extAvailableOn(String platforms) {
    return 'Available on: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Change TCP traffic for all apps?';

  @override
  String get winwsRequirements => 'This VPN mode is unavailable';

  @override
  String get emptyServersTitle => 'Add a server or a subscription';

  @override
  String get emptyServersBody =>
      'Paste a subscription link from your VPN service, add your own server or scan a QR code.';

  @override
  String get qrShort => 'QR code';

  @override
  String get extAboutHello => 'Example panel: shows active connections and sends a test notification.';

  @override
  String get extAboutZapret =>
      'Bypasses blocking without a VPN by reshaping the start of connections so the provider cannot recognise the site.';

  @override
  String get extAboutByedpi => 'Bypasses blocking without a VPN through the local ByeDPI proxy.';

  @override
  String get modeTunHint => 'All of the computer\'s traffic goes through the VPN';

  @override
  String get modeProxyHint => 'Only browsers and apps that use the system proxy';

  @override
  String get modeBypassHint => 'Bypass blocking without a VPN server';

  @override
  String get modeExtensionHint => 'Blocking bypass from an extension';

  @override
  String get engineInfo =>
      'The engine is the program inside Sora that connects to a server and carries your traffic through it. Different engines understand different protocols and behave differently on poor networks.\n\nIn Auto mode Sora picks the engine that fits your server, and usually there is nothing else to do. Xray works best with VLESS, REALITY and XHTTP. sing-box is fast and understands many protocols. mihomo is handy for Clash subscriptions and complex rules.\n\nChange the engine by hand if a server will not connect or keeps dropping. You can always switch back.';

  @override
  String get tunStackInfo =>
      'In TUN mode Sora creates a virtual network card, and all of the computer\'s traffic goes through it. The stack decides what reads those packets.\n\nSystem uses the operating system\'s own network stack and is usually the fastest. gVisor reads packets inside the engine: a little slower, but more compatible with apps and firewalls. Mixed sends TCP through the system and UDP through gVisor.\n\nIf everything works, leave it alone. Try another stack if sites load badly or games and calls lag.';

  @override
  String get protection => 'Protection';

  @override
  String get killSwitchInfo =>
      'Normally, when a VPN drops, apps carry on directly and your provider sees your real traffic. This setting prevents that: while the VPN is on or recovering, the internet goes through it and nowhere else.\n\nIf the connection breaks, sites simply stop loading until it reconnects. Your local network, such as the router and printer, keeps working.\n\nWhen you turn the VPN off yourself, the block lifts and the internet works as usual.';

  @override
  String get strictKillSwitchInfo =>
      'Strict mode goes further: the block stays even if you close Sora, turn the VPN off or restart the computer. Without a VPN there is no internet at all until you turn this switch off.\n\nIt is for people who need to be sure not a single packet leaves outside the VPN, even if the app fails.\n\nFor everyday use, the regular setting is enough. If you turned this on and lost the network, come back here and turn it off.';

  @override
  String get zapretWithVpnInfo =>
      'Not all traffic has to go through a VPN. Rules can send some sites directly, for example local services that do not work from abroad. If your provider slows or blocks such a site, the VPN cannot help, because that traffic does not pass through it.\n\nThis switch sends direct traffic through Zapret, which reshapes the start of each connection so the provider\'s filter does not recognise the site. Traffic that goes through the VPN stays as it is.\n\nIf all of your traffic goes through the VPN, this makes no difference.';

  @override
  String get failoverInfo =>
      'When you connect to a group of servers, Sora watches whether the current one answers. If it stops, the connection moves to the next working server in the group on its own.\n\nWhile the server changes, the connection may drop for a few seconds.\n\nTurn this off to always stay on one server.';

  @override
  String get ipv6Info =>
      'IPv6 is the newer version of internet addresses. Not every provider or VPN server supports it.\n\nWith this on, IPv6 traffic also goes through the VPN. If the server does not support IPv6, sites may load slowly.\n\nWith it off, Sora uses IPv4 only, which is more reliable. Turn it on if you know your server works with IPv6.';

  @override
  String get fragmentInfo =>
      'When an app opens a secure connection, the server name goes in plain text at the very start. This is called SNI, and it tells your provider\'s filter where you are connecting.\n\nFragmentation splits that start into small pieces. The server puts them back together, while a simple filter cannot, so the connection gets through.\n\nThis applies to the connection to your VPN server. Turn it on if a server will not connect although it works for others: that often means the provider is blocking the connection to it.';

  @override
  String get splitPosInfo =>
      'The bypass works by cutting the first packet of a connection into parts. This sets where to cut.\n\nYou can write a byte number, such as 1 or 2, or a marker. The most useful marker is midsld, the middle of the domain: the site name ends up torn across two packets. Separate several places with commas, for example 1,midsld.\n\nThe defaults are usually enough. Change them if the bypass does not work: different providers need different values.';

  @override
  String get disorderInfo =>
      'The first packet is cut into parts, which normally go in order. With this on, the second part goes first.\n\nThe site still gets the data correctly, because TCP puts the parts back in place. Your provider\'s filter often looks only at the first piece to arrive and misses the site name.\n\nTurn it on if plain splitting is not enough. On some networks it slows pages a little.';

  @override
  String get tlsRecordInfo =>
      'Data inside TLS is packed into records. The start of a connection normally sits in one record, where a filter can easily find the site name.\n\nThis setting splits it into two records. The server reads both, while filters that check only the first lose the site name.\n\nIt works well together with packet splitting. A few old servers may refuse it: if a site stops opening, turn this off.';

  @override
  String get hostCaseInfo =>
      'On sites without HTTPS, the request goes in plain text, including the Host header with the site name. Simple filters look for its exact spelling.\n\nThis setting changes the letters of the header name: Host becomes hoSt. To the server it is the same, but an old filter no longer recognises the request.\n\nIt has no effect on HTTPS. Few sites work without it today, so this is rarely needed.';

  @override
  String get probeMethodInfo =>
      'The numbers next to servers show how quickly each one answers. There are several ways to measure that.\n\nThrough the engine: a real request to a site through the server. The most honest method, it shows whether the VPN really works, but it takes longer.\nConnection: only connects to the server\'s port. Fast, but does not check that the VPN works.\nTLS handshake: connects and starts encryption with the server.\nICMP: a plain ping. Some working servers do not answer it.\n\nAuto uses the engine, and a plain connection where it cannot. That is enough for most people.';

  @override
  String get autoSelectInfo => 'How Fastest picks a server: by ping, by measured speed or by both.';

  @override
  String get autoSwitchInfo =>
      'After each ping check, Sora looks at the chosen server. If it has become much slower or stopped answering and a faster one is available, Sora switches on its own.\n\nThe switch takes a couple of seconds and happens at most once every 10 minutes, so the connection does not jump around.\n\nThis only affects a server you picked by hand: Fastest already chooses by itself.';

  @override
  String get probeTls => 'TLS handshake';

  @override
  String get probeIcmp => 'ICMP (ping)';

  @override
  String get serverConfig => 'Server config';

  @override
  String get copy => 'Copy';

  @override
  String get profilesEnabled => 'Use profiles';

  @override
  String get profilesEnabledInfo =>
      'A network profile remembers settings for a specific network: one server at home, another at work.\n\nWhile this switch is off, profiles do nothing: Sora changes no settings and sends no notices about networks.\n\nOnce it is on, Sora recognises a network by its Wi-Fi name or router address and offers the profile\'s settings. If a profile allows it, Sora applies them without asking.';

  @override
  String get extensionBypassInfo =>
      'This is a way around blocks without a VPN. The extension reshapes the start of each connection so the provider\'s filter does not recognise the site, and the page opens directly. Your IP address stays the same.\n\nIt runs instead of a VPN: turning it on ends the current connection, and turning it off returns Sora to the server you had chosen.\n\nIt does not suit everyone: different providers need different profiles, and sites blocked by IP address will not open this way. You choose the profile in the extension\'s panel.';

  @override
  String get infoSources => 'Read more';

  @override
  String get extFilter => 'Filter';

  @override
  String get extBypassRun => 'Blocking bypass';

  @override
  String get chainNoServers =>
      'Only regular servers can join a chain. Xray profiles run on their own, so they are not listed here.';
}
