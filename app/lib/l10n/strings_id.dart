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
  String get connEmpty => 'Tidak ada koneksi';

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
  String get errAuth => 'Akses ke layanan Sora ditolak';

  @override
  String get errVersion => 'Versi aplikasi dan layanan Sora berbeda';

  @override
  String get errBusy => 'Perintah sebelumnya masih berjalan';

  @override
  String get errEngineMissing => 'Mesin yang diperlukan untuk server ini tidak ditemukan';

  @override
  String get errEngineStart => 'Mesin tidak dapat dimulai';

  @override
  String get errEngineStopped => 'Mesin berhenti';

  @override
  String get errTunnel => 'Mode VPN ini tidak tersedia';

  @override
  String get errTimeout => 'Server tidak merespons tepat waktu';

  @override
  String get errFirewall => 'Akses internet di luar VPN tidak dapat diblokir';

  @override
  String get errSubFetch => 'Langganan tidak dapat diunduh';

  @override
  String get errSubFormat => 'Format langganan tidak dikenali';

  @override
  String get errSubEmpty => 'Langganan ini tidak berisi server';

  @override
  String get errSubDuplicate => 'Langganan ini sudah ditambahkan';

  @override
  String get errSubLimit => 'Batas jumlah langganan telah tercapai';

  @override
  String get errSubScheme => 'Skema tautan langganan tidak didukung';

  @override
  String get errSecretStore => 'Penyimpanan Sora rusak atau tidak dapat diakses';

  @override
  String get errNoServers => 'Tidak ada server untuk dihubungkan';

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
  String get themeSystem => 'Ikuti sistem';

  @override
  String get themeLight => 'Lampu';

  @override
  String get themeDark => 'Gelap';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'Ikuti sistem';

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
  String get splitPos => 'Pisahkan posisi';

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
      other: 'langganan berakhir dalam $days hari',
      one: 'langganan berakhir pada hari $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Server $count, tercepat',
      one: 'Server $count, tercepat',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Mode';

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
  String get importSealed => 'Tautan ini dienkripsi untuk Happ, dan hanya Happ yang dapat membacanya';

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
  String get notificationsEmpty => 'Tidak ada notifikasi';

  @override
  String get retryConnect => 'Coba lagi koneksi';

  @override
  String get openLogs => 'Buka log';

  @override
  String get tourBack => 'Kembali';

  @override
  String get tourNext => 'Berikutnya';

  @override
  String get chooseProgram => 'Pilih sebuah program';

  @override
  String get installedApps => 'Aplikasi yang diinstal';

  @override
  String get runningProcesses => 'Proses yang berjalan';

  @override
  String get programsEmpty => 'Tidak ada aplikasi yang ditemukan';

  @override
  String get selectExe => 'Pilih file .exe';

  @override
  String get speedtest => 'Kecepatan';

  @override
  String get speedtestSearch => 'Temukan layanan';

  @override
  String get speedtestEmpty => 'Tidak ada kecocokan';

  @override
  String get speedtestBackToList => 'Kembali ke layanan';

  @override
  String get speedtestOpenBrowser => 'Buka di peramban';

  @override
  String get speedtestUnavailable => 'Browser yang tertanam tidak dapat dijalankan';

  @override
  String get speedtestPageFailed => 'Halaman tidak dapat dimuat';

  @override
  String get speedtestExternalFailed => 'Browser sistem tidak dapat dibuka';

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
  String get updateDropWarning => 'Putuskan koneksi untuk memperbarui?';

  @override
  String get updateWaitConnection => 'Koneksi belum siap';

  @override
  String get updateNetworkError => 'Tidak dapat mengunduh pembaruan';

  @override
  String get updateReleaseError => 'Data rilis atau file yang diperlukan hilang atau tidak valid.';

  @override
  String get updateChecksumError => 'Unduhan tidak cocok dengan SHA256SUMS';

  @override
  String get updateInstallError => 'Pembaruan tidak selesai';

  @override
  String get updateUnsupported => 'Eksekusi ini tidak dimiliki oleh pasangan paket Sora yang didukung';

  @override
  String get updateVersionRevoked => 'Pengembang telah menarik versi ini';

  @override
  String updateRollbacking(String version) {
    return 'Mengembalikan ke versi $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Pembaruan ke $version tidak lolos pemeriksaan kesehatan, jadi Sora dibatalkan ke $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Pengembalian otomatis gagal';

  @override
  String get updateRollbackCacheError =>
      'Tidak dapat menyiapkan salinan rollback terverifikasi dari versi saat ini, sehingga pembaruan tidak diinstal.';

  @override
  String get updateCopyCommand => 'Salin perintah';

  @override
  String get updateInstalled => 'Pembaruan diinstal';

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
  String get collapseServers => 'Ciutkan server';

  @override
  String get expandServers => 'Perluas server';

  @override
  String get hideDescription => 'Sembunyikan deskripsi';

  @override
  String get showDescription => 'Tampilkan deskripsi';

  @override
  String get errEngineUnsupported => 'Mesin yang dipilih tidak mendukung profil atau pengaturan ini';

  @override
  String get errRestore => 'Pembersihan koneksi tidak lengkap';

  @override
  String get errSessionEnded => 'Sesi ini telah berakhir';

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
      'Pilih Otomatis jika Anda tidak yakin mesin mana yang dibutuhkan server Anda. Sora memeriksa profil dan pengaturan sebelum menghubungkan. Mesin tidak dapat meningkatkan bandwidth paket Anda: kinerja bergantung pada server, rute, protokol, dan jaringan.\n\n## Mode\n\n### Semua lalu lintas (TUN)\n\nSora membuat antarmuka jaringan virtual dan merutekan lalu lintas aplikasi melaluinya, termasuk TCP dan UDP. Gunakan mode ini untuk Telegram, game, dan suara Discord. Aturan dapat mengirim situs atau program tertentu secara langsung atau memblokirnya. Layanan jaringan memerlukan izin dan server yang mendukung protokol yang diperlukan.\n\n### Proksi System\n\nSora mengonfigurasi proksi HTTP/SOCKS lokal. Aplikasi yang menghormati pengaturan proxy sistem menggunakannya. Aplikasi dengan tumpukan jaringannya sendiri dapat terhubung secara langsung; UDP dan panggilan suara umumnya memerlukan TUN. Mode ini cocok untuk browser dan aplikasi dengan dukungan proxy.\n\n### Tidak ada server\n\nDi Linux, Sora menggunakan [zapret](https://github.com/bol-van/zapret) untuk membagi dan membentuk ulang permintaan HTTP/TLS dan melewati beberapa pemeriksaan DPI. IP Anda tetap sama dan koneksi langsung ke situs web. Hasil bergantung pada penyedia Anda dan metode pemblokiran.\n\nIntegrasi saat ini menggunakan tpws untuk HTTP dan TLS melalui TCP. Ini tidak melewati pemblokiran IP atau menyampaikan UDP, dan tidak dapat menjamin koneksi MTProto MTProto. Gunakan server VPN dengan TUN untuk suara Discord, panggilan Telegram dan pembatasan semacam ini.\n\n## Mesin\n\n### Otomatis\n\nSora memilih mesin terinstal yang mendukung seluruh paket koneksi: protokol server, transport, grup, fragmentasi, dan mode. Pilihan manual yang tidak kompatibel ditolak sebelum menghentikan koneksi saat ini. Pilih Otomatis atau mesin lain dan terapkan kembali pengaturannya.\n\n### sing-box\n\nPaket Sora baru mencakup [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), fork dari [sing-box](https://github.com/SagerNet/sing-box), menambahkan XHTTP dan VLESS Encryption sisi klien. Sora mengenali build dan kemampuannya. Build upstream tanpa XHTTP tidak mendapatkan kemampuan ini hanya dari namanya saja.\n\nProtokol yang didukung mencakup parameter VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard dan AmneziaWG 1.x/2.x Sora dapat mengimpor. Profil JSON Xray lengkap memerlukan Xray. Bidang AWG 3.x baru belum dapat diimpor. sing-box menggunakan port kontrol lokal yang dilindungi kata sandi, yang dapat dideteksi oleh aplikasi lain di komputer.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) mendukung fragmentasi VLESS, REALITY, XHTTP, VLESS Encryption dan TLS. Ini juga menjalankan profil lengkap penyedia Xray sambil mempertahankan perutean dan grupnya. Profil tersebut tidak dapat secara otomatis dikonversi ke mesin lain tanpa mengubah perilakunya.\n\nXray yang dibundel menghapus pengaturan yang menonaktifkan verifikasi sertifikat TLS (`allowInsecure`). Otomatis memilih sing-box atau mihomo untuk server biasa yang memerlukan pengaturan ini. Memilih Xray secara manual melaporkan ketidakcocokan sebelum menghentikan koneksi saat ini. Profil JSON lengkap yang lebih lama memerlukan profil penyedia yang diperbarui dengan sertifikat atau pin sertifikat yang dapat diverifikasi.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) mendukung grup fallback dan penyeimbang beban yang dipesan, XHTTP dan AmneziaWG. Pilih ketika failover otomatis ke server cadangan penting. Pengaturan fragmentasi TLS Sora tidak tersedia dengan mesin ini.\n\n## Kompatibilitas di Sora\n\n| Fitur | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN dan TCP/UDP | Ya | Ya | Ya |\n| XHTTP | Ya | Ya | Ya |\n| VLESS Encryption | Ya | Ya | Ya |\n| Profil lengkap Xray | Tidak | Ya | Tidak |\n| TUIC / AnyTLS | Keduanya | Tidak | TUIC |\n| mieru | Tidak | Tidak | Ya |\n| NaiveProxy | Ya | Tidak | Tidak |\n| Fragmentasi TLS | Ya | Ya | Tidak |\n| AmneziaWG 1.x/2.x | Ya¹ | Tidak | Ya |\n| Grup cadangan yang dipesan | Tidak | Tidak² | Ya |\n\n¹ Profil dengan J1/J2/J3/Itime menggunakan mihomo; bidang-bidang ini tidak boleh dibuang secara diam-diam. ² Untuk grup profil Xray lengkap, aplikasi memilih profil cadangan. Dukungan bergantung pada build yang diinstal; periksa versinya di Tentang.\n\n## Tumpukan TUN\n\nTumpukan menangani TCP dan UDP di dalam antarmuka virtual. Di panel mode, Xray dan mihomo menawarkan gVisor, System, Mixed dan MIPS. Setiap mesin menyimpan preferensinya sendiri. Proksi System dan mode Tanpa Server tidak menggunakan preferensi ini.\n\n- **Mixed**: TCP menggunakan tumpukan sistem, sedangkan gVisor menangani UDP. Ini adalah bawaan mihomo di Linux. Di Windows, Xray dan mihomo menggunakan MIPS secara bawaan.\n- **System**: menggunakan tumpukan sistem. Coba opsi lain jika aplikasi jaringan mengalami masalah.\n- **gVisor**: menangani lalu lintas di ruang pengguna.\n- **MIPS**: tumpukan IP milik mihomo, tersedia dalam paket versi 1.19.32.\n\nPada Linux, Xray menggunakan gVisor bawaannya secara default. System, Mixed dan MIPS di Linux menggunakan mihomo sebagai mesin TUN, meneruskan TCP dan UDP ke Xray melalui tautan SOCKS lokal yang diautentikasi. Xray mempertahankan protokol, profil penyedia, dan perutean. Ketiga opsi ini memerlukan mihomo yang diinstal. Pada Windows, Xray menggunakan mihomo 1.19.32 atau lebih baru untuk keempat tumpukan TUN. Protokol dan perutean tetap di Xray. Aturan aplikasi dalam kombinasi ini hanya mendukung koneksi langsung dan pemblokiran; di Linux aturan ini memerlukan gVisor bawaan Xray.\n\nJembatan menjalankan proses kedua. Dalam tiga pengukuran idle di Linux, memori fisik menggunakan sekitar 32–36 MiB lebih banyak daripada Xray TUN asli. Ini tidak mengukur beban pengunduhan: biaya CPU dan memori bergantung pada koneksi. sing-box tidak memiliki pemilih tumpukan. Tidak ada tumpukan yang menjamin kinerja lebih baik di setiap jaringan.\n\n## Menerapkan pengaturan\n\nMemilih server akan menyambungkan ulang koneksi secara otomatis. Perubahan mode, mesin, DNS, atau aturan yang Anda buat diterapkan sekali setelah jeda singkat dengan koneksi ulang otomatis; pembaruan latar belakang tidak menyambungkan ulang VPN. Memulai ulang mesin dapat mengganggu unduhan dan panggilan.\n\nInternet hanya melalui VPN memblokir lalu lintas langsung ketika terowongan terputus. Ini mempengaruhi keseluruhan mesin. Pemutusan hubungan secara eksplisit menghapus aturan Sora. Jika pembersihan tidak selesai, coba lagi putuskan sambungan dan buka log.\n\n## Dokumentasi proyek\n\n- [sing-box-lx: konfigurasi dan dukungan](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [dokumentasi sing-box](https://sing-box.sagernet.org/)\n- [dokumentasi Xray](https://xtls.github.io/)\n- [dokumentasi mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: pengoperasian dan batasan](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC membawa TCP melalui panggilan video di Jitsi, Yandex Telemost, atau WB Stream. Impor tautan olcrtc:// atau kode QR. Protokol ini bekerja dengan sing-box, Xray, dan mihomo dalam mode proksi dan TUN; UDP tidak didukung. Kedua ujung memerlukan build OLC2 yang kompatibel. Proyek asal telah diarsipkan.\n';

  @override
  String get probeServers => 'Ping';

  @override
  String get extensions => 'Ekstensi';

  @override
  String extRatingLabel(String rating) {
    return 'Peringkat $rating dari 5';
  }

  @override
  String extByAuthor(String author) {
    return 'oleh $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Instalasi: $count';
  }

  @override
  String get extInstallOne => '1 pemasangan';

  @override
  String get extSideloadWarning => 'Kunci bertanda tangan sendiri';

  @override
  String get extPermissionsWidened => 'Pembaruan meminta izin baru:';

  @override
  String get extInstall => 'Pasang';

  @override
  String get extUpdate => 'Perbarui';

  @override
  String get extCancel => 'Batal';

  @override
  String get extConfirm => 'Konfirmasi';

  @override
  String get extCatalog => 'Katalog';

  @override
  String get extInstalled => 'Ekstensi terpasang';

  @override
  String get extSearchHint => 'Cari ekstensi';

  @override
  String get extCatAll => 'Semuanya';

  @override
  String get extCatTools => 'Alat';

  @override
  String get extCatThemes => 'Tema';

  @override
  String get extCatAutomation => 'Otomatisasi';

  @override
  String get extCatStats => 'Statistik';

  @override
  String get extCatNetwork => 'Jaringan';

  @override
  String get extSortBy => 'Urutkan berdasarkan';

  @override
  String get extSortPopular => 'Paling populer';

  @override
  String get extSortRating => 'Nilai tertinggi';

  @override
  String get extSortName => 'Nama';

  @override
  String get extCatalogError => 'Tidak dapat memuat katalog';

  @override
  String get extRetry => 'Coba lagi';

  @override
  String get extEmptySearch => 'Tidak ada yang ditemukan';

  @override
  String get extEmptyInstalled => 'Belum ada ekstensi yang dipasang';

  @override
  String get extInstallFromFile => 'Instal dari file';

  @override
  String get extInstallFromUrl => 'Instal dari URL';

  @override
  String get extDownload => 'Unduh';

  @override
  String get extDownloading => 'Mengunduh…';

  @override
  String get extVerifying => 'Memverifikasi…';

  @override
  String get extInstalling => 'Memasang…';

  @override
  String get extErrSignature => 'Pemeriksaan tanda tangan gagal';

  @override
  String get extErrManifest => 'Manifes ekstensi tidak valid.';

  @override
  String get extErrNetwork => 'Kesalahan jaringan';

  @override
  String get extErrHash => 'Unduhan tidak sesuai dengan katalog';

  @override
  String extErrMinApp(String version) {
    return 'Ekstensi ini memerlukan versi aplikasi $version atau lebih baru.';
  }

  @override
  String get extErrHttpsOnly => 'Hanya tautan https:// yang diperbolehkan';

  @override
  String get extErrGeneric => 'Ada yang tidak beres';

  @override
  String get extErrAuthorKeyChanged =>
      'Pembaruan ini ditandatangani dengan kunci penulis yang berbeda dari versi yang diinstal, sehingga diblokir';

  @override
  String get extDisabled => 'Dinonaktifkan';

  @override
  String extToggleEnabled(String name) {
    return 'Aktifkan $name';
  }

  @override
  String get extSearchInstalled => 'Cari ekstensi terpasang';

  @override
  String get extUpdateAll => 'Perbarui semua';

  @override
  String extUpdatesAvailable(int count) {
    return '$count pembaruan tersedia';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count diperbarui';
  }

  @override
  String get extRiskNormal => 'Biasa';

  @override
  String get extRiskSensitive => 'Sensitif';

  @override
  String get extRiskDangerous => 'Resiko tinggi';

  @override
  String get extPermissionsRemoved => 'Tidak lagi diminta:';

  @override
  String get extUpdateFailedKept => 'Versi sebelumnya masih terinstal.';

  @override
  String get extConflictsTitle => 'Konflik perluasan';

  @override
  String get extConflictTheme => 'Tema aplikasi';

  @override
  String get extConflictNetHooks => 'Kait jaringan';

  @override
  String extConflictWinner(String name) {
    return '$name menang';
  }

  @override
  String extConflictsCount(int count) {
    return 'Konflik perluasan: $count';
  }

  @override
  String get extConflictsResolve => 'Selesaikan konflik';

  @override
  String extVersionLabel(String version) {
    return 'Versi $version';
  }

  @override
  String get extPermissionsTitle => 'Izin';

  @override
  String get extNoPermissions => 'Tidak ada izin khusus.';

  @override
  String get extSettings => 'Pengaturan';

  @override
  String get extSaveSettings => 'Simpan pengaturan';

  @override
  String extUpdateTo(String version) {
    return 'Perbarui ke $version';
  }

  @override
  String get extEnabled => 'Diaktifkan';

  @override
  String extRollbackTo(String version) {
    return 'Kembalikan ke $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Kembalikan ke versi $version?';
  }

  @override
  String get extUninstall => 'Copot pemasangan';

  @override
  String extUninstallConfirm(String name) {
    return 'Hapus “$name” dan pengaturannya?';
  }

  @override
  String get extPanelUnavailable => 'Panel ekstensi tidak tersedia.';

  @override
  String get extPermConnectionsRead => 'Lihat daftar koneksi aktif';

  @override
  String get extPermServersRead => 'Lihat daftar server Anda';

  @override
  String get extPermSettingsRead => 'Baca pengaturan aplikasi';

  @override
  String get extPermSettingsWrite => 'Mengubah pengaturan aplikasi';

  @override
  String get extPermNotifications => 'Tampilkan notifikasi';

  @override
  String get extPermTray => 'Tambahkan item ke menu baki';

  @override
  String get extPermUiPanel => 'Tampilkan panel di dalam aplikasi';

  @override
  String get extPermThemeApply => 'Terapkan tema';

  @override
  String get extPermRoutingRules => 'Tambahkan aturan perutean';

  @override
  String get extPermNetHooks => 'Integrasikan ke jalur jaringan';

  @override
  String get extPermNetFetch => 'Minta URL dari daftar yang diizinkan';

  @override
  String get extPermBackground => 'Jalankan tugas latar belakang';

  @override
  String get extPermNotYetActive => 'Dinonaktifkan';

  @override
  String get extCapBackground => 'Berjalan di latar belakang';

  @override
  String get extCapNetHook => 'Pengelakan dan kait jaringan';

  @override
  String get extCapPanel => 'Panel antarmuka';

  @override
  String get extCapRouting => 'Aturan perutean';

  @override
  String get extCapTheme => 'Tema';

  @override
  String get extCapWidget => 'Widget';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Catatan Perubahan';

  @override
  String get extImageFailed => 'Tidak dapat memuat gambar';

  @override
  String get extScreenshots => 'Tangkapan Layar';

  @override
  String get extSortRelevance => 'Relevansi';

  @override
  String get extBgTitle => 'Tugas latar belakang';

  @override
  String get extBgEnabled => 'Jalankan di latar belakang';

  @override
  String get extBgInterval => 'Jalankan setiap';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count menit');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count jam');
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Akses jaringan';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Jaringan: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Ke $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostik HTTP';

  @override
  String get diagnosticNoData => 'Belum ada permintaan yang tercatat';

  @override
  String get qrShareTitle => 'Bagikan kode QR';

  @override
  String get qrScanTitle => 'Pindai kode QR';

  @override
  String get qrCopyLink => 'Salin tautan';

  @override
  String get qrFromClipboard => 'Tempel dari papan klip';

  @override
  String get qrNoCode => 'Tidak ada kode QR di gambar ini.';

  @override
  String get qrInvalid => 'Kode QR ini tidak berisi tautan yang valid.';

  @override
  String get qrScan => 'Pindai QR';

  @override
  String get qrFromImage => 'Buka gambar';

  @override
  String get connGroupByProcess => 'Kelompokkan berdasarkan proses';

  @override
  String get connListView => 'Daftar';

  @override
  String get connCopyHost => 'Salin hostnya';

  @override
  String get connAddRule => 'Tambahkan aturan';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count koneksi');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Prasetel';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Khusus';

  @override
  String get dnsCheck => 'Periksa kebocoran data';

  @override
  String get dnsChecking => 'Memeriksa...';

  @override
  String get dnsNoLeak => 'Tidak ditemukan kebocoran';

  @override
  String get dnsLeakFound => 'Kebocoran terdeteksi';

  @override
  String get dnsLastCheck => 'Pemeriksaan terakhir';

  @override
  String get dnsNeverChecked => 'Belum diuji';

  @override
  String get dnsLeakCheckTunnelDns => 'Resolver DNS terowongan';

  @override
  String get dnsLeakCheckSystemResolvers => 'Resolver sistem';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Perlindungan DNS oleh pemutus jaringan';

  @override
  String get dnsLeakCheckEncryptedDns => 'DNS terenkripsi sistem operasi';

  @override
  String get dnsLeakCheckDnsSpoof => 'Tanggapan DNS palsu';

  @override
  String get dnsExpected => 'Diharapkan';

  @override
  String get dnsActual => 'Diamati';

  @override
  String get measureSpeed => 'Ukur kecepatan';

  @override
  String get benchmarkStale => 'ketinggalan jaman';

  @override
  String get autoSelectMode => 'Pilih server secara otomatis';

  @override
  String get autoSelectPing => 'Ping tercepat';

  @override
  String get autoSelectSpeed => 'Kecepatan tercepat';

  @override
  String get autoSelectSmart => 'Pilihan cerdas';

  @override
  String get coreWatchUnstable => 'Koneksi ke inti tidak stabil';

  @override
  String get watchReconnect => 'Sambungkan kembali';

  @override
  String get crashRestoreTitle => 'Sesi terakhir diinterupsi';

  @override
  String get restoreOnCrash => 'Pulihkan sesi setelah crash';

  @override
  String get crashRestore => 'Pulihkan';

  @override
  String get crashDismiss => 'Tidak sekarang';

  @override
  String get overrideTitle => 'Hasil edit saya';

  @override
  String get overrideEdit => 'Mengedit server';

  @override
  String get overrideHide => 'Sembunyikan';

  @override
  String get overrideUnhide => 'Tunjukkan';

  @override
  String get overrideClear => 'Setel ulang pengeditan';

  @override
  String get overrideEmpty => 'Belum ada pengeditan';

  @override
  String get overrideCustomRules => 'Aturan sendiri';

  @override
  String get errBenchmarkUnsupported => 'Pengukuran kecepatan memerlukan versi inti yang lebih baru';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Pengukuran $done dari $total…';
  }

  @override
  String get profiles => 'Profil jaringan';

  @override
  String get profilesEmpty => 'Belum ada profil';

  @override
  String get profileAdd => 'Tambahkan profil';

  @override
  String get profileName => 'Nama profil';

  @override
  String get profileSsids => 'Wi-Fi jaringan (SSID)';

  @override
  String get profileGateways => 'Gerbang jaringan';

  @override
  String get profileAsns => 'AS nomor';

  @override
  String get profileAutoApply => 'Terapkan otomatis';

  @override
  String get profileSnapshot => 'Ingat pengaturan saat ini';

  @override
  String get profileSnapshotDone => 'Pengaturan saat ini disimpan ke dalam profil';

  @override
  String get profileDelete => 'Hapus profil';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Hapus profil \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Terapkan profil \"$name\"?';
  }

  @override
  String get profileApply => 'Terapkan';

  @override
  String profileApplied(Object name) {
    return 'Profil “$name” diterapkan';
  }

  @override
  String get profileUndo => 'Batal';

  @override
  String get profileActive => 'Aktif';

  @override
  String networkNow(Object info) {
    return 'Sekarang: $info';
  }

  @override
  String get networkUnknown => 'Info jaringan tidak tersedia';

  @override
  String get profileNoTriggers => 'Tidak ada kondisi profil';

  @override
  String get chains => 'Rantai proksi';

  @override
  String get chainsEmpty => 'Belum ada rantai';

  @override
  String get chainAdd => 'Rantai baru';

  @override
  String get chainName => 'Nama rantai';

  @override
  String get chainTooFew => 'Rantai memerlukan setidaknya dua server';

  @override
  String get chainTooMany => 'Rantai hanya dapat berisi hingga tiga server';

  @override
  String get chainEstimate => 'Perkiraan latensi';

  @override
  String get chainSave => 'Simpan rantai';

  @override
  String get chainDelete => 'Hapus rantai';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Hapus rantai \"$name\"?';
  }

  @override
  String get chainUnsupported => 'Mesin yang dipilih tidak mendukung rantai server';

  @override
  String get chainHopMissing => 'Salah satu server dalam rantai tidak lagi tersedia';

  @override
  String chainHop(Object n) {
    return 'Hop $n';
  }

  @override
  String get chainEntry => 'Masuk';

  @override
  String get chainExit => 'Keluar';

  @override
  String get sync => 'Sinkronisasi perangkat';

  @override
  String get syncDevices => 'Perangkatku';

  @override
  String get syncEmpty => 'Tidak ada perangkat yang dipasangkan';

  @override
  String get syncPair => 'Pasangkan perangkat';

  @override
  String get syncShowCode => 'Tunjukkan kode saya';

  @override
  String get syncScanCode => 'Pindai kode';

  @override
  String get syncRevoke => 'Mundur';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Cabut \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Sinkronisasi terakhir: $time';
  }

  @override
  String get syncNever => 'Tidak pernah';

  @override
  String get syncPaired => 'Perangkat dipasangkan';

  @override
  String get syncPairingTitle => 'Pasangkan dengan perangkat ini';

  @override
  String get syncWaiting => 'Menunggu perangkat lain…';

  @override
  String get zapretWithVpn => 'Lewati pemfilteran DPI untuk lalu lintas jaringan langsung';

  @override
  String get chainDuplicate => 'Ada server yang digunakan lebih dari sekali dalam rantai';

  @override
  String get edit => 'Sunting';

  @override
  String get remove => 'Hapus';

  @override
  String get autoSwitchOnDegrade => 'Aktifkan degradasi secara otomatis';

  @override
  String get tunStackMixed => 'Campur aduk';

  @override
  String get tunStackSystem => 'Sistem';

  @override
  String get customServerAdd => 'Tambahkan server khusus';

  @override
  String get customServers => 'Serverku';

  @override
  String get customServerName => 'Nama';

  @override
  String get customServerNameRequired => 'Nama belum diisi';

  @override
  String get customServerAddress => 'Alamat';

  @override
  String get customServerAddressRequired => 'Alamat belum diisi';

  @override
  String get customServerAddressInvalid => 'Alamat tidak valid';

  @override
  String get customServerPort => 'Port';

  @override
  String get customServerPortInvalid => 'Port tidak valid';

  @override
  String get customServerProtocol => 'Protokol';

  @override
  String get customServerCredentials => 'Informasi masuk';

  @override
  String get customServerShowSecret => 'Tampilkan rahasia';

  @override
  String get customServerHideSecret => 'Sembunyikan rahasia';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Hapus server “$name”?';
  }

  @override
  String get leakTestTitle => 'Uji kebocoran data';

  @override
  String get leakTestRun => 'Periksa';

  @override
  String get leakTestCancel => 'Batal';

  @override
  String leakTestProgress(int count) {
    return 'Tes selesai: $count';
  }

  @override
  String get leakTestAllClear => 'Tidak ditemukan kebocoran';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count kebocoran ditemukan');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Perbaiki';

  @override
  String get leakTestCheckDirectDns => 'Langsung DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP gema';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Resolver sistem';

  @override
  String get leakTestCheckTunnelConnectivity => 'Konektivitas terowongan';

  @override
  String get leakTestCheckTunnelDns => 'DNS melalui terowongan';

  @override
  String get noticeDegraded =>
      'Server menjadi lambat. Sora beralih ke server terbaik yang ditemukan selama pengukuran.';

  @override
  String get obfs => 'Penyamaran lalu lintas';

  @override
  String get syncCodeExpired => 'Kode telah kedaluwarsa';

  @override
  String get syncDaemonFailed => 'Tidak dapat memulai layanan sinkronisasi';

  @override
  String get syncDaemonMissing => 'Komponen sora-sync tidak ditemukan';

  @override
  String get syncDaemonStarting => 'Memulai layanan sinkronisasi…';

  @override
  String get syncErrAuth => 'Layanan sinkronisasi menolak token akses';

  @override
  String get syncErrNotFound => 'Perangkat tidak lagi dipasangkan';

  @override
  String get syncErrPairingActive => 'Sesi berpasangan sudah terbuka';

  @override
  String get syncErrUnreachable => 'Perangkat lain tidak menjawab';

  @override
  String get syncError => 'Kesalahan sinkronisasi';

  @override
  String syncExpiresIn(String duration) {
    return 'Kode kedaluwarsa dalam $duration';
  }

  @override
  String get syncJoining => 'Memasangkan dengan perangkat…';

  @override
  String get syncNewCode => 'Kode baru';

  @override
  String syncPairedWith(String name) {
    return 'Dipasangkan dengan $name';
  }

  @override
  String get syncRetry => 'Ulangi';

  @override
  String get syncStopShowing => 'Sembunyikan kode';

  @override
  String get syncSyncNow => 'Sinkronkan sekarang';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Menerima $pulled, mengirim $pushed';
  }

  @override
  String get syncResultTitle => 'Hasil sinkronisasi';

  @override
  String get syncPulled => 'Diterima';

  @override
  String get syncPushed => 'Terkirim';

  @override
  String get syncNoChanges => 'Tidak ada perubahan yang terdeteksi';

  @override
  String get syncDocKindSubscriptions => 'Langganan';

  @override
  String get syncDocKindSettings => 'Pengaturan aplikasi';

  @override
  String get syncDocKindOverrides => 'Penyesuaian berlangganan';

  @override
  String get syncDocKindProfiles => 'Profil jaringan';

  @override
  String get syncDocKindChains => 'Rantai proksi';

  @override
  String syncFrom(String name) {
    return 'dari $name';
  }

  @override
  String get syncThisDevice => 'Perangkat ini';

  @override
  String get syncUnavailableAndroid => 'Sinkronisasi tidak tersedia di Android';

  @override
  String get diagnosticPackets => 'Penangkapan paket';

  @override
  String get diagnosticEvents => 'Acara Windows';

  @override
  String get diagnosticCapture => 'Tangkap selama 10 detik';

  @override
  String get diagnosticRequiresTun => 'Pengambilan paket memerlukan koneksi Sora TUN yang aktif.';

  @override
  String get diagnosticUnavailable => 'Diagnostik ini tidak tersedia pada platform ini.';

  @override
  String get extErrRevoked => 'Tim Sora menarik versi ekstensi ini karena tidak aman atau rusak.';

  @override
  String get extErrRevocationsExpired => 'Instalasi diblokir hingga daftar pencabutan diperbarui.';

  @override
  String extRevokedDisabled(String names) {
    return 'Ekstensi yang ditarik dimatikan: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Kunci privat';

  @override
  String get customServerWgAddresses => 'Alamat antarmuka';

  @override
  String get customServerWgPeerKey => 'Kunci publik server';

  @override
  String get customServerWgPresharedKey => 'Kunci prabagi';

  @override
  String get customServerWgAllowedIps => 'IP yang diizinkan';

  @override
  String get customServerWgKeepalive => 'Keepalive, detik';

  @override
  String get customServerWgKeyInvalid => 'Kunci WireGuard tidak valid';

  @override
  String get customServerWgCidrInvalid => 'Prefiks CIDR tidak valid';

  @override
  String get customServerWgKeepaliveInvalid => 'Interval keepalive tidak valid';

  @override
  String get strictKillSwitch => 'Pemutus jaringan ketat';

  @override
  String get strictKillSwitchWarning => 'Blokir lalu lintas di luar VPN setelah keluar?';

  @override
  String get extWorkerFailed => 'Tugas latar belakang ekstensi gagal';

  @override
  String get extAssetRejected => 'File ekstensi berisi warna yang sulit dibaca atau aturan yang tidak valid';

  @override
  String get extVerifiedSora => 'Diverifikasi oleh Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count B';
  }

  @override
  String get extOpen => 'Buka';

  @override
  String get customServerOwn => 'Server sendiri';

  @override
  String get customServerPaste => 'Tempel tautan';

  @override
  String get customServerUser => 'Nama pengguna';

  @override
  String get customServerPassword => 'Kata sandi';

  @override
  String get customServerSecretRequired => 'Nilai belum diisi';

  @override
  String get customServerLinkInvalid => 'Tautan server tidak valid';

  @override
  String get errInternal => 'Kesalahan internal Sora';

  @override
  String get errTls => 'Sertifikat server ditolak';

  @override
  String get errFileAccess => 'Tidak dapat mengakses berkas';

  @override
  String get errDataLimit => 'Terlalu banyak data';

  @override
  String get errCredentials => 'Kredensial tersimpan tidak ditemukan';

  @override
  String subscriptionStale(String time) {
    return 'Terakhir diperbarui: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Belum diperbarui';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Server mengembalikan kode HTTP $status',
      zero: 'Server menolak permintaan',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Pengaturan server tidak lengkap atau tidak didukung';

  @override
  String get errServerIds => 'Dua server memiliki pengenal yang sama';

  @override
  String get errRoutingGroup => 'Rute mengarah ke server yang hilang atau grup rusak';

  @override
  String get errConnections => 'Daftar koneksi tidak tersedia';

  @override
  String get errLogs => 'Layanan ini tidak menyimpan log';

  @override
  String get errDiagnostics => 'Tidak dapat mengumpulkan diagnostik';

  @override
  String get errMissingItem => 'Item yang diminta sudah tidak ada';

  @override
  String get errInvalidRequest => 'Permintaan berisi nilai yang tidak valid';

  @override
  String get errProxyLogin => 'Proksi sistem tidak mendukung login ini';

  @override
  String get errLogFilter => 'Filter log tidak valid';

  @override
  String get errSubRedirect => 'Server mengalihkan ke alamat tidak aman';

  @override
  String get errProxySetup => 'Tidak dapat mengatur proksi sistem';

  @override
  String get notificationsToday => 'Hari ini';

  @override
  String get notificationsYesterday => 'Kemarin';

  @override
  String get notificationsMarkRead => 'Tandai semua sudah dibaca';

  @override
  String get notificationsUnread => 'Belum dibaca';

  @override
  String get desktopNotifications => 'Notifikasi desktop';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Interval pembaruan langganan tidak valid';

  @override
  String get errRule => 'Aturan perutean tidak valid';

  @override
  String get errDns => 'Pengaturan DNS tidak valid';

  @override
  String get errEndpoint => 'Alamat server yang akan diuji tidak valid';

  @override
  String get errCancelled => 'Permintaan dibatalkan';

  @override
  String get customServerOptions => 'Pengaturan koneksi';

  @override
  String get customServerTransport => 'Transportasi';

  @override
  String get customServerSecurity => 'Keamanan';

  @override
  String get customServerCipher => 'Sandi';

  @override
  String get customServerWgInterface => 'Antarmuka';

  @override
  String get customServerWgPeer => 'Peer';

  @override
  String extAvailableOn(String platforms) {
    return 'Tersedia di: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Ubah lalu lintas TCP semua aplikasi?';

  @override
  String get winwsRequirements => 'Mode VPN ini tidak tersedia';
}
