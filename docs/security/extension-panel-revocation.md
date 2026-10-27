# Revoking a running extension panel

Disabling an extension previously relied on Navigator.maybePop to remove its
panel. A root route can refuse that pop, and even a normal pop can wait for
another frame. The native controller and its opening generation then remained
usable. The bridge retained its initial permission snapshot.

Two widget regressions reproduced this through the actual panel host and
store, with a fake native platform adapter and the real signed HelloPanel
package. An allowed synthetic notification established the positive control.
After setEnabled(false), another queued native-channel notification still
entered Sora's history. Disabling during native initialization also allowed
the late controller to load the panel. No live connection or owner notification
was read, and no native browser or core was launched for this reproduction.

The host now invalidates its existing generation synchronously when the
extension is disabled, removed, replaced, or loses/changes its panel grants.
It detaches the controller and local server before attempting navigation, then
uses the existing platform disposal APIs. The root-route unavailable state
does not depend on a successful pop. An initializing controller cannot attach
after that generation changes. Revoked navigation is refused, and replies
finishing after invalidation are dropped. The initial ui.panel grant is also
required before creating a surface.

The package verification, author pin, CSP, RPC permission map, method names and
core authentication are unchanged. A permission change requires reopening a
fresh panel; an old page does not gain newly added grants. Already dispatched
work is not a cancellable transaction, so this does not retract a side effect
that was authorized before invalidation or claim owner-SID isolation.

Local regressions cover positive dispatch, late post-disable dispatch, root
navigation, disabling during initialization, and a reply deliberately held
until after disable. The existing bridge/server/startup suite remains required.
The native integration additionally disables the published package at the end
of its two cycles and installs a temporary-author-signed permission-reducing
source update while its panel is open. Those new native teardown cases are
pending hosted WebKitGTK/WebView2 execution; mock-platform checks are not
their substitute. Production catalog/package signatures and roots are untouched.

The full local Flutter suite passed 560 tests with 73 prerequisite skips;
the focused host/bootstrap/server tests and the existing runtime suite also
passed. The delayed-host-work fixture adds the notification while authorized
and holds only its reply, so it checks response suppression rather than
pretending that revocation can undo an already performed action.
