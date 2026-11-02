class_name CameraRig
extends Camera3D
## La cámara del jugador. Sentado tiene vistas fijas (tus cartas, el rival, los
## costados y la espalda) que se cambian con W/A/S/D, las flechas o dejando el mouse
## en un borde. Entre la silla, la entrada y la barra camina rodeando la mesa.

signal view_changed(view: View)

enum View { HAND, RIVAL, LEFT, RIGHT, BACK }

const STEP_SECONDS := 0.45
const TURN_SECONDS := 0.3
## Grados (mirar arriba/abajo, girar) respecto de CamSeat.
const VIEW_ANGLES := {
	View.HAND: Vector2(-14, 0), View.RIVAL: Vector2(6, 0),
	View.LEFT: Vector2(4, 75), View.RIGHT: Vector2(4, -75), View.BACK: Vector2(2, 180),
}
## Adónde lleva cada dirección desde cada vista.
const NAV := {
	View.HAND: {&"up": View.RIVAL, &"left": View.LEFT, &"right": View.RIGHT, &"down": View.BACK},
	View.RIVAL: {&"down": View.HAND, &"left": View.LEFT, &"right": View.RIGHT},
	View.LEFT: {&"right": View.RIVAL, &"left": View.BACK, &"down": View.HAND},
	View.RIGHT: {&"left": View.RIVAL, &"right": View.BACK, &"down": View.HAND},
	View.BACK: {&"up": View.HAND, &"down": View.HAND, &"left": View.RIGHT, &"right": View.LEFT},
}
## Bordes de la pantalla (fracción) y cuánto hay que quedarse para girar.
const EDGE_TOP := 0.06
const EDGE_BOTTOM := 0.05
const EDGE_SIDE := 0.04
const EDGE_DWELL := 0.35
## Caminos que rodean la mesa en lugar de atravesarla.
const ROUTES := {
	[&"CamBar", &"CamSeat"]: [&"PathSide", &"PathStand"],
	[&"CamSeat", &"CamBar"]: [&"PathStand", &"PathSide"],
	[&"CamSeat", &"CamShop"]: [&"PathStand", &"PathSide", &"PathCounter"],
	[&"CamShop", &"CamSeat"]: [&"PathCounter", &"PathSide", &"PathStand"],
	[&"CamShop", &"CamBar"]: [&"PathCounter", &"PathSide"],
	[&"CamBar", &"CamShop"]: [&"PathSide", &"PathCounter"],
}

var bar: Bar3D
var target_marker: StringName = &""
var view: View = View.HAND
## false en los tests: el mouse no gira la cámara.
var edge_look := true

var _base: Transform3D
var _turn := Vector2.ZERO
var _turn_tween: Tween
var _walk: Tween
var _edge := &""
var _edge_time := 0.0
var _edge_used := false


func setup(p_bar: Bar3D) -> void:
	bar = p_bar
	current = true


func seated() -> bool:
	return target_marker == &"CamSeat" and (_walk == null or not _walk.is_running())


## instant: sin caminar (al arrancar y en los tests).
func go_to(name: StringName, instant := false) -> void:
	if name == target_marker:
		return
	var marker := bar.marker(String(name))
	if marker == null:
		return
	var from := target_marker
	target_marker = name
	# Las vistas son solo en la silla; en otro lugar se mira derecho.
	if name == &"CamSeat":
		set_view(View.HAND, from == &"")
	else:
		if _turn_tween != null:
			_turn_tween.kill()
		if is_inside_tree() and not instant:
			_turn_tween = create_tween()
			_turn_tween.tween_property(self, "_turn", Vector2.ZERO, TURN_SECONDS)
		else:
			_turn = Vector2.ZERO
	if _walk != null:
		_walk.kill()
	if instant or not is_inside_tree() or from == &"":
		_base = marker.global_transform
		_apply()
		return
	var stops: Array[Transform3D] = []
	for stop: StringName in ROUTES.get([from, name], []):
		var m := bar.marker(String(stop))
		if m != null:
			stops.append(m.global_transform)
	stops.append(marker.global_transform)
	_walk = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var prev := _base
	for stop in stops:
		_walk.tween_method(_blend.bind(prev, stop), 0.0, 1.0, STEP_SECONDS)
		prev = stop


func _blend(t: float, from: Transform3D, to: Transform3D) -> void:
	_base = from.interpolate_with(to, t)


func set_view(v: View, instant := false) -> void:
	if v == view and not instant:
		return
	view = v
	var a: Vector2 = VIEW_ANGLES[v]
	var wanted := Vector2(deg_to_rad(a.x), deg_to_rad(a.y))
	if _turn_tween != null:
		_turn_tween.kill()
	if instant or not is_inside_tree():
		_turn = wanted
	else:
		_turn_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_turn_tween.tween_property(self, "_turn", wanted, TURN_SECONDS)
	view_changed.emit(v)


## dir: &"up", &"down", &"left" o &"right".
func navigate(dir: StringName) -> void:
	if not seated():
		return
	var next: Variant = NAV[view].get(dir)
	if next != null:
		set_view(next)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_W, KEY_UP:
			navigate(&"up")
		KEY_S, KEY_DOWN:
			navigate(&"down")
		KEY_A, KEY_LEFT:
			navigate(&"left")
		KEY_D, KEY_RIGHT:
			navigate(&"right")


func _process(delta: float) -> void:
	if edge_look and seated():
		_check_edges(delta)
	_apply()


## Dejar el mouse un rato en un borde gira hacia ese lado; para volver a girar
## hay que salir del borde.
func _check_edges(delta: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var m := vp.get_mouse_position() / size
	var edge := &""
	if m.y < EDGE_TOP:
		edge = &"up"
	elif m.y > 1.0 - EDGE_BOTTOM:
		edge = &"down"
	elif m.x < EDGE_SIDE:
		edge = &"left"
	elif m.x > 1.0 - EDGE_SIDE:
		edge = &"right"
	if edge != _edge:
		_edge = edge
		_edge_time = 0.0
		_edge_used = false
		return
	if edge == &"" or _edge_used:
		return
	_edge_time += delta
	if _edge_time >= EDGE_DWELL:
		_edge_used = true
		navigate(edge)


func _apply() -> void:
	# Girar sobre el eje vertical del mundo y cabecear sobre el propio, para que la
	# cámara nunca se ladee.
	var basis := Basis(Vector3.UP, _turn.y) * _base.basis * Basis(Vector3.RIGHT, _turn.x)
	global_transform = Transform3D(basis, _base.origin)
