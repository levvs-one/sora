# Fix log — sora-legacy, Раунд 2 (верификация + добор)

**Агент:** аудитор-верификатор. **Ветка:** `bugfix/audit-2026-10-19` (пуша нет).
**Дата:** 2026-10-19. **База:** 25 коммитов раунда 1.
**Контекст:** `FIX-PLAN.md`, `sora-legacy-audit.md`, `fixlog-legacy-go.md`, `fixlog-legacy-csharp.md`.

Коммиты раунда 2: `[audit-fix][legacy-r2] ...`.

---

## 1. Проверка раунда 1 (spot-check)

Проверено `git show` + чтением файлов; C# — ручная вычитка синтаксиса
(типы, using, скобки, async/await), т.к. тулчейна нет.

| Коммит | ID | Результат |
|--------|----|-----------|
| e31f0fc `UpdateHandle.cs` | LEGACY-H1 | OK. `CompareVersions`/`ParseVersionParts` корректны; `VerifyCoreArchiveAsync` — сигнатуры `DownloadStringAsync(string,string,string)`, оба `SaveLog`, `GetDownloadFileName` совпадают; `using SHA256`/`File.OpenRead` парные; `async`-лямбда на `UpdateCompleted` допустима (event `EventHandler<T>` → async void). Замечание: в промежуточном состоянии `_ = DownloadFileAsync(...)` при `void`-сигнатуре не скомпилировалось бы, но следующий коммит L9 (2401981) перевёл метод на `Task` — на tip'е всё сходится. |
| ae3b541 `AddServer2Form.cs`+`ConfigHandler.cs`+`Utils.cs` | LEGACY-H3 | OK. `using System.IO`/`System.Diagnostics` на месте; `GetConfigPath()` — default-параметр; `UI.Show(string)` существует; `IsAllowedCustomConfigExtension` покрывает `.json/.yaml/.yml`; traversal-чек через `GetFullPath`+префикс корректен. |
| 1e6ef47 `MainForm.Community.cs` | LEGACY-H2 | OK. `using System.IO` добавлен; `UI.ShowYesNo`/`ShowWarning` существуют; `SaveConfig(ref config, false)` — сигнатура совпадает; probe-файл через `Guid` уникален, `catch` → false. |
| 816fcdf `V2rayHandler.cs` | LEGACY-M9 | OK. `IsKnownCoreProcess`: `MainModule?.FileName` с catch `Win32Exception`/`InvalidOperationException`; `LazyConfig.GetCoreInfo` существует, `coreExes` — `List<string>`; сравнение с/без `.exe` покрывает оба формата; `using` для `Process`. |
| 2401981 `DownloadHandle.cs`+`UpdateHandle.cs` | LEGACY-L9 (+H1 downgrade) | OK. `DownloadFileAsync` → `async Task`, `CancelAfter`, CTS в `using`; downgrade-чек `CompareVersions(version, curVersion) <= 0` на месте в финальном состоянии (строка 602). |
| d4570a2 `UpdateHandle.cs` | LEGACY-M10 | OK. `using (Process p)`, `Kill()` при `!WaitForExit(5000)` + повторный `WaitForExit(1000)`; `return version` внутри using; `killEx` использован. |
| 3b5b7b8 `SysProxyHandle.cs` | LEGACY-M11 | OK. `QuoteArgument` в обеих ветках `SetIEProxy`. |
| b6cadf6 `FileManager.cs` | LEGACY-L8 | OK. Zip-Slip: `GetFullPath(Combine(baseDir, entry))` + префикс-чек; мёртвый `v2rayUpgrade` удалён. |
| 6a2e94f `Program.cs` | LEGACY-L11b | OK. `IsOwnExecutableRunning`: fail-closed при ошибке проверки, `Dispose()` в `finally`, сравнение `MainModule.FileName` с exe-путём. |
| Go (все) | H5/M2–M7/L2–L6 | `go build ./...` OK, `go vet ./...` OK, тесты `control/ipc/parser/probe/subscription/secret/supervise/registry/guard/xray` зелёные. |

**Ошибок раунда 1 не найдено.** C# собрать нечем — вычитка ручная двойная, все внешние
ссылки (методы, overload'ы, using) сверены с кодом.

---

## 2. Свежий поиск (grep)

| Паттерн | Итог |
|---------|------|
| `exec.Command`/`LookPath` (Go) | Проверено 8 точек. `binary.go:59`, `process.go:57,182`, `tunroute_linux.go:141,165,353`, `nftables_linux.go:135` — пути либо digest-верифицированы (H5), либо литералы/абсолютные. **Ложные.** `tunroute.ip()`: сборка argv строкой + `strings.Fields` хрупка, но `DeviceName` — серверная константа (`control/plan.go:172` → `engine.TunDevice`), из сети недостижима — **не эксплуатируется**, зафиксирована как наблюдение. |
| `Process.Start`/`UseShellExecute` (C#) | 15 точек. `MainForm.Community.cs:1185` (`OpenSoraCommunityLink`) — только хардкод-https URL'ы. `SoraMarkdownView.cs:346` — `TryGetSafeUrl` режет всё кроме http/https. `explorer.exe /select` — путь из `SpecialFolder`+timestamp или `SaveFileDialog`, кавычки экранированы, `"` в путях Windows невозможна. `MainForm.cs` — константные URL. `OptionSettingForm.cs:337` (`EnableLoopback.exe`) — собственный бинарь из каталога приложения (та же модель доверия, что H2). **Ложные.** |
| `InsecureSkipVerify`/`*ValidationCallback` | Нет срабатываний. |
| `http.DefaultClient` | **`core/engine/xray/engine.go:151` — НАЙДЕНО (NEW).** Метрики `http://127.0.0.1:port/debug/vars` через `DefaultClient` → honoring `HTTP_PROXY` у VPN-пользователей роняет/уводит метрики в прокси. Исправлено: выделенный клиент с `Transport{Proxy: nil}` (коммит 0fedd1a). `supervisor_test.go:101` — только тест. |
| `panic(` | `core/session/manager.go:56` — guard конструктора на nil Factory (программная ошибка, из сети недостижимо). Остальное — `core/testdata` (тест-хелперы). **Ложные.** |
| `0600/0700/0777` | Все точки — 0700 на каталоги, 0600 на файлы секретов/токенов; `enginetest` 0700 — тест-хелпер с nolint. **Ложные.** |
| `TODO/FIXME/XXX/HACK` | Нет (кроме ложного `askToDownload`). |
| `Convert.To`/`int.Parse` без try | `ShareHandler.cs:635` `int.Parse(port)` — группа regex `\d+`, outer `catch (Exception)` в `ImportFromClipboardConfig` гасит overflow → graceful. `Utils.ToInt/ToBool` — обёртки с try. **Ложные.** |
| `new Mutex(` | `Program.cs:132,139` — L11b-фикс на месте, fail-closed. **Ложные.** |

### Новые баги, найденные и исправленные в R2

1. **NEW-R2-1 (C#, Low): undisposed `HttpClient` в `DownloadHandle`.**
   `DownloadFileAsync` и `UrlRedirectAsync` создавали `new HttpClient(...)` без `using` —
   сокеты висели до финализатора при каждой проверке обновлений. Исправлено: `using` для
   клиента и `HttpResponseMessage`; заодно null-safe `Location?.ToString()` в `UrlRedirectAsync`
   (метод — мёртвый код, вызовов нет). Коммит d8e814d.
2. **NEW-R2-2 (Go, Low/Medium): `http.DefaultClient` для loopback-метрик xray.**
   См. таблицу выше. Исправлено коммитом 0fedd1a.
3. **NEW-R2-3 (C#, Medium): fail-closed SHA-256 для geo-файлов (LEGACY-H1 geo-часть, добор).**
   Раунд 1 пропустил: манифест не был подтверждён. В R2 подтверждено через GitHub API:
   `Loyalsoldier/v2ray-rules-dat` публикует `geoip.dat.sha256sum` / `geosite.dat.sha256sum`
   по предсказуемым URL (`.../releases/latest/download/{name}.dat.sha256sum`), формат —
   `"<64hex>  <filename>"` (проверен live-запросом). Реализован `VerifyGeoFileAsync` +
   async-хендлер в `UpdateGeoFile`: сверка до замены рабочего файла, mismatch/недоступность
   манифеста → отклонение + удаление скачанного. Downgrade к geo неприменим (версий нет).
   Коммит d8e814d.

---

## 3. Добор пропусков

| Пункт | Статус |
|-------|--------|
| LEGACY-M8 (unpinned actions, curl\|bash, govulncheck@latest) | **DONE**, коммит 960f480. Все 11 `uses:` запинены по SHA (SHA взяты из GitHub API на 2026-10-19, рядом комментарий с тегом — dependabot для github-actions настроен и умеет обновлять SHA-пины). `bash <(curl …/download-actionlint.bash)` заменён на скачивание релизного архива `actionlint_1.7.7_linux_amd64.tar.gz` с проверкой SHA-256 (`023070a2…e0757` из официального `actionlint_1.7.7_checksums.txt`). `govulncheck@latest` → `v1.9.0` (latest на proxy.golang.org). `grep -r "@v[0-9]" .github/workflows/` пуст. |
| LEGACY-H1 geo-хэши | **DONE** (см. NEW-R2-3 выше). |
| LEGACY-H1 Authenticode | Остаётся пропуском: официальные сборки Xray/v2fly не подписаны — требование подписи сломало бы обновления; minisign-ключи — за владельцем (раздел 9 FIX-PLAN). |
| LEGACY-H2 вариант A (per-machine установщик) | Остаётся пропуском: меняет модель установки, требует миграции и тестов (причина из R1 в силе). |
| LEGACY-H6/H7/H8/M12/M13 (Android) | Остаются пропусками: кода нет, это новая разработка; security requirements зафиксированы в `docs/android-security-requirements.md` (R1). |

---

## Проверки

- `go build ./...` — OK; `go vet ./...` — OK.
- `go test ./...` — зелёные, кроме `TestTunAndFakeIPAvoidLANAndEachOther` (core/engine):
  падает и на чистом дереве (зафиксировано в R1 — окружение: fake-IP pool пересекается
  с интерфейсами хоста). Пакет `core/engine` в R2 не трогался.
- C#: тулчейна нет — все правки вычитаны вручную, внешние ссылки сверены.

## Сводка раунда 2

- Проверено исправлений R1: **10** (8 C# вычитаны вручную + Go build/vet/tests) — ошибок **0**.
- Новых багов найдено: **3** (NEW-R2-1, NEW-R2-2, NEW-R2-3) — исправлены **3**, закоммичены.
- Добор пропусков: **LEGACY-M8 done**, **LEGACY-H1 geo done**.
- Осталось открытых (сознательные пропуски, требуют владельца/новой разработки):
  Authenticode-гейт, per-machine установщик (H2-A), Android H6/H7/H8/M12/M13.
- Коммиты R2: `960f480`, `d8e814d`, `0fedd1a` на ветке `bugfix/audit-2026-10-19`. Пуша нет.
