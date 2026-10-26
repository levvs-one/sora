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
Add-Type -AssemblyName System.Net.Http
$downloadClient = [Net.Http.HttpClient]::new()
function Receive-ReleaseFile([string]$File, [long]$Limit) {
    $inputStream = $null; $outputStream = $null; $response = $null
    $deadline = [Threading.CancellationTokenSource]::new()
    $deadline.CancelAfter(600000)
    try {
        if ($env:SORA_DIST) {
            $source = Get-Item -LiteralPath (Join-Path $env:SORA_DIST $File)
            if ($source.PSIsContainer -or ($source.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Release inputs must be regular files.' }
            $inputStream = [IO.File]::OpenRead($source.FullName)
        } else {
            $response = $downloadClient.GetAsync("$repo/releases/download/v$version/$File", [Net.Http.HttpCompletionOption]::ResponseHeadersRead, $deadline.Token).GetAwaiter().GetResult()
            [void]$response.EnsureSuccessStatusCode()
            if ($response.RequestMessage.RequestUri.Scheme -ne 'https' -or $response.Content.Headers.ContentLength -gt $Limit) { throw 'Invalid download scheme or size.' }
            $streamTask = $response.Content.ReadAsStreamAsync()
            $streamTask.Wait($deadline.Token)
            $inputStream = $streamTask.GetAwaiter().GetResult()
        }
        $outputStream = [IO.File]::Create((Join-Path $work $File))
        $buffer = [byte[]]::new(65536)
        [long]$total = 0
        while ($true) {
            $readTask = $inputStream.ReadAsync($buffer, 0, $buffer.Length, $deadline.Token)
            # Bound the wait even if a stream cannot cancel an in-flight read.
            $readTask.Wait($deadline.Token)
            $count = $readTask.GetAwaiter().GetResult()
            if ($count -eq 0) { break }
            $total += $count
            if ($total -gt $Limit) { throw "$File exceeds its download size limit." }
            $outputStream.Write($buffer, 0, $count)
        }
        if ($total -eq 0) { throw "$File is empty." }
    } finally {
        if ($outputStream) { $outputStream.Dispose() }
        if ($inputStream) { $inputStream.Dispose() }
        if ($response) { $response.Dispose() }
        $deadline.Dispose()
    }
}
try {
    Receive-ReleaseFile 'SHA256SUMS' 1048576
    Receive-ReleaseFile 'SHA256SUMS.minisig' 8192
    if (-not (Get-Content -LiteralPath (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -cmatch ' [ *]release[.]json$' })) { throw 'Schema 1 release metadata is required.' }
    Receive-ReleaseFile 'release.json' 1048576
    & $verifier -verify-release $work -release-version $version
    if ($LASTEXITCODE -ne 0) { throw 'The release signature or metadata was rejected; nothing was installed.' }
    $sizeText = & $verifier -verify-release $work -release-version $version -release-artifact $name -release-target 'windows/amd64'
    if ($LASTEXITCODE -ne 0 -or $sizeText -notmatch '^(0|[1-9][0-9]{0,9})$') { throw 'Invalid verifier size response.' }
    [long]$signedSize = $sizeText
    if ($signedSize -lt 1 -or $signedSize -gt 2147483648) { throw 'Invalid verifier size response.' }
    Receive-ReleaseFile $name $signedSize
    if ((Get-Item -LiteralPath (Join-Path $work $name)).Length -ne $signedSize) { throw 'Signed package size mismatch.' }
    $pattern = "^([0-9a-f]{64})\s+\*?$([regex]::Escape($name))$"
    $lines = @(Get-Content (Join-Path $work 'SHA256SUMS') | Where-Object { $_ -match $pattern })
    if ($lines.Count -ne 1 -or $lines[0] -notmatch $pattern) { throw "$name needs exactly one entry in SHA256SUMS." }
    $expected = $Matches[1]
    $hash = [Security.Cryptography.SHA256]::Create()
    $package = [IO.File]::OpenRead((Join-Path $work $name))
    try {
        $actual = [BitConverter]::ToString($hash.ComputeHash($package)).Replace('-', '').ToLowerInvariant()
    } finally {
        $package.Dispose()
        $hash.Dispose()
    }
    if ($actual -ne $expected) { throw "$name does not match SHA256SUMS; nothing was installed." }

    Write-Output "sora: installing $version"
    $setup = Start-Process (Join-Path $work $name) -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -PassThru
    # Start-Process -Wait also waits for the Sora window the installer opens.
    $setup.WaitForExit()
    if ($setup.ExitCode -ne 0) { throw "The installer ended with code $($setup.ExitCode)." }
    Write-Output 'sora: installed. Sora is in the Start menu; its icon lives in the tray.'
} finally {
    $downloadClient.Dispose()
    $resolvedWork = [IO.Path]::GetFullPath($work)
    if ([IO.Path]::GetDirectoryName($resolvedWork).TrimEnd('\') -ne [IO.Path]::GetTempPath().TrimEnd('\')) { throw 'Unexpected temporary directory; refusing cleanup.' }
    Remove-Item -LiteralPath $resolvedWork -Recurse -Force -ErrorAction SilentlyContinue
}
