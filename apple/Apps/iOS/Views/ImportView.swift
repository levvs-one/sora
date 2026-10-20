import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Import: paste a link, take it from the clipboard, scan a QR code, or
/// arrive here pre-filled from a deep link / subscription URL hand-off.
/// Success is a count and a close — the imported servers appear in the
/// Servers list under their subscription group.
public struct ImportView: View {
    @EnvironmentObject private var servers: ServersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @StateObject private var model: ImportViewModel
    @State private var showScanner = false

    public init(prefill: String) {
        // The real model is injected in `onAppear` via the environment's
        // ServersViewModel; StateObject is created with a placeholder
        // store-backed model replaced below by `ImportViewModel(servers:)`
        // in task — see `bootstrap`.
        _model = StateObject(wrappedValue: ImportViewModel(
            servers: ServersViewModel(store: JSONFileProfileStore.sharedContainer())))
        self.prefill = prefill
    }
    private let prefill: String

    public var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.space4) {
                Text("importExplainer")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.ink2(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: $model.input)
                    .frame(minHeight: DesignTokens.space7 * 2)
                    .padding(DesignTokens.space2)
                    .background(DesignTokens.field(for: scheme),
                                in: RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .accessibilityLabel(Text("importPasteLink"))
                    .accessibilityHint(Text("importPasteHint"))

                HStack(spacing: DesignTokens.space3) {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("qrFromClipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity, minHeight: DesignTokens.hitTarget)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(Text("qrFromClipboard"))
                    .accessibilityHint(Text("importClipboardHint"))

                    Button {
                        showScanner = true
                    } label: {
                        Label("qrScan", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity, minHeight: DesignTokens.hitTarget)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(Text("qrScan"))
                    .accessibilityHint(Text("qrScanHint"))
                }

                if let url = model.pendingSubscriptionURL {
                    VStack(alignment: .leading, spacing: DesignTokens.space2) {
                        Text("importSubscriptionURLTitle")
                            .font(.headline)
                        Text(url.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.ink2(for: scheme))
                            .lineLimit(2)
                            .truncationMode(.middle)
                        Text("importSubscriptionURLMessage")
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.ink2(for: scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignTokens.space3)
                    .background(DesignTokens.surface(for: scheme),
                                in: RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .accessibilityElement(children: .combine)
                }

                if let count = model.importedCount {
                    Label {
                        Text("importDone \(count)")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignTokens.statusOn)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }

                Spacer()
            }
            .padding(DesignTokens.space4)
            .background(DesignTokens.background(for: scheme))
            .navigationTitle(Text("importTitle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                        .accessibilityLabel(Text("close"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("add") {
                        model.servers = servers
                        model.importFromText()
                    }
                    .disabled(model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(Text("add"))
                    .accessibilityHint(Text("importConfirmHint"))
                }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { code in
                    showScanner = false
                    model.servers = servers
                    model.importScanned(code)
                }
            }
            .alert("importTitle", isPresented: alertPresented) {
                Button("close", role: .cancel) { model.alertKey = nil }
            } message: {
                Text(LocalizedStringKey(model.alertKey ?? "alert.importFailed"))
            }
            .onAppear {
                model.servers = servers
                if model.input.isEmpty, !prefill.isEmpty {
                    model.input = prefill
                }
            }
        }
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let text = UIPasteboard.general.string,
           let found = ClipboardPayloadFinder.find(in: text) ?? (text.isEmpty ? nil : text) {
            model.input = found
        }
        #endif
    }

    private var alertPresented: Binding<Bool> {
        Binding(get: { model.alertKey != nil },
                set: { if !$0 { model.alertKey = nil } })
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ImportView(prefill: "").preferredColorScheme(.dark)
            ImportView(prefill: "").preferredColorScheme(.light)
        }
        .environmentObject(ServersViewModel(store: JSONFileProfileStore(directory: FileManager.default.temporaryDirectory)))
    }
}
#endif
