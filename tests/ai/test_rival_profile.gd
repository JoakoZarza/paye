extends GutTest

const LEGACY_PATH: String = "res://tests/fixtures/legacy_rivals.json"


func test_legacy_sigue_cargando() -> void:
	var rivals: Dictionary = RivalProfile.load_all(LEGACY_PATH)
	assert_true(rivals.has(&"agresivo"))
	assert_true(rivals.has(&"mentiroso"))
	assert_true(rivals.has(&"tramposo"))
	var agresivo: RivalProfile = rivals[&"agresivo"]
	var tramposo: RivalProfile = rivals[&"tramposo"]
	assert_almost_eq(agresivo.aggression, 0.85, 0.0001)
	assert_eq(tramposo.cheat_budget, 3)


func test_escalado_por_ronda() -> void:
	var rivals: Dictionary = RivalProfile.load_all(LEGACY_PATH)
	var mentiroso: RivalProfile = rivals[&"mentiroso"]
	var scaled: RivalProfile = mentiroso.scaled_for_round(5)
	assert_almost_eq(scaled.lying, 0.97, 0.0001)
	assert_eq(scaled.cheat_budget, 2)
	assert_almost_eq(mentiroso.lying, 0.85, 0.0001)
	assert_eq(mentiroso.cheat_budget, 1)


func test_escalado_tope_1() -> void:
	var rivals: Dictionary = RivalProfile.load_all(LEGACY_PATH)
	var scaled: RivalProfile = rivals[&"tramposo"].scaled_for_round(40)
	assert_true(scaled.aggression <= 1.0)
	assert_true(scaled.lying <= 1.0)
	assert_true(scaled.cheating <= 1.0)
	assert_true(scaled.stubbornness <= 1.0)
	assert_true(scaled.tell_reliability <= 1.0)


func test_catalogo_tiene_seis_pecados_almas_y_gualicho() -> void:
	var catalog: Dictionary = RivalProfile.load_catalog()
	for sin_name: StringName in [&"ira", &"gula", &"pereza", &"envidia", &"lujuria", &"soberbia"]:
		assert_eq(catalog[sin_name].size(), 3)
	assert_eq(catalog[&"alma"].size(), 4)
	assert_eq(catalog[&"gualicho"].size(), 1)


func test_valores_de_estallido() -> void:
	var profile: RivalProfile = RivalProfile.load_catalog()[&"ira"][0]
	assert_almost_eq(profile.aggression, 0.8, 0.0001)
	assert_almost_eq(profile.lying, 0.3, 0.0001)
	assert_almost_eq(profile.cheating, 0.5, 0.0001)
	assert_almost_eq(profile.stubbornness, 0.6, 0.0001)
	assert_almost_eq(profile.tell_reliability, 0.75, 0.0001)
	assert_eq(profile.cheat_budget, 2)
	assert_almost_eq(float(profile.cheat_weights["SLEEVE"]), 1.0, 0.0001)
	assert_almost_eq(profile.tilt_multiplier, 2.0, 0.0001)
	assert_eq(profile.special, &"")
	assert_eq(profile.sin, &"ira")
	assert_eq(profile.variant, &"estallido")


func test_novato_tiene_mas_ruido() -> void:
	var profile: RivalProfile = RivalProfile.load_catalog()[&"alma"][0]
	assert_almost_eq(profile.noise, 0.45, 0.0001)


func test_variacion_respeta_rango() -> void:
	var catalog: Dictionary = RivalProfile.load_catalog()
	var original: RivalProfile = catalog[&"ira"][0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for _i: int in range(1000):
		_assert_jitter_in_range(original, original.jittered(rng, 0.05))
	var mudo: RivalProfile = catalog[&"alma"][3]
	for _j: int in range(1000):
		assert_gte(mudo.jittered(rng, 0.05).aggression, 0.0)


func test_jitter_no_modifica_el_original() -> void:
	var original: RivalProfile = RivalProfile.load_catalog()[&"ira"][0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var copy: RivalProfile = original.jittered(rng, 0.05)
	assert_almost_eq(original.aggression, 0.8, 0.0001)
	assert_almost_eq(original.lying, 0.3, 0.0001)
	assert_eq(original.cheat_budget, 2)
	assert_ne(copy, original)


func _assert_jitter_in_range(original: RivalProfile, copy: RivalProfile) -> void:
	for pair: Array in [
		[original.aggression, copy.aggression],
		[original.lying, copy.lying],
		[original.cheating, copy.cheating],
		[original.stubbornness, copy.stubbornness],
		[original.tell_reliability, copy.tell_reliability],
	]:
		assert_gte(pair[1], 0.0)
		assert_lte(pair[1], 1.0)
		assert_lte(absf(pair[1] - pair[0]), 0.05 + 0.000001)
	assert_eq(copy.cheat_budget, original.cheat_budget)
