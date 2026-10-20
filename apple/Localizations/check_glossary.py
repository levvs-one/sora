#!/usr/bin/env python3
"""Glossary consistency check for Localizable.xcstrings (see GLOSSARY.md).

One concept = one term. For each concept this script scans the en and ru
stringUnit values for known synonym intruders. A hit is a violation unless
the key is in the concept's allowlist, where the intruder word carries a
*different, sanctioned* meaning (documented in GLOSSARY.md).

Usage: python3 check_glossary.py [path/to/Localizable.xcstrings]
Exit code 0 = no violations, 1 = violations found.
"""
import json, re, sys
from pathlib import Path

# concept -> (canonical en, canonical ru, intruders {lang: regex}, allowlist)
CONCEPTS = {
    "server": ("server", "сервер",
               {"en": r"\b(node|endpoint|relay box|host)\b", "ru": r"(хост(?!инг)|конечная точка|узел)"},
               # 'host' = a connection's destination host (Connections screen,
               # host-case transform, extension network hosts) - not a server.
               {"connCopyHost", "hostCase", "extPermNetworkDetail",
                "dnsLeakFixReviewEncryptedDns"}),  # 'endpoint' there = DNS resolver endpoint
    "subscription": ("subscription", "подписка",
                     {"en": r"\b(membership|plan|abonnement)\b", "ru": r"(абонемент|членство)"},
                     # 'plan' in modesGuide = the provider's tariff plan
                     # ("your plan's bandwidth"), not a sora subscription.
                     {"modesGuide"}),
    "connection (state/process)": ("connection / connect", "подключение",
                     {"en": r"\b(link-up|session start)\b", "ru": r"(коннект|подсоединение)"},
                     set()),
    "tunnel": ("tunnel", "туннель",
               {"en": r"\b(tunel)\b", "ru": r"(тоннель|тунель)"},
               set()),
    "chain": ("chain", "цепочка",
              {"en": r"\b(proxy cascade|cascade)\b", "ru": r"(каскад)"},
              set()),
    "profile (network profile)": ("profile", "профиль",
              {"en": r"\b(preset profile|config profile)\b", "ru": r"(пресет профиля)"},
              # 'VPN profile' in state.* = the *system* VPN configuration,
              # a different concept, sanctioned in GLOSSARY.md.
              {"state.vpnProfileNotApproved", "state.vpnProfileMissing",
               "state.profileNotCreated", "state.intentNeedsAppApproval"}),
}

def values(strings, loc):
    for key, entry in strings.items():
        loc_entry = entry.get("localizations", {}).get(loc, {})
        unit = loc_entry.get("stringUnit", {})
        if unit.get("value"):
            yield key, unit["value"]
        for sub in loc_entry.get("substitutions", {}).values():
            for cat in sub.get("variations", {}).get("plural", {}).values():
                v = cat.get("stringUnit", {}).get("value")
                if v: yield key, v

def main():
    path = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).with_name("Localizable.xcstrings"))
    strings = json.loads(path.read_text(encoding="utf-8"))["strings"]
    violations, allowed = [], []
    by_lang = {loc: dict() for loc in ("en", "ru")}
    for loc in by_lang:
        for k, v in values(strings, loc): by_lang[loc].setdefault(k, []).append(v)
    for concept, (cen, cru, intruders, allow) in CONCEPTS.items():
        for lang, pattern in intruders.items():
            for key, texts in by_lang[lang].items():
                if any(re.search(pattern, t, re.IGNORECASE) for t in texts):
                    (allowed if key in allow else violations).append((concept, lang, key))
    print(f"checked {len(strings)} keys x (en, ru)")
    for concept, lang, key in allowed:
        print(f"  allowed (sanctioned distinct meaning, GLOSSARY.md): [{concept}] {lang} {key}")
    if violations:
        for concept, lang, key in violations:
            print(f"  VIOLATION: [{concept}] {lang} {key}")
        print(f"RESULT: {len(violations)} violation(s)")
        return 1
    print(f"RESULT: 0 violations, {len(allowed)} sanctioned exception(s)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
