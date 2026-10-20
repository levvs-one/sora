# Review: SW4 — UI детектора цензуры (Dart)

**Ревьюер:** независимый ревьюер роя (subagent), 2026-10-19 ~23:50 MSK
**Объект:** `aaf0e96` `[swarm] censor detector UI: verdict prompt, diagnostics screen, verdict history (SW4)`
в `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`. Flutter SDK в окружении нет — ревью чтением кода.
**Вердикт: ПРИНЯТЬ с замечаниями.** Код качественный, гонки продуманы. Внёс 2 мелких фикса
коммитом `8fa775b` `[swarm-review]`. Есть 3 существенных замечания (ниже), блокеров для мержа —
одно: код не компилируется до применения l10n-очереди (ожидаемо по workflow).

---

## 1. Гонки — хорошо

- **Диалог во время build:** `CensorPromptHost._maybeShow` — листенер `CensorDetector`, но показ
  всегда через `addPostFrameCallback`. `showGeneralDialog` никогда не вызывается синхронно из build. ✓
- **Второй вердикт при открытом диалоге:** гарды `_showing`/`_scheduled`; в `whenComplete`
  сброс `_showing`, `dismissPrompt()` только если `prompt.id` совпадает с показанным
  (новый вердикт не затирается), затем повторный `_maybeShow()` — новый промпт показывается следующим. ✓
- **Два вердикта до одного кадра:** показывается актуальный; пропущенный остаётся в истории
  и в нотификациях (след не теряется). Приемлемо.
- **Listener/dispose:** `addListener` в `initState`, `removeListener` в `dispose`. ✓
  `mounted`-гарды: в колбэке кадра, в `_ApplyButton` (finally), `context.mounted` перед push Details. ✓
- Контекст для диалога берётся из `navigator.currentState?.overlay?.context`, а не из контекста хоста. ✓
- Ниты (не блокеры): нет `didUpdateWidget` на случай замены `Sora` (синглтон времени жизни приложения —
  не проблема); при `overlay.context == null` промпт висит до следующего notify — корректный retry.

## 2. Персистентность — хорошо, один фикс внёс

- Кап истории 50: `removeRange(historyLimit, _history.length)` корректен.
- JSON round-trip симметричен (`toJson`/`fromJson`, `confidence` clamp 0..100, дефолты `[]`/`''`).
- **Найдено и исправлено:** в `_load()` общий `try/catch` вокруг всего списка — одна битая запись
  (неверный тип в `as`-касте `fromJson`, напр. `confidence` строкой) роняла **всю** историю.
  Исправление (коммит `8fa775b`): позаписный `try/catch`, битые записи пропускаются, остальные живут.
- Битый JSON целиком → catch → старт с пустой историей, без падения. ✓
- `_persist()` на каждый `ingest` — ок для ≤50 записей.

## 3. Честность — в основном да, один открытый вопрос

- Промпт и нотификация — только при `actionable` (`likelyBlocked`/`blocked`); `unknown`/`notBlocked`
  идут только в историю. Неуверенный вердикт о блокировке не заявляет. ✓
- Тексты честные: «may be blocked», «looks like», процент уверенности показан явно. ✓
- Промпт не персистится: `_prompt` только in-memory; при рестарте не амбушит; след остаётся
  в истории нотификаций (`recordNotification` в `ingestCensorVerdict`). ✓
- **Открытый вопрос:** `actionable` — только по `kind`, без порога `confidence`.
  Вердикт `blocked` с `confidence: 5` теоретически поднимет промпт «похоже, провайдер блокирует
  (уверенность 5%)». Число показано честно, но семантика спорная. Варианты: порог (напр. ≥50)
  или оставить на усмотрение core. Сам не менял — нужен продуктовый вердикт владельца/автора.

## 4. Интеграция — корректно, но в коммит затесался чужой код

- `CensorDetector.fetchVerdict` — документированный seam; `null` = graceful no-op. ✓
- TODO в `Sora._watchSession` корректно оформлен, ссылается на `proto/sora/censor/v1/censor.proto`. ✓
- Хук в `_emit` при `ConnectionFailed`: существующая логика не тронута
  (`recordNotification`/`_notices` как были); `unawaited` + `_disposed`-гард в `.then`;
  `pollAfterFailure` молча глотает ошибки — осознанно, без `CoreFailure`-шума. ✓
- **Проблема:** в коммит без упоминания в сообщении вшит блок custom servers (~70 строк `sora.dart`:
  `import custom.pbgrpc`, `_customServers`, `load/add/delete/testCustomServer`,
  `unawaited(loadCustomServers())` в обработчике открытия линка). К цензору отношения не имеет.
  Вырезать/вынести отдельным коммитом — но историю переписывать нельзя (ветка общая, поверх уже
  лежат чужие коммиты), поэтому только спекой для автора/владельца.

## 5. Координация с SW3 — чисто

- Изменения SW3 (`90ec663`) целы: `autoSwitchOnDegrade` в `settings.dart` на месте;
  reliability/probeStats/auto-switch в `sora.dart` на месте (проверено grep'ом).
- Дифф `aaf0e96` по `settings.dart`/`sora.dart` — чисто аддитивный (плюс одна строка
  в инициализаторе конструктора `censor = CensorDetector(...)`).
- `main.dart` / `notifications_screen.dart` — аддитивно. Утверждение автора о корректном
  переприменении поверх SW3 подтверждается.

## 6. Стандарты UI — ключи 1-в-1, но компиляция ждёт l10n

- Все 20 используемых ключей сверены 1-в-1 с `reports/l10n-queue/SW4.md` — все на месте:
  `censorTitle`, `censorPromptTitle`, `censorPromptBody{confidence}`, `censorEnable`, `censorDetails`,
  `censorNotNow`, `censorConfidence{confidence}`, `censorKindBlocked/Likely/Clear/Unknown`,
  `censorExplainer`, `censorApplyProfile`, `censorNoProfile`, `censorHistory`, `censorEmpty`,
  `censorReasonTlsReset/DnsSpoofed/HttpBlock/ConnectTimeout`. Параметризованные — `{confidence}`. ✓
- Красного нет: только `Colors.transparent`; иконки/кнопки/прогресс — `palette.ink/ink2/ink3`,
  спокойные тона, без алармизма. ✓ Все строки через `S.of`. ✓
- **Важно:** ключей пока нет в сгенерированных `app/lib/l10n/strings*.dart` — как закоммичен,
  код **не компилируется** (нет геттеров `S.censorPromptTitle` и др.). Это ожидаемо по workflow
  очереди, но SW4 не собирается до прохода l10n-агента. Чужой незакоммиченный WIP в `l10n/`
  (плюралы и пр.) ключей цензора не содержит — не трогал.
- Мелочь: `DateFormat('dd.MM.yyyy  HH:mm')` — захардкоженный паттерн (+ двойной пробел).
  Для ru-first приложения терпимо; идеал — `DateFormat.yMd().add_Hm()`. Оставил, отмечаю.

## 7. Фильтр слопа

- Вырезал: мёртвый `shadowColor: palette.shadow` при `elevation: 0` (коммит `8fa775b`).
- Вырезал бы: блок custom servers из этого коммита (см. п.4) — не его фича, не его сообщение.
- Оставил: `semanticButton: true` в `notifications_screen.dart` — осмысленный a11y-фикс, хоть и не про цензор.
- Остальное по делу: комменты точные, док у `fetchVerdict`/`ingest` хороший, API kit (`Pressable`,
  `Screen`/`Group`/`Heading`, `Motion`, `push`, `SoraScope`) использованы корректно
  (сигнатуры сверены с `kit.dart`/`theme.dart`).

## Исправлено

Коммит `8fa775b` `[swarm-review] censor: skip malformed history entries instead of wiping all;
drop dead shadowColor (SW4)` — только 2 файла, pathspec-форма (учтён урок AGENTS.md про чужой
staged WIP; в дереве ~109 файлов чужих незакоммиченных изменений — не тронуты):
1. `app/lib/src/core/censor.dart` — `_load()`: позаписный `try/catch`, битая запись пропускается.
2. `app/lib/src/ui/censor.dart` — убран мёртвый `shadowColor` при `elevation: 0`.

## Осталось

1. **Применить l10n-очередь SW4** (20 ключей) — без этого не компилируется. Не моя зона: в `l10n/`
   активен чужой незакоммиченный WIP.
2. **Вынести custom-servers из `aaf0e96`** отдельным коммитом/спекой (историю не трогать).
3. **Решить порог `confidence` для `actionable`** (сейчас kind-only) — продуктовое решение.
4. `flutter analyze` + сборка на машине с SDK — в этом окружении SDK нет, проверял чтением кода.
