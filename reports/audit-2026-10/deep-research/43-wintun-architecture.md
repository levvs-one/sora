# 43 — WinTun: архитектура, ring buffers, spin-before-block, тюнинг

Дата: 2026-10-20. Третий проход группы E. Первый проход дал базу (официальная дока, rateJuggler из amneziawg-go). Здесь — механика до уровня кода драйвера (tailscale/wintun, форк официального) и конкретные тюнинг-константы.

## 1. Архитектура (первоисточник: https://git.zx2c4.com/wintun/about/)

WinTun — L3 TUN-драйвер для Windows (NDIS 6 miniport, только IP-пакеты, без Ethernet-заголовков):

- Userspace ↔ драйвер общаются через **пару shared memory ring buffers** (send + receive). Никаких IOCTL на пакет — только чтение/запись общей памяти с `Head`/`Tail` указателями. Это и есть причина скорости: per-packet syscall cost почти нулевой.
- `TUN_RING`: `Head` (владелец: драйвер на send / приложение на receive), `Tail` (наоборот), `Alertable` (флаг «меня можно будить»), затем `Data[]`.
- `TUN_PACKET`: `Size` (до `0xFFFF`) + сырые байты IPv4/IPv6-пакета.
- Ring capacity: степень двойки от `0x20000` (**128 KiB**) до `0x4000000` (**64 MiB**). `Data` аллоцируется как `capacity + 0x10000`, чтобы любой пакет читался континуально без модульного wrap-around.
- Регистрация колец — два IOCTL: `TUN_IOCTL_REGISTER_RINGS` (0xca6ce5c0), `TUN_IOCTL_FORCE_CLOSE_HANDLES` (0xca6ce5c4). Доступ к IOCTL — только LocalSystem и Administrators (security descriptor при загрузке драйвера).
- Важно для sora: драйвер ставится **один на пул** (`WintunCreateAdapter`), адаптеров в пуле может быть несколько. Установка/удаление драйвера — привилегированная операция; гигиена удаления критична (кейс KB5075912 из первого прохода: осиротевший драйвер ломал UAC).

## 2. Spin-before-block: две стороны медали

**Сторона userspace** (официальная дока, дословно): «Some high performance use cases may want to **spin on `WintunReceivePacket` for a number of cycles** before falling back to waiting on the read-wait event». Паттерн из example.c: цикл `WintunReceivePacket` → если `ERROR_NO_MORE_ITEMS`, то `WaitForSingleObject(WintunGetReadWaitEvent)`.

**Сторона драйвера** (tailscale/wintun, `wintun.c` 427–455 — трёхфазная стратегия receive-потока ядра, когда send-ring пуст):
1. **Busy read**: tight loop по `Ring->Tail`, до ~0.1 мс (1/10 мс по `KeQueryPerformanceCounter`);
2. **Yield spin**: `ZwYieldExecution()` между повторами, в том же окне;
3. **Block**: `KeWaitForMultipleObjects` на `{Disconnected, Receive.TailMoved}` до пробуждения.

Перед сном драйвер делает double-check: ставит `Ring->Alertable = TRUE` через `InterlockedSet`, перепроверяет `Tail` — это закрывает гонку «пакет пришёл между проверкой и сном». Т.е. спин на ~0.1 мс уже встроен в сам драйвер; userspace-спин — второй уровень той же идеи.

## 3. Референсная реализация тюнинга: rateJuggler (amneziawg-go, `tun/tun_windows.go`)

Глубокий разбор (https://deepwiki.com/amnezia-vpn/amneziawg-go/3.2-windows-tun-implementation):

| Константа | Значение | Смысл |
|---|---|---|
| `rateMeasurementGranularity` | 500 мс | окно замера скорости |
| `spinloopRateThreshold` | **800 Mbps** | выше — включается спинлуп вместо блокирующего чтения |
| `spinloopDuration` | ~12.5 мкс | макс. спин на итерацию |
| Ring capacity | **8 MB** | сессия WinTun |
| `BatchSize()` | **1** | батчинг чтения — TODO до сих пор |

Логика: при низкой нагрузке — блокирующее чтение (экономия CPU/батареи), при >800 Мбит/с — спинлуп (минимум латентности). Порог 800 Мбит/с выбран эмпирически: ниже спин жрёт CPU впустую.

## 4. Цифры: зачем всё это

- OpenVPN: 414 Мбит/с через tap-windows против **737 Мбит/с через WinTun** — смена драйвера сама по себе ~1.8x (malwaretips, цит. по первому проходу).
- Ранние замеры Donenfeld (2021): wireguard-go/Wintun по Wi-Fi ~95 Мбит/с против 600 Мбит/с по проводу — WinTun чувствителен к латентности базовой сети (theregister.com).
- wireguard-go на Windows в проде упирается в ~600 Мбит/с–1 Гбит/с на userspace-пути; WireGuardNT (kernel) снимает потолок, но с рисками поставки (тема 45).

## 5. Вердикт: лучшее или слоп

**Лучшее.** WinTun — правильный и единственный практичный L3-датаплан Windows для userspace-VPN: zero-syscall пакетный обмен через shared memory, честная документация по спину, зрелый драйвер. Альтернативы (TAP — L2-оверхед и медленнее; WFP-callout — тема 44; WireGuardNT — риски подписи) хуже или рискованнее.

## 6. Рекомендация «внедрить так»

sora не пишет свой WinTun-код — его пишет движок (sing-box через `sing-tun`). Поэтому «тюнинг WinTun» для sora = **проверка, что движок делает правильные вещи**, плюс своё вокруг:

1. **Проверить в sing-tun**: размер ring capacity сессии (дефолт у многих биндингов — 0x400000/4 MiB из example.c; 8 MiB как у amneziawg-go — разумный минимум для гигабита), наличие spin-before-block в read-пути. Если sing-tun этого не делает — issue/патч апстриму, это дёшево и заметно на >500 Мбит/с.
2. **Батчинг чтения** (`BatchSize() == 1` — известное TODO даже у amneziawg-go): проверить, батчит ли sing-tun `WintunReceivePacket` в цикле до `ERROR_NO_MORE_ITEMS` за один проход (drain-the-ring). Недодрейн кольца = лишние пробуждения на пакет.
3. **MTU интерфейса**: WinTun позволяет до 65535, но ставить 9000 бессмысленно (тема 47). Дефолт 1500/1420.
4. **Defender**: задокументировать исключение для sora-core и движков — реалтайм-скан туннельного трафика (первый проход, тема 46).
5. **Не писать свой Wintun-биндинг** и не форкать драйвер — зрелая компонента, кастомизация не окупится.
6. В диагностику добавить WinTun-версию драйвера и размер кольца (видимость для саппорта).
