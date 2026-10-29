extends GutTest


func test_carga_los_tres_rivales() -> void:
	var rivals: Dictionary = RivalProfile.load_all()
	assert_true(rivals.has(&"agresivo"))
	assert_true(rivals.has(&"mentiroso"))
	assert_true(rivals.has(&"tramposo"))
	var agresivo: RivalProfile = rivals[&"agresivo"]
	var tramposo: RivalProfile = rivals[&"tramposo"]
	assert_almost_eq(agresivo.aggression, 0.85, 0.0001)
	assert_eq(tramposo.cheat_budget, 3)


func test_escalado_por_ronda() -> void:
	var rivals: Dictionary = RivalProfile.load_all()
	var mentiroso: RivalProfile = rivals[&"mentiroso"]
	var scaled: RivalProfile = mentiroso.scaled_for_round(5)
	assert_almost_eq(scaled.lying, 0.97, 0.0001)
	assert_eq(scaled.cheat_budget, 2)
	assert_almost_eq(mentiroso.lying, 0.85, 0.0001)
	assert_eq(mentiroso.cheat_budget, 1)


func test_escalado_tope_1() -> void:
	var rivals: Dictionary = RivalProfile.load_all()
	var scaled: RivalProfile = rivals[&"tramposo"].scaled_for_round(40)
	assert_true(scaled.aggression <= 1.0)
	assert_true(scaled.lying <= 1.0)
	assert_true(scaled.cheating <= 1.0)
	assert_true(scaled.stubbornness <= 1.0)
	assert_true(scaled.tell_reliability <= 1.0)
