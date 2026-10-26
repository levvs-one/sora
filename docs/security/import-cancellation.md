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
Aggregate concurrent parsing and the other S3 resource boundaries remain open.
