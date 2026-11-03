class_name RingStyle
extends RefCounted
## Botones de la mesa 3D: sin caja, solo el texto con borde negro que tiembla apenas,
## como los subtítulos del rival pero más tranquilo. Al pasar el mouse se dora.

const COLOR := Color("#D8C9A3")
const HOVER := Color("#D9A54A")
const DISABLED := Color(0.55, 0.52, 0.46, 0.6)
const FONT_SIZE := 24
## Movimiento de RichTextLabel: un vaivén lento (wave) y encima el temblor (shake).
const SHAKE := "[wave amp=30.0 freq=1.2 connected=1][shake rate=6.0 level=4 connected=1]%s[/shake][/wave]"


## Convierte un botón normal: el texto pasa a una etiqueta temblorosa encima.
static func shakify(b: Button) -> void:
	if b.get_node_or_null("Shaky") != null:
		return
	var text := b.text
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, empty)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.TRANSPARENT)
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	var label := shaky_label(text)
	label.name = "Shaky"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(label)
	_paint(b, label, false)
	b.mouse_entered.connect(func() -> void: _paint(b, label, true))
	b.mouse_exited.connect(func() -> void: _paint(b, label, false))


static func shaky_label(text: String, size := FONT_SIZE) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_color_override("default_color", COLOR)
	label.text = "[center]" + SHAKE % text + "[/center]"
	return label


static func _paint(b: Button, label: RichTextLabel, hover: bool) -> void:
	var color := DISABLED if b.disabled else (HOVER if hover else COLOR)
	label.add_theme_color_override("default_color", color)
