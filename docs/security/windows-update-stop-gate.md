# Windows upgrade service-stop gate

Before replacing files, the installer used to run `sc stop SoraCore`, ignore its
result, sleep for 1.5 seconds and unconditionally allow installation. An accepted
stop request is not the same as the service reaching `Stopped`.

The existing native `stopService` implementation already waits for SCM's stopped
state with a 30-second polling budget. The installer now extracts its bundled
new core first and invokes the exclusive `-stop-service` mode. This avoids
depending on an old installed core understanding the new option. The command
preserves service registration/configuration and treats only
`ERROR_SERVICE_DOES_NOT_EXIST` as a successful absent-service case. Other open,
query, control or timeout errors propagate as failure. A service already in
`StopPending` is waited on without sending a second stop control.

Inno's existing `PrepareToInstall` event returns an error for launch failure or
nonzero exit, before file replacement. Extraction failure also aborts preparation.
The core is first in the solid archive to avoid extracting the GUI/engines before
this check. There is no new SCM polling script, service wrapper or dependency.

## Verification

Native Windows unit tests use a narrow SCM-query/control fixture, never the
machine's service manager: already stopped, running, already stopping, initial
and later query failure, refused stop, inactive-service race and the real
30-second expiry. Parser tests reject false values, positional arguments and
combinations with release verification, preparation or other commands before
dispatch. Other platforms recognize the flag but return an unsupported-service
error without creating a core instance.

`packaging/windows/test_service_stop.py` compiles the exact shipped preparation
event into a minimal temporary installer. An inert executable validates the
command argument and returns a test-selected exit code; it cannot call SCM.
Successful preparation replaces a planted payload. Refusal, an unlaunchable
executable and extraction failure must leave it unchanged and return failure.
No Sora service, application registration, route or firewall is installed by
this fixture. The existing Windows CI installs Inno 6.7.1 and runs these cases,
then performs a real same-version upgrade of its running test installation
before the existing pipe and traffic checks.

Local verification covers native SCM fixtures (including 30.04-second expiry),
Linux CLI/release/preparation tests, formatting, lint and workflow checks. Inno
is not installed on the owner's machine: the compiled installer cases and real
SCM upgrade still require the new hosted Windows CI result. Do not infer them
from the local unit results.

## Choice and remaining work

Existing `golang.org/x/sys/windows/svc/mgr` v0.48.0 and Inno's event/Exec APIs fit
the pinned Go 1.26.9 / toolchain 1.27.3 and Windows 10 1809+ contract. Alternatives
were inspected before adding the entry point (26 October 2026):

| Candidate | Release / activity | Stars / open incl. PR | Weight | License / runtime |
| --- | --- | --- | --- | --- |
| kardianos/service v1.3.0 | tag 2026-07-06; push 2026-08-29 | 4,851 / 169 | 64,135 B Go module zip | Zlib / Go 1.23, x/sys |
| WinSW v2.12.0 stable | release 2023-01-28; push 2026-07-30 | 14,384 / 276 | 18,243,033 B x64 executable | MIT / bundled .NET Core or Framework-specific executables |

`kardianos/service` is compatible but would introduce a second service lifecycle
layer over the existing x/sys host. WinSW requires changing the registered host
to a wrapper/configuration, and its stable release is over two years old. Both
are unnecessary for exposing an existing bounded SCM operation; neither is added.

This gate is not Windows rollback. After a successful stop, later cancellation,
copy/registration failure, service/IPC health failure, persistent recovery,
offline authenticated rollback and power loss still need a coordinated update
transaction. SCM `Running` alone does not prove IPC or network readiness. No
release, signing, production configuration or owner service operation is performed.

Sources: [Inno preparation event](https://jrsoftware.org/ishelp/topic_scriptevents.htm),
[Exec result contract](https://jrsoftware.org/ishelp/topic_isxfunc_exec.htm),
[temporary extraction](https://jrsoftware.org/ishelp/topic_isxfunc_extracttemporaryfile.htm),
[pinned SCM API](https://pkg.go.dev/golang.org/x/sys@v0.48.0/windows/svc/mgr),
[kardianos/service](https://github.com/kardianos/service),
[WinSW](https://github.com/winsw/winsw).
