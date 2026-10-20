# Эволюция DPI-обходов: что нового в zapret 2025–2026 и что внедрять в sora

Тема 7/20, R&D сетевых технологий. Статус на 2026-10-19.
Вендорная zapret в sora/third_party — v72.13 (актуальная ветка bol-van/zapret).

## 1. Что нового в апстриме (sora не использует)

**nfqws (v71–v72, пакетный уровень, Linux+root+iptables):**
- Режимы desync: `fake`, `fakedsplit`, `fakeddisorder`, `multisplit`,
  `multidisorder`, `hostfakesplit` (+`altorder`), `rst`, `synack`, `syndata`,
  `ipfrag1/2`, `hopbyhop`, `destopt`, `udplen`.
- Фейковые пакеты с неверным SEQ/ACK: `--dpi-desync-fake-tcp-mod=seq`
  (DPI видит «невалидный» пакет и рассинхронизируется, сервер отбрасывает).
- Fooling: `md5sig`, `ts` (TCP timestamps), `badsum`, `badseq`.
- `--ip-id=seq|seqgroup|rnd|zero`, `--wssize-forced-cutoff`, моды TCP-флагов,
  `--dup-ip-id`.
- QUIC: сборка CRYPTO из фрагментов, стратегия
  `--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6`.

**tpws (то, что sora запускает):**
- Мульти-стратегии: `--new` + `--filter-tcp/--filter-l7` + `--hostlist*`,
  включая `--hostlist-auto` (сам детектирует блокировки и строит хостлист —
  шейпить только то, что реально режут).
- Опции, которых не было в `BypassStrategy`: `--hostdot`, `--hosttab`,
  `--hostnospace`, `--methodspace`, `--unixeol`, `--split-any-protocol`,
  `--disorder=http|tls`, `--oob=http|tls` — **проброшены, см. коммиты ниже**.
- `--tamper-start/--tamper-cutoff`, `--mss`, `--fix-seg`, `--oob-data`.

**zapret2 (новый репозиторий bol-van, 2025):** Lua-скриптуемый desync
(`--lua-desync`: fake/multisplit/multidisorder), nfqws2/dvtws2/winws2,
профили с L7-фильтрами (включая quic), blockcheck2.sh.

**Поле (ntc.party, исследования):** `zapret-Checker` — автоподбор стратегий
(Windows, сообщество); FOCI 2026 — SNI-цензура QUIC в РФ; тренд к
allowlist-фильтрации у операторов.

## 2. Что умеет sora сейчас

- Только tpws в `--socks`-режиме (userspace, без root). Стратегия задаётся
  вручную через план/RPC; дефолт для zapret_with_vpn: split `1,2`+disorder.
- nfqws **собирается** `packaging/zapret/build.sh`, но **никогда не запускается**.
- QUIC/UDP: **ноль обработки** — tpws работает с TCP-потоком, UDP идёт мимо.
- Автоподбора стратегий не было; смежный пакет `core/tune` (SW5) теперь
  перебирает обфускации при обрыве, включая «zapret-альтернативы».
- `blockcheck.sh` завендорен, но не используется.

## 3. Фильтр слопа (применён ко всем позициям)

Отсечено безжалостно, даже популярное:
- **Миграция на zapret2** — слоп для нас: Lua-рантайм и новое дерево ради
  скриптуемости, которая нужна при десятках стратегий; у нас их <10.
  Следить, не мигрировать.
- **dvtws** — нет BSD-таргета. Вычеркнуто.
- **Свой blockcheck с нуля** — слоп: скрипт уже завендорен; берём только
  корпус проверенных стратегий как данные, не код.
- **`--mss` по умолчанию** — режет скорость всему трафику (предупреждение
  самого zapret); только как last-resort в пуле, никогда дефолтом.
- **nfqws вместо tpws** — root+iptables ради TCP-шейпинга, который tpws
  уже делает в userspace: проигрыш по сложности. nfqws — только точечно
  (QUIC/UDP), см. P2.
- **Маркетинговые цифры эффективности** — запрещены: каждая стратегия в пуле
  обязана иметь честное измерение (прошла/не прошла против тестового домена
  через `core/probe`+`core/tune`), иначе в пул не попадает.

Прошло фильтр — ниже.

## 4. Спека

### P0 (высокий эффект, низкая/средняя сложность)

1. **Курированный пул zapret-стратегий + интеграция с `core/tune`.**
   ~8 стратегий (данные из корпуса blockcheck.sh): split+disorder,
   tlsrec/sniext, fakedsplit-эмуляция через disorder+oob, http-тамперы
   (hostcase/hostdot/methodspace), tls-only disorder. `tune` перебирает их
   через существующий AttemptFunc; победа кэшируется per-network (кэш уже
   есть). Сложность: средняя. Эффект: «подключил — работает» без ручной
   настройки; закрывает gap №2 из competitor-analysis.
2. **Пробросить новые поля в proto+RPC+UI.** Поля уже есть в
   `engine.BypassStrategy`; нужны `BypassStrategy` fields 8+ в
   `proto/sora/core/v1/core_control.proto`, маппинг в `core/control/plan.go`,
   UI. Сложность: низкая. Без этого новые опции недоступны пользователю.
3. **QUIC-probe + fallback.** Активная проверка достижимости UDP/443
   (`core/probe`): при блокировке QUIC — честный сигнал движкам/браузеру
   откатиться на TCP (не «тихий» таймаут). Сложность: низкая. Эффект:
   чинит YouTube/HTTP-3 без root и nfqws.

### P1 (средний эффект, средняя сложность)

4. **Мульти-стратегии tpws: per-domain / per-proto.** Один tpws с `--new`:
   TLS-стратегия для 443, HTTP-тамперы для 80, `--hostlist-auto` чтобы
   шейпить только реально режущиеся домены (остальное — без оверхеда и
   лишнего фингерпринта). Сложность: средняя (проверить multi-strategy в
   `--socks`-режиме; если не заведётся — N процессов tpws по классам
   трафика, `Engine` уже умеет N процессов).
5. **`--tamper-start/--tamper-cutoff`, `--oob-data`.** Тонкая настройка
   «шейпить только начало handshake» — меньше оверхеда на длинных
   соединениях. Сложность: низкая.

### P2 (точечный эффект, высокая сложность)

6. **Опциональный nfqws-профиль для Linux+root: только UDP/QUIC.**
   `--filter-udp=443 --dpi-desync=fake` + fake-tcp-mod=seq для TCP-фолбэка.
   Строго opt-in, только то, что tpws физически не может (пакеты с неверным
   SEQ, UDP). Сложность: высокая (root, iptables, риски). Без честных
   замеров против P0.3 — не делать.
7. **Краудсорсинговая карта стратегий (opt-in).** Агрегированные
   «стратегия X работает у ASN Y» из кэшей `core/tune` — новому пользователю
   сразу рабочая стратегия. Из competitor-analysis §3 №9; только агрегаты,
   только opt-in.

## 5. Что сделано (коммиты, ветка bugfix/audit-2026-10-19, пуша нет)

- `5b34de1 [net-rd] bypass: не держать мьютекс, пока tpws стартует` (sora) —
  порт lock-fix из legacy: Apply не держит `e.mu` во время до 5с ожидания
  прослушивания; `current()`/`publish()`.
- Tamper-опции tpws в `BypassStrategy` (sora: внутри `be01e06`;
  legacy: `085cd2b [net-rd] bypass: недостающие tamper-опции tpws...`):
  `HostDot/HostTab/HostNoSpace/MethodSpace/UnixEOL`, `SplitAnyProtocol`,
  `DisorderScope/OOBScope` (http|tls) → `--hostdot`, `--hosttab`,
  `--hostnospace`, `--methodspace`, `--unixeol`, `--split-any-protocol`,
  `--disorder=tls`, `--oob=http`; валидация scope'ов и «стратегия ничего
  не меняет»; тесты `Args` (точные argv) — `go build+vet+test` зелёные.

## 6. Открытые вопросы / риски

- Параллельные агенты активно коммитят в те же файлы (`plan.go`,
  `validate.go`): один незакоммиченный чужой кусок один раз затёр мою
  правку validate.go — восстановлено; итог проверен тестами. При мерже
  смотреть `BypassStrategy` и её `validate` внимательно.
- `TestTunAndFakeIPAvoidLANAndEachOther` падает в этой VM из-за интерфейса
  `198.19.0.2/30` — окружение, не мой код (зона TUN).
- sora/app не тронут; proto/UI для новых полей — отдельный заход (P0.2).
