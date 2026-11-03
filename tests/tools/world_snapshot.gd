extends SceneTree
## Captura la mesa 3D en un PNG para revisarla sin jugar.
## Uso: godot --path . -s res://tests/tools/world_snapshot.gd -- <salida.png> [ps1: 1|0] [fase: match|bar] [vista: hand|rival|left|right|back]

const MAIN := "res://ui/main.tscn"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://world.png"
	var ps1 := args.size() < 2 or args[1] != "0"
	var phase := "match" if args.size() < 3 else args[2]
	root.size = Vector2i(1280, 720)
	root.theme = load("res://ui/theme.tres")
	var main := Control.new()
	main.set_script(load("res://ui/main.gd"))
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# main._ready lee data/ui.json; para la captura forzamos 3D.
	main.set_meta("force_view", {"view": "3d", "ps1": ps1})
	root.add_child(main)
	await process_frame
	var rc: RunController = main.rc
	rc.start_run(&"normal")
	if phase == "match":
		rc.enter_match()
	main.camera.mouse_look = false
	main.router.refresh()
	await create_timer(1.2).timeout
	if args.size() > 3:
		# Dónde queda el mouse para cada vista; back = mantenerlo en el borde derecho.
		var spots := {"hand": Vector2(0.5, 0.9), "rival": Vector2(0.5, 0.25), "left": Vector2(0.15, 0.4),
			"right": Vector2(0.85, 0.4), "back": Vector2(1.0, 0.45)}
		main.camera.forced_mouse = spots.get(args[3], Vector2(0.5, 0.9))
		await create_timer(3.0 if args[3] == "back" else 1.2).timeout
	for i in 5:
		await process_frame
	root.get_texture().get_image().save_png(out)
	quit()
