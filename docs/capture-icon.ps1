# Capture the 1024x1024 app icon master image
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$out  = "$PSScriptRoot\..\LifeZonesMap\Resources\Assets.xcassets\AppIcon.appiconset"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$file = Join-Path $out "icon-1024.png"

$args = @(
  "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-sandbox",
  "--force-device-scale-factor=1",
  "--virtual-time-budget=4000",
  "--window-size=1024,1024",
  "--default-background-color=00000000",  # transparent
  "--screenshot=$file",
  "http://localhost:8765/icon.html"
)
Start-Process -FilePath $edge -ArgumentList $args -NoNewWindow -Wait
Write-Host "Wrote $file ($((Get-Item $file).Length) bytes)"
