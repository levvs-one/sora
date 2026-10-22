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
  String get connEmpty => '没有连接';

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
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#服务器，最快', one: '#服务器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

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
  String get programsEmpty => '没有找到应用程序。 尝试另一个名字。';

  @override
  String get selectExe => '选择一个 .exe 文件';

  @override
  String get speedtest => '速度';

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
  String get updateSignaturePending => '更新文件会与随版本发布的校验和比对。';

  @override
  String get updateManualSigWarning => '下面的文件与版本的校验和一致。如果是从官方版本下载的，请运行该命令。';

  @override
  String get updateVersionRevoked => '开发者已撤回此版本，请等待修复版。';

  @override
  String get updateRolloutPending => '新版本正分批推出，届时会自动通知您更新。';

  @override
  String updateRollbacking(String version) {
    return '正在回滚至版本 $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '更新至 $version 后未通过运行检查，Sora 已回滚至 $fromVersion。';
  }

  @override
  String get updateRollbackError => '自动回滚失败。若新版本无法运行，请手动重新安装先前的版本。';

  @override
  String get updateRollbackCacheError => '无法准备目前版本的已验证回滚副本，因此未安装更新。';

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
      '如果您不确定您的服务器需要哪个引擎，请选择自动。 Sora 在连接前检查配置文件和设置。 引擎无法增加计划的带宽：性能取决于服务器、路由、协议和网络。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 创建虚拟网络接口并通过它路由应用程序流量，包括 TCP 和 UDP。 Telegram、游戏和Discord语音使用此模式。 规则可以直接发送或阻止特定站点或程序。 网络服务需要权限和支持所需协议的服务器。\n\n### System 代理\n\nSora 配置本地 HTTP/SOCKS 代理。 尊重系统代理设置的应用程序使用它。 拥有自己的网络堆栈的应用程序可以直接连接； UDP和语音通话一般需要TUN。 此模式适合具有代理支持的浏览器和应用程序。\n\n### 没有服务器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 来拆分和重塑 HTTP/TLS 请求并绕过一些 DPI 检查。 您的 IP 保持不变，连接直接进入网站。 结果取决于您的提供商和阻止方法。\n\n当前集成使用 tpws 进行 HTTP 和 TCP 上的 TLS。 它不绕过IP阻塞或中继UDP，并且不能保证Telegram的MTProto连接。 使用具有 TUN 的 VPN 服务器进行 Discord 语音、Telegram 呼叫和此类限制。\n\n## 引擎\n\n＃＃＃ 汽车\n\nSora 选择支持整个连接计划的已安装引擎：服务器协议、传输、组、分段和模式。 在停止当前连接之前，不兼容的手动选择将被拒绝。 选择自动或其他引擎并再次应用设置。\n\n### sing-box\n\n新的 Sora 软件包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，添加了客户端 XHTTP 和 VLESS Encryption。 Sora 认可该构建及其功能。 没有 XHTTP 的上游版本无法仅从其名称中获得此功能。\n\n支持的协议包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可导入的 AmneziaWG 1.x/2.x 参数。完整的 Xray JSON 配置需要 Xray。目前尚不能导入新的 AWG 3.x 字段。sing-box 使用受密码保护的本地控制端口，计算机上的其他应用可以检测到该端口。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支持 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它还运行完整的提供商 Xray 配置文件，同时保留其路由和组。 此类配置文件无法在不改变其行为的情况下自动转换为另一个引擎。\n\n捆绑的 Xray 删除了禁用 TLS 证书验证的设置（“allowInsecure”）。 对于需要此设置的普通服务器，自动选择sing-box或mihomo。 在停止当前连接之前选择 Xray 手动报告不兼容性。 较旧的完整 JSON 配置文件需要更新的提供者配置文件以及可验证的证书或证书 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支持有序回退和负载均衡组 XHTTP 和 AmneziaWG。 当自动故障转移到备份服务器很重要时选择它。 Sora 的 TLS 碎片设置在此引擎上不可用。\n\n## Sora 的兼容性\n\n| 特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 和 TCP/UDP | 是的 | 是的 | 是的 |\n| XHTTP | 是的 | 是的 | 是的 |\n| VLESS Encryption | 是的 | 是的 | 是的 |\n| Xray 完整简介 | 没有 | 是的 | 没有 |\n| TUIC / AnyTLS | 两者 | 没有 | TUIC |\n| TLS 碎片 | 是的 | 是的 | 没有 |\n| AmneziaWG 1.x/2.x | 是的 1 | 没有 | 是的 |\n| 有序后备组 | 没有 | 没有² | 是的 |\n\n1 带 J1/J2/J3/Itime 的型材使用 mihomo； 这些字段绝不能被默默地丢弃。 ² 对于一组完整的 Xray 配置文件，应用程序会选择一个备份配置文件。 支持取决于安装的版本； 在“关于”中检查其版本。\n\n## TUN 堆栈\n\n该堆栈在虚拟接口内处理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每个引擎都会保存自己的首选项。 System 代理和无服务器模式不使用此首选项。\n\n- **Mixed**: TCP 使用系统堆栈，而 gVisor 处理 UDP。 这是 Linux 上 mihomo 的默认设置。在 Windows 上，Xray 和 mihomo 默认使用 MIPS。\n- **System**: 使用系统堆栈。 如果网络应用程序遇到问题，请尝试其他选项。\n- **gVisor**: 处理用户空间中的流量。\n- **MIPS**: mihomo 自己的 IP 堆栈，在捆绑版本 1.19.32 中提供。\n\n在Linux上，Xray默认使用其内置的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作为 TUN 引擎，通过经过身份验证的本地 SOCKS 链路将 TCP 和 UDP 转发到 Xray。 Xray 保留协议、提供商配置文件和路由。 这三个选项需要安装 mihomo。 在Windows 上，Xray 的四种 TUN 协议栈均使用 mihomo 1.19.32 或更高版本。协议和路由仍由 Xray 处理。此组合中的应用规则仅支持直连和阻断；在 Linux 上，这些规则需要 Xray 内置的 gVisor。\n\n桥接器运行第二个进程。 在 Linux 上的三个空闲测量中，它比本机 Xray TUN 多使用了约 32-36 MiB 的物理内存。 这不测量下载负载：CPU 和内存成本取决于连接。 sing-box没有堆栈选择器。 没有任何堆栈可以保证每个网络都有更好的性能。 选择一个堆栈并选择“应用并重新连接”以在您的网络中进行尝试。\n\n## 应用设置\n\n选择服务器会自动重新连接。 模式、引擎、DNS和规则设置立即保存； 在活动连接期间，单击应用并重新连接即可使用它们。 重新启动引擎可能会中断下载和调用。 重复点击不会启动并行连接； 断开连接结束转换并释放连接。\n\n当隧道断开时，仅通过 VPN 的 Internet 会阻止直接流量。 它影响整个机器。 显式断开连接会删除 Sora 的规则。 如果清理未完成，请重试断开连接并打开日志。\n\n## 项目文档\n\n- [sing-box-lx：配置和支持](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文档](https://sing-box.sagernet.org/)\n- [Xray 文档](https://xtls.github.io/)\n- [mihomo 文档](https://wiki.metacubex.one/)\n- [zapret：操作和限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '检查服务器';

  @override
  String get extensions => '扩展';

  @override
  String extRatingLabel(String rating) {
    return '评分 $rating，满分 5 分';
  }

  @override
  String extByAuthor(String author) {
    return '作者：$author';
  }

  @override
  String extInstallsCount(String count) {
    return '安装次数：$count';
  }

  @override
  String get extInstallOne => '1 次安装';

  @override
  String get extSideloadWarning => '仅在信任作者的自签名密钥时安装。';

  @override
  String get extPermissionsWidened => '此更新要求新的权限：';

  @override
  String get extDangerousAck => '我了解这些权限的影响范围很大';

  @override
  String get extInstall => '安装';

  @override
  String get extUpdate => '更新';

  @override
  String get extCancel => '取消';

  @override
  String get extConfirm => '确认';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => '目录';

  @override
  String get extInstalled => '已安装';

  @override
  String get extSearchHint => '搜寻扩展';

  @override
  String get extCatAll => '全部';

  @override
  String get extCatTools => '工具';

  @override
  String get extCatThemes => '主题';

  @override
  String get extCatAutomation => '自动化';

  @override
  String get extCatStats => '统计';

  @override
  String get extCatNetwork => '网络';

  @override
  String get extSortBy => '排序方式';

  @override
  String get extSortPopular => '最热门';

  @override
  String get extSortRating => '评分最高';

  @override
  String get extSortName => '名称';

  @override
  String get extCatalogError => '无法加载目录';

  @override
  String get extRetry => '重试';

  @override
  String get extEmptySearch => '找不到结果';

  @override
  String get extEmptyInstalled => '尚未安装扩展。\n请从目录中寻找，或从文件安装。';

  @override
  String get extInstallFromFile => '从文件安装';

  @override
  String get extInstallFromUrl => '从 URL 安装';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => '下载';

  @override
  String get extDownloading => '正在下载…';

  @override
  String get extVerifying => '正在验证…';

  @override
  String get extInstalling => '正在安装…';

  @override
  String get extInstallFailed => '安装失败';

  @override
  String get extErrSignature => '签名验证失败。文件可能已损毁或遭到窜改。';

  @override
  String get extErrManifest => '扩展的信息清单无效。';

  @override
  String get extErrNetwork => '网络错误，请检查连接后再试一次。';

  @override
  String get extErrHash => '下载的文件与目录不符，可能遭到窜改。';

  @override
  String extErrMinApp(String version) {
    return '此扩展需要应用程序 $version 或更新版本。';
  }

  @override
  String get extErrHttpsOnly => '仅允许 https:// 链接';

  @override
  String get extErrGeneric => '发生错误，请再试一次。';

  @override
  String get extErrAuthorKeyChanged => '此更新的作者签署密钥与已安装版本不同，因此已遭封锁。若您信任新密钥，请先卸载扩展，再自行重新安装。';

  @override
  String get extDisabled => '已停用';

  @override
  String extToggleEnabled(String name) {
    return '启用 $name';
  }

  @override
  String get extSearchInstalled => '搜寻已安装的扩展';

  @override
  String get extUpdateAll => '全部更新';

  @override
  String extUpdatesAvailable(int count) {
    return '有 $count 个可用更新';
  }

  @override
  String extUpdatedCount(int count) {
    return '已更新 $count 个';
  }

  @override
  String get extRiskNormal => '一般';

  @override
  String get extRiskSensitive => '敏感';

  @override
  String get extRiskDangerous => '高风险';

  @override
  String get extPermissionsRemoved => '不再要求：';

  @override
  String get extUpdateFailedKept => '已保留先前安装的版本。';

  @override
  String get extConflictsTitle => '扩展冲突';

  @override
  String get extConflictTheme => '应用主题';

  @override
  String get extConflictNetHooks => '网络拦截挂钩';

  @override
  String extConflictWinner(String name) {
    return '优先使用 $name';
  }

  @override
  String extConflictsCount(int count) {
    return '有 $count 个冲突需要您决定';
  }

  @override
  String get extConflictsResolve => '解决冲突';

  @override
  String extVersionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get extPermissionsTitle => '权限';

  @override
  String get extNoPermissions => '不需要特殊权限。';

  @override
  String get extSettings => '设置';

  @override
  String get extSaveSettings => '保存设置';

  @override
  String extUpdateTo(String version) {
    return '更新至 $version';
  }

  @override
  String get extEnabled => '已启用';

  @override
  String extRollbackTo(String version) {
    return '回滚至 $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return '要回滚至版本 $version 吗？';
  }

  @override
  String get extUninstall => '卸载';

  @override
  String extUninstallConfirm(String name) {
    return '要移除「$name」及其设置吗？';
  }

  @override
  String get extPanelUnavailable => '扩展面板不可用。';

  @override
  String get extPermConnectionsRead => '查看目前的连接清单';

  @override
  String get extPermServersRead => '查看您的服务器清单';

  @override
  String get extPermSettingsRead => '读取应用程序设置';

  @override
  String get extPermSettingsWrite => '变更应用程序设置';

  @override
  String get extPermNotifications => '显示通知';

  @override
  String get extPermTray => '添加系统托盘菜单项';

  @override
  String get extPermUiPanel => '在应用程序中显示面板';

  @override
  String get extPermThemeApply => '应用应用程序主题';

  @override
  String get extPermRoutingRules => '添加路由规则（影响流量去向）';

  @override
  String get extPermNetHooks => '介入网络传输路径（DPI 绕过模块）';

  @override
  String get extPermNetFetch => '访问允许清单中的 URL';

  @override
  String get extPermBackground => '执行后台任务';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => '在后台执行';

  @override
  String get extCapNetHook => '绕过机制与网络挂钩';

  @override
  String get extCapPanel => '面板';

  @override
  String get extCapRouting => '路由规则';

  @override
  String get extCapTheme => '主题';

  @override
  String get extCapWidget => '小组件';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => '版本记录';

  @override
  String get extImageFailed => '无法加载图片';

  @override
  String get extScreenshots => '截图';

  @override
  String get extSortRelevance => '相关性';

  @override
  String get extPermNetworkDetail => 'VPN 请求仅限访问以下主机。';

  @override
  String get extBgTitle => '后台任务';

  @override
  String get extBgEnabled => '在后台执行';

  @override
  String get extBgInterval => '执行间隔';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 分钟');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 小时');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => '请先启用扩展，才能管理后台任务。';

  @override
  String get extCapNetwork => '网络访问';

  @override
  String extCapNetworkHosts(String hosts) {
    return '网络：$hosts';
  }

  @override
  String exportLogFile(String name) {
    return '保存为 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 诊断';

  @override
  String get diagnosticNoData => '尚未记录请求。 首先打开一个速度测试网站。';

  @override
  String get qrShareTitle => '透过 QR 分享';

  @override
  String get qrScanTitle => '扫描 QR 码';

  @override
  String get qrCopyLink => '复制链接';

  @override
  String get qrShowLink => '显示链接';

  @override
  String get qrHideLink => '隐藏链接';

  @override
  String get qrWarning => '此 QR 码含有连接信息，请勿向陌生人展示。';

  @override
  String get qrScanHint => '选择包含二维码的截图或照片，或粘贴链接';

  @override
  String get qrFromClipboard => '从剪贴板粘贴';

  @override
  String get qrNoCode => '此图片中未找到二维码。';

  @override
  String get qrInvalid => '此 QR 码不含有效链接。';

  @override
  String get qrScan => '扫描 QR';

  @override
  String get qrFromImage => '打开图片';

  @override
  String get connGroupByProcess => '依进程分组';

  @override
  String get connListView => '列表视图';

  @override
  String get connCopyHost => '复制主机名称';

  @override
  String get connAddRule => '添加规则';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 个连接');
    return '$_temp0';
  }

  @override
  String get dnsPreset => '预设';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => '自订';

  @override
  String get dnsCheck => '检查泄漏';

  @override
  String get dnsChecking => '正在检查...';

  @override
  String get dnsNoLeak => '未发现泄漏';

  @override
  String get dnsLeakFound => '检测到泄漏';

  @override
  String get dnsLastCheck => '上次检查';

  @override
  String get dnsNeverChecked => '尚未检查';

  @override
  String get dnsLeakCheckTunnelDns => '隧道 DNS 解析器';

  @override
  String get dnsLeakCheckSystemResolvers => '系统解析器';

  @override
  String get dnsLeakCheckKillSwitchDns => '网络锁定的 DNS 保护';

  @override
  String get dnsLeakFixConfigureTunnelDns => '请在上方的 DNS 设置中指定隧道 DNS。';

  @override
  String get dnsLeakFixReviewSystemResolvers => '检查系统在隧道外会使用哪些解析器。';

  @override
  String get dnsLeakFixEnableKillSwitch => '请启用网络锁定，让 DNS 流量保持在隧道内。';

  @override
  String get dnsLeakCheckEncryptedDns => '操作系统加密 DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS 响应伪造';

  @override
  String get dnsLeakFixReviewEncryptedDns => '检查系统在隧道外使用的加密 DNS 端点。';

  @override
  String get dnsLeakFixUseEncryptedDns => '请为隧道使用加密 DNS（DoT 或 DoH），避免解析器伪造响应。';

  @override
  String get dnsCheckNeedsConnection => '请先连接 VPN，再检查是否泄漏。';

  @override
  String get dnsExpected => '预期';

  @override
  String get dnsActual => '实际';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortPing => '延迟';

  @override
  String get sortSpeed => '速度';

  @override
  String get sortName => '名称';

  @override
  String get measureSpeed => '测量速度';

  @override
  String get benchmarkStale => '已过时';

  @override
  String get autoSelectMode => '自动选择服务器';

  @override
  String get autoSelectPing => '最低延迟';

  @override
  String get autoSelectSpeed => '最高速度';

  @override
  String get autoSelectSmart => '智能选择';

  @override
  String get coreWatchUnstable => '与核心的连接不稳定';

  @override
  String get watchReconnect => '重新连接';

  @override
  String get coreRestoringLink => '正在恢复与核心的连接…';

  @override
  String get crashRestoreTitle => '上次会话意外中断';

  @override
  String get restoreOnCrash => '崩溃后恢复会话';

  @override
  String get crashRestore => '恢复';

  @override
  String get crashDismiss => '暂不';

  @override
  String get overrideTitle => '我的修改';

  @override
  String get overrideEdit => '编辑服务器';

  @override
  String get overrideHide => '隐藏';

  @override
  String get overrideUnhide => '显示';

  @override
  String get overrideClear => '清除修改';

  @override
  String get overrideEmpty => '尚无修改';

  @override
  String get overrideCustomRules => '自订规则';

  @override
  String get errBenchmarkUnsupported => '测速需要更新版本的核心';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '正在测量 $done/$total…';
  }

  @override
  String get profiles => '网络配置文件';

  @override
  String get profilesEmpty => '尚无配置文件。建立后，即可在已知网络中自动应用设置。';

  @override
  String get profileAdd => '添加配置文件';

  @override
  String get profileName => '配置文件名称';

  @override
  String get profileSsids => 'Wi-Fi 网络（SSID）';

  @override
  String get profileSsidsHint => '家庭、办公室，以逗号分隔';

  @override
  String get profileGateways => '网关';

  @override
  String get profileAsns => 'AS 编号';

  @override
  String get profileAutoApply => '自动应用';

  @override
  String get profileAutoApplyHint => '关闭时，应用配置文件前会要求确认。';

  @override
  String get profileSnapshot => '记住当前设置';

  @override
  String get profileSnapshotDone => '当前设置已保存至配置文件';

  @override
  String get profileDelete => '删除配置文件';

  @override
  String profileDeleteConfirm(Object name) {
    return '要删除配置文件「$name」吗？';
  }

  @override
  String profileApplyAsk(Object name) {
    return '要应用配置文件「$name」吗？';
  }

  @override
  String get profileApply => '应用';

  @override
  String profileApplied(Object name) {
    return '已应用配置文件「$name」';
  }

  @override
  String get profileUndo => '撤销';

  @override
  String get profileActive => '使用中';

  @override
  String networkNow(Object info) {
    return '目前：$info';
  }

  @override
  String get networkUnknown => '无法取得网络信息';

  @override
  String get profileNoTriggers => '请至少添加一个触发条件：SSID、网关或 ASN';

  @override
  String get chains => '代理链';

  @override
  String get chainsEmpty => '尚无代理链。串接 2 至 3 台服务器，让流量依序通过每台服务器。';

  @override
  String get chainAdd => '添加代理链';

  @override
  String get chainName => '代理链名称';

  @override
  String get chainPickServers => '选择 2 至 3 台服务器';

  @override
  String get chainOrderHint => '拖动以调整顺序：流量从上方进入，从下方离开。';

  @override
  String get chainTooFew => '请至少选择 2 台服务器';

  @override
  String get chainTooMany => '代理链最多包含 3 台服务器';

  @override
  String get chainEstimate => '预估延迟';

  @override
  String get chainSave => '保存代理链';

  @override
  String get chainDelete => '删除代理链';

  @override
  String chainDeleteConfirm(Object name) {
    return '要删除代理链「$name」吗？';
  }

  @override
  String get chainUnsupported => '目前的引擎无法建立代理链';

  @override
  String get chainHopMissing => '代理链中的一台服务器已无法使用';

  @override
  String chainHop(Object n) {
    return '第 $n 跳';
  }

  @override
  String get chainEntry => '入口';

  @override
  String get chainExit => '出口';

  @override
  String get sync => '设备同步';

  @override
  String get syncDevices => '我的设备';

  @override
  String get syncEmpty => '尚无配对的设备。请透过局域网与另一台设备配对。';

  @override
  String get syncPair => '配对设备';

  @override
  String get syncShowCode => '显示我的代码';

  @override
  String get syncScanCode => '扫描代码';

  @override
  String get syncRevoke => '撤销';

  @override
  String syncRevokeConfirm(Object name) {
    return '要撤销「$name」吗？';
  }

  @override
  String syncLastSync(Object time) {
    return '上次同步：$time';
  }

  @override
  String get syncNever => '从未';

  @override
  String get syncNoLan => '设备必须位于同一个局域网';

  @override
  String get syncPaired => '设备已配对';

  @override
  String get syncPairingTitle => '与此设备配对';

  @override
  String get syncWaiting => '正在等待另一台设备…';

  @override
  String get syncSecureNote => '通道采用端到端加密，无需账号或云服务器。';

  @override
  String get zapretWithVpn => '直接连接流量的 DPI 绕过';

  @override
  String get zapretWithVpnHint => '与 VPN 隧道并行执行 zapret：隧道流量使用 VPN，直接连接流量则透过绕过机制。';

  @override
  String get chainDuplicate => '每台服务器只能选择一次';

  @override
  String get edit => '编辑';

  @override
  String get remove => '移除';

  @override
  String get autoSwitchOnDegrade => '质量下降时自动切换';

  @override
  String get autoSwitchOnDegradeDetail => '若所选服务器大幅变慢或停止回应，Sora 会切换至测量结果最佳的服务器，最多每 10 分钟切换一次。';

  @override
  String get tunStackMixed => '混合';

  @override
  String get tunStackSystem => '系统';

  @override
  String get customServerAdd => '添加自订服务器';

  @override
  String get customServers => '我的服务器';

  @override
  String get customServerName => '名称';

  @override
  String get customServerNameHint => '例如：我的 VPS';

  @override
  String get customServerNameRequired => '请输入名称';

  @override
  String get customServerAddress => '地址';

  @override
  String get customServerAddressHint => 'example.com 或 192.0.2.1';

  @override
  String get customServerAddressRequired => '请输入服务器地址';

  @override
  String get customServerAddressInvalid => '地址无效';

  @override
  String get customServerPort => '端口';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => '端口必须是 1 到 65535 之间的数字';

  @override
  String get customServerProtocol => '协议';

  @override
  String get customServerCredentials => '登录信息';

  @override
  String get customServerOptional => '可选';

  @override
  String get customServerShowSecret => '显示密钥';

  @override
  String get customServerHideSecret => '隐藏密钥';

  @override
  String get customServerBadge => '自订';

  @override
  String customServerDeleteConfirm(String name) {
    return '要删除服务器「$name」吗？';
  }

  @override
  String get customServerEmptyHint => '手动添加服务器：地址、端口和协议';

  @override
  String get customServerTest => '测试';

  @override
  String get leakTestTitle => '泄漏测试';

  @override
  String get leakTestIntro => '检查流量能否不经隧道离开设备：包括直接 DNS 和 ICMP 请求、IPv6 对外流量以及系统解析器。请在连接时执行。';

  @override
  String get leakTestRun => '执行测试';

  @override
  String get leakTestCancel => '取消';

  @override
  String get leakTestNeedsConnection => '请先连接，再执行泄漏测试。';

  @override
  String leakTestProgress(int count) {
    return '已完成测试：$count';
  }

  @override
  String get leakTestAllClear => '未发现泄漏';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '发现 # 处泄漏');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => '修复';

  @override
  String get leakTestFixedNote => '已启用网络锁定，请重新测试以确认。';

  @override
  String get leakTestCheckDirectDns => '直接 DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP 回显';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => '系统解析器';

  @override
  String get leakTestCheckTunnelConnectivity => '隧道连接状态';

  @override
  String get leakTestCheckTunnelDns => '隧道 DNS';

  @override
  String get noticeDegraded => '服务器变慢，已切换至测量结果最佳的服务器';

  @override
  String get obfs => '流量混淆';

  @override
  String get syncCodeExpired => '代码已到期';

  @override
  String get syncDaemonFailed => '无法启动同步服务';

  @override
  String get syncDaemonMissing => '找不到 sora-sync 元件。请重新安装应用程序以启用设备同步。';

  @override
  String get syncDaemonStarting => '正在启动同步服务…';

  @override
  String get syncErrAuth => '同步服务拒绝了访问令牌。请重新启动应用程序后再试一次。';

  @override
  String get syncErrNotFound => '此设备已解除配对';

  @override
  String get syncErrPairingActive => '已有进行中的配对会话';

  @override
  String get syncErrUnreachable => '另一台设备没有回应。请确认设备位于同一个网络，且正在显示配对代码。';

  @override
  String get syncError => '同步错误';

  @override
  String syncExpiresIn(String duration) {
    return '代码将在 $duration 后到期';
  }

  @override
  String get syncJoining => '正在与设备配对…';

  @override
  String get syncLegacyCleared => '旧设备清单未曾完成实际配对，因此已清除。请重新配对设备，这次会真正建立配对。';

  @override
  String get syncNewCode => '新代码';

  @override
  String syncPairedWith(String name) {
    return '已与 $name 配对';
  }

  @override
  String get syncRetry => '重试';

  @override
  String get syncStopShowing => '隐藏代码';

  @override
  String get syncSyncNow => '立即同步';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '已接收 $pulled，已发送 $pushed';
  }

  @override
  String get syncResultTitle => '同步结果';

  @override
  String get syncPulled => '已接收';

  @override
  String get syncPushed => '已发送';

  @override
  String get syncNoChanges => '没有更改';

  @override
  String get syncDocKindSubscriptions => '订阅';

  @override
  String get syncDocKindSettings => '应用程序设置';

  @override
  String get syncDocKindOverrides => '订阅覆盖设置';

  @override
  String get syncDocKindProfiles => '网络配置文件';

  @override
  String get syncDocKindChains => '代理链';

  @override
  String syncFrom(String name) {
    return '来自 $name';
  }

  @override
  String get syncThisDevice => '此设备';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密码，例如 chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => '抓包';

  @override
  String get diagnosticEvents => 'Windows 事件';

  @override
  String get diagnosticCapture => '捕捉10秒';

  @override
  String get diagnosticRequiresTun => '数据包捕获需要活动的 Sora TUN 连接。';

  @override
  String get diagnosticUnavailable => '此诊断在此平台上不可用。';

  @override
  String get extErrRevoked => 'Sora 团队已撤回此扩展版本，因为它不安全或已损坏。';

  @override
  String get extErrRevocationsExpired => '撤销列表更新前无法安装扩展。';

  @override
  String extRevokedDisabled(String names) {
    return '已关闭被撤回的扩展：$names';
  }

  @override
  String get customServerWgPrivateKey => '私钥';

  @override
  String get customServerWgAddresses => '接口地址';

  @override
  String get customServerWgPeerKey => '服务器公钥';

  @override
  String get customServerWgPresharedKey => '预共享密钥';

  @override
  String get customServerWgAllowedIps => '允许的 IP';

  @override
  String get customServerWgKeepalive => 'Keepalive（秒）';

  @override
  String get customServerWgKeyInvalid => '密钥必须是 base64 编码的 32 字节，与 wg genkey 的输出相同。';

  @override
  String get customServerWgCidrInvalid => '请输入以逗号分隔的前缀，例如 10.0.0.2/32。';

  @override
  String get customServerWgKeepaliveInvalid => '请输入 0 到 65535 之间的秒数。';

  @override
  String get strictKillSwitch => '严格网络锁定';

  @override
  String get strictKillSwitchWarning => '连接后，即使崩溃、重启或退出应用，也会阻止 VPN 之外的流量。只有断开连接或关闭此选项才会恢复访问。设备重启后，仅在启用启动时连接时恢复阻止。';

  @override
  String get extWorkerFailed => '扩展的后台任务失败。请查看扩展日志。';

  @override
  String get extAssetRejected => '扩展文件被拒绝：颜色难以辨认或规则无效。';

  @override
  String get extVerifiedSora => '经 Sora 验证';

  @override
  String extReceivedBytes(String count) {
    return '$count 字节';
  }

  @override
  String get extOpen => '打开';
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
  String get connEmpty => '没有连接';

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
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#服务器，最快', one: '#服务器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

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
  String get programsEmpty => '没有找到应用程序。 尝试另一个名字。';

  @override
  String get selectExe => '选择一个 .exe 文件';

  @override
  String get speedtest => '速度';

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
  String get updateSignaturePending => '更新文件会与随版本发布的校验和比对。';

  @override
  String get updateManualSigWarning => '下面的文件与版本的校验和一致。如果是从官方版本下载的，请运行该命令。';

  @override
  String get updateVersionRevoked => '开发者已撤回此版本，请等待修复版。';

  @override
  String get updateRolloutPending => '新版本正分批推出，届时会自动通知您更新。';

  @override
  String updateRollbacking(String version) {
    return '正在回滚至版本 $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '更新至 $version 后未通过运行检查，Sora 已回滚至 $fromVersion。';
  }

  @override
  String get updateRollbackError => '自动回滚失败。若新版本无法运行，请手动重新安装先前的版本。';

  @override
  String get updateRollbackCacheError => '无法准备目前版本的已验证回滚副本，因此未安装更新。';

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
      '如果您不确定您的服务器需要哪个引擎，请选择自动。 Sora 在连接前检查配置文件和设置。 引擎无法增加计划的带宽：性能取决于服务器、路由、协议和网络。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 创建虚拟网络接口并通过它路由应用程序流量，包括 TCP 和 UDP。 Telegram、游戏和Discord语音使用此模式。 规则可以直接发送或阻止特定站点或程序。 网络服务需要权限和支持所需协议的服务器。\n\n### System 代理\n\nSora 配置本地 HTTP/SOCKS 代理。 尊重系统代理设置的应用程序使用它。 拥有自己的网络堆栈的应用程序可以直接连接； UDP和语音通话一般需要TUN。 此模式适合具有代理支持的浏览器和应用程序。\n\n### 没有服务器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 来拆分和重塑 HTTP/TLS 请求并绕过一些 DPI 检查。 您的 IP 保持不变，连接直接进入网站。 结果取决于您的提供商和阻止方法。\n\n当前集成使用 tpws 进行 HTTP 和 TCP 上的 TLS。 它不绕过IP阻塞或中继UDP，并且不能保证Telegram的MTProto连接。 使用具有 TUN 的 VPN 服务器进行 Discord 语音、Telegram 呼叫和此类限制。\n\n## 引擎\n\n＃＃＃ 汽车\n\nSora 选择支持整个连接计划的已安装引擎：服务器协议、传输、组、分段和模式。 在停止当前连接之前，不兼容的手动选择将被拒绝。 选择自动或其他引擎并再次应用设置。\n\n### sing-box\n\n新的 Sora 软件包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，添加了客户端 XHTTP 和 VLESS Encryption。 Sora 认可该构建及其功能。 没有 XHTTP 的上游版本无法仅从其名称中获得此功能。\n\n支持的协议包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可导入的 AmneziaWG 1.x/2.x 参数。完整的 Xray JSON 配置需要 Xray。目前尚不能导入新的 AWG 3.x 字段。sing-box 使用受密码保护的本地控制端口，计算机上的其他应用可以检测到该端口。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支持 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它还运行完整的提供商 Xray 配置文件，同时保留其路由和组。 此类配置文件无法在不改变其行为的情况下自动转换为另一个引擎。\n\n捆绑的 Xray 删除了禁用 TLS 证书验证的设置（“allowInsecure”）。 对于需要此设置的普通服务器，自动选择sing-box或mihomo。 在停止当前连接之前选择 Xray 手动报告不兼容性。 较旧的完整 JSON 配置文件需要更新的提供者配置文件以及可验证的证书或证书 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支持有序回退和负载均衡组 XHTTP 和 AmneziaWG。 当自动故障转移到备份服务器很重要时选择它。 Sora 的 TLS 碎片设置在此引擎上不可用。\n\n## Sora 的兼容性\n\n| 特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 和 TCP/UDP | 是的 | 是的 | 是的 |\n| XHTTP | 是的 | 是的 | 是的 |\n| VLESS Encryption | 是的 | 是的 | 是的 |\n| Xray 完整简介 | 没有 | 是的 | 没有 |\n| TUIC / AnyTLS | 两者 | 没有 | TUIC |\n| TLS 碎片 | 是的 | 是的 | 没有 |\n| AmneziaWG 1.x/2.x | 是的 1 | 没有 | 是的 |\n| 有序后备组 | 没有 | 没有² | 是的 |\n\n1 带 J1/J2/J3/Itime 的型材使用 mihomo； 这些字段绝不能被默默地丢弃。 ² 对于一组完整的 Xray 配置文件，应用程序会选择一个备份配置文件。 支持取决于安装的版本； 在“关于”中检查其版本。\n\n## TUN 堆栈\n\n该堆栈在虚拟接口内处理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每个引擎都会保存自己的首选项。 System 代理和无服务器模式不使用此首选项。\n\n- **Mixed**: TCP 使用系统堆栈，而 gVisor 处理 UDP。 这是 Linux 上 mihomo 的默认设置。在 Windows 上，Xray 和 mihomo 默认使用 MIPS。\n- **System**: 使用系统堆栈。 如果网络应用程序遇到问题，请尝试其他选项。\n- **gVisor**: 处理用户空间中的流量。\n- **MIPS**: mihomo 自己的 IP 堆栈，在捆绑版本 1.19.32 中提供。\n\n在Linux上，Xray默认使用其内置的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作为 TUN 引擎，通过经过身份验证的本地 SOCKS 链路将 TCP 和 UDP 转发到 Xray。 Xray 保留协议、提供商配置文件和路由。 这三个选项需要安装 mihomo。 在Windows 上，Xray 的四种 TUN 协议栈均使用 mihomo 1.19.32 或更高版本。协议和路由仍由 Xray 处理。此组合中的应用规则仅支持直连和阻断；在 Linux 上，这些规则需要 Xray 内置的 gVisor。\n\n桥接器运行第二个进程。 在 Linux 上的三个空闲测量中，它比本机 Xray TUN 多使用了约 32-36 MiB 的物理内存。 这不测量下载负载：CPU 和内存成本取决于连接。 sing-box没有堆栈选择器。 没有任何堆栈可以保证每个网络都有更好的性能。 选择一个堆栈并选择“应用并重新连接”以在您的网络中进行尝试。\n\n## 应用设置\n\n选择服务器会自动重新连接。 模式、引擎、DNS和规则设置立即保存； 在活动连接期间，单击应用并重新连接即可使用它们。 重新启动引擎可能会中断下载和调用。 重复点击不会启动并行连接； 断开连接结束转换并释放连接。\n\n当隧道断开时，仅通过 VPN 的 Internet 会阻止直接流量。 它影响整个机器。 显式断开连接会删除 Sora 的规则。 如果清理未完成，请重试断开连接并打开日志。\n\n## 项目文档\n\n- [sing-box-lx：配置和支持](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文档](https://sing-box.sagernet.org/)\n- [Xray 文档](https://xtls.github.io/)\n- [mihomo 文档](https://wiki.metacubex.one/)\n- [zapret：操作和限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '检查服务器';

  @override
  String get extensions => '扩展';

  @override
  String extRatingLabel(String rating) {
    return '评分 $rating，满分 5 分';
  }

  @override
  String extByAuthor(String author) {
    return '作者：$author';
  }

  @override
  String extInstallsCount(String count) {
    return '安装次数：$count';
  }

  @override
  String get extInstallOne => '1 次安装';

  @override
  String get extSideloadWarning => '仅在信任作者的自签名密钥时安装。';

  @override
  String get extPermissionsWidened => '此更新要求新的权限：';

  @override
  String get extDangerousAck => '我了解这些权限的影响范围很大';

  @override
  String get extInstall => '安装';

  @override
  String get extUpdate => '更新';

  @override
  String get extCancel => '取消';

  @override
  String get extConfirm => '确认';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => '目录';

  @override
  String get extInstalled => '已安装';

  @override
  String get extSearchHint => '搜寻扩展';

  @override
  String get extCatAll => '全部';

  @override
  String get extCatTools => '工具';

  @override
  String get extCatThemes => '主题';

  @override
  String get extCatAutomation => '自动化';

  @override
  String get extCatStats => '统计';

  @override
  String get extCatNetwork => '网络';

  @override
  String get extSortBy => '排序方式';

  @override
  String get extSortPopular => '最热门';

  @override
  String get extSortRating => '评分最高';

  @override
  String get extSortName => '名称';

  @override
  String get extCatalogError => '无法加载目录';

  @override
  String get extRetry => '重试';

  @override
  String get extEmptySearch => '找不到结果';

  @override
  String get extEmptyInstalled => '尚未安装扩展。\n请从目录中寻找，或从文件安装。';

  @override
  String get extInstallFromFile => '从文件安装';

  @override
  String get extInstallFromUrl => '从 URL 安装';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => '下载';

  @override
  String get extDownloading => '正在下载…';

  @override
  String get extVerifying => '正在验证…';

  @override
  String get extInstalling => '正在安装…';

  @override
  String get extInstallFailed => '安装失败';

  @override
  String get extErrSignature => '签名验证失败。文件可能已损毁或遭到窜改。';

  @override
  String get extErrManifest => '扩展的信息清单无效。';

  @override
  String get extErrNetwork => '网络错误，请检查连接后再试一次。';

  @override
  String get extErrHash => '下载的文件与目录不符，可能遭到窜改。';

  @override
  String extErrMinApp(String version) {
    return '此扩展需要应用程序 $version 或更新版本。';
  }

  @override
  String get extErrHttpsOnly => '仅允许 https:// 链接';

  @override
  String get extErrGeneric => '发生错误，请再试一次。';

  @override
  String get extErrAuthorKeyChanged => '此更新的作者签署密钥与已安装版本不同，因此已遭封锁。若您信任新密钥，请先卸载扩展，再自行重新安装。';

  @override
  String get extDisabled => '已停用';

  @override
  String extToggleEnabled(String name) {
    return '启用 $name';
  }

  @override
  String get extSearchInstalled => '搜寻已安装的扩展';

  @override
  String get extUpdateAll => '全部更新';

  @override
  String extUpdatesAvailable(int count) {
    return '有 $count 个可用更新';
  }

  @override
  String extUpdatedCount(int count) {
    return '已更新 $count 个';
  }

  @override
  String get extRiskNormal => '一般';

  @override
  String get extRiskSensitive => '敏感';

  @override
  String get extRiskDangerous => '高风险';

  @override
  String get extPermissionsRemoved => '不再要求：';

  @override
  String get extUpdateFailedKept => '已保留先前安装的版本。';

  @override
  String get extConflictsTitle => '扩展冲突';

  @override
  String get extConflictTheme => '应用主题';

  @override
  String get extConflictNetHooks => '网络拦截挂钩';

  @override
  String extConflictWinner(String name) {
    return '优先使用 $name';
  }

  @override
  String extConflictsCount(int count) {
    return '有 $count 个冲突需要您决定';
  }

  @override
  String get extConflictsResolve => '解决冲突';

  @override
  String extVersionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get extPermissionsTitle => '权限';

  @override
  String get extNoPermissions => '不需要特殊权限。';

  @override
  String get extSettings => '设置';

  @override
  String get extSaveSettings => '保存设置';

  @override
  String extUpdateTo(String version) {
    return '更新至 $version';
  }

  @override
  String get extEnabled => '已启用';

  @override
  String extRollbackTo(String version) {
    return '回滚至 $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return '要回滚至版本 $version 吗？';
  }

  @override
  String get extUninstall => '卸载';

  @override
  String extUninstallConfirm(String name) {
    return '要移除「$name」及其设置吗？';
  }

  @override
  String get extPanelUnavailable => '扩展面板不可用。';

  @override
  String get extPermConnectionsRead => '查看目前的连接清单';

  @override
  String get extPermServersRead => '查看您的服务器清单';

  @override
  String get extPermSettingsRead => '读取应用程序设置';

  @override
  String get extPermSettingsWrite => '变更应用程序设置';

  @override
  String get extPermNotifications => '显示通知';

  @override
  String get extPermTray => '添加系统托盘菜单项';

  @override
  String get extPermUiPanel => '在应用程序中显示面板';

  @override
  String get extPermThemeApply => '应用应用程序主题';

  @override
  String get extPermRoutingRules => '添加路由规则（影响流量去向）';

  @override
  String get extPermNetHooks => '介入网络传输路径（DPI 绕过模块）';

  @override
  String get extPermNetFetch => '访问允许清单中的 URL';

  @override
  String get extPermBackground => '执行后台任务';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => '在后台执行';

  @override
  String get extCapNetHook => '绕过机制与网络挂钩';

  @override
  String get extCapPanel => '面板';

  @override
  String get extCapRouting => '路由规则';

  @override
  String get extCapTheme => '主题';

  @override
  String get extCapWidget => '小组件';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => '版本记录';

  @override
  String get extImageFailed => '无法加载图片';

  @override
  String get extScreenshots => '截图';

  @override
  String get extSortRelevance => '相关性';

  @override
  String get extPermNetworkDetail => 'VPN 请求仅限访问以下主机。';

  @override
  String get extBgTitle => '后台任务';

  @override
  String get extBgEnabled => '在后台执行';

  @override
  String get extBgInterval => '执行间隔';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 分钟');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 小时');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => '请先启用扩展，才能管理后台任务。';

  @override
  String get extCapNetwork => '网络访问';

  @override
  String extCapNetworkHosts(String hosts) {
    return '网络：$hosts';
  }

  @override
  String exportLogFile(String name) {
    return '保存为 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 诊断';

  @override
  String get diagnosticNoData => '尚未记录请求。 首先打开一个速度测试网站。';

  @override
  String get qrShareTitle => '透过 QR 分享';

  @override
  String get qrScanTitle => '扫描 QR 码';

  @override
  String get qrCopyLink => '复制链接';

  @override
  String get qrShowLink => '显示链接';

  @override
  String get qrHideLink => '隐藏链接';

  @override
  String get qrWarning => '此 QR 码含有连接信息，请勿向陌生人展示。';

  @override
  String get qrScanHint => '选择包含二维码的截图或照片，或粘贴链接';

  @override
  String get qrFromClipboard => '从剪贴板粘贴';

  @override
  String get qrNoCode => '此图片中未找到二维码。';

  @override
  String get qrInvalid => '此 QR 码不含有效链接。';

  @override
  String get qrScan => '扫描 QR';

  @override
  String get qrFromImage => '打开图片';

  @override
  String get connGroupByProcess => '依进程分组';

  @override
  String get connListView => '列表视图';

  @override
  String get connCopyHost => '复制主机名称';

  @override
  String get connAddRule => '添加规则';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 个连接');
    return '$_temp0';
  }

  @override
  String get dnsPreset => '预设';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => '自订';

  @override
  String get dnsCheck => '检查泄漏';

  @override
  String get dnsChecking => '正在检查...';

  @override
  String get dnsNoLeak => '未发现泄漏';

  @override
  String get dnsLeakFound => '检测到泄漏';

  @override
  String get dnsLastCheck => '上次检查';

  @override
  String get dnsNeverChecked => '尚未检查';

  @override
  String get dnsLeakCheckTunnelDns => '隧道 DNS 解析器';

  @override
  String get dnsLeakCheckSystemResolvers => '系统解析器';

  @override
  String get dnsLeakCheckKillSwitchDns => '网络锁定的 DNS 保护';

  @override
  String get dnsLeakFixConfigureTunnelDns => '请在上方的 DNS 设置中指定隧道 DNS。';

  @override
  String get dnsLeakFixReviewSystemResolvers => '检查系统在隧道外会使用哪些解析器。';

  @override
  String get dnsLeakFixEnableKillSwitch => '请启用网络锁定，让 DNS 流量保持在隧道内。';

  @override
  String get dnsLeakCheckEncryptedDns => '操作系统加密 DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS 响应伪造';

  @override
  String get dnsLeakFixReviewEncryptedDns => '检查系统在隧道外使用的加密 DNS 端点。';

  @override
  String get dnsLeakFixUseEncryptedDns => '请为隧道使用加密 DNS（DoT 或 DoH），避免解析器伪造响应。';

  @override
  String get dnsCheckNeedsConnection => '请先连接 VPN，再检查是否泄漏。';

  @override
  String get dnsExpected => '预期';

  @override
  String get dnsActual => '实际';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortPing => '延迟';

  @override
  String get sortSpeed => '速度';

  @override
  String get sortName => '名称';

  @override
  String get measureSpeed => '测量速度';

  @override
  String get benchmarkStale => '已过时';

  @override
  String get autoSelectMode => '自动选择服务器';

  @override
  String get autoSelectPing => '最低延迟';

  @override
  String get autoSelectSpeed => '最高速度';

  @override
  String get autoSelectSmart => '智能选择';

  @override
  String get coreWatchUnstable => '与核心的连接不稳定';

  @override
  String get watchReconnect => '重新连接';

  @override
  String get coreRestoringLink => '正在恢复与核心的连接…';

  @override
  String get crashRestoreTitle => '上次会话意外中断';

  @override
  String get restoreOnCrash => '崩溃后恢复会话';

  @override
  String get crashRestore => '恢复';

  @override
  String get crashDismiss => '暂不';

  @override
  String get overrideTitle => '我的修改';

  @override
  String get overrideEdit => '编辑服务器';

  @override
  String get overrideHide => '隐藏';

  @override
  String get overrideUnhide => '显示';

  @override
  String get overrideClear => '清除修改';

  @override
  String get overrideEmpty => '尚无修改';

  @override
  String get overrideCustomRules => '自订规则';

  @override
  String get errBenchmarkUnsupported => '测速需要更新版本的核心';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '正在测量 $done/$total…';
  }

  @override
  String get profiles => '网络配置文件';

  @override
  String get profilesEmpty => '尚无配置文件。建立后，即可在已知网络中自动应用设置。';

  @override
  String get profileAdd => '添加配置文件';

  @override
  String get profileName => '配置文件名称';

  @override
  String get profileSsids => 'Wi-Fi 网络（SSID）';

  @override
  String get profileSsidsHint => '家庭、办公室，以逗号分隔';

  @override
  String get profileGateways => '网关';

  @override
  String get profileAsns => 'AS 编号';

  @override
  String get profileAutoApply => '自动应用';

  @override
  String get profileAutoApplyHint => '关闭时，应用配置文件前会要求确认。';

  @override
  String get profileSnapshot => '记住当前设置';

  @override
  String get profileSnapshotDone => '当前设置已保存至配置文件';

  @override
  String get profileDelete => '删除配置文件';

  @override
  String profileDeleteConfirm(Object name) {
    return '要删除配置文件「$name」吗？';
  }

  @override
  String profileApplyAsk(Object name) {
    return '要应用配置文件「$name」吗？';
  }

  @override
  String get profileApply => '应用';

  @override
  String profileApplied(Object name) {
    return '已应用配置文件「$name」';
  }

  @override
  String get profileUndo => '撤销';

  @override
  String get profileActive => '使用中';

  @override
  String networkNow(Object info) {
    return '目前：$info';
  }

  @override
  String get networkUnknown => '无法取得网络信息';

  @override
  String get profileNoTriggers => '请至少添加一个触发条件：SSID、网关或 ASN';

  @override
  String get chains => '代理链';

  @override
  String get chainsEmpty => '尚无代理链。串接 2 至 3 台服务器，让流量依序通过每台服务器。';

  @override
  String get chainAdd => '添加代理链';

  @override
  String get chainName => '代理链名称';

  @override
  String get chainPickServers => '选择 2 至 3 台服务器';

  @override
  String get chainOrderHint => '拖动以调整顺序：流量从上方进入，从下方离开。';

  @override
  String get chainTooFew => '请至少选择 2 台服务器';

  @override
  String get chainTooMany => '代理链最多包含 3 台服务器';

  @override
  String get chainEstimate => '预估延迟';

  @override
  String get chainSave => '保存代理链';

  @override
  String get chainDelete => '删除代理链';

  @override
  String chainDeleteConfirm(Object name) {
    return '要删除代理链「$name」吗？';
  }

  @override
  String get chainUnsupported => '目前的引擎无法建立代理链';

  @override
  String get chainHopMissing => '代理链中的一台服务器已无法使用';

  @override
  String chainHop(Object n) {
    return '第 $n 跳';
  }

  @override
  String get chainEntry => '入口';

  @override
  String get chainExit => '出口';

  @override
  String get sync => '设备同步';

  @override
  String get syncDevices => '我的设备';

  @override
  String get syncEmpty => '尚无配对的设备。请透过局域网与另一台设备配对。';

  @override
  String get syncPair => '配对设备';

  @override
  String get syncShowCode => '显示我的代码';

  @override
  String get syncScanCode => '扫描代码';

  @override
  String get syncRevoke => '撤销';

  @override
  String syncRevokeConfirm(Object name) {
    return '要撤销「$name」吗？';
  }

  @override
  String syncLastSync(Object time) {
    return '上次同步：$time';
  }

  @override
  String get syncNever => '从未';

  @override
  String get syncNoLan => '设备必须位于同一个局域网';

  @override
  String get syncPaired => '设备已配对';

  @override
  String get syncPairingTitle => '与此设备配对';

  @override
  String get syncWaiting => '正在等待另一台设备…';

  @override
  String get syncSecureNote => '通道采用端到端加密，无需账号或云服务器。';

  @override
  String get zapretWithVpn => '直接连接流量的 DPI 绕过';

  @override
  String get zapretWithVpnHint => '与 VPN 隧道并行执行 zapret：隧道流量使用 VPN，直接连接流量则透过绕过机制。';

  @override
  String get chainDuplicate => '每台服务器只能选择一次';

  @override
  String get edit => '编辑';

  @override
  String get remove => '移除';

  @override
  String get autoSwitchOnDegrade => '质量下降时自动切换';

  @override
  String get autoSwitchOnDegradeDetail => '若所选服务器大幅变慢或停止回应，Sora 会切换至测量结果最佳的服务器，最多每 10 分钟切换一次。';

  @override
  String get tunStackMixed => '混合';

  @override
  String get tunStackSystem => '系统';

  @override
  String get customServerAdd => '添加自订服务器';

  @override
  String get customServers => '我的服务器';

  @override
  String get customServerName => '名称';

  @override
  String get customServerNameHint => '例如：我的 VPS';

  @override
  String get customServerNameRequired => '请输入名称';

  @override
  String get customServerAddress => '地址';

  @override
  String get customServerAddressHint => 'example.com 或 192.0.2.1';

  @override
  String get customServerAddressRequired => '请输入服务器地址';

  @override
  String get customServerAddressInvalid => '地址无效';

  @override
  String get customServerPort => '端口';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => '端口必须是 1 到 65535 之间的数字';

  @override
  String get customServerProtocol => '协议';

  @override
  String get customServerCredentials => '登录信息';

  @override
  String get customServerOptional => '可选';

  @override
  String get customServerShowSecret => '显示密钥';

  @override
  String get customServerHideSecret => '隐藏密钥';

  @override
  String get customServerBadge => '自订';

  @override
  String customServerDeleteConfirm(String name) {
    return '要删除服务器「$name」吗？';
  }

  @override
  String get customServerEmptyHint => '手动添加服务器：地址、端口和协议';

  @override
  String get customServerTest => '测试';

  @override
  String get leakTestTitle => '泄漏测试';

  @override
  String get leakTestIntro => '检查流量能否不经隧道离开设备：包括直接 DNS 和 ICMP 请求、IPv6 对外流量以及系统解析器。请在连接时执行。';

  @override
  String get leakTestRun => '执行测试';

  @override
  String get leakTestCancel => '取消';

  @override
  String get leakTestNeedsConnection => '请先连接，再执行泄漏测试。';

  @override
  String leakTestProgress(int count) {
    return '已完成测试：$count';
  }

  @override
  String get leakTestAllClear => '未发现泄漏';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '发现 # 处泄漏');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => '修复';

  @override
  String get leakTestFixedNote => '已启用网络锁定，请重新测试以确认。';

  @override
  String get leakTestCheckDirectDns => '直接 DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP 回显';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => '系统解析器';

  @override
  String get leakTestCheckTunnelConnectivity => '隧道连接状态';

  @override
  String get leakTestCheckTunnelDns => '隧道 DNS';

  @override
  String get noticeDegraded => '服务器变慢，已切换至测量结果最佳的服务器';

  @override
  String get obfs => '流量混淆';

  @override
  String get syncCodeExpired => '代码已到期';

  @override
  String get syncDaemonFailed => '无法启动同步服务';

  @override
  String get syncDaemonMissing => '找不到 sora-sync 元件。请重新安装应用程序以启用设备同步。';

  @override
  String get syncDaemonStarting => '正在启动同步服务…';

  @override
  String get syncErrAuth => '同步服务拒绝了访问令牌。请重新启动应用程序后再试一次。';

  @override
  String get syncErrNotFound => '此设备已解除配对';

  @override
  String get syncErrPairingActive => '已有进行中的配对会话';

  @override
  String get syncErrUnreachable => '另一台设备没有回应。请确认设备位于同一个网络，且正在显示配对代码。';

  @override
  String get syncError => '同步错误';

  @override
  String syncExpiresIn(String duration) {
    return '代码将在 $duration 后到期';
  }

  @override
  String get syncJoining => '正在与设备配对…';

  @override
  String get syncLegacyCleared => '旧设备清单未曾完成实际配对，因此已清除。请重新配对设备，这次会真正建立配对。';

  @override
  String get syncNewCode => '新代码';

  @override
  String syncPairedWith(String name) {
    return '已与 $name 配对';
  }

  @override
  String get syncRetry => '重试';

  @override
  String get syncStopShowing => '隐藏代码';

  @override
  String get syncSyncNow => '立即同步';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '已接收 $pulled，已发送 $pushed';
  }

  @override
  String get syncResultTitle => '同步结果';

  @override
  String get syncPulled => '已接收';

  @override
  String get syncPushed => '已发送';

  @override
  String get syncNoChanges => '没有更改';

  @override
  String get syncDocKindSubscriptions => '订阅';

  @override
  String get syncDocKindSettings => '应用程序设置';

  @override
  String get syncDocKindOverrides => '订阅覆盖设置';

  @override
  String get syncDocKindProfiles => '网络配置文件';

  @override
  String get syncDocKindChains => '代理链';

  @override
  String syncFrom(String name) {
    return '来自 $name';
  }

  @override
  String get syncThisDevice => '此设备';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密码，例如 chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => '抓包';

  @override
  String get diagnosticEvents => 'Windows 事件';

  @override
  String get diagnosticCapture => '捕捉10秒';

  @override
  String get diagnosticRequiresTun => '数据包捕获需要活动的 Sora TUN 连接。';

  @override
  String get diagnosticUnavailable => '此诊断在此平台上不可用。';

  @override
  String get extErrRevoked => 'Sora 团队已撤回此扩展版本，因为它不安全或已损坏。';

  @override
  String get extErrRevocationsExpired => '撤销列表更新前无法安装扩展。';

  @override
  String extRevokedDisabled(String names) {
    return '已关闭被撤回的扩展：$names';
  }

  @override
  String get customServerWgPrivateKey => '私钥';

  @override
  String get customServerWgAddresses => '接口地址';

  @override
  String get customServerWgPeerKey => '服务器公钥';

  @override
  String get customServerWgPresharedKey => '预共享密钥';

  @override
  String get customServerWgAllowedIps => '允许的 IP';

  @override
  String get customServerWgKeepalive => 'Keepalive（秒）';

  @override
  String get customServerWgKeyInvalid => '密钥必须是 base64 编码的 32 字节，与 wg genkey 的输出相同。';

  @override
  String get customServerWgCidrInvalid => '请输入以逗号分隔的前缀，例如 10.0.0.2/32。';

  @override
  String get customServerWgKeepaliveInvalid => '请输入 0 到 65535 之间的秒数。';

  @override
  String get strictKillSwitch => '严格网络锁定';

  @override
  String get strictKillSwitchWarning => '连接后，即使崩溃、重启或退出应用，也会阻止 VPN 之外的流量。只有断开连接或关闭此选项才会恢复访问。设备重启后，仅在启用启动时连接时恢复阻止。';

  @override
  String get extWorkerFailed => '扩展的后台任务失败。请查看扩展日志。';

  @override
  String get extAssetRejected => '扩展文件被拒绝：颜色难以辨认或规则无效。';

  @override
  String get extVerifiedSora => '经 Sora 验证';

  @override
  String extReceivedBytes(String count) {
    return '$count 字节';
  }

  @override
  String get extOpen => '打开';
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
  String get connEmpty => '沒有連接';

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
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '光';

  @override
  String get themeDark => '黑暗的';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '#伺服器，最快', one: '#伺服器，最快');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '模式';

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
  String get programsEmpty => '沒有找到應用程式。 嘗試另一個名字。';

  @override
  String get selectExe => '選擇一個 .exe 檔案';

  @override
  String get speedtest => '速度';

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
  String get updateSignaturePending => '更新檔案會與隨版本發布的檢查碼比對。';

  @override
  String get updateManualSigWarning => '下方檔案與版本的檢查碼相符。如果是從官方版本下載的，請執行該指令。';

  @override
  String get updateVersionRevoked => '開發者已撤回此版本，請等待修正版。';

  @override
  String get updateRolloutPending => '新版本正分批推出，屆時會自動通知您更新。';

  @override
  String updateRollbacking(String version) {
    return '正在還原至版本 $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '更新至 $version 後未通過運作檢查，Sora 已還原至 $fromVersion。';
  }

  @override
  String get updateRollbackError => '自動還原失敗。若新版本無法運作，請手動重新安裝先前的版本。';

  @override
  String get updateRollbackCacheError => '無法準備目前版本的已驗證還原副本，因此未安裝更新。';

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
      '如果您不確定您的伺服器需要哪個引擎，請選擇自動。 Sora 在連接前檢查設定檔和設定。 引擎無法增加計劃的頻寬：效能取決於伺服器、路由、協定和網路。\n\n## 模式\n\n### 所有流量 (TUN)\n\nSora 建立虛擬網路介面並透過它路由應用程式流量，包括 TCP 和 UDP。 Telegram、遊戲和Discord語音使用此模式。 規則可以直接發送或封鎖特定網站或程式。 網路服務需要權限和支援所需協定的伺服器。\n\n### System 代理\n\nSora 設定本機 HTTP/SOCKS 代理程式。 尊重系統代理設定的應用程式使用它。 擁有自己的網路堆疊的應用程式可以直接連接； UDP和語音通話一般需要TUN。 此模式適合具有代理支援的瀏覽器和應用程式。\n\n### 沒有伺服器\n\n在 Linux 上，Sora 使用 [zapret](https://github.com/bol-van/zapret) 來拆分和重塑 HTTP/TLS 請求並繞過一些 DPI 檢查。 您的 IP 保持不變，連線直接進入網站。 結果取決於您的提供者和阻止方法。\n\n目前整合使用 tpws 進行 HTTP 和 TCP 上的 TLS。 它不繞過IP阻塞或中繼UDP，也不能保證Telegram的MTProto連線。 使用具有 TUN 的 VPN 伺服器進行 Discord 語音、Telegram 通話和此類限制。\n\n## 引擎\n\n＃＃＃ 汽車\n\nSora 選擇支援整個連線計畫的已安裝引擎：伺服器協定、傳輸、群組、分段和模式。 在停止目前連線之前，不相容的手動選擇將被拒絕。 選擇自動或其他引擎並再次套用設定。\n\n### sing-box\n\n新的 Sora 軟體包包括 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx)，它是 [sing-box](https://github.com/SagerNet/sing-box) 的分支，增加了客戶端 XHTTP Sora 認可此構建及其功能。 沒有 XHTTP 的上游版本無法僅從其名稱中獲得此功能。\n\n支援的協定包括 VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard，以及 Sora 可匯入的 AmneziaWG 1.x/2.x 參數。完整的 Xray JSON 設定需要 Xray。目前尚無法匯入新的 AWG 3.x 欄位。sing-box 使用受密碼保護的本機控制連接埠，電腦上的其他應用程式可以偵測到該連接埠。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) 支援 VLESS、REALITY、XHTTP、VLESS Encryption 和 TLS 分片。 它還運行完整的供應商 Xray 配置文件，同時保留其路由和群組。 此類設定檔無法在不改變其行為的情況下自動轉換為另一個引擎。\n\n捆綁的 Xray 刪除了停用 TLS 憑證驗證的設定（「allowInsecure」）。 對於需要此設定的普通伺服器，自動選擇sing-box或mihomo。 在停止目前連線之前選擇 Xray 手動報告不相容性。 較舊的完整 JSON 設定檔需要更新的提供者設定檔以及可驗證的憑證或憑證 pin。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) 支援有序回退和負載平衡組 XHTTP 和 AmneziaWG。 當自動故障轉移到備份伺服器很重要時選擇它。 Sora 的 TLS 碎片設定在此引擎上不可用。\n\n## Sora 的兼容性\n\n|特色 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux TUN 和 TCP/UDP |是的 |是的 |是的 |\n| XHTTP |是的 |是的 |是的 |\n| VLESS Encryption |是的 |是的 |是的 |\n| Xray 完整簡介 |沒有 |是的 |沒有 |\n| TUIC / AnyTLS |兩者 |沒有 | TUIC |\n| TLS 碎片 |是的 |是的 |沒有 |\n| AmneziaWG 1.x/2.x |是的 1 |沒有 |是的 |\n|有順序後備組 |沒有 |沒有² |是的 |\n\n1 附 J1/J2/J3/Itime 的型材使用 mihomo；這些欄位絕不能被默默地丟棄。 ² 對於一組完整的 Xray 設定文件，應用程式會選擇一個備份設定檔。 支援取決於安裝的版本；在「關於」中檢查其版本。\n\n## TUN 堆疊\n\n此堆疊在虛擬介面內處理 TCP 和 UDP。 在模式面板中，Xray和mihomo提供gVisor、System、Mixed和MIPS。 每個引擎都會保存自己的首選項。 System 代理程式和無伺服器模式不使用此首選項。\n\n- **Mixed**: TCP 使用系統堆疊，而 gVisor 處理 UDP。 這是 Linux 上 mihomo 的預設值。在 Windows 上，Xray 和 mihomo 預設使用 MIPS。\n- **System**: 使用系統堆疊。 如果網頁應用程式遇到問題，請嘗試其他選項。\n- **gVisor**: 處理用戶空間中的流量。\n- **MIPS**: mihomo 自己的 IP 堆疊，在捆綁版本 1.19.32 中提供。\n\n在Linux上，Xray預設使用其內建的gVisor。 Linux 上的 System、Mixed 和 MIPS 使用 mihomo 作為 TUN 引擎，透過經過驗證的本機 SOCKS 連結將 TCP 和 UDP 轉送到 Xray。 Xray 保留協定、提供者設定檔和路由。 這三個選項需要安裝 mihomo。 在Windows 上，Xray 的四種 TUN 協定堆疊均使用 mihomo 1.19.32 或更新版本。協定與路由仍由 Xray 處理。此組合中的應用程式規則僅支援直連與封鎖；在 Linux 上，這些規則需要 Xray 內建的 gVisor。\n\n橋接器運行第二個進程。 在 Linux 上的三個空閒測量中，它比本機 Xray TUN 多使用了約 32-36 MiB 的實體記憶體。 這不會測量下載負載：CPU 和記憶體成本取決於連接。 sing-box沒有堆疊選擇器。 沒有任何堆疊可以保證每個網路都有更好的效能。 選擇一個堆疊並選擇“應用並重新連接”以在您的網路中進行嘗試。\n\n## 應用程式設定\n\n選擇伺服器會自動重新連線。 模式、引擎、DNS和規則設定立即儲存；在活動連線期間，按一下應用並重新連線即可使用它們。 重新啟動引擎可能會中斷下載和呼叫。 重複點擊不會啟動並行連接；斷開連接結束轉換並釋放連接。\n\n當隧道斷開時，僅透過 VPN 的 Internet 會阻止直接流量。 它影響整個機器。 明確斷開連線會刪除 Sora 的規則。 如果清理未完成，請重試斷開連線並開啟日誌。\n\n## 專案文檔\n\n- [sing-box-lx：設定與支援](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 文件](https://sing-box.sagernet.org/)\n- [Xray 文件](https://xtls.github.io/)\n- [mihomo 文件](https://wiki.metacubex.one/)\n- [zapret：操作與限制](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '檢查伺服器';

  @override
  String get extensions => '擴充';

  @override
  String extRatingLabel(String rating) {
    return '評分 $rating，滿分 5 分';
  }

  @override
  String extByAuthor(String author) {
    return '作者：$author';
  }

  @override
  String extInstallsCount(String count) {
    return '安裝次數：$count';
  }

  @override
  String get extInstallOne => '1 次安裝';

  @override
  String get extSideloadWarning => '僅在信任作者的自簽章金鑰時安裝。';

  @override
  String get extPermissionsWidened => '此更新要求新的權限：';

  @override
  String get extDangerousAck => '我瞭解這些權限的影響範圍很大';

  @override
  String get extInstall => '安裝';

  @override
  String get extUpdate => '更新';

  @override
  String get extCancel => '取消';

  @override
  String get extConfirm => '確認';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => '目錄';

  @override
  String get extInstalled => '已安裝';

  @override
  String get extSearchHint => '搜尋擴充功能';

  @override
  String get extCatAll => '全部';

  @override
  String get extCatTools => '工具';

  @override
  String get extCatThemes => '佈景主題';

  @override
  String get extCatAutomation => '自動化';

  @override
  String get extCatStats => '統計';

  @override
  String get extCatNetwork => '網路';

  @override
  String get extSortBy => '排序方式';

  @override
  String get extSortPopular => '最熱門';

  @override
  String get extSortRating => '評分最高';

  @override
  String get extSortName => '名稱';

  @override
  String get extCatalogError => '無法載入目錄';

  @override
  String get extRetry => '重試';

  @override
  String get extEmptySearch => '找不到結果';

  @override
  String get extEmptyInstalled => '尚未安裝擴充功能。\n請從目錄中尋找，或從檔案安裝。';

  @override
  String get extInstallFromFile => '從檔案安裝';

  @override
  String get extInstallFromUrl => '從 URL 安裝';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => '下載';

  @override
  String get extDownloading => '正在下載…';

  @override
  String get extVerifying => '正在驗證…';

  @override
  String get extInstalling => '正在安裝…';

  @override
  String get extInstallFailed => '安裝失敗';

  @override
  String get extErrSignature => '簽章驗證失敗。檔案可能已損毀或遭到竄改。';

  @override
  String get extErrManifest => '擴充功能的資訊清單無效。';

  @override
  String get extErrNetwork => '網路錯誤，請檢查連接後再試一次。';

  @override
  String get extErrHash => '下載的檔案與目錄不符，可能遭到竄改。';

  @override
  String extErrMinApp(String version) {
    return '此擴充功能需要應用程式 $version 或更新版本。';
  }

  @override
  String get extErrHttpsOnly => '僅允許 https:// 連結';

  @override
  String get extErrGeneric => '發生錯誤，請再試一次。';

  @override
  String get extErrAuthorKeyChanged => '此更新的作者簽署金鑰與已安裝版本不同，因此已遭封鎖。若您信任新金鑰，請先解除安裝擴充功能，再自行重新安裝。';

  @override
  String get extDisabled => '已停用';

  @override
  String extToggleEnabled(String name) {
    return '啟用 $name';
  }

  @override
  String get extSearchInstalled => '搜尋已安裝的擴充功能';

  @override
  String get extUpdateAll => '全部更新';

  @override
  String extUpdatesAvailable(int count) {
    return '有 $count 個可用更新';
  }

  @override
  String extUpdatedCount(int count) {
    return '已更新 $count 個';
  }

  @override
  String get extRiskNormal => '一般';

  @override
  String get extRiskSensitive => '敏感';

  @override
  String get extRiskDangerous => '高風險';

  @override
  String get extPermissionsRemoved => '不再要求：';

  @override
  String get extUpdateFailedKept => '已保留先前安裝的版本。';

  @override
  String get extConflictsTitle => '擴充功能衝突';

  @override
  String get extConflictTheme => '應用程式佈景主題';

  @override
  String get extConflictNetHooks => '網路攔截掛鉤';

  @override
  String extConflictWinner(String name) {
    return '優先使用 $name';
  }

  @override
  String extConflictsCount(int count) {
    return '有 $count 個衝突需要您決定';
  }

  @override
  String get extConflictsResolve => '解決衝突';

  @override
  String extVersionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get extPermissionsTitle => '權限';

  @override
  String get extNoPermissions => '不需要特殊權限。';

  @override
  String get extSettings => '設定';

  @override
  String get extSaveSettings => '儲存設定';

  @override
  String extUpdateTo(String version) {
    return '更新至 $version';
  }

  @override
  String get extEnabled => '已啟用';

  @override
  String extRollbackTo(String version) {
    return '還原至 $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return '要還原至版本 $version 嗎？';
  }

  @override
  String get extUninstall => '解除安裝';

  @override
  String extUninstallConfirm(String name) {
    return '要移除「$name」及其設定嗎？';
  }

  @override
  String get extPanelUnavailable => '擴充功能面板無法使用。';

  @override
  String get extPermConnectionsRead => '查看目前的連接清單';

  @override
  String get extPermServersRead => '查看您的伺服器清單';

  @override
  String get extPermSettingsRead => '讀取應用程式設定';

  @override
  String get extPermSettingsWrite => '變更應用程式設定';

  @override
  String get extPermNotifications => '顯示通知';

  @override
  String get extPermTray => '新增系統匣選單項目';

  @override
  String get extPermUiPanel => '在應用程式中顯示面板';

  @override
  String get extPermThemeApply => '套用應用程式佈景主題';

  @override
  String get extPermRoutingRules => '新增路由規則（影響流量去向）';

  @override
  String get extPermNetHooks => '介入網路傳輸路徑（DPI 繞過模組）';

  @override
  String get extPermNetFetch => '存取允許清單中的 URL';

  @override
  String get extPermBackground => '執行背景工作';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => '在背景執行';

  @override
  String get extCapNetHook => '繞過機制與網路掛鉤';

  @override
  String get extCapPanel => '面板';

  @override
  String get extCapRouting => '路由規則';

  @override
  String get extCapTheme => '佈景主題';

  @override
  String get extCapWidget => '小工具';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => '版本記錄';

  @override
  String get extImageFailed => '無法載入圖片';

  @override
  String get extScreenshots => '螢幕擷取畫面';

  @override
  String get extSortRelevance => '相關程度';

  @override
  String get extPermNetworkDetail => 'VPN 請求僅限存取以下主機。';

  @override
  String get extBgTitle => '背景工作';

  @override
  String get extBgEnabled => '在背景執行';

  @override
  String get extBgInterval => '執行間隔';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 分鐘');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 小時');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => '請先啟用擴充功能，才能管理背景工作。';

  @override
  String get extCapNetwork => '網路存取';

  @override
  String extCapNetworkHosts(String hosts) {
    return '網路：$hosts';
  }

  @override
  String exportLogFile(String name) {
    return '儲存為 $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 診斷';

  @override
  String get diagnosticNoData => '尚未記錄請求。 首先打開一個速度測試網站。';

  @override
  String get qrShareTitle => '透過 QR 分享';

  @override
  String get qrScanTitle => '掃描 QR 碼';

  @override
  String get qrCopyLink => '複製連結';

  @override
  String get qrShowLink => '顯示連結';

  @override
  String get qrHideLink => '隱藏連結';

  @override
  String get qrWarning => '此 QR 碼含有連接資訊，請勿向陌生人展示。';

  @override
  String get qrScanHint => '選擇包含 QR 碼的截圖或相片，或貼上連結';

  @override
  String get qrFromClipboard => '從剪貼簿貼上';

  @override
  String get qrNoCode => '此圖片中找不到 QR 碼。';

  @override
  String get qrInvalid => '此 QR 碼不含有效連結。';

  @override
  String get qrScan => '掃描 QR';

  @override
  String get qrFromImage => '開啟圖片';

  @override
  String get connGroupByProcess => '依處理程序分組';

  @override
  String get connListView => '清單檢視';

  @override
  String get connCopyHost => '複製主機名稱';

  @override
  String get connAddRule => '新增規則';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 個連接');
    return '$_temp0';
  }

  @override
  String get dnsPreset => '預設組態';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => '自訂';

  @override
  String get dnsCheck => '檢查洩漏';

  @override
  String get dnsChecking => '正在檢查...';

  @override
  String get dnsNoLeak => '未發現洩漏';

  @override
  String get dnsLeakFound => '偵測到洩漏';

  @override
  String get dnsLastCheck => '上次檢查';

  @override
  String get dnsNeverChecked => '尚未檢查';

  @override
  String get dnsLeakCheckTunnelDns => '通道 DNS 解析器';

  @override
  String get dnsLeakCheckSystemResolvers => '系統解析器';

  @override
  String get dnsLeakCheckKillSwitchDns => '網路鎖定的 DNS 保護';

  @override
  String get dnsLeakFixConfigureTunnelDns => '請在上方的 DNS 設定中指定通道 DNS。';

  @override
  String get dnsLeakFixReviewSystemResolvers => '檢查系統在通道外會使用哪些解析器。';

  @override
  String get dnsLeakFixEnableKillSwitch => '請啟用網路鎖定，讓 DNS 流量保持在通道內。';

  @override
  String get dnsLeakCheckEncryptedDns => '作業系統加密 DNS';

  @override
  String get dnsLeakCheckDnsSpoof => 'DNS 回應偽造';

  @override
  String get dnsLeakFixReviewEncryptedDns => '檢查系統在通道外使用的加密 DNS 端點。';

  @override
  String get dnsLeakFixUseEncryptedDns => '請為通道使用加密 DNS（DoT 或 DoH），避免解析器偽造回應。';

  @override
  String get dnsCheckNeedsConnection => '請先連接 VPN，再檢查是否洩漏。';

  @override
  String get dnsExpected => '預期';

  @override
  String get dnsActual => '實際';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortPing => '延遲';

  @override
  String get sortSpeed => '速度';

  @override
  String get sortName => '名稱';

  @override
  String get measureSpeed => '測量速度';

  @override
  String get benchmarkStale => '已過時';

  @override
  String get autoSelectMode => '自動選擇伺服器';

  @override
  String get autoSelectPing => '最低延遲';

  @override
  String get autoSelectSpeed => '最高速度';

  @override
  String get autoSelectSmart => '智慧選擇';

  @override
  String get coreWatchUnstable => '與核心的連接不穩定';

  @override
  String get watchReconnect => '重新連接';

  @override
  String get coreRestoringLink => '正在恢復與核心的連接…';

  @override
  String get crashRestoreTitle => '上次工作階段意外中斷';

  @override
  String get restoreOnCrash => '當機後還原工作階段';

  @override
  String get crashRestore => '還原';

  @override
  String get crashDismiss => '暫時不要';

  @override
  String get overrideTitle => '我的修改';

  @override
  String get overrideEdit => '編輯伺服器';

  @override
  String get overrideHide => '隱藏';

  @override
  String get overrideUnhide => '顯示';

  @override
  String get overrideClear => '清除修改';

  @override
  String get overrideEmpty => '尚無修改';

  @override
  String get overrideCustomRules => '自訂規則';

  @override
  String get errBenchmarkUnsupported => '測速需要更新版本的核心';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '正在測量 $done/$total…';
  }

  @override
  String get profiles => '網路設定檔';

  @override
  String get profilesEmpty => '尚無設定檔。建立後，即可在已知網路中自動套用設定。';

  @override
  String get profileAdd => '新增設定檔';

  @override
  String get profileName => '設定檔名稱';

  @override
  String get profileSsids => 'Wi-Fi 網路（SSID）';

  @override
  String get profileSsidsHint => '住家、辦公室，以逗號分隔';

  @override
  String get profileGateways => '閘道';

  @override
  String get profileAsns => 'AS 編號';

  @override
  String get profileAutoApply => '自動套用';

  @override
  String get profileAutoApplyHint => '關閉時，套用設定檔前會要求確認。';

  @override
  String get profileSnapshot => '記住目前設定';

  @override
  String get profileSnapshotDone => '目前設定已儲存至設定檔';

  @override
  String get profileDelete => '刪除設定檔';

  @override
  String profileDeleteConfirm(Object name) {
    return '要刪除設定檔「$name」嗎？';
  }

  @override
  String profileApplyAsk(Object name) {
    return '要套用設定檔「$name」嗎？';
  }

  @override
  String get profileApply => '套用';

  @override
  String profileApplied(Object name) {
    return '已套用設定檔「$name」';
  }

  @override
  String get profileUndo => '復原';

  @override
  String get profileActive => '使用中';

  @override
  String networkNow(Object info) {
    return '目前：$info';
  }

  @override
  String get networkUnknown => '無法取得網路資訊';

  @override
  String get profileNoTriggers => '請至少新增一個觸發條件：SSID、閘道或 ASN';

  @override
  String get chains => '代理鏈';

  @override
  String get chainsEmpty => '尚無代理鏈。串接 2 至 3 台伺服器，讓流量依序通過每台伺服器。';

  @override
  String get chainAdd => '新增代理鏈';

  @override
  String get chainName => '代理鏈名稱';

  @override
  String get chainPickServers => '選擇 2 至 3 台伺服器';

  @override
  String get chainOrderHint => '拖曳以調整順序：流量從上方進入，從下方離開。';

  @override
  String get chainTooFew => '請至少選擇 2 台伺服器';

  @override
  String get chainTooMany => '代理鏈最多包含 3 台伺服器';

  @override
  String get chainEstimate => '預估延遲';

  @override
  String get chainSave => '儲存代理鏈';

  @override
  String get chainDelete => '刪除代理鏈';

  @override
  String chainDeleteConfirm(Object name) {
    return '要刪除代理鏈「$name」嗎？';
  }

  @override
  String get chainUnsupported => '目前的引擎無法建立代理鏈';

  @override
  String get chainHopMissing => '代理鏈中的一台伺服器已無法使用';

  @override
  String chainHop(Object n) {
    return '第 $n 跳';
  }

  @override
  String get chainEntry => '入口';

  @override
  String get chainExit => '出口';

  @override
  String get sync => '裝置同步';

  @override
  String get syncDevices => '我的裝置';

  @override
  String get syncEmpty => '尚無配對的裝置。請透過區域網路與另一台裝置配對。';

  @override
  String get syncPair => '配對裝置';

  @override
  String get syncShowCode => '顯示我的代碼';

  @override
  String get syncScanCode => '掃描代碼';

  @override
  String get syncRevoke => '撤銷';

  @override
  String syncRevokeConfirm(Object name) {
    return '要撤銷「$name」嗎？';
  }

  @override
  String syncLastSync(Object time) {
    return '上次同步：$time';
  }

  @override
  String get syncNever => '從未';

  @override
  String get syncNoLan => '裝置必須位於同一個區域網路';

  @override
  String get syncPaired => '裝置已配對';

  @override
  String get syncPairingTitle => '與此裝置配對';

  @override
  String get syncWaiting => '正在等待另一台裝置…';

  @override
  String get syncSecureNote => '通道採用端對端加密，不需要帳號或雲端伺服器。';

  @override
  String get zapretWithVpn => '直接連線流量的 DPI 繞過';

  @override
  String get zapretWithVpnHint => '與 VPN 通道並行執行 zapret：通道流量使用 VPN，直接連線流量則透過繞過機制。';

  @override
  String get chainDuplicate => '每台伺服器只能選擇一次';

  @override
  String get edit => '編輯';

  @override
  String get remove => '移除';

  @override
  String get autoSwitchOnDegrade => '品質下降時自動切換';

  @override
  String get autoSwitchOnDegradeDetail => '若所選伺服器大幅變慢或停止回應，Sora 會切換至測量結果最佳的伺服器，最多每 10 分鐘切換一次。';

  @override
  String get tunStackMixed => '混合';

  @override
  String get tunStackSystem => '系統';

  @override
  String get customServerAdd => '新增自訂伺服器';

  @override
  String get customServers => '我的伺服器';

  @override
  String get customServerName => '名稱';

  @override
  String get customServerNameHint => '例如：我的 VPS';

  @override
  String get customServerNameRequired => '請輸入名稱';

  @override
  String get customServerAddress => '位址';

  @override
  String get customServerAddressHint => 'example.com 或 192.0.2.1';

  @override
  String get customServerAddressRequired => '請輸入伺服器位址';

  @override
  String get customServerAddressInvalid => '位址無效';

  @override
  String get customServerPort => '連接埠';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => '連接埠必須是 1 到 65535 之間的數字';

  @override
  String get customServerProtocol => '協定';

  @override
  String get customServerCredentials => '登入資訊';

  @override
  String get customServerOptional => '選填';

  @override
  String get customServerShowSecret => '顯示機密資訊';

  @override
  String get customServerHideSecret => '隱藏機密資訊';

  @override
  String get customServerBadge => '自訂';

  @override
  String customServerDeleteConfirm(String name) {
    return '要刪除伺服器「$name」嗎？';
  }

  @override
  String get customServerEmptyHint => '手動新增伺服器：位址、連接埠和協定';

  @override
  String get customServerTest => '測試';

  @override
  String get leakTestTitle => '洩漏測試';

  @override
  String get leakTestIntro => '檢查流量能否不經通道離開裝置：包括直接 DNS 和 ICMP 請求、IPv6 對外流量以及系統解析器。請在連接時執行。';

  @override
  String get leakTestRun => '執行測試';

  @override
  String get leakTestCancel => '取消';

  @override
  String get leakTestNeedsConnection => '請先連接，再執行洩漏測試。';

  @override
  String leakTestProgress(int count) {
    return '已完成測試：$count';
  }

  @override
  String get leakTestAllClear => '未發現洩漏';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '發現 # 處洩漏');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => '修正';

  @override
  String get leakTestFixedNote => '已啟用網路鎖定，請重新測試以確認。';

  @override
  String get leakTestCheckDirectDns => '直接 DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP 回應';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => '系統解析器';

  @override
  String get leakTestCheckTunnelConnectivity => '通道連接狀態';

  @override
  String get leakTestCheckTunnelDns => '通道 DNS';

  @override
  String get noticeDegraded => '伺服器變慢，已切換至測量結果最佳的伺服器';

  @override
  String get obfs => '流量混淆';

  @override
  String get syncCodeExpired => '代碼已到期';

  @override
  String get syncDaemonFailed => '無法啟動同步服務';

  @override
  String get syncDaemonMissing => '找不到 sora-sync 元件。請重新安裝應用程式以啟用裝置同步。';

  @override
  String get syncDaemonStarting => '正在啟動同步服務…';

  @override
  String get syncErrAuth => '同步服務拒絕了存取權杖。請重新啟動應用程式後再試一次。';

  @override
  String get syncErrNotFound => '此裝置已解除配對';

  @override
  String get syncErrPairingActive => '已有進行中的配對工作階段';

  @override
  String get syncErrUnreachable => '另一台裝置沒有回應。請確認裝置位於同一個網路，且正在顯示配對代碼。';

  @override
  String get syncError => '同步錯誤';

  @override
  String syncExpiresIn(String duration) {
    return '代碼將在 $duration 後到期';
  }

  @override
  String get syncJoining => '正在與裝置配對…';

  @override
  String get syncLegacyCleared => '舊裝置清單未曾完成實際配對，因此已清除。請重新配對裝置，這次會真正建立配對。';

  @override
  String get syncNewCode => '新代碼';

  @override
  String syncPairedWith(String name) {
    return '已與 $name 配對';
  }

  @override
  String get syncRetry => '重試';

  @override
  String get syncStopShowing => '隱藏代碼';

  @override
  String get syncSyncNow => '立即同步';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '已接收 $pulled，已傳送 $pushed';
  }

  @override
  String get syncResultTitle => '同步結果';

  @override
  String get syncPulled => '已接收';

  @override
  String get syncPushed => '已傳送';

  @override
  String get syncNoChanges => '沒有變更';

  @override
  String get syncDocKindSubscriptions => '訂閱';

  @override
  String get syncDocKindSettings => '應用程式設定';

  @override
  String get syncDocKindOverrides => '訂閱覆寫設定';

  @override
  String get syncDocKindProfiles => '網路設定檔';

  @override
  String get syncDocKindChains => '代理鏈';

  @override
  String syncFrom(String name) {
    return '來自 $name';
  }

  @override
  String get syncThisDevice => '此裝置';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials => 'Shadowsocks：方法:密碼，例如 chacha20-ietf-poly1305:password';

  @override
  String get diagnosticPackets => '抓包';

  @override
  String get diagnosticEvents => 'Windows 事件';

  @override
  String get diagnosticCapture => '捕捉10秒';

  @override
  String get diagnosticRequiresTun => '封包擷取需要活動的 Sora TUN 連線。';

  @override
  String get diagnosticUnavailable => '此診斷在此平台上不可用。';

  @override
  String get extErrRevoked => 'Sora 團隊已撤回此擴充功能版本，因為它不安全或已損壞。';

  @override
  String get extErrRevocationsExpired => '撤銷清單更新前無法安裝擴充功能。';

  @override
  String extRevokedDisabled(String names) {
    return '已關閉被撤回的擴充功能：$names';
  }

  @override
  String get customServerWgPrivateKey => '私密金鑰';

  @override
  String get customServerWgAddresses => '介面位址';

  @override
  String get customServerWgPeerKey => '伺服器公開金鑰';

  @override
  String get customServerWgPresharedKey => '預先共用金鑰';

  @override
  String get customServerWgAllowedIps => '允許的 IP';

  @override
  String get customServerWgKeepalive => 'Keepalive（秒）';

  @override
  String get customServerWgKeyInvalid => '金鑰必須是 base64 編碼的 32 位元組，與 wg genkey 的輸出相同。';

  @override
  String get customServerWgCidrInvalid => '請輸入以逗號分隔的前綴，例如 10.0.0.2/32。';

  @override
  String get customServerWgKeepaliveInvalid => '請輸入 0 到 65535 之間的秒數。';

  @override
  String get strictKillSwitch => '嚴格網路鎖定';

  @override
  String get strictKillSwitchWarning =>
      '連線後，即使當機、重新啟動或結束應用程式，也會阻擋 VPN 以外的流量。只有中斷連線或關閉此選項才會恢復存取。裝置重新啟動後，僅在啟用啟動時連線時恢復阻擋。';

  @override
  String get extWorkerFailed => '擴充功能的背景工作失敗。請查看擴充功能記錄。';

  @override
  String get extAssetRejected => '擴充功能檔案遭拒：顏色難以辨認或規則無效。';

  @override
  String get extVerifiedSora => '經 Sora 驗證';

  @override
  String extReceivedBytes(String count) {
    return '$count 位元組';
  }

  @override
  String get extOpen => '開啟';
}
