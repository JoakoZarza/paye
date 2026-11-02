class_name TablePresenter
extends RefCounted
## Lo que la mesa muestra y deja hacer, sin dibujar nada: acciones legales del
## jugador, turno del dealer, seguir de mano, textos y "lo que sabés". La usan la
## mesa 2D y la 3D, así las reglas de la pantalla existen una sola vez (Plan 7, Tarea 1).

signal changed
## Eventos del núcleo recién aplicados, para animar (cartas, cantos, fin de mano).
signal events_applied(events: Array[GameEvent])
## Terminó lo que se jugaba en la mesa: el router tiene que cambiar de pantalla.
signal left_table

const T := TrucoAction.Type
const PLAYER := 0
const DEALER := 1
const LOG_LINES := 14
const ICONS := {&"calm": "😐 tranquilo", &"nervous": "😬 nervioso",
	&"smug": "😏 agrandado", &"angry": "😠 enojado"}
const PHASE_NAMES := {
	TrucoHand.Phase.PLAYING: "Jugando", TrucoHand.Phase.ENVIDO_RESPONSE: "Responden el envido",
	TrucoHand.Phase.TANTO_DECLARATION: "Declaran el tanto", TrucoHand.Phase.TRUCO_RESPONSE: "Responden el truco",
	TrucoHand.Phase.SHOW_DECISION: "Mano terminada", TrucoHand.Phase.OVER: "Mano terminada",
}
const ACTION_NAMES := {
	T.ENVIDO: "Envido", T.REAL_ENVIDO: "Real envido", T.FALTA_ENVIDO: "Falta envido",
	T.TRUCO: "Truco", T.RETRUCO: "Quiero retruco", T.VALE_CUATRO: "Quiero vale cuatro",
	T.QUIERO: "Quiero", T.NO_QUIERO: "No quiero", T.SON_BUENAS: "Son buenas",
	T.DEMAND_SHOW: "Mostrame", T.ACCEPT_TANTO: "Está bien", T.MAZO: "Me voy al mazo", T.SHOW_TANTO: "Mostrar el tanto",
}
const EVIDENCE_NAMES := {Cheat.Kind.SLEEVE: "tiene una carta de más",
	Cheat.Kind.DUPLICATE: "una carta repetida", Cheat.Kind.ACCOMPLICE: "alguien mira tus cartas"}
const TELLS_PATH := "res://data/i18n/tells.csv"
const UI_JSON := "res://data/ui.json"

var rc: RunController
var log_lines: Array[String] = []
var known: Array[String] = []

var _tells: Dictionary = {}


func _init(p_rc: RunController) -> void:
	rc = p_rc
	_tells = _load_csv(TELLS_PATH)


## Reparte la primera mano del partido si hace falta. La mano única de la cuenta
## y de "una mano más" ya la repartió el controlador.
func start() -> void:
	if rc == null or rc.table() == null:
		return
	var m := rc.table().truco_match
	if m.hand == null and m.winner() == -1:
		_apply(rc.systems.start_hand())
	changed.emit()


func hand() -> TrucoHand:
	return rc.table().truco_match.hand


# --- Turnos ---

func hand_finished() -> bool:
	var m := rc.table().truco_match
	return m.hand == null or m.hand.is_over() or m.winner() != -1


func player_can_act() -> bool:
	var t := rc.table()
	var h := t.truco_match.hand
	return h != null and not hand_finished() and not t.is_dealer_turn() and h.current_player() == PLAYER


func dealer_should_play() -> bool:
	return rc.table() != null and rc.table().is_dealer_turn() and not hand_finished()


func player_legal() -> Array[TrucoAction]:
	var out: Array[TrucoAction] = []
	if not player_can_act():
		return out
	for a in hand().legal_actions():
		if a.player == PLAYER:
			out.append(a)
	return out


static func find(legal: Array[TrucoAction], type: T, card_index := -1) -> TrucoAction:
	for a in legal:
		if a.type == type and (card_index == -1 or a.card_index == card_index):
			return a
	return null


## Jugar la carta i de tu mano, o null si ahora no se puede.
func card_action(i: int) -> TrucoAction:
	return find(player_legal(), T.PLAY_CARD, i)


## La mano terminó y el rival ganó el envido: nadie te pregunta nada. Podés pedir
## que muestre (o reclamar si se fue sin mostrar); si seguís de largo, te olvidaste.
func in_show_decision() -> bool:
	return player_can_act() and hand().phase == TrucoHand.Phase.SHOW_DECISION


func demand_text() -> String:
	return "Reclamar el envido" if hand().mazo_unshown() else "Pedir que muestre"


## Cantos y respuestas como botones: [{text, action, name}]. Sin cartas, sin
## declarar el tanto y sin la decisión de mostrar, que se dibujan aparte.
func call_buttons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if in_show_decision():
		return out
	for a in player_legal():
		if a.type == T.PLAY_CARD or a.type == T.DECLARE_TANTO:
			continue
		out.append({"text": ACTION_NAMES.get(a.type, T.keys()[a.type]), "action": a, "name": "Act_%s" % T.keys()[a.type]})
	return out


## Valores que podés declarar (vacío si no te toca declarar).
func tanto_values() -> Array[int]:
	var out: Array[int] = []
	if in_show_decision():
		return out
	for a in player_legal():
		if a.type == T.DECLARE_TANTO:
			out.append(a.value)
	return out


func own_tanto() -> int:
	return hand().own_tanto(PLAYER)


func act(a: TrucoAction) -> void:
	if a == null or not player_can_act():
		return
	_apply(rc.table().player_action(a))
	changed.emit()


func declare(value: int) -> void:
	act(TrucoAction.make(T.DECLARE_TANTO, PLAYER, -1, value))


func demand_show() -> void:
	act(find(player_legal(), T.DEMAND_SHOW))


## "Seguir" en la decisión de mostrar: dejarlo pasar y pasar a lo que sigue.
func accept_and_continue() -> void:
	act(find(player_legal(), T.ACCEPT_TANTO))
	if hand_finished():
		continue_hand()


func dealer_step() -> void:
	if not dealer_should_play():
		return
	_apply(rc.table().dealer_step())
	changed.emit()


## Al terminar la mano: la siguiente, o cerrar el partido según la fase.
func continue_hand() -> void:
	var m := rc.table().truco_match
	known.clear()
	match rc.phase:
		RunController.Phase.BILL_HAND:
			_apply(rc.finish_bill_hand())
		RunController.Phase.ONE_MORE:
			_apply(rc.finish_one_more())
		_:
			if m.winner() == -1:
				_apply(rc.systems.start_hand())
				changed.emit()
				return
			_apply(rc.finish_match())
	left_table.emit()


# --- Acusar ---

func can_accuse() -> bool:
	var t := rc.table()
	return not hand_finished() and t.can_accuse() and not t.is_dealer_turn()


## [{text, accusation, name}]
func accuse_options() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{"text": "Tiene una carta de más", "accusation": Accusation.make(Accusation.Target.DEALER_HAND), "name": "Acc_Hand"},
		{"text": "Alguien le pasa tus cartas", "accusation": Accusation.make(Accusation.Target.ACCOMPLICE),
			"name": "Acc_Accomplice"},
	]
	for c: Card in hand().played[DEALER]:
		out.append({"text": "Esa carta jugada: " + card_text(c),
			"accusation": Accusation.make(Accusation.Target.HISTORY_CARD, c.key()), "name": "Acc_Card"})
	return out


func accuse(acc: Accusation) -> void:
	_apply(rc.table().accuse(acc))
	changed.emit()


# --- Amuletos ---

## [{id, text, passive, enabled, needs}]; needs: &"" (se usa directo), &"marker" o &"spare_deck".
func amulet_buttons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sys := rc.systems
	var my_turn := player_can_act()
	for def in sys.loadout.equipped():
		var text := "%s (nivel %d)" % [UiText.t("UI_AMULET_" + String(def.id).to_upper()), sys.loadout.level(def.id)]
		var passive := def.kind == AmuletDef.Kind.PASSIVE
		if passive:
			text += " · pasivo"
		else:
			text += " · %d" % sys.loadout.charges_left(def.id)
		var needs: StringName = def.id if def.id in [&"marker", &"spare_deck"] else &""
		out.append({"id": def.id, "text": text, "passive": passive,
			"enabled": not passive and my_turn and sys.can_use(def.id), "needs": needs})
	return out


func use_amulet(id: StringName, args: Dictionary = {}) -> void:
	_apply(rc.systems.use(id, args))
	changed.emit()


func marker_can_change_suit() -> bool:
	return rc.systems.loadout.level(&"marker") >= AmuletDef.MAX_LEVEL


func spare_options() -> Array[Card]:
	return rc.systems.preview_spare()


# --- Textos ---

func title() -> String:
	return "%s — %s" % [mode_title(), sin_name()]


func sin_name() -> String:
	return UiText.t("UI_SIN_" + String(rc.table().brain.profile.sin).to_upper())


func mode_title() -> String:
	match rc.phase:
		RunController.Phase.BILL_HAND:
			return "La cuenta: una sola mano"
		RunController.Phase.ONE_MORE:
			return "Una mano más"
	return "Ronda %d" % rc.state.round


func score_text() -> String:
	var m := rc.table().truco_match
	return "Vos %d — %d %s   (a %d puntos)" % [m.scores[PLAYER], m.scores[DEALER], sin_name(), m.target]


func phase_text() -> String:
	var h := hand()
	if h == null:
		return ""
	var who := "" if h.is_over() else ("  · te toca a vos" if h.current_player() == PLAYER else "  · juega el rival")
	var truco := ["", "", "  · truco", "  · retruco", "  · vale cuatro"]
	return PHASE_NAMES.get(h.phase, "") + truco[clampi(h.truco_level(), 0, 4)] + who


## La pista actual del rival o "" si no hay: {text, icon}.
func tell() -> Dictionary:
	var t := rc.table().brain.last_tell
	if t == null:
		return {}
	return {"text": _tells.get(String(t.text_key), String(t.text_key)), "icon": ICONS.get(t.icon, ""), "kind": t.icon}


func tell_text() -> String:
	var t := tell()
	return "" if t.is_empty() else "Pista: «%s» %s" % [t["text"], t["icon"]]


func known_text() -> String:
	return "" if known.is_empty() else "Lo que sabés:\n" + "\n".join(known)


func evidence_text() -> String:
	var ev := rc.table().evidence()
	return "" if ev.is_empty() else "Algo raro en la mesa: %s" % ", ".join(ev.map(
		func(c: Cheat) -> String: return EVIDENCE_NAMES.get(c.kind, Cheat.Kind.keys()[c.kind])))


static func card_text(c: Card) -> String:
	return "%d de %s" % [c.effective_number(), UiText.t("UI_SUIT_" + Card.Suit.keys()[c.effective_suit()])]


func dealer_seconds() -> float:
	if not FileAccess.file_exists(UI_JSON):
		return 0.6
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(UI_JSON)) != OK or not json.data is Dictionary:
		return 0.6
	return float((json.data as Dictionary).get("dealer_step_seconds", 0.6))


# --- Registro ---

func _apply(events: Array[GameEvent]) -> void:
	for e in events:
		var text := describe(e)
		if text != "":
			log_lines.append(text)
	while log_lines.size() > LOG_LINES:
		log_lines.pop_front()
	events_applied.emit(events)


func _who(p: Variant) -> String:
	return "Vos" if int(p) == PLAYER else "El rival"


func describe(e: GameEvent) -> String:
	var d := e.data
	match e.type:
		&"coin_toss":
			return "Se tiró una moneda: " + ("sos mano." if int(d["mano"]) == PLAYER else "es mano el rival.")
		&"hand_started":
			known.clear()
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
			known.append(_info_text(d))
			return ""
		&"player_cheat_info":
			known.append(_cheat_info_text(d))
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
