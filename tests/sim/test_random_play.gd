extends GutTest
## Juega 10.000 manos eligiendo acciones legales al azar y verifica invariantes.

const TOTAL_HANDS := 10000
const MAX_ACTIONS_PER_HAND := 60
const SEED := 42


func test_diez_mil_manos_al_azar() -> void:
	var picker := RandomNumberGenerator.new()
	picker.seed = SEED
	var deal_rng := RandomNumberGenerator.new()
	deal_rng.seed = SEED
	var hands := 0
	var failures := 0
	while hands < TOTAL_HANDS and failures == 0:
		var target := 15 if hands % 2 == 0 else 30
		var m := TrucoMatch.new(target, deal_rng)
		while m.winner() == -1 and hands < TOTAL_HANDS and failures == 0:
			failures += _play_hand(m, picker, hands)
			hands += 1
	assert_eq(failures, 0)
	assert_eq(hands, TOTAL_HANDS)


## Devuelve 1 si alguna invariante falló, 0 si la mano fue correcta.
func _play_hand(m: TrucoMatch, picker: RandomNumberGenerator, n: int) -> int:
	m.start_hand()
	var falta := m.falta_points()
	var before := m.scores.duplicate()
	var seen := {}
	var actions := 0
	while not m.hand.is_over():
		var legal := m.hand.legal_actions()
		if legal.is_empty():
			fail_test("mano %d (semilla %d): sin acciones legales en fase %d" % [n, SEED, m.hand.phase])
			return 1
		var a: TrucoAction = legal[picker.randi_range(0, legal.size() - 1)]
		for e in m.apply(a):
			if e.type == &"illegal_action":
				fail_test("mano %d (semilla %d): acción legal rechazada" % [n, SEED])
				return 1
			if e.type == &"card_played":
				var key: String = e.data["card"].key()
				if seen.has(key):
					fail_test("mano %d (semilla %d): carta %s jugada dos veces" % [n, SEED, key])
					return 1
				seen[key] = true
		actions += 1
		if actions > MAX_ACTIONS_PER_HAND:
			fail_test("mano %d (semilla %d): más de %d acciones" % [n, SEED, MAX_ACTIONS_PER_HAND])
			return 1
	var gained: int = (m.scores[0] - before[0]) + (m.scores[1] - before[1])
	# Truco máximo + envido máximo (envido-envido-real = 7, o la falta) + multa.
	var cap := 4 + maxi(7, falta) + TrucoHand.LIE_PENALTY
	# Al llegar al objetivo los puntos se recortan, por eso solo exige >= 1 si nadie ganó.
	if gained > cap or (gained < 1 and m.winner() == -1):
		fail_test("mano %d (semilla %d): puntos fuera de rango (%d)" % [n, SEED, gained])
		return 1
	return 0
