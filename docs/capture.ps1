# Captures Life Zones design screenshots using Edge headless.
# Run while python design server is on http://localhost:8765
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$out  = "$PSScriptRoot\screenshots"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$jobs = @(
    @{ s = "map";        w = 460;  h = 920;  f = "01-map.png" },
    @{ s = "checkin";    w = 460;  h = 920;  f = "02-checkin.png" },
    @{ s = "pulse";      w = 460;  h = 920;  f = "03-pulse.png" },
    @{ s = "welcome";    w = 460;  h = 920;  f = "04-onboard-welcome.png" },
    @{ s = "zones";      w = 460;  h = 920;  f = "05-onboard-zones.png" },
    @{ s = "schedule";   w = 460;  h = 920;  f = "06-onboard-schedule.png" },
    @{ s = "first";      w = 460;  h = 920;  f = "07-onboard-first.png" },
    @{ s = "hifi";       w = 1320; h = 950;  f = "08-hifi-three.png";   layout = "row" },
    @{ s = "widgets";    w = 1240; h = 830;  f = "09-widgets.png";      layout = "scroll" },
    @{ s = "identity";   w = 1240; h = 2700; f = "10-identity.png";     layout = "scroll" }
)

foreach ($j in $jobs) {
    $url = "http://localhost:8765/capture.html?screen=$($j.s)"
    if ($j.ContainsKey('layout')) { $url += "&layout=$($j.layout)" }
    $file = Join-Path $out $j.f
    Write-Host "Capturing $($j.s) -> $($j.f)"

    # Build args; use Start-Process so PowerShell doesn't choke on stderr
    $args = @(
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-sandbox",
        "--force-device-scale-factor=2",
        "--virtual-time-budget=8000",
        "--window-size=$($j.w),$($j.h)",
        "--screenshot=$file",
        $url
    )

    $proc = Start-Process -FilePath $edge -ArgumentList $args -NoNewWindow -PassThru -Wait
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  ok $size bytes"
    } else {
        Write-Host "  MISSING (exit $($proc.ExitCode))"
    }
}

Write-Host ""
Write-Host "Done."
Get-ChildItem $out | Format-Table Name, Length -AutoSize
