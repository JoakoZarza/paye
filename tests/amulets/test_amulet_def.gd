extends GutTest

const AmuletDef = preload("res://core/amulets/amulet_def.gd")

func test_carga_los_doce() -> void:
	var amulets: Dictionary = AmuletDef.load_all()
	assert_eq(amulets.size(), 12)
	assert_true(amulets.has(&"marker"))


func test_valores_del_marcador() -> void:
	var amulets: Dictionary = AmuletDef.load_all()
	var marker: AmuletDef = amulets[&"marker"]
	assert_eq(marker.rarity, AmuletDef.Rarity.RARE)
	assert_eq(marker.kind, AmuletDef.Kind.ACTIVE)
	assert_eq(marker.charges, 1)
	assert_eq(marker.name_key, &"AMULET_MARKER_NAME")


func test_pasivos_tienen_cero_cargas() -> void:
	var amulets: Dictionary = AmuletDef.load_all()
	for amulet_id: Variant in amulets:
		var amulet: AmuletDef = amulets[amulet_id]
		if amulet.kind == AmuletDef.Kind.PASSIVE:
			assert_eq(amulet.charges, 0)


func test_niveles_y_fallback_de_valores() -> void:
	var amulets: Dictionary = AmuletDef.load_all()
	var ribbon: AmuletDef = amulets[&"red_ribbon"]
	assert_eq(ribbon.value("price_multiplier", 3), 0.6)
	assert_eq(ribbon.value("price_multiplier", 2), 0.7)
	assert_eq(ribbon.value("missing", 3, "default"), "default")
	var marker: AmuletDef = amulets[&"marker"]
	assert_eq(marker.value("change_suit", 1), false)
	assert_eq(marker.value("change_suit", 3), true)
	assert_eq(marker.value("charges", 9), 1)
	for amulet_id: Variant in amulets:
		var amulet: AmuletDef = amulets[amulet_id]
		assert_eq(amulet.levels.size(), 3, "%s debe tener tres niveles" % amulet_id)
