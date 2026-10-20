# Cloak и shadowsocks-плагины: состояние экосистемы (2025–2026)

Дата: 2026-10-19. Источники: GitHub API/репозитории, Docker Hub, документация sing-box/mihomo/Xray, обзоры 2025–2026.

## 1. Cloak (cbeuw/Cloak) — жив, но на аппарате жизнеобеспечения

- Репозиторий существует, активен только dependabot: PR #321 (20.11.2025) поднял `golang.org/x/crypto` 0.37.0→0.45.0. Функциональных коммитов/релизов давно нет (последняя ветка v2.5.x, ~2022). Источник: https://api.github.com/repos/cbeuw/Cloak/issues/events/21057540783 (через GitHub API).
- Живёт за счёт сообщества: активные форки (напр. erowalker/Cloak — правки `internal/server/TLS.go`, 2026), установочные скрипты HirbodBehnam/Shadowsocks-Cloak-Installer, гайды SixGenInc/Noctilucent (README, crawl 2026): https://raw.githubusercontent.com/SixGenInc/Noctilucent/master/README.md
- Реальный потребитель — AmneziaVPN («OpenVPN over Cloak», самоподъём на VPS через клиент). Но свежий обзор 2026 фиксирует: Amnezia постепенно сворачивает «OpenVPN over Cloak» и Shadowsocks — их всё лучше детектирует DPI: https://moarfaj.medium.com/brand-new-independently-built-vpns-2024-2026-a-technical-investigation-91b7b437af1c (раздел Amnezia VPN). При этом свежий тред апреля 2026 ещё показывает Cloak как опцию установки: https://diggita.com/post/470314?scrollToComments=true — то есть сворачивание частичное, не полное.
- Ни sing-box, ни Xray, ни mihomo **не поддерживают Cloak нативно**. Клиенты v2rayN/v2rayNG/Nekoray/Hiddify Cloak не умеют.
- Вывод: протокол заморожен с 2022 г., новых идей/фич нет, DPI его догоняет. Это тупиковая ветвь эволюции.

## 2. Shadowsocks-плагины (SIP003): кто жив, кто мёртв

| Плагин | Статус 2025–2026 | Комментарий |
|---|---|---|
| v2ray-plugin (teddysun) | Условно жив (maintenance) | Репозиторий переехал в организацию shadowsocks; форк qiuyuzhou/v2ray-plugin (создан 12.10.2026): Go 1.25.5, V2Ray core v5.53.0, добавились QUIC и **Hysteria2** транспорты. Источник: https://github.com/qiuyuzhou/v2ray-plugin |
| xray-plugin (teddysun) | Жив на минималках | Docker-образ `gists/xray-plugin:1.8.24` обновлён ~1 день назад (crawl 2026); Android-вариант `xray-plugin-android` — версия 1.8.24, targetSdk 30 (устарело для Android 14+). Источник: https://hub.docker.com/r/gists/xray-plugin/tags, https://deepwiki.com/teddysun/xray-plugin-android |
| simple-obfs | Мёртв | Последний коммит ~2019, C/libev. Живёт только как встроенная реализация в sing-box/mihomo. Отдельный бинарник тащить не нужно и не стоит. |
| kcptun | Мёртв | Последний релиз 2020. Никому не нужен: Hysteria2/TUIC закрывают кейс «плохая сеть» лучше. |
| gost-plugin | Нишевый | Поддерживается mihomo встроенно (adapter/outbound/shadowsocks.go), но сам по себе мало распространён. |

## 3. Живые преемники: куда реально ушла экосистема

- **ShadowTLS v3** — де-факто наследник идеи Cloak (TLS-camouflage, но с challenge-response от активного пробинга). Встроен нативно в **sing-box** (`transport/shadowtls/v3.go`) и **mihomo** (adapter/outbound/shadowsocks.go:173-178). Активно используется в свежих сборках. Источник: https://deepwiki.com/xinebf/mihomo/6.5-shadowsocks-ssr-snell-shadowtls-and-obfuscation-transports, https://deepwiki.com/SagerNet/sing-box/4.2-proxy-protocol-implementations
  - ⚠️ Нюанс: в 2025 опубликован тест Aparecium, показывающий детектируемость ShadowTLS v3 через HMAC-tainting (ServerFinished длиннее на 4 байта): https://deepwiki.com/ban6cat6/aparecium/3.2-shadowtls-protocol. Не смертельно, но идеального «невидимки» нет.
- **RestLS / JLS** — более новые TLS-обёртки, встроены в mihomo (RestLS: `transport/restls/restls.go`), скриптуемый TLS. Ниша, но живая.
- **AnyTLS** — нативный TLS-туннель в sing-box (inbound+outbound), поддерживается v2rayN 7.14.3+. Источник: https://deepwiki.com/liwoyuandianer/github-edgeone/3.2-protocol-support-and-architecture
- **Shadowsocks-2022 (SIP022)** — текущий стандарт: BLAKE3-KDF, обязательная защита от replay, UDP-сессии, multi-user через EIH. Поддерживается sing-box, Xray, mihomo, shadowsocks-rust. Источник: https://deepwiki.com/shadowsocks/shadowsocks-org/2.3.2-sip022:-aead-2022-ciphers, https://lib.rs/crates/shadowsocks-rust
- Контекст рынка (RU, октябрь 2025): голый SS и обфусцированный SS детектятся DPI за часы; выживают VLESS+TLS/Reality. Источник: https://dev.to/__2ea5fee000c/vless-protocol-how-it-bypasses-censorship-in-russia-and-why-it-works-4o9d — SS-обфускация больше не «оружие победы», а совместимость с легаси-серверами.

## 4. Что это значит для sora (текущее состояние кода)

- `core/engine/singbox/render.go:212` — SS рендерится с `plugin=obfs-local` (simple-obfs). sing-box реализует simple-obfs и **v2ray-plugin встроенно** (`transport/sip003`: obfs.go, v2ray.go) — внешний бинарник не нужен, но sora пробрасывает только obfs-параметры, v2ray-plugin недостижим.
- `core/engine/mihomo/config.go:96-98` — только поля `obfs/obfs-param/obfs-password` (legacy simple-obfs). mihomo нативно умеет plugin/plugin_opts: Simple-Obfs, V2Ray-Plugin, **ShadowTLS**, RestLS, Gost-Plugin, KCPTun — sora это не пробрасывает.
- `core/engine/xray/render.go:216-218` — SS без obfs вообще (Xray-ядро SIP003-плагины не поддерживает).
- Cloak не поддерживается ни одним из трёх движков sora — нативная поддержка означала бы тащить внешний бинарь ck-client/ck-server и отдельный протокол. Не делать.

## 5. Рекомендации для sora

### HIGH
1. **Пробросить generic `plugin`/`plugin_opts` в sing-box и mihomo.** sing-box уже умеет simple-obfs + v2ray-plugin встроенно; mihomo — +ShadowTLS/RestLS/Gost. Сейчас sora отдаёт только simple-obfs. Нужны: поле `Plugin`/`PluginOpts` в модели outbound, парсинг `ss://…?plugin=` из URI при импорте, рендер в оба движка, валидация. Эффект: совместимость с существующими SS-подписками (v2ray-plugin+WS+TLS — самый распространённый живой сетап), ноль новых бинарников.
2. **UX для Shadowsocks-2022 (SIP022).** Все три движка поддерживают `2022-blake3-*`. Нужны: генератор PSK (base64, 16/32 байта), выбор метода в UI, понятная ошибка при вводе пароля вместо PSK (типичная ошибка пользователей). Эффект: SS-2022 — единственный SS-вариант с будущим; без UX пользователи продолжат использовать слабые legacy-шифры.

### MEDIUM
3. **ShadowTLS v3 как transport-опция для SS (sing-box, mihomo).** Живой преемник Cloak, встроен в оба движка, challenge-response против активного пробинга. Предложить в UI как «SS + ShadowTLS» для жёстких сетей. Эффект: современная TLS-маскировка без внешних зависимостей; закрывает кейс, ради которого когда-то брали Cloak.
4. **AnyTLS как отдельный протокол (sing-box native).** Простой, современный, поддерживается v2rayN 7.14+. Эффект: +1 актуальный протокол почти бесплатно (движок уже умеет).
5. **Парсинг `plugin=` из ss:// URI при импорте** (часть п.1, но UI-сторона): многие подписки отдают SS с v2ray-plugin в URI; сейчас такие ноды либо не импортируются, либо теряют обфускацию.

### LOW
6. **Cloak — не в ядро, только как расширение.** Если понадобится (пользователи Amnezia-мигранты), Cloak реализуется как `.soraext`-расширение (обёртка над ck-client), а не нативный протокол: ни один движок его не знает, upstream заморожен, DPI догоняет. Эффект: закрытие ниши без загрязнения кодовой базы.
7. **Не тащить: kcptun, внешний simple-obfs-бинарник, ShadowsocksR.** Всё мёртво или покрыто встроенными реализациями/Hysteria2.

## 6. Итог одной строкой

Cloak — музейный экспонат на жизнеобеспечении (только dependabot + форки + Amnezia, которая сама его сворачивает); живые деньги экосистемы SS — **v2ray-plugin (maintenance), ShadowTLS v3 / RestLS (встроены в sing-box/mihomo), SS-2022**. sora должна: пробросить plugin/plugin_opts в оба движка (high), дать UX для SS-2022 (high), предложить ShadowTLS v3 (medium) — и не трогать Cloak в ядре.
