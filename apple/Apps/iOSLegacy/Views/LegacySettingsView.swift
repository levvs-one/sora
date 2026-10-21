import SwiftUI

/// Settings for iOS 13–14 — the same controls over the same
/// `AppSettings` (via the shared `SettingsViewModel`) as the main
/// app: DNS, kill switch, split tunnelling, notifications, theme.
/// Changes apply on the next connect; the main app's footer says so
/// and so does this one (same strings).
///
/// Segment-specific honest states (ARCHITECTURE §5.2 ladder for
/// iOS 13–14), rendered in their own section instead of missing rows:
///  * Widgets: on iOS 13 the widget step is SKIPPED ENTIRELY —
///    WidgetKit arrives with iOS 14, this target ships no widget
///    extension (see TARGET-NOTES.md for the 14.0 variant), and the
///    row below says the function lives in the app, key
///    `state.widgetUnavailableIOS13` (proposed, listed for the
///    coordinator — not yet in the strings catalog).
///  * Shortcuts: limited mode (donated activities + quick actions),
///    key `state.shortcutsLimitedMode` (proposed, listed likewise).
/// SwiftUI-1 deltas: multiline editors are UITextView wrappers,
/// theme writes through AppState (no `@AppStorage`), save on
/// disappear via `onDisappear`.
struct LegacySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var model: SettingsViewModel
    @Environment(\.colorScheme) private var scheme

    init() {}

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("dns")) {
                    LegacyMultilineTextField(text: dnsBinding)
                        .frame(minHeight: LegacyDesignTokens.space7)
                        .accessibility(label: Text("dns"))
                        .accessibility(hint: Text("dnsHint"))
                    Text("dnsHint")
                        .font(.footnote)
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("sectionConnection")) {
                    Toggle(isOn: killSwitchBinding) {
                        Text("killSwitch")
                    }
                    .frame(minHeight: LegacyDesignTokens.hitTarget)
                    .accessibility(label: Text("killSwitch"))
                    .accessibility(hint: Text("settingsKillSwitchHint"))
                    Text("settingsKillSwitchNote")
                        .font(.footnote)
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("splitPos")) {
                    LegacyMultilineTextField(text: excludedBinding)
                        .frame(minHeight: LegacyDesignTokens.space7)
                        .accessibility(label: Text("settingsSplitExcluded"))
                        .accessibility(hint: Text("splitPosHint"))
                    LegacyMultilineTextField(text: includedBinding)
                        .frame(minHeight: LegacyDesignTokens.space7)
                        .accessibility(label: Text("settingsSplitIncluded"))
                        .accessibility(hint: Text("splitPosHint"))
                    Text("splitPosHint")
                        .font(.footnote)
                        .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("settings")) {
                    Toggle(isOn: notificationsBinding) {
                        Text("notifications")
                    }
                    .frame(minHeight: LegacyDesignTokens.hitTarget)
                    .accessibility(label: Text("notifications"))
                    .accessibility(hint: Text("settingsNotificationsHint"))
                    Picker("theme", selection: themeBinding) {
                        Text("themeSystem").tag("system")
                        Text("themeDark").tag("dark")
                        Text("themeLight").tag("light")
                    }
                    .accessibility(label: Text("theme"))
                    .accessibility(hint: Text("settingsThemeHint"))
                }

                // The §5.2 ladder, stated on screen: what this system
                // does not have, and where the function lives instead.
                Section(header: Text("settingsLegacyCapabilitiesTitle")) {
                    LegacyCapabilityRow(
                        systemImage: "apps.iphone",
                        titleKey: "settingsWidgetsTitle",
                        stateKey: "state.widgetUnavailableIOS13")
                    LegacyCapabilityRow(
                        systemImage: "command",
                        titleKey: "intentStatusTitle",
                        stateKey: LegacyShortcuts.modeDescriptionKey)
                }
            }
            .background(LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all))
            .navigationBarTitle(Text("settings"), displayMode: .inline)
            .onDisappear { model.save() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: Bindings (each writes AppSettings + persists immediately,
    // exactly like the main app's SettingsView)

    private var dnsBinding: Binding<String> {
        Binding(get: { model.dnsText }, set: { model.dnsText = $0; model.save() })
    }
    private var killSwitchBinding: Binding<Bool> {
        Binding(get: { model.settings.killSwitch },
                set: { model.settings.killSwitch = $0; model.save() })
    }
    private var excludedBinding: Binding<String> {
        Binding(get: { model.excludedRoutesText },
                set: { model.excludedRoutesText = $0; model.save() })
    }
    private var includedBinding: Binding<String> {
        Binding(get: { model.includedRoutesText },
                set: { model.includedRoutesText = $0; model.save() })
    }
    private var notificationsBinding: Binding<Bool> {
        Binding(get: { model.notificationsEnabled },
                set: { enabled in LegacyTask.run { await model.setNotificationsEnabled(enabled) } })
    }
    private var themeBinding: Binding<String> {
        Binding(get: { appState.themeRaw }, set: { appState.themeRaw = $0 })
    }
}

/// One honest-capability row: what the surface is, and its state on
/// this system in plain language. Never a greyed-out fake control.
private struct LegacyCapabilityRow: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    let stateKey: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: LegacyDesignTokens.space3) {
            Image(systemName: systemImage)
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .accessibility(hidden: true)
            VStack(alignment: .leading, spacing: LegacyDesignTokens.space1) {
                Text(titleKey)
                    .foregroundColor(LegacyDesignTokens.ink(for: scheme))
                Text(LocalizedStringKey(stateKey))
                    .font(.footnote)
                    .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(minHeight: LegacyDesignTokens.rowMinHeight)
        .accessibilityElement(children: .combine)
        .accessibility(label: Text(titleKey))
        .accessibility(value: Text(LocalizedStringKey(stateKey)))
    }
}
