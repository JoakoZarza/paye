class_name Table3D
extends Node
## Pone en el bar 3D lo que dice el TablePresenter: tus cartas en abanico, las del
## rival boca abajo, las jugadas en su baza, lo que dice el rival al lado suyo, la luz según
## su humor, la planilla de puntos y lo que está apoyado en la mesa (TableProps). Los clics en tus cartas vuelven al presentador (Plan 7, Tarea 4).

signal amulet_pressed(id: StringName, needs: StringName)

const CARD_SCENE := preload("res://world/card_3d.tscn")
const MOVE_SECONDS := 0.25
## Abanico como se agarran las cartas: giran alrededor del puño, la de la derecha encima.
const FAN_ANGLE := deg_to_rad(16.0)
const FAN_RADIUS := 0.13
const FAN_LAYER := 0.004
## Tu mano, inclinada hacia la cámara.
const HAND_TILT := deg_to_rad(-45.0)
## Sin mirar tus cartas la mano solo baja: sigue tapándolas del rival.
const HAND_LOWERED := Vector3(0, -0.1, 0.03)
const FACE_UP := deg_to_rad(-90.0)
const FACE_DOWN := deg_to_rad(90.0)
const LAMP_COLORS := {&"calm": Color("#ffc77a"), &"nervous": Color("#e8d08a"),
	&"smug": Color("#ffb45a"), &"angry": Color("#ff7a52")}
const LAMP_DEFAULT := Color("#ffc77a")
## Tus amuletos, de tu lado a la izquierda. Los objetos del rival irían en DealerItems.
const AMULET_SPOTS := [Vector3(-0.3, 0.7505, 0.3), Vector3(-0.2, 0.7505, 0.36),
	Vector3(-0.38, 0.7505, 0.2), Vector3(-0.38, 0.7505, 0.36)]
## En su turno el rival levanta el abanico, como quien piensa qué tirar.
const DEALER_THINKING := Vector3(0, 0.05, 0.03)
## El nombre de la carta que mirás inclinado: más chico y apenas arriba de ella.
const PEEK_SCALE := 0.45
const PEEK_ABOVE := Vector3(0, 0.07, 0)
## Dónde deja el rival las cartas del tanto que muestra, y cuánto las deja.
const SHOW_SPOT := Vector3(0, 0.756, -0.27)
const SHOW_GAP := 0.075
const SHOW_SECONDS := 4.0
## Entre mano y mano: el mazo sube al centro a la altura del pecho, se mezcla, baja a
## su lugar y se reparte de a una carta, empezando por el mano.
const SHUFFLE_AT := Vector3(0, 1.02, -0.05)
const SHUFFLE_RISE := 0.35
const SHUFFLE_SECONDS := 0.8
const SHUFFLE_DROP := 0.3
const DEAL_STEP := 0.11
const DEAL_FLIGHT := 0.18
## Animación "shuffle" del modelo del mazo, si la trae.
const SHUFFLE_ANIMATION := &"shuffle"
## Los tests la apagan para que las cartas estén en su lugar al instante.
static var animate_deals := true
## El canto va debajo de lo que murmura.
const CALL_OFFSET := Vector3(0, -0.26, 0)
const PLAYER := TablePresenter.PLAYER
const DEALER := TablePresenter.DEALER

var bar: Bar3D
var presenter: TablePresenter
var ps1 := false

var _root: Node3D
## Card -> Card3D. Es la única referencia a las cartas del rival: el árbol de nodos
## no sabe nada de ellas hasta que se revelan.
var _cards: Dictionary = {}
var _revealed: Dictionary = {}
var _speech: Subtitle3D
var _said_id := 0
var _call: Subtitle3D
var _call_id := 0
var _sheet: ScoreSheet
var _amulets: Array[AmuletToken] = []
var _amulets_key := ""
var _babble: Babble
var _props: TableProps
## Cartas jugadas (Card -> true) y la que estás mirando inclinado, con su nombre arriba.
var _on_table: Dictionary = {}
var _peeked: Card3D
var _peek_label: Subtitle3D
## Cartas del tanto que mostró el rival, boca arriba de su lado hasta show_until.
var _showing: Array[Card] = []
var _shown_id := 0
var _show_until := 0.0
var _last_hand: TrucoHand
var _dealing := false
## Mientras se reparte: Card3D -> [posición, rotación] adonde va cuando le toque.
var _pending: Dictionary = {}
var _new_hand := false
var _hand_raised := true


func _init(p_bar: Bar3D, p_presenter: TablePresenter, p_ps1 := false) -> void:
	bar = p_bar
	presenter = p_presenter
	ps1 = p_ps1


func _ready() -> void:
	_root = Node3D.new()
	_root.name = "TableCards"
	bar.add_child(_root)
	_speech = Subtitle3D.new()
	_speech.name = "RivalSpeech"
	_speech.face_camera = false
	bar.marker("SpeechAnchor").add_child(_speech)
	_call = Subtitle3D.new()
	_call.name = "RivalCall"
	_call.face_camera = false
	_call.position = CALL_OFFSET
	bar.marker("SpeechAnchor").add_child(_call)
	_babble = Babble.new()
	_babble.name = "RivalBabble"
	bar.marker("SpeechAnchor").add_child(_babble)
	_babble.set_voice(presenter.sin_name())
	_speech.letter_typed.connect(_babble.on_letter)
	_call.letter_typed.connect(_babble.on_letter)
	_sheet = ScoreSheet.new()
	_sheet.name = "Sheet"
	_sheet.ps1 = ps1
	bar.marker("ScoreSheet").add_child(_sheet)
	_peek_label = Subtitle3D.new()
	_peek_label.name = "PeekLabel"
	_peek_label.scale = Vector3.ONE * PEEK_SCALE
	_root.add_child(_peek_label)
	_props = TableProps.new()
	_props.name = "Props"
	_props.ps1 = ps1
	bar.add_child(_props)
	presenter.changed.connect(sync)
	sync()


## La mano se levanta cuando la cabeza mira tus cartas; si mirás para otro lado
## la bajás un poco, sin apoyarla.
func _process(_delta: float) -> void:
	if _peeked != null and (not is_instance_valid(_peeked) or (not _leaning() and not _peeked_shown())):
		_end_peek()
	if not _showing.is_empty() and Time.get_ticks_msec() / 1000.0 > _show_until:
		_showing.clear()
		sync()
	var raised := hand_should_be_raised()
	if raised != _hand_raised:
		_hand_raised = raised
		sync()


func hand_should_be_raised() -> bool:
	var cam := bar.camera
	return cam == null or cam.looking_at_hand()


func hand_raised() -> bool:
	return _hand_raised


func _exit_tree() -> void:
	if is_instance_valid(_root):
		_root.queue_free()
	for n in [_speech, _call]:
		if is_instance_valid(n):
			n.queue_free()
	for n in [_babble, _sheet, _props] + _amulets:
		if is_instance_valid(n):
			n.queue_free()
	if not is_instance_valid(bar):
		return
	var light := bar.get_node_or_null("LampLight") as Light3D
	if light != null:
		light.light_color = LAMP_DEFAULT


func _label3d(parent: Node3D, size: int) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.002
	l.outline_size = 8
	parent.add_child(l)
	return l


func card_nodes() -> Array[Card3D]:
	var out: Array[Card3D] = []
	for c in _cards.values():
		out.append(c)
	return out


## Nodo de tu carta i en la mano, o null.
func player_card(i: int) -> Card3D:
	var h := presenter.hand()
	if h == null or i >= h.cards[PLAYER].size():
		return null
	return _cards.get(h.cards[PLAYER][i])


func sync() -> void:
	var h := presenter.hand()
	var wanted := {}
	_new_hand = h != null and h != _last_hand and animate_deals and is_inside_tree()
	if h != null and h != _last_hand:
		_last_hand = h
		if _new_hand:
			_dealing = true
			_pending.clear()
	if h != null:
		# El mazo, a la derecha del pie; las cartas nuevas salen de ahí.
		_props.set_mano(h.mano)
		bar.marker("Deck").position = TableProps.deck_spot(h.mano) + Vector3(0, TableProps.DECK_SIZE.y, 0)
		var my_turn := presenter.player_can_act()
		var mine: Array = h.cards[PLAYER]
		var center := bar.marker("PlayerHand").position
		if not _hand_raised:
			center += HAND_LOWERED
		for i in mine.size():
			var spot := fan(center, i, mine.size(), HAND_TILT, 0.0)
			_place(mine[i], i, false, spot[0], spot[1], _hand_raised and my_turn)
			wanted[mine[i]] = true
		# El rival también las agarra en abanico, de espaldas a vos.
		if presenter.shown_id != _shown_id:
			_shown_id = presenter.shown_id
			_showing = presenter.shown_cards.duplicate()
			_show_until = Time.get_ticks_msec() / 1000.0 + SHOW_SECONDS
		var theirs: Array = h.cards[DEALER]
		var theirs_at := bar.marker("DealerHand").position
		if presenter.dealer_should_play():
			theirs_at += DEALER_THINKING
		for i in theirs.size():
			var k := _showing.find(theirs[i])
			if k >= 0:
				# Mostrándolas: boca arriba sobre la mesa, de su lado.
				var at := SHOW_SPOT + Vector3((k - (_showing.size() - 1) * 0.5) * SHOW_GAP, 0, 0)
				_place(theirs[i], i, true, at, Vector3(FACE_UP, 0, 0), false, true)
			else:
				var spot := fan(theirs_at, i, theirs.size(), HAND_TILT, PI)
				_hide_again(theirs[i])
				_place(theirs[i], i, true, spot[0], spot[1], false)
			wanted[theirs[i]] = true
		_on_table.clear()
		for who in [PLAYER, DEALER]:
			var played: Array = h.played[who]
			for b in played.size():
				# Con la manga el rival puede jugar una cuarta carta: va encima de la tercera.
				var marker := bar.marker("Baza%d_%s" % [mini(b + 1, 3), "Player" if who == PLAYER else "Dealer"])
				var pos := marker.position + Vector3(0, 0.001 * maxi(b - 2, 0), 0)
				_place(played[b], -1, who == DEALER, pos, Vector3(FACE_UP, 0, 0), false, true)
				wanted[played[b]] = true
				_on_table[played[b]] = true
	for card in _cards.keys():
		if not wanted.has(card):
			(_cards[card] as Node).queue_free()
			_cards.erase(card)
			_revealed.erase(card)
	_sync_tell()
	var accomplice := bar.slot("accomplice")
	if accomplice != null:
		accomplice.visible = presenter.accomplice_present()
	var m := presenter.rc.table().truco_match
	_sheet.set_scores(m.scores)
	if _new_hand:
		_new_hand = false
		_deal(h)
	_props.set_chips(presenter.rc.state.round - 1)
	_props.set_stake(stake() if h != null else 0)
	_sync_amulets()


## [posición, rotación] de la carta i de n en un abanico centrado en center.
static func fan(center: Vector3, i: int, n: int, tilt: float, yaw: float) -> Array:
	var roll := -(i - (n - 1) * 0.5) * FAN_ANGLE
	var basis := Basis.from_euler(Vector3(tilt, yaw, 0))
	var in_hand := Vector3(-sin(roll) * FAN_RADIUS, (cos(roll) - 1.0) * FAN_RADIUS, i * FAN_LAYER)
	return [center + basis * in_hand, Vector3(tilt, yaw, roll)]


func _place(card: Card, index: int, dealer: bool, pos: Vector3, rot: Vector3, hoverable: bool,
		reveal := false) -> void:
	var node: Card3D = _cards.get(card)
	if node == null:
		node = CARD_SCENE.instantiate()
		node.position = bar.marker("Deck").position
		node.rotation = Vector3(FACE_DOWN, 0, 0)
		_root.add_child(node)
		node.setup_card(card, index, dealer, not dealer)
		if not dealer:
			_revealed[card] = true
		node.clicked.connect(_on_card_clicked)
		node.hover_changed.connect(_on_card_hover.bind(card, node))
		_cards[card] = node
		if ps1:
			Ps1Material.apply(node)
		if _dealing:
			node.visible = false
			_pending[node] = [pos, rot]
	node.card_index = index
	node.hoverable = hoverable
	if _pending.has(node):
		_pending[node] = [pos, rot]
		return
	if (reveal and not _revealed.has(card)) or node.face_is_stale(card):
		node.reveal(card)
		_revealed[card] = true
		if ps1:
			Ps1Material.apply(node)
	# Ya está en su lugar (sin contar lo que se levanta por el hover): no se toca.
	var at_rest := Vector3(node.position.x, node.rest_y, node.position.z)
	if is_equal_approx(node.rest_y, pos.y) and at_rest.distance_to(pos) < 0.001 and node.rotation.distance_to(rot) < 0.001:
		return
	node.move_to(pos, rot, MOVE_SECONDS)


func _on_card_clicked(index: int) -> void:
	if index >= 0:
		presenter.act(presenter.card_action(index))


func _sync_tell() -> void:
	# Lo que murmura se va solo; el canto queda abajo hasta que respondas.
	if presenter.rival_line_id != _said_id:
		_said_id = presenter.rival_line_id
		_speech.say(presenter.rival_line)
	if presenter.rival_call_id != _call_id:
		_call_id = presenter.rival_call_id
		_call.say(presenter.rival_call, presenter.rival_waiting)
	elif _call.persistent and not presenter.rival_waiting:
		_call.dismiss()
	var t := presenter.tell()
	var light := bar.get_node_or_null("LampLight") as Light3D
	if light != null:
		light.light_color = LAMP_COLORS.get(t.get("kind", &""), LAMP_DEFAULT)


## Lo que vale la mano con el truco cantado (2, 3 o 4); 0 sin truco.
func stake() -> int:
	var h := presenter.hand()
	if h == null or h.is_over():
		return 0
	var level := h.truco_level()
	return level if level >= 2 else 0


func props() -> TableProps:
	return _props


func amulet_tokens() -> Array[AmuletToken]:
	return _amulets


## Rehace los amuletos de la mesa solo si cambió algo (cargas, turno, cuáles hay).
func _sync_amulets() -> void:
	var infos := presenter.amulet_buttons()
	var key := str(infos)
	if key == _amulets_key:
		return
	_amulets_key = key
	for t in _amulets:
		t.queue_free()
	_amulets.clear()
	for i in infos.size():
		var token := AmuletToken.new()
		token.position = AMULET_SPOTS[i % AMULET_SPOTS.size()] + Vector3(0, 0, 0.12 * (i / AMULET_SPOTS.size()))
		_root.add_child(token)
		token.setup(infos[i], ps1)
		token.pressed.connect(func(id: StringName, needs: StringName) -> void: amulet_pressed.emit(id, needs))
		_amulets.append(token)


func _leaning() -> bool:
	return bar.camera != null and bar.camera.leaning()


## Inclinado sobre la mesa, pasar el mouse por una carta jugada la levanta y dice qué es.
func _on_card_hover(on: bool, card: Card, node: Card3D) -> void:
	if not on:
		if node == _peeked:
			_end_peek()
		return
	var shown := card in _showing
	if not shown and (not _on_table.has(card) or not _leaning()):
		return
	if _peeked != null and _peeked != node and is_instance_valid(_peeked):
		_peeked.peek(false)
	_peeked = node
	node.peek(true)
	_peek_label.position = node.position + PEEK_ABOVE
	_peek_label.say(TablePresenter.card_text(card), true)


func peeked_text() -> String:
	return _peek_label.text if _peeked != null else ""


func _end_peek() -> void:
	if is_instance_valid(_peeked):
		_peeked.peek(false)
	_peeked = null
	_peek_label.say("")


func showing() -> Array[Card]:
	return _showing


## Una carta del rival que volvió a su mano después de mostrarla se tapa otra vez.
func _hide_again(card: Card) -> void:
	var node: Card3D = _cards.get(card)
	if node == null or not _revealed.has(card):
		return
	node.setup_card(card, node.card_index, true, false)
	_revealed.erase(card)


func dealing() -> bool:
	return _dealing


## Mezcla en el aire y reparte de a una, alternando y empezando por el mano.
func _deal(h: TrucoHand) -> void:
	var deck := _props.deck
	if _props._deck_tween != null:
		_props._deck_tween.kill()
	var lift := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	lift.tween_property(deck, "position", SHUFFLE_AT, SHUFFLE_RISE)
	await lift.finished
	var anim := deck.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null and anim.has_animation(SHUFFLE_ANIMATION):
		anim.play(SHUFFLE_ANIMATION)
	# Hasta que esté la animación de Joako: el mazo se sacude un poco en el aire.
	var shake := create_tween().set_loops(4)
	shake.tween_property(deck, "rotation:y", 0.25, SHUFFLE_SECONDS / 8.0)
	shake.tween_property(deck, "rotation:y", -0.25, SHUFFLE_SECONDS / 8.0)
	await get_tree().create_timer(SHUFFLE_SECONDS).timeout
	shake.kill()
	deck.rotation.y = 0.0
	var rest := TableProps.deck_spot(h.mano)
	var drop := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	drop.tween_property(deck, "position", rest, SHUFFLE_DROP)
	await drop.finished
	for card in deal_order(h):
		var node: Card3D = _cards.get(card)
		if node == null or not is_instance_valid(node) or not _pending.has(node):
			continue
		var target: Array = _pending[node]
		_pending.erase(node)
		node.position = bar.marker("Deck").position
		node.visible = true
		node.move_to(target[0], target[1], DEAL_FLIGHT)
		await get_tree().create_timer(DEAL_STEP).timeout
	for node: Card3D in _pending.keys():
		if is_instance_valid(node):
			node.visible = true
	_pending.clear()
	_dealing = false
	sync()


## Orden de reparto: una para el mano, una para el pie, y así; las de más, al final.
static func deal_order(h: TrucoHand) -> Array[Card]:
	var first: Array = h.cards[h.mano] + h.played[h.mano]
	var second: Array = h.cards[1 - h.mano] + h.played[1 - h.mano]
	var out: Array[Card] = []
	for i in maxi(first.size(), second.size()):
		if i < first.size():
			out.append(first[i])
		if i < second.size():
			out.append(second[i])
	return out


func _peeked_shown() -> bool:
	for c in _showing:
		if _cards.get(c) == _peeked:
			return true
	return false
