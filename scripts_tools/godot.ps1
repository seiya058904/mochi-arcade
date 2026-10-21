param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GodotArgs)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = $env:MOCHI_GODOT
if (-not $engine) { $engine = Join-Path $projectRoot '.local\toolchain\godot-4.7.2\Godot_v4.7.2-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $engine)) { throw 'Set MOCHI_GODOT to the Godot 4.7.2 executable.' }
# Calling the GUI binary through a pipeline waits and retains stdout/stderr.
& $engine --path $projectRoot @GodotArgs | Out-Host
exit $LASTEXITCODE
