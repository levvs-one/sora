# PASS3-TRANSPORT — транспортный отдел, проход 3/3

Дата: 2026-10-20. Проект: sora (`~/workspace/bug-hunt/sora`, ветка
`bugfix/audit-2026-10-19`, пуша нет). Зона: только `core/engine`
(+ его тесты). Вне зоны ничего не тронуто; решения владельца
(Xray-бамп, lx-бамп) не реализовывались.

База: PASS3-DEEP-RESEARCH.md (S2, S3, S4, A1, A2, A4, A5-остаток,
A6), WEB-RESEARCH-5 Tier A2 (противоречие AWG3-матрицы mihomo),
PASS2-DEEP-RESEARCH S1/A1 (mihomo AWG 3.x по исходнику пина,
семантика `disable_cookies` у lx). Первоисточники, перепроверенные
в этом проходе по докам: wiki.metacubex.one — transport
configuration (xhttp-opts целиком: reuse-settings, download-settings,
x-padding-bytes, список режимов) и TLS configuration
(reality-opts / ech-opts); xtls.github.io — VLESS outbound
(комбинации XTLS).

Итог: 8 коммитов `[pass3-transport]`, после каждого — `go build
./engine/...` + `go vet ./engine/...` + тесты engine (TMPDIR/GOCACHE
по регламенту). Финальная верификация: `go build ./...` по всему
core, vet и полный набор `./engine/...` — зелёные.

| Коммит | Пункт |
|---|---|
| `2146dc7b` | S3 Vision |
| `d7157da8` | S4 ECH |
| `3fcab572` | S2 mihomo REALITY ML-KEM |
| `29dccbc0` | A1 mihomo XHTTP |
| `31f88b78` | A4 Xray XHTTP headers + A2 SpiderX warning |
| `73fcdaed` | AWG3-матрица mihomo |
| `c5215627` | A5-остаток sing-box http_clients |
| `c0e8b037` | A6 Xray NameserverPolicy gate |

---

## 1. S3 Vision — СДЕЛАНО

**S3а (mux+vision).** Посылка «у sing-box/mihomo vision нет» была
ложна, и предикат это отражал: sing-box эмитил `multiplex` +
`flow: xtls-rprx-vision` одновременно, mihomo — `smux` + `flow`.
`engine.RealityMux` теперь сам flow-aware (`!IsVisionFlow(o.Flow)`,
оба варианта vision), поэтому ни один рендерер не может вернуть
пару mux+vision, забыв собственный guard; guard в Xray-рендерере
упрощён до одного предиката. Комментарии в mux.go, singbox/render.go,
mihomo/proxy.go, xray/render.go переписаны по факту движков («vision
есть у всех трёх; mux под ним не применяем нигде»).
`ApplyAutoVision` не тронут (по спеке).

Тесты: новая матрица предиката (`mux_test.go`: vision и
vision-udp443 режут mux, без flow — дефолт жив); mihomo
`buildProxy` (vision → нет smux, flow рендерится); sing-box —
существовавший `TestRenderMultiplexDefaultsToReality` ПИНИЛ
mux+vision (enginetest VLESS = reality+vision) и перестроен:
vision-план — нет multiplex, flow рендерится; flow снят — T007
дефолт возвращается.

**S3б (запрет flow на не-TCP).** По докам XTLS: XTLS доступен при
TCP+TLS/REALITY **или** при VLESS Encryption без ограничений на
транспорт. Добавлен `Outbound.HasVLESSEncryption()` (непустая
строка, не `"none"`); `validate.go` (validateXHTTP) и
`xray/checkStreamCompat` разрешают flow на не-TCP ровно при нём.
REALITY+xhttp+vision без Encryption по-прежнему отказано на обоих
слоях; warning `reality-xhttp-vision` больше не срабатывает на
легальной зашифрованной комбинации (при REALITY без Encryption —
срабатывает, как раньше).

Тесты: матрица validateXHTTP (encryption → ок; `"none"` → отказ;
REALITY без Encryption → отказ), xray render принимает
encryption+xhttp+vision и encryption+grpc+vision (существующие
отказы xhttp+vision / grpc+vision без encryption сохранены).

Проверка на бинаре (остаётся dev-машине, не блокирует фикс):
`xray run -test` на пине 26.3.27 для связок (1) vlessenc+xhttp+vision
— принимается; (2) reality+xhttp+vision — фактический ответ пина как
регрессионный ориентир. Поведение пары mux+vision на пине sing-box
больше не релевантно: мы её не эмитим ни при каких условиях.

## 2. S4 ECH — СДЕЛАНО (рендер mihomo + честность Xray) + СПЕКА (рендер Xray)

**mihomo.** Вместо плоского `ech: true` рендерится
`ech-opts: {enable, config, query-server-name}` по докам пина.
Pinned config конвертируется из PEM-строк плана в одну base64-строку
mihomo (армор снимается, тело проверяется как base64 и
перекодируется). Два PEM-блока (два полных ECHConfigList) в одно
значение mihomo не склеиваются принципиально — рендер отказывает;
не-base64 — тоже отказывает. Тесты: toggle, pinned+query-server-name
(армор не утекает в YAML), отказ на двух блоках и на мусоре,
отсутствие блока по умолчанию.

**Валидатор.** Запрет `QueryServerName` («not rendered yet, needs
sing-box >= 1.13») снят целиком: sing-box его рендерит (пол пинов
1.14.3), mihomo теперь тоже. Регрессионный тест заменён на
приёмочный.

**Xray — честный отказ вместо молчания (рендер — спека ниже).**
Новый `FeatureECH`: `RequiredFeatures` ставит его при любом
ECH-outbound; sing-box и mihomo заявляют, Xray — сознательно нет
(комментарий в catalog.go), и Xray-рендерер дополнительно отказывает
на ECH-outbound именованной ошибкой. Раньше план уходил на Xray и
SNI шёл открытым без единого сигнала.

**Спека рендера Xray (почему не код).** Xray ECH умеет
(`echConfigList`, `echForceQuery`: none/half/full), но формат
`echConfigList`, который ждёт пин 26.3.27, в этом проходе не
подтверждён: план хранит PEM-строки (форма sing-box), Xray по
вторичным источникам принимает base64 ECHConfigList, а также
особые формы (DNS-имя/URL) — угадывание здесь = риск молча
неработающего ECH вместо честного отказа. Проверка на dev-машине:
(1) `xray tls ech` на пине — получить эталонную пару и её форму;
(2) `xray run -test` с `echConfigList` в обеих формах (PEM-текст и
base64 сырого ECHConfigList из тех же байтов); (3) захват: outer
SNI ≠ inner при включённом ECH. Семантика на будущее, когда формат
подтвердится: pinned config → `echConfigList` из `ECH.Config` +
`echForceQuery: none`; конфиг из DNS → `full` (или `half` — по
семантике пина, зафиксировать по итогам п. 2). Гейт FeatureECH
снимается тем же коммитом, что и проверенный рендер. Отдельная
проверка там же: `mihomo -t` с ech-opts + pinned config.

## 3. S2 mihomo REALITY ML-KEM — СДЕЛАНО

Семантика подтверждена доками пина (TLS configuration):
`reality-opts.support-x25519mlkem768` существует. В план добавлена
общая ручка PASS2 S3 — `TLS.KeyShare` (`""`/`classical`/`hybrid`),
с валидацией: неизвестное значение — ошибка плана; KeyShare без
REALITY — ошибка плана. Mihomo рендерит: hybrid →
`support-x25519mlkem768: true`, classical → `false` **явно**
(поле-указатель, false не испаряется из YAML), unset — ключ
отсутствует.

Дефолт честно помечен на самом поле плана: подтверждён ли дефолт
mihomo по исходнику пина — **нет** (доки показывают только явный
`true` в примере); `""` означает «дефолт движка, не проверено», а
не обещание гибрида. Тест гейтит все три написания рендера +
валидацию.

Остаток по теме (не этот пункт): sing-box-lx рендер той же ручки
(`key_share`) — PASS2 S3 в силе; поле плана для него теперь есть,
рендерер lx не подключён, потому что точное имя/значения поля у lx
требуют сверки с докам/бинарём lx, а не догадки. Проверка на бинаре:
захват ClientHello mihomo 1.19.32 с флагом и без (X25519MLKEM768 в
supported_groups/key_share) и живой коннект к Xray ≥ 26.9.8 REALITY.

## 4. A1 mihomo XHTTP — СДЕЛАНО + СПЕКА (подъём каталога)

По докам пина (transport configuration, прочитаны целиком):
- `reuse-settings` рендерится **всегда**: у mihomo у этой опции нет
  дефолта — без блока переиспользование выключено, каждый запрос =
  новое соединение (самая дорогая и заметная картина). Из плана —
  max-concurrency / max-connections / c-max-reuse-times /
  h-max-request-times (строки-диапазоны по докам; полей плана под
  h-max-reusable-secs и h-keep-alive-period нет — остаются
  неустановленными). При пустом тюнинге — дефолт из примера доков
  `max-concurrency: "16-32"`; на настроенный план дефолт не
  навешивается (max-concurrency конфликтует с max-connections).
- `download-settings` — `{server, port, свой reuse-settings}`;
  неустановленное наследует uplink по докам, поэтому path/host не
  дублируются.
- `x-padding-bytes` — из `XPaddingBytes` плана дословно (сервер
  проверяет диапазон).
- **`mode: auto` — подпункт закрыт доками, не догадкой:** текст
  доков — «Mode. Available values: `auto`, `stream-one`,
  `stream-up`, or `packet-up`». `auto` легален для mihomo и
  проходит в YAML как есть; тест пинит дословный рендер.

Тесты: дефолтный reuse (и именно 16-32), настроенный reuse без
утечки дефолтной concurrency, x-padding, download-settings,
mode: auto.

**Спека подъёма каталога (почему не в этом коммите).** По спеке A1
претензии mihomo на `FeatureXHTTPXmux`/`FeatureXHTTPDownloadSplit`
даются только после `mihomo -t`. На этой VM бинаря нет, поэтому
претензий не добавлено; комментарии catalog.go / engine.go /
plan.go и тест `TestCatalogXmuxClaimMatchesRenderers` обновлены
под промежуточную правду («рендер есть, претензия ждёт -t»).
Dev-машина: `mihomo -t` на рендерах reuse-settings /
download-settings / x-padding-bytes (тестовые планы — в
render_test.go mihomo), счётчик соединений на XHTTP-сервере
до/после; одним коммитом с успешной проверкой — обе претензии в
`Catalog[KindMihomo]`.

## 5. A4 Xray XHTTP headers + A2 SpiderX — СДЕЛАНО

**A4.** Xray был единственным из трёх рендереров, ронявшим
`headers` у XHTTP. Теперь `xhttpSettings.headers` ставится при
непустых заголовках плана (пустые — ключ отсутствует, не `{}`).
Тест парсит рендер в обе стороны. Паритет базового набора
(host/path/mode/headers) по трём рендерерам теперь: sing-box —
host/path/mode/headers, mihomo — то же (+п. 4), Xray — то же.

**A2 (тот же класс честности).** `TLS.SpiderX` рендерит только
Xray. У sing-box поля в клиентской REALITY-схеме нет в принципе,
у mihomo в доковой `reality-opts` его нет (наличие в пине не
подтверждено). Вместо молчаливой потери `RealityWarnings` теперь
даёт код `reality-spiderx-xray-only` при установленном SpiderX
(предупреждение, не блок — по аналогии с существующими
RealityWarnings). Тест: ставится/снимается вместе с полем.
Проверка на dev-машине: grep исходника пина mihomo 1.19.32 по
`spider` в reality-пути и `mihomo -t` с `reality-opts.spider-x` —
если поле есть, предупреждение для mihomo заменяется рендером.

## 6. AWG3-матрица mihomo — СДЕЛАНО (врёт тест, не capability)

Противоречие разрешено по первоисточнику пина (PASS2 S1 читал
исходник 1.19.32 построчно; WEB-RESEARCH-5 Tier A2 — релизы):
mihomo несёт AWG 3.0/3.1 с **1.19.30** (`feat: support AmneziaWG
v3.0/v3.1`), 1.19.31 чинит DisableCookies/RandomPadding для v3;
`AmneziaWGOption` пина содержит `version`, `header-protection-key`,
`content-padding-addition`, ranged-тайминги, `random-trailers`,
`disable-cookies`. Врал наш тест и рендерер.

- `BuildCapabilities`: mihomo ≥ 1.19.30 получает
  `FeatureAmneziaWG3` (карта фич клонируется — общий каталог не
  мутируется; неизвестная/нулевая версия — закрыто, fail closed).
- `amneziaOptions`: отказ на 3.1 снят; рендерятся все 3.x-ключи
  kebab-именами пина + **обязательный `version: 3`** (без него
  mihomo строит legacy-устройство и поля молча не применяются —
  та самая ловушка, от которой защищал старый отказ).
- Границы честности сохранены отказами рендера: сахар id/ip/ib в
  mihomo отсутствует (гейт `FeatureAmneziaMasquerade` не тронут,
  остаётся lx-only) и v1.5-only J1/J2/J3/Itime несовместимы с
  version 3 (PASS2 S1 п. 4).
- `disable_cookies`: комментарий плана исправлен — спека говорит
  «только не шлёт», движки читают шире (lx: «never send **or
  demand**»); честная формулировка теперь в plan.go (клиентская
  ручка, на совместимость не влияет) — PASS2 A1.
- Тесты: `d24_awg3_test.go` переписан в версионную матрицу
  (1.19.29 — miss; 1.19.30 и пин 1.19.32 — carry; каталог не
  загрязнён; селект предпочитает пин-mihomo и откатывается на lx
  при старом билде; masquerade miss даже на пине). Mihomo
  render-тест: полный 3.1-вектор → YAML с `version: 3` и всеми
  девятью 3.x-ключами; masquerade и 3.x+J1 — отказы; 2.0 рендерится
  как раньше, без ключа version.

Остаётся dev-машине: `mihomo -t` на отрендеренном v3-конфиге и
проводной интероп-тест (пакет на проводе) — рендер доказан по
докам/исходнику пина, не по бинарю.

## 7. A5-остаток — СДЕЛАНО

`route()` sing-box рендерил `http_clients` только при непустом
detour; direct-only план с remote rule-set'ами жил на implicit
default HTTP client, который 1.16 удаляет. Теперь клиент рендерится
при любых remote rule-set'ах: с detour — как раньше, без прокси —
явный direct-клиент (только tag), `default_http_client` всегда на
него указывает. Тест, пинивший отсутствие клиента, переписан на
явный direct-клиент. Проверка на dev-машине: `sing-box check` на
tag-only клиенте пина lx.14.

## 8. A6 Xray NameserverPolicy — СДЕЛАНО (честный гейт) + СПЕКА (рендер)

Xray-рендер DNS политику не читал, гейта не было: split-DNS план
молча уезжал на Xray и «direct»-домены резолвились туннельным
резолвером. `MissingFor` для Xray теперь возвращает `DNS
nameserver policy (split DNS)` при непустой политике (sing-box и
mihomo её рендерят и не репортят — тест пинит все три стороны).

**Спека полного фикса.** Xray DNS server-объекты поддерживают
`domains`: политику маппить в серверы вида
`{address: <сервер политики в Xray-нотации>, domains:
["domain:<суффикс>"]}` (ключи `+.ru`/`*.ru`/голый домен → суффикс
без префикса). Подводные камни, из-за которых это не сделано
вслепую: нотация адреса зависит от транспорта исходного DNSServer
плана, а политика ссылается на адреса, а не на теги — соответствие
адрес→транспорт надо восстанавливать из `DNS.Servers`, как это
делает sing-box (`byAddress`). Проверка: `xray run -test` с
dns.servers[]-объектами с `domains` на пине + поведенческий тест
(домен из политики уходит на свой сервер). Гейт снимается тем же
коммитом, что и проверенный рендер.

---

## Инциденты

1. **Рассинхрон общего реального индекса (главный).** После
   коммитов S3/S4 (моих, через temp-index + commit-tree) и
   соседних commit-tree коммитов реальный индекс ветки содержал
   staged-удаления 76 файлов: мои engine-изменения S3/S4/S2 +
   чужие F3 (l10n/*.dart, ui/dns.dart) — индекс просто остался на
   старом дереве, а HEAD ушёл вперёд. Bare-`git commit` любого
   агента в этот момент закоммитил бы массовый реверт. Проверка
   перед действием: `git diff HEAD` — пуст (worktree == HEAD
   точно), index↔HEAD и worktree↔index — зеркальные пары, т.е.
   подлинно staged чужой работы в индексе не было. Действие:
   `git restore --staged .` — индекс выровнен по HEAD, worktree не
   тронут. После следующих своих коммитов выравнивал индекс
   точечно (`git restore --staged -- <мои пути>`).
2. **Живая чужая staged-работа (не трогал).** После коммита A1 в
   индексе появились staged-удаления в `app/lib/src/ext/*`,
   `core/ext/*`, `docs/`, `tools/` со статусом MM — это текущая
   работа агента pass3-ext, а не артефакт. Оставлены как есть;
   фиксирую здесь, потому что bare-коммит в этом окне утащил бы и
   их. Свои коммиты после этого — только temp-index по точным
   путям, чужой индекс не sweep'ится.
3. **Общий /tmp.** Мой CAS-скрипт в /tmp исчез между коммитами A4
   и AWG3 (общий /tmp чистят/переиспользуют соседи — урок из
   AGENTS.md про коллизии). Скрипт пересоздан в
   `~/workspace/.build-tmp/commit_cas_transport.sh`, коммит AWG3
   лёг со второй попытки чисто; рабочее дерево не пострадало
   (проверено `git status` до повтора).
4. HEAD ветки двигался соседями между всеми моими коммитами;
   CAS-цикл (read-tree на свежий HEAD → write-tree → commit-tree →
   update-ref со старым значением) каждый раз ложился на точного
   родителя, `git show --stat` каждого коммита сверен: только мои
   файлы зоны.

## Что не сделано и почему (сводно)

- Рендер ECH на Xray — спека в п. 2 (формат echConfigList на пине
  не подтверждён без бинаря; вместо догадки — FeatureECH-гейт и
  именованный отказ).
- Подъём претензий mihomo на XHTTPXmux/DownloadSplit — спека в
  п. 4 (только после `mihomo -t`).
- Рендер политики DNS на Xray — спека в п. 8 (гейт стоит).
- key_share рендер для sing-box-lx — поле плана готово (п. 3),
  рендер — PASS2 S3, требует сверки поля lx не по догадке.
- Все бинарные проверки (`xray run -test`, `mihomo -t`,
  `sing-box check`, захваты ClientHello) — dev-машина; на этой VM
  бинарей движков нет.
