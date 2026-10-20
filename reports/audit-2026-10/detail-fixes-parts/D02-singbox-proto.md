# D2 — core/engine/singbox протоколы (commit dd49dc4, 95 строк через временный индекс)

## Hysteria2 up_mbps/down_mbps
- Было по задаче: не прокидываются. Проверка: цепочка уже сшита net R&D (парсер upmbps/downmbps → credentialDocument → engine.Outbound → render up_mbps/down_mbps, ноль опускается = BBR). Тест TestRenderHysteria2BandwidthAndHopping уже был.
- Стало: добавлен негативный тест TestRenderHysteria2OmitsZeroBandwidth — нулевые капы не рендерятся. Фикс не понадобился.
- Эффект: brutal CC включается только при заданных капах, случайно — никогда.

## NaiveProxy: рендер sing-box стороны
- Было: протокола naive нет нигде.
- Стало: кейс в outbound() — `type: naive`, username/password, минимальный tls (SNI=хост), `udp_over_tcp: {enabled, version: 2}` (без него UDP молча чернеет). НЕ используется общий r.tls() — Cronet владеет хендшейком, sing-box отвергает uTLS/ALPN/insecure/REALITY на naive. insecure=true → явная ошибка рендера, а не мёртвый конфиг. Привязка через локальную protocolNaive — сработает, когда парсер научится "naive".
- Тесты: TestRenderNaiveOutbound, TestRenderNaiveFallsBackToServerName, TestRenderNaiveRefusesInsecureTLS — PASS. Пакет зелёный (29 тестов).

## Спека остатка (парсер/план/control/mihomo/xray)
- Нужны: core/parser разбор `naive+https://user:pass@host:port?padding=true#name`; engine.ProtocolNaive + validate; control/plan.go credentialDocument; рендеры mihomo/xray (сейчас not supported — ожидаемо).

## КРИТИЧНО: build tag
- sing-box naive требует сборки с тегом with_naive_outbound (тащит Cronet). Пины — форк Leadaxe/sing-box-lx v1.14.3-lx.14; наличие тега не подтверждено (нужен бинарник/workflow форка). Без тега `type: naive` уронит старт движка. До верификации импорт naive-ссылок включать нельзя.

## Процессное
- Параллельный агент дважды перезаписывал render.go; правки переприменены. В реальном индексе застейджена чужая версия файлов без hunks D2 — чужой bare-коммит может откатить dd49dc4; индекс не тронут, флаг зафиксирован.
