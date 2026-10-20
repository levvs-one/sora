# l10n queue — SW4 (censor detector UI)

Scope: `app/lib/src/ui/censor.dart`, `app/lib/src/sora.dart` (`ingestCensorVerdict`),
`app/lib/src/ui/notifications_screen.dart` (action label `censor`).

No collisions with existing keys (checked against `app_en.arb`).
Parameterized keys use `{confidence}` (int), matching the existing `{name}` convention.

| key | en | ru |
|---|---|---|
| `censorTitle` | Blocking diagnostics | Диагностика блокировок |
| `censorPromptTitle` | Connection may be blocked | Возможно, соединение блокируют |
| `censorPromptBody` | It looks like your provider is blocking the connection (confidence {confidence}%). Try masking? | Похоже, провайдер блокирует соединение (уверенность {confidence}%). Попробовать маскировку? |
| `censorEnable` | Enable | Включить |
| `censorDetails` | Details | Подробнее |
| `censorNotNow` | Not now | Не сейчас |
| `censorConfidence` | Confidence: {confidence}% | Уверенность: {confidence}% |
| `censorKindBlocked` | Blocking detected | Блокировка обнаружена |
| `censorKindLikely` | Looks like blocking | Похоже на блокировку |
| `censorKindClear` | No blocking detected | Блокировка не обнаружена |
| `censorKindUnknown` | Could not determine | Не удалось определить |
| `censorExplainer` | This is not an app error: your provider seems to be limiting the connection. Masking changes how the app connects and often helps. | Это не ошибка приложения: похоже, провайдер ограничивает соединение. Маскировка меняет способ подключения и часто помогает. |
| `censorApplyProfile` | Apply recommended profile | Применить рекомендованный профиль |
| `censorNoProfile` | No suitable profile for this verdict | Для этого вердикта нет подходящего профиля |
| `censorHistory` | Check history | История проверок |
| `censorEmpty` | No checks yet. If a connection fails, the detector will check whether your provider is blocking it. | Проверок пока не было. Если соединение не удастся установить, детектор проверит, не блокирует ли его провайдер. |
| `censorReasonTlsReset` | TLS connections are being reset — a typical sign of filtering | TLS-соединения сбрасываются — характерный признак фильтрации |
| `censorReasonDnsSpoofed` | DNS responses are being spoofed | DNS-ответы подменяются |
| `censorReasonHttpBlock` | HTTP requests are being blocked | HTTP-запросы блокируются |
| `censorReasonConnectTimeout` | Connections keep timing out | Соединения обрываются по таймауту |

## Contract notes for the core (Go agent)

Expected detector reason `code` vocabulary (unknown codes fall back to the
core-provided `detail`, so new codes degrade gracefully):

- `tls.reset`, `dns.spoofed`, `http.block`, `connect.timeout`

Dart-side wire seam: `CensorDetector.fetchVerdict` in
`app/lib/src/core/censor.dart` (`Future<CensorVerdict?> Function(CoreLink link)?`).
Set it once `proto/sora/censor/v1/censor.proto` lands; the poll-after-failure
hook in `Sora._emit` and the event-subscription TODO in `Sora._watchSession`
are already in place.
