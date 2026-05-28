# Capture alternate app icon variants
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$base = "$PSScriptRoot\..\LifeZonesMap\Resources\Assets.xcassets"

$variants = @("sage", "clay", "ink")

foreach ($v in $variants) {
    $iconsetName = "AppIcon-$v.appiconset"
    $out = Join-Path $base $iconsetName
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    $file = Join-Path $out "icon-1024.png"

    $args = @(
        "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-sandbox",
        "--force-device-scale-factor=1",
        "--virtual-time-budget=4000",
        "--window-size=1024,1024",
        "--default-background-color=00000000",
        "--screenshot=$file",
        "http://localhost:8765/icon-variants.html?v=$v"
    )
    Start-Process -FilePath $edge -ArgumentList $args -NoNewWindow -Wait
    Write-Host "Wrote $iconsetName ($((Get-Item $file).Length) bytes)"

    # Write Contents.json
    $contents = @"
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"@
    $contentsPath = Join-Path $out "Contents.json"
    [System.IO.File]::WriteAllText($contentsPath, $contents)
}
Write-Host "Done. Three variants generated."
