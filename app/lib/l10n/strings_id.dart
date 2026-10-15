// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class SId extends S {
  SId([String locale = 'id']) : super(locale);

  @override
  String get stateOff => 'Tidak terhubung';

  @override
  String get stateConnecting => 'Menghubungkan';

  @override
  String get stateConnected => 'Terhubung';

  @override
  String get stateReconnecting => 'Menghubungkan kembali';

  @override
  String get stateDisconnecting => 'Memutuskan sambungan';

  @override
  String get stateFailed => 'Tidak terhubung';

  @override
  String get coreMissing => 'Layanan Sora tidak merespons';

  @override
  String get serverAuto => 'Tercepat';

  @override
  String get serverBypass => 'Tidak ada server';

  @override
  String get addSubscription => 'Tambahkan langganan';

  @override
  String get servers => 'Server';

  @override
  String get settings => 'Pengaturan';

  @override
  String get subscription => 'Berlangganan';

  @override
  String get subscriptionLink => 'Tautan berlangganan';

  @override
  String get add => 'Menambahkan';

  @override
  String get refresh => 'Memperbarui';

  @override
  String get rename => 'Ganti nama';

  @override
  String get delete => 'Menghapus';

  @override
  String get cancel => 'Membatalkan';

  @override
  String get save => 'Menyimpan';

  @override
  String get name => 'Nama';

  @override
  String deleteSubscription(String name) {
    return 'Hapus “$name”?';
  }

  @override
  String get routes => 'Rute';

  @override
  String get presetGlobal => 'Semuanya melalui VPN';

  @override
  String get presetRu => 'Rusia langsung';

  @override
  String get presetIr => 'Iran langsung';

  @override
  String get presetCn => 'Cina langsung';

  @override
  String get blockAds => 'Blokir iklan';

  @override
  String get killSwitch => 'Internet hanya melalui VPN';

  @override
  String get engine => 'Mesin';

  @override
  String get engineAuto => 'Mobil';

  @override
  String get animations => 'Animasi';

  @override
  String get logs => 'Catatan';

  @override
  String get about => 'Tentang';

  @override
  String get logsAll => 'Semua';

  @override
  String get logsImportant => 'Penting';

  @override
  String get logsErrors => 'Kesalahan';

  @override
  String get search => 'Mencari';

  @override
  String get export => 'Simpan ke file';

  @override
  String get clear => 'Jernih';

  @override
  String get logsEmpty => 'Tidak ada apa pun di sini';

  @override
  String appVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get notInstalled => 'Tidak dipasang';

  @override
  String get sourceCode => 'Kode sumber';

  @override
  String get license => 'Lisensi';

  @override
  String usage(String used, String total) {
    return '$used dari $total';
  }

  @override
  String until(String date) {
    return 'sampai $date';
  }

  @override
  String get expired => 'Kedaluwarsa';

  @override
  String milliseconds(int n) {
    return '$n ms';
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
  String get errGeneric => 'Ada yang tidak beres';

  @override
  String get errCore => 'Layanan Sora tidak merespons';

  @override
  String get errAuth => 'Tidak ada akses ke layanan Sora';

  @override
  String get errVersion => 'Perbarui Sora: aplikasi dan layanan memiliki versi yang berbeda';

  @override
  String get errBusy => 'Tunggu, perintah sebelumnya masih berjalan';

  @override
  String get errEngineMissing => 'Tidak ada mesin yang ditemukan untuk server ini';

  @override
  String get errEngineStart => 'Mesinnya tidak menyala';

  @override
  String get errEngineStopped => 'Mesinnya berhenti';

  @override
  String get errTunnel => 'Tidak ada izin untuk membuat koneksi VPN';

  @override
  String get errServers => 'Server dikonfigurasi dengan kesalahan';

  @override
  String get errNetwork => 'Tidak dapat menjangkau server';

  @override
  String get errTimeout => 'Server tidak menjawab tepat waktu';

  @override
  String get errFirewall => 'Tidak dapat memblokir internet di luar VPN';

  @override
  String get errSubFetch => 'Tidak dapat memuat langganan';

  @override
  String get errSubFormat => 'Ini bukan tautan berlangganan';

  @override
  String get errSubEmpty => 'Langganan tidak memiliki server';

  @override
  String get errSubDuplicate => 'Langganan ini sudah ditambahkan';

  @override
  String get errSubLimit => 'Terlalu banyak langganan';

  @override
  String get errSubScheme => 'Tautan harus dimulai dengan https://';

  @override
  String get errSecretStore => 'Penyimpanan Sora rusak atau tidak tersedia';

  @override
  String get errNoServers => 'Tambahkan langganan untuk terhubung';

  @override
  String get exportText => 'Teks';

  @override
  String get connections => 'Koneksi';

  @override
  String get close => 'Menutup';

  @override
  String get chainDirect => 'Langsung';

  @override
  String get chainBlocked => 'Diblokir';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lampu';

  @override
  String get themeDark => 'Gelap';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Koneksi';

  @override
  String get sectionNoServer => 'Tidak ada server';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostik';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Mobil';

  @override
  String get dnsHint => 'Alamat, dipisahkan koma';

  @override
  String get fragment => 'Fragmentasi TLS';

  @override
  String get fragmentPackets => 'Apa yang harus dibagi';

  @override
  String get fragmentLength => 'Ukuran potongan';

  @override
  String get fragmentInterval => 'Jeda antar bagian';

  @override
  String get byDefault => 'Bawaan';

  @override
  String get rangeHint => 'Misalnya 100-200';

  @override
  String get splitPos => 'Pisahkan posisi';

  @override
  String get splitPosHint => 'Misalnya, 1, menengah';

  @override
  String get disorder => 'Susun ulang potongan';

  @override
  String get tlsRecord => 'Pisahkan data TLS';

  @override
  String get tlsRecordNo => 'TIDAK';

  @override
  String get tlsRecordSni => 'Atas nama situs';

  @override
  String get tlsRecordFirst => 'Setelah byte pertama';

  @override
  String get hostCase => 'Ubah kasus Host';

  @override
  String get probeMethod => 'Metode';

  @override
  String get probeAuto => 'Mobil';

  @override
  String get probeEngine => 'Melalui mesin';

  @override
  String get probeConnect => 'Koneksi saja';

  @override
  String get probeUrl => 'Alamat tes';

  @override
  String get probeTimeout => 'Tunggu';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Langganan';

  @override
  String get subscriptionSettings => 'Pengaturan';

  @override
  String get userAgent => 'Agen-Pengguna';

  @override
  String get autoUpdate => 'Perbarui secara otomatis';

  @override
  String get updateInterval => 'seberapa sering';

  @override
  String get intervalProvider => 'Seperti yang diminta penyedia';

  @override
  String hours(int n) {
    return '$n jam';
  }

  @override
  String get updateNow => 'Perbarui sekarang';

  @override
  String get logLevel => 'Apa yang harus direkam';

  @override
  String get levelDebug => 'Semuanya';

  @override
  String get levelInfo => 'Biasa';

  @override
  String get levelWarning => 'Penting';

  @override
  String get levelError => 'Hanya kesalahan';

  @override
  String get recordDestinations => 'Catat alamat situs';

  @override
  String get reset => 'Atur ulang pengaturan';

  @override
  String get resetConfirm => 'Reset semua pengaturan?';

  @override
  String get resetAction => 'Mengatur ulang';

  @override
  String get invalidValue => 'Nilai ini tidak akan berfungsi';

  @override
  String get website => 'Halaman berlangganan';

  @override
  String get providerWebsite => 'Situs web penyedia';

  @override
  String get support => 'Mendukung';

  @override
  String controlPortQuestion(String engine) {
    return '$engine dikontrol melalui port di komputer ini. Program lain akan dapat mengetahui bahwa VPN aktif.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Pilih $engine';
  }

  @override
  String get rules => 'Aturan adat';

  @override
  String get ruleAdd => 'Aturan baru';

  @override
  String get ruleHint => 'Situs, IP atau program';

  @override
  String get ruleDirect => 'Langsung';

  @override
  String get ruleProxy => 'Melalui VPN';

  @override
  String get ruleBlock => 'Memblokir';

  @override
  String get failover => 'Aktifkan kegagalan';

  @override
  String get connectOnStart => 'Hubungkan di awal';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'langganan berakhir dalam # hari',
      one: 'langganan berakhir pada hari #',
      zero: 'langganan berakhir dalam beberapa jam',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left kiri';
  }

  @override
  String get ruleInvalid => 'Ini tidak terlihat seperti situs, IP, atau program';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Server #, pada gilirannya',
      one: 'Server #, pada gilirannya',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Server #, tercepat',
      one: 'Server #, tercepat',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelTun => 'Semua lalu lintas';

  @override
  String get tunnelProxy => 'Proksi System';

  @override
  String get proxyAddress => 'Alamat proksi';

  @override
  String get copied => 'Disalin';

  @override
  String get launchAtLogin => 'Mulailah dengan sistem';

  @override
  String get closeToTray => 'Simpan di dalam baki dalam keadaan tertutup';

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get trayOpen => 'Buka Sora';

  @override
  String get trayConnect => 'Menghubungkan';

  @override
  String get trayDisconnect => 'Memutuskan';

  @override
  String get trayServer => 'pelayan';

  @override
  String get trayQuit => 'Keluar dari Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora masih ada di baki';

  @override
  String get noticeInTrayBody => 'Keluar dari menu ikonnya';

  @override
  String get noticeLost => 'Koneksi terputus';

  @override
  String get noticeLostBody => 'Sora tersambung kembali';

  @override
  String get noticeRestored => 'Terhubung lagi';

  @override
  String get noticeFailed => 'Tidak dapat terhubung';

  @override
  String get noticeBackup => 'Server utama tidak menjawab; cadangan membawa lalu lintas';

  @override
  String get noticeNext => 'Server tidak menjawab; yang berikutnya membawa lalu lintas';

  @override
  String get noticeMainBack => 'Server utama menjawab lagi dan membawa lalu lintas';

  @override
  String get noticeSubscription => 'Berlangganan';

  @override
  String get importTitle => 'Tambahkan langganan ini?';

  @override
  String get importSealed =>
      'Tautan ini dienkripsi untuk Happ, dan hanya Happ yang dapat membacanya. Tanyakan penyedia Anda untuk tautan berlangganan biasa.';

  @override
  String get understood => 'OKE';

  @override
  String get noAnswer => 'tidak ada jawaban';

  @override
  String get home => 'Rumah';

  @override
  String get navRules => 'Aturan';

  @override
  String get navConnections => 'Koneksi';

  @override
  String get navLogs => 'Log';

  @override
  String get navAbout => 'Tentang';

  @override
  String get sidebarToggle => 'Alihkan bilah sisi';

  @override
  String get more => 'Lagi';

  @override
  String get less => 'Lebih sedikit';

  @override
  String get currentServer => 'Server saat ini';

  @override
  String get trafficDown => 'Diunduh';

  @override
  String get trafficUp => 'Diunggah';

  @override
  String perSecond(String value) {
    return '$value/dtk';
  }

  @override
  String activeRules(int count) {
    return 'Aturan aktif: $count';
  }

  @override
  String get recentNotifications => 'Pemberitahuan terkini';

  @override
  String get notificationsEmpty => 'Peristiwa koneksi dan langganan akan muncul di sini';

  @override
  String get retryConnect => 'Coba lagi koneksi';

  @override
  String get openLogs => 'Buka log';

  @override
  String get tourReplay => 'Tampilkan panduan lagi';

  @override
  String tourStep(int step) {
    return 'Langkah $step dari 5';
  }

  @override
  String get tourBack => 'Kembali';

  @override
  String get tourNext => 'Berikutnya';

  @override
  String get tourSkip => 'Melewati';

  @override
  String get tourFinish => 'Selesai';

  @override
  String get tourAdd => 'Tambahkan tautan berlangganan penyedia Anda.';

  @override
  String get tourServer => 'Pilih server. “Tercepat” memilih satu untuk Anda.';

  @override
  String get tourConnect => 'Klik di sini untuk menghubungkan atau memutuskan sambungan.';

  @override
  String get tourMode => 'Pilih mode. Tombol pemutus memblokir internet jika VPN terputus.';

  @override
  String get tourSettings => 'Buka pengaturan. Anda dapat memutar ulang panduan ini di sana.';

  @override
  String get chooseProgram => 'Pilih sebuah program';

  @override
  String get installedApps => 'Aplikasi yang diinstal';

  @override
  String get runningProcesses => 'Proses yang berjalan';

  @override
  String get programsFailed => 'Tidak dapat memuat aplikasi';

  @override
  String get programsEmpty => 'Tidak ada aplikasi yang ditemukan. Coba nama lain.';

  @override
  String get selectExe => 'Pilih file .exe';

  @override
  String get trafficUnavailable => 'Counter belum tersedia';

  @override
  String get speedtest => 'Kecepatan';

  @override
  String get speedtestCheck => 'Periksa kecepatan';

  @override
  String get speedtestSearch => 'Temukan layanan';

  @override
  String get speedtestEmpty => 'Tidak ada kecocokan. Ubah pencarian.';

  @override
  String get speedtestBackToList => 'Kembali ke layanan';

  @override
  String get speedtestOpenBrowser => 'Buka di peramban';

  @override
  String get speedtestUnavailable =>
      'Browser yang tertanam tidak dapat dijalankan. Buka layanan di browser sistem Anda.';

  @override
  String get speedtestPageFailed => 'Halaman tidak dapat dimuat. Muat ulang atau buka layanan di browser sistem Anda.';

  @override
  String get speedtestExternalFailed => 'Browser sistem tidak dapat dibuka. Coba lagi.';

  @override
  String get modes => 'Mode';

  @override
  String get proxyShort => 'Proksi';

  @override
  String get tunMode => 'Semua lalu lintas (TUN)';

  @override
  String get checkUpdates => 'Periksa pembaruan';

  @override
  String get updates => 'Pembaruan aplikasi';

  @override
  String updateAvailable(String version) {
    return 'Versi $version tersedia';
  }

  @override
  String get updateOpenAbout => 'Lihat pembaruan';

  @override
  String updateNotes(String version) {
    return 'Perubahan pada $version';
  }

  @override
  String get updateCheck => 'Periksa pembaruan';

  @override
  String get updateChecking => 'Memeriksa...';

  @override
  String get updateNoNotes => 'Rilisan ini tidak memiliki catatan.';

  @override
  String get updateDropWarning =>
      'Koneksi VPN akan terputus selama beberapa detik saat Sora dan pembaruan intinya. Melanjutkan?';

  @override
  String get updateWaitConnection => 'Tunggu hingga koneksi dan inti VPN siap.';

  @override
  String get updateDownloading => 'Mengunduh dan memverifikasi file...';

  @override
  String get updateInstalling => 'Mempersiapkan pembaruan atau menunggu otentikasi administrator...';

  @override
  String get updateNetworkError => 'Tidak dapat mengunduh pembaruan. Coba lagi.';

  @override
  String get updateReleaseError => 'Data rilis atau file yang diperlukan hilang atau tidak valid.';

  @override
  String get updateChecksumError => 'Unduhan tidak cocok dengan SHA256SUMS. Tidak ada yang dipasang.';

  @override
  String get updateInstallError => 'Pembaruan tidak selesai. Otentikasi mungkin telah dibatalkan.';

  @override
  String get updateUnsupported =>
      'Eksekusi ini tidak dimiliki oleh pasangan paket Sora yang didukung. Gunakan petunjuk instalasi rilis.';

  @override
  String get updateManual =>
      'Jalankan perintah ini di terminal untuk menginstal kedua paket terverifikasi, lalu buka kembali Sora. File-file tersebut tetap berada di direktori unduhan. Koneksi VPN akan terputus.';

  @override
  String get updateCopyCommand => 'Salin perintah';

  @override
  String get updateChecksDisabled => 'Pemeriksaan otomatis dinonaktifkan di Pengaturan.';

  @override
  String get updateInstalled => 'Pembaruan diinstal. Buka kembali Sora.';

  @override
  String get projectLinks => 'Proyek';

  @override
  String get githubReleases => 'Rilis dan unduhan';

  @override
  String get telegramChannel => 'saluran Telegram';

  @override
  String get licenses => 'Lisensi';

  @override
  String get componentLicenses => 'Lisensi komponen';

  @override
  String get appCopyright => '© 2026 levvs-one dan kontributor';

  @override
  String get collapseServers => 'Ciutkan server';

  @override
  String get expandServers => 'Perluas server';

  @override
  String get hideDescription => 'Sembunyikan deskripsi';

  @override
  String get showDescription => 'Tampilkan deskripsi';

  @override
  String get pendingConnectionChanges => 'Hubungkan kembali untuk menerapkan perubahan ini.';

  @override
  String get reconnectNow => 'Terapkan dan sambungkan kembali';

  @override
  String get bypassLimitations =>
      'Mode ini melewati DPI hanya untuk HTTP dan TLS, tidak mendukung UDP atau mengubah IP Anda. Gunakan server VPN untuk suara Discord, panggilan, dan alamat Telegram yang diblokir.';

  @override
  String get errEngineUnsupported =>
      'Mesin yang dipilih tidak mendukung profil atau pengaturan ini. Pilih Otomatis atau mesin yang kompatibel.';

  @override
  String get errRestore =>
      'Pembersihan koneksi tidak lengkap. Coba lagi memutuskan sambungan; lihat log untuk detailnya.';

  @override
  String get errSessionEnded => 'Sesi ini telah berakhir. Segarkan status koneksi.';

  @override
  String get retryDisconnect => 'Coba lagi putuskan sambungan';

  @override
  String get tunStack => 'tumpukan TUN';

  @override
  String get modesInfo => 'Tentang mode';

  @override
  String get modesGuideTitle => 'Mode dan mesin';

  @override
  String get modesGuide =>
      'Pilih Otomatis jika Anda tidak yakin mesin mana yang dibutuhkan server Anda. Sora memeriksa profil dan pengaturan sebelum menghubungkan. Mesin tidak dapat meningkatkan bandwidth paket Anda: kinerja bergantung pada server, rute, protokol, dan jaringan.\n\n## Mode\n\n### Semua lalu lintas (TUN)\n\nSora membuat antarmuka jaringan virtual dan merutekan lalu lintas aplikasi melaluinya, termasuk TCP dan UDP. Gunakan mode ini untuk Telegram, game, dan suara Discord. Aturan dapat mengirim situs atau program tertentu secara langsung atau memblokirnya. Layanan jaringan memerlukan izin dan server yang mendukung protokol yang diperlukan.\n\n### Proksi System\n\nSora mengonfigurasi proksi HTTP/SOCKS lokal. Aplikasi yang menghormati pengaturan proxy sistem menggunakannya. Aplikasi dengan tumpukan jaringannya sendiri dapat terhubung secara langsung; UDP dan panggilan suara umumnya memerlukan TUN. Mode ini cocok untuk browser dan aplikasi dengan dukungan proxy.\n\n### Tidak ada server\n\nDi Linux, Sora menggunakan [zapret](https://github.com/bol-van/zapret) untuk membagi dan membentuk ulang permintaan HTTP/TLS dan melewati beberapa pemeriksaan DPI. IP Anda tetap sama dan koneksi langsung ke situs web. Hasil bergantung pada penyedia Anda dan metode pemblokiran.\n\nIntegrasi saat ini menggunakan tpws untuk HTTP dan TLS melalui TCP. Ini tidak melewati pemblokiran IP atau menyampaikan UDP, dan tidak dapat menjamin koneksi MTProto MTProto. Gunakan server VPN dengan TUN untuk suara Discord, panggilan Telegram dan pembatasan semacam ini.\n\n## Mesin\n\n### Otomatis\n\nSora memilih mesin terinstal yang mendukung seluruh paket koneksi: protokol server, transport, grup, fragmentasi, dan mode. Pilihan manual yang tidak kompatibel ditolak sebelum menghentikan koneksi saat ini. Pilih Otomatis atau mesin lain dan terapkan kembali pengaturannya.\n\n### sing-box\n\nPaket Sora baru mencakup [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), fork dari [sing-box](https://github.com/SagerNet/sing-box), menambahkan XHTTP dan VLESS Encryption sisi klien. Sora mengenali build dan kemampuannya. Build upstream tanpa XHTTP tidak mendapatkan kemampuan ini hanya dari namanya saja.\n\nProtokol yang didukung mencakup parameter VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard dan AmneziaWG 1.x/2.x Sora dapat mengimpor. Profil JSON Xray lengkap memerlukan Xray. Bidang AWG 3.x baru belum dapat diimpor. sing-box menggunakan port kontrol lokal yang dilindungi kata sandi, yang dapat dideteksi oleh aplikasi lain di komputer.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) mendukung fragmentasi VLESS, REALITY, XHTTP, VLESS Encryption dan TLS. Ini juga menjalankan profil lengkap penyedia Xray sambil mempertahankan perutean dan grupnya. Profil tersebut tidak dapat secara otomatis dikonversi ke mesin lain tanpa mengubah perilakunya.\n\nXray yang dibundel menghapus pengaturan yang menonaktifkan verifikasi sertifikat TLS (`allowInsecure`). Otomatis memilih sing-box atau mihomo untuk server biasa yang memerlukan pengaturan ini. Memilih Xray secara manual melaporkan ketidakcocokan sebelum menghentikan koneksi saat ini. Profil JSON lengkap yang lebih lama memerlukan profil penyedia yang diperbarui dengan sertifikat atau pin sertifikat yang dapat diverifikasi.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) mendukung grup fallback dan penyeimbang beban yang dipesan, XHTTP dan AmneziaWG. Pilih ketika failover otomatis ke server cadangan penting. Pengaturan fragmentasi TLS Sora tidak tersedia dengan mesin ini.\n\n## Kompatibilitas di Sora\n\n| Fitur | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN dan TCP/UDP | Ya | Ya | Ya |\n| XHTTP | Ya | Ya | Ya |\n| VLESS Encryption | Ya | Ya | Ya |\n| Profil lengkap Xray | Tidak | Ya | Tidak |\n| TUIC / AnyTLS | Keduanya | Tidak | TUIC |\n| Fragmentasi TLS | Ya | Ya | Tidak |\n| AmneziaWG 1.x/2.x | Ya¹ | Tidak | Ya |\n| Grup cadangan yang dipesan | Tidak | Tidak² | Ya |\n\n¹ Profil dengan J1/J2/J3/Itime menggunakan mihomo; bidang-bidang ini tidak boleh dibuang secara diam-diam. ² Untuk grup profil Xray lengkap, aplikasi memilih profil cadangan. Dukungan bergantung pada build yang diinstal; periksa versinya di Tentang.\n\n## Tumpukan TUN\n\nTumpukan menangani TCP dan UDP di dalam antarmuka virtual. Di panel mode, Xray dan mihomo menawarkan gVisor, System, Mixed dan MIPS. Setiap mesin menyimpan preferensinya sendiri. Proksi System dan mode Tanpa Server tidak menggunakan preferensi ini.\n\n- **Mixed** — TCP menggunakan tumpukan sistem, sedangkan gVisor menangani UDP. Ini adalah bawaan mihomo di Linux. Di Windows, Xray dan mihomo menggunakan MIPS secara bawaan.\n- **System** — menggunakan tumpukan sistem. Coba opsi lain jika aplikasi jaringan mengalami masalah.\n- **gVisor** — menangani lalu lintas di ruang pengguna.\n- **MIPS** — tumpukan IP milik mihomo, tersedia dalam paket versi 1.19.32.\n\nPada Linux, Xray menggunakan gVisor bawaannya secara default. System, Mixed dan MIPS di Linux menggunakan mihomo sebagai mesin TUN, meneruskan TCP dan UDP ke Xray melalui tautan SOCKS lokal yang diautentikasi. Xray mempertahankan protokol, profil penyedia, dan perutean. Ketiga opsi ini memerlukan mihomo yang diinstal. Pada Windows, Xray menggunakan mihomo 1.19.32 atau lebih baru untuk keempat tumpukan TUN. Protokol dan perutean tetap di Xray. Aturan aplikasi dalam kombinasi ini hanya mendukung koneksi langsung dan pemblokiran; di Linux aturan ini memerlukan gVisor bawaan Xray.\n\nJembatan menjalankan proses kedua. Dalam tiga pengukuran idle di Linux, memori fisik menggunakan sekitar 32–36 MiB lebih banyak daripada Xray TUN asli. Ini tidak mengukur beban pengunduhan: biaya CPU dan memori bergantung pada koneksi. sing-box tidak memiliki pemilih tumpukan. Tidak ada tumpukan yang menjamin kinerja lebih baik di setiap jaringan. Pilih tumpukan dan pilih Terapkan dan sambungkan kembali untuk mencobanya di jaringan Anda.\n\n## Menerapkan pengaturan\n\nMemilih server akan terhubung kembali secara otomatis. Pengaturan mode, mesin, DNS, dan aturan segera disimpan; selama koneksi aktif, klik Terapkan dan sambungkan kembali untuk menggunakannya. Memulai ulang mesin dapat mengganggu pengunduhan dan panggilan. Klik berulang kali tidak memulai koneksi paralel; pemutusan mengakhiri transisi dan melepaskan koneksi.\n\nInternet hanya melalui VPN memblokir lalu lintas langsung ketika terowongan terputus. Ini mempengaruhi keseluruhan mesin. Pemutusan hubungan secara eksplisit menghapus aturan Sora. Jika pembersihan tidak selesai, coba lagi putuskan sambungan dan buka log.\n\n## Dokumentasi proyek\n\n- [sing-box-lx: konfigurasi dan dukungan](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [dokumentasi sing-box](https://sing-box.sagernet.org/)\n- [dokumentasi Xray](https://xtls.github.io/)\n- [dokumentasi mihomo](https://wiki.metacubex.one/)\n- [zapret: pengoperasian dan batasan](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Periksa server';

  @override
  String get extensions => 'Ekstensi';

  @override
  String get extensionsSoon => 'Segera hadir';

  @override
  String exportLogFile(String name) {
    return 'Ke $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostik HTTP';

  @override
  String get diagnosticPackets => 'Penangkapan paket';

  @override
  String get diagnosticEvents => 'Acara Windows';

  @override
  String get diagnosticCapture => 'Tangkap selama 10 detik';

  @override
  String get diagnosticNoData => 'Belum ada permintaan yang tercatat. Buka situs tes kecepatan terlebih dahulu.';

  @override
  String get diagnosticRequiresTun => 'Pengambilan paket memerlukan koneksi Sora TUN yang aktif.';

  @override
  String get diagnosticUnavailable => 'Diagnostik ini tidak tersedia pada platform ini.';
}
