# PASS3-DEEP-RESEARCH — проход 3/3: только новое после PASS2-DEEP-RESEARCH

Дата: 2026-10-20. База: DEEP-RESEARCH-70.md, PASS1-DEEP-RESEARCH.md,
PASS2-DEEP-RESEARCH.md (все три прочитаны целиком перед проходом).
Метод: первоисточники, прочитанные в этом проходе, — официальные доки
sing-box (changelog целиком до 1.14.0 п. 34, страница Deprecated,
страницы TUN / UDP NAT Fields / TLS / VLESS), официальные доки XTLS
(VLESS outbound — комбинации XTLS), официальные доки mihomo
(wiki.metacubex.one: transport configuration — полный каталог
xhttp-opts, TLS configuration — reality-opts/ech-opts), changelog
Hysteria (верх линии), Chrome Releases (каналы stable/beta).
Локальная сверка кода sora — ветка `bugfix/audit-2026-10-19`,
tip `1925867e` (за день ветка ушла вперёд pass2-коммитами; ни один
S-пункт проходов 1–2 ими не закрыт — проверено прямыми grep'ами,
см. таблицу статусов в конце).

**Слоп-фильтр:** как в проходах 1–2 — только то, что меняет код,
каталог, пины или валидацию sora. Неподтверждённое помечено честно.

**Итог одной строкой:** главная болезнь прохода — не движки, а наш
собственный слой честности: каталог capability в двух местах обещает
то, чего не рендерит ни один движок (xmux на Xray-пути, ECH на
Xray-пути), а два комментария про Vision («у sing-box/mihomo vision
нет») фактически неверны и из них выросло реальное расхождение
рендереров (mux+vision вместе на двух движках из трёх).

---

## СТАТУС ИЗВЕСТНЫХ S-ПУНКТОВ (проверка, не переоткрытие)

| Пункт | Статус в коде на tip `1925867e` |
|---|---|
| PASS2 S1: mihomo ложно отказывает AWG 3.1 | **Не изменился.** `core/engine/mihomo/proxy.go:240-246` по-прежнему возвращает ошибку на `UsesAWG31()`; `FeatureAmneziaWG3` для mihomo в каталоге нет |
| PASS2 S2: lx `chrome` = Chrome 133, `chrome_155` не пропускается | **Не изменился.** `core/engine/fingerprint.go:52-59` — прежний неверный комментарий про Auto; `KnownFingerprints` (fingerprint.go) `chrome_155` не содержит; симметричного warning для lx нет |
| PASS2 S3: REALITY `key_share` (lx) отсутствует | **Не изменился.** В `core/engine/plan.go` структура `TLS` (строки 74–89) поля KeyShare не имеет; sing-box-рендер `key_share` не эмитит. **Третья нога той же проблемы — mihomo — вынесена в S2 этого прохода** |
| PASS2 S5: Xray v26.10.17 (stall-фикс, новый TUN-стек, Vision/Go 1.27.3) | **Не изменился.** `catalog.go` MinVersion Xray по-прежнему `26.3.27`; новее v26.10.17 релиза Xray в этом проходе не нашлось |
| PASS2 S6: lx-XHTTP поля (xmux/x_padding/session) не рендерятся | **Не изменился и оказался шире:** xmux/x_padding не рендерит **ни один** движок, включая Xray, которому каталог эту фичу приписывает — см. S1 этого прохода |
| PASS1 A7: hy2 Ed25519-диагностика / `disable_chrome_parrot` | **Не изменился.** Строки `disable_chrome_parrot` в `core/` нет вообще (grep по всему core — пусто) |

---

## S-TIER

### S1. Каталог врёт про Xray-xmux: `FeatureXHTTPXmux` у Xray есть, но xmux и x_padding не рендерит НИ ОДИН движок — включая Xray

- **Факт:** План несёт xmux-тюнинг и пэддинг
  (`core/engine/plan.go:111-124`: `XmuxMaxConcurrency`,
  `XmuxMaxConnections`, `XmuxMaxReuseTimes`, `XmuxMaxRequestTimes`,
  `XPaddingBytes`), каталог маршрутизирует такие планы **только**
  на Xray (`core/engine/catalog.go:95` — `FeatureXHTTPXmux: true`
  у KindXray; у sing-box и mihomo фичи намеренно нет, каталог:40-46
  и 73-76). При этом комментарий в самом plan.go:113-116 честно
  пишет «no renderer emits it yet» — а каталог об этом не знает.
  Проверка всех трёх рендереров в этом проходе:
  - **Xray** (`core/engine/xray/render.go:286-296`): xhttp-кейс
    эмитит только `mode`/`path`/`host` + `downloadSettings`.
    Xmux, `xPaddingBytes` и даже `headers` (`t.Headers`) молча
    теряются.
  - **sing-box** (`core/engine/singbox/render.go:440-446`): только
    host/path/mode/headers (это PASS2 S6).
  - **mihomo** (`core/engine/mihomo/proxy.go:206-208`,
    `config.go:173-178`): только path/host/mode/headers.
  Парсер усугубляет: `core/parser/parser.go:458-475` из `extra=`
  поднимает только `downloadSettings`; xmux/session-ключи
  игнорируются уже на импорте, т.е. подписка с xmux-тюнингом
  теряет его дважды.
- **Почему это S, а не повтор PASS2 S6:** проход 2 считал, что на
  Xray-пути xmux работает («поля плана честно маршрутизируют план
  от sing-box»), и чинить предлагал только lx-рендер. По факту
  маршрутизация ведёт в движок, который поля **тоже роняет**:
  пользователь с xmux-подпиской получает «фича поддерживается,
  движок выбран правильно» — и провод без xmux. Отдельная острота
  x_padding: сервер XHTTP **проверяет** диапазон пэддинга запроса
  (доки mihomo, transport configuration: «The server checks
  whether it falls within the allowed range») — сервер с
  нестандартным диапазоном отклонит запросы клиента, который
  пэддинг из подписки потерял и шлёт дефолтные 100-1000.
- **Источники:** доки mihomo (полный каталог xhttp-opts, включая
  `x-padding-bytes`, `reuse-settings`, session/seq/uplink поля) —
  https://wiki.metacubex.one/en/config/proxies/transport/ ;
  PASS2 S6 (lx PARAM_MAP поименно против Xray splithttp);
  локальный код (выше).
- **Спека фикса:**
  1. **Честность немедленно (до рендера):** убрать
     `FeatureXHTTPXmux` из KindXray в catalog.go:95, чтобы
     `Missing()` честно говорил «xmux не умеет никто», а не
     маршрутизировал в молчаливую потерю. Это одна строка и
     меняет только UX-правду, не провод.
  2. **Рендер Xray:** в xhttp-кейс добавить `xmux` из полей плана
     (`maxConcurrency`, `maxConnections`, `cMaxReuseTimes`,
     `maxRequestTimes`), `xPaddingBytes` из `XPaddingBytes`,
     `headers` из `t.Headers`. В плане не хватает
     `cMaxLifetimeMs` (Xray) / `hMaxReusableSecs` (mihomo) —
     добавить поле `XmuxMaxLifetimeMs` либо осознанно оставить 0
     (дефолт движка); развилку `maxRequestTimes` vs
     `hMaxRequestTimes` у Xray сверить по пину (см. проверку).
  3. **Рендеры lx/mihomo** — по спеке PASS2 S6 (lx:
     `x_padding_bytes`, `xmux`, session/seq) и A1 этого прохода
     (mihomo: `reuse-settings`, `x-padding-bytes`); после этого
     вернуть фичу в каталог тем движкам, где рендер реально есть.
  4. **Парсер:** поднимать xmux-ключи из `extra=` в план
     (расширить `extraParams`, parser.go:468-475).
- **Риск:** низкий для п. 1 (только каталог); средний для рендера —
  Xray xmux-поля принимают и числа, и диапазонные строки у разных
  версий; план хранит int'ы — эмитить числами.
- **Проверить на dev-машине/бинаре:** `xray run -test` на пине
  26.3.27 с рендером, содержащим xmux + xPaddingBytes; живой
  прогон против XHTTP-сервера с нестандартным диапазоном
  пэддинга (сервер принимает только при совпадении); счётчик
  переиспользованных соединений на сервере (xmux реально
  работает, а не просто парсится).

### S2. REALITY на mihomo: ручки гибридного key share нет в рендере — третья нога PASS2 S3

- **Факт:** Официальные доки mihomo (TLS configuration) задают
  `reality-opts` тремя полями: `public-key`, `short-id`,
  **`support-x25519mlkem768: true`**. Наш рендер
  (`core/engine/mihomo/config.go:201-204`) структуру reality
  определяет только двумя полями, `applyTLS`
  (`core/engine/mihomo/proxy.go`, блок REALITY) третье не ставит
  никогда. Против серверов Xray ≥26.9.8 (принимают только
  ClientHello с гибридом X25519MLKEM768 — PASS2 S3) mihomo-путь
  получает тот же непрозрачный `reality verification failed` и
  уход на камуфляжный сайт, что и sing-box без `key_share`.
  PASS2 S3 специфицировал ручку только для lx
  (`tls.reality.key_share`); mihomo-ручка в проходах 1–2 не
  упоминалась вообще.
- **Честная граница:** дефолт флага в mihomo по исходнику пина в
  этом проходе **не подтверждён** (доки показывают явный `true`
  в примере; если бы дефолт был true, поле было бы бессмысленно —
  но это рассуждение, не доказательство). Вне зависимости от
  дефолта: выразить «сервер требует гибрид» планом на
  mihomo-пути сегодня невозможно.
- **Источник:** https://wiki.metacubex.one/en/config/proxies/tls/
  (блок reality-opts); PASS2 S3 (механика отказа ≥26.9.8).
- **Спека фикса:** та же ручка плана, что PASS2 S3 вводит для lx
  (`TLS.KeyShare`: `""`/`classical`/`hybrid`), рендерится третьим
  соответствием: hybrid → mihomo
  `support-x25519mlkem768: true`; classical → `false` явно.
  Валидационный warning PASS2 S3 (отпечатки без гибрида против
  серверов ≥26.9.8) распространить на mihomo-путь.
- **Риск:** низкий; поле опционально, старые серверы гибрид
  принимают как обычный key share.
- **Проверить на бинаре:** захват ClientHello mihomo 1.19.32 с
  флагом и без (есть ли X25519MLKEM768 в supported_groups /
  key_share); живой коннект к локальному Xray ≥26.9.8 REALITY-
  серверу обоими вариантами конфига.

### S3. Vision: посылка «у sing-box и mihomo vision нет» ложна — из неё вырос mux+vision на двух рендерерах и запрет легальной комбинации Xray

Две стороны одной устаревшей посылки.

**(а) Mux эмитится вместе с vision на sing-box и mihomo.**
- **Факт:** `core/engine/mux.go:20-24` фиксирует архитектурное
  решение: «sing-box and mihomo have no vision flow, so mux stays
  on for their REALITY outbounds». Та же фраза — комментарии в
  `singbox/render.go` (блок RealityMux) и `mihomo/proxy.go:169`.
  Посылка неверна: официальные доки sing-box (VLESS outbound)
  документируют `flow` со значением `xtls-rprx-vision`, и наш
  рендер это значение эмитит дословно
  (`singbox/render.go:260`); mihomo flow прокидывает
  (`mihomo/proxy.go:53`), экосистема mihomo vision описывает
  (Stash Wiki: VLESS + `flow: xtls-rprx-vision` over TCP).
  Следствие: `RealityMux` (`mux.go`) не смотрит на flow вообще, и
  там, где Xray-рендерер vision обрабатывает специально (mux
  пропускается, `xray/render.go:258`), sing-box эмитит
  `multiplex` + `flow: xtls-rprx-vision` одновременно, а mihomo —
  `smux` + `flow`. У Xray mux под vision инертен by design; у
  sing-box/mihomo семантика пары mux+vision нигде в нашем коде не
  определена: в лучшем случае мёртвый вес, в худшем — сервер с
  vision-юзером mux не ждёт.
- **Источник:** https://sing-box.sagernet.org/configuration/outbound/vless/
  (`flow`: available values — `xtls-rprx-vision`);
  https://stash.wiki/en/proxy-protocols/proxy-types (XTLS Vision
  в mihomo-семействе).
- **Спека:** сделать `RealityMux` flow-aware на уровне предиката
  (vision-поток → mux не предлагается ни одному движку), а не
  по одному guard'у в Xray-рендерере; комментарии в mux.go /
  обоих рендерерах переписать по факту («vision есть у всех трёх;
  mux под ним не применяем нигде»).
- **Проверить на бинаре:** `sing-box check` + живой прогон
  VLESS+REALITY+vision через sing-box-lx с multiplex в конфиге и
  без — фиксируем фактическое поведение пина до смены предиката
  (если пин пару игнорирует — фикс чисто гигиенический, если
  ломает — это был живой баг).

**(б) Запрет flow на не-TCP режет легальную комбинацию Xray:
VLESS Encryption + XHTTP + vision.**
- **Факт:** Официальные доки XTLS (VLESS outbound, прочитаны в
  этом проходе): «XTLS is available only in the following
  combinations: **TCP+TLS/REALITY**; **VLESS Encryption: No
  underlying transport restrictions**». Наш код запрещает шире:
  `core/engine/validate.go:258-262` — ошибка на любой
  vision-flow + xhttp; `core/engine/xray/render.go:383-387`
  (`checkStreamCompat`) — ошибка на любой flow + не-TCP, с
  комментарием, повторяющим только первую половину правила
  («XTLS is available only under TCP+TLS/REALITY»).
  VLESS Encryption у нас поддерживается (рендер эмитит
  `encryption`, каталог — FeatureVLESSEncrypt), т.е. связка
  «encryption=mlkem768x25519plus… + xhttp + vision», которую
  панели уже раздают, sora отклоняет на двух слоях.
- **Источник:** https://xtls.github.io/en/config/outbounds/vless.html
  (секция flow, комбинации XTLS).
- **Спека:** в обоих местах условие запрета дополнить исключением:
  flow на не-TCP разрешён, когда `o.Encryption` — непустая
  VLESS-Encryption строка (не `""`/`"none"`). Для
  REALITY+xhttp+vision запрет **сохранить** (REALITY — не
  Encryption; warning `reality-xhttp-vision` в reality.go
  корректен). `ApplyAutoVision` не трогать (авто-включение —
  по-прежнему только TCP).
- **Риск:** средний при неверной границе: разрешить лишнее —
  Xray отклонит конфиг при загрузке (громко, не молча);
  спецификация выше границу держит узкой.
- **Проверить на бинаре:** `xray run -test` на пине: (1) vlessenc
  + xhttp + vision — принимается; (2) reality + xhttp + vision —
  фиксируем фактический ответ пина как регрессионный ориентир.

### S4. Xray-путь молча роняет ECH целиком; mihomo роняет закреплённый конфиг; валидатор ECH врёт про query_server_name

- **Факт:** Xray ECH **умеет** (клиент и сервер):
  `transport/internet/tls/ech.go`, поля tlsSettings
  `echConfigList` и `echForceQuery` (`none`/`half`/`full`).
  Наш Xray-рендерер ECH не упоминает вообще (grep `ech` по
  `core/engine/xray/*.go` — пусто): план с `TLS.ECH.Enabled`
  (plan.go:58-70), ушедший на Xray, идёт с открытым SNI — ровно
  тот класс «тихой потери обещанной приватности», за который
  проходы 1–2 чинили AWG и xmux. Каталог фичи ECH не имеет,
  `Missing()` потерю не видит; валидатор (`validate.go:309-336`,
  `:817-827`) проверяет TLS/REALITY/DNS-bootstrap, но не
  рендеримость движком.
  Два сопутствующих дефекта той же темы:
  - **mihomo:** рендер — только `ech: true` (`mihomo/config.go:
    121-123`, `proxy.go:287-290`); закреплённый `ECH.Config` и
    `QueryServerName` теряются, хотя доки mihomo задают
    `ech-opts: {enable, config, query-server-name}` —
    план, честно требующий pinned config (иначе validate.go:823
    не пропускает без шифрованного DNS), на mihomo пин теряет.
  - **Валидатор:** `validate.go:329` отклоняет любой
    `QueryServerName` с текстом «not rendered yet (needs
    sing-box >= 1.13)» — но sing-box-рендер его эмитит
    (`singbox/render.go:403`) и пол пинов — 1.14.3. Текст и
    запрет устарели в момент, когда рендер добавили.
- **Источники:** https://deepwiki.com/XTLS/Xray-core/4.4-encrypted-client-hello-(ech)
  (ApplyECH, ech.go, CLI `xray tls ech`);
  https://wiki.metacubex.one/en/config/proxies/tls/ (ech-opts);
  доки sing-box TLS (ech: config / query_server_name, client only).
- **Спека фикса:**
  1. Каталог: ввести `FeatureECH` (sing-box, mihomo — true;
     Xray — false до рендера) + запись в `Missing()`:
     «ECH (Xray renderer does not emit it)» — честность до
     рендера, как в S1 п. 1.
  2. Рендер Xray: `tlsSettings.echConfigList` из `ECH.Config`
     (формат на пине сверить: Xray ждёт base64 ECHConfigList,
     план хранит PEM-строки как для sing-box — конверсия на
     рендере либо отдельное поле плана; не угадывать, см.
     проверку) + `echForceQuery`: pinned config → `none`,
     config из DNS → `full` (или `half` — по семантике пина).
  3. Рендер mihomo: заменить `ech: true` на `ech-opts` с
     enable/config/query-server-name.
  4. Валидатор: запрет QueryServerName снять для sing-box-пути
     (или целиком после п. 3 — тогда поле рендерят два движка,
     а Xray-путь закроет FeatureECH-гейт из п. 1).
- **Риск:** ECH — opt-in фича с известными сетями-резаками
  (plan.go:79-81 это уже фиксирует); риск фикса — только в
  формате echConfigList (п. проверки).
- **Проверить на бинаре:** `xray run -test` с echConfigList на
  пине 26.3.27; захват: outer SNI ≠ inner при ECH на Xray-пути;
  `mihomo -t` с ech-opts + pinned config.

---

## A-TIER

### A1. mihomo XHTTP: без `reuse-settings` переиспользование соединений ВЫКЛЮЧЕНО — каждое соединение новое; `download-settings` и `x-padding-bytes` не рендерятся

- **Факт:** Доки mihomo (transport configuration, прочитаны
  целиком): про `reuse-settings` — «unlike the original
  implementation, this option has no default value. **If
  omitted, connection reuse is disabled and each request opens a
  new underlying connection**». У Xray и lx xmux-пул включён
  всегда. Наш `xhttpOpts` (`mihomo/config.go:173-178`) —
  path/host/mode/headers: ни reuse-settings, ни
  download-settings, ни x-padding-bytes. Итог на mihomo-пути:
  XHTTP работает в самом дорогом и самом заметном режиме —
  новое TCP+TLS на каждый запрос (та самая картина параллельных
  хендшейков, с которой борется наш freeze-контур), а планы со
  сплитом каталог от mihomo честно уводит (FeatureXHTTPDownload
  Split нет) — но «обычные» XHTTP-планы деградацию получают
  молча.
- **Источник:** https://wiki.metacubex.one/en/config/proxies/transport/
  (xhttp-opts, reuse-settings/download-settings, значения —
  диапазонные строки вида `"16-32"`).
- **Наш код:** `core/engine/mihomo/config.go:173-178`,
  `core/engine/mihomo/proxy.go:206-208`.
- **Спека:** расширить `xhttpOpts`: `reuse-settings` из полей
  плана (max-concurrency/max-connections — строками,
  c-max-reuse-times, h-max-request-times), `x-padding-bytes` из
  `XPaddingBytes`, `download-settings` из
  DownloadAddress/DownloadPort (+ собственный reuse-settings
  внутри). Даже при пустом плане эмитить reuse-settings с
  разумным дефолтом (иначе режим «без переиспользования»
  останется дефолтом mihomo-пути). После рендера каталогу
  можно давать mihomo FeatureXHTTPXmux / DownloadSplit —
  только после `mihomo -t`.
- **Подпункт-проверка (не подтверждено):** доки mihomo перечисляют
  режимы xhttp как `stream-one`/`stream-up`/`packet-up` —
  **`auto` в списке нет**, а наш рендер прокидывает
  `t.Mode` дословно (пустой → поле опущено, явный `auto` из
  подписки → уйдёт в YAML как есть). Принимает ли mihomo
  `mode: auto` — проверить `mihomo -t`; если нет, рендерер
  обязан маппить `auto` → отсутствие поля именно для mihomo
  (у Xray и lx `auto` легален).
- **Риск:** низкий; reuse-дефолт меняет только экономику
  соединений.
- **Проверить на бинаре:** `mihomo -t` (reuse-settings,
  download-settings, mode: auto); счётчик соединений на
  XHTTP-сервере до/после.

### A2. REALITY SpiderX: план несёт, рендерят только Xray; для sing-box поля в движке нет в принципе — нужна честная пометка, а не молчаливая потеря

- **Факт:** `core/engine/plan.go:88` — `TLS.SpiderX`. Xray
  рендерит в обеих ногах (`xray/render.go:308` и `:418`,
  дефолт `"/"`). sing-box: блок reality в `tls()`
  (`singbox/render.go:392`) — только public_key/short_id, и это
  потолок движка: официальная схема клиентского REALITY
  sing-box (доки TLS, Reality Fields) полей кроме
  `public_key`/`short_id` не имеет — spider-механика там не
  параметризуется. mihomo: структура reality (`config.go:
  201-204`) spider-поля не имеет; есть ли оно в
  `reality-opts` пина — **не подтверждено** (в доковой странице
  TLS его нет).
- **Следствие:** подписка с `spx=` на sing-box/mihomo путях
  теряет параметр без единого сигнала; на Xray — работает.
  Класс тот же, что S4, но вес параметра ниже (spiderX влияет
  на паттерн проб dest при хендшейке, не на сам факт
  соединения) — поэтому A, не S.
- **Спека:** validation/diagnostics warning «spiderX honoured
  only by Xray» при выборе другого движка (по аналогии с
  существующими RealityWarnings в `core/engine/reality.go`);
  для mihomo — сначала проверка пина, при наличии поля —
  рендер.
- **Проверить на бинаре:** grep исходника пина mihomo 1.19.32
  по `spider` в reality-пути; `mihomo -t` с
  `reality-opts.spider-x` (если поле есть).

### A3. TUN `dns_mode`: проход 2 уточняется — дефолт зависит от `auto_route`; наш Linux-кейс безопасен по дефолту, Windows/macOS — нет; фиксировать явно всё равно надо

- **Факт (новый против PASS2 A2):** Доки sing-box TUN:
  «`hijack` is used by default **when `auto_route` is enabled,
  otherwise `disabled` is used by default**». Наш рендер
  (`singbox/render.go`, `tun()`): Linux — `auto_route=false`
  (маршруты ведёт tunroute) → дефолт движка на Linux —
  `disabled`, платформенного перехвата нет; Windows/macOS —
  `auto_route=true` → дефолт `hijack`: движок сам ставит
  per-interface DNS и (Windows + `strict_route`) WFP-блокировку
  порта 53 чужим интерфейсам — рядом с нашим kill switch и
  нашим hijack-dns route-action. Плюс зафиксированный в
  PASS2 A2 дрейф: поведение «без auto_route» чинилось между
  1.14.x point-релизами — т.е. именно наш Linux-профиль живёт
  на дефолте, который внутри пиновой линии уже двигался.
- **Спека (уточняет PASS2 A2):** эмитить `dns_mode` явно на
  всех платформах из плана: Linux — `disabled` (DNS наш:
  tunroute + hijack-dns action + CheckDnsLeaks); Windows/macOS —
  решение владельца одним значением (`hijack` как второй пояс
  к kill switch либо `disabled` ради единственного владельца
  DNS), но **явно в рендере**, чтобы point-релизы движка не
  могли его перевернуть молча.
- **Источник:** https://sing-box.sagernet.org/configuration/inbound/tun/
  (dns_mode/dns_address).
- **Проверить на dev-машине:** CheckDnsLeaks-стенд на пине
  lx.14: Linux (подтвердить disabled-поведение по факту, не по
  докам) и Windows (пересечение WFP-фильтров движка с нашим
  kill switch при `strict_route`).

### A4. Xray-рендер XHTTP роняет `headers` — единственный из трёх

- **Факт:** `xray/render.go:288` — `xhttpSettings` без
  `headers`; sing-box эмитит (`singbox/render.go:443-445`),
  mihomo эмитит (`mihomo/proxy.go:208`), Xray поле поддерживает
  (та же схема splithttp). Подписки, где CDN-фронтинг несётся
  кастомными заголовками сверх `host`, на Xray-пути теряют их
  молча.
- **Спека:** `xs.set("headers", t.Headers)` в xhttp-кейс;
  регрессионный тест на паритет трёх рендереров по базовому
  набору полей транспорта (host/path/mode/headers) — такой тест
  заодно ловил бы S1-класс в будущем.
- **Проверить:** `xray run -test`; паритет-тест в CI.

### A5. Деприкации 1.16: повторный полный аудит по официальной странице — чисто везде, кроме одного частичного закрытия: implicit HTTP client при пустом detour

- **Факт:** Официальный список удалений (страница Deprecated,
  прочитана целиком): в **1.16.0** уходят `download_detour`,
  implicit default HTTP client для remote rule-set'ов,
  inline `tls.acme`, legacy `strategy` DNS rule action,
  `rule_set_ip_cidr_accept_empty`, `independent_cache`,
  `store_rdrc`, legacy address-filter поля DNS-правил
  (`ip_cidr`/`ip_is_private` без `match_response`), Hysteria v1
  tuning-поля; в **1.17.0** — TUN `stack`. Сверка с нашим
  рендером в этом проходе (grep по всему `core/engine`):
  ничего из списка не эмитится — **кроме одного нюанса**:
  `route()` (`singbox/render.go`, блок rule-set) создаёт
  `http_clients` + `default_http_client` **только когда**
  `ruleSetDetour() != ""`. План без прокси (чистый direct /
  импортированный профиль с remote rule-set'ами и финалом
  direct) рендерится без http_clients — и сегодня работает на
  том самом implicit fallback, который 1.16 удаляет. PASS1 S3
  пометил этот пункт «у нас уже мигрировано» — миграция
  оказалась условной.
- **Источник:** https://sing-box.sagernet.org/deprecated/ ;
  changelog 1.14.0 п. 22 (unify HTTP client).
- **Спека:** при наличии remote rule-set'ов рендерить
  `http_clients` всегда: detour = выбранный detour, при его
  отсутствии — явный клиент без detour (direct), и
  `default_http_client` на него. Закрыть до бампа на 1.16,
  регрессия — рендер-тест «direct-only план с rule-set'ом
  содержит http_clients».
- **Статус остальных горизонтов (проверено, без изменений):**
  sing-box 1.15 — по-прежнему alpha (последняя — alpha.12),
  stable не существует, MinVersion 1.14.3 корректен (PASS1 S2
  в силе); TUN `stack` — version-gate в рендере на месте
  (`singbox/render.go:929-936`); Xray-сторона — plaintext
  cutoff и legacy reverse обрабатываются существующим кодом
  (перепроверка в этом проходе не делалась).

### A6. Xray-путь молча роняет DNS `NameserverPolicy` (split DNS) — у фичи нет capability-гейта

- **Факт:** `plan.go:311` — `DNS.NameserverPolicy`. sing-box
  рендерит политику в DNS-правила (`singbox/render.go`,
  блок dns()), mihomo — в `nameserver-policy`
  (`mihomo/rules.go`, buildDNS). Xray-рендер DNS
  (`xray/render.go`, `dns()`) политику не читает вообще:
  ни ошибки, ни приближения. В каталоге/Missing() политики
  нет — план с политикой (типовой кейс: `+.ru` → direct)
  свободно маршрутизируется на Xray, и split DNS там молча
  перестаёт существовать: «direct»-домены резолвятся общим
  сервером через туннель (функциональная деградация +
  частичная утечка картины запросов не тому резолверу).
  Для сравнения: fakeip на Xray-пути защищён отсутствием
  FeatureFakeIP — у политики такого предохранителя нет.
- **Спека:** Xray DNS server-объекты поддерживают поле
  `domains` (список доменов, для которых сервер используется) —
  маппить политику в серверы с `domains: ["domain:<suffix>"]`
  либо, минимально честно, запись в `Missing()` для Xray при
  непустой NameserverPolicy. Первое — цель, второе —
  промежуточная честность.
- **Проверить на бинаре:** `xray run -test` с dns.servers[]
  объектами с `domains` на пине; поведенческий тест: домен из
  политики уходит на «свой» сервер (лог/захват).

---

## B-TIER

### B1. WS early-data: `early-data-header-name` не рендерит никто; Xray не рендерит и для ws `headers` сверх host

- mihomo ws-opts знает `early-data-header-name` и
  `v2ray-http-upgrade-fast-open` (доки transport); наш
  `wsOpts` (`mihomo/config.go:155-162`) — path/headers/
  v2ray-http-upgrade/max-early-data. Xray ws-кейс
  (`xray/render.go`, wsSettings) — path/host/maxEarlyData без
  `earlyDataHeaderName` и без произвольных headers. Подписки
  вида `?ed=2560` с выносом early data в заголовок (стиль
  `Sec-WebSocket-Protocol`) деградируют до «early data
  выключен». В плане поля под имя заголовка нет. Действие:
  B-очередь — поле плана + три рендера одним заходом с A4
  (паритет транспортов).

### B2. Hysteria2 `realm` (NAT traversal, sing-box 1.14 п. 10) — watch, не внедрять

- 1.14 добавил Hysteria Realm service и поле `realm` у
  hy2 inbound/outbound для серверов за NAT. Наши one-click
  серверы — публичные, rendezvous не нужен; клиентская
  поддержка чужих realm-серверов из подписок — спроса нет.
  Зафиксировано, чтобы следующий проход не «открывал»
  как пробел. Источник: changelog 1.14.0 п. 10.

### B3. TUN UDP NAT поля sing-box 1.14 (`udp_mapping`/`udp_filtering`/`udp_nat_max`) — дефолты sane, рендер не нужен

- Доки UDP NAT Fields: дефолты — `endpoint_independent` и
  для mapping, и для filtering (full-cone), `udp_timeout` 5m.
  Это ровно поведение, нужное играм/VoIP/WebRTC; наш TUN-рендер
  полей не ставит и получает правильные дефолты. Действие:
  нет; при жалобах на NAT-тип — знать, где ручка. Заодно:
  `endpoint_independent_nat` мёртв с 1.11 — мы его не
  рендерим, чисто. Источник:
  https://sing-box.sagernet.org/configuration/shared/udp-nat/

### B4. Статус-проверки без изменений (чтобы не переоткрывали)

- **Hysteria:** 2.13.0 — по-прежнему верхушка changelog
  (проверено в этом проходе); пол one-click из PASS2 S4 в
  силе, PR #1703 в линии до 2.13.0 отсутствует (PASS2).
- **Chrome/parrot:** stable — 155 (широкий роллаут
  2026-10-06); 156 — Beta с 2026-09-30, при двухнедельном
  цикле stable ожидается в ближайшие дни. `CurrentChromeParrot
  = HelloChrome_155` сегодня корректен; `ParrotReviewOverdue`
  (30 дней от 2026-10-20) сработает 2026-11-19 — к тому
  моменту 156 будет stable и, вероятно, без parrot'а в utls:
  это плановый процесс прохода 1 (S3), не находка.
  Источники: Chrome Releases blog; ghacks (155 stable,
  2026-10-07).
- **mihomo:** тега новее 1.19.32 в этом проходе **не нашлось**
  (поиск по релизам; помечаю «не подтверждено», а не «нет»).
- **sing-box-lx:** тега новее `v1.14.3-lx.14` поиском **не
  нашлось** (та же честная пометка).
- **JA4:** ревизий спецификации FoxIO в этом проходе не
  искал повторно — PASS1 вердикт («формула не менялась»)
  остаётся в силе как последнее проверенное состояние.
- **Fragment + REALITY в upstream sing-box:** расхождения с
  lx (PASS2 S3, задача 088) в этом проходе **не подтверждено**:
  фрагментация живёт в общем utls-пути sing-box
  (`common/tls/utls_client.go`), который использует и
  REALITY-клиент; утверждать «upstream не фрагментирует
  REALITY» нельзя. Стенд при следующем синке lx.

---

## Отсечено слоп-фильтром

- **Zeptun как TUN-движок mihomo** (issue MetaCubeX/mihomo
  #3240) — стороннее предложение без принятия мейнтейнерами;
  sora движки не линкует. Rejected.
- **Tailcat (sing-box 1.15-alpha.5), Snell/OpenVPN/OpenConnect
  (1.14)** — протоколов нет в продуктовом плане sora;
  повторно rejected по принципу проходов 1–2.
- **sing-box API service / Dashboard / `sing-box api`
  (1.14 п. 7–8)** — у sora свой control plane и gRPC;
  дублирующий контур управления — слоп.
- **TLS `handshake_timeout` (1.14)** — дефолт движка 15 с
  sane; поля в плане нет и жалоб нет. Не рендерить.
- **DNS `evaluate`/`race`/`respond` (1.14 п. 12)** — мощная
  механика response-dependent резолвинга; нашему плану
  (политики по суффиксам) не нужна, сложность не окупается.
  Watch при появлении split-DNS кейсов, которые суффиксами не
  выражаются.
- **XDRIVE, MASQUE-расширения Xray 26.10.17** — уже отсечено
  в PASS2; статус не изменился.
- **`congestion-controller` для mihomo TUN (PASS2 A7)** —
  повторно: полевых данных нет, кода не требуется.

---

*Код не трогался, коммитов нет — как заказано. Утверждения о
коде sora проверяемы по файлам и строкам выше на tip `1925867e`;
утверждения о движках — по ссылкам на официальные доки и
changelog'и, прочитанным в этом проходе 2026-10-20.
Неподтверждённое помечено на месте: дефолт
`support-x25519mlkem768` в mihomo (S2), `mode: auto` у mihomo
XHTTP (A1), spider-поле в mihomo reality-opts (A2), поведение
пары mux+vision на пине sing-box (S3а), формат echConfigList
на пине Xray (S4), отсутствие тегов новее пинов у mihomo/lx
(B4).*
