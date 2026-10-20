# QR-коды в VPN-приложениях: лучшие практики

Дата: 2026-10-19. Тема ресёрча #12. 6 поисковых запросов, источники 2025–2026.

## 1. Что нашёл

### Как используют QR конкуренты
- **WireGuard (офиц. клиенты)**: главный сценарий — конфиг телефона: `qrencode -t ansiutf8 < client.conf` на сервере → в приложении «Scan from QR code». Конфиг содержит приватный ключ → трактуется как секрет. Не сохранять скриншоты, показывать только в доверенном окружении, чистить терминал после сканирования.
  — https://tutorials.technology/tutorials/wireguard-vpn-linux-setup-2026.html
  — https://www.vpnsmith.com/en/blog/wireguard-android-setup
- **v2rayNG / v2rayN**: импорт через `+` → QR/буфер/файл; v2rayN-десктоп — экспорт QR на сервер (правый клик → «Show QR code», ZXing, EC level **M**, 500×500 px, UTF-8, DisableECI). Поддерживаются URI всех протоколов (vmess://, vless://, trojan://, ss://, hy2://...).
  — https://deepwiki.com/free-nodes/v2rayfree/7.1-v2rayng-(android)
- **AmneziaVPN / AmneziaWG**: десктоп — Share → QR или файл; мобильный — «Scan QR code» импортирует всё, включая параметры обфускации AmneziaWG. Серверные скрипты генерируют тройку `.conf + .png + .vpnuri`. Реципиенту не нужен SSH-доступ к серверу.
  — https://valebyte.com/en/blog/amneziavpn-on-vps-bypassing-wireguard-and-openvpn-blocks/
  — https://dev.to/bivlked/your-wireguard-got-blocked-deploy-amneziawg-20-in-5-minutes-2k7h
- **Streisand**: генератор сервера выдаёт QR для Shadowsocks/WireGuard/Orbot — для «приклеить на стену» в презентациях (офлайн-дистрибуция ключей).
  — https://forum.cloudron.io/topic/1267/streisandeffect-security-solution/4
- **Hiddify**: импорт manual/QR/clipboard/deep-link; панель хостера — QR + «скопировать ссылку» + «открыть локально» (три пути импорта рядом).
  — https://hostkey.com/blog/58-hiddify-personal-vpn-server/
  — https://deepwiki.com/hiddify/hiddify-app
- **Shadowrocket**: кнопка-сканер на главном экране; один QR может нести **один узел или целую подписку**. Провайдеры привязывают sub-URL к аккаунту и лимитируют обновления — секрет хранить в менеджере паролей, не слать в чаты.
  — https://www.rapidseedbox.com/blog/shadowrocket-ultimate-guide
  — https://www.shadowrocket6.com/en/blog/articles/airport-subscription-buying-guide-shadowrocket-2026.html
- **Tailscale**: QR используется не для конфигов, а для **login URL** (`tailscale up --qr` показывает QR ссылки аутентификации) — паттерн «сканируй, чтобы залогинить устройство».
  — https://computingforgeeks.com/how-to-install-and-configure-tailscale-client-on-opnsense/

### Технические best practices (2025–2026 гайды)
- **EC level**: L (~7%) — чистый экран; M (~15%) — дефолт для большинства случаев; Q (~25%) — износ; H (~30%) — только если есть логотип по центру или ожидаются повреждения. H «на всякий случай» вреден: код становится плотнее и хуже сканируется с расстояния. v2rayN использует M — верный выбор.
  — https://freeqr.com/blog/qr-code-error-correction
  — http://dev.to/thejayedge/qr-code-error-correction-levels-l-vs-m-vs-q-vs-h-and-when-the-tradeoff-is-actually-worth-it-4h6d
- **Quiet zone** ≥ 4 модулей; тёмный код на светлом фоне (инверсия ломается на части сканеров); не искажать пропорции; минимальный размер на экране — код должен занимать ≥ 2–3 см и рендериться без сглаживания (crisp pixels).
  — http://dev.to/pulkitgovrani/qr-code-best-practices-size-contrast-error-correction-and-testing-21e1
  — https://qrcody.net/qr-code-scanability-best-practices.html
- **Размер payload**: чем короче строка, тем разреженнее матрица и надёжнее скан. Для URI VLESS/VMess с длинными SNI/path — предпочитать compact-представление (без remark, trim лишних query-параметров). Длинные (>~500 символов) конфиги на экране телефона сканируются хуже; тогда лучше deep-link/файл.
  — https://bestqr.co/blog/qr-code-error-correction-levels.html
- **Безопасность экрана**: QR с ключами = секрет. Практика WireGuard-сообщества: предупреждение на экране («не фотографируйте, не показывайте посторонним»), автоскрытие через таймер, не сохранять в галерею/скриншоты, запрет скриншотов на экране сканирования/показа (FLAG_SECURE на Android — для sora desktop нет аналога, но предупреждение нужно).
- **Deep-link + QR комбо**: Hiddify/Amnezia держат рядом три действия — «показать QR», «скопировать ссылку», «открыть в приложении» (deep-link sora://). Один и тот же payload во всех трёх — пользователь выбирает канал под ситуацию.
- **Что кодировать**: всегда URI (`vless://…`, `sora://import?url=…`), а не JSON/сырой конфиг. URI уже есть в пайплайне импорта sora — ноль нового парсинга. Для пачки серверов — кодировать subscription URL (как Shadowrocket), а не N отдельных QR.

## 2. Текущее состояние sora (read-only осмотр)
- `app/lib/src/ui/qr.dart` (F1, wave 1): `QrShareSheet` (qr_flutter, `QrVersions.auto`, белая quiet zone, `qrWarning`, кнопка «скопировать ссылку») + `QrScanScreen` (mobile_scanner + вставка из буфера, роутинг в существующий import flow). База есть.
- sora-legacy/v2rayN: `QRCodeHelper.cs` — ZXing, EC=M, 500×500, UTF-8/DisableECI. Эталон для десктопа, менять нечего.

## 3. Что sora должен перенять

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| 1 | **Фиксировать EC=M, запретить H без логотипа.** Сейчас `QrVersions.auto` ок, но EC не задан явно (дефолт qr_flutter — L). Для экрана без повреждений M — оптимум: v2rayN и гайды 2025–2026 сходятся на M. | Более надёжное сканирование с дешёвых камер / при бликах, без роста плотности. | medium |
| 2 | **Таймер автоскрытия + предупреждение на экране шаринга.** Показывать QR ≤60 сек, затем блюр с кнопкой «показать снова». Текст: «код = ключи, не фотографируйте». Паттерн WireGuard-сообщества; у sora уже есть `qrWarning`, но нет автоскрытия. | Главный риск QR — фото экрана посторонним / скриншот в мессенджер. Дешёвая защита. | high |
| 3 | **Трио «QR / скопировать ссылку / открыть в sora» в одном шите.** Как у Hiddify: один payload, три канала. Сейчас в `QrShareSheet` есть QR + копирование; добавить deep-link кнопку `sora://import?...` (схемы уже поддержаны) для шаринга на то же устройство. | Покрывает все ситуации шаринга одним UI, без нового парсинга. | medium |
| 4 | **Шаринг подписки одним QR (sub-URL), а не по одному серверу.** Как Shadowrocket: один QR = `https://…/sub` → импорт десятков узлов. На сервере sora уже есть подписки; на клиенте добавить «поделиться подпиской». | Главный сценарий «дай другу VPN»: 1 скан вместо N. | high |
| 5 | **Compact-URI перед кодированием.** Обрезать remark до разумного, убирать пустые query-параметры; если payload > ~700 символов — предупреждать и предлагать файл/deep-link вместо QR. | Плотные матрицы — топ-1 причина «не сканируется» по гайдам 2026. | medium |
| 6 | **Сканер: автоопределение типа payload.** URI узла → импорт узла; sub-URL / base64-пачка → импорт подписки; `sora://` → внутренний роут. Сейчас скан идёт «в стандартный import flow» — проверить, что он различает эти три случая, как Shadowrocket. | Убирает двусмысленность «что за QR мне дали». | medium |
| 7 | **QR для pairing при E2E-синхронизации (F9).** Паттерн Tailscale `--qr`: вместо ручного ввода кода — QR с одноразовым Noise-handshake токеном на экране одного устройства → скан вторым. | F9 уже планирует Noise_XX+mDNS+QR; зафиксировать QR как primary UX, а не fallback. | low (зависит от F9) |
| 8 | **На десктопе: экспорт QR в PNG + копирование в буфер обмена как изображение.** v2rayN показывает QR в окне; удобно «перетащить в мессенджер». Добавить кнопку «сохранить PNG». | Мелочь, но стандартный expectation десктопных клиентов. | low |
| 9 | **Не изобретать свой формат QR.** Только стандартные URI-схемы (vless://, ss://, wireguard .conf-текст и т.п.) — как WireGuard/Amnezia. Закрытый формат ломает кросс-клиентский импорт и доверие. | Совместимость с экосистемой; sora и так на URI — просто не отходить. | low (подтверждение принципа) |

## 4. Чего НЕ делать
- EC=H «для надёжности» без логотипа — плотнее матрица, хуже скан (антипаттерн из гайдов).
- Логотип по центру QR с ключами — бессмысленный риск + требует H.
- Кодирование сырого JSON конфига вместо URI — длиннее, несовместимо с другими клиентами.
- QR со статическим долгоживущим токеном без expiry для pairing (см. п.7) — одноразовость обязательна.
