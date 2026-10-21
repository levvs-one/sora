# CENSOR-FP — НЕЗАВИСИМОЕ РЕВЬЮ (фингерпринты: uTLS/JA3/JA4/ECH/ALPN/PQ)

Ревьюер: независимый, код не правил. Объект: коммиты `5b6337fa`, `7b459128`,
`de0ee41a`, `288353aa`, `84b35166`; отчёт автора `reports/CENSOR-FP.md`.
Ветка `bugfix/audit-2026-10-19`, ревью на чистом worktree HEAD `86c9c2a2`
(основное дерево загрязнено конкурентными WIP соседей — все проверки кода и
тестов выполнены в detached-worktree на HEAD, мутации — только там, удалён).
Бинари: `~/workspace/.engines-amd64` — sing-box 1.14.3-lx.22, Xray 26.10.17,
mihomo 1.19.32 (версии сверены по `--version`/`-v` самих бинарей).
Пуша не было, коммитов ревьюера нет.

## ИТОГОВЫЙ ВЕРДИКТ: **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ**

Ядро отдела — ECH-армор, единый резолвер, байтовый анализ и пробы по захватам —
подтверждено независимыми прогонами на реальных бинарях, включая ручной разбор
ClientHello и ручной `sing-box check`. Одно серьёзное замечание в собственной
зоне FP (гейт KeyShare не замкнут для mihomo — каталог, тест P1 красный на HEAD)
и одно известное автору незамкнутое подключение проб к продакшн-селекции.

## Таблица вердиктов 1–7

| # | Пункт | Вердикт |
|---|---|---|
| 1 | ECH-армор (главный баг) | **ПРИНЯТЬ** |
| 2 | Единый источник политики | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 3 | Захваты, не декларации (probeexec/AnalyzeHello) | **ПРИНЯТЬ** |
| 4 | KeyShare-гейт | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ (серьёзное, Major-1)** |
| 5 | Инциденты честности | **ПРИНЯТЬ** |
| 6 | Адаптивность (watchdog, шов проб) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 7 | Мелочи | **ПРИНЯТЬ** |

---

## 1. ECH-армор — ПРИНЯТЬ

Подтверждено своими руками на реальном sing-box lx.22 (свой тест в worktree,
рендер штатным `singbox.Render` из плана с пином в исторической метке):

- Рендер из пина `-----BEGIN ECHCONFIG-----` пишет канонические
  `-----BEGIN ECH CONFIGS-----`; `sing-box check` такой конфиг **принимает**
  (exit 0, пустой вывод).
- Тот же конфиг с меткой, заменённой обратно на `ECHCONFIG`, бинарь
  **отвергает**: `FATAL initialize outbound[0] trojan[...]: invalid ECH configs pem`.
- Поиск по репо (HEAD): производственный код старой метки не пишет — `ECHCONFIG`
  встречается только в комментариях (`core/engine/echconfig.go:17`,
  `core/engine/singbox/render.go:456`) и в тестах как *входной* пин исторической
  формы. Пишут ровно три места, все через общие хелперы:
  sing-box → `engine.ECHConfigPEM` (`singbox/render.go:459`), mihomo и Xray →
  `engine.ECHConfigListBase64` (`mihomo/proxy.go:485`, `xray/render.go:389`).
- ECH на всех трёх движках по факту: перепрогон `TestProbeRealBinaries`
  (SORA_ENGINES_DIR=пины) — **PASS, 74.9 с**: ECH = ProbeAccepted для
  sing-box/mihomo/Xray, т.е. внешний SNI захваченного hello равен
  `public.example.com` (public_name пина), а не заявленному SNI.
- Боковое утверждение автора «Xray принимает даже мусорный base64» проверено
  вручную: конфиг с `echConfigList: "!!!not-base64-garbage!!!"` —
  `xray run -test` отвечает `Configuration OK`. Конфиг-чек у Xray оракулом не
  является, решает захват — как и написано у автора.

## 2. Единый источник политики — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- `ResolveFingerprint` (`core/engine/fingerprint_policy.go:164`) — единственная
  точка разрешения: вызовы только из трёх рендереров (singbox/render.go:431,
  mihomo/proxy.go:450,468, xray/render.go:377,432). Второго резолвера/второй
  ротации поиском не найдено; приватная ротация Xray удалена —
  `xray/render.go:441: var fingerprintRotation = engine.CanonicalRotation`
  (алиас на общие данные, своего среза в рендерере нет), Xray engine.go ходит
  по этому же алиасу.
- Свои векторы (матрица попугай×движок, тест в worktree, 24 комбинации):
  - Xray: все имена как есть, `FingerprintSpellingOK=true` для versioned/auto.
  - sing-box/mihomo: `hellochrome_133/155` → резолв в алиас `"chrome"`,
    SpellingOK=false; `ProbeMissing` с непустой пробой потерю **называет**
    дословно: `fingerprint "hellochrome_133" ... (sing-box cannot spell
    versioned parrots; the alias would be a different ClientHello)`.
  - RotationFor: sing-box/mihomo `[chrome firefox safari randomized]`,
    Xray `[hellochrome_auto firefox safari chrome randomized]` — деградация и
    дедупликация по движку работают.
- Замечания:
  - **(Major-2, общее с п.6)** Гейт SpellingOK живёт только внутри
    `ProbeMissing`, а тот вызывается только из `SelectEngineProbed`, у которого
    в продакшне вызывающих нет (см. п.6). В текущем продакшн-пути
    (`SelectEngine`/`selectPlan`) пининг versioned-попугая на sing-box/mihomo
    **молча** деградирует в алиас на рендере. Деградация честно задокументирована
    в коде и видна в Notes пробы, но отказ/предупреждение пользователю она даст
    только когда шов проб подключат. Автор это эскалировал открыто — не скрытый
    дефект, а зафиксированный остаток.
  - (Minor) `hellochrome_auto` на sing-box/mihomo тоже даёт SpellingOK=false:
    алиасная деградация `_auto → chrome` семантически является задуманным
    алиасом (это канонический дефолт Xray), а гейт классифицирует её как потерю.
    Направление ошибки безопасное (fail-closed), но шумное.
  - (Minor) Нога XHTTP-download у Xray (`xray/render.go:539+`,
    `xhttpDownlinkFingerprint`) — второй, отдельный путь разрешения: берёт
    явный план/hint напрямую, `ResolveFingerprint` не вызывает, зато честно
    отказывает при отсутствии явного попугая. Задокументировано, fail-closed;
    «единственная точка» строго верна для основного TLS-пути.
  - (Minor, предсуществующее) Неизвестное имя (`bogus-parrot`) `ResolveFingerprint`
    пропускает дословно на все движки; защита — только `FingerprintWarning`
    (предупреждение, не отказ) и валид
...[truncated 8327 chars]