class_name BaseScreen
extends Control
## Base común de las pantallas.

signal acted

var rc: RunController
## El bar 3D de fondo (null en la vista 2D) y si tiene el filtro PS1.
var world: Bar3D
var ps1 := false
var router: ScreenRouter


## Dónde está la cámara en el bar 3D mientras se ve esta pantalla.
func camera_marker() -> StringName:
	return &"CamBar"


## Fondo oscuro encima del bar 3D para leer la pantalla.
func wants_backdrop() -> bool:
	return true


func setup(p_rc: RunController) -> void:
	rc = p_rc
	refresh()


func refresh() -> void:
	pass
