extends GutTest

const RunDeck = preload("res://core/run/run_deck.gd")
const TableRules = preload("res://core/amulets/table_rules.gd")

func test_carga_normal_y_viuda() -> void:
	var decks: Dictionary = RunDeck.load_all()
	assert_eq(decks.size(), 2)
	var normal: RunDeck = decks[&"normal"]
	var widow: RunDeck = decks[&"widow"]
	assert_eq(normal.prize_multiplier, 1.0)
	assert_eq(normal.dealer_budget_multiplier, 1)
	assert_eq(normal.name_key, &"DECK_NORMAL_NAME")
	assert_eq(widow.prize_multiplier, 2.0)
	assert_eq(widow.dealer_budget_multiplier, 2)
	assert_eq(widow.desc_key, &"DECK_WIDOW_DESC")


func test_viuda_aplica_a_las_reglas() -> void:
	var decks: Dictionary = RunDeck.load_all()
	var rules := TableRules.new()
	decks[&"widow"].apply_to(rules)
	assert_eq(rules.dealer_budget_multiplier, 2)


func test_viuda_con_presupuesto_cero() -> void:
	var p := RivalProfile.from_dict({"id": "t", "aggression": 0.5, "lying": 0.5, "cheating": 1.0, "stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": 0})
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var t := CheatTable.new(TrucoMatch.new(15, rng), DealerBrain.new(p, rng), 1, rng)
	RunDeck.load_all()[&"widow"].apply_to(t.rules)
	t.start_match()
	assert_eq(t.brain.cheat_budget, 0)
