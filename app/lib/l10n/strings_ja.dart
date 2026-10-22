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
  String get connEmpty => '接続がありません';

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
  String get themeSystem => 'システムに合わせる';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => '暗い';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムに合わせる';

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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# サーバー、最速', one: '# サーバー、最速');
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'モード';

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
  String get programsEmpty => 'アプリケーションが見つかりませんでした。 別の名前を試してください。';

  @override
  String get selectExe => '.exe ファイルを選択してください';

  @override
  String get speedtest => 'スピード';

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

  @override
  String get updateSignaturePending => '更新ファイルはリリースと一緒に公開されたチェックサムと照合されます。';

  @override
  String get updateManualSigWarning => '以下のファイルはリリースのチェックサムと一致しています。公式リリースからダウンロードした場合はコマンドを実行してください。';

  @override
  String get updateVersionRevoked => '開発者はこのバージョンを取り下げました。修正後のリリースをお待ちください。';

  @override
  String get updateRolloutPending => '新しいバージョンは段階的に公開されており、自動的に提供されます。';

  @override
  String updateRollbacking(String version) {
    return 'バージョン $version にロールバックしています...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return '$version への更新はヘルスチェックに合格しなかったため、Sora は $fromVersion にロールバックされました。';
  }

  @override
  String get updateRollbackError => '自動ロールバックに失敗しました。新しいバージョンが動作しない場合は、以前のリリースを手動で再インストールしてください。';

  @override
  String get updateRollbackCacheError => '現在のバージョンの検証済みロールバック コピーを準備できなかったため、アップデートはインストールされませんでした。';

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
      'サーバーにどのエンジンが必要かわからない場合は、「自動」を選択してください。 Sora は接続前にプロファイルと設定を確認します。 エンジンはプランの帯域幅を増やすことはできません。パフォーマンスはサーバー、ルート、プロトコル、ネットワークに依存します。\n\n## モード\n\n### すべてのトラフィック (TUN)\n\nSora は、仮想ネットワーク インターフェイスを作成し、TCP や UDP などのアプリケーション トラフィックをそのインターフェイス経由でルーティングします。 このモードは、Telegram、ゲーム、および Discord 音声に使用します。 ルールでは、特定のサイトやプログラムを直接送信したり、ブロックしたりできます。 ネットワーク サービスには、許可と、必要なプロトコルをサポートするサーバーが必要です。\n\n### System プロキシ\n\nSora は、ローカル HTTP/SOCKS プロキシを構成します。 システムのプロキシ設定を尊重するアプリケーションはこれを使用します。 独自のネットワーク スタックを持つアプリケーションは直接接続できます。 UDP および音声通話には通常、TUN が必要です。 このモードは、プロキシをサポートするブラウザとアプリケーションに適しています。\n\n### サーバーがありません\n\nLinux では、Sora は [zapret](https://github.com/bol-van/zapret) を使用して HTTP/TLS リクエストを分割および再形成し、一部の DPI チェックをバイパスします。 IP は変更されず、接続は Web サイトに直接接続されます。 結果はプロバイダーとブロック方法によって異なります。\n\n現在の統合では、HTTP および TLS over TCP に tpws を使用します。 IP ブロッキングや UDP の中継はバイパスせず、Telegram の MTProto 接続を保証することはできません。 Discord 音声、Telegram 通話、およびこれらの種類の制限には、TUN を備えた VPN サーバーを使用します。\n\n## エンジン\n\n### 自動\n\nSora は、接続プラン全体 (サーバー プロトコル、トランスポート、グループ、フラグメンテーション、モード) をサポートする、インストールされているエンジンを選択します。 互換性のない手動選択は、現在の接続を停止する前に拒否されます。 [自動] または別のエンジンを選択し、設定を再度適用します。\n\n### sing-box\n\n新しい Sora パッケージには、[sing-box](https://github.com/SagerNet/sing-box) のフォークである [sing-box-lx](https://github.com/Leadaxe/sing-box-lx) が含まれており、クライアント側 XHTTP および VLESS Encryption が追加されています。 Sora は、ビルドとその機能を認識します。 XHTTP のないアップストリーム ビルドでは、名前だけではこの機能が得られません。\n\n対応するプロトコルは VLESS、VMess、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS、WireGuard、および Sora が読み込める AmneziaWG 1.x/2.x のパラメーターです。完全な Xray JSON プロファイルには Xray が必要です。新しい AWG 3.x のフィールドはまだ読み込めません。sing-box はパスワードで保護されたローカル制御ポートを使用し、このポートは同じコンピューターの他のアプリから検出できます。\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) は、VLESS、REALITY、XHTTP、VLESS Encryption、および TLS フラグメンテーションをサポートします。 また、ルーティングとグループを維持しながら、完全なプロバイダー Xray プロファイルを実行します。 このようなプロファイルは、動作を変更せずに別のエンジンに自動的に変換できません。\n\nバンドルされている Xray では、TLS 証明書の検証を無効にする設定 (`allowInsecure`) が削除されました。 この設定が必要な通常のサーバーでは、sing-box または mihomo が自動的に選択されます。 Xray を選択すると、現在の接続を停止する前に非互換性が手動で報告されます。 古い完全な JSON プロファイルには、検証可能な証明書または証明書 PIN を含む更新されたプロバイダー プロファイルが必要です。\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) は、順序付けされたフォールバックおよび負荷分散グループ、XHTTP および AmneziaWG をサポートします。 バックアップ サーバーへの自動フェイルオーバーが重要な場合に選択してください。 Sora の TLS フラグメンテーション設定は、このエンジンでは使用できません。\n\n## Sora の互換性\n\n| 特集 | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN と TCP/UDP | はい | はい | はい |\n| XHTTP | はい | はい | はい |\n| VLESS Encryption | はい | はい | はい |\n| Xray の全プロフィール | いいえ | はい | いいえ |\n| TUIC / AnyTLS | 両方 | いいえ | TUIC |\n| mieru | いいえ | いいえ | はい |\n| NaiveProxy | はい | いいえ | いいえ |\n| TLS フラグメンテーション | はい | はい | いいえ |\n| AmneziaWG 1.x/2.x | はい¹ | いいえ | はい |\n| 順序付けされたフォールバック グループ | いいえ | いいえ² | はい |\n\n¹ J1/J2/J3/Itime のプロファイルは mihomo を使用します。 これらのフィールドは決して黙って破棄してはなりません。 ² 完全な Xray プロファイルのグループの場合、アプリはバックアップ プロファイルを選択します。 サポートはインストールされているビルドによって異なります。 「バージョン情報」でバージョンを確認してください。\n\n## TUN スタック\n\nスタックは仮想インターフェイス内で TCP と UDP を処理します。 モード パネルでは、Xray および mihomo は、gVisor、System、Mixed、および MIPS を提供します。 各エンジンは独自の設定を保存します。 System プロキシ モードとサーバーレス モードでは、この設定は使用されません。\n\n- **Mixed** - TCP はシステム スタックを使用し、gVisor は UDP を処理します。 Linux では mihomo のデフォルトです。Windows では Xray と mihomo のデフォルトは MIPS です。\n- **System**: システム スタックを使用します。 ネットワーク アプリケーションに問題が発生した場合は、別のオプションを試してください。\n- **gVisor**: ユーザー空間のトラフィックを処理します。\n- **MIPS**: mihomo 独自の IP スタック。バンドルされたバージョン 1.19.32 で利用可能。\n\nLinux では、Xray はデフォルトで組み込みの gVisor を使用します。 Linux の System、Mixed、および MIPS は、TUN エンジンとして mihomo を使用し、認証されたローカル SOCKS リンク経由で TCP と UDP を Xray に転送します。 Xray は、プロトコル、プロバイダー プロファイル、およびルーティングを保持します。 これら 3 つのオプションには、mihomo がインストールされている必要があります。 Windows では、Xray は4種類すべてのTUNスタックに mihomo 1.19.32 以降を使用します。プロトコルとルーティングは Xray が処理します。この構成のアプリケーションルールは直接接続とブロックのみ対応します。Linux では、これらのルールには Xray 内蔵の gVisor が必要です。\n\nブリッジは 2 番目のプロセスを実行します。 Linux での 3 つのアイドル状態の測定では、ネイティブ Xray TUN よりも約 32 ～ 36 MiB 多くの物理メモリを使用しました。 これはダウンロードの負荷を測定するものではありません。CPU とメモリのコストは接続によって異なります。 sing-box にはスタック セレクターがありません。 すべてのネットワークでより優れたパフォーマンスを保証するスタックはありません。 スタックを選択し、[適用して再接続] を選択して、ネットワーク内で試してください。\n\n## 設定を適用する\n\nサーバーを選択すると、自動的に再接続されます。 モード、エンジン、DNS、ルールの設定はすぐに保存されます。 アクティブな接続中に、[適用] をクリックして再接続し、それらを使用します。 エンジンを再起動すると、ダウンロードと通話が中断される場合があります。 クリックを繰り返しても並列接続は開始されません。 切断すると遷移が終了し、接続が解放されます。\n\nVPN 経由のみのインターネットは、トンネルが切断されたときに直接トラフィックをブロックします。 マシン全体に影響します。 明示的に切断すると、Sora のルールが削除されます。 クリーンアップが完了しない場合は、切断を再試行してログを開きます。\n\n## プロジェクトのドキュメント\n\n- [sing-box-lx: 構成とサポート](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box ドキュメント](https://sing-box.sagernet.org/)\n- [Xray ドキュメント](https://xtls.github.io/)\n- [mihomo ドキュメント](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: 操作と制限事項](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC は Jitsi、Yandex Telemost、WB Stream のビデオ通話を通じて TCP を転送します。olcrtc:// リンクまたは QR コードをインポートしてください。プロキシと TUN モードで sing-box、Xray、mihomo に対応します。UDP には対応していません。両端で互換性のある OLC2 ビルドが必要です。元のプロジェクトはアーカイブされています。\n';

  @override
  String get probeServers => 'サーバーを確認する';

  @override
  String get extensions => '拡張機能';

  @override
  String extRatingLabel(String rating) {
    return '$rating の評価 (5 点中)';
  }

  @override
  String extByAuthor(String author) {
    return '作者: $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'インストール数: $count';
  }

  @override
  String get extInstallOne => 'インストール数: 1';

  @override
  String get extBadgeVerified => '確認済み';

  @override
  String get extBadgeTop => '今週の一番人気';

  @override
  String get extBadgeNew => '新しい';

  @override
  String get extBadgeStaff => 'Soraチーム';

  @override
  String get extSideloadShort => 'カタログ外';

  @override
  String get extSideloadWarning => 'この拡張子はチームカタログからのものではありません。作成者だけがキーを保証しています。作成者を信頼できる場合にのみインストールしてください。';

  @override
  String extInstallTitle(String name) {
    return '「$name」をインストール';
  }

  @override
  String extUpdateTitle(String name) {
    return '「$name」を更新';
  }

  @override
  String get extPermissionsIntro => 'この拡張機能では次のことが可能になります。';

  @override
  String get extPermissionsWidened => 'アップデートでは新しい権限が求められます。';

  @override
  String get extDangerousAck => 'これらの権限が重要であることを理解しています';

  @override
  String get extInstall => 'インストール';

  @override
  String get extUpdate => '更新';

  @override
  String get extCancel => 'キャンセル';

  @override
  String get extConfirm => '確認';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'カタログ';

  @override
  String get extInstalled => 'インストールされている拡張機能';

  @override
  String get extSearchHint => '拡張機能を検索';

  @override
  String get extCatAll => 'すべて';

  @override
  String get extCatTools => 'ツール';

  @override
  String get extCatThemes => 'テーマ';

  @override
  String get extCatAutomation => '自動化';

  @override
  String get extCatStats => '統計';

  @override
  String get extCatNetwork => 'ネットワーク';

  @override
  String get extSortBy => '並べ替え';

  @override
  String get extSortPopular => '一番人気';

  @override
  String get extSortRating => '最高評価';

  @override
  String get extSortName => '名前';

  @override
  String get extCatalogError => 'カタログを読み込めませんでした';

  @override
  String get extRetry => 'リトライ';

  @override
  String get extEmptySearch => '何も見つかりませんでした';

  @override
  String get extEmptyInstalled => '拡張機能はまだインストールされていません。\nカタログから見つけるか、ファイルからインストールします。';

  @override
  String get extInstallFromFile => 'ファイルからインストールする';

  @override
  String get extInstallFromUrl => 'URLからインストール';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'ダウンロード';

  @override
  String get extDownloading => 'ダウンロード中…';

  @override
  String get extVerifying => '検証中…';

  @override
  String get extInstalling => 'インストール中…';

  @override
  String get extInstallFailed => 'インストールに失敗しました';

  @override
  String get extErrSignature => '署名チェックに失敗しました。ファイルが破損しているか改ざんされている可能性があります。';

  @override
  String get extErrManifest => '拡張マニフェストが無効です。';

  @override
  String get extErrNetwork => 'ネットワークエラー。接続を確認して、もう一度試してください。';

  @override
  String get extErrHash => 'ダウンロードがカタログと一致しません。改ざんされている可能性があります。';

  @override
  String extErrMinApp(String version) {
    return 'この拡張機能にはアプリのバージョン $version 以降が必要です。';
  }

  @override
  String get extErrHttpsOnly => 'https:// リンクのみが許可されます';

  @override
  String get extErrGeneric => '何か問題が発生しました。もう一度試してください。';

  @override
  String get extErrAuthorKeyChanged =>
      'このアップデートは、インストールされているバージョンとは異なる作成者キーで署名されているため、ブロックされました。新しいキーを信頼する場合は、拡張機能をアンインストールし、明示的に再度インストールしてください。';

  @override
  String get extUpdateAvailable => 'アップデートあり';

  @override
  String get extDisabled => '無効';

  @override
  String extToggleEnabled(String name) {
    return '$nameを有効にする';
  }

  @override
  String get extSearchInstalled => 'インストール済みの拡張機能を検索';

  @override
  String get extUpdateAll => '全て更新';

  @override
  String extUpdatesAvailable(int count) {
    return '$count アップデートが利用可能';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count更新';
  }

  @override
  String get extRiskNormal => '通常';

  @override
  String get extRiskSensitive => '機密';

  @override
  String get extRiskDangerous => '高リスク';

  @override
  String get extPermissionsRemoved => '要求されなくなりました:';

  @override
  String get extUpdateFailedKept => '以前のバージョンがまだインストールされています。';

  @override
  String get extConflictsTitle => '拡張子の競合';

  @override
  String get extConflictsIntro => 'これらの拡張機能は同じものを使おうとしています。動かす方を選んでください。もう一方はインストールされたままです。';

  @override
  String get extConflictTheme => 'アプリテーマ';

  @override
  String get extConflictNetHooks => 'ネットワークフック';

  @override
  String extConflictWinner(String name) {
    return '$nameが勝利';
  }

  @override
  String extConflictsCount(int count) {
    return '$count 紛争にはあなたの決定が必要です';
  }

  @override
  String get extConflictsResolve => '競合を解決する';

  @override
  String get extConflictNote => '選択はこのデバイスに保存されます。テーマはすぐに切り替わります。ネットワークフックはこのバージョンでは実行されません。';

  @override
  String extVersionLabel(String version) {
    return 'バージョン$version';
  }

  @override
  String get extAuthor => '作者';

  @override
  String get extRating => '評価';

  @override
  String get extInstalls => 'インストール数';

  @override
  String get extVersion => 'バージョン';

  @override
  String get extAbout => 'この拡張機能について';

  @override
  String get extPermissionsTitle => '権限';

  @override
  String get extNoPermissions => '特別な権限はありません。';

  @override
  String get extSettings => '設定';

  @override
  String get extSaveSettings => '設定の保存';

  @override
  String get extSaving => '保存中…';

  @override
  String extUpdateTo(String version) {
    return '$version に更新';
  }

  @override
  String get extEnabled => '有効';

  @override
  String extRollbackTo(String version) {
    return '$version に戻す';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'バージョン $version にロールバックしますか?';
  }

  @override
  String get extUninstall => 'アンインストール';

  @override
  String extUninstallConfirm(String name) {
    return '「$name」とその設定を削除しますか?';
  }

  @override
  String get extPanelUnavailable => 'パネルが使用できません。拡張機能が無効になっているか、削除されている可能性があります。';

  @override
  String get extPermConnectionsRead => 'アクティブな接続のリストを参照';

  @override
  String get extPermServersRead => 'サーバーのリストを参照してください';

  @override
  String get extPermSettingsRead => 'アプリ設定の読み取り';

  @override
  String get extPermSettingsWrite => 'アプリの設定を変更する';

  @override
  String get extPermNotifications => '通知を表示する';

  @override
  String get extPermTray => 'トレイ メニューに項目を追加します';

  @override
  String get extPermUiPanel => 'アプリ内のパネルを表示する';

  @override
  String get extPermThemeApply => 'テーマを適用する';

  @override
  String get extPermRoutingRules => 'ルーティング ルールを追加します (ネットワーク トラフィックの送信先に影響します)';

  @override
  String get extPermNetHooks => 'ネットワーク パスへの統合 (DPI バイパス モジュール)';

  @override
  String get extPermNetFetch => '許可リストから URL をリクエストします';

  @override
  String get extPermBackground => 'バックグラウンドタスクを実行する';

  @override
  String get extPermBackgroundDetail => 'パネルが閉じている場合でも、スケジュールされたタスクを実行します。拡張機能の設定で一時停止したり、実行頻度を変更したりできます。';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'バックグラウンドで実行';

  @override
  String get extCapNetHook => '回避機能とネットワークフック';

  @override
  String get extCapPanel => 'パネル';

  @override
  String get extCapRouting => 'ルーティングルール';

  @override
  String get extCapTheme => 'テーマ';

  @override
  String get extCapWidget => 'ウィジェット';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => '変更履歴';

  @override
  String get extImageFailed => '画像を読み込めませんでした';

  @override
  String get extRatingHow => '評価の仕組み';

  @override
  String get extRatingHowBody =>
      '評価にはベイズ平均が使用されます。評価の少ない拡張機能は、より多くの人が投票するまで中央付近に留まるため、1 つの 5 つ星のレビューによって新しい拡張機能を上位に押し上げることはできません。最近の評価は古い評価よりも重みがあり、アカウントごとに 1 つの評価のみがカウントされます。';

  @override
  String get extScreenshots => 'スクリーンショット';

  @override
  String get extSortRelevance => '関連性';

  @override
  String get extPermNetworkDetail => 'VPN 経由でインターネットからデータを取得します。許可されるのは下のホストだけで、それ以外はブロックされます。';

  @override
  String get extBgTitle => 'バックグラウンドタスク';

  @override
  String get extBgEnabled => 'バックグラウンドで実行';

  @override
  String get extBgInterval => '実行間隔';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 分');
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 時間');
    return '$_temp0';
  }

  @override
  String get extBgNote => 'Sora を開いている間はトレイにある場合も含め、タスクがスケジュールどおり実行されます。最短間隔は 15 分です。';

  @override
  String get extBgDisabledNote => '拡張機能がバックグラウンド タスクを管理できるようにします。';

  @override
  String get extCapNetwork => 'ネットワークアクセス';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'ネットワーク: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return '保存先: $name';
  }

  @override
  String get diagnosticHttp => 'HTTP 診断';

  @override
  String get diagnosticNoData => '記録されたリクエストはまだありません。 まずスピードテストのWebサイトを開きます。';

  @override
  String get qrShareTitle => 'QR コードを共有';

  @override
  String get qrScanTitle => 'QR コードをスキャンします';

  @override
  String get qrCopyLink => 'リンクをコピー';

  @override
  String get qrShowLink => 'リンクを表示';

  @override
  String get qrHideLink => 'リンクを隠す';

  @override
  String get qrWarning => 'この QR コードには接続の詳細が含まれています。見知らぬ人に見せないでください。';

  @override
  String get qrScanHint => 'QR コードを含むスクリーンショットや写真を選ぶか、リンクを貼り付けてください';

  @override
  String get qrFromClipboard => 'クリップボードから貼り付け';

  @override
  String get qrNoCode => 'この画像に QR コードが見つかりません。';

  @override
  String get qrInvalid => 'この QR コードには有効なリンクが含まれていません。';

  @override
  String get qrScan => 'スキャン QR';

  @override
  String get qrFromImage => '画像を開く';

  @override
  String get connGroupByProcess => 'プロセスごとにグループ化する';

  @override
  String get connListView => 'リスト';

  @override
  String get connCopyHost => 'ホストのコピー';

  @override
  String get connAddRule => 'ルールの追加';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 件の接続');
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'プリセット';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'カスタム';

  @override
  String get dnsCheck => 'データ漏洩のチェック';

  @override
  String get dnsChecking => '確認中...';

  @override
  String get dnsNoLeak => '漏れは見つかりませんでした';

  @override
  String get dnsLeakFound => '漏れを検出しました';

  @override
  String get dnsLastCheck => '最終チェック';

  @override
  String get dnsNeverChecked => 'まだテストされていません';

  @override
  String get dnsLeakCheckTunnelDns => 'トンネルの DNS リゾルバー';

  @override
  String get dnsLeakCheckSystemResolvers => 'システムリゾルバー';

  @override
  String get dnsLeakCheckKillSwitchDns => 'ネットワーク遮断による DNS 保護';

  @override
  String get dnsLeakFixConfigureTunnelDns => '上記の DNS 設定でトンネルの DNS を構成します。';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'システムがトンネルの外側でどのリゾルバーを使用するかを確認してください。';

  @override
  String get dnsLeakFixEnableKillSwitch => 'ネットワーク遮断を有効にして、DNS 通信をトンネル内に留めてください。';

  @override
  String get dnsLeakCheckEncryptedDns => 'OS の暗号化 DNS';

  @override
  String get dnsLeakCheckDnsSpoof => '偽造されたDNS応答';

  @override
  String get dnsLeakFixReviewEncryptedDns => 'システムがトンネルの外でどの暗号化された DNS エンドポイントを使用しているかを確認してください。';

  @override
  String get dnsLeakFixUseEncryptedDns => 'リゾルバーが応答を偽造できないように、トンネルには暗号化された DNS (DoT または DoH) を使用します。';

  @override
  String get dnsCheckNeedsConnection => 'まずVPNに接続してから、漏れがないか確認してください。';

  @override
  String get dnsExpected => '予想される';

  @override
  String get dnsActual => '観察された';

  @override
  String get sortBy => '並べ替え順';

  @override
  String get sortPing => 'ピン';

  @override
  String get sortSpeed => 'スピード';

  @override
  String get sortName => '名前';

  @override
  String get measureSpeed => '速度を測定する';

  @override
  String get benchmarkStale => '時代遅れ';

  @override
  String get autoSelectMode => 'サーバーの自動選択';

  @override
  String get autoSelectPing => '最速の ping';

  @override
  String get autoSelectSpeed => '最速スピード';

  @override
  String get autoSelectSmart => '賢い選択';

  @override
  String get coreWatchUnstable => 'Sora コアへの接続が不安定です';

  @override
  String get watchReconnect => '再接続';

  @override
  String get coreRestoringLink => 'Sora コアへの接続を復元しています…';

  @override
  String get crashRestoreTitle => '最後のセッションが中断されました';

  @override
  String get restoreOnCrash => 'クラッシュ後のセッションの復元';

  @override
  String get crashRestore => '復元';

  @override
  String get crashDismiss => '今はだめ';

  @override
  String get overrideTitle => '私の編集';

  @override
  String get overrideEdit => 'サーバーの編集';

  @override
  String get overrideHide => '隠す';

  @override
  String get overrideUnhide => 'ショー';

  @override
  String get overrideClear => '編集内容をリセット';

  @override
  String get overrideEmpty => 'まだ編集はありません';

  @override
  String get overrideCustomRules => '独自のルール';

  @override
  String get errBenchmarkUnsupported => '速度測定には新しいコアが必要です';

  @override
  String benchmarkProgress(Object done, Object total) {
    return '$total からの $done の測定…';
  }

  @override
  String get profiles => 'ネットワークプロファイル';

  @override
  String get profilesEmpty => 'プロフィールはまだありません。既知のネットワークに設定を自動的に適用するために作成します。';

  @override
  String get profileAdd => 'プロフィールを追加';

  @override
  String get profileName => 'プロファイル名';

  @override
  String get profileSsids => 'Wi-Fi ネットワーク (SSID)';

  @override
  String get profileSsidsHint => '自宅、オフィスをカンマで区切って指定';

  @override
  String get profileGateways => 'ネットワークゲートウェイ';

  @override
  String get profileAsns => 'AS 番号';

  @override
  String get profileAutoApply => '自動適用';

  @override
  String get profileAutoApplyHint => 'オフの場合、プロファイルを適用する前に確認します。';

  @override
  String get profileSnapshot => '現在の設定を記憶する';

  @override
  String get profileSnapshotDone => '現在の設定をプロファイルに保存';

  @override
  String get profileDelete => 'プロフィールの削除';

  @override
  String profileDeleteConfirm(Object name) {
    return 'プロフィール「$name」を削除しますか?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'プロファイル「$name」を適用しますか?';
  }

  @override
  String get profileApply => '適用';

  @override
  String profileApplied(Object name) {
    return 'プロファイル「$name」が適用されました';
  }

  @override
  String get profileUndo => 'キャンセル';

  @override
  String get profileActive => 'アクティブ';

  @override
  String networkNow(Object info) {
    return '現在: $info';
  }

  @override
  String get networkUnknown => 'ネットワーク情報が利用できません';

  @override
  String get profileNoTriggers => '少なくとも 1 つのトリガーを追加します: SSID、ゲートウェイ、または ASN';

  @override
  String get chains => 'プロキシ チェーン';

  @override
  String get chainsEmpty => 'チェーンはまだありません。 2 ～ 3 台のサーバーをリンクし、トラフィックが各サーバーを経由するようにします。';

  @override
  String get chainAdd => '新しいチェーン';

  @override
  String get chainName => 'チェーン名';

  @override
  String get chainPickServers => '2 ～ 3 台のサーバーを選択します';

  @override
  String get chainOrderHint => 'ドラッグして順序を変更します。トラフィックは上部から入り、下部から出ます。';

  @override
  String get chainTooFew => '少なくとも 2 つのサーバーを選択してください';

  @override
  String get chainTooMany => 'チェーンには最大 3 台のサーバーを保持します';

  @override
  String get chainEstimate => '推定遅延時間';

  @override
  String get chainSave => 'チェーンの保存';

  @override
  String get chainDelete => 'チェーンの削除';

  @override
  String chainDeleteConfirm(Object name) {
    return 'チェーン「$name」を削除しますか?';
  }

  @override
  String get chainUnsupported => '現在のエンジンはチェーンを構築できません';

  @override
  String get chainHopMissing => 'チェーン サーバーの 1 つが利用できなくなりました';

  @override
  String chainHop(Object n) {
    return 'ホップ $n';
  }

  @override
  String get chainEntry => '入口';

  @override
  String get chainExit => '出口';

  @override
  String get sync => 'デバイスの同期';

  @override
  String get syncDevices => '私のデバイス';

  @override
  String get syncEmpty => 'ペアリングされたデバイスがありません。ローカル ネットワーク経由で別のデバイスをペアリングします。';

  @override
  String get syncPair => 'デバイスのペアリング';

  @override
  String get syncShowCode => 'コードを表示';

  @override
  String get syncScanCode => 'コードをスキャンします';

  @override
  String get syncRevoke => '撤退';

  @override
  String syncRevokeConfirm(Object name) {
    return '「$name」を取り消しますか?';
  }

  @override
  String syncLastSync(Object time) {
    return '最終同期: $time';
  }

  @override
  String get syncNever => '決してしない';

  @override
  String get syncNoLan => 'デバイスは同じローカル ネットワーク上に存在する必要があります';

  @override
  String get syncPaired => 'デバイスがペアリングされました';

  @override
  String get syncPairingTitle => 'このデバイスとペアリングします';

  @override
  String get syncWaiting => '他のデバイスを待っています…';

  @override
  String get syncSecureNote => 'エンドツーエンドの暗号化チャネル。アカウントもクラウドサーバーもありません。';

  @override
  String get zapretWithVpn => '直接ネットワーク トラフィックの DPI フィルタリングをバイパスする';

  @override
  String get zapretWithVpnHint => 'VPN トンネルと並行して zapret を実行します。トンネル内の通信は VPN を、直接通信は回避機能を使用します。';

  @override
  String get chainDuplicate => '各サーバーは 1 回だけ出現できます';

  @override
  String get edit => '編集';

  @override
  String get remove => '削除する';

  @override
  String get autoSwitchOnDegrade => '自動スイッチオンの劣化';

  @override
  String get autoSwitchOnDegradeDetail =>
      '選択したサーバーが大幅に遅くなったり応答しなくなったりすると、Sora は測定結果が最も良いサーバーに切り替えます。切り替えは 10 分に 1 回までです。';

  @override
  String get tunStackMixed => 'ミックス';

  @override
  String get tunStackSystem => 'システム';

  @override
  String get customServerAdd => 'カスタムサーバーの追加';

  @override
  String get customServers => '私のサーバー';

  @override
  String get customServerName => '名前';

  @override
  String get customServerNameHint => '例: 私の VPS';

  @override
  String get customServerNameRequired => '名前を入力してください';

  @override
  String get customServerAddress => '住所';

  @override
  String get customServerAddressHint => 'example.com または 192.0.2.1';

  @override
  String get customServerAddressRequired => 'サーバーアドレスを入力してください';

  @override
  String get customServerAddressInvalid => '無効なアドレスです';

  @override
  String get customServerPort => 'ポート';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'ポートは 1 ～ 65535 の番号でなければなりません';

  @override
  String get customServerProtocol => 'プロトコル';

  @override
  String get customServerCredentials => 'ログイン情報';

  @override
  String get customServerOptional => 'オプション';

  @override
  String get customServerShowSecret => 'シークレットを表示';

  @override
  String get customServerHideSecret => '秘密を隠す';

  @override
  String get customServerBadge => 'カスタム';

  @override
  String customServerDeleteConfirm(String name) {
    return 'サーバー「$name」を削除しますか?';
  }

  @override
  String get customServerEmptyHint => 'サーバーを手動で追加します: アドレス、ポート、プロトコル';

  @override
  String get customServerTest => 'テスト';

  @override
  String get leakTestTitle => 'データ漏洩のテスト';

  @override
  String get leakTestIntro => '通信がトンネルを通らずにデバイスから出られるか確認します。直接の DNS・ICMP 通信、IPv6 の外部通信、システムのリゾルバーを調べます。接続中に実行してください。';

  @override
  String get leakTestRun => 'チェック';

  @override
  String get leakTestCancel => 'キャンセル';

  @override
  String get leakTestNeedsConnection => 'VPN に接続してデータ漏洩をテストします。';

  @override
  String leakTestProgress(int count) {
    return '完了したテスト: $count';
  }

  @override
  String get leakTestAllClear => '漏れは見つかりませんでした';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# 件の漏えいを検出');
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => '修正';

  @override
  String get leakTestFixedNote => 'ネットワーク遮断は有効です。もう一度テストして確認してください。';

  @override
  String get leakTestCheckDirectDns => '直接 DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP エコー';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'システムリゾルバー';

  @override
  String get leakTestCheckTunnelConnectivity => 'トンネル接続';

  @override
  String get leakTestCheckTunnelDns => 'DNS トンネルを通過';

  @override
  String get noticeDegraded => 'サーバーが遅くなりました。 Sora は、測定中に見つかった最適なサーバーに切り替えました。';

  @override
  String get obfs => '通信の難読化';

  @override
  String get syncCodeExpired => 'コードの有効期限が切れています';

  @override
  String get syncDaemonFailed => '同期サービスを開始できませんでした';

  @override
  String get syncDaemonMissing => 'sora-sync コンポーネントが見つかりませんでした。アプリを再インストールしてデバイスの同期を有​​効にします。';

  @override
  String get syncDaemonStarting => '同期サービスを開始しています…';

  @override
  String get syncErrAuth => '同期サービスがアクセス トークンを拒否しました。アプリを再起動して、もう一度試してください。';

  @override
  String get syncErrNotFound => 'デバイスはペアリングされていません';

  @override
  String get syncErrPairingActive => 'ペアリングセッションはすでに開いています';

  @override
  String get syncErrUnreachable => '他のデバイスが応答しませんでした。同じネットワーク上にあり、そのコードが表示されていることを確認してください。';

  @override
  String get syncError => '同期エラー';

  @override
  String syncExpiresIn(String duration) {
    return 'コードは $duration 後に失効します';
  }

  @override
  String get syncJoining => 'デバイスとペアリング中…';

  @override
  String get syncLegacyCleared => '古いデバイスリストは実際にはペアリングされていなかったため、クリアされました。デバイスを再度ペアリングします。今度は実際にペアリングします。';

  @override
  String get syncNewCode => '新しいコード';

  @override
  String syncPairedWith(String name) {
    return '$nameと組み合わせる';
  }

  @override
  String get syncRetry => '繰り返し';

  @override
  String get syncStopShowing => 'コードを非表示';

  @override
  String get syncSyncNow => '今すぐ同期';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return '$pulled を受信、$pushed を送信';
  }

  @override
  String get syncResultTitle => '同期結果';

  @override
  String get syncPulled => '受信しました';

  @override
  String get syncPushed => '送信済み';

  @override
  String get syncNoChanges => '変更なし';

  @override
  String get syncDocKindSubscriptions => 'サブスクリプション';

  @override
  String get syncDocKindSettings => 'アプリ設定';

  @override
  String get syncDocKindOverrides => 'サブスクリプションの上書き設定';

  @override
  String get syncDocKindProfiles => 'ネットワークプロファイル';

  @override
  String get syncDocKindChains => 'プロキシ チェーン';

  @override
  String syncFrom(String name) {
    return '$name から';
  }

  @override
  String get syncThisDevice => 'この装置';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get customServerShadowsocksCredentials => 'Shadowsocks の場合: 方式:パスワード (例: chacha20-ietf-poly1305:password)';

  @override
  String get diagnosticPackets => 'パケットキャプチャ';

  @override
  String get diagnosticEvents => 'Windowsイベント';

  @override
  String get diagnosticCapture => '10秒間のキャプチャ';

  @override
  String get diagnosticRequiresTun => 'パケット キャプチャには、アクティブな Sora TUN 接続が必要です。';

  @override
  String get diagnosticUnavailable => 'この診断は、このプラットフォームでは使用できません。';

  @override
  String get extErrRevoked => 'この拡張機能のバージョンは安全でないか壊れているため、Sora チームが取り消しました。';

  @override
  String get extErrRevocationsExpired => '取り消された拡張機能のリストを更新できませんでした。更新されるまでインストールできません。ネットワークを確認して再試行してください。';

  @override
  String extRevokedDisabled(String names) {
    return '取り消された拡張機能をオフにしました: $names';
  }

  @override
  String get customServerWgPrivateKey => '秘密鍵';

  @override
  String get customServerWgAddresses => 'インターフェイスのアドレス';

  @override
  String get customServerWgPeerKey => 'サーバーの公開鍵';

  @override
  String get customServerWgPresharedKey => '事前共有鍵';

  @override
  String get customServerWgAllowedIps => '許可する IP';

  @override
  String get customServerWgKeepalive => 'Keepalive (秒)';

  @override
  String get customServerWgKeyInvalid => '鍵は wg genkey が出力するような base64 の 32 バイトにしてください。';

  @override
  String get customServerWgCidrInvalid => '10.0.0.2/32 のようなプレフィックスをカンマ区切りで入力してください。';

  @override
  String get customServerWgKeepaliveInvalid => '0 から 65535 までの秒数を入力してください。';

  @override
  String get strictKillSwitch => '厳格なネットワーク遮断';

  @override
  String get strictKillSwitchWarning =>
      '接続後は、クラッシュ、再起動、アプリ終了後も VPN 外の通信を遮断します。接続を切るか、この設定をオフにした場合のみアクセスが戻ります。端末の再起動後は、起動時の接続が有効な場合のみ遮断を再開します。';

  @override
  String get extWorkerFailed => '拡張機能のバックグラウンドタスクに失敗しました。拡張機能のログを確認してください。';

  @override
  String get extAssetRejected => '拡張機能のファイルを拒否しました。色が読みにくいか、ルールが無効です。';
}
