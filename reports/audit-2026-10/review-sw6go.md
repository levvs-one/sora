# Review: SW6 Go — background workers + net.fetch (роя, Go-часть)

- Репо: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`
- Ревьюировался коммит `c1be5ee` (`[swarm] background workers + net.fetch for extensions v2 (SW6)`),
  после rebase'а ветки идентичное содержимое живёт как `2551170` (`git diff c1be5ee 2551170` — пуст).
- Объём: 7 новых файлов в `core/ext/` (1742 строки): `manifest_v1ext.go`, `netfetch.go`,
  `worker.go`, `extlog.go` + 3 тест-файла.
- Утверждение автора «`host.go`/`store.go`/`manifest.go` не тронуты» — **подтверждено**
  (`git diff 2551170^ 2551170` по этим файлам пуст). В рабочем дереве есть чужой
  незакоммиченный WIP другого отдела (`core/ext/host.go`, мелкий lint-чистка
  `WatchExtensionEvents`) — не трогал, в свой коммит не включаю.
- Проверки: `go build ./ext/`, `go vet ./ext/`, `go test ./ext/ -count=1`,
  `go test -race` (многократно), `gofmt -l` — всё чисто.
  (Замечание: `go build ./...` всего модуля падает в `cmd/sora-core` —
  предсуществующая поломка другого отдела, proto/control mismatch, не моё.)

## Вердикт

**Принять с исправлениями.** Базовый дизайн грамотный: deny-by-default allowlist,
перепроверка редиректов, bounded логи, clamp интервала, recovery паник, двухпроходный
парсинг манифеста без ломки v1. Найдены и исправлены 3 реальные дыры + 1 вырезанный
слой слопа (см. «Исправлено»). Остались замечания ниже — некритичные, на усмотрение
автора/parent'а.

## Исправлено (коммит `[swarm-review]`, только мои 5 файлов)

Все три дыры сначала воспроизведены **падающими тестами** на pre-fix коде, затем
пофикшены; тесты теперь зелёные.

1. **Утечка секретов в аудит-лог (приватность).** `safeMethodURL` писал в лог полный URL
   включая query (`?api_key=...`) и fragment — а лог расширения показывается в UI
   приложения. Теперь query/fragment/userinfo вырезаются из лог-строки
   (`netfetch.go`). Тест: `TestFetchQueryNotLogged` (allowed + denied запросы).
2. **Обход запрета IP-литералов через нестандартные нотации.** `net.ParseIP` не понимает
   `2130706433` (decimal), `0x7f000001`/`0x7f.1` (hex), `017700000001` (octal) — а
   `normalizeHostPattern` их принимал как «DNS-имена», и `checkURL` пропускал.
   На pure-Go резолвере они не резолвятся (проверено эмпирически), но на cgo/glibc
   (`inet_aton`) — резолвятся в IP: SSRF-вектор обхода allowlist-политики.
   Добавлен `isIPLike` (manifest_v1ext.go), используется и в валидации манифеста,
   и в `checkURL`. Легитимные хосты не страдают (числовых TLD не существует).
   Тест: `TestFetchRejectsIPLikeHosts`.
3. **Ticker loop переживал Unregister / дублировался при re-Register (lifecycle).**
   `Unregister` только удалял задачу из map — горутина продолжала тикать и выполнять
   воркер до `Stop()`; повторный `Register` запускал второй loop (двойное выполнение).
   Теперь у `WorkerTask` свой `ctx`/`stop`, derived от run-контекста планировщика:
   `Unregister` и `Register`-replace гасят старый loop. Тесты:
   `TestUnregisterStopsTaskLoop`, `TestRegisterReplacesTaskStopsOldLoop`.
4. **Слоп: вырезан фейковый `granted []string` из `Fetcher.Fetch`.** Параметр выдавал
   caller'ом (`WorkerEnv` передавал хардкод `[]string{"net.fetch"}`) и не мог быть
   security-check'ом. Право теперь enforced в единственном месте конструирования
   (`Scheduler.Register` проверяет `hasPermission(m, "net.fetch")`), nil-fetcher
   fail-closed в `WorkerEnv.Fetch`. Удалён мёртвый `hasString`, обновлены тесты
   (тест `TestFetchDeniedWithoutPermission` удалён как потерявший premise —
   сценарий покрыт `TestWorkerEnvFetchNeedsNetFetchPermission`).

## Проверено вручную (атаки не прошли)

- Allowlist: `*.example.com` не матчит голый `example.com` и `evilexample.com`
  (требуется `.`-граница); exact-запись не матчит поддомены; case-insensitive;
  trailing dot ок.
- Редиректы: каждый hop перепроверяется `checkURL` (max 3); 302 на http/userinfo/
  IP/порт/вне allowlist — denied.
- `https://user:pass@host`, `https://host:8443`, `https://[::1]`, `http://`,
  `ftp://`, lookalike `sub.example.com.evil.com` — всё denied (есть тесты).
- Backslash-userinfo (`https://a\@evil.com`) — Go роняет парсинг, denied.
- Процент-энкодинг хоста (`%61pi.example.com`) unescape'ится до проверки — матчится
  корректно, обхода нет.
- Манифест: двухпроходный парсинг бит-в-бит совместим (RawMessage переизлучается
  как есть; порядок ключей/пробелы/дубликаты ведут себя как прямой decode);
  неизвестные ключи отвергаются и в v1-части, и в ext-части (`DisallowUnknownFields`);
  `interval_minutes` валидируется 1..10080, runtime clamp [15мин, 7дней];
  `entry` — относительный `.js` без `..` и ведущего `/`.
- Лимиты: rate 30/мин + burst 10 (token bucket), тело запроса 1 МиБ, ответа 8 МиБ
  (читается через LimitReader, over-limit → denied), таймаут 30с на запрос через
  context (дедлайн общий и на редиректы), воркер 5 мин на run, паники recover'ятся
  и логируются.
- Логи: ring-buffer 256 записей/расширение, сообщение ≤1024 (truncate в двух местах),
  `Entries()` возвращает копию. `LogHub` создаёт логи по требованию; `Drop` есть.

## Осталось / замечания (не фиксил — на решение автора)

1. **Маршрутизация трафика net.fetch.** `Fetcher` использует дефолтный транспорт —
   запросы идут системным сетевым путём. Для VPN-клиента это вопрос: должен ли
   трафик расширений идти через туннель (иначе — раскрытие IP пользователя
   сторонним API). Это уже host/Dart-интеграция, в Go-части скоупа нет — но решение
   нужно зафиксировать до релиза.
2. **IDN.** Unicode-allowlist отклоняется (`dnsLabelPattern` — только ASCII), работает
   только punycode; unicode-хост в запросе просто не сматчится (deny-by-default —
   безопасно, но стоит задокументировать).
3. **`Stop()` ждёт in-flight runs через `wg.Wait()` без таймаута.** Если host-side
   JS-раннер проигнорирует `ctx` (5-мин дедлайн), `Stop()` повиснет навсегда.
   Раннер — код хоста, не расширения, так что это не уязвимость, но стоит либо
   задокументировать контракт «раннер обязан уважать ctx», либо добавить bounded wait
   с warning'ом в лог.
4. **Кастомные заголовки расширения форвардятся Go на редиректы** (стандартное
   поведение `net/http`: `X-Api-Key` и т.п. уедут на другой allowlisted хост при
   кросс-хост 302). Оба хоста — в allowlist расширения, так что low; при желании —
   сносить extension-заголовки при смене хоста в `CheckRedirect`.
5. **`LogHub.logs` растёт по числу extID** — bounded числом установленных расширений;
   предполагается, что host вызывает `Drop` при uninstall (проверить в host.go/Dart
   при интеграции).
6. **Единичный flake `-race`.** Один из первых прогонов `go test -race` упал, после
   — ~10 чистых прогонов (включая `-count=3` и прицельно тайминг-тесты ×5).
   Воспроизвести не удалось; источник не локализован. Стоит прогнать `-race`
   на CI несколько раз.
7. Мелочь: `Fetch` мутирует копию `req.Method` (`req.Method = method`) — безвредно,
   но шумно; `logf`/`Append` оба truncate'ят до `MaxLogMessage` — дублирование
   безвредно.

## Тесты

Было 35 тестов (по заявлению автора — фактически больше с субтестами), все проходили.
Добавлено 4 новых: `TestFetchQueryNotLogged`, `TestFetchRejectsIPLikeHosts`,
`TestUnregisterStopsTaskLoop`, `TestRegisterReplacesTaskStopsOldLoop`; удалён 1
устаревший (`TestFetchDeniedWithoutPermission`). Непокрытое, что сознательно оставил:
гонку `Stop()` vs зависший раннер (п.3 выше — host-side), поведение при cgo-резолвере
(покрыто кодом `isIPLike`, но тестовый стенд — pure Go).
