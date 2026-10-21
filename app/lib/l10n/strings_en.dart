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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# servers', one: '# server');
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
  String get launchAtLoginDetail => 'Sora will launch automatically when you sign in, hidden in the tray.';

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
  String get programsEmpty => 'No applications found. Try another name.';

  @override
  String get selectExe => 'Choose an .exe file';

  @override
  String get speedtest => 'Speed';

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
  String get updateSignaturePending => 'Update files are checked against the checksums published with the release.';

  @override
  String get updateManualSigWarning =>
      'The files below match the release checksums. Run the command if you downloaded them from the official release.';

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
      'Choose Auto if you are unsure which engine your server needs. Sora checks the profile and settings before connecting. An engine cannot increase your plan’s bandwidth: performance depends on the server, route, protocol and network.\n\n## Modes\n\n### All traffic (TUN)\n\nSora creates a virtual network interface and routes application traffic through it, including TCP and UDP. Use this mode for Telegram, games and Discord voice. Rules can send specific sites or programs directly or block them. The network service needs permission and a server that supports the required protocol.\n\n### System proxy\n\nSora configures a local HTTP/SOCKS proxy. Applications that respect system proxy settings use it. Applications with their own network stack may connect directly; UDP and voice calls generally need TUN. This mode suits browsers and applications with proxy support.\n\n### No server\n\nOn Linux, Sora uses [zapret](https://github.com/bol-van/zapret) to split and reshape HTTP/TLS requests and bypass some DPI checks. Your IP stays the same and connections go directly to the website. Results depend on your provider and the blocking method.\n\nThe current integration uses tpws for HTTP and TLS over TCP. It does not bypass IP blocking or relay UDP, and cannot guarantee Telegram’s MTProto connections. Use a VPN server with TUN for Discord voice, Telegram calls and these kinds of restrictions.\n\n## Engines\n\n### Auto\n\nSora selects an installed engine that supports the entire connection plan: server protocols, transports, groups, fragmentation and mode. An incompatible manual choice is rejected before stopping the current connection. Choose Auto or another engine and apply the settings again.\n\n### sing-box\n\nNew Sora packages include [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), a fork of [sing-box](https://github.com/SagerNet/sing-box), adding client-side XHTTP and VLESS Encryption. Sora recognizes the build and its capabilities. An upstream build without XHTTP does not gain this capability from its name alone.\n\nSupported protocols include VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard and the AmneziaWG 1.x/2.x parameters Sora can import. Full Xray JSON profiles require Xray. New AWG 3.x fields cannot be imported yet. sing-box uses a password-protected local control port, which other applications on the computer can detect.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) supports VLESS, REALITY, XHTTP, VLESS Encryption and TLS fragmentation. It also runs complete provider Xray profiles while preserving their routing and groups. Such profiles cannot be automatically converted to another engine without changing their behavior.\n\nThe bundled Xray removed the setting that disables TLS certificate verification (`allowInsecure`). Auto selects sing-box or mihomo for ordinary servers requiring this setting. Selecting Xray manually reports incompatibility before stopping the current connection. Older full JSON profiles need an updated provider profile with a verifiable certificate or certificate pin.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) supports ordered fallback and load-balancing groups, XHTTP and AmneziaWG. Choose it when automatic failover to a backup server matters. Sora’s TLS fragmentation setting is unavailable with this engine.\n\n## Compatibility in Sora\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN and TCP/UDP | Yes | Yes | Yes |\n| XHTTP | Yes | Yes | Yes |\n| VLESS Encryption | Yes | Yes | Yes |\n| Full Xray profile | No | Yes | No |\n| TUIC / AnyTLS | Both | No | TUIC |\n| TLS fragmentation | Yes | Yes | No |\n| AmneziaWG 1.x/2.x | Yes¹ | No | Yes |\n| Ordered fallback group | No | No² | Yes |\n\n¹ Profiles with J1/J2/J3/Itime use mihomo; these fields must never be silently discarded. ² For a group of complete Xray profiles, the app selects a backup profile. Support depends on the installed build; check its version in About.\n\n## TUN stack\n\nThe stack handles TCP and UDP inside the virtual interface. In the modes panel, Xray and mihomo offer gVisor, System, Mixed and MIPS. Each engine saves its own preference. System proxy and Serverless modes do not use this preference.\n\n- **Mixed**: TCP uses the system stack, while gVisor handles UDP. This is the default for mihomo on Linux. On Windows, Xray and mihomo default to MIPS.\n- **System**: uses the system stack. Try another option if network applications encounter problems.\n- **gVisor**: handles traffic in userspace.\n- **MIPS**: mihomo’s own IP stack, available in the bundled version 1.19.32.\n\nOn Linux, Xray uses its built-in gVisor by default. System, Mixed and MIPS on Linux use mihomo as the TUN engine, forwarding TCP and UDP to Xray over an authenticated local SOCKS link. Xray retains the protocol, provider profile and routing. These three options require an installed mihomo. On Windows, Xray uses mihomo 1.19.32 or newer for all four TUN stacks. Protocols and routing remain in Xray. Application rules in this combination support only direct connections and blocking; on Linux these rules require Xray’s built-in gVisor.\n\nThe bridge runs a second process. In three idle measurements on Linux, it used about 32–36 MiB more physical memory than native Xray TUN. This does not measure download load: CPU and memory costs depend on connections. sing-box has no stack selector. No stack guarantees better performance in every network. Choose a stack and select Apply and reconnect to try it in your network.\n\n## Applying settings\n\nSelecting a server reconnects automatically. Mode, engine, DNS and rule settings are saved immediately; during an active connection, click Apply and reconnect to use them. Restarting an engine may interrupt downloads and calls. Repeated clicks do not start parallel connections; disconnecting ends the transition and releases the connection.\n\nInternet only through VPN blocks direct traffic when a tunnel drops. It affects the whole machine. An explicit disconnect removes Sora’s rules. If cleanup does not finish, retry disconnecting and open the log.\n\n## Project documentation\n\n- [sing-box-lx: configuration and support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box documentation](https://sing-box.sagernet.org/)\n- [Xray documentation](https://xtls.github.io/)\n- [mihomo documentation](https://wiki.metacubex.one/)\n- [zapret: operation and limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Check servers';

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
      'These extensions want the same thing. Choose which one runs; the other stays installed.';

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
      'Your choice is saved on this device. A theme switches right away; network hooks are not run in this version.';

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
      'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings.';

  @override
  String get extPermNotYetActive => 'This permission does nothing in this version of Sora yet.';

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
    return 'Catalog cached $date';
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
      'Fetches data from the internet through the VPN. Only the hosts below are allowed; everything else is blocked.';

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
      'The task runs on schedule while Sora is open, including when it sits in the tray. The shortest interval is 15 minutes.';

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
    return 'To $name';
  }

  @override
  String get diagnosticHttp => 'HTTP diagnostics';

  @override
  String get diagnosticNoData => 'No recorded requests yet. Open a speed test website first.';

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
  String get qrScanHint => 'Choose a screenshot or photo with a QR code, or paste a link';

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
  String benchmarkProgress(Object done, Object total) {
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
  String get profileSsidsHint => 'Home, Office, comma separated';

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
  String chainDeleteConfirm(Object name) {
    return 'Delete chain \"$name\"?';
  }

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

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
  String get chainDuplicate => 'Each server can appear only once';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';

  @override
  String get autoSwitchOnDegradeDetail =>
      'If the selected server slows down a lot or stops answering, Sora switches to the best measured one, at most once every 10 minutes.';

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
  String customServerDeleteConfirm(String name) {
    return 'Delete server “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Add a server manually: address, port and protocol';

  @override
  String get customServerTest => 'Test';

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
      'The old device list was never actually paired, so it was cleared. Pair your devices again, for real this time.';

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
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet: the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'For Shadowsocks: method:password, for example chacha20-ietf-poly1305:password';

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
  String get extErrRevocationsExpired =>
      'The list of revoked extensions could not be renewed. Installing is blocked until it is: check the network and try again.';

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
  String get customServerWgKeyInvalid => 'The key must be 32 bytes of base64, as wg genkey prints.';

  @override
  String get customServerWgCidrInvalid => 'Enter comma separated prefixes such as 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Enter a number of seconds from 0 to 65535.';

  @override
  String get strictKillSwitch => 'Strict kill switch';

  @override
  String get strictKillSwitchWarning =>
      'After connecting, blocks traffic outside the VPN even after a crash, restart or app exit. Only Disconnect or turning this off restores access. After reboot, blocking resumes only when Connect on start is enabled.';

  @override
  String get extWorkerFailed => 'The extension background task failed. Check the extension log.';

  @override
  String get extAssetRejected => 'Extension asset rejected: unreadable colors or invalid rules.';
}
