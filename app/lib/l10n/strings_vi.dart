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
  String get connEmpty => 'Không có kết nối';

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
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Ánh sáng';

  @override
  String get themeDark => 'Tối tăm';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

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
  String get programsEmpty => 'Không tìm thấy ứng dụng nào. Hãy thử một tên khác.';

  @override
  String get selectExe => 'Chọn tệp .exe';

  @override
  String get speedtest => 'Tốc độ';

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
  String get updateSignaturePending => 'Tệp cập nhật được đối chiếu với checksum công bố kèm bản phát hành.';

  @override
  String get updateManualSigWarning =>
      'Các tệp dưới đây khớp với checksum của bản phát hành. Hãy chạy lệnh nếu bạn tải chúng từ bản phát hành chính thức.';

  @override
  String get updateVersionRevoked => 'Nhà phát triển đã rút phiên bản này. Vui lòng chờ bản phát hành được sửa chữa.';

  @override
  String get updateRolloutPending =>
      'Một phiên bản mới hơn đang được triển khai dần dần và sẽ tự động được cung cấp cho bạn.';

  @override
  String updateRollbacking(String version) {
    return 'Quay lại phiên bản $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Bản cập nhật cho $version không vượt qua được quá trình kiểm tra tình trạng nên Sora đã được khôi phục về $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Tự động khôi phục không thành công. Nếu phiên bản mới không hoạt động, hãy cài đặt lại bản phát hành trước đó theo cách thủ công.';

  @override
  String get updateRollbackCacheError =>
      'Không thể chuẩn bị bản sao khôi phục đã được xác minh của phiên bản hiện tại, do đó bản cập nhật chưa được cài đặt.';

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
      'Chọn Tự động nếu bạn không chắc máy chủ của mình cần công cụ nào. Sora kiểm tra cấu hình và cài đặt trước khi kết nối. Công cụ không thể tăng băng thông gói của bạn: hiệu suất phụ thuộc vào máy chủ, tuyến đường, giao thức và mạng.\n\n## Chế độ\n\n### Tất cả lưu lượng truy cập (TUN)\n\nSora tạo giao diện mạng ảo và định tuyến lưu lượng ứng dụng qua đó, bao gồm TCP và UDP. Sử dụng chế độ này cho Telegram, trò chơi và giọng nói Discord. Các quy tắc có thể gửi trực tiếp các trang web hoặc chương trình cụ thể hoặc chặn chúng. Dịch vụ mạng cần có sự cho phép và máy chủ hỗ trợ giao thức được yêu cầu.\n\n### Proxy System\n\nSora định cấu hình proxy HTTP/SOCKS cục bộ. Các ứng dụng tôn trọng cài đặt proxy hệ thống sẽ sử dụng nó. Các ứng dụng có ngăn xếp mạng riêng có thể kết nối trực tiếp; UDP và cuộc gọi thoại thường cần TUN. Chế độ này phù hợp với các trình duyệt và ứng dụng có hỗ trợ proxy.\n\n### Không có máy chủ\n\nTrên Linux, Sora sử dụng [zapret](https://github.com/bol-van/zapret) để phân tách và định hình lại các yêu cầu HTTP/TLS cũng như bỏ qua một số kiểm tra DPI. IP của bạn vẫn giữ nguyên và các kết nối sẽ truy cập trực tiếp vào trang web. Kết quả phụ thuộc vào nhà cung cấp của bạn và phương pháp chặn.\n\nTích hợp hiện tại sử dụng tpws cho HTTP và TLS qua TCP. Nó không bỏ qua việc chặn IP hoặc chuyển tiếp UDP và không thể đảm bảo các kết nối MTProto của Telegram. Sử dụng máy chủ VPN có TUN cho giọng nói Discord, cuộc gọi Telegram và các loại hạn chế này.\n\n## Động cơ\n\n### Tự động\n\nSora chọn một công cụ được cài đặt hỗ trợ toàn bộ gói kết nối: giao thức máy chủ, truyền tải, nhóm, phân mảnh và chế độ. Lựa chọn thủ công không tương thích sẽ bị từ chối trước khi dừng kết nối hiện tại. Chọn Tự động hoặc công cụ khác và áp dụng lại cài đặt.\n\n###sing-box\n\nCác gói Sora mới bao gồm [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), một nhánh của [sing-box](https://github.com/SagerNet/sing-box), thêm XHTTP và VLESS Encryption phía máy khách. Sora công nhận bản dựng và khả năng của nó. Một bản dựng ngược dòng không có XHTTP sẽ không có được khả năng này chỉ từ tên của nó.\n\nCác giao thức được hỗ trợ bao gồm VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard và các tham số AmneziaWG 1.x/2.x Sora có thể nhập. Cấu hình JSON Xray đầy đủ yêu cầu Xray. Chưa thể nhập các trường AWG 3.x mới. sing-box sử dụng cổng điều khiển cục bộ được bảo vệ bằng mật khẩu mà các ứng dụng khác trên máy tính có thể phát hiện.\n\n###Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) hỗ trợ phân mảnh VLESS, REALITY, XHTTP, VLESS Encryption và TLS. Nó cũng chạy các hồ sơ Xray hoàn chỉnh của nhà cung cấp trong khi vẫn bảo toàn định tuyến và nhóm của họ. Những cấu hình như vậy không thể được tự động chuyển đổi sang một công cụ khác mà không thay đổi hành vi của chúng.\n\nXray đi kèm đã xóa cài đặt tắt xác minh chứng chỉ TLS (`allowInsecure`). Tự động chọn sing-box hoặc mihomo cho các máy chủ thông thường yêu cầu cài đặt này. Việc chọn Xray sẽ báo cáo sự không tương thích theo cách thủ công trước khi dừng kết nối hiện tại. Hồ sơ JSON đầy đủ cũ hơn cần hồ sơ nhà cung cấp được cập nhật với chứng chỉ hoặc mã chứng chỉ có thể xác minh được.\n\n###mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) hỗ trợ các nhóm cân bằng tải và dự phòng theo thứ tự, XHTTP và AmneziaWG. Chọn nó khi việc tự động chuyển đổi dự phòng sang máy chủ dự phòng có vấn đề. Cài đặt phân mảnh TLS của Sora không khả dụng với công cụ này.\n\n## Khả năng tương thích trong Sora\n\n| Tính năng | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN và TCP/UDP | Có | Có | Có |\n| XHTTP | Có | Có | Có |\n| VLESS Encryption | Có | Có | Có |\n| Hồ sơ Xray đầy đủ | Không | Có | Không |\n| TUIC / AnyTLS | Cả hai | Không | TUIC |\n| Phân mảnh TLS | Có | Có | Không |\n| AmneziaWG 1.x/2.x | Có¹ | Không | Có |\n| Nhóm dự phòng được đặt hàng | Không | Không có | Có |\n\n¹ Cấu hình có J1/J2/J3/Itime sử dụng mihomo; những trường này không bao giờ được loại bỏ một cách âm thầm. ² Đối với một nhóm cấu hình Xray hoàn chỉnh, ứng dụng sẽ chọn một cấu hình dự phòng. Hỗ trợ tùy thuộc vào bản dựng được cài đặt; kiểm tra phiên bản của nó trong Giới thiệu.\n\n## ngăn xếp TUN\n\nNgăn xếp xử lý TCP và UDP bên trong giao diện ảo. Trong bảng chế độ, Xray và mihomo cung cấp gVisor, System, Mixed và MIPS. Mỗi động cơ lưu tùy chọn riêng của mình. Chế độ proxy và Serverless System không sử dụng tùy chọn này.\n\n- **Mixed**: TCP sử dụng ngăn xếp hệ thống, trong khi gVisor xử lý UDP. Đây là mặc định của mihomo trên Linux. Trên Windows, Xray và mihomo mặc định dùng MIPS.\n- **System**: sử dụng ngăn xếp hệ thống. Hãy thử tùy chọn khác nếu ứng dụng mạng gặp sự cố.\n- **gVisor**: xử lý lưu lượng truy cập trong không gian người dùng.\n- **MIPS**: Ngăn xếp IP riêng của mihomo, có sẵn trong phiên bản đi kèm 1.19.32.\n\nTrên Linux, Xray sử dụng gVisor tích hợp theo mặc định. System, Mixed và MIPS trên Linux sử dụng mihomo làm công cụ TUN, chuyển tiếp TCP và UDP tới Xray qua liên kết SOCKS cục bộ đã được xác thực. Xray giữ lại giao thức, hồ sơ nhà cung cấp và định tuyến. Ba tùy chọn này yêu cầu cài đặt mihomo. Trên Windows, Xray sử dụng mihomo 1.19.32 trở lên cho cả bốn ngăn xếp TUN. Giao thức và định tuyến vẫn do Xray xử lý. Quy tắc ứng dụng trong cấu hình này chỉ hỗ trợ kết nối trực tiếp và chặn; trên Linux, các quy tắc này cần gVisor tích hợp của Xray.\n\nCây cầu chạy một quá trình thứ hai. Trong ba phép đo không hoạt động trên Linux, nó sử dụng bộ nhớ vật lý nhiều hơn khoảng 32–36 MiB so với Xray TUN gốc. Điều này không đo lường tải tải xuống: chi phí CPU và bộ nhớ phụ thuộc vào kết nối. sing-box không có bộ chọn ngăn xếp. Không có ngăn xếp nào đảm bảo hiệu suất tốt hơn trong mọi mạng. Chọn một ngăn xếp rồi chọn Áp dụng và kết nối lại để thử trong mạng của bạn.\n\n## Áp dụng cài đặt\n\nViệc chọn máy chủ sẽ tự động kết nối lại. Cài đặt chế độ, công cụ, DNS và quy tắc được lưu ngay lập tức; trong khi kết nối đang hoạt động, hãy nhấp vào Áp dụng và kết nối lại để sử dụng chúng. Việc khởi động lại công cụ có thể làm gián đoạn quá trình tải xuống và cuộc gọi. Nhấp chuột lặp đi lặp lại không bắt đầu kết nối song song; ngắt kết nối kết thúc quá trình chuyển đổi và giải phóng kết nối.\n\nInternet chỉ thông qua VPN chặn lưu lượng truy cập trực tiếp khi đường hầm bị hỏng. Nó ảnh hưởng đến toàn bộ máy. Việc ngắt kết nối rõ ràng sẽ loại bỏ các quy tắc của Sora. Nếu việc dọn dẹp không hoàn tất, hãy thử ngắt kết nối lại và mở nhật ký.\n\n## Tài liệu dự án\n\n- [sing-box-lx: cấu hình và hỗ trợ](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Tài liệu sing-box](https://sing-box.sagernet.org/)\n- [Tài liệu Xray](https://xtls.github.io/)\n- [Tài liệu mihomo](https://wiki.metacubex.one/)\n- [zapret: hoạt động và những hạn chế](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Kiểm tra máy chủ';

  @override
  String get extensions => 'Tiện ích mở rộng';

  @override
  String extRatingLabel(String rating) {
    return 'Xếp hạng $rating trên 5';
  }

  @override
  String extByAuthor(String author) {
    return 'bởi $author';
  }

  @override
  String extInstallsCount(String count) {
    return '$count lượt cài đặt';
  }

  @override
  String get extInstallOne => '1 lượt cài đặt';

  @override
  String get extSideloadWarning => 'Chỉ cài đặt nếu bạn tin tưởng khóa tự ký của tác giả.';

  @override
  String get extPermissionsWidened => 'Bản cập nhật yêu cầu quyền mới:';

  @override
  String get extDangerousAck => 'Tôi hiểu rằng những quyền này là nghiêm trọng';

  @override
  String get extInstall => 'Cài đặt';

  @override
  String get extUpdate => 'Cập nhật';

  @override
  String get extCancel => 'Hủy';

  @override
  String get extConfirm => 'Xác nhận';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Danh mục';

  @override
  String get extInstalled => 'Tiện ích mở rộng đã cài đặt';

  @override
  String get extSearchHint => 'Tìm tiện ích mở rộng';

  @override
  String get extCatAll => 'Tất cả';

  @override
  String get extCatTools => 'Dụng cụ';

  @override
  String get extCatThemes => 'Giao diện';

  @override
  String get extCatAutomation => 'Tự động hóa';

  @override
  String get extCatStats => 'Thống kê';

  @override
  String get extCatNetwork => 'Mạng';

  @override
  String get extSortBy => 'Sắp xếp theo';

  @override
  String get extSortPopular => 'Phổ biến nhất';

  @override
  String get extSortRating => 'Được đánh giá cao nhất';

  @override
  String get extSortName => 'Tên';

  @override
  String get extCatalogError => 'Không thể tải danh mục';

  @override
  String get extRetry => 'Thử lại';

  @override
  String get extEmptySearch => 'Không tìm thấy gì';

  @override
  String get extEmptyInstalled =>
      'Chưa cài đặt tiện ích mở rộng nào.\nTìm một cái trong danh mục hoặc cài đặt từ một tập tin.';

  @override
  String get extInstallFromFile => 'Cài đặt từ tập tin';

  @override
  String get extInstallFromUrl => 'Cài đặt từ URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Tải xuống';

  @override
  String get extDownloading => 'Đang tải xuống…';

  @override
  String get extVerifying => 'Đang xác minh…';

  @override
  String get extInstalling => 'Đang cài đặt…';

  @override
  String get extInstallFailed => 'Cài đặt không thành công';

  @override
  String get extErrSignature => 'Kiểm tra chữ ký không thành công. Tệp có thể bị hỏng hoặc bị giả mạo.';

  @override
  String get extErrManifest => 'Tệp kê khai tiện ích mở rộng không hợp lệ.';

  @override
  String get extErrNetwork => 'Lỗi mạng. Hãy kiểm tra kết nối của bạn và thử lại.';

  @override
  String get extErrHash => 'Bản tải xuống không khớp với danh mục. Nó có thể đã bị giả mạo.';

  @override
  String extErrMinApp(String version) {
    return 'Tiện ích mở rộng này cần phiên bản ứng dụng $version hoặc mới hơn.';
  }

  @override
  String get extErrHttpsOnly => 'Chỉ cho phép liên kết https://';

  @override
  String get extErrGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get extErrAuthorKeyChanged =>
      'Bản cập nhật này được ký bằng khóa tác giả khác với phiên bản đã cài đặt nên đã bị chặn. Nếu bạn tin cậy khóa mới, hãy gỡ cài đặt tiện ích mở rộng và cài đặt lại một cách rõ ràng.';

  @override
  String get extDisabled => 'Đã tắt';

  @override
  String extToggleEnabled(String name) {
    return 'Kích hoạt $name';
  }

  @override
  String get extSearchInstalled => 'Tìm tiện ích đã cài đặt';

  @override
  String get extUpdateAll => 'Cập nhật tất cả';

  @override
  String extUpdatesAvailable(int count) {
    return '$count có bản cập nhật';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count đã cập nhật';
  }

  @override
  String get extRiskNormal => 'Bình thường';

  @override
  String get extRiskSensitive => 'Nhạy cảm';

  @override
  String get extRiskDangerous => 'Rủi ro cao';

  @override
  String get extPermissionsRemoved => 'Không còn được yêu cầu:';

  @override
  String get extUpdateFailedKept => 'Phiên bản trước đó vẫn được cài đặt.';

  @override
  String get extConflictsTitle => 'Xung đột tiện ích mở rộng';

  @override
  String get extConflictTheme => 'Chủ đề ứng dụng';

  @override
  String get extConflictNetHooks => 'Móc mạng';

  @override
  String extConflictWinner(String name) {
    return '$name thắng';
  }

  @override
  String extConflictsCount(int count) {
    return '$count xung đột cần bạn quyết định';
  }

  @override
  String get extConflictsResolve => 'Giải quyết xung đột';

  @override
  String extVersionLabel(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get extPermissionsTitle => 'Quyền';

  @override
  String get extNoPermissions => 'Không có quyền đặc biệt.';

  @override
  String get extSettings => 'Cài đặt';

  @override
  String get extSaveSettings => 'Lưu cài đặt';

  @override
  String extUpdateTo(String version) {
    return 'Nâng cấp lên $version';
  }

  @override
  String get extEnabled => 'Đã bật';

  @override
  String extRollbackTo(String version) {
    return 'Quay lại $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Quay lại phiên bản $version?';
  }

  @override
  String get extUninstall => 'Gỡ cài đặt';

  @override
  String extUninstallConfirm(String name) {
    return 'Xóa “$name” và các cài đặt của nó?';
  }

  @override
  String get extPanelUnavailable => 'Bảng tiện ích không khả dụng.';

  @override
  String get extPermConnectionsRead => 'Xem danh sách các kết nối đang hoạt động';

  @override
  String get extPermServersRead => 'Xem danh sách máy chủ của bạn';

  @override
  String get extPermSettingsRead => 'Đọc cài đặt ứng dụng';

  @override
  String get extPermSettingsWrite => 'Thay đổi cài đặt ứng dụng';

  @override
  String get extPermNotifications => 'Hiển thị thông báo';

  @override
  String get extPermTray => 'Thêm các mục vào menu khay';

  @override
  String get extPermUiPanel => 'Hiển thị các bảng bên trong ứng dụng';

  @override
  String get extPermThemeApply => 'Áp dụng chủ đề';

  @override
  String get extPermRoutingRules => 'Thêm quy tắc định tuyến (ảnh hưởng đến nơi lưu lượng truy cập mạng đi)';

  @override
  String get extPermNetHooks => 'Tích hợp vào đường dẫn mạng (DPI mô-đun bỏ qua)';

  @override
  String get extPermNetFetch => 'Yêu cầu URL từ danh sách được phép';

  @override
  String get extPermBackground => 'Chạy các tác vụ nền';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Chạy ở chế độ nền';

  @override
  String get extCapNetHook => 'Vượt chặn và hook mạng';

  @override
  String get extCapPanel => 'Bảng giao diện';

  @override
  String get extCapRouting => 'Quy tắc định tuyến';

  @override
  String get extCapTheme => 'Giao diện';

  @override
  String get extCapWidget => 'Widget';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Nhật ký thay đổi';

  @override
  String get extImageFailed => 'Không thể tải hình ảnh';

  @override
  String get extScreenshots => 'Ảnh chụp màn hình';

  @override
  String get extSortRelevance => 'Mức độ liên quan';

  @override
  String get extPermNetworkDetail => 'Yêu cầu qua VPN chỉ được phép đến các máy chủ bên dưới.';

  @override
  String get extBgTitle => 'Tác vụ nền';

  @override
  String get extBgEnabled => 'Chạy ở chế độ nền';

  @override
  String get extBgInterval => 'Chạy mỗi';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# phút');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# giờ');
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Kích hoạt tiện ích mở rộng để quản lý tác vụ nền của nó.';

  @override
  String get extCapNetwork => 'Truy cập mạng';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Mạng: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Lưu vào $name';
  }

  @override
  String get diagnosticHttp => 'Chẩn đoán HTTP';

  @override
  String get diagnosticNoData => 'Chưa có yêu cầu nào được ghi lại. Trước tiên hãy mở một trang web kiểm tra tốc độ.';

  @override
  String get qrShareTitle => 'Chia sẻ mã QR';

  @override
  String get qrScanTitle => 'Quét mã QR';

  @override
  String get qrCopyLink => 'Sao chép liên kết';

  @override
  String get qrShowLink => 'Hiển thị liên kết';

  @override
  String get qrHideLink => 'Ẩn liên kết';

  @override
  String get qrWarning => 'Mã QR này chứa chi tiết kết nối. Đừng cho người lạ xem.';

  @override
  String get qrScanHint => 'Chọn ảnh chụp màn hình hoặc ảnh có mã QR, hoặc dán liên kết';

  @override
  String get qrFromClipboard => 'Dán từ bảng nhớ tạm';

  @override
  String get qrNoCode => 'Không tìm thấy mã QR trong hình ảnh này.';

  @override
  String get qrInvalid => 'Mã QR này không chứa liên kết hợp lệ.';

  @override
  String get qrScan => 'Quét QR';

  @override
  String get qrFromImage => 'Mở hình ảnh';

  @override
  String get connGroupByProcess => 'Nhóm theo quy trình';

  @override
  String get connListView => 'Danh sách';

  @override
  String get connCopyHost => 'Sao chép máy chủ';

  @override
  String get connAddRule => 'Thêm quy tắc';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# kết nối');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'cài sẵn';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Tùy chỉnh';

  @override
  String get dnsCheck => 'Kiểm tra rò rỉ dữ liệu';

  @override
  String get dnsChecking => 'Đang kiểm tra...';

  @override
  String get dnsNoLeak => 'Không tìm thấy rò rỉ';

  @override
  String get dnsLeakFound => 'Phát hiện rò rỉ';

  @override
  String get dnsLastCheck => 'Kiểm tra lần cuối';

  @override
  String get dnsNeverChecked => 'Chưa được thử nghiệm';

  @override
  String get dnsLeakCheckTunnelDns => 'Trình phân giải DNS của đường hầm';

  @override
  String get dnsLeakCheckSystemResolvers => 'Trình phân giải hệ thống';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Bảo vệ DNS bằng chặn mạng';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Định cấu hình DNS cho đường hầm trong cài đặt DNS ở trên.';

  @override
  String get dnsLeakFixReviewSystemResolvers =>
      'Kiểm tra xem hệ thống của bạn sẽ sử dụng bộ phân giải nào bên ngoài đường hầm.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Bật chặn mạng để lưu lượng DNS luôn đi trong đường hầm.';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS mã hóa của hệ điều hành';

  @override
  String get dnsLeakCheckDnsSpoof => 'Giả mạo DNS phản hồi';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Kiểm tra xem điểm cuối DNS được mã hóa nào mà hệ thống của bạn sử dụng bên ngoài đường hầm.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Dùng DNS mã hóa (DoT hoặc DoH) cho đường hầm để trình phân giải không thể giả mạo câu trả lời.';

  @override
  String get dnsCheckNeedsConnection => 'Trước tiên hãy kết nối với VPN, sau đó kiểm tra xem có rò rỉ không.';

  @override
  String get dnsExpected => 'Dự kiến';

  @override
  String get dnsActual => 'Đã quan sát';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get sortPing => 'Ping';

  @override
  String get sortSpeed => 'Tốc độ';

  @override
  String get sortName => 'Tên';

  @override
  String get measureSpeed => 'Đo tốc độ';

  @override
  String get benchmarkStale => 'lỗi thời';

  @override
  String get autoSelectMode => 'Tự động chọn máy chủ';

  @override
  String get autoSelectPing => 'Ping nhanh nhất';

  @override
  String get autoSelectSpeed => 'Tốc độ nhanh nhất';

  @override
  String get autoSelectSmart => 'Lựa chọn thông minh';

  @override
  String get coreWatchUnstable => 'Kết nối tới lõi Sora không ổn định';

  @override
  String get watchReconnect => 'Kết nối lại';

  @override
  String get coreRestoringLink => 'Đang khôi phục kết nối tới lõi Sora…';

  @override
  String get crashRestoreTitle => 'Phiên cuối cùng bị gián đoạn';

  @override
  String get restoreOnCrash => 'Khôi phục phiên sau sự cố';

  @override
  String get crashRestore => 'Khôi phục';

  @override
  String get crashDismiss => 'Không phải bây giờ';

  @override
  String get overrideTitle => 'Chỉnh sửa của tôi';

  @override
  String get overrideEdit => 'Chỉnh sửa máy chủ';

  @override
  String get overrideHide => 'Ẩn';

  @override
  String get overrideUnhide => 'Hiển thị';

  @override
  String get overrideClear => 'Đặt lại chỉnh sửa';

  @override
  String get overrideEmpty => 'Chưa có chỉnh sửa nào';

  @override
  String get overrideCustomRules => 'Quy tắc riêng';

  @override
  String get errBenchmarkUnsupported => 'Đo tốc độ cần lõi mới hơn';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Đo $done từ $total…';
  }

  @override
  String get profiles => 'Cấu hình mạng';

  @override
  String get profilesEmpty => 'Chưa có hồ sơ nào. Tạo một cái để tự động áp dụng cài đặt trên các mạng đã biết.';

  @override
  String get profileAdd => 'Thêm hồ sơ';

  @override
  String get profileName => 'Tên hồ sơ';

  @override
  String get profileSsids => 'Wi-Fi mạng (SSID)';

  @override
  String get profileSsidsHint => 'Nhà, Văn phòng cách nhau bằng dấu phẩy';

  @override
  String get profileGateways => 'Cổng mạng';

  @override
  String get profileAsns => 'AS số';

  @override
  String get profileAutoApply => 'Tự động áp dụng';

  @override
  String get profileAutoApplyHint => 'Khi tắt, yêu cầu xác nhận trước khi áp dụng hồ sơ.';

  @override
  String get profileSnapshot => 'Ghi nhớ cài đặt hiện tại';

  @override
  String get profileSnapshotDone => 'Cài đặt hiện tại được lưu vào hồ sơ';

  @override
  String get profileDelete => 'Xóa hồ sơ';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Xóa hồ sơ \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Đăng ký hồ sơ \"$name\"?';
  }

  @override
  String get profileApply => 'Áp dụng';

  @override
  String profileApplied(Object name) {
    return 'Đã áp dụng hồ sơ “$name”';
  }

  @override
  String get profileUndo => 'Hủy';

  @override
  String get profileActive => 'Đang hoạt động';

  @override
  String networkNow(Object info) {
    return 'Bây giờ: $info';
  }

  @override
  String get networkUnknown => 'Không có thông tin mạng';

  @override
  String get profileNoTriggers => 'Thêm ít nhất một trình kích hoạt: SSID, cổng hoặc ASN';

  @override
  String get chains => 'Chuỗi proxy';

  @override
  String get chainsEmpty => 'Chưa có dây chuyền nào. Liên kết 2–3 máy chủ để lưu lượng truy cập đi qua từng máy chủ.';

  @override
  String get chainAdd => 'Dây chuyền mới';

  @override
  String get chainName => 'Tên dây chuyền';

  @override
  String get chainPickServers => 'Chọn 2–3 máy chủ';

  @override
  String get chainOrderHint => 'Kéo để sắp xếp lại: lưu lượng vào ở trên cùng và thoát ra ở dưới cùng.';

  @override
  String get chainTooFew => 'Chọn ít nhất 2 máy chủ';

  @override
  String get chainTooMany => 'Một chuỗi chứa tối đa 3 máy chủ';

  @override
  String get chainEstimate => 'Độ trễ ước tính';

  @override
  String get chainSave => 'Lưu chuỗi';

  @override
  String get chainDelete => 'Xóa chuỗi';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Xóa chuỗi \"$name\"?';
  }

  @override
  String get chainUnsupported => 'Động cơ hiện tại không hỗ trợ tạo chuỗi';

  @override
  String get chainHopMissing => 'Một trong các máy chủ của chuỗi không còn khả dụng';

  @override
  String chainHop(Object n) {
    return 'Chặng $n';
  }

  @override
  String get chainEntry => 'Đầu vào';

  @override
  String get chainExit => 'Đầu ra';

  @override
  String get sync => 'Đồng bộ hóa thiết bị';

  @override
  String get syncDevices => 'Thiết bị của tôi';

  @override
  String get syncEmpty => 'Không có thiết bị nào được ghép nối. Ghép nối một thiết bị khác qua mạng cục bộ.';

  @override
  String get syncPair => 'Ghép nối thiết bị';

  @override
  String get syncShowCode => 'Hiển thị mã của tôi';

  @override
  String get syncScanCode => 'Quét mã';

  @override
  String get syncRevoke => 'Rút tiền';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Thu hồi \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Đồng bộ hóa lần cuối: $time';
  }

  @override
  String get syncNever => 'Không bao giờ';

  @override
  String get syncNoLan => 'Các thiết bị phải nằm trên cùng một mạng cục bộ';

  @override
  String get syncPaired => 'Đã ghép nối thiết bị';

  @override
  String get syncPairingTitle => 'Ghép nối với thiết bị này';

  @override
  String get syncWaiting => 'Đang chờ thiết bị kia…';

  @override
  String get syncSecureNote => 'Kênh được mã hóa hai đầu. Không có tài khoản, không có máy chủ đám mây.';

  @override
  String get zapretWithVpn => 'Bỏ qua DPI lọc lưu lượng truy cập mạng trực tiếp';

  @override
  String get zapretWithVpnHint =>
      'Chạy zapret song song với đường hầm VPN: lưu lượng trong đường hầm dùng VPN, lưu lượng trực tiếp đi qua cơ chế vượt chặn.';

  @override
  String get chainDuplicate => 'Mỗi máy chủ chỉ có thể xuất hiện một lần';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get remove => 'Xóa';

  @override
  String get autoSwitchOnDegrade => 'Tự động chuyển đổi khi xuống cấp';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Nếu máy chủ đã chọn chậm đi nhiều hoặc ngừng phản hồi, Sora chuyển sang máy chủ tốt nhất theo kết quả đo, tối đa một lần mỗi 10 phút.';

  @override
  String get tunStackMixed => 'Hỗn hợp';

  @override
  String get tunStackSystem => 'Hệ thống';

  @override
  String get customServerAdd => 'Thêm máy chủ tùy chỉnh';

  @override
  String get customServers => 'Máy chủ của tôi';

  @override
  String get customServerName => 'Tên';

  @override
  String get customServerNameHint => 'Ví dụ: VPS của tôi';

  @override
  String get customServerNameRequired => 'Nhập tên';

  @override
  String get customServerAddress => 'Địa chỉ';

  @override
  String get customServerAddressHint => 'example.com hoặc 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Nhập địa chỉ máy chủ';

  @override
  String get customServerAddressInvalid => 'Địa chỉ không hợp lệ';

  @override
  String get customServerPort => 'Cổng';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Cổng phải là số từ 1 đến 65535';

  @override
  String get customServerProtocol => 'Giao thức';

  @override
  String get customServerCredentials => 'Thông tin đăng nhập';

  @override
  String get customServerOptional => 'Tùy chọn';

  @override
  String get customServerShowSecret => 'Hiển thị bí mật';

  @override
  String get customServerHideSecret => 'Ẩn bí mật';

  @override
  String get customServerBadge => 'tùy chỉnh';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Xóa máy chủ “$name”?';
  }

  @override
  String get customServerEmptyHint => 'Thêm máy chủ theo cách thủ công: địa chỉ, cổng và giao thức';

  @override
  String get customServerTest => 'Kiểm tra';

  @override
  String get leakTestTitle => 'Kiểm tra rò rỉ dữ liệu';

  @override
  String get leakTestIntro =>
      'Kiểm tra xem lưu lượng có thể rời thiết bị ngoài đường hầm hay không: DNS và ICMP trực tiếp, lưu lượng IPv6 đi ra và trình phân giải của hệ thống. Chạy khi đang kết nối.';

  @override
  String get leakTestRun => 'Kiểm tra';

  @override
  String get leakTestCancel => 'Hủy';

  @override
  String get leakTestNeedsConnection => 'Kết nối với VPN để kiểm tra rò rỉ dữ liệu.';

  @override
  String leakTestProgress(int count) {
    return 'Đã hoàn thành kiểm tra: $count';
  }

  @override
  String get leakTestAllClear => 'Không tìm thấy rò rỉ';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Phát hiện # rò rỉ');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Sửa';

  @override
  String get leakTestFixedNote => 'Đã bật chặn mạng. Chạy lại kiểm tra để xác nhận.';

  @override
  String get leakTestCheckDirectDns => 'Trực tiếp DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP tiếng vọng';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Trình phân giải hệ thống';

  @override
  String get leakTestCheckTunnelConnectivity => 'Kết nối đường hầm';

  @override
  String get leakTestCheckTunnelDns => 'DNS xuyên qua đường hầm';

  @override
  String get noticeDegraded =>
      'Máy chủ trở nên chậm. Sora đã chuyển sang máy chủ tốt nhất được tìm thấy trong quá trình đo.';

  @override
  String get obfs => 'Ngụy trang lưu lượng';

  @override
  String get syncCodeExpired => 'Mã đã hết hạn';

  @override
  String get syncDaemonFailed => 'Không thể khởi động dịch vụ đồng bộ hóa';

  @override
  String get syncDaemonMissing =>
      'Không tìm thấy thành phần sora-sync. Cài đặt lại ứng dụng để bật đồng bộ hóa thiết bị.';

  @override
  String get syncDaemonStarting => 'Đang bắt đầu dịch vụ đồng bộ hóa…';

  @override
  String get syncErrAuth => 'Dịch vụ đồng bộ hóa đã từ chối mã thông báo truy cập. Khởi động lại ứng dụng và thử lại.';

  @override
  String get syncErrNotFound => 'Thiết bị không còn được ghép nối';

  @override
  String get syncErrPairingActive => 'Phiên ghép nối đã được mở';

  @override
  String get syncErrUnreachable =>
      'Thiết bị kia không trả lời. Đảm bảo nó nằm trên cùng một mạng và hiển thị mã của nó.';

  @override
  String get syncError => 'Lỗi đồng bộ hóa';

  @override
  String syncExpiresIn(String duration) {
    return 'Mã hết hạn sau $duration';
  }

  @override
  String get syncJoining => 'Đang ghép nối với thiết bị…';

  @override
  String get syncLegacyCleared =>
      'Danh sách thiết bị cũ chưa bao giờ thực sự được ghép nối nên đã bị xóa. Ghép nối lại các thiết bị của bạn, lần này là thực sự.';

  @override
  String get syncNewCode => 'Mã mới';

  @override
  String syncPairedWith(String name) {
    return 'Ghép nối với $name';
  }

  @override
  String get syncRetry => 'Lặp lại';

  @override
  String get syncStopShowing => 'Ẩn mã';

  @override
  String get syncSyncNow => 'Đồng bộ ngay';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Đã nhận $pulled, đã gửi $pushed';
  }

  @override
  String get syncResultTitle => 'Kết quả đồng bộ hóa';

  @override
  String get syncPulled => 'Đã nhận được';

  @override
  String get syncPushed => 'Đã gửi';

  @override
  String get syncNoChanges => 'Không phát hiện thấy thay đổi nào';

  @override
  String get syncDocKindSubscriptions => 'Đăng ký';

  @override
  String get syncDocKindSettings => 'Cài đặt ứng dụng';

  @override
  String get syncDocKindOverrides => 'Tùy chỉnh đăng ký';

  @override
  String get syncDocKindProfiles => 'Cấu hình mạng';

  @override
  String get syncDocKindChains => 'Chuỗi proxy';

  @override
  String syncFrom(String name) {
    return 'từ $name';
  }

  @override
  String get syncThisDevice => 'Thiết bị này';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials =>
      'Với Shadowsocks: phương thức:mật khẩu, ví dụ chacha20-ietf-poly1305:matkhau';

  @override
  String get diagnosticPackets => 'Chụp gói';

  @override
  String get diagnosticEvents => 'Sự kiện Windows';

  @override
  String get diagnosticCapture => 'Chụp trong 10 giây';

  @override
  String get diagnosticRequiresTun => 'Việc chụp gói cần có kết nối Sora TUN đang hoạt động.';

  @override
  String get diagnosticUnavailable => 'Chẩn đoán này không có sẵn trên nền tảng này.';

  @override
  String get extErrRevoked => 'Nhóm Sora đã thu hồi phiên bản tiện ích này vì không an toàn hoặc bị lỗi.';

  @override
  String get extErrRevocationsExpired => 'Việc cài đặt bị chặn cho đến khi danh sách thu hồi được cập nhật.';

  @override
  String extRevokedDisabled(String names) {
    return 'Đã tắt các tiện ích bị thu hồi: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Khóa riêng';

  @override
  String get customServerWgAddresses => 'Địa chỉ giao diện';

  @override
  String get customServerWgPeerKey => 'Khóa công khai của máy chủ';

  @override
  String get customServerWgPresharedKey => 'Khóa chia sẻ trước';

  @override
  String get customServerWgAllowedIps => 'IP được phép';

  @override
  String get customServerWgKeepalive => 'Keepalive, giây';

  @override
  String get customServerWgKeyInvalid => 'Khóa phải là 32 byte base64, như wg genkey in ra.';

  @override
  String get customServerWgCidrInvalid => 'Nhập các tiền tố cách nhau bằng dấu phẩy, ví dụ 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Nhập số giây từ 0 đến 65535.';

  @override
  String get strictKillSwitch => 'Chặn mạng nghiêm ngặt';

  @override
  String get strictKillSwitchWarning =>
      'Sau khi kết nối, chặn lưu lượng ngoài VPN kể cả khi gặp sự cố, khởi động lại hoặc thoát ứng dụng. Chỉ ngắt kết nối hoặc tắt tùy chọn này mới khôi phục truy cập. Sau khi khởi động lại thiết bị, chỉ tiếp tục chặn nếu đã bật kết nối khi khởi động.';

  @override
  String get extWorkerFailed => 'Tác vụ nền của tiện ích mở rộng thất bại. Kiểm tra nhật ký tiện ích.';

  @override
  String get extAssetRejected => 'Tệp tiện ích bị từ chối: màu khó đọc hoặc quy tắc không hợp lệ.';

  @override
  String get extVerifiedSora => 'Được Sora xác minh';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Mở';
}
