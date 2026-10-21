# CENSOR-LEAK E1 — фикс: Xray DNS `+local` (несогласованная семантика резолверов)

Фиксер эскалации E1 отдела CENSOR-LEAK (подтверждена двумя независимыми
ревью: CENSOR-LEAK.md §2 и CENSOR-LEAK-REVIEW.md §5). Ветка
`bugfix/audit-2026-10-19`, репозиторий `~/workspace/bug-hunt/sora`.
Режим: строго локально, пуша не было.

**Коммит: `f8370738`** (`[censor] CENSOR-LEAK E1 fix: …`), родитель
`79803f49`. Состав: `core/engine/xray/render.go` (только функция `dns()`)
+ новый `core/engine/xray/dns_render_test.go`. Больше ничего.

## 1. Правильная семантика — по факту, а не по предположению

### Что значит `+local` в Xray 26.10.17 (пин проекта)

По официальной документации Xray (Built-in DNS Server, xtls.github.io):
`tcp+local://` = TCPL, `https+local://` = DOHL, `quic+local://` = DOQL —
во всех трёх случаях запрос **не проходит через компонент маршрутизации**,
а уходит напрямую через Freedom outbound. Общее правило (TIP 4 документации):
«The DNS server enters the routing system for matching by default unless it
contains `+local`». Без `+local` запрос — routed: его ведёт финальное правило
плана (в типовом плане sora — MatchAll → Proxy, т.е. туннель; «routed» не
равно «гарантированно через туннель», если сам план финалом ставит direct —
это уже выбор плана, а не рендера).

Подтверждено живым щупом на самом бинаре пина
(`~/workspace/.engines-amd64/xray`, Xray 26.10.17): резолвер
`127.0.0.1:15354`, правило маршрутизации `ip 127.0.0.1/32 → blackhole`,
триггер — резолв `example.com` через freedom `domainStrategy: UseIP`:

| Спеллинг | Правило-block: пакет у слушателя | Без правила: пакет | Вывод |
|---|---|---|---|
| `tcp://` | нет | да (DNS-over-TCP фрейм) | routed |
| `tcp+local://` | **да** | да | direct, роутинг обойдён |
| `https://…/dns-query` | нет | да (TLS ClientHello) | routed |
| `https+local://…` | **да** | да | direct, роутинг обойдён |
| `quic+local://` | (лог: клиент «Local DNS-over-QUIC», диспетчер: `from DNS accepted … [local]`) | — | direct по построению |

### Таблица «тип резолвера × движок × routed/direct» ДО фикса

| Тип | sing-box | mihomo | Xray до фикса |
|---|---|---|---|
| system | `type: local` (системный) | `system` в system-бакете | `localhost` (системный) |
| plain (udp) | без detour → dial по default route (**routed**) | Nameserver-бакет (direct-диал, `#outbound` только из `Dialer`) | голый адрес → **routed** |
| tcp | то же, routed | то же | `tcp+local` при !ProxyOnly → **direct**; routed при ProxyOnly |
| tls (DoT) | то же, routed | то же | `tls://` без `+local` → формально routed (но см. §3: DoT на пине нет) |
| https (DoH) | то же, routed | то же | `https+local` при !ProxyOnly → **direct**; routed при ProxyOnly |
| h3 (DoH3) | `type: h3`, routed | `https…?h3=true` | честная ошибка рендера (DoH3 в Xray нет) |
| quic (DoQ) | то же, routed | `quic://` в Nameserver | **`quic+local` всегда** (переменная `local` в коде вообще игнорировалась — даже ProxyOnly получал direct) |
| ProxyOnly (любой тип) | `detour = proxyFinal()` — явно через прокси-финал | proxy-server-nameserver | routed (кроме quic — см. выше) |

Ключевые факты по соседям (по коду): sing-box — `detour` ставится **только**
ProxyOnly-резолверам (`singbox/render.go`, `server.set("detour",
r.proxyFinal())`); сервер без detour диалится по default route движка
(route.final плана) — то есть **инвариант sora: DNS следует маршруту плана;
direct — не дефолт рендера, а следствие правил плана**. mihomo — расходится
в другую сторону: не-ProxyOnly резолверы падают в `Nameserver`/`direct`-
бакеты и диалятся движком напрямую (для DoH/DoT/DoQ — зашифрованно, но мимо
туннеля; `mihomo/rules.go` `buildDNS`); это зафиксировано как остаточное
расхождение в §5, фикс E1 по мандату — только Xray.

Итог дефекта: пользовательский план по умолчанию (`control/plan.go`
`dnsFromProto` не ставит ProxyOnly никому; дефолтные TUN-резолверы —
`https://1.1.1.1`, `https://8.8.8.8`) на Xray получал DoH **мимо туннеля**
прямым Freedom-диалом, тогда как тот же план на sing-box шёл по маршруту.

## 2. Фикс

В `dns()` (`core/engine/xray/render.go`) удалена переменная `local` и вся
ветка с `+local` для обычных резолверов:

- `DNSTCP`: `tcp+local://` → **`tcp://`** (routed) при !ProxyOnly; при
  ProxyOnly было `tcp://` — байт-в-байт как раньше.
- `DNSHTTPS`: `https+local://` → **`https://`** (routed) при !ProxyOnly;
  ProxyOnly — без изменений.
- `DNSPlain`, `DNSTLS`, `DNSSystem`: рендер не изменён (были routed).
- Никаких изменений семантики для планов, которые и так были routed:
  все ProxyOnly-резолверы и все plain/tls/system рендерятся идентично
  до/после. Меняется только класс, который уходил direct вопреки плану:
  tcp/https при !ProxyOnly.

Комментарий функции переписан: инвариант, почему `+local` запрещён обычному
резолверу, и оба исключения пина (ниже) — с обоснованием в коде, а не молча.

### Исключение пина, сохранённое осознанно: DoQ

`DNSQUIC` оставлен `quic+local://` для обоих значений ProxyOnly (поведение
не изменилось — так было и до фикса). Причина доказана на бинаре, а не
предположена: **routed DoQ в Xray 26.10.17 не существует**. Документация
знает только `quic+local://` (DOQL); фабрика имён серверов пина для
`quic://` без `+local` падает в classic-UDP клиент, чей адрес назначения —
литеральная строка `quic://…` (лог пина: `created UDP client initialized
for quic://127.0.0.1:15355:53`, далее попытка резолвить «хост»
`quic://127.0.0.1:15355`). Замена на `quic://` обменяла бы рабочий
(зашифрованный, хоть и direct) DoQ на молча битый DNS — это не routed DoQ.
Исключение запинено тестом таблицы и комментарием в коде. Снятие
исключения — когда пин научится routed DoQ, либо продуктовым решением
(step-down quic→https для Xray по образцу существующего h3→https в
bridge/registry — чужая зона, в этот фикс не входит).

## 3. Смежные доказанные находки (НЕ чинились — эскалации координатору)

1. **E1-DoT: у пина нет DNS-over-TLS вообще.** Та же фабрика проглатывает
   `tls://`: лог — `created UDP client initialized for tls://…:53`, запрос
   уходит как classic-UDP на литеральный «хост» `tls://host:port`. Текущий
   рендер DNSTLS в Xray — не DoT, а молча деградировавший UDP. В фикс E1
   не вошло сознательно: честная ошибка рендера (по образцу h3) ломает
   все DoT-планы на Xray и 12+ тест-файлов на `enginetest.Plan` (он несёт
   DNSTLS-сервер), а step-down/выделенный outbound — решение уровня
   bridge/registry и владельца, как это уже было с h3. Спеллинг оставлен
   без `+local` и запинен тестом с пометкой; нужно отдельное решение:
   step-down tls→https для Xray-кандидата, либо выделенный DoT-outbound,
   либо честный отказ.
2. **E1-plain-port: голый `IP:port` пин отклоняет.** `dnsFromProto`
   проксирует пользовательский порт в `DNSServer.Port`; plain-рендер даёт
   `8.8.8.8:53` — бинарь: `Failed to start … parse "8.8.8.8:53": first
   path segment in URL cannot contain colon` (rc=23), хотя документация
   форму обещает. `udp://` — не выход (та же литеральная деградация).
   Корректная форма на пине — объектный сервер `{address, port}`; рендер
   sora эмитит только строки. Дефект предсуществующий, класс — «рендер
   отклоняется бинарём при старте» (fail-closed, не leak), в мандат E1
   не входил.
3. Xray-рендер игнорирует `DNSServer.Dialer` и `SkipVerify` (mihomo и
   sing-box их рендерят). Зафиксировано без изменений: `Dialer` также
   игнорирует sing-box, т.е. единого инварианта тут пока нет.

## 4. Тесты и верификация

Новые тесты (`core/engine/xray/dns_render_test.go`):

- `TestRenderDNSResolverTable` — таблица: 7 кейсов транспортов
  (system/plain/plain-без-типа/tcp/tls/https/quic) × ProxyOnly on/off,
  точные ожидаемые строки + запрет `+local` вне DoQ-исключения пина.
- `TestBinaryAcceptsDNSResolverTable` — один рендер со всеми
  транспортами в обоих ProxyOnly-состояниях, приёмка
  `xray run -test` на пине (гейт `SORA_XRAY_BIN`/`SORA_ENGINES_DIR`,
  как принято в пакете). Прогон с `SORA_ENGINES_DIR=~/workspace/.engines-amd64`:
  PASS (0.40 с).

Регрессия (имена DNS-тестов поименно — все PASS): xray —
`TestRenderDNSResolverTable`, `TestRenderRejectsDoH3WithGuidance`;
sing-box — `TestRenderDNSIPv6Strategy`, `TestRenderDNSH3UsesTypeH3`,
`TestDNSSkipVerifyRendersInsecureTLS`; mihomo —
`TestDNSUsesTheRequestedTransportAndOutbound`, `TestDNSH3ForcesHTTP3`,
`TestDNSSkipVerifyAppendsCertParam`, `TestRenderRefusesTunWithoutDNS`,
`TestTunUsesSeparateAddressesEvenWithoutFakeDNS`.

Прогоны:

- Ворктри (с чужой сессией): `go test ./engine/xray/ ./engine/` — ok/ok;
  `./engine/singbox/ ./engine/mihomo/` — ok/ok; `go vet ./engine/xray/` —
  чисто; gofmt по тронутым файлам — чисто.
- Чистый экспорт коммита `f8370738` (`git archive`): `go test
  ./engine/xray/` — **ok** (включая бинарную приёмку с env); vet — чисто;
  gofmt по моим файлам — чисто.
- **Чужое падение (не чинил, перечисляю):** на чистом экспорте
  `go test ./engine/` падает `TestCatalogXmuxClaimMatchesRenderers`
  (`engine_test.go:475,492` — xmux-клейм Xray). Падение **идентично на
  чистом экспорте родителя `79803f49`** без моего коммита: это in-flight
  работа соседней сессии (вторая половина живёт в её грязном ворктри; в
  самом ворктри `./engine/` зелёный). Там же предсуществует
  `gofmt -l`: `engine/xray/engine_test.go` (на родителе — тоже).

## 5. Дисциплина дерева

- Чужие незакоммиченные ханки в `core/engine/xray/render.go` изучены до
  работы: три ханка — `stream()` tcp/grpc (снятие CENSOR-P2 backstop'ов)
  и пустая строка в `xhttpDownloadSettings`. **С DNS-регионом не
  пересекаются** — стоп-условие мандата не сработало, работа выполнена.
- Коммит собран temp-index + CAS по рецепту AGENTS.md: патч извлечён из
  `git diff HEAD` без экспортированного `GIT_INDEX_FILE`, отфильтрован
  по телу ханков (prefix-stripped) — в коммит попали только 2 моих ханка
  из 5; `git diff --cached --stat` перед `write-tree`:
  `dns_render_test.go +114`, `render.go +38/−8` — только мои файлы.
  CAS `update-ref` с old-value сработал с первой попытки на `79803f49`.
- **Эпизод отравления индекса (зафиксирован по мандату):** сразу после
  коммита общий staged содержал откат ровно моего коммита: staged-блоб
  `render.go` = `ddc3bd2a52eaf025819bded7e2f24b67c2feb638` (блоб
  родителя; коммит несёт `f1bb3528`) и staged-удаление
  `dns_render_test.go` (numstat `0 114`). Нейтрализовано только по моим
  путям: `git restore --staged -- core/engine/xray/render.go
  core/engine/xray/dns_render_test.go`.
  После нейтрализации staged пуст, HEAD `f8370738` цел, чужие ворктри-
  изменения не тронуты (в `git diff HEAD -- render.go` остались только
  три чужих ханка).
