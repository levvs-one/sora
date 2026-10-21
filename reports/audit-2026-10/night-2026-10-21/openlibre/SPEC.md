# OpenLibre / olcrtc — спецификация по первоисточникам (SPEC)

Подотдел спеки/исследований, департамент OpenLibre. Только исследование, код продукта sora не трогался.

## Источники и ревизии (все цитаты — `файл:строка` внутри соответствующего клона)

| Клон | Путь | HEAD | Remote |
|---|---|---|---|
| olcrtc | `~/workspace/openlibre-ref/olcrtc` | `f3ad8fb7c0d0fa981423f83269526fa94077c23d` (`f3ad8fb docs: redact zarazaex.xyz references as [DEL]`) | `github.com/openlibrecommunity/olcrtc` |
| olcng | `~/workspace/openlibre-ref/olcng` | `c2664a28cb7ee8a6fbfaae660f069132a6978850` | `github.com/openlibrecommunity/olcng` |
| owenclave | `~/workspace/openlibre-ref/owenclave` | `1907659fac09c8b9eec0e6e68de737e0295edf72` (`1907659 feat: decrypt happ://crypt-crypt5 subscription links locally`) | `https://github.com/owenewans/owenclave` — **склонировался успешно** (2026-10-21), недоступности не было |

Дальше префиксы цитат: `[olcrtc]`, `[owenclave]`, `[olcng]` — файл внутри соответствующего клона на указанном выше HEAD.

Ключевой факт, определяющий всё остальное:

> «The current `olcrtc` does not parse such a URI automatically. If a client application wants to use this notation, it must parse the string itself and pass the resulting fields into the `olcrtc` YAML config.» — [olcrtc] `docs/uri.md:17`

> «this is a convention **for client applications**. `olcrtc` itself does not read or process such a file» (про подписку) — [olcrtc] `docs/sub.md:24`

В Go-коде olcrtc парсера `olcrtc://` **нет вообще**: единственный генератор URI в репозитории — shell-строка в `install.sh` ([olcrtc] `install.sh:603`), поиск по `olcrtc://` в `cmd/`, `internal/`, `pkg/`, `mobile/` других попаданий не даёт. Единственный реальный парсер формата в экосистеме — Kotlin в owenclave.

---

## 1. Грамматика `olcrtc://`

### 1.1. Формула (docs/uri.md)

```text
olcrtc://<Provider>?<Transport>@<RoomID>#<EncryptionKey>$<MIMO>
olcrtc://<Provider>?<Transport><key=value&key=value>@<RoomID>#<EncryptionKey>$<MIMO>
```

— [olcrtc] `docs/uri.md:30-31`, повтор в `docs/sub.md` (раздел Server lines).

Версии в полосе нет: «This convention has no in-band version field. The schema below is URI format v1» — [olcrtc] `docs/uri.md:19`. Подписка — тоже v1 без in-band version ([olcrtc] `docs/sub.md:26`).

Разделители ([olcrtc] `docs/uri.md`, таблица Separators):

| Разделитель | Что за ним |
|---|---|
| `://` | начало payload после схемы `olcrtc` |
| `?` | `<Transport>` |
| `<...>` | payload параметров транспорта, сразу после имени транспорта |
| `@` | `<RoomID>` |
| `#` | `<EncryptionKey>` |
| `$` | `<MIMO>` |

### 1.2. Поля: обязательность, кодировки, дефолты

| Поле | YAML | Обязательность (по факту кода) | Кодировка / алфавит | Дефолт |
|---|---|---|---|---|
| `Provider` | `auth.provider` | Обязательно. Пустое → `ErrProviderRequired` ([olcrtc] `internal/app/session/config.go:51-52`, `validate.go:validateProvider`) | Голое имя из закрытого реестра: `jitsi` / `telemost` / `wbstream` / `none` (см. §3). Никакого escaping в примерах и в `install.sh` нет | В URI — нет. В owenclave Bean — `jitsi` ([owenclave] `app/src/main/java/io/nekohasekai/sagernet/fmt/olcrtc/OLCRTCBean.java:26`); в `install.sh:141-144` выбор по умолчанию — `jitsi` |
| `Transport` | `net.transport` | Обязательно. Пустое → `ErrTransportRequired` ([olcrtc] `internal/app/session/config.go:54-55`) | Голое имя: `datachannel` / `vp8channel` / `seichannel` / `videochannel` | В URI — нет. Парсер owenclave при отсутствии `?` подставляет `datachannel` ([owenclave] `.../fmt/olcrtc/OLCRTCFmt.kt:34`); Bean — `datachannel` (`OLCRTCBean.java:27`); `install.sh` default choice 1 = `datachannel` |
| payload `<k=v&...>` | поля транспорта (табл. §3.2) | Опционален целиком: «The block is dropped when defaults are used» ([olcrtc] `docs/uri.md`, Format). Для `datachannel` — запрещён по смыслу («No payload») | Пары `key=value`, разделитель `&`, обёртка `<` `>`. Значения — десятичные int или enum-строки (`qrcode`, `low`, …). Percent-encoding внутри payload дока не вводит | Все ключи опциональны по отдельности; недостающие добираются дефолтами транспорта (§3.2, три разных слоя дефолтов — см. расхождение Р-5) |
| `RoomID` | `room.id` | Обязательно для всех провайдеров, кроме `none`: `ErrRoomIDRequired` ([olcrtc] `internal/app/session/validate.go:validateCommon`) | **Провайдер-зависим, без единой кодировки.** jitsi: полный URL комнаты `https://host/room` или `host/room`, сырой, с `://` и `/` внутри ([olcrtc] `docs/uri.md:240` и пример). telemost: голый ID хэш или полный `https://telemost.yandex.ru/j/<id>` — код принимает оба ([olcrtc] `internal/auth/telemost/telemost.go:28-36`: префикс дописывается, если нет `https://`). wbstream: голый ID с сайта `stream.wb.ru`; значение `any` кодом отвергается как пустое ([olcrtc] `internal/auth/wbstream/wbstream.go`, `Issue`: `RoomURL == "" \|\| RoomURL == "any"` → `ErrRoomIDRequired`) | Нет |
| `EncryptionKey` | `crypto.key` | Обязательно: `ErrKeyRequired`, а по форме — `ErrKeyInvalid` ([olcrtc] `internal/app/session/validate.go:101-107`) | **Строго hex, ровно 64 символа = 32 байта**: `hex.DecodeString` + `len(key) != chacha20poly1305.KeySize` → invalid. Дока смягчает: «in hex, usually 64 chars (`32` bytes)» ([olcrtc] `docs/uri.md`, таблица Fields) — код строже доки, см. Р-7. Генерация: `openssl rand -hex 32` ([olcrtc] `install.sh:276`; `validate_key` в `install.sh:97-104`: только `[0-9a-fA-F]` и длина 64). Не base64, не percent-encoding | Нет. На сервере генерируется и переиспользуется из `~/.olcrtc_key` ([olcrtc] `docs/fast.md`, Step 2) |
| `MIMO` | — (в YAML **не передаётся**: «Not passed to `olcrtc`. Client comment only», [olcrtc] `docs/uri.md`, Mapping) | Опционален: всё после первого `$`, включая отсутствие самого `$` (в примере sub.md вторая строка без `$`-хвоста не бывает, но в uri.md MIMO в примерах иногда просто `MIMO`) | Свободный текст для UI/метаданных, примеры: `RU / olc free sub / IPv6` — с пробелами и `/` **сырьём, без encoding**. Дока: разделители внутри полей использовать не рекомендуется; если надо — клиент обязан ввести **свой** симметричный escaping/percent-encoding ([olcrtc] `docs/uri.md:118`) — то есть единого правила кодировки в спеке **нет** | Отсутствует = пустой комментарий. `install.sh:598-603`: дефолтный комментарий `olc - t.me/openlibrecommunity` |

Что URI **не кодирует вообще** (важно для sora — это потерянная часть YAML): `mode` (подразумевается клиент/`cnc` у потребителя, сервер/`srv` у издателя), `net.dns` (owenclave добирает `8.8.8.8:53`, `OLCRTCBean.java:30`), SOCKS host/port/user/pass, `auth.token`, `room.channel`, `engine.*` для провайдера `none`, `liveness`, `lifecycle`, `traffic`, `profiles`/failover, `data`. Прямо признано только про `data`: «`data: data` is not encoded in this format, because it is a local runtime setting» ([olcrtc] `docs/uri.md`, Mapping).

### 1.3. Как парсит owenclave (единственный реальный парсер)

Файл: [owenclave] `app/src/main/java/io/nekohasekai/sagernet/fmt/olcrtc/OLCRTCFmt.kt`, функция `parseOLCRTCLink` (строки 6-43), генерация — `OLCRTCBean.toUri()` (45-59).

Алгоритм парсинга — последовательный поиск **первого** вхождения разделителя, в фиксированном порядке независимо от позиции:

1. `removePrefix("olcrtc://")` (:8) — без проверки, что префикс был; схема в `Formats.kt:141` проверяется case-insensitive (`startsWith("olcrtc://", ignoreCase = true)`), сам `removePrefix` — case-sensitive.
2. Первый `$` (:11) → всё после = name/MIMO, `URLDecoder.decode(..., "UTF-8")` (:12).
3. В оставшемся первый `#` (:16) → всё после = EncryptionKey, **без декодирования** (:17-19, :40).
4. В оставшемся первый `@` (:23) → всё после = RoomID, `URLDecoder.decode` (:24, :39).
5. В оставшемся первый `?` (:28) → до него Provider (`URLDecoder.decode`, :37), после — Transport до первого `<` (:30-33, `URLDecoder.decode`, :38). **Сам блок `<...>` и всё после него внутри транспортно-провайдерной части выбрасывается** (:32-33 — берётся только `substring(0, ltIdx)`).

Валидации нет никакой: ни длины/hex ключа, ни принадлежности Provider/Transport реестрам, ни непустоты RoomID. Пустые куски становятся пустыми строками (Bean-дефолты срабатывают только на `null`, `OLCRTCBean.java:25-32`, а парсер ставит не-null строки).

Генерация `toUri()` (:45-59): `URLEncoder.encode` для Provider, Transport, RoomID и name (но не для ключа), разделители вставляются всегда, payload не эмитится никогда. `URLEncoder` — это *form*-кодировка: пробел → `+`, `:` и `/` → `%3A`/`%2F`.

Как потребитель доводит Bean до olcrtc: [owenclave] `app/src/main/java/io/nekohasekai/sagernet/bg/proto/V2RayInstance.kt:63-88` (`buildOlcrtcYaml`) — собирает YAML только из `mode: cnc`, `auth.provider`, `room.id`, `crypto.key`, `net.transport`, `net.dns`, `socks.host/port(+user/pass)`, `debug: true`. Никаких секций `vp8:`/`sei:`/`video:` не эмитится — параметры из payload не просто теряются при парсинге, им **некуда** попасть дальше.

### 1.4. Как генерирует install.sh (единственный генератор в olcrtc)

[olcrtc] `install.sh:582-603`: payload собирается только для не-datachannel транспортов и всегда с полным набором ключей фактически выбранных настроек; для videochannel состав зависит от кодека (tile → `video-tile-module`+`video-tile-rs`; qrcode с `qr_size>0` → `video-qr-recovery`+`video-qr-size`; qrcode с `qr_size=0` → только `video-qr-recovery`). Итог: `olcrtc://$PROVIDER?${TRANSPORT}${PAYLOAD}@$ROOM_ID#$KEY\$$comment` — всё сырьём, без какого-либо escaping; комментарий по умолчанию содержит пробелы и дефисы.

---

## 2. Формат подписки (docs/sub.md целиком)

Источник: [olcrtc] `docs/sub.md` (EN; есть зеркало `sub.ru.md`).

- Носитель: «`sub.md` is a plain text file hosted on a server and served as plain text» (:14). Пример URL в доке: `https://killpeople.freegore.xyz/sub`.
- **Base64-обёртки в спеке нет.** Файл — plain text как есть. (То, что owenclave умеет base64 — общее свойство его generic-парсера, не этого формата, см. Р-4.)
- Версии в полосе нет, формат = subscription v1 (:26). На все перечисленные эндпоинты распространяются требования OLC2 crypto и OLVC v5 (:26).
- Чтение сверху вниз, три вида строк (:43-49): глобальные `#key: value`, строки `olcrtc://...`, локальные `##key: value`.

Глобальные поля (`#`, [olcrtc] `docs/sub.md:78-94`):

| Поле | Смысл |
|---|---|
| `#name:` | имя подписки |
| `#update:` | время последнего обновления, Unix time (рекомендация: в секундах, :131) |
| `#refresh:` | период обновления, напр. `5s`, `10m`, `6h` (рекомендация: также `1d`, :132) |
| `#color:` | цвет подписки, UI-only (рекомендация: `#RRGGBB`, :133) |
| `#icon:` | иконка подписки, UI-only (строковый id или emoji, :134) |
| `#used:` | использовано, напр. `10mb/10gb` (юниты `kb/mb/gb/tb`, :135) |
| `#available:` | всего доступно, напр. `1.1gb` |

Локальные поля (`##`, [olcrtc] `docs/sub.md:111-125`): **привязка — к ближайшей предшествующей строке `olcrtc://`**: «Lines like `##key: value` apply only to the **last URI** declared above… the client must bind a `##...` block to the nearest preceding `olcrtc://...` line» (:113-115).

| Поле | Смысл |
|---|---|
| `##name:` | имя сервера/ноды |
| `##color:` | UI-цвет |
| `##icon:` | UI-иконка |
| `##used:` | usage конкретного сервера, напр. `500mb/10gb` |
| `##available:` | доступный объём конкретного сервера |
| `##ip:` | IP сервера, если надо показать клиенту |
| `##comment:` | свободный комментарий |

Локальные почти дублируют глобальные, но без `refresh` (:127). Пустые строки между элементами разрешены (:104). Одна URI-строка = один сервер (:102). Заголовков/комментариев иных видов (произвольный `#`-текст не по схеме, `//`, `;`) спека не определяет — не-`#key:` строки поведением не покрыты.

### 2.1. Дословный тестовый корпус из доки

Полный пример, [olcrtc] `docs/sub.md:141-163`, дословно:

```text
#name: Zarazaex Free RU
#update: 1778011200
#refresh: 10m
#color: #4A90E2
#icon: 🇷🇺
#used: 10mb/10gb
#available: 9.99gb

olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olcng free sub / IPv6
##name: RU-1
##icon: 🇷🇺
##color: #4A90E2
##used: 500mb/10gb
##available: 9.5gb
##ip: 203.0.113.10
##comment: basic free node

olcrtc://wbstream?datachannel@abc123xyz#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$DE / backup / IPv4
##name: DE-Backup
##icon: 🇩🇪
##color: #2EBD85
##comment: reserve route, wbstream+datachannel does not work in guest flow
```

Отдельные URI-примеры из [olcrtc] `docs/uri.md` (дословно, строки :127, :153, :180, :209, :240):

```text
olcrtc://wbstream?datachannel@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olc free sub / IPv6
olcrtc://wbstream?vp8channel<vp8-fps=60&vp8-batch=64>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olc free sub / IPv6
olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$DE / olc free sub
olcrtc://telemost?videochannel<video-w=1080&video-h=1080&video-fps=60&video-codec=qrcode>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$MIMO
olcrtc://jitsi?datachannel@https://meet.example.org/myroom#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olc free sub
```

Итоговый вывод `install.sh` из [olcrtc] `docs/fast.md` (Result, Step 2):

```text
uri: olcrtc://jitsi?datachannel@https://meet.example.org/olcrtc-xxxxxxxx#<key>$olc - t.me/openlibrecommunity
```

---

## 3. Провайдеры и транспорты

### 3.1. Провайдеры (реестр кода)

Регистрация: [olcrtc] `internal/engine/builtin/builtin.go:105-114` (`RegisterDefaults`): `wbstream`, `telemost`, `jitsi`, `none`. Интерфейс провайдера: [olcrtc] `internal/auth/auth.go:59-70` (`Engine()`, `DefaultServiceURL()`, `Issue(ctx, Config) (Credentials, error)`); `Credentials{URL, Token, Extra}` — `auth.go:36-40`. Провайдер `auth.Config` несёт `RoomURL`, `Name` (display name), опциональный предвыпущенный `Token`, DNS/прокси (`auth.go:44-57`).

| Provider (URI/YAML) | Engine (код) | DefaultServiceURL | Что нужно для подключения | Аутентификация / токены |
|---|---|---|---|---|
| `jitsi` | `jitsi` ([olcrtc] `internal/auth/jitsi/jitsi.go:42`) | `https://meet.handyweb.org` (`jitsi.go:44-49`) | RoomID = URL `https://host/room` или `host/room` (парсинг без HTTP: `internal/auth/jitsi/jitsi.go`, `Issue`/`parseRoomURL`). Любой self-hosted/public Jitsi Meet **без аутентификации**; список публичных инстансов — `docs/jitsi.instances.yaml` (16 хостов на этом HEAD: `meet.egovm.ru`, `conference.ct.placetime.team`, `jitsy.amateusfox.online`, `meet.mamba.group`, `meet.ecopsy.com`, `meet.mirox.chat`, `webinar.knomary.dev`, `meet.playform.ru`, `webinar.devknomarylms.ru`, `zgn-y-vc01.zignotch.com`, `conf.expressmoney.com`, `m.catonmoon.com`, `conf.hyperia.space`, `jitsi.etudevs.ru`, `meet.riddlerx.org` + комментарий) | **Токен не используется вообще**: «Token is unused - Jitsi guest access requires no token» (`jitsi.go`, `Issue`). DataChannel — поверх colibri-ws bridge, `EndpointMessage{raw}` broadcast ([olcrtc] `docs/settings.md`, Jitsi) |
| `telemost` | `goolom` ([olcrtc] `internal/auth/telemost/telemost.go:23`) | `https://telemost.yandex.ru` (`telemost.go:26`); API base `https://cloud-api.yandex.ru/telemost_front/v2/telemost` (`internal/auth/telemost/api.go:21`) | Комната создаётся **только** на сайте telemost.yandex.ru, RoomID = ID или полный URL `https://telemost.yandex.ru/j/<id>` (`telemost.go:28-36`). `Issue` ходит в Yandex API за connection info (media server URL + credentials) | Гостевой флоу без аккаунтного токена в URI; `auth.token` провайдером не потребляется (в `Issue` не используется). Создание комнат API не поддерживает |
| `wbstream` | `livekit` ([olcrtc] `internal/auth/wbstream/wbstream.go:20`) | `https://stream.wb.ru` (`internal/auth/wbstream/api.go:20`, `defaultAPIURL`); WS по умолчанию `wss://rtc-el-02.wb.ru` (`api.go:19`) | Комната создаётся вручную на `stream.wb.ru`, RoomID оттуда | Два флоу (`wbstream.go`, `Issue`): (а) гость — регистрация анонимного гостя, получение guest access token, `joinRoom`, `getToken` → LiveKit token; гостевой токен имеет `canPublishData=false`; (б) `auth.token` задан → гость-шаг пропускается, сессия заходит как аккаунт. **Для datachannel нужен именно (б) с moderator/`canPublishData=true`, на обоих концах** ([olcrtc] `docs/settings.md`, WBStream и Optional fields) |
| `none` | прямой: `livekit` (дефолт, [olcrtc] `internal/engine/builtin/builtin.go`: `defaultDirectEngine = "livekit"`), `goolom`, `jitsi` — по `engine.name` ([olcrtc] `internal/config/config.go:117-122`) | нет ("" → вызывающий обязан дать `engine.url`) | RoomID не требуется (`validate.go:validateCommon`: пропуск при `provider == none`). Нужны `engine.url` + `engine.token` напрямую | Auth-флоу нет вообще: «passes a caller-supplied URL+Token through unchanged» ([olcrtc] `internal/auth/auth.go:9-12`). **В URI не выражается** — слотов под engine/url/token нет |

Движки (engines) как отдельный реестр: `livekit`, `goolom`, `jitsi` ([olcrtc] `internal/engine/builtin/builtin.go:108-110`). Это не провайдеры и не транспорты; в URI не попадают.

Матрица совместимости провайдер×транспорт ([olcrtc] `docs/settings.md`, Compatibility matrix): datachannel: telemost `−`, wbstream `~` (только с moderator-токеном), jitsi `+`; vp8channel: все `+`; seichannel: telemost `−`, wbstream `+`, jitsi `+` (с оговоркой про Jicofo/self-hosted); videochannel: все `+` (telemost — «slow/best effort»). Рекомендуемая комбинация — `jitsi + datachannel`, альтернатива — `wbstream + vp8channel`. Скорость по убыванию: datachannel > vp8channel > seichannel > videochannel.

### 3.2. Транспорты и полный словарь параметров

Регистрация: [olcrtc] `internal/app/session/config.go:163-168`. Все параметры — `int`, кроме `video.codec`/`video.qr_recovery` (строковые enum). FPS для всех транспортов валидируется в `1..240` ([olcrtc] `internal/transport/transport.go:160-165` `MaxFPS = 240`; `internal/app/session/validate.go:validateFPS`). Дефолты ниже — **сессионный слой** (`internal/app/session/config.go:33-42`, `defaults.go:60-109`), т.е. то, что реально применяется при запуске из YAML; отклонения других слоёв — в Р-5.

#### datachannel

Payload/параметров нет ([olcrtc] `docs/uri.md`: «No payload»). Отдельных YAML-полей нет ([olcrtc] `docs/settings.md`: «No extra fields»).

#### vp8channel — ключи URI: `vp8-fps`, `vp8-batch`

| Ключ URI | YAML | Тип | Дефолт (session) | Диапазон/валидация |
|---|---|---|---|---|
| `vp8-fps` | `vp8.fps` | int | 30 | 1..240 |
| `vp8-batch` | `vp8.batch_size` | int | 64 | >0 обязателен после дефолтов (`ErrVP8BatchSizeRequired`, если 0 и дефолт не применился — на практике дефолт применяется всегда) |

#### seichannel — ключи URI: `fps`, `batch`, `frag`, `ack-ms` (без префикса!)

| Ключ URI | YAML | Тип | Дефолт (session) | Диапазон |
|---|---|---|---|---|
| `fps` | `sei.fps` | int | 30 | 1..240 |
| `batch` | `sei.batch_size` | int | 64 | >0 |
| `frag` | `sei.fragment_size` | int, байты | 900 | 1..60000 ([olcrtc] `internal/app/session/validate.go:25`, `validateSEIChannel`) |
| `ack-ms` | `sei.ack_timeout_ms` | int, мс | 2000 | >0 |

#### videochannel — ключи URI: `video-w`, `video-h`, `video-fps`, `video-codec`, `video-qr-size`, `video-qr-recovery`, `video-tile-module`, `video-tile-rs`

| Ключ URI | YAML | Тип | Дефолт (session) | Диапазон/значения |
|---|---|---|---|---|
| `video-w` | `video.width` | int, px | 1920 (для `tile` — 1080, `defaults.go:63-72`) | 16..8192 |
| `video-h` | `video.height` | int, px | 1080 | 16..8192; для `tile` строго 1080×1080 (`ErrTileCodecDimensions`) |
| `video-fps` | `video.fps` | int | 30 | 1..240 |
| `video-codec` | `video.codec` | enum | `qrcode` | `qrcode` \| `tile` |
| `video-qr-size` | `video.qr_size` | int, байты | 0 = auto | ≥0 (транспортно 0 заменяется на 256, см. Р-5) |
| `video-qr-recovery` | `video.qr_recovery` | enum | `low` | `low` \| `medium` \| `high` \| `highest` |
| `video-tile-module` | `video.tile_module` | int, px, только `tile` | session не дефолтит (0); транспортный слой: 4 | 1..270 (валидация пропускает и 0) |
| `video-tile-rs` | `video.tile_rs` | int, % parity, только `tile` | 0 (по `docs/settings.md` и session) | 0..200 |

Устаревшее: payload-ключи/YAML `video-bitrate`/`video.hw` (`video-bitrate`, `video-hw`) — runtime игнорирует, продюсеры обязаны перестать эмитить ([olcrtc] `docs/uri.md:21`, `docs/sub.md:28`); в YAML они ещё принимаются строгим загрузчиком на один миграционный цикл как no-op ([olcrtc] `internal/config/config.go:132-139`, `docs/configuration.md`, Config schema migration), как и топ-левел `link`, `ffmpeg`.

---

## 4. Протоколы сообщества помимо olcrtc; olcng; остальные репозитории org

### 4.1. olcng — вердикт

**olcng — это клиент, не протокол.** «olcng - is a free VPN, fork of v2rayNG by Olc» ([olcng] `readme.md:14`). Android-клиент на Kotlin поверх Xray (в клоне: `V2rayNG/` + `AndroidLibXrayLite/`).

Собственного формата ссылок у olcng **нет**:

- Реестр протоколов исчерпывается стандартными Xray/v2rayNG: `EConfigType` = VMESS, CUSTOM, SHADOWSOCKS, SOCKS, VLESS, TROJAN, WIREGUARD, HYSTERIA2, HYSTERIA, HTTP, POLICYGROUP ([olcng] `V2rayNG/app/src/main/java/xyz/zarazaex/olc/enums/EConfigType.kt:5-18`); парсеры в `fmt/` — только эти (`VmessFmt`, `VlessFmt`, `TrojanFmt`, `ShadowsocksFmt`, `SocksFmt`, `HttpFmt`, `Hysteria2Fmt`, `WireguardFmt`, `CustomFmt`).
- Поиска по `olcrtc` по всему клону olcng — **ноль попаданий**: olcng olcrtc-ссылки не парсит и не генерирует. Упоминание «olcng» в примере подписки olcrtc (`$RU / olcng free sub / IPv6`, sub.md Full example) — это просто свободный текст MIMO, а не интеграция.
- Итог: из olcng sora не нужно поддерживать **ничего специфичного**; его протоколы — это обычные vmess/vless/trojan/ss/socks/wireguard/hysteria2, покрываемые стандартными парсерами sora независимо от olcng.

### 4.2. Остальные репозитории org — по одной строке

Проверено по ссылкам из клонированных первоисточников (полный листинг org публично через имеющиеся инструменты поиска не отдаётся; для twl/rewl/pxy в клонах нет ни одной ссылки — честная оговорка, см. §6):

- `material` — **не протокол**: репозиторий графических ассетов; из него все доки olcrtc/olcng тянут логотипы (`https://github.com/openlibrecommunity/material/blob/master/olcrtc.png`, [olcrtc] `docs/sub.md:3`; `OLcNG.png`, [olcng] `readme.md:3`).
- `twl` — в первоисточниках не упомянут; свидетельств собственного формата ссылок/протокола не найдено → протоколом не считать до отдельного подтверждения.
- `rewl` — аналогично: не упомянут, формата ссылок не найдено → не протокол (по имеющимся данным).
- `pxy` — аналогично: не упомянут, формата ссылок не найдено → не протокол (по имеющимся данным).

### 4.3. Закрытый перечень того, что sora должна поддерживать (вердикт)

1. URI `olcrtc://` формата v1 по грамматике §1 (все 3 провайдера URI-слоя + 4 транспорта + весь словарь payload §3.2) — парсинг и генерация.
2. Подписку subscription v1 по §2 (plain text, `#`-глобальные, `##`-локальные с привязкой к предыдущей URI-строке).
3. Wire-совместимость при подключении, если sora будет ходить в туннель сама, а не через внешний olcrtc: OLC2 record layer + OLVC v5 + handshake v3 (§5) — либо интеграцию с бинарником/библиотекой olcrtc (`pkg/olcrtc`, `mobile/`) как это делает owenclave.
4. Больше из экосистемы OpenLibre — **ничего**: ни olcng (клиент без формата), ни material/twl/rewl/pxy (протоколов не выявлено).

---

## 5. Рукопожатие и сессия: как клиент по URI устанавливает соединение

URI даёт только вход в YAML-конфиг. Дальше (всё — код olcrtc):

1. **Дефолты + валидация**: `ApplyDefaults` → `Validate` ([olcrtc] `internal/app/session/run.go:50-56`): провайдер/транспорт должны быть в реестрах, RoomID и ключ обязательны, ключ — 64 hex.
2. **Auth / сигналинг SFU**: провайдер из реестра вызывает `Issue(ctx, Config{RoomURL, Name, Token, DNS...})` и возвращает `Credentials{URL, Token, Extra}` ([olcrtc] `internal/auth/auth.go:44-70`); фабрика открывает engine-сессию по имени движка провайдера ([olcrtc] `internal/engine/builtin/builtin.go:116-170`). То есть сигналинг полностью провайдерный: jitsi — парсинг host/room без HTTP, дальше собственный Jitsi/Jingle engine (colibri-ws для datachannel); telemost — REST Yandex API → Goolom (WebRTC) engine; wbstream — REST guest/account флоу → LiveKit engine (wss). От клиента **помимо URI** нужны: display name (генерируется из встроенных словарей `internal/names`, в URI не входит), DNS (дефолт примеров `8.8.8.8:53`), для wbstream-datachannel — `auth.token`, для режима клиента — локальный SOCKS listen-адрес.
3. **Транспорт** поверх engine-сессии: datachannel — байты как есть; видео-транспорты несут данные в видеотреке: vp8channel — KCP поверх VP8-кадров; seichannel/videochannel — общий фрейм OLVC: magic `OLVC` (`0x4f4c5643`), **версия 5**, per-fragment CRC32, ack/retransmit ([olcrtc] `internal/transport/common/frame.go:43-46` и комментарий формата :10-31). Старые фреймы (маги `OVC1`/`OVV2`) отвергаются по magic/version.
4. **Шифрование (симметричное, из ключа URI)**: ключ из `#`-фрагмента URI — это **общий PSK 32 байта**, не публичный ключ и не пароль на SFU. OLC2 record layer ([olcrtc] `internal/crypto/chacha.go:1-9, 27-32, 125-163`):
   - Из PSK через **HKDF-SHA256** (salt=nil, info=label) выводятся два направленных ключа: `olcrtc/v2/client-to-server` и `olcrtc/v2/server-to-client`;
   - AEAD — **XChaCha20-Poly1305** (`chacha20poly1305.NewX`);
   - Рекорд: magic `OLC2` | counter uint64 BE | sender prefix 16 байт (случайный на KeySet) | ciphertext | tag; nonce = prefix‖counter;
   - AAD разделены для data/control: `olcrtc/muxconn/v2/data` и `olcrtc/muxconn/v2/control` ([olcrtc] `internal/muxconn/conn.go:68-69`);
   - Replay protection: окно 64 рекорда на отправителя. **Fallback на старый формат нет** — обе стороны обязаны быть совместимых сборок ([olcrtc] `docs/uri.md`, Mapping; `docs/configuration.md`, Wire compatibility).
5. **Мультиплексирование**: поверх зашифрованного транспорта — smux (data- и отдельный control-сессии, [olcrtc] `internal/tunnelcore/session.go:37-95`).
6. **Handshake на первом (control) smux-стриме** ([olcrtc] `internal/handshake/handshake.go:1-25, 32-57`): длина-префиксный (4 байта BE) JSON, `ProtoVersion = 3`; клиент шлёт `CLIENT_HELLO{version, device_id, challenge (16 случайных байт, hex), claims?}`, сервер отвечает `SERVER_WELCOME{session_id, peer_id?, challenge echo}` или `SERVER_REJECT{reason, challenge}`; challenge защищает от переадресации ответа чужому клиенту с тем же PSK. DeviceID клиент резолвит/генерирует локально ([olcrtc] `internal/client/client.go:214-235`) — в URI его нет. AuthHook сервера по умолчанию в `session/run.go` только логирует claims — содержательной проверки claims в базовом пути нет.
7. **После handshake** control-стрим остаётся открытым: `CONTROL_PING`/`CONTROL_PONG` liveness (дефолты 10s/15s/4 промаха, [olcrtc] `internal/control/control.go:28-44`), при промахах сессия smux пересобирается; трафик идёт новыми smux-стримами клиента; на клиенте наружу торчит локальный SOCKS5.

Итого для подключения помимо URI нужны: вторая сторона (srv) с **тем же** провайдером, транспортом (включая параметры), RoomID и ключом; доступность SFU провайдера из сети клиента; локальные настройки (DNS, SOCKS), display name/device id (генерируются), для wbstream-DC — аккаунтный токен модератора на обеих сторонах.

---

## 6. Расхождения дока ↔ код (критично)

**Р-1. owenclave полностью теряет payload `<...>` (самое серьёзное).** Парсер вырезает транспорт до `<` и выбрасывает блок ([owenclave] `OLCRTCFmt.kt:30-33`); в Bean полей под параметры нет (`OLCRTCBean.java:13-21` — только provider/transport/room/key/dns/socks); `toUri()` payload не эмитит (`OLCRTCFmt.kt:45-59`); `buildOlcrtcYaml` секции `vp8/sei/video` не эмитит (`V2RayInstance.kt:63-88`). Следствие: любая не-дефолтная настройка из ссылки/подписки (напр. `fps=60&batch=64&frag=900&ack-ms=2000` из примера sub.md) при импорте в owenclave молча заменяется дефолтами olcrtc. Если параметры сервера отличаются от дефолтов — туннель не встанет или встанет не тот. **Для sora: payload парсить и хранить обязательно, owenclave как референс полноты использовать нельзя.**

**Р-2. Кодировка полей: три несовместимых практики при отсутствии правила в спеке.** Дока отдаёт escaping на откуп клиенту ([olcrtc] `docs/uri.md:118`); примеры доки и `install.sh:603` эмитят всё сырьём (пробелы, `/`, `://` в RoomID/MIMO); owenclave на чтении делает `URLDecoder.decode` (Provider/Transport/RoomID/MIMO, не ключ), а на записи — `URLEncoder.encode` тех же полей (`OLCRTCFmt.kt:12,37-39,47-56`). Практические следствия: (а) ссылка, сгенерированная owenclave для jitsi, содержит RoomID вида `https%3A%2F%2Fmeet.example.org%2Fmyroom` — клиент, не делающий decode, по ней не подключится; (б) сырая ссылка из доки, где MIMO содержит `+` или `%XX`, при чтении owenclave будет молча переиначена (`+`→пробел); (в) `URLEncoder` кодирует пробел как `+`, а не `%20`.

**Р-3. Парсер owenclave режет по первому вхождению разделителя в фиксированном порядке `$`→`#`→`@`→`?`** (`OLCRTCFmt.kt:11,16,23,28`). Любой из этих символов внутри RoomID (напр. `@` в URL комнаты, `#`/`$` в ID у telemost/wbstream) ломает все последующие поля. Дока лишь «рекомендует» не использовать разделители внутри полей ([olcrtc] `docs/uri.md:118`), жёсткого запрета/экранирования нет — формат в этом месте недоопределён, а jitsi RoomID при этом *обязан* содержать `:` и `/`.

**Р-4. Подписка: owenclave формат sub.md не реализует.** В [owenclave] `app/src/main/java/io/nekohasekai/sagernet/group/RawUpdater.kt:291-340` (`parseRaw`) нет ни одного упоминания `#name:`/`##`: порядок попыток — Clash YAML (`proxies:`) → JSON-конфиги → `parseShareLinks(text.decodeBase64())` (:320) → `parseShareLinks(text)` plain → WireGuard. Итог по sub.md-файлу: URI-строки вытянутся generic-парсером (`Formats.kt:141-145`), но **все `#`-метаданные и все `##`-блоки игнорируются**: `##name:` не переименует сервер (имя берётся только из `$MIMO`), `#refresh/#used/#available/#update` не применяются. Обратно: base64-обёртка, которой в спеке подписки нет, owenclave фактически примет (generic fallback `decodeBase64`, `Formats.kt:50-61` — MIME/UrlSafe/standard автоопределение). Для sora: ориентироваться на доку sub.md, а не на поведение owenclave; base64 — принимать как толерантность, не как норму формата.

**Р-5. Дефолты транспортов расходятся в трёх слоях (дока / session / transport / install.sh).**

| Параметр | docs/settings.md (таблица) | session defaults (реальный YAML-путь) | transport `withDefaults` (прямое построение) | install.sh / fast.md |
|---|---|---|---|---|
| vp8 fps / batch | 30 / 64 | 30 / 64 | 30 / 64 | **25 / 1** (`install.sh:355,406-410`; `docs/fast.md:186-187`) |
| sei fps | 30 (рекоменд.) | 30 | 30 | **60** (`install.sh:356,417-418`; `docs/fast.md:195`) |
| sei ack-ms | 2000 | 2000 | **3000** (`internal/transport/seichannel/transport.go:29` `defaultAckTimeout = 3s`; `options.go:29-31` — подставляется именно он, если Options собраны в обход session) | 2000 |
| video width (qrcode) | дефолт 1920, но «Recommended: width: 1080» в той же доке (`docs/settings.md:176` против таблицы :182) | 1920 | 1920 | 1920 |
| video qr_size | 0 = auto | 0 (не дефолтится) | **256** (`internal/transport/videochannel/transport.go:29`, `options.go:42-44`) | 0 |
| video tile_module | (таблица без дефолта, диапазон 1..270) | не дефолтится (0) | 4 | 4 |
| video tile_rs | **0** | 0 | 0 как валидный выбор; отрицательный → **20** (`options.go:48-52`) | **20** (`install.sh:354,378-379`) |

Для sora нормативным считать session-слой + таблицу settings.md; значения install.sh — это *выборы скрипта для новых серверов*, и именно они попадают в генерируемые им URI (поэтому в живых подписках `vp8-fps=25&vp8-batch=1` и `fps=60` у sei — норма, а не ошибка).

**Р-6. URI — неполное подмножество конфигурации, дока этого не оговаривает (кроме `data`).** Провайдер `none` с `engine.name/url/token`, поле `auth.token` (без него wbstream+datachannel из подписки **неработоспособен** в guest flow), `room.channel`, DNS, SOCKS, liveness/traffic/failover в URI не выражаются. Подписка, содержащая `wbstream?datachannel` без токена, заведомо битая для guest — дока sub.md это честно показывает в `##comment` примера, но в грамматику ограничение не вынесено.

**Р-7. Ключ: дока мягче кода.** «usually 64 chars» ([olcrtc] `docs/uri.md`, Fields) против жёстких ровно-64-hex в валидации ([olcrtc] `internal/app/session/validate.go:101-107`) и в `install.sh:97-104`. Ключи иной длины (напр. base64 32 байт = 44 символа) форматом не поддерживаются, хотя дока словом «usually» это допускает в чтении.

**Р-8. owenclave: дефолт транспорта только при отсутствии `?`, валидации нет.** `olcrtc://jitsi@room#key` (без `?transport`) даст transport=`datachannel` (`OLCRTCFmt.kt:34`), а `olcrtc://jitsi?@room#key` даст transport=`""`, который Bean-дефолт не починит (не null) и который уедет в YAML как есть. Аналогично пустой Provider при `olcrtc://?datachannel@...`. olcrtc такой конфиг отвергнет уже при старте — то есть ошибка проявляется поздно и не в клиенте подписки.

**Р-9. Имя сервера: три источника с неописанным приоритетом.** `$MIMO` в URI, `##name:` в подписке, `displayName()` Bean (`name`, иначе `olcrtc/<provider>`, `OLCRTCBean.java:62-65`). Дока приоритета `##name` vs MIMO не задаёт; owenclave фактически всегда берёт MIMO (Р-4). Для sora принять: `##name:` выше MIMO (по смыслу sub.md `##name` — именно «Server/node name»).

**Р-10 (мелкое).** `docs/fast.md` в примере результата печатает ключ с многоточием (`...4799...`), а install.sh печатает полный; на парсинг не влияет. В `docs/sub.md:166-168` owenclave назван главным клиентом формата — при том что Р-1/Р-4 показывают: реализует он формат частично.

---

## 7. Что публично НЕ специфицировано (честный список)

1. **Единое правило escaping/percent-encoding полей URI.** Спека прямо перекладывает его на клиента ([olcrtc] `docs/uri.md:118`); на практике существуют минимум две несовместимые практики (сырьё у install.sh/доки, form-encoding у owenclave).
2. **Поведение при разделителях внутри полей** — только рекомендация «не использовать», без запрета, экранирования или правила «последнее/первое вхождение».
3. **Допустимые символы и длина RoomID / MIMO**, Unicode в MIMO (эмодзи в примерах есть только в `#icon:`/`##icon:` подписки), нормализация регистра Provider/Transport (код сравнивает точные строки реестров; owenclave сверяет схему case-insensitive, имена — нет).
4. **Приоритет `##name:` против `$MIMO`**, поведение при `##`-блоке до первой URI-строки, при дублях `#`-полей, при неизвестных `#`/`##` ключах, при строках-комментариях вне схемы — в sub.md не определено.
5. **Транспорт подписки**: HTTP-заголовки, кэширование, авторизация при fetch, обработка редиректов, кодировка файла (UTF-8 подразумевается примерами с эмодзи, но не заявлена), лимиты размера — не специфицированы.
6. **Семантика `#refresh:`** (минимум/максимум, поведение при отсутствии, единицы кроме примеров `5s/10m/6h/1d`; `1d` Go-duration не является — клиент-обязанность) и `#update:` при расхождении часов.
7. **Формат `#used:`/`#available:`** сверх примеров и списка юнитов: разделитель, пробелы, десятичные разделители, отрицательные/превышенные значения не определены.
8. **Провайдерные API как публичный протокол**: REST-флоу telemost (`cloud-api.yandex.ru/telemost_front`) и wbstream (guest register/join/getToken), Jitsi/Jingle-детали engine, Goolom-сигналинг — существуют только как код (`internal/auth/*`, `internal/engine/*`), отдельной спеки нет; любой внешний клиент вынужден читать код.
9. **Handshake claims**: состав `claims` в `CLIENT_HELLO`, семантика серверного AuthHook и device_id (формат, приватность, ротация) публично не специфицированы — только код.
10. **Совместимость версий вперёд**: как клиент обязан вести себя при URI/подписке «v2», при неизвестном провайдере/транспорте/ключе payload — не определено (нет in-band version и нет правила игнорирования неизвестного; owenclave неизвестные payload-ключи теряет молча вместе со всеми остальными).
11. **twl / rewl / pxy**: в клонированных первоисточниках не упомянуты; публичной спеки/формата ссылок по ним в рамках этого исследования не найдено — утверждение «не протоколы» в §4.2 сделано по отсутствию свидетельств, а не по положительному подтверждению.
12. **QR-формат ссылок**: install.sh рисует QR из URI сторонним бинарником `gr`, но QR как канал распространения в uri.md/sub.md не специфицирован.
