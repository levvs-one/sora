#!/usr/bin/env python3
"""Adds the UI-zone l10n keys (19) to app_en.arb, app_ru.arb, strings.dart
(abstract) and all strings_XX.dart implementations.

Run from app/lib/l10n. Idempotent: skips keys that already exist.
Source of truth for values is the KEYS table below (en + ru; other
locales get the English fallback, matching the repo's convention).

Zone: extensions UI (40-agent wave, UI zone lead). No Flutter SDK in this
environment, so the generated strings_*.dart are edited by hand in the
exact shape flutter gen-l10n would emit.
"""
import glob
import json
import sys

KEYS = [
    ("extToggleEnabled", "Enable {name}", "Включить {name}", {"name": "String"}),
    ("extSearchInstalled", "Search installed", "Поиск установленных", None),
    ("extUpdateAll", "Update all", "Обновить все", None),
    ("extUpdatesAvailable", "{count} updates available", "Доступно обновлений: {count}", {"count": "int"}),
    ("extUpdatedCount", "{count} updated", "Обновлено: {count}", {"count": "int"}),
    ("extRiskNormal", "Normal", "Обычный", None),
    ("extRiskSensitive", "Sensitive", "Чувствительный", None),
    ("extRiskDangerous", "High risk", "Высокий риск", None),
    ("extPermissionsRemoved", "No longer requested:", "Больше не запрашивается:", None),
    ("extUpdateFailedKept", "The previous version is still installed.", "Предыдущая версия осталась установлена.", None),
    ("extConflictsTitle", "Extension conflicts", "Конфликты расширений", None),
    ("extConflictsIntro",
     "These extensions want the same thing. Choose which one wins \u2014 the other stays installed, but its contested capability is paused.",
     "Эти расширения претендуют на одно и то же. Выберите победителя \u2014 другое останется установлено, но спорная возможность будет приостановлена.",
     None),
    ("extConflictRoutingRules", "Routing rules", "Правила маршрутизации", None),
    ("extConflictTheme", "App theme", "Тема приложения", None),
    ("extConflictNetHooks", "Network hooks", "Сетевые хуки", None),
    ("extConflictWinner", "{name} wins", "Побеждает: {name}", {"name": "String"}),
    ("extConflictsCount", "{count} conflicts need your decision", "Требуют решения: {count}", {"count": "int"}),
    ("extConflictsResolve", "Resolve", "Решить", None),
    ("extConflictNote", "Your choice is saved on this device and applied by the engine.",
     "Ваш выбор сохраняется на этом устройстве и применяется движком.", None),
]


def dart_sig(key, params):
    if params is None:
        return f"String get {key};"
    ps = ", ".join(f"{t} {n}" for n, t in params.items())
    return f"String {key}({ps});"


def dart_impl(key, value, params):
    v = value
    for n in (params or {}):
        v = v.replace("{" + n + "}", "${" + n + "}")
    if params is None:
        return f"  @override\n  String get {key} => '{v}';"
    ps = ", ".join(f"{t} {n}" for n, t in params.items())
    return f"  @override\n  String {key}({ps}) => '{v}';"


def arb_block(key, value, params):
    lines = [f'  "{key}": "{value}",']
    if params:
        ph = ", ".join(f'"{n}": {{"type": "{t}"}}' for n, t in params.items())
        lines.append(f'  "@{key}": {{"placeholders": {{{ph}}}}},')
    return lines


def insert_after(lines, anchor_pred, new_lines):
    idx = next(i for i, l in enumerate(lines) if anchor_pred(l))
    # idempotency: skip blocks whose first key already follows the anchor
    return lines[: idx + 1] + new_lines + lines[idx + 1:]


added = 0

# 1. strings.dart (abstract)
p = "strings.dart"
lines = open(p, encoding="utf-8").read().split("\n")
new = ["  " + dart_sig(k, pr) for k, _, _, pr in KEYS
       if f" {dart_sig(k, pr)}" not in "\n".join(lines)]
if new:
    lines = insert_after(lines,
                         lambda l: l.strip() == "String get extDisabled;",
                         new)
    open(p, "w", encoding="utf-8").write("\n".join(lines))
    added += 1
    print(f"strings.dart: +{len(new)} abstract")

# 2. arb files
for p, col in [("app_en.arb", 1), ("app_ru.arb", 2)]:
    raw = open(p, encoding="utf-8").read().split("\n")
    block = []
    for k, en, ru, pr in KEYS:
        if f'"{k}"' in "\n".join(raw):
            continue
        block.extend(arb_block(k, en if col == 1 else ru, pr))
    if block:
        raw = insert_after(raw, lambda l: '"extDisabled"' in l, block)
        open(p, "w", encoding="utf-8").write("\n".join(raw))
        added += 1
    d = json.load(open(p, encoding="utf-8"))
    assert all(k in d for k, _, _, _ in KEYS), p
    print(p, "ok")

# 3. locale impls
for p in sorted(glob.glob("strings_*.dart")):
    if p == "strings.dart":
        continue
    is_ru = (p == "strings_ru.dart")
    lines = open(p, encoding="utf-8").read().split("\n")
    new = []
    for k, en, ru, pr in KEYS:
        if any(k in l for l in lines):
            continue
        new.append(dart_impl(k, ru if is_ru else en, pr))
    if new:
        lines = insert_after(
            lines, lambda l: "String get extDisabled =>" in l, new)
        open(p, "w", encoding="utf-8").write("\n".join(lines))
        added += 1
print("done, files touched:", added)
