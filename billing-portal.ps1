# ABC Freight Forwarders - Simulated Billing Portal (TCP 8080)
# Run in PowerShell as Administrator. Keep the window open while testing.
# v2 fix: read the client IP BEFORE closing the response (v1 printed an empty IP).

$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://+:8080/")
$l.Start()
Write-Host "ABC Freight Billing Portal chal raha hai (port 8080)..." -ForegroundColor Green
while ($l.IsListening) {
  $c = $l.GetContext()
  $ip = $c.Request.RemoteEndPoint.Address
  Write-Host "Request aayi: $ip" -ForegroundColor Yellow
  $html = "<h1>ABC Freight Forwarders - Billing Portal</h1><p>Sirf Finance zone ke liye</p>"
  $b = [Text.Encoding]::UTF8.GetBytes($html)
  $c.Response.OutputStream.Write($b, 0, $b.Length)
  $c.Response.Close()
}
