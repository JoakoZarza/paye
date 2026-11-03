class_name TantoDial
extends HBoxContainer
## Contador de tanto como un cuentavueltas: una flechita arriba y otra abajo para la
## decena y para la unidad. Solo deja quedarse en valores que se pueden declarar.

signal declared(value: int)

var value := 0
var _legal: Array[int] = []
var _tens: RichTextLabel
var _units: RichTextLabel


func _init(legal: Array[int], start: int) -> void:
	name = "TantoDial"
	_legal = legal.duplicate()
	_legal.sort()
	value = start if start in _legal else (_legal[0] if not _legal.is_empty() else 0)
	add_theme_constant_override("separation", 6)
	_tens = _column("Tens", 10)
	_units = _column("Units", 1)
	var ok := Button.new()
	ok.name = "Declare"
	ok.text = "Declarar"
	ok.pressed.connect(func() -> void: declared.emit(value))
	add_child(ok)
	RingStyle.shakify(ok)
	_show()


## Sube (dir 1) o baja (dir -1) de a step y se acomoda al valor válido más cercano en
## esa dirección; si no hay, se queda.
func nudge(step: int, dir: int) -> void:
	var wanted := value + step * dir
	var best := value
	for v in _legal:
		if dir > 0 and v > value and (best == value or absi(v - wanted) < absi(best - wanted)):
			best = v
		elif dir < 0 and v < value and (best == value or absi(v - wanted) < absi(best - wanted)):
			best = v
	value = best
	_show()


func _column(prefix: String, step: int) -> RichTextLabel:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)
	col.add_child(_arrow(prefix + "Up", true, nudge.bind(step, 1)))
	var digit := RingStyle.shaky_label("0", 30)
	digit.custom_minimum_size = Vector2(26, 0)
	col.add_child(digit)
	col.add_child(_arrow(prefix + "Down", false, nudge.bind(step, -1)))
	return digit


func _arrow(node_name: String, up: bool, on_press: Callable) -> Button:
	var b := Arrow.new()
	b.name = node_name
	b.up = up
	b.custom_minimum_size = Vector2(26, 16)
	b.pressed.connect(on_press)
	return b


func _show() -> void:
	_tens.text = "[center]" + RingStyle.SHAKE % str(value / 10) + "[/center]"
	_units.text = "[center]" + RingStyle.SHAKE % str(value % 10) + "[/center]"


## Una flechita dibujada, sin depender de que la fuente tenga el símbolo.
class Arrow extends Button:
	var up := true

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var s := size
		var w := minf(s.x, 18.0) * 0.5
		var c := Vector2(s.x * 0.5, s.y * 0.5)
		var h := minf(s.y, 12.0) * 0.5
		var pts := PackedVector2Array([c + Vector2(-w, h), c + Vector2(w, h), c + Vector2(0, -h)]) if up \
			else PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c + Vector2(0, h)])
		var color := RingStyle.HOVER if is_hovered() else RingStyle.COLOR
		draw_colored_polygon(pts, Color.BLACK)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * 0.7)
		draw_colored_polygon(inner, color)
