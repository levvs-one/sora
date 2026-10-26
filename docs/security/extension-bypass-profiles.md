# Selected extension bypass profiles

This change connects a signed declarative extension to existing host behavior:
Linux Zapret/tpws and Windows driverless ByeDPI. It does not implement the
separately requested Windows WinDivert/winws adapter or publish catalog bytes.

The app checks the package signature and catalog-pinned author identity before
validating or extracting a descriptor. hook_version 2 accepts only bounded
named protobuf BypassStrategy values. Native paths, flags, scripts and arbitrary
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

The signed public catalog and published packages are unchanged. Source projects
must get the actual first supported host version before production author/team
signing. Catalog refresh already delivers separately signed additions without
rebuilding a compatible app. Catalog preflight now presents version/OS requirements without hiding entries;
it does not replace native checks. The Windows WinDivert adapter, its distribution notices/source obligations, production
signing approval and publication remain separate required work.

Local validation: full Flutter suite 547 passed / 71 prerequisite skips,
then 12 profile/transport/UI cases passed with both private gRPC cases enabled;
analyze found no issues. Actual light/dark 320px, text-scale 1.6 PNGs were
rendered and inspected. Go ext/control race tests passed (14.978s/cached),
all sora-ext race tests passed, normal core and CLI CI lint found zero issues,
and Linux/Windows CLI vet passed. Hosted native Windows tests remain pending.
