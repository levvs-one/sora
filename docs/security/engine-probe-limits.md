# Engine version-probe resource limits

The version probe formerly collected combined stdout/stderr in an unbounded
`bytes.Buffer`. A valid first line did not constrain the remaining bytes. Its
context killed the immediate process, but inherited output handles could still
keep `Cmd.Run` waiting after that process exited.

The probe now retains at most 64 KiB across both streams in a fixed array. An
attempted extra byte cancels the command and rejects the result, including a
valid version prefix. Exact-limit output remains accepted. The same comparable
writer is assigned to stdout and stderr; `os/exec` serializes its `Write` calls.
Version and build-tag parsing still use the complete accepted output.

The existing ten-second probe context remains. Standard-library `Cmd.WaitDelay`
adds a one-second bound after cancellation or observed process exit, closing
lingering I/O pipes. This does not kill an arbitrary descendant process tree or
provide an OS sandbox, executable authentication or a hard kernel scheduling
deadline. Long-running engine supervision and configuration checks are separate
paths and are unchanged by this patch.

Actual child-process regressions failed against the old source: 65,537 combined
bytes were accepted from stdout, stderr and split streams; an inherited pipe
was accepted after the finite holder exited. The fixture writes at most 65,537
bytes, never runs an external command, and closes inherited handles after three
seconds. Test cleanup waits for its completion marker. Small output, exactly
65,536 bytes, version/tags and context cancellation are positive controls.

## Dependency choice

The existing `Tail` retains the last lines rather than the complete first-line
version response, so it cannot enforce this contract. Standard `io.LimitReader`
would require changing pipe ownership and coordinating readers; it does not
bound an `io.Writer` passed to `Cmd`. The small fixed writer leaves that lifecycle
with `os/exec`. No dependency or Go minimum changes are required (core Go 1.26.9,
toolchain 1.27.3).

Candidates inspected on 26 October 2026, before implementation. Open counts below
are GitHub API `open_issues_count` (including pull requests); weight is the Go
module archive, not installed binary size.

| Candidate | Latest release | Stars / open | Module zip | License / Go |
| --- | --- | --- | --- | --- |
| go-cmd/cmd v1.4.4 | 2026-10-23 | 1,028 / 8 | 32,792 B | MIT / 1.20 |
| djherbis/buffer v1.2.0 | 2021-04-25 | 552 / 0 | 23,739 B | MIT / 1.13 |
| muesli/cancelreader v0.2.2 | 2022-06-22 | 145 / 12 | 17,969 B | MIT / 1.17 |

All declared Go minimums fit this project. `go-cmd` documents unbounded buffered
output; its streaming limit applies to an unterminated line, not total bytes.
`buffer/limio` offers a short-writing byte limiter but no command cancellation,
and has no release or push since 2021/2022. `cancelreader` has no byte limit and
its Windows implementation only supports stdin; its release/push dates are also
over two years old. Those maintenance and Windows constraints rule them out.
The selected implementation uses existing `context`, fixed Go storage and
`os/exec.WaitDelay`, without replacing process supervision.

Sources: [Go Cmd/WaitDelay](https://pkg.go.dev/os/exec#Cmd),
[go-cmd v1.4.4](https://github.com/go-cmd/cmd/tree/v1.4.4),
[buffer/limio](https://github.com/djherbis/buffer/blob/v1.2.0/limio/limit.go),
[cancelreader Windows limitations](https://github.com/muesli/cancelreader/tree/v0.2.2).
