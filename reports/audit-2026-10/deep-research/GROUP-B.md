# GROUP-B «Протоколы» — сводка третьего, самого глубокого прохода

Дата: 2026-10-20. Лид группы B. 10 тем, файлы `11–20` в `~/workspace/bug-hunt/reports/deep-research/`.
Источники: спеки (XTLS, SIP022/SIP023, RFC 10024, Noise, docs.amnezia.org), исходники (Xray-core, mihomo, sing-box, hysteria2, amneziawg-go, trojan-go), issue-трекеры (hysteria PR #1703), замеры (clashopen 2026, Cloudflare 2026).

**Организационное**: spawn недоступен на depth 2/2 — все 10 тем выполнены лидом лично. Дублирования тиров 1–46 из WEB-RESEARCH.md нет: там «что делать», здесь «как устроено и как именно внедрить».

## Ранжированные рекомендации (все 10 тем)

### P0 — делать немедленно (разрыв «работает / не работает»)

1. **VLESS+REALITY+vision как обязательная связка (тема 11).** Спека XTLS: UUID — только аутентификация, шифрование — на транспорте; vision-flow закрывает макро-тайминги. В UI запретить/варнить `reality+tcp` без `xtls-rprx-vision` (TLS-in-TLS детектируется) и пару XHTTP+vision (несовместимы). Поле `encryption` — текстовый инпут с дефолтом `none` (гайдлайн автора).
2. **Hysteria2: прокинуть brutal (тема 14).** Без `up_mbps`/`down_mbps` hy2 падает на BBR — протокол-кастрат. UI «скорость тарифа» + авто-калибровка по speedtest (ручной ввод завышают). Плюс stall-watchdog: «established, но 0 байт при спросе 15–20 с → реконнект» (баг сервера v2.11.0, фикс PR #1703 — требовать свежую версию в one-click деплое).
3. **PQ key_share в ClientHello (тема 20).** X25519MLKEM768 — дефолт Chrome 131+, RFC 10024 финализирован (авг. 2026), >2/3 трафика Cloudflare — гибрид. Фингерпринт «свежий Chrome без PQ» — детект-сигнал для DPI. Аудит всех ClientHello (uTLS, REALITY, QUIC) + JA4-check в диагностике.
4. **AmneziaWG: capability-check движка (темы 17, 19).** sing-box upstream AWG не умеет (только форк amnezia-box). Если движок молча игнорирует AWG-поля — на проводе обычный WG, это обман пользователя. Жёсткий варнинг/блок при `awg_supported=false`.

### P1 — высокий эффект, плановая работа

5. **AmneziaWG 3.1 полностью (тема 17).** HeaderProtectionKey (S1–S4 ≥ 12, H1–H4 := 1..4), ContentPaddingAddition, тайминги-диапазоны (RekeyAfterTime/RekeyTimeout/RejectAfterTime/KeepaliveTimeout/MaxHandshakeAttempts), RandomTrailers, DisableCookies. Валидация: H-диапазоны не пересекаются, Jmax < MTU, S1+56 ≠ S2. Генератор «диалектов» + I1-пресеты (QUIC/DNS/SIP) + CPS-редактор. Честно: CN — не AWG.
6. **Shadowsocks-2022 как дефолт SS (тема 12).** `2022-blake3-aes-256-gcm`, генератор base64-ключей в UI (пароли запрещены спекой), поддержка EIH (`iPSK:uPSK`) для мультитенанта, UDP relay нативный (роуминг по session_id). Legacy-методы — в «устаревшие» с варнингом про replay-атаки.
7. **Trojan: fallback как фича (тема 13).** Trojan без fallback на голом IP — палится пробингом за один запрос. One-click деплой: настоящий сайт + fallback + длинный WS-путь + LE-серт. Уникальная диагностика: тест «невалидный пароль → отвечает настоящий сайт».
8. **TUIC v5 рядом с hy2 (тема 15).** Замеры 2026: TUIC прощает отсутствие тюнинга и выигрывает интерактив/0-RTT на мобильных; hy2+brutal — bulk и потери. Держать оба, автовыбор по speedtest-матрице на одном сервере (данных такого рода в открытых источниках нет — дифференциатор). v4 не деплоить.
9. **WG PSK как PQ-слой (темы 16, 20).** `wg genpsk` в UI + one-click dual-accept (прецедент AmneziaVPN 11.2024): квантово-стойкий хендшейк почти бесплатно, старые клиенты не ломаются. Плюс диагностика хендшейка (возраст, transfer) и MTU-хелпер.
10. **VMess: честный legacy (тема 18).** Не удалять (тысячи подписок), а: автонормализация `aid→0` с уведомлением, бейдж Legacy, мастер миграции на VLESS+REALITY, метрика заката.

### P2 — точечные улучшения

11. **WG TCP-режим для сетей без UDP (тема 19)** — честная подпись «не стелс, а доступность; медленнее». Диагностика трёх случаев: «нет UDP» / «режут WG-сигнатуру» / «AS-уровень» → три разных совета.
12. **Тумблер «PQ only» (тема 20)** — для параноиков, с честной подписью про классические сертификаты. ML-KEM для самоподписанных сертов, где sora контролирует обе стороны.

## Отсечено фильтром (слоп)

- Свои «улучшения» поверх VLESS (кастомные schedulers, шифрование UUID) — ломают совместимость, автор спеки против.
- hy2 без brutal / с завышенным `up_mbps` «побольше» — вредит каналу.
- udp2tcp как «стелс» — это TCP-мелтдаун без маскировки.
- «Сменить порт WG» как анти-DPI; generic-рандомный I1 против AS-блокировок (нужен QUIC+SNI).
- «Quantum-proof VPN»-маркетинг; кастомные гибриды вместо X25519MLKEM768; PQ-бейдж без PQ в фингерпринте.
- Удаление VMess; продвижение VMess новичкам; молчаливое исправление `aid`.
- Trojan на IP без домена/сайта; короткие WS-пути; `allowInsecure` в проде.
- SS-2022 как одиночный анти-DPI (энтропийный блоб виден); legacy SS-методы в новых деплоях.
- Ротация статических WG-ключей «для безопасности» (сессии и так каждые 2 минуты).

## Ключевые первоисточники (для инженеров)

- Спека VLESS: https://xtls.github.io/en/development/protocols/vless.html
- SIP022/SIP023: shadowsocks-org docs (deepwiki-разборы по исходникам)
- AmneziaWG 3.1: https://docs.amnezia.org/documentation/amnezia-wg/ (полная таблица параметров)
- Hysteria2 stall: https://dev.to/colitu/our-hysteria2-connections-died-after-every-upload-speed-test-the-fix-was-37-lines-2n81 (PR #1703)
- TUIC vs hy2 2026: https://www.clashopen.com/en/blog/articles/hysteria2-vs-tuic-v5-benchmark-2026.html
- PQ: RFC 10024; https://www.postquantumsecurity.org/publications/browsers_pqc.html
- Noise IKpsk2: https://www.wireguard.com/papers/wireguard-formal-verification.pdf

## Связь с предыдущими проходами

Углубляет (не дублирует): тир S #2 (uTLS/PQ → тема 20 даёт механику), #3 (REALITY/vision → тема 11 даёт спеку), #7 (hy2 brutal → тема 14 даёт механику CC и stall-баг), #10 (AWG → тема 17 даёт 3.1 по полочкам), #12 (XHTTP+vision конфликт → тема 11 подтверждает), #17 (PQ → тема 20 даёт RFC-статус), тир A #16–17. Закрывает пробелы amneziawg-spec.md (параметры 3.1 с точными типами и правилами валидации) и WG-OBFUSCATION-RD.md (ранжирование техник по уровням угрозы, честные ограничения udp2tcp).
