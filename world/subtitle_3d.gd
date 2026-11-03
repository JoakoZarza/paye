class_name Subtitle3D
extends Node3D
## Lo que dice el rival, escrito en el aire al lado suyo. Cada letra es su propio
## Label3D y tiembla a saltitos: casi no se nota, pero si lo mirás inquieta.

const FONT_SIZE := 44
const PIXEL := 0.0016
const MAX_WIDTH := 0.62
const LINE_GAP := 1.15
## Letras por segundo al escribirse y cuánto queda antes de apagarse.
const TYPE_RATE := 40.0
const HOLD_SECONDS := 3.5
const FADE_SECONDS := 0.6
## Temblor: cada cuánto salta, cuánto (fracción de la altura de letra) y la chance de
## un tirón más grande.
const JITTER_STEP := 0.07
const JITTER := 0.045
const TWITCH_CHANCE := 0.02
const TWITCH := 3.0
const COLOR := Color("#D8C9A3")

## Cada letra que aparece, para el balbuceo.
signal letter_typed(ch: String)

var text := ""
## Un canto que espera tu respuesta no se apaga solo.
var persistent := false
## false: queda fijo como lo dejó su padre (los diálogos del rival, en perspectiva).
var face_camera := true
var _glyphs: Array[Label3D] = []
var _homes: Array[Vector3] = []
var _age := 0.0
var _jitter_time := 0.0
var _rng := RandomNumberGenerator.new()
var _typed := 0


func say(p_text: String, p_persistent := false) -> void:
	text = p_text
	persistent = p_persistent
	_age = 0.0
	_typed = 0
	for g in _glyphs:
		g.queue_free()
	_glyphs.clear()
	_homes.clear()
	if text == "":
		return
	var font := ThemeDB.fallback_font
	var height := font.get_height(FONT_SIZE) * PIXEL
	var lines := _wrap(font, text)
	for row in lines.size():
		var line: String = lines[row]
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * PIXEL
		var x := -width * 0.5
		var y := -row * height * LINE_GAP
		for ch in line:
			var advance := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * PIXEL
			if ch != " ":
				var g := Label3D.new()
				g.text = ch
				g.font_size = FONT_SIZE
				g.pixel_size = PIXEL
				g.outline_size = 10
				g.modulate = COLOR
				g.outline_modulate = Color(0, 0, 0, 0.9)
				g.no_depth_test = true
				g.shaded = false
				g.visible = false
				var home := Vector3(x + advance * 0.5, y, 0)
				g.position = home
				add_child(g)
				_glyphs.append(g)
				_homes.append(home)
			x += advance


## Empieza a apagarse ya (respondiste el canto).
func dismiss() -> void:
	persistent = false
	_age = maxf(_age, HOLD_SECONDS)


func glyph_count() -> int:
	return _glyphs.size()


func visible_glyphs() -> int:
	var n := 0
	for g in _glyphs:
		if g.visible:
			n += 1
	return n


func _wrap(font: Font, s: String) -> Array[String]:
	var out: Array[String] = []
	for paragraph in s.split("\n"):
		var line := ""
		for word in paragraph.split(" ", false):
			var tried := word if line == "" else line + " " + word
			if line != "" and font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * PIXEL > MAX_WIDTH:
				out.append(line)
				line = word
			else:
				line = tried
		out.append(line)
	return out


func _process(delta: float) -> void:
	step(delta)
	if face_camera:
		_face_camera()


## Avanza la escritura, el temblor y el apagado (separado para los tests).
func step(delta: float) -> void:
	if _glyphs.is_empty():
		return
	_age += delta
	if persistent:
		_age = minf(_age, HOLD_SECONDS)
	var shown := mini(int(_age * TYPE_RATE), _glyphs.size())
	while _typed < shown:
		letter_typed.emit(_glyphs[_typed].text)
		_typed += 1
	var fade := clampf((HOLD_SECONDS + FADE_SECONDS - _age) / FADE_SECONDS, 0.0, 1.0)
	_jitter_time += delta
	var jump := _jitter_time >= JITTER_STEP
	if jump:
		_jitter_time = 0.0
	var size := ThemeDB.fallback_font.get_height(FONT_SIZE) * PIXEL
	for i in _glyphs.size():
		var g := _glyphs[i]
		g.visible = i < shown and fade > 0.0
		g.modulate.a = fade
		g.outline_modulate.a = 0.9 * fade
		if jump:
			var amount := JITTER * size * (TWITCH if _rng.randf() < TWITCH_CHANCE else 1.0)
			g.position = _homes[i] + Vector3(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount), 0)


## Gira sobre el eje vertical para quedar de frente a la cámara.
func _face_camera() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var to := cam.global_position - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return
	global_basis = Basis(Vector3.UP, atan2(to.x, to.z))
