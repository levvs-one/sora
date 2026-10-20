# UX списка серверов при тысячах серверов — web research

Дата: 2026-10-19. Запросов: 6 (Proton, v2rayNG/v2rayN, IVPN/Mullvad, Windscribe, Flutter-virtualization, Nekoray/NekoBox, Nord/PIA).

## 1. Что делают лучшие клиенты

**Общие паттерны у коммерческих клиентов** (Proton, Nord, PIA, Windscribe):
- **Избранное (favorites/★) — у всех.** PIA: сердечко у сервера, избранное всплывает наверх списка; Windscribe: отдельные списки избранных; Proton: избранные серверы + search; Nord: избранные страны. Это главный инструмент против «тысяч строк».
  - https://www.experte.com/vpn/pia&where&where&where&where
  - https://www.experte.com/vpn/windscribe&where
- **Recent / Quick Connect — у всех.** PIA: quick-connect list из последних 6 серверов на главном экране (флаги для one-tap подключения); Nord: «recent connections» под полем поиска; Proton: Quick Connect кнопка + smart suggestions.
  - https://privacyhq.com/vpn-reviews/private-internet-access/
  - https://screensdesign.com/showcase/vpn-by-private-internet-access
  - https://www.aivanet.com/2024/08/proton-vpn-review-a-scientific-approach-to-security/
- **Сортировка + поиск.** PIA: сортировка по имени / задержке / избранному + встроенный поиск; Nord: строка поиска по странам; Proton: поиск по серверам; Windscribe: поиск по списку. Сортировка по нагрузке (load) есть в ни у кого как явная опция — пользователи Proton массово просят (uservoice-тред, март–апрель 2026); вместо этого «Fastest server» = auto-подбор по load.
  - https://protonmail.uservoice.com/forums/932836-proton-vpn/suggestions/47609036-sort-by-server-load
  - https://www.cloudwards.net/how-to-use-proton-vpn/
- **Нагрузка (load %) и метрики в строке.** Proton: цветной индикатор нагрузки на сервере (зелёный/жёлтый/красный) в строке списка — пользователи читают его глазами вместо сортировки; Windscribe: load + пометка 10 Gbps throughput. У sora таких данных от провайдера нет (и не будет — чужие подписки), но идея «визуального прокси-метрики» применима к замеренным pинг/speed.
  - https://allaboutcookies.org/protonvpn-review
  - https://www.aivanet.com/2024/09/windscribe-review-build-your-own-plan-with-this-unique-vpn/
- **Группировка страна → город (drill-down).** Nord: выбор страны → конкретные локации внутри; Windscribe: «one of the broadest city-level targeting», выбор страны раскрывает список серверов/городов; Proton: «view servers by both country and city». Это иерархия, а не плоский список.
  - https://cybernews.com/best-vpn/nordvpn-vs-pia/
  - https://thebestvpn.com/reviews/windscribe-vpn/
- **Карта серверов.** Nord, Proton, PIA — интерактивная карта как альтернатива списку. Для коммерческих провайдеров карта — брендинг + выбор по географии.
- **Профили (saved configs).** Proton: «custom connection profiles» — сохранённый сервер + настройки под активность (стриминг, гейминг).
- **Mullvad — контрпример:** нет ни load, ни ping, ни fastest-кнопки, только фильтруемый список серверов (страна → город → сервер). Обзоры прямо называют это неудобством выбора («harder to choose the best server»). Урок: минимализм без метрик — это downgrade, не фича.
  - https://www.comparitech.com/es/vpn/reviews/mullvad-review/

**Паттерны прокси-клиентов (v2rayN, Nekoray/NekoBox, v2rayNG):**
- **Группы подписок как табы/границы управления.** v2rayN: одна подписка = одна группа; группы — вкладки над списком; Nekoray: proxies organized into groups as tabs. Фильтрация и сортировка применяются внутри группы. Принцип: «подписка = источник данных, группа = граница управления, фильтр = инструмент просмотра» (v2rayedge/v2ray6 гайды 2025–2026).
  - https://www.v2ray5.com/en/blog/articles/v2rayn-interface-walkthrough.html
  - https://www.v2ray6.com/en/handbook.html
  - https://deepwiki.com/MatsuriDayo/nekoray/5-main-window-and-core-ui
- **Batch-операции и multi-select.** v2rayN: тест реальной задержки по выделению/всей группе, сортировка по latency, удаление/копирование выделенных; Nekoray: moving, cloning, deleting profiles, group speedtest (TCP ping / URL latency / full test с latency+UDP+speed+IP info).
  - https://www.v2raychina.com/en/blog/articles/v2rayn-slow-speed-layered-check.html
  - https://deepwiki.com/bernard-xu/nekoray/5-main-window-and-core-ui
- **Столбцы-таблица на десктопе.** v2rayN: alias, address, protocol, transport, latency, group в колонках — на десктопе таблица информативнее карточек.
- **Автотесты не заменяют ручной выбор:** свежие гайды подчёркивают, что однократный ping-тест — не ранжирование навсегда; тесты протухают, нужна перепроверка при смене сети (совпадает с выводом competitor-analysis: «непрерывный re-test»).

**Техническая база (Flutter):**
- Виртуализация обязательна: `ListView.builder` / `SliverList` + `SliverChildBuilderDelegate` рендерят только видимое; `itemExtent` для фиксированной высоты даёт ~30% прирост; `shrinkWrap` с большими списками — запрет; `cacheExtent` 500–1000px.
  - https://dev.to/srfdeveloper/flutter-lists-grids-the-ultimate-scrolling-guide-2025-1ge4
  - https://copyprogramming.com/howto/flutter-populate-listview-from-a-list-code-example

## 2. Что есть у sora сейчас (servers.dart, прочтено)

- Секции по подпискам (collapsible headers, `_SubscriptionHeader`), порядок подписок сохраняется.
- Поиск (по имени, case-insensitive), сортировка ping / speed / name.
- Проба пинга (глобальная + по подписке), benchmark скорости.
- Строка «Авто» сверху, QR-скан, добавление подписки.
- Флаги из эмодзи в именах → PNG-флажки в строке; пинг и скорость в правой колонке строки.
- Overrides F6: hide/rename серверов поверх подписки.
- Группы одинаковых имён сворачиваются в одну строку (pickMember).
- **Нет:** избранного, recent-серверов, drill-down страна→город, multi-select, сохранённых профилей, карты.

## 3. Что sora должен перенять

| # | Фича | Откуда | Эффект | Почему |
|---|---|---|---|---|
| 1 | **Избранное (★) с закрепом наверх** — toggle в строке, секция «Избранное» поверх подписок, переживает обновления подписки (по устойчивому id, как overrides F6) | PIA, Windscribe, Proton, Nord | **high** | #1 инструмент против тысяч строк у всех коммерческих клиентов; у sora нет вообще |
| 2 | **Recent: последние N серверов** — горизонтальная лента/one-tap на home рядом с «Авто» (как флаги Quick Connect у PIA) | PIA (last 6), Nord (recent connections) | **high** | 80% подключений — к 3–5 серверам; убирает скролл из основного сценария |
| 3 | **Группировка по странам внутри подписки** — свернуть сотни серверов провайдера в «страна → города/серверы», использовать уже парсящиеся флаги; auto-подбор лучшего внутри страны | Nord, Windscribe, Proton | **high** | У sora сортировка уже есть, но нет иерархии; подписки Remnawave часто содержат 100+ серверов одной страны |
| 4 | **Визуальные бейджи качества в строке** — цветной индикатор ping/speed (зелёный/жёлтый/красный, как load-индикатор Proton) вместо голых цифр | Proton (load circles), Windscribe (speed indicator) | **medium** | Сканируется взглядом быстрее цифр; данные замеров у sora уже есть (latency/bandwidth в state) |
| 5 | **Multi-select + batch-операции** — выделить несколько → probe, скрыть, скопировать, удалить | v2rayN, Nekoray | **medium** | Power-user сценарий чистки подписок; десктопная таблица v2rayN показывает, что это ожидаемо на Windows/Linux |
| 6 | **Сохранённые профили «сервер + настройки»** — пресеты под активности (игры/стриминг), one-tap | Proton (connection profiles) | **medium** | Естественно ложится на уже запланированные сетевые профили (F5); отдельный маленький слой поверх избранного |
| 7 | **Поиск с хоткеем и подсветкой** — Ctrl/Cmd+F фокус на поиск (десктоп), debounce, подсветка совпадений | общий паттерн | **low/medium** | Дешёво, закрывает сценарий «нашёл среди 2000» |
| 8 | **Карта серверов** | Nord, Proton, PIA | **low** | Красиво, но для чужих подписок геолокация по IP ненадёжна; брендинг-эффект без функционального выигрыша против избранного/recent |
| 9 | **Сортировка по нагрузке (load)** | запросы юзеров Proton | **low** | Невозможна: sora не владеет серверами, провайдеры load не отдают; заменяется auto-подбором и бейджами из собственных замеров |

### Технические замечания (без кода, для планирования)
- Виртуализация уже правильная (`SliverList.separated` внутри `CustomScrollView`, строки фиксированной высоты 48/56). При добавлении секций «Избранное/Recent/Страны» держать всё в одном `CustomScrollView` со sliver-секциями, не плодить вложенные скроллы.
- Поиск сейчас O(n) по всем подпискам на каждый кейстрок — при тысячах серверов добавить debounce ~200мс и мемоизацию отфильтрованного списка.
- Пинг-проба тысяч серверов: v2rayN/NekoBox делают concurrent batch с прогрессом и отменой; у sora проба уже есть — проверить, что она батчится и отменяется, а не вешает UI.
- Избранное/recent хранить рядом с overrides F6 (per-subscription id + server id), переживать обновление подписки по стабильному идентификатору сервера, а не по имени (имена у провайдеров меняются).
