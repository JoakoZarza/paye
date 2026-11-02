extends GutTest


func test_escena_construye_huecos_y_marcadores() -> void:
	var bar := load("res://world/bar_3d.tscn").instantiate() as Bar3D
	add_child_autofree(bar)
	await get_tree().process_frame
	assert_eq(bar.get_child_count() >= 20, true)
	for asset_name: String in Bar3D.SLOT_NAMES:
		assert_not_null(bar.slot(asset_name), "Falta el hueco %s" % asset_name)
		assert_false(bar.slot(asset_name).has_model(), "No se esperaba modelo para %s" % asset_name)
	for marker_name: String in Bar3D.MARKER_POSITIONS:
		assert_not_null(bar.marker(marker_name), "Falta el marcador %s" % marker_name)
	assert_not_null(bar.get_node_or_null("LampLight"))
	assert_not_null(bar.get_node_or_null("WorldEnvironment"))
