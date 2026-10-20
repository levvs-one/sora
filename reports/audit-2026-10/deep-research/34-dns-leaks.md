# 34. DNS-утечки — векторы по ОС и как каждый закрывать

Дата: 2026-10-20. Группа D «DNS», третий проход. У sora уже есть `core/diagnostics/dnsleak.go` (tunnel-dns / system-resolvers / killswitch-dns) — здесь векторы утечек глубже, чем «сверить резолверы».

## 1. Windows: NRPT + SMHNR

- **SMHNR** (Smart Multi-Homed Name Resolution, Win 8+): шлёт DNS-запрос **во все интерфейсы одновременно**, побеждает быстрейший ответ — утечка by design. Отключение: `Set-DnsClientGlobalSetting -SmartMultiHomedNameResolution $false` или реестр `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\DisableSmartNameResolution=1`. Нюанс (SANS): GPO «Turn off» всё равно оставляет fallback на SMHNR при неудаче других запросов — отключение частичное.
- **NRPT** (Name Resolution Policy Table) — надёжный механизм: `Add-DnsClientNrptRule -Namespace "." -NameServers "<tunnel-dns>"` ловит все запросы и направляет в туннельный DNS **независимо от SMHNR**. SANS-тесты: NRPT работает на всех редакциях и при включённом SMHNR.
- Плюс: LLMNR и NetBIOS — тоже векторы (multicast-резолв мимо туннеля); гасить политикой вместе с SMHNR.
- **Что делать sora:** при активном TUN на Windows — ставить NRPT-правило `.` → свой DNS (127.0.0.1 hijack или адрес движка), снимать при дисконнекте; SMHNR — отключать реестром с восстановлением. Это делает сервис (у sora есть Windows-служба) — не UI.

## 2. Linux: systemd-resolved

- Механика: per-link DNS + routing domains. `resolvectl dns sora0 <dns>`, `resolvectl domain sora0 ~.` — тильда-точка = «этот линк обслуживает всё». Без `~.` запросы уходят на DHCP-линк (утечка).
- `/etc/resolv.conf` должен быть симлинком на `/run/systemd/resolve/stub-resolv.conf` (127.0.0.53); иначе часть софта читает resolv.conf напрямую мимо resolved.
- `DNSOverTLS=opportunistic` в resolved — тихая деградация до plaintext; для VPN-режима не включать (DNS идёт в туннель, шифровать внутри не нужно).
- **Что делать sora:** sora-сервис уже root — при старте TUN: `resolvectl dns/domain` на `sora0` + проверка симлинка resolv.conf; при стопе — откат. Альтернатива без resolved — переписать resolv.conf напрямую (у sora есть `systemdns_resolvconf.go` — сверить, что он ставит только свои серверы, без старых).

## 3. macOS

- Порядок сервисов (service order): TUN-интерфейс должен быть первым; per-network DNS может переопределять.
- Честная граница: без configuration profile / MDM чистое принуждение DNS на macOS не делается — ОС «намеренно делает это сложным» (valtersit, 2026). Плюс captive portal assistant имеет exemption.
- **Что делать sora:** ставить DNS на TUN-сервисе через `networksetup -setdnsservers`, первым в service order; в диагностике честно показывать «macOS: принуждение частичное».

## 4. Android: Private DNS + обход 2026 года

- **Private DNS** (DoT hostname): системный резолвер; VPN-приложение перехватывает DNS через TUN `dns-hijack`, но если у пользователя задан Private DNS hostname — часть запросов может уходить DoT напрямую, мимо VPN-DNS. Решение: при активном VPN просить переключить Private DNS в Automatic (инструкция в UI) — система отдаст DNS VPN-туннелю.
- **Сентябрь 2026, Mullvad/Armin Šupuk:** обход «Block connections without VPN» через **NAT-T keepalive offload**: приложение просит keepalive-UDP, Android отдаёт отправку в Wi-Fi/cellular-чип, чип шлёт **мимо VPN**, получатель видит реальный IP. Обычных network-разрешений достаточно, спецпермишен не нужен. Google пометил как duplicate, фикса/CVE на момент раскрытия не было. Пакеты не несут произвольных данных, но деанонимизируют.
- **Браузерный DoH** (Chrome/Firefox Secure DNS) обходит TUN DNS-hijack полностью — домены для правил тогда только из sniffing; при ECH не спасает и он (см. 45-fakeip-comparison §3.5).
- **Что делать sora (Android, перспектива):** в диагностике — проверка Private DNS (предупреждение, если не Automatic); в FAQ — про браузерный DoH; keepalive-обход — честно задокументировать как платформенный риск вне контроля приложения.

## 5. Универсальное закрытие на уровне движка

- `hijack-dns` (sing-box route rule) / `dns-hijack: ["any:53"]` (mihomo TUN) — перехватывать весь порт 53 в туннеле;
- firewall: блочить 53/853 наружу мимо TUN (kill switch должен покрывать DNS — у sora чек `killswitch-dns` уже есть);
- DoH/DoT приложений — не перехватывается принципиально: честная граница в доке, не баг.

## Вердикт: лучшее

NRPT на Windows и `resolvectl ~.` на Linux — лучшее (дешёвые, системные, проверенные). Слоп — «поставить DNS на адаптер и надеяться» без NRPT/route-domain: на Windows это не закрывает SMHNR.

## Рекомендация: внедрить так

1. Windows-служба: NRPT `.` → туннельный DNS на время сессии + `DisableSmartNameResolution=1`; откат при стопе.
2. Linux-служба: `resolvectl dns/domain sora0 ~.`; проверка симлинка resolv.conf; откат.
3. macOS: DNS на TUN + service order; честный статус «частично».
4. В `dnsleak.go` добавить векторы: SMHNR-статус (Windows), resolv.conf-симлинк (Linux), Private DNS (Android).
5. Документировать как не-баги: браузерный DoH, keepalive-offload на Android.
