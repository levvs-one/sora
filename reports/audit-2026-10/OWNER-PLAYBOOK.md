# Sora / sora-legacy — плейбук владельца после аудита

**Статус на 2026-10-19 21:00 (MSK):** вся кодовая работа выполнена, финальный отчёт — `reports/FIX-REPORT.md`.
Остались только действия, которые кодом не закрываются. Этот файл — пошаговый план на неделю.

---

## 0. Проверка состояния (уже сделано)

- Ветка `bugfix/audit-2026-10-19` существует **локально** в обоих репозиториях, рабочие деревья чистые:
  - `sora`: 49 коммитов поверх `main` (репозиторий: github.com/levvs-one/sora)
  - `sora-legacy`: 29 коммитов поверх `legacy` (репозиторий: github.com/levvs-one/sora-legacy)
- Пуша в GitHub **не было** — решение за тобой.

## 1. Ревью и мерж (твоя dev-машина)

1. **Посмотри сводку:**
   ```bash
   git log --oneline main..bugfix/audit-2026-10-19      # sora
   git diff --stat main...bugfix/audit-2026-10-19
   git log --oneline legacy..bugfix/audit-2026-10-19    # sora-legacy
   ```
   Формат коммитов `[audit-fix][<зона>] <что> (<ID>)`; покрытие всех 93 находок — в таблице раздела 3 FIX-REPORT.md, детали — в `fixlog-*.md`.
2. **Прогон на тулчейнах (этого не было в песочнице):**
   ```bash
   go build ./... && go vet ./... && go test ./...     # оба Go-ядра
   flutter analyze                                      # Dart/UI (sora)
   dotnet build                                         # C# (sora-legacy)
   ```
   Единственный падающий Go-тест (`TestTunAndFakeIPAvoidLANAndEachOther`) падает и на чистом дереве — особенность песочницы, не регрессия.
3. **Ручная проверка:** диплинки `sora://` (Linux/Windows/macOS) и отмена обновления на середине.
4. **Пуш и PR:**
   ```bash
   git push -u origin bugfix/audit-2026-10-19
   ```
   ⚠️ Базовые ветки различаются: **sora → `main`**, **sora-legacy → `legacy`**. Не открывай PR legacy в `main` по ошибке.

## 2. Key ceremony (minisign) — закрывает H1

Плейсхолдер `REPLACE-ME-AFTER-KEY-CEREMONY` сейчас в трёх файлах:
`packaging/install/install.sh`, `packaging/install/install.ps1`, `packaging/linux/sora-update`.
До замены значения скрипты **fail-closed** — установка невозможна (это осознанно).

1. На изолированной офлайн-машине:
   ```bash
   minisign -G -p sora-release.pub -s sora-release.key
   ```
   Секретный ключ `.key` — на офлайн-носитель + бэкап. Никогда в репозиторий и не в CI.
2. Возьми base64-строку из `sora-release.pub` (вторая строка после `untrusted comment:`)
   и замени ею значение по умолчанию в трёх файлах выше.
   Для CI-тестов можно переопределить через env `SORA_MINISIGN_PUBKEY` — так скрипты уже умеют.
3. Процедура каждого релиза:
   ```bash
   sha256sum * > SHA256SUMS
   minisign -S -m SHA256SUMS -s sora-release.key   # → SHA256SUMS.minisig
   ```
   Опубликовать `SHA256SUMS` и `SHA256SUMS.minisig` рядом с артефактами.
4. Задокументируй процедуру ротации: новый ключ → новый релиз с вшитым новым публичным ключом;
   старый ключ подписывает «migration notice».

## 3. Authenticode / Trusted Signing (Windows)

Официальные сборки движков сейчас не подписаны, поэтому принудительный гейт в коде оставлен опциональным —
он бы сломал обновления. План: получить кодовый сертификат или Azure Trusted Signing, подписать установщик
и обновляемые бинарники, опубликовать отпечаток сертификата. После этого включить принудительную проверку.

## 4. Решения, которые нужны от тебя

| Вопрос | Источник | Комментарий |
|--------|----------|-------------|
| Per-machine vs per-user установка (legacy) | LEGACY-H2 вариант A | Требует миграции; решение за тобой |
| Доверие форку sing-box (`Leadaxe/sing-box-lx`) | SORA-M3 | Доверяем как есть / апстрим / сборка из исходников в CI. Без решения M3 неполон |
| DoH-дефолты (Cloudflare/Google) | SORA-L18 | Оставить с документированием или сменить дефолт |
| Политика purge: удалять ли `/var/lib/sora` / `%ProgramData%\Sora` | SORA-L7 | Задокументировать для пользователя |
| `StableKey` с UUID | SORA-L12 | Осознанное «оставить с честным комментарием» или исключить UUID |

## 5. Ops / CI (из FIX-PLAN, раздел 9)

- Включить SLSA / GitHub attestations для релизных артефактов.
- Убедиться, что dependabot покрывает `github-actions` и включён.
- Android — новая разработка; требования уже зафиксированы: `sora-legacy/docs/android-security-requirements.md`.
