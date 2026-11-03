class_name BaseScreen
extends Control
## Base común de las pantallas.

signal acted

var rc: RunController
## El bar 3D de fondo (null en la vista 2D) y si tiene el filtro PS1.
var world: Bar3D
var ps1 := false
var router: ScreenRouter
## Espacio mínimo entre dos textos escritos en el mundo (píxeles).
const TAG_GAP := 4.0
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
	var l := RingStyle.reading_label(text, size)
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
	var placed: Array[Rect2] = []
	for t in _tags:
		var c: Control = t[0]
		var anchor: Node3D = t[1]
		if not is_instance_valid(c) or not is_instance_valid(anchor):
			continue
		var at: Vector3 = anchor.global_position + (t[2] as Vector3)
		# Detrás de la cámara (o pegado a ella) no se ve.
		c.visible = (cam.global_transform.affine_inverse() * at).z < -0.05
		if not c.visible:
			continue
		var size := c.get_combined_minimum_size()
		c.size = size
		c.position = cam.unproject_position(at) / view * screen - size * 0.5
		# Si pisa a otro texto ya puesto, baja hasta quedar intercalado debajo.
		for k in 6:
			var hit := -1
			for i in placed.size():
				if placed[i].grow(TAG_GAP).intersects(Rect2(c.position, size)):
					hit = i
					break
			if hit < 0:
				break
			c.position.y = placed[hit].end.y + TAG_GAP
		if c.visible:
			placed.append(Rect2(c.position, size))


## Desplazamientos (en el mundo) para poner textos en fila: separados por gap a lo
## ancho y, si dos vecinos son largos, intercalados uno más atrás que el otro (depth).
static func row_spots(texts: Array[String], gap: float, depth: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var back := false
	for i in texts.size():
		var x := (i - (texts.size() - 1) * 0.5) * gap
		if i > 0 and too_close(texts[i - 1], texts[i]):
			back = not back
		else:
			back = false
		out.append(Vector3(x, 0, -depth if back else 0.0))
	return out


## Dos textos vecinos se pisan si uno pasa de 10 caracteres y el otro de 6.
static func too_close(a: String, b: String) -> bool:
	return (a.length() > 10 and b.length() > 6) or (b.length() > 10 and a.length() > 6)


## Vista 3D: los mazos para empezar, uno al lado del otro sobre la mesa, con lo que
## tienen de distinto escrito abajo.
func world_decks(on_pick: Callable) -> void:
	var table := world.slot("table")
	var decks := RunDeck.load_all().values()
	for i in decks.size():
		var deck: RunDeck = decks[i]
		var key := "UI_DECK_" + String(deck.id).to_upper()
		var x := (i - (decks.size() - 1) * 0.5) * 0.36
		world_button(UiText.t(key + "_NAME"), "Deck_" + String(deck.id), on_pick.bind(deck.id), table,
			Vector3(x, 0.82, 0))
		world_label(wrap_text(UiText.t(key + "_DESC"), 22), table, Vector3(x, 0.76, 0.08), 15)


## Corta un texto en renglones de a lo sumo width letras.
static func wrap_text(text: String, width: int) -> String:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" ", false):
		if line != "" and (line + " " + word).length() > width:
			lines.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	if line != "":
		lines.append(line)
	return "\n".join(lines)


## Donde se escribe lo que hay que saber: la pizarra del bar.
func board() -> Node3D:
	return world.slot("scoreboard")
