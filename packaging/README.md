# packaging

| Каталог | Что собирается |
| --- | --- |
| [`windows`](windows/README.md) | установщик для Windows x64 (Inno Setup) |
| [`linux`](linux/README.md) | пакеты .deb, .rpm и для Arch (nfpm) |
| [`engines`](engines) | список сборок sing-box, Xray и mihomo с контрольными суммами и скрипт загрузки |
| [`zapret`](zapret) | сборка tpws и nfqws |
| [`install`](install) | установка с проверкой подписи: `install.sh` для Linux, `install.ps1` для Windows; нужен заранее доверенный проверяющий файл |

CI по тегу `v*` собирает черновик и `SHA256SUMS`. Подпись манифеста внешним ключом и доверенный путь первого запуска нужно подготовить до публикации. В опубликованном v1.1.2 их нет. Контракт и ограничения: [release signatures](../docs/security/release-signatures.md).
