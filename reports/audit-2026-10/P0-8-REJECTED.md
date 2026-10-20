# P0-8: pre-Initial dummy + high-port для QUIC-транспортов — ОТКЛОНЕНО слоп-фильтром

Дата: 2026-10-20. Имплементатор: swarm-агент P0-8.

## Вердикт
**Ничего не реализовано в коде — движки не поддерживают ни одну из техник.**
Реализация «в лоб» (свой dummy-пакет из core/) была бы слопом: core/ рендерит
JSON-конфиг для внешних бинарников sing-box-lx и Xray и не владеет сокетом —
dummy перед QUIC Initial должен слать сам движок, иначе это театр.
Пункт закрыт как «отклонён слоп-фильтром, ждём upstream».

## Что проверено

QUIC-транспорты, которые рендерит sora (всё покрытие — больше нет):
- `core/engine/singbox/render.go`: `ProtocolHysteria2` (case 245), `ProtocolTUIC` (case 264)
- `core/engine/xray/render.go`: `hysteria()` — нативный Hysteria2 Xray (TUIC в Xray не поддерживается вовсе)

### sing-box-lx 1.14.3-lx.14 (пины сверены с доками upstream sing-box 1.14.0)
- hysteria2 outbound: поля `server_ports`, `hop_interval(_max)`, `up/down_mbps`,
  `obfs` (salamander/gecko), `password`, `tls`, QUIC Fields, Dial Fields —
  **опции «отправить dummy-пакет перед Initial» нет**.
- tuic outbound: `congestion_control`, `udp_relay_mode`, `udp_over_stream`,
  `zero_rtt_handshake`, `heartbeat`, `tls`, QUIC Fields, Dial Fields —
  **dummy-опции нет**.
- QUIC Fields (1.14.0): только `initial_packet_size`, `disable_path_mtu_discovery`.
- Dial Fields: `bind_interface`, `inet4/inet6_bind_address` (без порта), `routing_mark`,
  `udp_fragment`, … — **выбора source-порта нет**.
- Близкие, но не та техника (поэтому не дёргаем): `obfs` salamander (уже рендерится),
  gecko с min/max packet size (1.14; требует поддержки сервером — дефолтом сломает
  подключения), `disable_chrome_parrot` (по умолчанию false = паррот Chrome включён,
  уже хорошо), `udp_fragment` (фрагментация UDP ≠ dummy pre-packet; трогать
  дефолтом — поведение, не относящееся к P0-8).

### Xray 26.3.27 (пины сверены с xtls.github.io)
- hysteria outbound: `settings` = {version, address, port};
  `streamSettings` = network "hysteria" + `hysteriaSettings` {version, auth,
  up_mbps, down_mbps} + `tlsSettings` + `finalmask` + `sockopt` —
  **dummy-опции нет ни в одном объекте**.
- `sockopt`: mark, tcpFastOpen, tproxy, interface, V6Only, buffers, … —
  **выбора source-порта нет**.

### high-port
- Целевой порт диктуется сервером (`server_port` — required в обоих движках);
  клиент его не выбирает. Менять нечего — только документировать.
- Исходный порт не настраивается ни в одном движке; ОС выдаёт ephemeral-порт.
  На Linux это уже высокий диапазон (32768–60999) — желаемый эффект «бесплатно».

### mihomo (третий рендер, `core/engine/mihomo/proxy.go`)
- hysteria2: `up/down`, `ports`/`hop_interval`, `password`, `obfs` (salamander),
  `realm`, dial-опции (`interface-name`, `routing-mark`, `ip-version`, `tfo`, `mptcp`) —
  **dummy-опции нет, выбора source-порта нет**.
- tuic: `Token`/`UUID`, `CongestionController`, `UdpRelayMode`, `UDPOverStream` —
  **dummy-опции нет**.
- (Прим.: таск фиксирует пины sing-box-lx / Xray; mihomo проверен для полноты
  покрытия QUIC-рендеров — вывод тот же.)

### «Slicing — бесплатно в quic-go ≥ 0.52.0» (из WEB-RESEARCH-2)
Внутреннее поведение QUIC-библиотеки внутри движка, не опция конфига.
Рендером не прокидывается; отдельного действия не требует.

## Что делать, когда появится upstream
- sing-box: если в `option.Hysteria2OutboundOptions` / `TUICOutboundOptions`
  появится поле типа dummy/padding pre-packet — прокинуть дефолт для
  hy2/TUIC в `engine/singbox/render.go` + unit-тест (рендер содержит опцию;
  негатив — не-QUIC транспорты не затронуты).
- Xray: аналогично для `hysteriaSettings` в `engine/xray/render.go`.
- Source-port: пересмотреть, если появится опция в Dial Fields / sockopt
  (пока — не ожидается: ephemeral-порты ОС уже высокие).

## Проверка, выполненная при закрытии
- Код не менялся (0 файлов в репо), unit-тесты не добавлялись: тестировать
  нечего (требование тестов относится «к тому, что реализовано»).
- `go build ./...` в `core/` на момент закрытия (2026-10-20 ~02:00 MSK) —
  **красный, но не по моей вине**: чужой незакоммиченный WIP сиблинга
  (`core/engine/validate.go` вызывает несуществующие `o.RealityWarnings()` /
  `ValidateReality`; новый незатреканный `core/engine/mux.go` с
  `type MuxOptions` ещё не закоммичен). P0-8 к этому отношения не имеет;
  чинить чужой WIP не стал (директивы: не трогать чужую работу).
