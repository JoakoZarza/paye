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
