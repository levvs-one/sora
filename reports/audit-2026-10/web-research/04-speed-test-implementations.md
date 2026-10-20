# Speed-тесты в VPN-клиентах: сравнение реализаций

Дата: 2026-10-19. Веб-исследование (поиск, источники 2025–2026) + чтение кода v2rayN (sora-legacy) и текущего sora (read-only).

Текущий статус sora: встроенный браузер со списком speedtest-сайтов (`app/lib/src/speedtest_services.dart`: Ookla, Fast.com, OpenSpeedTest и др.) — ручной тест в вебвью, результаты нигде не сохраняются и не питают выбор сервера.

---

## 1. Что делают конкуренты

### 1.1. ExpressVPN — эталон коммерческого UX
- Встроенный speed test в приложениях Windows/macOS/Linux/Android/iOS/Apple TV. Метрики: **download, upload, latency, jitter, packet loss**. Для десктопа — тест по **всем серверным локациям** с ранжированием: колонки локация / latency / download / **комбинированный Speed Index**, сортировка по клику, прямое подключение из результатов. На Linux 2025 — добавился базовый замер через ISP рядом для сравнения «с VPN / без VPN».
- Если тест запущен без подключения, приложение само коннектится к выбранной локации, тестирует и отключается. Длительность — несколько минут (полный прогон по всем локациям).
- Источники: [expressvpn.com — How the speed test works](https://www.expressvpn.com/ru/support/troubleshooting/what-is-speed-test/), [expressvpn.com — Speed Test for Windows](https://www.expressvpn.com/vpn-software/vpn-apple-tv?skiptag), [addictivetips.com](https://www.addictivetips.com/review/expressvpn/).

### 1.2. PIA (Private Internet Access) — 100% open source
- В клиентском UI **каждый сервер можно протестировать отдельно** (per-server speed check из интерфейса), плюс автоопределение быстрейшего сервера. Клиенты полностью open source — можно подсмотреть реализацию.
- Источник: [proprivacy.com — PIA review 2026](https://proprivacy.com/vpn/review/privateinternetaccess).

### 1.3. Windscribe
- Встроенный speed tester в приложениях; ключевой дифференциатор — серверный список показывает **текущую загрузку (load) каждого сервера** и метку 10 Gbps, Quick Connect приоритизирует высокоскоростные. Т.е. пользователь выбирает не по «пингу», а по пропускной способности.
- Источники: [comparitech.com](https://www.comparitech.com/blog/vpn-privacy/expressvpn-vs-windscribe/), [linkbbs.com](https://www.linkbbs.com/archives/5295.html).

### 1.4. Mullvad / Proton VPN / Surfshark / NordVPN
- **Mullvad**: встроенного speed-теста в приложении нет (открытый клиент — можно проверить). Скорость декларируется обзорами, в UI — только выбор сервера.
- **Proton VPN**: встроенного теста нет; ставка на VPN Accelerator (протокольный уровень). Выбор сервера — по «Fastest».
- **NordVPN, Surfshark**: публикуют только внешние замеры; в приложении — авто-выбор быстрейшего, своих тестовых инструментов в UI нет (Nord — meshnet ping-инструмент, не бенчмарк).
- Вывод: встроенные speed-тесты в app — фича ExpressVPN, Windscribe, PIA и прокси-клиентов (v2rayN, Nekoray/URL-test, Clash), но **не** Mullvad/Proton/Nord.

### 1.5. v2rayN (код в sora-legacy, `Handler/SpeedtestHandler.cs`)
- 4 режима массового теста: **Ping** (ICMP), **Tcping** (TCP connect), **Realping** (HTTP-запрос через прокси-цепочку: поднимается xray с конфигом под все выбранные серверы, каждый тестируется через локальный прокси), **Speedtest** — скачивание тестового файла через прокси каждого сервера, **таймаут 8 секунд на сервер, серверы идут последовательно**.
- Ограничения: speed-тест только download, upload не меряется; результаты — строка в колонке UI, истории нет; долго при сотнях серверов (последовательно × 8 сек).

---

## 2. Методологии: как правильно мерять

### 2.1. Ookla Speedtest (стандарт де-факто)
- **TCP-тест + HTTP fallback**. Ping/jitter: многократные запросы, в зачёт идёт **минимальное** значение. Download: клиент открывает множественные соединения к серверу (:8080), адаптирует размер чанка и буферы в реальном времени, в первую половину теста при необходимости **добавляет потоки**; длительность фиксированная. Аплоад — аналогично наоборот. Сервер выбирается: ~10 ближайших по геолокации → ping → минимальный latency.
- Количество потоков: **4–16 динамически** (современные данные; старые доки — до 4). Именно многопоточность даёт цифру «пропускная способность линии», а не одного потока.
- Источники: [speedtest.net — официальная методология](https://www.speedtest.net/help/guides/how-does-speedtest-measure-my-network-speeds), [nettest.online](https://www.nettest.online/learn/speed-test-accuracy-different-results.html), [7signal.com](https://www.7signal.com/news/blog/site-speed-tests-vs-7signal-throughput-tests), [CAIDA paper](https://www.caida.org/catalog/papers/2024_empirical_characterization_ooklas_speed_test/empirical_characterization_ooklas_speed_test.pdf).

### 2.2. LibreSpeed (открытая альтернатива, LGPL)
- Чистый JS+PHP/Go/Node бэкенд. Ping/jitter: многократный GET пустого файла, **первый замер отбрасывается** (TCP handshake), jitter — взвешенное скользящее среднее по алгоритму (0.7/0.3 и 0.2/0.8 в зависимости от направления изменения — устойчивость к выбросам). Download: параллельные XHR-потоки (по умолчанию 6), upload — 3 потока, ping-сэмплов 10. Данные для download — случайные, несжимаемые (иначе компрессия исказит замер).
- Есть CLI-клиент и Docker — можно использовать как референс реализации.
- Источники: [deepwiki — librespeed/speedtest](https://deepwiki.com/librespeed/speedtest/1.1-features-and-capabilities), [deepwiki — librespeed/speedtest-cli ping](https://deepwiki.com/librespeed/speedtest-cli/4.1-ping-and-latency-measurement), [oneuptime.com](https://oneuptime.com/blog/post/2026-01-15-setup-speed-test-server-ubuntu/view).

### 2.3. speedtest-go (github.com/showwin/speedtest-go)
- Go-библиотека, реализующая протокол Ookla speedtest.net: FetchUserInfo → FetchServerList → FindServer (ближайшие) → Ping → DownloadTest → UploadTest. ~97 известных импортёров (pkg.go.dev), включая VPN/прокси-проекты. Лицензия MIT.
- Плюс: нулевая работа по протоколу, готовые параллельные потоки. Минус: привязка к инфраструктуре Ookla (чужие серверы, меняющийся API, реклама в экосистеме не проблема для либы).
- Источники: [pkg.go.dev — showwin/speedtest-go](https://pkg.go.dev/github.com/showwin/speedtest-go/speedtest?tab=importedby), [pkg.go.dev — laonix/speedtest](https://pkg.go.dev/github.com/laonix/speedtest).

### 2.4. Честность результатов (важно для «лучшего клиента»)
- Разные методологии дают **до 2× разницу** на одном канале: число потоков (Ookla 4–16 vs Fast.com 3–8 vs M-Lab 1 поток), учёт/отсев warmup, среднее vs пик, отсев выбросов. 
- Частые искажения: тест меряет скорость до **сервера тест-провайдера**, а не до VPN-сервера; провайдеры могут приоритизировать трафик speedtest.net; Wi-Fi и фоновая нагрузка шумят — честный клиент должен предупреждать.
- Источники: [nettest.online](https://www.nettest.online/learn/speed-test-accuracy-different-results.html), [makeuseof.com — own server vs Ookla](https://www.makeuseof.com/i-ran-a-speed-test-against-my-own-server-and-saw-what-ookla-couldnt/), [fastestfibre.co.za](https://fastestfibre.co.za/how-does-a-speed-test-work/).

---

## 3. Что sora должен перенять

### 3.1. Свой встроенный speed-тест (не вебвью) — high
Убрать зависимость от сторонних сайтов в вебвью как единственного способа. Встроить замер в sora-core (Go):
- Метрики: download, upload, latency (min из N попыток), jitter (взвешенное сглаживание по LibreSpeed), packet loss.
- Методология: многопоточный HTTP(S) download/upload через **активный VPN-туннель** (меряем именно скорость связки, а не ISP), отсев warmup, адаптивная длительность (~10 с), 4–8 потоков.
- Важно: мерять нужно throughput **через VPN**, а не до тест-сервера в обход — иначе цифра врёт пользователю.
- speedtest-go — кандидат на переиспользование протокола Ookla, но для VPN-клиента правильнее своя реализация поверх своих же тест-эндпоинтов (независимость от Ookla).

### 3.2. Тест «через VPN vs напрямую» рядом — high
Как в новом Linux-клиенте ExpressVPN: два замера рядом (baseline ISP + через VPN). Это честно показывает «цену» VPN и снимает жалобы «VPN режет скорость». Эффект: доверие + диагностика.

### 3.3. Массовый тест серверов с ранжированием — high
Как у ExpressVPN (Speed Index, сортировка, подключение из результатов) и v2rayN (массовые ping/tcping/realping):
- Таблица серверов с колонками latency/download/upload и комбинированным скором; сортировка по клику; кнопка «подключиться» прямо из строки.
- Параллелизация с лимитом (у v2rayN — 12 потоков), таймауты, отмена; не последовательно по 8 секунд как у v2rayN.
- Режимы: быстрый (ping/tcping для всех) → полный (throughput для топ-N по пингу), чтобы не гонять сотни серверов по 10 секунд.

### 3.4. История замеров + графики — medium/high
Никто из массовых клиентов не хранит историю скорости серверов. У sora это питает дифференциатор «умный выбор сервер+движок» (competitor-analysis §3 №1, №11): фоновые замеры, хранение (SQLite), график по серверу, деградация/аномалии видны. Эффект medium сам по себе, high как топливо для автовыбора.

### 3.5. Загрузка серверов в списке — medium
У Windscribe: load-индикаторы и 10-Gbps метки влияют на выбор сильнее пинга. У sora подписки провайдеров load не отдают, но можно показывать **свою измеренную** пропускную способность из истории (см. 3.4) как прокси-метрику. Дешёвый UI-слой поверх истории.

### 3.6. Честные подписи к цифрам — low (но дёшево)
Под результатом: «замер через VPN-сервер X, N потоков, M секунд; Wi-Fi/фоновая нагрузка влияют». Одна строка снимает класс жалоб. Плюс предупреждение, если тест шёл не через VPN (kill switch выкл. и т.п.).

### 3.7. Что НЕ перенимать
- PIA-style «тест каждого сервера вручную по клику» без истории — половина решения.
- v2rayN-style последовательный speed-тест всех серверов — не масштабируется.
- Зависимость только от Ookla-инфраструктуры — чужая точка отказа и чужие серверы; для VPN-клиента измерение должно идти через туннель к контролируемым эндпоинтам.

---

## 4. Оценка эффекта

| Перенять | Эффект | Сложность | Почему |
|---|---|---|---|
| 3.1 Встроенный speed-тест в core (DL/UL/ping/jitter/loss, многопоточный, через туннель) | high | M | Паритет с ExpressVPN/Windscribe; база для всего остального; убирает вебвью-костыль |
| 3.2 Замер «VPN vs напрямую» рядом | high | S | Доверие, честная демонстрация цены VPN, диагностика; уже делает ExpressVPN на Linux |
| 3.3 Массовый тест серверов с ранжированием и Speed Index | high | M | Прямой ответ на gap «выбор по пропускной способности»; подключение из результатов |
| 3.4 История замеров + графики | medium/high | M | Нет ни у кого; топливо для умного автовыбора сервера+движка |
| 3.5 Индикация скорости/нагрузки в списке серверов | medium | S | Дешёвый UI поверх истории; как load у Windscribe, но по своим данным |
| 3.6 Честные подписи и предупреждение «тест не через VPN» | low | S | Одна строка, снимает класс жалоб |

## 5. Рекомендуемый порядок
1. 3.1 — встроенный замер в sora-core (Go), методология по LibreSpeed/Ookla: N потоков, отсев warmup, jitter взвешенным сглаживанием, первый ping отбрасывать.
2. 3.2 — рядом baseline без VPN (S, большой UX-выигрыш).
3. 3.3 — массовый тест топ-N серверов с таблицей и Speed Index.
4. 3.4 — персистентная история (питает автовыбор из roadmap).
5. 3.5, 3.6 — UI-полировка поверх.

Открытые вопросы для проектирования: где хостить тест-эндпоинты (свои vs Ookla/fast.com через туннель — свои дают независимость, Ookla даёт сопоставимость цифр); как часто фоновые замеры, чтобы не жечь трафик лимитных подписок (нужен бюджет трафика на тесты и opt-in).
