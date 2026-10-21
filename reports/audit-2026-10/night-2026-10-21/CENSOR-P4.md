# CENSOR-P4 — AmneziaWG 3.1 и Shadowsocks 2022 + плагины

Ветка `bugfix/audit-2026-10-19`, репозиторий sora (только sora; legacy — зона другого отдела). Строго локально, пуша не было.
Пины: sing-box-lx **lx.22**, Xray **26.10.17**, mihomo **1.19.32**; бинарии `~/workspace/.engines-amd64/`.

## Коммиты

Мои (temp-index + CAS, чужие staged не тронуты):

- `ffede2e8` — SS: методы и плагины как измеренные данные (матрица методов по движкам, каталог SIP003-плагинов с каноническим порядком опций), PSK SS-2022 и параметры плагинов — fail-closed на валидации плана; sing-box рендерит plugin_opts канонически.
- `59c7943d` — host-пробы: `supervise.ProbeHost` измеряет `/dev/net/tun` и модуль kernel WireGuard по факту; registry штампует факты в каждый `Availability`; селекшен отказывает TUN-планам на измеренно-TUN-less хосте и не требует kernel WG для userspace-AWG.
- `c55e705c` — AWG: нулевое значение `AmneziaWG` = plain WireGuard (`IsZero` в feature-detection и рендерах); публичный `GeneratePreset`, неизвестный пресет — ошибка.
- `cf35f0f9` — тесты отдела (матрицы селекшена, границы junk, байт-точные пресеты, детерминизм опций, host-пробы, interop).

Часть рендерных ханков (гейты SS в xray/singbox/mihomo, MissingFor по методам/плагинам в catalog) раньше уехала в HEAD целыми файлами коммитами соседних отделов — проверено поименно, на месте. Символы `SupportsShadowsocksMethod`/`SupportsSSPlugin`, которых ждал CENSOR-P2, теперь в HEAD: чистая сборка HEAD от моих символов больше не зависит от ворктри.

## Что сделано

### AmneziaWG
- Все параметры профиля (Jc/Jmin/Jmax, S1–S4, H1–H4, I1–I5/CPS, J1–J3/Itime, 3.1-механика) — данные профиля с валидацией диапазонов и взаимных ограничений; 3.1-параметры, которые не несёт ни один движок, и Jc>0 без Jmax — отказ плана с причиной, ничего не клампится молча.
- Гейты по движкам — от **проб**: версия и теги (`with_awg`) берутся из фактического вывода бинаря (lx.22 подтверждает `with_awg`), не из пина; неизвестная версия — fail-closed.
- Рендеры AWG на sing-box (lx, with_awg) и mihomo (floor 1.19.30 от probed-версии); Xray AWG не несёт — честный отказ на селекшене.

### Shadowsocks 2022 + плагины
- `Shadowsocks2022Methods()` — полный набор SIP022 (5 методов, добавлены chacha8/chacha12); носимость — по измеренной матрице (ниже), план с методом, который не несёт ни один доступный движок, отказывается на селекшене с именем метода.
- PSK: SIP022-ключ обязан быть base64 точной длины метода (SIP023 — последняя часть цепочки); битый ключ — жёсткий отказ плана (sing-box такой конфиг и сам отклоняет на загрузке: «bad key length, required 32, got 16»).
- Плагины как данные: каталог с per-engine носимостью и упорядоченной схемой опций. sing-box: `obfs-local`, `v2ray-plugin`; mihomo: + `gost-plugin`, `shadow-tls`, `restls` (имя в mihomo — `restls`), `jls`, `kcptun`, `obfs-local`→`obfs`; Xray плагины не несёт и **молча игнорирует** поле plugin (измерено) — поэтому отказ на селекшене/рендере обязателен. Имена для mihomo транслируются по каталогу: неизвестное имя у mihomo молча превращается в голый SS (измерено по исходнику пина и поведению), у нас — отказ.
- Значения опций валидируются по типам (host, path от `/`, bool-флаги, int ≥ 0, режимы obfs http|tls, shadow-tls version 2|3, websocket-only для v2ray/gost); секретные значения опций (пароли shadow-tls/restls/jls, ключ kcptun) регистрируются в Secrets поимённо и не светятся в логах сверх редактора.

### Измеренные матрицы (факт по пинам, не документация)
- Методы: 2022 aes-128/aes-256/chacha20 — все три движка; **chacha12-2022 — ни один**; chacha8-2022 — только mihomo; aes-192-gcm — sing-box+mihomo, не Xray; AEAD-алиасы `chacha20-poly1305`/`xchacha20-poly1305` — только Xray; stream-шифры и `none` — sing-box+mihomo, не Xray; голый stream `chacha20` — только mihomo. (Вариант stream `chacha20-ietf` унаследовал вердикт по префиксу, отдельным замером не покрыт.)
- Плагины: sing-box `check` пропускает v2ray-plugin/obfs-local, отклоняет gost/shadow-tls/неизвестные; SS-**inbound** поля plugin не имеет ни у sing-box, ни у mihomo — серверная сторона плагинов движками не обслуживается.

## Interop по факту трафика (`core/engine/interop/censor_p4_test.go`)
- **SS-2022 — PASS полностью**: клиенты sing-box/Xray/mihomo через registry-путь против sing-box-сервера `2022-blake3-aes-256-gcm`; негативы: неверный PSK не проходит; chacha12 отказывается на селекшене.
- **v2ray-plugin — плагин на проводе доказан байтами**: шим RFC 6455 фиксирует WS-апгрейд на рендерный путь `/ws` у обоих клиентов; sing-box открывает mux.cool-контроль к `v1.mux.cool` (магия видна в первом фрейме verbatim), mihomo фреймит целевую сессию напрямую. Оба движка поверх WS говорят **v2ray mux.cool**, а не голый SS-поток — завершение data-plane требует настоящего mux.cool-контрпартия (бинарь v2ray-plugin), см. эскалации. Негативы: plain-SS не апгрейдится и не проходит; Xray отказывается на селекшене.
- **AWG — SKIP с точной причиной в этой песочнице**: seccomp-профиль VM запрещает `sendmmsg` (`Seccomp: 2`, 4 фильтра у каждого процесса; EPERM воспроизведён у детей bash/Go/python одинаково), а wireguard-go шлёт handshake и junk только через sendmmsg. Сигнатура в тесте: строка `sendmmsg: operation not permitted` в логах движка и/или seccomp у тест-процесса → skip с причиной; на машине без фильтра тест проверяет трафик полностью. Негативные контроли (mismatched H1, plain WG) под блоком проходят вакуумно — содержательны только на dev-машине.
- Все продуктовые пути при этом покрыты: рендеры AWG принимаются `sing-box check`, uapi-лог движка подтверждает применение junk/H/S/I параметров.

## Мелочи (критерии владельца)
1. **Границы junk** — отдельный сьют `censor_p4_bounds_test.go`: Jc/Jmin/Jmax, S1–S4 — 0/min/max/max+1/отрицательные; коллизия S1+56=S2 — точная грань ±1; H-диапазоны — min/max, касание vs соседство, обратный порядок, равенство; 3.1 range<uint16> — грани; валидация вход не мутирует. Ничего не клампится — только отказ с причиной.
2. **Байт-точность пресетов** — `TestPresetShapesByteExact` на сгенерированных значениях: QUIC version ровно 4 байта + `<rc 8>`; DNS txid 2B/flags `0x0100`/counts/question 12–24B; SIP декодируется в литерал `INVITE sip:` + 8–16B URI; filler I2–I5 — структура `<b 4–15B><rc><t><r>`; диапазоны генерации Jc 3–8, Jmin 50–200, Jmax, S1–S4 — по спецификации пресетов.
3. **Детерминизм опций плагинов** — канонический порядок по схеме каталога; тест: рендер дважды байт-идентичен, перестановка опций на входе даёт тот же выход (`tls;host=example.com;path=/ws`).
4. **Тайминги из данных** — константы interop-харнесса именованы и обоснованы в коде (settle сервера, стартовый/контекстный таймауты, политика повторов fetch — харнессная: 5 попыток × 5с); генеративные тайминги AWG (rekey/keepalive диапазоны) — поля профиля, валидируются, не хардкод по месту.
5. **Логи и секреты** — ошибки единообразны по префиксам `engine:`/`singbox:`/`mihomo:`/`xray:` с причиной; тест `TestSecretsCoverPluginAndAWGKeys`: PSK, ключи AWG и секретные значения плагин-опций поимённо в Secrets и маскируются редактором.

## Эскалации (точные)
1. **AWG-трафик и kernel WG/TUN — dev-машина.** В VM: seccomp запрещает sendmmsg (userspace WG/AWG не может отправить ни одного пакета), `/dev/net/tun` и модуля WG нет. На dev-машине: `SORA_ENGINES_DIR=... go test -count=1 -run TestP4AmneziaWGTraffic ./engine/interop/` — там же негативные контроли станут содержательными.
2. **Серверная сторона плагинов — решение по упаковке.** Нужны бинари v2ray-plugin (mux.cool server), simple-obfs (obfs-local server), gost/shadow-tls/restls/jls/kcptun externals; в поставке их нет, движки inbound-плагины не обслуживают. До решения клиентские рендеры и гейты готовы, серверный interop плагинов не заявляется.
3. **chacha12-2022 не несёт ни один пин** — планы честно отказываются; появится носитель — одна строка в матрице `ss_support.go`.
4. **Чужие падения в `core/control`** (не мои, не трогал): `TestCredentialDocumentMatchesLegacyMapForm` — дрейф xmux-полей в golden-документе кредов (работа отдела REALITY/XHTTP); `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` — длина unix-socket пути в общем TMPDIR. Остальной затронутый набор пакетов зелён: `go build ./...`, `go vet`, тесты engine/xray/mihomo/singbox/supervise/registry/wgobfusc.
5. **Общий индекс**: в shared index сейчас staged-удаление `core/engine/supervise/hostprobe.go` (индексный артефакт соседей; в HEAD файл на месте — мои коммиты шли CAS-ом мимо общего индекса). Координатору: не коммитить общий индекс вслепую.
