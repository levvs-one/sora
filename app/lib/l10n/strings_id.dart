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
  String get syncErrUnreachable => 'The other device didn\'t answer. Make sure it\'s on the same network and showing its code.';
  @override
  String get syncError => 'Sync error';

  @override
  String syncExpiresIn(String duration) {
    return 'Code expires in $duration';
  }

  @override
  String get syncJoining => 'Pairing with the device…';

  @override
  String get syncLegacyCleared => 'The old device list was never actually paired, so it was cleared. Pair your devices again — for real this time.';

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
  String get syncThisDevice => 'This device';

  @override
  String get syncUnavailableAndroid => 'Device sync isn\'t available on Android yet — the sync service can\'t run there.';
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
  String speedMbps(double value) {
    return '${intl.NumberFormat('0.0', localeName).format(value)} Mbps';
  }

  @override
  String latencyMs(int value) {
    return '$value ms';
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
  String get launchAtLoginDetail => 'Sora akan berjalan otomatis saat Anda masuk dan tetap berada di tray.';

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
  String get updateSignaturePending => 'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';
  String get updateManualSigWarning => 'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';
  String get updateWindowsSigBlocked => 'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';

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
  String extRatingLabel(String rating) => 'Rating $rating of 5';
  @override
  String extByAuthor(String author) => 'by $author';
  @override
  String extInstallsCount(String count) => '$count installs';
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
  String get extSideloadWarning => 'Not from the team catalog. The author\'s key is self-attested: install only if you trust the author.';
  @override
  String extInstallTitle(String name) => 'Install $name';
  @override
  String extUpdateTitle(String name) => 'Update $name';
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
  String get extEmptyInstalled => 'No extensions installed yet.
Find one in the catalog or install from a file.';
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
  String extErrMinApp(String version) => 'This extension needs app version $version or newer.';
  @override
  String get extErrHttpsOnly => 'Only https:// links are allowed';
  @override
  String get extErrGeneric => 'Something went wrong. Please try again.';
  @override
  String get extErrAuthorKeyChanged => 'This update is signed with a different author key than the installed version, so it was blocked. If you trust the new key, uninstall the extension and install it again explicitly.';
  @override
  String get extUpdateAvailable => 'Update available';
  @override
  String get extDisabled => 'Disabled';
  @override
  String extToggleEnabled(String name) => 'Enable ${name}';
  @override
  String get extSearchInstalled => 'Search installed';
  @override
  String get extUpdateAll => 'Update all';
  @override
  String extUpdatesAvailable(int count) => '${count} updates available';
  @override
  String extUpdatedCount(int count) => '${count} updated';
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
  String get extConflictsIntro => 'These extensions want the same thing. Choose which one wins — the other stays installed, but its contested capability is paused.';
  @override
  String get extConflictRoutingRules => 'Routing rules';
  @override
  String get extConflictTheme => 'App theme';
  @override
  String get extConflictNetHooks => 'Network hooks';
  @override
  String extConflictWinner(String name) => '${name} wins';
  @override
  String extConflictsCount(int count) => '${count} conflicts need your decision';
  @override
  String get extConflictsResolve => 'Resolve';
  @override
  String get extConflictNote => 'Your choice is saved on this device and applied by the engine.';
  @override
  String extVersionLabel(String version) => 'Version $version';
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
  @override
  String extUpdateTo(String version) => 'Update to $version';
  @override
  String get extEnabled => 'Enabled';
  @override
  String extRollbackTo(String version) => 'Roll back to $version';
  @override
  String extRollbackConfirm(String version) => 'Roll back to version $version?';
  @override
  String get extUninstall => 'Uninstall';
  @override
  String extUninstallConfirm(String name) => 'Remove “$name” and its settings?';
  @override
  String get extPanelUnavailable => 'The panel is unavailable. The extension may have been disabled or removed.';
  @override
  String get extCatalogSoonTitle => 'The team catalog is coming soon';
  @override
  String get extCatalogSoonBody => 'Until then, you can install extensions from a file or a link — every package is still signature-checked.';
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
  String get extPermBackgroundDetail => 'Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings.';

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
  String extCatalogCached(String date) => 'Cached catalog · ${date}';
  @override
  String get extChangelog => 'Changelog';
  @override
  String get extImageFailed => 'Couldn\'t load the image';
  @override
  String get extRatingHow => 'How ratings work';
  @override
  String get extRatingHowBody => 'Ratings use a Bayesian average: an extension with few ratings stays near the middle until more people vote, so a single 5-star review cannot push a new extension to the top. Recent ratings weigh more than old ones, and only one rating per account counts.';
  @override
  String get extScreenshots => 'Screenshots';
  @override
  String get extSortRelevance => 'Relevance';
  @override
  String get extPermNetworkDetail => 'Fetches data from the internet. Only the hosts below are allowed — everything else is blocked.';
  @override
  String get extBgTitle => 'Background task';
  @override
  String get extBgEnabled => 'Run in the background';
  @override
  String get extBgInterval => 'Run every';
  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minutes',
      one: '# minute',
    );
    return _temp0;
  }
  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours',
      one: '# hour',
    );
    return _temp0;
  }
  @override
  String get extBgNote => 'Background execution is not available in this version of Sora. Your schedule is saved and will apply automatically once the background runtime ships. The shortest interval is 15 minutes.';
  @override
  String get extBgDisabledNote => 'Enable the extension to manage its background task.';
  @override
  String get extBgRuntimeBadge => 'Not available yet';
  @override
  String get extCapNetwork => 'Network access';
  @override
  String extCapNetworkHosts(String hosts) {
    return 'Network: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'Ke $name';
  }

  @override
  String get diagnosticHttp => 'Diagnostik HTTP';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Belum ada permintaan yang tercatat. Buka situs tes kecepatan terlebih dahulu.';

  @override
  String get dnsExpected => 'Expected';
  @override
  String get dnsActual => 'Observed';
  @override
  String get dnsCheckNeedsConnection => 'Connect to the VPN first, then check for leaks.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# connections',
      one: '# connection',
    );
    return _temp0;
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
  String benchmarkProgress(int done, int total) => 'Measuring $done of $total…';
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
  String profileDeleteConfirm(String name) => 'Delete profile "${name}"?';

  @override
  String profileApplyAsk(String name) => 'Apply profile "${name}"?';

  @override
  String get profileApply => 'Apply';

  @override
  String profileApplied(String name) => 'Profile "${name}" applied';

  @override
  String get profileUndo => 'Undo';

  @override
  String get profileActive => 'Active';

  @override
  String networkNow(String info) => 'Now: ${info}';

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
  String chainDeleteConfirm(String name) => 'Delete chain "${name}"?';

  @override
  String get chainUnsupported => 'The current engine cannot build chains';

  @override
  String get chainHopMissing => 'One of the chain servers is no longer available';

  @override
  String chainHop(String n) => 'Hop ${n}';

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
  String syncRevokeConfirm(String name) => 'Revoke "${name}"?';

  @override
  String syncLastSync(String time) => 'Last sync: ${time}';

  @override
  String get syncNever => 'Never';

  @override
  String get syncWhat => 'What syncs';

  @override
  String get syncWhatBody => 'Subscriptions, rules, settings and network profiles. Never synced: local logs, IPC tokens.';

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
  String get zapretWithVpnHint => 'Runs zapret next to the VPN tunnel: tunneled traffic uses the VPN, direct traffic goes through the bypass.';
  @override
  String get chainDuplicate => 'Each server can appear only once';
  @override
  String get edit => 'Edit';
  @override
  String get remove => 'Remove';
  @override
  String get autoSwitchOnDegrade => 'Auto-switch on degradation';
  @override
  String get autoSwitchOnDegradeDetail => 'If the selected server slows down a lot or stops answering, Sora switches to the best measured one — at most once every 10 minutes.';
  @override
  String get tunStackMixed => 'Mixed';
  @override
  String get tunStackSystem => 'System';

  @override
  String get censorTitle => 'Blocking diagnostics';

  @override
  String get censorHistory => 'Check history';

  @override
  String get censorEmpty => 'No checks yet. If a connection fails, the detector will check whether your provider is blocking it.';

  @override
  String get censorExplainer => 'This is not an app error: your provider seems to be limiting the connection. Masking changes how the app connects and often helps.';

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
  String get leakTestIntro => 'Probes whether traffic can leave the device outside the tunnel: direct DNS and ICMP, IPv6 egress, and the system resolvers. Run it while connected.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# leaks found',
      one: '# leak found',
    );
    return _temp0;
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
  String smartPickReason(String ping, String speed) {
    return 'Picked by smart mode: ping $ping, speed $speed';
  }

  @override
  String serverReliability(int pct) {
    return 'Reliability $pct%';
  }
}
