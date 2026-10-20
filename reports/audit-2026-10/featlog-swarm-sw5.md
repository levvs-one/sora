# featlog-swarm-sw5 — авто-тюнинг DPI (пакет `core/tune`)

Ветка `bugfix/audit-2026-10-19`, всё локально, пуша нет. Тронуты только `core/tune/*`
(новые файлы) + этот лог. Чужие пакеты не правились.

## Что сделано

Новый пакет `core/tune` — автоматический подбор рабочей обфускации при
неудачном подключении. Файлы:

- `core/tune/doc.go` — описание пакета и контракта;
- `core/tune/strategy.go` — `Strategy`, порядок кандидатов, пресеты,
  zapret-альтернативы, `Lookup` по стабильному ID;
- `core/tune/cache.go` — пер-сетевой кэш успеха (`tune/cache.json`, 0600,
  TTL 30 дней);
- `core/tune/tuner.go` — `Tuner`, клампинг лимитов, цикл попыток, `Result`
  с честной телеметрией;
- `core/tune/tune_test.go` — 22 теста, включая негативные.

Проверки: `gofmt` чист, `go vet ./tune/` чист, `go test -race ./tune/` — все
зелёные.

## API (для интегратора сессии)

```go
cache := tune.NewCache(dataDir)              // тот же dataDir, что у profiles.NewStore
tuner := tune.New(tune.DefaultOptions(), cache)

attempt := func(ctx context.Context, s tune.Strategy) error {
    plan := applyStrategy(basePlan, s)       // см. таблицу ниже
    return probeConnection(ctx, plan)        // nil = подключилось
}
res, err := tuner.Tune(ctx, fp, tune.CurrentStrategy(), attempt)
// Телеметрия в журнал сессии:
s.log.Append(session.Event{Kind: session.EventLog, Detail: res.Summary()})
```

Порядок кандидатов: `current` → запомненная для этой сети (если есть, без
дублирования) → `preset/balanced` → `preset/max` → 4 zapret-альтернативы.
Первая успешная запоминается (`Remember`) и в следующий раз в знакомой сети
оказывается в голове очереди. В новой сети — дефолтный порядок.

Таблица маппинга `Strategy.ID` → действие в `AttemptFunc` (сессия уже
импортирует эти пакеты):

| ID | Действие |
|---|---|
| `current` (`tune.IDCurrent`) | план как есть, просто перепроверить |
| `preset/balanced` (`tune.IDBalanced`) | применить `obfs.PresetBalanced` к пробам/диалу |
| `preset/max` (`tune.IDMax`) | применить `obfs.PresetMax` |
| `zapret/split-oob`, `zapret/disorder`, `zapret/tlsrec`, `zapret/http-case` | `outbound.Bypass = &s.Bypass` (`s.HasBypass == true`) для bypass-outbound'ов |

Фингерпринт сети: `profiles.Fingerprint` (тот же, что в F5). Ключ кэша =
`SSID + Gateway + ASN`; интерфейсная строка (`Fingerprint`) намеренно не
входит — она для отображения и churn'ится при DHCP/SLAAC (ложный miss стоит
дешевле ложного hit'а).

Лимиты (всё клампится в `Options.Normalize`): стратегий 1–32 (дефолт 8 =
весь список), таймаут попытки 1с–2мин (дефолт 15с), общий бюджет =
таймаут…10мин (дефолт 2мин). Отмена пользователем — через `ctx`; при отмене
`Tune` возвращает `ctx.Err()` честно, а не «стратегии не подошли».

Ошибки: `tune.ErrNoStrategy` (все перепробованы; текст перечисляет ID и
последнюю ошибку), `tune.ErrBudget` (бюджет исчерпан до перебора всех).
`Result.Summary()` — одна строка для журнала, напр.:
`tune: strategy "preset/max" worked after 3 attempt(s) in 11.2s`.

Рекомендация интегратору: при распознавании знакомой сети пре-применять
запомненную стратегию к плану (тогда `current` == запомненная и она идёт
первой без дубля — покрыто тестом `TestTunePreappliedCachedStrategyTriedOnce`).
Точка вставки — путь переподключения в `core/session/runner.go`
(рядом с существующими `s.log.Append(...)`), плюс сброс/перезапуск тюнера
при `EventNetwork`.

## Отклонено фильтром слопа (не внедрял, причины)

1. **Собственные zapret-пресеты Balanced/Max в тюнере** (первый черновик:
   `SplitPos: ["sniext+1"]` и комбо с disorder). Вырезано: это были мои
   догадки, дублирующие настоящий API параллельного агента
   (`obfs.PresetBalanced`/`obfs.PresetMax`). Недодуманное — не внедрять.
   Пресеты теперь только ID-ссылки на `core/obfs`.
2. **Прямой импорт `core/obfs` в `tune`**. Отклонён: тюнеру содержимое
   профилей не нужно вообще (он их не применяет) — зависимость была бы
   write-only и тянула бы за собой пакет, который в момент работы дважды
   не компилировался из-за правок соседнего агента. Минимализм: `tune`
   зависит только от `core/profiles` (+ `core/engine` ради структуры
   `BypassStrategy` для zapret-вариантов, которые определяет сам тюнер).
3. **Хранение слепка `BypassStrategy` в кэше**. Вырезано: кэш хранит только
   `strategy_id` + время; параметры резолвятся через `Lookup`. Проще,
   переживает изменение структур движка.
4. **Включение интерфейсной строки в ключ кэша**. Отклонено: churn при
   DHCP/SLAAC давал бы ложные miss'ы; идентичность сети = SSID+Gateway+ASN,
   как в триггерах самих F5-профилей.

## Замечания по дереву (не моё, не трогал)

- `core/obfs/utls.go` в ходе работы один раз не проходил `go vet` (несоответствие типов
  `tls.Certificate` vs `utls.Certificate`), позже собирается — соседний
  агент правит на лету. Маппинг `preset/*` → `obfs.Preset*` сверен с
  `core/obfs/profile.go` (сигнатуры `PresetFast/Balanced/Max`, поля `Profile`).
- `go vet ./tune/` один раз упал с `undefined: validateHysteria2Tuning` в
  `core/engine` — файл дописывался конкурентом в тот же момент; повторная
  сборка чистая. Мой пакет от этого не зависит напрямую, кроме типа
  `engine.BypassStrategy`.
- Коммит будет `[swarm] ... (SW5)`, без пуша, только `core/tune/*`.
