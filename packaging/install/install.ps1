# Run a previously authenticated copy of this script, never a downloaded pipe.
# SORA_VERIFIER must name a previously trusted sora-core; otherwise the installed
# core is used. A downloaded verifier cannot establish its own trust.
# Signature verification precedes package download, checksum checking and UAC.
#
# $env:SORA_VERSION = '1.0.3' installs that release instead of the latest.
# $env:SORA_DIST = '<folder>' installs an installer already in that folder,
# with signed SHA256SUMS; CI uses an isolated verifier with a temporary test key.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Windows PowerShell 5.1 offers TLS 1.0 by default, which GitHub refuses.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = 'https://github.com/levvs-one/sora'
$verifier = $env:SORA_VERIFIER
if (-not $verifier) { $verifier = Join-Path $env:ProgramFiles 'Sora/core/sora-core.exe' }
if (-not [IO.Path]::IsPathRooted($verifier)) { throw 'SORA_VERIFIER must be an absolute path to a previously trusted core.' }
$verifier = [IO.Path]::GetFullPath($verifier)
$verifierFile = Get-Item -LiteralPath $verifier -ErrorAction SilentlyContinue
if (-not $verifierFile -or $verifierFile.PSIsContainer -or ($verifierFile.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'A previously authenticated sora-core verifier is required. See docs/security/release-signatures.md.'
}
if ($env:SORA_DIST) {
    $distribution = [IO.Path]::GetFullPath($env:SORA_DIST).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($verifier.StartsWith($distribution, [StringComparison]::OrdinalIgnoreCase)) { throw 'Do not trust a verifier supplied with the downloads.' }
}

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Sora for Windows needs 64-bit Windows 10 1809 or later.'
}

$version = $env:SORA_VERSION
if ($env:SORA_DIST) {
    if (-not $version) { throw 'SORA_VERSION is needed with SORA_DIST.' }
} elseif (-not $version) {
    $latest = Invoke-RestMethod -UseBasicParsing 'https://api.github.com/repos/levvs-one/sora/releases/latest'
    $version = $latest.tag_name -replace '^v', ''
}
if ($version.Length -gt 64 -or $version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw "'$version' is not a stable release of Sora." }

$name = "Sora-Setup-$version-x64.exe"
$work = Join-Path ([IO.Path]::GetTempPath()) ("sora-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
try {
    foreach ($file in @('SHA256SUMS', 'SHA256SUMS.minisig', $name)) {
        if ($file -eq $name) {
            & $verifier -verify-release $work -release-version $version
            if ($LASTEXITCODE -ne 0) { throw 'The release signature was rejected; nothing was installed.' }
        }
        $target = Join-Path $work $file
        if ($env:SORA_DIST) {
            Copy-Item (Join-Path $env:SORA_DIST $file) $target
        } else {
            Invoke-WebRequest -UseBasicParsing "$repo/releases/download/v$version/$file" -OutFile $target
        }
    }
    $pattern = "^([0-9a-f]{64})\s+\*?$([regex]::Escape($name))$"
    $lines = @(Get-Content (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -match $pattern })
    if ($lines.Count -ne 1 -or $lines[0] -notmatch $pattern) { throw "$name needs exactly one entry in SHA256SUMS." }
    $expected = $Matches[1]
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $work $name)).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { throw "$name does not match SHA256SUMS; nothing was installed." }

    Write-Output "sora: installing $version"
    $setup = Start-Process (Join-Path $work $name) -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -PassThru
    # Start-Process -Wait also waits for the Sora window the installer opens.
    $setup.WaitForExit()
    if ($setup.ExitCode -ne 0) { throw "The installer ended with code $($setup.ExitCode)." }
    Write-Output 'sora: installed. Sora is in the Start menu; its icon lives in the tray.'
} finally {
    $resolvedWork = [IO.Path]::GetFullPath($work)
    if ([IO.Path]::GetDirectoryName($resolvedWork).TrimEnd('\') -ne [IO.Path]::GetTempPath().TrimEnd('\')) { throw 'Unexpected temporary directory; refusing cleanup.' }
    Remove-Item -LiteralPath $resolvedWork -Recurse -Force -ErrorAction SilentlyContinue
}
