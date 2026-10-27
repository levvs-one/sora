# Import cancellation and the vault commit boundary

`ParseImport` previously ignored its request context. Two regression cases using
a real temporary FileProtector vault confirmed that an already-cancelled context
and an already-expired deadline both returned success and persisted another
credential reference. A retained fixture credential remained unchanged. This
was a direct handler reproduction, not an authorization bypass, live secret
incident or independent audit.

The handler now reuses the existing `requestDeadline`/60-second import fallback,
checks the request before parsing, and checks again immediately before the
existing atomic `SecretStore.Apply`. Observed cancellation returns gRPC Canceled
or DeadlineExceeded through the installed gRPC `status.FromContextError` API.
Version negotiation, parsing, credential references and atomic storage remain
unchanged. `FetchSubscription` already passes its context to this handler.
No new dependency, cancellation framework, parser wrapper or configuration was
introduced. The source file, existing error mapping and installed API docs were
read before the change.

The regression checks that no extra reference was persisted, the original
credential bytes remain equal, and a subsequent uncancelled import still
succeeds. Existing full control/parser/subscription race suites remain required.
The test does not execute an engine, install a service or change networking.
Native Windows execution must come from hosted CI, not the cross-build.

This is a checkpoint before committing, not a cancellable storage transaction:
cancellation after the final check can race with `Apply` or arrive while it is
running; it does not undo that atomic write. The parser still has no
context-aware preemption; synchronous parsing can run past a
deadline before the final check rejects the result. Neither the fallback timer
nor this change establishes a hard CPU/memory limit.

The background subscription scheduler already has four fetch slots, and one
subscription has an in-progress flag. Those existing limits do not prove a
global budget across manual imports, explicit fetches and distinct refreshes.
The shared payload admission below addresses active decoding; aggregate memory and the other S3 resource boundaries remain open.

## Subscription refresh checkpoints

The shared manual/scheduled refresh path also used to accept valid provider
bytes after its context was cancelled. Three new regressions with the existing
fake provider and a real private vault reproduced success and replacement of
the stored record, server list and credentials for an already-cancelled request,
an expired request, and a valid response released after cancellation.

Refresh now refuses work on an already-finished caller, checks the fetch context
before parsing/using the result, and checks again immediately before the existing
atomic vault update. Cancellation clears the in-progress flag and emits the final
non-updating state while preserving the previous record/list/credential bytes.
The caller's context is distinguished from the book's own fetch timeout:
provider deadlines still record normal failure/backoff rather than an immediate
successful retry. Existing four scheduler slots and per-ID serialization remain.

The regressions verify every retained vault value, release of Updating, and a
subsequent successful refresh. An additional standard-library synctest case
advances the real two-minute child deadline and confirms retained servers plus
failure/backoff while the caller remains alive; it does not wait two wall minutes. They run no real fetch, engine, listener or system
change. Synchronous parsing is still not preempted, and cancellation after the
final checkpoint can race an atomic write; there is no transactional undo.
The saved-fetch core lifetime is addressed below. Aggregate resource limits
and physical cancellation of arbitrary provider/parser work remain separate
boundaries.

## Shared payload admission

One control-plane Server now admits at most four calls to its common
`parsePayload` path at once, before format detection and full decoding. The
permit remains held through credential-document preparation and is released on
every return. `ParseImport`, its `FetchSubscription` caller, and the shared
manual/initial/scheduled subscription refresh path use that admission. Each
wait uses the existing caller/fetch context; a cancelled or expired waiter does
not start parsing or write credentials.

Four is an explicit capacity policy matching the existing four automatic-fetch
workers, not a benchmark-derived throughput or memory threshold. The scheduler's
fetch slots and per-ID update flag retain their existing roles. HTTP bodies can
already have arrived before admission. A waiting import keeps its request bytes,
and results, vault writes and protobuf responses outlive the decoding permit.
This is not a pre-decode RPC admission limit, a byte budget, a hard heap/CPU
sandbox, or a cap across separately constructed Server instances. Single-server
link validation in `normalizedLink` and the custom-server link handler, plus
engine-config parsers, remain outside this common payload gate.

### Existing-library comparison (27 October 2026)

The project pins Go 1.26.9/toolchain 1.27.3 and already contained both modules.
The following sizes are complete pinned module ZIPs in the Go cache, not binary
size deltas; GitHub open counts include pull requests.

| Candidate | Release evidence | GitHub stars / open count | Pinned ZIP | License / runtime |
| --- | --- | --- | --- | --- |
| `golang.org/x/sync/semaphore` | pinned and latest v0.24.0, 23 September 2026 | 936 / 9; Go mirror, issues tracked centrally | 26,232 B | BSD-3-Clause; Go >=1.26.0; semaphore imports only the standard library |
| `google.golang.org/grpc.MaxConcurrentStreams` | pinned v1.83.2, 25 August; latest v1.84.0, 17 September 2026 | 23,094 / 192 | 3,002,440 B for v1.83.2 | Apache-2.0; pinned module Go >=1.25.0 |

Primary evidence: [sync metadata](https://proxy.golang.org/golang.org/x/sync/@latest),
[gRPC metadata](https://proxy.golang.org/google.golang.org/grpc/@latest),
[sync repository](https://github.com/golang/sync),
[gRPC repository](https://github.com/grpc/grpc-go), and the exact installed
module sources/go.mod files. Both repositories had pushes in October 2026.

The selected [Weighted API](https://pkg.go.dev/golang.org/x/sync@v0.24.0/semaphore)
already provides cancellable acquisition and release. A direct import promotes
the same pinned module from indirect to direct; it adds no module/version or
checksum change. A standard buffered channel was also considered, but would
duplicate wait/cancel bookkeeping already implemented by this dependency.
[gRPC's stream limit](https://pkg.go.dev/google.golang.org/grpc@v1.83.2#MaxConcurrentStreams)
applies per transport and cannot govern the in-process refresh path, so it was
not selected as the shared parser gate. No transport setting or dependency
upgrade was introduced.

### Observable checks and limits

The old-code admission regression held four real parses at the existing
reference-preparation callback: a fifth actual ParseImport still completed and
persisted a credential. Both cancellation/deadline variants reproduced this
missing capacity policy. This was an admission test with small synthetic
subscriptions, not a denial-of-service demonstration or peak-memory benchmark.

The final test also starts the real book refresh with an injected provider,
while all four permits are occupied. Both waiting paths cancel/expire without
changing the temporary vault's existing record/list/credential bytes; Updating
clears, admitted work completes, and a subsequent import succeeds. Malformed
payload and reference-error paths are exercised before saturation to check
permit release. Standard `testing/synctest` coordinates blocking and advances
the deadline without timing thresholds or large allocations. No real provider,
engine, listener, capture or host network is used.

Synchronous parser work after admission is still not preempted, and the existing
post-parse commit checkpoints do not undo an atomic write. Total outstanding
RPCs/retained inputs, AST width/node budgets and the other resource boundaries
remain open; saved-fetch lifecycle ownership is addressed below.

## Latest saved subscription link

Saving a new URL while an older refresh owned the subscription's in-progress
slot previously dropped the new fetch. Three regressions reproduced this with
automatic updates disabled: an old successful fetch, an old failed fetch, and
cancellation of an older manual refresh. The latest saved URL remained empty or
kept the previous server list. These tests use an injected provider and a real
temporary vault, without provider requests or a running core.

The existing book mutex now protects one pending saved-link intent per ID.
Admission snapshots the current URL and user agent and consumes that intent
only when the existing per-ID slot is reserved. Finishing an older request
admits the latest saved link before releasing the mutex. Rapid intervening URL
edits coalesce; they do not create waiting workers. Deletion removes the intent.
A failure without a further saved URL does not enqueue another attempt.
Manual refresh cancellation does not cancel an independently saved new link.

This reuses the existing admission and vault-update paths. Two installed
alternatives were checked against their pinned documentation on 27 October:

| Candidate | Pinned release | Repository stars / open count | Module ZIP | License / Go floor |
| --- | --- | --- | --- | --- |
| [singleflight](https://pkg.go.dev/golang.org/x/sync@v0.24.0/singleflight) | v0.24.0, 23 September 2026 | 936 / 9 | 26,232 B | BSD-3-Clause / 1.26.0 |
| [errgroup](https://pkg.go.dev/golang.org/x/sync@v0.24.0/errgroup) | v0.24.0, 23 September 2026 | 936 / 9 | 26,232 B | BSD-3-Clause / 1.26.0 |

Both belong to the same already-installed module; counts include pull requests,
and its mirror was pushed on 15 October. Neither is deprecated in its package
documentation. Both fit the project's Go 1.26.9/toolchain 1.27.3 floor and use
standard-library imports. Singleflight shares the currently running result;
Forget permits overlapping work. Errgroup limits concurrent tasks but does not
retain the latest changed URL. Neither replaces the book's saved-intent/atomic
admission boundary, so no dependency, version or second limiter was added.

The six scenarios assert exact fetch order, no overlap while the old request is
blocked, final latest server/credential retention, coalescing of intermediate
links, deletion without resurrection, a single failed latest attempt, and a
metadata-only save without an extra fetch. Standard synctest coordinates the
requests. Existing cancellation, child-timeout/backoff and parser-admission
regressions remain required.

The pending intent is process-local, not a durable queue or crash-recovery
guarantee. The two-minute fetch timeout, four scheduler slots and shared
four-parser admission are retained. Saved-fetch core cancellation is addressed
below; global fetch admission, CPU preemption and rollback of an atomic vault
write remain separate boundaries.

## Saved fetches follow the core lifetime

SaveSubscription intentionally starts a new/changed-link fetch independently
of its UI request. Previously its context.Background also made it independent
of the core's Server.Run context. Four private-vault regressions reproduced
work still marked Updating after that core lifetime ended, accepted late
provider bytes, and a queued latest-link save launching another fetch.

The book now owns one standard context.WithCancel scope from construction.
The existing core Run context cancels that scope through context.AfterFunc and
on Run return. Saved-link fetches use it; the existing pending-intent admission
does not launch a replacement after it has ended. Creating the scope before
Run also covers a save admitted before the scheduler starts. The normal App
Serve path already calls Server.Run with its lifetime context. This does not
attach saved work to a shorter UI/RPC request.

The implementation reuses the standard context APIs and the existing
fetchAccepted cancellation checkpoints. It adds no scheduler, retry loop,
module, environment option or second limiter. Manual-refresh caller context,
the book's two-minute per-fetch timeout, per-ID serialization, automatic-fetch
slots and payload admission retain their existing roles.

The regressions observe positive provider entry, core cancellation, Updating
release for a cooperative provider, unchanged real vault references/record
bytes, and no queued latest-link fetch after stop. A separate existing fake
provider deliberately ignores cancellation and returns a valid payload late;
that payload is discarded without recording a provider failure. The tests
run before/during Run and use standard synctest, with no live provider,
engine, listener, capture or system configuration.

Validation: all four old-code scenarios failed; the fixed scenarios passed
20 race-enabled repetitions. Fresh full control/parser/subscription race suites
passed in a private user/network namespace; Windows vet/lint and cross-build
passed. Native Windows ran both groups five times successfully.

This is cooperative scope cancellation and a pre-commit checkpoint, not forced
preemption of an arbitrary Fetch implementation, physical network-drain proof,
or an undo of Apply already past its last cancellation check. A provider that
ignores its context can remain executing until it returns. Run cancellation
closes this book's saved scope; a new core constructs a new book. Pending intent
is still process-local, without a durable resume/crash-recovery queue. The
remaining aggregate resource boundaries are not certified by these
handler-level tests; Serve-return ownership is checked separately below.


## Serve return owns its background scope

Run cancellation alone was not sufficient when App.Serve returned while its
caller remained alive. Both an already-stopped gRPC server and a closed
listener reproduced the saved fetch surviving that return. Serve now creates
a standard child context and defers its cancellation, ending its owned Run
work on every return without cancelling the caller or changing returned errors.

These regressions call the actual Serve method with a constructed control
plane, a real private vault and the installed gRPC bufconn listener. A fake
provider first proves the saved fetch is active, then exposes its context.
The stopped-server result remains nil, a closed-listener failure remains
non-nil, the caller stays alive, and the fetch context ends as Canceled.
No App.New, platform recovery, real socket, engine, route or system service is
started. Direct handler admission uses a temporary authenticator; this is not
an IPC peer-identity or authorization proof.

Both old-code cases failed. The change passed 20 race-enabled repetitions,
the fresh complete sora-core command race suite, Windows vet/lint/cross-build,
and 20 native Windows repetitions of both exit cases. These cooperative
scope checks do not establish physical network drain, hard process/power
recovery, parser preemption or rollback of a committed vault write.
