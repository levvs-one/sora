import Foundation
#if canImport(Carbon)
import Carbon.HIToolbox
#endif

/// Global connect/disconnect hot key (task §6): ⌃⌥S by default.
///
/// CHOICE: Carbon `RegisterEventHotKey`, not `NSEvent.addGlobalMonitor`.
/// Justification:
///  * A global NSEvent monitor requires Accessibility permission
///    (TCC prompt, System Settings trip) and only *observes* events —
///    the app gets spammed with every keystroke system-wide.
///  * Carbon hot keys need NO extra permission, work sandboxed, fire
///    only for the exact registered combination, and have been the
///    supported mechanism for global hot keys on macOS for two decades
///    (still shipped and used by current apps; the API is deprecated
///    in name only for event *handling*, hot-key registration is not).
///  * Fallback: an in-app local monitor covers the focused-window case
///    if registration ever fails (e.g. another app owns the combo) —
///    Settings reports the conflict honestly instead of silently
///    pretending the hot key works.
public final class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()

    @Published public private(set) var isRegistered = false
    @Published public var isEnabled: Bool = true { didSet { isEnabled ? register() : unregister() } }

    /// Invoked on the main queue when the hot key fires.
    public var onToggle: (() -> Void)?

    #if canImport(Carbon)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    #endif

    private init() {}

    public func register() {
        #if canImport(Carbon)
        if hotKeyRef != nil { isRegistered = true; return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            if id.id == 1 { DispatchQueue.main.async { mgr.onToggle?() } }
            return noErr
        }, 1, &spec, selfPtr, &eventHandler)

        // ⌃⌥S — key code 1 = kVK_ANSI_S.
        let hotKeyID = EventHotKeyID(signature: OSType(0x534F5241) /* "SORA" */, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_S),
                                         UInt32(controlKey | optionKey),
                                         hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        isRegistered = (status == noErr && hotKeyRef != nil)
        #else
        isRegistered = false
        #endif
    }

    public func unregister() {
        #if canImport(Carbon)
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        isRegistered = false
        #endif
    }
}
