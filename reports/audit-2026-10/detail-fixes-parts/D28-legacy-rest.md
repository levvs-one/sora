# D28 — sora-legacy Go остаток: probe, routing, secret, session, subscription (коммиты 184460c, 5b626d4, 49bc569)

## Непрокинутый параметр: ManagerConfig.NetworkInterval
- Было: session.Config имел NetworkInterval (дефолт 2s), ManagerConfig — нет, Connect не передавал → всегда дефолт.
- Стало: поле в ManagerConfig, дефолт в NewManager, прокинуто в Connect. Поведение по умолчанию не изменилось.
- Тесты TestManagerPassesTheNetworkIntervalToSessions / TestManagerDefaultsTheNetworkInterval — PASS.

## Хардкод: dial подписок игнорировал Options.Timeout
- Было: net.Dialer{Timeout: 30s} хардкод; при Timeout: 120s dial резался на 30s.
- Стало: dialChecked(timeout) с бюджетом из опций (фолбэк DefaultTimeout при <=0); obfs-обёртка использует ту же функцию.
- Тесты: TestTheDialerHonoursTheFetcherTimeout (+), TestADialIsBoundByTheFetcherTimeout (−) — PASS.

## Хардкод: fingerprint знал только sora0
- Было: NetworkFingerprint() исключал только "sora0", а не Plan.Tun.DeviceName → кастомное имя TUN давало ложные «смены сети» → renewConnections → флаппинг.
- Стало: networkFingerprint(device) параметризован; networkProbe() использует фактическое имя; публичный NetworkFingerprint() без изменений.
- Тесты TestNetworkProbeExcludesThePlansOwnTunnelDevice / TestNetworkProbeKeepsTheInjectedProbeForTheDefaultDevice — PASS.

## Кавеат
- Зона — допущение (следов D25–D27 не найдено): риск пересечения/пробелов — нужна сверка.
- Осознанно не тронуто: probe.go отполирован; secret UserAgent="sora-core/1" — маркер контракта; дубли specialUse связаны комментариями.
