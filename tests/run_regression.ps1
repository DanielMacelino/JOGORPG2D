param([string]$GodotExecutable = 'C:\Users\DanielMMF\Desktop\Godot_v4.7.2-stable_win64.exe', [switch]$Combat, [switch]$CombatOnly, [string]$CombatClasses = '')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $GodotExecutable)) {
    throw 'Informe o executável do Godot usando -GodotExecutable.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $env:TEMP ('ashenwild-regression-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
foreach ($entry in @('scripts', 'scenes', 'assets', 'tests', 'project.godot')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $testRoot -Recurse
}
$configPath = Join-Path $testRoot 'project.godot'
$config = [IO.File]::ReadAllText($configPath)
$testName = 'Ashenwild Regression ' + [Guid]::NewGuid().ToString('N')
$config = $config.Replace('config/name="Ashenwild: Riftbound Survivors"', 'config/name="' + $testName + '"')
[IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
$phases = @('import', 'regression')
if ($CombatOnly) { $phases = @('import', 'combat') }
elseif ($Combat) { $phases += 'combat' }
foreach ($phase in $phases) {
    $outLog = Join-Path $testRoot ($phase + '.out.log')
    $errLog = Join-Path $testRoot ($phase + '.err.log')
    $arguments = @('--headless', '--path', ('"' + $testRoot + '"'))
    if ($phase -eq 'import') {
        $arguments += @('--editor', '--quit')
    } elseif ($phase -eq 'regression') {
        $arguments += @('--script', 'res://tests/progression_regression.gd', '--quit-after', '5000')
    } else {
        $arguments += @('--script', 'res://tests/combat_balance.gd', '--fixed-fps', '60', '--quit-after', '350000')
        if ($CombatClasses) { $arguments += @('--', ('--classes=' + $CombatClasses)) }
    }
    $testProcess = Start-Process -FilePath $GodotExecutable -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru -Wait
    $errors = [IO.File]::ReadAllText($errLog)
    $output = [IO.File]::ReadAllText($outLog)
    if ($testProcess.ExitCode -ne 0 -or $errors -match '(SCRIPT ERROR|ERROR:|WARNING:)') {
        Get-Content -LiteralPath $outLog | Select-Object -Last 20
        Get-Content -LiteralPath $errLog
        throw "Falha na fase $phase. Logs em $testRoot"
    }
    if ($phase -eq 'regression' -and $output -notmatch 'PASS: circular class trees') { throw "Regressão incompleta. Logs em $testRoot" }
    if ($phase -eq 'combat' -and $output -notmatch 'BALANCE COMPLETE') { throw "Amostra de combate incompleta. Logs em $testRoot" }
    if ($phase -ne 'import') { Get-Content -LiteralPath $outLog -Encoding UTF8 }
}
Write-Output "Logs e projeto isolado: $testRoot"
