extends BaseScreen
## La mesa 2D: dibuja lo que dice el TablePresenter y le pasa los clics. No
## decide nada (Plan 6, Tarea 3; Plan 7, Tarea 1).

const T := TrucoAction.Type
const PLAYER := TablePresenter.PLAYER
const DEALER := TablePresenter.DEALER
const HIDDEN_CARD := "[ ? ]"
## Vista 3D: los cantos van en un arco alrededor de tu mano (centro y radios en
## fracción de pantalla; ángulos en grados, 270 = abajo).
const RING_CENTER := Vector2(0.5, 0.68)
const RING_RADII := Vector2(0.135, 0.165)
const RING_FROM := 160.0
const RING_TO := 380.0
## Espacio mínimo entre dos cantos (píxeles) y hasta cuánto se puede abrir el arco.
const RING_GAP := 6.0
const RING_MAX_GROW := 1.8
## Margen alrededor de un botón dentro del cual la cabeza se queda quieta.
const HOLD_MARGIN := 14.0
## La flor de acusar: radio (píxeles), cuánto tarda en abrirse cada pétalo y el desfase entre ellos.
const PETAL_RADIUS := 190.0
const PETAL_SECONDS := 0.25
const PETAL_STAGGER := 0.04
## Si tu mano queda más abajo que esto (fracción de pantalla), los cantos no se ven.
const HIDE_BELOW := 0.95

var presenter: TablePresenter

var _timer: Timer
var _title: Label
var _score: Label
var _phase_label: Label
var _tell_label: Label
var _known_label: Label
var _evidence_label: Label
var _dealer_row: HBoxContainer
var _table_row: HBoxContainer
var _player_row: HBoxContainer
var _actions: HFlowContainer
var _amulets: HFlowContainer
var _popup_box: VBoxContainer
var _log: Label
var _main: VBoxContainer
var _dealer_title: Label
var _table_title: Label
var _player_title: Label
var _built := false
var _ring: Control
## Vista 3D: las opciones de acusar abiertas como una flor alrededor de tus cartas.
var _flower: Control
var _flower_hand: TrucoHand
## Cuánto se abrió el arco para que no se pisen los cantos (1 = nada).
var ring_grow := 1.0
var _table3d: Table3D
var _log_title: Label
var _amulets_title: Label


func _ready() -> void:
	_build()


func setup(p_rc: RunController) -> void:
	_build()
	presenter = TablePresenter.new(p_rc)
	presenter.changed.connect(_after_action)
	presenter.left_table.connect(func() -> void: acted.emit())
	_timer.wait_time = presenter.dealer_seconds()
	if world != null:
		_use_world()
	super.setup(p_rc)


## Vista 3D: las cartas las pone el bar; acá quedan los botones abajo, sin tapar
## los clics sobre las cartas.
func _use_world() -> void:
	# En 3D lo que pasó se ve en la mesa y los amuletos están apoyados en ella.
	# La ronda son las fichas, el puntaje la planilla y la fase se ve en las manos; las
	# cartas de más del rival se cuentan mirando su abanico.
	for n in [_dealer_row, _table_row, _player_row, _dealer_title, _table_title, _player_title,
			_log_title, _log, _amulets_title, _amulets, _title, _score, _phase_label, _evidence_label]:
		n.visible = false
	# Título y puntaje arriba, botones abajo, el medio libre para ver la mesa.
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main.add_child(gap)
	_main.move_child(gap, _phase_label.get_index() + 1)
	# Botones a la izquierda y registro a la derecha; el centro, libre para el rival y tu mano.
	_main.size_flags_stretch_ratio = 0.9
	var middle := Control.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_stretch_ratio = 1.1
	var split := _main.get_parent()
	split.add_child(middle)
	split.move_child(middle, _main.get_index() + 1)
	(split.get_child(split.get_child_count() - 1) as Control).size_flags_stretch_ratio = 0.7
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring = Control.new()
	_ring.name = "Ring"
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring)
	_table3d = Table3D.new(world, presenter, ps1)
	_table3d.amulet_pressed.connect(_on_amulet)
	add_child(_table3d)


## Con el mouse sobre un botón la cabeza no se mueve, así se puede apretar.
func _process(delta: float) -> void:
	if world == null or world.camera == null:
		return
	world.camera.ui_hold = _mouse_on_button()
	follow_hand()
	# Sin mirar tus cartas los cantos se apagan un poco, pero se pueden apretar igual.
	var wanted := 1.0 if _table3d.hand_raised() or world.camera.ui_hold else 0.4
	_ring.modulate.a = move_toward(_ring.modulate.a, wanted, delta * 4.0)


## Al irse la mesa la cabeza queda libre (si no, ganar con el mouse sobre un botón
## dejaba la cámara trabada).
func _exit_tree() -> void:
	if world != null and world.camera != null:
		world.camera.ui_hold = false
	# Si te vas con una carta al frente, el bar no queda a oscuras.
	if world != null and _table3d != null and _table3d.focused_card() != null:
		world.dim(false)


## Los cantos están pegados a tu mano en el mundo: si subís la mirada se van con ella
## hacia abajo y salen de la pantalla.
func follow_hand() -> void:
	var cam := world.camera
	var anchor := world.marker("PlayerHand")
	if cam == null or anchor == null or not cam.is_inside_tree():
		return
	var spot := anchor.global_position
	if cam.is_position_behind(spot):
		_ring.visible = false
		return
	_ring.visible = not _table3d.dealing()
	var view := cam.get_viewport().get_visible_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var frac := cam.unproject_position(spot) / view
	# Con la mano fuera de cuadro no asoma ni el borde de un canto.
	_ring.visible = frac.y < HIDE_BELOW
	_ring.position = (frac - RING_CENTER) * get_viewport_rect().size


func _mouse_on_button() -> bool:
	var mouse := get_global_mouse_position()
	for b in find_children("*", "BaseButton", true, false):
		var c := b as Control
		if c.is_visible_in_tree() and c.get_global_rect().grow(HOLD_MARGIN).has_point(mouse):
			return true
	return false


## Pasa los cantos de la fila al arco alrededor de tus cartas: repartidos a distancias
## iguales sobre el arco, y cada uno pegado por su lado de adentro, así todos quedan a la
## misma distancia de las cartas sin importar lo largo del texto.
func _arrange_ring() -> void:
	var items: Array[Control] = []
	for c in _actions.get_children():
		_actions.remove_child(c)
		_ring.add_child(c)
		if c is Button:
			RingStyle.shakify(c as Button)
		items.append(c as Control)
	# Si se pisan, se abre el arco de a poco hasta que entren todos.
	var screen := get_viewport_rect().size
	var grow := 1.0
	while true:
		var rects := _ring_rects(items, grow, screen)
		if not _any_overlap(rects) or grow >= RING_MAX_GROW:
			break
		grow += 0.06
	ring_grow = grow
	var spots := ring_spots(items.size(), grow)
	for i in items.size():
		var c := items[i]
		var r := _ring_rect(c, spots[i], grow, Vector2.ONE)
		c.anchor_left = spots[i].x
		c.anchor_right = spots[i].x
		c.anchor_top = spots[i].y
		c.anchor_bottom = spots[i].y
		c.offset_left = r.position.x
		c.offset_right = r.end.x
		c.offset_top = r.position.y
		c.offset_bottom = r.end.y


## Rectángulo del canto respecto de su punto (en píxeles), pegado por su lado de
## adentro: los de la izquierda terminan en el punto, los de la derecha empiezan ahí.
func _ring_rect(c: Control, spot: Vector2, grow: float, _screen: Vector2) -> Rect2:
	var size := c.get_combined_minimum_size()
	var side := clampf((spot.x - RING_CENTER.x) / (RING_RADII.x * grow), -1.0, 1.0)
	var left := -size.x * (0.5 - 0.5 * side)
	return Rect2(Vector2(left, -size.y * 0.5), size)


func _ring_rects(items: Array[Control], grow: float, screen: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var spots := ring_spots(items.size(), grow)
	for i in items.size():
		var r := _ring_rect(items[i], spots[i], grow, screen)
		out.append(Rect2(spots[i] * screen + r.position, r.size))
	return out


static func _any_overlap(rects: Array[Rect2]) -> bool:
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].grow(RING_GAP).intersects(rects[j]):
				return true
	return false


## n puntos (fracción de pantalla) a la misma distancia uno de otro sobre el arco.
static func ring_spots(n: int, grow := 1.0) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 0:
		return out
	var samples: Array[Vector2] = []
	var lengths: Array[float] = [0.0]
	for k in 121:
		var a := deg_to_rad(lerpf(RING_FROM, RING_TO, k / 120.0))
		samples.append(RING_CENTER + Vector2(cos(a) * RING_RADII.x, -sin(a) * RING_RADII.y) * grow)
		if k > 0:
			# En píxeles de 16:9, para que la distancia sea la que se ve.
			lengths.append(lengths[k - 1] + ((samples[k] - samples[k - 1]) * Vector2(16, 9)).length())
	var total: float = lengths[120]
	for i in n:
		var want := total * (0.5 if n == 1 else float(i) / (n - 1))
		var k := 1
		while k < 120 and lengths[k] < want:
			k += 1
		var t := 0.0 if lengths[k] == lengths[k - 1] else (want - lengths[k - 1]) / (lengths[k] - lengths[k - 1])
		out.append(samples[k - 1].lerp(samples[k], clampf(t, 0.0, 1.0)))
	return out


func refresh() -> void:
	if rc == null or rc.table() == null:
		return
	presenter.start()


# --- Construcción ---

func _build() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 16)
	margin.add_child(split)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_stretch_ratio = 2.0
	split.add_child(main)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(side)

	_main = main
	_title = _label(main, 26)
	_score = _label(main)
	_phase_label = _label(main)
	_dealer_title = _label(main)
	_dealer_title.text = "Cartas del rival"
	_dealer_row = _row(main)
	_table_title = _label(main)
	_table_title.text = "En la mesa (rival arriba, vos abajo)"
	_table_row = _row(main)
	_player_title = _label(main)
	_player_title.text = "Tus cartas"
	_player_row = _row(main)
	_actions = HFlowContainer.new()
	main.add_child(_actions)
	_amulets_title = _label(main)
	_amulets_title.text = "Amuletos"
	_amulets = HFlowContainer.new()
	main.add_child(_amulets)
	_popup_box = VBoxContainer.new()
	main.add_child(_popup_box)

	_tell_label = _label(side)
	_known_label = _label(side)
	_evidence_label = _label(side)
	_log_title = _label(side, 18)
	_log_title.text = "Lo que pasó"
	_log = _label(side, 16)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_dealer_timer)
	add_child(_timer)


func _label(parent: Control, size := 20) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func _row(parent: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	r.custom_minimum_size = Vector2(0, 56)
	parent.add_child(r)
	return r


func _button(parent: Control, text: String, on_press: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


# --- Dibujo ---

func _after_action() -> void:
	# La flor de un amuleto sigue abierta aunque el rival juegue, si es la misma mano.
	if not is_instance_valid(_flower) or presenter.hand() != _flower_hand:
		_popup_close()
	_redraw()
	if world != null:
		_let_clicks_through(self)
	_schedule_dealer()


func _redraw() -> void:
	var p := presenter
	_title.text = p.title()
	_score.text = p.score_text()
	_phase_label.text = p.phase_text()
	# En 3D la pista la dice el rival en el aire.
	_tell_label.text = "" if world != null else p.tell_text()
	_known_label.text = p.known_text()
	_evidence_label.text = p.evidence_text()
	_log.text = "\n".join(p.log_lines)

	_clear(_dealer_row)
	_clear(_table_row)
	_clear(_player_row)
	_clear(_actions)
	_clear(_amulets)
	# Una flor abierta sobrevive a que el rival hable o cante, mientras siga la misma mano.
	var keep: Control = _flower if is_instance_valid(_flower) else null
	if keep != null:
		_ring.remove_child(keep)
	if _ring != null:
		_clear(_ring)
	var hand := p.hand()
	if keep != null and hand != _flower_hand:
		keep.queue_free()
		keep = null
		_flower = null
		if _table3d != null:
			_table3d.card_pick = Callable()
			_table3d.unfocus()
	if hand == null:
		return
	if world == null:
		_draw_cards(hand)
	_draw_actions(hand)
	if _ring != null:
		_arrange_ring()
		if keep != null:
			for c in _ring.get_children():
				(c as Control).visible = false
			_ring.add_child(keep)


func _draw_actions(_hand: TrucoHand) -> void:
	var p := presenter
	if p.hand_finished():
		_button(_actions, "Seguir", _on_continue).name = "Continue"
		return
	if p.in_show_decision():
		_button(_actions, p.demand_text(), p.demand_show).name = "Act_DEMAND_SHOW"
		_button(_actions, "Seguir", p.accept_and_continue).name = "Continue"
	else:
		for call in p.call_buttons():
			_button(_actions, call["text"], p.act.bind(call["action"])).name = call["name"]
		_draw_tanto_picker()
	if p.can_accuse():
		_button(_actions, "Acusar…", _show_accuse).name = "Accuse"
	_draw_amulets()


func _draw_cards(hand: TrucoHand) -> void:
	for c in hand.cards[DEALER]:
		var l := Label.new()
		l.text = HIDDEN_CARD
		_dealer_row.add_child(l)
	for who in [DEALER, PLAYER]:
		var played: Array = hand.played[who]
		for c: Card in played:
			var l := Label.new()
			l.text = ("%s: " % ("Rival" if who == DEALER else "Vos")) + card_text(c)
			_table_row.add_child(l)

	for i in hand.cards[PLAYER].size():
		var play := presenter.card_action(i)
		var b := _button(_player_row, card_text(hand.cards[PLAYER][i]), presenter.act.bind(play), play != null)
		b.name = "Card%d" % i


## Solo los botones y selectores atajan el mouse; el resto deja pasar el clic al
## 3D. Los textos llevan borde para leerse sobre la escena.
func _let_clicks_through(node: Node) -> void:
	for c in node.get_children():
		if c is Control and not (c is BaseButton):
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if c is Label:
			(c as Label).add_theme_constant_override("outline_size", 6)
			(c as Label).add_theme_color_override("font_outline_color", Color.BLACK)
		_let_clicks_through(c)


func _draw_tanto_picker() -> void:
	var values := presenter.tanto_values()
	if values.is_empty():
		return
	var real := presenter.own_tanto()
	if world != null:
		var legal: Array[int] = []
		legal.assign(values)
		var dial := TantoDial.new(legal, real)
		dial.declared.connect(presenter.declare)
		_actions.add_child(dial)
		return
	var picker := OptionButton.new()
	picker.name = "TantoPicker"
	for v in values:
		picker.add_item(("%d (el tuyo)" % v) if v == real else str(v), v)
		if v == real:
			picker.select(picker.item_count - 1)
	_actions.add_child(picker)
	_button(_actions, "Declarar", func() -> void: presenter.declare(picker.get_selected_id())).name = "Declare"


func _draw_amulets() -> void:
	for a in presenter.amulet_buttons():
		if a["passive"]:
			var l := Label.new()
			l.text = a["text"]
			_amulets.add_child(l)
			continue
		var b := _button(_amulets, a["text"], _on_amulet.bind(a["id"], a["needs"]), a["enabled"])
		b.name = "Amulet_%s" % a["id"]


static func card_text(c: Card) -> String:
	return TablePresenter.card_text(c)


# --- Turnos ---

## También la usan los tests.
func _hand_finished() -> bool:
	return presenter.hand_finished()


func _schedule_dealer() -> void:
	if presenter.dealer_should_play() and _timer.is_stopped() and is_inside_tree():
		_timer.start()


## También la llaman los tests para no esperar el temporizador.
func _on_dealer_timer() -> void:
	# Mientras se reparte el rival espera a tener sus cartas.
	if _table3d != null and _table3d.dealing() and is_inside_tree():
		_timer.start()
		return
	presenter.dealer_step()


func _on_continue() -> void:
	_popup_close()
	presenter.continue_hand()


# --- Acusar ---

func _show_accuse() -> void:
	_popup_close()
	if _ring != null:
		bloom(presenter.accuse_options())
		return
	_label(_popup_box).text = "¿De qué lo acusás?"
	var row := HFlowContainer.new()
	_popup_box.add_child(row)
	for o in presenter.accuse_options():
		_button(row, o["text"], _accuse.bind(o["accusation"])).name = o["name"]
	_button(row, "Cancelar", _popup_close)
	_popup_built()


func _accuse(acc: Accusation) -> void:
	_popup_close()
	presenter.accuse(acc)


# --- Amuletos ---

func _on_amulet(id: StringName, needs: StringName) -> void:
	match needs:
		&"marker":
			_show_marker()
		&"spare_deck":
			_show_spare()
		_:
			_use_amulet(id, {})


func _use_amulet(id: StringName, args: Dictionary) -> void:
	_popup_close()
	presenter.use_amulet(id, args)


func _card_picker() -> OptionButton:
	var pick := OptionButton.new()
	var hand := presenter.hand()
	for i in hand.cards[PLAYER].size():
		pick.add_item(card_text(hand.cards[PLAYER][i]), i)
	_popup_box.add_child(pick)
	return pick


func _show_marker() -> void:
	_popup_close()
	if _ring != null:
		_await_card("Marcador: tocá la carta", _marker_number)
		return
	_label(_popup_box).text = "Marcador: ¿qué carta y qué número?"
	var card := _card_picker()
	var number := OptionButton.new()
	for n in Card.VALID_NUMBERS:
		number.add_item(str(n), n)
	_popup_box.add_child(number)
	var suit := OptionButton.new()
	suit.add_item("mismo palo", -1)
	if presenter.marker_can_change_suit():
		for s in Card.Suit.size():
			suit.add_item(UiText.t("UI_SUIT_" + Card.Suit.keys()[s]), s)
	_popup_box.add_child(suit)
	var row := HBoxContainer.new()
	_popup_box.add_child(row)
	_button(row, "Marcar", func() -> void:
		_use_amulet(&"marker", {"card_index": card.get_selected_id(), "number": number.get_selected_id(),
			"suit": suit.get_selected_id()}))
	_button(row, "Cancelar", _popup_close)
	_popup_built()


func _show_spare() -> void:
	_popup_close()
	if _ring != null:
		_await_card("Mazo aparte: tocá la carta que cambiás", _spare_choice)
		return
	_label(_popup_box).text = "Mazo aparte: ¿qué carta cambiás?"
	var card := _card_picker()
	var options := presenter.spare_options()
	var choice := OptionButton.new()
	for i in options.size():
		choice.add_item("por el " + card_text(options[i]), i)
	if not options.is_empty():
		_popup_box.add_child(choice)
	var row := HBoxContainer.new()
	_popup_box.add_child(row)
	_button(row, "Cambiar", func() -> void:
		var args := {"card_index": card.get_selected_id()}
		if not options.is_empty():
			args["choice"] = choice.get_selected_id()
		_use_amulet(&"spare_deck", args))
	_button(row, "Cancelar", _popup_close)
	_popup_built()


## Vista 3D: la carta se elige tocándola en la mano (no se juega). Arriba queda qué se
## está eligiendo y "Cancelar".
func _await_card(title: String, next: Callable) -> void:
	# "Cancelar" al costado, no encima: las cartas tienen que poder tocarse.
	bloom([], title, Vector2(PETAL_RADIUS + 130, 0))
	_table3d.card_pick = func(i: int) -> void:
		_table3d.focus_card(i)
		next.call(i)


## Un pétalo por carta tuya; al elegir una sigue next(card_index).
func _card_petals(next: Callable) -> Array:
	var out := []
	var hand := presenter.hand()
	for i in hand.cards[PLAYER].size():
		out.append({"text": card_text(hand.cards[PLAYER][i]), "name": "PickCard%d" % i, "callback": next.bind(i)})
	return out


func _marker_number(card_index: int) -> void:
	var out := []
	for n in Card.VALID_NUMBERS:
		out.append({"text": str(n), "name": "PickNumber%d" % n, "callback": _marker_suit.bind(card_index, n)})
	bloom(out, "Marcador: ¿qué número?")


func _marker_suit(card_index: int, number: int) -> void:
	if not presenter.marker_can_change_suit():
		_use_amulet(&"marker", {"card_index": card_index, "number": number, "suit": -1})
		return
	var mark := func(suit: int) -> void:
		_use_amulet(&"marker", {"card_index": card_index, "number": number, "suit": suit})
	var out := [{"text": "mismo palo", "name": "PickSuitSame", "callback": mark.bind(-1)}]
	for su in Card.Suit.size():
		out.append({"text": UiText.t("UI_SUIT_" + Card.Suit.keys()[su]), "name": "PickSuit%d" % su,
			"callback": mark.bind(su)})
	bloom(out, "Marcador: ¿qué palo?")


func _spare_choice(card_index: int) -> void:
	var options := presenter.spare_options()
	if options.is_empty():
		_use_amulet(&"spare_deck", {"card_index": card_index})
		return
	var out := []
	for i in options.size():
		out.append({"text": "por el " + card_text(options[i]), "name": "PickSpare%d" % i,
			"callback": _use_amulet.bind(&"spare_deck", {"card_index": card_index, "choice": i})})
	bloom(out, "Mazo aparte: ¿por cuál?")


func _popup_built() -> void:
	if world != null:
		_let_clicks_through(_popup_box)


func _popup_close() -> void:
	if _popup_box != null:
		_clear(_popup_box)
	_close_flower()


func camera_marker() -> StringName:
	return &"CamSeat"


func wants_backdrop() -> bool:
	return false


# --- Flor de acusar (vista 3D) ---

## Los cantos se esconden y las acusaciones se abren como pétalos desde el centro de
## tus cartas; en el medio queda "Cancelar".
func bloom(options: Array, title := "", cancel_offset := Vector2.ZERO) -> void:
	_close_flower(true)
	for c in _ring.get_children():
		(c as Control).visible = false
	_flower = Control.new()
	_flower.name = "Flower"
	_flower_hand = presenter.hand()
	_flower.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_flower)
	var center := RING_CENTER * get_viewport_rect().size
	for i in options.size():
		var o: Dictionary = options[i]
		var a := -PI * 0.5 + TAU * i / options.size()
		var callback: Callable = o["callback"] if o.has("callback") else _accuse.bind(o["accusation"])
		_petal(o["text"], o["name"], callback, center,
			center + Vector2(cos(a), sin(a) * 0.75) * _petal_radius(options.size()), i * PETAL_STAGGER)
	# Con una carta al frente "Cancelar" va al costado: en el medio está la carta.
	if cancel_offset == Vector2.ZERO and _table3d != null and _table3d.focused_card() != null:
		cancel_offset = Vector2(_petal_radius(options.size()) + 130, 0)
	_petal("Cancelar", "CancelAccuse", _close_flower, center + cancel_offset, center + cancel_offset, 0.0)
	if title != "":
		var head := RingStyle.reading_label("[center]" + RingStyle.JITTER % title + "[/center]", 22)
		head.name = "FlowerTitle"
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.size = Vector2(520, 40)
		head.position = center - Vector2(260, _petal_radius(options.size()) * 0.75 + 95)
		_flower.add_child(head)


## Con muchas opciones (los números del marcador) la flor se abre más.
static func _petal_radius(count: int) -> float:
	return PETAL_RADIUS * clampf(float(count) / 6.0, 1.0, 1.35)


func _petal(text: String, node_name: String, callback: Callable, from: Vector2, to: Vector2, delay: float) -> void:
	var b := ScreenTools.button(_flower, text, node_name, callback)
	RingStyle.shakify(b)
	var size := b.get_combined_minimum_size()
	b.size = size
	b.pivot_offset = size * 0.5
	b.position = to - size * 0.5
	if not is_inside_tree():
		return
	b.position = from - size * 0.5
	b.scale = Vector2.ONE * 0.2
	b.modulate.a = 0.0
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(b, "position", to - size * 0.5, PETAL_SECONDS).set_delay(delay)
	t.tween_property(b, "scale", Vector2.ONE, PETAL_SECONDS).set_delay(delay)
	t.tween_property(b, "modulate:a", 1.0, PETAL_SECONDS * 0.6).set_delay(delay)


## keep_focus: se cierra para abrir la flor siguiente; la carta sigue al frente.
func _close_flower(keep_focus := false) -> void:
	if _table3d != null:
		_table3d.card_pick = Callable()
		if not keep_focus:
			_table3d.unfocus()
	if not is_instance_valid(_flower):
		_flower = null
		return
	_flower.queue_free()
	_ring.remove_child(_flower)
	_flower = null
	for c in _ring.get_children():
		(c as Control).visible = true
