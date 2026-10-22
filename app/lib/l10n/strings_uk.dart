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
  String get connEmpty => 'Немає з’єднань';

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
  String get errTunnel => 'Цей режим VPN недоступний. Виберіть інший режим або перевірте права служби.';

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
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'світло';

  @override
  String get themeDark => 'Темний';

  @override
  String get language => 'Мова';

  @override
  String get languageSystem => 'Як у системі';

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
  String get failover => 'Помилка ввімкнення';

  @override
  String get connectOnStart => 'Підключитися при запуску';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'термін дії підписки закінчується через $days днів',
      one: 'підписка закінчується через день $days',
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
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сервери $count, найшвидші',
      one: 'Сервер $count, найшвидший',
    );
    return '$_temp0';
  }

  @override
  String get tunnelMode => 'Режим';

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
  String get notificationsEmpty => 'Немає сповіщень';

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
  String get programsEmpty => 'Додатків не знайдено. Спробуйте інше ім\'я.';

  @override
  String get selectExe => 'Виберіть файл .exe';

  @override
  String get speedtest => 'швидкість';

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
      'Файли оновлення звіряються з контрольними сумами, опублікованими разом із релізом.';

  @override
  String get updateManualSigWarning =>
      'Файли нижче збігаються з контрольними сумами релізу. Виконайте команду, якщо завантажили їх з офіційного релізу.';

  @override
  String get updateVersionRevoked => 'Розробник відкликав цю версію. Зачекайте на виправлений випуск.';

  @override
  String get updateRolloutPending => 'Поступово розгортається новіша версія, яка буде запропонована вам автоматично.';

  @override
  String updateRollbacking(String version) {
    return 'Повернення до версії $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Оновлення до $version не пройшло перевірку справності, тому Sora було відкочено до $fromVersion.';
  }

  @override
  String get updateRollbackError =>
      'Помилка автоматичного відкоту. Якщо нова версія не працює, перевстановіть попередню версію вручну.';

  @override
  String get updateRollbackCacheError =>
      'Не вдалося підготувати перевірену відкочену копію поточної версії, тому оновлення не встановлено.';

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
      'Виберіть «Авто», якщо ви не впевнені, яка система потрібна вашому серверу. Sora перевіряє профіль і налаштування перед підключенням. Механізм не може збільшити пропускну здатність вашого плану: продуктивність залежить від сервера, маршруту, протоколу та мережі.\n\n## Режими\n\n### Весь трафік (TUN)\n\nSora створює віртуальний мережевий інтерфейс і направляє через нього трафік додатків, включаючи TCP і UDP. Використовуйте цей режим для Telegram, ігор і голосу Discord. Правила можуть безпосередньо надсилати певні сайти чи програми або блокувати їх. Службі мережі потрібен дозвіл і сервер, який підтримує необхідний протокол.\n\n### System проксі\n\nSora налаштовує локальний проксі HTTP/SOCKS. Програми, які поважають системні налаштування проксі-сервера, використовують його. Програми з власним мережевим стеком можуть підключатися безпосередньо; Для UDP і голосових викликів зазвичай потрібен TUN. Цей режим підходить для браузерів і програм з підтримкою проксі.\n\n### Немає сервера\n\nНа Linux Sora використовує [zapret](https://github.com/bol-van/zapret) для розділення та зміни форми запитів HTTP/TLS та обходу деяких перевірок DPI. Ваша IP-адреса залишається незмінною, а з’єднання йдуть безпосередньо на веб-сайт. Результати залежать від вашого провайдера та методу блокування.\n\nПоточна інтеграція використовує tpws для HTTP та TLS через TCP. Він не обходить IP-блокування та не ретранслює UDP і не може гарантувати з’єднання MTProto Telegram. Використовуйте сервер VPN із TUN для голосу Discord, дзвінків Telegram і подібних обмежень.\n\n## Двигуни\n\n### Авто\n\nSora вибирає встановлений механізм, який підтримує весь план підключення: протоколи сервера, транспорти, групи, фрагментацію та режим. Несумісний вибір вручну відхиляється перед припиненням поточного підключення. Виберіть «Авто» або інший механізм і знову застосуйте налаштування.\n\n### sing-box\n\nНові пакети Sora включають [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), розгалуження [sing-box](https://github.com/SagerNet/sing-box), додавання XHTTP і VLESS Encryption на стороні клієнта. Sora розпізнає конструкцію та її можливості. Вихідна збірка без XHTTP не отримує цю можливість лише через назву.\n\nПідтримувані протоколи включають VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard і параметри AmneziaWG 1.x/2.x Sora може імпортувати. Повні профілі Xray JSON потребують Xray. Нові поля AWG 3.x ще не можна імпортувати. sing-box використовує локальний порт керування, захищений паролем, який можуть виявити інші програми на комп’ютері.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) підтримує фрагментацію VLESS, REALITY, XHTTP, VLESS Encryption і TLS. Він також запускає повні профілі постачальника Xray, зберігаючи їх маршрутизацію та групи. Такі профілі не можна автоматично конвертувати в інший механізм без зміни їхньої поведінки.\n\nУ комплекті Xray видалено параметр, який вимикає перевірку сертифіката TLS (`allowInsecure`). Автоматично вибирає sing-box або mihomo для звичайних серверів, які потребують цього параметра. Вибір Xray вручну повідомляє про несумісність перед припиненням поточного з’єднання. Старіші повні профілі JSON потребують оновленого профілю постачальника з сертифікатом, який можна перевірити, або PIN-кодом сертифіката.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) підтримує впорядковані резервні групи та групи балансування навантаження, XHTTP і AmneziaWG. Виберіть його, коли автоматичне перемикання після відмови на резервний сервер має значення. Налаштування фрагментації TLS Sora недоступне з цим механізмом.\n\n## Сумісність у Sora\n\n| Особливість | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux / Windows TUN і TCP/UDP | Так | Так | Так |\n| XHTTP | Так | Так | Так |\n| VLESS Encryption | Так | Так | Так |\n| Повний профіль Xray | Ні | Так | Ні |\n| TUIC / AnyTLS | Обидва | Ні | TUIC |\n| mieru | Ні | Ні | Так |\n| NaiveProxy | Так | Ні | Ні |\n| Фрагментація TLS | Так | Так | Ні |\n| AmneziaWG 1.x/2.x | Так¹ | Ні | Так |\n| Замовлена ​​резервна група | Ні | №² | Так |\n\n¹ Профілі з J1/J2/J3/Itime використовують mihomo; ці поля ніколи не можна мовчки відкидати. ² Для групи повних профілів Xray програма вибирає резервний профіль. Підтримка залежить від встановленої збірки; перевірте його версію в Про програму.\n\n## Стек TUN\n\nСтек обробляє TCP і UDP у віртуальному інтерфейсі. На панелі режимів Xray і mihomo пропонують gVisor, System, Mixed і MIPS. Кожен двигун зберігає власні переваги. Режими проксі System і режим без сервера не використовують цей параметр.\n\n- **Mixed**: TCP використовує системний стек, тоді як gVisor обробляє UDP. Це типовий варіант для mihomo в Linux. У Windows Xray і mihomo типово використовують MIPS.\n- **System**: використовує системний стек. Спробуйте інший варіант, якщо мережеві програми стикаються з проблемами.\n- **gVisor**: обробляє трафік у просторі користувача.\n- **MIPS**: власний IP-стек mihomo, доступний у пакетній версії 1.19.32.\n\nНа Linux Xray використовує свій вбудований gVisor за замовчуванням. System, Mixed і MIPS на Linux використовують mihomo як механізм TUN, пересилаючи TCP і UDP на Xray через автентифіковане локальне посилання SOCKS. Xray зберігає протокол, профіль провайдера та маршрутизацію. Для цих трьох опцій потрібен встановлений mihomo. На Windows Xray використовує mihomo 1.19.32 або новіший для всіх чотирьох стеків TUN. Протоколи й маршрутизація залишаються в Xray. Правила застосунків у цій зв’язці підтримують лише пряме з’єднання та блокування; на Linux вони потребують вбудованого gVisor Xray.\n\nМіст запускає другий процес. У трьох вимірюваннях бездіяльності на Linux він використовував приблизно на 32–36 МБ більше фізичної пам’яті, ніж рідний Xray TUN. Це не вимірює навантаження на завантаження: вартість процесора та пам’яті залежить від з’єднань. sing-box не має селектора стека. Жоден стек не гарантує кращої продуктивності в кожній мережі. Виберіть стек, виберіть «Застосувати» та повторно підключіться, щоб спробувати його у своїй мережі.\n\n## Застосування налаштувань\n\nВибір сервера повторює підключення автоматично. Налаштування режиму, механізму, DNS і правил зберігаються негайно; під час активного підключення натисніть «Застосувати» та підключіться повторно, щоб використовувати їх. Перезапуск двигуна може перервати завантаження та дзвінки. Повторні клацання не запускають паралельні підключення; від\'єднання завершує перехід і розриває з\'єднання.\n\nІнтернет лише через VPN блокує прямий трафік у разі обриву тунелю. Це впливає на всю машину. Явне відключення видаляє правила Sora. Якщо очищення не завершується, повторіть спробу від’єднання та відкрийте журнал.\n\n## Проектна документація\n\n- [sing-box-lx: налаштування та підтримка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [Документація sing-box](https://sing-box.sagernet.org/)\n- [Документація Xray](https://xtls.github.io/)\n- [Документація mihomo](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: робота та обмеження] (https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC передає TCP через відеодзвінок у Jitsi, Яндекс Телемості або WB Stream. Імпортуйте посилання olcrtc:// або QR-код. Протокол працює з sing-box, Xray і mihomo в режимах проксі й TUN; UDP не підтримується. Обом сторонам потрібні сумісні збірки OLC2. Вихідний проєкт архівовано.\n';

  @override
  String get probeServers => 'Перевірити сервери';

  @override
  String get extensions => 'Розширення';

  @override
  String extRatingLabel(String rating) {
    return 'Рейтинг $rating з 5';
  }

  @override
  String extByAuthor(String author) {
    return 'від $author';
  }

  @override
  String extInstallsCount(String count) {
    return 'Встановлення: $count';
  }

  @override
  String get extInstallOne => '1 встановлення';

  @override
  String get extSideloadWarning => 'Установлюйте, лише якщо довіряєте самопідписаному ключу автора.';

  @override
  String get extPermissionsWidened => 'Оновлення запитує нові дозволи:';

  @override
  String get extDangerousAck => 'Я розумію, що ці дозволи серйозні';

  @override
  String get extInstall => 'Встановити';

  @override
  String get extUpdate => 'Оновити';

  @override
  String get extCancel => 'Скасувати';

  @override
  String get extConfirm => 'Підтвердити';

  @override
  String get extOk => 'OK';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Встановлені розширення';

  @override
  String get extSearchHint => 'Пошук розширень';

  @override
  String get extCatAll => 'Усі';

  @override
  String get extCatTools => 'Інструменти';

  @override
  String get extCatThemes => 'Теми';

  @override
  String get extCatAutomation => 'Автоматизація';

  @override
  String get extCatStats => 'Статистика';

  @override
  String get extCatNetwork => 'Мережа';

  @override
  String get extSortBy => 'Сортувати за';

  @override
  String get extSortPopular => 'Найпопулярніший';

  @override
  String get extSortRating => 'Найвищий рейтинг';

  @override
  String get extSortName => 'Назва';

  @override
  String get extCatalogError => 'Не вдалося завантажити каталог';

  @override
  String get extRetry => 'Повторіть спробу';

  @override
  String get extEmptySearch => 'Нічого не знайдено';

  @override
  String get extEmptyInstalled => 'Розширень ще не встановлено.\nЗнайдіть його в каталозі або встановіть із файлу.';

  @override
  String get extInstallFromFile => 'Встановити з файлу';

  @override
  String get extInstallFromUrl => 'Встановити з URL';

  @override
  String get extUrlHint => 'https://…/extension.soraext';

  @override
  String get extDownload => 'Завантажити';

  @override
  String get extDownloading => 'Завантаження…';

  @override
  String get extVerifying => 'Перевірка…';

  @override
  String get extInstalling => 'Встановлення…';

  @override
  String get extInstallFailed => 'Помилка встановлення';

  @override
  String get extErrSignature => 'Не вдалося перевірити підпис. Файл може бути пошкоджено або підроблено.';

  @override
  String get extErrManifest => 'Маніфест розширення недійсний.';

  @override
  String get extErrNetwork => 'Помилка мережі. Перевірте підключення та повторіть спробу.';

  @override
  String get extErrHash => 'Завантаження не відповідає каталогу. Можливо, це було підроблено.';

  @override
  String extErrMinApp(String version) {
    return 'Для цього розширення потрібна версія програми $version або новіша.';
  }

  @override
  String get extErrHttpsOnly => 'Дозволено лише посилання https://';

  @override
  String get extErrGeneric => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get extErrAuthorKeyChanged =>
      'Це оновлення підписано іншим ключем автора, ніж встановлена ​​версія, тому його було заблоковано. Якщо ви довіряєте новому ключу, видаліть розширення та встановіть його знову явно.';

  @override
  String get extDisabled => 'Вимкнено';

  @override
  String extToggleEnabled(String name) {
    return 'Увімкнути $name';
  }

  @override
  String get extSearchInstalled => 'Пошук серед установлених';

  @override
  String get extUpdateAll => 'Оновити все Доступні оновлення';

  @override
  String extUpdatesAvailable(int count) {
    return '$count';
  }

  @override
  String extUpdatedCount(int count) {
    return '$count оновлено';
  }

  @override
  String get extRiskNormal => 'Нормальний';

  @override
  String get extRiskSensitive => 'Чутливий';

  @override
  String get extRiskDangerous => 'Високий ризик';

  @override
  String get extPermissionsRemoved => 'Більше не вимагається:';

  @override
  String get extUpdateFailedKept => 'Попередня версія все ще встановлена.';

  @override
  String get extConflictsTitle => 'Конфлікти розширень';

  @override
  String get extConflictTheme => 'Тема програми';

  @override
  String get extConflictNetHooks => 'Мережеві перехоплення';

  @override
  String extConflictWinner(String name) {
    return 'Перевага: $name';
  }

  @override
  String extConflictsCount(int count) {
    return '$count конфлікти потребують вашого рішення';
  }

  @override
  String get extConflictsResolve => 'Вирішення конфліктів';

  @override
  String extVersionLabel(String version) {
    return 'Версія $version';
  }

  @override
  String get extPermissionsTitle => 'Дозволи';

  @override
  String get extNoPermissions => 'Немає спеціальних дозволів.';

  @override
  String get extSettings => 'Налаштування';

  @override
  String get extSaveSettings => 'Зберегти налаштування';

  @override
  String extUpdateTo(String version) {
    return 'Оновити до $version';
  }

  @override
  String get extEnabled => 'Увімкнено';

  @override
  String extRollbackTo(String version) {
    return 'Відкотити до $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Відкотити до версії $version?';
  }

  @override
  String get extUninstall => 'Видалити';

  @override
  String extUninstallConfirm(String name) {
    return 'Видалити «$name» та його налаштування?';
  }

  @override
  String get extPanelUnavailable => 'Панель розширення недоступна.';

  @override
  String get extPermConnectionsRead => 'Перегляд активних з\'єднань';

  @override
  String get extPermServersRead => 'Бачити список серверів';

  @override
  String get extPermSettingsRead => 'Прочитайте налаштування програми';

  @override
  String get extPermSettingsWrite => 'Змінити налаштування програми';

  @override
  String get extPermNotifications => 'Показати сповіщення';

  @override
  String get extPermTray => 'Додавати пункти до меню трею';

  @override
  String get extPermUiPanel => 'Показати панелі всередині програми';

  @override
  String get extPermThemeApply => 'Застосовувати теми оформлення';

  @override
  String get extPermRoutingRules => 'Додати правила маршрутизації (впливає на те, куди йде мережевий трафік)';

  @override
  String get extPermNetHooks => 'Інтеграція в мережевий шлях (модулі обходу DPI)';

  @override
  String get extPermNetFetch => 'Запитувати URL із дозволеного списку';

  @override
  String get extPermBackground => 'Запуск фонових завдань';

  @override
  String get extPermNotYetActive => 'Not active in this version of Sora yet, granting it changes nothing today.';

  @override
  String get extCapBackground => 'Працює у фоновому режимі';

  @override
  String get extCapNetHook => 'Обходи блокувань і мережеві хуки';

  @override
  String get extCapPanel => 'Інтерфейсні панелі';

  @override
  String get extCapRouting => 'Правила маршрутизації';

  @override
  String get extCapTheme => 'Теми';

  @override
  String get extCapWidget => 'Віджети';

  @override
  String extCatalogCached(String date) {
    return 'Cached catalog, $date';
  }

  @override
  String get extChangelog => 'Журнал змін';

  @override
  String get extImageFailed => 'Не вдалося завантажити зображення';

  @override
  String get extScreenshots => 'Скріншоти';

  @override
  String get extSortRelevance => 'Релевантність';

  @override
  String get extPermNetworkDetail => 'Запити через VPN дозволені лише до цих хостів.';

  @override
  String get extBgTitle => 'Фонове завдання';

  @override
  String get extBgEnabled => 'Виконувати у фоні';

  @override
  String get extBgInterval => 'Запускати кожні';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвилини',
      many: '$count хвилин',
      few: '$count хвилини',
      one: '$count хвилина',
    );
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count години',
      many: '$count годин',
      few: '$count години',
      one: '$count година',
    );
    return '$_temp0';
  }

  @override
  String get extBgDisabledNote => 'Увімкніть розширення для керування його фоновим завданням.';

  @override
  String get extCapNetwork => 'Доступ до мережі';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Мережа: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'У $name';
  }

  @override
  String get diagnosticHttp => 'HTTP діагностика';

  @override
  String get diagnosticNoData => 'Ще немає записаних запитів. Спочатку відкрийте сайт тесту швидкості.';

  @override
  String get qrShareTitle => 'Поділитися QR-кодом';

  @override
  String get qrScanTitle => 'Сканувати QR-код';

  @override
  String get qrCopyLink => 'Копіювати посилання';

  @override
  String get qrWarning => 'Показуйте код лише тим, кому довіряєте.';

  @override
  String get qrScanHint => 'Виберіть знімок екрана або фото з QR-кодом чи вставте посилання';

  @override
  String get qrFromClipboard => 'Вставити з буфера обміну';

  @override
  String get qrNoCode => 'На зображенні не знайдено QR-код.';

  @override
  String get qrInvalid => 'Цей код QR не містить дійсного посилання.';

  @override
  String get qrScan => 'Сканувати QR';

  @override
  String get qrFromImage => 'Відкрити зображення';

  @override
  String get connGroupByProcess => 'Згрупувати за процесом';

  @override
  String get connListView => 'Списком';

  @override
  String get connCopyHost => 'Копіювати хост';

  @override
  String get connAddRule => 'Додати правило';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count з’єднання',
      many: '$count з’єднань',
      few: '$count з’єднання',
      one: '$count з’єднання',
    );
    return '$_temp0';
  }

  @override
  String get dnsPreset => 'Пресет';

  @override
  String get dnsPresetCloudflare => 'Cloudflare';

  @override
  String get dnsPresetGoogle => 'Google';

  @override
  String get dnsPresetQuad9 => 'Quad9';

  @override
  String get dnsPresetAdGuard => 'AdGuard';

  @override
  String get dnsPresetCustom => 'Власний';

  @override
  String get dnsCheck => 'Перевірте наявність витоку даних';

  @override
  String get dnsChecking => 'Перевірка...';

  @override
  String get dnsNoLeak => 'Витоків не знайдено';

  @override
  String get dnsLeakFound => 'Витоку виявлено';

  @override
  String get dnsLastCheck => 'Остання перевірка';

  @override
  String get dnsNeverChecked => 'Ще не перевірялося';

  @override
  String get dnsLeakCheckTunnelDns => 'Резолвери DNS тунелю';

  @override
  String get dnsLeakCheckSystemResolvers => 'Системні резолвери';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Захист DNS через kill switch';

  @override
  String get dnsLeakFixConfigureTunnelDns => 'Налаштуйте DNS для тунелю в налаштуваннях DNS вище.';

  @override
  String get dnsLeakFixReviewSystemResolvers => 'Перевірте, які резолвери ваша система використовуватиме поза тунелем.';

  @override
  String get dnsLeakFixEnableKillSwitch => 'Увімкніть kill switch, щоб трафік DNS залишався в тунелі.';

  @override
  String get dnsLeakCheckEncryptedDns => 'Зашифрований DNS системи';

  @override
  String get dnsLeakCheckDnsSpoof => 'Підроблені відповіді DNS';

  @override
  String get dnsLeakFixReviewEncryptedDns =>
      'Перевірте, які зашифровані кінцеві точки DNS використовує ваша система поза тунелем.';

  @override
  String get dnsLeakFixUseEncryptedDns =>
      'Використовуйте зашифрований DNS (DoT або DoH) для тунелю, щоб резолвери не могли підробити відповіді.';

  @override
  String get dnsCheckNeedsConnection => 'Спочатку підключіться до VPN, а потім перевірте наявність витоків.';

  @override
  String get dnsExpected => 'Очікується';

  @override
  String get dnsActual => 'Дотримується';

  @override
  String get measureSpeed => 'Виміряйте швидкість';

  @override
  String get benchmarkStale => 'застарілий';

  @override
  String get autoSelectMode => 'Автоматичний вибір сервера';

  @override
  String get autoSelectPing => 'Найшвидший пінг';

  @override
  String get autoSelectSpeed => 'Найшвидша швидкість';

  @override
  String get autoSelectSmart => 'Розумний вибір';

  @override
  String get coreWatchUnstable => 'Підключення до ядра Sora нестабільне';

  @override
  String get watchReconnect => 'Перепідключити';

  @override
  String get crashRestoreTitle => 'Останній сеанс було перервано';

  @override
  String get restoreOnCrash => 'Відновити сеанс після збою';

  @override
  String get crashRestore => 'Відновити';

  @override
  String get crashDismiss => 'Не зараз';

  @override
  String get overrideTitle => 'Мої редагування';

  @override
  String get overrideEdit => 'Редагувати сервери';

  @override
  String get overrideHide => 'Сховати';

  @override
  String get overrideUnhide => 'Показати';

  @override
  String get overrideClear => 'Скинути правки';

  @override
  String get overrideEmpty => 'Ще жодних змін';

  @override
  String get overrideCustomRules => 'Свої правила';

  @override
  String get errBenchmarkUnsupported => 'Для вимірювання швидкості потрібне нове ядро';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Замір $done з $total…';
  }

  @override
  String get profiles => 'Профілі мережі';

  @override
  String get profilesEmpty =>
      'Ще немає профілів. Створіть його, щоб автоматично застосувати налаштування до відомих мереж.';

  @override
  String get profileAdd => 'Додати профіль';

  @override
  String get profileName => 'Назва профілю';

  @override
  String get profileSsids => 'Wi-Fi мережі (SSID)';

  @override
  String get profileSsidsHint => 'Будинок, Офіс через кому';

  @override
  String get profileGateways => 'Мережеві шлюзи';

  @override
  String get profileAsns => 'AS чисел';

  @override
  String get profileAutoApply => 'Застосовувати автоматично';

  @override
  String get profileAutoApplyHint => 'Якщо вимкнено, запитувати перед застосуванням профілю.';

  @override
  String get profileSnapshot => 'Запам\'ятати поточні налаштування';

  @override
  String get profileSnapshotDone => 'Поточні налаштування збережено в профілі';

  @override
  String get profileDelete => 'Видалити профіль';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Видалити профіль \"$name\"?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Застосувати профіль \"$name\"?';
  }

  @override
  String get profileApply => 'Застосувати';

  @override
  String profileApplied(Object name) {
    return 'Профіль «$name» застосований';
  }

  @override
  String get profileUndo => 'Скасувати';

  @override
  String get profileActive => 'Активний';

  @override
  String networkNow(Object info) {
    return 'Зараз: $info';
  }

  @override
  String get networkUnknown => 'Інформація про мережу недоступна';

  @override
  String get profileNoTriggers => 'Додайте принаймні один тригер: SSID, шлюз або ASN';

  @override
  String get chains => 'Ланцюжки проксі';

  @override
  String get chainsEmpty => 'Ланцюгів ще немає. Зв’яжіть 2–3 сервери, щоб трафік проходив через кожен із них.';

  @override
  String get chainAdd => 'Новий ланцюг';

  @override
  String get chainName => 'Назва ланцюга';

  @override
  String get chainPickServers => 'Виберіть 2–3 сервери';

  @override
  String get chainOrderHint => 'Перетягніть, щоб змінити порядок: рух в’їжджає вгорі, а виходить – унизу.';

  @override
  String get chainTooFew => 'Виберіть принаймні 2 сервери';

  @override
  String get chainTooMany => 'Ланцюжок містить щонайбільше 3 сервери';

  @override
  String get chainEstimate => 'Розрахункова затримка';

  @override
  String get chainSave => 'Зберегти ланцюжок';

  @override
  String get chainDelete => 'Видалити ланцюжок';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Видалити ланцюжок \"$name\"?';
  }

  @override
  String get chainUnsupported => 'Поточний двигун не підтримує ланцюжки';

  @override
  String get chainHopMissing => 'Один із ланцюжкових серверів більше не доступний';

  @override
  String chainHop(Object n) {
    return 'Перехід $n';
  }

  @override
  String get chainEntry => 'Вхід';

  @override
  String get chainExit => 'Вихід';

  @override
  String get sync => 'Синхронізація пристроїв';

  @override
  String get syncDevices => 'Мої пристрої';

  @override
  String get syncEmpty => 'Немає сполучених пристроїв. Підключіть інший пристрій через локальну мережу.';

  @override
  String get syncPair => 'Спарити пристрій';

  @override
  String get syncShowCode => 'Показати мій код';

  @override
  String get syncScanCode => 'Сканувати код';

  @override
  String get syncRevoke => 'Відкликати';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Відкликати \"$name\"?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Остання синхронізація: $time';
  }

  @override
  String get syncNever => 'Ніколи';

  @override
  String get syncNoLan => 'Пристрої мають бути в одній локальній мережі';

  @override
  String get syncPaired => 'Пристрій спарений';

  @override
  String get syncPairingTitle => 'Спарити з цим пристроєм';

  @override
  String get syncWaiting => 'Очікування іншого пристрою…';

  @override
  String get syncSecureNote => 'Канал із наскрізним шифруванням. Ні облікових записів, ні хмарних серверів.';

  @override
  String get zapretWithVpn => 'Обхід фільтрації DPI для прямого мережевого трафіку';

  @override
  String get zapretWithVpnHint =>
      'Запускає zapret разом із VPN-тунелем: трафік тунелю йде через VPN, а прямий трафік через засіб обходу блокувань.';

  @override
  String get chainDuplicate => 'Кожен сервер може з\'явитися лише один раз';

  @override
  String get edit => 'Редагувати';

  @override
  String get remove => 'Видалити';

  @override
  String get autoSwitchOnDegrade => 'Автоматичне перемикання при деградації';

  @override
  String get autoSwitchOnDegradeDetail =>
      'Якщо вибраний сервер сильно сповільниться або перестане відповідати, Sora перемкнеться на найкращий за вимірюваннями, але не частіше ніж раз на 10 хвилин.';

  @override
  String get tunStackMixed => 'Змішаний';

  @override
  String get tunStackSystem => 'Системний';

  @override
  String get customServerAdd => 'Додати спеціальний сервер';

  @override
  String get customServers => 'Мої сервери';

  @override
  String get customServerName => 'Назва';

  @override
  String get customServerNameHint => 'Наприклад: мій VPS';

  @override
  String get customServerNameRequired => 'Введіть назву';

  @override
  String get customServerAddress => 'Адреса';

  @override
  String get customServerAddressHint => 'example.com або 192.0.2.1';

  @override
  String get customServerAddressRequired => 'Введіть адресу сервера';

  @override
  String get customServerAddressInvalid => 'Недійсна адреса';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortHint => '443';

  @override
  String get customServerPortInvalid => 'Порт має бути числом від 1 до 65535';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Дані для входу';

  @override
  String get customServerOptional => 'Необов\'язково';

  @override
  String get customServerShowSecret => 'Показати секрет';

  @override
  String get customServerHideSecret => 'Сховати секрет';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Видалити сервер “$name”?';
  }

  @override
  String get customServerTest => 'Тест';

  @override
  String get leakTestTitle => 'Перевірка на витік даних';

  @override
  String get leakTestIntro =>
      'Перевіряє, чи може трафік залишити пристрій поза тунелем: прямі запити DNS та ICMP, вихід IPv6 і системні резолвери. Запускайте під час активного підключення.';

  @override
  String get leakTestRun => 'Перевірити';

  @override
  String get leakTestCancel => 'Скасувати';

  @override
  String get leakTestNeedsConnection => 'Підключіться до VPN, щоб перевірити наявність витоку даних.';

  @override
  String leakTestProgress(int count) {
    return 'Тести завершено: $count';
  }

  @override
  String get leakTestAllClear => 'Витоків не знайдено';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Знайдено $count витоку',
      many: 'Знайдено $count витоків',
      few: 'Знайдено $count витоки',
      one: 'Знайдено $count витік',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Skipped, not applicable in this session';

  @override
  String get leakTestFix => 'Виправити';

  @override
  String get leakTestFixedNote => 'Kill switch увімкнено. Повторіть перевірку.';

  @override
  String get leakTestCheckDirectDns => 'Прямий DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP відлуння';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Системні резолвери';

  @override
  String get leakTestCheckTunnelConnectivity => 'Підключення тунелю';

  @override
  String get leakTestCheckTunnelDns => 'DNS через тунель';

  @override
  String get noticeDegraded =>
      'Сервер став повільним. Sora перейшов на найкращий сервер, знайдений під час вимірювання.';

  @override
  String get obfs => 'Маскування трафіку';

  @override
  String get syncCodeExpired => 'Строк дії коду минув';

  @override
  String get syncDaemonFailed => 'Не вдалося запустити службу синхронізації';

  @override
  String get syncDaemonMissing =>
      'Компонент sora-sync не знайдено. Перевстановіть програму, щоб увімкнути синхронізацію пристрою.';

  @override
  String get syncDaemonStarting => 'Запуск служби синхронізації…';

  @override
  String get syncErrAuth =>
      'Служба синхронізації відхилила маркер доступу. Перезапустіть програму та повторіть спробу.';

  @override
  String get syncErrNotFound => 'Пристрій більше не підключено';

  @override
  String get syncErrPairingActive => 'Сеанс створення пари вже відкрито';

  @override
  String get syncErrUnreachable =>
      'Інший пристрій не відповідає. Переконайтеся, що він у тій самій мережі та відображає його код.';

  @override
  String get syncError => 'Помилка синхронізації';

  @override
  String syncExpiresIn(String duration) {
    return 'Термін дії коду спливе через $duration';
  }

  @override
  String get syncJoining => 'Сполучення з пристроєм…';

  @override
  String get syncLegacyCleared =>
      'Старий список пристроїв насправді ніколи не сполучався, тому його було очищено. З’єднайте свої пристрої знову, цього разу по-справжньому.';

  @override
  String get syncNewCode => 'Новий код';

  @override
  String syncPairedWith(String name) {
    return 'в парі з $name';
  }

  @override
  String get syncRetry => 'Повторити';

  @override
  String get syncStopShowing => 'Сховати код';

  @override
  String get syncSyncNow => 'Синхронізувати';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Отримано $pulled, надіслано $pushed';
  }

  @override
  String get syncResultTitle => 'Результат синхронізації';

  @override
  String get syncPulled => 'Отримано';

  @override
  String get syncPushed => 'Відправлено';

  @override
  String get syncNoChanges => 'Змін не виявлено';

  @override
  String get syncDocKindSubscriptions => 'Підписки';

  @override
  String get syncDocKindSettings => 'Налаштування програми';

  @override
  String get syncDocKindOverrides => 'Перевизначення підписок';

  @override
  String get syncDocKindProfiles => 'Профілі мережі';

  @override
  String get syncDocKindChains => 'Ланцюжки проксі';

  @override
  String syncFrom(String name) {
    return 'з $name';
  }

  @override
  String get syncThisDevice => 'Цей пристрій';

  @override
  String get syncUnavailableAndroid =>
      'Device sync isn\'t available on Android yet, the sync service can\'t run there.';

  @override
  String get diagnosticPackets => 'Перехоплення пакетів';

  @override
  String get diagnosticEvents => 'Події Windows';

  @override
  String get diagnosticCapture => 'Зробіть знімок на 10 секунд';

  @override
  String get diagnosticRequiresTun => 'Для захоплення пакетів потрібне активне з’єднання Sora TUN.';

  @override
  String get diagnosticUnavailable => 'Ця діагностика недоступна на цій платформі.';

  @override
  String get extErrRevoked => 'Команда Sora відкликала цю версію розширення: вона небезпечна або зламана.';

  @override
  String get extErrRevocationsExpired => 'Установлення заблоковано до оновлення списку відкликаних розширень.';

  @override
  String extRevokedDisabled(String names) {
    return 'Вимкнено відкликані розширення: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Приватний ключ';

  @override
  String get customServerWgAddresses => 'Адреси інтерфейсу';

  @override
  String get customServerWgPeerKey => 'Публічний ключ сервера';

  @override
  String get customServerWgPresharedKey => 'Спільний ключ';

  @override
  String get customServerWgAllowedIps => 'Дозволені IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, секунд';

  @override
  String get customServerWgKeyInvalid => 'Ключ має бути 32 байтами в base64, як виводить wg genkey.';

  @override
  String get customServerWgCidrInvalid => 'Вкажіть адреси через кому у вигляді 10.0.0.2/32.';

  @override
  String get customServerWgKeepaliveInvalid => 'Вкажіть кількість секунд від 0 до 65535.';

  @override
  String get strictKillSwitch => 'Суворий kill switch';

  @override
  String get strictKillSwitchWarning =>
      'Після підключення блокує трафік поза VPN навіть після збою, перезапуску чи виходу з програми. Доступ відновиться лише після відключення VPN або цієї опції. Після перезавантаження блокування відновлюється лише з увімкненим підключенням під час запуску.';

  @override
  String get extWorkerFailed => 'Фонове завдання розширення завершилося з помилкою. Перевірте журнал розширення.';

  @override
  String get extAssetRejected => 'Файл розширення відхилено: нечитабельні кольори або неправильні правила.';

  @override
  String get extVerifiedSora => 'Перевірено Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count Б';
  }

  @override
  String get extOpen => 'Відкрити';

  @override
  String get customServerOwn => 'Власний сервер';

  @override
  String get customServerPaste => 'Вставити посилання';

  @override
  String get customServerUser => 'Користувач';

  @override
  String get customServerPassword => 'Пароль';

  @override
  String get customServerSecretRequired => 'Введіть значення';

  @override
  String get customServerLinkInvalid => 'Неправильне посилання на сервер';

  @override
  String get customServerMethodHint => 'chacha20-ietf-poly1305';

  @override
  String get customServerWgAddressesHint => '10.0.0.2/32';

  @override
  String get errInternal => 'Внутрішня помилка Sora. Збережіть журнал і повідомте про збій.';

  @override
  String get errTls => 'Сертифікат сервера відхилено. Перевірте годинник або зверніться до провайдера.';

  @override
  String get errFileAccess => 'Немає доступу до файлу. Перевірте права та вільне місце.';

  @override
  String get errDataLimit => 'Забагато даних. Виберіть менше елементів і повторіть.';

  @override
  String get errCredentials => 'Збережені дані доступу втрачено. Імпортуйте сервер знову.';

  @override
  String subscriptionStale(String time) {
    return 'Оновлено: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Ще не оновлювалася. Повторіть.';

  @override
  String get errHttpStatus => 'Сервер відхилив запит. Перевірте посилання або зверніться до провайдера.';

  @override
  String get errInvalidServer => 'Налаштування сервера неповні або не підтримуються. Оновіть підписку.';

  @override
  String get errServerIds => 'Два сервери мають однаковий ідентифікатор. Імпортуйте їх знову.';

  @override
  String get errRoutingGroup => 'Маршрут посилається на видалені сервери або пошкоджену групу. Оновіть підписку.';

  @override
  String get errConnections => 'Список підключень недоступний. Підключіться або виберіть інше ядро.';

  @override
  String get errLogs => 'Ця служба не веде журнал. Оновіть Sora.';

  @override
  String get errDiagnostics => 'Не вдалося зібрати діагностику. Повторіть або збережіть журнал.';

  @override
  String get errMissingItem => 'Запитаний елемент більше не існує. Оновіть список.';

  @override
  String get errInvalidRequest => 'У запиті неправильні значення. Перевірте введені дані та повторіть.';

  @override
  String get errProxyLogin => 'Системний проксі не підтримує цей вхід. Видаліть логін і пароль локального проксі.';

  @override
  String get errLogFilter => 'Неправильний фільтр журналу. Очистьте пошук і повторіть.';

  @override
  String get errSubRedirect => 'Сервер перенаправив на небезпечну адресу. Запитайте нове посилання у провайдера.';

  @override
  String get errProxySetup => 'Не вдалося налаштувати системний проксі. Перепідключіться або відкрийте журнал.';

  @override
  String get notificationsToday => 'Сьогодні';

  @override
  String get notificationsYesterday => 'Учора';

  @override
  String get notificationsMarkRead => 'Прочитати всі';

  @override
  String get notificationsUnread => 'Не прочитано';

  @override
  String get desktopNotifications => 'Системні сповіщення';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }
}
