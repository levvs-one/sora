# Протоколы сообщества

| Протокол | sing-box-lx | Xray | mihomo |
| --- | --- | --- | --- |
| mieru | Нет | Нет | Да, 1.19.32 |
| NaiveProxy HTTPS / QUIC | Да, 1.14.3-lx.14 | Нет | Нет |
| olcrtc | Да, через olcrtc | Да, через olcrtc | Да, через olcrtc |

## mieru

Импортируются [официальные ссылки mieru](https://github.com/enfein/mieru/blob/v3.38.1/docs/client-install.md): `mierus://user:password@host?profile=Name&port=443&protocol=TCP` и полный protobuf-конфиг `mieru://base64`. Обе ссылки можно вставить в добавление подписки или прочитать из QR. Приложение сохраняет регистр base64 полного конфига. HTTPS-подписки принимают обычные и base64-списки, а Clash YAML принимает `type: mieru`.

Поддерживаются TCP и UDP, `port` или `port-range`, `username`, `password`, `multiplexing`, `handshake-mode`, `traffic-pattern` и отдельный Clash-флаг пересылки `udp`. Параметры сверены с [адаптером mihomo 1.19.32](https://github.com/MetaCubeX/mihomo/blob/v1.19.32/adapter/outbound/mieru.go). Пары `port` и `protocol` в `mierus://` могут повторяться. Каждый binding и сервер полного конфига становится отдельным выбираемым сервером Sora; TCP и UDP на одном порту не считаются дубликатами. Настройки локальных слушателей и управления полного клиентского конфига не импортируются.

Закреплённый адаптер mihomo использует штатный MTU 1400. Ссылки с явным `mtu=1400` и полные профили с этим значением импортируются; другой MTU и встроенный dialer официального клиента не доступны в адаптере и отклоняются. Неизвестные параметры, неверные диапазоны, несовпадающее число портов и транспортов и неверные значения multiplexing отклоняются. Имена и пароли URL-декодируются один раз. Дополнительный процесс mieru в Sora не запускается.

## NaiveProxy

Принимаются `naive+https://user:password@host:443/#Name`, `naive+quic://user:password@host:443/#Name` и sing-box JSON с `type: naive`. Формат учётных данных соответствует [v2rayN NaiveFmt](https://github.com/2dust/v2rayN/blob/master/v2rayN/ServiceLib/Handler/Fmt/NaiveFmt.cs), заголовки CRLF соответствуют [NaiveProxy USAGE](https://github.com/klzgrad/naiveproxy/blob/master/USAGE.txt). Поддерживаются вставка одиночной ссылки, QR и обычные/base64-подписки. Порт по умолчанию 443. `pass@host` задаёт только пароль, `user:@host` задаёт только имя.

Сохраняются username/password, SNI, QUIC, `extra-headers` и `insecure-concurrency`. В JSON используются `extra_headers`, `insecure_concurrency`, `tls.enabled`, `tls.server_name`, `tls.certificate`. Дополнительные заголовки сохраняются в хранилище секретов и маскируются в журналах. TLS проверяется Cronet. `insecure`, произвольный ALPN, uTLS, REALITY и TLS fragmentation этим outbound не поддерживаются и отклоняются. Параметр ссылки `padding` не имеет соответствия в sing-box и тоже отклоняется; padding wire protocol согласуется самим Cronet. Прочие расширенные параметры sing-box, не представленные в плане Sora, не игнорируются при импорте.

Используется [закреплённый sing-box-lx 1.14.3-lx.14](https://github.com/Leadaxe/sing-box-lx/releases/tag/v1.14.3-lx.14). В Linux amd64/arm64 Cronet уже связан статически с musl. Windows amd64 получает `libcronet.dll` из того же архива, проверенного по SHA-256 в `engines.lock`; библиотека ставится рядом с `sing-box.exe`. Версии движка и библиотеки обновляются вместе. Purego-сборки sing-box Linux ищут `libcronet.so` рядом с executable, в `LD_LIBRARY_PATH`, `/usr/local/lib` и `/usr/lib`; Sora не наследует `LD_LIBRARY_PATH` в дочерний движок. Windows ищет DLL рядом с executable и в `PATH`. Предварительная проверка реальной конфигурации Naive удостоверяет загрузку библиотеки при обнаружении движков. Windows 7/386 не имеет Cronet и не получает эту возможность.

### Обновление Cronet в пакетах

Исходный sing-box 1.14.2 и поставляемый форк закрепляют bindings `cronet-go` на `0d28acc44093`, а платформенные библиотеки на `c10c03c318db`. Это проверяется по [go.mod sing-box 1.14.2](https://github.com/SagerNet/sing-box/blob/v1.14.2/go.mod) и [go.mod sing-box-lx](https://github.com/Leadaxe/sing-box-lx/blob/v1.14.3-lx.14/go.mod). Совпадения имени файла недостаточно для совместимости: загрузчик регистрирует конкретный набор символов Cronet и NaiveProxy. При обновлении нужно брать библиотеку из того же проверенного архива движка, а затем повторять native-проверку и межпротокольные тесты.

В закреплённом Windows-пакете `libcronet.dll` занимает 9529344 байта, SHA-256 `3217c6260fbca5f16072e0b79735742f40109a63bb0ff88fd6b96dd6b54a2928`. Установщик уже включает все файлы каталога движков. В Linux дополнительных библиотек и записей пакета не требуется: обе поставляемые архитектуры используют статический ELF. Это сохраняет существующие XHTTP и AmneziaWG без второго бинарника NaiveProxy.

## Выбор движка и защита

Auto выбирает mihomo для mieru и sing-box с работающим Cronet для NaiveProxy. Ручной несовместимый выбор отклоняется до остановки текущего соединения. Один план со смесью mieru и NaiveProxy отклоняется: общего поддерживающего движка нет. Ошибки используют существующие ключи `core.plan.*` и `core.subscription.*`. Протокол и транспорт передаются существующими protobuf-полями, остальные параметры остаются за credential reference в core.

Бинарники firewall guard не меняются. Трафик mieru создаёт mihomo, а NaiveProxy и Cronet работают внутри sing-box. Для строгого восстановления учитываются все порты диапазона mieru и реальный внешний транспорт: TCP/UDP для mieru, TCP для Naive HTTPS и UDP для Naive QUIC. Разрешения остальных процессов не расширяются. Политика ограничена 65536 endpoint-записями; превышение отклоняется до применения защиты.

## Локальная проверка новых протоколов

`core/engine/interop/community-servers.sh <каталог>` скачивает только тестовые Linux amd64 серверы: официальный mita 3.38.1 и Caddy 2.11.7-naive из релизов автора NaiveProxy. SHA-256 закреплены в скрипте. Они не входят в поставку приложения.

```sh
cd core
bash engine/interop/community-servers.sh /tmp/sora-community-servers
SORA_ENGINES_DIR=/path/to/packaged/engines SORA_COMMUNITY_SERVERS_DIR=/tmp/sora-community-servers \
  unshare -Urn bash -c 'ip link set lo up; go test -v ./engine/interop -run TestCommunityServersCarryRealTraffic -count=1'
```

Проверяются HTTP через настоящий mieru TCP/UDP и Naive HTTPS/QUIC, отказ неверных паролей и отсутствие секретов в логах. TLS-сертификат тестового Caddy создан на время теста и явно доверен Cronet; проверка сертификата не отключается. Это проверка proxy path, не захвата пакетов через TUN. Реальная Windows и Linux arm64 здесь не исполнялись.

# olcrtc

Sora поддерживает клиентские URI v1 из [документации upstream](https://github.com/openlibrecommunity/olcrtc/blob/f3ad8fb7c0d0fa981423f83269526fa94077c23d/docs/uri.md). Вставьте одиночную ссылку в поле добавления подписки или импортируйте QR. HTTPS-подписки принимают обычный и base64-кодированный текст. Комментарий после `$` становится именем сервера, `##name:` из [формата подписок v1](https://github.com/openlibrecommunity/olcrtc/blob/f3ad8fb7c0d0fa981423f83269526fa94077c23d/docs/sub.md) переопределяет его.

Поддерживаются Jitsi, Яндекс Телемост и WB Stream; транспорты datachannel, vp8channel, seichannel и videochannel. Параметры `<key=value&...>` соответствуют URI v1. Допускается percent-encoding полей, `+` сохраняется. Старые `video-bitrate` и `video-hw` игнорируются согласно upstream. Неизвестные параметры и некорректные ключи отклоняются.

Jitsi требует URL комнаты HTTPS, включая самостоятельные инстансы. У Телемоста не работают datachannel и seichannel, у WB Stream datachannel не работает в гостевом режиме. Sora отклоняет эти сочетания до замены текущей сессии. Имена и адреса комнат должны совпадать с сервером.

`#name:`, `#refresh:`, `#used:` и `#available:` читаются из метаданных подписки. Объёмы используют десятичные kb/mb/gb/tb. Парсер принимает интервал от 5 секунд до 365 дней; планировщик Sora ограничивает его сверху 30 днями. Ручной интервал имеет прежние ограничения Sora. `##name:` относится только к предыдущей успешно разобранной URI. Цвета, иконки, время обновления провайдера, отдельные квоты узлов и `##ip:` не меняют оформление или маршрутизацию Sora. Поле `##ip:` не заменяет адрес SFU. Одиночная ссылка хранится как локальная подписка с отключённым автообновлением.

## Соединение

Auto выбирает установленный совместимый sing-box, Xray или mihomo. Ручной выбор проверяется до остановки текущего соединения. Каждый используемый olcrtc outbound запускает отдельный процесс, максимум 32 комнаты на сессию. Основной движок подключается к случайному порту SOCKS5 на 127.0.0.1 с отдельными случайными логином и паролем. Готовность проверяется через SOCKS5-аутентификацию. Ключ, комната и транспорт хранятся за ссылкой на секрет в core; protobuf-поля не добавлялись.

Работают системный прокси и TUN. Upstream olcrtc переносит только TCP: TUN не добавляет UDP, игры и голосовые вызовы через этот протокол могут не работать. UDP не отправляется напрямую при отказе olcrtc. Другие явно заданные маршруты сохраняются.

Конфигурация записывается в `client.yaml` с правами 0600 в отдельной директории 0700 внутри приватного home сессии. На Windows файлы наследуют приватную DACL каталога службы, как хранилище секретов Sora. После остановки процесс завершается и файл удаляется. Linux `/dev/stdin` читается upstream, но общий для Linux и Windows путь используется для единообразной очистки. Процесс получает только путь файла. Ключ и локальные пароли маскируются в выводе.

Ошибки передаются через существующие `core.engine.*` и `core.plan.*`. У процесса ограниченный бюджет перезапусков. Ошибка повторного запуска не считается восстановленным соединением. При локальной проверке upstream datachannel после принудительного завершения клиента повторный handshake в той же комнате иногда завершался тайм-аутом. В таком случае требуется повторное подключение; защита от утечки остаётся включённой до явного отключения.

## Защита сети

SFU и ICE выбирают адреса после входа в комнату. В strict mode Windows разрешает динамические назначения только установленному `olcrtc.exe` под аккаунтом службы. На Linux nftables использует существующую границу выделенного UID службы: для сессии olcrtc разрешается исходящий трафик этого UID, включая core и другие его процессы. Трафик прочих UID остаётся заблокирован. Поэтому strict mode olcrtc на Linux не ограничивает служебный UID фиксированными адресами серверов. При переходе на другой протокол исключение убирается. На Windows бинарник из `SORA_OLCRTC_BIN` для strict mode должен находиться в установленном каталоге движков под именем `olcrtc.exe`.

## Сборка и совместимость

Используется неизменённый [upstream f3ad8fb7c0d0fa981423f83269526fa94077c23d](https://github.com/openlibrecommunity/olcrtc/tree/f3ad8fb7c0d0fa981423f83269526fa94077c23d): OLC2, smux v2, OLVC v5 для видеотранспортов. Старые форматы шифрования не поддерживаются. Оба конца должны использовать совместимые сборки. Проект архивирован, релизов нет, лицензия WTFPL; README объявляет EoL и перенос разработки в snolc. Поддержка исправлений upstream не обещана.

`packaging/engines/fetch.sh` проверяет SHA-256 архива и собирает Linux amd64/arm64 и Windows amd64 с Go 1.27.3, `-mod=readonly`, `-trimpath`, `CGO_ENABLED=0`, без VCS-метаданных. Зависимости проверяются через upstream `go.sum` и стандартную sumdb Go, в том числе модуль с Codeberg. При недоступности источника сборка завершается ошибкой. Рядом с бинарником поставляется JSON с ревизией и SHA-256 для обнаружения без запуска: upstream не имеет команды версии. Windows 7 не поддерживается.

## Воспроизведение локальной проверки

`core/engine/olcrtc/live_test.go` использует настоящие olcrtc и LiveKit. Прямой режим upstream `auth.provider: none`, `engine.name: livekit` позволяет обойти внешнюю систему получения токенов и запустить локальный SFU. Это параметр испытания, не расширение URI v1.

Задайте `SORA_OLCRTC_BIN` с JSON-манифестом рядом, `SORA_ENGINES_DIR`, `SORA_LIVEKIT_BIN`, `SORA_LIVEKIT_CONFIG`, `SORA_LIVEKIT_TOKENS`. Последний файл содержит две строки JWT, выданные официальным `github.com/livekit/protocol/auth` для идентичностей сервера и клиента в одной комнате. В конфигурации LiveKit используется порт 17880 и доступный в изолированной сети IP. Для ICE нужна нелокальная loopback-интерфейсу адресация, например dummy-интерфейс 10.202.0.1/24 в `unshare -Urn`.

```sh
cd core
unshare -Urn bash -c 'ip link set lo up; ip link add olc-test type dummy; ip addr add 10.202.0.1/24 dev olc-test; ip link set olc-test up; go test -v ./engine/olcrtc -run "TestReal|TestLocal" -count=1'
```

Проверяются HTTP через каждый основной движок и реальный локальный WebRTC, аутентификация SOCKS, права файлов, сообщение об остановке процесса и удаление конфигурации. Внешние Jitsi, Телемост и WB Stream этим испытанием не проверяются.
