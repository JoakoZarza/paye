extends GutTest

const H := preload("res://tests/cheats/cheat_test_helpers.gd")

var _economy: Economy
var _decks: Dictionary
var _defs: Dictionary


func before_all() -> void:
	_economy = Economy.load_from()
	_decks = RunDeck.load_all()
	_defs = AmuletDef.load_all()


func _loadout(ids: Array = []) -> Loadout:
	var l := Loadout.new()
	for id in ids:
		l.equip(_defs[StringName(id)])
	return l


func _sources(r: Dictionary) -> Array:
	return r["multipliers"].map(func(m: Dictionary) -> StringName: return m["source"])


func test_sin_multiplicadores() -> void:
	var r := Prize.compute(600, 5, 0, 0, true, _loadout(), _decks[&"normal"], _economy)
	assert_eq(r["total"], 600)
	assert_eq(r["multipliers"].size(), 0)


func test_partido_perfecto_duplica() -> void:
	var r := Prize.compute(600, 0, 0, 0, true, _loadout(), _decks[&"normal"], _economy)
	assert_eq(r["total"], 1200)
	assert_eq(_sources(r), [&"flawless"])


func test_trampa_no_detectada() -> void:
	var r := Prize.compute(600, 5, 2, 0, true, _loadout(), _decks[&"normal"], _economy)
	assert_eq(r["total"], 900)
	assert_eq(_sources(r), [&"undetected_cheat"])


func test_trampa_pescada_no_cuenta() -> void:
	var r := Prize.compute(600, 5, 2, 1, true, _loadout(), _decks[&"normal"], _economy)
	assert_eq(r["total"], 600)


func test_se_multiplican_entre_si() -> void:
	var r := Prize.compute(600, 0, 0, 0, false, _loadout(["train_coin"]), _decks[&"widow"], _economy)
	assert_eq(r["total"], 3600)
	assert_eq(_sources(r), [&"flawless", &"train_coin", &"deck"])


func test_mesa_cuenta_trampas_del_jugador() -> void:
	var t := H.table(H.profile(0.0, 0))
	t.start_hand(-1, [H.cards([[H.E, 4], [H.B, 5], [H.C, 6]]), H.cards([[H.O, 7], [H.E, 1], [H.C, 4]])], 0)
	var events := t.use_player_cheat(CheatTable.PlayerCheat.MARKED)
	assert_eq(t.player_cheats_used, 1)
	assert_eq(t.player_cheats_caught, 1 if events[0].type == &"player_caught" else 0)
	t.start_match()
	assert_eq(t.player_cheats_used, 0)
