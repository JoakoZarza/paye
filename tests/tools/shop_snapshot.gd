extends SceneTree
## Captura la tienda en un PNG para revisarla sin jugar.
## Uso: godot --path . -s res://tests/tools/shop_snapshot.gd -- <salida.png>


func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://shop.png"
	root.size = Vector2i(1280, 720)
	root.theme = load("res://ui/theme.tres")
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var rc := RunController.new(Economy.load_from(), MetaState.new(), 4, "user://snapshot_meta.json")
	rc.start_run(&"normal")
	rc.state.round = 3
	rc.state.money = 2000
	rc.phase = RunController.Phase.SHOP
	rc.shop.open(rc.state)
	var screen: BaseScreen = load("res://ui/screens/shop_screen.tscn").instantiate()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)
	screen.acted.connect(screen.refresh)
	screen.setup(rc)
	screen._buy(0)
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png(out)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://snapshot_meta.json"))
	quit()
