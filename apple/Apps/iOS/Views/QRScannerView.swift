import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

/// QR scanner over AVFoundation.
///
/// Capability handling is a runtime probe, per the adaptivity standard:
/// camera presence and authorization are checked before any session is
/// built. The Simulator and denied-permission cases render the designed
/// `qrNoCamera` state (existing localization key, same as the Flutter
/// app) with a route back to paste-import — never a crash, never a
/// black preview pretending to scan.
public struct QRScannerView: View {
    public let onScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var availability: Availability = .checking

    private enum Availability { case checking, available, unavailable }

    public init(onScanned: @escaping (String) -> Void) { self.onScanned = onScanned }

    public var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background(for: scheme).ignoresSafeArea()
                switch availability {
                case .checking:
                    ProgressView()
                        .accessibilityLabel(Text("qrScanTitle"))
                case .unavailable:
                    SoraEmptyStateView(
                        titleKey: "qrNoCamera",
                        messageKey: "qrNoCameraMessage",
                        actionTitleKey: "close",
                        action: { dismiss() })
                case .available:
                    #if canImport(AVFoundation)
                    ScannerPreview(onScanned: onScanned)
                        .ignoresSafeArea(edges: .bottom)
                        .accessibilityLabel(Text("qrScanTitle"))
                        .accessibilityHint(Text("qrScanHint"))
                    #else
                    SoraEmptyStateView(
                        titleKey: "qrNoCamera",
                        messageKey: "qrNoCameraMessage",
                        actionTitleKey: "close",
                        action: { dismiss() })
                    #endif
                }
            }
            .navigationTitle(Text("qrScanTitle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .accessibilityLabel(Text("cancel"))
                }
            }
            .task { availability = Self.probeCamera() ? .available : .unavailable }
        }
    }

    /// Runtime capability probe — device has a video capture device AND
    /// the user has not denied camera access. `#available` is not used:
    /// this is a hardware/permission probe, not a version branch,
    /// because camera availability has never been version-shaped.
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
/// AVCaptureSession preview + metadata output. The session runs on a
/// background queue; a decoded QR value is delivered once, on the main
/// actor, and the session stops — no repeated callbacks.
private struct ScannerPreview: UIViewRepresentable {
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
