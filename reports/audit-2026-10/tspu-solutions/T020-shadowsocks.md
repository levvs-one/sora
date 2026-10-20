# T020 — Shadowsocks SIP022-честность: аудит, legacy-бейдж, миграция на SS-2022

Статус: код — в ветке `bugfix/audit-2026-10-19` (коммиты `[tspu-fix]`, см. «Что сделано»);
остальное — решения для UI/продукта ниже.

## Проблема

Shadowsocks жив как транспорт, но уязвим на двух уровнях:

1. **Форма трафика.** Первый пакет SS — высокоэнтропийный блок детерминированной
   структуры; детект по энтропии+длине (GFW, ТСПУ) не закрывается сменой шифра.
   SS-2022 закрывает replay-атаки, **но не энтропийный вектор** — это нужно говорить
   честно.
2. **Legacy-шифры** (`aes-256-gcm`, `chacha20-ietf-poly1305`, `aes-128-gcm`):
   подвержены RST-оракулу — TIMEOUT на пакетах ≤50 Б, RST на пакетах ≥51 Б
   (отчёт 07, P07-1). Активный пробер отличает SS-сервер от случайного хоста.

## Что сделано (Go-ядро)

Аудит Xray-core v26.10.17 (исходники, `/tmp/src/xray-core` на момент аудита):
Detection Prevention по SIP022 соблюдён — single-write всего handshake
(`stream.go`), `ResetTCPConn` с `SO_LINGER=0` (SIP022 §3.1.4), паддинг
случайной длины 1..900 Б (`mrand.IntN(MaxPaddingLength)+1`), окно timestamp ±30 с,
replay — sliding window. P07-2/P07-3 закрыты движком. sing-box — проверить по
`engines.lock` (исходников в аудите не было).

Коммиты:
- `13bdb64` `[tspu-fix] T020: SS legacy badge, SS-2022 migration helpers,
  known-port warning` — `core/engine/ss.go`:
  `WarnShadowsocksLegacyCipher` (для `ssClassAEAD`), `WarnShadowsocksKnownPort`
  (порт 8388), `DefaultNewShadowsocksMethod="2022-blake3-aes-256-gcm"`,
  `Shadowsocks2022Methods()`, `GenerateShadowsocks2022PSK()` (crypto/rand,
  base64 StdEncoding).
- `[tspu-fix] T020: SS plugin plumbing` (swept в соседние коммиты 1121593,
  26774d8 при восстановлении дерева — содержимое проверено, на месте):
  поля `Plugin`/`PluginOpts` в `engine/plan.go`, маскировка в
  `engine/validate.go` `Secrets()`, рендер: sing-box — `plugin`/`plugin_opts`
  verbatim (explicit plugin побеждает legacy obfs-mapping; пустой `;obfs-host=`
  больше не эмитится), mihomo — `SSPlugin`/`SSPluginOpts`, парсер нормализует
  `plugin`/`plugin_opts` → `Options["ss_plugin"/"ss_plugin_opts"]`
  (split-форма приоритетна), `control/plan.go` — `ss_plugin`/`ss_plugin_opts`
  в credentialDocument/applyCredential.
- `73e3d8d` `[tspu-fix] T020: SS plugin tests` — `TestParseShadowsocksPlugin`,
  `TestShadowsocksPluginSurvivesTheVault` (включая Secrets-маскировку),
  `TestRenderShadowsocksPlugin` (sing-box), `TestSSPluginOpts` +
  `TestBuildProxyShadowsocksPlugin` (mihomo, 6 кейсов опций).

## Матрица поддержки plugin'ов по движкам (честно)

| Движок   | plugin (SIP002) | Комментарий |
|----------|-----------------|-------------|
| sing-box | ✅ | `plugin`/`plugin_opts` verbatim |
| mihomo   | ✅ | `plugin`/`plugin-opts` (map) |
| xray     | ❌ | Xray SS-inbound/outbound не поддерживает plugin'ы — ограничение движка, не sora |

UI должен скрывать поле plugin для xray-планов (показывать причину).

## Решения для UI (Dart, спека)

1. **Бейдж «Legacy»** на сервере с `aes-*-gcm`/`chacha20-ietf-poly1305`:
   текст — «Уязвим к активному пробингу (RST-оракул). Работает, но не надейся
   на стелс». Не блокировать, не удалять.
2. **Кнопка «Обновить до 2022»** — генерирует PSK через
   `GenerateShadowsocks2022PSK`, подставляет `2022-blake3-aes-256-gcm`,
   показывает новый `ss://` и QR. Старый сервер остаётся в списке
   (пользователь сам удаляет после проверки). Требуется подтверждение, что
   серверная сторона обновлена, — иначе кнопка чинит конфиг, ломая соединение.
3. **Дефолт для новых** — `2022-blake3-aes-256-gcm` (уже
   `DefaultNewShadowsocksMethod`).
4. **Предупреждение про известный порт** 8388 (`WarnShadowsocksKnownPort`).
5. **Поле plugin/plugin_opts** в редакторе SS (кроме xray).
6. **Опциональный TLS-транспорт поверх SS** (sing-box `tls` под SS-outbound):
   честная подпись — «переносит битву с энтропийного детекта на JA4/SNI-поле,
   не делает невидимым».

## Честные ограничения

- SS-2022 **не** закрывает энтропийный вектор; голый SS ненадёжен против
  ТСПУ/GFW как стелс-транспорт. Позиционирование: «быстрый транспорт для
  неагрессивных сетей», не «невидимка».
- Рандомизация длины первого пакета сверх SIP022-паддинга движками не
  делается; кастомный фрагментирующий транспорт — отдельная задача, не этот T-ID.
- Удаление legacy-шифров — **не делать**: сломает существующие подписки.
