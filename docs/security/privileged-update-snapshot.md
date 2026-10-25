# Linux update snapshot boundary

The root-owned `sora-update` helper previously copied caller-controlled packages
with `cp` before checking their lengths. Oversized or growing inputs could consume
root-owned storage, and replacing a checked regular file with a FIFO could stall
the copy. This change addresses that boundary, not the whole S3 service/IPC audit.

The helper now calls the installed core with:

```sh
/usr/bin/sora-core -prepare-update deb -release-version 1.2.3 \
  /absolute/untrusted-downloads /var/tmp/private-owned-snapshot
```

`rpm` and `arch` select the existing package names for the Linux amd64 desktop
pair. The command accepts only this mode, version and two absolute directories.
It exits before core construction, service operations, token reads or networking.
It installs nothing and grants no additional privilege; pkexec still authorizes
only the root-owned shell entry point. Other platforms refuse the command.

The destination must already be empty, owned by the effective user and mode 0700.
In production the helper creates it as root with mktemp under /var/tmp. Source
and destination directories are anchored using `os.Root`. For each single-component
input name, `unix.Openat` uses the pinned directory descriptor with O_NOFOLLOW,
O_NONBLOCK and O_CLOEXEC. fstat checks the opened object before any content read:
only nonempty regular files within the bound and with one link are accepted.
This avoids a check-then-open decision on a caller-controlled path. Renaming the
source directory does not redirect later reads to a replacement path.

The no-follow flag must reach the kernel open itself: the tested Go Root.OpenFile
implementation still resolves in-root symlinks. Tests caught that behaviour, so
the single-component open uses the existing x/sys primitive instead. This is not
a custom path resolver; nested and parent filenames are refused.

Manifest/signature/optional JSON copies have fixed 1 MiB/8 KiB/1 MiB limits.
Authentication precedes all package opens. Authenticated target/size queries then
select exactly the two supported packages. Copying reads at most limit+1 bytes,
checks descriptor size/modification time/link count afterward and verifies signed
length and hash on the private output. Exclusive creation uses mode 0600.
Failures remove files created by the command; a preexisting destination is never
overwritten. The shell retains its private signature/hash/package-manager checks.

Signed legacy manifests retain the existing explicit 2 GiB per-package ceiling
and authenticated hashes. They have no signed length; retiring that compatibility
path is a separate S2 transition decision. No unsigned fallback is added. A core
without the new command refuses preparation, leaving the installed pair untouched;
ship core/helper changes together through the reviewed signed transition.

Cancellation closes the active source file and the copy phase has a ten-minute
context deadline. A context cannot reliably preempt a kernel operation stuck on
an unresponsive filesystem. Other processes with root privilege are outside the
private-directory guarantee. Concurrent administrator/package-manager operations,
crash recovery, disk quotas and the remaining IPC/extension boundaries still need
their own audit; this is not an external independent audit.

## Implementation and evidence

The project already requires Go 1.26.9/toolchain 1.27.3 and x/sys v0.48.0. Use
standard os.Root, io.LimitReader, file descriptors and the installed Unix bindings;
no package or runtime dependency is added. The existing Minisign implementation
continues to authenticate metadata and the selected files.

Candidates checked on 25 October 2026 (open counts include PRs):

| Candidate | Current version/date | Stars / open | Module zip | License / minimum Go |
| --- | --- | --- | ---: | --- |
| [google/safeopen](https://github.com/google/safeopen) | pseudo-version 43626d6f4685, 2026-03-27 | 107 / 1 | 23148 B | Apache-2.0 / 1.21 |
| [filepath-securejoin](https://github.com/cyphar/filepath-securejoin) | v0.7.0, 2026-06-18 | 113 / 13 | 141080 B | BSD-3-Clause and MPL-2.0 (pathrs-lite) / 1.18 |

Both fit the toolchain. safeopen explicitly recommends os.Root instead of its own
API. securejoin/pathrs-lite adds another resolver and optional libpathrs integration
without replacing the domain's authenticated size/hash/selection policy. The
[standard traversal-resistant API](https://go.dev/blog/osroot) plus the existing
single-component Unix open is sufficient here.

Native tests use real signed producer fixtures for all three formats and an
ephemeral signed legacy pair. They cover sparse oversized inputs, corruption,
missing/empty files, symlinks, hardlinks, FIFO, directories, cancellation, output
permissions/nonemptiness, mixed CLI modes and a replaced source-directory path.
The namespace suite also builds the existing temporary-key verifier and exercises
the actual helper/CLI/signature/copy boundary with a valid pair and tampering.
Only package-manager/system-query operations are intercepted; no host package,
service, route or firewall operation is performed.
