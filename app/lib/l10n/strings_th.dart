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
      'เลือกอัตโนมัติหากคุณไม่แน่ใจว่าเซิร์ฟเวอร์ของคุณต้องการเอ็นจิ้นใด Sora ตรวจสอบโปรไฟล์และการตั้งค่าก่อนเชื่อมต่อ กลไกไม่สามารถเพิ่มแบนด์วิธของแผนของคุณได้: ประสิทธิภาพขึ้นอยู่กับเซิร์ฟเวอร์ เส้นทาง โปรโตคอล และเครือข่าย\n\n## โหมด\n\n### การจราจรทั้งหมด (TUN)\n\nSora สร้างอินเทอร์เฟซเครือข่ายเสมือนและกำหนดเส้นทางการรับส่งข้อมูลแอปพลิเคชัน รวมถึง TCP และ UDP ใช้โหมดนี้สำหรับ Telegram เกม และเสียง Discord กฎสามารถส่งไซต์หรือโปรแกรมเฉพาะได้โดยตรงหรือบล็อกไซต์หรือโปรแกรมเหล่านั้น บริการเครือข่ายจำเป็นต้องได้รับอนุญาตและเซิร์ฟเวอร์ที่รองรับโปรโตคอลที่จำเป็น\n\n### พร็อกซี System\n\nSora กำหนดค่าพร็อกซี HTTP/SOCKS ในเครื่อง แอปพลิเคชันที่เคารพการตั้งค่าพร็อกซีของระบบจะใช้งาน แอปพลิเคชันที่มีสแต็กเครือข่ายของตนเองอาจเชื่อมต่อโดยตรง โดยทั่วไป UDP และการโทรด้วยเสียงต้องใช้ TUN โหมดนี้เหมาะกับเบราว์เซอร์และแอปพลิเคชันที่รองรับพร็อกซี\n\n### ไม่มีเซิร์ฟเวอร์\n\nใน Linux นั้น Sora ใช้ [zapret](https://github.com/bol-van/zapret) เพื่อแยกและปรับแต่งคำขอ HTTP/TLS และข้ามการตรวจสอบ DPI บางอย่าง IP ของคุณยังคงเหมือนเดิมและการเชื่อมต่อจะไปยังเว็บไซต์โดยตรง ผลลัพธ์ขึ้นอยู่กับผู้ให้บริการของคุณและวิธีการบล็อก\n\nการรวมปัจจุบันใช้ tpws สำหรับ HTTP และ TLS ผ่าน TCP ไม่หลีกเลี่ยงการบล็อก IP หรือรีเลย์ UDP และไม่สามารถรับประกันการเชื่อมต่อ Telegram ของ MTProto ได้ ใช้เซิร์ฟเวอร์ VPN พร้อม TUN สำหรับเสียง Discord, การโทร Telegram และข้อจำกัดประเภทนี้\n\n## เครื่องยนต์\n\n### ออโต้\n\nSora เลือกเอ็นจิ้นที่ติดตั้งซึ่งสนับสนุนแผนการเชื่อมต่อทั้งหมด: โปรโตคอลเซิร์ฟเวอร์ การขนส่ง กลุ่ม การกระจายตัว และโหมด ตัวเลือกด้วยตนเองที่เข้ากันไม่ได้จะถูกปฏิเสธก่อนที่จะหยุดการเชื่อมต่อปัจจุบัน เลือกอัตโนมัติหรือเครื่องยนต์อื่นแล้วใช้การตั้งค่าอีกครั้ง\n\n### sing-box\n\nแพ็คเกจ Sora ใหม่ประกอบด้วย [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) ซึ่งเป็นทางแยกของ [sing-box](https://github.com/SagerNet/sing-box) โดยเพิ่ม XHTTP และ VLESS Encryption ฝั่งไคลเอ็นต์ Sora จดจำบิลด์และความสามารถของมัน การสร้างอัพสตรีมที่ไม่มี XHTTP จะไม่ได้รับความสามารถนี้จากชื่อเพียงอย่างเดียว\n\nโปรโตคอลที่รองรับ ได้แก่ VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard และพารามิเตอร์ AmneziaWG 1.x/2.x Sora สามารถนำเข้าได้ โปรไฟล์ Xray JSON แบบเต็มต้องใช้ Xray ยังไม่สามารถนำเข้าฟิลด์ AWG 3.x ใหม่ได้ sing-box ใช้พอร์ตควบคุมภายในที่มีการป้องกันด้วยรหัสผ่าน ซึ่งแอปพลิเคชันอื่นบนคอมพิวเตอร์สามารถตรวจพบได้\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) รองรับการแยกส่วน VLESS, REALITY, XHTTP, VLESS Encryption และการกระจายตัวของ TLS นอกจากนี้ยังรันโปรไฟล์ผู้ให้บริการ Xray ที่สมบูรณ์โดยยังคงรักษาการกำหนดเส้นทางและกลุ่มไว้ โปรไฟล์ดังกล่าวไม่สามารถแปลงเป็นเอ็นจิ้นอื่นโดยอัตโนมัติโดยไม่เปลี่ยนพฤติกรรม\n\nXray ที่ให้มาได้ลบการตั้งค่าที่ปิดใช้งานการตรวจสอบใบรับรอง TLS (`allowInsecure`) เลือก sing-box หรือ mihomo อัตโนมัติสำหรับเซิร์ฟเวอร์ทั่วไปที่ต้องการการตั้งค่านี้ การเลือก Xray จะรายงานความไม่เข้ากันด้วยตนเองก่อนที่จะหยุดการเชื่อมต่อปัจจุบัน โปรไฟล์ JSON แบบเต็มรุ่นเก่าต้องมีโปรไฟล์ผู้ให้บริการที่อัปเดตพร้อมใบรับรองที่ตรวจสอบได้หรือ PIN ใบรับรอง\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) รองรับกลุ่มทางเลือกสำรองและกลุ่มบาลานซ์โหลด, XHTTP และ AmneziaWG เลือกเมื่อการเฟลโอเวอร์อัตโนมัติไปยังเซิร์ฟเวอร์สำรองมีความสำคัญ การตั้งค่าการกระจายตัวของ TLS ของ Sora ไม่พร้อมใช้งานกับกลไกนี้\n\n## ความเข้ากันได้ใน Sora\n\n| คุณสมบัติ | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN และ TCP/UDP | ใช่ | ใช่ | ใช่ |\n| XHTTP | ใช่ | ใช่ | ใช่ |\n| VLESS Encryption | ใช่ | ใช่ | ใช่ |\n| โปรไฟล์ Xray แบบเต็ม | ไม่ | ใช่ | ไม่ |\n| TUIC / AnyTLS | ทั้งสอง | ไม่ | TUIC |\n| การกระจายตัวของ TLS | ใช่ | ใช่ | ไม่ |\n| AmneziaWG 1.x/2.x | ใช่¹ | ไม่ | ใช่ |\n| จัดกลุ่มสำรอง | ไม่ | โน² | ใช่ |\n\n¹ โปรไฟล์ที่มี J1/J2/J3/Itime ใช้ mihomo; ฟิลด์เหล่านี้จะต้องไม่ถูกละทิ้งอย่างเงียบๆ ² สำหรับกลุ่มโปรไฟล์ Xray ที่สมบูรณ์ แอปจะเลือกโปรไฟล์สำรอง การสนับสนุนขึ้นอยู่กับบิลด์ที่ติดตั้ง ตรวจสอบเวอร์ชันในเกี่ยวกับ\n\n## กอง TUN\n\nสแต็กจัดการ TCP และ UDP ภายในอินเทอร์เฟซเสมือน ในแผงโหมด Xray และ mihomo มี gVisor, System, Mixed และ MIPS เครื่องยนต์แต่ละตัวจะบันทึกการตั้งค่าของตัวเอง พร็อกซี System และโหมด Serverless ไม่ได้ใช้การกำหนดค่าตามความชอบนี้\n\n- **Mixed** — TCP ใช้สแต็กของระบบ ในขณะที่ gVisor จัดการ UDP นี่เป็นค่าเริ่มต้นสำหรับ mihomo\n- **System** — ใช้สแต็กระบบ ลองใช้ตัวเลือกอื่นหากแอปพลิเคชันเครือข่ายประสบปัญหา\n- **gVisor** — จัดการการรับส่งข้อมูลในพื้นที่ผู้ใช้\n- **MIPS** — IP Stack ของ mihomo เอง มีให้ใช้งานในเวอร์ชันบันเดิล 1.19.32\n\nบน Linux นั้น Xray จะใช้ gVisor ในตัวเป็นค่าเริ่มต้น System, Mixed และ MIPS บน Linux ใช้ mihomo เป็นกลไก TUN โดยส่งต่อ TCP และ UDP ไปยัง Xray ผ่านลิงก์ SOCKS ท้องถิ่นที่ได้รับการรับรองความถูกต้อง Xray ยังคงรักษาโปรโตคอล โปรไฟล์ผู้ให้บริการ และการกำหนดเส้นทางไว้ ตัวเลือกทั้งสามนี้จำเป็นต้องมี mihomo ที่ติดตั้งไว้ บน Windows Xray ใช้ mihomo 1.19.32 หรือใหม่กว่าสำหรับ TUN ทั้งสี่สแตก โปรโตคอลและการกำหนดเส้นทางยังอยู่ใน Xray กฎแอปในรูปแบบนี้รองรับเฉพาะการเชื่อมต่อโดยตรงและการบล็อก บน Linux กฎเหล่านี้ต้องใช้ gVisor ในตัวของ Xray\n\nบริดจ์รันกระบวนการที่สอง ในการวัดที่ไม่ได้ใช้งานสามครั้งบน Linux นั้น ใช้หน่วยความจำกายภาพมากกว่าประมาณ 32–36 MiB มากกว่า Xray TUN ดั้งเดิม สิ่งนี้ไม่ได้วัดปริมาณการดาวน์โหลด: ต้นทุน CPU และหน่วยความจำขึ้นอยู่กับการเชื่อมต่อ เก็บ gVisor ไว้ เว้นแต่ว่าคุณต้องการสแต็กอื่น sing-box ไม่มีตัวเลือกสแต็ก ไม่มีสแต็กรับประกันประสิทธิภาพที่ดีขึ้นในทุกเครือข่าย เลือกสแต็กแล้วเลือกใช้และเชื่อมต่อใหม่เพื่อลองใช้ในเครือข่ายของคุณ\n\n## กำลังใช้การตั้งค่า\n\nการเลือกเซิร์ฟเวอร์จะเชื่อมต่อใหม่โดยอัตโนมัติ การตั้งค่าโหมด กลไก DNS และกฎจะถูกบันทึกทันที ในระหว่างการเชื่อมต่อที่ใช้งานอยู่ ให้คลิก ใช้ และเชื่อมต่อใหม่เพื่อใช้งาน การรีสตาร์ทเครื่องยนต์อาจขัดจังหวะการดาวน์โหลดและการโทร การคลิกซ้ำๆ จะไม่เริ่มการเชื่อมต่อแบบขนาน การยกเลิกการเชื่อมต่อจะเป็นการสิ้นสุดการเปลี่ยนแปลงและปล่อยการเชื่อมต่อ\n\nอินเทอร์เน็ตผ่าน VPN เท่านั้นที่จะบล็อกการรับส่งข้อมูลโดยตรงเมื่ออุโมงค์ล่ม มันกระทบทั้งเครื่อง การตัดการเชื่อมต่อที่ชัดเจนจะลบกฎของ Sora หากการล้างข้อมูลไม่เสร็จสิ้น ให้ลองยกเลิกการเชื่อมต่ออีกครั้งและเปิดบันทึก\n\n## เอกสารประกอบโครงการ\n\n- [sing-box-lx: การกำหนดค่าและการสนับสนุน](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [เอกสารประกอบ sing-box](https://sing-box.sagernet.org/)\n- [เอกสารประกอบ Xray](https://xtls.github.io/)\n- [เอกสารประกอบ mihomo](https://wiki.metacubex.one/)\n- [zapret: การทำงานและข้อจำกัด](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'ตรวจสอบเซิร์ฟเวอร์';

  @override
  String get extensions => 'ส่วนขยาย';

  @override
  String get extensionsSoon => 'เร็วๆ นี้';

  @override
  String exportLogFile(String name) {
    return 'บันทึกเป็น $name';
  }

  @override
  String get diagnosticHttp => 'การวินิจฉัย HTTP';

  @override
  String get diagnosticPackets => 'การจับแพ็คเก็ต';

  @override
  String get diagnosticEvents => 'เหตุการณ์ของวินโดวส์';

  @override
  String get diagnosticCapture => 'จับภาพเป็นเวลา 10 วินาที';

  @override
  String get diagnosticNoData => 'ยังไม่มีการร้องขอที่บันทึกไว้ เปิดเว็บไซต์ทดสอบความเร็วก่อน';

  @override
  String get diagnosticRequiresTun => 'การจับแพ็คเก็ตจำเป็นต้องมีการเชื่อมต่อ Sora TUN ที่ใช้งานอยู่';

  @override
  String get diagnosticUnavailable => 'การวินิจฉัยนี้ไม่พร้อมใช้งานบนแพลตฟอร์มนี้';
}
