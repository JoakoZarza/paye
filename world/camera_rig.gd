class_name CameraRig
extends Camera3D
## La cámara del jugador: va al marcador de cada fase y, sentado, el mouse la gira
## un poco para mirar al rival y la mesa (Plan 7, decisión 1 y Tarea 5).

const MOVE_SECONDS := 0.6
const LOOK_YAW := deg_to_rad(20.0)
const LOOK_PITCH := deg_to_rad(12.0)
const LOOK_SMOOTH := 8.0
const MARKERS := {
	RunController.Phase.MATCH: &"CamSeat", RunController.Phase.BILL_HAND: &"CamSeat",
	RunController.Phase.ONE_MORE: &"CamSeat", RunController.Phase.SHOP: &"CamShop",
}
const DEFAULT_MARKER := &"CamBar"

var bar: Bar3D
var target_marker: StringName = &""
## Sin mouse (tests) la cámara queda derecha.
var mouse_look := true

var _base: Transform3D
var _look := Vector2.ZERO
var _tween: Tween


func setup(p_bar: Bar3D) -> void:
	bar = p_bar
	current = true


static func marker_for(phase: RunController.Phase) -> StringName:
	return MARKERS.get(phase, DEFAULT_MARKER)


## instant: sin animación (al arrancar y en los tests).
func go_to_phase(phase: RunController.Phase, instant := false) -> void:
	var name := marker_for(phase)
	if name == target_marker:
		return
	var marker := bar.marker(String(name))
	if marker == null:
		return
	target_marker = name
	if _tween != null:
		_tween.kill()
	if instant or not is_inside_tree():
		_base = marker.global_transform
		global_transform = _base
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_blend_to.bind(_base, marker.global_transform), 0.0, 1.0, MOVE_SECONDS)


func _blend_to(t: float, from: Transform3D, to: Transform3D) -> void:
	_base = from.interpolate_with(to, t)


func _process(delta: float) -> void:
	var wanted := Vector2.ZERO
	if mouse_look and target_marker == &"CamSeat" and get_viewport() != null:
		var size := get_viewport().get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			var m := (get_viewport().get_mouse_position() / size * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
			wanted = Vector2(-m.x * LOOK_YAW, -m.y * LOOK_PITCH)
	_look = _look.lerp(wanted, clampf(delta * LOOK_SMOOTH, 0.0, 1.0))
	# Girar sobre el eje vertical del mundo y cabecear sobre el propio, para que la
	# cámara nunca se ladee.
	var basis := Basis(Vector3.UP, _look.x) * _base.basis * Basis(Vector3.RIGHT, _look.y)
	global_transform = Transform3D(basis, _base.origin)
