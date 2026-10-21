# Android VpnService: чек-лист и архитектура клиента sora

Дата: **19.10.2026** (исследование 18/20). Статус: **спека к будущей разработке** -
Android-клиента в коде пока нет (`app/` содержит раннеры только `windows`/`linux`).
Дополняет `../sora-legacy/docs/android-security-requirements.md` (контракт H6/H7/H8/M12/M13 -
UID-авторизация сервиса, манифест, Keystore, канал UI↔ядро, кэш плана) сетевой частью.

Референсы: официальные Android Developers docs, исходники WireGuard for Android,
v2rayNG, sing-box `experimental/libbox` (+ SFA), NekoBox.

---

## 1. Чек-лист VpnService 2025–2026

### 1.1. Обязательно (иначе не работает / отклоняет Play / падает на 14+)

- [ ] **Foreground service type на Android 14+ (API 34).** `startForeground()` без
      объявленного типа → `MissingForegroundServiceTypeException`. Для VPN-сервиса два
      допустимых варианта: `specialUse` + обязательный `<property
      android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="...">`
      с описанием use-case (для ревью Play), либо `systemExempted`, доки прямо разрешают
      его для «VPN apps (configured using Settings > Network & Internet > VPN)».
      Плюс пермишены `FOREGROUND_SERVICE` и `FOREGROUND_SERVICE_SPECIAL_USE`.
- [ ] **`VpnService.prepare()` consent.** Первый запуск, системный диалог; `null` =
      уже разрешено. Потеря права (другой VPN, отзыв пользователем) → `onRevoke()`,
      закрыть fd и остановиться корректно, не висеть.
- [ ] **`protect()` сокетов control plane.** Каждый исходящий сокет движка к серверу
      обязан пройти `VpnService.protect(fd)` (или `protect(Socket)`), иначе петля:
      пакеты туннеля возвращаются в TUN. В библиотечном режиме (Go-движок в процессе)
      нужен callback Go→Kotlin: `PlatformInterface`-стиль, как у sing-box libbox.
- [ ] **Обход VPN для самого приложения.** `Builder.addDisallowedApplication(packageName)`
      для собственного пакета, иначе собственный трафик и DNS control plane идут через
      TUN (петля/дедлок при старте). Делают так WireGuard, v2rayNG, SFA.
- [ ] **DNS через `addDnsServer()`.** Без явных DNS-серверов система резолвит через
      underlying network = утечка. Порядок: сначала свои резолверы, затем маршруты.
- [ ] **IPv6: маршрутизировать или глушить.** `addRoute("::", 0)` для full-tunnel;
      если IPv6 не поддерживается сервером, осознанно не добавлять `::/0` и понимать,
      что IPv6-трафик пойдёт мимо VPN (утечка). Молчаливое «ничего не делать» = баг.
- [ ] **16 KB page size (Play, targetSdk 35+, обязательно с 01.11.2025).** Все `.so`
      в APK/AAB должны быть выровнены на 16 KB. Go PIE-бинарники под arm64 по умолчанию
      64 KB-aligned, ок; для x86_64 (эмуляторы) нужен `-ldflags="-R 0x10000"`.
      Проверить `zipalign -c -P 16` и `llvm-objdump -p | grep LOAD` в CI.

### 1.2. Kill switch = always-on + lockdown (системный, единственный надёжный)

- [ ] Не изобретать свой kill switch на `iptables`, на Android нет прав. Kill switch =
      **«Always-on VPN» + «Block connections without VPN»** в системных настройках
      (Settings → Network & Internet → VPN → ⚙). Программно включается только через
      DevicePolicyManager (device owner); для обычных приложений, экран-инструкция с
      диплинком в `Settings.ACTION_VPN_SETTINGS` и проверка `VpnService.isLockdownEnabled()`
      (API 29+).
- [ ] В lockdown-режиме система держит сервис всегда запущенным и режет весь трафик
      мимо VPN. `core/guard.NoopFirewall` уже спроектирован ровно под это
      («system-owned tunnels such as Android VpnService»).
- [ ] Известные ограничения lockdown (честно писать в UI/доках, не обещать абсолют):
      обход через NAT-T keepalive offload на Wi-Fi/Cellular чипе (исследование 2025,
      Mullvad: UDP keepalive-пакеты уходят с железа мимо VPN даже в lockdown);
      свежий незакрытый Android-баг с утечкой через keepalive (GrapheneOS чинит у себя).
      Дополнительно держать in-app watchdog: при `onRevoke()`/падении движка, явный
      статус «не защищено», а не молчание.

### 1.3. Per-app allow/disallow

- [ ] `addAllowedApplication()` / `addDisallowedApplication()`, взаимоисключающие:
      либо allow-list (только выбранные через VPN, v2rayNG-режим «proxy only»),
      либо deny-list (все через VPN кроме выбранных). Смешивать нельзя, смена списка =
      пересоздание интерфейса (`establish()` заново).
- [ ] UX как у v2rayNG: два режима + поиск по приложениям; системные пакеты помечать.
      Disallowed-приложения ходят «как будто VPN нет» это by design, предупреждать.
- [ ] `allowBypass()` не вызывать без явной необходимости (даёт приложениям право самим
      выбирать сеть через `bindProcessToNetwork`).

### 1.4. DNS-утечки: специфика Android

- [ ] **Системный Private DNS (DoT, Android 9+) в strict-режиме** (задан hostname,
      напр. `dns.adguard.com`) **переопределяет DNS VPN**, запросы уходят провайдеру
      DoT мимо туннеля. Режим «Automatic» обычно безопасен. Приложение обязано читать
      `Settings.Global.PRIVATE_DNS_MODE` (+ `PRIVATE_DNS_SPECIFIER`) и при strict-режиме
      показывать предупреждение «обнаружен Private DNS, возможная утечка» со ссылкой
      на настройку. Детект, а не молчание.
- [ ] `core/diagnostics.SystemResolvers()` на `!windows` читает `/etc/resolv.conf` -
      на Android это мусор (резолвингом владеет netd). Нужен `systemdns_android.go`
      (build tag `android`): резолверы брать из Kotlin (`ConnectivityManager`
      → `LinkProperties.getDnsServers()`, Private DNS mode) и прокидывать в Go через
      gomobile-бридж как `DnsLeakInput.SystemResolversOverride`. Без этого чек
      `system-resolvers` на Android врёт.
- [ ] Canary-проверка `tunnel-dns` (`one.one.one.one`) работает и на Android без
      изменений, идёт через TUN.
- [ ] Браузерный DoH / захардкоженные резолверы в приложениях вне контроля VPN-клиента -
      фиксировать в доках как известное ограничение.

### 1.5. Battery / background 2025–2026

- [ ] Постоянный foreground service + нестираемое уведомление (канал `IMPORTANCE_LOW`).
      На Android 14+ пользователя могут «остановить» FGS из task manager, обрабатывать
      рестарт через always-on (система сама перезапустит) + `START_STICKY`.
- [ ] **Не поллить сеть.** Смена сети (Wi-Fi↔LTE, captive portal), только через
      `ConnectivityManager.NetworkCallback`; движок переподключать по событию, а не
      по таймеру. WakeLock, только на время handshake, с таймаутом.
- [ ] `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: запрашивать через
      `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (для VPN, легитимный кейс),
      плюс инструкция «Battery usage → Unrestricted» для Samsung/OneUI (агрессивное
      усыпление, топ-1 причина «connected but no internet»).
- [ ] `Builder.setMetered()` (API 29+): прокидывать metered-флаг underlying-сети
      (`ConnectivityManager.isActiveNetworkMetered()`), чтобы приложения внутри VPN
      видели корректный metered-статус. `setUnderlyingNetworks()`, держать актуальным
      список сетей для upstream-соединений (важно при dual Wi-Fi+Cellular).
- [ ] Android 15: фоновые сетевые запросы вне валидного lifecycle процесса теперь
      кидают `UnknownHostException`/`IOException`, весь сетевой код движка только
      внутри живого сервиса.

### 1.6. Грабли (deprecated / частые ошибки)

- Исполняемые бинарники движков из app-private dir: **заблокировано** с Android 10
      (targetSdk 29+, W^X/noexec). Путь sing-box/xray/mihomo «скачал бинарник и запустил»
      (текущий `core/engine/supervise`) на Android невозможен, только **in-process
      library mode** (см. §2).
- `addRoute("0.0.0.0", 0)` без `addAddress()` / без `establish()` на главном потоке -
      `establish()` блокирующий, вызывать в фоне.
- MTU: дефолтный TUN MTU; для WireGuard-подобных UDP-туннелей ставить 1420–1500
      осознанно, иначе фрагментация/потери на мобильных сетях.
- `setBlocking(true)` на fd перед передачей в нативный код (паттерн WireGuard).
- Дубль `establish()` без закрытия старого fd, утечка интерфейсов; всегда
      `close()` предыдущего `ParcelFileDescriptor`.
- Не кэшировать `VpnService.prepare()`-consent: после обновления APK / смены
      пользователя consent может слететь, проверять каждый старт.
- Китайские OEM (MIUI/HyperOS, EMUI): автозапуск + «без ограничений» в фоне нужно
      просить отдельно; deep-link на vendor battery settings.

---

## 2. Архитектура Android-клиента sora: Go core + Kotlin-обёртка

### 2.1. Реалистичность gomobile, да, но с рефакторингом границы движков

- **Формат:** `gomobile bind` нового пакета `core/mobile` (build tag `android`) →
      `sora-core.aar`. Экспортируемый API, плоский и gomobile-совместимый
      (строки/байты/колбэк-интерфейсы, без каналов в сигнатурах): `Start(configJSON)`,
      `Stop()`, `StatusJSON()`, колбэк `PlatformBridge { Protect(fd int32), GetSystemDNS() string, ... }`.
      Прецеденты: v2rayNG (`AndroidLibV2rayLite` + Xray в процессе), sing-box libbox
      (`BoxService` + `PlatformInterface`: `OpenTun`, `FindConnectionOwner`...), SFA.
- **Что уже готово в core:** нет cgo; `os/exec` изолирован в `supervise`/`tunroute`/
      `guard(nftables)`/`fingerprint`, все с build-тегами платформ, в mobile-сборку
      не попадут; dbus только в `ipc/polkit_linux.go`; `core/guard.NoopFirewall` и
      `core/session` guard уже предусматривают «system-owned tunnels such as Android
      VpnService»; `core/doc.go` заявляет Android как целевую платформу.
- **Что нужно доработать (P0 инженерный):**
  1. Движки сейчас, внешние процессы (`engine/supervise`: «run -c stdin»).
     Нужен **in-process driver**: sing-box, `experimental/libbox` (официальный),
     Xray, in-process через Xray-core API (как libv2ray у v2rayNG),
     mihomo, in-process (как у ClashMeta Android). Граница: интерфейс
     `engine.Driver` с двумя реализациями `external` (текущая) / `embedded` (Android).
     Это самая крупная работа темы.
  2. TUN: Kotlin делает `Builder.establish()`, fd (`dup()`, см. грабли libbox)
     передаётся в Go; движок поднимает TUN поверх fd. Сокеты движка, через
     `Protect()`-колбэк в Kotlin.
  3. IPC UI↔ядро: на Android оба в одном процессе, gRPC через Unix-socket не нужен;
     Kotlin↔Go, прямые вызовы AAR. Контракт безопасности из legacy-дока (H8/M12/M13:
     Keystore, EncryptedSharedPreferences, зануление токена) остаётся в силе для
     Kotlin-слоя.
  4. `diagnostics`: `systemdns_android.go` (см. §1.4); PCAPNG-захват TUN на Android -
     читать пакеты из того же fd в Kotlin/Go кольцевым буфером (дебаг-режим).

### 2.2. Спека по приоритетам

**P0, без этого клиент нельзя выпускать:**
- VpnService + FGS (`specialUse`/`systemExempted`, §1.1) + `prepare()`/`onRevoke()`.
- In-process драйвер хотя бы sing-box (дефолт по `DefaultPreference`: «native Android
      support» уже в `catalog.go`) + `Protect()`-бридж + `addDisallowedApplication(self)`.
- DNS: `addDnsServer()` из плана; детект strict Private DNS + варнинг; фикс
      `SystemResolvers()` для Android (§1.4).
- Kill switch через always-on + lockdown: экран-инструкция, `isLockdownEnabled()`,
      in-app watchdog при `onRevoke()`.
- IPv6: осознанная политика (§1.1), без молчаливых утечек.
- Манифест/хранилище по legacy H6/H7/H8/M12/M13 (контракт уже зафиксирован).
- 16 KB alignment в CI (§1.1).

**P1, паритет с v2rayNG/NekoBox:**
- Per-app allow/disallow UI (§1.3).
- `setMetered()`/`setUnderlyingNetworks()` + `NetworkCallback`-переподключения.
- Battery: unrestricted-инструкция (особенно Samsung), wakelock-только-handshake.
- Метрики/мониторинг соединений в UI (API ядра уже есть).
- QR импорт/шеринг (общий P0-gap из competitor-analysis, на Android критичен).
- Подписки/автообновление, переиспользовать `core/subscription` как есть.

**P2, дифференциация:**
- Сетевые профили (дом/мобильная/роуминг) поверх `NetworkCallback`.
- zapret на Android: невозможен в текущем виде (нужен root/nfq); только через
      userspace-реализацию, исследовать отдельно, не обещать.
- Синхронизация устройств (F9 E2E-сервис уже в core, переиспользовать).
- Расширения `.soraext`: на Android, только с явным согласием и песочницей.

### 2.3. Что ляжет на Android как есть, что, нет

| Компонент core | Android |
|---|---|
| `parser`, `profiles`, `subscription`, `secret`, `session`, `control` (gRPC-контракт) | как есть |
| `diagnostics/dnsleak.go` (canary, killswitch-dns) | как есть, кроме `SystemResolvers()` |
| `engine/*` (рендер конфигов sing-box/xray/mihomo) | как есть; меняется только способ запуска (embedded driver) |
| `engine/supervise`, `guard/nftables`, `tunroute`, `ipc` (polkit/peercred) | не используется на Android |
| `probe` (bandwidth) | как есть, сокеты через Protect-бридж |
| `service/sync` (E2E) | как есть |

---

## 3. Связь с другими темами

- Тема 18/20 (эта): сеть/VpnService. Контракт безопасности Kotlin-слоя, тема
  `sora-legacy/docs/android-security-requirements.md` (H6/H7/H8/M12/M13).
- При старте разработки: сначала `engine.Driver` embedded для sing-box (P0 инж.),
  затем Kotlin-каркас VpnService по чек-листу §1, затем P1.
