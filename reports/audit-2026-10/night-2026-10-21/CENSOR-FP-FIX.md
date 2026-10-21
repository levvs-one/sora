# CENSOR-FP-FIX — Major-1 (клейм KeyShare для mihomo) исправлен; Major-2 (шов проб) — только оценка

Фиксер: отдел CENSOR-FP. Ветка `bugfix/audit-2026-10-19`, строго локально,
пуша не было. Коммит: **`63faf1d3`** `[censor] FP Major-1: claim
FeatureRealityKeyShare for mihomo …` поверх `3b003e8b`, temp-index + CAS
(см. §3). Рабочее дерево чужих WIP не тронуто.

---

## 1. Major-1: факт подтверждён собственным захватом — клейм добавлен

### 1.1 Захват на пине (переиспользован штатный probeexec, новый риг не изобретался)

Бинарь: `~/workspace/.engines-amd64/mihomo -v` → **Mihomo Meta v1.19.32**
linux amd64. Метод: тест в чистом экспорте HEAD поверх штатного
`probeexec.Runner.capture` (рендер штатным mihomo-рендерером плана
`realityPlan("chrome", keyShare)`, реальный бинарь на loopback,
SOCKS-through к capture-листенеру, разбор `diagnostics.AnalyzeHello`) +
полный штатный `Runner.Probe(KindMihomo)`.

Захваченные ClientHello mihomo (один прогон, 2026-10-20):

| KeyShare плана | Длина hello | key_share группы | Группа 4588 (X25519MLKEM768) | PQKeyShare |
|---|---|---|---|---|
| `""` (не задан) | 499 B | [GREASE, 29] | нет | false |
| `"classical"` | 595 B | [GREASE, 29] | нет | false |
| `"hybrid"` | **1817 B** | [GREASE, **4588**, 29] | **есть** (и в supported_groups) | **true** |

Полная проба: `ECH=accepted, KeyShare=accepted`, заметка дословно:
`key share: classical/hybrid change the captured key_share groups as pinned`.
И главное — проба сама называет дефект каталога (до фикса):

```
Divergences: [mihomo: probe accepts REALITY key share but the catalog does
not claim reality-key-share (expectation stale; probe wins)]
```

Сверка с цифрами ревьюера (hybrid 1753 B против 595 B без hybrid):
сигнатура та же; 595 B у ревьюера совпали с моими classical буквально;
абсолютная длина hybrid плавает между захватами (GREASE/паддинг; инвариант —
не байты, а присутствие группы 4588 и рост hello ~в 3 раза). Рендер:
`core/engine/mihomo/proxy.go` (`support-x25519mlkem768: true/false` из
`TLS.KeyShare`) на HEAD присутствует. **Чья проба неверна — ничья: факт
ревьюера подтверждён, каталог врал молчанием.**

### 1.2 Дифф (весь коммит — одна строка)

```diff
--- a/core/engine/catalog.go
+++ b/core/engine/catalog.go
@@ -52,7 +52,7 @@
 			FeatureLoadBalance: true, FeatureXHTTP: true, FeatureVLESSEncrypt: true,
-			FeatureXHTTPDownloadSplit: true, FeatureXHTTPXmux: true, FeatureXHTTPPadding: true,
+			FeatureXHTTPDownloadSplit: true, FeatureXHTTPXmux: true, FeatureXHTTPPadding: true, FeatureRealityKeyShare: true,
 			FeatureAmneziaWG: true, FeaturePrivateControl: true, FeatureChains: true,
```

Блок `KindMihomo` в `core/engine/catalog.go`. Выравнивание соседних строк
не потребовалось; `gofmt -l` по файлу — чисто. Sing-box (строка 91) клеймо
уже имел, Xray сознательно не имеет (нет ручки; комментарий на месте) —
не тронуты, `FeatureH2Headers` sing-box на месте (HEAD-блоб, строки 92–95).

### 1.3 Тесты до/после (чистые экспорты HEAD, не рабочее дерево)

База «до» — экспорт `ebbb7edd`; коммит-база `3b003e8b` отличается от неё
только новым тест-файлом registry (catalog.go и тест гейта между ними
байт-в-байт одинаковы), закоммиченный catalog.go байт-идентичен
протестированному after-экспорту.

| Проверка | До | После |
|---|---|---|
| `TestCensorP1KeyShareGate` (`./engine/`) | **FAIL**: `mihomo spells key_share and must not report it missing: "feature reality-key-share"` | **PASS** |
| `go test ./engine/` целиком | 2 FAIL: гейт + `TestCatalogXmuxClaimMatchesRenderers` | 1 FAIL: только `TestCatalogXmuxClaimMatchesRenderers` |
| `go test ./engine/registry/` | ok | ok |
| `go vet ./engine/ ./engine/registry/ ./engine/probeexec/` | — | чисто |
| Захват probeexec (mihomo, пин 1.19.32) | KeyShare=Accepted при молчащем каталоге (divergence) | divergence по KeyShare устранена самим клеймом |

Не чинилось (по заданию — перечислить): `TestCatalogXmuxClaimMatchesRenderers`
— предсуществующее падение на чистом HEAD, не связано с KeyShare:
`xray claims FeatureXHTTPXmux but its renderer emits no xmux` /
`xmux plan must report xhttp-xmux missing, got ""`. Чья зона — владелец
каталога/Xray-рендера (P1-xmux), не FP.

## 2. ⚠️ Рецидив отравления индекса по catalog.go — СРАЗУ после коммита (индекс мной НЕ тронут)

По просьбе координатора фиксирую состав и блобы. При последнем наблюдении
перед коммитом общий staged был пуст (после `git restore --staged .`
координатора). Мой коммит делался temp-index'ом и от общего индекса не
зависит. **При первой же проверке после коммита** в общем индексе снова
staged-изменение ровно по одному пути:

- `git diff --cached --name-status` → `M core/engine/catalog.go` (1 файл, 1+/1−);
- staged-дифф — **точный откат моего коммита**: строка KindMihomo теряет
  `FeatureRealityKeyShare: true`, больше ничего;
- блобы: HEAD `d9c6e3e768f0d718c825cb3578d96c492f51570a` (правильный, с
  клеймом) → **index `c8f5c62be68768ed2a2e238b6fc19113e7673140`** — это
  байт-в-байт blob catalog.go у parent-коммита `3b003e8b` (состояние до
  фикса); рабочее дерево `8859b8bc0fc182a560c5defcd231d47950c80731`;
- `git status --porcelain -- core/engine/catalog.go` → `MM`.

Индекс я НЕ трогал (ни restore, ни add). Риск для координатора: любой
голый `git commit` сейчас закоммитит именно этот откат 63faf1d3.
Подпись та же, что у прежних эпизодов: в индекс попадает старый blob
файла, по которому только что сел коммит (похоже на
checkout-from-revision/stale-snapshot у конкурентного процесса).

Заодно: рабочее дерево catalog.go (blob `8859b8bc`) содержит кроме моей
строки два чужих ханка — снятие `FeatureH2Headers` у sing-box и снятие
пустой строки. Они не мои, в коммит не вошли (проверено `git show --stat
HEAD`: 1 файл, 1+/1−; HEAD-блоб содержит и клеймо, и H2Headers).

## 3. Как коммитилось (CAS, по регламенту AGENTS.md)

Патч построен из чистых экспортов (`diff` HEAD-блоба против after-файла,
без GIT_INDEX_FILE в окружении), применён в уникальный temp-index
(`GIT_INDEX_FILE=/tmp/idx_censorfp_<pid>_1`): `read-tree 3b003e8b` →
`apply --cached` → staged в temp-index ровно `catalog.go | 2 +-` →
`write-tree`/`commit-tree -p 3b003e8b` → `update-ref <branch> <new> <old>`
— CAS сошёлся с первой попытки, HEAD был `3b003e8b`, стал `63faf1d3`.

---

## 4. Major-2 (ТОЛЬКО ОЦЕНКА — код не тронут): шов проб не подключён к продакшну

### 4.1 Карта: что есть и где обрывается

Шов (владелец — FP, готов и покрыт тестами):

- `core/engine/probecaps.go:131` `ProbeMissing` — **единственное** место,
  где живёт гейт `FingerprintSpellingOK` (probecaps.go, ветка внутри
  ProbeMissing) плюс вердикты пробы (ECH/KeyShare/fingerprint Rejected);
- `core/engine/probecaps.go:182` `SelectEngineProbed` — `SelectEngine` с
  оверлеем проб (pre-reject по ProbeMissing + fallback «probe carries»);
- `core/engine/registry/probes.go:32` `RefreshProbes` (заполняет
  `probeStore`, sync.Map по `*Registry`), `:44` `Probes()`,
  `:59` `SelectPlanProbed` → `SelectEngineProbed`.

Продакшн-путь сегодня (HEAD `63faf1d3`):

- `core/cmd/sora-core/main.go` — session factory = `app.engines.Factory()`;
  `benchmarkSelectKind` (там же) ходит в `engine.SelectEngine` напрямую;
- `core/cmd/sora-core/engines.go` — `lazyEngines`: `discover =
  registry.Discover`, фоновая `warm()`, `get()`, `Factory()` делегирует в
  `registry.Factory()`. **RefreshProbes не вызывается**;
- `core/engine/registry/registry.go:243` `Factory()` → `:323`
  `selectPlan` (per-kind цикл, bridge-кандидат для Xray-TUN) → `:350`
  `engine.SelectEngine(&candidate, r.Availability(), []Kind{kind})`;
  `:383` `Measure` → `:392` тоже `engine.SelectEngine`;
- `core/engine/catalog.go:299` `SelectEngine` судит только по
  `BuildCapabilities`/`MissingFor` (ожидание каталога). Понятий «проба» и
  «spelling» в нём нет.

Вызывающие `RefreshProbes`/`SelectPlanProbed`/`SelectEngineProbed` в
продакшне: **нет ни одного** (grep по HEAD и по рабочему дереву: только
определения, комментарии и `probecaps_test.go`). Следствия:

1. `probeStore` в продакшне всегда пуст, `Probes()` == nil — даже
   подключённый `SelectPlanProbed` выродился бы в обычный `SelectEngine`
   (ProbeMissing при nil-пробе возвращает nil — `probecaps.go:132`);
2. план с пином `hellochrome_133/155` на sing-box/mihomo: селекция
   принимает, рендерер (`ResolveFingerprint`,
   `fingerprint_policy.go:164` → `spellingForEngine`) **молча** подменяет
   имя алиасом `chrome`; на проводе — hello алиаса (проба это доказала:
   JA4 versioned == JA4 chrome, заметка «renderer degradation»).
   Ни отказа, ни предупреждения в `Selection.Rejected` не появляется.

### 4.2 Минимальный замыкающий дифф (оценка, ~2 обязательных касания)

Новые файлы не нужны; сигнатуры шва для этого и проектировались
(см. комментарий в `registry/probes.go:20-22` и эскалацию в
`reports/CENSOR-FP.md:27` — «подключение в цикл Discover и в selectPlan —
эскалация владельцам control/registry»).

- **A. Селекция (registry, обязательно):** `registry.go:350` —
  `engine.SelectEngine(&candidate, …)` →
  `engine.SelectEngineProbed(&candidate, r.Availability(), []Kind{kind},
  r.Probes())`. Замена drop-in: тот же per-kind цикл и bridge-семантика
  сохраняются (SelectPlanProbed целиком для selectPlan НЕ подходит — он
  не умеет bridge-кандидата и чужой preference-порядок). Аналогично
  `:392` в `Measure` — можно второй фазой.
- **B. Триггер проб (cmd, обязательно):** в `cmd/sora-core/engines.go`
  после успешного `Discover` в `lazyEngines.get()/warm()` — фоновый
  `reg.RefreshProbes(ctx)` (goroutine, с логом исхода). **A без B — мёртв**
  (nil-пробы ⇒ гейт молчит), **B без A — факты, которые никто не читает**.
  RefreshProbes нельзя на синхронный путь: проба — ~15 стартов бинаря на
  движок с capture-таймаутами 10–15 с (probeexec), это десятки секунд.
- **C. Опционально (фаза 2):** `benchmarkSelectKind` в
  `cmd/sora-core/main.go` — на пробовую селекцию ради единообразия
  benchmark-отказов.

`core/control` для варианта A+B менять **не нужно**: `Factory()` —
та же сигнатура, меняется только содержимое `Selection.Rejected`
(добавляются строки `probe: …`).

### 4.3 Риски

- **Поведенческий флип fail-closed.** Планы с versioned-попугаем на
  sing-box/mihomo, которые сегодня «работают» через тихий алиас, начнут
  получать отказ селекции. Сюда же шум по `hellochrome_auto` (ревью,
  Minor п.2): `_auto → chrome` — задуманный алиас, а гейт классифицирует
  как потерю. Перед включением владельцу стоит решить: сразу отказ или
  сначала warning-период / исключение для `_auto`.
- **Стартовое время и флаки.** RefreshProbes дорог и зависит от loopback-
  захватов; только фон, никогда не в путь коннекта; падение пробы =
  отсутствие фактов = сегодняшнее поведение (безопасное направление,
  кроме самого SpellingOK-гейта).
- **Свежесть фактов.** `probeStore` привязан к экземпляру Registry:
  новый Discover — пустой стор до конца рефреша (окно, где гейт снова
  молчит); вердикт может флипнуться mid-process после приземления проб.
- **Диагностика.** `SelectEngineProbed` prepend-ит probe-отказы в
  `Rejected`; потребители `LastSelection`/диагностики в control увидят
  новые строки (ключи ошибок в selectPlan — `KeyPlanEngineUnsupported` —
  не меняются).
- **Обратная сторона оверлея.** С живыми пробами заработает и направление
  «probe carries»: план, отказанный каталогом, но принятый пробой (ECH/
  KeyShare), будет выбран. После Major-1 для mihomo KeyShare это уже не
  нужно, но для будущего дрейфа пинов — осознанное поведение, не сюрприз.

### 4
...[truncated 501 chars]