class_name BaseScreen
extends Control
## Base común de las pantallas.

signal acted

var rc: RunController


func setup(p_rc: RunController) -> void:
	rc = p_rc
	refresh()


func refresh() -> void:
	pass
