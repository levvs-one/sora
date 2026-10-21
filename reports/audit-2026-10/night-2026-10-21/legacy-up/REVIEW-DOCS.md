# REVIEW-DOCS — независимый факт-чек документации коммита ee5f2ba [legacy-up] docs

Репозиторий: `sora-legacy`, ветка `bugfix/audit-2026-10-19`, HEAD = `ee5f2ba`.
Метод: все сверки — по закоммиченному состоянию (`git archive HEAD` в чистый
каталог), не по рабочему дереву. Код и доки не правились, коммитов не делалось.

Объект: 8 файлов — `README.md`, `README.en.md`, `docs/install.md` (новый),
`docs/development.md` (новый), `docs/security.md` (новый),
`docs/architecture/engines.md`, `legacy/docs/platforms.md`, `packaging/README.md`.

**Итог: коммит в целом честный и заметно лучше прежнего состояния, но НЕ принять
без правок.** Найдены 3 существенных расхождения док↔код (одно — завышение
гарантии безопасности в трёх файлах сразу, одно — несуществующее «1:1»
повторение CLI, одно — прямое противоречие внутри комплекта доков) и несколько
средних/мелких. Всё остальное из обязательного списка (пп. 2, 3, 4, 6, 7, 8, 9,
10 задания) подтверждено по первоисточникам — детали ниже.

---

## Расхождения док ↔ код (по тяжести)

### Р-1. СУЩЕСТВЕННОЕ, безопасность: проверка `.dgst` при обновлении ядер из GUI заявлена для всех ядер, код проверяет только v2fly/v2fly_v5/Xray; sing-box (SagerNet), clash, clash_meta обновляются БЕЗ сверки хеша

Доки (одинаковое безусловное утверждение в трёх файлах):

- `README.md` (§Безопасность): «Обновление ядер из поставляемого клиента
  сверяет SHA-256 архива с `.dgst`-манифестом релиза до распаковки.»
- `docs/install.md:55`: «поставляемый клиент умеет обновлять ядра (Xray,
  **sing-box и другие из своего списка**) и геобазы с официальных релизов.
  Архив ядра до распаковки сверяется по SHA-256 с `.dgst`-манифестом релиза;
  несовпадение — отказ, бинарь не заменяется.»
- `docs/security.md`: «Обновление ядер из поставляемого клиента сверяет
  SHA-256 скачанного архива с `.dgst`-манифестом официального релиза до
  распаковки. Не прошёл проверку — не распаковывается…»

Код — `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs`, `VerifyCoreArchiveAsync`:

```csharp
private static bool HasChecksumManifest(ECoreType type)
{
    // v2fly и XTLS публикуют .dgst-файлы рядом с ассетами релиза.
    switch (type)
    {
        case ECoreType.v2fly:
        case ECoreType.v2fly_v5:
        case ECoreType.Xray:
            return true;
        default:
            return false;
    }
}
```

и при `!HasChecksumManifest(type)`:

```csharp
// Апстрим не публикует .dgst в предсказуемом виде для этого движка —
// ограничение задокументировано; запрет downgrade (см. выше) действует всегда.
Utils.SaveLog($"Checksum manifest is not available for core {type}; skipping hash verification.");
return null; // = проверка пройдена, обновление продолжается
```

Т.е. для `SagerNet` (это и есть пункт меню обновления sing-box), `clash`,
`clash_meta` сверки нет вообще — только запрет downgrade. Утверждение
исполнителя «обновления ядер из GUI — SHA-256 против .dgst до распаковки»
верно лишь для 3 из 5 типов ядер в меню. Для security.md безусловная форма
недопустима: читатель получает гарантию, которой для sing-box нет.

Правка: во всех трёх местах ограничить утверждение типами v2fly/Xray и прямо
сказать, что для sing-box и clash/mihomo `.dgst` апстрим не публикует в
предсказуемом виде, проверка хеша там пропускается, действует только запрет
downgrade (как честно написано в комментарии кода).

Замечание в плюс: геобазы проверяются отдельно и fail-closed, по
`{url}.sha256sum` (`VerifyGeoFileAsync`) — доки этого не искажают (про геобазы
заявлен только источник, не `.dgst`).

### Р-2. СУЩЕСТВЕННОЕ: «новый клиент повторяет CLI-контракт один в один» — неверно для `--tun`: новый Client `--tun` не обрабатывает вообще

Док — `docs/install.md:40` и таблица под ней:

> «Контракт, который сегодня работает у пользователя (реализация — `Program.cs`
> поставляемого клиента; **новый клиент повторяет её один в один** и добавляет
> импорт по ссылке)» — и в таблице строка `| --tun | стартовать с режимом TUN |`.

Поставляемый клиент: `--tun` есть — `legacy/v2rayN/v2rayN/Program.cs:59-60`
передаёт `args.Any(arg => … "--tun" …)` вторым параметром в `MainForm`.

Новый клиент: `--tun` отсутствует полностью.

- `legacy/Client/ClientContract.cs:12-15` — только `SilentArgument`,
  `RestoreProxyArgument`, `WaitForArgument`, `LinkSchemePrefix`; константы TUN
  нет.
- `legacy/Client/Program.cs:14-22` — собственный заголовок-контракт перечисляет
  `--silent`, `--restore-proxy`, `--wait-for`, `sora://…` — и всё; `Main` не
  смотрит `--tun` нигде (grep по `legacy/Client/*.cs`: `--tun` не встречается).
- Режим TUN нового клиента берётся из сохранённой настройки
  (`ClientSettings.Tun`, по умолчанию `True`), а не из аргумента запуска.

Итог по п.1 задания: `--silent` / `--restore-proxy` / `--wait-for` (15 с,
`WaitForExit(15000)` в обоих) / single-instance (mutex по пути exe + активация
окна через `HKCU\Software\Sora`, значение `WindowHwnd_<MD5 каталога>`) новый
Client действительно повторяет 1:1, `sora://` добавляет, и мертва сегодня
только обработка `sora://` поставляемым клиентом — всё это подтверждено. Но
`--tun` в «1:1» не входит: после смены комплекта `sora_x.exe --tun` будет
молча проигнорирован (частично маскируется тем, что `Tun` по умолчанию True,
но это не контракт аргумента).

Правка: либо убрать `--tun` из фразы про 1:1 и оговорить его как известный
разрыв, либо убрать строку из таблицы «повторяемого» контракта и вынести в
честные ограничения нового клиента рядом с AUTO_DETECT/RAS.

### Р-3. СУЩЕСТВЕННОЕ: README — «Ядром пользуются оба клиента поколения» — ложь, противоречит собственному install.md

Док — `README.md:34`: «Ядро — служба на Go (`core/`), контракт `sora.core.v1`
версии 1.7; на Windows служба регистрируется как `SoraLegacyCore`. **Ядром
пользуются оба клиента поколения.**»

Код: в поставляемом клиенте нет ни одного обращения к службе ядра
(grep по `legacy/v2rayN/v2rayN/**/*.cs`: `SoraLegacyCore`, `sora-core`,
named pipe, CoreService — 0 совпадений); он запускает бинари движков сам
(`Handler/V2rayHandler.cs` и др.). Службой пользуется только новый клиент
через `legacy/Control`. Собственный же `docs/install.md` говорит правильно:
«Службу `SoraLegacyCore` этот установщик **не ставит**: поставляемый клиент
запускает движки сам. Служба — путь нового клиента и разработки».

Правка: в README заменить на «ядром пользуется новый клиент; поставляемый
клиент запускает движки сам».

### Р-4. СРЕДНЕЕ: «проверка обновлений интерфейса прямо сообщает…» — сообщающий код мёртв; живой обработчик просто открывает страницу релизов в браузере

Доки:

- `README.md`: «Самообновления у самого клиента нет: **проверка обновлений
  интерфейса прямо сообщает, что официальные сборки публикуются в
  репозитории**.»
- `docs/install.md`: «Проверка обновлений интерфейса отключена и **прямо об
  этом сообщает**.»

Код: метод действительно существует и говорит ровно это —
`UpdateHandle.cs:142-145`:

```csharp
public void CheckUpdateGuiN(Config config, Action<bool, string> update, bool preRelease)
{
    update(false, "Самообновление Sora отключено: официальные сборки публикуются в репозитории sora-client.");
}
```

Но единственный вызов закомментирован — `Forms/MainForm.cs:1446`:

```csharp
//(new UpdateHandle()).CheckUpdateGuiN(config, _updateUI, config.checkPreReleaseUpdate);
```

а живой обработчик пункта меню (`MainForm.cs:1434-1437`) делает только
`Process.Start(Global.UpdateUrl)`, где
`Global.cs:13: UpdateUrl = "https://github.com/levvs-one/sora-legacy/releases"`.

Суть (самообновления нет, обновление — ручная переустановка) — правда, и
п.5 задания в этой части подтверждён. Но механизм описан неверно: пользователь
не видит никакого сообщения — у него открывается страница релизов. Заодно
текст мёртвого метода ссылается на «репозитории sora-client», а URL ведёт на
sora-legacy.

Правка: «пункт проверки обновлений интерфейса открывает страницу релизов в
браузере; самообновления нет» — во всех местах.

### Р-5. СРЕДНЕЕ: development.md — «Пять проектов net48» при шести в репозитории; пропущен именно поставляемый клиент

`docs/development.md:50`: «Пять проектов net48:» — и список Client, Control и
три Interop. В репозитории net48-проектов шесть: пропущен
`legacy/v2rayN/v2rayN/v2rayN.csproj` (`<TargetFramework>net48</TargetFramework>`)
— тот самый поставляемый клиент, который раздел ниже собирает через
`Build-WindowsProfiles.ps1`. Формулировка «пять проектов» читается как полный
состав. Дополнительно `Control` и `ControlInterop` мультитаргетны
(`net48;net8.0`), что под заголовком «проекты net48» — упрощение.

Правка: «Проекты нового клиента и тестов (net48; Control и ControlInterop —
также net8.0)» + строка сборки v2rayN или отсылка к разделу профилей.

### Р-6. МЕЛКОЕ, но фактическое: install.md — порядок шагов установщика обратный коду

`docs/install.md` перечисляет: шаг 1 — проверка/установка .NET, шаг 2 — KB3033929.
В `Sora.iss`, `PrepareToInstall`: сначала блок
`if IsWindows7 and not IsWin64 and not IsKb3033929Installed` (строка 152),
затем `if not IsDotNet48Installed` (строка 179). Содержимое шагов (порог
`Release >= 528040`, обе ветки реестра на x64, SHA-256 обоих встроенных
установщиков до запуска, `/q /norestart`, `wusa.exe /quiet /norestart`,
коды 3010/1641 → перезагрузка) — всё верно; переставлен только порядок.

### Р-7. МЕЛКОЕ: engines.md §9 — после правки осталась строка не этого поколения

Заголовок и §9 поправили корректно (см. п.9 ниже), но в таблице §9 осталась
строка «Dart-код контракта **1.3** | `protoc-gen-dart` на машине разработки не
установлен…» — наследие основного репозитория: в этом репозитории Dart-кода
нет, контракт — 1.7. Историческая пометка в шапке это частично прикрывает,
но строка вводит в заблуждение именно о контракте этого поколения.

---

## Подтверждено по первоисточникам (обязательный список задания)

**П.1 (остальное).** Single-instance: поставляемый — mutex по
`Utils.GetExePath()` (`\\`→`/`), при дубле читает hwnd из
`HKCU\Software\Sora` (`Global.MyRegPath = "Software\\Sora"`,
`WindowHwndKey = "WindowHwnd_" + GetMD5(StartupPath())`), `ShowWindow(hwnd,4)`,
`SwitchToThisWindow`. Новый — та же схема (`ClientContract.RegistryPath`,
`WindowHwnd_ + AutoRun.DirectoryHash`). Коды `--restore-proxy`: 0 — нет записи
или восстановлено, 1 — повреждённая запись/не удалось применить; без
`--silent` — подтверждение (LEGACY-L11 в обоих). Всё сходится с install.md.

**П.2.** Службы в `Sora.iss` нет: ни `[Service]`, ни регистрации, grep
`SoraLegacyCore` по `legacy/installer/Sora.iss` и `legacy/build/*.ps1` — пусто.
Служба — `core/cmd/sora-core/service_windows.go:22` (`serviceName =
"SoraLegacyCore"`), ставится самой службой: `cli.go:75-76`
`--install-service` / `--uninstall-service`. Доки относят это верно
(install.md, development.md).

**П.3.** `[UninstallDelete]` в `Sora.iss` — ровно список доков:
`guiNConfig.json`, `statistics.json`, `guiLogs`, `guiTemps`, `guiBackups`,
`guiConfigs` → подписки/настройки поставляемого клиента удаление не переживают;
доки предупреждают об этом прямо и в README-контексте, и в install.md п.4 —
верно. Обновление поверх переживает: `Stage-Release.ps1` исключает
`guiNConfig.json` из комплекта
(`$_.Name -notin @('grpc_csharp_ext.x64.dll', 'guiNConfig.json')`), каталоги
данных в stage не входят. `%APPDATA%\sora-legacy\core` установщик/
деинсталлятор не упоминают — не трогается, верно. `RemoveOrphanedAutoRun` —
сканирует `HKCU\…\Run`, удаляет только `SoraAutoRun_*`, чья командная строка
содержит exe-путь именно этой установки (`Pos(ExePath, Lowercase(Value)) > 0`)
— доки точны, включая «другая копия Sora не трогается». Автозапуск внутри
клиента: `SoraAutoRun_<MD5(StartupPath())>`, команда `"<exe>" --silent`
(`Tool/Utils.cs:545,574`) — совпадает с install.md и с новым `AutoRun.cs`.

**П.4.** Пути restore-proxy в доках не смешаны. Поставляемый:
`SysProxyHandle.ResetIEProxy` — запись `user-wininet.json`
(`UserWininetConfigFile`), replay через bundled `sysproxy.exe`
(`set <flags> <server> <bypass> <pac-url>`), файл удаляется после успешного
replay; нет записи — успех; повреждённая — `InvalidDataException` → false → 1.
Новый Client: `legacy/Client/SystemProxy.cs` — нативный replay именованных
значений HKCU Internet Settings, PAC (`AutoConfigURL`) восстанавливается при
флаге `PROXY_TYPE_AUTO_PROXY_URL`; честные ограничения в шапке файла дословно
совпадают с подразделом install.md: бит `AUTO_DETECT` не восстанавливается
(живёт только в бинарном `DefaultConnectionSettings`, который не
переписывается), per-connection RAS не переигрываются, `sysproxy.exe` старого
пути применяет шире. Каждое утверждение отнесено к правильному клиенту/статусу.

**П.5 (остальное).** Самообновления GUI нет (см. Р-4 про механизм). Флаг службы
в security.md назван верно: `-allow-unverified-engines`, default off,
development-only — `core/cmd/sora-core/cli.go:80` («off by default because a
deleted or corrupted manifest must not be enough…»); при отсутствии/
нечитаемости `SHA256SUMS` discovery падает closed (`supervise/binary.go`).
Продукт — только ручная переустановка: другого механизма в коде нет.

**П.6.** Пины сходятся до символа. `packaging/engines/engines.lock`:
sing-box **1.14.3 upstream** (SagerNet, linux amd64/arm64), Xray **26.3.27**
(комментарий lock: XTLS помечает новые теги prerelease — как в
development.md), mihomo **1.19.32**. Windows-payload: `Stage-Release.ps1`
сверяет `xray.exe`, `sing-box.exe` и все 4 файла tun2proxy с SHA-256, зашитыми
в скрипт; что Windows sing-box — lx-форк, доки честно ссылают на
`legacy/PLANS.md` (там: «sing-box-lx 1.14.3-lx.14 Win7 x86») — в самом скрипте
форк никак не помечен, ссылка на PLANS корректна как источник. KeyShare:
`core/engine/catalog.go` — статической заявки у sing-box нет; в
`BuildCapabilities` заявка ставится только при
`strings.HasPrefix(version.PreRelease, "lx.")` и версии ≥ 1.14.3. Доки
(README, development.md, шапка engines.md) описывают это верно: «только для
lx-варианта; на upstream не заявляется; ядро заявляет при обнаружении
lx-сборки».

**П.7.** Разрыв ровно 13 RPC, список задания точен. Legacy proto
(`proto/sora/core/v1/core_control.proto`) — **30 RPC**; эталон основного
репозитория — 43 RPC; разность множеств (comm) — ровно:
`BenchmarkServers, CheckDnsLeaks, DeleteProfile, GetBenchmarks,
GetDeviceIdentity, GetNetworkFingerprint, GetSubscriptionOverride,
ListProfiles, ProbeChain, SaveProfile, SaveSubscriptionOverride, SelectServer,
SetDeviceIdentity` — ни одного лишнего (все 13 действительно отсутствуют в
legacy), ни одного пропущенного, legacy-only RPC нет. Версия контракта 1.7
подтверждена: `core/cmd/sora-core/main.go:46` —
`Version = control.Version{Major: 1, Minor: 7, MinSupportedMinor: 1}`.
Оговорка к форме: README даёт счёт «13 RPC» и называет три примера +
категории (профили, цепочки, переопределения по RPC, синхронизация) — полного
поимённого списка из 13 в самих доках нет; счёт и примеры верны. Рекомендация:
привести список полностью — он короткий и снимает вопрос сверки у читателя.
Также верно: файл переопределений ядро читает и применяет при каждом
обновлении (`core/control/override.go`, `core/subscription/override.go`,
store под `<dataDir>/overrides/`), а `Save/GetSubscriptionOverride` RPC нет —
формулировка README («интерфейс запись переопределений пока не предлагает»)
точна, в UI нового клиента override-записи нет.

**П.8.** `packaging/README.md` после правки: обещаний MSI/AppImage/APK/AAB/
F-Droid/подписи не осталось; наоборот, прямым текстом «Никаких MSI, AppImage и
Android-пакетов в этом репозитории нет» и «подпись не выпускается и
документация её не обещает». Таблица каталогов соответствует факту:
`engines/fetch.sh` (HTTPS, стоп при несовпадении суммы, geo из архива Xray,
пишет `SHA256SUMS`), `zapret/build.sh` (собирает tpws+nfqws из
`third_party/zapret` во временном каталоге, **дописывает** дайджесты в
`SHA256SUMS` — запускать после fetch.sh; формулировки development.md про
«tpws проверяется строго, nfqws — для полноты, ядро использует tpws»
совпадают с комментарием build.sh про `verifyTpws` и tpws-only ядро),
`linux` — nfpm, один `nfpm.yaml`, deb/rpm/archlinux. `platforms.md` Linux:
графического клиента не обещано («Графического клиента для Linux в этом
поколении нет»), пакеты — только служба ядра, оговорка «установка на живой
системе не проверялась (нужен root); проверены состав, скрипты, systemd-unit,
polkit» совпадает с `packaging/linux/README.md`.

**П.9.** Все относительные ссылки в 8 изменённых файлах ведут на существующие
файлы; якоря `docs/install.md#обновление` и `#удаление` — на существующие
заголовки. Все упомянутые пути/команды существуют и названы верно:
`legacy/build/Stage-Release.ps1` (параметры в примере development.md —
`-SourceBin/-StagePath/-CompatPayload/-XrayArchive/-WindowsTarget` — совпадают
с param-блоком скрипта), `legacy/build/Build-WindowsProfiles.ps1` (ровно 4
профиля win7/win8/win10/win11, `sora_<цель>.exe`, win8 = 8.1),
`packaging/zapret/build.sh`, `packaging/engines/fetch.sh amd64 dist/engines`,
`nfpm.yaml` (в development.md рецепт пакета дословно совпадает с
`packaging/linux/README.md`, включая `SORA_VERSION=0.3.0` как пример),
`.github/workflows/legacy.yml` (job `windows-x86`, Go Win7 SDK 1.26.9 с
SHA-256 в workflow — как заявлено), `core/cmd/sora-core/cli.go` (ссылка про
`SORA_LEGACY_DATA_DIR` уместна: env игнорируется для привилегированного
запуска, `cli.go:128-142`), `docs/architecture/core.md`, `legacy/PLANS.md`,
`SECURITY.md`. `engines.md`: шапка теперь помечает документ историческим
(«Дата проверки 06.10.2026 (исторический разбор…)»), пины в шапке исправлены
на фактические (было «sing-box v1.14.2» — стало 1.14.3 upstream, mihomo
1.19.32, Xray 26.3.27), строка §9 о поставке движков исправлена верно
(Linux: fetch.sh+SHA256SUMS fail-closed; Windows: Stage-Release.ps1).
Осталась только строка про Dart 1.3 — Р-7.

**П.10.** Маркетинговых обещаний сверх кода не найдено (поиск по превосходным
формам/«полная защита»/«гарантир…» по всем 8 файлам — пусто). Статус нового
Client и stage нигде не приукрашен — кроме Р-2/Р-3. Подпись релиза:
`docs/security.md` говорит прямо — «Подписи релизов установщика (minisign,
Authenticode) пока не выпускаются… установщик неподписан» — соответствует
факту (ни в iss, ни в Stage-Release, ни в packaging подписи нет; minisign-ключ
— placeholder/церемония не проведена). Остальные утверждения security.md
сверены и верны: AES-256-GCM + свежий nonce на запись (`core/secret/store.go`),
DPAPI user-scope (`protector_windows.go`: `CRYPTPROTECT_LOCAL_MACHINE` не
выставлен), каталоги `0700` (`main.go:127`, store `dirMode = 0o700`), журнал
только в памяти (`core/logs`), маскирование секретов в журнале/диагностике,
подписки только `https://` (`subscription.ValidateReference`: http →
`CodeUnsupported`, «would send the token in clear»), телеметрии в ядре нет,
конфигурация движкам — по stdin, не файлом/аргументами
(`supervise/process.go:30-31`). README-утверждения ядра также подтверждены:
TUIC default BBR (`core/engine/quic_defaults.go:49`), Hy2 up/down + port
hopping (catalog), классический VMess base64 (`parser.go:668`), fallback-ссылка
подписок (W2, `core/control/subscriptions.go`), обфускация fetcher'а —
фрагментация ClientHello/FakeSNI/джиттер (`core/obfs/`, применяется в
`subscription.New`), супервизор с бюджетом рестартов (default 5,
`supervise/supervisor.go:181-182`).

Мелкие неточности security.md, не блокирующие: «управление … с проверкой
вызывающей стороны и токеном» — токен требуют не все методы
(`core/control/server.go:126-157` честно фиксирует известные gaps:
Handshake/SetKillSwitch/PutSecret/DeleteSecret без токена, реальная граница —
peer allow-list транспорта). Формулировку стоит смягчить до «локальный
транспорт с проверкой вызывающей стороны; часть методов — с токеном».

---

## Вердикты по файлам

| Файл | Вердикт |
| --- | --- |
| `README.md` | **Правки по списку**: Р-1 (.dgst), Р-3 («оба клиента»), Р-4 (сообщение об обновлении). Рекомендация по п.7 — полный список 13 RPC. |
| `README.en.md` | **Принять** (все его утверждения сверены и верны: поставляемый exe, stage, мёртвый `sora://`, 31 язык, проверки на современной Windows). Замечание — в «Мелочах». |
| `docs/install.md` | **Правки по списку**: Р-2 (--tun/1:1), Р-1 (.dgst incl. sing-box), Р-4, Р-6 (порядок KB/.NET). |
| `docs/development.md` | **Правки по списку**: Р-5 («пять проектов»). Остальное (рецепты ядра/клиентов/движков/zapret/nfpm/установщика, пины, lx-оговорки, каталог данных) — верно. |
| `docs/security.md` | **Правки по списку**: Р-1 (.dgst без оговорок — для security-дока это главное), смягчение фразы про токен управления. Остальное — образцово честно, включая неподписанный установщик. |
| `docs/architecture/engines.md` | **Принять с одной мелкой правкой**: Р-7 (строка Dart/контракт 1.3 в §9). Шапка-«исторический», пины и строка поставки движков исправлены верно. |
| `legacy/docs/platforms.md` | **Принять**: профили, значения Inno по умолчанию и для 8.1/10/11 (`6.1sp1` default; `6.3`, `10.0`, `10.0.22000`), Linux-раздел — всё по `Sora.iss`/`Build-WindowsProfiles.ps1`/`legacy.yml`/nfpm. |
| `packaging/README.md` | **Принять**: несуществующих артефактов и подписи не обещает; состав каталогов соответствует скриптам. |

---

## Мелочи

- **Двуязычие.** Полнота только в RU — это в README.en.md честно объявлено
  («Full documentation is in Russian»), но англоязычный читатель не узнаёт
  даже про **удаление подписок при деинсталляции** — материальное
  предупреждение, стоит добавить одной строкой в EN.
- **Терминология.** `docs/install.md` пишет регистрацию протокола как
  `HKCU\Software\Classes\sora`; в `Sora.iss` стоит `Root: HKA` — при
  per-user установке (`PrivilegesRequired=lowest`) HKA резолвится в HKCU, по
  факту верно, но буква скрипта другая; единообразнее писать «HKA (при
  per-user установке — HKCU)». Заодно: только первая запись `[Registry]`
  несёт `uninsdeletekey`, удаление «целиком» работает за счёт дерева ключа —
  док прав, уточнение не требуется.
- **Локализм в публичном доке.** `docs/development.md`: «Локально — системный
  Go или сборка из `~/workspace/go`» — путь конкретной dev-машины; внешнему
  читателю ничего не говорит, убрать или заменить на «любой Go с PATH».
- **README, список протоколов ядра** не включает AnyTLS, хотя ядро его несёт
  (catalog mihomo/sing-box, рендеры есть; share-ссылок `anytls://` parser не
  знает — только подписки). Это недообещание, не переобещание; добавить с
  оговоркой «по подпискам» или оставить. В той же строке KeyShare: фраза
  «рендерится только для lx-варианта sing-box» верна в sing-box-скоупе, но
  mihomo KeyShare заявляет статически (catalog) — читатель может прочитать
  шире, чем написано.
- **XHTTP `extra` в README** — оговорка «в пределах возможностей конкретного
  движка» спасает утверждение (у sing-box download-split не заявляется ни на
  одной сборке, у lx — xmux/padding только с `with_xhttp`), формулировка
  корректна, менять не надо.
- **install.md, шаг удаления 1**: «переигрывает запись … и удаляет запись» —
  удаление файла происходит только в ветке `UserSettingsRecorded == true`;
  при записанном, но не помеченном файле поставляемый клиент файл не удаляет
  (новый, кстати, тоже). На итог деинсталляции влияет косвенно (файл всё равно
  сносится с каталогом), в док можно не тащить.
- **Форматирование**: таблицы и заголовки во всех 8 файлах рендерятся,
  UTF-8 валиден, битых символов нет (казавшийся мусор в терминальном выводе —
  кодировка вывода, не файлов). В `docs/development.md` пример
  `Stage-Release.ps1` снабжён плейсхолдерами `<…>` — единообразно с остальными
  рецептами файла.
