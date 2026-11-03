class_name Table3D
extends Node
## Pone en el bar 3D lo que dice el TablePresenter: tus cartas en abanico, las del
## rival boca abajo, las jugadas en su baza, lo que dice el rival al lado suyo, la luz según
## su humor y la pizarra. Los clics en tus cartas vuelven al presentador (Plan 7, Tarea 4).

const CARD_SCENE := preload("res://world/card_3d.tscn")
const MOVE_SECONDS := 0.25
## Abanico como se agarran las cartas: giran alrededor del puño, la de la derecha encima.
const FAN_ANGLE := deg_to_rad(16.0)
const FAN_RADIUS := 0.13
const FAN_LAYER := 0.002
## Tu mano, inclinada hacia la cámara.
const HAND_TILT := deg_to_rad(-45.0)
## Sin mirar tus cartas la mano solo baja: sigue tapándolas del rival.
const HAND_LOWERED := Vector3(0, -0.1, 0.03)
const FACE_UP := deg_to_rad(-90.0)
const FACE_DOWN := deg_to_rad(90.0)
const LAMP_COLORS := {&"calm": Color("#ffc77a"), &"nervous": Color("#e8d08a"),
	&"smug": Color("#ffb45a"), &"angry": Color("#ff7a52")}
const LAMP_DEFAULT := Color("#ffc77a")
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
var _tallies: Array[ScoreTally] = []
var _babble: Babble
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
	bar.marker("SpeechAnchor").add_child(_speech)
	_babble = Babble.new()
	_babble.name = "RivalBabble"
	bar.marker("SpeechAnchor").add_child(_babble)
	_babble.set_voice(presenter.sin_name())
	_speech.letter_typed.connect(_babble.on_letter)
	for who in [PLAYER, DEALER]:
		var tally := ScoreTally.new()
		tally.name = "Tally" + ("Player" if who == PLAYER else "Dealer")
		tally.ps1 = ps1
		bar.marker(tally.name).add_child(tally)
		_tallies.append(tally)
	presenter.changed.connect(sync)
	sync()


## La mano se levanta cuando la cabeza mira tus cartas; si mirás para otro lado
## la bajás un poco, sin apoyarla.
func _process(_delta: float) -> void:
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
	if is_instance_valid(_speech):
		_speech.queue_free()
	for n in [_babble] + _tallies:
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
	if h != null:
		var mine: Array = h.cards[PLAYER]
		var center := bar.marker("PlayerHand").position
		if not _hand_raised:
			center += HAND_LOWERED
		for i in mine.size():
			var spot := fan(center, i, mine.size(), HAND_TILT, 0.0)
			_place(mine[i], i, false, spot[0], spot[1], _hand_raised)
			wanted[mine[i]] = true
		# El rival también las agarra en abanico, de espaldas a vos.
		var theirs: Array = h.cards[DEALER]
		for i in theirs.size():
			var spot := fan(bar.marker("DealerHand").position, i, theirs.size(), HAND_TILT, PI)
			_place(theirs[i], i, true, spot[0], spot[1], false)
			wanted[theirs[i]] = true
		for who in [PLAYER, DEALER]:
			var played: Array = h.played[who]
			for b in played.size():
				# Con la manga el rival puede jugar una cuarta carta: va encima de la tercera.
				var marker := bar.marker("Baza%d_%s" % [mini(b + 1, 3), "Player" if who == PLAYER else "Dealer"])
				var pos := marker.position + Vector3(0, 0.001 * maxi(b - 2, 0), 0)
				_place(played[b], -1, who == DEALER, pos, Vector3(FACE_UP, 0, 0), false, true)
				wanted[played[b]] = true
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
	for who in [PLAYER, DEALER]:
		_tallies[who].set_points(m.scores[who])


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
		_cards[card] = node
		if ps1:
			Ps1Material.apply(node)
	node.card_index = index
	node.hoverable = hoverable
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
	if presenter.rival_line_id != _said_id:
		_said_id = presenter.rival_line_id
		_speech.say(presenter.rival_line, presenter.rival_waiting)
	elif _speech.persistent and not presenter.rival_waiting:
		_speech.dismiss()
	var t := presenter.tell()
	var light := bar.get_node_or_null("LampLight") as Light3D
	if light != null:
		light.light_color = LAMP_COLORS.get(t.get("kind", &""), LAMP_DEFAULT)
