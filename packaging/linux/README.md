# packaging/linux

Пакеты .deb, .rpm и для Arch собираются [nfpm](https://github.com/goreleaser/nfpm) из двух описаний:

- `nfpm.yaml`: пакет `sora-core`, служба с ядрами и zapret;
- `nfpm-app.yaml`: пакет `sora`, приложение. Зависит от `sora-core` той же версии.

| Путь | Пакет | Что это |
| --- | --- | --- |
| `/usr/bin/sora-core` | sora-core | служба |
| `/usr/lib/sora/engines/` | sora-core | sing-box, Xray, mihomo, ByeDPI, tpws, nfqws, geoip.dat, geosite.dat |
| `/usr/lib/systemd/system/sora-core.service` | sora-core | unit, см. [service/linux](../../service/linux/README.md) |
| `/usr/lib/sysusers.d/sora.conf` | sora-core | пользователь и группа `sora` |
| `/usr/share/polkit-1/actions/io.github.levvs-one.sora.policy` | sora-core | доступ к службе для активной сессии |
| `/usr/share/licenses/sora-core/` | sora-core | лицензии |
| `/usr/lib/sora/app/`, `/usr/bin/sora` | sora | приложение |
| `/usr/lib/sora/sora-update` | sora | helper установки проверенной пары пакетов |
| `/usr/share/polkit-1/actions/io.github.levvs-one.sora.update.policy` | sora | обновление с паролем администратора |
| `/usr/share/applications/io.github.levvs_one.sora.desktop` | sora | ярлык, обработчик ссылок `sora://` и `happ://` |
| `/usr/share/icons/hicolor/scalable/apps/io.github.levvs_one.sora.svg` | sora | значок |

Скрипты в `scripts/`: после установки создаётся пользователь `sora`, служба включается и запускается; перед удалением служба останавливается; после удаления снимается таблица nftables `sora`, если она осталась.

## Сборка

```sh
cd core && CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o ../dist/sora-core ./cmd/sora-core && cd ..
packaging/engines/fetch.sh amd64 dist/engines
packaging/zapret/build.sh dist/engines
SORA_ARCH=amd64 SORA_VERSION=1.0.6 nfpm package --config packaging/linux/nfpm.yaml --packager deb --target dist/

cd app && flutter build linux --release --dart-define=SORA_VERSION=1.0.6 && cd ..
SORA_ARCH=amd64 SORA_FLUTTER_ARCH=x64 SORA_VERSION=1.0.6 nfpm package --config packaging/linux/nfpm-app.yaml --packager deb --target dist/
```

`--packager rpm` и `--packager archlinux` собирают остальные форматы. Для нативной
сборки ARM64 используются `SORA_ARCH=arm64`, `SORA_FLUTTER_ARCH=arm64` и
`flutter build linux --release --target-platform=linux-arm64`. Для amd64
значение Flutter-архитектуры - `x64`, имя архитектуры пакета - `amd64`.

Для Linux amd64 и ARM64 `fetch.sh` проверяет хеш официального архива ByeDPI
v0.17.3 и помещает бинарник и MIT-лицензию в пакет core. Это локальный
SOCKS-бэкенд для TCP, а не системный пакетный фильтр; его стратегии не
гарантируют обход блокировок в каждой сети.

На ARM64 runner CI получает официальный Flutter 3.47.6 из исходников с проверкой
revision `5fc346839b5d0eef006ed8404392afb4dfae428d`, поскольку официальный Linux SDK
archive содержит только x64. Штатный bootstrap этого revision загружает ARM64
Dart и engine с официального storage. Версия SDK и зависимости приложения не
меняются. До упаковки проверяется ELF machine каждого бинарника и `.so` в bundle,
а нативный WebKitGTK-тест открывает подписанный тестовый пакет расширения.

Это сборка и проверка пакетов, а не публикация или подтверждение полного ARM64
цикла установки/обновления. `install.sh` выбирает обязательную пару core+app
для обеих архитектур и отказывает до установки при отсутствии одного пакета.
Приложение выбирает архитектуру своей Dart VM через штатный `dart:ffi Abi`, а
привилегированный snapshot - архитектуру установленного Go-бинарника. Helper
сверяет нативную архитектуру ОС, подписанный target и метаданные пакета. Для
amd64 и ARM64 используются свои имена пакетов при скачивании, подготовке
rollback cache и откате; перехода к другой архитектуре при отсутствии пакета нет.
Неподдерживаемый ABI отвергается до скачивания пакетов и установки. Смешанные архитектуры
и эмуляция не являются проверенным сценарием. `PLANS.md` остаётся открытым до поставки.

ARM64 CI запускает тесты signed-metadata/download/rollback, нативный Go snapshot
и helper в приватных namespaces с перехватом запросов ОС и пакетного менеджера.
Это проверки контрактов, а не реальная смена версии системы, проверка питания
или свидетельство поддержки всех дистрибутивов.

CI собирает все форматы в каждом pull request. На одноразовых Ubuntu runners
amd64 и ARM64 выполняется настоящий `install.sh` с собранной парой core+app.
Проверяются версии и архитектуры обоих установленных deb-пакетов, ELF приложения,
активность службы и handshake с авторизованным QueryLogs через Unix socket.
Используется существующий Go-клиент стенда под служебным UID `sora`; это не
проверка доступа обычной desktop-сессии или подключения установленного Flutter UI.
Подпись установочных тестовых данных создаётся временным ключом, отдельный
verifier доверяет ему только в тесте; корень установленной production-службы
не меняется. Лог установки сохраняется отдельным CI artifact.
Fedora и Arch проверяются реальной установкой только на amd64. Проверки ARM64
обновления и rollback выше остаются проверками контрактов, а не реальной сменой
установленной версии или восстановления после потери питания.

Обновление в приложении использует GitHub Releases и SHA256SUMS. Helper копирует оба пакета в закрытый root-каталог, повторно проверяет хеши, имена и версии пакетов и передаёт всю пару одному вызову пакетного менеджера. Действие polkit требует `auth_admin` в любой сессии, без сохранения разрешения. Если helper или pkexec отсутствует либо авторизация отклонена, приложение сохраняет проверенные загрузки и показывает команду для терминала. Первая установка новой функции поверх старого пакета без helper использует этот ручной путь.

Без установки пакетов и обращения к установленной службе helper проверяется командой `python3 packaging/linux/test_update.py -v`. Нужен bubblewrap с доступными user namespaces; в тесте пакетные менеджеры заменены регистраторами аргументов, файловая система хоста доступна только для чтения, `/run` изолирован.
