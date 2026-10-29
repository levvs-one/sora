// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get stateOff => 'Не подключено';

  @override
  String get stateConnecting => 'Подключение';

  @override
  String get stateConnected => 'Подключено';

  @override
  String get stateReconnecting => 'Переподключение';

  @override
  String get stateDisconnecting => 'Отключение';

  @override
  String get coreMissing => 'Служба Sora не отвечает';

  @override
  String get serverAuto => 'Самый быстрый';

  @override
  String get serverBypass => 'Без сервера';

  @override
  String get addSubscription => 'Добавить подписку';

  @override
  String get servers => 'Серверы';

  @override
  String get settings => 'Настройки';

  @override
  String get subscription => 'Подписка';

  @override
  String get subscriptionLink => 'Ссылка на подписку';

  @override
  String get add => 'Добавить';

  @override
  String get refresh => 'Обновить';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get name => 'Название';

  @override
  String deleteSubscription(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get routes => 'Маршруты';

  @override
  String get presetGlobal => 'Всё через VPN';

  @override
  String get presetRu => 'Россия напрямую';

  @override
  String get presetIr => 'Иран напрямую';

  @override
  String get presetCn => 'Китай напрямую';

  @override
  String get blockAds => 'Блокировать рекламу';

  @override
  String get killSwitch => 'Интернет только через VPN';

  @override
  String get engine => 'Ядро';

  @override
  String get engineAuto => 'Авто';

  @override
  String get animations => 'Анимации';

  @override
  String get logs => 'Журнал';

  @override
  String get about => 'О приложении';

  @override
  String get logsAll => 'Все';

  @override
  String get logsImportant => 'Важное';

  @override
  String get logsErrors => 'Ошибки';

  @override
  String get search => 'Поиск';

  @override
  String get export => 'Сохранить в файл';

  @override
  String get clear => 'Очистить';

  @override
  String get logsEmpty => 'Здесь пусто';

  @override
  String get connEmpty => 'Нет соединений';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get notInstalled => 'Не установлено';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get license => 'Лицензия';

  @override
  String usage(String used, String total) {
    return '$used из $total';
  }

  @override
  String until(String date) {
    return 'до $date';
  }

  @override
  String get expired => 'Срок истёк';

  @override
  String milliseconds(int n) {
    return '$n мс';
  }

  @override
  String latencyMs(int value) {
    return '$value мс';
  }

  @override
  String speedMbps(double value) {
    return '$value Мбит/с';
  }

  @override
  String bytesB(String n) {
    return '$n Б';
  }

  @override
  String bytesKB(String n) {
    return '$n КБ';
  }

  @override
  String bytesMB(String n) {
    return '$n МБ';
  }

  @override
  String bytesGB(String n) {
    return '$n ГБ';
  }

  @override
  String bytesTB(String n) {
    return '$n ТБ';
  }

  @override
  String get errGeneric => 'Что-то пошло не так';

  @override
  String get errCore => 'Служба Sora не отвечает';

  @override
  String get errAuth => 'Нет доступа к службе Sora';

  @override
  String get errVersion => 'Приложение и служба Sora разных версий';

  @override
  String get errBusy => 'Предыдущая команда ещё выполняется';

  @override
  String get errEngineMissing => 'Не найдено ядро для этого сервера';

  @override
  String get errEngineStart => 'Ядро не запустилось';

  @override
  String get errEngineStopped => 'Ядро остановилось';

  @override
  String get errTunnel => 'Этот режим VPN недоступен';

  @override
  String get errTimeout => 'Сервер не ответил вовремя';

  @override
  String get errFirewall => 'Не удалось включить блокировку интернета без VPN';

  @override
  String get errSubFetch => 'Не удалось загрузить подписку';

  @override
  String get deviceIdentity => 'Идентификатор устройства';

  @override
  String get hwid => 'HWID';

  @override
  String get deviceIdentityReset => 'Сбросить идентификатор';

  @override
  String get deviceIdentityResetConfirm => 'Сбросить идентификатор устройства?';

  @override
  String get errSubDeviceLimit => 'Превышен лимит устройств';

  @override
  String get errSubDeviceRequired => 'Провайдер требует идентификатор устройства';

  @override
  String get errSubFormat => 'Формат подписки не распознан';

  @override
  String get errSubEmpty => 'В подписке нет серверов';

  @override
  String get errSubDuplicate => 'Эта подписка уже добавлена';

  @override
  String get errSubLimit => 'Достигнут предел числа подписок';

  @override
  String get errSubScheme => 'Неподдерживаемая схема ссылки подписки';

  @override
  String get errSecretStore => 'Хранилище Sora повреждено или недоступно';

  @override
  String get errNoServers => 'Нет серверов для подключения';

  @override
  String get connections => 'Соединения';

  @override
  String get close => 'Закрыть';

  @override
  String get chainDirect => 'Напрямую';

  @override
  String get chainBlocked => 'Заблокировано';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get sectionConnection => 'Подключение';

  @override
  String get sectionNoServer => 'Без сервера';

  @override
  String get sectionPing => 'Пинг';

  @override
  String get sectionLog => 'Диагностика';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Авто';

  @override
  String get fragment => 'Фрагментация TLS';

  @override
  String get fragmentPackets => 'Что дробить';

  @override
  String get fragmentLength => 'Размер частей';

  @override
  String get fragmentInterval => 'Пауза между частями';

  @override
  String get byDefault => 'По умолчанию';

  @override
  String get splitPos => 'Места разбиения';

  @override
  String get disorder => 'Менять порядок частей';

  @override
  String get tlsRecord => 'Делить TLS-запись';

  @override
  String get tlsRecordNo => 'Нет';

  @override
  String get tlsRecordSni => 'По имени сайта';

  @override
  String get tlsRecordFirst => 'После первого байта';

  @override
  String get hostCase => 'Менять регистр Host';

  @override
  String get probeMethod => 'Способ';

  @override
  String get probeAuto => 'Авто';

  @override
  String get probeEngine => 'Через ядро';

  @override
  String get probeConnect => 'Только соединение';

  @override
  String get probeUrl => 'Адрес проверки';

  @override
  String get probeTimeout => 'Ожидание';

  @override
  String seconds(int n) {
    return '$n с';
  }

  @override
  String get subscriptions => 'Подписки';

  @override
  String get subscriptionSettings => 'Настройки';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get autoUpdate => 'Обновлять автоматически';

  @override
  String get updateInterval => 'Как часто';

  @override
  String get intervalProvider => 'Как просит провайдер';

  @override
  String hours(int n) {
    return '$n ч';
  }

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String get logLevel => 'Что записывать';

  @override
  String get levelDebug => 'Всё';

  @override
  String get levelInfo => 'Обычное';

  @override
  String get levelWarning => 'Важное';

  @override
  String get levelError => 'Только ошибки';

  @override
  String get recordDestinations => 'Записывать адреса сайтов';

  @override
  String get reset => 'Сбросить настройки';

  @override
  String get resetConfirm => 'Сбросить все настройки?';

  @override
  String get resetAction => 'Сбросить';

  @override
  String get invalidValue => 'Такое значение не подойдёт';

  @override
  String get website => 'Сайт подписки';

  @override
  String get providerWebsite => 'Сайт провайдера';

  @override
  String get support => 'Поддержка';

  @override
  String chooseEngine(String engine) {
    return 'Выбрать $engine';
  }

  @override
  String get rules => 'Свои правила';

  @override
  String get ruleAdd => 'Новое правило';

  @override
  String get ruleHint => 'Сайт, IP или программа';

  @override
  String get ruleDirect => 'Напрямую';

  @override
  String get ruleProxy => 'Через VPN';

  @override
  String get ruleBlock => 'Блокировать';

  @override
  String get failover => 'Переключаться при сбое';

  @override
  String get connectOnStart => 'Подключаться при запуске';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дней',
      few: '$days дня',
      one: '$days день',
      zero: 'несколько часов',
    );
    return '$name: подписка закончится через $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: осталось $left';
  }

  @override
  String get ruleInvalid => 'Не похоже на сайт, IP или программу';

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count серверов',
      few: '$count сервера',
      one: '$count сервер',
    );
    return '$_temp0, самый быстрый';
  }

  @override
  String get tunnelMode => 'Режим';

  @override
  String get tunnelProxy => 'Системный прокси';

  @override
  String get proxyAddress => 'Адрес прокси';

  @override
  String get copied => 'Скопировано';

  @override
  String get launchAtLogin => 'Запускать вместе с системой';

  @override
  String get closeToTray => 'Сворачивать в трей при закрытии';

  @override
  String get notifications => 'Уведомления';

  @override
  String get trayOpen => 'Открыть Sora';

  @override
  String get trayConnect => 'Подключить';

  @override
  String get trayDisconnect => 'Отключить';

  @override
  String get trayServer => 'Сервер';

  @override
  String get trayQuit => 'Выйти из Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora осталась в трее';

  @override
  String get noticeLost => 'Соединение прервалось';

  @override
  String get noticeLostBody => 'Sora переподключается';

  @override
  String get noticeRestored => 'Снова подключено';

  @override
  String get noticeFailed => 'Не удалось подключиться';

  @override
  String get noticeBackup => 'Основной сервер не ответил, работает запасной';

  @override
  String get noticeNext => 'Сервер не ответил, работает следующий';

  @override
  String get noticeMainBack => 'Основной сервер снова отвечает, трафик идёт через него';

  @override
  String get noticeSubscription => 'Подписка';

  @override
  String get importTitle => 'Добавить подписку?';

  @override
  String get importSealed => 'Эта ссылка зашифрована для Happ, прочитать её может только Happ';

  @override
  String get noAnswer => 'нет ответа';

  @override
  String get home => 'Главная';

  @override
  String get navRules => 'Правила';

  @override
  String get navConnections => 'Подключения';

  @override
  String get navLogs => 'Логи';

  @override
  String get navAbout => 'О приложении';

  @override
  String get sidebarToggle => 'Развернуть меню';

  @override
  String get more => 'Ещё';

  @override
  String get less => 'Свернуть';

  @override
  String get notificationsEmpty => 'Нет уведомлений';

  @override
  String get retryConnect => 'Подключиться снова';

  @override
  String get openLogs => 'Открыть логи';

  @override
  String get tourBack => 'Назад';

  @override
  String get tourNext => 'Далее';

  @override
  String get chooseProgram => 'Выбрать программу';

  @override
  String get installedApps => 'Установленные программы';

  @override
  String get runningProcesses => 'Запущенные процессы';

  @override
  String get programsEmpty => 'Программы не найдены';

  @override
  String get selectExe => 'Выбрать файл .exe';

  @override
  String get speedtest => 'Скорость';

  @override
  String get speedtestSearch => 'Найти сервис';

  @override
  String get speedtestEmpty => 'Ничего не найдено';

  @override
  String get speedtestBackToList => 'К списку сервисов';

  @override
  String get speedtestOpenBrowser => 'Открыть в браузере';

  @override
  String get speedtestUnavailable => 'Встроенный браузер не запустился';

  @override
  String get speedtestPageFailed => 'Страница не загрузилась';

  @override
  String get speedtestExternalFailed => 'Системный браузер не открылся';

  @override
  String get modes => 'Режимы';

  @override
  String get proxyShort => 'Прокси';

  @override
  String get tunMode => 'Весь трафик (TUN)';

  @override
  String get checkUpdates => 'Проверять обновления';

  @override
  String get updates => 'Обновления приложения';

  @override
  String updateAvailable(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get updateOpenAbout => 'Посмотреть обновление';

  @override
  String updateNotes(String version) {
    return 'Что изменилось в $version';
  }

  @override
  String get updateCheck => 'Проверить обновления';

  @override
  String get updateChecking => 'Проверяем...';

  @override
  String get updateNoNotes => 'Автор релиза не добавил описание.';

  @override
  String get updateDropWarning => 'Прервать соединение для обновления?';

  @override
  String get updateWaitConnection => 'Подключение ещё не готово';

  @override
  String get updateNetworkError => 'Не удалось скачать обновление';

  @override
  String get updateReleaseError => 'Данные релиза или нужные файлы отсутствуют либо некорректны.';

  @override
  String get updateChecksumError => 'Файл не совпадает с SHA256SUMS';

  @override
  String get updateInstallError => 'Обновление не завершилось';

  @override
  String get updateUnsupported => 'Этот файл приложения не принадлежит поддерживаемой паре пакетов Sora';

  @override
  String get updateVersionRevoked => 'Эта версия отозвана разработчиком';

  @override
  String updateRollbacking(String version) {
    return 'Откатываемся к версии $version...';
  }

  @override
  String updateRolledBack(String version, String fromVersion) {
    return 'Обновление до $version не прошло проверку работоспособности, поэтому Sora откатилась к $fromVersion.';
  }

  @override
  String get updateRollbackError => 'Автоматический откат не удался';

  @override
  String get updateRollbackCacheError =>
      'Не удалось подготовить проверенную копию текущей версии для отката, поэтому обновление не установлено.';

  @override
  String get updateCopyCommand => 'Скопировать команду';

  @override
  String get updateInstalled => 'Обновление установлено';

  @override
  String get projectLinks => 'Проект';

  @override
  String get githubReleases => 'Релизы и загрузки';

  @override
  String get telegramChannel => 'Канал в Telegram';

  @override
  String get licenses => 'Лицензии';

  @override
  String get componentLicenses => 'Лицензии компонентов';

  @override
  String get collapseServers => 'Свернуть серверы';

  @override
  String get expandServers => 'Показать серверы';

  @override
  String get hideDescription => 'Скрыть описание';

  @override
  String get showDescription => 'Показать описание';

  @override
  String get errEngineUnsupported => 'Выбранное ядро не поддерживает этот профиль или настройки';

  @override
  String get errRestore => 'Не удалось полностью очистить подключение';

  @override
  String get errSessionEnded => 'Эта сессия уже завершена';

  @override
  String get retryDisconnect => 'Повторить отключение';

  @override
  String get tunStack => 'Стек TUN';

  @override
  String get modesInfo => 'Подробнее о режимах';

  @override
  String get modesGuideTitle => 'Режимы и ядра';

  @override
  String get modesGuide =>
      'Выбирайте «Авто», если не знаете, какое ядро нужно серверу. Sora сверяет поддержку профиля и настроек перед подключением. Само ядро не меняет скорость тарифа: результат зависит от сервера, маршрута, протокола и сети.\n\n## Режимы\n\n### Весь трафик (TUN)\n\nSora создаёт виртуальный сетевой интерфейс и направляет через него трафик приложений, включая TCP и UDP. Это подходящий режим для Telegram, игр и голосовой связи Discord. Правила могут отправлять отдельные сайты и программы напрямую или блокировать их. Для работы нужны права сетевой службы и сервер, поддерживающий нужный протокол.\n\n### Системный прокси\n\nSora задаёт локальный HTTP/SOCKS-прокси. Его используют приложения, которые учитывают системные настройки прокси. Программа со своим сетевым стеком может пройти напрямую; UDP и голосовые звонки обычно требуют TUN. Этот режим удобен для браузеров и приложений с поддержкой прокси.\n\n### Без сервера\n\nВ Linux Sora использует [zapret](https://github.com/bol-van/zapret): разбивает и меняет HTTP/TLS-запросы, чтобы обходить некоторые проверки DPI. Адрес IP остаётся вашим, соединение идёт к сайту напрямую. Результат зависит от провайдера и способа блокировки.\n\nТекущая интеграция использует tpws и обрабатывает TCP для HTTP и TLS. Она не обходит блокировку по IP, не пересылает UDP и не гарантирует работу Telegram с MTProto. Для голоса Discord, звонков Telegram и таких блокировок выберите VPN-сервер и TUN.\n\n## Ядра\n\n### Авто\n\nSora выбирает установленное ядро, которое поддерживает весь план подключения. Важно всё сразу: протоколы серверов, транспорт, группы, фрагментация и режим. Если выбранный вручную движок несовместим, новое подключение отклоняется до отключения текущего. Выберите «Авто» или другое ядро и примените настройки снова.\n\n### sing-box\n\nВ новых пакетах Sora используется [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), форк [sing-box](https://github.com/SagerNet/sing-box). Он добавляет клиентский XHTTP и VLESS Encryption. Sora распознаёт сборку и её возможности; стандартный sing-box без XHTTP не получает эту возможность по одному лишь названию.\n\nПоддерживаются VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard и параметры AmneziaWG 1.x/2.x, которые умеет импортировать Sora. Полные JSON-профили Xray требуют Xray. Новые параметры AWG 3.x ещё не импортируются. Управление sing-box использует защищённый паролем локальный порт; другие программы на компьютере могут заметить его наличие.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) подходит для VLESS, REALITY, XHTTP, VLESS Encryption и TLS-фрагментации. Он также запускает полные профили Xray от провайдера, сохраняя их маршрутизацию и группы. Профиль такого вида нельзя автоматически превратить в конфиг другого движка без изменения его поведения.\n\nВ поставляемом Xray удалён параметр отключения проверки TLS-сертификата (`allowInsecure`). Для таких обычных серверов «Авто» выбирает sing-box или mihomo. При ручном выборе Xray Sora сообщает о несовместимости до отключения текущего соединения. Для старого полного JSON-профиля нужен обновлённый профиль провайдера с проверяемым сертификатом или его отпечатком.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) поддерживает группы с последовательным резервом и балансировкой, а также XHTTP и AmneziaWG. Выбирайте его, если важен автоматический переход на запасной сервер. Фрагментация TLS из настроек Sora для этого ядра недоступна.\n\n## Совместимость в Sora\n\n| Возможность | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| TUN и TCP/UDP в Linux | Да | Да | Да |\n| XHTTP | Да | Да | Да |\n| VLESS Encryption | Да | Да | Да |\n| Полный профиль Xray | Нет | Да | Нет |\n| TUIC / AnyTLS | Оба | Нет | TUIC |\n| mieru | Нет | Нет | Да |\n| NaiveProxy | Да | Нет | Нет |\n| TLS-фрагментация | Да | Да | Нет |\n| AmneziaWG 1.x/2.x | Да¹ | Нет | Да |\n| Группа с резервом | Нет | Нет² | Да |\n\n¹ Профили с J1/J2/J3/Itime направляются в mihomo; эти параметры нельзя молча отбрасывать. ² Для группы полных профилей Xray запасной профиль выбирает приложение. Точная поддержка зависит от установленной сборки. Её версию можно посмотреть в «О приложении».\n\n## Стек TUN\n\nСтек обрабатывает TCP и UDP внутри виртуального интерфейса. В панели режимов у Xray и mihomo можно выбрать gVisor, System, Mixed или MIPS. Выбор сохраняется отдельно для каждого ядра. В режиме системного прокси и «Без сервера» этот выбор не используется.\n\n- **Mixed**: TCP использует системный стек, UDP обрабатывает gVisor. Это вариант по умолчанию для mihomo в Linux. В Windows Xray и mihomo по умолчанию используют MIPS.\n- **System**: использует системный стек. При проблемах с сетевыми программами попробуйте другой вариант.\n- **gVisor**: обрабатывает трафик в пользовательском пространстве.\n- **MIPS**: собственный IP-стек mihomo, доступный в поставляемой версии 1.19.32.\n\nВ Linux у Xray gVisor работает встроенно и выбран по умолчанию. System, Mixed и MIPS в Linux подключаются через TUN-движок mihomo: он передаёт TCP и UDP в Xray по защищённому локальному SOCKS. Протокол, профиль провайдера и маршрутизация остаются в Xray. Для этих трёх вариантов нужен установленный mihomo. В Windows Xray использует mihomo 1.19.32 или новее для всех четырёх стеков TUN. Протоколы и маршрутизация остаются в Xray. Правила приложений в этой связке поддерживают только прямое соединение и блокировку; на Linux они требуют встроенного gVisor Xray.\n\nСвязка запускает второй процесс. В трёх замерах в Linux без трафика она потребляла примерно на 32–36 МиБ больше физической памяти, чем встроенный TUN Xray. Это не оценка нагрузки при скачивании: расходы процессора и память зависят от соединений. Для sing-box переключатель не добавляется. Ни один вариант не гарантирует более высокую скорость во всех сетях.\n\n## Когда применяются настройки\n\nВыбор сервера автоматически переподключает соединение. Ваши изменения режима, ядра, DNS или правил применяются один раз после короткой паузы с автоматическим переподключением; фоновые обновления не переподключают VPN. Перезапуск ядра может прервать загрузки и звонки.\n\n«Интернет только через VPN» блокирует прямой выход при обрыве туннеля. Это ограничение действует на всю машину, поэтому используйте его осознанно. При явном отключении Sora снимает свои правила. Если очистка не завершилась, повторите отключение и откройте журнал.\n\n## Документация проектов\n\n- [sing-box-lx: настройки и поддержка](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.ru.md)\n- [sing-box: документация](https://sing-box.sagernet.org/)\n- [Xray: документация](https://xtls.github.io/)\n- [mihomo: документация](https://wiki.metacubex.one/)\n- [mieru](https://wiki.metacubex.one/en/config/proxies/mieru/)\n- [NaiveProxy](https://sing-box.sagernet.org/configuration/outbound/naive/)\n- [zapret: описание и ограничения](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n\n## OLCRTC\n\nOLCRTC передаёт TCP через видеозвонок в Jitsi, Яндекс Телемосте или WB Stream. Импортируйте ссылку olcrtc:// или QR-код. Протокол работает с sing-box, Xray и mihomo в режимах прокси и TUN; UDP не поддерживается. Обоим концам нужны совместимые сборки OLC2. Исходный проект архивирован.\n';

  @override
  String get probeServers => 'Пинг';

  @override
  String get extensions => 'Расширения';

  @override
  String extRatingLabel(String rating) {
    return 'Оценка $rating из 5';
  }

  @override
  String extByAuthor(String author) {
    return '$author';
  }

  @override
  String extInstallsCount(String count) {
    return 'установок: $count';
  }

  @override
  String get extInstallOne => '1 установка';

  @override
  String get extSideloadWarning => 'Самоподписанный ключ';

  @override
  String get extPermissionsWidened => 'Обновление запрашивает новые разрешения:';

  @override
  String get extInstall => 'Установить';

  @override
  String get extUpdate => 'Обновить';

  @override
  String get extCancel => 'Отмена';

  @override
  String get extConfirm => 'Подтвердить';

  @override
  String get extCatalog => 'Каталог';

  @override
  String get extInstalled => 'Установленные';

  @override
  String get extSearchHint => 'Поиск расширений';

  @override
  String get extCatAll => 'Все';

  @override
  String get extCatTools => 'Инструменты';

  @override
  String get extCatThemes => 'Темы';

  @override
  String get extCatAutomation => 'Автоматизация';

  @override
  String get extCatStats => 'Статистика';

  @override
  String get extCatNetwork => 'Сеть';

  @override
  String get extSortBy => 'Сортировка';

  @override
  String get extSortPopular => 'По популярности';

  @override
  String get extSortRating => 'По рейтингу';

  @override
  String get extSortName => 'По названию';

  @override
  String get extCatalogError => 'Не удалось загрузить каталог';

  @override
  String get extRetry => 'Повторить';

  @override
  String get extEmptySearch => 'Ничего не найдено';

  @override
  String get extEmptyInstalled => 'Пока нет установленных расширений';

  @override
  String get extInstallFromFile => 'Установить из файла';

  @override
  String get extInstallFromUrl => 'Установить по ссылке';

  @override
  String get extDownload => 'Скачать';

  @override
  String get extDownloading => 'Скачивание…';

  @override
  String get extVerifying => 'Проверка…';

  @override
  String get extInstalling => 'Установка…';

  @override
  String get extErrSignature => 'Проверка подписи не пройдена';

  @override
  String get extErrManifest => 'Манифест расширения некорректен.';

  @override
  String get extErrNetwork => 'Ошибка сети';

  @override
  String get extErrHash => 'Скачанный файл не совпадает с каталогом';

  @override
  String extErrMinApp(String version) {
    return 'Расширению нужна версия приложения $version или новее.';
  }

  @override
  String get extErrHttpsOnly => 'Разрешены только ссылки https://';

  @override
  String get extErrGeneric => 'Что-то пошло не так';

  @override
  String get extErrAuthorKeyChanged =>
      'Это обновление подписано другим ключом автора, а не тем, что у установленной версии, поэтому оно заблокировано';

  @override
  String get extDisabled => 'Отключено';

  @override
  String extToggleEnabled(String name) {
    return 'Включить $name';
  }

  @override
  String get extSearchInstalled => 'Поиск установленных';

  @override
  String get extUpdateAll => 'Обновить все';

  @override
  String extUpdatesAvailable(int count) {
    return 'Доступно обновлений: $count';
  }

  @override
  String extUpdatedCount(int count) {
    return 'Обновлено: $count';
  }

  @override
  String get extRiskNormal => 'Обычный';

  @override
  String get extRiskSensitive => 'Чувствительный';

  @override
  String get extRiskDangerous => 'Высокий риск';

  @override
  String get extPermissionsRemoved => 'Больше не запрашивается:';

  @override
  String get extUpdateFailedKept => 'Предыдущая версия осталась установлена.';

  @override
  String get extConflictsTitle => 'Конфликты расширений';

  @override
  String get extConflictTheme => 'Тема приложения';

  @override
  String get extConflictNetHooks => 'Сетевые хуки';

  @override
  String extConflictWinner(String name) {
    return 'Побеждает: $name';
  }

  @override
  String extConflictsCount(int count) {
    return 'Конфликты расширений: $count';
  }

  @override
  String get extConflictsResolve => 'Решить';

  @override
  String extVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get extPermissionsTitle => 'Разрешения';

  @override
  String get extNoPermissions => 'Особых разрешений не требуется.';

  @override
  String get extSettings => 'Настройки';

  @override
  String get extSaveSettings => 'Сохранить настройки';

  @override
  String extUpdateTo(String version) {
    return 'Обновить до $version';
  }

  @override
  String get extEnabled => 'Включено';

  @override
  String extRollbackTo(String version) {
    return 'Откатить до $version';
  }

  @override
  String extRollbackConfirm(String version) {
    return 'Откатить до версии $version?';
  }

  @override
  String get extUninstall => 'Удалить';

  @override
  String extUninstallConfirm(String name) {
    return 'Удалить «$name» и его настройки?';
  }

  @override
  String get extPanelUnavailable => 'Панель расширения недоступна.';

  @override
  String get extPermConnectionsRead => 'Видеть список активных соединений';

  @override
  String get extPermServersRead => 'Видеть список ваших серверов';

  @override
  String get extPermSettingsRead => 'Читать настройки приложения';

  @override
  String get extPermSettingsWrite => 'Изменять настройки приложения';

  @override
  String get extPermNotifications => 'Показывать уведомления';

  @override
  String get extPermTray => 'Добавлять пункты в меню трея';

  @override
  String get extPermUiPanel => 'Показывать панели в приложении';

  @override
  String get extPermThemeApply => 'Применять темы оформления';

  @override
  String get extPermRoutingRules => 'Добавлять правила маршрутизации';

  @override
  String get extPermNetHooks => 'Встраиваться в сетевой тракт';

  @override
  String get extPermNetFetch => 'Запрашивать URL из разрешённого списка';

  @override
  String get extPermBackground => 'Выполнять фоновые задачи';

  @override
  String get extPermNotYetActive => 'Отключено';

  @override
  String get extCapBackground => 'Работает в фоновом режиме';

  @override
  String get extCapNetHook => 'Обходы и сетевые хуки';

  @override
  String get extCapPanel => 'Панели';

  @override
  String get extCapRouting => 'Правила маршрутизации';

  @override
  String get extCapTheme => 'Темы';

  @override
  String get extCapWidget => 'Виджеты';

  @override
  String extCatalogCached(String date) {
    return 'Кэш каталога от $date';
  }

  @override
  String get extChangelog => 'История версий';

  @override
  String get extImageFailed => 'Не удалось загрузить изображение';

  @override
  String get extScreenshots => 'Скриншоты';

  @override
  String get extSortRelevance => 'Сначала подходящие';

  @override
  String get extBgTitle => 'Фоновая задача';

  @override
  String get extBgEnabled => 'Выполнять в фоне';

  @override
  String get extBgInterval => 'Запускать каждые';

  @override
  String extBgMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return '$_temp0';
  }

  @override
  String extBgHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String get extCapNetwork => 'Доступ к сети';

  @override
  String extCapNetworkHosts(String hosts) {
    return 'Сеть: $hosts';
  }

  @override
  String exportLogFile(String name) {
    return 'В $name';
  }

  @override
  String get diagnosticHttp => 'HTTP-диагностика';

  @override
  String get diagnosticNoData => 'Запросов пока нет';

  @override
  String get qrShareTitle => 'Поделиться QR-кодом';

  @override
  String get qrScanTitle => 'Сканировать QR-код';

  @override
  String get qrCopyLink => 'Скопировать ссылку';

  @override
  String get qrFromClipboard => 'Вставить из буфера обмена';

  @override
  String get qrNoCode => 'На изображении не найден QR-код.';

  @override
  String get qrInvalid => 'В этом QR-коде нет корректной ссылки.';

  @override
  String get qrScan => 'Сканировать QR';

  @override
  String get qrFromImage => 'Открыть изображение';

  @override
  String get connGroupByProcess => 'По процессам';

  @override
  String get connListView => 'Списком';

  @override
  String get connCopyHost => 'Скопировать хост';

  @override
  String get connAddRule => 'Добавить правило';

  @override
  String connConnectionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count соединений',
      few: '$count соединения',
      one: '$count соединение',
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
  String get dnsPresetCustom => 'Свой';

  @override
  String get dnsCheck => 'Проверить утечки';

  @override
  String get dnsChecking => 'Проверка...';

  @override
  String get dnsNoLeak => 'Утечек не найдено';

  @override
  String get dnsLeakFound => 'Обнаружена утечка';

  @override
  String get dnsLastCheck => 'Последняя проверка';

  @override
  String get dnsNeverChecked => 'Ещё не проверялось';

  @override
  String get dnsLeakCheckTunnelDns => 'Резолверы DNS туннеля';

  @override
  String get dnsLeakCheckSystemResolvers => 'Системные резолверы';

  @override
  String get dnsLeakCheckKillSwitchDns => 'Kill switch закрывает DNS';

  @override
  String get dnsLeakCheckEncryptedDns => 'Зашифрованный DNS системы';

  @override
  String get dnsLeakCheckDnsSpoof => 'Подмена ответов DNS';

  @override
  String get dnsExpected => 'Ожидалось';

  @override
  String get dnsActual => 'Обнаружено';

  @override
  String get measureSpeed => 'Замерить скорость';

  @override
  String get benchmarkStale => 'устарело';

  @override
  String get autoSelectMode => 'Автовыбор сервера';

  @override
  String get autoSelectPing => 'Самый быстрый пинг';

  @override
  String get autoSelectSpeed => 'Самая высокая скорость';

  @override
  String get autoSelectSmart => 'Умный выбор';

  @override
  String get coreWatchUnstable => 'Связь с ядром нестабильна';

  @override
  String get watchReconnect => 'Переподключить';

  @override
  String get crashRestoreTitle => 'Прошлое соединение оборвалось';

  @override
  String get restoreOnCrash => 'Восстанавливать сессию после сбоя';

  @override
  String get crashRestore => 'Восстановить';

  @override
  String get crashDismiss => 'Не сейчас';

  @override
  String get overrideTitle => 'Мои правки';

  @override
  String get overrideEdit => 'Редактировать серверы';

  @override
  String get overrideHide => 'Скрыть';

  @override
  String get overrideUnhide => 'Показать';

  @override
  String get overrideClear => 'Сбросить правки';

  @override
  String get overrideEmpty => 'Пока нет правок';

  @override
  String get overrideCustomRules => 'Свои правила';

  @override
  String get errBenchmarkUnsupported => 'Для замера скорости нужна новая версия ядра';

  @override
  String benchmarkProgress(Object done, Object total) {
    return 'Замер $done из $total…';
  }

  @override
  String get profiles => 'Сетевые профили';

  @override
  String get profilesEmpty => 'Профилей пока нет';

  @override
  String get profileAdd => 'Добавить профиль';

  @override
  String get profileName => 'Название профиля';

  @override
  String get profileSsids => 'Wi-Fi-сети (SSID)';

  @override
  String get profileGateways => 'Шлюзы';

  @override
  String get profileAsns => 'Номера AS';

  @override
  String get profileAutoApply => 'Применять автоматически';

  @override
  String get profileSnapshot => 'Запомнить текущие настройки';

  @override
  String get profileSnapshotDone => 'Текущие настройки сохранены в профиль';

  @override
  String get profileDelete => 'Удалить профиль';

  @override
  String profileDeleteConfirm(Object name) {
    return 'Удалить профиль «$name»?';
  }

  @override
  String profileApplyAsk(Object name) {
    return 'Применить профиль «$name»?';
  }

  @override
  String get profileApply => 'Применить';

  @override
  String profileApplied(Object name) {
    return 'Профиль «$name» применён';
  }

  @override
  String get profileUndo => 'Отменить';

  @override
  String get profileActive => 'Активен';

  @override
  String networkNow(Object info) {
    return 'Сейчас: $info';
  }

  @override
  String get networkUnknown => 'Нет данных о сети';

  @override
  String get profileNoTriggers => 'Нет условий профиля';

  @override
  String get chains => 'Цепочки прокси';

  @override
  String get chainsEmpty => 'Цепочек пока нет';

  @override
  String get chainAdd => 'Новая цепочка';

  @override
  String get chainName => 'Название цепочки';

  @override
  String get chainTooFew => 'Для цепочки нужны хотя бы два сервера';

  @override
  String get chainTooMany => 'В цепочке может быть не больше трёх серверов';

  @override
  String get chainEstimate => 'Примерная задержка';

  @override
  String get chainSave => 'Сохранить цепочку';

  @override
  String get chainDelete => 'Удалить цепочку';

  @override
  String chainDeleteConfirm(Object name) {
    return 'Удалить цепочку «$name»?';
  }

  @override
  String get chainUnsupported => 'Выбранное ядро не поддерживает цепочки';

  @override
  String get chainHopMissing => 'Один из серверов цепочки больше недоступен';

  @override
  String chainHop(Object n) {
    return 'Хоп $n';
  }

  @override
  String get chainEntry => 'Вход';

  @override
  String get chainExit => 'Выход';

  @override
  String get sync => 'Синхронизация устройств';

  @override
  String get syncDevices => 'Мои устройства';

  @override
  String get syncEmpty => 'Нет спаренных устройств';

  @override
  String get syncPair => 'Спарить устройство';

  @override
  String get syncShowCode => 'Показать мой код';

  @override
  String get syncScanCode => 'Сканировать код';

  @override
  String get syncRevoke => 'Отозвать';

  @override
  String syncRevokeConfirm(Object name) {
    return 'Отозвать «$name»?';
  }

  @override
  String syncLastSync(Object time) {
    return 'Последняя синхронизация: $time';
  }

  @override
  String get syncNever => 'Никогда';

  @override
  String get syncPaired => 'Устройство спарено';

  @override
  String get syncPairingTitle => 'Спарить с этим устройством';

  @override
  String get syncWaiting => 'Ожидание другого устройства…';

  @override
  String get zapretWithVpn => 'DPI-обход для прямого трафика';

  @override
  String get chainDuplicate => 'В цепочке повторяется сервер';

  @override
  String get edit => 'Изменить';

  @override
  String get remove => 'Убрать';

  @override
  String get autoSwitchOnDegrade => 'Автопереключение при деградации';

  @override
  String get tunStackMixed => 'Смешанный';

  @override
  String get tunStackSystem => 'Системный';

  @override
  String get customServerAdd => 'Добавить свой сервер';

  @override
  String get customServers => 'Мои серверы';

  @override
  String get customServerName => 'Название';

  @override
  String get customServerNameRequired => 'Название не указано';

  @override
  String get customServerAddress => 'Адрес';

  @override
  String get customServerAddressRequired => 'Адрес не указан';

  @override
  String get customServerAddressInvalid => 'Некорректный адрес';

  @override
  String get customServerPort => 'Порт';

  @override
  String get customServerPortInvalid => 'Неверный порт';

  @override
  String get customServerProtocol => 'Протокол';

  @override
  String get customServerCredentials => 'Данные для входа';

  @override
  String get customServerShowSecret => 'Показать секрет';

  @override
  String get customServerHideSecret => 'Скрыть секрет';

  @override
  String customServerDeleteConfirm(String name) {
    return 'Удалить сервер «$name»?';
  }

  @override
  String get leakTestTitle => 'Проверка утечек';

  @override
  String get leakTestRun => 'Проверить';

  @override
  String get leakTestCancel => 'Отмена';

  @override
  String leakTestProgress(int count) {
    return 'Выполнено тестов: $count';
  }

  @override
  String get leakTestAllClear => 'Утечек не найдено';

  @override
  String leakTestFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count утечек',
      few: 'Найдены $count утечки',
      one: 'Найдена $count утечка',
    );
    return '$_temp0';
  }

  @override
  String get leakTestSkipped => 'Пропущен: в этой сессии неприменим';

  @override
  String get leakTestFix => 'Исправить';

  @override
  String get leakTestCheckDirectDns => 'Прямой DNS';

  @override
  String get leakTestCheckIcmpEcho => 'ICMP echo';

  @override
  String get leakTestCheckIpv6 => 'IPv6';

  @override
  String get leakTestCheckSystemResolvers => 'Системные резолверы';

  @override
  String get leakTestCheckTunnelConnectivity => 'Связность туннеля';

  @override
  String get leakTestCheckTunnelDns => 'DNS через туннель';

  @override
  String get noticeDegraded => 'Сервер замедлился, Sora переключилась на лучший из измеренных';

  @override
  String get obfs => 'Маскировка трафика';

  @override
  String get syncCodeExpired => 'Срок действия кода истёк';

  @override
  String get syncDaemonFailed => 'Не удалось запустить службу синхронизации';

  @override
  String get syncDaemonMissing => 'Компонент sora-sync не найден';

  @override
  String get syncDaemonStarting => 'Запуск службы синхронизации…';

  @override
  String get syncErrAuth => 'Служба синхронизации отклонила токен доступа';

  @override
  String get syncErrNotFound => 'Устройство больше не спарено';

  @override
  String get syncErrPairingActive => 'Сессия спаривания уже открыта';

  @override
  String get syncErrUnreachable => 'Другое устройство не отвечает';

  @override
  String get syncError => 'Ошибка синхронизации';

  @override
  String syncExpiresIn(String duration) {
    return 'Код истечёт через $duration';
  }

  @override
  String get syncJoining => 'Спаривание с устройством…';

  @override
  String get syncNewCode => 'Новый код';

  @override
  String syncPairedWith(String name) {
    return '«$name» спарено';
  }

  @override
  String get syncRetry => 'Повторить';

  @override
  String get syncStopShowing => 'Прекратить показ';

  @override
  String get syncSyncNow => 'Синхронизировать';

  @override
  String syncSyncResult(int pulled, int pushed) {
    return 'Получено: $pulled, отправлено: $pushed';
  }

  @override
  String get syncResultTitle => 'Результат синхронизации';

  @override
  String get syncPulled => 'Получено';

  @override
  String get syncPushed => 'Отправлено';

  @override
  String get syncNoChanges => 'Нет изменений';

  @override
  String get syncDocKindSubscriptions => 'Подписки';

  @override
  String get syncDocKindSettings => 'Настройки';

  @override
  String get syncDocKindOverrides => 'Переопределения подписок';

  @override
  String get syncDocKindProfiles => 'Сетевые профили';

  @override
  String get syncDocKindChains => 'Цепочки прокси';

  @override
  String syncFrom(String name) {
    return 'с $name';
  }

  @override
  String get syncThisDevice => 'Это устройство';

  @override
  String get syncUnavailableAndroid => 'Синхронизация недоступна на Android';

  @override
  String get diagnosticPackets => 'Захват пакетов';

  @override
  String get diagnosticEvents => 'События Windows';

  @override
  String get diagnosticCapture => 'Записать 10 секунд';

  @override
  String get diagnosticRequiresTun => 'Для захвата пакетов нужно активное TUN-подключение Sora.';

  @override
  String get diagnosticUnavailable => 'Эта диагностика недоступна на данной платформе.';

  @override
  String get extErrRevoked => 'Команда Sora отозвала эту версию расширения: она небезопасна или сломана.';

  @override
  String get extErrRevocationsExpired => 'Установка заблокирована до обновления списка отозванных расширений.';

  @override
  String extRevokedDisabled(String names) {
    return 'Выключены отозванные расширения: $names';
  }

  @override
  String get customServerWgPrivateKey => 'Приватный ключ';

  @override
  String get customServerWgAddresses => 'Адреса интерфейса';

  @override
  String get customServerWgPeerKey => 'Публичный ключ сервера';

  @override
  String get customServerWgPresharedKey => 'Общий ключ';

  @override
  String get customServerWgAllowedIps => 'Разрешённые IP';

  @override
  String get customServerWgKeepalive => 'Keepalive, секунд';

  @override
  String get customServerWgKeyInvalid => 'Неверный ключ WireGuard';

  @override
  String get customServerWgCidrInvalid => 'Неверный префикс CIDR';

  @override
  String get customServerWgKeepaliveInvalid => 'Неверный интервал keepalive';

  @override
  String get strictKillSwitch => 'Строгий kill switch';

  @override
  String get strictKillSwitchWarning => 'Блокировать трафик вне VPN после выхода?';

  @override
  String get extWorkerFailed => 'Фоновая задача расширения завершилась с ошибкой';

  @override
  String get extAssetRejected => 'В файле расширения нечитаемые цвета или неверные правила';

  @override
  String get extVerifiedSora => 'Проверено Sora';

  @override
  String extReceivedBytes(String count) {
    return '$count Б';
  }

  @override
  String get extOpen => 'Открыть';

  @override
  String get customServerOwn => 'Свой сервер';

  @override
  String get customServerPaste => 'Вставить ссылку';

  @override
  String get customServerUser => 'Пользователь';

  @override
  String get customServerPassword => 'Пароль';

  @override
  String get customServerSecretRequired => 'Значение не указано';

  @override
  String get customServerLinkInvalid => 'Неверная ссылка на сервер';

  @override
  String get errInternal => 'Внутренняя ошибка Sora';

  @override
  String get errTls => 'Сертификат сервера отклонён';

  @override
  String get errFileAccess => 'Нет доступа к файлу';

  @override
  String get errDataLimit => 'Слишком много данных';

  @override
  String get errCredentials => 'Сохранённые данные доступа потеряны';

  @override
  String subscriptionStale(String time) {
    return 'Обновлено: $time';
  }

  @override
  String get subscriptionNeverUpdated => 'Ещё не обновлялась';

  @override
  String errHttpStatus(int status) {
    String _temp0 = intl.Intl.pluralLogic(
      status,
      locale: localeName,
      other: 'Сервер вернул код HTTP $status',
      zero: 'Сервер отклонил запрос',
    );
    return '$_temp0';
  }

  @override
  String get errInvalidServer => 'Настройки сервера неполные или не поддерживаются';

  @override
  String get errServerIds => 'У двух серверов одинаковый идентификатор';

  @override
  String get errRoutingGroup => 'Маршрут ссылается на удалённые серверы или повреждённую группу';

  @override
  String get errConnections => 'Список подключений недоступен';

  @override
  String get errLogs => 'Эта служба не ведёт журнал';

  @override
  String get errDiagnostics => 'Не удалось собрать диагностику';

  @override
  String get errMissingItem => 'Запрошенный элемент больше не существует';

  @override
  String get errInvalidRequest => 'В запросе неверные значения';

  @override
  String get errProxyLogin => 'Системный прокси не поддерживает этот вход';

  @override
  String get errLogFilter => 'Неверный фильтр журнала';

  @override
  String get errSubRedirect => 'Сервер перенаправил на небезопасный адрес';

  @override
  String get errProxySetup => 'Не удалось настроить системный прокси';

  @override
  String get notificationsToday => 'Сегодня';

  @override
  String get notificationsYesterday => 'Вчера';

  @override
  String get notificationsMarkRead => 'Прочитать все';

  @override
  String get notificationsUnread => 'Не прочитано';

  @override
  String get desktopNotifications => 'Системные уведомления';

  @override
  String notificationRepeat(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'x$countString';
  }

  @override
  String get errSubInterval => 'Недопустимый интервал обновления подписки';

  @override
  String get errRule => 'В правиле маршрутизации ошибка';

  @override
  String get errDns => 'Некорректные настройки DNS';

  @override
  String get errEndpoint => 'Некорректный адрес сервера для проверки';

  @override
  String get errCancelled => 'Запрос отменён';

  @override
  String get customServerOptions => 'Параметры подключения';

  @override
  String get customServerTransport => 'Транспорт';

  @override
  String get customServerSecurity => 'Защита';

  @override
  String get customServerCipher => 'Шифр';

  @override
  String get customServerWgInterface => 'Интерфейс';

  @override
  String get customServerWgPeer => 'Пир';

  @override
  String extAvailableOn(String platforms) {
    return 'Доступно на: $platforms.';
  }

  @override
  String get winwsScopeWarning => 'Изменить TCP-трафик всех приложений?';

  @override
  String get winwsRequirements => 'Этот режим VPN недоступен';
}
