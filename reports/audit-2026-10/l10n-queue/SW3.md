# SW3 — умный автовыбор: новые строки для l10n

> Правило роя: `app/lib/l10n/*` руками НЕ править. Ключи ниже используют в коде
> через `S.of(context)` и ждут прогона генерации l10n (arb → strings.dart).
> Пока генерация не выполнена, код не соберётся — это ожидаемо, см. отчёт SW3.

Связанная константа: `Sora.autoSwitchCooldown = 10 минут` (`app/lib/src/sora.dart`).
Текст `autoSwitchOnDegradeDetail` обещает «не чаще одного раза в 10 минут» —
при изменении константы обновить текст.

## 1. `smartPickReason`

- Сигнатура: `String smartPickReason(String ping, String speed);`
- Плейсхолдеры уже отформатированы вызывающим кодом: `ping` — `S.milliseconds(ms)`
  или `S.noAnswer`; `speed` — `S.speedMbps(bps / 1e6)` или `S.noAnswer`.
- Использование: `app/lib/src/ui/servers.dart`, `_SmartPickBadge` — бейдж под
  строкой «Автоматически», когда выбран auto-режим и `autoSelectMode == 'smart'`.
- en: `Picked by smart mode: ping {ping}, speed {speed}`
- ru: `Выбран умным режимом: пинг {ping}, скорость {speed}`

## 2. `autoSwitchOnDegrade`

- Сигнатура: `String get autoSwitchOnDegrade;`
- Использование: `app/lib/src/ui/settings_screen.dart`, заголовок `SwitchTile`
  рядом с выбором режима автовыбора.
- en: `Auto-switch on degradation`
- ru: `Автопереключение при деградации`

## 3. `autoSwitchOnDegradeDetail`

- Сигнатура: `String get autoSwitchOnDegradeDetail;`
- Использование: тот же `SwitchTile`, честное описание под заголовком.
- en: `If the selected server slows down a lot or stops answering, Sora switches to the best measured one — at most once every 10 minutes.`
- ru: `Если выбранный сервер сильно замедлится или перестанет отвечать, Sora переключится на лучший из измеренных — не чаще одного раза в 10 минут.`

## 4. `serverReliability`

- Сигнатура: `String serverReliability(int pct);`
- Плейсхолдер `pct` — целое 0..100, знак `%` уже в шаблоне.
- Использование: `app/lib/src/ui/servers.dart`, `_ReliabilityDot` — тултип и
  semantics-метка точки надёжности в строке сервера.
- en: `Reliability {pct}%`
- ru: `Надёжность {pct}%`

## 5. `noticeDegraded`

- Сигнатура: `String get noticeDegraded;`
- Использование: `app/lib/src/sora.dart`, `notificationFor` для нового
  `Notice`-варианта `ServerDegraded` (уведомление о деградационном переключении).
- en: `The server slowed down — switched to the best measured one`
- ru: `Сервер замедлился — переключено на лучший из измеренных`
