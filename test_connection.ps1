$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress | Select-Object -First 1
$url = "http://$($ip):8000/api/broadcast-alert/"
$uid = "9twZ7Lr4ImVb6hBEUadSkRfO74u2"

Write-Host "--- FIREQUARD CONNECTIVITY TEST ---" -ForegroundColor Cyan
Write-Host "Target IP: $ip"
Write-Host "Target URL: $url"
Write-Host "Testing Local Access..."

$body = @{
    type     = "fire"
    severity = "high"
    society  = "FireGuard HQ"
    block    = "TEST"
    details  = @{ gas_level = 50 }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -Headers @{ "X-User-ID" = $uid }
    Write-Host "✅ SUCCESS! Server is reachable." -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)"
    Write-Host "`nCheck your Django Terminal - you should see DEBUG logs now."
}
catch {
    Write-Host "❌ FAILED! Could not connect to server." -ForegroundColor Red
    Write-Host "Error: $_"
    Write-Host "`nPossible Causes:"
    Write-Host "1. Server not running (run: python manage.py runserver 0.0.0.0:8000)"
    Write-Host "2. Firewall blocking Port 8000"
    Write-Host "3. Wrong IP address detected"
}
Pause
