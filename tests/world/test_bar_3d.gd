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


func test_el_rival_entero_sigue_al_pecado_y_la_version() -> void:
	var bar: Bar3D = load("res://world/bar_3d.tscn").instantiate()
	add_child_autofree(bar)
	var rival := RivalProfile.new()
	rival.sin = &"ira"
	rival.variant = &"rencor"
	bar.set_rival(rival)
	var body := bar.slot("rival")
	# Sin modelos todavía, se queda con el primer nombre y muestra el cubo.
	assert_eq(body.asset_name, "rival_ira_rencor")
	assert_false(body.has_model())
	rival.sin = &"alma"
	rival.variant = &"mudo"
	bar.set_rival(rival)
	assert_eq(body.asset_name, "rival_alma_mudo")
	assert_not_null(bar.rival_head(), "el nombre va arriba de su cabeza")
	assert_eq(bar.rival_head().get_parent(), body, "y se mueve con él")


## Un modelo de prueba con dos animaciones, guardado como escena.
func _animated_model(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var root := Node3D.new()
	root.name = "Fake"
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	var lib := AnimationLibrary.new()
	for n in ["idle", "talk"]:
		var a := Animation.new()
		a.length = 0.3
		lib.add_animation(n, a)
	player.add_animation_library("", lib)
	root.add_child(player)
	player.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, dir.path_join("fake.tscn"))
	root.free()


func test_las_animaciones_se_piden_por_nombre() -> void:
	var dir := "user://test_models"
	_animated_model(dir)
	var slot := AssetSlot.new()
	slot.models_dir = dir
	slot.model_ext = ".tscn"
	slot.asset_name = "fake"
	add_child_autofree(slot)
	assert_true(slot.has_model())
	assert_eq(slot.current_animation(), &"idle", "arranca con idle")
	assert_true(slot.play_once(&"talk"))
	assert_eq(slot.current_animation(), &"talk")
	assert_false(slot.play_once(&"win"), "una que no tiene no hace nada")
	slot.set_loop(&"think")
	assert_eq(slot.current_animation(), &"talk", "no corta la que se está haciendo")
	slot._on_anim_finished(&"talk")
	assert_eq(slot.current_animation(), &"idle", "sin think vuelve a idle")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join("fake.tscn")))
