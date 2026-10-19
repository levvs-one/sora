# uTLS freshness gate (S3)

Падающий CI-job, а не тихий warning: протухший фингерпринт — это не
«технический долг», а неработающий VPN (Chrome 133 блокировался ТСПУ в
октябре 2026, пока алиас `chrome` всё ещё указывал на него). Поэтому job
краснеет, а не пишет в лог.

## Что проверяет `check.py`

1. **Отставание utls (A).** Пин `refraction-networking/utls` в `core/go.mod`
   против tip дефолтной ветки upstream (GitHub API). Падает, если пин старше
   tip более чем на **30 дней** (`S3_LAG_LIMIT_DAYS`).
2. **Эталонный JA4 (B).** Текущий Chrome stable (официальный Google Version
   History API) против `chrome_version` в `known_ja4.json`. Падает, когда
   Chrome stable ушёл вперёд: эталонный JA4 и parrot в utls могли протухнуть.
3. **Согласованность (C).** `known_ja4.json` обязан совпадать с
   `core/engine/fingerprint.go` (`CurrentChromeVersion`, `ReferenceChromeJA4`).
   Падает при рассинхроне — правили одно, забыли другое.

Сетевой сбой или непонятный ответ API — тоже красный job с префиксом
`INFRA:`: неизвестное состояние не считается «свежо», это сигнал
перезапустить.

## Почему лимит 30 дней

Chrome выпускается примерно каждые 4 недели, и каждый релиз — потенциальный
новый parrot в utls (HelloChrome_155 добавлен 06.10.2026). Отставание дольше
одного релизного цикла означает, что свежий parrot уже существует, а пин его
не содержит. 30 дней — это «один пропущенный релиз Chrome + запас», а не
«каждый коммит upstream» (utls коммитит мелочь вроде обновления CI — на неё
реагировать не нужно).

## Что делать, когда job красный

- **FAIL utls lag** — `cd core && go get github.com/refraction-networking/utls@<новый-коммит>`,
  затем `go build ./... && go vet ./...`; убедиться, что `HelloChrome_Auto`
  в новом utls совпадает с эталонным JA4 (JA4 self-check в диагностике);
  если Chrome заодно обновился — см. следующий пункт.
- **FAIL chrome stable** — руками снять JA4 с брендированного Chrome новой
  версии, проверить, что в upstream utls есть `HelloChrome_<N>` parrot
  (если нет — сначала бамп utls из пункта выше), обновить `known_ja4.json`
  **и** `core/engine/fingerprint.go` (`CurrentChromeParrot`,
  `CurrentChromeVersion`, `ReferenceChromeJA4`) **и** `packaging/engines/engines.lock`.
- **FAIL fixture/code drift** — руками свести `known_ja4.json` и
  `fingerprint.go`, выяснить, какое из двух врёт.
- **INFRA** — перезапустить job; если повторяется — чинить сеть/API, код не
  трогать.

## Локальная проверка / симуляция красного

```sh
# офлайн-юнит-проверки, без сети:
python3 .github/utls-freshness/check.py --selftest

# полный прогон (нужен интернет):
python3 .github/utls-freshness/check.py

# симуляция красного по лагу utls:
S3_LAG_LIMIT_DAYS=-1 python3 .github/utls-freshness/check.py

# симуляция красного по рассинхрону фикстуры и кода:
cp .github/utls-freshness/known_ja4.json /tmp/ja4_old.json
# (понизить chrome_version в копии, например до 154)
S3_KNOWN_JA4=/tmp/ja4_old.json python3 .github/utls-freshness/check.py
```

## Ограничения (честно)

- Лаг считается по **pseudo-version** пину (`vX.Y.Z-0.YYYYMMDDHHMMSS-sha`):
  только он несёт время коммита. Пин на release-тег job не датирует и
  честно падает с `INFRA` + инструкцией, как доработать.
- Переизмерение JA4 против брендированного Chrome — ручная операция,
  job лишь детектит момент, когда она нужна.
- Авто-fallback фингерпринта при TLS-timeout — не здесь, это отдельная
  задача (другой агент).
