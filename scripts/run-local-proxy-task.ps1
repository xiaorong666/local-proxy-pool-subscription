param(
    [string]$Version = "",
    [int]$TimeoutMinutes = 45
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$RunScript = Join-Path $Root "scripts\run-subs-check.ps1"
$PublishScript = Join-Path $Root "scripts\publish-public.ps1"

& $RunScript -Version $Version -TimeoutMinutes $TimeoutMinutes -SkipGitPush
& $PublishScript -CommitMessage "chore: update proxy subscriptions"

Write-Host "local proxy task completed successfully."
