# Маршрутизация: спека R&D (тема 15/20, net-rd)

Дата: 2026-10-19. Ветка: bugfix/audit-2026-10-19. Репо: sora (коммиты), sora-legacy (только анализ).

**Фильтр слопа применён** (директива владельца): в спеку попало только то, что даёт
реальную точность/безопасность/честность. Вычеркнутое — в конце с причинами.

## Находки

1. Источники geo-данных 2025–2026:
   - v2fly/geoip — сборка ежемесячно (5-го числа), источник DB-IP Lite (не MaxMind);
     v2fly/domain-list-community — geosite, релизы по мере правок (есть sha256sum).
   - Loyalsoldier/geoip — еженедельно по четвергам, 7 форматов (dat, mmdb, sing-box srs,
     mihomo mrs, clash/surge ruleset, txt); Loyalsoldier/v2ray-rules-dat — расширенный
     geosite (category-* теги, которыми пользуются пресеты sora).
   - SagerNet/sing-geoip + sing-geosite — .srs rule-set'ы, sing-box тянет и авто-обновляет сам.
   - MetaCubeX/meta-rules-dat — geosite.dat/geoip.dat/geoip.metadb/GeoLite2-ASN.mmdb;
     дефолт для mihomo в sora (GeoIPDefaultURL/GeoSiteDefaultURL).
2. MaxMind GeoLite2 — слоп для встраивания: с 2019 аккаунт+ключ+EULA, обязанность удалять
   старые базы за 30 дней, с 2023 ключи протухают каждые 90 дней. Агрегаторы (Loyalsoldier,
   DB-IP) свежее и чище по лицензии.
3. Платные клиенты (публичные источники): Mullvad — split tunneling по приложениям,
   multihop с выбором entry/exit, DAITA, quantum-resistant; AdGuard VPN — двухрежимные
   exclusions (сайты + приложения, allowlist/blocklist), subnet exclusions, safelisting,
   прозрачный лог применённых правил. ASN/time-правила никто не делает киллер-фичей.
4. Рулевые движки: sing-box — process_name/path/package, ip_cidr, port, network, protocol,
   domain_*, remote rule_set (.srs/.json, update_interval), wifi_ssid/bssid, invert;
   mihomo — DOMAIN*, IP-CIDR, GEOIP, GEOSITE, PROCESS-NAME, ASN, RULE-SET + rule-providers
   (interval, format mrs/yaml/text), geodata-mode + geo-auto-update.
5. Код sora: engine.Rule — 12 типов (ASN и time отсутствуют); routing.Presets:
   global/ru/ir/cn + BlockAds (geosite category-ads-all); user-правила первые, дальше
   пресет, в конце match-all. Shipped geoip/geosite.dat — из Xray-архива
   (packaging/engines/fetch.sh, пин версии), обновляются только со сменой Xray.
   Уточнение к вводной: SHA-256 покрывает бинари движков (engines.digests), сами .dat
   отдельной проверкой не охвачены; mihomo при Options.GeoData тянет dat с MetaCubeX
   без верификации; sing-box geo — через SagerNet .srs (авто-апдейт движком); Xray — статика.
6. Баг: mihomo заявлял FeatureRuleSets, но RuleRuleSet рендерился как RULE-SET,<url>
   без секции rule-providers → невалидный конфиг. Починен (см. коммиты).

## Спека (эффект / сложность)

### P0 — подписанное авто-обновление geo-баз
Эффект: свежие geoip/geosite без MITM-риска; устраняет рассинхрон тегов после обновления
(правило ссылается на тег, которого нет в базе → тихий misroute).
Сложность: средняя. Манифест на minisign (инфра уже есть в core/ext), staged rollout,
rollback на предыдущую базу, CI-сверка тегов пресетов с новой базой до публикации.
Фильтр: без подписи авто-апдейт — слоп и дыра; так — честная безопасность.

### P1 — ASN-правила (engine.RuleASN)
Эффект: точная маршрутизация по оператору (банки, CDN, обход ASN VPN-детекторов).
Сложность: средняя. sing-box → `asn`, mihomo → `ASN` (+ship GeoLite2-ASN.mmdb/geoip.metadb),
Xray → честный отказ в рендере (нативной поддержки нет, эмулировать нельзя).
Фильтр: точный матчинг IP→ASN, ноль ложных срабатываний — не маркетинг.

### P1 — импорт rule-set'ов (sing-box .srs, clash/mihomo rule-providers)
Эффект: community-пакеты (anti-ads, streaming, банки) без ручного ввода.
Сложность: средняя. mihomo-часть уже починена этим коммитом; добавить: валидацию
(https, лимит размера, behavior), provenance в UI (URL, sha256, дата обновления),
единый формат импорта (URL → contract Rule{rule-set}).
Фильтр: только с показанным происхождением и хешем, иначе — слепой слоп.

### P1 — конструктор правил с честной семантикой
Эффект: порядок правил, детект затенённых (shadowed) правил, dry-run «какое правило
сработает для домена/IP».
Сложность: средняя. Фильтр: минимализм — без «умных пресетов», только точные
механики; dry-run обязан совпадать с движком (тесты на рендерах).

### P2 — CI-сверка тегов пресетов с базами
Эффект: честные гарантии вместо «вроде работает»: какие geosite-теги пресетов есть
в shipped dat и SagerNet .srs.
Сложность: низкая.

### P2 — ASN-датасорс с честной атрибуцией
Эффект: актуальные ASN без MaxMind. Сложность: низкая (Loyalsoldier weekly / DB-IP Lite).

## Вычеркнуто фильтром слопа
- Time-based правила: маркетинговая фича, реальная ценность ~0.
- Multihop entry/exit в UI: дублирует существующие proxy chains (F8).
- MaxMind GeoLite2 напрямую: лицензионный геморрой (см. находку 2).
- «Fastest server» по пингу в один клик: маркетинговые цифры; у sora уже честные замеры.
- WiFi SSID-матчеры: перекрыто сетевыми профилями (F5).

## Коммиты
- ffdf453 `[net-rd] mihomo: render rule-providers for RuleRuleSet https URLs`
  (core/engine/mihomo/rules.go, config.go, render.go, rules_test.go): RULE-SET-правила
  теперь получают секцию rule-providers (type http, behavior classical, format по
  расширению: mrs/yaml/text, interval 86400, дедуп по URL, теги sora-ruleset-N);
  не-https URL — ошибка рендера, как в sing-box. Тесты: 4 новых, все зелёные;
  go build + go vet чистые.
- sora-legacy не трогал: та же дыра RULE-SET есть в
  sora-legacy/core/engine/mihomo/rules.go — рекомендую применить аналогичный фикс.
- Чужой падающий тест TestRenderAnyTLSProxy (AnyTLS в mihomo/proxy.go, другая зона) —
  не мой, не чинил.
