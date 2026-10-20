# GROUP-G: Измерения, UX, архитектура, релизы — сводка третьего прохода

Дата: 2026-10-20. Лид группы G (работал один, без сабагентов). 10 тем → файлы `61–70` в `~/workspace/bug-hunt/reports/deep-research/`. Первый проход (WEB-RESEARCH.md) не дублируется: здесь — первоисточники (API-доки, исходники, спеки, опубликованные аудиты/модели) и точные спеки внедрения. Репо читались только.

## Файлы

| # | Файл | Тема | Ядро находки |
|---|---|---|---|
| 61 | [61-ooni-api.md](sandbox://workspace/bug-hunt/reports/deep-research/61-ooni-api.md) | OONI API | `/api/v1/measurements` + `/v1/aggregation/*` (ClickHouse); тесты `vanilla_tor/tor/torsf/psiphon/openvpn` — **`lantern` в OONI не существует**; формула риск-скора по `anomaly`-доле; офлайн-снапшот с фолбэк-цепочкой |
| 62 | [62-speedtest-methodology.md](sandbox://workspace/bug-hunt/reports/deep-research/62-speedtest-methodology.md) | Speedtest | Ookla: усечённое среднее (минус топ-2, минус нижние 22%); LibreSpeed: `count_ping=10`, grace 1.5 с, **асимметричный jitter** (`0.7/0.3` на всплеск, `0.2/0.8` на спад); замер строго через туннель с egress-проверкой |
| 63 | [63-ja4-fingerprint.md](sandbox://workspace/bug-hunt/reports/deep-research/63-ja4-fingerprint.md) | JA4 | Спека FoxIO дословно (секции, GREASE, sigalgs в исходном порядке, SNI/ALPN вне хэша); 3-уровневый stealth-check: статика → живой сервер → JA4S dest-валидация |
| 64 | [64-censorship-detection.md](sandbox://workspace/bug-hunt/reports/deep-research/64-censorship-detection.md) | Детект цензуры | blockcheck: 5 фаз (DNS→стратегии→пересечение); канарейки test+control по OONI; детектор «сибирской заморозки» (6 параллельных TLS, fp-контроль) с автосменой fp и бэк-оффом |
| 65 | [65-mullvad-app-ux.md](sandbox://workspace/bug-hunt/reports/deep-research/65-mullvad-app-ux.md) | Mullvad | Таксономия CLI, relay constraints иерархией, `-j/--json`, exit 0/1, export/import настроек, lockdown до логина; **у sora управляющего CLI нет** — только флаги демона |
| 66 | [66-ivpn-trusted-networks.md](sandbox://workspace/bug-hunt/reports/deep-research/66-ivpn-trusted-networks.md) | IVPN | Точная спека: trusted/untrusted/default, дефолт новых сетей **untrusted**, матрица действий 2×2 + block LAN; firewall как независимый контур; улучшения: SSID+BSSID, captive-probe |
| 67 | [67-singbox-codebase-tour.md](sandbox://workspace/bug-hunt/reports/deep-research/67-singbox-codebase-tour.md) | sing-box | Конвейер inbounds→router→outbounds, `box.Box`, реестр `include/registry.go`, фабрика транспортов, mux-слои; чеклист добавления протокола; CI-чек «рендер vs схема `option/`» |
| 68 | [68-update-frameworks.md](sandbox://workspace/bug-hunt/reports/deep-research/68-update-frameworks.md) | Обновления | Sparkle 2 (EdDSA+дельты+атомарность+phased), Tailscale `clientupdate` (треки, `Confirm`, re-exec), minisign trusted comment (анти-даунгрейд); дизайн staged 1%→100%, автооткат, update-over-VPN, metered |
| 69 | [69-reproducible-builds-audits.md](sandbox://workspace/bug-hunt/reports/deep-research/69-reproducible-builds-audits.md) | Аудиты | Что проверяют (Cure53/X41/Assured/ROS по отчётам Mullvad): IPC-права, kill switch **сниффером**, no-logs форензикой, фаззинг, секреты стейджинг≠прод; reproducible builds для Go; чеклист подготовки |
| 70 | [70-threat-models.md](sandbox://workspace/bug-hunt/reports/deep-research/70-threat-models.md) | Threat models | Сценарная лестница IVPN; доказательная модель Mullvad; черновик host-based модели sora (T1–T7): **гэпы — TunnelVision/DHCP, Max-style oracle при split-tunnel, ключ подписи — плейсхолдер** |

## Ранжированные рекомендации (вся группа)

### S-tier — разрыв «работает / не работает», безопасность

1. **JA4 stealth-check + трекинг свежести фингерпринтов (63).** Прямое продолжение тира-2 WEB-RESEARCH: устаревший fp = блокировка ТСПУ. `core/stealth/ja4.go`, таблица `known_ja4.json` из CI, проверка в диагностике. Дёшево, ловит тихие регрессии.
2. **Детектор «сибирской заморозки» с автосменой fp (64).** Ответ на волну РКН-2026: активный зонд 6×TLS с fp-контролем, ротация на проходящие fp, бэк-офф, журнал событий. Плюс обязательный mux/vision для REALITY.
3. **Церемония minisign-ключа + staged rollout + автооткат (68, 69).** Ключ до сих пор плейсхолдер — без него вся цепочка подписей декларативна (подтверждено в MEMORY 2026-10-19). Затем: фид `releases.json` с когортами 1%→100%, стоп-кран `blocked_versions`, health-check 60 с, автооткат, апдейт-трафик через туннель, уважение к metered.
4. **Speedtest в core через туннель (62).** Методология дословно: усечённое среднее Ookla + grace + асимметричный jitter LibreSpeed; egress-проверка; пара «VPN/прямо»; история → топливо автовыбора сервера/движка.

### A-tier — высокий эффект, средний кост

5. **OONI-риск протоколов + офлайн-снапшот (61).** Скор по `anomaly`-доле (не путать с `failure`!), по ASN, с `as_of`. Кормит автовыбор протокола. Не выдумывать тест `lantern`.
6. **Threat model + подготовка к аудиту (70, 69).** `docs/threat-model.md` (таблица T1–T7, не-цели), затем первый внешний аудит; автотест kill switch сниффером в CI уже сейчас.
7. **Доверенные сети по спеке IVPN (66).** Ложится на существующие `core/profiles`: `trust` + матрица действий + SSID/BSSID + captive-probe; дефолт новых сетей — untrusted.
8. **Management CLI по таксономии Mullvad (65).** `sora status/connect/server/account/killswitch/speedtest/diag`, `--json`, exit 0/1/2, тот же API что у GUI.

### B-tier — фундамент, долгий горизонт

9. **Гайд контрибьютора по sing-box + CI-чек схемы (67).** Ловит рассинхрон рендера `core/engine` до релиза; clashapi для диагностики движка.
10. **Reproducible builds Go-компонентов + SLSA (69).** `-trimpath`, `SOURCE_DATE_EPOCH`, «пересобери сам»; Flutter — честно best effort.

## Сквозные принципы (вердикты «лучшее», повторяющиеся в темах)

- **Честность вместо цифр:** скор с датой и покрытием, а не «стелсовость 87/100»; `inconclusive` как валидный ответ диагностики.
- **Fail-closed дефолты:** новые сети — untrusted; подпись не сошлась — ничего не ставится; нет ключа — установка отказывается.
- **Проверяемость:** kill switch — сниффером, а не конфигом; JA4 — по эталонным дампам; обновления — пересборкой.
- **Не копировать слепо:** 16-значные аккаунты Mullvad (своя подписочная модель), рандомизация fp (консенсус: точная имитация свежего браузера), ручной blockcheck (нужен авто-режим).

## Открытые вопросы владельцу

1. Церемония minisign-ключа — блокер для тем 68/69 (уже в OWNER-PLAYBOOK).
2. OONI-синк и зонды цензуры: фоновый трафик к заблокированным доменам — только с явного согласия (приватность).
3. Каденс внешних аудитов и бюджет (Mullvad: раз в 2 года; X41 — 30 человеко-дней на 5 платформ).
4. Warrant canary: заводить ли (практика IVPN, дёшево).

## Что не покрыто / ограничения

- Теста `lantern` в OONI нет — скор строится без него (зафиксировано в 61).
- Публичной threat-model-страницы Mullvad не найдено — не выдумывалась, отмечено в 70.
- DeepWiki отдал 429 на одном запросе (LibreSpeed doc.md) — формула jitter взята из `librespeed/speedtest-cli` (`defs/server.go`) и кросс-проверена по адаптации Chrometric.
- Все рекомендации сверены с текущим кодом sora read-only (cli.go, profiles.go, updates.dart, docs/security.md); правок в репо не вносилось.
