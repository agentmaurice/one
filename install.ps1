# Install AgentMaurice One for Windows without administrator privileges.
[CmdletBinding()]
param(
    [string]$Version = $(if ($env:AGENTMAURICE_ONE_VERSION) { $env:AGENTMAURICE_ONE_VERSION } else { "0.1.0-alpha.5" }),
    [string]$InstallDir = $(if ($env:AGENTMAURICE_ONE_INSTALL_DIR) { $env:AGENTMAURICE_ONE_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "AgentMaurice\bin" }),
    [string]$ReleaseBaseUrl = $env:AGENTMAURICE_ONE_RELEASE_BASE_URL,
    [string]$GetBaseUrl = $(if ($env:AGENTMAURICE_ONE_GET_BASE_URL) { $env:AGENTMAURICE_ONE_GET_BASE_URL } else { "https://get.agentmaurice.app" }),
    [switch]$AddToPath,
    [string]$DataDir = $env:AGENTMAURICE_ONE_DATA_DIR,
    [switch]$NoAutostart
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
$officialDownload = [string]::IsNullOrWhiteSpace($ReleaseBaseUrl)
$GetBaseUrl = $GetBaseUrl.TrimEnd('/')
if ($officialDownload) {
    $ReleaseBaseUrl = "$GetBaseUrl/products/one/download"
}
else {
    $ReleaseBaseUrl = $ReleaseBaseUrl.TrimEnd('/')
}
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
$stagedViewer = $null
$backupViewer = $null
$viewerSwapped = $false
$viewerCommitted = $false
$restartExistingTask = $false

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    if ($officialDownload) {
        $archiveUrl = "${ReleaseBaseUrl}?version=$Version&os=windows&arch=$arch&type=archive"
        $checksumUrl = "${ReleaseBaseUrl}?version=$Version&os=windows&arch=$arch&type=checksum"
    }
    else {
        $archiveUrl = "$ReleaseBaseUrl/$archiveName"
        $checksumUrl = "$archiveUrl.sha256"
    }
    Write-Host "Downloading $archiveName"
    try {
        Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath -UseBasicParsing
        Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumPath -UseBasicParsing
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
    $sourceViewer = Join-Path (Join-Path $tempRoot $bundleName) "viewer"
    if (-not (Test-Path -LiteralPath (Join-Path $sourceViewer "index.html") -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $sourceViewer ".bundled-viewer.json") -PathType Leaf)) {
        throw "Release archive does not contain the pinned One viewer"
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
    if (-not $NoAutostart) {
        & $sourceBinary service --help | Out-Null
        if ($LASTEXITCODE -ne 0) {
            # Releases before `maurice service` still install: One is started manually.
            Write-Warning "This One release does not support automatic startup; One will be started without registering a startup task."
            $NoAutostart = $true
        }
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $destination = Join-Path $InstallDir "maurice.exe"
    $viewerDestination = Join-Path $InstallDir "viewer"
    if ((Test-Path -LiteralPath $viewerDestination) -and
        -not (Test-Path -LiteralPath (Join-Path $viewerDestination ".bundled-viewer.json") -PathType Leaf)) {
        throw "Install directory already contains an unrelated viewer directory"
    }
    $stagedViewer = Join-Path $InstallDir (".viewer.install." + [System.Guid]::NewGuid().ToString("N"))
    Copy-Item -LiteralPath $sourceViewer -Destination $stagedViewer -Recurse
    $stagedBinary = Join-Path $InstallDir (".maurice.install." + [System.Guid]::NewGuid().ToString("N") + ".exe")
    Copy-Item -LiteralPath $sourceBinary -Destination $stagedBinary

    if (Test-Path -LiteralPath $viewerDestination) {
        $backupViewer = Join-Path $InstallDir (".viewer.backup." + [System.Guid]::NewGuid().ToString("N"))
        Move-Item -LiteralPath $viewerDestination -Destination $backupViewer
    }
    $viewerSwapped = $true
    Move-Item -LiteralPath $stagedViewer -Destination $viewerDestination
    $stagedViewer = $null

    if (Test-Path -LiteralPath $destination) {
        $existingTask = Get-ScheduledTask -TaskName "AgentMaurice One" -ErrorAction SilentlyContinue
        if ($null -ne $existingTask -and $existingTask.State -eq "Running") {
            $restartExistingTask = $true
            Stop-ScheduledTask -TaskName "AgentMaurice One"
            for ($attempt = 0; $attempt -lt 20; $attempt++) {
                Start-Sleep -Milliseconds 250
                if ((Get-ScheduledTask -TaskName "AgentMaurice One").State -ne "Running") { break }
            }
            if ((Get-ScheduledTask -TaskName "AgentMaurice One").State -eq "Running") {
                throw "One did not stop before the executable update"
            }
        }
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
    $viewerCommitted = $true

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
    if (-not $NoAutostart) {
        $serviceArguments = @("service", "install", "--home-profile", "workstation")
        if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
            $serviceArguments += @("--data-dir", $DataDir)
        }
        & $destination @serviceArguments
        if ($LASTEXITCODE -ne 0) {
            throw "One was installed, but automatic startup failed or One did not become healthy; check maurice service status and maurice doctor"
        }
    }
    elseif ($restartExistingTask) {
        Start-ScheduledTask -TaskName "AgentMaurice One"
    }
    $resolvedDataDir = if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
        $DataDir
    } elseif ($env:APP_DATA_DIR) {
        $env:APP_DATA_DIR
    } else {
        Join-Path $HOME ".maurice\one"
    }
    $instanceExisted = (Test-Path -LiteralPath (Join-Path $resolvedDataDir "bootstrap_key")) -or
        (Test-Path -LiteralPath (Join-Path $resolvedDataDir "config\standalone.yaml"))
    if ($instanceExisted) {
        $stopArguments = @("stop")
        if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
            $stopArguments += @("--data-dir", $DataDir)
        }
        & $destination @stopArguments
        if ($LASTEXITCODE -ne 0) { throw "One could not stop; the binary is installed at $destination" }
        Write-Host ""
        Write-Host "Updating One on the existing data directory..."
    }
    else {
        Write-Host ""
        Write-Host "Starting One and creating a temporary code-agent pairing prompt..."
    }
    # One process per data directory: the startup service already started One;
    # a manual start only runs without it.
    if ($NoAutostart) {
        $startArguments = @("start", "--wait", "120s")
        if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
            $startArguments += @("--data-dir", $DataDir)
        }
        & $destination @startArguments
        if ($LASTEXITCODE -ne 0) { throw "One could not start; the binary is installed at $destination" }
    }
    if ($instanceExisted) {
        $pairingPrompt = "Updated One on the existing data directory. Organization, data, and the CLI context stay. No new pairing prompt.`n`nOne data directory: $resolvedDataDir"
    }
    else {
    $pairingPrompt = & $destination setup --pairing-prompt
    if ($LASTEXITCODE -ne 0) { throw "One setup or pairing failed; the binary is installed at $destination" }
    $doctorStatus = $null
    try { $doctorStatus = & $destination status --json 2>$null | ConvertFrom-Json } catch { }
    $doctorDataDir = if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
        $DataDir
    } elseif ($doctorStatus -and $doctorStatus.data_dir) {
        $doctorStatus.data_dir
    } elseif ($env:APP_DATA_DIR) {
        $env:APP_DATA_DIR
    } else {
        Join-Path $HOME ".maurice\one"
    }
    $pairingPrompt = $pairingPrompt -join [Environment]::NewLine
    if ($pairingPrompt.Contains("maurice doctor --json")) {
        $pairingPrompt = $pairingPrompt.Replace(
            "maurice doctor --json", "maurice doctor --data-dir ONE_DATA_DIR --json")
        $pairingPrompt += [Environment]::NewLine + [Environment]::NewLine +
            "One data directory (replace ONE_DATA_DIR with this path): $doctorDataDir"
    } else {
        $pairingPrompt += [Environment]::NewLine + [Environment]::NewLine +
            "Run Doctor with --data-dir set to this One directory: $doctorDataDir"
    }
    }

    $installationConsent = $false
    if ($officialDownload -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
        $consentAnswer = Read-Host "Allow AgentMaurice to report this installation (version, OS, architecture and a random installation ID) to get.agentmaurice.app? [y/N]"
        $installationConsent = $consentAnswer -match '^(?i:y|yes)$'
    }

    if ($officialDownload -and $installationConsent) {
        try {
            $installationIdPath = Join-Path $InstallDir ".agentmaurice-one-installation-id"
            if (Test-Path -LiteralPath $installationIdPath) {
                $installationId = (Get-Content -LiteralPath $installationIdPath -Raw).Trim()
                if ($installationId -notmatch '^[0-9a-f]{32}$') {
                    throw "Stored installation ID is invalid"
                }
            }
            else {
                $installationId = [System.Guid]::NewGuid().ToString("N")
                [System.IO.File]::WriteAllText($installationIdPath, "$installationId`n")
            }
            $installationPayload = @{
                installation_id = $installationId
                version = $Version
                os = "windows"
                arch = $arch
            } | ConvertTo-Json -Compress
            Invoke-WebRequest -Uri "$GetBaseUrl/products/one/installations" -Method Post `
                -ContentType "application/json" -Body $installationPayload -TimeoutSec 10 `
                -UseBasicParsing | Out-Null
        }
        catch {
            Write-Warning "Installation succeeded; installation count could not be reported."
        }
    }
    $pairingPrompt | Write-Output
}
catch {
    if ($viewerSwapped -and -not $viewerCommitted) {
        if (Test-Path -LiteralPath $viewerDestination) {
            Remove-Item -LiteralPath $viewerDestination -Recurse -Force
        }
        if ($backupViewer -and (Test-Path -LiteralPath $backupViewer)) {
            Move-Item -LiteralPath $backupViewer -Destination $viewerDestination
            $backupViewer = $null
        }
    }
    if ($restartExistingTask) {
        try { Start-ScheduledTask -TaskName "AgentMaurice One" } catch { }
    }
    throw
}
finally {
    if ($stagedViewer -and (Test-Path -LiteralPath $stagedViewer)) {
        Remove-Item -LiteralPath $stagedViewer -Recurse -Force
    }
    if ($backupViewer -and (Test-Path -LiteralPath $backupViewer)) {
        Remove-Item -LiteralPath $backupViewer -Recurse -Force
    }
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
