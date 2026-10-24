[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Path,
    [Parameter(Mandatory)][string]$ReportPath
)

$ErrorActionPreference = 'Stop'
$targets = @(Get-Item -LiteralPath $Path)
$files = @()
foreach ($target in $targets) {
    $entries = @($target)
    if ($target.PSIsContainer) { $entries += @(Get-ChildItem -LiteralPath $target.FullName -Recurse -Force) }
    if ($entries | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) {
        throw 'Release inspection refuses symbolic links and junctions'
    }
    $files += @($entries | Where-Object { -not $_.PSIsContainer -and $_.Extension -in '.exe', '.dll', '.sys' })
}
$files = @($files | Sort-Object FullName -Unique)
if (-not $files.Count) { throw 'No Windows executable files were found' }
if ([IO.Path]::GetExtension($ReportPath) -ne '.json') { throw 'The report path must end in .json' }

$inventory = foreach ($file in $files) {
    $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName
    [ordered]@{
        Path = $file.FullName
        Size = $file.Length
        SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        Authenticode = $signature.Status.ToString()
        Signer = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { $null }
        SignerThumbprint = if ($signature.SignerCertificate) { $signature.SignerCertificate.Thumbprint } else { $null }
        ProductVersion = $file.VersionInfo.ProductVersion
        SoraOwned = $file.Name -match '^(sora(?:-core|-sync)?\.exe|Sora-Setup-.+\.exe)$'
    }
}

$scanResults = @()
$scanFailure = $null
$defenderStatus = $null
$bundleErrors = @()
foreach ($application in @($files | Where-Object { $_.Name -eq 'sora.exe' })) {
    foreach ($relative in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'flutter_windows.dll', 'data/icudtl.dat', 'data/app.so', 'data/flutter_assets')) {
        $dependency = Join-Path $application.DirectoryName $relative
        $isDirectory = $relative -eq 'data/flutter_assets'
        $kind = if ($isDirectory) { 'Container' } else { 'Leaf' }
        if (-not (Test-Path -LiteralPath $dependency -PathType $kind)) {
            $bundleErrors += "Missing application dependency: $dependency"
        } elseif (-not $isDirectory -and (Get-Item -LiteralPath $dependency).Length -eq 0) {
            $bundleErrors += "Empty application dependency: $dependency"
        }
    }
}
try {
    if ($bundleErrors.Count) { throw ($bundleErrors -join "`n") }
    $status = Get-MpComputerStatus
    $defenderStatus = [ordered]@{
        Enabled = $status.AntivirusEnabled
        RealTimeEnabled = $status.RealTimeProtectionEnabled
        Version = $status.AntivirusSignatureVersion
        UpdatedUTC = $status.AntivirusSignatureLastUpdated.ToUniversalTime().ToString('o')
    }
    if (-not $status.AMServiceEnabled -or -not $status.AntivirusEnabled) {
        throw 'Microsoft Defender Antivirus is unavailable; files were not scanned'
    }
    $platformRoot = Join-Path $env:ProgramData 'Microsoft\Windows Defender\Platform'
    $scanner = Get-ChildItem -LiteralPath $platformRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object { Join-Path $_.FullName 'MpCmdRun.exe' } |
        Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $scanner) { $scanner = Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe' }
    if (-not (Test-Path -LiteralPath $scanner)) { throw 'Microsoft Defender scan executable is unavailable' }
    # Read-only custom scans inspect archives and ignore file exclusions.
    # No protection setting is changed, and scan detections are not remediated.
    foreach ($target in $targets) {
        $scanOutput = @(& $scanner -Scan -ScanType 3 -File $target.FullName -DisableRemediation 2>&1)
        $scanExit = $LASTEXITCODE
        $scanResults += [ordered]@{ Path = $target.FullName; ExitCode = $scanExit; Output = ($scanOutput -join "`n") }
        if ($scanExit -ne 0) { throw 'Defender detected a threat or could not complete the scan; inspect its output' }
    }
    foreach ($entry in $inventory) {
        if ((Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.SHA256) {
            throw 'An inspected file changed during the scan'
        }
    }
} catch {
    $scanFailure = $_.Exception.Message
}

$unsignedOwned = @($inventory | Where-Object { $_.SoraOwned -and $_.Authenticode -ne 'Valid' })
$ownedNames = @($inventory | Where-Object { $_.SoraOwned } | ForEach-Object { [IO.Path]::GetFileName($_.Path) })
$missingOwned = @('sora.exe', 'sora-core.exe', 'sora-sync.exe') | Where-Object { $_ -notin $ownedNames }
$completeRelease = @($missingOwned).Count -eq 0 -and @($ownedNames | Where-Object { $_ -like 'Sora-Setup-*.exe' }).Count -gt 0
$report = [ordered]@{
    CreatedUTC = [DateTime]::UtcNow.ToString('o')
    Files = @($inventory)
    Defender = $defenderStatus
    Scans = $scanResults
    ScanError = $scanFailure
    CompleteReleaseSet = $completeRelease
    BundleErrors = $bundleErrors
    AuthenticodeReady = $completeRelease -and $unsignedOwned.Count -eq 0
    Scope = 'Local Defender scan and Authenticode status; not a guarantee for other products or SmartScreen reputation'
}
$reportFile = [IO.Path]::GetFullPath($ReportPath)
New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($reportFile)) | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportFile -Encoding utf8
Write-Output "Windows security evidence: $reportFile"
if ($scanFailure) { throw $scanFailure }
if ($env:GITHUB_REF_TYPE -eq 'tag' -and -not $report.AuthenticodeReady) {
    throw 'A release requires the complete Sora executable set with valid Authenticode signatures'
}
