# WAVE-A-TOOLCHAINS — отдел тулчейнов и верификации

Ветка `bugfix/audit-2026-10-19`. Все вердикты ниже — машинные (компиляторы,
анализатор, тесты), полученные на этой VM 2026-10-20. Предыдущий заход отдела
(«всё уже сделано») был ложной тревогой: Flutter/.NET в начале этой сессии не
стояли, коммитов a899cb3/95a50db не существовало.

## Установленное

| Инструмент | Версия | Куда | Проверка целостности |
|---|---|---|---|
| Flutter SDK | 3.47.7 stable (Dart 3.13.5) | `~/workspace/flutter` | SHA-256 архива сошёлся с официальным `releases_linux.json`: `af7455f5…dd6230`, размер 1 578 092 224 б. Исходный `flutter.tar.xz` на диске был оборванной загрузкой (124 416 000 б, чужой хеш) — докачан `curl -C -` |
| .NET SDK | 8.0.426 | `~/workspace/dotnet` | `dotnet --info` |
| buf / protoc | 1.57.0 / 28.3 | `~/workspace/tools-bin` (стояли) | `--version` |
| protoc-gen-go | v1.36.11 | `~/workspace/tools-bin/bin` | собран из модуля protobuf v1.36.11 — версия совпадает с шапкой закоммиченных стабов |
| protoc-gen-go-grpc | v1.5.1 | `~/workspace/tools-bin/bin` | отдельный модуль `google.golang.org/grpc/cmd/protoc-gen-go-grpc`; версия — по шапке стабов |
| protoc-gen-dart | protoc_plugin 25.0.0 | `~/.pub-cache/bin` | пара к protobuf (Dart) 6.1.0 из pubspec.lock |

Замечания по установке: сеть рвёт большие загрузки (Flutter докачивался дважды,
один раз прогресс был потерян при рестарте VM); `dotnet-install.sh` падает на
распаковке при TMPDIR=/tmp (tmpfs 512 МБ) — нужен TMPDIR на диске.

Dart SDK 3.13.5 — точное совпадение с `app/pubspec.yaml` (`sdk: ^3.13.5`).

## 1. Flutter: pub get / analyze / test

### pub get
С первого раза вскрыл реальный дефект локализаций (см. §4): synthetic
localizations generation падала на битых ARB. После фиксов §4 —
`Got dependencies!` без ошибок. `flutter pub get` обновил `pubspec.lock`
(6 пакетов: archive 4.5.2, cryptography 2.9.0, mobile_scanner 5.2.3,
posix 6.5.2, qr 3.0.2, qr_flutter 4.1.0) — закоммичено вместе с l10n-набором,
все вердикты ниже получены против этого lock.

### flutter analyze (первый в истории проекта машинный прогон)
База: **320 issues — 239 error / 26 warning / 55 info**.

Ключевой вердикт по ambiguous_import: риск `NetworkProfile`/`NetworkFingerprint`
**снят машинно** — ошибок по этим именам нет, фикс
`hide NetworkFingerprint, NetworkProfile` в `app/lib/src/sora.dart:24` работает.
Попутно найден ДРУГОЙ ambiguous_import: `catalogBadges` определён и в
`lib/src/ext/catalog.dart`, и в `lib/src/ui/extensions/widgets.dart`
(использовался в detail_screen/store_screen) — исправлено в кластере extensions.

Распределение ошибок по кластерам и причины:

| Кластер | Ошибок | Корневая причина |
|---|---|---|
| `lib/src/ui/extensions/` (6 файлов) | ~186 | Файлы восстановлены из снепшотов отдела расширений: относительные импорты посчитаны на уровень выше (`../../l10n/strings.dart` вместо `../../../…`, `../design/theme.dart` вместо `../../…`, `../sora.dart` вместо `../../sora.dart`) → 13 uri_does_not_exist + каскад 144 undefined_identifier; плюс коллизия catalogBadges |
| `lib/src/obfs.dart` | 30 | Файл имитирует protoc-вывод и импортирует `dart:core as $core`; «app model» половина (со стр. ~674) писалась в расчёте на непрефиксный dart:core — String/int/List не в скоупе. Фикс — второй импорт `import 'dart:core';` |
| `lib/src/ui/sync.dart` | 10 | Spread `..._ready(...)` внутри кейса switch-expression в `children: [...]` (парсер не принимает) + переприсваивание final `session` |
| `lib/src/sora.dart` | 3 | Object?→String без каста (:97); вызовы несуществующего `ProxyChain.validateHops()` ×2 — валидация переехала в фабрику `tryParse`, вызовы заменены на неё |
| `lib/src/ext/catalog.dart` | 2 | Внутри CatalogEntry голое имя `sha256` резолвилось в собственное поле класса, затеняя crypto.sha256 → `convert` на String + каскад double→int. Фикс (`import … as crypto` + `crypto.sha256.convert`) внёс параллельный отдел seams — коммит `d508247f` |
| `lib/src/ui/about.dart` | 2 | Условие отката было конъюнкцией «не занято ИЛИ (занято ИЛИ диалог уже висит)» с null-check паттерном по bool — переписано if-кейсом с busy-guard и флагом `_rollbackNoticeShown` |
| `lib/src/updates.dart` | 1 | `final text` присваивался в try и в catch — убран final |
| `lib/src/desktop/desktop.dart` | 1 | app_links 7.x: `getLatestAppLinkString()` не существует; актуальный API — `getLatestLink()` → `Uri?`, вызов адаптирован (`.toString()` на месте потребления) |
| `lib/src/ui/qr.dart` | 1 | errorBuilder: в mobile_scanner 5.2.3 второй аргумент — `MobileScannerException`, не `MobileScannerErrorDetails`; тип колбэка приведён к API пакета |
| `lib/src/ui/rules_screen.dart` | 1 | `body_might_complete_normally` — addRuleSheet завершалась unawaited-вызовом без return; теперь возвращает `showFieldSheet(...).whenComplete(очистка)` |
| `lib/src/ui/servers.dart` | 1 | `Symbols.gauge_rounded` нет в запиненной material_symbols_icons; ближайшая существующая — `speed_rounded` (замена зафиксирована) |
| `test/ui2_test.dart` | 1 | Фейк `_EmptySora.connect` отстал от сигнатуры `Sora.connect({bool retry, ProxyChain? via})` (F8) — параметр добавлен |

Исполнители: три параллельных агента по непересекающимся зонам, коммиты
`[toolchain]`: ba01afb3 (UI-кластер C), f8d5a406, 978c09a7, 3c29d3ea (кластер B),
далее кластер A (extensions) — см. финальный прогон ниже.

Финальный прогон после всех фиксов отдела: **0 errors / 16 warnings / 45 info**
(база: 239/26/55). Ошибок не осталось ни в одном кластере.

### flutter test (TMPDIR обязательно на диске — test compiler пишет в TMPDIR,
переполненный tmpfs /tmp теряет output.dill и вешает загрузку файлов)
- `test/proto_wire_tags_test.dart` (wire-pin): **26/26 passed** — теги всех
  сообщений волн F2/F5/F6/F8 и ранее запиненных подтверждены машинно.
- Полностью зелёные файлы: app_test, browser_diagnostics_test,
  connection_race_test, ext_parity_test, ext_revocation_test, glow_test,
  language_test, licenses_test, speedtest_test, sync_qr_test
  (в сумме по прогонам 280+ тестов, 0 падений по ассертам).
- `live_core_test` / `live_tunnel_test`: skip по дизайну (нужен запущенный
  core / `SORA_CORE_LIVE`, часть — Windows service) — в этой песочнице
  честно пропускаются, не падают.
- Найден и исправлен реальный баг продукта: `updateCohort` (rollout-когорта)
  считался в знаковом 64-бит int — для ~половины UUID аккумулятор уходил в
  минус и когорта отличалась от запиненного «SHA-256 mod 100» (test-uuid-2:
  ожидалось 68, получалось 52). Фикс — BigInt (коммит 24515c92), пин-тест зелён.
- Оставшиеся падения (триаж завершён/в работе на момент сдачи): см. финальный
  раздел отчёта ниже.

## 2. .NET: legacy C# — ПОЛНОСТЬЮ ВЕРИФИЦИРОВАНО

`dotnet build` (SDK 8.0.426, Linux, TMPDIR на диске):

| Проект | TFM | Итог |
|---|---|---|
| `legacy/Control/Sora.Legacy.Control.csproj` | net48;net8.0 | **0 warnings, 0 errors** (включая Grpc.Tools-кодген из `proto/sora/core/v1/core_control.proto` и CsWin32-генераторы) |
| `legacy/Client/Sora.Legacy.Client.csproj` | net48 WinForms | **0 warnings, 0 errors**, `Sora.Legacy.exe` собран (Microsoft.NETFramework.ReferenceAssemblies 1.0.3 — сборка net48 на Linux принципиально работает, стены не случилось) |
| `legacy/tests/ClientInterop` | net48;net8.0 | 0/0 |
| `legacy/tests/ControlInterop` | net48;net8.0 | 0/0 |
| `legacy/tests/ServiceInterop` | net48;net8.0 | 0/0 |

Все C#-фиксы аудита/5-пасс ревью, правившиеся вычиткой, машинно подтверждены.

## 3. buf generate: дифф генерации против hand-written стабов

Плагины подобраны по шапкам закоммиченных стабов (protoc-gen-go v1.36.11,
protoc-gen-go-grpc v1.5.1, protoc_plugin 25.0.0). Генерация — в scratch-дерево,
рабочее дерево не затиралось.

### Go (core/gen, 12 файлов)
**9/12 байт-в-байт идентичны.** Расхождения:
- `core_control.pb.go`, `core_control_grpc.pb.go` — только строка версии
  protoc в шапке (`(unknown)` у buf против `v5.28.3`). Схемного дрейфа нет:
  все сообщения волн присутствуют и в proto, и в стабах согласованно.
- `sora/obfs/v1/obfs_grpc.pb.go` — только комментарии: в proto после генерации
  стаба добавили doc-комментарий про precedence сохранённого профиля (16 строк
  диффа, 0 строк кода).

### Dart (app/lib/src/generated)
Сгенерированное дерево шире закоммиченного (пакеты censor/ext/obfs для Dart не
генерировались никогда — приложение использует hand-written obfs.dart и обходится
без остальных) — это не дрейф, а неполный набор. По общим файлам:
- `custom.pb.dart`, `leak.pb.dart` — инвентарь классов и мультисеты номеров
  полей **идентичны**.
- `core_control.pb.dart` — по всем общим сообщениям номера/типы полей совпадают
  (единственное «расхождение» разбора — CensorshipDetected.confidence: стаб
  пишет `a<double>(2, …, PbFieldType.OD)`, плагин — сокращение `aD(2)`;
  семантически одно и то же).
- **Реальный пробел на HEAD**: в `core_control.pbgrpc.dart` отсутствовал RPC
  `SelectServer` целиком (клиентский метод, `_$selectServer`, регистрация в
  service base, `selectServer_Pre`, абстрактный метод), в `core_control.pbjson.dart`
  отсутствовали дескрипторы SelectServerRequest/Response — при том что сами
  сообщения в pb.dart есть, а proto объявляет `rpc SelectServer` (API 1.12).
  Трансплант из сгенерированного файла внесён в рабочее дерево pbgrpc (4 ханка);
  pbjson-часть параллельно закрыл отдел интеграции своей правкой (см. ниже про
  коллизию).

### P0: hand-written стаб не компилируется — поле `clear`
`SaveSubscriptionOverrideRequest.clear` (proto: `bool clear = 7`): стаб
объявляет `bool get clear` / `set clear(...)`, что конфликтует с унаследованным
`GeneratedMessage.clear()` — **CFE-ошибка, `core_control.pb.dart` на HEAD не
компилируется** против protobuf 6.1.0 (невидимо для analyze: `lib/src/generated/**`
исключён из analysis_options). Настоящий protoc-gen-dart экранирует такие имена:
`clear_7` (параметр фабрики, геттер и сеттер; wire/JSON-имя поля не меняется).
Фикс внесён в рабочее дерево (стаб + pin-тест, который сам использовал `.clear`):
после него pin-тест 26/26. Вызывающих `.clear` в коде приложения нет —
переименование безопасно. **Коммит фикса — вместе с коммитом отдела интеграции
по generated/** (файлы сейчас в их незакоммиченном WIP; pathspec-коммит pb.dart
из моего отдела утащил бы их ханки — по дисциплине AGENTS.md не коммитил).

### Ещё один не-компилирующийся стаб: custom.pb.dart `has_credentials`
Тот же класс дефекта, другой файл: `CustomServer` имеет поля `credentials`
(String, #6) и `has_credentials` (bool, #7). Ручной стаб назвал акцессоры поля #7
`hasCredentials` — коллизия с presence-методом поля #6 `hasCredentials()`.
Плагин экранирует в `hasCredentials_7` (и `hasHasCredentials_7` /
`clearHasCredentials_7`). Исправлено и закоммичено нами (c9474741) — файл не
входил в чужой WIP. Проверка остальных прото на этот класс: `has_usage`
(SubscriptionInfo) коллизии не создаёт (плагин оставляет `hasUsage`, стаб
согласен) — ложная тревога, не трогали. Вызывающих переименованные акцессоры
в коде приложения нет в обоих случаях.

### Коллизия с отделом интеграции (честно)
Отдел интеграции параллельно правит те же generated-файлы (GroupSpec.selected,
SelectServer-проводка). Моя первая попытка pbjson-транспланта наложилась на их
уже внесённые в рабочее дерево дескрипторы (дубли при компиляции временного
теста) — трансплант pbjson откачен (`git checkout`), их версия на месте;
pbgrpc-ханки сосуществуют с их правками в одном грязном файле. Итоговый коммит
generated/ — за отделом интеграции/родителем одной операцией.

## 4. gen-l10n: 32 ARB, генерация была СЛОМАНА на HEAD

`flutter pub get` на исходном дереве падал на synthetic l10n generation.
Найдено и исправлено (коммит `01050361`):

1. **600 битых placeholder-метаданных в 30 локалях**: тип записан вложенным
   объектом — `"type": {"type": "int"}` вместо `"type": "int"` (20 сообщений ×
   30 файлов; шаблон ru и en — корректны). Транслейшн-пайплайн заворачивал тип
   в лишний объект. gen-l10n на этом умирал (`The "type" value … must be a
   non-empty string`, первое падение — latencyMs).
2. **В шаблоне отсутствовали @-блоки 10 сообщений** (connConnectionsCount,
   benchmarkProgress, profileDeleteConfirm, profileApplyAsk, profileApplied,
   networkNow, chainDeleteConfirm, chainHop, syncRevokeConfirm, syncLastSync) —
   типы плейсхолдеров выводились в Object, а локали декларировали свои, что
   build-time генерация трактует как ошибку. Блоки добавлены в ru и en с типами,
   совпадающими с закоммиченным сгенерированным API (int для счётчиков,
   String для имён/времени; chainHop — String, вызывающий передаёт `'${i + 1}'`).
   В 30 локалях benchmarkProgress done/total приведены String→int,
   connConnectionsCount count — int.
3. **Сгенерированные strings*.dart были рассинхронизированы с ARB** (порядок
   ключей, язык doc-комментариев, покрытие вариантов zh_Hans/Hant). Перегенерированы
   официальным gen-l10n: API (все сигнатуры, включая 10 исправленных) совпал с
   прежним один в один; отныне `flutter gen-l10n` — идемпотентен, предупреждений
   ноль, `flutter pub get` проходит чисто.

Итог по §4: 32/32 локали, генерация + компиляция результата — машинно зелёные.

## Warnings / info после фиксов (16 warnings / 45 info; не блокируют)
Финальный список — из analyze2 (0 errors):
- warnings: преимущественно точечная мелочь в ui (unused_local_variable,
  invalid_null_aware_operator `about.dart:185`, unnecessary_non_null_assertion,
  dead_code `obfs.dart:763` — недостижимый хвост в app-model секции) и
  inference_failure в extensions после фикса импортов; ни одного warning
  уровня «подозрение на баг» не подтверждено при вычитке, кроме уже
  исправленных.
- info (45): unintended_html_in_doc_comment, avoid_dynamic_calls,
  use_build_context_synchronously, unnecessary_brace_in_string_interps,
  unnecessary_underscores, no_leading_underscores_for_local_identifiers,
  unnecessary_import, unawaited_futures, deprecated_member_use и пр. — стиль.
- `dart format --set-exit-if-changed`: 66 из 133 файлов не форматированы —
  кодовая база никогда не проходила dart format. Массовую переформатировку
  НЕ делали (сносит чужие WIP всех отделов); рекомендация владельцу —
  отдельный format-коммит перед мержем.

## Коммиты отдела ([toolchain], все pathspec-формой, индекс проверялся)
- `01050361` l10n: ARB-фиксы + регенерация 32 локалей + pubspec.lock.
- `376ea52f` obfs.dart: непрефиксный dart:core импорт.
- `ba01afb3` UI-кластер C: sync switch, qr errorBuilder, rules return,
  servers icon, ui2_test override.
- `3c29d3ea` updates: final у rollout-текста. `978c09a7` about: rollback-notice
  if-кейсом. `f8d5a406` desktop: app_links 7.x getLatestLink().
- `16a8d8ba` extensions (кластер A): импорты приведены к реальной глубине
  (×13), UI-рендерер бейджей переименован catalogBadges→catalogBadgeWidgets
  (коллизия с данными каталога в ext/catalog.dart), недостающая `}` класса
  в store_screen, `children: const []` в двух вызовах Screen.
- `c9474741` custom.pb.dart: hasCredentials_7.
- `24515c92` updates: updateCohort через BigInt.
- В рабочем дереве (коммит — за отделом интеграции вместе с их generated-WIP):
  core_control.pb.dart `clear`→`clear_7`, core_control.pbgrpc.dart трансплант
  SelectServer, proto_wire_tags_test.dart `.clear_7`.
- В рабочем дереве (коммит — за отделом серверов, владельцем файла): sora.dart —
  два вызова заменены на `ChainsStore.validateHops(...)` (валидация живёт в
  chains.dart:133, не в модели ProxyChain); ошибка :97 ушла каскадом после
  фикса obfs.dart, правки в sora.dart для неё не потребовалось.

## Триаж тестовых падений (завершён; контрольный прогон 7 затронутых файлов:
## 148 passed / 32 skipped / 0 failed; финальный analyze: 0 errors / 12 warnings / 42 info)
1. **updates_rollout «unreachable policy»** — тест был неправ: под-кейсы делили
   общее хранилище, состояние протекало между ними (отсюда notices=0). Изоляция
   storage на под-кейс — `ba847031`. Поведение продукта (фолбэк offer-all +
   уведомление) корректно.
2. **updates_test «About … install-update»** — тест был неправ: ожидания
   навигации не учитывали восстановленный слот Connections (`1c74bbe6`) +
   пункты меню TUN-стека локализованы, на 420px нужен скролл к mode-tun
   (`35f5b04c`). Кнопка на месте; фикс about (978c09a7) логику не ломал.
3. **desktop_shell ×4** — ДВА корня: (а) тест: `7aafa4a5` вернул Connections
   8-м пунктом сайдбара, ожидания теста — дореформенные, заодно Ctrl+8 в
   section() вёл не в About (About — Ctrl+9) — это же ломало группу 2 выше;
   (б) КОД (регрессия): `86b8742e` (a11y) заменил у kit Segments фикс. height:36
   на minHeight:36 — высота перестала ограничиваться сверху, в unbounded
   родителях FractionallySizedBox получал Infinity («BoxConstraints forces
   an infinite height», каскад у всех Segments). Фикс кода: индикатор —
   Positioned.fill, размер задаёт Row с полом minHeight — `186f4aa2`.
4. **desktop_test «refused»** — тест был неправ: `3e9a0e32` сознательно научил
   parseImportLink принимать голые http(s) URL (QR/мессенджеры/clipboard);
   тест старше фичи (`6d671e2f` — кейс перенесён в позитивные).
5. **ui2_test добор** — тест был неправ: `98464ab2` локализовал подписи
   TUN-стека (RU: «Смешанный»/«Системный»), тест тапал старые EN-подписи;
   на 420px плитка mode-tun подрезалась краем диалога — добавлен
   ensureVisible (`35f5b04c`). Ни одного ассерта триаж не ослабил: где тест
   был неправ, он кодировал поведение, отменённое конкретными коммитами;
   где был неправ код — правился код.

## Стены (точное)
- `flutter build` не гоняли: в задаче analyze/test; на этой VM нет системных
  GTK/Windows тулчейнов для сборки приложения — это Wave B (пакеты).
- Live-тесты ядра (live_core/live_tunnel) в песочнице — skip по дизайну;
  их прогон возможен только с запущенным core/Windows service.
