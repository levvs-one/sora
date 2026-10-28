# Engine discovery and digest memory

This is an internal S3 source/resource review, not an independent audit or
proof that an unprivileged process can replace an installed engine.

`supervise.Prober.Discover` considers an operator environment override, the
configured engines directory, then PATH. A successful version command
recognizes the reported engine; it does not authenticate executable provenance.
The installed Windows service receives its engines directory under Program
Files from Inno, while Linux packages place engines under `/usr/lib/sora/engines`.
This review did not exercise another user's installed ACLs, symlink/reparse
points, executable replacement races or PATH/environment modification rights.

`olcrtc.Discover` reads Go build information without running the candidate,
checks module/OS/architecture, then compares an adjacent manifest's pinned
revision and SHA-256. `Binary.VerifyDigest` is used there; it is not an unused
authentication hook. An adjacent checksum and mutable build information are
not an independently trusted signature. Their protection still depends on the
package and the directory containing them. Hashing does not pin a later exec
to the same file or remove other administrator writers.

The digest calculation previously used `os.ReadFile`, retaining the entire
executable. It now uses standard-library `io.Copy` into `sha256.New`, with the
same hexadecimal digest normalization and constant-time comparison. No engine
format, maximum size, discovery order, environment policy or dependency changed.
This does not bound I/O duration, reject special files, or establish provenance.

`TestBinaryVerifyDigest` checks empty, one-byte, multi-chunk and 2 MiB files,
uppercase/whitespace normalization, malformed/truncated/wrong digests, appended
bytes, missing files and directories. `BenchmarkBinaryVerifyDigest` uses a
private 8 MiB fixture. On home-pc, Go 1.27.3/linux-amd64, one iteration allocated
8,397,304 bytes before the change and 33,224 bytes after it. These are allocation
measurements, not a demonstrated attack or a cross-platform performance promise.
The existing dependencies were inspected and the installed toolchain's
`go doc io.Copy` and `go doc crypto/sha256.New` were read before implementation;
the production change is a small replacement using the standard library.

The app's Windows `PipeConnector` separately verifies the kernel-reported server
PID against the SCM's SoraCore PID by default. A manually configured
`SORA_CORE_SOCKET` explicitly disables that service binding. This is existing
behavior, not a missing default check discovered by this review. Go's generic
local dialer does not supply that app-specific binding. Complete multi-user
identity/lifetime tests and independent update health checks remain open.
