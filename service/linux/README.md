# service/linux

Системные файлы службы `sora-core` для Linux. Код службы лежит в `core/cmd/sora-core`.

| Файл | Куда ставится | Что делает |
| --- | --- | --- |
| `sora-core.service` | `/usr/lib/systemd/system/` | служба от пользователя `sora` с ограничениями systemd |
| `sora.sysusers` | `/usr/lib/sysusers.d/sora.conf` | пользователь и группа `sora` |
| `sora.policy` | `/usr/share/polkit-1/actions/io.github.levvs-one.sora.policy` | разрешение для активной локальной сессии |

Как это работает:

- Служба работает от пользователя `sora`, а не от root. Ей даны только `CAP_NET_ADMIN`, `CAP_NET_BIND_SERVICE` и `CAP_NET_RAW`: адаптер TUN, маршруты, nftables. Из устройств доступен только `/dev/net/tun`, файловая система только для чтения, кроме своих каталогов. `systemd-analyze security` оценивает службу в 4.0.
- Kill switch пропускает трафик ядер по пользователю `sora`, поэтому служба и пользователь за компьютером не должны быть одной учётной записью.
- Приложение подключается к `/run/sora/core.sock`. Сокет открыт для записи всем, а пропускает служба: она узнаёт процесс на другом конце через `SO_PEERCRED` и спрашивает polkit, сидит ли он в активной локальной сессии. Без polkit пускаются члены группы `sora`.
- Данные службы лежат в `/var/lib/sora` с правами 0700, ядра в `/usr/lib/sora/engines`.

Ручная установка без пакета:

```sh
sudo install -Dm755 sora-core /usr/bin/sora-core
sudo install -Dm644 service/linux/sora-core.service /usr/lib/systemd/system/sora-core.service
sudo install -Dm644 service/linux/sora.sysusers /usr/lib/sysusers.d/sora.conf
sudo install -Dm644 service/linux/sora.policy /usr/share/polkit-1/actions/io.github.levvs-one.sora.policy
sudo systemd-sysusers
sudo systemctl daemon-reload
sudo systemctl enable --now sora-core
```

Если служба была убита и интернет не работает, таблицы ядра снимаются командами `sudo nft delete table inet sora`, `sudo nft delete table inet sora_ingress` и `sudo nft delete table inet sora_nfqws`.

При удалении пакета данные в `/var/lib/sora` (подписки и секреты) сохраняются, чтобы переустановка ничего не теряла. На Debian и Ubuntu полное удаление вместе с данными — `sudo apt purge sora-core`. У пакетов RPM и Arch отдельного purge нет, поэтому там каталог удаляется вручную: `sudo rm -rf /var/lib/sora`.
