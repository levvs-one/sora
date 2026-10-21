import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

/// QR scanner for iOS 13–14 (AVFoundation) — same capability contract
/// as the main app's QRScannerView: camera presence and authorization
/// are probed at runtime before any session is built; the Simulator
/// and the denied-permission case render the designed `qrNoCamera`
/// state with a route back to paste-import — never a crash, never a
/// black preview pretending to scan. SwiftUI-1 deltas: the activity
/// indicator is the UIKit wrapper (no `ProgressView`), dismissal via
/// `presentationMode`, camera probe on `onAppear` (no `.task`).
struct LegacyQRScannerView: View {
    let onScanned: (String) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var scheme
    @State private var availability: Availability = .checking

    private enum Availability { case checking, available, unavailable }

    init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

    var body: some View {
        NavigationView {
            ZStack {
                LegacyDesignTokens.background(for: scheme).edgesIgnoringSafeArea(.all)
                stateContent
            }
            .navigationBarTitle(Text("qrScanTitle"), displayMode: .inline)
            .navigationBarItems(leading:
                Button("cancel") { presentationMode.wrappedValue.dismiss() }
                    .accessibility(label: Text("cancel")))
            .onAppear {
                availability = Self.probeCamera() ? .available : .unavailable
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var stateContent: some View {
        Group {
            if availability == .checking {
                LegacyActivityIndicator()
                    .accessibility(label: Text("qrScanTitle"))
            } else if availability == .unavailable {
                LegacyEmptyStateView(
                    titleKey: "qrNoCamera",
                    messageKey: "qrNoCameraMessage",
                    actionTitleKey: "close",
                    action: { presentationMode.wrappedValue.dismiss() })
            } else {
                #if canImport(AVFoundation)
                LegacyScannerPreview(onScanned: onScanned)
                    .edgesIgnoringSafeArea(.bottom)
                    .accessibility(label: Text("qrScanTitle"))
                    .accessibility(hint: Text("qrScanHint"))
                #else
                LegacyEmptyStateView(
                    titleKey: "qrNoCamera",
                    messageKey: "qrNoCameraMessage",
                    actionTitleKey: "close",
                    action: { presentationMode.wrappedValue.dismiss() })
                #endif
            }
        }
    }

    /// Runtime capability probe — identical to the main app's: device
    /// has a video capture device AND camera access is not denied.
    /// Not a version branch: camera availability is not version-shaped.
    private static func probeCamera() -> Bool {
        #if canImport(AVFoundation)
        #if targetEnvironment(simulator)
        return false // honest Simulator state, by design
        #else
        guard AVCaptureDevice.default(for: .video) != nil else { return false }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted: return false
        default: return true
        }
        #endif
        #else
        return false
        #endif
    }
}

#if canImport(AVFoundation)
/// AVCaptureSession preview + metadata output — the same session
/// discipline as the main app's ScannerPreview: background-queue
/// start, one delivery on the main queue, then the session stops.
private struct LegacyScannerPreview: UIViewRepresentable {
    let onScanned: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScanned: onScanned) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer // swiftlint:disable:this force_cast
        }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let onScanned: (String) -> Void
        private var delivered = false

        init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

        func attach(to view: PreviewView) {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.startRunning()
            }
        }

        func stop() {
            if session.isRunning { session.stopRunning() }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !delivered,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }
            delivered = true
            stop()
            onScanned(value)
        }
    }
}
#endif
