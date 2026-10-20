# 66. IVPN: модель доверенных сетей и firewall UX — точная спека для копирования

Дата: 2026-10-20. Группа G, третий проход.

## Первоисточники

- IVPN blog (2018): «New trusted Wi-Fi networks feature» — исходная спека фичи.
- Исходники: `github.com/ivpn/ios-app` — `NetworkProtectionViewController.swift`, `NetworkProtectionRulesViewController.swift` (модель, ключи настроек, интеграция с `ConnectionManager.evaluateConnection()`).
- Macworld review: описание firewall («работает независимо от приложения»).
- Сверка с sora (read-only): `core/profiles/profiles.go` — профили с триггерами/матчингом (SSID/ASN) и `AutoApply` **есть**, но **уровней доверия нет**; `core/guard/` (nftables/WFP) есть.

## 1. Точная спека IVPN (как это устроено)

**Три уровня доверия сети:**
| Уровень | Поведение |
|---|---|
| Trusted | авто-**отключение** VPN |
| Untrusted | авто-**подключение** VPN |
| None/Default | действуют дефолтные правила |

**Идентификация сетей:**
- Wi-Fi — по **SSID**, каждая сеть хранится отдельно (Core Data `Network` entity).
- Cellular — **одна системная настройка** (не per-оператор).
- Ethernet — аналогично отдельной сущностью (в десктопных клиентах).
- Неизвестная сеть → **Default**, а дефолт IVPN рекомендует ставить **untrusted** («в большинстве случаев ничего делать не нужно при подключении к новой сети»).

**Матрица действий** (настраивается отдельно для trusted/untrusted):
- При входе в **untrusted**: автоматически подключить VPN **и/или** включить firewall.
- При входе в **trusted**: автоматически отключить VPN **и/или** выключить firewall.
- Отдельный тумблер: **блокировать LAN на untrusted-сетях** (только OpenVPN/WireGuard).

**Ключи настроек (iOS, дословно):** `networkProtectionEnabled`, `networkProtectionUntrustedConnect`, `networkProtectionUntrustedBlockLan`, `networkProtectionTrustedDisconnect`.

**Интеграция:** `NetworkManager` следит за сменой сети в реальном времени → `ConnectionManager.evaluateConnection()` применяет правила; на iOS — через VPN on-demand rules.

**Кейсы, ради которых фича существует** (из анонса IVPN):
1. «VPN только для Wi-Fi-безопасности»: клиент сам подключается на чужих сетях, дома — нет.
2. **Вложенные туннели:** дома стоит VPN-роутер — подключать клиентский VPN поверх него = двойной туннель, деградация. Trusted-сеть решает.

**Firewall UX:** у IVPN firewall — это kill switch, который **работает независимо от приложения** (отдельный от GUI контур). Включается/выключается как часть сетевых правил, а не как «кнопка в приложении».

## 2. Что копировать один в один

1. **Трёхуровневую модель** trusted/untrusted/default с дефолтом **untrusted для новых сетей** (fail-closed — правильный дефолт для VPN-клиента).
2. **Матрицу действий 2×2:** (untrusted: connect VPN / enable firewall) × (trusted: disconnect VPN / disable firewall) + отдельный «block LAN on untrusted».
3. **Идентификацию по SSID** для Wi-Fi, одну настройку для cellular, дефолт для неизвестных.
4. **Firewall как независимый контур** (у sora задел есть — `core/guard/`): переключение firewall не должно требовать запущенного UI.
5. **Кейс «не делать двойной туннель»** — явно в UI: «дома у вас VPN-роутер? Отметьте сеть доверенной».

## 3. Чего НЕ копировать / где IVPN слабоват

- У IVPN нет привязки доверия к **идентичности точки доступа** (BSSID): злой твин с тем же SSID («HomeWiFi» в кафе) будет считаться доверенным. Sora должна хранить **SSID+BSSID** и предупреждать при смене BSSID у доверенной сети («SSID знаком, точка доступа новая — считать недоверенной?»).
- Нет учёта **captive portal**: на untrusted с captive portal авто-подключение VPN до авторизации в портале = вечный реконнект. Нужен детектор портала (HTTP 204-probe) с паузой авто-правил.
- iOS-реализация завязана на on-demand rules; на десктопе sora — свой `NetworkManager`-мониторинг (уже есть триггеры в profiles).

## Вердикт «лучшее или слоп»

**Лучшее:** fail-closed дефолт (новые сети — untrusted), матрица действий вместо одного тумблера, firewall как независимый контур, явный кейс против двойных туннелей.

**Слоп:** доверять только SSID без BSSID; авто-правила без детектора captive portal.

## Рекомендация «внедрить так» (ложится на существующие `core/profiles`)

1. В `Profile`/`Match`: поле `trust: trusted|untrusted|inherit`; глобальный `default_trust = untrusted` для неизвестных сетей.
2. Действия при смене сети (расширение `Apply`): `on_untrusted: {connect_vpn, enable_firewall, block_lan}`, `on_trusted: {disconnect_vpn, disable_firewall}`.
3. Хранить SSID+BSSID; при смене BSSID у trusted — даунгрейд до untrusted + уведомление.
4. Captive-portal probe перед применением авто-правил.
5. UI: в карточке текущей сети (как у IVPN — сеть видна на главном экране) — переключатель доверия; список сетей с уровнями; явный хинт про VPN-роутер дома.
6. Firewall (`core/guard`): режим strict переживает закрытие UI и ребут (связка с темой 68 — персистентность).
