param(
    [string]$TaskName = "LocalProxyPoolSubscription",
    [int]$EveryHours = 3,
    [int]$TimeoutMinutes = 45,
    [switch]$RunNow
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$RunScript = Join-Path $Root "scripts\run-subs-check.ps1"
$LogDir = Join-Path $Root "logs"
$LogFile = Join-Path $LogDir "local-proxy-pool-task.log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$Command = "& '$RunScript' -TimeoutMinutes $TimeoutMinutes *>> '$LogFile' 2>&1"
$EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Hours $EveryHours) -RepetitionDuration (New-TimeSpan -Days 3650)
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Description "Run local subs-check and publish proxy subscription files." -Force | Out-Null

Write-Host "Registered scheduled task: $TaskName"
Write-Host "Log file: $LogFile"

if ($RunNow) {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "Started scheduled task: $TaskName"
}
