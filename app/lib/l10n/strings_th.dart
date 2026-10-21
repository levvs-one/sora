// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class STh extends S {
  STh([String locale = 'th']) : super(locale);

  @override
  String get stateOff => 'ไม่ได้เชื่อมต่อ';

  @override
  String get stateConnecting => 'กำลังเชื่อมต่อ';

  @override
  String get stateConnected => 'เชื่อมต่อแล้ว';

  @override
  String get stateReconnecting => 'กำลังเชื่อมต่อใหม่';

  @override
  String get stateDisconnecting => 'กำลังตัดการเชื่อมต่อ';

  @override
  String get stateFailed => 'ไม่ได้เชื่อมต่อ';

  @override
  String get coreMissing => 'บริการ Sora ไม่ตอบสนอง';

  @override
  String get serverAuto => 'เร็วที่สุด';

  @override
  String get serverBypass => 'ไม่มีเซิร์ฟเวอร์';

  @override
  String get addSubscription => 'เพิ่มการสมัครสมาชิก';

  @override
  String get servers => 'เซิร์ฟเวอร์';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get subscription => 'สมัครสมาชิก';

  @override
  String get subscriptionLink => 'ลิงค์สมัครสมาชิก';

  @override
  String get add => 'เพิ่ม';

  @override
  String get refresh => 'อัปเดต';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get delete => 'ลบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get name => 'ชื่อ';

  @override
  String deleteSubscription(String name) {
    return 'ลบ “$name” หรือไม่';
  }

  @override
  String get routes => 'เส้นทาง';

  @override
  String get presetGlobal => 'ทุกอย่างผ่าน VPN';

  @override
  String get presetRu => 'รัสเซียโดยตรง';

  @override
  String get presetIr => 'อิหร่านโดยตรง';

  @override
  String get presetCn => 'จีนโดยตรง';

  @override
  String get blockAds => 'บล็อกโฆษณา';

  @override
  String get killSwitch => 'อินเทอร์เน็ตผ่าน VPN เท่านั้น';

  @override
  String get engine => 'เครื่องยนต์';

  @override
  String get engineAuto => 'อัตโนมัติ';

  @override
  String get animations => 'ภาพเคลื่อนไหว';

  @override
  String get logs => 'บันทึก';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get logsAll => 'ทั้งหมด';

  @override
  String get logsImportant => 'สำคัญ';

  @override
  String get logsErrors => 'ข้อผิดพลาด';

  @override
  String get search => 'ค้นหา';

  @override
  String get export => 'บันทึกลงไฟล์';

  @override
  String get clear => 'ชัดเจน';

  @override
  String get logsEmpty => 'ไม่มีอะไรที่นี่';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get notInstalled => 'ไม่ได้ติดตั้ง';

  @override
  String get sourceCode => 'ซอร์สโค้ด';

  @override
  String get license => 'ใบอนุญาต';

  @override
  String usage(String used, String total) {
    return '$used ของ $total';
  }

  @override
  String until(String date) {
    return 'จนถึง $date';
  }

  @override
  String get expired => 'หมดอายุแล้ว';

  @override
  String milliseconds(int n) {
    return '$n มิลลิวินาที';
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
    return '$n บี';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n เมกะไบต์';
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
  String get errGeneric => 'มีบางอย่างผิดพลาด';

  @override
  String get errCore => 'บริการ Sora ไม่ตอบสนอง';

  @override
  String get errAuth => 'ไม่มีการเข้าถึงบริการ Sora';

  @override
  String get errVersion => 'อัปเดต Sora: แอปและบริการเป็นเวอร์ชันที่แตกต่างกัน';

  @override
  String get errBusy => 'รอสักครู่ คำสั่งก่อนหน้ายังคงทำงานอยู่';

  @override
  String get errEngineMissing => 'ไม่พบเอ็นจิ้นสำหรับเซิร์ฟเวอร์นี้';

  @override
  String get errOlcrtcInvalid =>
      'เซิร์ฟเวอร์ olcRTC นี้ไม่สมบูรณ์: โปรดตรวจสอบผู้ให้บริการ การขนส่ง ห้อง และคีย์เข้ารหัส';

  @override
  String get errOlcrtcCombination => 'ผู้ให้บริการและการขนส่ง olcRTC นี้ทำงานร่วมกันไม่ได้';

  @override
  String get errOlcrtcTokenRequired => 'เซิร์ฟเวอร์ olcRTC นี้ต้องใช้โทเค็นบัญชีผู้ให้บริการซึ่งลิงก์ไม่มี';

  @override
  String get errOlcrtcNotConnectable => 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ olcRTC นี้จากลิงก์เพียงอย่างเดียวได้';

  @override
  String get errOlcrtcServerMode => 'Sora เชื่อมต่อกับเซิร์ฟเวอร์ olcRTC เท่านั้นและไม่เรียกใช้เซิร์ฟเวอร์เอง';

  @override
  String get olcrtcTcpOnly => 'TCP เท่านั้น';

  @override
  String get olcrtcIpv4Only => 'IPv4 เท่านั้น';

  @override
  String get errEngineStart => 'เครื่องยนต์สตาร์ทไม่ติด';

  @override
  String get errEngineStopped => 'เครื่องยนต์หยุดทำงาน';

  @override
  String get errTunnel => 'ไม่ได้รับอนุญาตให้สร้างการเชื่อมต่อ VPN';

  @override
  String get errServers => 'เซิร์ฟเวอร์ได้รับการกำหนดค่าโดยมีข้อผิดพลาด';

  @override
  String get errNetwork => 'ไม่สามารถเข้าถึงเซิร์ฟเวอร์ได้';

  @override
  String get errTimeout => 'เซิร์ฟเวอร์ไม่ตอบทันเวลา';

  @override
  String get errFirewall => 'ไม่สามารถบล็อกอินเทอร์เน็ตนอก VPN ได้';

  @override
  String get errSubFetch => 'ไม่สามารถโหลดการสมัครสมาชิกได้';

  @override
  String get errSubFormat => 'นี่ไม่ใช่ลิงค์สมัครสมาชิก';

  @override
  String get errSubEmpty => 'การสมัครสมาชิกไม่มีเซิร์ฟเวอร์';

  @override
  String get errSubDuplicate => 'เพิ่มการสมัครรับข้อมูลนี้แล้ว';

  @override
  String get errSubLimit => 'สมัครสมาชิกมากเกินไป';

  @override
  String get errSubScheme => 'ลิงค์ต้องขึ้นต้นด้วย https://';

  @override
  String get errSecretStore => 'ที่เก็บข้อมูล Sora เสียหายหรือไม่พร้อมใช้งาน';

  @override
  String get errNoServers => 'เพิ่มการสมัครสมาชิกเพื่อเชื่อมต่อ';

  @override
  String get exportText => 'ข้อความ';

  @override
  String get connections => 'การเชื่อมต่อ';

  @override
  String get close => 'ปิด';

  @override
  String get chainDirect => 'โดยตรง';

  @override
  String get chainBlocked => 'ถูกบล็อก';

  @override
  String get theme => 'ธีม';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'แสงสว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get language => 'ภาษา';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'การเชื่อมต่อ';

  @override
  String get sectionNoServer => 'ไม่มีเซิร์ฟเวอร์';

  @override
  String get sectionPing => 'ปิง';

  @override
  String get sectionLog => 'การวินิจฉัย';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'อัตโนมัติ';

  @override
  String get dnsHint => 'ที่อยู่ คั่นด้วยเครื่องหมายจุลภาค';

  @override
  String get fragment => 'การกระจายตัวของ TLS';

  @override
  String get fragmentPackets => 'จะแบ่งอะไร.';

  @override
  String get fragmentLength => 'ขนาดชิ้น';

  @override
  String get fragmentInterval => 'หยุดชั่วคราวระหว่างชิ้น';

  @override
  String get byDefault => 'ค่าเริ่มต้น';

  @override
  String get rangeHint => 'ตัวอย่างเช่น 100-200';

  @override
  String get splitPos => 'แยกตำแหน่ง';

  @override
  String get splitPosHint => 'ตัวอย่างเช่น 1, midsld';

  @override
  String get disorder => 'จัดลำดับชิ้นส่วนใหม่';

  @override
  String get tlsRecord => 'แยกบันทึก TLS';

  @override
  String get tlsRecordNo => 'เลขที่';

  @override
  String get tlsRecordSni => 'ที่ชื่อเว็บไซต์';

  @override
  String get tlsRecordFirst => 'หลังจากไบต์แรก';

  @override
  String get hostCase => 'เปลี่ยนกรณีโฮสต์';

  @override
  String get probeMethod => 'วิธี';

  @override
  String get probeAuto => 'อัตโนมัติ';

  @override
  String get probeEngine => 'ผ่านทางเครื่องยนต์';

  @override
  String get probeConnect => 'การเชื่อมต่อเท่านั้น';

  @override
  String get probeUrl => 'ที่อยู่ทดสอบ';

  @override
  String get probeTimeout => 'รอ';

  @override
  String seconds(int n) {
    return '$n ส';
  }

  @override
  String get subscriptions => 'การสมัครรับข้อมูล';

  @override
  String get subscriptionSettings => 'การตั้งค่า';

  @override
  String get userAgent => 'ผู้ใช้-ตัวแทน';

  @override
  String get autoUpdate => 'อัปเดตอัตโนมัติ';

  @override
  String get updateInterval => 'บ่อยแค่ไหน';

  @override
  String get intervalProvider => 'ตามที่ผู้ให้บริการถาม';

  @override
  String hours(int n) {
    return '$n ชม';
  }

  @override
  String get updateNow => 'อัปเดตตอนนี้';

  @override
  String get logLevel => 'สิ่งที่จะบันทึก';

  @override
  String get levelDebug => 'ทุกอย่าง';

  @override
  String get levelInfo => 'ตามปกติ';

  @override
  String get levelWarning => 'สำคัญ';

  @override
  String get levelError => 'ข้อผิดพลาดเท่านั้น';

  @override
  String get recordDestinations => 'บันทึกที่อยู่ไซต์';

  @override
  String get reset => 'รีเซ็ตการตั้งค่า';

  @override
  String get resetConfirm => 'รีเซ็ตการตั้งค่าทั้งหมดใช่ไหม';

  @override
  String get resetAction => 'รีเซ็ต';

  @override
  String get invalidValue => 'ค่านี้จะไม่ทำงาน';

  @override
  String get website => 'หน้าสมัครสมาชิก';

  @override
  String get providerWebsite => 'เว็บไซต์ผู้ให้บริการ';

  @override
  String get support => 'สนับสนุน';

  @override
  String controlPortQuestion(String engine) {
    return '$engine ถูกควบคุมผ่านพอร์ตบนคอมพิวเตอร์เครื่องนี้ โปรแกรมอื่นๆ จะสามารถบอกได้ว่า VPN เปิดอยู่';
  }

  @override
  String chooseEngine(String engine) {
    return 'เลือก $engine';
  }

  @override
  String get rules => 'กฎที่กำหนดเอง';

  @override
  String get ruleAdd => 'กฎใหม่';

  @override
  String get ruleHint => 'ไซต์ IP หรือโปรแกรม';

  @override
  String get ruleDirect => 'โดยตรง';

  @override
  String get ruleProxy => 'ผ่านวีพีเอ็น';

  @override
  String get ruleBlock => 'ปิดกั้น';

  @override
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'เปิดสวิตช์ความล้มเหลว';

  @override
  String get connectOnStart => 'เชื่อมต่อเมื่อเริ่มต้น';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'การสมัครสมาชิกจะสิ้นสุดใน # วัน',
      one: 'การสมัครสมาชิกจะสิ้นสุดในวัน #',
      zero: 'การสมัครสมาชิกจะสิ้นสุดในอีกไม่กี่ชั่วโมง',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: เหลือ $left';
  }

  @override
  String get ruleInvalid => 'สิ่งนี้ดูไม่เหมือนไซต์, IP หรือโปรแกรม';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ในทางกลับกันเซิร์ฟเวอร์ #',
      one: 'ในทางกลับกันเซิร์ฟเวอร์ #',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เซิร์ฟเวอร์ # เร็วที่สุด',
      one: 'เซิร์ฟเวอร์ # เร็วที่สุด',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'โหมด';

  @override
  String get tunnelTun => 'การจราจรทั้งหมด';

  @override
  String get tunnelProxy => 'พร็อกซี System';

  @override
  String get proxyAddress => 'ที่อยู่พร็อกซี';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get launchAtLogin => 'เริ่มต้นด้วยระบบ';

  @override
  String get launchAtLoginDetail => 'Sora จะเริ่มทำงานอัตโนมัติเมื่อคุณเข้าสู่ระบบและอยู่ในถาดระบบ';

  @override
  String get closeToTray => 'เก็บในถาดเมื่อปิด';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get trayOpen => 'เปิด Sora';

  @override
  String get trayConnect => 'เชื่อมต่อ';

  @override
  String get trayDisconnect => 'ตัดการเชื่อมต่อ';

  @override
  String get trayServer => 'เซิร์ฟเวอร์';

  @override
  String get trayQuit => 'ออกจาก Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora ยังอยู่ในถาด';

  @override
  String get noticeInTrayBody => 'ออกจากเมนูของไอคอน';

  @override
  String get noticeLost => 'การเชื่อมต่อขาดหายไป';

  @override
  String get noticeLostBody => 'Sora กำลังเชื่อมต่อใหม่';

  @override
  String get noticeRestored => 'เชื่อมต่ออีกครั้ง';

  @override
  String get noticeFailed => 'ไม่สามารถเชื่อมต่อได้';

  @override
  String get noticeBackup => 'เซิร์ฟเวอร์หลักไม่ตอบ การสำรองข้อมูลดำเนินการรับส่งข้อมูล';

  @override
  String get noticeNext => 'เซิร์ฟเวอร์ไม่ตอบ อันถัดไปมีการจราจร';

  @override
  String get noticeMainBack => 'เซิร์ฟเวอร์หลักตอบกลับอีกครั้งและดำเนินการรับส่งข้อมูล';

  @override
  String get noticeSubscription => 'สมัครสมาชิก';

  @override
  String get importTitle => 'เพิ่มการสมัครสมาชิกนี้หรือไม่?';

  @override
  String get importSealed =>
      'ลิงก์นี้ได้รับการเข้ารหัสสำหรับ Happ และมีเพียง Happ เท่านั้นที่สามารถอ่านได้ สอบถามผู้ให้บริการของคุณเกี่ยวกับลิงค์สมัครสมาชิกธรรมดา';

  @override
  String get understood => 'ตกลง';

  @override
  String get noAnswer => 'ไม่มีคำตอบ';

  @override
  String get home => 'บ้าน';

  @override
  String get navRules => 'กฎ';

  @override
  String get navConnections => 'การเชื่อมต่อ';

  @override
  String get navLogs => 'บันทึก';

  @override
  String get navAbout => 'เกี่ยวกับ';

  @override
  String get sidebarToggle => 'สลับแถบด้านข้าง';

  @override
  String get more => 'มากกว่า';

  @override
  String get less => 'น้อย';

  @override
  String get currentServer => 'เซิร์ฟเวอร์ปัจจุบัน';

  @override
  String get trafficDown => 'ดาวน์โหลดแล้ว';

  @override
  String get trafficUp => 'อัปโหลดแล้ว';

  @override
  String perSecond(String value) {
    return '$value/วินาที';
  }

  @override
  String activeRules(int count) {
    return 'กฎที่ใช้งานอยู่: $count';
  }

  @override
  String get recentNotifications => 'การแจ้งเตือนล่าสุด';

  @override
  String get notificationsEmpty => 'กิจกรรมการเชื่อมต่อและการสมัครสมาชิกจะปรากฏที่นี่';

  @override
  String get retryConnect => 'ลองเชื่อมต่ออีกครั้ง';

  @override
  String get openLogs => 'เปิดบันทึก';

  @override
  String get tourReplay => 'แสดงคำแนะนำอีกครั้ง';

  @override
  String tourStep(int step) {
    return 'ขั้นตอนที่ $step จาก 5';
  }

  @override
  String get tourBack => 'กลับ';

  @override
  String get tourNext => 'ต่อไป';

  @override
  String get tourSkip => 'ข้าม';

  @override
  String get tourFinish => 'เสร็จแล้ว';

  @override
  String get tourAdd => 'เพิ่มลิงค์สมัครสมาชิกของผู้ให้บริการของคุณ';

  @override
  String get tourServer => 'เลือกเซิร์ฟเวอร์ “เร็วที่สุด” เลือกหนึ่งรายการสำหรับคุณ';

  @override
  String get tourConnect => 'คลิกที่นี่เพื่อเชื่อมต่อหรือยกเลิกการเชื่อมต่อ';

  @override
  String get tourMode => 'เลือกโหมด Kill switch จะบล็อกอินเทอร์เน็ตหาก VPN หลุด';

  @override
  String get tourSettings => 'เปิดการตั้งค่า คุณสามารถเล่นซ้ำคู่มือนี้ได้ที่นั่น';

  @override
  String get chooseProgram => 'เลือกโปรแกรม';

  @override
  String get installedApps => 'แอพพลิเคชั่นที่ติดตั้ง';

  @override
  String get runningProcesses => 'กระบวนการที่กำลังทำงานอยู่';

  @override
  String get programsFailed => 'ไม่สามารถโหลดแอปพลิเคชันได้';

  @override
  String get programsEmpty => 'ไม่พบแอปพลิเคชัน ลองใช้ชื่ออื่น';

  @override
  String get selectExe => 'เลือกไฟล์ .exe';

  @override
  String get trafficUnavailable => 'เคาน์เตอร์ยังไม่มีให้บริการ';

  @override
  String get speedtest => 'ความเร็ว';

  @override
  String get speedtestCheck => 'ตรวจสอบความเร็ว';

  @override
  String get speedtestSearch => 'ค้นหาบริการ';

  @override
  String get speedtestEmpty => 'ไม่มีการแข่งขัน เปลี่ยนการค้นหา';

  @override
  String get speedtestBackToList => 'กลับไปที่บริการ';

  @override
  String get speedtestOpenBrowser => 'เปิดในเบราว์เซอร์';

  @override
  String get speedtestUnavailable => 'เบราว์เซอร์แบบฝังตัวไม่สามารถเริ่มทำงานได้ เปิดบริการในเบราว์เซอร์ระบบของคุณ';

  @override
  String get speedtestPageFailed => 'ไม่สามารถโหลดหน้านี้ได้ โหลดซ้ำหรือเปิดบริการในเบราว์เซอร์ระบบของคุณ';

  @override
  String get speedtestExternalFailed => 'เบราว์เซอร์ระบบไม่สามารถเปิดได้ ลองอีกครั้ง';

  @override
  String get modes => 'โหมด';

  @override
  String get proxyShort => 'หนังสือมอบฉันทะ';

  @override
  String get tunMode => 'การจราจรทั้งหมด (TUN)';

  @override
  String get checkUpdates => 'ตรวจสอบการอัปเดต';

  @override
  String get updates => 'การอัปเดตแอป';

  @override
  String updateAvailable(String version) {
    return 'มีเวอร์ชัน $version ให้เลือก';
  }

  @override
  String get updateOpenAbout => 'ดูการอัพเดต';

  @override
  String updateNotes(String version) {
    return 'การเปลี่ยนแปลงใน $version';
  }

  @override
  String get updateCheck => 'ตรวจสอบการอัปเดต';

  @override
  String get updateChecking => 'กำลังตรวจสอบ...';

  @override
  String get updateNoNotes => 'การเปิดตัวไม่มีบันทึก';

  @override
  String get updateDropWarning => 'การเชื่อมต่อ VPN จะลดลงไม่กี่วินาทีในขณะที่ Sora และการอัปเดตหลัก ดำเนินการต่อ?';

  @override
  String get updateWaitConnection => 'รอให้การเชื่อมต่อ VPN และคอร์พร้อม';

  @override
  String get updateDownloading => 'กำลังดาวน์โหลดและยืนยันไฟล์...';

  @override
  String get updateInstalling => 'กำลังเตรียมการอัปเดตหรือรอการรับรองความถูกต้องของผู้ดูแลระบบ...';

  @override
  String get updateNetworkError => 'ไม่สามารถดาวน์โหลดการอัปเดตได้ ลองอีกครั้ง';

  @override
  String get updateReleaseError => 'ข้อมูลการเผยแพร่หรือไฟล์ที่จำเป็นหายไปหรือไม่ถูกต้อง';

  @override
  String get updateChecksumError => 'การดาวน์โหลดไม่ตรงกับ SHA256SUMS ไม่มีอะไรถูกติดตั้ง';

  @override
  String get updateInstallError => 'การอัปเดตไม่เสร็จสิ้น การรับรองความถูกต้องอาจถูกยกเลิก';

  @override
  String get updateUnsupported =>
      'ไฟล์ปฏิบัติการนี้ไม่ได้เป็นเจ้าของโดยคู่แพ็คเกจ Sora ที่รองรับ ใช้คำแนะนำในการติดตั้งรีลีส';

  @override
  String get updateManual =>
      'เรียกใช้คำสั่งนี้ในเทอร์มินัลเพื่อติดตั้งแพ็คเกจที่ตรวจสอบแล้วทั้งสองรายการ จากนั้นเปิด Sora อีกครั้ง ไฟล์จะยังคงอยู่ในไดเร็กทอรีดาวน์โหลด การเชื่อมต่อ VPN จะลดลง';

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
  String get updateCopyCommand => 'คำสั่งคัดลอก';

  @override
  String get updateChecksDisabled => 'การตรวจสอบอัตโนมัติถูกปิดใช้งานในการตั้งค่า';

  @override
  String get updateInstalled => 'ติดตั้งการอัปเดตแล้ว เปิด Sora อีกครั้ง';

  @override
  String get projectLinks => 'โครงการ';

  @override
  String get githubReleases => 'การเผยแพร่และการดาวน์โหลด';

  @override
  String get telegramChannel => 'ช่อง Telegram';

  @override
  String get licenses => 'ใบอนุญาต';

  @override
  String get componentLicenses => 'ใบอนุญาตส่วนประกอบ';

  @override
  String get appCopyright => '© 2026 levvs-one และผู้มีส่วนร่วม';

  @override
  String get collapseServers => 'ยุบเซิร์ฟเวอร์';

  @override
  String get expandServers => 'ขยายเซิร์ฟเวอร์';

  @override
  String get hideDescription => 'ซ่อนคำอธิบาย';

  @override
  String get showDescription => 'แสดงคำอธิบาย';

  @override
  String get pendingConnectionChanges => 'เชื่อมต่อใหม่เพื่อใช้การเปลี่ยนแปลงเหล่านี้';

  @override
  String get reconnectNow => 'สมัครและเชื่อมต่อใหม่';

  @override
  String get bypassLimitations =>
      'โหมดนี้จะข้าม DPI สำหรับ HTTP และ TLS เท่านั้น ไม่รองรับ UDP หรือเปลี่ยน IP ของคุณ ใช้เซิร์ฟเวอร์ VPN สำหรับเสียง การโทร และที่อยู่ Telegram ที่ถูกบล็อกของ Discord';

  @override
  String get errEngineUnsupported =>
      'เอ็นจิ้นที่เลือกไม่รองรับโปรไฟล์หรือการตั้งค่านี้ เลือกอัตโนมัติหรือเครื่องยนต์ที่รองรับ';

  @override
  String get errRestore =>
      'การล้างข้อมูลการเชื่อมต่อไม่สมบูรณ์ ลองยกเลิกการเชื่อมต่ออีกครั้ง ดูบันทึกเพื่อดูรายละเอียด';

  @override
  String get errSessionEnded => 'เซสชันนี้สิ้นสุดแล้ว รีเฟรชสถานะการเชื่อมต่อ';

  @override
  String get retryDisconnect => 'ลองตัดการเชื่อมต่ออีกครั้ง';

  @override
  String get tunStack => 'กอง TUN';

  @override
  String get modesInfo => 'เกี่ยวกับโหมด';

  @override
  String get modesGuideTitle => 'โหมดและเครื่องยนต์';

  @override
  String get modesGuide =>
      'เลือกอัตโนมัติหากคุณไม่แน่ใจว่าเซิร์ฟเวอร์ของคุณต้องการเอ็นจิ้นใด Sora ตรวจสอบโปรไฟล์และการตั้งค่าก่อนเชื่อมต่อ กลไกไม่สามารถเพิ่มแบนด์วิธของแผนของคุณได้: ประสิทธิภาพขึ้นอยู่กับเซิร์ฟเวอร์ เส้นทาง โปรโตคอล และเครือข่าย\n\n## โหมด\n\n### การจราจรทั้งหมด (TUN)\n\nSora สร้างอินเทอร์เฟซเครือข่ายเสมือนและกำหนดเส้นทางการรับส่งข้อมูลแอปพลิเคชัน รวมถึง TCP และ UDP ใช้โหมดนี้สำหรับ Telegram เกม และเสียง Discord กฎสามารถส่งไซต์หรือโปรแกรมเฉพาะได้โดยตรงหรือบล็อกไซต์หรือโปรแกรมเหล่านั้น บริการเครือข่ายจำเป็นต้องได้รับอนุญาตและเซิร์ฟเวอร์ที่รองรับโปรโตคอลที่จำเป็น\n\n### พร็อกซี System\n\nSora กำหนดค่าพร็อกซี HTTP/SOCKS ในเครื่อง แอปพลิเคชันที่เคารพการตั้งค่าพร็อกซีของระบบจะใช้งาน แอปพลิเคชันที่มีสแต็กเครือข่ายของตนเองอาจเชื่อมต่อโดยตรง โดยทั่วไป UDP และการโทรด้วยเสียงต้องใช้ TUN โหมดนี้เหมาะกับเบราว์เซอร์และแอปพลิเคชันที่รองรับพร็อกซี\n\n### ไม่มีเซิร์ฟเวอร์\n\nใน Linux นั้น Sora ใช้ [zapret](https://github.com/bol-van/zapret) เพื่อแยกและปรับแต่งคำขอ HTTP/TLS และข้ามการตรวจสอบ DPI บางอย่าง IP ของคุณยังคงเหมือนเดิมและการเชื่อมต่อจะไปยังเว็บไซต์โดยตรง ผลลัพธ์ขึ้นอยู่กับผู้ให้บริการของคุณและวิธีการบล็อก\n\nการรวมปัจจุบันใช้ tpws สำหรับ HTTP และ TLS ผ่าน TCP ไม่หลีกเลี่ยงการบล็อก IP หรือรีเลย์ UDP และไม่สามารถรับประกันการเชื่อมต่อ Telegram ของ MTProto ได้ ใช้เซิร์ฟเวอร์ VPN พร้อม TUN สำหรับเสียง Discord, การโทร Telegram และข้อจำกัดประเภทนี้\n\n## เครื่องยนต์\n\n### ออโต้\n\nSora เลือกเอ็นจิ้นที่ติดตั้งซึ่งสนับสนุนแผนการเชื่อมต่อทั้งหมด: โปรโตคอลเซิร์ฟเวอร์ การขนส่ง กลุ่ม การกระจายตัว และโหมด ตัวเลือกด้วยตนเองที่เข้ากันไม่ได้จะถูกปฏิเสธก่อนที่จะหยุดการเชื่อมต่อปัจจุบัน เลือกอัตโนมัติหรือเครื่องยนต์อื่นแล้วใช้การตั้งค่าอีกครั้ง\n\n### sing-box\n\nแพ็คเกจ Sora ใหม่ประกอบด้วย [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) ซึ่งเป็นทางแยกของ [sing-box](https://github.com/SagerNet/sing-box) โดยเพิ่ม XHTTP และ VLESS Encryption ฝั่งไคลเอ็นต์ Sora จดจำบิลด์และความสามารถของมัน การสร้างอัพสตรีมที่ไม่มี XHTTP จะไม่ได้รับความสามารถนี้จากชื่อเพียงอย่างเดียว\n\nโปรโตคอลที่รองรับ ได้แก่ VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard และพารามิเตอร์ AmneziaWG 1.x/2.x Sora สามารถนำเข้าได้ โปรไฟล์ Xray JSON แบบเต็มต้องใช้ Xray ยังไม่สามารถนำเข้าฟิลด์ AWG 3.x ใหม่ได้ sing-box ใช้พอร์ตควบคุมภายในที่มีการป้องกันด้วยรหัสผ่าน ซึ่งแอปพลิเคชันอื่นบนคอมพิวเตอร์สามารถตรวจพบได้\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) รองรับการแยกส่วน VLESS, REALITY, XHTTP, VLESS Encryption และการกระจายตัวของ TLS นอกจากนี้ยังรันโปรไฟล์ผู้ให้บริการ Xray ที่สมบูรณ์โดยยังคงรักษาการกำหนดเส้นทางและกลุ่มไว้ โปรไฟล์ดังกล่าวไม่สามารถแปลงเป็นเอ็นจิ้นอื่นโดยอัตโนมัติโดยไม่เปลี่ยนพฤติกรรม\n\nXray ที่ให้มาได้ลบการตั้งค่าที่ปิดใช้งานการตรวจสอบใบรับรอง TLS (`allowInsecure`) เลือก sing-box หรือ mihomo อัตโนมัติสำหรับเซิร์ฟเวอร์ทั่วไปที่ต้องการการตั้งค่านี้ การเลือก Xray จะรายงานความไม่เข้ากันด้วยตนเองก่อนที่จะหยุดการเชื่อมต่อปัจจุบัน โปรไฟล์ JSON แบบเต็มรุ่นเก่าต้องมีโปรไฟล์ผู้ให้บริการที่อัปเดตพร้อมใบรับรองที่ตรวจสอบได้หรือ PIN ใบรับรอง\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) รองรับกลุ่มทางเลือกสำรองและกลุ่มบาลานซ์โหลด, XHTTP และ AmneziaWG เลือกเมื่อการเฟลโอเวอร์อัตโนมัติไปยังเซิร์ฟเวอร์สำรองมีความสำคัญ การตั้งค่าการกระจายตัวของ TLS ของ Sora ไม่พร้อมใช้งานกับกลไกนี้\n\n## ความเข้ากันได้ใน Sora\n\n| คุณสมบัติ | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN และ TCP/UDP | ใช่ | ใช่ | ใช่ |\n| XHTTP | ใช่ | ใช่ | ใช่ |\n| VLESS Encryption | ใช่ | ใช่ | ใช่ |\n| โปรไฟล์ Xray แบบเต็ม | ไม่ | ใช่ | ไม่ |\n| TUIC / AnyTLS | ทั้งสอง | ไม่ | TUIC |\n| การกระจายตัวของ TLS | ใช่ | ใช่ | ไม่ |\n| AmneziaWG 1.x/2.x | ใช่¹ | ไม่ | ใช่ |\n| จัดกลุ่มสำรอง | ไม่ | โน² | ใช่ |\n\n¹ โปรไฟล์ที่มี J1/J2/J3/Itime ใช้ mihomo; ฟิลด์เหล่านี้จะต้องไม่ถูกละทิ้งอย่างเงียบๆ ² สำหรับกลุ่มโปรไฟล์ Xray ที่สมบูรณ์ แอปจะเลือกโปรไฟล์สำรอง การสนับสนุนขึ้นอยู่กับบิลด์ที่ติดตั้ง ตรวจสอบเวอร์ชันในเกี่ยวกับ\n\n## กอง TUN\n\nสแต็กจัดการ TCP และ UDP ภายในอินเทอร์เฟซเสมือน ในแผงโหมด Xray และ mihomo มี gVisor, System, Mixed และ MIPS เครื่องยนต์แต่ละตัวจะบันทึกการตั้งค่าของตัวเอง พร็อกซี System และโหมด Serverless ไม่ได้ใช้การกำหนดค่าตามความชอบนี้\n\n- **Mixed** — TCP ใช้สแต็กของระบบ ในขณะที่ gVisor จัดการ UDP นี่เป็นค่าเริ่มต้นสำหรับ mihomo บน Linux ส่วน Windows ใช้ MIPS เป็นค่าเริ่มต้นสำหรับ Xray และ mihomo\n- **System** — ใช้สแต็กระบบ ลองใช้ตัวเลือกอื่นหากแอปพลิเคชันเครือข่ายประสบปัญหา\n- **gVisor** — จัดการการรับส่งข้อมูลในพื้นที่ผู้ใช้\n- **MIPS** — IP Stack ของ mihomo เอง มีให้ใช้งานในเวอร์ชันบันเดิล 1.19.32\n\nบน Linux นั้น Xray จะใช้ gVisor ในตัวเป็นค่าเริ่มต้น System, Mixed และ MIPS บน Linux ใช้ mihomo เป็นกลไก TUN โดยส่งต่อ TCP และ UDP ไปยัง Xray ผ่านลิงก์ SOCKS ท้องถิ่นที่ได้รับการรับรองความถูกต้อง Xray ยังคงรักษาโปรโตคอล โปรไฟล์ผู้ให้บริการ และการกำหนดเส้นทางไว้ ตัวเลือกทั้งสามนี้จำเป็นต้องมี mihomo ที่ติดตั้งไว้ บน Windows Xray ใช้ mihomo 1.19.32 หรือใหม่กว่าสำหรับ TUN ทั้งสี่สแตก โปรโตคอลและการกำหนดเส้นทางยังอยู่ใน Xray กฎแอปในรูปแบบนี้รองรับเฉพาะการเชื่อมต่อโดยตรงและการบล็อก บน Linux กฎเหล่านี้ต้องใช้ gVisor ในตัวของ Xray\n\nบริดจ์รันกระบวนการที่สอง ในการวัดที่ไม่ได้ใช้งานสามครั้งบน Linux นั้น ใช้หน่วยความจำกายภาพมากกว่าประมาณ 32–36 MiB มากกว่า Xray TUN ดั้งเดิม สิ่งนี้ไม่ได้วัดปริมาณการดาวน์โหลด: ต้นทุน CPU และหน่วยความจำขึ้นอยู่กับการเชื่อมต่อ sing-box ไม่มีตัวเลือกสแต็ก ไม่มีสแต็กรับประกันประสิทธิภาพที่ดีขึ้นในทุกเครือข่าย เลือกสแต็กแล้วเลือกใช้และเชื่อมต่อใหม่เพื่อลองใช้ในเครือข่ายของคุณ\n\n## กำลังใช้การตั้งค่า\n\nการเลือกเซิร์ฟเวอร์จะเชื่อมต่อใหม่โดยอัตโนมัติ การตั้งค่าโหมด กลไก DNS และกฎจะถูกบันทึกทันที ในระหว่างการเชื่อมต่อที่ใช้งานอยู่ ให้คลิก ใช้ และเชื่อมต่อใหม่เพื่อใช้งาน การรีสตาร์ทเครื่องยนต์อาจขัดจังหวะการดาวน์โหลดและการโทร การคลิกซ้ำๆ จะไม่เริ่มการเชื่อมต่อแบบขนาน การยกเลิกการเชื่อมต่อจะเป็นการสิ้นสุดการเปลี่ยนแปลงและปล่อยการเชื่อมต่อ\n\nอินเทอร์เน็ตผ่าน VPN เท่านั้นที่จะบล็อกการรับส่งข้อมูลโดยตรงเมื่ออุโมงค์ล่ม มันกระทบทั้งเครื่อง การตัดการเชื่อมต่อที่ชัดเจนจะลบกฎของ Sora หากการล้างข้อมูลไม่เสร็จสิ้น ให้ลองยกเลิกการเชื่อมต่ออีกครั้งและเปิดบันทึก\n\n## เอกสารประกอบโครงการ\n\n- [sing-box-lx: การกำหนดค่าและการสนับสนุน](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [เอกสารประกอบ sing-box](https://sing-box.sagernet.org/)\n- [เอกสารประกอบ Xray](https://xtls.github.io/)\n- [เอกสารประกอบ mihomo](https://wiki.metacubex.one/)\n- [zapret: การทำงานและข้อจำกัด](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'ตรวจสอบเซิร์ฟเวอร์';

  @override
  String get extensions => 'ส่วนขยาย';

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
    return 'บันทึกเป็น $name';
  }

  @override
  String get diagnosticHttp => 'การวินิจฉัย HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'ยังไม่มีการร้องขอที่บันทึกไว้ เปิดเว็บไซต์ทดสอบความเร็วก่อน';

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
