# 28. tls_fragment — механика фрагментации TLS, реализация в sing-box, компромиссы

Дата: 2026-10-20. Группа C «DPI-обход», третий проход. Первоисточники: документация sing-box (`configuration/shared/tls/` — опции `fragment`, `fragment_fallback_delay`, `record_fragment`), разбор singbox-internals «TLS ClientHello Fragmentation» (псевдокод `Conn.Write`), RFC 2246 §6.2.1 (record layer fragmentation). Отчёт 42 тира A упоминал `tls_fragment` как «пробросить в UI» — здесь механика и цена.

## 1. Механика

**Два независимых механизма** (опции outbound TLS в sing-box):

1. **`fragment: true` — разрез на уровне TCP-сегментов (packet fragmentation).**
   - Перехватывается только **первый `Write`** — то есть ClientHello; остальные записи идут напрямую.
   - Алгоритм (по разбору singbox-internals): из ClientHello извлекается SNI (`IndexTLSServerName`); домен бьётся на лейблы (public suffix отбрасывается); **внутри каждого лейбла выбирается случайная точка разреза**; ClientHello режется на куски по этим точкам.
   - Включается `TCP_NODELAY`; каждый кусок пишется **с ожиданием ACK** (`writeAndWaitAck`) — сервер подтверждает получение куска до отправки следующего.
   - DPI, ждущий SNI в одном пакете/сегменте, паттерна не видит; TCP-стек сервера собирает ClientHello корректно.
2. **`record_fragment: true` — разрез на уровне TLS records.**
   - Куски переупаковываются с TLS record-заголовком (content type + version + length) — то есть формально это несколько TLS-записей вместо одной. Легально по RFC 2246 §6.2.1 (record layer может фрагментировать как угодно до 2^14).
   - Ломает DPI, парсящий «один record = один ClientHello».

**`fragment_fallback_delay`:** если сервер не отвечает за указанное время (DPI съел куски / сервер не понял), — fallback: переотправка ClientHello целиком без фрагментации. Страховка от поломки экзотических серверов.

**Родственники в sing-box:** `tlsspoof` (вброс malformed-пакетов `wrong-sequence/wrong-checksum/wrong-ack/wrong-md5/wrong-timestamp` перед настоящим ClientHello через raw-сокеты/WinDivert — идеологически то же, что zapret `fake`+`fooling`, но на уровне TLS-стека клиента, без драйвера).

## 2. Компромиссы (задержка vs обход)

| Цена | Величина | Комментарий |
|---|---|---|
| Handshake latency | +1–3 RTT (write→ACK→write…) | фрагменты шлются последовательно с ожиданием ACK; на высоком RTT заметно |
| CPU/батарея | мизер | только первый Write соединения |
| Совместимость | риск с «строгими» middlebox | некоторые корпоративные DPI/прокси рвут разрезанные ClientHello; лечится fallback_delay |
| Эффективность | средняя | бьёт SNI-инспекцию первого пакета; **не бьёт** реассемблирующий DPI, поведенческий анализ, IP-блок |

Это **самый дешёвый** десинк: без драйвера, без root, на уровне сокета. Но и самый слабый: против ТСПУ-2026 работает как «режим совместимости», а не как основной обход. Не путать с zapret split: zapret режет на уровне пакетов ядра с fooling, sing-box fragment — на уровне приложения без fooling (сервер видит все куски валидными).

## 3. Вердикт: лучшее или слоп

**Лучшее — как дешёвый базовый слой.** Нулевая цена внедрения (флаг в конфиге), реальный эффект против SNI-инспекции первого пакета, fallback страхует совместимость. Слоп — продавать как «DPI-обход» в одиночку или включать без fallback (ломает часть сетей молча).

## 4. Рекомендация «внедрить так»

1. **Пробросить в UI как «режим совместимости»** (подтверждаю отчёт 42): `fragment` + `record_fragment` + `fragment_fallback_delay` (дефолт fallback, напр. 1–2s) — три чекбокса/одно поле, не «advanced-хак».
2. **Дефолт:** `fragment=true` в RU-пресетах (дешёвый выигрыш против SNI-реза), `record_fragment` — опционально (агрессивнее, выше риск).
3. **Комбинация:** fragment (L7-сокет) + zapret split/fake (L3-пакеты) — разные слои, складываются; не взаимоисключают.
4. **Диагностика:** при «TLS timeout» — подсказка «попробуйте выключить фрагментацию» (редкий, но реальный класс ложных срабатываний на строгих middlebox).
5. **Не делать:** fragment без fallback_delay; позиционирование как замена nfqws; включение для QUIC (там свой механизм — файл 23).

Источники: sing-box docs `configuration/shared/tls/` (outbound: `fragment`, `fragment_fallback_delay`, `record_fragment`); singbox-internals «TLS ClientHello Fragmentation» (алгоритм разреза по лейблам SNI, writeAndWaitAck); deepwiki SagerNet/sing-box (tlsspoof/tlsfragment в `common/tls/`); RFC 2246 §6.2.1.
