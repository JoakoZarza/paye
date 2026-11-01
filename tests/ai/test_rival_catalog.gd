extends GutTest

var _catalog: Dictionary


func before_all() -> void:
	_catalog = RivalProfile.load_catalog()


func _make(seed: int) -> RivalCatalog:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return RivalCatalog.new(_catalog, rng)


func test_orden_de_pecados() -> void:
	var c := _make(1)
	assert_eq(c.rounds(), 9)
	for r in range(1, 10):
		assert_eq(c.rival_for(r).sin, RivalCatalog.RUN_ORDER[r - 1])
	assert_eq(c.gualicho().sin, &"gualicho")


func test_almas_no_se_repiten() -> void:
	for seed in 100:
		var c := _make(seed)
		var seen: Dictionary = {}
		for r in [2, 5, 8]:
			var alma := c.rival_for(r)
			assert_false(seen.has(alma.variant), "alma repetida con semilla %d" % seed)
			seen[alma.variant] = true


func test_misma_semilla_misma_run() -> void:
	var a := _make(42)
	var b := _make(42)
	for r in range(1, 10):
		var pa := a.rival_for(r)
		var pb := b.rival_for(r)
		assert_eq(pa.variant, pb.variant)
		assert_eq(pa.aggression, pb.aggression)
		assert_eq(pa.lying, pb.lying)
		assert_eq(pa.tell_reliability, pb.tell_reliability)


func test_semillas_distintas_cambian_versiones() -> void:
	var seen: Dictionary = {}
	var aggressions: Dictionary = {}
	for seed in 50:
		var c := _make(seed)
		for r in range(1, 10):
			var p := c.rival_for(r)
			if p.sin == &"alma":
				continue
			if not seen.has(p.sin):
				seen[p.sin] = {}
			seen[p.sin][p.variant] = true
		aggressions[c.rival_for(1).aggression] = true
	for sin in [&"ira", &"gula", &"pereza", &"envidia", &"lujuria", &"soberbia"]:
		assert_eq((seen[sin] as Dictionary).size(), 3, "faltan versiones de %s" % sin)
	assert_gt(aggressions.size(), 1)


func test_variacion_aplicada_y_original_intacto() -> void:
	var c := _make(3)
	var p := c.rival_for(1)
	var base: RivalProfile
	for v: RivalProfile in _catalog[&"ira"]:
		if v.variant == p.variant:
			base = v
	assert_almost_eq(p.aggression, base.aggression, RivalCatalog.JITTER + 0.000001)
	assert_eq(p.cheat_budget, base.cheat_budget)
	assert_ne(p, base)


func test_rival_for_fuera_de_rango_falla() -> void:
	var c := _make(1)
	assert_null(c.rival_for(0))
	assert_null(c.rival_for(10))
