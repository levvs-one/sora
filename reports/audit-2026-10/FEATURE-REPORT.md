# FEATURE-REPORT — волны 1–3 + раздел расширений (2026-10-19)

Ветка `bugfix/audit-2026-10-19`, всё локально, пуша нет.
План: `reports/FEATURE-PLAN.md`. Видение расширений: `reports/EXTENSIONS-VISION.md`.
Логи волн: `reports/featlog-wave{1,2,3}-{go,dart,ext}.md`.

## Волна 1 (P0) — закрыты главные гэпы конкурентов
- **F1 QR-шеринг/сканирование**: `QrShareScreen` (H-коррекция, ссылка скрыта) + `QrScanScreen` (фонарик, буфер обмена, фолбэк без камеры). Переиспользует `ParseImport`/`GetSubscriptionLink`.
- **F4 экран соединений**: шапка статистики, вид «списком / по процессам», сворачиваемые группы, контекстное меню (закрыть / копировать хост / добавить правило).
- **F3 DNS-менеджер**: backend `CheckDnsLeaks` (3 проверки, 16 тестов, API 1.8) + UI с пресетами и «светофором»; предупреждения — спокойные, не красные.
- **F0**: UX-аудит split-tunneling, поправлен пустой program_picker.

## Волна 2 — скорость, живучесть, override
- **F2 выбор по скорости**: замеры через временную сессию движка, streaming RPC `BenchmarkServers`, история `probe/history.json` (TTL 24ч); UI — экран замеров, сортировка, smart-скоринг автовыбора.
- **F6 override-слой**: правки поверх подписки переживают refresh (backend `OverrideStore` + UI «Мои правки»).
- **F7 живучесть**: watchdog ядра (>5 крашей/60с → `EngineUnstable`), watchdog `WatchEvents` в UI, crash-intent с баннером восстановления, staged updates с отменой.

## Волна 3 — профили, цепочки, синк, zapret, расширения
- **F5 сетевые профили**: триггеры SSID/шлюз/ASN, fingerprint, авто-применение с undo; RPC `ListProfiles`/`SaveProfile`/`DeleteProfile`/`GetNetworkFingerprint`, событие `ProfileMatched` (API 1.10).
- **F8 proxy chains**: `Via`-рендеринг на Go, capability-флаги движков; UI-конструктор с drag-reorder. **Закрыта теневая фича**: `connectChain` раньше кидал `chainUnsupported` всегда — теперь реально строит план и подключается (с проверкой capability и версии ядра).
- **F9 E2E-синк без облака**: отдельный сервис `service/sync` (QR-пейринг, mDNS, Noise_XX, document sync, localhost HTTP API с bearer-токеном); все тесты зелёные.
- **F11 VPN+zapret**: `zapret_with_vpn` в `SessionPlan` (ядро 1.10), тоггл только на Linux+zapret. **Закрыта теневая фича**: тоггл раньше никуда не уходил — дописаны hand-written Dart-стабы полей 15/16/17 `SessionPlan` (дескриптор перегенерирован побайтово-проверенным энкодером) и проводка в `buildPlan`.
- **F10 расширения (MVP)**: манифест v1, `.soraext` (zip+minisign, fail-closed), permissions-модель, `ext_host.proto`, `core/ext` (install/update/rollback/enable/disable, per-extension токены, подписанный каталог), стор в приложении (карточки со звёздами/бейджами, настройки в карточке, один тап), sideload с предупреждением. ExtensionHost завайрен в `sora-core`.

## Тотальное 5-проходное ревью (по требованию владельца)
Координатор + 5 зональных воркеров, каждый файл — 5 линз (безопасность, корректность, живучесть, качество, системы/UX).
~155 находок, **21 коммит-фикс** (`[review-5pass]`), отчёт `reports/REVIEW-5PASS.md`.
Топ: Critical — сломанная компиляция C# от прошлой правки (исправлено); High — исполнение движка до проверки дайджеста, паника ядра через crafted vault, мнимый фикс NEW-1 переделан по-настоящему.
Вердикт по новому коду волн: высокий уровень, 100% строк через l10n, состояния везде.

## Проверки
- `go build` + `go vet`: core и service/sync — чисто; `GOOS=windows` — чисто.
- `go test`: всё зелёное, кроме предсуществующего `TestTunAndFakeIPAvoidLANAndEachOther` (падает и на чистом дереве — песочница).
- Dart/C#: без тулчейнов — ручная вычитка; перед мержем на dev-машине: `flutter analyze`, `flutter build`, перегенерация Dart-protobuf и сверка с hand-written стабами, сборка C#.

## Осталось владельцу
1. Церемония ключа minisign → заменить заглушки (обновления, каталог расширений).
2. `flutter analyze` + ручные прогоны новых экранов; сборка C#.
3. `--dart-define=APP_VERSION=x.y.z` при релизной сборке (гейт `min_app_version` расширений).
4. Ручной тест `sora://` диплинков на Linux cold-start.
