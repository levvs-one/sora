# Анализ №5: документация (docs/, README, examples)

Зона: `docs/` (13 md + `research/`), `README.md`, `README.en.md`, `examples/hello-panel`.
Ветка `bugfix/audit-2026-10-19`. Read-only анализ. POWER-RUN №10 сверял доки vs код —
здесь не дублируется, фокус: полнота, навигация, устаревшее, противоречия, честность.

---

## Вердикт

Документация **выше среднего для open-source**: честная про key ceremony, kill switch,
zapret-ограничения; FAQ без воды; примеры проверяются (`sha256sum -c` проходит).
Но есть **два privacy-критичных противоречия** (маскирование журнала по умолчанию
и «приложение не ходит в сеть»), **одно устаревшее утверждение** (Xray TUN на Windows),
и **системный разрыв**: волны фич F1/F5/F6/F8/F9/F11 добавили экраны в настройки,
но `docs/usage.md` их не описывает вообще. Позиционирование «no hidden telemetry»
недодоказано: нет реестра сетевых контактов (кто, куда и как часто ходит в сеть).

---

## Сильные стороны

1. **Честность там, где обычно врут.** `docs/security.md:32` прямо говорит, что
   key ceremony не проведена и установка отказывается продолжаться без ключа.
   `docs/extensions.md` §6: team key — placeholder, catalog checks fail closed.
   `docs/faq.md`: SmartScreen-предупреждение объяснено без замалчивания.
2. **FAQ — реальные вопросы, ноль воды.** 14 вопросов, все по делу (TUN vs прокси,
   что видит провайдер, zapret не прячет IP, ARM64, три ядра). Нет «Что такое VPN?».
3. **Ограничения заявлены вслух.** `docs/security.md:41`: провайдер VPN видит
   назначения; DNS по умолчанию — Cloudflare/Google (`docs/usage.md` § «DNS по
   умолчанию» — редкий для VPN-клиентов уровень честности). zapret: «IP не скрывает,
   VPN не заменяет» — и в README, и в faq, и в usage.
4. **Threat model для sync существует** (`docs/sync-threat-model.md`): активы,
   границы доверия, протокол, accepted risks, «What the app must do». Плюс честный
   бокс «Implementation status» — статус «не завired» совпадает с кодом
   (`app/lib/src/ui/sync.dart`: «the service is not launched or wired to the app yet»).
5. **Пример расширения целостен**: `examples/hello-panel/checksums.txt` верифицируется
   (`sha256sum -c` → OK), README примера честно говорит, что ключ throwaway.
6. **Навигация `docs/README.md`** — полный индекс по аудиториям (пользователи /
   провайдеры / разработчики / безопасность / исследования), R&D честно отделены
   («не руководство пользователя»).
7. `docs/android-vpnservice.md` — 211 строк спеки на несуществующий продукт, но с
   честной шапкой «спека к будущей разработке, клиента в коде нет». Не театр.

---

## Слоп / проблемы

### P0 — противоречия, бьющие по доверию

**1. Маскирование доменов в журнале: доки противоречат друг другу и коду**
- `docs/security.md:16`: «адреса и домены **по умолчанию** — хосты и IP заменяются
  на `[destination]`; запись доменов можно отключить в настройках журнала».
- `docs/faq.md:47`: «Домены и IP-адреса серверов **маскируются по умолчанию**;
  запись доменов можно отключить».
- `docs/troubleshooting.md:3`: «**домены сайтов по умолчанию записываются**,
  это можно выключить в настройках журнала».
- Код: `core/logs/logs.go:98-100` — `DefaultSettings()` = `RecordDestinations: true`
  («including destinations»); `logs.go:185` — маскирование применяется только при
  `RecordDestinations == false`. Сервис стартует с `logs.DefaultSettings()`
  (`core/cmd/sora-core/main.go:119`).
- **Итог: прав troubleshooting, неправы security.md и faq.md.** По умолчанию домены
  пишутся открытым текстом; переключатель «Record site addresses» их *включает*
  запись, а не «можно отключить» (формулировка инвертирована в обоих местах).
  Для страницы «Безопасность» это прямое завышение приватности.

**2. «Приложение не ходит в сеть» — неправда**
- `docs/security.md:38`: «**Приложение не ходит в сеть само.** Все сетевые запросы
  (подписки, обновления) выполняет служба; приложение общается только со службой
  по локальному сокету/каналу».
- Код: `app/lib/src/updates.dart:196,310` — приложение само делает HTTPS-запросы
  (`http.AbortableRequest('GET', ...)`, `User-Agent: Sora/<version>`) к
  `api.github.com` и скачивает релизы. Проверка обновлений — каждые 12 часов
  (`docs/usage.md` § «Обновление и трей»).
- **Итог: утверждение ложно.** Каждый запуск + каждые 12 часов приложение отдаёт
  GitHub свой IP, User-Agent с версией. Это не «телеметрия» в строгом смысле, но
  для позиционирования «no hidden telemetry» такой контакт обязан быть
  задокументирован в security.md, а не опровергаться им.

**3. Устарело: Xray TUN на Windows**
- `docs/usage.md:52`: «Xray на Windows работает в режиме прокси; TUN через Xray
  доступен на Linux».
- `CHANGELOG.md` § 1.0.10: «Xray поддерживает TUN в Windows через пакетный движок
  mihomo: gVisor, System, Mixed и MIPS, включая полные профили Xray в режиме "Авто"».
  Встроенный гайд в приложении (`app/lib/l10n/strings_en.dart`, modeGuide):
  «On Windows, Xray uses mihomo 1.19.32 or newer for all four TUN stacks».
- **Итог: usage.md устарел**, вводит в заблуждение при выборе ядра.

**4. Обещанная, но отсутствующая инструкция**
- `docs/security.md:32`: «Ручная проверка описана в [инструкции по установке]
  (install.md#windows)».
- `docs/install.md:27-29`: ручная проверка — только `Get-FileHash` (сравнение
  хэша, **без проверки minisign-подписи**). На Linux (`install.md:45`) — только
  `sha256sum -c`, тоже без подписи.
- **Итог: ссылка обещает процедуру проверки подписи, которой нет.** Либо дописать
  `minisign -Vm`, либо убрать ссылку.

### P1 — фичи без документации (экраны есть, docs/usage.md молчит)

Все ниже — реальные экраны в «Настройки» (`app/lib/src/ui/settings_screen.dart`):

| Фича | Код | В usage.md |
|---|---|---|
| F8 Proxy chains (именованные цепочки 2–3 хопа) | `ui/chains.dart`, settings:287 | 0 упоминаний |
| F5 Network profiles (авто-профили сети) | `ui/profiles.dart`, settings:282 | 0 упоминаний («профиль» встречается 1 раз — про JSON-профили провайдера, другое) |
| F1 QR share/scan подписки | `ui/qr.dart`, `ui/servers.dart:121` | 0 упоминаний; `providers.md` только про deeplinks |
| F11 zapret одновременно с VPN («DPI bypass for direct traffic») | `ui/modes.dart:269-271` | описан только режим «Без сервера»; про совместный режим ни слова |
| F6 Subscription override («My edits») | `ui/subscription.dart:170` | 0 упоминаний |
| DNS leak test (CheckDnsLeaks) | `ui/leaktest.dart` | 0 упоминаний |
| Расширения для пользователя (каталог, разрешения, sideload-риски) | `ui/extensions/` | только строка в таблице (`usage.md:21`); `extensions.md` — английский dev-spec, пользовательской доки нет, в т.ч. про `dangerous`-разрешения |
| Синхронизация устройств (F9) | `ui/sync.dart` | 0 упоминаний (честно, т.к. не заведено; но экран в настройках уже есть — пользователь упрётся в «реестр без спаривания» без объяснений) |

Дополнительно:
- `docs/install.md` (Linux): не сказано, что `/var/lib/sora` остаётся после
  `apt remove` (для Windows это сказано явно, `install.md:28`). Несимметрично.
- Встроенный гайд «Режимы/Ядра/TUN-стеки» в приложении (`strings.dart:1776`,
  переведён на все языки) новее и подробнее `docs/usage.md`, но usage.md на него
  не ссылается и местами противоречит (см. P0-3).

### P2 — навигация и пробелы threat model / privacy

1. **README-индекс неполный.** `README.md` § «Документация» ссылается на
   install/usage/troubleshooting/providers/architecture/development/security,
   но не на `docs/faq.md`, `docs/extensions.md`, `docs/android-vpnservice.md`,
   `docs/sync-threat-model.md`, `docs/stealth.md`. `docs/README.md` полный —
   индексы расходятся.
2. **Нет реестра сетевых контактов.** Для «no hidden telemetry» нужен раздел
   «кто и когда ходит в сеть»: проверка обновлений (приложение → api.github.com,
   каждые 12 ч, отключаемо), подписки (служба → URL провайдера, по расписанию),
   DoH по умолчанию (Cloudflare/Google), каталог расширений, `net.fetch`
   расширений (allowlist, аудит-лог), speedtest-сайты во встроенном браузере.
   Сейчас это размазано по трём страницам, часть — только в коде.
3. **Нет единого threat model продукта.** Есть `sync-threat-model.md` (только
   английский) и описательная `security.md` (что хранится/шифруется). Для
   security-аудитора нет одной страницы «модель угроз Sora».
4. **`sync-threat-model.md` и `extensions.md` — только на английском** при
   русскоязычной аудитории доков. Русские пользователи ставят расширения
   (с `dangerous`-разрешениями) без русскоязычного описания рисков.
5. **Расхождение с памятью проекта (требует проверки):** `MEMORY.md` утверждает,
   что F9 «redone for real: sync UI wired to the service/sync daemon», но код
   (`ui/sync.dart`, коммит `5bcc46f` — последний по файлу) и
   `sync-threat-model.md` единогласно говорят «not wired». Либо память опережает
   ветку, либо работа не вмержена — доки сейчас честны, но факт проверить.

### P3 — мелочи

- `docs/usage.md` «Клавиши»: `Ctrl+1..8` — в таблице разделов ровно 8, сходится. Ок.
- Якоря `usage.md#кнопка-режима`, `architecture.md#kill-switch`,
  `security.md#журнал`, `install.md#windows` — все существуют. Ок.
- `docs/faq.md`: нет вопросов «нужна ли регистрация/аккаунт?» (её нет — стоит
  заявить как фичу), «что уходит в сеть при проверке обновлений?»,
  «есть ли Android?» (честный ответ: пока нет, есть спека). Воды нет — это плюс,
  но 4 вопроса про приватность/сеть отсутствуют при privacy-позиционировании.
- `examples/hello-panel`: `id "org.sora.hello-panel"`, author «Sora Team», но
  подпись — throwaway-ключ (README примера это честно оговаривает). Подпись
  minisign не верифицирована здесь (нет бинаря) — только `checksums.txt` (OK).

---

## Ранжированные рекомендации

**P0 (доверие, сделать до релиза):**
1. Исправить `docs/security.md:16` и `docs/faq.md:47`: домены **записываются**
   по умолчанию; переключатель их *выключает* запись. Текст troubleshooting.md:3 —
   эталон.
2. Переписать `docs/security.md:38`: признать, что **приложение** проверяет
   обновления через api.github.com (каждые 12 ч, отключаемо в настройках) и
   скачивает релизы; добавить раздел «Сетевые контакты» (обновления, подписки,
   DoH по умолчанию, каталог расширений) — это и есть доказательство
   «no hidden telemetry».
3. Обновить `docs/usage.md:52`: Xray TUN на Windows доступен (через mihomo-мост,
   с 1.0.10); сослаться на встроенный гайд в приложении.
4. `docs/install.md`: добавить ручную проверку minisign-подписи
   (`minisign -Vm SHA256SUMS -x SHA256SUMS.minisig -p <ключ>`) для Windows и
   Linux — или убрать обещание из `security.md:32`.

**P1 (полнота):**
5. Дописать `docs/usage.md`: разделы «Цепочки», «Сетевые профили», «QR-шеринг»,
   «zapret вместе с VPN», «Проверка утечек DNS», «Мои правки подписки».
6. Написать русскую пользовательскую страницу расширений (каталог, разрешения
   и что значит `dangerous`, sideload-предупреждение) — сейчас только EN spec.
7. Синхронизировать README-индекс с `docs/README.md` (добавить faq, extensions,
   sync-threat-model).
8. `docs/install.md` (Linux): дописать про остающиеся данные `/var/lib/sora`
   при удалении, как на Windows.

**P2 (стратегия):**
9. Единая страница threat model продукта (или честный `PRIVACY.md`): активы,
   границы доверия, сетевые контакты, accepted risks. Сейчас есть только для sync.
10. Перевести `sync-threat-model.md` и пользовательскую часть `extensions.md`
    на русский — иначе privacy-доки недоступны основной аудитории.
11. FAQ: добавить «нужна ли регистрация», «что отправляется при проверке
    обновлений», «будет ли Android».
12. Проверить расхождение MEMORY.md vs код по F9 (wired/not wired) и либо
    обновить бокс в `sync-threat-model.md`, либо память.

---

## Проверено по коду (для воспроизводимости)

- `core/logs/logs.go:98-100,185`, `core/cmd/sora-core/main.go:119` — дефолт журнала.
- `app/lib/src/updates.dart:196,310` — сетевые запросы приложения.
- `app/lib/src/ui/settings_screen.dart:282,287,292` — экраны Profiles/Chains/Sync.
- `app/lib/src/ui/modes.dart:269-271` — zapretWithVpn.
- `app/lib/src/ui/servers.dart:121`, `app/lib/src/ui/sync.dart:38` — QR-скан.
- `app/lib/src/ui/subscription.dart:170` — override layer.
- `core/subscription/subscription.go:33` — User-Agent `sora-core/1` (providers.md ✓).
- `core/control/plan.go:785` — дефолтные DoH-резолверы (usage.md ✓).
- 32 `.arb`-файла — «32 языка» (README/usage ✓).
