<p align="center">
  <img src="docs/images/logo-512.png" width="96" alt="Логотип Sora">
</p>
<h1 align="center">Sora</h1>

[English](README.en.md)

[![Release](https://img.shields.io/github/v/release/levvs-one/sora)](https://github.com/levvs-one/sora/releases)
[![Downloads](https://img.shields.io/github/downloads/levvs-one/sora/total)](https://github.com/levvs-one/sora/releases)
[![License](https://img.shields.io/github/license/levvs-one/sora)](LICENSE)

Открытый VPN-клиент для Windows и Linux. Работает с подпиской вашего VPN-провайдера: вставьте ссылку, выберите сервер, подключитесь.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/home-1440x900-dark.png">
  <img src="docs/images/home-1440x900-light.png" alt="Главное окно Sora" width="1440">
</picture>

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

Для более старых систем — отдельный клиент [sora-legacy](https://github.com/levvs-one/sora-legacy).

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

## Безопасность

- Релизы сопровождаются `SHA256SUMS` — установочные скрипты проверяют контрольные суммы до установки.
- Подлинность релизов: подпись minisign (`SHA256SUMS`) и контрольные суммы файлов; без валидной подписи установка и обновление не продолжаются.
- Автообновления проверяют контрольные суммы скачанных файлов.
- Телеметрии нет: Sora ничего не отправляет разработчикам и третьим сторонам.

Подробности — в [docs/security.md](docs/security.md).

## Документация

- Пользователям: [установка](docs/install.md), [использование](docs/usage.md), [решение проблем](docs/troubleshooting.md).
- Провайдерам: [форматы подписок](docs/providers.md).
- Разработчикам: [архитектура](docs/architecture.md), [сборка из исходников](docs/development.md).
- Безопасность: [модель приватности и данные](docs/security.md).

Полный указатель документации — в [docs/](docs/).

## Лицензия

[GPL-3.0](LICENSE). [Лицензии сторонних компонентов](THIRD-PARTY-NOTICES.md).
