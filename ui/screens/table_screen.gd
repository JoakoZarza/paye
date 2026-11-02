extends BaseScreen
## La mesa: el partido, la mano de la cuenta y "una mano más". Solo muestra el
## estado del núcleo y llama a sus métodos; no decide nada (Plan 6, Tarea 3).

const T := TrucoAction.Type
const PLAYER := 0
const DEALER := 1
const HIDDEN_CARD := "[ ? ]"
const LOG_LINES := 14
const ICONS := {&"calm": "😐 tranquilo", &"nervous": "😬 nervioso",
	&"smug": "😏 agrandado", &"angry": "😠 enojado"}
const PHASE_NAMES := {
	TrucoHand.Phase.PLAYING: "Jugando", TrucoHand.Phase.ENVIDO_RESPONSE: "Responden el envido",
	TrucoHand.Phase.TANTO_DECLARATION: "Declaran el tanto", TrucoHand.Phase.TRUCO_RESPONSE: "Responden el truco",
	TrucoHand.Phase.SHOW_DECISION: "¿Mostrar el tanto?", TrucoHand.Phase.OVER: "Mano terminada",
}
const ACTION_NAMES := {
	T.ENVIDO: "Envido", T.REAL_ENVIDO: "Real envido", T.FALTA_ENVIDO: "Falta envido",
	T.TRUCO: "Truco", T.RETRUCO: "Quiero retruco", T.VALE_CUATRO: "Quiero vale cuatro",
	T.QUIERO: "Quiero", T.NO_QUIERO: "No quiero", T.SON_BUENAS: "Son buenas",
	T.DEMAND_SHOW: "Mostrame", T.ACCEPT_TANTO: "Está bien", T.MAZO: "Me voy al mazo", T.SHOW_TANTO: "Mostrar el tanto",
}
## El ganador del envido se fue al mazo sin mostrar: se reclama o se deja pasar.
const CLAIM_NAMES := {T.DEMAND_SHOW: "Reclamar el envido", T.ACCEPT_TANTO: "Dejarlo pasar"}
const TELLS_PATH := "res://data/i18n/tells.csv"
const UI_JSON := "res://data/ui.json"

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
var _log_lines: Array[String] = []
var _known: Array[String] = []
var _tells: Dictionary = {}
var _built := false


func _ready() -> void:
	_build()


func setup(p_rc: RunController) -> void:
	_build()
	super.setup(p_rc)


func refresh() -> void:
	if rc == null or rc.table() == null:
		return
	var m := rc.table().truco_match
	# Primera mano del partido. La mano única de la cuenta y de "una mano más"
	# ya la repartió el controlador.
	if m.hand == null and m.winner() == -1:
		_log_events(rc.systems.start_hand())
	_redraw()
	_schedule_dealer()


# --- Construcción ---

func _build() -> void:
	if _built:
		return
	_built = true
	_tells = _load_csv(TELLS_PATH)
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

	_title = _label(main, 26)
	_score = _label(main)
	_phase_label = _label(main)
	_label(main).text = "Cartas del rival"
	_dealer_row = _row(main)
	_label(main).text = "En la mesa (rival arriba, vos abajo)"
	_table_row = _row(main)
	_label(main).text = "Tus cartas"
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
	_timer.wait_time = _dealer_seconds()
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

func _redraw() -> void:
	var t := rc.table()
	var m := t.truco_match
	var hand := m.hand
	var rival := rc.table().brain.profile
	_title.text = "%s — %s" % [_mode_title(), UiText.t("UI_SIN_" + String(rival.sin).to_upper())]
	_score.text = "Vos %d — %d %s   (a %d puntos)" % [m.scores[PLAYER], m.scores[DEALER],
		UiText.t("UI_SIN_" + String(rival.sin).to_upper()), m.target]
	_phase_label.text = _phase_text(hand)
	var tell := t.brain.last_tell
	_tell_label.text = "" if tell == null else "Pista: «%s» %s" % [_tells.get(String(tell.text_key), String(tell.text_key)),
		ICONS.get(tell.icon, "")]
	_known_label.text = "" if _known.is_empty() else "Lo que sabés:\n" + "\n".join(_known)
	var ev := t.evidence()
	_evidence_label.text = "" if ev.is_empty() else "Algo raro en la mesa: %s" % ", ".join(ev.map(
		func(c: Cheat) -> String: return Cheat.Kind.keys()[c.kind]))

	_clear(_dealer_row)
	_clear(_table_row)
	_clear(_player_row)
	_clear(_actions)
	_clear(_amulets)
	if hand == null:
		return
	for c in hand.cards[DEALER]:
		var l := Label.new()
		l.text = HIDDEN_CARD
		_dealer_row.add_child(l)
	for p in [DEALER, PLAYER]:
		var played: Array = hand.played[p]
		for c: Card in played:
			var l := Label.new()
			l.text = ("%s: " % ("Rival" if p == DEALER else "Vos")) + card_text(c)
			_table_row.add_child(l)

	var my_turn := _player_can_act()
	var legal := _player_legal()
	for i in hand.cards[PLAYER].size():
		var card: Card = hand.cards[PLAYER][i]
		var play := _find(legal, T.PLAY_CARD, i)
		var b := _button(_player_row, card_text(card), _act.bind(play), my_turn and play != null)
		b.name = "Card%d" % i
	if _hand_finished():
		_button(_actions, "Seguir", _on_continue).name = "Continue"
		return
	if my_turn:
		_draw_actions(legal)
	if t.can_accuse() and not t.is_dealer_turn():
		_button(_actions, "Acusar…", _show_accuse).name = "Accuse"
	_draw_amulets(my_turn)


func _draw_actions(legal: Array[TrucoAction]) -> void:
	var tanto_values: Array[int] = []
	for a in legal:
		if a.type == T.PLAY_CARD:
			continue
		if a.type == T.DECLARE_TANTO:
			tanto_values.append(a.value)
			continue
		var text: String = ACTION_NAMES.get(a.type, T.keys()[a.type])
		if rc.table().truco_match.hand.mazo_unshown():
			text = CLAIM_NAMES.get(a.type, text)
		_button(_actions, text, _act.bind(a)).name = "Act_%s" % T.keys()[a.type]
	if tanto_values.is_empty():
		return
	var real := rc.table().truco_match.hand.own_tanto(PLAYER)
	var picker := OptionButton.new()
	picker.name = "TantoPicker"
	for v in tanto_values:
		picker.add_item(("%d (el tuyo)" % v) if v == real else str(v), v)
		if v == real:
			picker.select(picker.item_count - 1)
	_actions.add_child(picker)
	_button(_actions, "Declarar", func() -> void:
		_act(TrucoAction.make(T.DECLARE_TANTO, PLAYER, -1, picker.get_selected_id()))).name = "Declare"


func _draw_amulets(my_turn: bool) -> void:
	var sys := rc.systems
	for def in sys.loadout.equipped():
		var text := "%s (nivel %d)" % [UiText.t("UI_AMULET_" + String(def.id).to_upper()), sys.loadout.level(def.id)]
		if def.kind == AmuletDef.Kind.PASSIVE:
			var l := Label.new()
			l.text = text + " · pasivo"
			_amulets.add_child(l)
			continue
		text += " · %d" % sys.loadout.charges_left(def.id)
		var b := _button(_amulets, text, _on_amulet.bind(def.id), my_turn and sys.can_use(def.id))
		b.name = "Amulet_%s" % def.id


func _mode_title() -> String:
	match rc.phase:
		RunController.Phase.BILL_HAND:
			return "La cuenta: una sola mano"
		RunController.Phase.ONE_MORE:
			return "Una mano más"
	return "Ronda %d" % rc.state.round


func _phase_text(hand: TrucoHand) -> String:
	if hand == null:
		return ""
	var who := "" if hand.is_over() else ("  · te toca a vos" if hand.current_player() == PLAYER else "  · juega el rival")
	var truco := ["", "", "  · truco", "  · retruco", "  · vale cuatro"]
	return PHASE_NAMES.get(hand.phase, "") + truco[clampi(hand.truco_level(), 0, 4)] + who


static func card_text(c: Card) -> String:
	return "%d de %s" % [c.effective_number(), UiText.t("UI_SUIT_" + Card.Suit.keys()[c.effective_suit()])]


# --- Turnos ---

func _player_can_act() -> bool:
	var t := rc.table()
	var hand := t.truco_match.hand
	return hand != null and not _hand_finished() and not t.is_dealer_turn() and hand.current_player() == PLAYER


func _player_legal() -> Array[TrucoAction]:
	var out: Array[TrucoAction] = []
	if not _player_can_act():
		return out
	for a in rc.table().truco_match.hand.legal_actions():
		if a.player == PLAYER:
			out.append(a)
	return out


func _find(legal: Array[TrucoAction], type: T, card_index := -1) -> TrucoAction:
	for a in legal:
		if a.type == type and (card_index == -1 or a.card_index == card_index):
			return a
	return null


func _hand_finished() -> bool:
	var m := rc.table().truco_match
	return m.hand == null or m.hand.is_over() or m.winner() != -1


func _act(a: TrucoAction) -> void:
	if a == null or not _player_can_act():
		return
	_popup_close()
	_log_events(rc.table().player_action(a))
	_after_action()


func _after_action() -> void:
	_redraw()
	_schedule_dealer()


func _schedule_dealer() -> void:
	if rc.table() != null and rc.table().is_dealer_turn() and not _hand_finished() and _timer.is_stopped():
		if is_inside_tree():
			_timer.start()


## También la llaman los tests para no esperar el temporizador.
func _on_dealer_timer() -> void:
	var t := rc.table()
	if t == null or not t.is_dealer_turn() or _hand_finished():
		return
	_log_events(t.dealer_step())
	_after_action()


## Al terminar la mano: la siguiente, o cerrar el partido según la fase.
func _on_continue() -> void:
	var m := rc.table().truco_match
	_known.clear()
	_popup_close()
	match rc.phase:
		RunController.Phase.BILL_HAND:
			_log_events(rc.finish_bill_hand())
		RunController.Phase.ONE_MORE:
			_log_events(rc.finish_one_more())
		_:
			if m.winner() == -1:
				_log_events(rc.systems.start_hand())
				_after_action()
				return
			_log_events(rc.finish_match())
	acted.emit()


# --- Acusar ---

func _show_accuse() -> void:
	_popup_close()
	_label(_popup_box).text = "¿De qué lo acusás?"
	var row := HFlowContainer.new()
	_popup_box.add_child(row)
	_button(row, "Tiene una carta de más", _accuse.bind(Accusation.make(Accusation.Target.DEALER_HAND))).name = "Acc_Hand"
	_button(row, "Alguien le pasa tus cartas", _accuse.bind(Accusation.make(Accusation.Target.ACCOMPLICE))).name = "Acc_Accomplice"
	for c: Card in rc.table().truco_match.hand.played[DEALER]:
		_button(row, "Esa carta jugada: " + card_text(c),
			_accuse.bind(Accusation.make(Accusation.Target.HISTORY_CARD, c.key())))
	_button(row, "Cancelar", _popup_close)


func _accuse(acc: Accusation) -> void:
	_popup_close()
	_log_events(rc.table().accuse(acc))
	_after_action()


# --- Amuletos ---

func _on_amulet(id: StringName) -> void:
	match id:
		&"marker":
			_show_marker()
		&"spare_deck":
			_show_spare()
		_:
			_use_amulet(id, {})


func _use_amulet(id: StringName, args: Dictionary) -> void:
	_popup_close()
	_log_events(rc.systems.use(id, args))
	_after_action()


func _card_picker() -> OptionButton:
	var pick := OptionButton.new()
	var hand := rc.table().truco_match.hand
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
	if rc.systems.loadout.level(&"marker") >= AmuletDef.MAX_LEVEL:
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
	var options := rc.systems.preview_spare()
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


# --- Registro ---

func _log_events(events: Array[GameEvent]) -> void:
	for e in events:
		var text := _describe(e)
		if text != "":
			_log_lines.append(text)
	while _log_lines.size() > LOG_LINES:
		_log_lines.pop_front()
	if _log != null:
		_log.text = "\n".join(_log_lines)


func _who(p: Variant) -> String:
	return "Vos" if int(p) == PLAYER else "El rival"


func _describe(e: GameEvent) -> String:
	var d := e.data
	match e.type:
		&"coin_toss":
			return "Se tiró una moneda: " + ("sos mano." if int(d["mano"]) == PLAYER else "es mano el rival.")
		&"hand_started":
			_known.clear()
			return "— Mano nueva: " + ("sos mano" if int(d["mano"]) == PLAYER else "es mano el rival") + " —"
		&"envido_forfeit":
			return "Reclamado: %s se fue sin mostrar y el envido es del otro." % _who(d["player"])
		&"tanto_shown":
			return "%s mostró el tanto: el envido es suyo (+%d)." % [_who(d["player"]), d["points"]]
		&"card_played":
			return "%s: %s" % [_who(d["player"]), card_text(d["card"])]
		&"call_made":
			return "%s: ¡%s!" % [_who(d["player"]), ACTION_NAMES.get(d["call"], "?")]
		&"call_accepted":
			return "%s: quiero." % _who(d["player"])
		&"call_rejected":
			return "%s: no quiero." % _who(d["player"])
		&"tanto_declared":
			return "%s: %d de tanto." % [_who(d["player"]), d["value"]]
		&"son_buenas":
			return "%s: son buenas." % _who(d["player"])
		&"show_demanded":
			return "%s pidió que muestre." % _who(d["player"])
		&"lie_caught":
			return "¡%s mintió el tanto!" % _who(d["player"])
		&"show_wrong":
			return "Pidió mostrar en falso."
		&"mazo":
			return "%s se fue al mazo." % _who(d["player"])
		&"baza_won":
			return "Baza: %s" % ("parda" if int(d["result"]) == BazaResolver.PARDA else _who(d["result"]))
		&"hand_over":
			var env: Array = d["envido"]
			var tru: Array = d["truco"]
			return "Fin de la mano: vos +%d, rival +%d." % [env[PLAYER] + tru[PLAYER], env[DEALER] + tru[DEALER]]
		&"match_over":
			return "Terminó el partido."
		&"accusation_right":
			return "¡Lo pescaste! La mano es tuya."
		&"accusation_wrong":
			return "Acusaste en falso: +%d para el rival." % CheatTable.WRONG_ACCUSATION_POINTS
		&"player_caught":
			return "¡Te pescaron haciendo trampa! Perdés la mano."
		&"cheat_tell":
			return "Notaste algo raro en el rival."
		&"amulet_used":
			return "Usaste %s." % UiText.t("UI_AMULET_" + String(d["id"]).to_upper())
		&"amulet_info":
			_known.append(_info_text(d))
			return ""
		&"player_cheat_info":
			_known.append(_cheat_info_text(d))
			return ""
		&"illegal_action":
			return "No se puede."
	return ""


func _info_text(d: Dictionary) -> String:
	var parts: Array[String] = []
	var numbers: Array = d.get("numbers", [])
	var suits: Array = d.get("suits", [])
	for i in numbers.size():
		var s := "" if i >= suits.size() else " de " + UiText.t("UI_SUIT_" + Card.Suit.keys()[suits[i]])
		parts.append(str(numbers[i]) + s)
	var text := "%s: tiene %s" % [UiText.t("UI_AMULET_" + String(d["id"]).to_upper()), ", ".join(parts)]
	if d.has("best_suit"):
		text += " (la más alta es de %s)" % UiText.t("UI_SUIT_" + Card.Suit.keys()[d["best_suit"]])
	return text


func _cheat_info_text(d: Dictionary) -> String:
	if d.has("cards"):
		var cards: Array = d["cards"]
		return "Espejo: " + ", ".join(cards.map(func(c: Card) -> String: return card_text(c)))
	return "Cartas marcadas: su mejor carta vale %d en la escala del truco." % d.get("best_rank", 0)


# --- Datos ---

func _dealer_seconds() -> float:
	if not FileAccess.file_exists(UI_JSON):
		return 0.6
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(UI_JSON)) != OK or not json.data is Dictionary:
		return 0.6
	return float((json.data as Dictionary).get("dealer_step_seconds", 0.6))


static func _load_csv(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 2:
			out[line[0]] = line[1]
	return out
