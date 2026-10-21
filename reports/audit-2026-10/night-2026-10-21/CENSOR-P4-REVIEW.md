# CENSOR-P4 — независимое ревью (AmneziaWG 3.1 + Shadowsocks 2022/плагины)

Ревьюер: независимый, код не правил. Ветка `bugfix/audit-2026-10-19`, HEAD на момент ревью `86c9c2a2`.
Объект: `ffede2e8`, `59c7943d`, `c55e705c`, `cf35f0f9` (все четыре — предки HEAD, подтверждено `merge-base --is-ancestor`) + поименные ханки соседей.
Метод: чистый экспорт HEAD (`git archive HEAD` в `/tmp`, без ворктри и общего индекса), `go build ./...` (exit 0), `go vet` по зоне, полный перепрогон interop на бинарях `~/workspace/.engines-amd64` (sing-box 1.14.3-lx.22, Xray 26.10.17, mihomo 1.19.32), собственные пробы ревьюера (маркер-секреты, Xray/plugin на живом трафике, `sing-box check` по сгенерированным AWG-рендерам, `sendmmsg` через ctypes, carriage опций mihomo). Пуша не было, коммитов не делалось.

## Итоговая таблица

| # | Пункт | Вердикт |
|---|-------|---------|
| 1 | SS-2022 трафик | **ПРИНЯТЬ** |
| 2 | v2ray-plugin / mux.cool | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (M3) |
| 3 | Fail-closed валидация и секреты | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (M2, L1) |
| 4 | Host-пробы (адаптивность) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (M4, L2) |
| 5 | AWG | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (M1 — сигнатура SKIP) |
| 6 | Мелочи | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (кросс-ссылки M3, L1) |
| 7 | Состояние дерева | **ПРИНЯТЬ** (факт индекса подтверждён и шире заявленного) |

**Общий вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.** Продуктовый код зоны P4 замечаний уровня High не имеет; замечания — полнота валидации, точность тестовой сигнатуры SKIP и глубина host-пробы.

## 1. SS-2022 трафик — ПРИНЯТЬ

- Перепрогон на чистом HEAD: `TestP4Shadowsocks2022Traffic` — **PASS полностью** (sing-box 22.7с, Xray 26.0с, mihomo 24.7с через registry-путь против sing-box-сервера `2022-blake3-aes-256-gcm`).
- Негативный контроль свой в тесте и перепрогонан: неверный PSK трафик не пропускает (22.5с, PASS).
- `chacha12-2022` отказывается **на селекшене** с именованной причиной (`shadowsocks method 2022-blake3-chacha12-poly1305` в MissingFor), не на Apply — PASS (9.3с).
- Единый источник: методы — `core/engine/ss_support.go`, плагины — `core/engine/ss_plugin.go`; потребители — `catalog.go:452/461/465` (MissingFor), рендеры singbox/xray/mihomo. Поиск вторых словарей по репо: конкурирующих таблиц методов/плагинов нет; единственная вторая логика — трансляция опций mihomo (`ssPluginOpts`, см. M3), таблицей носимости она не является.
- Честная оговорка автора про `chacha20-ietf` (вердикт по префиксу, отдельным замером не покрыт) — принята как раскрытое ограничение, не как дефект.

## 2. v2ray-plugin / mux.cool — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Байтовый захват автора **воспроизведён**: `TestP4ShadowsocksV2RayPluginTraffic` — PASS: оба клиента (sing-box, mihomo) делают WS-апгрейд ровно на рендерный путь `/ws`; первый фрейм sing-box содержит `v1.mux.cool` verbatim (ассерт теста, не fetch-исход); plain-SS не апгрейдится и не проходит (47.2с); Xray отказывается на селекшене.
- Утверждение «Xray поле plugin молча игнорирует» — **измерено ревьюером самостоятельно на бинаре**: (а) `xray run -test` на конфиге SS-аутбаунда с `"plugin":"v2ray-plugin","plugin_opts":"tls;host=example.com;path=/ws"` → rc=0, «Configuration OK»; (б) живой трафик: тот же конфиг + plain sing-box SS-сервер без плагина → через Xray SOCKS получен полный ответ таргета (2014 байт). Плагин игнорируется, трафик идёт голым SS — отказ на селекшене/рендере в sora обоснован и на месте (`xray/render.go:249`).
- Замечание M3 — ниже.

## 3. Fail-closed валидация — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Подтверждено:
- PSK неверной длины и не-base64 отклоняется на валидации плана с именованной ошибкой (требуемая длина названа, сам ключ не эхоится): тесты автора + собственный маркер-прогон ревьюера.
- **Собственный вектор-маркер** (`MARKERSECRET7f3a9c`, 5 векторов: битый PSK, PSK неверной длины, shadow-tls password + битая версия, kcptun key + битый int, AWG header-protection key): ни одна ошибка валидации маркер **не содержит**; при этом PSK, секретные значения плагин-опций поименно, ключ kcptun и AWG-ключ поименно присутствуют в `Secrets()` и маскируются редактором (плюс тест автора `TestSecretsCoverPluginAndAWGKeys` — PASS).
- Плагин с битыми значениями опций (тип/диапазон/режим/путь/дубль/неизвестный ключ) отклоняется с именованными ошибками — сьют автора PASS на чистом HEAD.

Замечания:
- **M2 (Medium): обязательных опций у плагинов нет вообще.** `validateShadowsocksPlugin` (`core/engine/ss_plugin.go`) валидирует только *присутствующие* значения. Собственная проба ревьюера: `Validate()` возвращает nil для shadow-tls без единой опции и без password, restls-plugin без password, kcptun без key, obfs-local без режима `obfs=`. Такие планы уезжают в движок и умирают опаково (или, для kcptun, рискуют упереться в дефолт движка) — ровно тот класс отказов, который отдел декларирует закрытым. Нужен `required` в схеме опций каталога.
- **L1 (Low, косметика):** дублирование токена в ошибках видов `ssOptTLSVersion`/`ssOptModeWS`: фактически выдаётся `shadowsocks plugin shadow-tls: option version version "9" is not 2 or 3` (префикс `option %s` + формат, начинающийся с имени вида). На fail-closed не влияет, в глаза бросается.

## 4. Host-пробы (адаптивность) — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Подтверждено:
- `registry.Discover` зовёт `supervise.ProbeHost()` один раз и штампует факты в каждый `Availability` (`registry.go:115`); селекшен отказывает TUN-плану на измеренно-TUN-less хосте с причиной `host has no TUN device (/dev/net/tun, probed)` до старта движка (тест `TestSelectEngineHostTUNProbeGate` PASS); userspace-AWG kernel-WG **не** требует (тот же тест, PASS); непрошенный хост (`Probed=false`) не гейтит.
- Пробы не по пинам и не по ОС: не-Linux честно отдаёт `Probed:false`.

Замечания:
- **M4 (Medium-Low): проба — `os.Stat`, а не открытие.** `probeHost` (`core/engine/supervise/hostprobe.go`) проверяет существование ноды и `ModeCharDevice` для TUN и `IsDir` для `/sys/module/wireguard`. Это факт файловой системы, но не проба по факту использования: висячая нода без живого драйвера даст `TUNDevice=true`, и план умрёт уже в движке. Чек-лист требовал пробу/открытие. Kernel-WG по sysfs — стандартный факт, но тоже путь, а не попытка. Рекомендация: для TUN — `os.OpenFile` (+ при желании TUNSETIFF на отдельном пути), для WG — stat оставить, но назвать честно.
- **Перепроверки нет и не обоснована.** В проде `lazyEngines` (`core/cmd/sora-core/engines.go`) кэширует `registry.Discover` на время жизни процесса: факты, измеренные at startup, залипают до рестарта ядра процесса; комментария-обоснования одноразовости в коде нет. Для TUN это почти всегда приемлемо, но по чек-листу — либо TTL/перепроба при отказе старта, либо честный комментарий.
- **L2 (Low):** комментарий в `hostprobe.go` утверждает «This VM … has no /dev/net/tun» — на момент ревью `/dev/net/tun` на этой VM **есть и открывается** (`os.open` ok). Сама проба при этом отвечает по факту верно — что как раз валидирует подход; комментарий устарел.

## 5. AWG — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Подтверждено:
- `IsZero`: нулевой `AmneziaWG` = plain WG во всех потребителях — `refs.go` (RequiredFeatures), `singbox/render.go:577`, `mihomo/proxy.go:151`, `xray/render.go:609`, stealth. Собственная проба ревьюера: рендер с `&AmneziaWG{}` — нет ни одного AWG-ключа (`jc/jmin/i1/header_protection_key/content_padding_addition`), MTU plain, `sing-box check` проходит.
- Junk/H/S/I1–I5 применяются: собственная проба — сгенерированные наборы `Generate` (2.0), `Generate31` (3.1), `GeneratePreset(DNS,31)`, `GeneratePreset(SIP,20)` проходят `Validate()` и рендерятся с ключами, а **реальный `sing-box check` lx.22 все четыре рендера принимает**. UAPI-подтверждение автора отдельно не перепрогонялось (косвенно: AWG-endpoint сервера в interop поднимался с junk-параметрами до клиентского SKIP).
- `GeneratePreset` публичен и fail-closed: собственная проба `GeneratePreset(Preset(99))` → ошибка, не нормализация в QUIC.
- Среда: `sendmmsg` запрещён **любому процессу** — подтверждено ревьюером прямым вызовом из ctypes: `sendmmsg ret=-1 errno=1 (EPERM)`, `Seccomp: 2`, 4 фильтра; даже обычный UDP `sendto` на loopback даёт EPERM. AWG-трафик здесь невозможен физически, это ограничение среды, а не продукта. Перепрогон interop: sing-box и mihomo — SKIP с причиной, негативы (mismatched H1, plain WG) — PASS вакуумно (автор это честно раскрывает).

Замечание:
- **M1 (Medium, валидность теста): сигнатура SKIP шире заявленной «точной».** Условие в `core/engine/interop/censor_p4_test.go`: `sandboxBlocksSendmmsg(center) || seccompFiltered()`, где `seccompFiltered()` — это просто `Seccomp:\t2` в `/proc/self/status`. Любой seccomp-фильтр (например, дефолтный Docker-профиль, где sendmmsg **разрешён**) превратит настоящий продуктовый отказ AWG на dev-машине в SKIP — тест «пошёл бы в трафик, а не в скип» на такой среде не выполняет. Для mihomo-сабтеста SKIP в этом прогоне, судя по 502 без sendmmsg-строки в логе, сработал именно по `seccompFiltered()`. Лечение: скип только по строке `sendmmsg: operation not permitted` в логе движка и/или собственной прямой пробе `sendmmsg` тест-процессом (как проба ревьюера выше), не по факту наличия фильтра.
- Команда на dev-машине (без seccomp-запрета sendmmsg): `SORA_ENGINES_DIR=<dir> go test -count=1 -run TestP4AmneziaWGTraffic ./engine/interop/` — там же негативные контроли станут содержательными. Kernel-WG/TUN-трафик AWG — та же машина, отдельная проверка не требуется продукту (userspace-путь), но TUN-планы гейтятся пробой из п.4.

## 6. Мелочи — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Границы junk: сьют `censor_p4_bounds_test.go` перепрогонан на чистом HEAD — PASS: Jc/Jmin/Jmax и S1–S4 на 0/min/max/max+1/отрицательных; коллизия `S1+56==S2` на точной грани ±1 и освобождение 0/0; H — min/max, касание vs соседство, обратный порядок, равенство; 3.1 `range<uint16>` — грани; `Jc>0 при Jmax==0` — отказ (P4-добавка). Мутации входа нет — ассерт `*a == before` в каждом кейсе; клампов в валидации нет, только отказы с причиной.
- Байт-точность I1–I5: `TestPresetShapesByteExact` PASS (QUIC 4B + `<rc 8>`, DNS txid/flags/counts, SIP `INVITE sip:` + URI, filler-структура), плюс собственные генерации выше.
- Детерминизм опций: канонический порядок каталога; повторный и **переставленный** ввод дают байт-идентичный рендер — `TestRenderPluginOptsDeterministic` (sing-box) и `TestCanonicalSSPluginOpts` PASS. Оговорка: mihomo-путь опций — map-трансляция (`ssPluginOpts`), байт-детерминизм там держится на маршалинге map, не на канонизации; и см. M3: mihomo молча теряет `obfs-uri`/`fast-open` у obfs-local (проба ревьюера: рендер `map[host:example.com mode:tls]` из полного валидного набора) и пропускает неизвестные ключи опций на рендере вместо fail-closed — рендерная глубина у mihomo слабее, чем у sing-box/Xray.
- Тайминги: именованы и обоснованы в шапке interop (`p4ServerSettle 500ms`, `p4StartTimeout 20s`, `p4CtxTimeout 60s`, политика fetch 5×5с) — магических слипов по месту нет.
- Логи зоны: секретов не содержат (маркер-прогон п.3); префиксы ошибок единообразны, за вычетом L1.

## 7. Состояние дерева — ПРИНЯТЬ

- Чистый экспорт HEAD собирается без ворктри: `go build ./...` exit 0, `go vet ./engine/... ./wgobfusc/...` чист, все P4-тесты в экспорте зелёны (engine/singbox/mihomo/xray/supervise/registry/wgobfusc + interop выше). Символы `SupportsShadowsocksMethod`/`SupportsSSPlugin` и потребители в HEAD полны.
- **Общий индекс: эскалация автора подтверждена и фактически шире.** В shared index staged-удаление не одного, а четырёх файлов: `core/engine/supervise/hostprobe.go`, `hostprobe_linux.go`, `hostprobe_other.go`, `hostprobe_test.go` (+2 строки `supervisor.go`; итого `git diff --cached --stat`: 5 файлов, 119 удалений). В HEAD файл цел: blob `HEAD:core/engine/supervise/hostprobe.go` = `e102e615`, хэш ворктри-файла тот же; в статусе файл виден как `D ` (staged) + `??` (untracked). Координатору: **общий индекс вслепую не коммитить** — подтверждение автора верно.
- Чужие рендерные ханки P4 поименно на месте в HEAD (выборочно): гейты MissingFor по методам/плагинам `catalog.go:452/461/465`; отказ Xray-рендера по плагину `xray/render.go:249`; гейты sing-box `singbox/render.go:277/280`; трансляция имён mihomo `mihomo/proxy.go:52-61`.
- Не-P4 падения на чистом HEAD (не зона отдела, фиксирую для координатора): пакет `core/engine` — `TestCatalogXmuxClaimMatchesRenderers` и `TestCensorP1KeyShareGate` FAIL (зоны XHTTP/xmux и CENSOR-P1). Заявленные автором падения `core/control` в этом ревью не перепроверялись (вне зоны).

## Замечания списком (по серьёзности)

| ID | Серьёзность | Где | Суть |
|----|-------------|-----|------|
| M1 | Medium | `core/engine/interop/censor_p4_test.go` (skip-условие) | SKIP по `Seccomp==2`, а не по точной EPERM-сигнатуре: на seccomp-фильтрованной dev-машине реальный отказ AWG замаскируется в SKIP |
| M2 | Medium | `core/engine/ss_plugin.go` `validateShadowsocksPlugin` | Нет обязательных опций: shadow-tls/restls без password, kcptun без key, obfs-local без режима проходят валидацию (проба: 7/7 nil) |
| M3 | Medium-Low | `core/engine/mihomo/proxy.go` `ssPluginOpts` | obfs-local: `obfs-uri` и `fast-open` молча теряются на mihomo; неизвестные ключи опций проходят рендер вместо fail-closed |
| M4 | Medium-Low | `core/engine/supervise/hostprobe.go`; `core/cmd/sora-core/engines.go` | Проба — stat, не открытие устройства; перепроверки/TTL нет, факты залипают на жизнь процесса без обоснования в коде |
| L1 | Low | `core/engine/ss_plugin.go` `validateSSPluginOptValue` | Дублирование токена: `option version version "9"`, аналогично mode |
| L2 | Low | `core/engine/supervise/hostprobe.go` (комментарий) | Утверждение «VM has no /dev/net/tun» устарело: нода есть и открывается; проба при этом честна |

Эскалации автора (серверные бинари плагинов, chacha12 без носителя, AWG/kernel на dev-машине) подтверждаю как честные и точно сформулированные.
