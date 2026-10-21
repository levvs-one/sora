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
  String get stateFailed => '연결되지 않음';

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
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return '버전 $version';
  }

  @override
  String get notInstalled => '설치되지 않음';

  @override
  String get sourceCode => '소스 코드';

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
  String get errCore => 'Sora 서비스가 응답하지 않습니다.';

  @override
  String get errAuth => 'Sora 서비스에 액세스할 수 없습니다.';

  @override
  String get errVersion => 'Sora 업데이트: 앱과 서비스의 버전이 다릅니다.';

  @override
  String get errBusy => '잠깐, 이전 명령이 아직 실행 중입니다.';

  @override
  String get errEngineMissing => '이 서버에 대한 엔진을 찾을 수 없습니다.';

  @override
  String get errOlcrtcInvalid => '이 olcRTC 서버가 불완전합니다: 제공업체, 전송 방식, 방, 암호화 키를 확인하세요';

  @override
  String get errOlcrtcCombination => '이 olcRTC 제공업체와 전송 방식은 함께 작동하지 않습니다';

  @override
  String get errOlcrtcTokenRequired => '이 olcRTC 서버에는 링크에 없는 제공업체 계정 토큰이 필요합니다';

  @override
  String get errOlcrtcNotConnectable => '이 olcRTC 서버에는 링크만으로 연결할 수 없습니다';

  @override
  String get errOlcrtcServerMode => 'Sora는 olcRTC 서버에 연결만 하며 직접 운영하지 않습니다';

  @override
  String get olcrtcTcpOnly => 'TCP 전용';

  @override
  String get olcrtcIpv4Only => 'IPv4 전용';

  @override
  String get errEngineStart => '엔진이 시동되지 않았습니다';

  @override
  String get errEngineStopped => '엔진이 멈췄다';

  @override
  String get errTunnel => 'VPN 연결을 생성할 수 있는 권한이 없습니다.';

  @override
  String get errServers => '서버가 오류로 구성되었습니다';

  @override
  String get errNetwork => '서버에 연결할 수 없습니다';

  @override
  String get errTimeout => '서버가 제 시간에 응답하지 않았습니다';

  @override
  String get errFirewall => 'VPN 외부의 인터넷을 차단할 수 없습니다';

  @override
  String get errSubFetch => '구독을 로드할 수 없습니다.';

  @override
  String get errSubFormat => '구독링크가 아닙니다';

  @override
  String get errSubEmpty => '구독에 서버가 없습니다.';

  @override
  String get errSubDuplicate => '이 구독은 이미 추가되었습니다.';

  @override
  String get errSubLimit => '구독이 너무 많습니다.';

  @override
  String get errSubScheme => '링크는 https://로 시작해야 합니다.';

  @override
  String get errSecretStore => 'Sora 스토리지가 손상되었거나 사용할 수 없습니다.';

  @override
  String get errNoServers => '연결하려면 구독을 추가하세요.';

  @override
  String get exportText => '텍스트';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => '빛';

  @override
  String get themeDark => '어두운';

  @override
  String get language => '언어';

  @override
  String get languageSystem => 'System';

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
  String get dnsHint => '주소, 쉼표로 구분';

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
  String get rangeHint => '예를 들어 100-200';

  @override
  String get splitPos => '위치 분할';

  @override
  String get splitPosHint => '예: 1, midsld';

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
  String controlPortQuestion(String engine) {
    return '$engine는 이 컴퓨터의 포트를 통해 제어됩니다. 다른 프로그램에서는 VPN이 켜져 있음을 알 수 있습니다.';
  }

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
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => '실패를 켜십시오';

  @override
  String get connectOnStart => '시작 시 연결';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '구독이 #일 후에 종료됩니다',
      one: '구독은 #일에 종료됩니다',
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
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 서버, 차례로', one: '# 서버, 차례로');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '가장 빠른 # 서버', one: '가장 빠른 # 서버');
    return '$_temp0';
  }

  @override
  String get tunnelMode => '방법';

  @override
  String get tunnelTun => '모든 트래픽';

  @override
  String get tunnelProxy => 'System 프록시';

  @override
  String get proxyAddress => '프록시 주소';

  @override
  String get copied => '복사됨';

  @override
  String get launchAtLogin => '시스템으로 시작하세요';

  @override
  String get launchAtLoginDetail => '로그인 시 Sora가 자동으로 시작되어 트레이에 상주합니다.';

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
  String get noticeInTrayBody => '아이콘 메뉴에서 종료';

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
  String get importSealed => '이 링크는 Happ에 대해 암호화되어 있으며 Happ만 읽을 수 있습니다. 일반 구독 링크는 공급자에게 문의하세요.';

  @override
  String get understood => '좋아요';

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
  String get currentServer => '현재 서버';

  @override
  String get trafficDown => '다운로드됨';

  @override
  String get trafficUp => '업로드됨';

  @override
  String perSecond(String value) {
    return '$value/초';
  }

  @override
  String activeRules(int count) {
    return '활성 규칙: $count';
  }

  @override
  String get recentNotifications => '최근 알림';

  @override
  String get notificationsEmpty => '연결 및 구독 이벤트가 여기에 표시됩니다.';

  @override
  String get retryConnect => '연결 재시도';

  @override
  String get openLogs => '로그 열기';

  @override
  String get tourReplay => '가이드 다시 표시';

  @override
  String tourStep(int step) {
    return '5단계 $step';
  }

  @override
  String get tourBack => '뒤쪽에';

  @override
  String get tourNext => '다음';

  @override
  String get tourSkip => '건너뛰다';

  @override
  String get tourFinish => '완료';

  @override
  String get tourAdd => '제공업체의 구독 링크를 추가하세요.';

  @override
  String get tourServer => '서버를 선택하세요. \"가장 빠름\"이 하나를 선택합니다.';

  @override
  String get tourConnect => '연결하거나 연결을 끊으려면 여기를 클릭하세요.';

  @override
  String get tourMode => '모드를 선택하세요. VPN이 끊어지면 킬 스위치가 인터넷을 차단합니다.';

  @override
  String get tourSettings => '설정을 엽니다. 여기서 이 가이드를 다시 재생할 수 있습니다.';

  @override
  String get chooseProgram => '프로그램을 선택하세요';

  @override
  String get installedApps => '설치된 애플리케이션';

  @override
  String get runningProcesses => '실행 중인 프로세스';

  @override
  String get programsFailed => '애플리케이션을 로드할 수 없습니다.';

  @override
  String get programsEmpty => '애플리케이션을 찾을 수 없습니다. 다른 이름을 사용해 보세요.';

  @override
  String get selectExe => '.exe 파일을 선택하세요';

  @override
  String get trafficUnavailable => '카운터는 아직 사용할 수 없습니다.';

  @override
  String get speedtest => '속도';

  @override
  String get speedtestCheck => '속도 확인';

  @override
  String get speedtestSearch => '서비스 찾기';

  @override
  String get speedtestEmpty => '일치하는 항목이 없습니다. 검색을 변경하세요.';

  @override
  String get speedtestBackToList => '서비스로 돌아가기';

  @override
  String get speedtestOpenBrowser => '브라우저에서 열기';

  @override
  String get speedtestUnavailable => '내장된 브라우저를 시작할 수 없습니다. 시스템 브라우저에서 서비스를 엽니다.';

  @override
  String get speedtestPageFailed => '페이지를 로드할 수 없습니다. 다시 로드하거나 시스템 브라우저에서 서비스를 엽니다.';

  @override
  String get speedtestExternalFailed => '시스템 브라우저를 열 수 없습니다. 다시 시도해 보세요.';

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
  String get updateDropWarning => 'Sora 및 핵심 업데이트가 진행되는 동안 VPN 연결이 몇 초 동안 끊어집니다. 계속하다?';

  @override
  String get updateWaitConnection => 'VPN 연결과 코어가 준비될 때까지 기다립니다.';

  @override
  String get updateDownloading => '파일 다운로드 및 확인 중...';

  @override
  String get updateInstalling => '업데이트를 준비 중이거나 관리자 인증을 기다리는 중...';

  @override
  String get updateNetworkError => '업데이트를 다운로드할 수 없습니다. 다시 시도해 보세요.';

  @override
  String get updateReleaseError => '릴리스 데이터 또는 필수 파일이 누락되었거나 잘못되었습니다.';

  @override
  String get updateChecksumError => '다운로드가 SHA256SUMS와 일치하지 않습니다. 아무것도 설치되지 않았습니다.';

  @override
  String get updateInstallError => '업데이트가 완료되지 않았습니다. 인증이 취소되었을 수 있습니다.';

  @override
  String get updateUnsupported => '이 실행 파일은 지원되는 Sora 패키지 쌍의 소유가 아닙니다. 릴리스 설치 지침을 사용하십시오.';

  @override
  String get updateManual => '터미널에서 이 명령을 실행하여 확인된 두 패키지를 모두 설치한 다음 Sora를 다시 엽니다. 파일은 다운로드 디렉터리에 유지됩니다. VPN 연결이 끊어집니다.';

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
  String get updateCopyCommand => '복사 명령';

  @override
  String get updateChecksDisabled => '설정에서 자동 검사가 비활성화되어 있습니다.';

  @override
  String get updateInstalled => '업데이트가 설치되었습니다. Sora를 다시 엽니다.';

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
  String get appCopyright => '© 2026 levvs-one 및 기여자';

  @override
  String get collapseServers => '서버 축소';

  @override
  String get expandServers => '서버 확장';

  @override
  String get hideDescription => '설명 숨기기';

  @override
  String get showDescription => '설명 표시';

  @override
  String get pendingConnectionChanges => '변경사항을 적용하려면 다시 연결하세요.';

  @override
  String get reconnectNow => '적용하고 다시 연결하세요';

  @override
  String get bypassLimitations =>
      '이 모드는 HTTP 및 TLS에 대해서만 DPI를 우회하고 UDP를 지원하지 않으며 IP를 변경하지 않습니다. Discord 음성, 통화 및 차단된 Telegram 주소에 VPN 서버를 사용하세요.';

  @override
  String get errEngineUnsupported => '선택한 엔진은 이 프로필이나 설정을 지원하지 않습니다. 자동 또는 호환 엔진을 선택하세요.';

  @override
  String get errRestore => '연결 정리가 완료되지 않았습니다. 연결 해제를 다시 시도하세요. 자세한 내용은 로그를 참조하세요.';

  @override
  String get errSessionEnded => '이 세션은 이미 종료되었습니다. 연결 상태를 새로 고칩니다.';

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
      '서버에 어떤 엔진이 필요한지 확실하지 않은 경우 자동을 선택하십시오. Sora는 연결하기 전에 프로필과 설정을 확인합니다. 엔진은 계획의 대역폭을 늘릴 수 없습니다. 성능은 서버, 경로, 프로토콜 및 네트워크에 따라 다릅니다.\n\n## 모드\n\n### 모든 트래픽(TUN)\n\nSora는 가상 네트워크 인터페이스를 생성하고 이를 통해 TCP 및 UDP를 포함한 애플리케이션 트래픽을 라우팅합니다. Telegram, 게임 및 Discord 음성에 이 모드를 사용하십시오. 규칙은 특정 사이트나 프로그램을 직접 보내거나 차단할 수 있습니다. 네트워크 서비스에는 권한이 필요하며 필요한 프로토콜을 지원하는 서버가 필요합니다.\n\n### System 프록시\n\nSora는 로컬 HTTP/SOCKS 프록시를 구성합니다. 시스템 프록시 설정을 존중하는 응용 프로그램이 이를 사용합니다. 자체 네트워크 스택이 있는 애플리케이션은 직접 연결할 수 있습니다. UDP 및 음성 통화에는 일반적으로 TUN이 필요합니다. 이 모드는 프록시를 지원하는 브라우저 및 애플리케이션에 적합합니다.\n\n### 서버 없음\n\nLinux에서 Sora는 [zapret](https://github.com/bol-van/zapret)를 사용하여 HTTP/TLS 요청을 분할 및 재구성하고 일부 DPI 검사를 우회합니다. 귀하의 IP는 동일하게 유지되며 연결은 웹사이트로 직접 연결됩니다. 결과는 공급자와 차단 방법에 따라 다릅니다.\n\n현재 통합에서는 HTTP 및 TCP를 통한 TLS에 tpws를 사용합니다. IP 차단이나 UDP 중계를 우회하지 않으며 Telegram의 MTProto 연결을 보장할 수 없습니다. Discord 음성, Telegram 통화 및 이러한 종류의 제한 사항에는 TUN이 포함된 VPN 서버를 사용하세요.\n\n## 엔진\n\n### 자동\n\nSora는 서버 프로토콜, 전송, 그룹, 조각화 및 모드 등 전체 연결 계획을 지원하는 설치된 엔진을 선택합니다. 현재 연결을 중단하기 전에 호환되지 않는 수동 선택이 거부됩니다. 자동 또는 다른 엔진을 선택하고 설정을 다시 적용하십시오.\n\n### sing-box\n\n새로운 Sora 패키지에는 [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), [sing-box](https://github.com/SagerNet/sing-box)의 포크가 포함되어 있으며 클라이언트 측 XHTTP 및 VLESS Encryption가 추가되었습니다. Sora는 ​​빌드와 해당 기능을 인식합니다. XHTTP가 없는 업스트림 빌드는 이름만으로는 이 기능을 얻을 수 없습니다.\n\n지원되는 프로토콜에는 VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard 및 AmneziaWG 1.x/2.x 매개변수가 포함됩니다. Sora는 가져올 수 있습니다. 전체 Xray JSON 프로필에는 Xray가 필요합니다. 새로운 AWG 3.x 필드는 아직 가져올 수 없습니다. sing-box는 컴퓨터의 다른 응용 프로그램이 감지할 수 있는 비밀번호로 보호된 로컬 제어 포트를 사용합니다.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core)는 VLESS, REALITY, XHTTP, VLESS Encryption 및 TLS 조각화를 지원합니다. 또한 라우팅과 그룹을 유지하면서 완전한 공급자 Xray 프로필을 실행합니다. 이러한 프로필은 동작을 변경하지 않고는 자동으로 다른 엔진으로 변환될 수 없습니다.\n\n번들로 제공되는 Xray는 TLS 인증서 확인을 비활성화하는 설정(`allowInsecure`)을 제거했습니다. 이 설정이 필요한 일반 서버에 대해서는 sing-box 또는 mihomo를 자동으로 선택합니다. Xray를 선택하면 현재 연결을 중단하기 전에 비호환성을 수동으로 보고합니다. 이전 전체 JSON 프로필에는 확인 가능한 인증서 또는 인증서 핀이 포함된 업데이트된 공급자 프로필이 필요합니다.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo)는 순서가 지정된 대체 및 로드 밸런싱 그룹인 XHTTP 및 AmneziaWG를 지원합니다. 백업 서버로의 자동 장애 조치가 중요한 경우 선택하세요. 이 엔진에서는 Sora의 TLS 조각화 설정을 사용할 수 없습니다.\n\n## Sora의 호환성\n\n| 기능 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN 및 TCP/UDP | 예 | 예 | 예 |\n| XHTTP | 예 | 예 | 예 |\n| VLESS Encryption | 예 | 예 | 예 |\n| 전체 Xray 프로필 | 아니요 | 예 | 아니요 |\n| TUIC / AnyTLS | 둘 다 | 아니요 | TUIC |\n| TLS 조각화 | 예 | 예 | 아니요 |\n| AmneziaWG 1.x/2.x | 예1 | 아니요 | 예 |\n| 정렬된 대체 그룹 | 아니요 | 노² | 예 |\n\n¹ J1/J2/J3/Itime가 포함된 프로필은 mihomo를 사용합니다. 이러한 필드는 자동으로 삭제되어서는 안 됩니다. ² 완전한 Xray 프로필 그룹의 경우 앱은 백업 프로필을 선택합니다. 지원은 설치된 빌드에 따라 다릅니다. 정보에서 버전을 확인하세요.\n\n## TUN 스택\n\n스택은 가상 인터페이스 내부에서 TCP 및 UDP를 처리합니다. 모드 패널에서 Xray 및 mihomo는 ​​gVisor, System, Mixed 및 MIPS를 제공합니다. 각 엔진은 고유한 기본 설정을 저장합니다. System 프록시 및 서버리스 모드에서는 이 기본 설정을 사용하지 않습니다.\n\n- **Mixed** — TCP는 시스템 스택을 사용하고 gVisor는 UDP를 처리합니다. Linux에서 mihomo의 기본값입니다. Windows에서는 Xray와 mihomo가 기본적으로 MIPS를 사용합니다.\n- **System** — 시스템 스택을 사용합니다. 네트워크 응용 프로그램에 문제가 발생하면 다른 옵션을 시도해 보십시오.\n- **gVisor** — 사용자 공간의 트래픽을 처리합니다.\n- **MIPS** — mihomo의 자체 IP 스택은 번들 버전 1.19.32에서 사용할 수 있습니다.\n\nLinux에서 Xray는 기본적으로 내장된 gVisor를 사용합니다. Linux의 System, Mixed 및 MIPS는 mihomo를 TUN 엔진으로 사용하여 인증된 로컬 SOCKS 링크를 통해 TCP 및 UDP를 Xray로 전달합니다. Xray는 프로토콜, 공급자 프로필 및 라우팅을 유지합니다. 이 세 가지 옵션에는 mihomo가 설치되어 있어야 합니다. Windows에서 Xray는 네 가지 TUN 스택 모두에 mihomo 1.19.32 이상을 사용합니다. 프로토콜과 라우팅은 Xray가 처리합니다. 이 구성의 앱 규칙은 직접 연결과 차단만 지원합니다. Linux에서는 이러한 규칙에 Xray 내장 gVisor가 필요합니다.\n\n브리지는 두 번째 프로세스를 실행합니다. Linux에 대한 세 가지 유휴 측정에서 기본 Xray TUN보다 약 32~36MiB 더 많은 물리적 메모리를 사용했습니다. 이는 다운로드 로드를 측정하지 않습니다. CPU 및 메모리 비용은 연결에 따라 달라집니다. sing-box에는 스택 선택기가 없습니다. 어떤 스택도 모든 네트워크에서 더 나은 성능을 보장하지 않습니다. 스택을 선택하고 적용 및 다시 연결을 선택하여 네트워크에서 사용해 보세요.\n\n## 설정 적용 중\n\n서버를 선택하면 자동으로 다시 연결됩니다. 모드, 엔진, DNS 및 규칙 설정은 즉시 저장됩니다. 활성 연결 중에 적용을 클릭하고 다시 연결하여 사용하세요. 엔진을 다시 시작하면 다운로드 및 호출이 중단될 수 있습니다. 반복해서 클릭해도 병렬 연결이 시작되지 않습니다. 연결을 끊으면 전환이 종료되고 연결이 해제됩니다.\n\nVPN을 통한 인터넷만 터널이 끊어지면 직접 트래픽을 차단합니다. 이는 전체 기계에 영향을 미칩니다. 명시적인 연결 해제는 Sora의 규칙을 제거합니다. 정리가 완료되지 않으면 연결을 끊고 로그를 다시 열어보세요.\n\n## 프로젝트 문서\n\n- [sing-box-lx: 구성 및 지원](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box 문서](https://sing-box.sagernet.org/)\n- [Xray 문서](https://xtls.github.io/)\n- [mihomo 문서](https://wiki.metacubex.one/)\n- [zapret: 동작 및 제한사항](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => '서버 확인';

  @override
  String get extensions => '확장';

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
  String get extPermBypassRead => 'See the DPI-bypass state and capabilities';

  @override
  String get extPermBypassWrite => 'Change the DPI-bypass strategy (affects how traffic is reshaped)';

  @override
  String get extPermBypassTune => 'Run automatic DPI-bypass tuning (probes the network)';

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
    return '저장: $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 진단';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => '아직 기록된 요청이 없습니다. 먼저 속도 테스트 웹사이트를 열어보세요.';

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
