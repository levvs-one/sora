# SW2 — ingress-защита (защита от входящих мимо туннеля)

Агент: SW2b (Go, `core/guard`). Ветка: `bugfix/audit-2026-10-19`, коммиты `[swarm] … (SW2)`, без пуша.
Ограничение: только НОВЫЕ файлы в `core/guard/`; существующие файлы пакета не тронуты.

## Что реализовано

Декоратор `IngressFirewall` поверх платформенного `Firewall` (композиция, без
изменения существующего кода). Ingress-правила ставятся ровно тогда, когда
армится kill switch (требование «по умолчанию вкл когда включён kill switch»),
снимаются при Disarm. `IngressConfig.Enabled=false` — выключаемо, kill switch
при этом работает как раньше.

Порядок правил (везде): loopback → интерфейс туннеля → established/related →
VPN-endpoints → LAN (по настройке) → финальный drop. Drop никогда не трогает
установленные соединения: на Linux их раньше принимает conntrack, на Windows
слой ALE_AUTH_RECV_ACCEPT видит только установку соединения, установленные
потоки реавторизацию не проходят.

Новые файлы (`core/guard/`):

- `ingress.go` — `IngressConfig`, `DefaultIngressConfig()` (вкл, loopback и
  LAN сохранять), валидация эндпоинтов (IP или ip:port; мусор/доманы/инъекции
  → fail closed), декоратор `WithIngress(inner, cfg)` (`Arm`/`Disarm`/`Armed`
  делегируют внутрь; отказ kill switch — например root-UID на Linux — роняет
  Arm до установки ingress-правил), `IngressArmed()`, `Name()`.
- `ingress_nftables.go` — чистый рендер (без build-тега, тестируется везде):
  `NftIngressRuleset(cfg, bypass)` — таблица `sora_ingress`, цепочка `ingress`
  на хуке `input`; `NftIngressRemove()`.
- `ingress_linux.go` (`//go:build linux`) — бэкенд поверх `*Nftables`:
  переиспользует доверенный путь к `nft` и `apply` (тот же пакет, ничего
  своего не резолвит/не исполняет); Arm — delete-then-apply (идемпотентность
  по паттерну SORA-M4), Disarm терпит отсутствие таблицы (SORA-M5).
- `ingress_windows.go` (`//go:build windows`) — бэкенд с собственной dynamic
  WFP-сессией («Sora ingress guard»): правила только на
  `ALE_AUTH_RECV_ACCEPT_V4/V6`, переиспользует веса/хелпер `applies` пакета;
  loopback, arrival iftype 53 (wintun), endpoints (/32//128), LAN bypass,
  финальный block с минимальным весом. Сессия закрывается на Disarm и
  снимается Windows при падении процесса.
- `ingress_other.go` — не-Linux/Windows: `NoopFirewall` → no-op (Android/
  VpnService, туннелем владеет ОС); неизвестный тип фаервола → fail closed.
- Тесты: `ingress_test.go` (конфиг, парсинг/реджект эндпоинтов, порядок
  правил, негативный «ровно один drop и он последний; established раньше»,
  AllowLAN=false, делегирование, disabled, отказ inner, Noop),
  `ingress_linux_test.go` (фейковый `nft`: установка/снятие обеих таблиц,
  идемпотентность, uid 0 роняет всё до ingress),
  `ingress_windows_test.go` (внутренний, без касания хоста: структура правил,
  только recv-слои, веса, AllowLAN=false).

Проверено: `gofmt` чист (мои файлы), `go vet` + `go build` + `go test`
зелёные на Linux; кросс-компиляция Windows — `build`+`vet`+компиляция тестов
OK; Darwin — `build` OK. Тулы: Go 1.24.0 докачан в `~/workspace/.tooling/go`
(в окружении его не было).

## Хук, который нужен в существующем коде (я его не правил)

1. **Wiring.** Там, где результат `guard.PlatformFirewall(opts)` передаётся в
   `guard.New(...)` (bootstrap сервиса/ядра), обернуть:
   ```go
   fw, err := guard.PlatformFirewall(opts)
   fw = guard.WithIngress(fw, ingressCfg)
   g, err := guard.New(guard.Options{EnginePorts: ...}, fw)
   ```
   `ingressCfg` собрать из `guard.DefaultIngressConfig()` + оверрайды:
   `VPNEndpoints` — адреса серверов активного плана (формат `ip`/`ip:port`),
   `AllowLAN` — из пользовательской настройки, `Enabled` — из настройки
   (дефолт true).
2. **Настройки.** В UI/слое конфигурации нужно поле `IngressEnabled`
   (дефолт вкл) и опционально `IngressAllowLAN`. В `session.Settings` и
   `FirewallOptions` я ничего не добавлял (чужие файлы) — маппинг
   «настройка → IngressConfig» делает владелец хука.
3. **Linux crash recovery.** Stale-таблица `sora_ingress` после падения
   заменяется при следующем Arm (delete-then-apply); отдельного
   `CleanupStale` для неё нет — при желании добавить вызов в стартап-очистку
   рядом с `Nftables.CleanupStale`.
4. **Windows.** Ничего дополнительно не нужно: сессия dynamic, фильтры
   снимаются на Disarm/падении.

## Отклонено фильтром слопа (директива владельца)

- **Per-port матчинг VPN-endpoint'ов в nftables** — вырезано сознательно:
  новое входящее от сервера идёт с эфемерного sport, привязка к порту была
  бы неверной семантикой. Доверие — по адресу (серверу, которому отдаём
  весь трафик, доверяем и входящие). Порт в `ip:port` принимается
  синтаксически ради UX (списки серверов — это host:port), но в правила не
  идёт; это задокументировано, а не «тихо проигнорировано».
- **Перечисление физических интерфейсов** — не нужно: упорядоченные
  accept-правила (lo, tun, established, endpoints, LAN) делают финальный
  drop корректным без хрупкого discovery интерфейсов.
- **Отдельное established-правило на Windows** — не нужно архитектурно
  (см. выше про ALE_AUTH_RECV_ACCEPT); не стал изображать conntrack там,
  где его нет.
- **Расширение `session.Settings`/`FirewallOptions`** — не моё (чужие
  файлы); вместо этого задокументирован хук выше.

## Риски и что не проверено

- Поведенческий тест на реальном Windows-хосте (аналог
  `TestWFPBlocksWhatIsNotTheTunnel`: входящий SYN на физический интерфейс
  дропается, established и LAN живы) — нужен Windows-раннер; структура
  правил покрыта юнит-тестом.
- Pre-existing, не моё, но блокирует `go vet`/`go test` пакета под Windows:
  `nftables_test.go` (без build-тега) ссылается на linux-only
  `guard.NftBinForTest`. Под Linux всё зелёное. Кто владеет файлом —
  добавить `//go:build linux` или вынести хук.
- Pre-existing `gofmt` ругается на `guard/nftables.go` (склеенная строка
  `} string {` в `NftRuleset`) — чужой файл, не правил.
- `go build ./...` всего модуля падает в `core/profiles`
  (`undefined: defaultRoute/currentSSID`) — pre-existing, другой агент,
  к guard не относится.
