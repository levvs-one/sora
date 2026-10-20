# Ревью SW2b: ingress-защита (`be01e06`) — отчёт независимого ревьюера

Дата: 2026-10-19. Репо `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`.
Ревьюировался коммит `be01e06` («ingress-защита от входящих мимо туннеля», SW2).
Внесённые мной правки: коммит `00b447a` (`[swarm-review]`, только 7 файлов `core/guard/`).

## Вердикт: принять с правками (правки уже внесены в `00b447a`)

Коммит решает задачу правильно по архитектуре: декоратор `WithIngress` поверх
платформенного `Firewall`, `nftables sora_ingress` на Linux, `WFP ALE_AUTH_RECV_ACCEPT`
на Windows, `NoopFirewall` на остальных. Но в нём был **блокер на Windows**,
**fail-open окно на Linux** и два нарушения fail-closed порядка — всё исправлено.
Без `00b447a` на Windows с дефолтным конфигом подключиться было бы невозможно вообще.

## Найденные проблемы

### F1 (blocker, исправлено): WFP `applies()` не знал про inbound-слои

`core/guard/firewall_windows.go`, `applies()` — семейный фильтр сравнивал слой
с `wf.LayerALEAuthConnectV4` (outbound). Ingress-правила ставятся на
`LayerALEAuthRecvAcceptV4/V6`, поэтому:

- v4-префиксы (VPN-endpoint'ы, LAN bypass) — **молча пропускались на обоих слоях**,
  permit-правила не создавались;
- v6-префиксы — ставились **на оба слоя, включая v4**; WFP отвергает
  cross-family условия → `install()` падал → `Arm()` возвращал ошибку.

С дефолтным конфигом (`AllowLAN=true`, в bypass есть `fc00::/7`, `fe80::/10`)
`Arm` на Windows падал **всегда**: kill switch вставал, ingress — нет,
подключение невозможно. Направление fail-closed, но функциональность сломана
полностью. Авторский же тест `TestWFPIngressRules` (ожидает
`v4endpoint=1, v6endpoint=1, lan=1`) с этим кодом падал бы — он нигде не
запускался (см. F8).

Исправление (`00b447a`): семейство слоя определяется как
`ConnectV4 || RecvAcceptV4`. Поведение outbound-пути не изменилось
(для `ConnectV4/V6` предикат тот же, что раньше). Проверено симуляцией точной
булевой логики: до фикса `endpoint=2 (оба v6, один на чужом слое), lan=0`,
после — `loopback=2, tunnel=2, v4endpoint=1, v6endpoint=1, lan=1, block=2`,
ровно как ждёт тест.

### F2 (high, исправлено): неатомарный arm на Linux — fail-open окно

`nftablesIngressBackend.arm()` делал два вызова `nft`: сначала
`delete table`, потом установка таблицы. Между ними — окно без ingress-таблицы,
входящие не фильтруются. Это ровно та ошибка, которую kill switch уже чинил
(`NftReplace`, SORA-M4: «two-invocation delete-then-add left traffic unguarded»),
а комментарий в коде утверждал, что «зеркалит» исправленный паттерн.

Исправление: добавлен `NftIngressReplace()` (delete+table в одном батче, ядро
коммитит транзакцией) с fallback на одиночную установку при первом arm'е —
один в один как `Nftables.Arm`. Новый тест `TestIngressArmReplacesAtomically`
пинит это фейковым nft с батч-семантикой.

### F3 (medium, исправлено): валидация конфига после `inner.Arm`

`IngressFirewall.Arm` сначала армил kill switch, потом валидировал конфиг.
Невалидный endpoint → ошибка, но kill switch оставался заармленным
(«успешный» побочный эффект при ошибке валидации).

Исправление: `validateIngressConfig` — до любых site-эффектов. Новый тест
`TestIngressFirewallValidatesBeforeArmingInner`: плохой endpoint → ошибка,
`inner.Arm` не вызван, kill switch не заармлен.

### F4 (medium, исправлено): повторный Arm не восстанавливал таблицу

Старый код пропускал backend-arm при `f.armed` — внешне удалённая таблица
` sora_ingress` не восстанавливалась, хотя `Nftables.Arm` сам по себе
идемпотентно переустанавливает. Исправление: повторный Arm пере-применяет
бэкенд (оба бэкенда идемпотентны: nft — атомарный replace, WFP — early-return
при открытом session). Тест `TestIngressReArmRestoresExternallyRemovedTable`.

### F5 (low, исправлено): `nftables_test.go` без build tag ломал windows-сборку тестов

Файл целиком про nftables (фейковый nft через `/bin/sh`, `NftBinForTest`
из linux-only `nftables_linux.go`), но без `//go:build linux` — из-за этого
`GOOS=windows go vet ./guard/` не собирался вообще, включая новые windows-тесты
коммита. Добавлен тег. Pre-existing, не из `be01e06`, но напрямую блокировал
проверку ревьюируемого коммита.

### F6 (гигиена, не исправлено — требует решения владельца): scope creep в коммите

В `be01e06` вместе с ingress затесались несвязанные изменения:
`core/engine/bypass/bypass.go`, `plan.go` (`BypassStrategy`: `DisorderScope`,
`OOBScope`, `HostDot/HostTab/HostNoSpace/MethodSpace/UnixEOL`,
`SplitAnyProtocol`), `validate.go` + тесты — это zapret-флаги DPI-обхода,
другой workstream. Коммит про ingress не должен их везти. Сама логика
там корректна (валидация скоупов, тесты рендеринга есть), претензия только
к гигиене коммита. Переписывать историю не стал — ветка общая, пуша не было;
рекомендую при мерже разнести.

### F7 (info): утверждение автора про WFP re-authorization — подтверждено

Проверено по документации MS («ALE Reauthorization», «Packet Inspection Points»):
ALE-авторизация — один раз на flow; `ALE_AUTH_RECV_ACCEPT` видит SYN / первый
UDP-датаграмм нового входящего flow и re-auth индикации. Установившиеся flow
не переоцениваются попакетно — аналог nftables `ct established,related accept`
корректен для security-свойства (блок видит только новые входящие).
Нюанс (только в сторону fail-closed): re-auth триггерится сменой политики на
слое — т.е. в момент установки/снятия наших же фильтров уже существующие
входящие flow могут быть переавторизованы и отброшены. На Linux такого нет
(established держится явно). Расхождение availability, не дыра.

## Что проверено и признано корректным

- **nftables порядок**: `iif "lo"` → `iifname "sora0"` → `ct established,related` →
  endpoint'ы (`ip`/`ip6 saddr`) → LAN → ровно один `counter drop`, последний.
  Chain `inet`, policy accept + финальный drop = эффективный default-drop. Дыр
  нет: на phys-iface разрешены только established/related, endpoint'ы (осознанное
  доверие — «серверу, которому доверен весь трафик, доверен и inbound») и LAN.
- **WFP веса**: permit'ы (10/50) > block (0), саблейер `0xffff` как у kill switch,
  финальный блок безусловный, правила только на recv-слоях (тест это пинит).
- **Fail-closed матрица**: невалидные endpoint'ы (домены, инъекции `;`/перевод
  строки, порты >65535, пустые) → ошибка до site-эффектов; `Enabled=false` →
  только kill switch; `AllowLoopback=false` → отказ; неизвестный тип firewall →
  ошибка, а не молчаливый пропуск; uid 0 → kill switch отказывает первым,
  ingress не трогается (тест есть).
- **Декоратор**: ingress ставится ровно при Arm, снимается при Disarm
  (ingress — первым при снятии, последним при установке: входящие фильтруются
  до последнего момента); двойного применения нет; `Disarm` идемпотентен;
  `NoopFirewall` → no-op без ошибки.
- **Рендеринг**: инъекции невозможны — endpoint'ы только через
  `netip.ParseAddr/ParseAddrPort`, bypass-сети через `parseBypassNetwork`
  (невалид → пропуск = drop, fail-closed); семейство `ip`/`ip6` выбирается
  по адресу.

## Тесты: что добавлено и что осталось

Добавлено в `00b447a` (все гоняются на Linux в изолированной песочнице —
дерево сейчас ломают чужие WIP в `core/engine`, `core/censor`):
- `TestNftIngressReplaceIsASingleBatch` — батч = delete+table одним куском;
- `TestIngressFirewallValidatesBeforeArmingInner` — валидация до `inner.Arm`;
- `TestIngressArmReplacesAtomically` — re-arm одним вызовом nft;
- `TestIngressReArmRestoresExternallyRemovedTable` — self-healing;
- симуляция логики `applies()` до/после (bug → `lan=0`, v6 на чужом слое;
  fix → распределение как в `TestWFPIngressRules`).

Осталось (не могу выполнить на Linux):
- **Запустить windows-тесты на Windows**: `TestWFPIngressRules`,
  `TestWFPIngressRulesWithoutLANSkipsLocalPermits` — компилируются
  (`GOOS=windows go vet` чистый), исполнить негде. Это критично: F1 был бы
  пойман авторским тестом сразу.

## Фильтр слопа

- Вырезал бы из коммита: F6 (bypass-флаги — отдельным коммитом).
- Оставил: дублирующиеся nil-ветки `newIngressBackend` на трёх платформах —
  это платформенный паттерн кодовой базы, не слоп.
- Мелочь: в ingress loopback-permit вес `weightPermit` (10), а в outbound —
  30; безвредно (разные сабслои), унифицировать не обязательно.
- Комментарии честные после правок (старый «mirroring delete-then-apply»
  удалён — он описывал уже несуществующее поведение).

## Что осталось сделать (не в моей власти)

1. Прогнать `go test ./guard/` на Windows (F1-фикс верифицировать исполнением).
2. Решить судьбу F6 при мерже (разнести коммит).
3. В CI добавить `GOOS=windows go vet ./...` (или `go test -c`) — сейчас
   windows-тесты не исполняются нигде, поэтому F1 дожил до ревью.
4. Дерево сейчас не собирается целиком из-за чужих незакоммиченных WIP
   (`core/engine/validate_tuning.go` конфликтует с `validate.go`,
   `core/censor/types.go` ссылается на несуществующий `obfsv1`) — не трогал,
   не моё.
