class_name BaseScreen
extends Control
## Base común de las pantallas.

signal acted

var rc: RunController
## El bar 3D de fondo (null en la vista 2D) y si tiene el filtro PS1.
var world: Bar3D
var ps1 := false
var router: ScreenRouter
## Vista 3D: textos y botones escritos sobre los objetos del bar ([control, nodo, desplazamiento]).
var _tags: Array = []


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


## Un botón tembloroso escrito encima de un objeto del bar (la silla, la barra...).
func world_button(text: String, node_name: String, callback: Callable, anchor: Node3D,
		offset := Vector3.ZERO, enabled := true) -> Button:
	var b := ScreenTools.button(self, text, node_name, callback, enabled)
	RingStyle.shakify(b)
	_tag(b, anchor, offset)
	return b


## Un texto tembloroso escrito encima de un objeto del bar.
func world_label(text: String, anchor: Node3D, offset := Vector3.ZERO, size := 22) -> RichTextLabel:
	var l := RingStyle.shaky_label(text, size)
	var font := ThemeDB.fallback_font
	l.custom_minimum_size = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size) + Vector2(24, 12)
	add_child(l)
	_tag(l, anchor, offset)
	return l


func _tag(c: Control, anchor: Node3D, offset: Vector3) -> void:
	_tags.append([c, anchor, offset])
	place_tags()


func _clear_tags() -> void:
	_tags.clear()


func _process(_delta: float) -> void:
	place_tags()


## Pone cada texto donde se ve su objeto; si queda detrás de la cámara no se ve.
func place_tags() -> void:
	if _tags.is_empty() or world == null or world.camera == null or not world.camera.is_inside_tree():
		return
	var cam := world.camera
	var view := cam.get_viewport().get_visible_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var screen := get_viewport_rect().size
	for t in _tags:
		var c: Control = t[0]
		var anchor: Node3D = t[1]
		if not is_instance_valid(c) or not is_instance_valid(anchor):
			continue
		var at: Vector3 = anchor.global_position + (t[2] as Vector3)
		c.visible = not cam.is_position_behind(at)
		var size := c.get_combined_minimum_size()
		c.size = size
		c.position = cam.unproject_position(at) / view * screen - size * 0.5
