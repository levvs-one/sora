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
source update while its panel is open. Those new native teardown cases
passed hosted WebKitGTK (job 121937941578) and WebView2 (job 121938746476,
run 40427833762) on the original PR111 head. They are now included in the
desktop integration branch. That historical pass does not prove a newer
combined head; its native CI must pass separately. Production catalog/package
signatures and roots are untouched.

The full local Flutter suite passed 560 tests with 73 prerequisite skips;
the focused host/bootstrap/server tests and the existing runtime suite also
passed. The delayed-host-work fixture adds the notification while authorized
and holds only its reply, so it checks response suppression rather than
pretending that revocation can undo an already performed action.

## Bounded initialization and honest connection failures

The host now gives its asynchronous startup 15 seconds, then detaches that
generation, stops its private local server and requests disposal of its
preparing/attached controller through the existing platform APIs. The retry
creates a new generation only after rechecking the current installed package
and grants. A late initializer cannot attach to that retry or close its newer
server. Teardown also removes the cached Sora listener.

The deadline bounds host initialization and loadRequest completion; it does
not certify page JavaScript readiness, forcibly terminate a stuck native
plugin or guarantee real-time cleanup by the OS. Widget regressions reproduce
a never-completing initializer, retry and late completion with a fake native
platform. The earlier implementation failed both deadline cases.

The panel connection query now has a five-second gRPC deadline and rejects a
wire SoraError through the documented bridge error contract. A private
loopback gRPC regression first returns a real positive row, then a wire error:
the earlier host incorrectly resolved that error as an empty successful list.
The Hello source also replaces stale rows with a permission/unavailable state
and re-enables Refresh; automatic refresh remains quiet. A Node VM regression
executes its actual page script with a minimal DOM fixture and verifies
positive escaped rows, both error states, recovery and interactive-only
notices. It is JavaScript logic coverage, not a browser preview.

The desktop integration branch passed the full local Flutter suite with
673 tests and 73 prerequisite skips, including the source-script regression;
the focused host/server/bootstrap/connections suite passed 23 tests and
analysis reported no issues. New signed-source native assertions exercise
the same stale-row failures and recovery in each native panel cycle.
They passed real WebKitGTK (job 122144807077) and WebView2 (job 122146905677,
run 40490921671) at 61fa17f82dbcbb35d41e82877dec25dfe3529272.
Both the published package and temporarily signed source completed two cycles,
including disable/signed permission-reducing update teardown. The full PR123
rollup finished with 20 successful checks and four conditional skips. The
source-only error injection tests rendering/recovery; it is not live provider
traffic or a new permission/authentication proof.
