extends GutTest
## Partidos completos con amuletos: un jugador al azar que usa amuletos al azar
## (invariantes) y un jugador con reglas simples, con y sin amuletos (efecto).

const SEED := 21
const MATCHES := 300
const USE_CHANCE := 0.2
const MAX_STEPS_PER_HAND := 80
const ALL_IDS: Array[StringName] = [&"marker", &"spare_deck", &"cigarette", &"cana_glass", &"rosary", &"facon",
	&"glasses", &"hat", &"mirror", &"marked_cards", &"red_ribbon", &"train_coin"]
const T := TrucoAction.Type

var _defs: Dictionary
var _profiles: Dictionary
var _approved_but_illegal := 0
var _long_hands := 0
var _repeated_cards := 0
var _negative_charges := 0


func before_all() -> void:
	_defs = AmuletDef.load_all()
	_profiles = RivalProfile.load_all()


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _system(rival: StringName, ids: Array, s: int) -> AmuletSystem:
	var loadout := Loadout.new()
	for id in ids:
		loadout.equip(_defs[id])
	var table := CheatTable.new(TrucoMatch.new(15, _rng(s)), DealerBrain.new(_profiles[rival], _rng(s + 1)), 1, _rng(s + 2))
	var sys := AmuletSystem.new(table, loadout, _rng(s + 3))
	sys.start_match()
	return sys


## Juega un partido; `player_turn` decide y aplica una acción del jugador.
func _play(sys: AmuletSystem, player_turn: Callable) -> int:
	var t := sys.table
	while t.truco_match.winner() == -1:
		sys.start_hand()
		var steps := 0
		while not t.truco_match.hand.is_over() and t.truco_match.winner() == -1:
			steps += 1
			if steps > MAX_STEPS_PER_HAND:
				_long_hands += 1
				return -1
			if t.is_dealer_turn():
				t.dealer_step()
			else:
				player_turn.call(sys)
			_check_cards(t)
		for def in sys.loadout.equipped():
			if sys.loadout.charges_left(def.id) < 0:
				_negative_charges += 1
	return t.truco_match.winner()


## Ninguna carta base aparece dos veces en la mesa, salvo la copia de la duplicada.
func _check_cards(t: CheatTable) -> void:
	var seen := {}
	for p in 2:
		for c in t.truco_match.hand.cards[p] + t.truco_match.hand.played[p]:
			var k: String = c.key()
			if seen.has(k):
				var dup := t.active_cheat != null and t.active_cheat.kind == Cheat.Kind.DUPLICATE and t.active_cheat.card_key == k
				if not dup:
					_repeated_cards += 1
			seen[k] = true


func _random_player(picker: RandomNumberGenerator) -> Callable:
	return func(sys: AmuletSystem) -> void:
		if picker.randf() < USE_CHANCE:
			var defs := sys.loadout.equipped()
			var def: AmuletDef = defs[picker.randi_range(0, defs.size() - 1)]
			if sys.can_use(def.id):
				var events := sys.use(def.id, _random_args(sys, def.id, picker))
				if events[0].type == &"illegal_action" and not def.id in [&"marker"]:
					_approved_but_illegal += 1
				return
		var legal := sys.table.truco_match.hand.legal_actions()
		sys.table.player_action(legal[picker.randi_range(0, legal.size() - 1)])


func _random_args(sys: AmuletSystem, id: StringName, picker: RandomNumberGenerator) -> Dictionary:
	var n: int = sys.table.truco_match.hand.cards[0].size()
	if id == &"marker":
		return {"card_index": picker.randi_range(0, n - 1), "number": Card.VALID_NUMBERS[picker.randi_range(0, 9)]}
	if id == &"spare_deck":
		return {"card_index": picker.randi_range(0, n - 1)}
	return {}


## Reglas simples: mejora la carta más baja con el marcador o el mazo aparte,
## canta truco con buena mano (con facón si lo tiene), anula los cantos del
## dealer con el rosario, quiere con buena mano y juega la carta más alta.
func _simple_player(sys: AmuletSystem) -> void:
	var hand := sys.table.truco_match.hand
	var mine: Array = hand.cards[0]
	var lowest := 0
	var best := 0
	for i in mine.size():
		if mine[i].truco_rank() < mine[lowest].truco_rank():
			lowest = i
		best = maxi(best, mine[i].truco_rank())
	if hand.phase == TrucoHand.Phase.PLAYING:
		if sys.can_use(&"marker") and hand.can_mark(0, lowest, 3):
			sys.use(&"marker", {"card_index": lowest, "number": 3})
			return
		if sys.can_use(&"spare_deck") and mine[lowest].truco_rank() < 5:
			sys.use(&"spare_deck", {"card_index": lowest})
			return
	if sys.can_use(&"rosary") and best < 10:
		sys.use(&"rosary")
		return
	var legal := hand.legal_actions()
	var pick := func(type: T) -> TrucoAction:
		for a in legal:
			if a.type == type:
				return a
		return null
	match hand.phase:
		TrucoHand.Phase.PLAYING:
			if best >= 12 and pick.call(T.TRUCO) != null:
				if sys.can_use(&"facon"):
					sys.use(&"facon")
				sys.table.player_action(pick.call(T.TRUCO))
				return
			var top := 0
			for i in mine.size():
				if mine[i].truco_rank() > mine[top].truco_rank():
					top = i
			sys.table.player_action(TrucoAction.make(T.PLAY_CARD, 0, top))
		TrucoHand.Phase.TANTO_DECLARATION:
			var v := hand.own_tanto(0)
			var a: TrucoAction = TrucoAction.make(T.DECLARE_TANTO, 0, -1, v)
			sys.table.player_action(a if _legal(legal, a) else legal[0])
		TrucoHand.Phase.SHOW_DECISION:
			sys.table.player_action(pick.call(T.ACCEPT_TANTO))
		_:
			sys.table.player_action(pick.call(T.QUIERO) if best >= 10 else pick.call(T.NO_QUIERO))


func _legal(legal: Array[TrucoAction], a: TrucoAction) -> bool:
	return legal.any(func(l: TrucoAction) -> bool: return l.equals(a))


func test_amuletos_al_azar_no_rompen_nada() -> void:
	for rival in [&"agresivo", &"mentiroso", &"tramposo"]:
		for n in MATCHES:
			var picker := _rng(SEED * 7 + n)
			var ids: Array = ALL_IDS.duplicate()
			# Cuatro amuletos al azar, siempre con al menos un activo.
			var chosen: Array = []
			while chosen.size() < Loadout.SLOTS:
				var id: StringName = ids.pop_at(picker.randi_range(0, ids.size() - 1))
				chosen.append(id)
			_play(_system(rival, chosen, SEED * 1000 + n), _random_player(picker))
	assert_eq(_approved_but_illegal, 0)
	assert_eq(_long_hands, 0)
	assert_eq(_repeated_cards, 0)


func test_cargas_nunca_negativas() -> void:
	assert_eq(_negative_charges, 0)


func test_amuletos_ayudan() -> void:
	var with := 0
	var without := 0
	var kit := [&"marker", &"spare_deck", &"rosary", &"facon"]
	for n in MATCHES:
		if _play(_system(&"agresivo", kit, SEED + n), _simple_player) == 0:
			with += 1
		if _play(_system(&"agresivo", [], SEED + n), _simple_player) == 0:
			without += 1
	gut.p("jugador simple contra agresivo: con amuletos %.2f, sin amuletos %.2f" % [float(with) / MATCHES, float(without) / MATCHES])
	assert_gt(with, without)
