# Web-research #25: AmneziaWG vs WireGuard — замеры и практика

Дата: 2026-10-19. Источники: официальная документация Amnezia (docs.amnezia.org, свежая, покрывает 3.1), amnezia.org/blog (релизные заметки 2.0/3.0/3.1), GL.iNet docs, dev.to-гайды по самосборке (авг–сен 2026), vpnsmith.com Anti-DPI 2026, deepwiki по amneziawg-go/kernel-module, wg-easy docs, firewalla docs. Веб-исследование по конкурентам: `../competitor-analysis.md`.

## 1. Что даёт AmneziaWG поверх WireGuard

Криптография WireGuard (Curve25519, ChaCha20-Poly1305, Noise IK) не тронута; меняется только транспортный слой, чтобы убрать узнаваемую DPI-сигнатуру (фиксированные 32-битные типы сообщений 1–4 и инвариантные размеры пакетов: init 148, response 92, cookie 64). С нулевыми параметрами обфускации AWG ведёт себя как обычный WireGuard (обратная совместимость на уровне конфига). Клиент и сервер обязаны совпадать по параметрам — иначе туннель не встанет. AWG не говорит со стоковым WireGuard, когда обфускация включена.

### 1.1. Параметры (официальная справка: https://docs.amnezia.org/documentation/amnezia-wg/)

| Параметр | Смысл | Диапазоны / автогенерация |
|---|---|---|
| `Jc` | Количество junk-пакетов перед handshake | 1–128; автогенерация 4–12 |
| `Jmin`/`Jmax` | Мин./макс. размер junk-пакетов (байт) | 0 ≤ Jmin < Jmax < 65535; автогенерация < 1280 |
| `S1`–`S4` | Случайные префиксы к Init / Response / Cookie / Data пакетам. Размеры на проводе: `len(init)=148+S1`, `len(resp)=92+S2`, `len(cookie)=64+S3`, `len(data)=payload+S4` | S1 ≤ 1132, S2 ≤ 1188 (S1+56 ≠ S2), S3 ≤ 1216, S4 ≤ 32; автогенерация S1–S3: 15–150, S4: 0–32 |
| `H1`–`H4` | Динамические заголовки типов пакетов (замена фиксированных 1–4). В 1.x — фиксированные значения, в 2.0+ — **диапазоны**: каждый пакет берёт случайное значение из диапазона; диапазоны типов не должны пересекаться | `range<uint32>` (`a-b` или `a`); ≥ 5; H1=1/H2=2/H3=3/H4=4 = «выключено» |
| `I1`–`I5` | Сигнатурные пакеты перед handshake (CPS — Custom Protocol Signature): произвольные UDP-пакеты, описанные тегами `<b hex>` (статические байты, напр. слепок QUIC Initial), `<t>` (unix timestamp), `<r N>` (случайные байты ≤1000), `<rc N>` (случайные буквы), `<rd N>` (случайные цифры). Посылаются каждые 120 с перед handshake, в порядке I1→I5 | произвольный hex-blob; автогенерации нет |
| `J1`–`J3`, `Itime` | Кастомные response-пакеты и тайминг init-пакетов (расширенные механизмы) | — |

3.1 добавляет (https://amnezia.org/blog/amneziawg-3-1-is-here, https://docs.amnezia.org/documentation/amnezia-wg/):
- `HeaderProtectionKey` (32-байтный ключ) — шифрование ChaCha20 низкоэнтропийных полей заголовков; **требует S1–S4 ≥ 12**;
- `ContentPaddingAddition` (range uint16) — случайный паддинг к transport payload;
- `RekeyAfterTime` / `RekeyTimeout` / `RejectAfterTime` / `KeepaliveTimeout` / `MaxHandshakeAttempts` — рандомизация таймингов сервисных событий;
- `RandomTrailers` (on/off), `DisableCookies` (on/off) — Cookie Reply используется при активном пробинге как дополнительный фингерпринт.

### 1.2. Эволюция версий (важно для совместимости)
- **1.0/1.5** (2024): фиксированные H1–H4, шум + паддинг. Обходится научившимся DPI запоминать новые статические значения.
- **2.0** (кон. 2025): H1–H4 — диапазоны, S3/S4 — новые, I1–I5 (CPS) — полноценно. Каждый сервер — «свой диалект», универсальной DPI-сигнатуры нет. Мимикрия под QUIC/DNS/SIP.
- **3.0/3.1** (2026): ответ на AI/поведенческий анализ трафика (размеры, межпакетные интервалы, keepalive-паттерны, статистика потока). Шифрование структуры заголовков, рандомизация таймингов, менее узнаваемые cookie. Мотивация — лето 2026: цензоры перешли от анализа отдельных пакетов к анализу соединения целиком + IP/подсети.
- Ограничение, честно озвученное самими авторами и независимыми разборами: против Китая (GFW 4.0, кон. 2025) ванильный AWG уже часто детектится; против России/Беларуси/Ирана/Турции — очень хорош. Не защищает от IP-блоклистов, запрета UDP и allow-list фаерволов.

### 1.3. Замеры скорости (все источники сходятся)
- Крипто-оверхед идентичен WG (~4%); обфускация добавляет **+3–7%** (паддинг/junk только на setup). Итого **<12%** против ~25–28% у OpenVPN.
- Реальный замер на незацензуренной сети: WireGuard 95 Мбит/с vs AmneziaWG 92 Мбит/с — разница ~3%, незаметна.
- «65% overhead», гуляющий по сети, — артефакт **userspace Go-реализации** (amneziawg-go); kernel-модуль идёт почти на скорости WG.
- Батарея: +1 п.п. за 4 ч стриминга vs WG (19% vs 18%), OpenVPN ~25%.
- В зацензуренной сети сравнение «92 Мбит/с vs 0 Мбит/с» — скорость не имеет значения, если WG заблокирован.
- Оговорка: в userspace-Go (а именно так AWG будет жить в sora-core на Windows/в sing-box-конвейере) оверхед выше, чем у kernel-модуля; для десктопа это приемлемо, для слабых роутеров — нет.

### 1.4. Лучшие практики настройки (сводно из docs, amneziawg-go README, гайдов)
1. **Jmax < MTU** — фрагментация junk-пакетов выглядит подозрительно; типично держат Jmax ≤ 1280.
2. **Диапазоны H1–H4 не пересекаются** между типами пакетов (иначе пиры не различат типы); значения ≥ 5; держать подальше от маленьких чисел.
3. **S1+56 ≠ S2** (требование протокола, иначе коллизия размеров init/response).
4. **HeaderProtectionKey ⇒ S1–S4 ≥ 12** (3.1).
5. **I1 — осмысленная мимикрия**: лучший эффект — слепок реального протокола (QUIC Initial с allowlisted SNI помогает даже при AS-уровневых блокировках, напр. Hetzner AS24940 из РФ). Пустые/случайные I-пакеты дают только энтропию, а не мимикрию.
6. **Параметры клиента = параметрам сервера**, бит-в-бит; расхождение = туннель не встанет. Отсюда — импорт конфига целиком (conf/QR/`vpn://` URI), а не ручной ввод.
7. Junk-пакеты идут **перед каждым handshake** (rekey каждые ~120 с), а не один раз за сессию — постоянный небольшой фоновый оверхед.
8. DSCP у junk-пакетов рандомизируется самим протоколом.

### 1.5. Поддержка в клиентах (ландшафт 2025–2026)
- **Официальные**: AmneziaVPN (все платформы), нативные клиенты AmneziaWG (Windows/macOS/Linux/Android/iOS).
- **Сторонние**: WG Tunnel (Android, FOSS) — полная поддержка AWG 2.0–3.1, пресеты мимикрии QUIC/DNS/SIP в UI + быстрые действия «показать/скрыть Amnezia-поля»; wg-easy, amnezia-wg-easy, Firewalla (бета, без I1–I5 на сервере), GL.iNet-роутеры, OpenWrt-пакеты.
- **sing-box upstream — НЕТ** нативной поддержки AWG; есть форк **amnezia-box** (sing-box + `protocol/awg` на `amneziawg-go`, с патчами под AWG 2.0: тег `<c>`, S4-keepalive fix; сборка с тегом `with_awg`). Актуален (1.13.x, 2026).
- **mihomo/clash** — нативной поддержки AWG нет в апстриме (sora рендерит AWG-параметры в mihomo-конфиг — проверить, какой именно форк/сборка mihomo их принимает; это место для верификации).
- **v2rayNG / NekoBox / Streisand / Hiddify / Shadowrocket** — AWG нет (таблица в competitor-analysis подтверждает: только AmneziaVPN и sora из рассмотренных).
- URI-формат: `vpn://` (Amnezia), `.conf` + QR; единого открытого URI-стандарта типа `wireguard://` для AWG-параметров нет — де-факто стандарт = ini-conf.

## 2. Что у sora уже есть (read-only ревизия)

- `core/engine/plan.go`: структура `AmneziaWG` — Jc/Jmin/Jmax, S1–S4, H1–H4 (строки, диапазоны поддерживаются), I1–I5, **J1–J3, Itime** (редкость — даже Firewalla их не поддерживает).
- `core/control/plan.go`: парсинг всех ключей из конфигов/URI (`amneziaKeys`).
- `core/engine/validate.go`: валидация диапазонов (Jc 0–128, jmin<jmax, H1–H4 ≥ 5 и различны и т.д.).
- `core/engine/singbox/render.go`: рендер в sing-box outbound `wireguard` (+ AWG-поля); J1/J2/J3/Itime → явная ошибка «require another engine»; MTU для AWG занижается до 1280.
- `core/engine/mihomo/proxy.go`: рендер AWG-полей в mihomo-конфиг.
- UI (Flutter): прямых упоминаний AmneziaWG вне l10n не найдено — проверить, есть ли экран редактирования AWG-параметров; судя по всему, параметры сейчас задаются только через импорт конфига/подписки.

## 3. Что sora должен перенять и почему

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| 1 | **Поддержать параметры AWG 3.1** в `plan.go`/валидации/рендере: `HeaderProtectionKey`, `ContentPaddingAddition`, `RekeyAfterTime`, `RekeyTimeout`, `RejectAfterTime`, `KeepaliveTimeout`, `MaxHandshakeAttempts`, `RandomTrailers`, `DisableCookies` (+ правило «S1–S4 ≥ 12 при HeaderProtectionKey») | 3.1 — актуальный ответ на AI-поведенческий DPI (лето 2026); без них sora застрянет на уровне 2.0, который цензоры уже учатся отличать по статистике потока | high |
| 2 | **Пресеты мимикрии I1 (QUIC/DNS/SIP) в UI** — как у WG Tunnel: готовые CPS-сигнатуры + кнопка «сгенерировать случайный набор» | I1 — самый сильный механизм 2.0+, но ручной CPS никто не напишет; пресет «QUIC Initial с allowlisted SNI» — документированный обход AS-уровневых блокировок. Это киллер-фича против AmneziaVPN | high |
| 3 | **Экран редактирования AWG-параметров** (Jc/Jmin/Jmax, S1–S4, H1–H4 диапазоны, I1–I5, переключатели 3.1) с inline-валидацией и подсказками (Jmax < MTU, S1+56≠S2, диапазоны H не пересекаются) | Сейчас параметры, похоже, только импортируются; AmneziaVPN и WG Tunnel дают пользователю крутилки — паритет UX, меньше «магии» | medium |
| 4 | **Кнопка «сгенерировать параметры»** (как автогенерация Amnezia: Jc 4–12, S1–S3 15–150, H-диапазоны непересекающиеся) + **проверка «клиент == сервер»** при ручном редактировании | Уникальный набор на сервер — суть анти-DPI 2.0; ручной ввод без генератора даёт слабые/одинаковые у всех наборы | medium |
| 5 | **Определиться с движком AWG**: sing-box upstream AWG не умеет — либо вендорить `amneziawg-go` напрямую (как amnezia-box, с их патчами `<c>`/S4-keepalive), либо явно задокументировать/проверять, какая сборка sing-box/mihomo принимает рендер. Сейчас `render.go` пишет AWG-поля в `type: wireguard` — убедиться, что целевой движок их реально понимает, иначе это молчаливый no-op | Риск «фича есть в UI/плане, но на проводе — обычный WG» — худший исход для anti-DPI позиционирования | high |
| 6 | **Замерять и показывать оверхед AWG** в экране диагностики/speedtest: сравнить WG vs AWG на том же сервере (userspace-Go даёт больший оверхед, чем kernel) | Честные цифры в UI — доверие + материал для позиционирования «почти как WG»; заодно ловит регрессии обфускации | low |
| 7 | **Импорт `vpn://` URI и QR для AWG-конфигов** (у sora deep-links уже есть: sora://, happ://, v2rayn://, clash://, hiddify://, sing-box:// — добавить vpn://) | Де-факто стандарт распространения AWG-конфигов (AmneziaVPN, wg-easy); без него не забрать конфиг из чужой экосистемы | medium |
| 8 | **В доку/FAQ**: «AWG не работает в Китае (GFW 4.0), для Китая — VLESS/XHTTP/REALITY; AWG — для RU/BY/IR/TR» + «J1/J2/J3/Itime поддерживаются не всеми движками» | Честное позиционирование сильнее, чем обещание «обходит всё»; снижает саппорт-нагрузку | low |

## 4. Ключевые ссылки

- Официальная документация по протоколу и всем параметрам (1.5/2.0/3.1): https://docs.amnezia.org/documentation/amnezia-wg/
- AmneziaWG 3.1 — что нового, AI-DPI: https://amnezia.org/blog/amneziawg-3-1-is-here
- AmneziaWG 2.0 — анонс: https://amnezia.org/blog/amneziawg-2-0-available-for-self-hosted
- AmneziaWG 3.0 и поведенческий анализ (postgoo): https://postgoo.com/posts/6a8f88bd98d49597ecb8c2cc?type=article
- Параметры обфускации, таблица (GL.iNet): https://docs.gl-inet.com/router/en/4/faq/amnezia_obfuscation_parameters/
- Практика самосборки 2.0 + замеры (~3%): https://dev.to/bivlked/amneziawg-20-self-host-an-obfuscated-wireguard-vpn-that-bypasses-dpi-4692
- Практика: Jc 4–12, S1–S4 ≥ 12 в 3.1, Jmax < MTU: https://dev.to/selfhostpilot/wireguard-split-tunneling-on-blocked-networks-udp2raw-144p
- Anti-DPI 2026, полевые данные (RU — очень хорошо, CN — детектируется): https://www.vpnsmith.com/en/blog/anti-dpi-vpn-bypass-2026
- AWG vs WG разбор: https://www.snapvpn.net/blog/amneziawg-vs-wireguard
- amneziawg-go: обфускация, теги CPS, Jmax < MTU: https://deepwiki.com/amnezia-vpn/amneziawg-go/5.2-advanced-security-features
- amnezia-box (sing-box форк с AWG): https://deepwiki.com/hoaxisr/amnezia-box/4.3-wireguard-and-amneziawg-outbounds
- WG Tunnel: пресеты мимикрии QUIC/DNS/SIP в UI: https://deepwiki.com/wgtunnel/android/7.6-amneziawg-support
- Firewalla: AWG-сервер (бета, без I1–I5): https://help.firewalla.com/hc/en-us/articles/49508731395091-AmneziaWG-VPN-Server-Configuration
- wg-easy: совместимые клиенты: https://wg-easy.github.io/wg-easy/v15.2/advanced/config/amnezia/

## 5. Вывод одной строкой

AmneziaWG — это WireGuard со скоростью ~97% от оригинала и без его DPI-сигнатуры; гонка вооружений ушла в 3.1 (поведенческий/AI-DPI). У sora уже редкое преимущество — AWG есть, а у v2rayNG/NekoBox/Streisand/Hiddify/Shadowrocket его нет; чтобы превратить это в отрыв, нужны параметры 3.1, пресеты мимикрии I1 в UI и честная проверка, что движок реально применяет обфускацию, а не молча игнорирует поля.
