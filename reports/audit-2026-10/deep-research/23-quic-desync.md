# 23. QUIC-десинхронизация — fake Initial-пакеты, QUIC SNI slicing; USENIX 2025; рецепт 2026

Дата: 2026-10-20. Группа C «DPI-обход», третий проход. Первоисточники: статья USENIX Security 2025 «Exposing and Circumventing SNI-based QUIC Censorship of the Great Firewall of China» (Zohaib, Zao, Sippe, Alaraj, Houmansadr, Durumeric, Wustrow), её artifact appendix, слайды авторов; исходники zapret (QUIC fake); релизы Xray/sing-box/Hysteria с QUIC SNI slicing.

## 1. Что доказала статья USENIX Security 2025 (первоисточник)

- **GFW блокирует QUIC по SNI с 7 апреля 2024** — первый в истории state-level цензор, парсящий QUIC.
- **Как:** QUIC Initial зашифрован, но **ключ выводим пассивным наблюдателем** (version-specific salt + HKDF, RFC 9001). GFW на масштабе страны: берёт первый пакет UDP-потока → проверяет эвристики → расшифровывает Initial → извлекает TLS ClientHello → читает SNI.
- **Эвристики фильтра (чтобы не расшифровывать всё подряд):** QUIC version 1, порт назначения 443, размер payload ≥1001 байт, **source port > destination port** (трюк против сканирования серверной стороны: серверные ответы обычно идут с 443 на высокий порт клиента, их пропускают).
- **Блокировка одним пакетом:** достаточно ОДНОГО Initial с запрещённым SNI — дальше дропаются все пакеты client→server 3 минуты (180 сек, «residual blocking» — впервые для UDP-протокола; для TCP TLS нужно минимум 2 пакета).
- **Блоклист отдельный** от других механизмов цензуры GFW.
- **Ахиллесова пята:** расшифровка дорогая — под умеренной нагрузкой эффективность падает (дневной паттерн: ночью блокировок больше, днём меньше — мощности не хватает).
- **Weaponization:** механизм можно обратить — спуфнутыми Initial-пакетами блокировать UDP между произвольными хостами (авторы показали атаку одной машиной, уведомили CERT Китая).
- **Контрмеры уже интегрированы** (коллаборация авторов): Mozilla Firefox, quic-go, «все основные QUIC-based circumvention tools».

Вывод для нас: «QUIC = невидимость» мертва как идея с апреля 2024. Но у механизма есть структурные слабости (эвристики, стоимость расшифровки, first-packet assumption), и каждая даёт вектор обхода.

## 2. Рабочие контрмеры (из статьи + экосистема 2025–2026)

1. **QUIC SNI slicing** — разбить Initial на несколько UDP-датаграмм. GFW смотрит только первый пакет потока и ждёт ≥1001 байт в нём; фрагментированный Initial не парсится. Дефолт: Firefox 137, Xray ≥25.6.8, sing-box ≥1.12, Hysteria ≥2.6.2. sora получает бесплатно со свежими движками — держать пин актуальным.
2. **Pre-QUIC dummy packet** — любая UDP-датаграмма перед Initial ломает «first-packet assumption» инспектора.
3. **Fake Initial (zapret-подход):** `--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=<quic_initial.bin>` — перед настоящим Initial шлётся поддельный Initial с «белым» SNI; DPI защёлкивается на нём. Работает против ТСПУ (RU), против GFW — частично (см. п.3).
4. **Нарушение эвристик:** source port ≤ dest port (GFW пропускает инспекцию, когда условие `sport > dport` не выполнено — замерили сами авторы); payload <1001 байт в первом пакете там, где это возможно.
5. **ECH в QUIC:** на начало 2025 GFW QUIC+ECH не блокировал; Узбекистан в дек. 2024 блокировал QUIC с ECH — вектор развивается, не панацея.
6. **QUIC connection migration** после handshake — смена 5-tuple уходит из-под residual-блока.
7. **Ротация IP**, избегание дата-центров (блок по подсети — см. файл 29).

## 3. Рецепт 2026 для QUIC 443 (честная версия)

**RU/ТСПУ (проверено полем, zapret-бандлы):**
```
--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=<bin>
```
+ в клиенте: свежий движок (QUIC SNI slicing из коробки), pre-QUIC dummy как опция.

**CN/GFW (по статье):** fake Initial менее надёжен — GFW расшифровывает и смотрит SNI в КАЖДОМ Initial-кандидате, но эвристики обходимы: slicing (разбить Initial) + sport≤dport + dummy-пакет. Комбинация, а не один трюк.

**Чего рецепт НЕ делает:** не спасает от блокировки по IP/подсети; не спасает от поведенческого троттлинга mid-stream (лето 2026, см. файл 21).

## 4. Вердикт: лучшее или слоп

**Лучшее.** Статья USENIX 2025 — эталонный разбор: измерено на 7 точках в CN (Tencent/Alibaba) + 6 вне, артефакты воспроизводимы, контрмеры уже в Firefox/quic-go. Slicing — бесплатный выигрыш «обнови движок». Fake Initial — рабочий инструмент против ТСПУ. Слопом было бы продавать «QUIC-обход» как один флаг без понимания, против какого именно инспектора он работает.

## 5. Рекомендация «внедрить так»

1. **Держать движки свежими** (Xray/sing-box/Hysteria) — QUIC SNI slicing приходит бесплатно; добавить в диагностику проверку «движок умеет QUIC SNI slicing: да/нет».
2. **В bypass-движок (nfqws/winws):** QUIC-профиль `--filter-udp=443` с fake Initial + repeats=6 как пресет «RU-QUIC»; бинарные шаблоны `quic_initial.bin` — в поставку, обновляемые.
3. **Pre-QUIC dummy packet** — опция транспорта для QUIC-исходящих (дешёвая, ломает first-packet assumption у наивных инспекторов).
4. **Эвристика sport≤dport** — задокументировать как известный обход GFW-эвристики; не полагаться как на единственную меру (эвристика поменяется).
5. **Strategy Tuner** (файл 24): QUIC-пространство поиска — fake-варианты × repeats × slicing on/off × dummy on/off.
6. Честно в UI: «QUIC-обход работает против SNI-инспекции; против IP-блока и поведенческого троттлинга — нет».

Источники: Zohaib et al., «Exposing and Circumventing SNI-based QUIC Censorship of the Great Firewall of China», USENIX Security 2025 (https://www.usenix.org/conference/usenixsecurity25/presentation/zohaib; artifact appendix secartifacts.github.io; слайды gfw.report); bol-van/zapret (QUIC fake); Xray 25.6.8 / sing-box 1.12 / Hysteria 2.6.2 changelogs (QUIC SNI slicing default).
