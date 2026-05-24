param(
    [string]$CommitMessage = "chore: update proxy subscriptions"
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

if (-not (Test-Path (Join-Path $Root ".git"))) {
    Write-Host "No git repository found; generated files were not pushed."
    return
}

$PublicDir = Join-Path $Root "public"
$GitCommand = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $GitCommand -and (Test-Path "${env:ProgramFiles}\Git\cmd\git.exe")) {
    $GitCommand = "${env:ProgramFiles}\Git\cmd\git.exe"
}

if (-not $GitCommand) {
    Write-Warning "Git is not installed; generated files were not pushed."
    return
}

$GitUserName = & $GitCommand config user.name
if (-not $GitUserName) {
    & $GitCommand config user.name "local-proxy-runner"
}

$GitUserEmail = & $GitCommand config user.email
if (-not $GitUserEmail) {
    & $GitCommand config user.email "local-proxy-runner@users.noreply.github.com"
}

Write-Host "Staging generated public files."
& $GitCommand add -- public/*.yaml public/*.txt public/index.html
if ($LASTEXITCODE -ne 0) {
    throw "git add failed"
}

if (Test-Path (Join-Path $PublicDir "stats")) {
    & $GitCommand add -- public/stats
    if ($LASTEXITCODE -ne 0) {
        throw "git add public/stats failed"
    }
}

$StagedFiles = @(& $GitCommand diff --cached --name-only)
if (-not $StagedFiles -or $StagedFiles.Count -eq 0) {
    Write-Host "No public file changes to commit."
    return
}

Write-Host "Committing updated subscription files:"
$StagedFiles | ForEach-Object { Write-Host " - $_" }

& $GitCommand commit -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    throw "git commit failed"
}

& $GitCommand push origin main
if ($LASTEXITCODE -ne 0) {
    throw "git push failed. Configure GitHub credentials on this Windows account, then rerun."
}

Write-Host "Published generated subscription files."
