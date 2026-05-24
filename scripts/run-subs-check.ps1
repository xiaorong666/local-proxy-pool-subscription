param(
    [string]$Version = "",
    [int]$TimeoutMinutes = 15,
    [switch]$SkipGitPush
)

$ErrorActionPreference = "Stop"

if (-not $Version) {
    $Version = if ($env:SUBS_CHECK_VERSION) { $env:SUBS_CHECK_VERSION } else { "v1.13.3" }
}

if ($env:SUBS_CHECK_TIMEOUT_MINUTES) {
    $TimeoutMinutes = [int]$env:SUBS_CHECK_TIMEOUT_MINUTES
}

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

$TmpDir = Join-Path $Root "tmp"
$PublicDir = Join-Path $Root "public"
New-Item -ItemType Directory -Force -Path $TmpDir, $PublicDir | Out-Null

$StampPath = Join-Path $TmpDir "run-start.stamp"
Set-Content -Path $StampPath -Value (Get-Date -Format o) -Encoding ascii
$Stamp = Get-Item $StampPath

$ArchiveName = "subs-check_Windows_x86_64.zip"
$ArchivePath = Join-Path $TmpDir $ArchiveName
$DownloadUrl = "https://github.com/sinspired/subs-check/releases/download/$Version/$ArchiveName"
$ExePath = Join-Path $TmpDir "subs-check.exe"

if (-not (Test-Path $ExePath)) {
    Write-Host "Downloading $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ArchivePath
    Expand-Archive -Path $ArchivePath -DestinationPath $TmpDir -Force

    if (-not (Test-Path $ExePath)) {
        $Found = Get-ChildItem -Path $TmpDir -Recurse -Filter "subs-check.exe" | Select-Object -First 1
        if (-not $Found) {
            throw "subs-check.exe was not found after extracting $ArchiveName"
        }
        Copy-Item -LiteralPath $Found.FullName -Destination $ExePath -Force
    }
}

Write-Host "Running subs-check for up to $TimeoutMinutes minute(s)"
$Process = Start-Process -FilePath $ExePath -ArgumentList @("-f", "config/config.yaml") -WorkingDirectory $Root -PassThru -NoNewWindow
$Finished = $Process.WaitForExit($TimeoutMinutes * 60 * 1000)

if (-not $Finished) {
    Write-Host "Timeout reached; stopping subs-check and validating generated files"
    Stop-Process -Id $Process.Id -Force
} elseif ($Process.ExitCode -ne 0) {
    throw "subs-check exited with code $($Process.ExitCode)"
}

$RequiredFiles = @(
    "public/all.yaml",
    "public/mihomo.yaml",
    "public/base64.txt"
)

foreach ($RelativePath in $RequiredFiles) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path $Path)) {
        throw "Missing output file: $RelativePath"
    }

    $Item = Get-Item $Path
    if ($Item.Length -le 0) {
        throw "Empty output file: $RelativePath"
    }

    if ($Item.LastWriteTime -le $Stamp.LastWriteTime) {
        throw "Output file was not refreshed in this run: $RelativePath"
    }
}

@'
<!doctype html>
<meta charset="utf-8">
<title>Proxy Subscription</title>
<h1>Proxy Subscription</h1>
<ul>
  <li><a href="./mihomo.yaml">mihomo.yaml</a></li>
  <li><a href="./all.yaml">all.yaml</a></li>
  <li><a href="./base64.txt">base64.txt</a></li>
  <li><a href="./history.yaml">history.yaml</a></li>
</ul>
'@ | Set-Content -Path (Join-Path $PublicDir "index.html") -Encoding utf8

if (-not $SkipGitPush -and (Test-Path (Join-Path $Root ".git"))) {
    $GitCommand = (Get-Command git -ErrorAction SilentlyContinue).Source
    if (-not $GitCommand -and (Test-Path "${env:ProgramFiles}\Git\cmd\git.exe")) {
        $GitCommand = "${env:ProgramFiles}\Git\cmd\git.exe"
    }

    if (-not $GitCommand) {
        Write-Warning "Git is not installed; generated files were not pushed."
        exit 0
    }

    $GitUserName = & $GitCommand config user.name
    if (-not $GitUserName) {
        & $GitCommand config user.name "local-proxy-runner"
    }

    $GitUserEmail = & $GitCommand config user.email
    if (-not $GitUserEmail) {
        & $GitCommand config user.email "local-proxy-runner@users.noreply.github.com"
    }

    & $GitCommand add -- public/*.yaml public/*.txt public/index.html
    if (Test-Path (Join-Path $PublicDir "stats")) {
        & $GitCommand add -- public/stats
    }

    $StagedFiles = & $GitCommand diff --cached --name-only
    if (-not $StagedFiles) {
        Write-Host "No public file changes to commit."
        exit 0
    }

    Write-Host "Committing updated subscription files:"
    $StagedFiles | ForEach-Object { Write-Host " - $_" }

    & $GitCommand commit -m "chore: update proxy subscriptions"
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed"
    }

    & $GitCommand push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed. Configure GitHub credentials on this Windows account, then rerun."
    }
}

Write-Host "subs-check completed successfully."
