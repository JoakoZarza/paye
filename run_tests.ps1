# Corre todos los tests de GUT sin pantalla. Requiere la variable de usuario GODOT.
param([string]$Dir = "res://tests")
$godot = [Environment]::GetEnvironmentVariable("GODOT", "User")
if (-not $godot) { $godot = $env:GODOT }
& $godot --headless --path $PSScriptRoot --import | Out-Null
& $godot --headless --path $PSScriptRoot -s addons/gut/gut_cmdln.gd "-gdir=$Dir" -ginclude_subdirs -gexit
exit $LASTEXITCODE
