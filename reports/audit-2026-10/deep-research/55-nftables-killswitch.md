# 55. nftables kill switch: правила, персистентность через ребут, задел sora-core как службы

Группа F «Маршрутизация и файрвол», проход 3. Дата: 2026-10-20.
Не дублирует WEB-RESEARCH §4 (там — UX уровней Off/Standard/Strict): здесь — пакетный уровень и персистентность.

## Находки

### 1. Эталон: Mullvad на Linux (открытый код + доки, 2026)
- Файрвол — nftables. Политики по состоянию туннеля: Connected (всё через туннель + LAN по настройке), Connecting (только VPN-сервер IP+порт+протокол, DNS и приложения заблокированы), Disconnected без lockdown (без правил), **Lockdown (как Error state): блокируется всё**.
- Защита от fingerprinting при установке соединения: к IP VPN-сервера пускаются только привилегированные процессы — на Linux это **fwmark `0x6d6f6c65`** («mole» в hex) или root. Остальным — drop, иначе непривилегированный процесс может слать пакеты на IP сервера и его можно фингерпринтить.
- LAN sharing — отдельный тумблер, работает независимо от lockdown: при disconnect+lockdown блокируется всё включая LAN.

### 2. Персистентность через ребут — как это делается правильно
- nftables by design не персистентен: правила живут до ребута. Персистентность = `nft list ruleset > /etc/nftables.conf` + `systemctl enable nftables` (сервис грузит конфиг на ранней стадии загрузки, до network-online).
- Для strict-уровня VPN это означает: **отдельный systemd unit sora-firewall**, `WantedBy=sysinit.target` / `Before=network-pre.target`, который ставит block-all таблицу до поднятия сети. Тогда окно утечки между загрузкой и стартом GUI закрыто.
- Важно: strict-правила должны переживать **краш** приложения — значит, их ставит и снимает только привилегированная служба (sora-core как служба — задел есть, MEMORY.md), а не GUI-процесс пользователя.

### 3. Канонический ruleset kill switch (модель default-drop)
```nft
table inet sora {
  chain output {
    type filter hook output priority filter; policy drop;
    iif "lo" accept
    ct state established,related accept
    oifname "tun0" accept            # всё, что уже в туннеле
    ip daddr <VPN-server-IP> udp dport <port> meta skuid <engine-uid> accept  # handshake
    udp dport 67 accept              # DHCP, иначе не поднимется сеть
    # DNS — только через туннель: прямых udp/53 наружу нет
  }
}
```
- `inet` family — одни правила на v4+v6 (иначе IPv6-утечка — классика провалов kill switch).
- DNS: прямых запросов наружу быть не должно вообще — только через `oifname tun0`. Это закрывает DNS-leak без отдельных хаков.
- Endpoint-правило — по конкретному IP+порт+протокол+UID движка (паттерн Mullvad), не «весь UDP наружу».

### 4. Состояние репо sora (факты)
- `sora-legacy/core/guard/nftables.go`: таблица `inet sora`, output hook, **policy accept** с точечными drop (DNS вне туннеля, «tunnel destination outside the tunnel»). UID-исключение для движка, LAN-bypass сети, комментарии в правилах. Тестируемый рендер (`nftables_test.go`).
- Оценка: для Standard-уровня — рабочая модель; для **Strict — слабовато**: `policy accept` означает «разрешено всё, кроме перечисленного» — дыра по умолчанию. Strict требует инверсии: `policy drop` + явные accept.
- Windows-часть уже на WFP (тема 56), Linux-часть — nftables. iptables в sora-legacy остался только в вендорном zapret (тема 57).

### 5. Конфликты и edge cases
- firewalld/ufw тоже пишут в nftables: своя таблица `inet sora` не конфликтует с их таблицами (nftables мультитабличен), но приоритет hook'ов и чужие drop-правила могут мешать — проверять `nft list ruleset` на конфликты при установке.
- Docker ставит свои iptables/nft правила — те же проверки.

## Вердикт: лучшее или слоп
- **Лучшее:** default-drop таблица `inet sora` + отдельный ранний systemd unit для Strict + endpoint-правила по UID/mark + явный блок IPv6 + DHCP-исключение.
- **Слоп:** `policy accept` для strict-уровня; правила, ставящиеся из GUI-процесса (умирают с сессией); инкрементальные `nft add rule` вместо атомарного `nft -f` (половинчатые таблицы при обрыве).

## Рекомендация «внедрить так»
1. **Три уровня:** Off (нет правил), Standard (текущий `guard/nftables.go`, policy accept + точечные drop, ставится службой при коннекте, снимается при дисконнекте), **Strict (новое): `policy drop` + allow-list, ставится systemd unit'ом до сети, снимается только явным выключением Strict пользователем**.
2. Strict-ruleset: lo, established, `oifname <tun>`, endpoint IP+port+proto+UID движка, DHCP (67/68), опционально LAN (тема 59). Всё остальное — drop. Атомарная установка одним `nft -f`.
3. **Self-test при включении Strict:** core сам пробует «утечь» (TCP наружу мимо tun) и проверяет, что drop сработал; результат — в UI («проверено: утечек нет»).
4. Конфликт-детект: при установке сканировать чужие таблицы на пересекающиеся drop/accept и предупреждать.
5. Логирование дропов — rate-limited, в диагностику (не в прод по умолчанию).
