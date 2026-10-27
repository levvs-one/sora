# Chunked probe admission and streaming

The control handler previously submitted all ProbeChunkSize batches before
consuming results. The concrete TCP backend admits only four simultaneous
Probe calls. A large single RPC could therefore reject its own later chunks,
even though its request stayed below the control plane's 4096-server limit.
The previous unbounded synthetic chunk prober did not exercise that policy.

A deterministic admission-faithful backend uses the real public
probe.MaxConcurrentRequests value and holds synthetic requests until released.
On the old handler, 600 outbounds produced only 512 results (one rejected
chunk), and 1024 produced only 512 (four rejected chunks). This is a handler
reproduction using synthetic results, not a live provider/network measurement.

The handler now schedules its chunks in a producer goroutine. It waits for the
current chunk's result-forwarding work to finish before submitting the next
chunk, while the handler itself delivers results concurrently. The real backend
releases its request slot before closing its result channel, so completion of
that forwarding is the appropriate admission boundary. The same boundary also
waits for an engine chunk and its orphan fallback before another chunk starts.

The two 600/1024 cases now cover outbound-only, endpoint-only and mixed requests.
Every requested result is delivered without exhausting the backend's request
budget; outbound IDs remain unique, while explicit endpoints retain their
existing empty-ID convention. A separate test makes a chunk wait for actual
stream Send before it may finish: waiting for all work before delivering
results would deadlock and fail this positive streaming control.
Standard testing/synctest coordinates these cases without wall-time thresholds.
No real socket, engine, adapter, capture or provider is used.

The existing chunk-boundary, engine fallback, partial-failure and mid-chunk
timeout tests also pass. Limits of 128 per chunk and 4096 per control request,
backend request/socket budgets and per-chunk concurrency remain unchanged.
This serializes cross-chunk engine launches; no throughput improvement is
claimed. Other concurrent clients can still exhaust the shared backend budget,
and real unavailable endpoints still fail. Client-side ping batching, labels,
spinners and transport error policy are outside this change.
