import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Import for iOS 13–14 — same flows as the main app's ImportView:
/// paste a link, take it from the clipboard, scan a QR code, or
/// arrive pre-filled from a deep link. SwiftUI-1 deltas: the text
/// editor is the UITextView wrapper (`TextEditor` is iOS 14), the
/// model is `@ObservedObject` (no `@StateObject`), dismissal goes
/// through `presentationMode` (no `\.dismiss` before iOS 15), and
/// alerts use the classic form.
struct LegacyImportView: View {
    @EnvironmentObject private var servers: ServersViewModel
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var model: ImportViewModel
    @State private var showScanner = false
    private let prefill: String

    init(prefill: String) {
        // Same placeholder-then-rebind pattern as the main app: the
        // model is created before the environment's ServersViewModel
        // is known and rebound in `onAppear`.
        _model = ObservedObject(wrappedValue: ImportViewModel(
            servers: ServersViewModel(store: JSONFileProfileStore.sharedContainer())))
        self.prefill = prefill
    }

    var body: some View {
        NavigationView {
            VStack(spacing: LegacyDesignTokens.space4) {
                Text("importExplainer")
                    .font(.subheadline)
                    .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                    .frame(maxWidth: CGFloat.infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                LegacyMultilineTextField(text: $model.input)
                    .frame(minHeight: LegacyDesignTokens.space7 * 2)
                    .padding(LegacyDesignTokens.space2)
                    .background(
                        RoundedRectangle(cornerRadius: LegacyDesignTokens.radiusMedium)
                            .fill(LegacyDesignTokens.field(for: scheme)))
                    .accessibility(label: Text("importPasteLink"))
                    .accessibility(hint: Text("importPasteHint"))

                HStack(spacing: LegacyDesignTokens.space3) {
                    Button(action: pasteFromClipboard) {
                        LegacyLabel(titleKey: "qrFromClipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: CGFloat.infinity,
                                   minHeight: LegacyDesignTokens.hitTarget)
                    }
                    .buttonStyle(LegacyBorderedButtonStyle())
                    .accessibility(label: Text("qrFromClipboard"))
                    .accessibility(hint: Text("importClipboardHint"))

                    Button(action: { showScanner = true }) {
                        LegacyLabel(titleKey: "qrScan", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: CGFloat.infinity,
                                   minHeight: LegacyDesignTokens.hitTarget)
                    }
                    .buttonStyle(LegacyBorderedButtonStyle())
                    .accessibility(label: Text("qrScan"))
                    .accessibility(hint: Text("qrScanHint"))
                }

                if model.pendingSubscriptionURL != nil {
                    subscriptionHandOff
                }

                if model.importedCount != nil {
                    HStack(spacing: LegacyDesignTokens.space2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(LegacyDesignTokens.statusOn)
                        Text("importDone \(model.importedCount!)")
                    }
                    .frame(maxWidth: CGFloat.infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }

                Spacer()
            }
            .padding(LegacyDesignTokens.space4)
            .background(LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all))
            .navigationBarTitle(Text("importTitle"), displayMode: .inline)
            .navigationBarItems(
                leading: Button("close") { presentationMode.wrappedValue.dismiss() }
                    .accessibility(label: Text("close")),
                trailing: Button("add") {
                    model.servers = servers
                    model.importFromText()
                }
                .disabled(model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibility(label: Text("add"))
                .accessibility(hint: Text("importConfirmHint")))
            .sheet(isPresented: $showScanner) {
                LegacyQRScannerView { code in
                    showScanner = false
                    model.servers = servers
                    model.importScanned(code)
                }
            }
            .alert(isPresented: alertBinding) { alert }
            .onAppear {
                model.servers = servers
                if model.input.isEmpty && !prefill.isEmpty {
                    model.input = prefill
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    /// A pasted subscription URL is handed over, not silently fetched
    /// — identical semantics (and strings) to the main app.
    private var subscriptionHandOff: some View {
        VStack(alignment: .leading, spacing: LegacyDesignTokens.space2) {
            Text("importSubscriptionURLTitle")
                .font(.headline)
            Text(model.pendingSubscriptionURL!.absoluteString)
                .font(.footnote)
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .lineLimit(2)
                .truncationMode(.middle)
            Text("importSubscriptionURLMessage")
                .font(.footnote)
                .foregroundColor(LegacyDesignTokens.ink2(for: scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: CGFloat.infinity, alignment: .leading)
        .padding(LegacyDesignTokens.space3)
        .background(
            RoundedRectangle(cornerRadius: LegacyDesignTokens.radiusMedium)
                .fill(LegacyDesignTokens.surface(for: scheme)))
        .accessibilityElement(children: .combine)
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let text = UIPasteboard.general.string,
           let found = ClipboardPayloadFinder.find(in: text) ?? (text.isEmpty ? nil : text) {
            model.input = found
        }
        #endif
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { model.alertKey != nil },
                set: { if !$0 { model.alertKey = nil } })
    }

    private var alert: Alert {
        Alert(title: Text("importTitle"),
              message: Text(LocalizedStringKey(model.alertKey ?? "alert.importFailed")),
              dismissButton: .cancel(Text("close")) { model.alertKey = nil })
    }
}
