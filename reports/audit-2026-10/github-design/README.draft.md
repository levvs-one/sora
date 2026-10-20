# Sora

[English](README.en.md)

[![Latest release](https://img.shields.io/github/v/release/levvs-one/sora)](https://github.com/levvs-one/sora/releases)

Открытый VPN-клиент для Windows и Linux. Работает с подпиской вашего VPN-провайдера: вставьте ссылку, выберите сервер, подключитесь.

![Главное окно Sora в светлой теме](docs/images/home-1440x900-light.png)

<details>
<summary>Тёмная тема</summary>

![Главное окно Sora в тёмной теме](docs/images/home-1440x900-dark.png)

</details>

## Установка

Windows 10 1809+ или Windows 11, x64. В PowerShell:

```powershell
irm https://github.com/levvs-one/sora/releases/latest/download/install.ps1 | iex
```

Linux x64: Debian, Ubuntu, Fedora, openSUSE, Arch. В терминале:

```sh
curl -fsSL https://github.com/levvs-one/sora/releases/latest/download/install.sh | sh
```

Скрипты проверяют контрольные суммы и устанавливают приложение со службой. Нужны права администратора. Для ручной установки — страница [релизов](https://github.com/levvs-one/sora/releases).

## Быстрый старт

1. Вставьте ссылку подписки.
2. Выберите сервер.
3. Нажмите «Подключить».

## Возможности

- Протоколы обхода блокировок: REALITY, XHTTP, AmneziaWG, Hysteria2; DPI-фрагментация.
- Три движка на выбор: sing-box, Xray, mihomo.
- Подписки с автообновлением: автовыбор сервера с наименьшей задержкой, трафик, срок действия, объявления провайдера.
- TUN-адаптер или системный прокси; kill switch; сплит-туннелинг по сайтам, IP-адресам и приложениям.
- На Linux — zapret-режим без сервера для части блокировок. IP-адрес не скрывает, VPN не заменяет.
- Диагностика в один клик: HAR, PCAPNG, журналы Windows; автообновления; 31 язык интерфейса.
- Расширения: подписанные дополнения расширяют возможности клиента.

## Документация

- [Установка, обновление и удаление](docs/install.md)
- [Как пользоваться](docs/usage.md)
- [Форматы подписок и информация для провайдеров](docs/providers.md)
- [Если что-то не работает](docs/troubleshooting.md)
- [Как устроена Sora](docs/architecture.md)
- [Разработка и сборка](docs/development.md)
- [История изменений](CHANGELOG.md)
- [Планы](PLANS.md)

## Лицензия

[GPL-3.0](LICENSE). [Лицензии сторонних компонентов](THIRD-PARTY-NOTICES.md).
