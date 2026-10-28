# Engine command pipe lifetime

The version prober already uses the standard library's `exec.Cmd.WaitDelay`.
The validator (`Check`) and running engine (`Start`) did not: even after their
main child exited successfully, an inherited stdout/stderr handle could keep
`cmd.Wait` draining until another process closed that handle.

A finite native child regression reproduced both paths before the change. The
existing self-process fixture exits its main process and leaves a three-second
pipe holder with private ready/done markers. Validation and runtime waiting
both returned success after that delay; the runtime still treated the wait as
unfinished while the already exited parent's descriptors remained inherited.
The fixture opens no network listener and reads no owner data. Cleanup waits
for the finite holder's done marker instead of leaving it behind.

The full local supervisor suite passed with `-race` in 36.501 seconds after the
change. Windows vet and test-binary cross-compilation also passed; native Windows
execution is covered by the repository's Windows core-test job, not inferred
from cross-compilation.

Both commands now set `WaitDelay` to one second, matching the existing version
probe. If the main child exits but pipes remain inherited, standard `os/exec`
closes those pipes and returns `ErrWaitDelay`. Existing error wrapping preserves
that cause and the captured diagnostic tail. Runtime exit classification must
complete rather than report the already exited child as running.

This does not give the running command a new context cancellation policy:
`Start` still uses its existing grace/kill owner, and `Check` keeps its existing
twenty-second context. Ordinary child completion and output are covered by the
existing supervisor/environment suite. The new negative test exercises both
commands through actual OS processes, checks the wait error and retained output,
and requires that the holder really started.

The implementation adds two standard-library field assignments, no dependency,
new process manager, parser, flags or runtime minimum. The
[standard wait contract](https://pkg.go.dev/os/exec#Cmd.WaitDelay) was checked
against the project's Go toolchain. Existing log-line buffering already has a
bound and was not replaced.

This is not executable authentication, a process sandbox, a guarantee that all
descendants are terminated, or a bound on arbitrary blocked writer callbacks or
kernel filesystem operations. Those remain separate trust/resource questions.
