// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SVi extends S {
  SVi([String locale = 'vi']) : super(locale);

  @override
  String get stateOff => 'Không được kết nối';

  @override
  String get stateConnecting => 'Đang kết nối';

  @override
  String get stateConnected => 'Đã kết nối';

  @override
  String get stateReconnecting => 'Đang kết nối lại';

  @override
  String get stateDisconnecting => 'Ngắt kết nối';

  @override
  String get stateFailed => 'Không được kết nối';

  @override
  String get coreMissing => 'Dịch vụ Sora không phản hồi';

  @override
  String get serverAuto => 'Nhanh nhất';

  @override
  String get serverBypass => 'Không có máy chủ';

  @override
  String get addSubscription => 'Thêm đăng ký';

  @override
  String get servers => 'Máy chủ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get subscription => 'Đăng ký';

  @override
  String get subscriptionLink => 'Liên kết đăng ký';

  @override
  String get add => 'Thêm vào';

  @override
  String get refresh => 'Cập nhật';

  @override
  String get rename => 'Đổi tên';

  @override
  String get delete => 'Xóa bỏ';

  @override
  String get cancel => 'Hủy bỏ';

  @override
  String get save => 'Cứu';

  @override
  String get name => 'Tên';

  @override
  String deleteSubscription(String name) {
    return 'Xóa “$name”?';
  }

  @override
  String get routes => 'Tuyến đường';

  @override
  String get presetGlobal => 'Mọi thứ thông qua VPN';

  @override
  String get presetRu => 'Nga trực tiếp';

  @override
  String get presetIr => 'Iran trực tiếp';

  @override
  String get presetCn => 'Trung Quốc trực tiếp';

  @override
  String get blockAds => 'Chặn quảng cáo';

  @override
  String get killSwitch => 'Chỉ Internet thông qua VPN';

  @override
  String get engine => 'Động cơ';

  @override
  String get engineAuto => 'Tự động';

  @override
  String get animations => 'Hoạt hình';

  @override
  String get logs => 'Nhật ký';

  @override
  String get about => 'Về';

  @override
  String get logsAll => 'Tất cả';

  @override
  String get logsImportant => 'Quan trọng';

  @override
  String get logsErrors => 'Lỗi';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get export => 'Lưu vào tập tin';

  @override
  String get clear => 'Thông thoáng';

  @override
  String get logsEmpty => 'Không có gì ở đây';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get notInstalled => 'Chưa được cài đặt';

  @override
  String get sourceCode => 'Mã nguồn';

  @override
  String get license => 'Giấy phép';

  @override
  String usage(String used, String total) {
    return '$used của $total';
  }

  @override
  String until(String date) {
    return 'cho đến $date';
  }

  @override
  String get expired => 'Hết hạn';

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
  String get errGeneric => 'Đã xảy ra lỗi';

  @override
  String get errCore => 'Dịch vụ Sora không phản hồi';

  @override
  String get errAuth => 'Không có quyền truy cập vào dịch vụ Sora';

  @override
  String get errVersion => 'Cập nhật Sora: ứng dụng và dịch vụ là phiên bản khác nhau';

  @override
  String get errBusy => 'Đợi đã, lệnh trước vẫn đang chạy';

  @override
  String get errEngineMissing => 'Không tìm thấy công cụ nào cho máy chủ này';

  @override
  String get errOlcrtcInvalid =>
      'Máy chủ olcRTC này chưa đầy đủ: hãy kiểm tra nhà cung cấp, phương thức truyền, phòng và khóa mã hóa';

  @override
  String get errOlcrtcCombination => 'Nhà cung cấp và phương thức truyền olcRTC này không hoạt động cùng nhau';

  @override
  String get errOlcrtcTokenRequired =>
      'Máy chủ olcRTC này cần mã thông báo tài khoản nhà cung cấp mà liên kết không có';

  @override
  String get errOlcrtcNotConnectable => 'Không thể kết nối tới máy chủ olcRTC này chỉ bằng một liên kết';

  @override
  String get errOlcrtcServerMode => 'Sora chỉ kết nối tới các máy chủ olcRTC và không chạy máy chủ riêng';

  @override
  String get olcrtcTcpOnly => 'Chỉ TCP';

  @override
  String get olcrtcIpv4Only => 'Chỉ IPv4';

  @override
  String get errEngineStart => 'Động cơ không khởi động';

  @override
  String get errEngineStopped => 'Động cơ dừng lại';

  @override
  String get errTunnel => 'Không có quyền tạo kết nối VPN';

  @override
  String get errServers => 'Máy chủ được cấu hình có lỗi';

  @override
  String get errNetwork => 'Không thể truy cập máy chủ';

  @override
  String get errTimeout => 'Máy chủ không trả lời kịp thời';

  @override
  String get errFirewall => 'Không thể chặn internet bên ngoài VPN';

  @override
  String get errSubFetch => 'Không thể tải đăng ký';

  @override
  String get errSubFormat => 'Đây không phải là liên kết đăng ký';

  @override
  String get errSubEmpty => 'Đăng ký không có máy chủ';

  @override
  String get errSubDuplicate => 'Đăng ký này đã được thêm';

  @override
  String get errSubLimit => 'Quá nhiều đăng ký';

  @override
  String get errSubScheme => 'Liên kết phải bắt đầu bằng https://';

  @override
  String get errSecretStore => 'Bộ lưu trữ Sora bị hỏng hoặc không khả dụng';

  @override
  String get errNoServers => 'Thêm đăng ký để kết nối';

  @override
  String get exportText => 'Chữ';

  @override
  String get connections => 'Kết nối';

  @override
  String get close => 'Đóng';

  @override
  String get chainDirect => 'Trực tiếp';

  @override
  String get chainBlocked => 'Bị chặn';

  @override
  String get theme => 'chủ đề';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ánh sáng';

  @override
  String get themeDark => 'Tối tăm';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Sự liên quan';

  @override
  String get sectionNoServer => 'Không có máy chủ';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Chẩn đoán';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Tự động';

  @override
  String get dnsHint => 'Địa chỉ, được phân tách bằng dấu phẩy';

  @override
  String get fragment => 'Phân mảnh TLS';

  @override
  String get fragmentPackets => 'Chia làm gì';

  @override
  String get fragmentLength => 'Kích thước mảnh';

  @override
  String get fragmentInterval => 'Tạm dừng giữa các phần';

  @override
  String get byDefault => 'Mặc định';

  @override
  String get rangeHint => 'Ví dụ: 100-200';

  @override
  String get splitPos => 'Chia vị trí';

  @override
  String get splitPosHint => 'Ví dụ: 1, midsld';

  @override
  String get disorder => 'Sắp xếp lại các phần';

  @override
  String get tlsRecord => 'Tách bản ghi TLS';

  @override
  String get tlsRecordNo => 'KHÔNG';

  @override
  String get tlsRecordSni => 'Tại tên trang web';

  @override
  String get tlsRecordFirst => 'Sau byte đầu tiên';

  @override
  String get hostCase => 'Thay đổi trường hợp máy chủ';

  @override
  String get probeMethod => 'Phương pháp';

  @override
  String get probeAuto => 'Tự động';

  @override
  String get probeEngine => 'Thông qua động cơ';

  @override
  String get probeConnect => 'Chỉ kết nối';

  @override
  String get probeUrl => 'Địa chỉ kiểm tra';

  @override
  String get probeTimeout => 'Chờ đợi';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Đăng ký';

  @override
  String get subscriptionSettings => 'Cài đặt';

  @override
  String get userAgent => 'Tác nhân người dùng';

  @override
  String get autoUpdate => 'Cập nhật tự động';

  @override
  String get updateInterval => 'Bao lâu một lần';

  @override
  String get intervalProvider => 'Như nhà cung cấp yêu cầu';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Cập nhật ngay bây giờ';

  @override
  String get logLevel => 'Ghi lại những gì';

  @override
  String get levelDebug => 'Mọi thứ';

  @override
  String get levelInfo => 'Thường';

  @override
  String get levelWarning => 'Quan trọng';

  @override
  String get levelError => 'Chỉ có lỗi';

  @override
  String get recordDestinations => 'Ghi lại địa chỉ trang web';

  @override
  String get reset => 'Đặt lại cài đặt';

  @override
  String get resetConfirm => 'Đặt lại tất cả cài đặt?';

  @override
  String get resetAction => 'Cài lại';

  @override
  String get invalidValue => 'Giá trị này sẽ không hoạt động';

  @override
  String get website => 'Trang đăng ký';

  @override
  String get providerWebsite => 'Trang web của nhà cung cấp';

  @override
  String get support => 'Ủng hộ';

  @override
  String controlPortQuestion(String engine) {
    return '$engine được điều khiển thông qua một cổng trên máy tính này. Các chương trình khác sẽ có thể cho biết VPN đang bật.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Chọn $engine';
  }

  @override
  String get rules => 'Quy tắc tùy chỉnh';

  @override
  String get ruleAdd => 'Quy tắc mới';

  @override
  String get ruleHint => 'Trang web, IP hoặc chương trình';

  @override
  String get ruleDirect => 'Trực tiếp';

  @override
  String get ruleProxy => 'Thông qua VPN';

  @override
  String get ruleBlock => 'Khối';

  @override
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'Bật thất bại';

  @override
  String get connectOnStart => 'Kết nối khi bắt đầu';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'đăng ký kết thúc sau # ngày',
      one: 'đăng ký kết thúc vào ngày #',
      zero: 'đăng ký sẽ kết thúc sau vài giờ nữa',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left còn lại';
  }

  @override
  String get ruleInvalid => 'Đây không giống một trang web, IP hay một chương trình';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lần lượt các máy chủ #',
      one: 'Lần lượt máy chủ #',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Máy chủ #, nhanh nhất',
      one: 'Máy chủ #, nhanh nhất',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Cách thức';

  @override
  String get tunnelTun => 'Tất cả lưu lượng truy cập';

  @override
  String get tunnelProxy => 'Proxy System';

  @override
  String get proxyAddress => 'Địa chỉ proxy';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get launchAtLogin => 'Bắt đầu với hệ thống';

  @override
  String get launchAtLoginDetail => 'Sora sẽ tự động khởi động khi bạn đăng nhập và nằm ở khay hệ thống.';

  @override
  String get closeToTray => 'Giữ trong khay khi đóng lại';

  @override
  String get notifications => 'Thông báo';

  @override
  String get trayOpen => 'Mở Sora';

  @override
  String get trayConnect => 'Kết nối';

  @override
  String get trayDisconnect => 'Ngắt kết nối';

  @override
  String get trayServer => 'Máy chủ';

  @override
  String get trayQuit => 'Thoát khỏi Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora vẫn còn trong khay';

  @override
  String get noticeInTrayBody => 'Thoát khỏi menu của biểu tượng của nó';

  @override
  String get noticeLost => 'Mất kết nối';

  @override
  String get noticeLostBody => 'Sora đang kết nối lại';

  @override
  String get noticeRestored => 'Đã kết nối lại';

  @override
  String get noticeFailed => 'Không thể kết nối';

  @override
  String get noticeBackup => 'Máy chủ chính không trả lời; bản sao lưu mang lưu lượng truy cập';

  @override
  String get noticeNext => 'Máy chủ không trả lời; chiếc tiếp theo mang theo giao thông';

  @override
  String get noticeMainBack => 'Máy chủ chính trả lời lại và mang lưu lượng';

  @override
  String get noticeSubscription => 'Đăng ký';

  @override
  String get importTitle => 'Thêm đăng ký này?';

  @override
  String get importSealed =>
      'Liên kết này được mã hóa cho Happ và chỉ Happ mới có thể đọc được. Hãy hỏi nhà cung cấp của bạn để có liên kết đăng ký đơn giản.';

  @override
  String get understood => 'ĐƯỢC RỒI';

  @override
  String get noAnswer => 'không có câu trả lời';

  @override
  String get home => 'Trang chủ';

  @override
  String get navRules => 'Quy tắc';

  @override
  String get navConnections => 'Kết nối';

  @override
  String get navLogs => 'Nhật ký';

  @override
  String get navAbout => 'Về';

  @override
  String get sidebarToggle => 'Chuyển đổi thanh bên';

  @override
  String get more => 'Hơn';

  @override
  String get less => 'Ít hơn';

  @override
  String get currentServer => 'Máy chủ hiện tại';

  @override
  String get trafficDown => 'Đã tải xuống';

  @override
  String get trafficUp => 'Đã tải lên';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Quy tắc hoạt động: $count';
  }

  @override
  String get recentNotifications => 'Thông báo gần đây';

  @override
  String get notificationsEmpty => 'Sự kiện kết nối và đăng ký sẽ xuất hiện ở đây';

  @override
  String get retryConnect => 'Thử lại kết nối';

  @override
  String get openLogs => 'Mở nhật ký';

  @override
  String get tourReplay => 'Hiển thị lại hướng dẫn';

  @override
  String tourStep(int step) {
    return 'Bước $step của 5';
  }

  @override
  String get tourBack => 'Mặt sau';

  @override
  String get tourNext => 'Kế tiếp';

  @override
  String get tourSkip => 'Nhảy';

  @override
  String get tourFinish => 'Xong';

  @override
  String get tourAdd => 'Thêm liên kết đăng ký của nhà cung cấp của bạn.';

  @override
  String get tourServer => 'Chọn một máy chủ. “Nhanh nhất” chọn một cho bạn.';

  @override
  String get tourConnect => 'Nhấn vào đây để kết nối hoặc ngắt kết nối.';

  @override
  String get tourMode => 'Chọn một chế độ. Kill switch chặn internet nếu VPN bị rớt.';

  @override
  String get tourSettings => 'Mở cài đặt. Bạn có thể phát lại hướng dẫn này ở đó.';

  @override
  String get chooseProgram => 'Chọn một chương trình';

  @override
  String get installedApps => 'Ứng dụng đã cài đặt';

  @override
  String get runningProcesses => 'Tiến trình đang chạy';

  @override
  String get programsFailed => 'Không thể tải ứng dụng';

  @override
  String get programsEmpty => 'Không tìm thấy ứng dụng nào. Hãy thử một tên khác.';

  @override
  String get selectExe => 'Chọn tệp .exe';

  @override
  String get trafficUnavailable => 'Bộ đếm chưa có sẵn';

  @override
  String get speedtest => 'Tốc độ';

  @override
  String get speedtestCheck => 'Kiểm tra tốc độ';

  @override
  String get speedtestSearch => 'Tìm một dịch vụ';

  @override
  String get speedtestEmpty => 'Không có trận đấu nào. Thay đổi tìm kiếm.';

  @override
  String get speedtestBackToList => 'Quay lại dịch vụ';

  @override
  String get speedtestOpenBrowser => 'Mở trong trình duyệt';

  @override
  String get speedtestUnavailable =>
      'Trình duyệt được nhúng không thể khởi động. Mở dịch vụ trong trình duyệt hệ thống của bạn.';

  @override
  String get speedtestPageFailed =>
      'Trang không thể tải. Tải lại nó hoặc mở dịch vụ trong trình duyệt hệ thống của bạn.';

  @override
  String get speedtestExternalFailed => 'Trình duyệt hệ thống không thể mở được. Hãy thử lại.';

  @override
  String get modes => 'Chế độ';

  @override
  String get proxyShort => 'ủy nhiệm';

  @override
  String get tunMode => 'Tất cả lưu lượng truy cập (TUN)';

  @override
  String get checkUpdates => 'Kiểm tra các bản cập nhật';

  @override
  String get updates => 'Cập nhật ứng dụng';

  @override
  String updateAvailable(String version) {
    return 'Phiên bản $version có sẵn';
  }

  @override
  String get updateOpenAbout => 'Xem cập nhật';

  @override
  String updateNotes(String version) {
    return 'Những thay đổi trong $version';
  }

  @override
  String get updateCheck => 'Kiểm tra các bản cập nhật';

  @override
  String get updateChecking => 'Đang kiểm tra...';

  @override
  String get updateNoNotes => 'Bản phát hành không có ghi chú.';

  @override
  String get updateDropWarning =>
      'Kết nối VPN sẽ bị ngắt trong vài giây trong khi Sora và bản cập nhật cốt lõi của nó. Tiếp tục?';

  @override
  String get updateWaitConnection => 'Đợi kết nối VPN và lõi sẵn sàng.';

  @override
  String get updateDownloading => 'Đang tải xuống và xác minh tệp...';

  @override
  String get updateInstalling => 'Đang chuẩn bị cập nhật hoặc chờ xác thực của quản trị viên...';

  @override
  String get updateNetworkError => 'Không thể tải xuống bản cập nhật. Hãy thử lại.';

  @override
  String get updateReleaseError => 'Dữ liệu phát hành hoặc các tệp được yêu cầu bị thiếu hoặc không hợp lệ.';

  @override
  String get updateChecksumError => 'Nội dung tải xuống không khớp với SHA256SUMS. Không có gì được cài đặt.';

  @override
  String get updateInstallError => 'Cập nhật chưa kết thúc. Xác thực có thể đã bị hủy.';

  @override
  String get updateUnsupported =>
      'Tệp thực thi này không thuộc sở hữu của cặp gói Sora được hỗ trợ. Sử dụng hướng dẫn cài đặt bản phát hành.';

  @override
  String get updateManual =>
      'Chạy lệnh này trong thiết bị đầu cuối để cài đặt cả hai gói đã được xác minh, sau đó mở lại Sora. Các tập tin vẫn ở trong thư mục tải xuống. Kết nối VPN sẽ bị rớt.';

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
  String get updateCopyCommand => 'Sao chép lệnh';

  @override
  String get updateChecksDisabled => 'Kiểm tra tự động bị tắt trong Cài đặt.';

  @override
  String get updateInstalled => 'Đã cài đặt bản cập nhật. Mở lại Sora.';

  @override
  String get projectLinks => 'Dự án';

  @override
  String get githubReleases => 'Phát hành và tải xuống';

  @override
  String get telegramChannel => 'Kênh Telegram';

  @override
  String get licenses => 'Giấy phép';

  @override
  String get componentLicenses => 'Giấy phép thành phần';

  @override
  String get appCopyright => '© 2026 levvs-one và những người đóng góp';

  @override
  String get collapseServers => 'Thu gọn máy chủ';

  @override
  String get expandServers => 'Mở rộng máy chủ';

  @override
  String get hideDescription => 'Ẩn mô tả';

  @override
  String get showDescription => 'Hiển thị mô tả';

  @override
  String get pendingConnectionChanges => 'Kết nối lại để áp dụng những thay đổi này.';

  @override
  String get reconnectNow => 'Áp dụng và kết nối lại';

  @override
  String get bypassLimitations =>
      'Chế độ này chỉ bỏ qua DPI cho HTTP và TLS, không hỗ trợ UDP hoặc thay đổi IP của bạn. Sử dụng máy chủ VPN cho cuộc gọi, cuộc gọi và địa chỉ Telegram bị chặn.';

  @override
  String get errEngineUnsupported =>
      'Công cụ đã chọn không hỗ trợ cấu hình hoặc cài đặt này. Chọn Tự động hoặc động cơ tương thích.';

  @override
  String get errRestore => 'Việc dọn dẹp kết nối chưa hoàn tất. Thử ngắt kết nối lại; xem nhật ký để biết chi tiết.';

  @override
  String get errSessionEnded => 'Phiên này đã kết thúc. Làm mới trạng thái kết nối.';

  @override
  String get retryDisconnect => 'Thử lại việc ngắt kết nối';

  @override
  String get tunStack => 'ngăn xếp TUN';

  @override
  String get modesInfo => 'Về chế độ';

  @override
  String get modesGuideTitle => 'Các chế độ và động cơ';

  @override
  String get modesGuide =>
      'Chọn Tự động nếu bạn không chắc máy chủ của mình cần công cụ nào. Sora kiểm tra cấu hình và cài đặt trước khi kết nối. Công cụ không thể tăng băng thông gói của bạn: hiệu suất phụ thuộc vào máy chủ, tuyến đường, giao thức và mạng.\n\n## Chế độ\n\n### Tất cả lưu lượng truy cập (TUN)\n\nSora tạo giao diện mạng ảo và định tuyến lưu lượng ứng dụng qua đó, bao gồm TCP và UDP. Sử dụng chế độ này cho Telegram, trò chơi và giọng nói Discord. Các quy tắc có thể gửi trực tiếp các trang web hoặc chương trình cụ thể hoặc chặn chúng. Dịch vụ mạng cần có sự cho phép và máy chủ hỗ trợ giao thức được yêu cầu.\n\n### Proxy System\n\nSora định cấu hình proxy HTTP/SOCKS cục bộ. Các ứng dụng tôn trọng cài đặt proxy hệ thống sẽ sử dụng nó. Các ứng dụng có ngăn xếp mạng riêng có thể kết nối trực tiếp; UDP và cuộc gọi thoại thường cần TUN. Chế độ này phù hợp với các trình duyệt và ứng dụng có hỗ trợ proxy.\n\n### Không có máy chủ\n\nTrên Linux, Sora sử dụng [zapret](https://github.com/bol-van/zapret) để phân tách và định hình lại các yêu cầu HTTP/TLS cũng như bỏ qua một số kiểm tra DPI. IP của bạn vẫn giữ nguyên và các kết nối sẽ truy cập trực tiếp vào trang web. Kết quả phụ thuộc vào nhà cung cấp của bạn và phương pháp chặn.\n\nTích hợp hiện tại sử dụng tpws cho HTTP và TLS qua TCP. Nó không bỏ qua việc chặn IP hoặc chuyển tiếp UDP và không thể đảm bảo các kết nối MTProto của Telegram. Sử dụng máy chủ VPN có TUN cho giọng nói Discord, cuộc gọi Telegram và các loại hạn chế này.\n\n## Động cơ\n\n### Tự động\n\nSora chọn một công cụ được cài đặt hỗ trợ toàn bộ gói kết nối: giao thức máy chủ, truyền tải, nhóm, phân mảnh và chế độ. Lựa chọn thủ công không tương thích sẽ bị từ chối trước khi dừng kết nối hiện tại. Chọn Tự động hoặc công cụ khác và áp dụng lại cài đặt.\n\n###sing-box\n\nCác gói Sora mới bao gồm [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), một nhánh của [sing-box](https://github.com/SagerNet/sing-box), thêm XHTTP và VLESS Encryption phía máy khách. Sora công nhận bản dựng và khả năng của nó. Một bản dựng ngược dòng không có XHTTP sẽ không có được khả năng này chỉ từ tên của nó.\n\nCác giao thức được hỗ trợ bao gồm VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard và các tham số AmneziaWG 1.x/2.x Sora có thể nhập. Cấu hình JSON Xray đầy đủ yêu cầu Xray. Chưa thể nhập các trường AWG 3.x mới. sing-box sử dụng cổng điều khiển cục bộ được bảo vệ bằng mật khẩu mà các ứng dụng khác trên máy tính có thể phát hiện.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) hỗ trợ phân mảnh VLESS, REALITY, XHTTP, VLESS Encryption và TLS. Nó cũng chạy các hồ sơ Xray hoàn chỉnh của nhà cung cấp trong khi vẫn bảo toàn định tuyến và nhóm của họ. Những cấu hình như vậy không thể được tự động chuyển đổi sang một công cụ khác mà không thay đổi hành vi của chúng.\n\nXray đi kèm đã xóa cài đặt tắt xác minh chứng chỉ TLS (`allowInsecure`). Tự động chọn sing-box hoặc mihomo cho các máy chủ thông thường yêu cầu cài đặt này. Việc chọn Xray sẽ báo cáo sự không tương thích theo cách thủ công trước khi dừng kết nối hiện tại. Hồ sơ JSON đầy đủ cũ hơn cần hồ sơ nhà cung cấp được cập nhật với chứng chỉ hoặc mã chứng chỉ có thể xác minh được.\n\n###mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) hỗ trợ các nhóm cân bằng tải và dự phòng theo thứ tự, XHTTP và AmneziaWG. Chọn nó khi việc tự động chuyển đổi dự phòng sang máy chủ dự phòng có vấn đề. Cài đặt phân mảnh TLS của Sora không khả dụng với công cụ này.\n\n## Khả năng tương thích trong Sora\n\n| Tính năng | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN và TCP/UDP | Có | Có | Có |\n| XHTTP | Có | Có | Có |\n| VLESS Encryption | Có | Có | Có |\n| Hồ sơ Xray đầy đủ | Không | Có | Không |\n| TUIC / AnyTLS | Cả hai | Không | TUIC |\n| Phân mảnh TLS | Có | Có | Không |\n| AmneziaWG 1.x/2.x | Có¹ | Không | Có |\n| Nhóm dự phòng được đặt hàng | Không | Không có | Có |\n\n¹ Cấu hình có J1/J2/J3/Itime sử dụng mihomo; những trường này không bao giờ được loại bỏ một cách âm thầm. ² Đối với một nhóm cấu hình Xray hoàn chỉnh, ứng dụng sẽ chọn một cấu hình dự phòng. Hỗ trợ tùy thuộc vào bản dựng được cài đặt; kiểm tra phiên bản của nó trong Giới thiệu.\n\n## ngăn xếp TUN\n\nNgăn xếp xử lý TCP và UDP bên trong giao diện ảo. Trong bảng chế độ, Xray và mihomo cung cấp gVisor, System, Mixed và MIPS. Mỗi động cơ lưu tùy chọn riêng của mình. Chế độ proxy và Serverless System không sử dụng tùy chọn này.\n\n- **Mixed** — TCP sử dụng ngăn xếp hệ thống, trong khi gVisor xử lý UDP. Đây là mặc định của mihomo trên Linux. Trên Windows, Xray và mihomo mặc định dùng MIPS.\n- **System** — sử dụng ngăn xếp hệ thống. Hãy thử tùy chọn khác nếu ứng dụng mạng gặp sự cố.\n- **gVisor** — xử lý lưu lượng truy cập trong không gian người dùng.\n- **MIPS** — Ngăn xếp IP riêng của mihomo, có sẵn trong phiên bản đi kèm 1.19.32.\n\nTrên Linux, Xray sử dụng gVisor tích hợp theo mặc định. System, Mixed và MIPS trên Linux sử dụng mihomo làm công cụ TUN, chuyển tiếp TCP và UDP tới Xray qua liên kết SOCKS cục bộ đã được xác thực. Xray giữ lại giao thức, hồ sơ nhà cung cấp và định tuyến. Ba tùy chọn này yêu cầu cài đặt mihomo. Trên Windows, Xray sử dụng mihomo 1.19.32 trở lên cho cả bốn ngăn xếp TUN. Giao thức và định tuyến vẫn do Xray xử lý. Quy tắc ứng dụng trong cấu hình này chỉ hỗ trợ kết nối trực tiếp và chặn; trên Linux, các quy tắc này cần gVisor tích hợp của Xray.\n\nCây cầu chạy một quá trình thứ hai. Trong ba phép đo không hoạt động trên Linux, nó sử dụng bộ nhớ vật lý nhiều hơn khoảng 32–36 MiB so với Xray TUN gốc. Điều này không đo lường tải tải xuống: chi phí CPU và bộ nhớ phụ thuộc vào kết nối. sing-box không có bộ chọn ngăn xếp. Không có ngăn xếp nào đảm bảo hiệu suất tốt hơn trong mọi mạng. Chọn một ngăn xếp rồi chọn Áp dụng và kết nối lại để thử trong mạng của bạn.\n\n## Áp dụng cài đặt\n\nViệc chọn máy chủ sẽ tự động kết nối lại. Cài đặt chế độ, công cụ, DNS và quy tắc được lưu ngay lập tức; trong khi kết nối đang hoạt động, hãy nhấp vào Áp dụng và kết nối lại để sử dụng chúng. Việc khởi động lại công cụ có thể làm gián đoạn quá trình tải xuống và cuộc gọi. Nhấp chuột lặp đi lặp lại không bắt đầu kết nối song song; ngắt kết nối kết thúc quá trình chuyển đổi và giải phóng kết nối.\n\nInternet chỉ thông qua VPN chặn lưu lượng truy cập trực tiếp khi đường hầm bị hỏng. Nó ảnh hưởng đến toàn bộ máy. Việc ngắt kết nối rõ ràng sẽ loại bỏ các quy tắc của Sora. Nếu việc dọn dẹp không hoàn tất, hãy thử ngắt kết nối lại và mở nhật ký.\n\n## Tài liệu dự án\n\n- [sing-box-lx: cấu hình và hỗ trợ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Tài liệu sing-box](https://sing-box.sagernet.org/)\n- [Tài liệu Xray](https://xtls.github.io/)\n- [Tài liệu mihomo](https://wiki.metacubex.one/)\n- [zapret: hoạt động và những hạn chế](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Kiểm tra máy chủ';

  @override
  String get extensions => 'Tiện ích mở rộng';

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
    return 'Lưu vào $name';
  }

  @override
  String get diagnosticHttp => 'Chẩn đoán HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Chưa có yêu cầu nào được ghi lại. Trước tiên hãy mở một trang web kiểm tra tốc độ.';

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
