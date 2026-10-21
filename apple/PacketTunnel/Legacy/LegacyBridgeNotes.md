# LegacyBridgeNotes — карта функций моста: 1.14-мост → пин lx.15

Дата: **2026-10-21**. Источники: дерево пина
`~/workspace/.legacy-engines/x/sing-box-lx-1.13.13-lx.15/experimental/libbox/`
и, для сравнения, `sing-box-lx-1.14.3-lx.22` той же папки; существующий
`PacketTunnel/LibboxBridge.swift` (мост основного таргета).
Статусы: **подтверждено** — сигнатура вычитана из исходников пина;
**TODO(verify-on-mac)** — Swift-спеллинг генерирует gomobile, сверяется
только по заголовкам собранного Libbox.xcframework (форк xcframework
не публикует, ENGINES.md §2.3).

## 1. Внутренний Swift-API (общий для обоих мостов, не меняется)

| Функция | Семантика |
|---|---|
| `LibboxBridge.setup(basePath:workingPath:tempPath:)` | один раз до старта |
| `LibboxBridge.startService(configJSON:)` | старт/перезапуск сервиса конфигом |
| `LibboxBridge.stopService()` | остановка, безопасна в покое |
| `LibboxBridge.isRunning` | флаг сервиса |
| `LibboxBridge.queryStats() -> TunnelStatusPayload` | счётчики или `.capabilityUnavailable` |

`PacketTunnelProvider.swift` от моста не зависит в деталях и
компилируется против любого из двух файлов; состав таргета разводит
файлы (Apps/iOSLegacy/TARGET-NOTES.md §3).

## 2. Карта функций

| # | 1.14-мост (как написано в LibboxBridge.swift) | Пин lx.15 (Go, `experimental/libbox`) | Статус |
|---|---|---|---|
| 1 | `LibboxSetup(options, &error)`, options: basePath/workingPath/tempPath | `Setup(options *SetupOptions) error` (setup.go:43); поля — ровно 8: BasePath, WorkingPath, TempPath, FixAndroidStack, CommandServerListenPort, CommandServerSecret, LogMaxLines, Debug | подтверждено по исходникам; Swift-спеллинг — TODO(verify-on-mac) |
| 2 | `LibboxNewService(configJSON, nil, &error) -> LibboxBoxService` | **Такой функции нет ни в lx.15, ни в lx.22.** Сервис: `NewCommandServer(handler, platformInterface) (*CommandServer, error)` (command_server.go:45) | расхождение D1: legacy-мост построен на CommandServer; 1.14-мосту при его Mac-верификации предстоит та же замена |
| 3 | `service.start(&error)` | `CommandServer.Start() error` (command_server.go:109) — поднимает gRPC-сервер команд; сам бокс стартует следующим вызовом | подтверждено; спеллинг TODO(verify-on-mac) |
| 4 | (в 1.14-мосте отдельного reload нет; рестарт = новый сервис) | `CommandServer.StartOrReloadService(configContent string, options *OverrideOptions) error` (:172); OverrideOptions{AutoRedirect, IncludePackage, ExcludePackage} | подтверждено; используется и для первого старта, и для hot-reload (fast switch без пересоздания туннеля) |
| 5 | `service.close(nil)` | `CommandServer.CloseService() error` (:180) + `CommandServer.Close()` (:158, без error — гасит gRPC и StartedService) | подтверждено; legacy stopService вызывает оба, в этом порядке |
| 6 | — (в 1.14-мосте нет) | `CommandServer.Pause()` / `Wake()` / `ResetNetwork()` (:208/:223/:233) | подтверждено; в legacy-мосте не экспонируются наружу: общий провайдер на sleep/wake только перевыставляет network settings. Кандидат на расширение протокола при интеграции — решение координатора |
| 7 | PlatformInterface — TODO в шапке 1.14-моста | `PlatformInterface` (platform.go:5), 19 методов: LocalDNSTransport, UsePlatformAutoDetectInterfaceControl, AutoDetectInterfaceControl, OpenTun, UseProcFS, FindConnectionOwner, StartDefaultInterfaceMonitor, CloseDefaultInterfaceMonitor, GetInterfaces, UnderNetworkExtension, IncludeAllNetworks, ReadWIFIState, SystemCertificates, ClearDNSCache, SendNotification (+ типы ConnectionOwner, TunOptions, WIFIState, NetworkInterface(+Iterator), Notification, OnDemandRule) | подтверждено по исходникам; все методы реализованы в `LegacyPlatformInterface`, честные заглушки помечены в коде и в §3 ниже |
| 8 | Статистика — TODO(verify-on-mac), мост бросает capabilityUnavailable | Поток, не запрос: `NewCommandClient(handler, options)` (command_client.go:80, без error), `CommandClientOptions{StatusInterval}` + `AddCommand(CommandStatus)` (command.go: CommandLog=0, CommandStatus=1, CommandGroup=2, CommandClashMode=3, CommandConnections=4), `Connect() error`, `Disconnect() error`; обработчик `CommandClientHandler.WriteStatus(*StatusMessage)`; StatusMessage{Memory, Goroutines, ConnectionsIn, ConnectionsOut, TrafficAvailable, Uplink, Downlink, UplinkTotal, DownlinkTotal} (command_types.go:12) | подтверждено; legacy queryStats отдаёт последний WriteStatus (UplinkTotal/DownlinkTotal — байты суммарно; Uplink/Downlink — скорости, в payload не идут), TrafficAvailable=false → capabilityUnavailable |
| 9 | — (в 1.14-мосте нет) | `CheckConfig(configContent string) error` (config.go:48), `FormatConfig` (:196) | подтверждено; CheckConfig — префлайт в startService (D7) |
| 10 | — | `Version() string`, `SetLocale(string)`, `FormatBytes/FormatMemoryBytes/FormatDuration`, `ProxyDisplayType` (setup.go:65–85) | подтверждено; мостом не используются (форматирование байт в UI — общий ByteFormat) |
| 11 | `LibboxCommandClient` упомянут в TODO без сигнатур | Методы клиента lx.15: SelectOutbound, URLTest, SetClashMode, CloseConnection(s), ServiceReload, ServiceClose, GetSystemProxyStatus, GetDeprecatedNotes, GetStartedAt, SetGroupExpand — command_client.go:459+ | подтверждено наличие; legacy-мост не вызывает (fast switch идёт через reload конфига, как в общем провайдере) |

## 3. Честные заглушки платформенного интерфейса (lx.15)

| Метод | Поведение в LegacyPlatformInterface | Почему так |
|---|---|---|
| OpenTun | fd из зарегистрированного провайдера (`registerTUNFDProvider`); нет регистрации → throw | fd живёт в общем PacketTunnelProvider (NEPacketTunnelFlow); регистрация — одна строка при сборке таргета, TODO(verify-on-mac) в TARGET-NOTES |
| GetInterfaces | пустой итератор | TODO(verify-on-mac): перечисление через getifaddrs, как SFI; маршруты всё равно задаёт NE, выдуманные интерфейсы хуже пустых |
| StartDefaultInterfaceMonitor | listener сохраняется, событий нет | ремонт сети на этом тире — wake-перевыставление настроек общим провайдером; фиктивные события не шлём |
| SystemCertificates | пустой итератор | TODO(verify-on-mac): PEM-якоря через SecTrust, выбор кодировки сверяется с парсером пина |
| SendNotification | throw | уведомления — зона приложения (NotificationService), не расширения |
| FindConnectionOwner | throw | на iOS владелец чужого соединения недоступен в принципе |
| AutoDetectInterfaceControl | throw, пара Use…=false | управление интерфейсом — платформенное (NE), не libbox |
| ReadWIFIState | пустой SSID/BSSID | без hotspot-разрешения iOS SSID не отдаёт — пустота и есть правда |
| ClearDNSCache | no-op | публичного flush на iOS нет; кэш бокса чистится reload-ом |
| LocalDNSTransport | nil | резолв — DNS-модуль бокса (как SFI на iOS) |

## 4. Чем lx.22 (основной пин) отличается от lx.15 в поверхности libbox

Для координатора, чтобы цена расхождения мостов была видна целиком:

- SetupOptions lx.22: +8 полей (CrashReportSource, AppVersion,
  AppMarketingVersion, OomKillerEnabled/Disabled, OomMemoryLimit,
  PowerReportEnabled, PlatformMetadata) и `ReloadSetupOptions`;
  `SetLocale` возвращает error (в lx.15 — нет).
- PlatformInterface lx.22: +CancelNotification, StartNeighborMonitor/
  CloseNeighborMonitor, RegisterMyInterface, UsePlatformShell/
  CheckPlatformShell/OpenShellSession, LookupUser, LookupSFTPServer,
  ReadSystemSSHHostKey, TailscaleHostname, UsePlatformBridge/
  CreateBridge.
- CommandServer lx.22: +WakeNow(), RecordScreenState(on),
  command_server_rebind_lx; ядро (New/Start/StartOrReload/Close/
  Pause/Wake/ResetNetwork) — то же.
- В lx.22 есть файлы, отсутствующие в lx.15 целиком (bridge_service_*,
  tailscale/openvpn/openconnect/usbip/stun типы команд, neighbor,
  networkquality, oom_report, power_report, ssh_shell) — legacy-тир
  их не использует и не эмулирует.
- Конфиг: пять 1.14-добавок, которые генератор для legacy-тира не
  эмитит, — ENGINES.md §4 (http_clients, hop_interval_max,
  bbr_profile, gecko, chrome_155).
