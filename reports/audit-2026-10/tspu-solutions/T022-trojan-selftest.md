# T022 — Trojan self-test против 5 классов активных проб

Статус: код — в ветке `bugfix/audit-2026-10-19`, коммит `b63c41b`
`[tspu-fix] T022: trojan active-probe self-test (5 trojan-prober classes)`.

## Проблема

Trojan без идеального fallback детектится за 1–2 активные пробы: сервер,
не умеющий отвечать как настоящий веб-сервер на чужой HTTP-трафик, палится
пробером (liuylv/trojan-prober). Пользователь узнаёт об этом от цензора,
а не от клиента.

## Решение: `core/probe/trojan.go`

`ProbeTrojanFallback(ctx, target "host:port") (*TrojanSelfTestReport, error)` —
клиентский самодиагностический прогон пяти классов проб против **своего**
сервера:

| Класс | Что шлём | web-like (pass) | proxy-like (fail) |
|---|---|---|---|
| `h1-close` | полный `GET / HTTP/1.1` + close | HTTP-ответ | закрытие без ответа |
| `h1-incomplete` | оборванный запрос (без пустой строки), ждём 2 с | ждёт / 408 | мгновенное закрытие |
| `overbuffer-incomplete` | 64 КиБ без CRLF | 414/431/400 или ждёт | RST/close |
| `h1-alpn-h2` | TLS с ALPN `h2`, затем полный HTTP/1.1-запрос | handshake ок + HTTP/ответ или clean close | RST/таймаут handshake |
| `short-alpn-h2` | TLS с ALPN `h2`, оборванный запрос, ждём 2 с | ждёт | RST |

Пробы идут **последовательно**: параллельные соединения с одного клиента
выглядят как скан и мутят классификацию. `TrojanSelfTestReport{OK}` = true
только если все 5 классов пройдены. `Detail` — короткая машинная строка
(`http-response: HTTP/1.1`, `waiting`, `closed-no-response`, `dial: …`,
`tls: …`); адресов в ошибках нет (`shortNetErr`).

TLS-пробы используют `InsecureSkipVerify` — осознанно: классифицируется
поведение, не идентичность; цель — свой сервер. Это диагностический
инструмент оператора, не сканер чужих хостов.

## Тесты (`core/probe/trojan_test.go`)

- `TestProbeTrojanFallbackWebLike` — fake-nginx (200 на полный запрос,
  ожидание на оборванном, 414 на overbuffer): 3 plaintext-пробы pass.
  (TLS-пробы против plaintext-порта висят на таймауте — корректно, но 16 с
  в юнит-тесте; покрыты отдельно.)
- `TestProbeTrojanFallbackProxyLike` — сервер, молча рвущий соединение:
  `OK=false`, `h1-close` падает, summary называет класс.
- `TestProbeTrojanFallbackTLS` — TLS-сервер с самоподписанным ECDSA-сертом:
  обе ALPN-пробы pass.
- `TestProbeTrojanFallbackInvalidTarget` — невалидный target → ошибка;
  `nil` ctx → Background.
- `TestTrojanProbeClassString` — имена классов.

## Подключение к продукту (UI/RPC — не в этом коммите)

1. Кнопка «Проверить fallback» в редакторе Trojan-сервера → RPC →
   `ProbeTrojanFallback` → отчёт с разбивкой по 5 классам.
2. Вердикт `OK=false` → предупреждение: «Fallback не переживёт активный
   пробинг. Инструкция: ideal fallback (полноценный сайт на 80/443,
   совпадающие ALPN, реалистичные заголовки)» — чеклист ideal fallback
   из отчёта 06, P06-3.
3. Периодический self-test — **не делать** автоматически: это исходящие
   соединения, которые сам цензор может заметить; только по явному
   запросу пользователя.

## Честные ограничения

- Self-test проверяет **поведение на активные пробы**, а не стелс в целом:
  пассивный DPI (размер/тайминги TLS, поведение при реальной нагрузке)
  им не покрывается.
- `OK=true` ≠ «недетектируем». Формулировка в UI обязана это отражать.
- Тест измеряет сервер здесь-и-сейчас; смена fallback-конфигурации
  требует перепроверки.
