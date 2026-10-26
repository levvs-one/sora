# Locked-file MSI transaction fixture

This extends the existing native MSI component proof. It does not replace the
shipped Inno installer or establish production Sora rollback/power recovery.
Native execution is restricted to the existing disposable Windows CI guard;
the owner's installation and services are not used.

Both the file-only and LocalSystem-service profiles require an additional
`locked-new-payload` phase after their successful old-version baseline. The
harness holds the planted payload with `CreateFileW(GENERIC_READ,
FILE_SHARE_READ, OPEN_EXISTING)`. A second write-access open must fail with
ERROR_SHARING_VIOLATION (32); failure to establish that control aborts the test.
The handle stays open until msiexec exits or times out, then closes in `finally`.
It blocks write/delete while allowing the existing observer to read old bytes.

Only this phase passes `MSIRESTARTMANAGERCONTROL=Disable`, so Restart Manager
does not terminate the test process holding the file. Existing `/qn /norestart`
and the 120-second outer timeout remain. This exercises refusal with a persistent
lock, not automatic process shutdown or interactive FilesInUse choices.

Required postconditions are MSI exit 1603 (3010 is not accepted as a committed
upgrade), native InstallValidate reached, old payload/product registration,
no new-payload observation, and restored old SCM/pipe readiness for the service
profile. Each completed phase also reads the documented
`PendingFileRenameOperations` queue and rejects entries naming this fresh fixture
directory. The test does not modify the registry or inspect unrelated entries
in its output. This check does not claim that all system reboot causes or
pending operations outside the fixture path are absent.

The existing refusal-after-new-payload and successful retry phases remain
mandatory, as do uninstall/file/product/service absence checks. Phase JSON adds
`lock_confirmed` and `pending_fixture_renames`; verbose MSI logs are retained.
The fixture MSI packages, native service manager and payload observer are reused
without a new dependency or handmade transaction manager. Python's existing
ctypes and standard winreg call the documented OS APIs.

Native outcomes for this new phase remain pending until hosted CI executes it.
Source/AST checks alone do not confirm the Windows lock or rollback behavior.
No owner MSI installation, SCM action, network/route/firewall change, reboot or
real private-data inspection is performed.

Sources read before implementation:
[CreateFileW sharing and return values](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew),
[Restart Manager property](https://learn.microsoft.com/en-us/windows/win32/msi/msirestartmanagercontrol),
[MoveFileExW reboot queue](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-movefileexw),
[Python winreg](https://docs.python.org/3/library/winreg.html#winreg.QueryValueEx),
[Windows Installer rollback](https://learn.microsoft.com/en-us/windows/win32/msi/rollback-installation).
