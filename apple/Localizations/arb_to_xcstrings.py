#!/usr/bin/env python3
"""Convert sora's Flutter ARB files (app/lib/l10n/app_*.arb) to an Xcode
string catalog (Localizable.xcstrings).

Usage:
    python3 arb_to_xcstrings.py [--arb-dir ../../app/lib/l10n] \
        [--out Localizable.xcstrings]

Rules (honest, no silent invention):
  * Every non-@ key of the English ARB is a catalog key.
  * A locale contributes a translation only when its ARB has the key;
    otherwise the key simply has no localization for that locale and Xcode
    falls back to the development language (en) at runtime. The converter
    prints a per-locale coverage report instead of fabricating strings.
  * Extra Apple-only keys (prefix ``state.``) live in EXTRA_KEYS below with
    full en/ru text; other locales fall back to en until translated.
  * ARB placeholders ``{name}`` become String Catalog format specifiers:
    int -> %lld, double -> %lf, everything else -> %@.
  * ICU plurals (7 keys in sora's ARBs, e.g. ``expiresIn``) become String
    Catalog substitutions: the pattern keeps prefix/suffix around
    ``%#@var@`` and each plural category becomes a variation whose text
    has ``#`` replaced by the typed specifier. ICU ``select`` aborts.
"""
import argparse, json, re, sys
from pathlib import Path

# Apple-only honest system-state strings. Full en + ru; other locales
# intentionally absent -> en fallback (see README.md).
EXTRA_KEYS = {
    # Keys consumed verbatim by Apps/macOS/.../TunnelStatus.swift:
    # `state.\(TunnelPhase.rawValue)` — names must match the enum exactly.
    "state.disconnected": {
        "en": "Not connected", "ru": "Не подключено"},
    "state.connecting": {
        "en": "Connecting…", "ru": "Подключение…"},
    "state.connected": {
        "en": "Connected", "ru": "Подключено"},
    "state.disconnecting": {
        "en": "Disconnecting…", "ru": "Отключение…"},
    "state.reconnecting": {
        "en": "Reconnecting…", "ru": "Переподключение…"},
    "state.extensionNotApproved": {
        "en": "Network extension not approved. Approve Sora in System Settings, then connect.",
        "ru": "Сетевое расширение не одобрено. Одобрите Sora в «Системных настройках», затем подключайтесь."},
    "state.extensionNeedsRestart": {
        "en": "Network extension needs a restart after an update. Restart Sora (a reboot may be needed), then connect.",
        "ru": "Сетевое расширение нужно перезапустить после обновления. Перезапустите Sora (может потребоваться перезагрузка), затем подключайтесь."},
    "state.profileNotCreated": {
        "en": "No VPN profile yet. Tap Connect and allow Sora to add a VPN configuration.",
        "ru": "VPN-профиль ещё не создан. Нажмите «Подключить» и разрешите Sora добавить VPN-конфигурацию."},
    "state.extensionMissing": {
        "en": "This build does not include the network extension, so the tunnel cannot start. Install an official Sora build.",
        "ru": "В этой сборке нет сетевого расширения, поэтому туннель не запустится. Установите официальную сборку Sora."},
    "state.failed": {
        "en": "Connection failed. Details are in Logs — Sora never shows raw system errors here.",
        "ru": "Подключение не удалось. Подробности — в «Журнале»; сырые системные ошибки Sora здесь не показывает."},
    # Keys referenced by Apps/macOS/.../SoraCoreBridge.swift.
    "error.core_unavailable": {
        "en": "Sora core is unavailable in this build.", "ru": "Ядро Sora недоступно в этой сборке."},
    "error.import_empty": {
        "en": "Nothing importable was found in that text.", "ru": "В этом тексте не нашлось ничего, что можно импортировать."},
    # Keys referenced by Apps/iOS/TunnelState.swift (alert.*),
    # Apps/macOS Notifications.swift (app.name, notify.*) and
    # SystemExtensionManager.swift (state.extensionFailed).
    "state.vpnProfileMissing": {
        "en": "No VPN profile yet. Add a server or subscription, then tap Connect — Sora will ask to create the profile.",
        "ru": "VPN-профиля пока нет. Добавьте сервер или подписку и нажмите «Подключить» — Sora предложит создать профиль."},
    "state.tunnelUnavailable": {
        "en": "The tunnel is unavailable in this build (the provider framework is not linked). Install an official Sora build.",
        "ru": "Туннель недоступен в этой сборке (фреймворк провайдера не подключён). Установите официальную сборку Sora."},
    "state.extensionFailed": {
        "en": "The network extension reported a problem. Details are in Logs; try reconnecting, and approve any pending request in System Settings.",
        "ru": "Сетевое расширение сообщило о проблеме. Подробности — в «Журнале»; попробуйте переподключиться и одобрите ожидающий запрос в «Системных настройках», если он есть."},
    "app.name": {"en": "Sora", "ru": "Sora"},
    "alert.noProfileSelected": {
        "en": "No server is selected. Pick a server first, then connect.",
        "ru": "Сервер не выбран. Сначала выберите сервер, затем подключайтесь."},
    "alert.configBuildFailed": {
        "en": "Sora could not build a configuration from the selected server. The server was not changed; try another one or re-import it.",
        "ru": "Sora не смогла собрать конфигурацию из выбранного сервера. Сервер не изменён; попробуйте другой или импортируйте его заново."},
    "alert.profileStoreFailed": {
        "en": "Sora could not save to the profile storage. Your existing profiles were not modified.",
        "ru": "Sora не смогла записать данные в хранилище профилей. Существующие профили не изменены."},
    "alert.providerMessageFailed": {
        "en": "The tunnel extension did not answer. It may have been stopped by the system — try reconnecting.",
        "ru": "Расширение туннеля не ответило. Возможно, система его остановила — попробуйте переподключиться."},
    "alert.importFailed": {
        "en": "Import failed. The text was not recognized as a server, subscription or config; nothing was added.",
        "ru": "Импорт не удался. Текст не распознан как сервер, подписка или конфигурация; ничего не добавлено."},
    "notify.connected": {
        "en": "Connected to %@", "ru": "Подключено к %@"},
    "notify.disconnected": {
        "en": "Disconnected", "ru": "Отключено"},
    "notify.reconnecting": {
        "en": "Connection lost — reconnecting…", "ru": "Соединение потеряно — переподключение…"},
    "notify.reconnected": {
        "en": "Reconnected to %@", "ru": "Снова подключено к %@"},
    "notify.failed.network": {
        "en": "Connection failed: no network. Sora will retry when a network appears.",
        "ru": "Подключение не удалось: нет сети. Sora повторит, когда сеть появится."},
    "notify.failed.server": {
        "en": "Connection failed: the server did not answer. Try another server.",
        "ru": "Подключение не удалось: сервер не отвечает. Попробуйте другой сервер."},
    "notify.failed.auth": {
        "en": "Connection failed: the server rejected the credentials. Re-import or update the subscription.",
        "ru": "Подключение не удалось: сервер отклонил учётные данные. Импортируйте заново или обновите подписку."},
    "notify.failed.config": {
        "en": "Connection failed: the configuration is not valid for this server.",
        "ru": "Подключение не удалось: конфигурация не подходит для этого сервера."},
    "notify.failed.extension": {
        "en": "Connection failed: a problem with the network extension. Check its approval in System Settings.",
        "ru": "Подключение не удалось: проблема с сетевым расширением. Проверьте его одобрение в «Системных настройках»."},
    "notify.failed.generic": {
        "en": "Connection failed. Details are in Logs in Sora.",
        "ru": "Подключение не удалось. Подробности — в «Журнале» Sora."},
    "state.emptyStateActionHint": {
        "en": "Nothing here yet. Use the button above to add the first one.",
        "ru": "Здесь пока пусто. Нажмите кнопку выше, чтобы добавить первый."},
    "state.vpnProfileNotApproved": {
        "en": "VPN profile not approved yet. Open Settings and allow Sora to add a VPN configuration, then try again.",
        "ru": "VPN-профиль ещё не одобрен. Откройте «Настройки» и разрешите Sora добавить VPN-конфигурацию, затем попробуйте снова."},
    "state.vpnProfileApprovalPathIos": {
        "en": "On iOS: Settings → General → VPN & Device Management → Sora → Allow.",
        "ru": "На iOS: «Настройки» → «Основные» → «VPN и управление устройством» → Sora → «Разрешить»."},
    "state.vpnProfileApprovalPathMac": {
        "en": "On macOS: System Settings → General → Login Items & Extensions (or Network → VPN) and approve Sora.",
        "ru": "На macOS: «Системные настройки» → «Основные» → «Объекты входа и расширения» (или «Сеть» → VPN) и одобрите Sora."},
    "state.extensionNotApproved": {
        "en": "The Sora network extension is not approved. Approve it in System Settings, then reconnect.",
        "ru": "Сетевое расширение Sora не одобрено. Одобрите его в «Системных настройках», затем переподключитесь."},
    "state.extensionNeedsRestart": {
        "en": "The network extension was updated and needs a restart. Restart Sora (on macOS a reboot may be required) and reconnect.",
        "ru": "Сетевое расширение обновилось и требует перезапуска. Перезапустите Sora (на macOS может потребоваться перезагрузка) и переподключитесь."},
    "state.extensionInstallFailed": {
        "en": "The network extension could not be installed. Check System Settings for a pending approval and try again.",
        "ru": "Не удалось установить сетевое расширение. Проверьте в «Системных настройках» ожидающее одобрение и попробуйте снова."},
    "state.extensionUpdatePendingApproval": {
        "en": "An updated network extension is waiting for approval. Until it is approved, the previous version keeps working or the tunnel stays off — it is never silently replaced.",
        "ru": "Обновлённое сетевое расширение ждёт одобрения. Пока оно не одобрено, работает прежняя версия или туннель остаётся выключен — подмены без вашего ведома не происходит."},
    "state.reconnectingAfterNetworkChange": {
        "en": "Network changed — reconnecting to the same server…",
        "ru": "Сеть изменилась — переподключаюсь к тому же серверу…"},
    "state.networkChangedOffline": {
        "en": "The new network has no internet connection yet. Sora will reconnect automatically when it appears.",
        "ru": "В новой сети пока нет интернета. Sora переподключится автоматически, как только он появится."},
    "state.autoLaunchUnavailable": {
        "en": "Launch at login is not available on this system version. Sora can still be opened manually; no setting was changed.",
        "ru": "Автозапуск при входе недоступен на этой версии системы. Sora можно открывать вручную; никакие настройки не изменены."},
    "state.killSwitchNeedsExtension": {
        "en": "Kill switch needs the approved network extension. Without it Sora will not pretend traffic is blocked while disconnected.",
        "ru": "Kill switch требует одобренного сетевого расширения. Без него Sora не будет делать вид, что трафик заблокирован при отключении."},
    "state.tunnelStoppedBySystem": {
        "en": "The system stopped the tunnel (for example after an update or a memory limit). Tap Connect to start it again.",
        "ru": "Система остановила туннель (например, после обновления или из-за лимита памяти). Нажмите «Подключить», чтобы запустить его снова."},
    "state.captivePortalDetected": {
        "en": "This Wi-Fi seems to require signing in through a web page. Connect to the portal first, then start Sora.",
        "ru": "Похоже, эта сеть Wi-Fi требует входа через веб-страницу. Сначала войдите на портале, затем запустите Sora."},
    "state.ipv6UnavailableOnNetwork": {
        "en": "IPv6 is not available on this network. Sora continues over IPv4 and blocks IPv6 leaks instead of sending traffic outside the tunnel.",
        "ru": "IPv6 недоступен в этой сети. Sora продолжает работу по IPv4 и блокирует утечки IPv6, а не отправляет трафик мимо туннеля."},
    "state.appGroupUnavailable": {
        "en": "The shared app group is unavailable, so the app and the tunnel extension cannot exchange settings. Reinstalling Sora usually fixes this; your subscriptions are kept in the backup export.",
        "ru": "Общая группа приложений недоступна, поэтому приложение и расширение туннеля не могут обмениваться настройками. Обычно помогает переустановка Sora; подписки сохраните через экспорт резерва."},
    "state.keychainUnavailable": {
        "en": "The system keychain is unavailable right now. Secrets stay stored and are not written anywhere less safe; try again after unlocking the device.",
        "ru": "Системная связка ключей сейчас недоступна. Секреты остаются на месте и не записываются в менее безопасное место; попробуйте снова после разблокировки устройства."},
    "state.reconnectDelayedLowPower": {
        "en": "Low Power Mode is delaying reconnection. Sora will reconnect as soon as the system allows background work.",
        "ru": "Режим энергосбережения задерживает переподключение. Sora переподключится, как только система разрешит фоновую работу."},
    "state.widgetStaleData": {
        "en": "Widget shows the last known state because the tunnel has not reported since. Open Sora to refresh.",
        "ru": "Виджет показывает последнее известное состояние, потому что туннель давно не сообщал данные. Откройте Sora, чтобы обновить."},
    "state.intentNeedsAppApproval": {
        "en": "This shortcut needs the VPN profile to be approved in Sora first. Open Sora once and finish setup, then run the shortcut again.",
        "ru": "Этой быстрой команде сначала нужно одобрение VPN-профиля в Sora. Откройте Sora один раз и завершите настройку, затем запустите команду снова."},
}

LOCALE_MAP = {  # ARB suffix -> BCP 47 used by Xcode
    "zh_Hans": "zh-Hans", "zh_Hant": "zh-Hant", "zh": "zh-Hans",
}
FMT = {"int": "%lld", "double": "%lf", "num": "%lf", "String": "%@", "string": "%@"}

def _fmt(name, ph):
    return FMT.get(ph.get(name, {}).get("type", "String"), "%@")

def convert(value, meta):
    """Return a stringUnit dict, or a full localization dict for plurals."""
    ph = (meta or {}).get("placeholders", {})
    if re.search(r"\{\w+,\s*select", value):
        raise SystemExit(f"ICU select not supported, needs manual port: {value[:80]}")
    m = re.search(r"\{(\w+),\s*plural,\s*", value)
    if not m:
        return {"stringUnit": {"state": "translated",
                "value": re.sub(r"\{(\w+)\}", lambda x: _fmt(x.group(1), ph), value)}}
    var, i, opts = m.group(1), m.end(), {}
    # ICU plural variables are numeric even when the ARB @-metadata omits
    # the type (true for all 7 plural keys in sora's ARBs; the generated
    # strings_en.dart confirms `int` for each).
    if ph.get(var, {}).get("type") in (None, "String", "string"):
        ph = {**ph, var: {"type": "int"}}
    while i < len(value):
        mm = re.match(r"\s*(=\d+|\w+)\{", value[i:])
        if not mm: break
        cat = mm.group(1); i += mm.end(); depth, j = 1, i
        while j < len(value) and depth:
            depth += {"{": 1, "}": -1}.get(value[j], 0); j += 1
        opts[cat] = value[i:j-1]; i = j
        if value[i:].lstrip().startswith("}"): i = value.index("}", i) + 1; break
    prefix = re.sub(r"\{(\w+)\}", lambda x: _fmt(x.group(1), ph), value[:m.start()])
    suffix = re.sub(r"\{(\w+)\}", lambda x: _fmt(x.group(1), ph), value[i:])
    pattern = f"{prefix}%#@{var}@{suffix}"
    variations = {}
    for cat, text in opts.items():
        key = "zero" if cat == "=0" else cat
        text = text.replace("#", _fmt(var, ph))
        text = re.sub(r"\{(\w+)\}", lambda x: _fmt(x.group(1), ph), text)
        variations[key] = {"stringUnit": {"state": "translated", "value": text}}
    return {"stringUnit": {"state": "translated", "value": pattern},
            "substitutions": {var: {"argNum": [mm.group(1) for mm in re.finditer(r"\{(\w+)", value)].index(var) + 1, "formatSpecifier": _fmt(var, ph),
                                    "variations": {"plural": variations}}}}

def main():
    ap = argparse.ArgumentParser()
    here = Path(__file__).resolve().parent
    ap.add_argument("--arb-dir", default=str(here / "../../app/lib/l10n"))
    ap.add_argument("--out", default=str(here / "Localizable.xcstrings"))
    a = ap.parse_args()
    arb_dir = Path(a.arb_dir)
    files = sorted(arb_dir.glob("app_*.arb"))
    if not files: raise SystemExit(f"no ARB files in {arb_dir}")
    data, locales = {}, []
    for f in files:
        suffix = f.stem.removeprefix("app_")
        loc = LOCALE_MAP.get(suffix, suffix)
        if loc not in data: data[loc] = json.loads(f.read_text(encoding="utf-8"))
        else: data[loc].update(json.loads(f.read_text(encoding="utf-8")))
        if loc not in locales: locales.append(loc)
    en = data["en"]
    keys = [k for k in en if not k.startswith("@")]
    strings, report = {}, {}
    for key in keys:
        locs = {}
        for loc in locales:
            v = data[loc].get(key)
            if isinstance(v, str):
                locs[loc] = convert(v, en.get("@" + key))
                report[loc] = report.get(loc, 0) + 1
        strings[key] = {"localizations": locs}
    for key, variants in EXTRA_KEYS.items():
        strings[key] = {"localizations": {loc: {"stringUnit": {"state": "translated", "value": v}}
                                         for loc, v in variants.items()}}
    catalog = {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}
    Path(a.out).write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    total = len(keys)
    print(f"keys={total} extra={len(EXTRA_KEYS)} locales={len(locales)} -> {a.out}")
    for loc in locales:
        print(f"  {loc}: {report.get(loc,0)}/{total} ({100*report.get(loc,0)/total:.1f}%)")
    print(f"  extra state.*: en+ru full ({len(EXTRA_KEYS)} keys), other locales fall back to en")

if __name__ == "__main__":
    main()
