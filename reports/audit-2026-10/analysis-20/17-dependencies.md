# Аналитик №17: зависимости и supply chain

Репозиторий: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`.
Дата анализа: 2026-10-20. Версии апстримов сверены через GitHub API и proxy.golang.org.

---

## Вердикт

Гигиена supply chain — **выше среднего по open-source**: SHA-пины Actions, `engines.lock` с SHA-256 на каждый бинарник, `engines.sig` с честной фиксацией «подписей нет», provenance-документация `third_party`, осознанный холд grpc-go. Это сильная сторона.

Но есть **три реальные проблемы**:

1. **Xray протух функционально, а не косметически.** Пин `v26.3.27` отстаёт от апстрима (`v26.10.17`) на ~4 месяца, и идёт активный uTLS-кризис: даже свежий Xray шлёт ClientHello Chrome 133 вместо 155 и детектится ТСПУ (XTLS/Xray-core#7131). Для anti-censorship клиента в РФ это не «технический долг», это деградация основной функции.
2. **Сканеры уязвимостей и dependabot не видят половину монорепо.** `service/sync` и `app` (pub) выпадают из govulncheck, osv-scanner и dependabot.
3. **Remote rule sets sing-box тянутся с tip ветки без пина и без проверки целостности** (`core/engine/singbox/render.go:20-21`) — компрометация двух репозиториев SagerNet = подмена правил маршрутизации у всех пользователей.

Обновляемость движка спроектирована честно, но дорого (ручная правка lock + версионные ассёрты в тестах) — именно поэтому Xray и протух.

---

## Сильные стороны

1. **GitHub Actions полностью SHA-запинены** с комментариями версий: `actions/checkout@d23441a… # v6`, `setup-go@40f1582b… # v5`, `osv-scanner-action@375a0e8e… # v2.3.1`, `codeql-action@d0bae162… # v3`, `golangci-lint-action@4afd733a… # v8` и др. (`.github/workflows/*.yml`). Плавающих тегов нет.
2. **`packaging/engines/engines.lock`** — одна строка на движок+архитектуру: `engine arch sha256 url`. `fetch.sh` качает только по HTTPS (`--proto '=https'`), сверяет SHA-256 и падает закрыто при расхождении.
3. **`packaging/engines/engines.sig`** — честная матрица методов проверки: `xray dgst-crosscheck`, `mihomo none`, `sing-box none`, с явной пометкой, что у mihomo и форка sing-box подписей нет вообще. `fetch.sh` при `method=none` пишет предупреждение, при `dgst-crosscheck`/`cosign` падает закрыто, если проверку провести нельзя.
4. **`THIRD-PARTY-NOTICES.md`** — таблица всех компонентов: версии, лицензии, ссылки на исходники. `third_party/README.md` — provenance пребилд-блобов WinDivert с SHA-256 (закрытие SORA-L8).
5. **Осознанный холд grpc-go 1.83.2**: dependabot.yml документирует, что 1.84 несёт GO-2026-6443 («fixed on 1.83.2 and on the 1.85 development line»). Это не протухание, это решение.
6. **Оборона в глубину в CI** (`.github/workflows/security.yml`): govulncheck (reachable, не граф), OSV, CodeQL, dependency-review на PR, gitleaks, крон 4 раза в сутки.
7. **Rule providers требуют `https://`** (`core/engine/mihomo/rules.go:95` — `registerRuleProvider` отвергает не-https). Дефолтных удалённых провайдеров в коде нет — URL приходит из плана пользователя.
8. **Свежесть точечных зависимостей**: `refraction-networking/utls v1.8.2` = последний релиз (2026-01-13), `flynn/noise v1.1.0` = последний, `hashicorp/mdns v1.0.7` = последний, `txthinking/socks5` пин = последний коммит. `tailscale/wf` закоммичен на HEAD (репо мёртв с 2024-02-14, см. проблему №11).
9. **Изоляция движков**: core не тянет sing-box/xray/mihomo как Go-модули — это внешние бинари, верифицируемые по `engines.digests` перед запуском. Компрометация Go-модуля движка невозможна по построению.
10. **Vendored webview-плагины корректны**: `app/pubspec.yaml:71-75` (`dependency_overrides`, пути относительны `app/`) указывают на существующие `app/third_party/webview_all_{linux,windows}` с собственным README о происхождении и объёме правок. Версия 1.4.4 = latest на pub.dev — дрейфа ноль.

---

## Слоп / проблемы

### P0

**1. Xray v26.3.27 протух на ~4 месяца + uTLS-кризис**
`packaging/engines/engines.lock:10-11,17,23` пинит `v26.3.27`. Апстрим на 2026-10-20: `v26.10.17` (релиз 2026-10-17). Между ними ~7 релизов.
Хуже: XTLS/Xray-core#7131 (открыт 2026-10-11) — Xray пинит utls `aa6edf4`, fingerprint `chrome` шлёт ClientHello **Chrome 133**, тогда как реальный Chrome — 155; в РФ такой fingerprint «по-видимому детектится и блокируется ТСПУ». Фикс — utls ≥ `6ebdceb` (HelloChrome_155, 2026-10-06), которого **нет ни в одном релизе Xray на сегодня**. Просто поднять пин до 26.10.17 кризис не закроет — нужен релиз Xray с новым utls, и это надо трекать отдельно, а не «обновить когда-нибудь».

**2. service/sync и app вне всех сканеров**
- `.github/workflows/security.yml:36` — `govulncheck ./...` с `working-directory: core`. `service/sync/go.mod` не проверяется.
- `.github/workflows/security.yml:48-49` — osv-scanner: `--lockfile=go.mod:core/go.mod` только. `service/sync/go.mod` и `app/pubspec.lock` не сканируются.
- `.github/dependabot.yml` — покрывает `/core` (gomod) и `/` (github-actions). Для `/service/sync` (gomod) и `/app` (pub) записей нет.
Итого: уязвимость в `miekg/dns`, `flynn/noise`, `hashicorp/mdns` или любом Dart-пакете не будет замечена автоматикой.

**3. Sing-box remote rule sets: tip ветки без пина и без digest**
`core/engine/singbox/render.go:20-21`:
```go
geoSiteRuleSetURL = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-%s.srs"
geoIPRuleSetURL   = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-%s.srs"
```
Скачиваются движком в рантайме (через `download_detour`, `render.go:434-444`), версия не зафиксирована, целостность не проверяется. Компрометация любого из двух репозиториев SagerNet (или MITM на raw.githubusercontent.com вне прокси) = тихая подмена правил маршрутизации у всех пользователей sing-box. Пользовательские rule-set URL (`render.go:500`) — та же механика, но там URL задаёт сам пользователь, это его выбор.

### P1

**4. sing-box-lx v1.14.3-lx.14: база свежая, форк отстал**
`packaging/engines/engines.lock:8-9,16,22`. База sing-box 1.14.3 вышла 2026-10-09 — свежо. Но тег форка `lx.14` против актуального `v1.14.3-lx.21` (2026-10-15): 7 релизов форка пропущено. Форк релизится почти ежедневно — вероятно мелкие фиксы, но какие именно, из lock'а не видно. Бонус-вопрос: какой utls внутри lx-сборок — если форк обновляет fingerprints быстрее Xray, это аргумент за него в контексте проблемы №1.

**5. Геобазы привязаны к винтажу Xray**
`packaging/engines/fetch.sh` берёт `geoip.dat`/`geosite.dat` из Xray-архива `v26.3.27` (август 2026). Геобазы протухают быстрее движков, а отдельного цикла их обновления нет: апдейт гео = апдейт Xray = правка lock + прогон версионных тестов. Сегодня пользователи получают гео двухмесячной давности.

**6. mihomo и sing-box-lx не публикуют подписей — остаточный риск честно зафиксирован, но не закрыт**
`packaging/engines/engines.sig`: оба — `none`. Защита — только SHA-256 из lock'а, который обновляется вручную. Подмена ассета на GitHub между ручными обновлениями lock'а не детектируется ничем, кроме внимательности мейнтейнера. Отсылка к FIX-PLAN.md §9 («owner decision: trust, switch upstream, or build from source») есть, но решения в репозитории не зафиксировано.

**7. Неточности THIRD-PARTY-NOTICES.md по лицензиям**
- mihomo помечен чистым «GPL-3.0», но апстрим добавляет условие: «any downstream projects not affiliated with MetaCubeX shall not contain the word `mihomo` in their names» (pkg.go.dev). Таблица приписывает naming-условие только sing-box-lx — непоследовательно.
- WinDivert-блобы (LGPLv3, `third_party/README.md`) не имеют отдельной строки в THIRD-PARTY-NOTICES.md. LGPLv3 требует поставки текста лицензии и возможности перелинковки/модификации библиотеки: проверить, что текст LGPLv3 лежит в пакете рядом с `zapret-LICENSE.txt`, а не только в исходниках апстрима.
- Само условие sing-box-lx («no derivative work may use the name or imply association without prior consent», поверх GPL-3.0-or-later) — не из разрешённых GPL §7 дополнительных условий, серая зона. Для sora некритично (только агрегация бинаря + дисклеймер в `NOTICE.md:7`), но формулировку в таблице («GPL-3.0-or-later с условием автора о названии») стоит оставить как есть — она честная.

### P2

**8. `mobile_scanner: ^5.2.3` при latest 7.4.2** (`app/pubspec.yaml:37`). Два мажора позади. Возможно осознанно (ломающие изменения API сканера), но комментария нет — через полгода никто не вспомнит, почему пин старый.

**9. `intl: any`** (`app/pubspec.yaml:34`). Единственная неограниченная зависимость. Сегодня резолвится в 0.20.3 (lock), воспроизводимость держится на lock-файле, но семантика «any» — слоп; `flutter_localizations` всё равно требует совместимый intl, так что диапазон можно зафиксировать.

**10. Пакеты без verified publisher на pub.dev**: `nativeapi` (lock 0.3.0, latest 0.5.2), `xdg_icons`, `webview_all`, `toastification`, `showcaseview`, `jovial_svg`, `flutter_markdown_plus`. Имена легитимны (typosquatting не обнаружен — все пакеты существуют и соответствуют назначению), но отсутствие verified publisher = выше риск тихого захвата неймспейса. `nativeapi` к тому же отстаёт (0.3.0 vs 0.5.2).

**11. `tailscale/wf` — заброшенный апстрим.** Пин `6fbb0a674ee6` (2024-02-14) = HEAD, новее ничего нет и не будет. Если там найдут CVE, фикса не будет — нужен план (форк/замена).

**12. Мелкое отставание `golang.org/x/*`**: `x/net v0.60.0` vs `v0.61.0` (2026-10-09), `x/crypto v0.57.0` vs `v0.58.0` (2026-10-09), `miekg/dns v1.1.72` (sync) vs `v1.1.73`. На один шаг позади, некритично; dependabot их подтянет.

**13. Обновление движка дорогое по построению.** `engines.lock` честно предупреждает: смена версии = URL + digest + «the tests of core/engine against the new build». Версионные ассёрты захардкожены в тестах (`core/engine/xray/logparse_test.go:13`, `core/engine/clashapi/client_test.go:49,55`, `core/engine/mihomo/logparse_test.go:9`, `core/engine/engine_test.go:93`). Это хороший контроль, но он же — причина протухания Xray: апдейт требует ручной работы в нескольких местах. Без снижения цены апдейта пины будут протухать снова.

---

## Ранжированные рекомендации

### P0 — сделать сейчас

1. **Xray: трекать uTLS-кризис как отдельную задачу, а не «обновить движок».** Подписаться на XTLS/Xray-core#7131; поднимать пин только до релиза, включающего utls ≥ `6ebdceb` (HelloChrome_155). До тех пор зафиксировать в `THIRD-PARTY-NOTICES.md`, что fingerprint `chrome` в 26.3.27 = Chrome 133 и детектится ТСПУ. Файлы: `packaging/engines/engines.lock`, `THIRD-PARTY-NOTICES.md`.
2. **Распространить сканеры на весь монорепо.** В `.github/workflows/security.yml`: добавить `govulncheck` для `service/sync` и `--lockfile` OSV для `service/sync/go.mod` и `app/pubspec.lock`. В `.github/dependabot.yml`: добавить `/service/sync` (gomod) и `/app` (pub).
3. **Запинить sing-box remote rule sets.** Варианты: URL с коммитом (`raw.githubusercontent.com/SagerNet/sing-geosite/<sha>/rule-set/...`) или проверка digest скачанного `.srs` в core перед передачей движку. Файл: `core/engine/singbox/render.go:20-21`.

### P1 — ближайший цикл

4. **Поднять sing-box-lx до актуального тега** (`lx.21` на 2026-10-20) и зафиксировать, какой utls внутри сборки — это влияет на приоритет проблемы №1.
5. **Отвязать геобазы от версии Xray**: отдельный пин `geoip.dat`/`geosite.dat` с SHA-256 и собственным (более частым) циклом обновления в `packaging/engines/`.
6. **Дописать THIRD-PARTY-NOTICES.md**: naming-условие mihomo; отдельная строка WinDivert (LGPLv3, происхождение — `third_party/README.md`); убедиться, что текст LGPLv3 поставляется в пакете рядом с `zapret-LICENSE.txt`.
7. **Зафиксировать owner-решение по неподписанным релизам** mihomo/sing-box-lx (FIX-PLAN.md §9 обещает): доверять SHA из lock'а, перейти на reproducible build из исходников со сверкой, или сменить апстрим. Сейчас решение висит в воздухе.

### P2 — гигиена

8. `mobile_scanner`: оценить переход 5.x → 7.x; если пин осознанный — комментарий в `app/pubspec.yaml:37`.
9. `intl: any` → конкретный caret-диапазон (`app/pubspec.yaml:34`).
10. План на случай CVE в `tailscale/wf` (заброшен): форк или замена.
11. Снизить цену апдейта движка: генерировать версионные ассёрты тестов из `engines.lock` (или один `engines_version_test.go`), чтобы бамп версии был правкой lock'а + прогоном, а не охотой по тестам.

---

## Что проверено и не стало проблемой

- Typosquatting в pubspec: все имена резолвятся в легитимные пакеты на pub.dev; `webview_all*`, `toastification`, `showcaseview`, `jovial_svg`, `nativeapi`, `xdg_icons`, `flutter_markdown_plus`, `mobile_scanner` — настоящие.
- `dependency_overrides` для webview-плагинов корректны (пути относительны `app/`, каталоги существуют, provenance задокументирована).
- Транзитивные Go-зависимости: `klauspost/compress` (BSD), `godbus/dbus` (BSD), `Microsoft/go-winio` (MIT), `gopacket` (BSD), `hashicorp/mdns` (MPL-2.0), `miekg/dns` (BSD), `flynn/noise` (BSD), `txthinking/socks5` (MIT — проверен текст лицензии) — конфликтов с GPL-3.0 нет.
- `mihomo v1.19.32` в lock'е = последний релиз апстрима (2026-09-30). Свежо.
- Дефолтный DNS-фолбэк `223.5.5.5` (Alibaba) в `core/engine/mihomo/rules.go:238-242` — только когда план пуст; задокументированное поведение, не скрытый выбор.
- `go 1.26.9` в обоих go.mod — актуальный тулчейн.
