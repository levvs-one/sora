# GROUP-C: DPI-обход — сводка третьего (глубокого) прохода

Дата: 2026-10-20. Лид группы C. 10 тем, 10 отчётов (`21`–`30`), метод — первоисточники: исходники zapret, статьи CCS/USENIX/NDSS, CVE-записи, диссертации, полевые разборы 2025–2026. Первый проход (WEB-RESEARCH, тиры 1–46) — обзор; здесь — механика «до провода» без дублирования.

Отчёты: [21-nfqws-internals.md](sandbox://workspace/bug-hunt/reports/deep-research/21-nfqws-internals.md) · [22-winws.md](sandbox://workspace/bug-hunt/reports/deep-research/22-winws.md) · [23-quic-desync.md](sandbox://workspace/bug-hunt/reports/deep-research/23-quic-desync.md) · [24-geneva.md](sandbox://workspace/bug-hunt/reports/deep-research/24-geneva.md) · [25-utls.md](sandbox://workspace/bug-hunt/reports/deep-research/25-utls.md) · [26-ech.md](sandbox://workspace/bug-hunt/reports/deep-research/26-ech.md) · [27-mimicry-vs-randomization.md](sandbox://workspace/bug-hunt/reports/deep-research/27-mimicry-vs-randomization.md) · [28-tls-fragment.md](sandbox://workspace/bug-hunt/reports/deep-research/28-tls-fragment.md) · [29-active-probing.md](sandbox://workspace/bug-hunt/reports/deep-research/29-active-probing.md) · [30-ml-classification.md](sandbox://workspace/bug-hunt/reports/deep-research/30-ml-classification.md)

## Главная мысль прохода

Цензор 2026 — это **слоёная система по цене вычислений**: L1 сигнатуры (первые байты) → L2 фингерпринт (JA3/JA4) → L3 активное зондирование → L4 поведенческий ML. Каждый слой бьётся своим инструментом, и **ни один инструмент не бьёт все слои**. Архитектура sora должна быть слоёной в ответ: точная мимикрия (L1/L2) + probe-resistance (L3) + стохастика поведения (L4) + десинк пакетов (L1-дёшево). Попытка «одного флага против DPI» — слоп.

## Ранжированные рекомендации

### P0 — критично, делать первым

1. **Миграция bypass-движка tpws → nfqws/winws** (21, 22). Механика доказана по исходникам: трёхфазная модель, fooling (md5sig/badseq/badsum), autottl, QUIC fake. tpws — TCP-only без fake: sora отстаёт на поколение. winws — тот же движок через WinDivert; цена — драйвер, UAC, антивирусы, WFP-конфликты (обработать честно, не замалчивать).
2. **Свежесть uTLS как процесс, не как флаг** (25). HelloChrome_Auto=155 (06.10.2026), пин ≥1.8.2 (CVE-2026-27017/26995 — «почти правильный» фингерпринт детектится). Убрать молчаливый дефолт `chrome` (=133=блок в RU). CI-трекинг актуальности + JA4-stealth-check в диагностике + авто-fallback fp при TLS-timeout.
3. **REALITY-dest гигиена + spiderX + vision-обязательность** (29). ТСПУ зондит как клиент и сверяет SNI с инфраструктурой (te-st.org №37, сен. 2026); волны бьют по подсетям. Гейты в one-click деплое, probe-resistance самопроверка в диагностике.

### P1 — высокий эффект, дёшево

4. **Архитектурный принцип «mimicry-first, randomness-last»** (27). Доказано: Wang 2012 (whitelist-цензор бьёт «look-like-nothing»), Sensors 2026 (donor-мимикрия 0.00–0.26 vs синтетика 0.60–0.96), поле 2026 (Chrome 155 проходит, 133 — нет). Запрет неточной мимикрии в ревью; рандом — только как деталь имитации (GREASE, split-позиции).
5. **Strategy Tuner — bounded-селекция по-просветовски** (24). Geneva даёт теорию (кодирование, фитнес с hard-ограничением «не ломать TCP»), форк «Просвет» (FrainTX/zapret) — рабочий полевой pipeline: 30+ рецептов → гены → скрещивание → двойной прогон стабильности → белый список приманок. Не чистый GA (шумный, медленный), а курированный генофонд + скрещивание + привязка к F5-профилю.
6. **QUIC-пакет: slicing бесплатно + fake Initial пресет** (23). USENIX 2025: GFW расшифровывает Initial (ключ выводим), бьёт одним пакетом, но эвристики обходимы (slicing, sport≤dport, dummy-пакет, payload<1001). Держать движки свежими; QUIC-профиль nfqws с fake+repeats=6.
7. **tls_fragment как «режим совместимости» в UI** (28). Механика sing-box: разрез ClientHello по лейблам SNI со случайными точками + writeAndWaitAck, `record_fragment` — переупаковка records, `fragment_fallback_delay` — страховка. Дёшево, но слабый слой — не продавать как обход.
8. **Стохастический паддинг + mux** (30). Против ML-DPI: random segmentation (98%→63% accuracy, +5% overhead), stochastic padding 2026 (U-бюджет, Rayleigh-тайминги — не даём классификатору выучить расписание), xmux против cross-layer RTT (NDSS 2025: фундаментальный отпечаток прокси) и сибирского триггера параллелизма.

### P2 — важно, но аккуратно

9. **ECH — переключатель с честной подписью** (26). Поправка: протокол — RFC 9849, RFC 9848 — DNS-сторона. Скрывает SNI, не IP; в RU сам в прицеле ТСПУ (дроп при outer SNI=cloudflare-ech.com); только в паре с DoH; несовместим с REALITY. Низкий вес в privacy score.
10. **NaiveProxy one-click как «маскировочный» пресет** (29, тир S #11). Настоящий Chromium-стек + сервер-притворяющийся-сайтом — лучший ответ на зонды. Честно: КНР заявляет идентификацию DPI-оборудованием (госзакупка 14.10.2026).

## Что отсечено как слоп (подтверждено глубже)

- Randomized-фингерпринты как «стелс» (25, 27) — вредны, JA4 их переживает.
- «QUIC = невидимость» (23) — мертва с 07.04.2024.
- ECH как «невидимость» / ECH+REALITY (26) — ложь/несовместимо.
- Детерминированный паддинг как защита от ML (30) — сам становится признаком.
- Чистый неограниченный GA в клиенте (24) — заменить bounded-селекцией.
- Один флаг «DPI-обход» (общее) — цензор слоёный, ответ должен быть слоёным.

## Неподтверждённое / требует проверки

- Детали текущих эвристик GFW QUIC после 2025 (payload≥1001, sport>dport — замер авторов; могли поменяться).
- Масштаб ML-DPI ТСПУ: «апрельская чистка», «сибирская волна» — полевые реверсы (habr/te-st), не официальные спеки; трактовать как рабочие гипотезы.
- Эффективность «Просвета» — по README автора, независимых замеров нет.
- winws на ARM64 Windows — не проверено.

## Следующий шаг для parent

P0-1..3 — в FIX-PLAN/roadmap как эпики с владельцами; P1 — в бэклог фич; принцип mimicry-first (P1-4) — в ARCHITECTURE.md как инвариант ревью. Research-watch (B67): USENIX/NDSS/FOCI по цензуре — раз в квартал, дешёвый процесс.
