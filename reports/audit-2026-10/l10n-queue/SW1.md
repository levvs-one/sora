# l10n queue — SW1 (ObfsScreen, `app/lib/src/ui/obfs.dart`, `app/lib/src/obfs.dart`)

Формат: `key | en | ru | get|method | params`. Ключи НЕ внесены в `app/lib/l10n/` — их добавит l10n-проход.
Метод: `obfsCompatibleEngines(String engines)`.

| key | en | ru | kind | params |
|---|---|---|---|---|
| obfs | Traffic obfuscation | Маскировка трафика | get | — |
| obfsPreset | Preset | Пресет | get | — |
| obfsPresetAggressive | Maximum obfuscation | Максимальная маскировка | get | — |
| obfsPresetBalanced | Balanced | Баланс | get | — |
| obfsPresetOff | Speed | Скорость | get | — |
| obfsPresetCustom | Custom | Вручную | get | — |
| obfsManual | Manual settings | Ручные настройки | get | — |
| obfsUtls | uTLS profile | uTLS-профиль | get | — |
| obfsUtlsAuto | Auto | Авто | get | — |
| obfsJitter | Timing jitter | Джиттер | get | — |
| obfsJitterNeedsFragment | Jitter only works with fragmentation enabled. | Джиттер работает только при включённой фрагментации. | get | — |
| obfsCapabilities | Engine capabilities | Возможности движка | get | — |
| obfsDetecting | Detecting capabilities… | Определение возможностей… | get | — |
| obfsUnknown | Capabilities are still being detected. | Возможности пока определяются. | get | — |
| obfsSupported | Supported | Поддерживается | get | — |
| obfsUnsupported | Not supported | Не поддерживается | get | — |
| obfsFineTune | Sizes and delays | Размеры и задержки | get | — |
| obfsCompatibleEngines | Compatible engines: {engines} | Совместимые движки: {engines} | method | engines: String |
| errObfsUnsupported | The installed core is too old for obfuscation profiles. Update Sora to apply them. | Установленный core слишком стар для профилей маскировки. Обновите Sora, чтобы применять их. | get | — |

Примечания для l10n-прохода:
- `describe` в `app/lib/src/ui/kit.dart` уже маппит `'app.obfs_unsupported' => s.errObfsUnsupported`.
- `obfsCompatibleEngines` вызывается как `s.obfsCompatibleEngines(lastApply.compatibleEngines.join(', '))`.
- Существующий `s.fragment` («TLS fragmentation») переиспользован для тумблера фрагментации, `s.refresh` — для кнопки повтора.
