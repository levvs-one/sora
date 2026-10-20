# Статус депрекации VMess (2026)

Дата: 2026-10-19. Тема: жив ли VMess в 2026, детект, стоит ли поддерживать, миграция на VLESS.

## Что нашёл

### 1. Формальной депрекации VMess нет
- Ни V2Fly, ни Xray не объявляли VMess deprecated. Все три движка (Xray, sing-box, mihomo) поддерживают VMess в 2026 наравне с VLESS.
- Панели (3x-ui, X-UI, Remnawave и др.) по-прежнему генерируют `vmess://` ссылки; подписочные сервисы и Telegram-каналы массово раздают VMess-конфиги.
- В гайдах 2026 (VPNSmith, октябрь 2026) VMess упоминается как «рабочий, но помеченный» (marked) протокол: «VMess offers more compatibility with older clients. Both bypass censorship effectively in 2026» — но рекомендация для новых серверов: VLESS + REALITY.

Источники:
- https://www.vpnsmith.com/en/blog/v2ray-vmess-vless-setup-2026
- https://docs.nexora-panel.org/protocols/vmess («VLESS with REALITY — the usual first choice»)

### 2. AlterID (pre-AEAD VMess) — фактически мёртв
- С ~2020 все современные конфиги используют `alterId: 0` (VMess AEAD). Non-AEAD VMess с alterId>0 deprecated и считается небезопасным.
- Sora уже делает правильно: `core/engine/mihomo/proxy.go` жёстко ставит `AlterID = 0`, sing-box-рендер использует `security: auto`. В UI alterId не экспонируется.
- Вывод: в sora нечего чинить, но стоит валидировать импортированные конфиги (см. рекомендации).

Источники:
- https://deepwiki.com/SagerNet/sing-box/4.2-proxy-protocol-implementations («AlterId: 0 for AEAD mode, 1 for legacy»)
- https://1gbits.com/blog/how-to-set-up-a-v2ray-server/ («alterId: 0: turns on modern VMess AEAD. Older non-zero values are deprecated»)

### 3. Проблемы детекта (MD5-based + отпечаток)
- Аутентификация VMess строится на MD5: AuthID = `HMAC-MD5(UUID, UTC)`, ключ команды = `MD5(UUID + 'c48619fe-8f02-49e0-b9e9-edf763e17e21')`, IV = `MD5(timestamp)` (по pkg.go.dev для Go-реализации; та же схема в v2ray-core). Крипто не сломано практически, но дизайн архаичный.
- Критичнее — **активное зондирование**: известная уязвимость v2ray-core#2523 (p4gefau1t, PoC): replay валидного authenticator + варьирование padding length выдаёт VMess-сервер по количеству прочитанных байт. Починено server-side через «drain»-поведение, но сам отпечаток — в дизайне протокола.
- **Пассивный детект полностью зашифрованного трафика**: USENIX Security 2023 (Wu et al.) — эвристики GFW покрывают Shadowsocks, VMess, obfs4 (отпечатки протоколов, доля set-битов, printable ASCII). OpenGFW шиппит это как built-in детект.
- Практика: отчёт оператора из РФ (октябрь 2025, anecdotal, не измерения) — VMess детект ~80% против <5% у VLESS+REALITY; ThroughWire (2026): «V2Ray (VMess) — Weak [active-probe resistance], aging fingerprint, easily flagged»; VPNSmith: «its fingerprint eventually became detectable by advanced DPI since 2021».
- VMess требует синхронизации часов ±90 сек — хрупкость на десктопах/мобильных (доп. вектор отказов).

Источники:
- https://lists.torproject.org/mailman3/hyperkitty/list/anti-censorship-team@lists.torproject.org/message/BZITRLE3B3TOGBFLQXWRF7UG7SWFD3TG/
- https://www.usenix.org/conference/usenixsecurity23/presentation/wu-mingshi
- https://www.throughwire.net/blog/best-protocol-for-china
- https://dev.to/__2ea5fee000c/vless-protocol-how-it-bypasses-censorship-in-russia-and-why-it-works-4o9d (anecdotal)
- https://pbxscience.com/why-opengfw-stands-apart-from-other-linux-firewalls/

### 4. VLESS — путь вперёд, но VMess остаётся fallback'ом
- Консенсус 2026: VLESS (2020) — легче, быстрее, стелсивее (нет app-layer шифрования, нет alterId, только UUID). VLESS+REALITY — дефолт для жёсткой цензуры; VLESS+WS+TLS+CDN — для надёжности; VMess+WS+TLS — только «legacy/совместимость».
- Причина не «VMess взломан», а: (а) VLESS делегирует шифрование TLS/REALITY (меньше оверхеда, двойного шифрования), (б) нет исторических отпечатков, (в) проще аудит.
- Двойной стек (VMess+VLESS параллельно на панели) — нормальная практика 2026.

Источники:
- https://v2raybox.com/what-is-vmess-protocol-and-how-does-it-work/
- https://foundorasystems.com/best-free-vpn-server-v2ray-in-2026/ (приоритет протоколов)

## Что sora должен перенять

1. **Пометка «Legacy» для VMess в UI** — в списке серверов / карточке сервера / help: VMess = совместимость, VLESS = рекомендовано. Маленький бейдж + одна строка объяснения в справке. Это честная позиция «лучшего клиента»: не врать, что все протоколы равны.
   *Эффект: medium* — дифференциация UX, ноль риска совместимости.

2. **Предупреждение при импорте `vmess://`** (и при подписке, где есть только VMess): «этот сервер использует VMess — в регионах с жёсткой цензурой предпочтительнее VLESS; если провайдер предлагает оба — выберите VLESS». Не блокировать, только информировать.
   *Эффект: medium* — снижает число «VPN не работает в Китае/РФ» кейсов.

3. **Валидация импортированных VMess-конфигов**: если `alterId > 0` — показать предупреждение («legacy non-AEAD, менее безопасно и детектируемо»), предложить спросить у провайдера AEAD-конфиг. Не коэрсить молча в 0 (старый сервер может требовать aid>0).
   *Эффект: low-medium* — edge-case, но дешёвый и честный.

4. **Дополнить help/docs**: в разделе про движки/протоколы (уже есть в strings_en.dart) добавить 2–3 строки: VMess vs VLESS, почему VLESS предпочтительнее, когда VMess ок (совместимость, CDN-relay). Не дублировать во все 31 язык сразу — сначала EN/RU, остальное через обычный l10n-процесс.
   *Эффект: low-medium* — просветительский, снижает нагрузку на поддержку.

5. **Мониторинг, не удаление**: VMess убирать из движков нельзя — тысячи legacy-подписок его раздают; «лучший клиент» обязан импортировать всё. Добавить пункт в чеклист аудита движков: если Xray/sing-box когда-нибудь пометят VMess deprecated — обновить таблицу совместимости и UI-бейджи.
   *Эффект: low* — страховка на будущее.

6. **Не делать**: авоконвертацию VMess→VLESS на клиенте (невозможно без серверной стороны), скрытие VMess из импорта, принуждение к смене протокола. Это сломает совместимость — прямо против позиционирования.

## Итог
VMess в 2026 — не deprecated официально, но **практически legacy**: живёт за счёт огромной установленной базы конфигов, проигрывает VLESS по детекту (MD5-based auth, известные активные зонды, пассивные эвристики fully-encrypted трафика) и по производительности (двойное шифрование с TLS). Стратегия для sora: **полная поддержка импорта + AEAD-only + UI-честность** (бейдж legacy, предупреждения, доки) без какого-либо удаления. Единственный обязательный guard — уже есть: alterId=0.
