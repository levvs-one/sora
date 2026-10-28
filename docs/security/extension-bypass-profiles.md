# Selected extension bypass profiles

This change connects a signed declarative extension to existing host behavior:
Linux Zapret/tpws and Windows driverless ByeDPI. Version 3 adds platform variants
for the separate Windows WinDivert/winws adapter described below. An older
client does not support this API.

The app checks the package signature and catalog-pinned author identity before
validating or extracting a descriptor. hook_version 2 accepts only bounded
named protobuf BypassStrategy values for tpws/byedpi; version 3 selects a strict
platform/backend pair and requires the literal system-tcp-80-443 scope for winws. Native paths, flags, scripts and arbitrary
engine fragments are rejected. Installation does not connect. The enabled
net.hooks grant and the existing permission-based conflict winner gate selection.
Invalid contenders do not silently release the conflict.

An explicit mode id points to the installed extension; manual Sora strategy
settings are retained. Settings writes validate the selected profile before
persistence. Runtime descriptors and strategies are replaced together after
loading, avoiding an intermediate empty cache. Each plan gets a copy.
A missing selected extension is retained as an unavailable selection rather
than replaced by an ordinary server. The client refuses a new Connect and
disconnects an active/in-flight selected profile when eligibility is lost.

This is an app boundary. It does not independently authenticate extension
grants inside the core, protect against another authorized control peer, pin
native binaries, supervise the connection after the app dies, or make bypass
traffic a VPN. Existing core strategy validation remains authoritative.

## Implementation choice

No parser or schema dependency was added. Existing Dart protobuf 6.1.0
mergeFromProto3Json and Go protobuf v1.36.11 protojson validate strategy fields;
dart:convert and encoding/json decode only the small descriptor envelope.
The typed strategy, existing settings schema, conflict store and Connect
serialization are reused instead of introducing a second settings/plan stack.

API sources opened during implementation:
[Go protojson](https://pkg.go.dev/google.golang.org/protobuf@v1.36.11/encoding/protojson),
[encoding/json strict fields](https://pkg.go.dev/encoding/json#Decoder.DisallowUnknownFields),
and the installed Dart protobuf GeneratedMessage implementation.
The new consumer deliberately rejects the old proposed version-1
engine-fragment scaffold, whose referenced external design file is absent.

## Evidence and limits

The Flutter regression builds the production sora-ext CLI, creates a disposable
author identity, packs the actual source project, signs it, and installs through
the normal author-pin gate. Production signing keys and team roots are untouched.
Tests cover signature mutation, wrong platform, missing grants, undecided and
invalid-asset conflicts, selected settings, disabled/uninstalled sources,
immutable copies, retained manual settings and the resulting plan.

A private Unix gRPC fixture verifies actual authenticated Connect/Disconnect:
source strategy, profile replacement, failed replacement retaining the old
connection, disabling during connection startup, no substitute afterward.
It runs no native engine and changes no owner network settings.
The fixture implements the custom-server and profile RPCs as well as connection
RPCs. Initially omitted services left unconsumed HTTP/2 messages at shutdown;
completing the fixture eliminated that invalid test-method failure.

All six source profiles also pass the real Go planFromProto and Plan.Validate
path without running an engine. CLI validation rejects old/unknown descriptor
contracts and does not package malformed profiles. Native execution/evasion,
Windows ARM64, Windows Server dependencies and coexistence are not proven here.

A new test first caught an implementation error: deriving the conflict set only
from successfully loaded profiles let an invalid competing net.hooks holder
disappear. The store now uses the same full permission-based set as the
conflict UI; the regression passes.

During a broad local race run two existing JS budget cases reported memory
budget errors. Their focused rerun passed with unchanged worker code and limits;
the cause was not established. Do not turn that result into a resource-bound
or exploit claim.

## Distribution

Zapret 1.0.0 and ByeDPI 1.0.0 are author and team signed in
`extensions/catalog-1.1.3.json` with min_app_version 1.1.3, the first released
host carrying both the app consumer and the native adapter. The legacy
`catalog.json` for v1.1.2 clients does not list them. Catalog refresh delivers
separately signed additions without rebuilding a compatible app. Catalog
preflight presents version/OS requirements without hiding entries; it does not
replace native checks.

Local validation: full Flutter suite 547 passed / 71 prerequisite skips,
then 12 profile/transport/UI cases passed with both private gRPC cases enabled;
analyze found no issues. Actual light/dark 320px, text-scale 1.6 PNGs were
rendered and inspected. Go ext/control race tests passed (14.978s/cached),
all sora-ext race tests passed, normal core and CLI CI lint found zero issues,
and Linux/Windows CLI vet passed. Hosted native Windows tests remain pending.


## Windows Winws adapter

Winws is an explicit serverless outbound protocol, never a SOCKS stand-in. It
admits one outbound without proxy chains/groups. Old cores reject this unknown
protocol rather than accepting a projection as direct traffic. Only the wrapper,
after validation, projects it to the ordinary forwarder. A missing native bundle
refuses the mode; ByeDPI is not an implicit substitute.

The host owns fixed TCP ports 80/443, IPv4/IPv6 and pinned upstream LAN exclusions.
These exclusions are not a complete IANA public-address classifier. Settings
cannot supply paths, raw filter expressions, extra ports or native arguments.
The supported strategy subset maps to pinned upstream multisplit/multidisorder
and HTTP case/domain/method options; OOB and TLS-record splitting refuse Winws.

The registry advertises serverless-winws only for the installed four-component
bundle on native Windows AMD64 with WLANAPI. Runtime repeats hashes under
read-only, non-reparse file/directory locks and verifies the held driver's
Authenticode chain with cached revocation checking. It refuses an incompatible
WinDivert service. A no-capture child must report readiness before querying the
loaded driver's path/type/state and starting the selected fixed filter. Shutdown
reaps only Sora's children before releasing bundle locks. It never stops or deletes
the shared service; WinDivert may remain loaded until a normal Windows restart.
Matching ImagePath is not proof that foreign handles or privileged writers are
absent. This is not an atomic killswitch or a per-application packet filter.

The app requires fresh host consent for the installed author/version on each
launch. Extension-local settings cannot grant it. Information/Escape do not
select a mode; unavailable native capability produces requirements without a
confirmation action. Updating/revoking/disabling a selected source invalidates
eligibility and ends an active/in-flight selection through the existing path.

The fetch script installs the pinned native files, seven complete licence/notice
texts, and complete Zapret/WinDivert/Cygwin source archives in a separate winws
directory. Cygwin 3.4.10 and WinDivert 2.2.2 are old releases; they were kept for
the exact pinned upstream runtime, not described as current maintained versions.
Cygwin bytes match its upstream binary package, WinDivert DLL/driver match its
official release. Source archives are individually hash-pinned; no source code is
built or loaded by the downloader. The Cygwin archived-source mirror is not
claimed as a current mirror-list entry or cryptographically signed source feed.

Local evidence: the full Go race suite passed; the Flutter suite passed 557 tests
with 73 prerequisite skips. The final private authenticated RPC/profile slice
also passed. Inert native Windows lifecycle fixtures cover failed/stalled startup,
driver-identity refusal, cancellation before bootstrap/capture, invalid replacement
retaining the old session, fatal child exit and stop/reap, without loading a driver.
An initial native test exposed double termination from cancel-before-stop; stopping
and reaping before cancellation fixed it, including 20 repeated stops. A later
regression reproduced a filter exiting during forwarder startup while Apply
returned success. Apply now checks the filter again before confirming startup;
the regression passed on Linux and in 20 inert native Windows repetitions.

The exact new fetch block was run against the cached real upstream archives:
four native files, seven notice texts and three complete source archives landed.
A valid repacked ZIP with unchanged native payloads failed its archive hash before
any EXE installation. Linux ARM64 omitted this Windows bundle.

The disposable Windows CI fixture additionally compiles this package's native
tests. It exercises production bundle locks/trust, pinned --dry-run/--wf-save,
synthetic packet filter evaluation with positive ABI controls, and real startup
with the literal false filter only. Production service queries run unchanged;
outer fixture cleanup is restricted to its newly created exact-path driver.
These new native checks and Windows consent widgets are pending hosted execution
until the feature commit is pushed. Cross-compilation is not their execution,
and a false-filter loader is not DPI effectiveness or full Windows Server,
HVCI/Secure Boot, ARM64, coexistence or real network/migration coverage.
