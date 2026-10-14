param([string]$GodotExecutable = 'C:\Users\DanielMMF\Desktop\Godot_v4.7.2-stable_win64.exe', [ValidateRange(2,4)][int]$Players = 2, [ValidateRange(0,300)][int]$DelayMs = 0, [ValidateRange(0,150)][int]$JitterMs = 0, [ValidateRange(0,0.3)][double]$Loss = 0, [switch]$Stress)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $env:TEMP ('ashenwild-online-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$port = Get-Random -Minimum 30000 -Maximum 45000
$processes = @()
$roles = @('host', 'client')
if ($Players -ge 3) { $roles += 'client2' }
if ($Players -ge 4) { $roles += 'client3' }
foreach ($role in $roles) {
    $directory = Join-Path $testRoot $role
    New-Item -ItemType Directory -Path $directory | Out-Null
    foreach ($entry in @('scripts', 'scenes', 'assets', 'tests', 'project.godot')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $directory -Recurse
    }
    $configPath = Join-Path $directory 'project.godot'
    $config = [IO.File]::ReadAllText($configPath).Replace('config/name="Ashenwild: Riftbound Survivors"', 'config/name="Ashenwild Online Test ' + $role + ' ' + [Guid]::NewGuid().ToString('N') + '"')
    [IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
    $importOut = Join-Path $directory 'import.out.log'
    $importErr = Join-Path $directory 'import.err.log'
    $import = Start-Process -FilePath $GodotExecutable -ArgumentList @('--headless', '--path', ('"' + $directory + '"'), '--editor', '--quit') -WindowStyle Hidden -RedirectStandardOutput $importOut -RedirectStandardError $importErr -PassThru -Wait
    if ($import.ExitCode -ne 0 -or [IO.File]::ReadAllText($importErr) -match '(SCRIPT ERROR|ERROR:|WARNING:)') {
        Get-Content -LiteralPath $importErr
        throw "Online import failed: $testRoot"
    }
}
try {
    foreach ($role in $roles) {
        $directory = Join-Path $testRoot $role
        $out = Join-Path $directory 'online.out.log'
        $err = Join-Path $directory 'online.err.log'
        $process = Start-Process -FilePath $GodotExecutable -ArgumentList @('--headless', '--max-fps', '60', '--path', ('"' + $directory + '"'), '--script', 'res://tests/online_integration.gd', '--', ('--role=' + $role), ('--port=' + $port), ('--players=' + $Players), ('--delay=' + $DelayMs), ('--jitter=' + $JitterMs), ('--loss=' + $Loss), ('--stress=' + [int]$Stress.IsPresent)) -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
		$null = $process.Handle
        $processes += @{ Process = $process; Out = $out; Err = $err; Role = $role }
    }
    $deadline = [DateTime]::UtcNow.AddSeconds(50)
    while (@($processes | Where-Object { -not $_.Process.HasExited }).Count -gt 0 -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    foreach ($entry in $processes) {
		if ($entry.Process.HasExited) { $entry.Process.WaitForExit(); $entry.Process.Refresh() }
        Get-Content -LiteralPath $entry.Out -Encoding UTF8
        Get-Content -LiteralPath $entry.Err -Encoding UTF8
        if (-not $entry.Process.HasExited -or $entry.Process.ExitCode -ne 0 -or [IO.File]::ReadAllText($entry.Err) -match '(SCRIPT ERROR|ERROR:|WARNING:)' -or [IO.File]::ReadAllText($entry.Out) -notmatch 'PASS ONLINE') {
            throw "Online test failed ($($entry.Role), exited=$($entry.Process.HasExited), code=$($entry.Process.ExitCode)): $testRoot"
        }
    }
} finally {
    foreach ($entry in $processes) {
        if (-not $entry.Process.HasExited) { Stop-Process -Id $entry.Process.Id }
    }
}
Write-Output "$Players isolated saves and logs: $testRoot"
