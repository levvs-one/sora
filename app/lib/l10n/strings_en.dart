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
  String get stateFailed => 'Not connected';

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
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Not installed';

  @override
  String get sourceCode => 'Source code';

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
  String speedMbps(double value) {
    return '${value.toStringAsFixed(1)} Mbps';
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
  String get errAuth => 'No access to the Sora service';

  @override
  String get errVersion => 'Update Sora: the app and the service are different versions';

  @override
  String get errBusy => 'Wait, the previous command is still running';

  @override
  String get errEngineMissing => 'No engine found for this server';

  @override
  String get errEngineStart => 'The engine did not start';

  @override
  String get errEngineStopped => 'The engine stopped';

  @override
  String get errTunnel => 'No permission to create the VPN connection';

  @override
  String get errServers => 'The server is configured with an error';

  @override
  String get errNetwork => 'Cannot reach the server';

  @override
  String get errTimeout => 'The server did not answer in time';

  @override
  String get errFirewall => 'Could not block the internet outside the VPN';

  @override
  String get errSubFetch => 'Could not load the subscription';

  @override
  String get errSubFormat => 'This is not a subscription link';

  @override
  String get errSubEmpty => 'The subscription has no servers';

  @override
  String get errSubDuplicate => 'This subscription is already added';

  @override
  String get errSubLimit => 'Too many subscriptions';

  @override
  String get errSubScheme => 'The link must start with https://';

  @override
  String get errSecretStore => 'Sora storage is damaged or unavailable';

  @override
  String get errNoServers => 'Add a subscription to connect';

  @override
  String get exportText => 'Text';

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
  String get rangeHint => 'For example, 100-200';

  @override
  String get splitPos => 'Split positions';

  @override
  String get splitPosHint => 'For example, 1, midsld';

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
  String controlPortQuestion(String engine) {
    return '$engine is controlled through a port on this computer. Other programs will be able to tell that a VPN is on.';
  }

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
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '# days', one: '# day', zero: 'a few hours');
    return '$name: the subscription ends in $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left left';
  }

  @override
  String get ruleInvalid => 'This does not look like a site, an IP or a program';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# servers', one: '# server');
    return '$_temp0, in turn';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# servers', one: '# server');
    return '$_temp0, the fastest';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelTun => 'All traffic';

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
  String get noticeInTrayBody => 'Quit from the menu of its icon';

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
  String get importSealed =>
      'This link is encrypted for Happ, and only Happ can read it. Ask your provider for the plain subscription link.';

  @override
  String get understood => 'OK';

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
  String get currentServer => 'Current server';

  @override
  String get trafficDown => 'Downloaded';

  @override
  String get trafficUp => 'Uploaded';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Active rules: $count';
  }

  @override
  String get recentNotifications => 'Recent notifications';

  @override
  String get notificationsEmpty => 'Connection and subscription events will appear here';

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
  String get programsFailed => 'Could not load applications';

  @override
  String get programsEmpty => 'No applications found. Try another name.';

  @override
  String get selectExe => 'Choose an .exe file';

  @override
  String get trafficUnavailable => 'Counters are not available yet';

  @override
  String get speedtest => 'Speed';

  @override
  String get speedtestCheck => 'Check speed';

  @override
  String get speedtestSearch => 'Find a service';

  @override
  String get speedtestEmpty => 'No matches. Change the search.';

  @override
  String get speedtestBackToList => 'Back to services';

  @override
  String get speedtestOpenBrowser => 'Open in browser';

  @override
  String get speedtestUnavailable => 'The embedded browser could not start. Open the service in your system browser.';

  @override
  String get speedtestPageFailed => 'The page could not load. Reload it or open the service in your system browser.';

  @override
  String get speedtestExternalFailed => 'The system browser could not open. Try again.';

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
  String get updateDropWarning =>
      'The VPN connection will drop for a few seconds while Sora and its core update. Continue?';

  @override
  String get updateWaitConnection => 'Wait for the VPN connection and core to become ready.';

  @override
  String get updateDownloading => 'Downloading and verifying files...';

  @override
  String get updateInstalling => 'Preparing the update or waiting for administrator authentication...';

  @override
  String get updateNetworkError => 'Could not download the update. Try again.';

  @override
  String get updateReleaseError => 'The release data or required files are missing or invalid.';

  @override
  String get updateChecksumError => 'The download does not match SHA256SUMS. Nothing was installed.';

  @override
  String get updateInstallError => 'The update did not finish. Authentication may have been cancelled.';

  @override
  String get updateUnsupported =>
      'This executable is not owned by a supported Sora package pair. Use the release installation instructions.';

  @override
  String get updateManual =>
      'Run this command in a terminal to install both verified packages, then reopen Sora. The files stay in the download directory. The VPN connection will drop.';

  @override
  String get updateCopyCommand => 'Copy command';

  @override
  String get updateChecksDisabled => 'Automatic checks are disabled in Settings.';

  @override
  String get updateInstalled => 'Update installed. Reopen Sora.';

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
  String get appCopyright => '© 2026 levvs-one and contributors';

  @override
  String get collapseServers => 'Collapse servers';

  @override
  String get expandServers => 'Expand servers';

  @override
  String get hideDescription => 'Hide description';

  @override
  String get showDescription => 'Show description';

  @override
  String get pendingConnectionChanges => 'Reconnect to apply these changes.';

  @override
  String get reconnectNow => 'Apply and reconnect';

  @override
  String get bypassLimitations =>
      'This mode bypasses DPI only for HTTP and TLS, does not support UDP or change your IP. Use a VPN server for Discord voice, calls and blocked Telegram addresses.';

  @override
  String get errEngineUnsupported =>
      'The selected engine does not support this profile or settings. Choose Auto or a compatible engine.';

  @override
  String get errRestore => 'Connection cleanup was incomplete. Retry disconnecting; see the log for details.';

  @override
  String get errSessionEnded => 'This session has already ended. Refresh the connection state.';

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
      'Choose Auto if you are unsure which engine your server needs. Sora checks the profile and settings before connecting. An engine cannot increase your plan’s bandwidth: performance depends on the server, route, protocol and network.\n\n## Modes\n\n### All traffic (TUN)\n\nSora creates a virtual network interface and routes application traffic through it, including TCP and UDP. Use this mode for Telegram, games and Discord voice. Rules can send specific sites or programs directly or block them. The network service needs permission and a server that supports the required protocol.\n\n### System proxy\n\nSora configures a local HTTP/SOCKS proxy. Applications that respect system proxy settings use it. Applications with their own network stack may connect directly; UDP and voice calls generally need TUN. This mode suits browsers and applications with proxy support.\n\n### No server\n\nOn Linux, Sora uses [zapret](https://github.com/bol-van/zapret) to split and reshape HTTP/TLS requests and bypass some DPI checks. Your IP stays the same and connections go directly to the website. Results depend on your provider and the blocking method.\n\nThe current integration uses tpws for HTTP and TLS over TCP. It does not bypass IP blocking or relay UDP, and cannot guarantee Telegram’s MTProto connections. Use a VPN server with TUN for Discord voice, Telegram calls and these kinds of restrictions.\n\n## Engines\n\n### Auto\n\nSora selects an installed engine that supports the entire connection plan: server protocols, transports, groups, fragmentation and mode. An incompatible manual choice is rejected before stopping the current connection. Choose Auto or another engine and apply the settings again.\n\n### sing-box\n\nNew Sora packages include [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), a fork of [sing-box](https://github.com/SagerNet/sing-box), adding client-side XHTTP and VLESS Encryption. Sora recognizes the build and its capabilities. An upstream build without XHTTP does not gain this capability from its name alone.\n\nSupported protocols include VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard and the AmneziaWG 1.x/2.x parameters Sora can import. Full Xray JSON profiles require Xray. New AWG 3.x fields cannot be imported yet. sing-box uses a password-protected local control port, which other applications on the computer can detect.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) supports VLESS, REALITY, XHTTP, VLESS Encryption and TLS fragmentation. It also runs complete provider Xray profiles while preserving their routing and groups. Such profiles cannot be automatically converted to another engine without changing their behavior.\n\nThe bundled Xray removed the setting that disables TLS certificate verification (`allowInsecure`). Auto selects sing-box or mihomo for ordinary servers requiring this setting. Selecting Xray manually reports incompatibility before stopping the current connection. Older full JSON profiles need an updated provider profile with a verifiable certificate or certificate pin.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) supports ordered fallback and load-balancing groups, XHTTP and AmneziaWG. Choose it when automatic failover to a backup server matters. Sora’s TLS fragmentation setting is unavailable with this engine.\n\n## Compatibility in Sora\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN and TCP/UDP | Yes | Yes | Yes |\n| XHTTP | Yes | Yes | Yes |\n| VLESS Encryption | Yes | Yes | Yes |\n| Full Xray profile | No | Yes | No |\n| TUIC / AnyTLS | Both | No | TUIC |\n| TLS fragmentation | Yes | Yes | No |\n| AmneziaWG 1.x/2.x | Yes¹ | No | Yes |\n| Ordered fallback group | No | No² | Yes |\n\n¹ Profiles with J1/J2/J3/Itime use mihomo; these fields must never be silently discarded. ² For a group of complete Xray profiles, the app selects a backup profile. Support depends on the installed build; check its version in About.\n\n## TUN stack\n\nThe stack handles TCP and UDP inside the virtual interface. In the modes panel, Xray and mihomo offer gVisor, System, Mixed and MIPS. Each engine saves its own preference. System proxy and Serverless modes do not use this preference.\n\n- **Mixed** — TCP uses the system stack, while gVisor handles UDP. This is the default for mihomo on Linux. On Windows, Xray and mihomo default to MIPS.\n- **System** — uses the system stack. Try another option if network applications encounter problems.\n- **gVisor** — handles traffic in userspace.\n- **MIPS** — mihomo’s own IP stack, available in the bundled version 1.19.32.\n\nOn Linux, Xray uses its built-in gVisor by default. System, Mixed and MIPS on Linux use mihomo as the TUN engine, forwarding TCP and UDP to Xray over an authenticated local SOCKS link. Xray retains the protocol, provider profile and routing. These three options require an installed mihomo. On Windows, Xray uses mihomo 1.19.32 or newer for all four TUN stacks. Protocols and routing remain in Xray. Application rules in this combination support only direct connections and blocking; on Linux these rules require Xray’s built-in gVisor.\n\nThe bridge runs a second process. In three idle measurements on Linux, it used about 32–36 MiB more physical memory than native Xray TUN. This does not measure download load: CPU and memory costs depend on connections. sing-box has no stack selector. No stack guarantees better performance in every network. Choose a stack and select Apply and reconnect to try it in your network.\n\n## Applying settings\n\nSelecting a server reconnects automatically. Mode, engine, DNS and rule settings are saved immediately; during an active connection, click Apply and reconnect to use them. Restarting an engine may interrupt downloads and calls. Repeated clicks do not start parallel connections; disconnecting ends the transition and releases the connection.\n\nInternet only through VPN blocks direct traffic when a tunnel drops. It affects the whole machine. An explicit disconnect removes Sora’s rules. If cleanup does not finish, retry disconnecting and open the log.\n\n## Project documentation\n\n- [sing-box-lx: configuration and support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box documentation](https://sing-box.sagernet.org/)\n- [Xray documentation](https://xtls.github.io/)\n- [mihomo documentation](https://wiki.metacubex.one/)\n- [zapret: operation and limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Check servers';

  @override
  String get extensions => 'Extensions';
  @override
  String extRatingLabel(String rating) => 'Rating $rating of 5';
  @override
  String extByAuthor(String author) => 'by $author';
  @override
  String extInstallsCount(String count) => '$count installs';
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
  String exportLogFile(String name) {
    return 'To $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diagnostics';

  @override
  String get diagnosticPackets => 'Packet capture';

  @override
  String get diagnosticEvents => 'Windows events';

  @override
  String get diagnosticCapture => 'Capture for 10 seconds';

  @override
  String get diagnosticNoData => 'No recorded requests yet. Open a speed test website first.';

  @override
  String get diagnosticRequiresTun => 'Packet capture needs an active Sora TUN connection.';

  @override
  String get diagnosticUnavailable => 'This diagnostic is unavailable on this platform.';
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
  String get connConnections => 'connections';
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
  String get updateStageVerify => 'Verifying';
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
}
