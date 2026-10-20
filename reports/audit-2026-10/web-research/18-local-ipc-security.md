# 18. Паттерны безопасности локального IPC привилегированных демонов

Дата: 2026-10-19. Веб-исследование + сверка с текущим `core/ipc` sora (только чтение).

## 1. Что нашёл (паттерны индустрии)

### Tailscale — safesocket + peer credentials + операторская модель
- `safesocket`: Unix-сокет создаётся с правами **0666, только если платформа проверяет peer credentials**, иначе 0600. Философия: широкие права на сокет допустимы, когда каждый `accept()` фильтруется по SO_PEERCRED ([deepwiki — Tailscaled Daemon Architecture](https://deepwiki.com/tailscale/tailscale/5.1-kubernetes-operator)).
- На Windows `ipnserver` привязывает **Actor к каждому HTTP-запросу** и принудительно держит **одного активного пользователя** (`addActiveHTTPRequest` сверяет identity нового соединения с активным).
- Модель «operator»: `tailscale set --operator=USER` — явное делегирование управления непривилегированному пользователю вместо «все, кто дотянулся до сокета» ([NixOS Wiki](https://wiki.nixos.org/w/index.php?title=Tailscale&mobileaction=toggle_view_desktop)).
- Аудит: `tailscale configure audit-log` — решения control-plane пишутся в журнал ([binadit tutorial](https://binadit.com/tutorials/implement-tailscale-oauth-integration-with-identity-providers)).

### Mullvad — gRPC поверх UDS/named pipe, root-демон
- `mullvad-daemon` — долгоживущий root-сервис, management interface — **gRPC через Unix domain socket или named pipe** ([deepwiki — Platform Services](https://deepwiki.com/mullvad/mullvadvpn-app/4.4-linux-system-integration)).
- Свежий урок: **CVE-2026-32323** (CVSS 7.3 HIGH) — LPE в macOS-установщике через *непроверенный путь бандла*: привилегированный процесс выполнял/доверял пути без проверки подлинности ([cve.report](https://cve.report/CVE-2026-32323.pdf)). Урок: всё, что привилегированный демон исполняет или чему доверяет по пути, должно проверяться (подпись/хеш/владелец), а не только IPC-граница.

### Docker — сокет как root-эквивалент
- `/run/docker.sock`: `root:docker`, **0660**. Доступ к сокету = полный root на хосте. `chmod 666` — антипаттерн. Практики 2026: socket-proxy с фильтрацией API (least privilege), auditd на доступ к сокету, rootless mode ([iximiuz Labs](https://labs.iximiuz.com/tutorials/docker-security-introduction-a859718d), [alelapi](https://alelapi.github.io/devops-interview-preparation/kubernetes/cks/secure_docker_daemon/)).

### Windows named pipes — каталог LPE-паттернов
- **Ошибки имперсонации**: сервис вызывает `ImpersonateNamedPipeClient()` и выполняет привилегированные действия от имени клиента — классика Potato-семейства. Правило: привилегированный сервер **никогда не имперсонирует** клиента для своих действий ([Semperis](https://www.semperis.com/blog/windows-privilege-abuse-can-lead-to-active-directory-compromise/)).
- **Явные ACL (SDDL)** на пайпе; пайпы с `Everyone: read/write` — находка для LPE-скана.
- **Pipe squatting / pre-creation**: низкопривилегированный процесс создаёт известный пайп первым → клиент подключается к атакующему и отдаёт ему секреты/команды ([malwaretips](https://malwaretips.com/threads/windows-lpe-vulnerabilities-via-kernel-drivers-and-named-pipes-allows-privilege-escalation.138937/)).
- **Confused deputy**: сервис принимает команды по пайпу без строгой авторизации клиента на каждую операцию.
- Верификация клиента: `GetNamedPipeClientProcessId` + `OpenProcessToken` (SID/сессия/админ) — и зеркально **клиент должен проверять сервер** (`GetNamedPipeServerProcessId` + требование SYSTEM).

### TOCTOU / symlink на Unix-сокетах
- CERT POS01-A: проверять через `lstat` + `fstat` по дескриптору и сравнивать `st_mode/st_ino/st_dev`; `O_NOFOLLOW`; никаких check-then-use по имени ([SEI CERT](https://wiki.sei.cmu.edu/confluence/plugins/viewsource/viewpagesrc.action?pageId=88018216)).
- `unix(7)`: abstract-сокеты **не имеют прав доступа и не подвержены файловым гонкам** (исчезают при закрытии), но и не дают fs-ACL — вся защита ложится на SO_PEERCRED. Pathname-сокеты: для connect нужен write на сокет + write/search на каталог; права задаются umask в момент bind ([man unix(7)](https://www.michaelkerrisk.com/linux/man-pages/man7/unix.7.html)).
- SO_PEERCRED фиксирует uid/pid **на момент connect()** — не на момент вызова RPC.

## 2. Что у sora уже есть (покрытие)

Sora уже реализует большинство базовых паттернов, местами лучше конкурентов:
- SO_PEERCRED на Linux (`ipc_peer_linux.go`), `GetNamedPipeClientProcessId` + токен/сессия на Windows (`ipc_windows.go`) — ядро не доверяет клиентским заявлениям.
- Явный SDDL на пайпе (`SY/BA/владелец-процесса/IU`, маска `0x0012018B` **исключает создание инстансов пайпа клиентом**).
- Auth-уровни `AuthRead/AuthControl` через gRPC credentials + **per-method авторизация с fail-closed по умолчанию** (`control/authz.go`) — это и есть защита от confused deputy.
- Сокет 0666 + фильтрация на accept — ровно паттерн Tailscale safesocket.
- Handshake timeout, cap 128 соединений (FD-exhaustion), отказ без ответа посторонним (не палит endpoint).
- Демон работает **не как root, а как выделенный пользователь `sora`** + жёсткий systemd-sandbox (`ProtectSystem=strict`, `NoNewPrivileges`, caps только NET_*) — сильнее, чем root-демоны Tailscale/Mullvad.
- Сервер **не имперсонирует** клиента (токен открывается только `TOKEN_QUERY`).
- Polkit для эскалации read→control на Linux.

## 3. Что перенять (гэпы)

### HIGH
1. **Клиентская проверка сервера на Windows (anti pipe-squatting).** Сейчас GUI подключается к известному `\\.\pipe\sora-core-v1`; низкопривилегированный процесс может создать пайп с тем же именем первым и получить команды/секреты клиента. Перенять зеркальный паттерн: после `DialPipe` клиент вызывает `GetNamedPipeServerProcessId`, открывает процесс и требует токен SYSTEM (или SID сервисного аккаунта); иначе — отказ и громкий алерт. Почему: единственный реальный LPE-вектор из каталога выше, не закрытый сейчас.
2. **Привязка polkit-гранта к соединению одноразовым токеном.** Сейчас AuthControl выдаётся на accept по peer-политике. Для привилегированных RPC добавить короткий-lived nonce, выданный в момент polkit-авторизации и передаваемый в gRPC metadata: защищает от сценария «процесс получил control, затем его pid переиспользован / токен украден другим процессом того же uid». Почему: SO_PEERCRED — снимок на момент connect; долгоживущие gRPC-стримы живут часами.
3. **Урок CVE-2026-32323: verify-before-execute.** Всё, что `sora-core` запускает с привилегиями (движки из `-engines-dir`, скрипты zapret, обновления), должно проверяться по подписи/хешу и владельцу каталога *до* exec, а не только в момент доставки обновления. IPC-граница уже закрыта; граница «доверенных путей» — следующий рубеж.

### MEDIUM
4. **Аудит auth-решений control-plane** (паттерн Tailscale audit-log): в журнал — кто (uid/pid/SID), когда, какой RPC, allow/deny, уровень. У sora уже есть категории журнала — добавить категорию `auth`. Дёшево, бесценно при инцидентах.
5. **Per-UID rate limiting поверх глобального cap 128.** Один локальный пользователь может крутить connect/disconnect и держать слоты/нагружать accept-цикл. Лимит вида N conn/min на uid (sliding window) + jittered backoff в клиенте.
6. **Single-user enforcement на Windows** (паттерн Tailscale `addActiveHTTPRequest`): сейчас AuthControl получает *любой* активный-сессионный пользователь и админ. Привязать control-права к сессии/пользователю, от которого запущен GUI (или к первому авторизованному), остальных — в read-only. Закрывает «второй пользователь на терминальном сервере управляет чужим VPN».
7. **Повторная проверка peer перед деструктивными RPC** (stop service, engine update, config wipe): свежий SO_PEERCRED/`GetNamedPipeClientProcessId` на момент вызова, а не кэш с handshake. Дешёвый вызов, убивает класс TOCTOU «connect → exec → подмена».

### LOW
8. **SO_PASSSEC / SELinux-метки пира** — только если появится MAC-профиль; сейчас избыточно.
9. **Abstract-namespace сокет как опция** — убирает файловые гонки, но теряет fs-ACL и непереносим; pathname + SO_PEERCRED уже достаточно.
10. **Публичный threat-model документ для IPC** («сокет 0666 безопасен, потому что…; граница доверия — процессы uid X; что НЕ защищает») — для аудиторов и прозрачности open-source. У Mullvad/Tailscale это частично в docs; у sora будет дифференциатором.

## 4. Оценка эффекта

| # | Мера | Эффект | Сложность |
|---|---|---|---|
| 1 | Client-side server verification (Windows) | high | S |
| 2 | Nonce-привязка polkit-гранта к соединению | high | S/M |
| 3 | Verify-before-execute для движков/скриптов | high | M |
| 4 | Аудит auth-решений | medium | S |
| 5 | Per-UID rate limit | medium | S |
| 6 | Single-user enforcement (Windows) | medium | S |
| 7 | Re-check peer перед деструктивными RPC | medium | S |
| 8–10 | SO_PASSSEC / abstract socket / threat-model doc | low | S |

**Вывод:** базовый слой IPC у sora уже на уровне Tailscale/Mullvad, а песочница демона — сильнее (не-root + systemd hardening). Реальные гэпы — на стороне клиента Windows (squatting), времени жизни авторизации (nonce, re-check) и доверенных путей исполнения (урок CVE-2026-32323). Всё закрывается без смены архитектуры.
