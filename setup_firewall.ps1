if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

New-NetFirewallRule -DisplayName "Django Port 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
Write-Host "Port 8000 opened successfully!"
Pause
