import SwiftUI

/// Settings: DNS, kill switch, split tunnelling, notifications, theme.
/// Every control writes through `SettingsViewModel` into SoraCore's
/// `AppSettings` (single source of truth shared with config building);
/// changes apply on the next connect, which the footer states plainly.
public struct SettingsView: View {
    @EnvironmentObject private var model: SettingsViewModel
    @EnvironmentObject private var tunnel: TunnelManager
    @Environment(\.colorScheme) private var scheme
    @AppStorage("sora.theme.v1") private var themeRaw: String = "system"

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: dnsBinding)
                        .frame(minHeight: DesignTokens.space7)
                        .accessibilityLabel(Text("dns"))
                        .accessibilityHint(Text("dnsHint"))
                    Text("dnsHint")
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                } header: { Text("dns") }

                Section {
                    Toggle(isOn: killSwitchBinding) {
                        Text("killSwitch")
                    }
                    .frame(minHeight: DesignTokens.hitTarget)
                    .accessibilityLabel(Text("killSwitch"))
                    .accessibilityHint(Text("settingsKillSwitchHint"))
                    Text("settingsKillSwitchNote")
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                } header: { Text("sectionConnection") }

                Section {
                    TextEditor(text: excludedBinding)
                        .frame(minHeight: DesignTokens.space7)
                        .accessibilityLabel(Text("settingsSplitExcluded"))
                        .accessibilityHint(Text("splitPosHint"))
                    TextEditor(text: includedBinding)
                        .frame(minHeight: DesignTokens.space7)
                        .accessibilityLabel(Text("settingsSplitIncluded"))
                        .accessibilityHint(Text("splitPosHint"))
                    Text("splitPosHint")
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.ink2(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                } header: { Text("splitPos") }

                Section {
                    Toggle(isOn: notificationsBinding) {
                        Text("notifications")
                    }
                    .frame(minHeight: DesignTokens.hitTarget)
                    .accessibilityLabel(Text("notifications"))
                    .accessibilityHint(Text("settingsNotificationsHint"))
                    Picker("theme", selection: $themeRaw) {
                        Text("themeSystem").tag("system")
                        Text("themeDark").tag("dark")
                        Text("themeLight").tag("light")
                    }
                    .accessibilityLabel(Text("theme"))
                    .accessibilityHint(Text("settingsThemeHint"))
                } header: { Text("settings") }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.background(for: scheme))
            .navigationTitle(Text("settings"))
            .onDisappear { model.save() }
        }
    }

    // MARK: Bindings (each writes AppSettings + persists immediately)

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
                set: { enabled in Task { await model.setNotificationsEnabled(enabled) } })
    }
}

/// Maps the stored theme choice to a SwiftUI color scheme; "system"
/// follows the device (nil), dark is the primary theme of the design.
public enum ThemeChoice {
    public static func scheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView().preferredColorScheme(.dark)
            SettingsView().preferredColorScheme(.light)
        }
        .environmentObject(SettingsViewModel(store: JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)))
        .environmentObject(TunnelManager())
    }
}
#endif
