# l10n queue — SW2 (LeakTestScreen, `app/lib/src/ui/leaktest.dart`)

Формат: `key | en | ru | get|method | params`. Ключи НЕ внесены в `app/lib/l10n/` — их добавит l10n-проход.
Методы: `leakTestProgress(int count)`, `leakTestFound(int count)` (plural по образцу
`subscriptionExpiresInDays`).

| key | en | ru | kind | params |
|---|---|---|---|---|
| leakTestTitle | Leak test | Проверка утечек | get | — |
| leakTestIntro | Probes whether traffic can leave the device outside the tunnel: direct DNS and ICMP, IPv6 egress, and the system resolvers. Run it while connected. | Проверяет, может ли трафик покинуть устройство в обход туннеля: прямые DNS- и ICMP-запросы, утечки IPv6 и системные резолверы. Запускайте при активном подключении. | get | — |
| leakTestRun | Run test | Проверить | get | — |
| leakTestCancel | Cancel | Отмена | get | — |
| leakTestProgress | Tests completed: {count} | Выполнено тестов: {count} | method | count: int |
| leakTestNeedsConnection | Connect to run the leak test. | Подключитесь, чтобы проверить утечки. | get | — |
| leakTestAllClear | No leaks found | Утечек не найдено | get | — |
| leakTestFound | {count, plural, one{# leak found} other{# leaks found}} | {count, plural, one{Найдена # утечка} few{Найдены # утечки} other{Найдено # утечек}} | method | count: int |
| leakTestSkipped | Skipped — not applicable in this session | Пропущен — неприменим в этой сессии | get | — |
| leakTestFix | Fix | Исправить | get | — |
| leakTestFixedNote | Kill switch is on — run the test again to verify. | Kill switch включён — запустите проверку снова. | get | — |
| leakTestCheckDirectDns | Direct DNS | Прямой DNS | get | — |
| leakTestCheckIpv6 | IPv6 | IPv6 | get | — |
| leakTestCheckIcmpEcho | ICMP echo | ICMP echo | get | — |
| leakTestCheckSystemResolvers | System resolvers | Системные резолверы | get | — |

Примечания:
- Ключи `leakTest.check.*` заданы ядром (`core/leak/leak.go`); экран резолвит их в строки выше,
  неизвестные показывает как есть (как `dns.dart`).
- Поле `details` ядро присылает готовым английским текстом (не ключом) — экран показывает как есть;
  follow-up для Go-агента: отдавать `details` ключами локализации.
- Длительность теста (`duration_ms`) в UI не показываем — диагностический шум (см. отчёт SW2).
- Ошибки — только через существующие ключи `describe()` (`errCore`, `errVersion`, …); новых не нужно.
