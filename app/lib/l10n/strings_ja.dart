// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get stateOff => '接続されていません';

  @override
  String get stateConnecting => '接続中';

  @override
  String get stateConnected => '接続済み';

  @override
  String get stateReconnecting => '再接続中';

  @override
  String get stateDisconnecting => '切断中';

  @override
  String get stateFailed => '接続されていません';

  @override
  String get coreMissing => 'Sora サービスが応答していません';

  @override
  String get serverAuto => '最速';

  @override
  String get serverBypass => 'サーバーがありません';

  @override
  String get addSubscription => 'サブスクリプションの追加';

  @override
  String get servers => 'サーバー';

  @override
  String get settings => '設定';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get subscriptionLink => '購読リンク';

  @override
  String get add => '追加';

  @override
  String get refresh => 'アップデート';

  @override
  String get rename => '名前の変更';

  @override
  String get delete => '消去';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get name => '名前';

  @override
  String deleteSubscription(String name) {
    return '「$name」を削除しますか?';
  

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
  String get routes => 'ルート';

  @override
  String get presetGlobal => 'すべてVPN経由';

  @override
  String get presetRu => 'ロシア直接';

  @override
  String get presetIr => 'イラン直接';

  @override
  String get presetCn => '中国直接';

  @override
  String get blockAds => '広告をブロックする';

  @override
  String get killSwitch => 'インターネットはVPN経由のみ';

  @override
  String get engine => 'エンジン';

  @override
  String get engineAuto => '自動';

  @override
  String get animations => 'アニメーション';

  @override
  String get logs => 'ログ';

  @override
  String get about => 'について';

  @override
  String get logsAll => '全て';

  @override
  String get logsImportant => '重要';

  @override
  String get logsErrors => 'エラー';

  @override
  String get search => '検索';

  @override
  String get export => 'ファイルに保存';

  @override
  String get clear => 'クリア';

  @override
  String get logsEmpty => 'ここには何もありません';

  @override
  String appVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get notInstalled => 'インストールされていません';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get license => 'ライセンス';

  @override
  String usage(String used, String total) {
    return '$used/$total';
  }

  @override
  String until(String date) {
    return '$dateまで';
  }

  @override
  String get expired => '期限切れ';

  @override
  String milliseconds(int n) {
    return '$n ミリ秒';
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
  String get errGeneric => '何か問題が発生しました';

  @override
  String get errCore => 'Sora サービスが応答していません';

  @override
  String get errAuth => 'Sora サービスにアクセスできません';

  @override
  String get errVersion => 'Sora を更新: アプリとサービスのバージョンが異なります';

  @override
  String get errBusy => '待ってください、前のコマンドはまだ実行中です';

  @override
  String get errEngineMissing => 'このサーバー用のエンジンが見つかりません';

  @override
  String get errEngineStart => 'エンジンが始動しなかった';

  @override
  String get errEngineStopped => 'エンジンが止まってしまった';

  @override
  String get errTunnel => 'VPN接続を作成する権限がありません';

  @override
  String get errServers => 'サーバーの構成にエラーがあります';

  @override
  String get errNetwork => 'サーバーにアクセスできません';

  @override
  String get errTimeout => 'サーバーは時間内に応答しませんでした';

  @override
  String get errFirewall => 'VPN の外部でインターネットをブロックできませんでした';

  @override
  String get errSubFetch => 'サブスクリプションを読み込めませんでした';

  @override
  String get errSubFormat => 'これは購読リンクではありません';

  @override
  String get errSubEmpty => 'サブスクリプションにはサーバーがありません';

  @override
  String get errSubDuplicate => 'このサブスクリプションはすでに追加されています';

  @override
  String get errSubLimit => 'サブスクリプションが多すぎます';

  @override
  String get errSubScheme => 'リンクは https:// で始まる必要があります';

  @override
  String get errSecretStore => 'Sora ストレージが破損しているか使用できません';

  @override
  String get errNoServers => '接続するサブスクリプションを追加する';

  @override
  String get exportText => '文章';

  @override
  String get connections => '接続';

  @override
  String get close => '近い';

  @override
  String get chainDirect => '直接';

  @override
  String get chainBlocked => 'ブロックされました';

  @override
  String get theme => 'テーマ';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => '暗い';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => '繋がり';

  @override
  String get sectionNoServer => 'サーバーがありません';

  @override
  String get sectionPing => 'ピン';

  @override
  String get sectionLog => '診断';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => '自動';

  @override
  String get dnsHint => 'アドレス、カンマ区切り';

  @override
  String get fragment => 'TLS フラグメンテーション';

  @override
  String get fragmentPackets => '何を分割するか';

  @override
  String get fragmentLength => 'ピースサイズ';

  @override
  String get fragmentInterval => '作品間で一時停止する';

  @override
  String get byDefault => 'デフォルト';

  @override
  String get rangeHint => 'たとえば、100 ～ 200';

  @override
  String get splitPos => 'スプリットポジション';

  @override
  String get splitPosHint => 'たとえば、1、midsld';

  @override
  String get disorder => '作品を並べ替える';

  @override
  String get tlsRecord => 'TLS レコードを分割する';

  @override
  String get tlsRecordNo => 'いいえ';

  @override
  String get tlsRecordSni => 'サイト名のところに';

  @override
  String get tlsRecordFirst => '最初のバイトの後';

  @override
  String get hostCase => 'ホストケースの変更';

  @override
  String get probeMethod => '方法';

  @override
  String get probeAuto => '自動';

  @override
  String get probeEngine => 'エンジンを通して';

  @override
  String get probeConnect => '接続のみ';

  @override
  String get probeUrl => 'テストアドレス';

  @override
  String get probeTimeout => '待って';

  @override
  String seconds(int n) {
    return '$n';
  }

  @override
  String get subscriptions => '定期購入';

  @override
  String get subscriptionSettings => '設定';

  @override
  String get userAgent => 'ユーザーエージェント';

  @override
  String get autoUpdate => '自動更新';

  @override
  String get updateInterval => 'どのくらいの頻度で';

  @override
  String get intervalProvider => 'プロバイダーの要望通り';

  @override
  String hours(int n) {
    return '${n}h';
  }

  @override
  String get updateNow => '今すぐアップデートしてください';

  @override
  String get logLevel => '何を記録するか';

  @override
  String get levelDebug => 'すべて';

  @override
  String get levelInfo => 'いつもの';

  @override
  String get levelWarning => '重要';

  @override
  String get levelError => 'エラーのみ';

  @override
  String get recordDestinations => 'サイトアドレスを記録する';

  @override
  String get reset => '設定をリセットする';

  @override
  String get resetConfirm => 'すべての設定をリセットしますか?';

  @override
  String get resetAction => 'リセット';

  @override
  String get invalidValue => 'この値は機能しません';

  @override
  String get website => '購読ページ';

  @override
  String get providerWebsite => 'プロバイダーのウェブサイト';

  @override
  String get support => 'サポート';

  @override
  String controlPortQuestion(String engine) {
    return '$engine は、このコンピューターのポートを通じて制御されます。 他のプログラムは、VPN がオンになっていることを認識できます。';
  }

  @override
  String chooseEngine(String engine) {
    return '$engineを選択してください';
  }

  @override
  String get rules => 'カスタムルール';

  @override
  String get ruleAdd => '新しいルール';

  @override
  String get ruleHint => 'サイト、IP、またはプログラム';

  @override
  String get ruleDirect => '直接';

  @override
  String get ruleProxy => 'VPN経由';

  @override
  String get ruleBlock => 'ブロック';

  @override
  String get failover => 'スイッチオンの失敗';

  @override
  String get connectOnStart => '起動時に接続する';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'サブスクリプションはあと # 日で終了します',
      one: 'サブスクリプションは # 日に終了します',
      zero: 'サブスクリプションは数時間後に終了します',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left 左';
  }

  @override
  String get ruleInvalid => 'これはサイト、IP、プログラムのようには見えません';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# サーバー、順番に', one: '# サーバー、順番に');
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# サーバー、最速', one: '# サーバー、最速');
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'モード';

  @override
  String get tunnelTun => 'すべてのトラフィック';

  @override
  String get tunnelProxy => 'System プロキシ';

  @override
  String get proxyAddress => 'プロキシアドレス';

  @override
  String get copied => 'コピーされました';

  @override
  String get launchAtLogin => 'システムから始める';

  @override
  String get launchAtLoginDetail => 'サインイン時に Sora が自動的に起動し、トレイに常駐します。';

  @override
  String get closeToTray => '閉じた状態でトレイに保管してください';

  @override
  String get notifications => '通知';

  @override
  String get trayOpen => 'Soraを開く';

  @override
  String get trayConnect => '接続する';

  @override
  String get trayDisconnect => '切断する';

  @override
  String get trayServer => 'サーバ';

  @override
  String get trayQuit => 'Soraを終了する';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state、$server';
  }

  @override
  String get noticeInTray => 'Sora はまだトレイ内にあります';

  @override
  String get noticeInTrayBody => 'アイコンのメニューから終了します';

  @override
  String get noticeLost => '接続が失われました';

  @override
  String get noticeLostBody => 'Sora が再接続中です';

  @override
  String get noticeRestored => '再び接続されました';

  @override
  String get noticeFailed => '接続できませんでした';

  @override
  String get noticeBackup => 'メインサーバーは応答しませんでした。 バックアップはトラフィックを伝送します';

  @override
  String get noticeNext => 'サーバーは応答しませんでした。 次のものがトラフィックを運ぶ';

  @override
  String get noticeMainBack => 'メインサーバーが再度応答し、トラフィックを伝送します';

  @override
  String get noticeSubscription => 'サブスクリプション';

  @override
  String get importTitle => 'このサブスクリプションを追加しますか?';

  @override
  String get importSealed => 'このリンクは Happ に対して暗号化されており、Happ のみが読み取ることができます。 プロバイダーにプレーンなサブスクリプション リンクを問い合わせてください。';

  @override
  String get understood => 'わかりました';

  @override
  String get noAnswer => '答えはありません';

  @override
  String get home => '家';

  @override
  String get navRules => 'ルール';

  @override
  String get navConnections => '接続';

  @override
  String get navLogs => 'ログ';

  @override
  String get navAbout => 'について';

  @override
  String get sidebarToggle => 'サイドバーの切り替え';

  @override
  String get more => 'もっと';

  @override
  String get less => '少ない';

  @override
  String get currentServer => '現在のサーバー';

  @override
  String get trafficDown => 'ダウンロード済み';

  @override
  String get trafficUp => 'アップロードされました';

  @override
  String perSecond(String value) {
    return '$value/秒';
  }

  @override
  String activeRules(int count) {
    return 'アクティブなルール: $count';
  }

  @override
  String get recentNotifications => '最近のお知らせ';

  @override
  String get notificationsEmpty => '接続イベントとサブスクリプション イベントがここに表示されます';

  @override
  String get retryConnect => '接続を再試行します';

  @override
  String get openLogs => 'ログを開く';

  @override
  String get tourReplay => 'ガイドを再度表示する';

  @override
  String tourStep(int step) {
    return 'ステップ $step/5';
  }

  @override
  String get tourBack => '戻る';

  @override
  String get tourNext => '次';

  @override
  String get tourSkip => 'スキップ';

  @override
  String get tourFinish => '終わり';

  @override
  String get tourAdd => 'プロバイダーのサブスクリプション リンクを追加します。';

  @override
  String get tourServer => 'サーバーを選択します。 「最速」では、1 つが選択されます。';

  @override
  String get tourConnect => 'ここをクリックして接続または切断します。';

  @override
  String get tourMode => 'モードを選択します。 VPN が切断された場合、キルスイッチはインターネットをブロックします。';

  @override
  String get tourSettings => '設定を開きます。 そこでこのガイドを再生できます。';

  @override
  String get chooseProgram => 'プログラムを選択してください';

  @override
  String get installedApps => 'インストールされているアプリケーション';

  @override
  String get runningProcesses => '実行中のプロセス';

  @override
  String get programsFailed => 'アプリケーションをロードできませんでした';

  @override
  String get programsEmpty => 'アプリケーションが見つかりませんでした。 別の名前を試してください。';

  @override
  String get selectExe => '.exe ファイルを選択してください';

  @override
  String get trafficUnavailable => 'カウンターはまだ利用できません';

  @override
  String get speedtest => 'スピード';

  @override
  String get speedtestCheck => '速度をチェックする';

  @override
  String get speedtestSearch => 'サービスを探す';

  @override
  String get speedtestEmpty => '一致はありません。 検索を変更します。';

  @override
  String get speedtestBackToList => 'サービスに戻る';

  @override
  String get speedtestOpenBrowser => 'ブラウザで開く';

  @override
  String get speedtestUnavailable => '組み込みブラウザを起動できませんでした。 システムブラウザでサービスを開きます。';

  @override
  String get speedtestPageFailed => 'ページを読み込めませんでした。 リロードするか、システム ブラウザでサービスを開きます。';

  @override
  String get speedtestExternalFailed => 'システムブラウザを開けませんでした。 もう一度やり直してください。';

  @override
  String get modes => 'モード';

  @override
  String get proxyShort => 'プロキシ';

  @override
  String get tunMode => 'すべてのトラフィック (TUN)';

  @override
  String get checkUpdates => 'アップデートをチェックする';

  @override
  String get updates => 'アプリのアップデート';

  @override
  String updateAvailable(String version) {
    return 'バージョン $version が利用可能です';
  }

  @override
  String get updateOpenAbout => '更新を見る';

  @override
  String updateNotes(String version) {
    return '$versionの変更点';
  }

  @override
  String get updateCheck => 'アップデートをチェックする';

  @override
  String get updateChecking => 'チェック中...';

  @override
  String get updateNoNotes => 'リリースにはメモがありません。';

  @override
  String get updateDropWarning => 'Sora とそのコアの更新中に、VPN 接続が数秒間切断されます。 続く？';

  @override
  String get updateWaitConnection => 'VPN 接続とコアの準備が整うまで待ちます。';

  @override
  String get updateDownloading => 'ファイルをダウンロードして確認しています...';

  @override
  String get updateInstalling => 'アップデートを準備中または管理者の認証を待っています...';

  @override
  String get updateNetworkError => 'アップデートをダウンロードできませんでした。 もう一度やり直してください。';

  @override
  String get updateReleaseError => 'リリース データまたは必要なファイルが欠落しているか無効です。';

  @override
  String get updateChecksumError => 'ダウンロードは SHA256SUMS と一致しません。 何もインストールされていませんでした。';

  @override
  String get updateInstallError => 'アップデートが完了しませんでした。 認証がキャンセルされた可能性があります。';

  @override
  String get updateUnsupported => 'この実行可能ファイルは、サポートされている Sora パッケージ ペアによって所有されていません。 リリースのインストール手順を使用してください。';

  @override
  String get updateManual =>
      'ターミナルでこのコマンドを実行して両方の検証済みパッケージをインストールし、Sora を再度開きます。 ファイルはダウンロード ディレクトリに残ります。 VPN 接続が切断されます。';
  String get updateSignaturePending => 'Release authenticity is not signature-verified yet — the signing-key ceremony is still pending. Files are integrity-checked (SHA-256) against the manifest fetched over TLS.';
  String get updateManualSigWarning => 'Warning: the manifest signature was not verified — the files below are hash-checked only. Run the command only if you trust the release channel.';
  String get updateWindowsSigBlocked => 'Automatic installation is disabled on Windows until release-signature verification is implemented. Download the installer from the release page and verify it manually.';

  @override
  String get updateCopyCommand => 'コピーコマンド';

  @override
  String get updateChecksDisabled => '自動チェックは設定で無効になっています。';

  @override
  String get updateInstalled => 'アップデートがインストールされました。 Soraを再度開きます。';

  @override
  String get projectLinks => 'プロジェクト';

  @override
  String get githubReleases => 'リリースとダウンロード';

  @override
  String get telegramChannel => 'Telegram チャンネル';

  @override
  String get licenses => 'ライセンス';

  @override
  String get componentLicenses => 'コンポーネントライセンス';

  @override
  String get appCopyright => '© 2026 levvs-one および貢献者';

  @override
  String get collapseServers => 'サーバーを折りたたむ';

  @override
  String get expandServers => 'サーバーを拡張する';

  @override
  String get hideDescription => '説明を隠す';

  @override
  String get showDescription => '説明を表示';

  @override
  String get pendingConnectionChanges => 'これらの変更を適用するには、再接続してください。';

  @override
  String get reconnectNow => '適用して再接続する';

  @override
  String get bypassLimitations =>
      'このモードは HTTP と TLS に対してのみ DPI をバイパスし、UDP をサポートしたり、IP を変更したりすることはありません。 Discord 音声、通話、およびブロックされた Telegram アドレスには VPN サーバーを使用します。';

  @override
  String get errEngineUnsupported => '選択したエンジンは、このプロファイルまたは設定をサポートしていません。 自動または互換性のあるエンジンを選択します。';

  @override
  String get errRestore => '接続のクリーンアップが不完全でした。 切断を再試行してください。 詳細についてはログを参照してください。';

  @override
  String get errSessionEnded => 'このセッションはすでに終了しています。 接続状態を更新します。';

  @override
  String get retryDisconnect => '切断を再試行してください';

  @override
  String get tunStack => 'TUNスタック';

  @override
  String get modesInfo => 'モードについて';

  @override
  String get modesGuideTitle => 'モードとエンジン';

  @override
  String get modesGuide =>
      'サーバーにどのエンジンが必要かわからない場合は、「自動」を選択してください。 Sora は接続前にプロファイルと設定を確認します。 エンジンはプランの帯域幅を増やすことはできません。パフォーマンスはサーバー、ルート、プロトコル、ネットワークに依存します。\n\n## モード\n\n### すべてのトラフィック (TUN)\n\nSora は、仮想ネットワーク インターフェイスを作成し、TCP や UDP などのアプリケーション トラフィックをそのインターフェイス経由でルーティングします。 このモードは、Telegram、ゲーム、および Discord 音声に使用します。 ルールでは、特定のサイトやプログラムを直接送信したり、ブロックしたりできます。 ネットワーク サービスには、許可と、必要なプロトコルをサポートするサーバーが必要です。\n\n### System プロキシ\n\nSora は、ローカル HTTP/SOCKS プロキシを構成します。 システムのプロキシ設定を尊重するアプリケーションはこれを使用します。 独自のネットワーク スタックを持つアプリケーションは直接接続できます。 UDP および音声通話には通常、TUN が必要です。 このモードは、プロキシをサポートするブラウザとアプリケーションに適しています。\n\n### サーバーがありません\n\nLinux では、Sora は [zapret](https://github.com/bol-van/zapret) を使用して HTTP/TLS リクエストを分割および再形成し、一部の DPI チェックをバイパスします。 IP は変更されず、接続は Web サイトに直接接続されます。 結果はプロバイダーとブロック方法によって異なります。\n\n現在の統合では、HTTP および TLS over TCP に tpws を使用します。 IP ブロッキングや UDP の中継はバイパスせず、Telegram の MTProto 接続を保証することはできません。 Discord 音声、Telegram 通話、およびこれらの種類の制限には、TUN を備えた VPN サーバーを使用します。\n\n## エンジン\n\n### 自動\n\nSora は、接続プラン全体 (サーバー プロトコル、トランスポート、グループ、フラグメンテーション、モード) をサポートする、インストールされているエンジンを選択します。 互換性のない手動選択は、現在の接続を停止する前に拒否されます。 [自動] または別のエンジンを選択し、設定を再度適用します。\n\n### sing-box\n\n新しい Sora パッケージには、[sing-box](https://github.com/SagerNet/sing-box) のフォークである [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) が含まれており、クライアント側 XHTTP および VLESS Encryption が追加されています。 Sora は、ビルドとその機能を認識します。 XHTTP のないアップストリーム ビルドでは、名前だけではこの機能が得られません。\n\n対応するプロトコルは VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard、および Sora が読み込める AmneziaWG 1.x/2.x のパラメーターです。完全な Xray JSON プロファイルには Xray が必要です。新しい AWG 3.x のフィールドはまだ読み込めません。sing-box はパスワードで保護されたローカル制御ポートを使用し、このポートは同じコンピューターの他のアプリから検出できます。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) は、VLESS、REALITY、XHTTP、VLESS Encryption、および TLS フラグメンテーションをサポートします。 また、ルーティングとグループを維持しながら、完全なプロバイダー Xray プロファイルを実行します。 このようなプロファイルは、動作を変更せずに別のエンジンに自動的に変換できません。\n\nバンドルされている Xray では、TLS 証明書の検証を無効にする設定 (`allowInsecure`) が削除されました。 この設定が必要な通常のサーバーでは、sing-box または mihomo が自動的に選択されます。 Xray を選択すると、現在の接続を停止する前に非互換性が手動で報告されます。 古い完全な JSON プロファイルには、検証可能な証明書または証明書 PIN を含む更新されたプロバイダー プロファイルが必要です。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) は、順序付けされたフォールバックおよび負荷分散グループ、XHTTP および AmneziaWG をサポートします。 バックアップ サーバーへの自動フェイルオーバーが重要な場合に選択してください。 Sora の TLS フラグメンテーション設定は、このエンジンでは使用できません。\n\n## Sora の互換性\n\n| 特集 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN と TCP/UDP | はい | はい | はい |\n| XHTTP | はい | はい | はい |\n| VLESS Encryption | はい | はい | はい |\n| Xray の全プロフィール | いいえ | はい | いいえ |\n| TUIC / AnyTLS | 両方 | いいえ | TUIC |\n| TLS フラグメンテーション | はい | はい | いいえ |\n| AmneziaWG 1.x/2.x | はい¹ | いいえ | はい |\n| 順序付けされたフォールバック グループ | いいえ | いいえ² | はい |\n\n¹ J1/J2/J3/Itime のプロファイルは mihomo を使用します。 これらのフィールドは決して黙って破棄してはなりません。 ² 完全な Xray プロファイルのグループの場合、アプリはバックアップ プロファイルを選択します。 サポートはインストールされているビルドによって異なります。 「バージョン情報」でバージョンを確認してください。\n\n## TUN スタック\n\nスタックは仮想インターフェイス内で TCP と UDP を処理します。 モード パネルでは、Xray および mihomo は、gVisor、System、Mixed、および MIPS を提供します。 各エンジンは独自の設定を保存します。 System プロキシ モードとサーバーレス モードでは、この設定は使用されません。\n\n- **Mixed** - TCP はシステム スタックを使用し、gVisor は UDP を処理します。 Linux では mihomo のデフォルトです。Windows では Xray と mihomo のデフォルトは MIPS です。\n- **System** — システム スタックを使用します。 ネットワーク アプリケーションに問題が発生した場合は、別のオプションを試してください。\n- **gVisor** — ユーザー空間のトラフィックを処理します。\n- **MIPS** — mihomo 独自の IP スタック。バンドルされたバージョン 1.19.32 で利用可能。\n\nLinux では、Xray はデフォルトで組み込みの gVisor を使用します。 Linux の System、Mixed、および MIPS は、TUN エンジンとして mihomo を使用し、認証されたローカル SOCKS リンク経由で TCP と UDP を Xray に転送します。 Xray は、プロトコル、プロバイダー プロファイル、およびルーティングを保持します。 これら 3 つのオプションには、mihomo がインストールされている必要があります。 Windows では、Xray は4種類すべてのTUNスタックに mihomo 1.19.32 以降を使用します。プロトコルとルーティングは Xray が処理します。この構成のアプリケーションルールは直接接続とブロックのみ対応します。Linux では、これらのルールには Xray 内蔵の gVisor が必要です。\n\nブリッジは 2 番目のプロセスを実行します。 Linux での 3 つのアイドル状態の測定では、ネイティブ Xray TUN よりも約 32 ～ 36 MiB 多くの物理メモリを使用しました。 これはダウンロードの負荷を測定するものではありません。CPU とメモリのコストは接続によって異なります。 sing-box にはスタック セレクターがありません。 すべてのネットワークでより優れたパフォーマンスを保証するスタックはありません。 スタックを選択し、[適用して再接続] を選択して、ネットワーク内で試してください。\n\n## 設定を適用する\n\nサーバーを選択すると、自動的に再接続されます。 モード、エンジン、DNS、ルールの設定はすぐに保存されます。 アクティブな接続中に、[適用] をクリックして再接続し、それらを使用します。 エンジンを再起動すると、ダウンロードと通話が中断される場合があります。 クリックを繰り返しても並列接続は開始されません。 切断すると遷移が終了し、接続が解放されます。\n\nVPN 経由のみのインターネットは、トンネルが切断されたときに直接トラフィックをブロックします。 マシン全体に影響します。 明示的に切断すると、Sora のルールが削除されます。 クリーンアップが完了しない場合は、切断を再試行してログを開きます。\n\n## プロジェクトのドキュメント\n\n- [sing-box-lx: 構成とサポート](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box ドキュメント](https://sing-box.sagernet.org/)\n- [Xray ドキュメント](https://xtls.github.io/)\n- [mihomo ドキュメント](https://wiki.metacubex.one/)\n- [zapret: 操作と制限事項](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'サーバーを確認する';

  @override
  String get extensions => '拡張機能';
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
  String get extBgNote => 'The system may delay runs to save battery. The shortest interval is 15 minutes.';
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
    return '保存先: $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 診断';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => '記録されたリクエストはまだありません。 まずスピードテストのWebサイトを開きます。';

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
