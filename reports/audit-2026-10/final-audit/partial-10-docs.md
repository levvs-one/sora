# Подкоманда №10 — документация vs код (финальный аудит)

Ветка `bugfix/audit-2026-10-19`, репо `sora` + `sora-legacy`. Проверены ВСЕ
проверяемые утверждения в `README.md`, `README.en.md`, `docs/*.md` (faq,
security, install, usage, architecture, extensions, extensions-*,
sync-threat-model, android-vpnservice, providers, development, stealth,
update-rollout, troubleshooting), `SECURITY.md`, `CONTRIBUTING.md` и
`sora-legacy/docs/` (включая `android-security-requirements.md`).
Код не правился: все фиксы — только текст доков. Враньё вида «дока обещает,
код не делает» зафиксировано как находка для зоны 4 (см. §3).

Базовый контекст учтён: POWER-RUN №10 (D1–D16) и ANALYSIS-20/05-docs (P0–P3).
Большинство их находок к этому моменту уже исправлено в доках или коде —
каждая перепроверена по текущему дереву, а не по старым отчётам (см. §4).

---

## 1. Ложь и неточности — исправлены в доках

| # | Утверждение → источник | Код (факт) | Вердикт | Действие |
|---|---|---|---|---|
| L1 | «Диагностика в один клик: HAR, PCAPNG, журналы Windows» — `README.md:50`, `README.en.md:50` | Ядро **отказывается** производить PCAPNG/EVTX принципиально: `core/control/server.go:1376-1390` (SORA-H3: «raw capture formats are refused outright»); UI экспортирует только HAR встроенного браузера и маскированный ZIP-архив (`app/lib/src/ui/logs.dart:260-266`: «the core refuses PCAPNG/EVTX outright… the menu no longer offers what the core cannot produce») | **ЛОЖЬ (High)** | Исправлено: «HAR и маскированный архив диагностики ядра» / «HAR and a redacted core diagnostics archive» |
| L2 | «Телеметрии нет: Sora ничего не отправляет разработчикам и третьим сторонам» — `README.md`, `README.en.md` (раздел «Безопасность») | Приложение само ходит на `api.github.com` при запуске и каждые 12 ч (`app/lib/src/updates.dart:392,497,548`: `User-Agent: Sora/<версия>`, скачивает файлы релизов). GitHub — третья сторона, видит IP и версию. `docs/security.md` это уже документировал честно — README ему противоречил (05-docs P0-2) | **ЛОЖЬ в blanket-форме (High, privacy-позиционирование)** | Исправлено: «не отправляет аналитику и статистику разработчикам. Единственное сетевое обращение самого приложения — проверка обновлений у GitHub…» |
| L3 | «Отдельные пункты диагностики создают … PCAPNG из десятисекундного захвата собственного активного TUN и EVTX из событий SoraCore за последние сутки… На Windows требуется Packet Monitor. Размер PCAPNG и EVTX ограничен 8 МБ» — `docs/usage.md` (раздел «Язык и журнал») | Тот же факт, что L1: форматы не производятся вообще, пунктов меню нет | **ЛОЖЬ (High)** | Абзац переписан: HAR + маскированный ZIP; прямо сказано, что сырые захваты не создаются намеренно и почему |
| L4 | «`sora-legacy` — отдельная ветка клиента для старых систем… Это предыдущее поколение» — `docs/faq.md:35` | sora-legacy — отдельный **репозиторий и проект** (его собственный README: «Отдельный репозиторий»); «ветка» и «предыдущее поколение» противоречат утверждённому позиционированию «отдельный проект для старых ОС» и вводят в заблуждение (это не ветка sora) | **НЕТОЧНОСТЬ позиционирования (Medium)** | Исправлено: «отдельный репозиторий и проект: клиент для старых систем… развивается отдельно» |
| L5 | «The app-side JS runner executes `entry` inside this envelope» — `docs/extensions.md` §7 | JS-раннера нет нигде: ни JS-движка в `app/pubspec.yaml`, ни одного вызова `ext.NewScheduler`/`Scheduler.Register` вне `core/ext/worker.go`; `_BackgroundTaskSection` (`detail_screen.dart:560`) только читает/пишет конфиг `$id.background.json`. Go-scheduler и `net.fetch` реализованы, но хоста у них нет | **ЛОЖЬ — дока обещает, код не делает → cross-ref зона 4** | В док вписан честный implementation status (scheduler есть в `core/ext`, воркеры на практике не выполняются, приложение только хранит конфиг). Код не тронут |
| L6 | «ядро … обслуживает приложение на Windows, Linux, Android и Android TV» — `sora-legacy/docs/architecture/core.md:4` | Android-приложения в sora-legacy нет: `app/android/` содержит только `tunnel/README.md` (спеку); сам `engines.md:181` честно говорит «службы туннеля пока нет» — core.md ему противоречил | **ЛОЖЬ (High, платформы)** | Исправлено: главная реализация — Windows/Linux; Android/Android TV — целевые платформы дизайна без клиента |
| L7 | Индекс `docs/README.md` не содержал `update-rollout.md` | Файл существует, остальные разделы полны | **НЕТОЧНОСТЬ (Low)** | Добавлена строка в индекс |
| L8 | В `docs/usage.md` не было раздела про синхронизацию, хотя экран существует и wired | `settings_screen.dart:292` → `SyncScreen`; демон, QR, HTTP API реальны (см. §2) — пользователь попадал на экран без единого слова в руководстве (05-docs P1) | **НЕПОЛНОТА (Medium)** | Добавлен раздел «Синхронизация устройств» с точным описанием UX и честной веткой «демон отсутствует → недоступно» |
| L9 | В `docs/faq.md` не было ответа «есть ли Android?» при privacy/платформенном позиционировании | Клиента нет, есть спека `docs/android-vpnservice.md` с честной шапкой | **НЕПОЛНОТА (Low)** | Добавлен FAQ: «Пока нет… спека… требования зафиксированы заранее» |

## 2. Проверено — правда (выборочно, самые громкие заявления)

| Утверждение | Источник | Сверка с кодом | Вердикт |
|---|---|---|---|
| Подписи релизов: minisign `SHA256SUMS`, «без валидной подписи установка и обновление не продолжаются»; ключ — заглушка до церемонии владельца, fail-closed | `README.md`, `docs/security.md#проверка-сборок`, `docs/install.md` | `packaging/install/install.sh:30,76-83` и `install.ps1:81,86`: `REPLACE-ME-AFTER-KEY-CEREMONY` → `die/throw`; привилегированный `packaging/linux/sora-update`: та же заглушка, проверка подписи от root до установки; Windows in-app update отключён fail-closed (`updates.dart:614-626` `signatureRequired`); Linux: приложение качает и `SHA256SUMS.minisig` для хелпера (`updates.dart:640-649`). Ни один док не утверждает, что релизы **уже** подписаны действующим ключом; в README добавлена явная строка про key ceremony + fail-closed | **ПРАВДА** (+усилено в README) |
| Платформы: Windows 10 1809+/Linux x64; Android-клиента нет | `README.md`, `docs/install.md` | `app/android` отсутствует; `docs/android-vpnservice.md` — честная спека («клиента в коде пока нет»); legacy: только C#/.NET-клиент | **ПРАВДА** |
| Расширения и магазин: каталог, sideload, панели, разрешения | `README.md`, `docs/usage.md`, `docs/extensions.md` §4/§6 | Стор wired; каталог проверяет пакет по закреплённому ключу автора (`app/lib/src/ext/store.dart:319,327` — power-run D6 закрыт кодом); панели изолированы CSP `connect-src 'none'` на каждом ответе loopback-сервера (`panel_screen.dart:37-41,97` — D5 закрыт кодом); team-ключ — placeholder, каталог fail-closed (честно в §6) | **ПРАВДА** |
| Sync: E2E без облака, QR-спаривание, Noise_XX | `docs/security.md`, `docs/sync-threat-model.md` (status 2026-10-20), `docs/usage.md` (новый раздел) | Приложение реально спавнит демон (`sync_daemon.dart`), показывает QR демона, ходит в его HTTP API (`sync_api.dart`); QR-формат Dart зеркалит `service/sync/pairing` (контракт F9-SYNC); `api_token` не логируется. Старый театр F9 устранён — доки и код совпадают | **ПРАВДА** |
| Цепочки прокси 2–3 хопа | `docs/usage.md`, `README.md` | `core/control/chain.go` ProbeChain + `ChainsScreen` в настройках; гейт API ≥1.10 | **ПРАВДА** |
| zapret одновременно с VPN (Linux) | `docs/usage.md:68`, README (Linux zapret-режим) | `modes.dart:266-271` тумблер; `sora.dart:652,1304,2172-2175`: `Platform.isLinux && serverlessAvailable` гейт, план несёт `zapretWithVpn` | **ПРАВДА** |
| Kill switch ставится до старта ядра | `docs/security.md`, `docs/architecture.md:28` | `core/session/runner.go:257` `guard.Apply` → `:262` `eng.Apply`; proto-комментарий «Arms the kill switch before the engine starts» | **ПРАВДА** |
| 32 языка интерфейса | README, usage | 32 файла `app/lib/l10n/app_*.arb`, `supportedLocales` сходится | **ПРАВДА** (legacy README «31 язык» — тоже правда: 31 `.arb` в legacy) |
| Три движка sing-box/Xray/mihomo; порядок выбора sing-box→Xray→mihomo | README, `architecture.md:26`, faq | `core/engine/engine.go:19-21`, `catalog.go:183` `DefaultPreference` | **ПРАВДА** |
| Протоколы REALITY, XHTTP, AmneziaWG, Hysteria2; DPI-фрагментация | README «Возможности» | `engine/reality.go`, XHTTP в parser/validate, `FeatureAmneziaWG` (`catalog.go:41`), hy2 в parser, `core/obfs/frag.go` | **ПРАВДА** |
| Сплит-туннелинг по сайтам, IP и приложениям | README | `core/control/plan.go:789-806` правила `process:`, `program_picker.dart` в rules screen | **ПРАВДА** |
| Версия API приложения = ядра | (числа в доках не заявляются) | Go `main.go:51` = 1.11; Dart `core/link.dart:20` = (1,11) — рассинхрона нет | **ПРАВДА** |
| Журнал: домены по умолчанию пишутся открытым текстом, маскирование — переключателем | `security.md`, `faq.md`, `troubleshooting.md` | `core/logs/logs.go` `RecordDestinations: true` по умолчанию; все три дока теперь согласованы (05-docs P0-1 закрыт) | **ПРАВДА** |
| Хранилище AES-256-GCM, DPAPI на Windows, owner-only файл на Linux | `docs/security.md`, faq | `core/secret/store.go`, `format.go`, `file_other.go:checkOwnerOnly` | **ПРАВДА** |
| Подписки: лимиты https-only, 5 редиректов, 16 МБ, 30 с; трафик/срок/объявления провайдера; автовыбор по задержке | `docs/providers.md:31`, `docs/security.md`, README | `core/subscription/subscription.go:24-27`, `info.go` (Announce/Expire/usage), `core/select/` | **ПРАВДА** |
| Экспорт журнала: LOG/TXT/JSON/JSONL/CSV/XML/ZIP/GZIP, лимит 32 МБ | `docs/usage.md` | `logs.dart:341-348` все 8 форматов; `core/logs/export.go:32` `MaxExportBytes = 32<<20` | **ПРАВДА** |
| Гайд — 5 шагов; тосты — 5 с; история уведомлений — 100; супервизор — до 5 рестартов за 10 мин | usage, architecture | `tour.dart` 5 описаний; `toasts` `Duration(seconds: 5)`; `settings.dart:367`/`sora.dart:210` `take(100)`; `supervisor.go:180,183` budget 5 / window 10 мин | **ПРАВДА** |
| DoH по умолчанию 1.1.1.1 / 8.8.8.8 | `docs/usage.md:82-83`, security | `app/lib/src/ui/dns.dart:20-21` | **ПРАВДА** |
| Xray TUN на Windows с 1.0.10 через мост mihomo 1.19.32+ | `docs/usage.md:70` | Устаревшая формулировка power-run/05-docs P0-3 уже исправлена; CHANGELOG 1.0.10 и встроенный гайд согласны | **ПРАВДА** |
| APP_VERSION прокидывается в релизные сборки (гейт `min_app_version`) | `docs/extensions.md` §2, `development.md:134` | `.github/workflows/repository.yml:247,523` — обе flutter-сборки с `--dart-define=APP_VERSION` (power-run D4 закрыт кодом+доками) | **ПРАВДА** |
| sora-legacy — отдельный проект для старых ОС | README, install, CONTRIBUTING, faq | После правки L4 формулировки согласованы везде; формулировок «устаревшая версия sora» в доках нет | **ПРАВДА** |
| Legacy `android-security-requirements.md` | legacy docs | Шапка честная: «требования к новой разработке», кода на момент аудита не было | **ПРАВДА** |

## 3. Cross-ref в зону 4 (код отстаёт от доков — код не чинен)

- **Extension background workers не выполняются.** `docs/extensions.md` §7 описывает runtime v2
  (scheduler, `WorkerEnv`, `net.fetch` с allowlist и аудит-логом). Go-реализация в `core/ext`
  существует (`worker.go`, `netfetch.go`), но ни один хост её не запускает: нет вызовов
  `NewScheduler`/`Register` вне пакета, нет JS-раннера в приложении, тумблер в UI только
  сохраняет конфиг. В док внесён честный статус; продуктовое решение (настоящий раннер или
  бейдж «скоро») — зона 4 / владелец. Заодно: `extensions-cookbook.md` содержит рецепты с
  `worker.fetch` — они относятся к тому же невыполняющемуся runtime v2.

## 4. Закрытые пункты прошлых прогонов (перепроверено по коду)

- POWER-RUN D4 (APP_VERSION в CI) — закрыт: workflow + development.md + packaging README согласованы.
- POWER-RUN D5 (fetch из панелей) — закрыт кодом: CSP `connect-src 'none'`.
- POWER-RUN D6 (пин ключа автора каталога) — закрыт кодом: `store.dart:319,327`.
- POWER-RUN D10/D11 + 05-docs P2-5 (F9 «театр») — закрыты: sync реально wired 2026-10-20, threat model обновлён.
- 05-docs P0-1 (маскирование журнала) — закрыт в доках; P0-2 — закрыт в security.md, остаток в README исправлен здесь (L2); P0-3 (Xray TUN) — закрыт; P0-4 (ручная проверка minisign в install.md) — закрыт: процедуры `minisign -V` есть для Windows и Linux.
- 05-docs P1 (фичи без usage) — закрыт: chains/profiles/QR/zapret+VPN/override/leaktest описаны; sync добавлен здесь (L8). Остаётся только русская пользовательская страница расширений уровня «что значит dangerous» — extensions.md остаётся EN-спекой разработчика; пользовательский минимум есть в usage.md (таблица раздела + permissions UI). Не враньё, а глубина покрытия — на усмотрение владельца.

## 5. Ссылки

Скриптовая проверка всех относительных ссылок и якорей (GitHub-slug, включая
дубли заголовков) по проектной документации обоих репозиториев: **0 битых**.
Единственные срабатывания — вендорные `third_party/zapret/docs/` (не наши доки;
якоря `-1` валидны на GitHub для дублей заголовков). Внешние ссылки сетью не
проверялись (только формат) — по заданию.

## 6. Коммиты

- sora `1ec95dd` `[final-audit] docs: honest claims — …` — README.md, README.en.md,
  docs/usage.md, docs/faq.md, docs/extensions.md (только §7-ханк), docs/README.md
  (только строка update-rollout). Собран из блобов поверх HEAD CAS-рецептом
  (AGENTS.md): чужие незакоммиченные ханки в тех же файлах (extensions.md,
  docs/README.md) в коммит НЕ попали и остались в рабочем дереве.
- sora-legacy `054b929` `[final-audit] docs: architecture/core.md — Android/Android TV
  are design targets…`.

## 7. Вердикт зоны

**Условно чисто.** После этих правок в пользовательской и security-документации
не осталось ни одного проверяемого утверждения, противоречащего коду: подписи
(fail-closed, ключ-заглушка честно названа), платформы (Android — только спеки),
фичи (расширения/sync/chains/zapret+VPN/kill switch — все wired и подтверждены
кодом), числа (32 языка, 3 движка, API 1.11=1.11, лимиты) и ссылки (0 битых)
сходятся. Единственный остаток — не документационный, а продуктовый: фоновая
runtime расширений описана как спека v2, но не исполняется (зона 4, §3); в самих
доках это теперь честно помечено.
