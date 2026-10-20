# D13 — core/profiles (commit 689636a)

## Per-SSID модель доверия — её не было, создана
- Стало: core/profiles/trust.go — TrustStore (SSID → trusted/untrusted/none), trust.json 0600, атомарная запись, порча = fail-fast. Effective(ssid): trusted только для явно доверенной; незнакомая → untrusted; пустой SSID → none.
- Эффект: дефолт новой сети = untrusted, как у IVPN. Тесты (дефолт, снятие метки, плохие SSID, round-trip, права) — PASS.

## Per-network memory — уже была, проверена
- core/tune/cache.go: стратегия по ключу SSID+шлюз+ASN, TTL 30 дней. Тесты PASS. Не трогал.

## Эвристика ненадёжности сети — создана
- Стало: Fingerprint.Security (unknown/wired/open/wep/wpa), Risky() = open‖wep. Linux: iw link + парсинг iw scan (BSS нет → unknown, не гадаем), мемоизация, таймауты 3с/6с. Windows: netsh wlan show networks. Advisory only — на matching и кэш не влияет.
- Тесты security_linux_test.go — PASS; windows — только кросс-компиляция (нужен Windows CI).

## Открытое
- trust/security не проброшены в proto (NetworkFingerprint, ProfileMatched) и UI — нужна регенерация (buf + клиент).
- Чужие падения: tune-тесты (strategy.go расширен без обновления tune_test.go); go build падает в censor/engine/profiles — half-applied правки других агентов.
- Наблюдение: networkKey для проводных сетей с одинаковым шлюзом даст коллизию кэша стратегий.
- Инцидент: другой агент сбросил 4 трекаемых файла — переприменил 1-в-1, закоммитил.
