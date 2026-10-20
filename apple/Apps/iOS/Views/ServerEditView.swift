import SwiftUI
import SoraCore

/// Manual server editor over the `ServerProfile` fields, plus a
/// paste-a-link path at the top (the same LinkParser as ImportView).
/// Validation is inline and plain-language (the Flutter add-server
/// screen's `customServer*Required/Invalid` strings) — no red banners,
/// the Save button simply stays disabled with the reason under the field.
public struct ServerEditView: View {
    @EnvironmentObject private var servers: ServersViewModel
    @Environment(\.dismiss) private var dismiss
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

    public init() {}

    private var port: Int? { Int(portText) }
    private var isValid: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty
            && (port.map { (1...65535).contains($0) } ?? false)
            && !credential.isEmpty
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("importPasteLink", text: $linkText, axis: .vertical)
                        .lineLimit(1...3)
                        .truncationMode(.middle)
                        .autocorrectionDisabled()
                        .accessibilityLabel(Text("importPasteLink"))
                        .accessibilityHint(Text("serverEditLinkHint"))
                    Button("serverEditFillFromLink") { fillFromLink() }
                        .disabled(linkText.isEmpty)
                        .accessibilityHint(Text("serverEditFillHint"))
                    if let linkErrorKey {
                        Text(LocalizedStringKey(linkErrorKey))
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.ink2(for: scheme))
                    }
                } header: { Text("serverEditLinkSection") }

                Section {
                    TextField("customServerName", text: $name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel(Text("customServerName"))
                        .accessibilityHint(Text("customServerNameHint"))
                    Picker("customServerProtocol", selection: $proto) {
                        ForEach(ProxyProtocol.allCases, id: \.self) { option in
                            Text(option.rawValue.uppercased()).tag(option)
                        }
                    }
                    .accessibilityLabel(Text("customServerProtocol"))
                    .accessibilityHint(Text("serverEditProtocolHint"))
                    TextField("customServerAddress", text: $address)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel(Text("customServerAddress"))
                        .accessibilityHint(Text("customServerAddressHint"))
                    if !address.isEmpty && address.contains(" ") {
                        Text("customServerAddressInvalid")
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.ink2(for: scheme))
                    }
                    TextField("customServerPort", text: $portText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel(Text("customServerPort"))
                        .accessibilityHint(Text("customServerPortHint"))
                    if port == nil || !(1...65535).contains(port ?? 0) {
                        Text("customServerPortInvalid")
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.ink2(for: scheme))
                    }
                } header: { Text("customServerAdd") }

                Section {
                    HStack(spacing: DesignTokens.space2) {
                        Group {
                            if showSecret {
                                TextField("customServerCredentials", text: $credential)
                            } else {
                                SecureField("customServerCredentials", text: $credential)
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel(Text("customServerCredentials"))
                        Button {
                            showSecret.toggle()
                        } label: {
                            Image(systemName: showSecret ? "eye.slash" : "eye")
                        }
                        .accessibilityLabel(Text(showSecret
                            ? "customServerHideSecret" : "customServerShowSecret"))
                    }
                    if proto == .shadowsocks {
                        TextField("serverEditMethod", text: $method)
                            .autocorrectionDisabled()
                            .accessibilityLabel(Text("serverEditMethod"))
                    }
                    TextField("serverEditSNI", text: $sni)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel(Text("serverEditSNI"))
                        .accessibilityHint(Text("serverEditSNIHint"))
                } header: { Text("customServerCredentials") }
            }
            .navigationTitle(Text("customServerAdd"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .accessibilityLabel(Text("cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add") { save() }
                        .disabled(!isValid)
                        .accessibilityLabel(Text("add"))
                        .accessibilityHint(Text("serverEditSaveHint"))
                }
            }
        }
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
        guard let port, isValid else { return }
        var profile = ServerProfile(
            name: name, protocol: proto, address: address, port: port)
        switch proto {
        case .vless, .vmess: profile.uuid = credential
        case .shadowsocks:
            profile.password = credential; profile.method = method
        default: profile.password = credential
        }
        if !sni.isEmpty {
            profile.tls = TLSSpec(enabled: true, serverName: sni)
        }
        // The id is content-derived in SoraCore's model; a manually built
        // profile gets its stable id by round-tripping through the
        // encoder/parser pair, which also validates the field set.
        if let link = LinkEncoder.encode(profile),
           let reparsed = try? LinkParser.parse(link) {
            profile = reparsed
        }
        servers.upsert(profile)
        dismiss()
    }
}

#if DEBUG
struct ServerEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ServerEditView().preferredColorScheme(.dark)
            ServerEditView().preferredColorScheme(.light)
        }
        .environmentObject(ServersViewModel(store: JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)))
    }
}
#endif
