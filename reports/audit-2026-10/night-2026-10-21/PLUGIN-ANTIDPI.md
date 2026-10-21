# Плагин Anti-DPI — отчёт мастер-координатора

Заказ владельца: ОДИН плагин — полностью функциональный, продвинутый,
настраиваемый, с описаниями, на всех системах. Статус: **сделан и принят**.
Пакет: `extensions/anti-dpi/` (`org.sora.anti-dpi`, v1.0.0) в репозитории
sora, ветка `bugfix/audit-2026-10-19`, финальный HEAD `a30da220`.
Пуша не было (родитель пушит батчами; коммиты `[antidpi]` — локально).

## Что построено

### Продукт (пакет `extensions/anti-dpi/`)
- Манифест v1: permissions `ui.panel, bypass.read, bypass.write,
  bypass.tune, notifications`; capabilities `ui-panel, network-hook`;
  settings_schema (language auto/en/ru, confirm_apply, monitor_limit).
- **15 пресетов**: все 11 профилей реестра тюнера ядра
  (`core/tune/desync/registry.go` — классы sni_block/stall/quic_throttle/
  kz_variant; стратегии сверены программно с `Params.BypassStrategy()` —
  11/11 MATCH) + 4 классики tpws (дефолтный сплит приложения, TLS-record,
  HTTP-реформа, multisplit). У каждого: описание, цель (тип блокировки),
  цена/риски — EN+RU, backends, scope.
- **Панель, 7 вкладок**: Обзор (capabilities платформы с причинами
  недоступности, источник глобальной стратегии, pending-состояние),
  Пресеты (карточки, применение, «в редактор»), Редактор (все 29 полей
  BypassStrategy в 5 группах; у каждого поля подпись и подсказка —
  механизм/диапазон/эффект; клиентская валидация — зеркало
  `core/engine/validate.go`: ttl⊥auto_ttl, зависимости fooling/fake/
  scope, запрет микса tpws-only×desync; бейджи доступности по бэкендам),
  Привязки (домен/категория → стратегия, precedence «пользователь
  сильнее» объяснён в UI), Автоподбор (TuneDesync: победитель, score в %,
  применение в один клик; при `strategy:null` — честный текст про
  привязку к сетевому профилю), Монитор (лента событий цензуры из
  `WatchBypassEvents`), Профили (экспорт/импорт JSON через textarea —
  файловых диалогов у панелей нет; импорт строгий, как парсер хоста).
- i18n: полные EN+RU (144 ключа + 29 полей × label/hint + виды цензуры +
  пресеты). Прочие локали приложения плагин не локализует (у панелей нет
  механизма app-строк) — зафиксировано как граница, не как пробел.

### Недостающий шов (ядро, контракт API 1.14)
ExtensionHost не имел bypass-API — достроен в ext-зонах:
- **Proto** `sora.ext.v1`: `GetBypassCapabilities`, `GetBypassState`,
  `GetBypassLayer`, `ApplyBypassLayer`, `TuneDesync`,
  `WatchBypassEvents` (все Since 1.14, additive-only). Версии ядра и
  клиента честно подняты до 1.14 (main.go `Version{1,14}`, link.dart;
  негоциация 1.13-клиентов сохранена и запинена).
- **Permissions**: `bypass.read` (Sensitive), `bypass.write`
  (Dangerous), `bypass.tune` (Dangerous) — в закрытый реестр Go + Dart
  parity + blurbs во все 32 ARB (RU — перевод, остальные — EN-фолбэк).
- **LayerStore** (`core/ext`): персистентный слой расширения (global +
  bindings), валидация той же семантикой, что у плана (общий
  `engine.Outbound.Validate`), fail-closed, лимиты (≤256 bindings,
  match ≤251 байт, слой ≤64 KiB), каноникализация IDNA, copy-then-swap
  запись (память не расходится с диском при ошибке).
- **Plan merge** (`core/control`): слой применяется при построении
  плана. Global — только в пустой zapret-стратегии запроса;
  пользовательская стратегия и правила всегда побеждают (включая
  суффикс-перекрытия и регистр — по каноническим формам). Bindings
  добавляют bypass-outbound + правило после пользовательских;
  merge не может инвалидировать валидный план (кап имени, probe-
  валидация каждого outbound, план с XrayProfile пропускает bindings).
  Отключённое/отозванное расширение: токены ревокнуты стором, слой в
  план не попадает.
- **Маркер `midsni`**: доказанно не нативен для zapret (`parse_posmarker`
  в tpws.c/nfqws.c: host/endhost/sld/midsld/endsld/method/sniext;
  бинарная проба tpws: `--split-pos=midsni` — отказ парсера, `midsld` —
  ок; семантика midsld≠midsni). Решение: маркер принимается слоем
  только на plain-domain bindings, merge резолвит его против домена
  привязки (`bypass.ResolveStrategy`); в global и на tag/IP/CIDR —
  InvalidArgument. Пути, где маркер доезжает до argv неразрешённым,
  нет (запинено свипом и сквозным тестом).
- **Тюнер**: ext-вызов идёт в то же ядро `runDesyncTune`, что и
  CensorControl (rate-limit, только canary, не под живой сессией,
  биндинг в F5-профиль). Победитель-registry резолвится в стратегию;
  genome без faithful rendering → `has_strategy=false`, честно.
- **Capabilities**: измеряются (бинарь из digest-verified discovery,
  nft/nfqueue/привилегии — реальные пробы), не выводятся из GOOS.

### Шов приложения (Dart)
- Сгенерирован Dart-стаб ExtensionHost; панель минтит токен
  (`granted ∩ реестр`), колбэки моста ходят в ядро; события цензуры
  стримятся в панель на время её жизни; revoke при закрытии.
- **Write-through**: успешный `applyBypassLayer` пишет полную стратегию
  в app-слот `antidpiStrategyJson` (+source); `buildPlan` использует
  слот целиком в обеих точках (bypass outbound и zapretWithVpn);
  правка legacy zapret-полей пользователем слот очищает (user wins).
- **Стор расширений поднят на уровень приложения**: `Sora.extensions`,
  `main()` грузит стор до первого Connect, revocation-sweep на старте
  чистит слот отозванного расширения (restart-replay тест).
- Сообщение ядра при invalid-argument доходит до панели
  (`{error: код, message: текст}`, `.code` контракта не сломан).
- Документация: `docs/extensions-api.md` (методы/событие/семантика),
  `sora-ext.d.ts`, мок `sora-ext serve` (слой в памяти, честно
  помеченный мок-победитель валидной 29-полевой стратегии).

## E2E — доказано фактами (core/control/antidpi_*_test.go)
- Реальный `anti-dpi.soraext` установлен через `OpenBytes` +
  `SideloadConsent` + `Store.Install` + `SetEnabled` в сервер,
  собранный как прод (main.go wiring, один LayerStore на host и merge).
- Apply пресета `sni_block/fake-autottl-badseq` → план несёт стратегию;
  state: source=extension, pending сброшен; user-стратегия побеждает;
  bindings → outbound+правило, конфликт с user-правилом → пропуск.
- **Argv из построенного плана**: nfqws — `--dpi-desync=fake`,
  `--dpi-desync-autottl`, `--dpi-desync-fooling=badseq`,
  `--filter-tcp=80,443`, `--filter-l7=tls`; tpws — `--tlsrec=sniext+1`.
- Гейтинг: read-only токен → Apply PermissionDenied; write-only →
  чтения PermissionDenied; ttl+auto_ttl → InvalidArgument; MintToken
  сверх granted → PermissionDenied; по каждому из 6 RPC есть
  поведенческие тесты, матрица из 10 RPC запинена (мутации ловятся).
- Disable: ранее выданный токен → Unauthenticated, MintToken →
  NotFound, новый план без слоя (ядро в исходном состоянии).
- TuneDesync через Host: честный завершённый поиск (attempts>0, winner
  пуст, has_strategy=false), неизвестный engine → InvalidArgument.
- Свип: 15/15 пресетов применимы в заявленной области (12 global +
  3 bindings по midsni-семантике) и рендерятся на своих бэкендах.
- **Пакетный сценарий**: DPI-симулятор на loopback сбрасывает прямой
  ClientHello с непрерывным SNI (PASS, origin не получил ничего).
  Tpws-лег — честный SKIP с измеренными причинами: SOCKS-ruleset tpws
  режет loopback-цели (reply 0x02), не-loopback egress перехватывает
  песочница, transparent-режим невозможен (нет root-модулей/
  IP_TRANSPARENT). Полные ассерты (≥2 сегмента, SNI разорван,
  байт-идентичность) стоят в тесте и сработают на dev-машине/хосте,
  где SOCKS-dial проходит.

## Ревью: два REJECT — оба сняты повторными проверками
- Ревьюер Go-шва: M1 merge мог уронить чужой Connect (длинный match →
  имя >256 байт; XrayProfile-alone), M2 расхождение версий 1.13/1.14,
  M3 гейтинг не запинен тестами, M4 дрейф конвертеров не ловился;
  L1–L3 (state для disabled, точечные конфликты, память/диск).
  Всё закрыто фиксами + тестами, ре-ревью — **APPROVE**, мутационная
  ценность подтверждена. По дороге исполнитель сам нашёл и исправил
  реальный дедлок в GetBypassState (db4b66a1) и честно поправил свой
  ранний «всё зелёно» (exit-код маскировался пайпом).
- Ревьюер Dart/пакета: M1 потеря сообщения ядра, M2 слот переживал
  рестарт, M3 молча усекающий импорт; L1–L6 (мок, badack в подсказке —
  унаследован из proto-комментария, шкала score, updated_at, гонка
  минта, хардкод-лейбл). Всё закрыто, ре-ревью — **APPROVE** (включая
  независимое исполнение bootstrap-шима и контрольную порчу пакета —
  validate ловит). Внеплановая находка фиксера: bootstrap-JS в HEAD
  был синтаксически сломан (`() {}` без `=>`) — `window.soraExt` в
  реальной панели не поднялся бы; исправлено и запинено node-тестом,
  исполняющим шим из bridge.dart.
- Инциденты общего индекса: 4 staged-revert эпизода за сессию (до
  −4967 строк) нейтрализованы точечно, HEAD и worktree ни разу не
  пострадали; все коммиты — temp-index+CAS/pathspec.

## Честные границы и остаток владельцу
- **Подпись пакета — dev-ключ** (свежий, публичный
  `RWQYfCIDnu/KtVRZb+LSWz3XSNHmwm9FFuccBGlciohMdIeYYvQ7uk4L`, секрет
  уничтожен). Публикация в каталог магазина — после key ceremony
  владельца; до неё установка — sideload, как задокументировано в
  гайде `docs/extensions/anti-dpi.md` и LISTING.md.
- **JS-исполнитель воркеров** — решение владельца; плагину не нужен:
  он построен на панельной + декларативной модели, работающей сегодня.
- Скриншоты для листинга: **pending** — на VM нет chromium/firefox/
  playwright; в LISTING помечено, не выдумано.
- Платформы по факту bypass-путей: Linux — tpws+nfqws полностью;
  Windows — tpws-подмножество (winws остаётся спекой ядра, не плагина);
  macOS/Android — bypass-путей в продукте нет, панель честно показывает
  capabilities с причинами. Плагин как пакет платформенно-независим.
- Живой tpws-прогон сквозь симулятор — на dev-машине (см. E2E выше);
  живой SFU/туннель — вне объёма плагина.
- Мелочи вне объёма (зафиксированы, не скрыты): комментарий
  `BypassStrategy.fooling` в proto по-прежнему перечисляет `badack`,
  которого ядро не принимает (панель исправлена, proto-комментарий —
  отдельной правкой с регенерацией); предсуществующий warning
  `unused_import` в panel_screen.dart:18 (от 2026-10-19); проверка
  plain-domain в панели на патологических входах строже ядра
  (безопасное направление).
- Известный чужой тайминг-флейк `TestWaitWhilePausedRePauseBeforeWakeup`
  (пакет ext, не antidpi-зона) один раз падал под нагрузкой VM; в
  повторных и финальных прогонах зелён.

## Финальная верификация координатора (HEAD a30da220)
- `go build ./...` (core) — OK; `go test ./ext/ ./control/ -count=1`
  (TMPDIR=/tmp) — ok ext 7.5s, ok control 10.9s (включая весь
  AntiDPI E2E на перепакованном пакете).
- `sora-ext validate extensions/anti-dpi/anti-dpi.soraext` — valid,
  единственное предупреждение — ожидаемое dangerous-permissions.
- `node extensions/anti-dpi-tests/panel.test.js` — 21/21.
- Дерево и индекс чисты (кроме чужого untracked
  `app/test/fuzz_mutation_test.dart` волны B — не тронут).

## Коммиты `[antidpi]` (27)
Ядро: 8a8b8be1, 400c4dc9, 91f3522a, db4b66a1 (дедлок).
Dart: 2efd3e4c, 9afc6cdf, 15b9c469, a10c383b, e2767336.
Пакет: db5394f9, 2d804dee. E2E+гайд: d8886f07, b97f6d54.
Фиксы ревью A: ed9ad858, d63390d3, 983f8f1e, e3a2b2e5, b5d34b5b.
Фиксы ревью B + перепаковка: 5db0b6c5, 64b5bd7c, a4caf1ff, 49a396b1,
85448620. Docs: a30da220 (proto README 1.14).
