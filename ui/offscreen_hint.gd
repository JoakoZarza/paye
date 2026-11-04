class_name OffscreenHint
extends Control
## Indicador al borde de la pantalla: "por acá hay algo que te interesa". Apunta hacia
## target mientras no se ve; cuando girás la cámara y aparece en pantalla, se apaga.

const SIZE := Vector2(26, 44)
const MARGIN := 18.0
const COLOR := Color("#D8C9A3")
const ALPHA := 0.7
## Va y viene hacia el borde, despacio, para que se note sin molestar.
const NUDGE := 6.0
const NUDGE_SPEED := 3.0
const FADE_SPEED := 6.0
## Cuánto margen de pantalla cuenta como "ya lo ves" (fracción).
const SEEN_INSET := 0.06

var target: Node3D
## Punto a señalar respecto del objeto (por ejemplo, arriba de la barra).
var offset := Vector3.ZERO
var camera: Camera3D
## -1 izquierda, 1 derecha (hacia dónde apunta ahora).
var side := -1
var _time := 0.0
var _shown := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	var want := 1.0 if wanted() else 0.0
	_shown = move_toward(_shown, want, delta * FADE_SPEED)
	queue_redraw()


## true si el objeto no está en pantalla (y hay que señalarlo).
func wanted() -> bool:
	if target == null or camera == null or not is_instance_valid(target) or not camera.is_inside_tree():
		return false
	var at := target.global_position + offset
	var local := camera.global_transform.affine_inverse() * at
	side = -1 if local.x < 0.0 else 1
	if camera.is_position_behind(at):
		return true
	var view := camera.get_viewport().get_visible_rect().size
	var p := camera.unproject_position(at) / view
	var inset := SEEN_INSET
	return p.x < inset or p.x > 1.0 - inset or p.y < inset or p.y > 1.0 - inset


func shown() -> bool:
	return _shown > 0.01


func _draw() -> void:
	if _shown <= 0.01:
		return
	var view := get_viewport_rect().size
	var nudge := (sin(_time * NUDGE_SPEED) * 0.5 + 0.5) * NUDGE
	var x := MARGIN + nudge if side < 0 else view.x - MARGIN - nudge
	var tip := Vector2(x, view.y * 0.5)
	var back := Vector2(SIZE.x * -side, 0)
	var half := Vector2(0, SIZE.y * 0.5)
	var color := Color(COLOR, ALPHA * _shown)
	var shadow := Color(0, 0, 0, 0.5 * _shown)
	# Un chevron grueso: dos trazos que se juntan en la punta.
	var points := PackedVector2Array([tip + back - half, tip, tip + back + half])
	var dropped := PackedVector2Array()
	for q in points:
		dropped.append(q + Vector2(2, 2))
	draw_polyline(dropped, shadow, 6.0, true)
	draw_polyline(points, color, 6.0, true)
