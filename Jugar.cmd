@echo off
rem Abre Paye. Usa la variable de usuario GODOT o, si falta, la ruta de winget.
set "PAYE_GODOT=%GODOT%"
if not defined GODOT set "PAYE_GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%PAYE_GODOT%" (
  echo No encuentro Godot en: %PAYE_GODOT%
  pause
  exit /b 1
)
rem El punto final evita que la barra de %~dp0 se coma la comilla.
"%PAYE_GODOT%" --path "%~dp0."
if errorlevel 1 pause
