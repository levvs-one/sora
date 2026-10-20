# TEAM-B — второй проход веб-разведки (2026-10-20)

Лид: перепроверка 5 Tier S новыми независимыми источниками + свежие релизы 5 конкурентов (май–окт 2026).

**Метод и оговорка:** субагенты недоступны на этой глубине (depth 2/2, can_spawn=no) — все 10 тем отработаны лидом напрямую: `browser.search`/`browser.open` + `git ls-remote`/`git log` по репозиториям (только чтение, код не менялся). Приоритет — первоисточники 2025–2026. Слоп отсечён.

---

## А. Перепроверка Tier S

### 1. NaiveProxy нативно в sing-box — ПОДТВЕРЖДЕНО (с уточнениями)

- Официальный changelog sing-box: **1.13.0 — "Add NaiveProxy outbound"**. Текущий dev — 1.15.0-alpha (git-теги; 1.14.3 вышел 10.10.2026).
- Реализация: `protocol/naive/outbound.go`, клиент `cronet.NaiveClient` из Go-биндингов **`0x676e67/cronet-go`** (репозитория `SagerNet/libcronet` не существует — sing-box отслеживает версию биндингов через `.github/CRONET_GO_VERSION` + `update_cronet.sh`). Биндинги живые (интеграционные тесты против живого sing-box).
- Билд-тег `with_naive_outbound` включён в официальных релизных пайплайнах по умолчанию.
- Ограничения из исходников: строгая валидация TLS (запрещены insecure/disableSNI/custom ALPN — иначе ломается фингерпринт); UDP только через UoT; QUIC/HTTP/3 поддерживается с выбором congestion control (BBR/BBRv2/Cubic/Reno).
- Форк amnezia-box (hoaxisr) тоже добавил NaiveProxy outbound в своей ветке 1.13.x.
- **Вердикт:** правда, работает нативно. Уточнение к первому проходу: в upstream — только с 1.13.0; имя биндингов — 0x676e67/cronet-go. Цена для sora прежняя: доставка libcronet + синхронные обновления с Chromium, иначе фингерпринт протухнет и станет детект-сигналом.

### 2. XHTTP downloadSettings: матрица совместимости — ПОДТВЕРЖДЕНА (с поправкой про sing-box)

- Официальная матрица Xray (xtls.github.io → Transport): `xhttp`+`reality` = **Supported**; `websocket`+`reality` = **Not supported**; `httpupgrade`+`reality` = **Not supported**; `mkcp`+`reality` = **Not supported**.
- XHTTP несовместим с XTLS-Vision (материал XTLS-экосистемы, habr, май 2026); защита от TLS-in-TLS — через xmux + сплит up/down.
- `downloadSettings` существует в исходниках Xray-core (`transport/internet/splithttp/config.proto`) — отдельная секция настроек download-пути (адрес/домен независимо от upload).
- **Поправка к первому проходу:** upstream sing-box **не** имеет нативного xhttp-транспорта. Nexora docs: "sing-box apps: yes, except xhttp and mkcp". Форки ремаппят xhttp→httpupgrade (прецедент: пакет `singbox_mm` на pub.dev — "remapped xHTTP/httpupgrade", с оговоркой о расхождении семантики с Xray split-http). Нативный xHTTP есть у форка mihomo (xinebf/mihomo).
- Прецедент импорта: v2rayN desktop парсит xhttp-"extra" из share-ссылок (коммит ноя 2025).
- **Вердикт:** матрица из TIER S #12 верна для Xray. Но "полное покрытие движков (Xray + sing-box + mihomo)" — неверно для sing-box: XHTTP реален на Xray (+ mihomo-форк); sing-box — только через форк/ремаппинг. Для sora: downloadSettings = Xray-движок; варнинги WS+REALITY и XHTTP+Vision в UI — обязательны.

### 3. Доверенные сети (IVPN-модель) + captive portal (Speedify) — ПОДТВЕРЖДЕНО первоисточниками

- IVPN, официальный блог: per-SSID статусы **trusted/untrusted/none**; действия при подключении (автоконнект на untrusted, автоотключение на trusted, вкл/выкл firewall); дефолт для новых сетей настраивается, рекомендация — **'untrusted'**.
- Код: IVPN Android app (open source) — Network Protection (`NetworkCommonFragment.kt`): требует background location (Android 10+) для идентификации WiFi-сетей; состояния trusted / mobile data / default.
- Speedify, официальный блог: при captive portal — уведомление → попап окна логина → трафик к порталу выводится мимо туннеля → после логина возвращается в туннель; остальной трафик тем временем держится на cellular (channel bonding). Маркетинговое "only VPN that…" — слоп, механика — задокументирована.
- **Вердикт:** IVPN-модель копируется 1:1 (дефолт untrusted). Captive portal по механике Speedify — ниша без конкурентов среди прокси-клиентов, воспроизводимо.

### 4. Geneva «Strategy Tuner» — оригинал ПОДТВЕРЖДЁН, живые форки НЕ подтверждены

- Оригинал: CCS 2020 (Bock, Hughey, Qiang, Levin) — генетический алгоритм поверх 4 примитивов (drop, tamper, duplicate, fragment); тесты против реальных цензоров CN/IN/KZ; код открыт (geneva.cs.umd.edu).
- Диссертация Kevin Bock (2022): strawman-рандом не нашёл **ни одной** рабочей стратегии до ручной помощи (и то 1 за 100k особей) — научное обоснование, что чистый случайный поиск не работает, нужен GA с фитнесом («работает + не ломает TCP + минимальность»).
- Официальный сайт UMD прямо предупреждает: обучение многократно триггерит цензуру, стратегии детектируемы — честные ограничения, совпадающие с выводами первого прохода.
- **Не подтверждено:** форк «Просвет» и другие живые форки 2025–2026 поиском не найдены. Репозиторий Kkevsterrr/geneva существует.
- **Вердикт:** научная база реальна; bounded-перебор в клиенте инженерно sound. Но живых форков как готового кода в этом проходе нет — фиксирую как открытый вопрос, а не факт.

### 5. CLI + action URL-схемы — ПОДТВЕРЖДЕНО

- Mullvad CLI (mullvad.net, гайд под версию 2026.1): `connect` / `disconnect` (флаг `-w`/`--wait`), `relay set location`, `status` (`-v`), `auto-connect set`, `lockdown-mode set`, `lan set`, `account`, `tunnel set ipv6`; коды выхода 0/1 (CLI-референс mintlify).
- Tailscale CLI: `up/down/set/login/logout/switch/status/ping/ssh/file/cert/netcheck/exit-node/update/whois/drive` (вывод `tailscale -h`).
- URL-схемы у OSS прокси-клиентов — **только import**: Clash Verge Rev обрабатывает `clash://` и `clash-verge://` (deep linking, tauri.conf.json); Hiddify — deep-link импорт, причём в 4.x добавили **подтверждение импорта против SSRF** (security fix — паттерн для sora, у неё тоже app_links). Управляющих схем (`connect`/`disconnect`/`toggle`) ни у кого не найдено.
- **Вердикт:** утверждение первого прохода стоит. Дополнительно: SSRF-подтверждение deep-link у Hiddify — обязательный паттерн при реализации `sora://` action-схемы.

---

## Б. Свежие релизы (май–окт 2026)

### 6. Nekoray / NekoBox — свежих релизов НЕТ

- Desktop nekoray (MatsuriDayo/nekoray): последний тег **4.0.1 (2024)** — проект фактически dormant.
- Android NekoBox (MatsuriDayo/NekoBoxForAndroid): последний релиз **1.4.2 (09.02.2026)** — вне окна 3–6 мес. Ближайшее заметное: on/off shortcuts для автоматизаций (янв 2026).
- **Вердикт:** смотреть не на что; экосистема MatsuriDayo стагнирует. Для sora — окно возможности, а не угроза.

### 7. v2rayNG — 2.3.12 (18.10.2026): активный мейнтенанс, без прорывов

- Теги: 2.3.10 (01.10) → 2.3.11 (11.10) → 2.3.12 (18.10.2026); сборки в основном пре-релизные.
- Заметное за месяцы (git log): DNAT DNS-запросов от LAN-резолверов на публичный IP (#6298, root-режим); изоляция fallback в policy groups (#6283); WireGuard-фичи из нового ядра + поле remoteDNS в UI (#6290/#6230); регулярные обновления AndroidLibXrayLite; Kotlin 2.4.21 / Gradle 9.8.1.
- Смежное, важное: **v2rayN desktop 7.24.4 (06.10.2026) — security fix: MitM-уязвимость в даунлоадере ядер + удалён allowInsecure**. Урок для sora (update-ux, TIER A #19): цепочка доставки движков должна проверяться подписью, иначе тот же класс бага.
- **Вердикт:** зрелый мейнтенанс, новых протоколов/механик нет; naive по-прежнему отсутствует.

### 8. Hiddify — v4.1.2 (окт 2026): самый насыщенный релиз среди пяти

- Теги: v4.0.4 → v4.0.5 → v4.1.0 → v4.1.1 → v4.1.2.
- Новое в 4.1.x (release notes GitHub): **proxy chains в UI** ("chain quick settings", ChainTimelineHeader) — конкурент фичи sora F8 уже в проде; **Vaydns со сканером и multi-resolver**; описания balancer-стратегий для пользователя; подтверждение deep-link импорта против SSRF; тип эндпоинта `awg` в редакторе конфигов; Liquid Glass иконки (iOS/macOS); фиксы gRPC-стрима и лимитов памяти iOS VPN-расширения.
- Issue #2371: в 4.1.1 сломана подпись LaunchAtLoginHelper на Intel macOS 12.7.6 — напоминание про матрицу тестирования старых macOS (актуально и для sora).
- **Вердикт:** Hiddify обгоняет по chains и DNS-фичам. Их SSRF-подтверждение deep-link и описания balancer-стратегий — готовые UX-паттерны для sora.

### 9. Streisand — ПРОБЕЛ: репозиторий iOS-клиента не идентифицирован

- Все находки ведут на StreisandEffect/streisand (ansible-деплой серверов, dormant с ~2017).
- Публичного GitHub-репо iOS-клиента «Streisand» (App Store; в RU-гайдах упоминается как open-source с «zero data collection, robust DNS control») в этом проходе найти не удалось — ни релизов, ни кода. В отчёте первого прохода (WEB-RESEARCH.md) «streisand» вообще не упоминается — тема была задана без базы.
- **Вердикт:** не покрыто. Нужен отдельный заход (App Store metadata / bundle id / поиск по разработчику), либо снять тему как неподтверждённую.

### 10. Karing — v1.2.26.2908: пулемётный темп патчей, тот же стек, что sora

- Последний тег v1.2.26.2908; GitHub latest → v1.2.25.2802 (окт 2026). 662 тега / 26 релизов — релизы почти ежедневно, changelogs на 1–2 строки ("Fixed VLESS node config errors…").
- Стек: **Flutter + sing-box GUI**, 15.6k stars — прямой конкурент sora по технологическому стеку.
- Важно: лицензия в репозитории — **«Other (NOASSERTION)»**, не стандартный OSS-текст. Для позиционирования sora («best open-source», чистая лицензия) — готовый дифференциатор.
- Заметных фич за окно из публичных notes не извлекается (changelogs пустые) — честно фиксирую, не выдумываю.

---

## В. Поправки к первому проходу

1. Naive outbound в upstream sing-box — **с 1.13.0** (не «уже давно»); биндинги — **0x676e67/cronet-go** (не SagerNet/libcronet — такого репо нет).
2. XHTTP: upstream sing-box **не** поддерживает xhttp-транспорт (только ремаппинг в форках). «Полное покрытие движков» из TIER S #12 для sing-box неверно — XHTTP реален на Xray (+ mihomo-форк).
3. Форк Geneva «Просвет» — **не подтверждён**; не использовать как факт.
4. Тема «Streisand» задана без базы: в WEB-RESEARCH.md первого прохода совпадений ноль; iOS-клиент как репозиторий не найден.

---

## Источники (ключевые, приоритет — первоисточники 2025–2026)

- https://sing-box.sagernet.org/changelog/ — 1.13.0: Add NaiveProxy outbound; 1.13: Wi-Fi state, ECH query_server_name, kTLS
- https://deepwiki.com/SagerNet/sing-box/4.4-vpn-endpoints-and-network-extensions — protocol/naive/outbound.go, cronet-go, тег with_naive_outbound
- https://deepwiki.com/0x676e67/cronet-go/6-testing — биндинги, интеграционные тесты
- https://xtls.github.io/en/config/transport.html — официальная матрица transport+security
- https://habr.com/en/articles/990208/ — XHTTP: нельзя с Vision, можно с REALITY; сплит up/down
- https://deepwiki.com/lhear/Xray-core/4.3-splithttp-transport — downloadSettings в config.proto
- https://docs.nexora-panel.org/protocols/vmess — "sing-box apps: yes, except xhttp and mkcp"
- https://pub.dev/packages/singbox_mm/changelog — ремаппинг xHTTP в sing-box-производных
- https://www.ivpn.net/blog/new-trusted-wi-fi-networks-feature-for-ivpn-apps/ — модель доверенных сетей
- https://speedify.com/blog/fast-bonding-vpn/how-to-use-always-on-vpn-captive-portals/ — механика captive portal
- https://geneva.cs.umd.edu/posts/code-release/ — релиз кода Geneva, дисклеймеры
- https://kevinbock.phd/pdf/2022-dissertation.pdf — strawman-тест (рандом не работает)
- https://mullvad.net/fa/help/how-use-mullvad-cli — CLI-гайд (2026.1)
- https://www.mintlify.com/mullvad/mullvadvpn-app/cli/commands/disconnect — коды выхода CLI
- https://deepwiki.com/clash-verge-rev/clash-verge-rev — clash:// deep linking
- https://github.com/2dust/v2rayNG/releases + git log 2.3.10→2.3.12
- https://botmonster.com/self-hosting/v2rayn-security-update-downloader-mitm/ — v2rayN 7.24.4 MitM-фикс
- https://github.com/hiddify/hiddify-app/releases — v4.1.x: chains, Vaydns, SSRF-подтверждение
- https://github.com/hiddify/hiddify-app/issues/2371 — сломанная подпись на Intel macOS
- https://github.com/KaringX/karing (+ /releases/latest) — v1.2.26.2908, лицензия NOASSERTION
