// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class SUk extends S {
  SUk([String locale = 'uk']) : super(locale);

  @override
  String get stateOff => 'Не підключено';

  @override
  String get stateConnecting => 'Підключення';

  @override
  String get stateConnected => 'Підключено';

  @override
  String get stateReconnecting => 'Повторне підключення';

  @override
  String get stateDisconnecting => 'Відключення';

  @override
  String get stateFailed => 'Не підключено';

  @override
  String get coreMissing => 'Служба Sora не відповідає';

  @override
  String get serverAuto => 'Найшвидший';

  @override
  String get serverBypass => 'Немає сервера';

  @override
  String get addSubscription => 'Додати підписку';

  @override
  String get servers => 'Сервери';

  @override
  String get settings => 'Налаштування';

  @override
  String get subscription => 'Підписка';

  @override
  String get subscriptionLink => 'Посилання на підписку';

  @override
  String get add => 'додати';

  @override
  String get refresh => 'оновлення';

  @override
  String get rename => 'Перейменувати';

  @override
  String get delete => 'Видалити';

  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'зберегти';

  @override
  String get name => 'Ім\'я';

  @override
  String deleteSubscription(String name) {
    return 'Видалити “$name”?';
  }

  @override
  String get routes => 'Маршрути';

  @override
  String get presetGlobal => 'Все через VPN';

  @override
  String get presetRu => 'Росія пряма';

  @override
  String get presetIr => 'Іран прямо';

  @override
  String get presetCn => 'Китай прямо';

  @override
  String get blockAds => 'Блокувати рекламу';

  @override
  String get killSwitch => 'Інтернет тільки через VPN';

  @override
  String get engine => 'Двигун';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'анімації';

  @override
  String get logs => 'Журнал';

  @override
  String get about => 'про';

  @override
  String get logsAll => 'все';

  @override
  String get logsImportant => 'важливо';

  @override
  String get logsErrors => 'Помилки';

  @override
  String get search => 'Пошук';

  @override
  String get export => 'Зберегти у файл';

  @override
  String get clear => 'ясно';

  @override
  String get logsEmpty => 'Тут нічого немає';

  @override
  String get connEmpty => 'No connections';

  @override
  String appVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get notInstalled => 'Не встановлено';

  @override
  String get sourceCode => 'Вихідний код';

  @override
  String get license => 'Ліцензія';

  @override
  String usage(String used, String total) {
    return '$used з $total';
  }

  @override
  String until(String date) {
    return 'до $date';
  }

  @override
  String get expired => 'Термін дії минув';

  @override
  String milliseconds(int n) {
    return '$n мс';
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
    return '$n ТБ';
  }

  @override
  String get errGeneric => 'Щось пішло не так';

  @override
  String get errCore => 'Служба Sora не відповідає';

  @override
  String get errAuth => 'Немає доступу до служби Sora';

  @override
  String get errVersion => 'Оновлення Sora: додаток і сервіс мають різні версії';

  @override
  String get errBusy => 'Зачекайте, попередня команда все ще виконується';

  @override
  String get errEngineMissing => 'Для цього сервера не знайдено механізму';

  @override
  String get errEngineStart => 'Двигун не заводився';

  @override
  String get errEngineStopped => 'Мотор зупинився';

  @override
  String get errTunnel => 'Немає дозволу на створення VPN-з’єднання';

  @override
  String get errServers => 'Сервер налаштовано з помилкою';

  @override
  String get errNetwork => 'Не вдається підключитися до сервера';

  @override
  String get errTimeout => 'Сервер не відповів вчасно';

  @override
  String get errFirewall => 'Не вдалося заблокувати Інтернет за межами VPN';

  @override
  String get errSubFetch => 'Не вдалося завантажити підписку';

  @override
  String get errSubFormat => 'Це не посилання для підписки';

  @override
  String get errSubEmpty => 'Підписка не має серверів';

  @override
  String get errSubDuplicate => 'Ця підписка вже додана';

  @override
  String get errSubLimit => 'Забагато підписок';

  @override
  String get errSubScheme => 'Посилання має починатися з https://';

  @override
  String get errSecretStore => 'Пам’ять Sora пошкоджена або недоступна';

  @override
  String get errNoServers => 'Щоб підключитися, додайте підписку';

  @override
  String get exportText => 'текст';

  @override
  String get connections => 'Зв\'язки';

  @override
  String get close => 'Закрити';

  @override
  String get chainDirect => 'Прямий';

  @override
  String get chainBlocked => 'заблоковано';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'світло';

  @override
  String get themeDark => 'Темний';

  @override
  String get language => 'Мова';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Підключення';

  @override
  String get sectionNoServer => 'Немає сервера';

  @override
  String get sectionPing => 'Пінг';

  @override
  String get sectionLog => 'діагностика';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Авто';

  @override
  String get dnsHint => 'Адреси, розділені комами';

  @override
  String get fragment => 'TLS фрагментація';

  @override
  String get fragmentPackets => 'Що розділити';

  @override
  String get fragmentLength => 'Розмір шматка';

  @override
  String get fragmentInterval => 'Пауза між частинами';

  @override
  String get byDefault => 'За замовчуванням';

  @override
  String get rangeHint => 'Наприклад, 100-200';

  @override
  String get splitPos => 'Розділ позицій';

  @override
  String get splitPosHint => 'Наприклад, 1, midsld';

  @override
  String get disorder => 'Змініть порядок частин';

  @override
  String get tlsRecord => 'Розділіть запис TLS';

  @override
  String get tlsRecordNo => 'немає';

  @override
  String get tlsRecordSni => 'На назву сайту';

  @override
  String get tlsRecordFirst => 'Після першого байту';

  @override
  String get hostCase => 'Змінити регістр хоста';

  @override
  String get probeMethod => 'метод';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Через двигун';

  @override
  String get probeConnect => 'Тільки підключення';

  @override
  String get probeUrl => 'Тестова адреса';

  @override
  String get probeTimeout => 'Зачекайте';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Підписки';

  @override
  String get subscriptionSettings => 'Налаштування';

  @override
  String get userAgent => 'Користувач-Агент';

  @override
  String get autoUpdate => 'Автоматичне оновлення';

  @override
  String get updateInterval => 'Як часто';

  @override
  String get intervalProvider => 'Як запитує провайдер';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Оновіть зараз';

  @override
  String get logLevel => 'Що записувати';

  @override
  String get levelDebug => 'все';

  @override
  String get levelInfo => 'Звичайний';

  @override
  String get levelWarning => 'важливо';

  @override
  String get levelError => 'Лише помилки';

  @override
  String get recordDestinations => 'Записати адреси сайтів';

  @override
  String get reset => 'Скидання налаштувань';

  @override
  String get resetConfirm => 'Скинути всі налаштування?';

  @override
  String get resetAction => 'Скинути';

  @override
  String get invalidValue => 'Це значення не працюватиме';

  @override
  String get website => 'Сторінка підписки';

  @override
  String get providerWebsite => 'Сайт провайдера';

  @override
  String get support => 'Підтримка';

  @override
  String controlPortQuestion(String engine) {
    return '$engine керується через порт на цьому комп’ютері. Інші програми зможуть визначити, що VPN увімкнено.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Виберіть $engine';
  }

  @override
  String get rules => 'Спеціальні правила';

  @override
  String get ruleAdd => 'Нове правило';

  @override
  String get ruleHint => 'Сайт, IP або програма';

  @override
  String get ruleDirect => 'Прямий';

  @override
  String get ruleProxy => 'Через VPN';

  @override
  String get ruleBlock => 'Блокувати';

  @override
  String routingNoteRecorded(String field) {
    return '$field: recorded, not applied';
  }

  @override
  String get failover => 'Помилка ввімкнення';

  @override
  String get connectOnStart => 'Підключитися при запуску';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'термін дії підписки закінчується через # днів',
      one: 'підписка закінчується через день #',
      zero: 'підписка закінчується через кілька годин',
    );
    return '$name: $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left ліворуч';
  }

  @override
  String get ruleInvalid => 'Це не схоже на сайт, IP чи програму';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сервери #, у свою чергу',
      one: 'Сервер #, у свою чергу',
    );
    return '$_temp0';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сервери #, найшвидші',
      one: 'Сервер #, найшвидший',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelTun => 'Весь трафік';

  @override
  String get tunnelProxy => 'Проксі System';

  @override
  String get proxyAddress => 'Адреса проксі';

  @override
  String get copied => 'Скопійовано';

  @override
  String get launchAtLogin => 'Почніть із системи';

  @override
  String get launchAtLoginDetail => 'Sora автоматично запускатиметься під час входу в систему й залишатиметься в треї.';

  @override
  String get closeToTray => 'Зберігати в закритому лотку';

  @override
  String get notifications => 'Сповіщення';

  @override
  String get trayOpen => 'Відкрийте Sora';

  @override
  String get trayConnect => 'Підключитися';

  @override
  String get trayDisconnect => 'Відключити';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Вийти з Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora все ще в треї';

  @override
  String get noticeInTrayBody => 'Вийдіть із меню його значка';

  @override
  String get noticeLost => 'З\'єднання втрачено';

  @override
  String get noticeLostBody => 'Sora повторно підключається';

  @override
  String get noticeRestored => 'Знову підключено';

  @override
  String get noticeFailed => 'Не вдалося підключитися';

  @override
  String get noticeBackup => 'Головний сервер не відповідає; резервна копія переносить трафік';

  @override
  String get noticeNext => 'Сервер не відповідає; наступний несе рух';

  @override
  String get noticeMainBack => 'Головний сервер знову відповідає і переносить трафік';

  @override
  String get noticeSubscription => 'Підписка';

  @override
  String get importTitle => 'Додати цю підписку?';

  @override
  String get importSealed =>
      'Це посилання зашифровано для Happ, і лише Happ може його прочитати. Попросіть свого провайдера надати просте посилання для підписки.';

  @override
  String get understood => 'добре';

  @override
  String get noAnswer => 'немає відповіді';

  @override
  String get home => 'додому';

  @override
  String get navRules => 'правила';

  @override
  String get navConnections => 'Зв\'язки';

  @override
  String get navLogs => 'Журнали';

  @override
  String get navAbout => 'про';

  @override
  String get sidebarToggle => 'Перемкнути бічну панель';

  @override
  String get more => 'більше';

  @override
  String get less => 'менше';

  @override
  String get currentServer => 'Поточний сервер';

  @override
  String get trafficDown => 'Завантажено';

  @override
  String get trafficUp => 'Завантажено';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Активні правила: $count';
  }

  @override
  String get recentNotifications => 'Останні сповіщення';

  @override
  String get notificationsEmpty => 'Тут відображатимуться події підключення та підписки';

  @override
  String get retryConnect => 'Повторити підключення';

  @override
  String get openLogs => 'Відкриті журнали';

  @override
  String get tourReplay => 'Знову показати посібник';

  @override
  String tourStep(int step) {
    return 'Крок $step із 5';
  }

  @override
  String get tourBack => 'Назад';

  @override
  String get tourNext => 'Далі';

  @override
  String get tourSkip => 'Пропустити';

  @override
  String get tourFinish => 'Готово';

  @override
  String get tourAdd => 'Додайте посилання на підписку вашого постачальника.';

  @override
  String get tourServer => 'Виберіть сервер. «Найшвидший» вибере для вас один.';

  @override
  String get tourConnect => 'Натисніть тут, щоб підключитися або відключитися.';

  @override
  String get tourMode => 'Виберіть режим. Kill Switch блокує Інтернет, якщо VPN переривається.';

  @override
  String get tourSettings => 'Відкрийте налаштування. Ви можете відтворити цей посібник там.';

  @override
  String get chooseProgram => 'Виберіть програму';

  @override
  String get installedApps => 'Встановлені програми';

  @override
  String get runningProcesses => 'Запущені процеси';

  @override
  String get programsFailed => 'Не вдалося завантажити програми';

  @override
  String get programsEmpty => 'Додатків не знайдено. Спробуйте інше ім\'я.';

  @override
  String get selectExe => 'Виберіть файл .exe';

  @override
  String get trafficUnavailable => 'Лічильників ще немає';

  @override
  String get speedtest => 'швидкість';

  @override
  String get speedtestCheck => 'Перевірте швидкість';

  @override
  String get speedtestSearch => 'Знайдіть послугу';

  @override
  String get speedtestEmpty => 'Немає збігів. Змінити пошук.';

  @override
  String get speedtestBackToList => 'Назад до послуг';

  @override
  String get speedtestOpenBrowser => 'Відкрити в браузері';

  @override
  String get speedtestUnavailable => 'Не вдалося запустити вбудований браузер. Відкрийте службу в системному браузері.';

  @override
  String get speedtestPageFailed =>
      'Не вдалося завантажити сторінку. Перезавантажте його або відкрийте службу в системному браузері.';

  @override
  String get speedtestExternalFailed => 'Не вдалося відкрити системний браузер. Спробуйте знову.';

  @override
  String get modes => 'Режими';

  @override
  String get proxyShort => 'Проксі';

  @override
  String get tunMode => 'Весь трафік (TUN)';

  @override
  String get checkUpdates => 'Перевірте наявність оновлень';

  @override
  String get updates => 'Оновлення програми';

  @override
  String updateAvailable(String version) {
    return 'Доступна версія $version';
  }

  @override
  String get updateOpenAbout => 'Переглянути оновлення';

  @override
  String updateNotes(String version) {
    return 'Зміни в $version';
  }

  @override
  String get updateCheck => 'Перевірте наявність оновлень';

  @override
  String get updateChecking => 'Перевірка...';

  @override
  String get updateNoNotes => 'Реліз не має приміток.';

  @override
  String get updateDropWarning =>
      'Під час оновлення Sora та його основного з’єднання VPN-з’єднання припиниться на кілька секунд. Продовжити?';

  @override
  String get updateWaitConnection => 'Зачекайте, поки VPN-з’єднання та ядро ​​будуть готові.';

  @override
  String get updateDownloading => 'Завантаження та перевірка файлів...';

  @override
  String get updateInstalling => 'Підготовка оновлення або очікування автентифікації адміністратора...';

  @override
  String get updateNetworkError => 'Не вдалося завантажити оновлення. Спробуйте знову.';

  @override
  String get updateReleaseError => 'Дані випуску або необхідні файли відсутні або недійсні.';

  @override
  String get updateChecksumError => 'Завантаження не відповідає SHA256SUMS. Нічого не встановлено.';

  @override
  String get updateInstallError => 'Оновлення не завершено. Можливо, автентифікацію скасовано.';

  @override
  String get updateUnsupported =>
      'Цей виконуваний файл не належить підтримуваній парі пакетів Sora. Використовуйте інструкції з встановлення випуску.';

  @override
  String get updateManual =>
      'Виконайте цю команду в терміналі, щоб інсталювати обидва перевірені пакети, а потім повторно відкрийте Sora. Файли залишаються в каталозі завантаження. З’єднання VPN припиниться.';

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
  String get updateCopyCommand => 'Копіювати команду';

  @override
  String get updateChecksDisabled => 'Автоматичні перевірки вимкнено в налаштуваннях.';

  @override
  String get updateInstalled => 'Оновлення встановлено. Повторно відкрийте Sora.';

  @override
  String get projectLinks => 'Демонструвати';

  @override
  String get githubReleases => 'Релізи та завантаження';

  @override
  String get telegramChannel => 'Канал Telegram';

  @override
  String get licenses => 'Ліцензії';

  @override
  String get componentLicenses => 'Ліцензії на компоненти';

  @override
  String get appCopyright => '© 2026 levvs-one та співавтори';

  @override
  String get collapseServers => 'Згорнути сервери';

  @override
  String get expandServers => 'Розгорнути сервери';

  @override
  String get hideDescription => 'Приховати опис';

  @override
  String get showDescription => 'Показати опис';

  @override
  String get pendingConnectionChanges => 'Повторно підключіться, щоб застосувати ці зміни.';

  @override
  String get reconnectNow => 'Застосуйте та повторно підключіться';

  @override
  String get bypassLimitations =>
      'Цей режим обходить DPI лише для HTTP та TLS, не підтримує UDP і не змінює ваш IP. Використовуйте сервер VPN для голосу Discord, дзвінків і заблокованих адрес Telegram.';

  @override
  String get errEngineUnsupported =>
      'Вибраний механізм не підтримує цей профіль або налаштування. Виберіть Авто або сумісний двигун.';

  @override
  String get errRestore => 'Очищення підключення не завершено. Повторити відключення; подробиці дивіться в журналі.';

  @override
  String get errSessionEnded => 'Ця сесія вже закінчилася. Оновіть стан підключення.';

  @override
  String get retryDisconnect => 'Повторіть спробу відключення';

  @override
  String get tunStack => 'стек TUN';

  @override
  String get modesInfo => 'Про режими';

  @override
  String get modesGuideTitle => 'Режими і двигуни';

  @override
  String get modesGuide =>
      'Виберіть «Авто», якщо ви не впевнені, яка система потрібна вашому серверу. Sora перевіряє профіль і налаштування перед підключенням. Механізм не може збільшити пропускну здатність вашого плану: продуктивність залежить від сервера, маршруту, протоколу та мережі.\n\n## Режими\n\n### Весь трафік (TUN)\n\nSora створює віртуальний мережевий інтерфейс і направляє через нього трафік додатків, включаючи TCP і UDP. Використовуйте цей режим для Telegram, ігор і голосу Discord. Правила можуть безпосередньо надсилати певні сайти чи програми або блокувати їх. Службі мережі потрібен дозвіл і сервер, який підтримує необхідний протокол.\n\n### System проксі\n\nSora налаштовує локальний проксі HTTP/SOCKS. Програми, які поважають системні налаштування проксі-сервера, використовують його. Програми з власним мережевим стеком можуть підключатися безпосередньо; Для UDP і голосових викликів зазвичай потрібен TUN. Цей режим підходить для браузерів і програм з підтримкою проксі.\n\n### Немає сервера\n\nНа Linux Sora використовує [zapret](https://github.com/bol-van/zapret) для розділення та зміни форми запитів HTTP/TLS та обходу деяких перевірок DPI. Ваша IP-адреса залишається незмінною, а з’єднання йдуть безпосередньо на веб-сайт. Результати залежать від вашого провайдера та методу блокування.\n\nПоточна інтеграція використовує tpws для HTTP та TLS через TCP. Він не обходить IP-блокування та не ретранслює UDP і не може гарантувати з’єднання MTProto Telegram. Використовуйте сервер VPN із TUN для голосу Discord, дзвінків Telegram і подібних обмежень.\n\n## Двигуни\n\n### Авто\n\nSora вибирає встановлений механізм, який підтримує весь план підключення: протоколи сервера, транспорти, групи, фрагментацію та режим. Несумісний вибір вручну відхиляється перед припиненням поточного підключення. Виберіть «Авто» або інший механізм і знову застосуйте налаштування.\n\n### sing-box\n\nНові пакети Sora включають [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), розгалуження [sing-box](https://github.com/SagerNet/sing-box), додавання XHTTP і VLESS Encryption на стороні клієнта. Sora розпізнає конструкцію та її можливості. Вихідна збірка без XHTTP не отримує цю можливість лише через назву.\n\nПідтримувані протоколи включають VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard і параметри AmneziaWG 1.x/2.x Sora може імпортувати. Повні профілі Xray JSON потребують Xray. Нові поля AWG 3.x ще не можна імпортувати. sing-box використовує локальний порт керування, захищений паролем, який можуть виявити інші програми на комп’ютері.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) підтримує фрагментацію VLESS, REALITY, XHTTP, VLESS Encryption і TLS. Він також запускає повні профілі постачальника Xray, зберігаючи їх маршрутизацію та групи. Такі профілі не можна автоматично конвертувати в інший механізм без зміни їхньої поведінки.\n\nУ комплекті Xray видалено параметр, який вимикає перевірку сертифіката TLS (`allowInsecure`). Автоматично вибирає sing-box або mihomo для звичайних серверів, які потребують цього параметра. Вибір Xray вручну повідомляє про несумісність перед припиненням поточного з’єднання. Старіші повні профілі JSON потребують оновленого профілю постачальника з сертифікатом, який можна перевірити, або PIN-кодом сертифіката.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) підтримує впорядковані резервні групи та групи балансування навантаження, XHTTP і AmneziaWG. Виберіть його, коли автоматичне перемикання після відмови на резервний сервер має значення. Налаштування фрагментації TLS Sora недоступне з цим механізмом.\n\n## Сумісність у Sora\n\n| Особливість | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN і TCP/UDP | Так | Так | Так |\n| XHTTP | Так | Так | Так |\n| VLESS Encryption | Так | Так | Так |\n| Повний профіль Xray | Ні | Так | Ні |\n| TUIC / AnyTLS | Обидва | Ні | TUIC |\n| Фрагментація TLS | Так | Так | Ні |\n| AmneziaWG 1.x/2.x | Так¹ | Ні | Так |\n| Замовлена ​​резервна група | Ні | №² | Так |\n\n¹ Профілі з J1/J2/J3/Itime використовують mihomo; ці поля ніколи не можна мовчки відкидати. ² Для групи повних профілів Xray програма вибирає резервний профіль. Підтримка залежить від встановленої збірки; перевірте його версію в Про програму.\n\n## Стек TUN\n\nСтек обробляє TCP і UDP у віртуальному інтерфейсі. На панелі режимів Xray і mihomo пропонують gVisor, System, Mixed і MIPS. Кожен двигун зберігає власні переваги. Режими проксі System і режим без сервера не використовують цей параметр.\n\n- **Mixed** — TCP використовує системний стек, тоді як gVisor обробляє UDP. Це типовий варіант для mihomo в Linux. У Windows Xray і mihomo типово використовують MIPS.\n- **System** — використовує системний стек. Спробуйте інший варіант, якщо мережеві програми стикаються з проблемами.\n- **gVisor** — обробляє трафік у просторі користувача.\n- **MIPS** — власний IP-стек mihomo, доступний у пакетній версії 1.19.32.\n\nНа Linux Xray використовує свій вбудований gVisor за замовчуванням. System, Mixed і MIPS на Linux використовують mihomo як механізм TUN, пересилаючи TCP і UDP на Xray через автентифіковане локальне посилання SOCKS. Xray зберігає протокол, профіль провайдера та маршрутизацію. Для цих трьох опцій потрібен встановлений mihomo. На Windows Xray використовує mihomo 1.19.32 або новіший для всіх чотирьох стеків TUN. Протоколи й маршрутизація залишаються в Xray. Правила застосунків у цій зв’язці підтримують лише пряме з’єднання та блокування; на Linux вони потребують вбудованого gVisor Xray.\n\nМіст запускає другий процес. У трьох вимірюваннях бездіяльності на Linux він використовував приблизно на 32–36 МБ більше фізичної пам’яті, ніж рідний Xray TUN. Це не вимірює навантаження на завантаження: вартість процесора та пам’яті залежить від з’єднань. sing-box не має селектора стека. Жоден стек не гарантує кращої продуктивності в кожній мережі. Виберіть стек, виберіть «Застосувати» та повторно підключіться, щоб спробувати його у своїй мережі.\n\n## Застосування налаштувань\n\nВибір сервера повторює підключення автоматично. Налаштування режиму, механізму, DNS і правил зберігаються негайно; під час активного підключення натисніть «Застосувати» та підключіться повторно, щоб використовувати їх. Перезапуск двигуна може перервати завантаження та дзвінки. Повторні клацання не запускають паралельні підключення; від\'єднання завершує перехід і розриває з\'єднання.\n\nІнтернет лише через VPN блокує прямий трафік у разі обриву тунелю. Це впливає на всю машину. Явне відключення видаляє правила Sora. Якщо очищення не завершується, повторіть спробу від’єднання та відкрийте журнал.\n\n## Проектна документація\n\n- [sing-box-lx: налаштування та підтримка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Документація sing-box](https://sing-box.sagernet.org/)\n- [Документація Xray](https://xtls.github.io/)\n- [Документація mihomo](https://wiki.metacubex.one/)\n- [zapret: робота та обмеження] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Перевірити сервери';

  @override
  String get extensions => 'Розширення';

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
    return 'У $name';
  }

  @override
  String get diagnosticHttp => 'HTTP діагностика';

  @override
  String get diagnosticArchive => 'Core diagnostics archive';

  @override
  String get diagnosticNoData => 'Ще немає записаних запитів. Спочатку відкрийте сайт тесту швидкості.';

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
