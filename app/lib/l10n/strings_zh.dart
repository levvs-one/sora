// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get stateOff => '未连接';

  @override
  String get stateConnecting => '正在连接';

  @override
  String get stateConnected => '已连接';

  @override
  String get stateReconnecting => '重新连接';

  @override
  String get stateDisconnecting => '断开连接';

  @override
  String get stateFailed => '未连接';

  @override
  String get coreMissing => 'Sora 服务没有响应';

  @override
  String get serverAuto => '最快';

  @override
  String get serverBypass => '没有服务器';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get servers => '服务器';

  @override
  String get settings => '设置';

  @override
  String get subscription => '订阅';

  @override
  String get subscriptionLink => '订阅链接';

  @override
  String get add => '添加';

  @override
  String get refresh => '更新';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '节省';

  @override
  String get name => '姓名';

  @override
  String deleteSubscription(String name) {
    return '删除“$name”？';
  }

  @override
  String get routes => '路线';

  @override
  String get presetGlobal => '一切都通过 VPN';

  @override
  String get presetRu => '俄罗斯直达';

  @override
  String get presetIr => '伊朗直飞';

  @override
  String get presetCn => '中国直达';

  @override
  String get blockAds => '屏蔽广告';

  @override
  String get killSwitch => '只能通过 VPN 上网';

  @override
  String get engine => '引擎';

  @override
  String get engineAuto => '汽车';

  @override
  String get animations => '动画';

  @override
  String get logs => '日志';

  @override
  String get about => '关于';

  @override
  String get logsAll => '全部';

  @override
  String get logsImportant => '重要的';

  @override
  String get logsErrors => '错误';

  @override
  String get search => '搜索';

  @override
  String get export => '保存到文件';

  @override
  String get clear => '清除';

  @override
  String get logsEmpty => '这里什么都没有';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String get notInstalled => '未安装';

  @override
  String get sourceCode => '源代码';

  @override
  String get license => '执照';

  @override
  String usage(String used, String total) {
    return '$used $total';
  }

  @override
  String until(String date) {
    return '直到$date';
  }

  @override
  String get expired => '已到期';

  @override
  String milliseconds(int n) {
    return '$n 女士';
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
    return '$n 知识库';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n国标';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => '出了点问题';

  @override
  String get errCore => 'Sora 服务没有响应';

  @override
  String get errAuth => '无法访问Sora服务';

  @override
  String get errVersion => '更新Sora：应用程序和服务是不同版本';

  @override
  String get errBusy => '等待，之前的命令仍在运行';

  @override
  String get errEngineMissing => '找不到该服务器的引擎';

  @override
  String get errEngineStart => '发动机没有启动';

  @override
  String get errEngineStopped => '发动机停了';

  @override
  String get errTunnel => '无权创建 VPN 连接';

  @override
  String get errServers => '服务器配置有错误';

  @override
  String get errNetwork => '无法到达服务器';

  @override
  String get errTimeout => '服务器没有及时回复';

  @override
  String get errFirewall => '无法阻止 VPN 之外的互联网';

  @override
  String get errSubFetch => '无法加载订阅';

  @override
  String get errSubFormat => '这不是订阅链接';

  @override
  String get errSubEmpty => '订阅没有服务器';

  @override
  String get errSubDuplicate => '此订阅已添加';

  @override
  String get errSubLimit => '订阅数量过多';

  @override
  String get errSubScheme => '链接必须以 https:// 开头';

  @override
  String get errSecretStore => 'Sora 存储损坏或不可用';

  @override
  String get errNoServers => '添加订阅以连接';

  @override
  String get exportText => '文本';

  @override
  String get connections => '连接';

  @override
  String get close => '关闭';

  @override
  String get chainDirect => '直接的';

  @override
  String get chainBlocked => '被阻止';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '语言';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => '联系';

  @override
  String get sectionNoServer => '没有服务器';

  @override
  String get sectionPing => '平';

  @override
  String get sectionLog => '诊断';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => '域名系统';

  @override
  String get dnsAuto => '汽车';

  @override
  String get dnsHint => '地址，逗号分隔';

  @override
  String get fragment => 'TLS 碎片';

  @override
  String get fragmentPackets => '分割什么';

  @override
  String get fragmentLength => '件数';

  @override
  String get fragmentInterval => '片断之间的停顿';

  @override
  String get byDefault => '默认';

  @override
  String get rangeHint => '例如，100-200';

  @override
  String get splitPos => '分割仓位';

  @override
  String get splitPosHint => '例如，1、midsld';

  @override
  String get disorder => '重新排序件';

  @override
  String get tlsRecord => '拆分 TLS 记录';

  @override
  String get tlsRecordNo => '不';

  @override
  String get tlsRecordSni => '在站点名称处';

  @override
  String get tlsRecordFirst => '第一个字节之后';

  @override
  String get hostCase => '更改主机大小写';

  @override
  String get probeMethod => '方法';

  @override
  String get probeAuto => '汽车';

  @override
  String get probeEngine => '通过发动机';

  @override
  String get probeConnect => '仅连接';

  @override
  String get probeUrl => '测试地址';

  @override
  String get probeTimeout => '等待';

  @override
  String seconds(int n) {
    return '$n S';
  }

  @override
  String get subscriptions => '订阅';

  @override
  String get subscriptionSettings => '设置';

  @override
  String get userAgent => '用户代理';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get updateInterval => '多常';

  @override
  String get intervalProvider => '正如提供商所要求的';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get logLevel => '记录什么';

  @override
  String get levelDebug => '一切';

  @override
  String get levelInfo => '通常';

  @override
  String get levelWarning => '重要的';

  @override
  String get levelError => '仅错误';

  @override
  String get recordDestinations => '记录站点地址';

  @override
  String get reset => '重置设置';

  @override
  String get resetConfirm => '重置所有设置？';

  @override
  String get resetAction => '重置';

  @override
  String get invalidValue => '这个值不会起作用';

  @override
  String get website => '订阅页面';

  @override
  String get providerWebsite => '提供商网站';

  @override
  String get support => '支持';

  @override
  String controlPortQuestion(String engine) {
    return '$engine 通过该计算机上的端口进行控制。 其他程序将能够判断 VPN 是否已打开。';
  }

  @override
  String chooseEngine(String engine) {
    return '选择$engine';
  }

  @override
  String get rules => '自定义规则';

  @override
  String get ruleAdd => '新规则';

  @override
  String get ruleHint => '站点、IP 或程序';

  @override
  String get ruleDirect => '直接的';

  @override
  String get ruleProxy => '通过VPN';

  @override
  String get ruleBlock => '堵塞';

  @override
  String get failover => '开机失败';

  @override
  String get connectOnStart => '启动时连接';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '订阅将在 # 天后结束',
      one: '订阅于 # 天结束',
      zero: '订阅将在几个小时后结束',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name：$left 左';
  }

  @override
  String get ruleInvalid => '这看起来不像一个网站、IP 或程序';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '依次为 # 服务器', one: '# 服务器依次');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#服务器，最快', one: '#服务器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

  @override
  String get tunnelTun => '所有流量';

  @override
  String get tunnelProxy => 'System代理';

  @override
  String get proxyAddress => '代理地址';

  @override
  String get copied => '已复制';

  @override
  String get launchAtLogin => '从系统入手';

  @override
  String get launchAtLoginDetail => '登录时 Sora 会自动启动，并隐藏到系统托盘中。';

  @override
  String get closeToTray => '关闭时保留在托盘中';

  @override
  String get notifications => '通知';

  @override
  String get trayOpen => '打开Sora';

  @override
  String get trayConnect => '连接';

  @override
  String get trayDisconnect => '断开';

  @override
  String get trayServer => '服务器';

  @override
  String get trayQuit => '退出 Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora：$state、$server';
  }

  @override
  String get noticeInTray => 'Sora 仍在托盘中';

  @override
  String get noticeInTrayBody => '从其图标的菜单中退出';

  @override
  String get noticeLost => '连接丢失';

  @override
  String get noticeLostBody => 'Sora 正在重新连接';

  @override
  String get noticeRestored => '再次连接';

  @override
  String get noticeFailed => '无法连接';

  @override
  String get noticeBackup => '主服务器没有应答； 备份承载流量';

  @override
  String get noticeNext => '服务员没有回答； 下一个承载流量';

  @override
  String get noticeMainBack => '主服务器再次应答并承载流量';

  @override
  String get noticeSubscription => '订阅';

  @override
  String get importTitle => '添加此订阅？';

  @override
  String get importSealed => '该链接针对Happ进行了加密，只有Happ可以读取。 向您的提供商询问简单的订阅链接。';

  @override
  String get understood => '好的';

  @override
  String get noAnswer => '没有答案';

  @override
  String get home => '家';

  @override
  String get navRules => '规则';

  @override
  String get navConnections => '连接';

  @override
  String get navLogs => '日志';

  @override
  String get navAbout => '关于';

  @override
  String get sidebarToggle => '切换侧边栏';

  @override
  String get more => '更多的';

  @override
  String get less => '较少的';

  @override
  String get currentServer => '当前服务器';

  @override
  String get trafficDown => '已下载';

  @override
  String get trafficUp => '已上传';

  @override
  String perSecond(String value) {
    return '$value/秒';
  }

  @override
  String activeRules(int count) {
    return '有效规则：$count';
  }

  @override
  String get recentNotifications => '最近的通知';

  @override
  String get notificationsEmpty => '连接和订阅事件将出现在这里';

  @override
  String get retryConnect => '重试连接';

  @override
  String get openLogs => '打开日志';

  @override
  String get tourReplay => '再次显示指南';

  @override
  String tourStep(int step) {
    return '第 5 步 $step';
  }

  @override
  String get tourBack => '后退';

  @override
  String get tourNext => '下一个';

  @override
  String get tourSkip => '跳过';

  @override
  String get tourFinish => '完毕';

  @override
  String get tourAdd => '添加您的提供商的订阅链接。';

  @override
  String get tourServer => '选择一个服务器。 “最快”为您选择一个。';

  @override
  String get tourConnect => '单击此处连接或断开连接。';

  @override
  String get tourMode => '选择一种模式。 如果 VPN 掉线，终止开关会阻止互联网。';

  @override
  String get tourSettings => '打开设置。 您可以在那里重播本指南。';

  @override
  String get chooseProgram => '选择一个程序';

  @override
  String get installedApps => '已安装的应用程序';

  @override
  String get runningProcesses => '正在运行的进程';

  @override
  String get programsFailed => '无法加载应用程序';

  @override
  String get programsEmpty => '没有找到应用程序。 尝试另一个名字。';

  @override
  String get selectExe => '选择一个 .exe 文件';

  @override
  String get trafficUnavailable => '柜台尚未可用';

  @override
  String get speedtest => '速度';

  @override
  String get speedtestCheck => '检查速度';

  @override
  String get speedtestSearch => '查找服务';

  @override
  String get speedtestEmpty => '没有匹配项。 更改搜索。';

  @override
  String get speedtestBackToList => '返回服务';

  @override
  String get speedtestOpenBrowser => '在浏览器中打开';

  @override
  String get speedtestUnavailable => '嵌入式浏览器无法启动。 在系统浏览器中打开该服务。';

  @override
  String get speedtestPageFailed => '页面无法加载。 重新加载它或在系统浏览器中打开该服务。';

  @override
  String get speedtestExternalFailed => '系统浏览器无法打开。 再试一次。';

  @override
  String get modes => '模式';

  @override
  String get proxyShort => '代理人';

  @override
  String get tunMode => '所有流量 (TUN)';

  @override
  String get checkUpdates => '检查更新';

  @override
  String get updates => '应用程序更新';

  @override
  String updateAvailable(String version) {
    return '版本 $version 可用';
  }

  @override
  String get updateOpenAbout => '查看更新';

  @override
  String updateNotes(String version) {
    return '$version的变化';
  }

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateChecking => '检查...';

  @override
  String get updateNoNotes => '该版本没有注释。';

  @override
  String get updateDropWarning => '当 Sora 及其核心更新时，VPN 连接将断开几秒钟。 继续？';

  @override
  String get updateWaitConnection => '等待 VPN 连接和核心准备就绪。';

  @override
  String get updateDownloading => '正在下载并验证文件...';

  @override
  String get updateInstalling => '正在准备更新或等待管理员身份验证...';

  @override
  String get updateNetworkError => '无法下载更新。 再试一次。';

  @override
  String get updateReleaseError => '发布数据或所需文件丢失或无效。';

  @override
  String get updateChecksumError => '下载的内容与 SHA256SUMS 不匹配。 没有安装任何东西。';

  @override
  String get updateInstallError => '更新没有完成。 身份验证可能已被取消。';

  @override
  String get updateUnsupported => '此可执行文件不属于受支持的 Sora 软件包对。 使用发行版安装说明。';

  @override
  String get updateManual => '在终端中运行此命令以安装两个经过验证的软件包，然后重新打开 Sora。 文件保留在下载目录中。 VPN 连接将会断开。';

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
  String get updateCopyCommand => '复制命令';

  @override
  String get updateChecksDisabled => '在“设置”中禁用自动检查。';

  @override
  String get updateInstalled => '已安装更新。 重新打开 Sora。';

  @override
  String get projectLinks => '项目';

  @override
  String get githubReleases => '发布和下载';

  @override
  String get telegramChannel => 'Telegram通道';

  @override
  String get licenses => '许可证';

  @override
  String get componentLicenses => '组件许可证';

  @override
  String get appCopyright => '© 2026 levvs-one 和贡献者';

  @override
  String get collapseServers => '崩溃服务器';

  @override
  String get expandServers => '扩展服务器';

  @override
  String get hideDescription => '隐藏描述';

  @override
  String get showDescription => '显示说明';

  @override
  String get pendingConnectionChanges => '重新连接以应用这些更改。';

  @override
  String get reconnectNow => '应用并重新连接';

  @override
  String get bypassLimitations =>
      '此模式仅针对 HTTP 和 TLS 绕过 DPI，不支持 UDP 或更改您的 IP。 使用 VPN 服务器进行 Discord 语音、呼叫和阻止的 Telegram 地址。';

  @override
  String get errEngineUnsupported => '所选引擎不支持此配置文件或设置。 选择自动或兼容的引擎。';

  @override
  String get errRestore => '连接清理不完整。 重试断开连接； 详细信息请参阅日志。';

  @override
  String get errSessionEnded => '本次会议已经结束。 刷新连接状态。';

  @override
  String get retryDisconnect => '重试断开连接';

  @override
  String get tunStack => 'TUN堆栈';

  @override
  String get modesInfo => '关于模式';

  @override
  String get modesGuideTitle => '模式和引擎';

  @override
  String get modesGuide =>
      '如果您不确定您的服务器需要哪个引擎，请选择自动。 Sora 在连接前检查配置文件和设置。 引擎无法增加计划的带宽：性能取决于服务器、路由、协议和网络。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 创建虚拟网络接口并通过它路由应用程序流量，包括 TCP 和 UDP。 Telegram、游戏和Discord语音使用此模式。 规则可以直接发送或阻止特定站点或程序。 网络服务需要权限和支持所需协议的服务器。\n\n### System 代理\n\nSora 配置本地 HTTP/SOCKS 代理。 尊重系统代理设置的应用程序使用它。 拥有自己的网络堆栈的应用程序可以直接连接； UDP和语音通话一般需要TUN。 此模式适合具有代理支持的浏览器和应用程序。\n\n### 没有服务器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 来拆分和重塑 HTTP/TLS 请求并绕过一些 DPI 检查。 您的 IP 保持不变，连接直接进入网站。 结果取决于您的提供商和阻止方法。\n\n当前集成使用 tpws 进行 HTTP 和 TCP 上的 TLS。 它不绕过IP阻塞或中继UDP，并且不能保证Telegram的MTProto连接。 使用具有 TUN 的 VPN 服务器进行 Discord 语音、Telegram 呼叫和此类限制。\n\n## 引擎\n\n＃＃＃ 汽车\n\nSora 选择支持整个连接计划的已安装引擎：服务器协议、传输、组、分段和模式。 在停止当前连接之前，不兼容的手动选择将被拒绝。 选择自动或其他引擎并再次应用设置。\n\n### sing-box\n\n新的 Sora 软件包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，添加了客户端 XHTTP 和 VLESS Encryption。 Sora 认可该构建及其功能。 没有 XHTTP 的上游版本无法仅从其名称中获得此功能。\n\n支持的协议包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可导入的 AmneziaWG 1.x/2.x 参数。完整的 Xray JSON 配置需要 Xray。目前尚不能导入新的 AWG 3.x 字段。sing-box 使用受密码保护的本地控制端口，计算机上的其他应用可以检测到该端口。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支持 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它还运行完整的提供商 Xray 配置文件，同时保留其路由和组。 此类配置文件无法在不改变其行为的情况下自动转换为另一个引擎。\n\n捆绑的 Xray 删除了禁用 TLS 证书验证的设置（“allowInsecure”）。 对于需要此设置的普通服务器，自动选择sing-box或mihomo。 在停止当前连接之前选择 Xray 手动报告不兼容性。 较旧的完整 JSON 配置文件需要更新的提供者配置文件以及可验证的证书或证书 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支持有序回退和负载均衡组 XHTTP 和 AmneziaWG。 当自动故障转移到备份服务器很重要时选择它。 Sora 的 TLS 碎片设置在此引擎上不可用。\n\n## Sora 的兼容性\n\n| 特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 和 TCP/UDP | 是的 | 是的 | 是的 |\n| XHTTP | 是的 | 是的 | 是的 |\n| VLESS Encryption | 是的 | 是的 | 是的 |\n| Xray 完整简介 | 没有 | 是的 | 没有 |\n| TUIC / AnyTLS | 两者 | 没有 | TUIC |\n| TLS 碎片 | 是的 | 是的 | 没有 |\n| AmneziaWG 1.x/2.x | 是的 1 | 没有 | 是的 |\n| 有序后备组 | 没有 | 没有² | 是的 |\n\n1 带 J1/J2/J3/Itime 的型材使用 mihomo； 这些字段绝不能被默默地丢弃。 ² 对于一组完整的 Xray 配置文件，应用程序会选择一个备份配置文件。 支持取决于安装的版本； 在“关于”中检查其版本。\n\n## TUN 堆栈\n\n该堆栈在虚拟接口内处理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每个引擎都会保存自己的首选项。 System 代理和无服务器模式不使用此首选项。\n\n- **Mixed** — TCP 使用系统堆栈，而 gVisor 处理 UDP。 这是 Linux 上 mihomo 的默认设置。在 Windows 上，Xray 和 mihomo 默认使用 MIPS。\n- **System** — 使用系统堆栈。 如果网络应用程序遇到问题，请尝试其他选项。\n- **gVisor** — 处理用户空间中的流量。\n- **MIPS** — mihomo 自己的 IP 堆栈，在捆绑版本 1.19.32 中提供。\n\n在Linux上，Xray默认使用其内置的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作为 TUN 引擎，通过经过身份验证的本地 SOCKS 链路将 TCP 和 UDP 转发到 Xray。 Xray 保留协议、提供商配置文件和路由。 这三个选项需要安装 mihomo。 在Windows 上，Xray 的四种 TUN 协议栈均使用 mihomo 1.19.32 或更高版本。协议和路由仍由 Xray 处理。此组合中的应用规则仅支持直连和阻断；在 Linux 上，这些规则需要 Xray 内置的 gVisor。\n\n桥接器运行第二个进程。 在 Linux 上的三个空闲测量中，它比本机 Xray TUN 多使用了约 32-36 MiB 的物理内存。 这不测量下载负载：CPU 和内存成本取决于连接。 sing-box没有堆栈选择器。 没有任何堆栈可以保证每个网络都有更好的性能。 选择一个堆栈并选择“应用并重新连接”以在您的网络中进行尝试。\n\n## 应用设置\n\n选择服务器会自动重新连接。 模式、引擎、DNS和规则设置立即保存； 在活动连接期间，单击应用并重新连接即可使用它们。 重新启动引擎可能会中断下载和调用。 重复点击不会启动并行连接； 断开连接结束转换并释放连接。\n\n当隧道断开时，仅通过 VPN 的 Internet 会阻止直接流量。 它影响整个机器。 显式断开连接会删除 Sora 的规则。 如果清理未完成，请重试断开连接并打开日志。\n\n## 项目文档\n\n- [sing-box-lx：配置和支持](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文档](https://sing-box.sagernet.org/)\n- [Xray 文档](https://xtls.github.io/)\n- [mihomo 文档](https://wiki.metacubex.one/)\n- [zapret：操作和限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '检查服务器';

  @override
  String get extensions => '扩展';

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
    return '保存为 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 诊断';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => '尚未记录请求。 首先打开一个速度测试网站。';

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
  String get qrScanHint => '选择包含二维码的截图或照片，或粘贴链接';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => '此图片中未找到二维码。';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => '打开图片';

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
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密码，例如 chacha20-ietf-poly1305:password';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class SZhHans extends SZh {
  SZhHans() : super('zh_Hans');

  @override
  String get stateOff => '未连接';

  @override
  String get stateConnecting => '正在连接';

  @override
  String get stateConnected => '已连接';

  @override
  String get stateReconnecting => '重新连接';

  @override
  String get stateDisconnecting => '断开连接';

  @override
  String get stateFailed => '未连接';

  @override
  String get coreMissing => 'Sora 服务没有响应';

  @override
  String get serverAuto => '最快';

  @override
  String get serverBypass => '没有服务器';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get servers => '服务器';

  @override
  String get settings => '设置';

  @override
  String get subscription => '订阅';

  @override
  String get subscriptionLink => '订阅链接';

  @override
  String get add => '添加';

  @override
  String get refresh => '更新';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '节省';

  @override
  String get name => '姓名';

  @override
  String deleteSubscription(String name) {
    return '删除“$name”？';
  }

  @override
  String get routes => '路线';

  @override
  String get presetGlobal => '一切都通过 VPN';

  @override
  String get presetRu => '俄罗斯直达';

  @override
  String get presetIr => '伊朗直飞';

  @override
  String get presetCn => '中国直达';

  @override
  String get blockAds => '屏蔽广告';

  @override
  String get killSwitch => '只能通过 VPN 上网';

  @override
  String get engine => '引擎';

  @override
  String get engineAuto => '汽车';

  @override
  String get animations => '动画';

  @override
  String get logs => '日志';

  @override
  String get about => '关于';

  @override
  String get logsAll => '全部';

  @override
  String get logsImportant => '重要的';

  @override
  String get logsErrors => '错误';

  @override
  String get search => '搜索';

  @override
  String get export => '保存到文件';

  @override
  String get clear => '清除';

  @override
  String get logsEmpty => '这里什么都没有';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String get notInstalled => '未安装';

  @override
  String get sourceCode => '源代码';

  @override
  String get license => '执照';

  @override
  String usage(String used, String total) {
    return '$used $total';
  }

  @override
  String until(String date) {
    return '直到$date';
  }

  @override
  String get expired => '已到期';

  @override
  String milliseconds(int n) {
    return '$n 女士';
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
    return '$n 知识库';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n国标';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => '出了点问题';

  @override
  String get errCore => 'Sora 服务没有响应';

  @override
  String get errAuth => '无法访问Sora服务';

  @override
  String get errVersion => '更新Sora：应用程序和服务是不同版本';

  @override
  String get errBusy => '等待，之前的命令仍在运行';

  @override
  String get errEngineMissing => '找不到该服务器的引擎';

  @override
  String get errEngineStart => '发动机没有启动';

  @override
  String get errEngineStopped => '发动机停了';

  @override
  String get errTunnel => '无权创建 VPN 连接';

  @override
  String get errServers => '服务器配置有错误';

  @override
  String get errNetwork => '无法到达服务器';

  @override
  String get errTimeout => '服务器没有及时回复';

  @override
  String get errFirewall => '无法阻止 VPN 之外的互联网';

  @override
  String get errSubFetch => '无法加载订阅';

  @override
  String get errSubFormat => '这不是订阅链接';

  @override
  String get errSubEmpty => '订阅没有服务器';

  @override
  String get errSubDuplicate => '此订阅已添加';

  @override
  String get errSubLimit => '订阅数量过多';

  @override
  String get errSubScheme => '链接必须以 https:// 开头';

  @override
  String get errSecretStore => 'Sora 存储损坏或不可用';

  @override
  String get errNoServers => '添加订阅以连接';

  @override
  String get exportText => '文本';

  @override
  String get connections => '连接';

  @override
  String get close => '关闭';

  @override
  String get chainDirect => '直接的';

  @override
  String get chainBlocked => '被阻止';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '语言';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => '联系';

  @override
  String get sectionNoServer => '没有服务器';

  @override
  String get sectionPing => '平';

  @override
  String get sectionLog => '诊断';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => '域名系统';

  @override
  String get dnsAuto => '汽车';

  @override
  String get dnsHint => '地址，逗号分隔';

  @override
  String get fragment => 'TLS 碎片';

  @override
  String get fragmentPackets => '分割什么';

  @override
  String get fragmentLength => '件数';

  @override
  String get fragmentInterval => '片断之间的停顿';

  @override
  String get byDefault => '默认';

  @override
  String get rangeHint => '例如，100-200';

  @override
  String get splitPos => '分割仓位';

  @override
  String get splitPosHint => '例如，1、midsld';

  @override
  String get disorder => '重新排序件';

  @override
  String get tlsRecord => '拆分 TLS 记录';

  @override
  String get tlsRecordNo => '不';

  @override
  String get tlsRecordSni => '在站点名称处';

  @override
  String get tlsRecordFirst => '第一个字节之后';

  @override
  String get hostCase => '更改主机大小写';

  @override
  String get probeMethod => '方法';

  @override
  String get probeAuto => '汽车';

  @override
  String get probeEngine => '通过发动机';

  @override
  String get probeConnect => '仅连接';

  @override
  String get probeUrl => '测试地址';

  @override
  String get probeTimeout => '等待';

  @override
  String seconds(int n) {
    return '$n S';
  }

  @override
  String get subscriptions => '订阅';

  @override
  String get subscriptionSettings => '设置';

  @override
  String get userAgent => '用户代理';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get updateInterval => '多常';

  @override
  String get intervalProvider => '正如提供商所要求的';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get logLevel => '记录什么';

  @override
  String get levelDebug => '一切';

  @override
  String get levelInfo => '通常';

  @override
  String get levelWarning => '重要的';

  @override
  String get levelError => '仅错误';

  @override
  String get recordDestinations => '记录站点地址';

  @override
  String get reset => '重置设置';

  @override
  String get resetConfirm => '重置所有设置？';

  @override
  String get resetAction => '重置';

  @override
  String get invalidValue => '这个值不会起作用';

  @override
  String get website => '订阅页面';

  @override
  String get providerWebsite => '提供商网站';

  @override
  String get support => '支持';

  @override
  String controlPortQuestion(String engine) {
    return '$engine 通过该计算机上的端口进行控制。 其他程序将能够判断 VPN 是否已打开。';
  }

  @override
  String chooseEngine(String engine) {
    return '选择$engine';
  }

  @override
  String get rules => '自定义规则';

  @override
  String get ruleAdd => '新规则';

  @override
  String get ruleHint => '站点、IP 或程序';

  @override
  String get ruleDirect => '直接的';

  @override
  String get ruleProxy => '通过VPN';

  @override
  String get ruleBlock => '堵塞';

  @override
  String get failover => '开机失败';

  @override
  String get connectOnStart => '启动时连接';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '订阅将在 # 天后结束',
      one: '订阅于 # 天结束',
      zero: '订阅将在几个小时后结束',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name：$left 左';
  }

  @override
  String get ruleInvalid => '这看起来不像一个网站、IP 或程序';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '依次为 # 服务器', one: '# 服务器依次');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#服务器，最快', one: '#服务器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

  @override
  String get tunnelTun => '所有流量';

  @override
  String get tunnelProxy => 'System代理';

  @override
  String get proxyAddress => '代理地址';

  @override
  String get copied => '已复制';

  @override
  String get launchAtLogin => '从系统入手';

  @override
  String get launchAtLoginDetail => '登录时 Sora 会自动启动，并隐藏到系统托盘中。';

  @override
  String get closeToTray => '关闭时保留在托盘中';

  @override
  String get notifications => '通知';

  @override
  String get trayOpen => '打开Sora';

  @override
  String get trayConnect => '连接';

  @override
  String get trayDisconnect => '断开';

  @override
  String get trayServer => '服务器';

  @override
  String get trayQuit => '退出 Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora：$state、$server';
  }

  @override
  String get noticeInTray => 'Sora 仍在托盘中';

  @override
  String get noticeInTrayBody => '从其图标的菜单中退出';

  @override
  String get noticeLost => '连接丢失';

  @override
  String get noticeLostBody => 'Sora 正在重新连接';

  @override
  String get noticeRestored => '再次连接';

  @override
  String get noticeFailed => '无法连接';

  @override
  String get noticeBackup => '主服务器没有应答； 备份承载流量';

  @override
  String get noticeNext => '服务员没有回答； 下一个承载流量';

  @override
  String get noticeMainBack => '主服务器再次应答并承载流量';

  @override
  String get noticeSubscription => '订阅';

  @override
  String get importTitle => '添加此订阅？';

  @override
  String get importSealed => '该链接针对Happ进行了加密，只有Happ可以读取。 向您的提供商询问简单的订阅链接。';

  @override
  String get understood => '好的';

  @override
  String get noAnswer => '没有答案';

  @override
  String get home => '家';

  @override
  String get navRules => '规则';

  @override
  String get navConnections => '连接';

  @override
  String get navLogs => '日志';

  @override
  String get navAbout => '关于';

  @override
  String get sidebarToggle => '切换侧边栏';

  @override
  String get more => '更多的';

  @override
  String get less => '较少的';

  @override
  String get currentServer => '当前服务器';

  @override
  String get trafficDown => '已下载';

  @override
  String get trafficUp => '已上传';

  @override
  String perSecond(String value) {
    return '$value/秒';
  }

  @override
  String activeRules(int count) {
    return '有效规则：$count';
  }

  @override
  String get recentNotifications => '最近的通知';

  @override
  String get notificationsEmpty => '连接和订阅事件将出现在这里';

  @override
  String get retryConnect => '重试连接';

  @override
  String get openLogs => '打开日志';

  @override
  String get tourReplay => '再次显示指南';

  @override
  String tourStep(int step) {
    return '第 5 步 $step';
  }

  @override
  String get tourBack => '后退';

  @override
  String get tourNext => '下一个';

  @override
  String get tourSkip => '跳过';

  @override
  String get tourFinish => '完毕';

  @override
  String get tourAdd => '添加您的提供商的订阅链接。';

  @override
  String get tourServer => '选择一个服务器。 “最快”为您选择一个。';

  @override
  String get tourConnect => '单击此处连接或断开连接。';

  @override
  String get tourMode => '选择一种模式。 如果 VPN 掉线，终止开关会阻止互联网。';

  @override
  String get tourSettings => '打开设置。 您可以在那里重播本指南。';

  @override
  String get chooseProgram => '选择一个程序';

  @override
  String get installedApps => '已安装的应用程序';

  @override
  String get runningProcesses => '正在运行的进程';

  @override
  String get programsFailed => '无法加载应用程序';

  @override
  String get programsEmpty => '没有找到应用程序。 尝试另一个名字。';

  @override
  String get selectExe => '选择一个 .exe 文件';

  @override
  String get trafficUnavailable => '柜台尚未可用';

  @override
  String get speedtest => '速度';

  @override
  String get speedtestCheck => '检查速度';

  @override
  String get speedtestSearch => '查找服务';

  @override
  String get speedtestEmpty => '没有匹配项。 更改搜索。';

  @override
  String get speedtestBackToList => '返回服务';

  @override
  String get speedtestOpenBrowser => '在浏览器中打开';

  @override
  String get speedtestUnavailable => '嵌入式浏览器无法启动。 在系统浏览器中打开该服务。';

  @override
  String get speedtestPageFailed => '页面无法加载。 重新加载它或在系统浏览器中打开该服务。';

  @override
  String get speedtestExternalFailed => '系统浏览器无法打开。 再试一次。';

  @override
  String get modes => '模式';

  @override
  String get proxyShort => '代理人';

  @override
  String get tunMode => '所有流量 (TUN)';

  @override
  String get checkUpdates => '检查更新';

  @override
  String get updates => '应用程序更新';

  @override
  String updateAvailable(String version) {
    return '版本 $version 可用';
  }

  @override
  String get updateOpenAbout => '查看更新';

  @override
  String updateNotes(String version) {
    return '$version的变化';
  }

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateChecking => '检查...';

  @override
  String get updateNoNotes => '该版本没有注释。';

  @override
  String get updateDropWarning => '当 Sora 及其核心更新时，VPN 连接将断开几秒钟。 继续？';

  @override
  String get updateWaitConnection => '等待 VPN 连接和核心准备就绪。';

  @override
  String get updateDownloading => '正在下载并验证文件...';

  @override
  String get updateInstalling => '正在准备更新或等待管理员身份验证...';

  @override
  String get updateNetworkError => '无法下载更新。 再试一次。';

  @override
  String get updateReleaseError => '发布数据或所需文件丢失或无效。';

  @override
  String get updateChecksumError => '下载的内容与 SHA256SUMS 不匹配。 没有安装任何东西。';

  @override
  String get updateInstallError => '更新没有完成。 身份验证可能已被取消。';

  @override
  String get updateUnsupported => '此可执行文件不属于受支持的 Sora 软件包对。 使用发行版安装说明。';

  @override
  String get updateManual => '在终端中运行此命令以安装两个经过验证的软件包，然后重新打开 Sora。 文件保留在下载目录中。 VPN 连接将会断开。';

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
  String get updateCopyCommand => '复制命令';

  @override
  String get updateChecksDisabled => '在“设置”中禁用自动检查。';

  @override
  String get updateInstalled => '已安装更新。 重新打开 Sora。';

  @override
  String get projectLinks => '项目';

  @override
  String get githubReleases => '发布和下载';

  @override
  String get telegramChannel => 'Telegram通道';

  @override
  String get licenses => '许可证';

  @override
  String get componentLicenses => '组件许可证';

  @override
  String get appCopyright => '© 2026 levvs-one 和贡献者';

  @override
  String get collapseServers => '崩溃服务器';

  @override
  String get expandServers => '扩展服务器';

  @override
  String get hideDescription => '隐藏描述';

  @override
  String get showDescription => '显示说明';

  @override
  String get pendingConnectionChanges => '重新连接以应用这些更改。';

  @override
  String get reconnectNow => '应用并重新连接';

  @override
  String get bypassLimitations =>
      '此模式仅针对 HTTP 和 TLS 绕过 DPI，不支持 UDP 或更改您的 IP。 使用 VPN 服务器进行 Discord 语音、呼叫和阻止的 Telegram 地址。';

  @override
  String get errEngineUnsupported => '所选引擎不支持此配置文件或设置。 选择自动或兼容的引擎。';

  @override
  String get errRestore => '连接清理不完整。 重试断开连接； 详细信息请参阅日志。';

  @override
  String get errSessionEnded => '本次会议已经结束。 刷新连接状态。';

  @override
  String get retryDisconnect => '重试断开连接';

  @override
  String get tunStack => 'TUN堆栈';

  @override
  String get modesInfo => '关于模式';

  @override
  String get modesGuideTitle => '模式和引擎';

  @override
  String get modesGuide =>
      '如果您不确定您的服务器需要哪个引擎，请选择自动。 Sora 在连接前检查配置文件和设置。 引擎无法增加计划的带宽：性能取决于服务器、路由、协议和网络。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 创建虚拟网络接口并通过它路由应用程序流量，包括 TCP 和 UDP。 Telegram、游戏和Discord语音使用此模式。 规则可以直接发送或阻止特定站点或程序。 网络服务需要权限和支持所需协议的服务器。\n\n### System 代理\n\nSora 配置本地 HTTP/SOCKS 代理。 尊重系统代理设置的应用程序使用它。 拥有自己的网络堆栈的应用程序可以直接连接； UDP和语音通话一般需要TUN。 此模式适合具有代理支持的浏览器和应用程序。\n\n### 没有服务器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 来拆分和重塑 HTTP/TLS 请求并绕过一些 DPI 检查。 您的 IP 保持不变，连接直接进入网站。 结果取决于您的提供商和阻止方法。\n\n当前集成使用 tpws 进行 HTTP 和 TCP 上的 TLS。 它不绕过IP阻塞或中继UDP，并且不能保证Telegram的MTProto连接。 使用具有 TUN 的 VPN 服务器进行 Discord 语音、Telegram 呼叫和此类限制。\n\n## 引擎\n\n＃＃＃ 汽车\n\nSora 选择支持整个连接计划的已安装引擎：服务器协议、传输、组、分段和模式。 在停止当前连接之前，不兼容的手动选择将被拒绝。 选择自动或其他引擎并再次应用设置。\n\n### sing-box\n\n新的 Sora 软件包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，添加了客户端 XHTTP 和 VLESS Encryption。 Sora 认可该构建及其功能。 没有 XHTTP 的上游版本无法仅从其名称中获得此功能。\n\n支持的协议包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可导入的 AmneziaWG 1.x/2.x 参数。完整的 Xray JSON 配置需要 Xray。目前尚不能导入新的 AWG 3.x 字段。sing-box 使用受密码保护的本地控制端口，计算机上的其他应用可以检测到该端口。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支持 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它还运行完整的提供商 Xray 配置文件，同时保留其路由和组。 此类配置文件无法在不改变其行为的情况下自动转换为另一个引擎。\n\n捆绑的 Xray 删除了禁用 TLS 证书验证的设置（“allowInsecure”）。 对于需要此设置的普通服务器，自动选择sing-box或mihomo。 在停止当前连接之前选择 Xray 手动报告不兼容性。 较旧的完整 JSON 配置文件需要更新的提供者配置文件以及可验证的证书或证书 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支持有序回退和负载均衡组 XHTTP 和 AmneziaWG。 当自动故障转移到备份服务器很重要时选择它。 Sora 的 TLS 碎片设置在此引擎上不可用。\n\n## Sora 的兼容性\n\n| 特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 和 TCP/UDP | 是的 | 是的 | 是的 |\n| XHTTP | 是的 | 是的 | 是的 |\n| VLESS Encryption | 是的 | 是的 | 是的 |\n| Xray 完整简介 | 没有 | 是的 | 没有 |\n| TUIC / AnyTLS | 两者 | 没有 | TUIC |\n| TLS 碎片 | 是的 | 是的 | 没有 |\n| AmneziaWG 1.x/2.x | 是的 1 | 没有 | 是的 |\n| 有序后备组 | 没有 | 没有² | 是的 |\n\n1 带 J1/J2/J3/Itime 的型材使用 mihomo； 这些字段绝不能被默默地丢弃。 ² 对于一组完整的 Xray 配置文件，应用程序会选择一个备份配置文件。 支持取决于安装的版本； 在“关于”中检查其版本。\n\n## TUN 堆栈\n\n该堆栈在虚拟接口内处理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每个引擎都会保存自己的首选项。 System 代理和无服务器模式不使用此首选项。\n\n- **Mixed** — TCP 使用系统堆栈，而 gVisor 处理 UDP。 这是 Linux 上 mihomo 的默认设置。在 Windows 上，Xray 和 mihomo 默认使用 MIPS。\n- **System** — 使用系统堆栈。 如果网络应用程序遇到问题，请尝试其他选项。\n- **gVisor** — 处理用户空间中的流量。\n- **MIPS** — mihomo 自己的 IP 堆栈，在捆绑版本 1.19.32 中提供。\n\n在Linux上，Xray默认使用其内置的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作为 TUN 引擎，通过经过身份验证的本地 SOCKS 链路将 TCP 和 UDP 转发到 Xray。 Xray 保留协议、提供商配置文件和路由。 这三个选项需要安装 mihomo。 在Windows 上，Xray 的四种 TUN 协议栈均使用 mihomo 1.19.32 或更高版本。协议和路由仍由 Xray 处理。此组合中的应用规则仅支持直连和阻断；在 Linux 上，这些规则需要 Xray 内置的 gVisor。\n\n桥接器运行第二个进程。 在 Linux 上的三个空闲测量中，它比本机 Xray TUN 多使用了约 32-36 MiB 的物理内存。 这不测量下载负载：CPU 和内存成本取决于连接。 sing-box没有堆栈选择器。 没有任何堆栈可以保证每个网络都有更好的性能。 选择一个堆栈并选择“应用并重新连接”以在您的网络中进行尝试。\n\n## 应用设置\n\n选择服务器会自动重新连接。 模式、引擎、DNS和规则设置立即保存； 在活动连接期间，单击应用并重新连接即可使用它们。 重新启动引擎可能会中断下载和调用。 重复点击不会启动并行连接； 断开连接结束转换并释放连接。\n\n当隧道断开时，仅通过 VPN 的 Internet 会阻止直接流量。 它影响整个机器。 显式断开连接会删除 Sora 的规则。 如果清理未完成，请重试断开连接并打开日志。\n\n## 项目文档\n\n- [sing-box-lx：配置和支持](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文档](https://sing-box.sagernet.org/)\n- [Xray 文档](https://xtls.github.io/)\n- [mihomo 文档](https://wiki.metacubex.one/)\n- [zapret：操作和限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '检查服务器';

  @override
  String get extensions => '扩展';

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
    return '保存为 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 诊断';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => '尚未记录请求。 首先打开一个速度测试网站。';

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
  String get qrScanHint => '选择包含二维码的截图或照片，或粘贴链接';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => '此图片中未找到二维码。';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => '打开图片';

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
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密码，例如 chacha20-ietf-poly1305:password';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class SZhHant extends SZh {
  SZhHant() : super('zh_Hant');

  @override
  String get stateOff => '未連接';

  @override
  String get stateConnecting => '正在連接';

  @override
  String get stateConnected => '已連接';

  @override
  String get stateReconnecting => '重新連接';

  @override
  String get stateDisconnecting => '斷開連接';

  @override
  String get stateFailed => '未連接';

  @override
  String get coreMissing => 'Sora 服務沒有回應';

  @override
  String get serverAuto => '最快';

  @override
  String get serverBypass => '沒有伺服器';

  @override
  String get addSubscription => '新增訂閱';

  @override
  String get servers => '伺服器';

  @override
  String get settings => '設定';

  @override
  String get subscription => '訂閱';

  @override
  String get subscriptionLink => '訂閱連結';

  @override
  String get add => '添加';

  @override
  String get refresh => '更新';

  @override
  String get rename => '重新命名';

  @override
  String get delete => '刪除';

  @override
  String get cancel => '取消';

  @override
  String get save => '節省';

  @override
  String get name => '姓名';

  @override
  String deleteSubscription(String name) {
    return '刪除“$name”？';
  }

  @override
  String get routes => '路線';

  @override
  String get presetGlobal => '一切都透過 VPN';

  @override
  String get presetRu => '俄羅斯直達';

  @override
  String get presetIr => '伊朗直飛';

  @override
  String get presetCn => '中國直達';

  @override
  String get blockAds => '封鎖廣告';

  @override
  String get killSwitch => '只能透過 VPN 上網';

  @override
  String get engine => '引擎';

  @override
  String get engineAuto => '汽車';

  @override
  String get animations => '動畫';

  @override
  String get logs => '紀錄';

  @override
  String get about => '關於';

  @override
  String get logsAll => '全部';

  @override
  String get logsImportant => '重要的';

  @override
  String get logsErrors => '錯誤';

  @override
  String get search => '搜尋';

  @override
  String get export => '儲存到文件';

  @override
  String get clear => '清除';

  @override
  String get logsEmpty => '這裡什麼都沒有';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String get notInstalled => '未安裝';

  @override
  String get sourceCode => '原始碼';

  @override
  String get license => '執照';

  @override
  String usage(String used, String total) {
    return '$used $total';
  }

  @override
  String until(String date) {
    return '直到$date';
  }

  @override
  String get expired => '已到期';

  @override
  String milliseconds(int n) {
    return '$n 女士';
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
    return '$n 知識庫';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n國標';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => '出了點問題';

  @override
  String get errCore => 'Sora 服務沒有回應';

  @override
  String get errAuth => '無法存取Sora服務';

  @override
  String get errVersion => '更新Sora：應用程式和服務是不同版本';

  @override
  String get errBusy => '等待，先前的命令仍在運行';

  @override
  String get errEngineMissing => '找不到該伺服器的引擎';

  @override
  String get errEngineStart => '引擎沒有啟動';

  @override
  String get errEngineStopped => '引擎停了';

  @override
  String get errTunnel => '無權建立 VPN 連接';

  @override
  String get errServers => '伺服器配置有錯誤';

  @override
  String get errNetwork => '無法到達伺服器';

  @override
  String get errTimeout => '伺服器沒有及時回复';

  @override
  String get errFirewall => '無法阻止 VPN 以外的互聯網';

  @override
  String get errSubFetch => '無法加載訂閱';

  @override
  String get errSubFormat => '這不是訂閱鏈接';

  @override
  String get errSubEmpty => '訂閱沒有伺服器';

  @override
  String get errSubDuplicate => '此訂閱已新增';

  @override
  String get errSubLimit => '訂閱數量太多';

  @override
  String get errSubScheme => '連結必須以 https:// 開頭';

  @override
  String get errSecretStore => 'Sora 儲存損壞或無法使用';

  @override
  String get errNoServers => '新增訂閱以連接';

  @override
  String get exportText => '文字';

  @override
  String get connections => '連接';

  @override
  String get close => '關閉';

  @override
  String get chainDirect => '直接的';

  @override
  String get chainBlocked => '被阻止';

  @override
  String get theme => '主題';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '語言';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => '聯繫';

  @override
  String get sectionNoServer => '沒有伺服器';

  @override
  String get sectionPing => '平';

  @override
  String get sectionLog => '診斷';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => '域名系統';

  @override
  String get dnsAuto => '汽車';

  @override
  String get dnsHint => '地址，逗號分隔';

  @override
  String get fragment => 'TLS 碎片';

  @override
  String get fragmentPackets => '分割什麼';

  @override
  String get fragmentLength => '件數';

  @override
  String get fragmentInterval => '片段之間的停頓';

  @override
  String get byDefault => '預設';

  @override
  String get rangeHint => '例如，100-200';

  @override
  String get splitPos => '分割部位';

  @override
  String get splitPosHint => '例如，1、midsld';

  @override
  String get disorder => '重新排序件';

  @override
  String get tlsRecord => '拆分 TLS 記錄';

  @override
  String get tlsRecordNo => '不';

  @override
  String get tlsRecordSni => '在網站名稱處';

  @override
  String get tlsRecordFirst => '第一個位元組之後';

  @override
  String get hostCase => '更改主機大小寫';

  @override
  String get probeMethod => '方法';

  @override
  String get probeAuto => '汽車';

  @override
  String get probeEngine => '透過發動機';

  @override
  String get probeConnect => '僅連接';

  @override
  String get probeUrl => '測試地址';

  @override
  String get probeTimeout => '等待';

  @override
  String seconds(int n) {
    return '$n S';
  }

  @override
  String get subscriptions => '訂閱';

  @override
  String get subscriptionSettings => '設定';

  @override
  String get userAgent => '使用者代理';

  @override
  String get autoUpdate => '自動更新';

  @override
  String get updateInterval => '多常';

  @override
  String get intervalProvider => '正如提供者所要求的';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get logLevel => '記錄什麼';

  @override
  String get levelDebug => '一切';

  @override
  String get levelInfo => '通常';

  @override
  String get levelWarning => '重要的';

  @override
  String get levelError => '僅錯誤';

  @override
  String get recordDestinations => '記錄站址';

  @override
  String get reset => '重置設定';

  @override
  String get resetConfirm => '重置所有設定？';

  @override
  String get resetAction => '重置';

  @override
  String get invalidValue => '這個值不會起作用';

  @override
  String get website => '訂閱頁面';

  @override
  String get providerWebsite => '提供者網站';

  @override
  String get support => '支援';

  @override
  String controlPortQuestion(String engine) {
    return '$engine 透過此電腦上的連接埠進行控制。 其他程式將能夠判斷 VPN 是否已開啟。';
  }

  @override
  String chooseEngine(String engine) {
    return '選擇$engine';
  }

  @override
  String get rules => '自訂規則';

  @override
  String get ruleAdd => '新規則';

  @override
  String get ruleHint => '站點、IP 或程式';

  @override
  String get ruleDirect => '直接的';

  @override
  String get ruleProxy => '透過VPN';

  @override
  String get ruleBlock => '堵塞';

  @override
  String get failover => '開機失敗';

  @override
  String get connectOnStart => '啟動時連接';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '訂閱將在 # 天後結束',
      one: '訂閱於 # 天結束',
      zero: '訂閱將在幾個小時後結束',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name：$left 左';
  }

  @override
  String get ruleInvalid => '這看起來不像一個網站、IP 或程式';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '依序為 # 伺服器', one: '# 伺服器依序');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#伺服器，最快', one: '#伺服器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

  @override
  String get tunnelTun => '所有流量';

  @override
  String get tunnelProxy => 'System代理';

  @override
  String get proxyAddress => '代理地址';

  @override
  String get copied => '已複製';

  @override
  String get launchAtLogin => '從系統入手';

  @override
  String get launchAtLoginDetail => '登入時 Sora 會自動啟動，並隱藏到系統托盤中。';

  @override
  String get closeToTray => '關閉時保留在托盤中';

  @override
  String get notifications => '通知';

  @override
  String get trayOpen => '開啟Sora';

  @override
  String get trayConnect => '連接';

  @override
  String get trayDisconnect => '斷開';

  @override
  String get trayServer => '伺服器';

  @override
  String get trayQuit => '退出 Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora：$state、$server';
  }

  @override
  String get noticeInTray => 'Sora 仍在托盤中';

  @override
  String get noticeInTrayBody => '從其圖標的選單中退出';

  @override
  String get noticeLost => '連線遺失';

  @override
  String get noticeLostBody => 'Sora 正在重新連接';

  @override
  String get noticeRestored => '再次連接';

  @override
  String get noticeFailed => '無法連接';

  @override
  String get noticeBackup => '主伺服器沒有應答；備份承載流量';

  @override
  String get noticeNext => '服務員沒有回答；下一個承載流量';

  @override
  String get noticeMainBack => '主伺服器再次應答並承載流量';

  @override
  String get noticeSubscription => '訂閱';

  @override
  String get importTitle => '新增此訂閱？';

  @override
  String get importSealed => '此連結針對Happ進行了加密，只有Happ可以讀取。 向您的提供者詢問簡單的訂閱連結。';

  @override
  String get understood => '好的';

  @override
  String get noAnswer => '沒有答案';

  @override
  String get home => '家';

  @override
  String get navRules => '規則';

  @override
  String get navConnections => '連接';

  @override
  String get navLogs => '紀錄';

  @override
  String get navAbout => '關於';

  @override
  String get sidebarToggle => '切換側邊欄';

  @override
  String get more => '更多的';

  @override
  String get less => '較少的';

  @override
  String get currentServer => '目前伺服器';

  @override
  String get trafficDown => '已下載';

  @override
  String get trafficUp => '已上傳';

  @override
  String perSecond(String value) {
    return '$value/秒';
  }

  @override
  String activeRules(int count) {
    return '有效規則：$count';
  }

  @override
  String get recentNotifications => '最近的通知';

  @override
  String get notificationsEmpty => '連接和訂閱事件將出現在這裡';

  @override
  String get retryConnect => '重試連接';

  @override
  String get openLogs => '打開日誌';

  @override
  String get tourReplay => '再次顯示指南';

  @override
  String tourStep(int step) {
    return '第 5 步 $step';
  }

  @override
  String get tourBack => '後退';

  @override
  String get tourNext => '下一個';

  @override
  String get tourSkip => '跳過';

  @override
  String get tourFinish => '完畢';

  @override
  String get tourAdd => '新增您的提供者的訂閱連結。';

  @override
  String get tourServer => '選擇一個伺服器。 “最快”為您選擇一個。';

  @override
  String get tourConnect => '按一下此處連接或斷開連接。';

  @override
  String get tourMode => '選擇一種模式。 如果 VPN 斷線，終止開關會阻止網路。';

  @override
  String get tourSettings => '打開設定。 您可以在那裡重播本指南。';

  @override
  String get chooseProgram => '選擇一個程序';

  @override
  String get installedApps => '已安裝的應用程式';

  @override
  String get runningProcesses => '正在運行的進程';

  @override
  String get programsFailed => '無法載入應用程式';

  @override
  String get programsEmpty => '沒有找到應用程式。 嘗試另一個名字。';

  @override
  String get selectExe => '選擇一個 .exe 檔案';

  @override
  String get trafficUnavailable => '櫃檯尚未可用';

  @override
  String get speedtest => '速度';

  @override
  String get speedtestCheck => '檢查速度';

  @override
  String get speedtestSearch => '尋找服務';

  @override
  String get speedtestEmpty => '沒有匹配項。 更改搜尋。';

  @override
  String get speedtestBackToList => '返回服務';

  @override
  String get speedtestOpenBrowser => '在瀏覽器中開啟';

  @override
  String get speedtestUnavailable => '嵌入式瀏覽器無法啟動。 在系統瀏覽器中開啟該服務。';

  @override
  String get speedtestPageFailed => '頁面無法載入。 重新載入它或在系統瀏覽器中開啟該服務。';

  @override
  String get speedtestExternalFailed => '系統瀏覽器無法開啟。 再試一次。';

  @override
  String get modes => '模式';

  @override
  String get proxyShort => '代理人';

  @override
  String get tunMode => '所有流量 (TUN)';

  @override
  String get checkUpdates => '檢查更新';

  @override
  String get updates => '應用程式更新';

  @override
  String updateAvailable(String version) {
    return '版本 $version 可用';
  }

  @override
  String get updateOpenAbout => '查看更新';

  @override
  String updateNotes(String version) {
    return '$version的變化';
  }

  @override
  String get updateCheck => '檢查更新';

  @override
  String get updateChecking => '檢查...';

  @override
  String get updateNoNotes => '該版本沒有註解。';

  @override
  String get updateDropWarning => '當 Sora 及其核心更新時，VPN 連線將斷開幾秒鐘。 繼續？';

  @override
  String get updateWaitConnection => '等待 VPN 連線和核心準備就緒。';

  @override
  String get updateDownloading => '正在下載並驗證文件...';

  @override
  String get updateInstalling => '正在準備更新或等待管理員身份驗證...';

  @override
  String get updateNetworkError => '無法下載更新。 再試一次。';

  @override
  String get updateReleaseError => '發布資料或所需文件遺失或無效。';

  @override
  String get updateChecksumError => '下載的內容與 SHA256SUMS 不符。 沒有安裝任何東西。';

  @override
  String get updateInstallError => '更新沒有完成。 身份驗證可能已被取消。';

  @override
  String get updateUnsupported => '此可執行檔不屬於受支援的 Sora 軟體包對。 使用發行版安裝說明。';

  @override
  String get updateManual => '在終端機中執行此命令以安裝兩個經過驗證的軟體包，然後重新開啟 Sora。 檔案保留在下載目錄中。 VPN 連線將會中斷。';

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
  String get updateCopyCommand => '複製指令';

  @override
  String get updateChecksDisabled => '在「設定」中停用自動檢查。';

  @override
  String get updateInstalled => '已安裝更新。 重新開啟 Sora。';

  @override
  String get projectLinks => '專案';

  @override
  String get githubReleases => '發佈和下載';

  @override
  String get telegramChannel => 'Telegram通道';

  @override
  String get licenses => '許可證';

  @override
  String get componentLicenses => '組件許可證';

  @override
  String get appCopyright => '© 2026 levvs-one 和貢獻者';

  @override
  String get collapseServers => '崩潰伺服器';

  @override
  String get expandServers => '擴充伺服器';

  @override
  String get hideDescription => '隱藏描述';

  @override
  String get showDescription => '顯示說明';

  @override
  String get pendingConnectionChanges => '重新連接以套用這些變更。';

  @override
  String get reconnectNow => '應用並重新連接';

  @override
  String get bypassLimitations =>
      '此模式僅針對 HTTP 和 TLS 繞過 DPI，不支援 UDP 或變更您的 IP。 使用 VPN 伺服器進行 Discord 語音、呼叫和封鎖的 Telegram 位址。';

  @override
  String get errEngineUnsupported => '所選引擎不支援此設定檔或設定。 選擇自動或相容的引擎。';

  @override
  String get errRestore => '連線清理不完整。 重試斷開連線；詳細資訊請參閱日誌。';

  @override
  String get errSessionEnded => '本次會議已經結束。 刷新連線狀態。';

  @override
  String get retryDisconnect => '重試斷開連接';

  @override
  String get tunStack => 'TUN堆疊';

  @override
  String get modesInfo => '關於模式';

  @override
  String get modesGuideTitle => '模式和引擎';

  @override
  String get modesGuide =>
      '如果您不確定您的伺服器需要哪個引擎，請選擇自動。 Sora 在連接前檢查設定檔和設定。 引擎無法增加計劃的頻寬：效能取決於伺服器、路由、協定和網路。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 建立虛擬網路介面並透過它路由應用程式流量，包括 TCP 和 UDP。 Telegram、遊戲和Discord語音使用此模式。 規則可以直接發送或封鎖特定網站或程式。 網路服務需要權限和支援所需協定的伺服器。\n\n### System 代理\n\nSora 設定本機 HTTP/SOCKS 代理程式。 尊重系統代理設定的應用程式使用它。 擁有自己的網路堆疊的應用程式可以直接連接； UDP和語音通話一般需要TUN。 此模式適合具有代理支援的瀏覽器和應用程式。\n\n### 沒有伺服器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 來拆分和重塑 HTTP/TLS 請求並繞過一些 DPI 檢查。 您的 IP 保持不變，連線直接進入網站。 結果取決於您的提供者和阻止方法。\n\n目前整合使用 tpws 進行 HTTP 和 TCP 上的 TLS。 它不繞過IP阻塞或中繼UDP，也不能保證Telegram的MTProto連線。 使用具有 TUN 的 VPN 伺服器進行 Discord 語音、Telegram 通話和此類限制。\n\n## 引擎\n\n＃＃＃ 汽車\n\nSora 選擇支援整個連線計畫的已安裝引擎：伺服器協定、傳輸、群組、分段和模式。 在停止目前連線之前，不相容的手動選擇將被拒絕。 選擇自動或其他引擎並再次套用設定。\n\n### sing-box\n\n新的 Sora 軟體包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，增加了客戶端 XHTTP Sora 認可此構建及其功能。 沒有 XHTTP 的上游版本無法僅從其名稱中獲得此功能。\n\n支援的協定包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可匯入的 AmneziaWG 1.x/2.x 參數。完整的 Xray JSON 設定需要 Xray。目前尚無法匯入新的 AWG 3.x 欄位。sing-box 使用受密碼保護的本機控制連接埠，電腦上的其他應用程式可以偵測到該連接埠。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支援 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它還運行完整的供應商 Xray 配置文件，同時保留其路由和群組。 此類設定檔無法在不改變其行為的情況下自動轉換為另一個引擎。\n\n捆綁的 Xray 刪除了停用 TLS 憑證驗證的設定（「allowInsecure」）。 對於需要此設定的普通伺服器，自動選擇sing-box或mihomo。 在停止目前連線之前選擇 Xray 手動報告不相容性。 較舊的完整 JSON 設定檔需要更新的提供者設定檔以及可驗證的憑證或憑證 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支援有序回退和負載平衡組 XHTTP 和 AmneziaWG。 當自動故障轉移到備份伺服器很重要時選擇它。 Sora 的 TLS 碎片設定在此引擎上不可用。\n\n## Sora 的兼容性\n\n|特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux TUN 和 TCP/UDP |是的 |是的 |是的 |\n| XHTTP |是的 |是的 |是的 |\n| VLESS Encryption |是的 |是的 |是的 |\n| Xray 完整簡介 |沒有 |是的 |沒有 |\n| TUIC / AnyTLS |兩者 |沒有 | TUIC |\n| TLS 碎片 |是的 |是的 |沒有 |\n| AmneziaWG 1.x/2.x |是的 1 |沒有 |是的 |\n|有順序後備組 |沒有 |沒有² |是的 |\n\n1 附 J1/J2/J3/Itime 的型材使用 mihomo；這些欄位絕不能被默默地丟棄。 ² 對於一組完整的 Xray 設定文件，應用程式會選擇一個備份設定檔。 支援取決於安裝的版本；在「關於」中檢查其版本。\n\n## TUN 堆疊\n\n此堆疊在虛擬介面內處理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每個引擎都會保存自己的首選項。 System 代理程式和無伺服器模式不使用此首選項。\n\n- **Mixed** — TCP 使用系統堆疊，而 gVisor 處理 UDP。 這是 Linux 上 mihomo 的預設值。在 Windows 上，Xray 和 mihomo 預設使用 MIPS。\n- **System** — 使用系統堆疊。 如果網頁應用程式遇到問題，請嘗試其他選項。\n- **gVisor** — 處理用戶空間中的流量。\n- **MIPS** — mihomo 自己的 IP 堆疊，在捆綁版本 1.19.32 中提供。\n\n在Linux上，Xray預設使用其內建的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作為 TUN 引擎，透過經過驗證的本機 SOCKS 連結將 TCP 和 UDP 轉送到 Xray。 Xray 保留協定、提供者設定檔和路由。 這三個選項需要安裝 mihomo。 在Windows 上，Xray 的四種 TUN 協定堆疊均使用 mihomo 1.19.32 或更新版本。協定與路由仍由 Xray 處理。此組合中的應用程式規則僅支援直連與封鎖；在 Linux 上，這些規則需要 Xray 內建的 gVisor。\n\n橋接器運行第二個進程。 在 Linux 上的三個空閒測量中，它比本機 Xray TUN 多使用了約 32-36 MiB 的實體記憶體。 這不會測量下載負載：CPU 和記憶體成本取決於連接。 sing-box沒有堆疊選擇器。 沒有任何堆疊可以保證每個網路都有更好的效能。 選擇一個堆疊並選擇“應用並重新連接”以在您的網路中進行嘗試。\n\n## 應用程式設定\n\n選擇伺服器會自動重新連線。 模式、引擎、DNS和規則設定立即儲存；在活動連線期間，按一下應用並重新連線即可使用它們。 重新啟動引擎可能會中斷下載和呼叫。 重複點擊不會啟動並行連接；斷開連接結束轉換並釋放連接。\n\n當隧道斷開時，僅透過 VPN 的 Internet 會阻止直接流量。 它影響整個機器。 明確斷開連線會刪除 Sora 的規則。 如果清理未完成，請重試斷開連線並開啟日誌。\n\n## 專案文檔\n\n- [sing-box-lx：設定與支援](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文件](https://sing-box.sagernet.org/)\n- [Xray 文件](https://xtls.github.io/)\n- [mihomo 文件](https://wiki.metacubex.one/)\n- [zapret：操作與限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '檢查伺服器';

  @override
  String get extensions => '擴充';

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
    return '儲存為 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 診斷';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => '尚未記錄請求。 首先打開一個速度測試網站。';

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
  String get qrScanHint => '選擇包含 QR 碼的截圖或相片，或貼上連結';

  @override
  String get qrFromClipboard => 'Paste from clipboard';

  @override
  String get qrNoCode => '此圖片中找不到 QR 碼。';

  @override
  String get qrInvalid => 'This QR code does not contain a valid link.';

  @override
  String get qrScan => 'Scan QR';

  @override
  String get qrFromImage => '開啟圖片';

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
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密碼，例如 chacha20-ietf-poly1305:password';
}
