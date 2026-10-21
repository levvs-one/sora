import SwiftUI
import SoraCore

/// Manual server editor for iOS 13–14 — same fields and inline,
/// plain-language validation as the main app's ServerEditView (the
/// Save button stays disabled with the reason under the field; no red
/// banners). SwiftUI-1 deltas: single-line `TextField` for the link
/// (no `axis:` parameter, iOS 16), no `autocorrectionDisabled()` /
/// `textInputAutocapitalization` modifiers (iOS 15 — the UIKit
/// behaviours are set through the fields' defaults here; see
/// TARGET-NOTES), dismissal via `presentationMode`.
struct LegacyServerEditView: View {
    @EnvironmentObject private var servers: ServersViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var scheme

    @State private var linkText = ""
    @State private var name = ""
    @State private var proto: ProxyProtocol = .vless
    @State private var address = ""
    @State private var portText = "443"
    @State private var credential = ""   // uuid or password, per protocol
    @State private var method = "chacha20-ietf-poly1305"
    @State private var sni = ""
    @State private var showSecret = false
    @State private var linkErrorKey: String?

    init() {}

    private var port: Int? { Int(portText) }
    private var isValid: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty
            && (port.map { (1...65535).contains($0) } ?? false)
            && !credential.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("serverEditLinkSection")) {
                    TextField("importPasteLink", text: $linkText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibility(label: Text("importPasteLink"))
                        .accessibility(hint: Text("serverEditLinkHint"))
                    Button("serverEditFillFromLink") { fillFromLink() }
                        .disabled(linkText.isEmpty)
                        .accessibility(hint: Text("serverEditFillHint"))
                    if linkErrorKey != nil {
                        Text(LocalizedStringKey(linkErrorKey!))
                            .font(.footnote)
                            .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    }
                }

                Section(header: Text("customServerAdd")) {
                    TextField("customServerName", text: $name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibility(label: Text("customServerName"))
                        .accessibility(hint: Text("customServerNameHint"))
                    Picker("customServerProtocol", selection: $proto) {
                        ForEach(ProxyProtocol.allCases, id: \.self) { option in
                            Text(option.rawValue.uppercased()).tag(option)
                        }
                    }
                    .accessibility(label: Text("customServerProtocol"))
                    .accessibility(hint: Text("serverEditProtocolHint"))
                    TextField("customServerAddress", text: $address)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibility(label: Text("customServerAddress"))
                        .accessibility(hint: Text("customServerAddressHint"))
                    if !address.isEmpty && address.contains(" ") {
                        Text("customServerAddressInvalid")
                            .font(.footnote)
                            .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    }
                    TextField("customServerPort", text: $portText)
                        .keyboardType(.numberPad)
                        .accessibility(label: Text("customServerPort"))
                        .accessibility(hint: Text("customServerPortHint"))
                    if port == nil || !(1...65535).contains(port ?? 0) {
                        Text("customServerPortInvalid")
                            .font(.footnote)
                            .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    }
                }

                Section(header: Text("customServerCredentials")) {
                    HStack(spacing: LegacyDesignTokens.space2) {
                        Group {
                            if showSecret {
                                TextField("customServerCredentials", text: $credential)
                            } else {
                                SecureField("customServerCredentials", text: $credential)
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibility(label: Text("customServerCredentials"))
                        Button(action: { showSecret.toggle() }) {
                            Image(systemName: showSecret ? "eye.slash" : "eye")
                        }
                        .accessibility(label: Text(showSecret
                            ? "customServerHideSecret" : "customServerShowSecret"))
                    }
                    if proto == .shadowsocks {
                        TextField("serverEditMethod", text: $method)
                            .accessibility(label: Text("serverEditMethod"))
                    }
                    TextField("serverEditSNI", text: $sni)
                        .accessibility(label: Text("serverEditSNI"))
                        .accessibility(hint: Text("serverEditSNIHint"))
                }
            }
            .navigationBarTitle(Text("customServerAdd"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("cancel") { presentationMode.wrappedValue.dismiss() }
                    .accessibility(label: Text("cancel")),
                trailing: Button("add") { save() }
                    .disabled(!isValid)
                    .accessibility(label: Text("add"))
                    .accessibility(hint: Text("serverEditSaveHint")))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func fillFromLink() {
        do {
            let parsed = try LinkParser.parse(linkText.trimmingCharacters(in: .whitespacesAndNewlines))
            name = parsed.name; proto = parsed.protocol
            address = parsed.address; portText = String(parsed.port)
            credential = parsed.uuid.isEmpty ? parsed.password : parsed.uuid
            method = parsed.method.isEmpty ? method : parsed.method
            sni = parsed.tls.serverName
            linkErrorKey = nil
        } catch {
            linkErrorKey = ParseFailureLocalization.key(
                forErrorDescription: String(describing: error))
        }
    }

    private func save() {
        guard let portValue = port, isValid else { return }
        var profile = ServerProfile(
            name: name, protocol: proto, address: address, port: portValue)
        switch proto {
        case .vless, .vmess: profile.uuid = credential
        case .shadowsocks:
            profile.password = credential; profile.method = method
        default: profile.password = credential
        }
        if !sni.isEmpty {
            profile.tls = TLSSpec(enabled: true, serverName: sni)
        }
        // Same round-trip id derivation as the main app: reparse
        // through the encoder/parser pair, which also validates.
        if let link = LinkEncoder.encode(profile),
           let reparsed = try? LinkParser.parse(link) {
            profile = reparsed
        }
        servers.upsert(profile)
        presentationMode.wrappedValue.dismiss()
    }
}
