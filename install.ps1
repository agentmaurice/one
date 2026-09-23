# Install AgentMaurice One for Windows without administrator privileges.
[CmdletBinding()]
param(
    [string]$Version = $(if ($env:AGENTMAURICE_ONE_VERSION) { $env:AGENTMAURICE_ONE_VERSION } else { "0.1.0-alpha.4" }),
    [string]$InstallDir = $(if ($env:AGENTMAURICE_ONE_INSTALL_DIR) { $env:AGENTMAURICE_ONE_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "AgentMaurice\bin" }),
    [string]$ReleaseBaseUrl = $env:AGENTMAURICE_ONE_RELEASE_BASE_URL,
    [switch]$AddToPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$') {
    throw "Invalid version: $Version"
}
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    throw "InstallDir cannot be empty"
}
if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows)) {
    throw "This installer supports Windows only"
}

$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
switch ($architecture) {
    "X64" { $arch = "amd64" }
    "Arm64" { $arch = "arm64" }
    default { throw "Unsupported Windows architecture: $architecture" }
}

$bundleName = "agentmaurice-one-$Version-windows-$arch"
$archiveName = "$bundleName.zip"
if ([string]::IsNullOrWhiteSpace($ReleaseBaseUrl)) {
    $ReleaseBaseUrl = "https://github.com/agentmaurice/one/releases/download/v$Version"
}
$ReleaseBaseUrl = $ReleaseBaseUrl.TrimEnd('/')
if ($ReleaseBaseUrl -notmatch '^https://') {
    $localHttp = $ReleaseBaseUrl -match '^http://(127\.0\.0\.1|localhost)(:[0-9]+)?($|/)'
    if (-not ($localHttp -and $env:AGENTMAURICE_ONE_ALLOW_HTTP -eq "1")) {
        throw "ReleaseBaseUrl must use HTTPS"
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agentmaurice-one-" + [System.Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempRoot $archiveName
$checksumPath = "$archivePath.sha256"
$stagedBinary = $null
$backupBinary = $null

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    $archiveUrl = "$ReleaseBaseUrl/$archiveName"
    Write-Host "Downloading $archiveName"
    try {
        Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath -UseBasicParsing
        Invoke-WebRequest -Uri "$archiveUrl.sha256" -OutFile $checksumPath -UseBasicParsing
    }
    catch {
        throw "Release asset is unavailable for windows/$arch at $archiveUrl. $($_.Exception.Message)"
    }

    $checksumFields = (Get-Content -LiteralPath $checksumPath -Raw).Trim() -split '\s+'
    $expectedChecksum = $checksumFields[0].ToLowerInvariant()
    if ($expectedChecksum -notmatch '^[0-9a-f]{64}$') {
        throw "Release checksum file is invalid"
    }
    $actualChecksum = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualChecksum -ne $expectedChecksum) {
        throw "Release archive checksum mismatch"
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $tempRoot
    $sourceBinary = Join-Path (Join-Path $tempRoot $bundleName) "maurice.exe"
    if (-not (Test-Path -LiteralPath $sourceBinary -PathType Leaf)) {
        throw "Release archive does not contain maurice.exe"
    }

    $signature = Get-AuthenticodeSignature -FilePath $sourceBinary
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "Windows Authenticode signature is not valid: $($signature.Status)"
    }
    if (-not $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Morvan Consulting(,|$)') {
        throw "Unexpected Windows signing authority"
    }

    & $sourceBinary version --json | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Downloaded maurice.exe did not start successfully"
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $destination = Join-Path $InstallDir "maurice.exe"
    $stagedBinary = Join-Path $InstallDir (".maurice.install." + [System.Guid]::NewGuid().ToString("N") + ".exe")
    Copy-Item -LiteralPath $sourceBinary -Destination $stagedBinary

    if (Test-Path -LiteralPath $destination) {
        $backupBinary = Join-Path $InstallDir (".maurice.backup." + [System.Guid]::NewGuid().ToString("N") + ".exe")
        [System.IO.File]::Replace($stagedBinary, $destination, $backupBinary, $true)
        $stagedBinary = $null
        Remove-Item -LiteralPath $backupBinary -Force
        $backupBinary = $null
    }
    else {
        [System.IO.File]::Move($stagedBinary, $destination)
        $stagedBinary = $null
    }

    if ($AddToPath) {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathEntries = @($userPath -split ';' | Where-Object { $_ })
        if ($pathEntries -notcontains $InstallDir) {
            $newPath = (@($pathEntries) + $InstallDir) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        }
        if (($env:Path -split ';') -notcontains $InstallDir) {
            $env:Path = "$InstallDir;$env:Path"
        }
    }

    Write-Host ""
    Write-Host "AgentMaurice One $Version installed at $destination"
    if (-not $AddToPath -and (($env:Path -split ';') -notcontains $InstallDir)) {
        Write-Host "Add $InstallDir to your user PATH, or rerun with -AddToPath."
    }
    Write-Host "Next: maurice help"
    Write-Host "Deno and embedded services are managed by One; do not install them separately."
    Write-Host ""
    Write-Host "Starting One and creating a temporary code-agent pairing prompt..."
    & $destination start --wait 120s
    if ($LASTEXITCODE -ne 0) { throw "One could not start; the binary is installed at $destination" }
    & $destination setup --pairing-prompt
    if ($LASTEXITCODE -ne 0) { throw "One setup or pairing failed; the binary is installed at $destination" }
}
finally {
    if ($stagedBinary -and (Test-Path -LiteralPath $stagedBinary)) {
        Remove-Item -LiteralPath $stagedBinary -Force
    }
    if ($backupBinary -and (Test-Path -LiteralPath $backupBinary)) {
        Remove-Item -LiteralPath $backupBinary -Force
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
