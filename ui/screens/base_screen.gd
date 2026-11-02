class_name BaseScreen
extends Control
## Base común de las pantallas.

signal acted

var rc: RunController
## El bar 3D de fondo (null en la vista 2D) y si tiene el filtro PS1.
var world: Bar3D
var ps1 := false


func setup(p_rc: RunController) -> void:
	rc = p_rc
	refresh()


func refresh() -> void:
	pass
