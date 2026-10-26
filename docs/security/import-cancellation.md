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
The initial independent background fetch launched by SaveSubscription retains
its existing context policy. Aggregate resource limits and lifecycle ownership
of that background operation remain separate work.
