extends BaseScreen
## La mesa 2D: dibuja lo que dice el TablePresenter y le pasa los clics. No
## decide nada (Plan 6, Tarea 3; Plan 7, Tarea 1).

const T := TrucoAction.Type
const PLAYER := TablePresenter.PLAYER
const DEALER := TablePresenter.DEALER
const HIDDEN_CARD := "[ ? ]"

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
	for n in [_dealer_row, _table_row, _player_row, _dealer_title, _table_title, _player_title]:
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
	add_child(Table3D.new(world, presenter, ps1))


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
	_label(main).text = "Amuletos"
	_amulets = HFlowContainer.new()
	main.add_child(_amulets)
	_popup_box = VBoxContainer.new()
	main.add_child(_popup_box)

	_tell_label = _label(side)
	_known_label = _label(side)
	_evidence_label = _label(side)
	_label(side, 18).text = "Lo que pasó"
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
	_tell_label.text = p.tell_text()
	_known_label.text = p.known_text()
	_evidence_label.text = p.evidence_text()
	_log.text = "\n".join(p.log_lines)

	_clear(_dealer_row)
	_clear(_table_row)
	_clear(_player_row)
	_clear(_actions)
	_clear(_amulets)
	var hand := p.hand()
	if hand == null:
		return
	if world == null:
		_draw_cards(hand)
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
	presenter.dealer_step()


func _on_continue() -> void:
	_popup_close()
	presenter.continue_hand()


# --- Acusar ---

func _show_accuse() -> void:
	_popup_close()
	_label(_popup_box).text = "¿De qué lo acusás?"
	var row := HFlowContainer.new()
	_popup_box.add_child(row)
	for o in presenter.accuse_options():
		_button(row, o["text"], _accuse.bind(o["accusation"])).name = o["name"]
	_button(row, "Cancelar", _popup_close)


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


func _show_spare() -> void:
	_popup_close()
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


func _popup_close() -> void:
	if _popup_box != null:
		_clear(_popup_box)
