# Installs Sora on Windows in one command, from PowerShell:
#
#   irm https://github.com/levvs-one/sora/releases/latest/download/install.ps1 | iex
#
# It finds the latest release, downloads the installer, verifies the
# release's minisign signature on SHA256SUMS, checks the installer against
# the signed SHA256SUMS and runs it without questions; Windows asks once for
# administrator rights, because the core is installed as a service. Nothing
# runs when the signature or the checksum does not match.
#
# $env:SORA_VERSION = '1.0.3' installs that release instead of the latest.
# $env:SORA_DIST = '<folder>' installs an installer already in that folder,
# with its SHA256SUMS and SHA256SUMS.minisig; CI checks the installer it
# built this way (CI must provide a .minisig made with its test key, or set
# $env:SORA_MINISIGN_PUBKEY to that test key).
# $env:SORA_MINISIGN_PUBKEY = '<base64>' overrides the embedded release
# public key (useful for CI self-tests with an ephemeral key).

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Windows PowerShell 5.1 offers TLS 1.0 by default, which GitHub refuses.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = 'https://github.com/levvs-one/sora'

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'Sora for Windows needs 64-bit Windows 10 1809 or later.'
}

# Downloads with retries and backoff: mirrors drop a connection now and then,
# and a half-downloaded installer must never reach the signature check.
function Invoke-SoraDownload {
    param([string]$Uri, [string]$OutFile, [int]$TimeoutSec = 300)
    $delay = 5
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing $Uri -OutFile $OutFile -TimeoutSec $TimeoutSec
            return
        } catch {
            if ($attempt -eq 3) { throw "sora: download failed after 3 attempts: $Uri" }
            Write-Output "sora: download attempt $attempt failed, retrying in $delay s"
            Start-Sleep -Seconds $delay
            $delay *= 2
        }
    }
}

$version = $env:SORA_VERSION
if ($env:SORA_DIST) {
    if (-not $version) { throw 'SORA_VERSION is needed with SORA_DIST.' }
} elseif (-not $version) {
    $delay = 5
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            # The latest release redirects to its tag; no API call, no rate
            # limit — the same source install.sh reads.
            $response = Invoke-WebRequest -UseBasicParsing "$repo/releases/latest" -TimeoutSec 60
            $tag = $response.BaseResponse.ResponseUri.Segments[-1].TrimEnd('/')
            if (-not $tag) { throw 'no tag in the redirect target' }
            $version = $tag -replace '^v', ''
            break
        } catch {
            if ($attempt -eq 3) { throw "sora: could not tell the latest release: $($_.Exception.Message)" }
            Start-Sleep -Seconds $delay
            $delay *= 2
        }
    }
}
if ($version -notmatch '^\d+(\.\d+){2,3}$') { throw "'$version' is not a release of Sora." }

$name = "Sora-Setup-$version-x64.exe"
$work = Join-Path ([IO.Path]::GetTempPath()) ("sora-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null

# --- Release signature trust anchor (SORA-H1) ---
# Minisign public key of the release signer, embedded at release time.
# PLACEHOLDER: the owner must run the key ceremony (see FIX-PLAN.md
# section 9, "Key ceremony") and replace this value with the real release
# public key. Until then installation refuses to proceed (fail-closed)
# instead of pretending the download is authentic.
$SoraReleasePubkey = if ($env:SORA_MINISIGN_PUBKEY) { $env:SORA_MINISIGN_PUBKEY } else { 'REPLACE-ME-AFTER-KEY-CEREMONY' }

function Assert-ReleaseSignature {
    param([string]$SignedFile, [string]$SignatureFile)
    if (-not $SoraReleasePubkey -or $SoraReleasePubkey -eq 'REPLACE-ME-AFTER-KEY-CEREMONY') {
        throw 'Release signing is not configured yet: the minisign public key is still a placeholder. The owner must complete the key ceremony (FIX-PLAN.md, section 9) before releases can be installed.'
    }
    $minisign = Get-Command minisign -ErrorAction SilentlyContinue
    if (-not $minisign) {
        throw 'minisign is required to verify the release signature but was not found in PATH.'
    }
    $pubFile = Join-Path $work 'sora-release.pub'
    "untrusted comment: sora release signing key`n$SoraReleasePubkey" | Set-Content -NoNewline -Path $pubFile
    & $minisign.Source -V -q -p $pubFile -m $SignedFile -x $SignatureFile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Signature verification failed for SHA256SUMS; nothing was installed.'
    }
    Write-Output 'sora: release signature verified'
}

try {
    foreach ($file in @('SHA256SUMS', 'SHA256SUMS.minisig', $name)) {
        $target = Join-Path $work $file
        if ($env:SORA_DIST) {
            Copy-Item (Join-Path $env:SORA_DIST $file) $target
        } else {
            Invoke-SoraDownload "$repo/releases/download/v$version/$file" $target
        }
    }
    # Authenticate the checksum manifest BEFORE trusting any hash in it.
    Assert-ReleaseSignature (Join-Path $work 'SHA256SUMS') (Join-Path $work 'SHA256SUMS.minisig')
    $pattern = "^([0-9a-f]{64})\s+\*?$([regex]::Escape($name))$"
    $line = Get-Content (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if (-not $line -or $line -notmatch $pattern) { throw "$name is not in SHA256SUMS." }
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
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
