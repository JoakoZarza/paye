extends GutTest
## Atención al tanto: reclamar al que se fue sin mostrar y acordarse de mostrar el propio.

const T := TrucoAction.Type
const O := Card.Suit.ORO
const C := Card.Suit.COPA
const E := Card.Suit.ESPADA
const B := Card.Suit.BASTO


func _brain(attention: float, s: int) -> DealerBrain:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var brain := DealerBrain.new(RivalProfile.from_dict({"id": "test", "aggression": 0.5, "lying": 0.0,
		"cheating": 0.0, "stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": 0,
		"attention": attention}), rng)
	brain.start_match()
	return brain


func _cards(spec: Array) -> Array[Card]:
	var out: Array[Card] = []
	for pair in spec:
		out.append(Card.new(pair[0], pair[1]))
	return out


## El jugador 0 gana el envido con 33 y se va al mazo sin mostrar.
func _unshown_mazo() -> TrucoHand:
	var h := TrucoHand.new([_cards([[O, 7], [O, 6], [C, 4]]), _cards([[E, 4], [B, 5], [C, 6]])], 0, 15)
	h.apply(TrucoAction.make(T.ENVIDO, 0))
	h.apply(TrucoAction.make(T.QUIERO, 1))
	h.apply(TrucoAction.make(T.DECLARE_TANTO, 0, -1, 33))
	h.apply(TrucoAction.make(T.SON_BUENAS, 1))
	h.apply(TrucoAction.make(T.MAZO, 0))
	return h


func _claims(attention: float) -> int:
	var brain := _brain(attention, 5)
	var claims := 0
	for i in 400:
		if brain.choose(HandView.new(_unshown_mazo(), 1)).type == T.DEMAND_SHOW:
			claims += 1
	return claims


func test_reclama_segun_su_atencion() -> void:
	assert_eq(_claims(1.0), 400)
	assert_eq(_claims(0.0), 0)
	assert_almost_eq(float(_claims(0.5)), 200.0, 40.0)


func test_atencion_por_defecto_y_en_el_catalogo() -> void:
	assert_almost_eq(RivalProfile.from_dict({}).attention, 0.5, 0.0001)
	var catalog := RivalProfile.load_catalog()
	assert_gt(catalog[&"envidia"][0].attention, catalog[&"pereza"][0].attention)


func test_con_atencion_baja_a_veces_se_olvida_de_mostrar() -> void:
	var forgot := 0
	for s in 200:
		var brain := _brain(0.0, s)
		# El dealer (1) gana el envido con 33 y le conviene irse.
		var h := TrucoHand.new([_cards([[E, 1], [B, 1], [E, 7]]), _cards([[O, 7], [O, 6], [C, 4]])], 0, 15)
		h.apply(TrucoAction.make(T.ENVIDO, 0))
		h.apply(TrucoAction.make(T.QUIERO, 1))
		h.apply(TrucoAction.make(T.DECLARE_TANTO, 0, -1, 0))
		h.apply(TrucoAction.make(T.DECLARE_TANTO, 1, -1, 33))
		var a := brain._fold(HandView.new(h, 1), 1, [TrucoAction.make(T.SHOW_TANTO, 1), TrucoAction.make(T.MAZO, 1)])
		if a.type == T.MAZO:
			forgot += 1
	assert_almost_eq(float(forgot), 100.0, 30.0, "atención 0: se olvida la mitad de las veces")
