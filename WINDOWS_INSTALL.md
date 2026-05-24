# Windows Local Runner Install

This runs `subs-check` from the Windows machine so the filtered nodes match that machine's network, then commits and pushes `public/` back to GitHub.

## Requirements

- Windows PowerShell
- Git for Windows
- GitHub credentials configured for `https://github.com/xiaorong666/local-proxy-pool-subscription.git`

Install Git if needed:

```powershell
winget install --id Git.Git -e --source winget
```

## Manual Run

```powershell
Set-Location C:\local-proxy-pool-subscription
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-subs-check.ps1
```

Use `-SkipGitPush` to only generate local files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-subs-check.ps1 -SkipGitPush
```

## Scheduled Run

Run once from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-scheduled-task.ps1 -RunNow
```

The scheduled task runs every 3 hours and allows each local check to run for 45 minutes. Logs are written to:

```text
logs\local-proxy-pool-task.log
```

If `git push` fails, configure GitHub credentials on that Windows account and rerun `scripts\run-subs-check.ps1`.
