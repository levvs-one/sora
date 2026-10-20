# Постквантум в VPN: ML-KEM гибриды

Дата: 2026-10-19. 7 веб-запросов, приоритет источникам 2025–2026. Репозитории sora/sora-legacy — только чтение.

## 1. Что реально внедрено в 2025–2026

**Консенсус индустрии: гибрид X25519 + ML-KEM (FIPS 203, финал авг 2024).** Никто не заменяет классику полностью — PQ-слой добавляется поверх, чтобы слом одного алгоритма не ронял защиту. Цель — защита от «harvest now, decrypt later» (записанный сегодня трафик вскроют будущим квантовым компьютером через алгоритм Шора).

### VPN-провайдеры

| Кто | Что | Статус |
|---|---|---|
| **Mullvad** | Quantum-resistant tunnels: Classic McEliece + ML-KEM → PSK-слот WireGuard. Схема: короткий WG-туннель к эфемерному пиру → внутри него PQ-обмен секретом → переподключение с выведенным PSK. Рекей WG идёт штатно, PSK подмешивается. | **Default ON на десктопе с 09.01.2025** (релиз 2025.2); iOS/Android поддерживается, дефолт позже. [mullvad.net](https://mullvad.net/zh-hans/blog/2025/1/9/quantum-resistant-tunnels-are-now-the-default-on-desktop) |
| **ExpressVPN** | Lightway: ML-KEM-**1024** (NIST Level 5, единственный провайдер с раскрытым уровнем) по умолчанию с янв 2025. Авг 2025: **opt-in PQ-WireGuard** — гибридный ML-KEM через PSK-слот WireGuard, свежий ключ на сессию через ML-KEM-гибридный TLS 1.3 канал, **без изменения протокола WireGuard** + опубликованный технический whitepaper как roadmap для индустрии. [wilsonsmedia.com](https://www.wilsonsmedia.com/expressvpn-adds-wireguard-to-support-industry-transition-to-post-quantum-vpns/) |
| **NordVPN** | NordLynx (WireGuard) + ML-KEM; старт Linux сен 2024, все платформы к нач. 2025; включается тумблером; ротация ключей каждые 90 сек (чаще штатных 120 сек WG). [symlexvpn.org](https://symlexvpn.org/quantum-safe-vpn-post-quantum-cryptography/) |
| **Surfshark** | Янв 2026: PQ для WireGuard (обмен ключами ML-KEM). Апр 2026: собственный протокол Dausos с PQ «из коробки». **Окт 2026: добавлен ML-DSA для аутентификации** → «первый полный PQ-WireGuard» (обмен + аутентификация). Пока macOS/iOS. [surfshark.com](https://surfshark.com/blog/post-quantum-secure-wireguard) |
| **Windscribe** | PSK-слот WireGuard заполняется через X25519MLKEM768-гибрид поверх TLS 1.3, ключ ротируется при каждом логине; live на десктопе/Android/iOS. [encapsulated.network](https://encapsulated.network/post-quantum-vpn-encryption/) |
| **NymVPN / AmneziaWG** | Lewes Protocol (PQ key exchange) стал дефолтом на всех Fast Mode-соединениях в июне 2026. **Релевантно sora напрямую: AmneziaWG уже в списке протоколов.** [encapsulated.network](https://encapsulated.network/post-quantum-vpn-encryption/) |
| **ProtonVPN** | PQ нет; весна/лето 2026 — новый клиентский WG-кодбейз (beta Android/Windows) как фундамент под будущий PQ. |

### Мессенджеры/стек (контекст паттерна)

- **Signal**: PQXDH (X25519 + Kyber) с сен 2023; **май 2026 — дефолт для всех новых диалогов**; окт 2025 анонсирован SPQR (Sparse Post-Quantum Ratchet, «тройной храповик», гибрид ML-KEM-768 + классика), постепенный роллаут. [locked.news](https://www.locked.news/articles/signal-post-quantum-default.html), [qntonsol.com](https://www.qntonsol.com/learn/pq-messaging-and-ssh-imessage-signal-openssh.html)
- **iMessage PQ3** — с фев 2024. **OpenSSH 10.0** (апр 2025) — `mlkem768x25519-sha256` дефолт; 10.1 предупреждает о не-PQ соединении.
- **Браузеры**: Chrome/Edge 131+, Firefox 132+ (145+ Android), Safari 26 — X25519MLKEM768 по умолчанию. Cloudflare: >50% веб-запросов с PQ key agreement к сер. 2026.

### Статус WireGuard upstream

**PQ в самом протоколе WireGuard нет и не будет**: Джейсон Доненфельд сознательно отказался от crypto-agility (аргумент — опыт SSL/TLS-уязвимостей). Официальный рецепт индустрии — отдельный PQ-обмен **вне** WG-хендшейка → результат в существующий PSK-слот. Пакетная структура и ChaCha20-Poly1305 не меняются, оверхед только в хендшейке (несколько КБ), на скорость потока влияния нет. [postquantum.com](https://postquantum.com/post-quantum/crypto-agility-program/), [shattered.io](https://shattered.io/post-quantum-wireguard-vs-classical-wireguard-2026/)

**Rosenpass** — эталонный опенсорс-вариант этого паттерна (Rust, Sovereign Tech Fund): Classic McEliece 460896 (статические ключи) + ML-KEM-512 (эфемерный обмен) → PSK-слот. Отдельный процесс рядом с WireGuard, откат тривиален. NetBird интегрирует (beta, «первый quantum-resistant mesh VPN»). [github.com/rosenpass/rosenpass](https://github.com/rosenpass/rosenpass) (URL из текста shattered.io, не из verbatim-списка — проверить перед публикацией)

### Что уже умеет Xray-core (движок sora!)

- **REALITY**: детект и предпочтение гибрида **X25519MLKEM768** (`utls.X25519MLKEM768` в `transport/internet/reality/reality.go`), верификация подписей **ML-DSA-65** через `cloudflare/circl`. [deepwiki Xray-core REALITY](https://deepwiki.com/XTLS/Xray-core/4.1-vless-protocol)
- **VLESS Encryption**: `mlkem768x25519plus` — гибридный PQ-слой (режимы native/xorpub/random, 1rtt/0rtt), клиентская сторона работает против серверов с поддержкой (Remnawave-панели и свежий Xray). Формат: `mlkem768x25519plus.<mode>.<rtt>.<ключи>`. [deepwiki amnezia-xray-core VLESS](https://deepwiki.com/amnezia-vpn/amnezia-xray-core/4.1-vless-protocol)
- CLI `xray mlkem768` генерирует PQ-ключи клиента; доки: [xtls.github.io](https://xtls.github.io/en/config/outbounds/vless.html)

### Что уже «бесплатно» в стеке sora

- **Go 1.24+ включает X25519MLKEM768 в `crypto/tls` по умолчанию** (когда `CurvePreferences` nil; откл. через `GODEBUG=tlsmlkem=0`). sora-core и sora-legacy-core — **`go 1.26.9`** → все TLS-транспорты (Trojan/TLS, VLESS/VMess/TLS, XHTTP/TLS, WS/TLS) уже договариваются о PQ-гибриде автоматически, без единой строки кода. [dev.to](https://dev.to/instatunnel/quantum-safe-local-tunnels-preparing-your-development-stack-for-post-quantum-cryptography-2jnh)
- Парсер sora уже импортирует `PresharedKey` из wg-конфигов, а рендеры **всех трёх движков** (sing-box, mihomo, xray) прокидывают `pre_shared_key` пирам (`core/engine/{singbox,mihomo,xray}`). Сантехника для PSK-инъекции есть.

## 2. Что sora должен перенять

### R1. «Quantum-resistant tunnel» для WireGuard/AmneziaWG (паттерн Mullvad/ExpressVPN) — эффект HIGH
При подключении WG: sora-core устанавливает короткий TLS 1.3-сеанс (уже PQ-гибридный на Go 1.26) к KEM-эндпоинту, выполняет X25519+ML-KEM-768 инкапсуляцию, выводит 32-байтный PSK и подставляет его пиру перед стартом туннеля. Никаких изменений wire-протокола, работает против **любого** WG-сервера провайдера, который отдаёт PQ-секрет (или локально: sora может сам держать KEM-сервис для своих будущих серверов из клиента, PLANS P2). Для AmneziaWG — дополнительно отследить апстрим Lewes Protocol (дефолт с июня 2026 у Nym). Это паритет с Mullvad/ExpressVPN — единственными, у кого PQ включён по умолчанию/опционально осознанно.

### R2. Включить PQ-фичи Xray там, где сервер поддерживает — эффект HIGH (малые затраты)
- Для VLESS-аутбаундов: опция `VLESS Encryption` в режиме `mlkem768x25519plus` (1rtt), когда сервер (Remnawave/Xray ≥ нужной версии) её анонсирует. Клиентский код уже в Xray-core — работа sora в основном конфигурационная + детект capability.
- REALITY: убедиться, что fingerprint/utls в бандле Xray не форсирует классический X25519 (по коду Xray гибрид предпочитается автоматически, если fingerprint его поддерживает).
- `xray mlkem768` можно вызывать из sora-core для генерации клиентских PQ-ключей при настройке.

### R3. Зафиксировать и показать «бесплатный» PQ-TLS — эффект MEDIUM
Проверить, что нигде в коде не задан `CurvePreferences` без X25519MLKEM768 и не стоит `GODEBUG=tlsmlkem=0` (дефолт Go 1.26 уже правильный, но стоит явно зафиксировать тестом). В диагностику/лог добавить отображаемую группу key exchange TLS-соединений и **бейдж «Quantum-resistant» в UI** при активном PQ (как зелёный «QUANTUM SECURE CONNECTION» у Mullvad). Дешёвый траст-сигнал: конкуренты это показывают, пользователи это гуглят.

### R4. Тумблер + дефолт-стратегия как у лидеров — эффект MEDIUM
Mullvad: default ON (десктоп). ExpressVPN WG: opt-in. NordVPN: тумблер. Для sora: настройка «Квантово-устойчивый туннель» (Авто/Вкл/Выкл) на WG/AmneziaWG-профилях, дефолт Авто→Вкл когда сервер поддерживает. Причины держать opt-out: +2 КБ в хендшейке могут ломать кривые DPI/мидлбоксы (известная проблема PQ-TLS — нужен фолбэк).

### R5. Не делать — эффект LOW/отрицательный
- Свой KEM/кастомный форк WireGuard-протокола: несовместимость со всеми серверами, аудит с нуля.
- ML-DSA-сертификаты для аутентификации сервера (путь Surfshark окт 2026): незрело (+15 КБ к хендшейку, Web PKI не готов до ~2027, в server-agnostic модели sora нечего верифицировать).
- Classic McEliece: имеет смысл для долгоживущих статических ключей (Mullvad, Rosenpass); для эфемерных сессий ML-KEM-768 достаточно и в разы компактнее.

## 3. Оценка эффекта (сводно)

| # | Мера | Эффект | Почему |
|---|---|---|---|
| R1 | PQ-PSK для WireGuard/AmneziaWG (ML-KEM KEX-канал) | **HIGH** | Паритет с Mullvad/ExpressVPN; HNDL-защита; ноль изменений протокола; маркетинг «quantum-resistant by default» |
| R2 | VLESS Encryption mlkem768x25519plus + REALITY-hybrid из Xray | **HIGH** | Уже в движке, в основном конфиг; покрывает главный анти-DPI стек sora |
| R3 | Зафиксировать Go-TLS PQ + бейдж в UI/диагностике | MEDIUM | Бесплатно уже сегодня; видимый траст-сигнал, конкуренты показывают |
| R4 | Тумблер Авто/Вкл/Выкл с фолбэком | MEDIUM | UX-паритет с Nord/Mullvad; страховка от битых мидлбоксов |
| R5 | Своя крипта / ML-DSA-сертификаты сейчас | LOW (−) | Незрело, дорого, ломает совместимость |

## 4. Источники (ключевые)

- Mullvad: quantum-resistant tunnels default on desktop (09.01.2025) — https://mullvad.net/zh-hans/blog/2025/1/9/quantum-resistant-tunnels-are-now-the-default-on-desktop
- ExpressVPN PQ-WireGuard + whitepaper (авг 2025) — https://www.wilsonsmedia.com/expressvpn-adds-wireguard-to-support-industry-transition-to-post-quantum-vpns/
- Surfshark: full PQ WireGuard с ML-DSA (окт 2026) — https://surfshark.com/blog/post-quantum-secure-wireguard
- Обзор PQ-VPN 2026 (Mullvad/Nord/Windscribe/Nym/ExpressVPN/Proton) — https://encapsulated.network/post-quantum-vpn-encryption/
- PQC vendor matrix 2026 — https://www.postquantumfield.com/blog/pqc-vendor-support-matrix/
- Post-quantum WireGuard vs classical: PSK-паттерн, Rosenpass — https://shattered.io/post-quantum-wireguard-vs-classical-wireguard-2026/
- Crypto-agility: позиция Доненфельда, Classic McEliece — https://postquantum.com/post-quantum/crypto-agility-program/
- Signal PQXDH default (май 2026) — https://www.locked.news/articles/signal-post-quantum-default.html ; SPQR — https://www.qntonsol.com/learn/pq-messaging-and-ssh-imessage-signal-openssh.html
- Xray-core REALITY PQ — https://deepwiki.com/XTLS/Xray-core/4.1-vless-protocol ; VLESS docs (mlkem768) — https://xtls.github.io/en/config/outbounds/vless.html ; VLESS Encryption формат — https://deepwiki.com/amnezia-vpn/amnezia-xray-core/4.1-vless-protocol
- Go 1.24+ TLS X25519MLKEM768 by default — https://dev.to/instatunnel/quantum-safe-local-tunnels-preparing-your-development-stack-for-post-quantum-cryptography-2jnh
- OpenVPN blog: «WireGuard PQ — только новым протоколом» (12.10.2026) — https://blog.openvpn.net/wireguard-vs-openvpn-for-a-multi-user-homelab
- Квантово-безопасные VPN, уровни ML-KEM — https://symlexvpn.org/quantum-safe-vpn-post-quantum-cryptography/
