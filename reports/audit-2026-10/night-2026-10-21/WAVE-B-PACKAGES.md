# WAVE-B-PACKAGES — волна B, часть 1: реальные пакеты, чистая установка, скриншоты

Ветка `bugfix/audit-2026-10-19`, исходный HEAD `70d36744`. Версия пакетов —
**1.0.12** (из `app/pubspec.yaml` `1.0.12+13`, по правилу packaging/linux/README).
Все артефакты собраны из чистого `git archive HEAD` (каталог
`~/workspace/bug-hunt/waveb/src`), не из рабочего дерева.

Статус по разделам: сборка ✅ · содержимое пакетов ✅ · установка в чистое
окружение ✅ (ALL-OK) · скриншоты ✅ (детали — в разделах 4–6).

SHA-256 пакетов (из `waveb/src/dist`):
- core deb `48154a07c38553229318aff45f2c6f5323dec30d683a1779f992cd915f4cbd3b`
- core rpm `cc195b0d7d19329017de5dec43c0ae9b1c950775748106b00a0c482b3e5cfd8b`
- core arch `2f32707715624d0e4414c99ca77477617e28dcc515e4cfe65ead21f2a6384a5d`
- app deb `7429e9e8a4a2daaaffadf4c9164b879ca70603bcd25868aad1deca6dc4a9434f`
- app rpm `3d82b83ab5789ecc06e72c921bc4d755bcef0958c1f77451e2a4e288bf2f45f1`
- app arch `7da7682b8bc19e8777b1334403971038fe8e12cb532b1dc0f63ed4e92300dce7`
- бинарь sora-core `df7c41d75f6df915ec7a9a297cf61c805827e34c3b5e371ef204d347bd7fc2da`

## 1. Собранные артефакты

| Артефакт | Размер | Примечание |
| --- | --- | --- |
| `sora-core` (бинарь, linux/amd64) | 19 746 976 B | `sora-core dev (contract 1.13, min supported 1, linux/amd64)` |
| `sora-core_1.0.12_amd64.deb` | 62 844 052 B | nfpm, конфиг `packaging/linux/nfpm.yaml` |
| `sora-core-1.0.12-1.x86_64.rpm` | 62 843 547 B | тот же конфиг |
| `sora-core-1.0.12-1-x86_64.pkg.tar.zst` | 34 548 299 B | тот же конфиг |
| `sora_1.0.12_amd64.deb` | 15 182 412 B | nfpm, `packaging/linux/nfpm-app.yaml` |
| `sora-1.0.12-1.x86_64.rpm` | 15 270 544 B | тот же конфиг |
| `sora-1.0.12-1-x86_64.pkg.tar.zst` | 15 043 647 B | тот же конфиг |
| Flutter bundle (linux release) | 36 MB | `app/build/linux/x64/release/bundle` — внутри пакетов приложения |

Движки в пакетах — по `packaging/engines/engines.lock` как есть на HEAD:
sing-box **1.14.3-lx.22**, Xray **26.10.17**, mihomo **1.19.32**, olcrtc —
сборка из пина-тега v0.0.1 (релизов у upstream нет), tpws/nfqws — из
`third_party/zapret` скриптом `packaging/zapret/build.sh`.

## 2. Дефекты, найденные по пути (исправлены)

### 2.1. `fetch.sh` падал в rootless/контейнерных окружениях — исправлено, `4ad29fa5`

`tar` при распаковке sing-box и исходников olcrtc пытался выставить владельца
из архива (uid 1001) и умирал: `Cannot change ownership ... Operation not
permitted` — в окружениях, где chown запрещён (user-namespace, rootless
контейнеры). Всё извлекаемое ставится дальше через `install -m`, владелец
промежуточной распаковки не используется. Фикс: `--no-same-owner` в оба вызова
tar + строка-обоснование в шапку скрипта. После фикса fetch проходит целиком:
все 4 артефакта amd64 сверены с локом, `olcrtc amd64: verified (built from
pinned source)`; `engines.digests` — 6/6 OK против собранных бинарей
(sing-box, xray, mihomo, tpws, nfqws, olcrtc).

### 2.2. Linux-раннер не компилировался — исправлено, `7cfbcafd`

Первая сборка `flutter build linux` в истории проекта (analyze C++ не
компилирует) упала: `app/linux/runner/my_application.cc:64: error: no matching
function for call to 'fl_method_call_respond'` — код передавал `FlValue*`,
активный API Flutter 3.47 требует `FlMethodResponse*`. Фикс — одна строка:
`fl_method_call_respond_success(method_call, result, &error)` (сигнатура
сверена с `fl_method_call.h` из SDK; семантика ответа getPendingLink и
Dart-контракт канала `sora.linux/deep_link` не меняются). После фикса полная
чистая сборка проходит (см. §3). Независимый ревьюер коммита — **APPROVE**
(проверил обе сигнатуры в заголовке SDK, отсутствие других вызовов старого
API в `app/linux` и нетронутый Dart-контракт `invokeMethod<String>
('getPendingLink')`).

### 2.3. Мелочь: `packaging/zapret/build.sh` не называет libcap в требованиях

Шапка build.sh перечисляет «C compiler, zlib и, для nfqws, libnetfilter_queue,
libnfnetlink и libmnl headers», но tpws включает `<sys/capability.h>`
(libcap-dev) — без него сборка умирает на `sec.h:11: fatal error`. В
`packaging/linux/nfpm.yaml` libcap упомянут верно. Комментарий исправлен
коммитом `0976e6a3`.

## 3. Сборка приложения: два «призрачных» отказа — не дефекты продукта

Для честности фиксирую оба, потому что со стороны они выглядят как поломки:

1. **Установка бандла в `/usr/local` вместо bundle-каталога.** После первой
   неудачной конфигурации (падение на отсутствовавшем тогда webkit2gtk-4.1
   **-dev**) CMakeCache сохранил `CMAKE_INSTALL_PREFIX=/usr/local`; последующие
   инкрементные сборки ставили бандл в `/usr/local` и рапортовали успех. С
   полностью чистого дерева (`rm -rf build .dart_tool`) префикс — правильный
   bundle-путь, сборка `rc=0`. CI собирает с чистого дерева — дефекта в
   репозитории нет; лечение на месте — `flutter clean`. Файлы из `/usr/local`
   на этой VM удалены точечно по install-манифесту.
2. **`file INSTALL cannot find build/native_assets/linux`.** Вызвано моей
   частичной очисткой: `rm -rf build` при живом `.dart_tool` — flutter_tools
   посчитал native-assets актуальными и не пересоздал каталог, а
   инсталл-правило шаблона (совпадает с текущим шаблоном Flutter 3.47 байт-в-
   байт в этой части) его требует. Полная очистка — сборка зелёная.

## 4. Проверка содержимого пакетов — PASS по всем трём форматам

Независимый ревьюер — **PASS по всем трём форматам** (полные извлечения;
кросс-проверка sha256-манифестов трёх деревьев — идентичны; скриптлеты и
зависимости сверены с эталонами побайтно). Пакеты после его проверки были
пересобраны при финальной сборке dist (комплектация движков), поэтому
финальные артефакты (те, что с SHA-256 в §1 и ставились в §5) дополнительно
перепроверены собственной инспекцией rpm/arch инструментом `pkgx` (в
окружении после рестарта VM не оказалось rpm/zstd-утилит; написан `pkgx` на
Go: заголовки RPM, скриптлеты, cpio-payload; zstd — klauspost/compress) —
все проверки ниже относятся к финальным артефактам и сошлись с эталоном
ревьюера (47 файлов payload).

- **Множества файлов**: deb ≡ arch побайтно по составу (ядро 62/62, приложение
  354/354, включая симлинк `/usr/bin/sora` во всех форматах); rpm отличается
  только отсутствием явных записей каталогов (14 у ядра, 25 у приложения) —
  ни одного файла не потеряно, лишних нет нигде.
- **Движки внутри пакетов**: `engines.digests` изнутри deb/rpm/arch сходится с
  бинарями внутри тех же пакетов (6/6 OK в каждом формате); версии изнутри
  deb: sing-box 1.14.3-lx.22, Xray 26.10.17.
- **Скриптлеты ядра**: deb — postinst/prerm/postrm побайтно равны
  `packaging/linux/scripts/*`; rpm — POSTIN/PREUN/POSTUN с тем же содержимым;
  arch — `.INSTALL` со всеми четырьмя функциями (post_install, post_upgrade,
  pre_remove, post_remove). У приложения скриптлетов нет — как спроектировано.
- **Метаданные и зависимости** — точно по overrides nfpm-конфигов в каждом
  формате (ядро: nftables/iproute(2)/libnetfilter_queue/zlib (+polkit у
  arch); приложение: `sora-core (= 1.0.12)` + gtk/webkit/gstreamer/pkexec/
  minisign в терминах каждого формата), версия везде 1.0.12.
- **Режимы**: бинари и helper'ы 0755, остальное 0644; размер установленного
  ядра по .PKGINFO — 257 702 901 B.

## 5. Чистая установка — ✅ ALL-OK (повторный прогон после рестарта VM)

Метод: чистая rootfs Ubuntu 24.04 (noble, minbase + systemd/dbus/apt),
установка .deb через apt, старт установленного ядра, RPC Handshake+GetStatus
по боевому сокету `/run/sora/core.sock`, затем app-пакет, регистрация
`sora://`, purge и проверка чистоты (файлы, `/var/lib/sora`, nft-таблицы
`sora`/`sora_nfqws`/`sora_ingress`). Скрипт прогона:
`~/workspace/bug-hunt/waveb/install-run.sh` (самодостаточен, один сеанс).

Что уже доказано вне контейнера (на хосте, теми же артефактами):
установленное из dist ядро стартует и отвечает пробе —
`handshake ok: negotiated api 1.13`, `GetStatus: DISCONNECTED`, полный список
capabilities; до этого ядро **отказалось** стартовать на каталоге данных 0770
(`core.secret.store_unavailable ... want 700`) — fail-closed как
спроектировано, старт со второго раза на 0700.

Блокеры именно контейнерного прогона — все со стороны этой песочницы, не
продукта:
- `systemd-nspawn --boot` невозможен: `Failed to mount sysfs ... Operation
  not permitted` (проверено в обоих режимах private-users) → установка едет в
  chroot с ручным стартом ядра по аргументам юнита; systemd-активация как
  таковая в этой среде не проверяется.
- ФС песочницы запрещает chown на чужие uid/gid всем (проверено: `chown
  1234:1234` → EPERM) → dpkg-скриптлеты в chroot идут под fakechroot
  (стандартный rootless-приём; содержимое файлов, разрешение зависимостей,
  сверка дайджестов и RPC при этом настоящие), ядро в chroot запускается от
  root, а не от пользователя `sora` — разделение пользователей здесь не
  перепроверяется.
- debootstrap непригоден здесь дважды (флачная сеть; postinst base-files
  умирает на том же chown) → rootfs собрана mmdebstrap с
  `TAR_OPTIONS=--no-same-owner`.
- **Рестарт VM посреди первого прогона**: установка была убита на этапе
  конфигурации зависимостей; следом платформенный os-intent-реплеер надолго
  занял apt-лок хоста. Повторный прогон — после пересборки rootfs.

Итог повторного прогона (`logs/install-run2.out`, 14 мин): **INSTALL-RUN:
ALL-OK, ноль FAIL** —
- core .deb встал в чистую rootfs; sysusers создал пользователя `sora`;
  все 17 контрольных путей на месте;
- версии движков изнутри чистой среды: sing-box **1.14.3-lx.22**, Xray
  **26.10.17**;
- установленное ядро стартовало (аргументы юнита, каталоги по контракту
  юнита: StateDirectoryMode 0700 эмулирован вручную), сокет появился;
- RPC-проба по боевому сокету: Handshake — negotiated api **1.13**,
  GetStatus — DISCONNECTED, полный набор capabilities;
- app .deb встал: бинарь, симлинк `/usr/bin/sora`, sora-update на месте;
- **deeplink**: `gio mime x-scheme-handler/sora` →
  `io.github.levvs_one.sora.desktop` — обработчик sora:// зарегистрирован;
- перед purge созданы 3 «осиротевшие» nft-таблицы (`sora`, `sora_nfqws`,
  `sora_ingress` — имитация убитого ядра): после `apt remove --purge`
  таблиц не осталось — postremove отработал;
- чистота после purge: бинарь ядра, `/usr/lib/sora`, симлинк приложения,
  юнит и `/var/lib/sora` — всё удалено, как обещают доки.

Не перепроверено здесь by design среды (честные границы): rpm/arch
устанавливаемость на родных дистрибутивах (содержимое верифицировано, §4;
rpm/arch-хоста в песочнице нет), systemd-активация юнита при буте
(nspawn запрещён), разделение User=sora (chown-бан), живой TUN/трафик.

## 6. Скриншоты — ✅ (коммит `0976e6a3`)

Собранный bundle запущен на Xvfb 1440×900 против живого ядра (то же ядро,
что в §5: приложение показывает его настоящий лог и состояние), навигация —
xdotool, кадры — ffmpeg x11grab. Окружение для запуска пришлось доукомплек-
товать из apt-кэша без системы (webkit/gstreamer/GL runtime извлечены в
локальный префикс + симлинк helper-процессов WebKit; на реальной установке
это всё — обычные зависимости пакета).

Отдельного экрана «серверы» в текущем UI нет: список серверов — левая панель
главного экрана (так спроектировано). Чтобы кадр был настоящим, а не
пустым, в приложение импортирована локальная фикстурная подписка (см.
находку 6.1): 3 сервера (VLESS/REALITY «DE Frankfurt», Trojan «NL
Amsterdam», Hysteria2 «UK London», проба честно показывает «no answer» —
фикстурные endpoint'ы не существуют).

Файлы в `docs/images/`:
- `home-1440x900-light.png`, `home-1440x900-dark.png` — главный экран с
  панелью серверов (заменили кадры прежнего UI; имена и ссылки README/
  metainfo не менялись);
- `connections-1440x900-{light,dark}.png` — экран Connections (пустое
  состояние «No connections», поиск, As list/By process);
- `extensions-1440x900-{light,dark}.png` — Extensions, вкладка Catalog
  (честный empty state «The team catalog is coming soon»);
- `social-preview-1200x630.png` — 1200×630, кроп+скейл светлого главного
  кадра (без дорисовок).

### 6.1. Поведение, проверенное попутно (не скриншотные артефакты)

- **Подписки только по https**: приложение отклоняет http:// URL до запроса
  («The link must start with https://» — уведомлением, без сырых ошибок).
- **SSRF-политика fetcher'а ядра работает как спроектировано**: подписка на
  `https://localhost:8443/…` отклонена ядром —
  `core.subscription.redirect_rejected` в логе: имя хоста, разрешившееся в
  loopback, режется на этапе dial (checkDial/publicAddr в
  core/subscription). Та же подписка по **IP-литералу** `https://127.0.0.1:8443/…`
  принята (isPrivateHost осознанно разрешает явные приватные IP) —
  импорт завершился «Subscription updated: 3 servers».
- **Кандидат в дефекты (для отдела стыков, не чинено здесь)**: после
  успешного импорта подписки в долгоживущей сессии приложения список
  серверов остался пустым (секция без строк, refresh не помог); помог только
  перезапуск приложения — полный ресинк состояния подтянул outbounds.
  Контекст репро: ядро один раз убивалось/перезапускалось под живым
  приложением до импорта; в чистом потоке (перезапуск приложения после
  импорта не требовался в обратную сторону) не воспроизводилось. Похоже на
  устаревший SubscriptionState в UI после события обновления.
- **SIGTERM-дренаж ядра**: при graceful SIGTERM ядро закрывает listener и
  снимает сокет-путь, но процесс в этом прогоне жил ещё ≥4 минут (приложение
  при этом честно показало «The Sora service is not responding»).
  Зафиксировано как наблюдение: возможно, дренаж по дизайну ждёт закрытия
  клиентского event-stream; на dev-машине стоит проверить, что выключение
  сервиса не висит минутами при подключённом UI.

## 7. Окружение и воспроизводимость

- Тулчейн: Flutter 3.47.7 (~/workspace/flutter), Go 1.27.2, nfpm из
  ~/workspace/gopath/bin; для сборки приложения на чистой машине нужны
  `clang ninja-build libgtk-3-dev libwebkit2gtk-4.1-dev` и для zapret —
  `zlib1g-dev libcap-dev libnetfilter-queue-dev libnfnetlink-dev libmnl-dev`
  (всё apt; webkit-dev нужен плагину webview — без него CMake-конфигурация
  падает на `pkg_check_modules`).
- Сеть песочницы флачна и ходит через прокси; fetch движков и apt здесь
  медленные, но проходимые (кэш модулей Go и .deb спасают повторы).
- Два рестарта VM за время волны; все артефакты на диске пережили оба.

## 8. Коммиты волны

- `4ad29fa5` [waveb] packaging: tar --no-same-owner в engines/fetch.sh (§2.1)
- `7cfbcafd` [waveb] linux: fl_method_call_respond_success в раннере (§2.2)
- `0976e6a3` [waveb] docs: скриншоты текущего UI в docs/images + комментарий
  libcap в zapret/build.sh (§2.3, §6)
- _этот отчёт — в архив отчётов репозитория по решению родителя._
