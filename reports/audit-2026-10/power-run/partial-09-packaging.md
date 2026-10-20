# Power-run 09 — Упаковка / установка / обновления (sora + sora-legacy)

Агент №9. Ветка `bugfix/audit-2026-10-19`, ничего не переключалось, ничего не пушилось.
Проверено чтением кода + эмпирическим прогоном настоящего `sora-update`
с подменёнными утилитами (песочница без bwrap — его нет в окружении).

Метод: install.sh / install.ps1 / sora-update / updates.dart / about.dart /
ext/{store,package,verifier,catalog}.dart / settings.dart / core миграции /
release job / sora-legacy UpdateHandle.cs (вычитка, без тулчейна).

## Пошаговый разбор

### 1. install.sh (Linux, первичная установка)
Порядок: резолв версии → скачивание пакетов → **verify minisign SHA256SUMS**
→ сверка sha256 пакетов → установка пакетным менеджером. Подпись
проверяется ДО любого доверия к хэшам и ДО установки — верно.
Плейсхолдер ключа → fail-closed (`die`), minisign обязателен. `trap`
чистит `$work` при любом выходе. Версия валидируется строгим кейсом.
**Вердикт: честно.**

### 2. install.ps1 (Windows, первичная установка)
Тот же порядок: скачивание (ретраи с бэкоффом) → `Assert-ReleaseSignature`
→ сверка хэша → `Start-Process /VERYSILENT`. `finally` удаляет `$work`.
**Вердикт: честно.**

### 3. sora-update (привилегированный helper, pkexec)
Эмпирика (фейковые id/uname/dpkg-query/dpkg-deb/minisign/apt-get, root):
- Без `SHA256SUMS.minisig` в каталоге загрузок → `downloads must be regular files`, exit 1.
- С ним → `minisign -V` по **приватному снапшоту в /var/tmp** (umask 077),
  затем `apt-get install -y` оба пакета одной транзакцией, exit 0.
- Проверки до установки: формат/версия regex, absolute path каталога,
  владение установкой через package manager, метаданные каждого пакета
  (имя/версия/архитектура из deb/rpm/pkg), downgrade-блок без
  `--allow-downgrade`, symlink-рейсы при копировании (`cp -P` + перепроверка).
- Подпись SHA256SUMS проверяется от root **до** `sha256sum -c` и до установки.
- `bash -n` чист. **Вердикт: честно, порядок «подпись → хэши → установка» соблюдён.**

### 4. updates.dart — staged update (check → download → verify → install)
Постадийная честность:
- **check**: отмена → error=null, stage=idle. Релиз валидируется строго
  (не draft/prerelease, semver x.y.z, ассеты только с github.com URL).
- **download**: отмена через AbortableRequest; лимиты размера; прогресс.
- **verify**: `verifyUpdateFile` по sha256 из манифеста до любых действий.
- **install**: `_guard()` перепроверяет соединение перед pkexec;
  отказ от confirmDrop → тихий возврат, error=null, temp удалён.
  Ошибка pkexec → error=installation + manualCommand, файлы **сохранены**
  для ручной команды (честно). Успех → installed=true → restart → quit.
- temp-каталог удаляется при неуспехе всегда, кроме manual/handOff —
  мусора не остаётся. **Вердикт: честно.**
- **Найденный критический дефект (исправлен):** приложение скачивало
  только `SHA256SUMS`, но НЕ `SHA256SUMS.minisig`, а helper без него
  отказывается работать. Эмпирически подтверждено (п.3): **staged update
  был сломан на 100%**. Фикс: докачка `.minisig` + запись в handoff-каталог;
  отсутствие ассета в релизе → fail-closed `UpdateError.release`.

### 5. about.dart — UI этапов
Стадии checking/downloading/verifying/installing отображаются;
кнопка отмены — только на отменяемых фазах; установка блокируется при
reconnecting/offline. Ручная команда — selectable + копирование.
**Вердикт: честно, состояние не врёт.**

### 6. Расширения: install → verify → gate → rollback
- Все три пути (файл/URL/каталог) идут через `_installBytes`: сначала
  `pkg.verify()` (minisign автора по checksums.txt + покрытие всех файлов),
  затем gate `min_app_version <= APP_VERSION` (--dart-define, в dev сборках
  честно пропускается), затем промпт прав. Подпись — ДО установки. ✓
- Каталог: подпись team-ключом, fail-closed при плейсхолдере; cap 4 МБ.
- Rollback N-1 (Dart): хранится предыдущая версия, откат перечитывает
  манифест с диска, реестр пишется атомарно (tmp+rename). ✓
- **Исправлен OOM-вектор:** скачивание `.soraext` шло через unbounded
  `http.get` до структурных проверок `ExtPackage.open`. Теперь стримминг
  с капом (каталог — точный `size` из подписанного каталога, URL — 64 МБ);
  тот же паттерн, что уже был для catalog.json.
- Фильтр слопа: идея «сужать granted-права при откате» **отклонена** —
  bridge гейтит по паре метод→право, старый код не может вызвать методы,
  которых не знает; лишние гранты инертны. Фикс был бы косметикой.
- **Латентное (не чиню, [cross-ref] владельцу расширений):**
  `core/ext.Store.Rollback` (Go) НЕ перечитывает манифест предыдущей
  версии — правит `cur.Manifest.Version` у НОВОГО манифеста (права, схема
  настроек, min_app_version остаются от откатываемой версии). Сегодня
  `Store.Install`/`Rollback` в проде недостижимы (ядро использует только
  `Issuer()`, RPC install/rollback нет), Dart-сторона делает правильно —
  поэтому только находка, без правки мёртвого кода (фильтр слопа).

### 7. Ядро: отката N-1 нет
Обновление ядра — через пакетный менеджер; механизма «откатить на
предыдущую версию из приложения» нет, `--allow-downgrade` приложение
никогда не передаёт (только ручной вызов helper'а). Это проектное
решение, не баг: атомарность — на пакетном менеджере. Честно фиксирую
как ограничение, фичи не выдумываю.

### 8. Миграции (идемпотентность, обратимость)
- `settings.dart` `_migrate`: идемпотентна (tourDone один раз, format=1,
  дефолт preset только при format==0 без preset). Даунгрейд: `stored >
  format` → ключи не трогаются, старые значения сохраняют смысл.
- `probe/history.json`: atomic write (tmp+rename, 0600), толерантное чтение
  (битый → дропается, не фатально), без схемы — даунгрейд-сейф.
- `overrides/*.json`: atomic save, битый → пустой override + лог.
- `extensions/installed.json`: tmp+rename; `fromJson` толерантен.
  Даунгрейд на старый app: запись с новым `manifest_version` будет
  пропущена (не роняет секцию) — деградация честная.
- **Вердикт: миграции идемпотентны; даунгрейд не портит данные.**

### 9. Права файлов после установки (nfpm)
sora-core: бинарь и движки 0755, данные 0644, unit/polkit 0644.
sora: `sora-update` 0755 (нужно для pkexec + `exec.path` аннотация;
root-владение — требование деплоя, в CI пакеты собираются от root),
дерево `/usr/lib/sora/app` наследует моды из flutter bundle; CI
ассертит `test -x /usr/bin/sora`. Purge чистит `/var/lib/sora`
(секреты не переживают удаление, SORA-L7); plain remove — сохраняет.
**Вердикт: верно.**

### 10. Release job (.github/workflows/repository.yml)
**Найдено и частично исправлено:** job создавал `SHA256SUMS`, но НЕ
`SHA256SUMS.minisig` — а все три установщика требуют подпись
(fail-closed). Без ручной подписи владелец опубликовал бы релиз, который
невозможно установить. Автоподпись невозможна до key ceremony, поэтому
фикс — честный комментарий с процедурой (подписать + залить `.minisig`
в draft до публикации), а не фейковая автоматизация.

### 11. sora-legacy (вычитка, C# без тулчейна)
- `CheckUpdateGuiN`: самообновление отключено честным сообщением. ✓
- `CheckUpdateCore`: downgrade запрещён (`CompareVersions <= 0`); хэш
  архива сверяется с **персональным** `.dgst` (один ассет — один манифест,
  first-hex-match корректен) ДО распаковки; несовпадение → файл удаляется,
  fail-closed. ✓
- Geo-файлы: аналогично через `{geo}.dat.sha256sum` (однохэшовый файл). ✓
- Подписки: sentinel `proxy_restore.pending` на случай обрыва между
  снятием и восстановлением системного прокси; `SaveSubItem` после каждой
  подписки. ✓
- [cross-ref] агенту подписок: `DownloadStringAsync` без капа размера.
- Минорно: замена geo-файла через Delete+Move (неатомарно); правку C#
  не вношу без тулчейна — только фиксация.

## Находки и фильтр слопа

| # | Находка | Фильтр слопа | Действие |
|---|---------|--------------|----------|
| 1 | updates.dart не качал `SHA256SUMS.minisig` → staged update мёртв на 100% (эмпирически) | Не слоп: ломает главную фичу зоны | **Исправлено** (ae750a9) + тест/фикстура |
| 2 | `test_update.py`: фикстура без `.minisig` → CI-тест падал до кода | Не слоп: чинит CI-контракт | **Исправлено** (492aa2d) |
| 3 | Release job без `.minisig` → неустанавливаемый релиз | Не слоп: операционный фейл; фикс — комментарий, не фейковая автоматизация | **Исправлено** (73d845d) |
| 4 | Unbounded `http.get` для `.soraext` (OOM до проверок) | Не слоп: прецедент капа уже есть в catalog.dart | **Исправлено** (34d6375) |
| 5 | `manualCommand` для zypper содержит `--allow-unsigned-rpm`, скрипты — намеренно нет (SORA-H1) | Спорно: без данных о поведении zypper с неподписанными RPM правка в любую сторону — гадание | Не чиню, [cross-ref] владельцу установщика |
| 6 | `core/ext.Store.Rollback` не перечитывает манифест N-1 | Не слоп как находка, но код сегодня недостижим в проде — править мёртвый код = слоп | Находка без правки, [cross-ref] |
| 7 | Windows in-app update: только sha256, без Authenticode | Честное состояние до key ceremony (FIX-PLAN п.9 — действие владельца) | Не чиню |
| 8 | Отката ядра N-1 нет (только пакетный менеджер) | Проектное ограничение, не баг | Фиксирую, фичи не выдумываю |
| — | Сужение granted при откате расширений | **Отклонено фильтром**: инертно, косметика | Не делаю |

## Что починил (коммиты, без пуша)
- `ae750a9` [power-run] fetch SHA256SUMS.minisig in staged updates
  (`app/lib/src/updates.dart`, тест, фикстура `latest.json`)
- `492aa2d` [power-run] helper test fixture: provide SHA256SUMS.minisig
- `73d845d` [power-run] release workflow: document manual SHA256SUMS signing
- `34d6375` [power-run] cap extension package downloads while streaming
  (`ext/package.dart`: `_maxPackageBytes` → публичный `maxPackageBytes`;
  `ui/extensions/store_screen.dart`: `_downloadCapped`)

Проверки: `bash -n` всех скриптов — чисто (shellcheck нет в окружении);
`py_compile` + YAML-парсинг — чисто; эмпирический прогон `sora-update`
(фейковые утилиты): без `.minisig` → отказ, с ним → подпись→установка, exit 0.
Flutter/Dart-тулчейна и bwrap в окружении нет — `flutter analyze/test`
и песочница `test_update.py` не запускались здесь, это за CI.

## Открытые вопросы
- Поведение `zypper install` с неподписанными RPM (нужен стенд openSUSE) —
  от него зависит, убирать ли `--allow-unsigned-rpm` из manual-команды.
- Key ceremony владельца разблокирует: реальный ключ в install.sh/ps1/
  sora-update, подпись SHA256SUMS релизов, team-ключ каталога расширений,
  Authenticode для Windows.
