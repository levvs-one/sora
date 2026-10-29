// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class SKo extends S {
  SKo([String locale = 'ko']) : super(locale);

  @override
  String get stateOff => '연결되지 않음';

  @override
  String get stateConnecting => '연결 중';

  @override
  String get stateConnected => '연결됨';

  @override
  String get stateReconnecting => '다시 연결하는 중';

  @override
  String get stateDisconnecting => '연결 끊기';

  @override
  String get coreMissing => 'Sora 서비스가 응답하지 않습니다.';

  @override
  String get serverAuto => '가장 빠른';

  @override
  String get serverBypass => '서버 없음';

  @override
  String get addSubscription => '구독 추가';

  @override
  String get servers => '서버';

  @override
  String get settings => '설정';

  @override
  String get subscription => '신청';

  @override
  String get subscriptionLink => '구독 링크';

  @override
  String get add => '추가하다';

  @override
  String get refresh => '업데이트';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get delete => '삭제';

  @override
  String get cancel => '취소';

  @override
  String get save => '구하다';

  @override
  String get name => '이름';

  @override
  String deleteSubscription(String name) {
    return '\'$name\'를 삭제하시겠습니까?';
  }

  @override
  String get routes => '노선';

  @override
  String get presetGlobal => 'VPN을 통해 모든 것';

  @override
  String get presetRu => '러시아 직접';

  @override
  String get presetIr => '이란 직항';

  @override
  String get presetCn => '중국직접';

  @override
  String get blockAds => '광고 차단';

  @override
  String get killSwitch => 'VPN을 통해서만 인터넷 사용 가능';

  @override
  String get engine => '엔진';

  @override
  String get engineAuto => '자동';

  @override
  String get animations => '애니메이션';

  @override
  String get logs => '통나무';

  @override
  String get about => '에 대한';

  @override
  String get logsAll => '모두';

  @override
  String get logsImportant => '중요한';

  @override
  String get logsErrors => '오류';

  @override
  String get search => '찾다';

  @override
  String get export => '파일에 저장';

  @override
  String get clear => '분명한';

  @override
  String get logsEmpty => '여기에는 아무것도 없습니다';

  @override
  String get connEmpty => '연결 없음';

  @override
  String appVersion(String version) {
    return '버전 $version';
  }

  @override
  String get notInstalled => '설치되지 않음';

  @override
  String get sourceCode => '소스 코드';

  @override
  String get reportProblem => '문제 신고';

  @override
  String get license => '특허';

  @override
  String usage(String used, String total) {
    return '$total의 $used';
  }

  @override
  String until(String date) {
    return '$date까지';
  }

  @override
  String get expired => '만료됨';

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
    return '${n}KB';
  }

  @override
  String bytesMB(String n) {
    return '${n}MB';
  }

  @override
  String bytesGB(String n) {
    return '${n}GB';
  }

  @override
  String bytesTB(String n) {
    return '${n}TB';
  }

  @override
  String get errGeneric => '문제가 발생했습니다.';

  @override
  String get errCore => 'Sora 서비스가 응답하지 않습니다';

  @override
  String get errAuth => 'Sora 서비스에 대한 접근이 거부되었습니다';

  @override
  String get errVersion => 'Sora 앱과 서비스의 버전이 다릅니다';

  @override
  String get errBusy => '이전 명령이 아직 실행 중입니다';

  @override
  String get errEngineMissing => '이 서버에 필요한 엔진을 찾을 수 없습니다';

  @override
  String get errEngineStart => '엔진을 시작하지 못했습니다';

  @override
  String get errEngineStopped => '엔진이 중지되었습니다';

  @override
  String get errTunnel => '이 VPN 모드는 사용할 수 없습니다';

  @override
  String get errTimeout => '서버가 제시간에 응답하지 않았습니다';

  @override
  String get errFirewall => 'VPN 외부의 인터넷 접근을 차단하지 못했습니다';

  @override
  String get errSubFetch => '구독을 다운로드하지 못했습니다';

  @override
  String get deviceIdentity => '기기 식별자';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => '식별자 초기화';

  @override
  String get deviceIdentityResetConfirm => '기기 식별자를 초기화할까요?';

  @override
  String get errSubDeviceLimit => '기기 한도에 도달했습니다';

  @override
  String get errSubDeviceRequired => '제공자가 기기 식별자를 요구합니다';

  @override
  String get errSubFormat => '구독 형식을 인식하지 못했습니다';

  @override
  String get errSubEmpty => '구독에 서버가 없습니다';

  @override
  String get errSubDuplicate => '이미 추가된 구독입니다';

  @override
  String get errSubLimit => '구독 수가 한도에 도달했습니다';

  @override
  String get errSubScheme => '지원되지 않는 구독 링크 방식';

  @override
  String get errSecretStore => 'Sora 저장소가 손상되었거나 접근할 수 없습니다';

  @override
  String get errNoServers => '연결할 서버가 없습니다';

  @override
  String get connections => '사이';

  @override
  String get close => '닫다';

  @override
  String get chainDirect => '직접';

  @override
  String get chainBlocked => '막힌';

  @override
  String get theme => '주제';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '빛';

  @override
  String get themeDark => '어두운';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get sectionConnection => '연결';

  @override
  String get sectionNoServer => '서버 없음';

  @override
  String get sectionPing => '핑';

  @override
  String get sectionLog => '진단';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => '자동';

  @override
  String get fragment => 'TLS 조각화';

  @override
  String get fragmentPackets => '무엇을 분할할 것인가';

  @override
  String get fragmentLength => '조각 크기';

  @override
  String get fragmentInterval => '조각 사이에 일시 중지';

  @override
  String get byDefault => '기본';

  @override
  String get splitPos => '위치 분할';

  @override
  String get disorder => '조각 재정렬';

  @override
  String get tlsRecord => 'TLS 레코드 분할';

  @override
  String get tlsRecordNo => '아니요';

  @override
  String get tlsRecordSni => '사이트 이름에';

  @override
  String get tlsRecordFirst => '첫 번째 바이트 이후';

  @override
  String get hostCase => '호스트 케이스 변경';

  @override
  String get probeMethod => '방법';

  @override
  String get probeAuto => '자동';

  @override
  String get probeEngine => '엔진을 통해서';

  @override
  String get probeConnect => '연결만 가능';

  @override
  String get probeUrl => '테스트 주소';

  @override
  String get probeTimeout => '기다리다';

  @override
  String seconds(int n) {
    return '$n';
  }

  @override
  String get subscriptions => '구독';

  @override
  String get subscriptionSettings => '설정';

  @override
  String get userAgent => '사용자 에이전트';

  @override
  String get autoUpdate => '자동으로 업데이트';

  @override
  String get updateInterval => '얼마나 자주';

  @override
  String get intervalProvider => '공급자가 요청하는 대로';

  @override
  String hours(int n) {
    return '${n}h';
  }

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get logLevel => '녹음할 내용';

  @override
  String get levelDebug => '모든 것';

  @override
  String get levelInfo => '평소';

  @override
  String get levelWarning => '중요한';

  @override
  String get levelError => '오류만';

  @override
  String get recordDestinations => '사이트 주소 기록';

  @override
  String get reset => '설정 재설정';

  @override
  String get resetConfirm => '모든 설정을 재설정하시겠습니까?';

  @override
  String get resetAction => '다시 놓기';

  @override
  String get invalidValue => '이 값은 작동하지 않습니다';

  @override
  String get website => '구독 페이지';

  @override
  String get providerWebsite => '제공업체 웹사이트';

  @override
  String get support => '지원하다';

  @override
  String chooseEngine(String engine) {
    return '$engine를 선택하세요';
  }

  @override
  String get rules => '맞춤 규칙';

  @override
  String get ruleAdd => '새로운 규칙';

  @override
  String get ruleHint => '사이트, IP 또는 프로그램';

  @override
  String get ruleDirect => '직접';

  @override
  String get ruleProxy => 'VPN을 통해';

  @override
  String get ruleBlock => '차단하다';

  @override
  String get failover => '실패를 켜십시오';

  @override
  String get connectOnStart => '시작 시 연결';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '구독이 $days일 후에 종료됩니다',
      one: '구독은 $days일에 종료됩니다',
      zero: '구독이 몇 시간 후에 종료됩니다',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left 왼쪽';
  }

  @override
  String get ruleInvalid => '사이트나 IP, 프로그램처럼 보이지 않습니다.';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '가장 빠른 $count 서버', one: '가장 빠른 $count 서버');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '방법';

  @override
  String get tunnelProxy => 'System 프록시';

  @override
  String get proxyAddress => '프록시 주소';

  @override
  String get copied => '복사됨';

  @override
  String get launchAtLogin => '시스템으로 시작하세요';

  @override
  String get closeToTray => '닫은 후에는 트레이에 보관하세요.';

  @override
  String get notifications => '알림';

  @override
  String get trayOpen => 'Sora 열기';

  @override
  String get trayConnect => '연결하다';

  @override
  String get trayDisconnect => '연결 끊기';

  @override
  String get trayServer => '섬기는 사람';

  @override
  String get trayQuit => 'Sora 종료';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora가 아직 트레이에 있습니다.';

  @override
  String get noticeLost => '연결 끊김';

  @override
  String get noticeLostBody => 'Sora가 다시 연결 중입니다.';

  @override
  String get noticeRestored => '다시 연결됨';

  @override
  String get noticeFailed => '연결할 수 없습니다.';

  @override
  String get noticeBackup => '메인 서버가 응답하지 않았습니다. 백업이 트래픽을 전달합니다.';

  @override
  String get noticeNext => '서버가 응답하지 않았습니다. 다음 차는 교통을 운반한다';

  @override
  String get noticeMainBack => '메인 서버가 다시 응답하고 트래픽을 전달합니다.';

  @override
  String get noticeSubscription => '신청';

  @override
  String get importTitle => '이 구독을 추가하시겠습니까?';

  @override
  String get importSealed => '이 링크는 Happ에 대해 암호화되어 있으며 Happ만 읽을 수 있습니다';

  @override
  String get noAnswer => '대답이 없다';

  @override
  String get home => '집';

  @override
  String get navRules => '규칙';

  @override
  String get navConnections => '사이';

  @override
  String get navLogs => '로그';

  @override
  String get navAbout => '에 대한';

  @override
  String get sidebarToggle => '사이드바 전환';

  @override
  String get more => '더';

  @override
  String get less => '더 적은';

  @override
  String get notificationsEmpty => '알림 없음';

  @override
  String get retryConnect => '연결 재시도';

  @override
  String get openLogs => '로그 열기';

  @override
  String get tourBack => '뒤쪽에';

  @override
  String get tourNext => '다음';

  @override
  String get chooseProgram => '프로그램을 선택하세요';

  @override
  String get installedApps => '설치된 애플리케이션';

  @override
  String get runningProcesses => '실행 중인 프로세스';

  @override
  String get programsEmpty => '애플리케이션을 찾을 수 없습니다';

  @override
  String get selectExe => '.exe 파일을 선택하세요';

  @override
  String get speedtest => '속도';

  @override
  String get speedtestSearch => '서비스 찾기';

  @override
  String get speedtestEmpty => '일치하는 항목이 없습니다';

  @override
  String get speedtestBackToList => '서비스로 돌아가기';

  @override
  String get speedtestOpenBrowser => '브라우저에서 열기';

  @override
  String get speedtestUnavailable => '내장된 브라우저를 시작할 수 없습니다';

  @override
  String get speedtestPageFailed => '페이지를 로드할 수 없습니다';

  @override
  String get speedtestExternalFailed => '시스템 브라우저를 열 수 없습니다';

  @override
  String get modes => '모드';

  @override
  String get proxyShort => '대리';

  @override
  String get tunMode => '모든 트래픽(TUN)';

  @override
  String get checkUpdates => '업데이트 확인';

  @override
  String get updates => '앱 업데이트';

  @override
  String updateAvailable(String version) {
    return '버전 $version를 사용할 수 있습니다';
  }

  @override
  String get updateOpenAbout => '업데이트 보기';

  @override
  String updateNotes(String version) {
    return '$version의 변경 사항';
  }

  @override
  String get updateCheck => '업데이트 확인';

  @override
  String get updateChecking => '확인 중...';

  @override
  String get updateNoNotes => '릴리스에는 메모가 없습니다.';

  @override
  String get updateDropWarning => '업데이트를 위해 연결을 끊을까요?';

  @override
  String get updateWaitConnection => '연결이 준비되지 않았습니다';

  @override
  String get updateNetworkError => '업데이트를 다운로드할 수 없습니다';

  @override
  String get updateReleaseError => '릴리스 데이터 또는 필수 파일이 누락되었거나 잘못되었습니다.';

  @override
  String get updateChecksumError => '다운로드가 SHA256SUMS와 일치하지 않습니다';

  @override
  String get updateInstallError => '업데이트가 완료되지 않았습니다';

  @override
  String get updateUnsupported => '이 실행 파일은 지원되는 Sora 패키지 쌍의 소유가 아닙니다';

  @override
  String get updateVersionRevoked => '개발자가 이 버전을 철회했습니다';

  @override
  String updateRollbacking(String version) {
    return '$version 버전으로 롤백하는 중...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version 업데이트가 상태 검사를 통과하지 못해 Sora가 $fromVersion로 롤백되었습니다.';
  }

  @override
  String get updateRollbackError => '자동 롤백에 실패했습니다';

  @override
  String get updateRollbackCacheError => '현재 버전의 확인된 롤백 복사본을 준비할 수 없어 업데이트가 설치되지 않았습니다.';

  @override
  String get updateCopyCommand => '복사 명령';

  @override
  String get updateInstalled => '업데이트가 설치되었습니다';

  @override
  String get projectLinks => '프로젝트';

  @override
  String get githubReleases => '릴리스 및 다운로드';

  @override
  String get telegramChannel => 'Telegram 채널';

  @override
  String get licenses => '라이센스';

  @override
  String get componentLicenses => '구성요소 라이선스';

  @override
  String get collapseServers => '서버 축소';

  @override
  String get expandServers => '서버 확장';

  @override
  String get hideDescription => '설명 숨기기';

  @override
  String get showDescription => '설명 표시';

  @override
  String get errEngineUnsupported => '선택한 엔진은 이 프로필이나 설정을 지원하지 않습니다';

  @override
  String get errRestore => '연결 정리가 완료되지 않았습니다';

  @override
  String get errSessionEnded => '이 세션은 이미 종료되었습니다';

  @override
  String get retryDisconnect => '연결 해제를 다시 시도하세요.';

  @override
  String get tunStack => 'TUN 스택';

  @override
  String get modesInfo => '모드 정보';

  @override
  String get modesGuideTitle => '모드 및 엔진';

  @override
  String get modesGuide =>
      '서버에 어떤 엔진이 필요한지 확실하지 않은 경우 자동을 선택하십시오. Sora는 연결하기 전에 프로필과 설정을 확인합니다. 엔진은 계획의 대역폭을 늘릴 수 없습니다. 성능은 서버, 경로, 프로토콜 및 네트워크에 따라 다릅니다.\n\n## 모드\n\n### 모든 트래픽(TUN)\n\nSora는 가상 네트워크 인터페이스를 생성하고 이를 통해 TCP 및 UDP를 포함한 애플리케이션 트래픽을 라우팅합니다. Telegram, 게임 및 Discord 음성에 이 모드를 사용하십시오. 규칙은 특정 사이트나 프로그램을 직접 보내거나 차단할 수 있습니다. 네트워크 서비스에는 권한이 필요하며 필요한 프로토콜을 지원하는 서버가 필요합니다.\n\n### System 프록시\n\nSora는 로컬 HTTP/SOCKS 프록시를 구성합니다. 시스템 프록시 설정을 존중하는 응용 프로그램이 이를 사용합니다. 자체 네트워크 스택이 있는 애플리케이션은 직접 연결할 수 있습니다. UDP 및 음성 통화에는 일반적으로 TUN이 필요합니다. 이 모드는 프록시를 지원하는 브라우저 및 애플리케이션에 적합합니다.\n\n### 서버 없음\n\nLinux에서 Sora는 [zapret](https://github.com/bol-van/zapret)를 사용하여 HTTP/TLS 요청을 분할 및 재구성하고 일부 DPI 검사를 우회합니다. 귀하의 IP는 동일하게 유지되며 연결은 웹사이트로 직접 연결됩니다. 결과는 공급자와 차단 방법에 따라 다릅니다.\n\n현재 통합에서는 HTTP 및 TCP를 통한 TLS에 tpws를 사용합니다. IP 차단이나 UDP 중계를 우회하지 않으며 Telegram의 MTProto 연결을 보장할 수 없습니다. Discord 음성, Telegram 통화 및 이러한 종류의 제한 사항에는 TUN이 포함된 VPN 서버를 사용하세요.\n\n## 엔진\n\n### 자동\n\nSora는 서버 프로토콜, 전송, 그룹, 조각화 및 모드 등 전체 연결 계획을 지원하는 설치된 엔진을 선택합니다. 현재 연결을 중단하기 전에 호환되지 않는 수동 선택이 거부됩니다. 자동 또는 다른 엔진을 선택하고 설정을 다시 적용하십시오.\n\n### sing-box\n\n새로운 Sora 패키지에는 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box)의 포크가 포함되어 있으며 클라이언트 측 XHTTP 및 VLESS Encryption가 추가되었습니다. Sora는 ​​빌드와 해당 기능을 인식합니다. XHTTP가 없는 업스트림 빌드는 이름만으로는 이 기능을 얻을 수 없습니다.\n\n지원되는 프로토콜에는 VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard 및 AmneziaWG 1.x/2.x 매개변수가 포함됩니다. Sora는 가져올 수 있습니다. 전체 Xray JSON 프로필에는 Xray가 필요합니다. 새로운 AWG 3.x 필드는 아직 가져올 수 없습니다. sing-box는 컴퓨터의 다른 응용 프로그램이 감지할 수 있는 비밀번호로 보호된 로컬 제어 포트를 사용합니다.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core)는 VLESS, REALITY, XHTTP, VLESS Encryption 및 TLS 조각화를 지원합니다. 또한 라우팅과 그룹을 유지하면서 완전한 공급자 Xray 프로필을 실행합니다. 이러한 프로필은 동작을 변경하지 않고는 자동으로 다른 엔진으로 변환될 수 없습니다.\n\n번들로 제공되는 Xray는 TLS 인증서 확인을 비활성화하는 설정(`allowInsecure`)을 제거했습니다. 이 설정이 필요한 일반 서버에 대해서는 sing-box 또는 mihomo를 자동으로 선택합니다. Xray를 선택하면 현재 연결을 중단하기 전에 비호환성을 수동으로 보고합니다. 이전 전체 JSON 프로필에는 확인 가능한 인증서 또는 인증서 핀이 포함된 업데이트된 공급자 프로필이 필요합니다.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo)는 순서가 지정된 대체 및 로드 밸런싱 그룹인 XHTTP 및 AmneziaWG를 지원합니다. 백업 서버로의 자동 장애 조치가 중요한 경우 선택하세요. 이 엔진에서는 Sora의 TLS 조각화 설정을 사용할 수 없습니다.\n\n## Sora의 호환성\n\n| 기능 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 및 TCP/UDP | 예 | 예 | 예 |\n| XHTTP | 예 | 예 | 예 |\n| VLESS Encryption | 예 | 예 | 예 |\n| 전체 Xray 프로필 | 아니요 | 예 | 아니요 |\n| TUIC / AnyTLS | 둘 다 | 아니요 | TUIC |\n| mieru | 아니요 | 아니요 | 예 |\n| NaiveProxy | 예 | 아니요 | 아니요 |\n| TLS 조각화 | 예 | 예 | 아니요 |\n| AmneziaWG 1.x/2.x | 예1 | 아니요 | 예 |\n| 정렬된 대체 그룹 | 아니요 | 노² | 예 |\n\n¹ J1/J2/J3/Itime가 포함된 프로필은 mihomo를 사용합니다. 이러한 필드는 자동으로 삭제되어서는 안 됩니다. ² 완전한 Xray 프로필 그룹의 경우 앱은 백업 프로필을 선택합니다. 지원은 설치된 빌드에 따라 다릅니다. 정보에서 버전을 확인하세요.\n\n## TUN 스택\n\n스택은 가상 인터페이스 내부에서 TCP 및 UDP를 처리합니다. 모드 패널에서 Xray 및 mihomo는 ​​gVisor, System, Mixed 및 MIPS를 제공합니다. 각 엔진은 고유한 기본 설정을 저장합니다. System 프록시 및 서버리스 모드에서는 이 기본 설정을 사용하지 않습니다.\n\n- **Mixed**: TCP는 시스템 스택을 사용하고 gVisor는 UDP를 처리합니다. Linux에서 mihomo의 기본값입니다. Windows에서는 Xray와 mihomo가 기본적으로 MIPS를 사용합니다.\n- **System**: 시스템 스택을 사용합니다. 네트워크 응용 프로그램에 문제가 발생하면 다른 옵션을 시도해 보십시오.\n- **gVisor**: 사용자 공간의 트래픽을 처리합니다.\n- **MIPS**: mihomo의 자체 IP 스택은 번들 버전 1.19.32에서 사용할 수 있습니다.\n\nLinux에서 Xray는 기본적으로 내장된 gVisor를 사용합니다. Linux의 System, Mixed 및 MIPS는 mihomo를 TUN 엔진으로 사용하여 인증된 로컬 SOCKS 링크를 통해 TCP 및 UDP를 Xray로 전달합니다. Xray는 프로토콜, 공급자 프로필 및 라우팅을 유지합니다. 이 세 가지 옵션에는 mihomo가 설치되어 있어야 합니다. Windows에서 Xray는 네 가지 TUN 스택 모두에 mihomo 1.19.32 이상을 사용합니다. 프로토콜과 라우팅은 Xray가 처리합니다. 이 구성의 앱 규칙은 직접 연결과 차단만 지원합니다. Linux에서는 이러한 규칙에 Xray 내장 gVisor가 필요합니다.\n\n브리지는 두 번째 프로세스를 실행합니다. Linux에 대한 세 가지 유휴 측정에서 기본 Xray TUN보다 약 32~36MiB 더 많은 물리적 메모리를 사용했습니다. 이는 다운로드 로드를 측정하지 않습니다. CPU 및 메모리 비용은 연결에 따라 달라집니다. sing-box에는 스택 선택기가 없습니다. 어떤 스택도 모든 네트워크에서 더 나은 성능을 보장하지 않습니다.\n\n## 설정 적용 중\n\n서버를 선택하면 자동으로 다시 연결됩니다. 직접 변경한 모드, 엔진, DNS 또는 규칙은 잠시 후 자동 재연결하여 한 번만 적용되며, 백그라운드 새로고침은 VPN을 다시 연결하지 않습니다. 엔진을 다시 시작하면 다운로드와 통화가 중단될 수 있습니다.\n\nVPN을 통한 인터넷만 터널이 끊어지면 직접 트래픽을 차단합니다. 이는 전체 기계에 영향을 미칩니다. 명시적인 연결 해제는 Sora의 규칙을 제거합니다. 정리가 완료되지 않으면 연결을 끊고 로그를 다시 열어보세요.\n\n## 프로젝트 문서\n\n- [sing-box-lx: 구성 및 지원](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 문서](https://sing-box.sagernet.org/)\n- [Xray 문서](https://xtls.github.io/)\n- [mihomo 문서](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: 동작 및 제한사항](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC는 Jitsi, Yandex Telemost 또는 WB Stream의 영상 통화를 통해 TCP를 전송합니다. olcrtc:// 링크나 QR 코드를 가져오세요. 프록시 및 TUN 모드에서 sing-box, Xray, mihomo와 함께 작동하며 UDP는 지원하지 않습니다. 양쪽에 호환되는 OLC2 빌드가 필요합니다. 원본 프로젝트는 보관 처리되었습니다.\n';

  @override
  String get probeServers => '핑';

  @override
  String get extensions => '확장';

  @override
  String extRatingLabel(String rating) {
    return '평가 $rating/5';
  }

  @override
  String extByAuthor(String author) {
    return '작성자: $author';
  }

  @override
  String extInstallsCount(String count) {
    return '설치 $count회';
  }

  @override
  String get extInstallOne => '설치 1회';

  @override
  String get extSideloadWarning => '자체 서명 키';

  @override
  String get extPermissionsWidened => '업데이트에서 새 권한을 요청합니다.';

  @override
  String get extInstall => '설치';

  @override
  String get extUpdate => '업데이트';

  @override
  String get extCancel => '취소';

  @override
  String get extConfirm => '확인';

  @override
  String get extCatalog => '카탈로그';

  @override
  String get extInstalled => '설치된 확장 프로그램';

  @override
  String get extSearchHint => '확장 검색';

  @override
  String get extCatAll => '모두';

  @override
  String get extCatTools => '도구';

  @override
  String get extCatThemes => '테마';

  @override
  String get extCatAutomation => '자동화';

  @override
  String get extCatStats => '통계';

  @override
  String get extCatNetwork => '네트워크';

  @override
  String get extSortBy => '정렬 기준';

  @override
  String get extSortPopular => '가장 인기 있는';

  @override
  String get extSortRating => '최고 평점';

  @override
  String get extSortName => '이름';

  @override
  String get extCatalogError => '카탈로그를 로드할 수 없습니다.';

  @override
  String get extRetry => '재시도';

  @override
  String get extEmptySearch => '아무것도 발견되지 않았습니다';

  @override
  String get extEmptyInstalled => '아직 확장 프로그램이 설치되지 않았습니다';

  @override
  String get extInstallFromFile => '파일에서 설치';

  @override
  String get extInstallFromUrl => 'URL에서 설치';

  @override
  String get extDownload => '다운로드';

  @override
  String get extDownloading => '다운로드 중…';

  @override
  String get extVerifying => '확인 중…';

  @override
  String get extInstalling => '설치 중…';

  @override
  String get extErrSignature => '서명 확인에 실패했습니다';

  @override
  String get extErrManifest => '확장 매니페스트가 잘못되었습니다.';

  @override
  String get extErrNetwork => '네트워크 오류입니다';

  @override
  String get extErrHash => '다운로드가 카탈로그와 일치하지 않습니다';

  @override
  String extErrMinApp(String version) {
    return '이 확장 프로그램에는 앱 버전 $version 이상이 필요합니다.';
  }

  @override
  String get extErrHttpsOnly => 'https:// 링크만 허용됩니다.';

  @override
  String get extErrGeneric => '문제가 발생했습니다';

  @override
  String get extErrAuthorKeyChanged => '이 업데이트는 설치된 버전과 다른 작성자 키로 서명되었으므로 차단되었습니다';

  @override
  String get extDisabled => '비활성화됨';

  @override
  String extToggleEnabled(String name) {
    return '$name 활성화';
  }

  @override
  String get extSearchInstalled => '설치된 확장 검색';

  @override
  String get extUpdateAll => '모두 업데이트';

  @override
  String extUpdatesAvailable(int count) {
    return '$count 업데이트 사용 가능';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count 업데이트됨';
  }

  @override
  String get extRiskNormal => '정상';

  @override
  String get extRiskSensitive => '민감함';

  @override
  String get extRiskDangerous => '높은 위험';

  @override
  String get extPermissionsRemoved => '더 이상 요청되지 않음:';

  @override
  String get extUpdateFailedKept => '이전 버전이 아직 설치되어 있습니다.';

  @override
  String get extConflictsTitle => '확장 프로그램 충돌';

  @override
  String get extConflictTheme => '앱 테마';

  @override
  String get extConflictNetHooks => '네트워크 후크';

  @override
  String extConflictWinner(String name) {
    return '$name 승리';
  }

  @override
  String extConflictsCount(int count) {
    return '확장 프로그램 충돌: $count';
  }

  @override
  String get extConflictsResolve => '충돌 해결';

  @override
  String extVersionLabel(String version) {
    return '버전 $version';
  }

  @override
  String get extPermissionsTitle => '권한';

  @override
  String get extNoPermissions => '특별한 권한이 없습니다.';

  @override
  String get extSettings => '설정';

  @override
  String get extSaveSettings => '설정 저장';

  @override
  String extUpdateTo(String version) {
    return '$version(으)로 업그레이드';
  }

  @override
  String get extEnabled => '활성화됨';

  @override
  String extRollbackTo(String version) {
    return '$version으로 롤백';
  }

  @override
  String extRollbackConfirm(String version) {
    return '버전 $version로 롤백하시겠습니까?';
  }

  @override
  String get extUninstall => '제거';

  @override
  String extUninstallConfirm(String name) {
    return '\"$name\" 및 해당 설정을 제거하시겠습니까?';
  }

  @override
  String get extPanelUnavailable => '확장 기능 패널을 사용할 수 없습니다.';

  @override
  String get extPermConnectionsRead => '활성 연결 목록 보기';

  @override
  String get extPermServersRead => '서버 목록 보기';

  @override
  String get extPermSettingsRead => '앱 설정 읽기';

  @override
  String get extPermSettingsWrite => '앱 설정 변경';

  @override
  String get extPermNotifications => '알림 표시';

  @override
  String get extPermTray => '트레이 메뉴에 항목 추가';

  @override
  String get extPermUiPanel => '앱 내부에 패널 표시';

  @override
  String get extPermThemeApply => '테마 적용';

  @override
  String get extPermRoutingRules => '라우팅 규칙 추가';

  @override
  String get extPermNetHooks => '네트워크 경로에 통합';

  @override
  String get extPermNetFetch => '허용 목록에서 URL 요청';

  @override
  String get extPermBackground => '백그라운드 작업 실행';

  @override
  String get extPermNotYetActive => '비활성화됨';

  @override
  String get extCapBackground => '백그라운드에서 실행됩니다.';

  @override
  String get extCapNetHook => '우회 기능 및 네트워크 후크';

  @override
  String get extCapPanel => '패널';

  @override
  String get extCapRouting => '라우팅 규칙';

  @override
  String get extCapTheme => '테마';

  @override
  String get extCapWidget => '위젯';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => '변경 로그';

  @override
  String get extImageFailed => '이미지를 로드할 수 없습니다.';

  @override
  String get extScreenshots => '스크린샷';

  @override
  String get extSortRelevance => '관련성';

  @override
  String get extBgTitle => '백그라운드 작업';

  @override
  String get extBgEnabled => '백그라운드에서 실행';

  @override
  String get extBgInterval => '실행 간격';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count분');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count시간');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => '네트워크 액세스';

  @override
  String extCapNetworkHosts(String hosts) {
    return '네트워크: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return '저장: $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 진단';

  @override
  String get diagnosticNoData => '아직 기록된 요청이 없습니다';

  @override
  String get qrShareTitle => 'QR로 공유';

  @override
  String get qrScanTitle => 'QR 코드 스캔';

  @override
  String get qrCopyLink => '링크 복사';

  @override
  String get qrFromClipboard => '클립보드에서 붙여넣기';

  @override
  String get qrNoCode => '이 이미지에서 QR 코드를 찾을 수 없습니다.';

  @override
  String get qrInvalid => '이 QR 코드에는 유효한 링크가 포함되어 있지 않습니다.';

  @override
  String get qrScan => '스캔 QR';

  @override
  String get qrFromImage => '이미지 열기';

  @override
  String get connGroupByProcess => '프로세스별 그룹화';

  @override
  String get connListView => '목록';

  @override
  String get connCopyHost => '호스트 복사';

  @override
  String get connAddRule => '규칙 추가';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '연결 $count개');
    return '$_temp0';
  }

  @override
  String get dnsPreset => '사전 설정';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => '사용자 지정';

  @override
  String get dnsCheck => '데이터 유출 확인';

  @override
  String get dnsChecking => '확인 중...';

  @override
  String get dnsNoLeak => '누출이 발견되지 않았습니다.';

  @override
  String get dnsLeakFound => '누출이 감지되었습니다.';

  @override
  String get dnsLastCheck => '마지막 확인';

  @override
  String get dnsNeverChecked => '아직 테스트되지 않았습니다.';

  @override
  String get dnsLeakCheckTunnelDns => '터널 DNS 리졸버';

  @override
  String get dnsLeakCheckSystemResolvers => '시스템 리졸버';

  @override
  String get dnsLeakCheckKillSwitchDns => '네트워크 차단을 통한 DNS 보호';

  @override
  String get dnsLeakCheckEncryptedDns => '운영 체제의 암호화 DNS';

  @override
  String get dnsLeakCheckDnsSpoof => '위조된 DNS 응답';

  @override
  String get dnsExpected => '예상됨';

  @override
  String get dnsActual => '관찰됨';

  @override
  String get measureSpeed => '속도 측정';

  @override
  String get benchmarkStale => '오래됨';

  @override
  String get autoSelectMode => '서버 자동 선택';

  @override
  String get autoSelectPing => '가장 빠른 핑';

  @override
  String get autoSelectSpeed => '가장 빠른 속도';

  @override
  String get autoSelectSmart => '현명한 선택';

  @override
  String get coreWatchUnstable => '코어와의 연결이 불안정합니다';

  @override
  String get watchReconnect => '다시 연결';

  @override
  String get crashRestoreTitle => '마지막 세션이 중단되었습니다.';

  @override
  String get restoreOnCrash => '충돌 후 세션 복원';

  @override
  String get crashRestore => '복원';

  @override
  String get crashDismiss => '지금은 아님';

  @override
  String get overrideTitle => '내 편집 내용';

  @override
  String get overrideEdit => '서버 편집';

  @override
  String get overrideHide => '숨기기';

  @override
  String get overrideUnhide => '표시';

  @override
  String get overrideClear => '편집 내용 재설정';

  @override
  String get overrideEmpty => '아직 수정사항이 없습니다.';

  @override
  String get overrideCustomRules => '자체 규칙';

  @override
  String get errBenchmarkUnsupported => '속도를 측정하려면 더 최신 버전의 코어가 필요합니다';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total에서 $done 측정…';
  }

  @override
  String get profiles => '네트워크 프로필';

  @override
  String get profilesEmpty => '아직 프로필이 없습니다';

  @override
  String get profileAdd => '프로필 추가';

  @override
  String get profileName => '프로필 이름';

  @override
  String get profileSsids => 'Wi-Fi 네트워크(SSID)';

  @override
  String get profileGateways => '네트워크 게이트웨이';

  @override
  String get profileAsns => 'AS 번호';

  @override
  String get profileAutoApply => '자동 적용';

  @override
  String get profileSnapshot => '현재 설정 기억';

  @override
  String get profileSnapshotDone => '프로필에 저장된 현재 설정';

  @override
  String get profileDelete => '프로필 삭제';

  @override
  String profileDeleteConfirm(Object name) {
    return '프로필 \"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String profileApplyAsk(Object name) {
    return '프로필 \"$name\"을 적용하시겠습니까?';
  }

  @override
  String get profileApply => '적용';

  @override
  String profileApplied(Object name) {
    return '프로필 \'$name\'이 적용됨';
  }

  @override
  String get profileUndo => '취소';

  @override
  String get profileActive => '활성';

  @override
  String networkNow(Object info) {
    return '현재: $info';
  }

  @override
  String get networkUnknown => '네트워크 정보를 사용할 수 없습니다.';

  @override
  String get profileNoTriggers => '프로필 조건이 없습니다';

  @override
  String get chains => '프록시 체인';

  @override
  String get chainsEmpty => '아직 체인이 없습니다';

  @override
  String get chainAdd => '새 체인';

  @override
  String get chainName => '체인 이름';

  @override
  String get chainTooFew => '체인에는 최소 두 개의 서버가 필요합니다';

  @override
  String get chainTooMany => '체인에는 최대 세 개의 서버만 사용할 수 있습니다';

  @override
  String get chainEstimate => '예상 대기 시간';

  @override
  String get chainSave => '저장 체인';

  @override
  String get chainDelete => '체인 삭제';

  @override
  String chainDeleteConfirm(Object name) {
    return '체인 \"$name\"을 삭제하시겠습니까?';
  }

  @override
  String get chainUnsupported => '선택한 엔진은 체인을 지원하지 않습니다';

  @override
  String get chainHopMissing => '체인의 서버 중 하나를 더 이상 사용할 수 없습니다';

  @override
  String chainHop(Object n) {
    return '홉 $n';
  }

  @override
  String get chainEntry => '입구';

  @override
  String get chainExit => '출구';

  @override
  String get sync => '장치 동기화';

  @override
  String get syncDevices => '내 장치';

  @override
  String get syncEmpty => '페어링된 장치가 없습니다';

  @override
  String get syncPair => '장치 페어링';

  @override
  String get syncShowCode => '내 코드 표시';

  @override
  String get syncScanCode => '스캔 코드';

  @override
  String get syncRevoke => '철회';

  @override
  String syncRevokeConfirm(Object name) {
    return '\"$name\"을(를) 취소하시겠습니까?';
  }

  @override
  String syncLastSync(Object time) {
    return '마지막 동기화: $time';
  }

  @override
  String get syncNever => '절대 안함';

  @override
  String get syncPaired => '장치가 페어링되었습니다';

  @override
  String get syncPairingTitle => '이 장치와 페어링';

  @override
  String get syncWaiting => '다른 장치를 기다리는 중…';

  @override
  String get zapretWithVpn => '우회 DPI 직접 네트워크 트래픽 필터링';

  @override
  String get chainDuplicate => '체인에 같은 서버가 두 번 이상 사용되었습니다';

  @override
  String get edit => '편집';

  @override
  String get remove => '제거';

  @override
  String get autoSwitchOnDegrade => '성능 저하 시 자동 전환';

  @override
  String get tunStackMixed => '혼합';

  @override
  String get tunStackSystem => '시스템';

  @override
  String get customServerAdd => '사용자 정의 서버 추가';

  @override
  String get customServers => '내 서버';

  @override
  String get customServerName => '이름';

  @override
  String get customServerNameRequired => '이름이 없습니다';

  @override
  String get customServerAddress => '주소';

  @override
  String get customServerAddressRequired => '주소가 없습니다';

  @override
  String get customServerAddressInvalid => '잘못된 주소';

  @override
  String get customServerPort => '포트';

  @override
  String get customServerPortInvalid => '잘못된 포트';

  @override
  String get customServerProtocol => '프로토콜';

  @override
  String get customServerCredentials => '로그인 정보';

  @override
  String get customServerShowSecret => '비밀 표시';

  @override
  String get customServerHideSecret => '비밀 숨기기';

  @override
  String customServerDeleteConfirm(String name) {
    return '서버 \"$name\"을 삭제하시겠습니까?';
  }

  @override
  String get leakTestTitle => '데이터 유출 테스트';

  @override
  String get leakTestRun => '확인';

  @override
  String get leakTestCancel => '취소';

  @override
  String leakTestProgress(int count) {
    return '테스트 완료: $count';
  }

  @override
  String get leakTestAllClear => '누출이 발견되지 않았습니다.';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '유출 $count건 발견');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => '수정';

  @override
  String get leakTestCheckDirectDns => '직접 DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP 에코';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => '시스템 리졸버';

  @override
  String get leakTestCheckTunnelConnectivity => '터널 연결';

  @override
  String get leakTestCheckTunnelDns => 'DNS 터널을 통과';

  @override
  String get noticeDegraded => '서버가 느려졌습니다. Sora은 측정 중에 찾은 최적의 서버로 전환했습니다.';

  @override
  String get obfs => '트래픽 난독화';

  @override
  String get syncCodeExpired => '코드가 만료되었습니다';

  @override
  String get syncDaemonFailed => '동기화 서비스를 시작할 수 없습니다.';

  @override
  String get syncDaemonMissing => 'sora-sync 구성 요소를 찾을 수 없습니다';

  @override
  String get syncDaemonStarting => '동기화 서비스를 시작하는 중…';

  @override
  String get syncErrAuth => '동기화 서비스가 액세스 토큰을 거부했습니다';

  @override
  String get syncErrNotFound => '장치가 더 이상 페어링되지 않습니다.';

  @override
  String get syncErrPairingActive => '페어링 세션이 이미 열려 있습니다.';

  @override
  String get syncErrUnreachable => '다른 장치가 응답하지 않았습니다';

  @override
  String get syncError => '동기화 오류';

  @override
  String syncExpiresIn(String duration) {
    return '코드는 $duration 후에 만료됩니다';
  }

  @override
  String get syncJoining => '기기와 페어링 중…';

  @override
  String get syncNewCode => '새 코드';

  @override
  String syncPairedWith(String name) {
    return '은 $name과 페어링됨';
  }

  @override
  String get syncRetry => '반복';

  @override
  String get syncStopShowing => '코드 숨기기';

  @override
  String get syncSyncNow => '지금 동기화';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '수신 $pulled, 전송 $pushed';
  }

  @override
  String get syncResultTitle => '동기화 결과';

  @override
  String get syncPulled => '수신됨';

  @override
  String get syncPushed => '보냄';

  @override
  String get syncNoChanges => '변경 사항이 감지되지 않았습니다.';

  @override
  String get syncDocKindSubscriptions => '구독';

  @override
  String get syncDocKindSettings => '앱 설정';

  @override
  String get syncDocKindOverrides => '신청 설정 재정의';

  @override
  String get syncDocKindProfiles => '네트워크 프로필';

  @override
  String get syncDocKindChains => '프록시 체인';

  @override
  String syncFrom(String name) {
    return '$name에서';
  }

  @override
  String get syncThisDevice => '이 장치';

  @override
  String get syncUnavailableAndroid => 'Android에서는 동기화를 사용할 수 없습니다';

  @override
  String get diagnosticPackets => '패킷 캡처';

  @override
  String get diagnosticEvents => '윈도우 이벤트';

  @override
  String get diagnosticCapture => '10초 동안 캡처';

  @override
  String get diagnosticRequiresTun => '패킷 캡처에는 활성 Sora TUN 연결이 필요합니다.';

  @override
  String get diagnosticUnavailable => '이 플랫폼에서는 이 진단을 사용할 수 없습니다.';

  @override
  String get extErrRevoked => 'Sora 팀이 안전하지 않거나 손상된 이 확장 프로그램 버전을 철회했습니다.';

  @override
  String get extErrRevocationsExpired => '취소 목록이 갱신될 때까지 설치가 차단됩니다.';

  @override
  String extRevokedDisabled(String names) {
    return '철회된 확장 프로그램을 껐습니다: $names';
  }

  @override
  String get customServerWgPrivateKey => '개인 키';

  @override
  String get customServerWgAddresses => '인터페이스 주소';

  @override
  String get customServerWgPeerKey => '서버 공개 키';

  @override
  String get customServerWgPresharedKey => '사전 공유 키';

  @override
  String get customServerWgAllowedIps => '허용된 IP';

  @override
  String get customServerWgKeepalive => 'Keepalive(초)';

  @override
  String get customServerWgKeyInvalid => '잘못된 WireGuard 키';

  @override
  String get customServerWgCidrInvalid => '잘못된 CIDR 접두사';

  @override
  String get customServerWgKeepaliveInvalid => '잘못된 keepalive 간격';

  @override
  String get strictKillSwitch => '엄격한 네트워크 차단';

  @override
  String get strictKillSwitchWarning => '종료 후에도 VPN 외부 트래픽을 차단할까요?';

  @override
  String get extWorkerFailed => '확장 기능의 백그라운드 작업이 실패했습니다';

  @override
  String get extAssetRejected => '확장 프로그램 파일에 읽기 어려운 색상이나 잘못된 규칙이 있습니다';

  @override
  String get extVerifiedSora => 'Sora 인증됨';

  @override
  String extReceivedBytes(String count) {
    return '$count 바이트';
  }

  @override
  String get extOpen => '열기';

  @override
  String get customServerOwn => '개인 서버';

  @override
  String get customServerPaste => '링크 붙여넣기';

  @override
  String get customServerUser => '사용자 이름';

  @override
  String get customServerPassword => '비밀번호';

  @override
  String get customServerSecretRequired => '값이 없습니다';

  @override
  String get customServerLinkInvalid => '잘못된 서버 링크입니다';

  @override
  String get errInternal => 'Sora 내부 오류입니다';

  @override
  String get errTls => '서버 인증서가 거부되었습니다';

  @override
  String get errFileAccess => '파일에 접근할 수 없습니다';

  @override
  String get errDataLimit => '데이터가 너무 많습니다';

  @override
  String get errCredentials => '저장된 인증 정보가 없습니다';

  @override
  String subscriptionStale(String time) {
    return '마지막 업데이트: $time';
  }

  @override
  String get subscriptionNeverUpdated => '아직 업데이트되지 않았습니다';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: '서버가 HTTP $status 코드를 반환했습니다',
      zero: '서버가 요청을 거부했습니다',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => '서버 설정이 불완전하거나 지원되지 않습니다';

  @override
  String get errServerIds => '두 서버의 식별자가 같습니다';

  @override
  String get errRoutingGroup => '경로가 없는 서버나 손상된 그룹을 참조합니다';

  @override
  String get errConnections => '연결 목록을 볼 수 없습니다';

  @override
  String get errLogs => '이 서비스는 로그를 보관하지 않습니다';

  @override
  String get errDiagnostics => '진단을 수집하지 못했습니다';

  @override
  String get errMissingItem => '요청한 항목이 더 이상 없습니다';

  @override
  String get errInvalidRequest => '요청에 잘못된 값이 있습니다';

  @override
  String get errProxyLogin => '시스템 프록시는 이 로그인을 지원하지 않습니다';

  @override
  String get errLogFilter => '로그 필터가 잘못되었습니다';

  @override
  String get errSubRedirect => '서버가 안전하지 않은 주소로 이동시켰습니다';

  @override
  String get errProxySetup => '시스템 프록시를 설정하지 못했습니다';

  @override
  String get notificationsToday => '오늘';

  @override
  String get notificationsYesterday => '어제';

  @override
  String get notificationsMarkRead => '모두 읽음으로 표시';

  @override
  String get notificationsUnread => '읽지 않음';

  @override
  String get desktopNotifications => '데스크톱 알림';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => '구독 업데이트 간격이 올바르지 않습니다';

  @override
  String get errRule => '라우팅 규칙이 올바르지 않습니다';

  @override
  String get errDns => 'DNS 설정이 올바르지 않습니다';

  @override
  String get errEndpoint => '테스트할 서버 주소가 올바르지 않습니다';

  @override
  String get errCancelled => '요청이 취소되었습니다';

  @override
  String get customServerOptions => '연결 설정';

  @override
  String get customServerTransport => '전송';

  @override
  String get customServerSecurity => '보안';

  @override
  String get customServerCipher => '암호화 방식';

  @override
  String get customServerWgInterface => '인터페이스';

  @override
  String get customServerWgPeer => '피어';

  @override
  String extAvailableOn(String platforms) {
    return '지원 플랫폼: $platforms.';
  }

  @override
  String get winwsScopeWarning => '모든 앱의 TCP 트래픽을 변경할까요?';

  @override
  String get winwsRequirements => '이 VPN 모드는 사용할 수 없습니다';
}
