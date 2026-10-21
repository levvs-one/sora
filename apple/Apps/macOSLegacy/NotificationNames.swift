import Foundation

/// Notification names for the legacy composition.
///
/// This declaration normally lives at the bottom of the main client's
/// menu-bar content file (`Apps/macOS/SoraMac/MenuBar/
/// MenuBarContent.swift`). That file is NOT part of the legacy
/// composition: alongside this name it defines the macOS 13 menu-bar
/// scene, which does not exist on macOS 11–12. The name itself is
/// used by files the legacy target reuses unchanged
/// (`StatusItemController`, `AppDelegate`) and by the legacy entry
/// point, so it is extracted here verbatim — same name, same raw
/// value — and the menu-bar content file stays excluded whole.
public extension Notification.Name {
    /// Posted by the status item when the user picks "Import…" with
    /// no main window focused; the main window's servers section
    /// opens in response (AppDelegate forwards).
    static let soraOpenImport = Notification.Name("io.github.levvs-one.sora.macos.openImport")
}
