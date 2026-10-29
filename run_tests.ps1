# Corre todos los tests de GUT sin pantalla. Requiere la variable de usuario GODOT.
# Sale con código distinto de 0 si falla un test, si hay errores de script o si no corrió nada.
param([string]$Dir = "res://tests")
$godot = [Environment]::GetEnvironmentVariable("GODOT", "User")
if (-not $godot) { $godot = $env:GODOT }
& $godot --headless --path $PSScriptRoot --import 2>&1 | Out-Null
$out = & $godot --headless --path $PSScriptRoot -s addons/gut/gut_cmdln.gd "-gdir=$Dir" -ginclude_subdirs -gexit 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$out
if ($out -match "SCRIPT ERROR|Parse Error|Nothing was run") {
	Write-Output "run_tests: FALLO (errores de script o nada corrió)"
	exit 1
}
exit $code
