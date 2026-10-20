# Тотальное 5-проходное ревью: единый отчёт

**Дата:** 2026-10-19. **Ветки:** `bugfix/audit-2026-10-19` в `~/workspace/bug-hunt/sora` и `~/workspace/bug-hunt/sora-legacy` (локально, пуша нет).
**Метод:** 5 независимых воркеров по зонам, каждый — 5 проходов одной линзой по каждому файлу: (1) безопасность, (2) корректность, (3) живучесть, (4) качество кода/эстетика, (5) системы и UX. Старые находки аудита не дублировались; неверные фиксы прошлых раундов считались находками.

Частичные отчёты: `reports/review-5pass/partial-{sora-go,legacy-go,legacy-csharp,sora-dart,scripts-ci}.md`.

---

## 1. Охват

| Зона | Файлов | Проходов | Непокрытых |
|---|---|---|---|
| sora Go-ядро (`core/`, `service/`, `proto/`) | 203 (+2 gen skim, 1 proto) | 5/5 | 0 |
| sora-legacy Go-ядро (`core/`, `service/`, `proto/`, `docs/`) | 182 | 5/5 | 0 |
| sora-legacy C# (`legacy/`, `app/`) | 105 | 5/5 | 0 |
| sora Dart (`app/`, 112 .dart + C++ раннеры) | 112+ | 5/5 | 0 |
| scripts/CI (packaging, `.github`, оба репо) | 30 | 5/5 | 0 |

Исключения (осознанно, зафиксировано): `third_party/` (138 вендорных C/C++-файлов), `core/gen` (generated protobuf — skim + сверка с proto), `generated_plugin_registrant`, `*.Designer.cs`/`Properties`/`Resx` (generated).

---

## 2. Сводная таблица severity

| Severity | Найдено | Исправлено кодом | Осталось спекой |
|---|---|---|---|
| Critical | 1 | 1 | 0 |
| High | 11 | 9 | 2 |
| Medium | ~31 | ~20 | ~11 |
| Low | ~90 | ~40 | ~50 |
| Info/Trivial | ~22 | ~4 | ~18 |
| **Итого** | **~155** | **~74** | **~81** |

---

## 3. Топ критичных (через все зоны)

1. **R5-LC-2-19 (Critical, исправлено `a047e17`)** — правка аудита без тулчейна сломала компиляцию всего C#-проекта: метод `IsAppDirectoryUserWritable()` оказался вложен в тело `RestartCommunityAsAdministrator()`. Урок: C# без компилятора требует построчной вычитки + механической проверки баланса скобок.
2. **R5-SG-1-8 (High, исправлено `b07c226`)** — `Discover()` исполнял бинарь движка ДО проверки дайджеста, нарушая задокументированный инвариант SORA-H5 («rejected instead of executed»). Теперь verify-before-execute.
3. **R5-SG-1-1 (High, исправлено `72abbb8`)** — паника ядра через crafted vault с пустым секретом (`&kept[0]` на пустом слайсе) — DoS всего core.
4. **R5-SC-2-1/2-2/2-3 (High, исправлено `98794f1`)** — fail-closed фикс H1 сломал два CI-контракта и `test_update.py`: install-шаги не могли пройти никогда (нет `.minisig`/ключа), happy-path тест умирал раньше своих сценариев — ложное чувство покрытия привилегированного root-хелпера.
5. **R5-LC-1-2 + R5-LC-2-1 (High, исправлено)** — «тихие убийцы»: синглтон `HttpClientHelper`, который никогда не был синглтоном (локальная переменная тенила поле), и `IsNumberic`, всегда возвращавший `true` (валидация портов — фикция).
6. **R5-SD-2-1 (High, спека)** — мёртвый тоггл F11 `zapretWithVpn`: Dart-protobuf не содержит поле 16, `buildPlan` его не выставляет. Нужна перегенерация protoc на dev-машине + 1 строка.
7. **R5-LG-1-2 (Medium, исправлено `f31f52e`)** — DNS-rebinding TOCTOU в пробере legacy: резолв при проверке ≠ резолв при dial → оракул локальной сети. Закрыто `Control`-хуком по образцу `dialChecked`.

---

## 4. По проходам: что нашли

### Проход 1 — Безопасность
Ключевое: исполнение-до-verify (R5-SG-1-8), паника через crafted vault (R5-SG-1-1), DNS-rebinding в пробере (R5-LG-1-2) и в `publicAddr` (CGNAT/special-use считались публичными — оба ядра, исправлено), инъекция в nft-ruleset через `--bypass` (R5-SG-1-10, исправлено канонизацией netip), инъекция опций shadowsocks-плагина через `;` (R5-LG-1-5, исправлено валидацией), незакрытые HttpClient/CTS в C# (R5-LC-1-1/1-2, исправлено), supply-chain sora-воркфлоу (floating теги — запинены, R5-SC-1-1), отсутствие проверки подписей апстримов в legacy fetch.sh (портировано, R5-SC-1-3). Fail-closed minisign (H1) **проверен исполнением** — настоящий, не декорация (сквозной цикл gen→sign→verify→tamper-reject, dgst-crosscheck против живого `.dgst`).
Осталось спекой: TOCTOU verify→exec (re-verify в `Start`), Windows pipe squatting, `*.exe`-glob в WFP, BinaryFormatter→JSON, traversal-гарды, replay-защита каталога расширений (пост-ceremony).

### Проход 2 — Корректность
Самые ценные: сломанная компиляция C# (Critical выше), `IsNumberic`/`IsIP` (High), NRE при `"vmess": null`/`"inbound": []` (High, исправлено нормализацией), `blProxy: true` на кнопке «обновить без прокси» (исправлено), удаление НЕ ТЕХ правил при мультивыборе (исправлено), cross-thread `RefreshRoutingsView` (исправлено через BeginInvoke), мисклассификация `::1`→RulePort и `1.2.3.4`→RuleDomainKeyword (исправлено через netip), порты `0/-1/99999` в рендерах (исправлено диапазоном), UUID v6/v7/v8 (исправлено), `ItemReason` без лимита (исправлено cap 100), type assertion без comma-ok (исправлено в обоих ядрах), мёртвый тоггл F11 (спека — protoc). Одно ложное срабатывание отозвано с тестом-доказательством (`guardApplied` до `Apply()` — намеренная семантика).

### Проход 3 — Живучесть
Исправлено: accept-loop без backoff (флуд коннектами жег CPU), unbounded `Watch`-каналы и `SetLogSettings` в гигабайты, `GracefulStop` без таймаута, `bypass.Apply` держал мьютекс 5с, ReDoS через пользовательский regex-фильтр (таймаут 2с + fail-open), GDI-утечки (Font/Bitmap/Icon/QR), кэш языка вместо чтения реестра на каждый Translate, ретраи/таймауты в install.sh/ps1/fetch.sh. Проверено и ОК: журнал H6, supervisor retry с budget, watchdog F7, dispose всех подписок/таймеров в Dart, resubscribe с backoff.
Осталось спекой: бюджет перезапусков tpws, дебаунс импорта 4MB, O(n²) RenderSubscriptions при Probe, prune benchmark-истории, семафоры без ctx в measure-батчах.

### Проход 4 — Качество кода
Исправлено: вводящие в заблуждение комментарии (polkit, `isNetworkError`, ExportDiagnostics, checkBypass), честные ключи ошибок (`KeyInternal`/`KeyInvalidRequest`), `throw;` вместо `throw ex;`, мёртвые ветки. Найден 1 мнимый фикс прошлого раунда: NEW-1 «защита от подмены ip/nft» использовал `exec.LookPath`, который сам идёт через PATH, — переделан по-настоящему (резолв из фиксированных системных каталогов, fail-closed; `e67a005`, `f015417`). Слоп-маркеров (TODO/FIXME/HACK) в новом коде: ноль.
Осталось спекой: мёртвые классы/файлы (ProxySetting, QueryableExtension), закомментированные блоки, опечатки нейминга, русская плюрализация, O(n²) дедуп Redactor.

### Проход 5 — Системы и UX
Исправлено: расходящиеся `isBuiltInTarget` (control vs engine — теперь единый `engine.IsBuiltInTarget`, все 5 таргетов во всех рендерах), `describe()` маппит `chainUnsupported` на локализованный текст (было generic «Something went wrong»). Проверено: контракты control→session→guard/engine/secret держатся; systemd-юнит — образцовый hardening; polkit согласована с кодом; 370 l10n-ключей × 31 локаль — 100% покрытие, все `CoreFailure` маппятся; состояния loading/error/empty везде; ошибки — через семантический `palette.danger`, не захардкоженный красный; dns-экран сознательно не красит ошибки в красное.
Осталось спекой: **мёртвый `BypassSettings`** — контракт обещает фичу, ядро валидирует и молча выбрасывает (нужна реализация или честный отказ); wire-код для `CodeUnsupported`; захардкоженные `ms`/`K`/`M`/LTR/формат даты; `_appVersion='1.9.0'` в extensions (брать из PackageInfo); Linux cold-start `sora://` через D-Bus теряет ссылку (H8 закрыл только тёплый путь — нужен ручной тест).

**Вердикт по UX нового кода волны фич (F1–F11):** высокий уровень — строки через `S.of`, confirm-диалоги на опасные действия, permission-промпты, verify-пайплайн расширений грамотный. Портят картину только «недожатые» мелочи из списка спек выше — ничего архитектурного.

---

## 5. Исправлено сразу (21 коммит, без пуша)

19 коммитов `[review-5pass]` + 2 `[audit-fix][quality]` (доделка мнимого NEW-1: `e67a005` в sora, `f015417` в legacy).

**sora** (5): `72abbb8` (secret: паника/wipe/лимиты), `b07c226` (digest-before-exec, nft-канонизация), `87e5ac8` (polkit-комментарий, rebinding, маскирование IPv6, comma-ok), `77bac69` (describe chainUnsupported), `e67a005` (настоящий резолв ip/nft из системных каталогов), `98794f1` (CI-контракты H1, пины actions, ретраи загрузок).
**sora-legacy** (14): `21bf84e` (upstream-сигнатуры в fetch.sh), `a047e17` (компиляция Community.cs), `1c6ff01` (13 correctness-фиксов), `769ae3b` (HttpClient/синглтон/ReDoS/UI-поток), `e29b945` (hotkey-гарды, пустой релиз-лист), `f015417` (резолв ip из системных каталогов), `1a25f0f`/`1800571`/`10ae560`/`dc83bf1`/`9cb8dad`/`4602748`/`5bc06ec`/`f31f52e`/`5fadb0a` (legacy-go: rebinding, special-use, vault-харденинг, таргеты, валидации, вотчеры).

После каждого Go-коммита: `go build ./...` + `go vet` чисто; новые тесты проверены падением без фикса. C#/Dart/PS — без тулчейнов, каждая правка вычитана вручную (баланс скобок — скриптом).

---

## 6. Осталось: кому и что

**Владельцу (решения/доступ):**
1. Key ceremony minisign → затем: подпись `SHA256SUMS` в release job (R5-SC-1-4), catalog max-age для расширений (R5-SD-1-4).
2. Проверка ветки zypper на живой openSUSE (unsigned rpm в non-interactive).
3. Унификация discovery latest в install.ps1 на редирект (убрать rate-limited API).
4. Per-machine vs per-user установка (legacy H2-A) — решение.
5. Продуктовые мелочи: единый `autoSelect`-режим, RTL для тостов, MTU-дефолты между движками.

**На dev-машине перед мержем (тулчейны):**
1. `flutter analyze` + `flutter build` + `flutter test` (Dart без компиляции!).
2. Сборка C# (legacy) — структурная поломка уже чинена, но билд обязателен.
3. Перегенерация Dart-protobuf (`zapret_with_vpn`, поле 16) + 1 строка в `buildPlan` (R5-SD-2-1).
4. Ручной тест: Linux cold-start `sora://` при закрытом приложении; диплинки; отмена обновления.
5. Полный прогон `test_update.py` в CI (bwrap).

**Будущая работа (спеки в частичных отчётах):** TOCTOU verify→exec, pipe squatting, бюджет tpws, дебаунс импорта, O(n²) UI при Probe, реализация или удаление `BypassSettings`, честный wire-код Unsupported, зачистка мёртвого кода/комментариев.

---

## 7. Замечания по процессу

- Параллельная работа 5 воркеров на одной ветке — без конфликтов (строго disjoint-пути, проверено).
- Волна фич (F1–F11) ложилась на ветку прямо во время ревью — воркеры это отследили: sora-go проверил 5 новых файлов, Dart-воркер сделал финальный re-check новых коммитов F8/F9/F10/F11 и `ext/`+`ui/extensions/`.
- Предсуществующие окруженческие падения тестов (`TestTunAndFakeIPAvoidLANAndEachOther` — интерфейс VM `198.19.0.2/30`) — не регрессии, падают и на чистом дереве.
- Главный урок прохода: правки без тулчейна (C#/Dart) требуют построчной вычитки — поймана 1 сломанная компиляция и 1 мнимый фикс.
