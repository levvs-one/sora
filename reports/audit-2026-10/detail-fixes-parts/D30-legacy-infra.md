# D30 — sora-legacy infra (коммиты ed2f2d3, f97d271, 942215a)

## Проверено, консистентно (без изменений)
- Все uses: по SHA; engines.lock (sing-box 1.14.2, xray 26.3.27, mihomo 1.19.32) ↔ fetch.sh ↔ engines.sig ↔ catalog.go ↔ тесты — совпадают.
- csproj 0.2.3 = Sora.iss 0.2.3 = CHANGELOG; KB3033929 и .NET 4.8 закреплены SHA-256.

## Правки
1. legacy.yml: golangci-lint v2.14.0 → v2.15.0 (безопасно: конфиг не использует exhaustive). Эффект: свежие багфиксы линтеров в CI.
2. legacy.yml job control-windows: go-version: 1.26.9 хардкод → go-version-file: core/go.mod. Эффект: убран дрейф версий.
3. packaging/linux/README.md: убраны две ложные фразы (несуществующий пакет интерфейса; «CI собирает пакеты в каждом PR»). Эффект: док не врёт.

## Открытые вопросы
- Версии tooling в телах workflow не покрыты dependabot (только uses:) — предложить периодическую проверку.
- go-win7 с плавающего тега current — SHA-проверка fail-closed, осознанно.
- Бамп движков в engines.lock — продуктовое решение, не тронут.
