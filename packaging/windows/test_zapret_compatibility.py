"""Load pinned winws with an empty capture filter in a disposable Windows runner."""

import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import zipfile

ARCHIVE_SHA256 = "c493e33a0dc4eba23a8686efdaba55f59755ad6ade3564aebd9d13f4c65e2e0c"
ARCHIVE_BYTES = 7_959_200
FILES = {
    "winws.exe": "a14bff1df6234ea555d2e0c61b589f0707c0b12d6c9b7eeccda76012154996e8",
    "WinDivert.dll": "c1e060ee19444a259b2162f8af0f3fe8c4428a1c6f694dce20de194ac8d7d9a2",
    "WinDivert64.sys": "8da085332782708d8767bcace5327a6ec7283c17cfb85e40b03cd2323a90ddc2",
    "cygwin1.dll": "103104a52e5293ce418944725df19e2bf81ad9269b9a120d71d39028e821499b",
}


def powershell(source, work):
    result = subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", source],
        env={**os.environ, "SORA_WINWS_FIXTURE_DIR": str(work)},
        capture_output=True, text=True, timeout=20, check=False,
    )
    if result.returncode:
        raise RuntimeError(f"Windows fixture check failed: {result.stdout} {result.stderr}")
    return result.stdout.strip()


def main():
    if (sys.platform != "win32" or os.environ.get("GITHUB_ACTIONS") != "true"
            or os.environ.get("RUNNER_OS") != "Windows"
            or os.environ.get("SORA_ISOLATED_ZAPRET_TEST") != "1"):
        raise RuntimeError("This driver fixture only runs in the explicit disposable Windows CI job")
    if len(sys.argv) != 3:
        raise RuntimeError("Expected pinned archive and a new private work directory")
    archive, work = Path(sys.argv[1]), Path(sys.argv[2]).resolve()
    work.mkdir(exist_ok=False)
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.GetCurrentProcess.restype = wintypes.HANDLE
    kernel.IsWow64Process2.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.USHORT), ctypes.POINTER(wintypes.USHORT)]
    kernel.IsWow64Process2.restype = wintypes.BOOL
    process_arch, native_arch = wintypes.USHORT(), wintypes.USHORT()
    if not kernel.IsWow64Process2(kernel.GetCurrentProcess(), ctypes.byref(process_arch), ctypes.byref(native_arch)):
        raise ctypes.WinError(ctypes.get_last_error())
    if native_arch.value != 0x8664:
        raise RuntimeError(f"Signed x64 driver requires a native AMD64 kernel, received {native_arch.value:#x}")
    if not (Path(os.environ["SystemRoot"]) / "System32" / "wlanapi.dll").is_file():
        raise RuntimeError("winws imports WLANAPI; this Windows image is incompatible without an OS component")
    with archive.open("rb") as stream:
        if archive.stat().st_size != ARCHIVE_BYTES or hashlib.file_digest(stream, "sha256").hexdigest() != ARCHIVE_SHA256:
            raise RuntimeError("Pinned zapret archive size or hash mismatch")
    with zipfile.ZipFile(archive) as source:
        for name, digest in FILES.items():
            data = source.read("zapret-v72.13/binaries/windows-x86_64/" + name)
            if hashlib.sha256(data).hexdigest() != digest:
                raise RuntimeError(f"Pinned native component hash mismatch: {name}")
            (work / name).write_bytes(data)
    print(powershell(r"""
      $ErrorActionPreference = 'Stop'
      if (Get-CimInstance Win32_SystemDriver -Filter "Name='WinDivert'") {
        throw 'A pre-existing WinDivert service makes this fixture non-isolated'
      }
      $driver = Join-Path $env:SORA_WINWS_FIXTURE_DIR 'WinDivert64.sys'
      $signature = Get-AuthenticodeSignature -LiteralPath $driver
      if ($signature.Status -ne 'Valid') { throw "Driver signature status: $($signature.Status)" }
      ConvertTo-Json -Compress @{phase='signature';status=[string]$signature.Status;thumbprint=$signature.SignerCertificate.Thumbprint}
    """, work))
    # The documented literal false filter diverts no traffic. Do not replace it
    # with a loopback/port filter: this probe is only about loader compatibility.
    log = work / "winws.log"
    child = None
    failure = None
    try:
        with log.open("wb") as output:
            child = subprocess.Popen(
                [str(work / "winws.exe"), "--wf-raw=false", "--dpi-desync=multisplit", "--dpi-desync-split-pos=1"],
                cwd=work, stdout=output, stderr=subprocess.STDOUT,
                creationflags=subprocess.CREATE_NO_WINDOW,
            )
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                if child.poll() is not None:
                    raise RuntimeError(f"winws exited before readiness: {child.returncode}")
                if log.stat().st_size > 64 * 1024:
                    raise RuntimeError("winws startup output exceeded the fixture budget")
                text = log.read_text(encoding="utf-8", errors="replace")
                if "windivert initialized. capture is started." in text:
                    print(json.dumps({"phase": "ready", "native_arch": native_arch.value, "filter": "false", "pid": child.pid}))
                    break
                time.sleep(0.05)
            else:
                raise RuntimeError("No driver readiness marker within 15 seconds")
    except Exception as error:
        failure = error
        print(f"Primary winws fixture failure: {error}", file=sys.stderr)
    finally:
        if child is not None and child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait(timeout=5)
        # WinDivert marks its newly created service for deletion. Stop only the
        # service whose binary path is exactly this fixture's pinned driver.
        try:
            print(powershell(r"""
              $ErrorActionPreference = 'Stop'
              $service = Get-CimInstance Win32_SystemDriver -Filter "Name='WinDivert'"
              if ($service) {
                $expected = Join-Path $env:SORA_WINWS_FIXTURE_DIR 'WinDivert64.sys'
                $actual = $service.PathName.Trim('"')
                if ($actual.StartsWith('\??\')) { $actual = $actual.Substring(4) }
                if ($actual -ne $expected) { throw 'Refusing cleanup of a driver outside this fixture' }
                & sc.exe stop WinDivert | Out-Null
                if ($LASTEXITCODE -notin @(0,1060,1062)) { throw 'Fixture driver stop failed' }
                $deadline = [DateTime]::UtcNow.AddSeconds(10)
                while ((Get-CimInstance Win32_SystemDriver -Filter "Name='WinDivert'") -and [DateTime]::UtcNow -lt $deadline) {
                  Start-Sleep -Milliseconds 100
                }
                if (Get-CimInstance Win32_SystemDriver -Filter "Name='WinDivert'") { throw 'Fixture driver service survived cleanup' }
              }
              ConvertTo-Json -Compress @{phase='cleanup';service_absent=$true}
            """, work))
        except Exception as error:
            print(f"Driver cleanup failure: {error}", file=sys.stderr)
            failure = failure or error
        if log.exists():
            print(log.read_bytes()[:64 * 1024].decode("utf-8", errors="replace"))
    if failure is not None:
        raise failure
    print(json.dumps({"phase": "passed", "filter": "false", "driver_loaded": True, "service_removed": True}))


if __name__ == "__main__":
    main()
