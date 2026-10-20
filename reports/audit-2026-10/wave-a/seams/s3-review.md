# S3 — независимое ревью фиксов кластера совместимости стыков (packaging/updates)

Ревьюер: независимый агент (не автор коммитов). Метод: каждое утверждение
автора (`s3-packaging-updates.md`) проверялось по коду и исполняемыми
прогонами в `/tmp`; репозитории не модифицировались (Go-тест для legacy —
через `-overlay`, файл теста в `/tmp`). Ветка в обоих репозиториях —
`bugfix/audit-2026-10-19`.

Сводка вердиктов:

| Коммит | Вердикт |
|---|---|
| sora `3860be97` install.sh binary-mode SHA256SUMS | **ПРИНЯТ** |
| sora `924f2201` nfpm-app: pkexec+minisign | **ПРИНЯТ** |
| sora `b14a97d7` postremove: таблица `sora_nfqws` | **ПРИНЯТ С ЗАМЕЧАНИЯМИ** (та же дыра осталась для третьей таблицы ядра — `sora_ingress`, см. §3) |
| legacy `375cb10a` zapret: дайджесты tpws/nfqws в SHA256SUMS | **ПРИНЯТ** (мелкие замечания, §4) |
| legacy `9fc03a7a` README: шаг zapret build | **ПРИНЯТ** |

Общее по всем пяти: `git show --stat` — каждый коммит трогает ровно один
заявленный файл, посторонних hunks нет; молчаливых фолбэков ни один фикс не
вводит (подробно по пунктам ниже).

---

## 1. sora `3860be97` — install.sh: binary-mode SHA256SUMS — ПРИНЯТ

Дифф: одна строка в `packaging/install/install.sh` — паттерн
`grep -E "  \\*?$name\$"` заменён на `grep -E " [ *]$name\$"` + комментарий.

Проверка остальных читателей (по коду):

- Dart, `app/lib/src/updates.dart:172`: `^([a-fA-F0-9]{64}) [ *](.+)$`,
  имя сверяется полностью (`match[2] == name`), дубль → ошибка.
  Принимает обе формы; тест `app/test/updates_test.dart:178` прямо
  закрепляет ` *install.sh` как валидный вход.
- Хелпер `sora-update`, `packaging/linux/sora-update:120` (awk):
  `length($1)==64`, hex-проверка, `substr($0,67)==name || =="*" name`,
  `count!=1` → die. Принимает обе формы (позиция 67 — начало имени в обеих
  раскладках: 64 hex + пробел + ` `/`*`).
- `packaging/install/install.ps1`: `^([0-9a-f]{64})\s+\*?name$` —
  `\s+` съедает 1–2 пробела, `\*?` — маркер. Обе формы.

Исполняемый round-trip (скрипт в `/tmp`, фикстуры — реальные файлы,
манифесты сгенерированы `sha256sum` / `sha256sum -b`):

- Новый паттерн install.sh: text-mode (`<hash>␣␣<name>`) — OK,
  binary-mode (`<hash>␣*<name>`) — OK, в обоих случаях последующий
  `sha256sum -c --quiet expected` проходит.
- Старый паттерн на binary-mode: FAIL на обоих файлах — дефект автора
  воспроизведён.
- Эквиваленты Dart-regex, awk хелпера и ps1-паттерна на тех же фикстурах:
  обе формы принимаются всеми тремя — утверждение «остальные 3 парсера
  форму принимают» верно.

Мусор (тот же прогон, цепочка grep + `sha256sum -c` целиком):

- hash длиной 63 и 10, не-hex hash из 64 символов, префиксное слово перед
  валидным hash, строка `x *<name>`: grep такие строки пропускает (паттерн
  сам по себе hash не валидирует — так было и до фикса), но
  `sha256sum -c` их все отвергает → die, установка не происходит.
- `<hash>␣␣*<name>` (два пробела + `*`): grep пропускает за счёт сдвига
  совпадения, `sha256sum -c` отвергает (имя файла буквально `*<name>`).
- Один пробел, таб, неверный mode-символ (`?`), суффикс после имени,
  имя с продолжением (`.evil`): отвергаются уже grep-ом.
- Дубликат «хорошая + плохая» строки одного имени: обе попадают в
  `expected`, `sha256sum -c` падает → fail-closed.
- Верхний регистр hex в binary-mode принимается и grep-ом, и
  `sha256sum -c`. Это не обход: hash обязан совпасть с содержимым файла,
  регистр hex семантику не меняет (Dart тоже допускает `A-F`).

Замечание (не дефект фикса, пре-существующее): `$name` в grep-паттерне не
экранирован (точки версии — regex-метасимволы). Обхода это не даёт:
манифест подписан minisign до этого шага, а `sha256sum -c` проверяет
буквальное имя из строки манифеста — подложенное имя файла на диске просто
не найдётся.

Итог: фикс точечный, семантика совпала со всеми остальными читателями,
fail-closed цепочки (подпись → grep → `sha256sum -c`) не ослаблена.

## 2. sora `924f2201` — nfpm-app: pkexec и minisign — ПРИНЯТ

Дифф: только `packaging/linux/nfpm-app.yaml`, overrides трёх форматов:
deb += `pkexec, minisign`; rpm += `polkit, minisign`;
archlinux += `polkit, minisign`. Файл — правильный: хелпер
`sora-update` поставляется именно пакетом приложения
(`nfpm-app.yaml`: `src: ./packaging/linux/sora-update` →
`/usr/lib/sora/sora-update`); в core-пакете (`nfpm.yaml`) хелпера нет.
YAML валиден (разобран парсером), формат списков соответствует принятому в
обоих nfpm-файлах репозитория; `sora-core` в каждом override сохранён —
nfpm-override заменяет, а не дополняет top-level depends, потери нет.

Действительно ли нужны обе утилиты в shipped-пути:

- `minisign`: хелпер, `packaging/linux/sora-update:51,55` —
  `command -v minisign || die`, затем `minisign -V` для проверки
  SHA256SUMS. Жёсткий die, без фолбэка. Также нужен `install.sh`, но тот
  пакетом не поставляется и честно умирает с сообщением — не этот шов.
- `pkexec`: сам хелпер его не вызывает — он вызывается через него:
  Dart `app/lib/src/updates.dart:703,877` — `_run('/usr/bin/pkexec',
  [updateHelper, ...])`; `_canElevate` (строки 307–312) требует файл
  `/usr/bin/pkexec`; policy
  `packaging/linux/io.github.levvs-one.sora.update.policy` аннотирует
  `exec.path=/usr/lib/sora/sora-update`. Утверждение коммита корректно.
- Имена пакетов по форматам верны: в Debian/Ubuntu `pkexec` — отдельный
  пакет (в `polkitd` бинаря нет), `minisign` — отдельный пакет; в
  rpm-мире (Fedora/openSUSE) отдельного пакета `pkexec` нет, бинарь даёт
  `polkit`; в Arch — также `polkit`, `minisign` существует. Подмена
  deb-варианта на rpm/arch была бы ошибкой — автор её не сделал.

Пробег остальных внешних вызовов хелпера (`sora-update` целиком):
`id, cut, mktemp, chmod, rm, cp, grep, awk, sed, sha256sum, uname` —
coreutils/grep/gawk-класс essential-утилит базовой системы, в этом
репозитории пакетами не декларируются нигде (и core-пакет их не
декларирует); `dpkg-query/dpkg-deb/apt-get` (deb-ветка),
`rpm/dnf/zypper` (rpm-ветка), `pacman` (arch-ветка) — инструменты самого
формата, которым пакет установлен. Отдельно arch-ветка хелпера сама
ставит `gst-plugins-good` через `pacman -S` — этот пакет в
arch-зависимостях nfpm-app уже был до фикса. Других неявных внешних
зависимостей уровня minisign/pkexec (не-essential, с жёстким die) не
найдено.

Нюанс вне объёма коммита: демон polkitd на deb остаётся лишь
`recommends` у sora-core; при установке с `--no-install-recommends`
pkexec не сможет авторизоваться — но Dart тогда честно уходит в
`manualCommand`, а не умирает внутри хелпера. Не блокирует принятие.

## 3. sora `b14a97d7` — postremove: таблица `sora_nfqws` — ПРИНЯТ С ЗАМЕЧАНИЯМИ

Что верно:

- Имя таблицы подтверждено по коду исполнителя:
  `core/engine/bypass/nfqws_queue.go:32` — `const nftTable = "sora_nfqws"`;
  `nfqws_linux.go` создаёт `add table inet sora_nfqws` и при остановке
  удаляет её сам (`Sweep`). Адресация в postremove — та же форма
  (`nft delete table inet sora_nfqws`), что и существующая строка для
  kill switch (`inet sora`, `core/guard/nftables.go:16`).
- Синтаксис: `sh -n` — OK. Прогон с записывающим fake-`nft`:
  вызываются ровно `delete table inet sora` и
  `delete table inet sora_nfqws` (ср. замечание ниже про третий вызов —
  это уже не этот коммит).
- Отсутствие таблицы / отсутствие или сбой `nft` не валит скрипт:
  строка закрыта `2>/dev/null || true`, как и соседняя; прогон с
  `nft`, возвращающим 1, — exit 0. На upgrade (`upgrade|1`) скрипт
  выходит до nft-строк — на апгрейде живая таблица не сносится, верно.

**Замечание (та же дыра, третья таблица).** Посылка авторского отчёта
(§ РАЗРЫВ-7: «ядро при остановке снимает обе свои таблицы») фактически
неверна: таблиц у ядра три. `core/guard/ingress_nftables.go:17` —
`nftIngressTable = "sora_ingress"`, ingress-защита включена по умолчанию
(`core/guard/ingress.go`, `DefaultIngressConfig` — `Enabled: true`) и
подключается безусловно (`core/cmd/sora-core/main.go:239`,
`guard.WithIngress(firewall, guard.DefaultIngressConfig())`). Её chain
заканчивается `counter drop` для входящего трафика. Сценарий дефекта
— зеркальный чинимому: `packaging/linux/scripts/postremove.sh` в
коммите `b14a97d7`

1. ядро убито -9 при поднятых kill switch + ingress (обычная сессия с
   подключением — ingress ставится вместе с kill switch);
2. пакет удаляется: preremove не может остановить уже мёртвую службу,
   postremove снимает `inet sora` и теперь `inet sora_nfqws`, но
   `inet sora_ingress` остаётся;
3. итог: после удаления пакета в системе живёт таблица с drop-входящих
   (кроме loopback/tunnel/established/LAN-исключений конфигурации на
   момент убийства) без владельца и без сервиса, который её снимет.

Точная недостающая строка в `packaging/linux/scripts/postremove.sh`
(после строки про `sora_nfqws`):
`nft delete table inet sora_ingress 2>/dev/null || true`.

Почему не ОТКЛОНЁН: добавленная строка сама по себе корректна, заявленную
в сообщении коммита таблицу чинит полностью, регрессий не вносит. Но
шов «postremove как страховка убитого ядра» коммитом не закрыт до конца,
а авторский фрагмент подаёт его как закрытый.

P.S. на момент написания ревью: в рабочем дереве (не в коммите
`b14a97d7`) другим агентом уже внесено незакоммиченное изменение в тот же
файл, добавляющее ровно строку про `sora_ingress` с корректным
комментарием (`git status`: ` M packaging/linux/scripts/postremove.sh`).
К ревьюируемому коммиту оно не относится; при мерже стоит убедиться, что
оно дойдёт до коммита, а не потеряется в общем дереве.

## 4. legacy `375cb10a` — zapret build: дайджесты в SHA256SUMS — ПРИНЯТ

Дифф: только `packaging/zapret/build.sh` (+14/−1): убрана копия
`$dest/zapret/LICENSE.txt`, добавлен append-блок дайджестов tpws/nfqws в
`$dest/SHA256SUMS` той же конструкцией
(`sha256sum | sed "s|$dest/<name>|<name>|"`), что и в main-репозитории
(`packaging/zapret/build.sh` в sora пишет так в `engines.digests`) —
паритет подтверждён сравнением файлов.

Строгая ветка `verifyTpws` действительно достигается:

- `core/engine/registry/registry.go:102-114`: `LoadDigests` →
  `digests["tpws"]`; нет записи → кандидат принимается (прежнее
  поведение); запись есть и digest не совпал → `""` (бинарь
  дисквалифицирован); совпал → кандидат.
- До фикса `fetch.sh` писал SHA256SUMS только по 5 файлам
  (`sing-box xray mihomo geoip.dat geosite.dat`, `(cd "$dest" &&
  sha256sum ... > SHA256SUMS)` в `packaging/engines/fetch.sh`), zapret
  дайджестов не дописывал → записи `tpws` не было никогда → строгая
  ветка была мёртвой. После фикса запись есть в каждом пакетном
  манифесте (nfpm кладёт `./dist/engines/SHA256SUMS` в
  `/usr/lib/sora/engines/SHA256SUMS`).
- Формат дописываемых строк совпадает с парсером: эмуляция обоих
  скриптов в `/tmp` (fetch создаёт манифест, затем append-блок из
  коммита, dest — и относительный, и абсолютный) даёт строки вида
  `<64-hex>␣␣tpws` / `<64-hex>␣␣nfqws` — тот же формат, что пишет
  fetch.sh. `supervise.LoadDigests` (`core/engine/supervise/binary.go`)
  парсит через `strings.Fields`, требует длину digest 64, срезает
  префикс `*` и берёт `filepath.Base` имени — обе формы (text/binary)
  и голое имя `tpws` принимает; это закреплено и существующими тестами
  (`TestDiscoverWithManifestVerifies` — двухпробельная форма;
  `TestVerifyTpwsChecksTheManifestWhenItListsTpws` — match/mismatch/
  нет записи/нет манифеста). Дополнительно прогнан исполняемый тест
  через настоящий `verifyTpws` (Go `-overlay`, тест-файл в `/tmp`,
  репозиторий не тронут): манифест ровно в формате append-блока коммита
  (`<hash>␣␣tpws` + `<hash>␣␣nfqws`) — совпадающий tpws принимается,
  подменённый после записи манифеста бинарь отвергается (строгая ветка),
  отсутствующий манифест по-прежнему допускается. Результат: PASS
  (вместе со всеми подтестами существующего
  `TestVerifyTpwsChecksTheManifestWhenItListsTpws`).

Про отсутствие SHA256SUMS — честно по коду, с уточнением к формулировке
задания: для самих движков отсутствие/битость манифеста — fail-closed
(`Prober.Discover`: ошибка `LoadDigests` без `--allow-unverified-engines`
→ ошибка discovery; тесты `TestDiscoverWithoutManifestFailsClosed`,
`...WithMalformedManifestFailsClosed`). Для tpws `verifyTpws` по дизайну
терпим: нет манифеста или нет записи → кандидат принимается (комментарий
в коде это прямо говорит, тест кейс «no manifest» закрепляет). Утечки из
этого не следует: `BypassAvailable()` требует `r.Usable()`, т.е. хотя бы
один верифицированный движок, а движков без манифеста нет. Фикс этой
семантики не меняет — он делает строгую ветку достижимой для
поставляемого tpws, что и заявлено.

Удаление LICENSE-копии — корректно: потребителей у
`$dest/zapret/LICENSE.txt` нет (grep по packaging/core/CI — пусто),
nfpm ставит лицензию напрямую из дерева:
`third_party/zapret/docs/LICENSE.txt` →
`/usr/share/licenses/sora-core/zapret-LICENSE.txt`
(`packaging/linux/nfpm.yaml`).

Мелкие замечания (не блокируют):

- Порядок пайплайна критичен и теперь задокументирован рецептом (§5):
  `fetch.sh` перезаписывает SHA256SUMS через `>`, поэтому zapret build
  обязан идти после fetch; повторный запуск fetch после zapret молча
  снёс бы дописанные строки обратно в lenient-режим. Комментарий в
  build.sh это фиксирует («This runs after fetch.sh… so it appends»).
- Повторный запуск build.sh без fetch допишет дубли строк tpws/nfqws.
  Для единственного потребителя (`LoadDigests`, map) безвредно:
  поздняя запись перезаписывает раннюю тем же (или новым, если бинарь
  пересобран) дайджестом.
- `sed`-паттерн с `$dest` не экранирован как regex: для dest со
  спецсимволами (`|`, `[`) подстановка могла бы не сработать. Все
  реальные вызовы используют `dist/engines`; та же конструкция — в
  main-репозитории. Паритет, не регрессия.

## 5. legacy `9fc03a7a` — README: шаг zapret build — ПРИНЯТ

Дифф: одна строка в `packaging/linux/README.md`, рецепт сборки:

```sh
packaging/engines/fetch.sh amd64 dist/engines
packaging/zapret/build.sh dist/engines   ← добавлено
SORA_ARCH=amd64 SORA_VERSION=0.3.0 nfpm package --config packaging/linux/nfpm.yaml …
```

- nfpm-конфиг legacy действительно требует выходы zapret build:
  `packaging/linux/nfpm.yaml` — `src: ./dist/engines/tpws`,
  `./dist/engines/nfqws`, `./dist/engines/zapret/fake/` (tree). До фикса
  рецепт их не производил: следование рецепту дословно умирало на шаге
  nfpm (нет src-файлов).
- Полнота рецепта после фикса: все src из nfpm покрыты — `dist/sora-core`
  (шаг go build), движки+geo+SHA256SUMS (fetch), tpws/nfqws/fake +
  дописанные дайджесты (zapret, и именно после fetch — критичный для
  §4 порядок соблюдён), остальное nfpm берёт из репозитория
  (service unit, sysusers, policy, лицензии, third_party).
- Паритет: в main-репозитории тот же рецепт
  (`packaging/linux/README.md:32-33`) содержит обе строки в том же
  порядке; CI main (`repository.yml`) также идёт fetch → zapret build.
  Legacy CI пакеты не собирает (прямо сказано в самом README), поэтому
  рецепт — единственный пакетный пайплайн legacy, и теперь он полон.

---

## Что не проверялось / ограничения ревью

- Реальная сборка пакетов nfpm и установка: nfpm в VM не установлен;
  состав и зависимости сверены по конфигам и записанному релизному
  манифесту из авторского фрагмента (§4.1 автора здесь не опровергнут).
- `test_update.py` целиком (нужен bwrap) — логика хелпера проверена
  чтением + точным awk-прогоном на фикстурах обеих форм.
- PowerShell-парсер: pwsh нет; паттерн install.ps1 проверен эквивалентной
  regex-семантикой на тех же фикстурах.
- Имена пакетов rpm/arch для minisign/polkit сверены по устройству
  дистрибутивов, локальная установка пакетов не выполнялась.
