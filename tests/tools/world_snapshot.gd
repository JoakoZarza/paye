extends SceneTree
## Captura la mesa 3D en un PNG para revisarla sin jugar.
## Uso: godot --path . -s res://tests/tools/world_snapshot.gd -- <salida.png> [ps1: 1|0] [fase: start|match|bar|shop] [vista: hand|rival|left|right|back] [puntos: 4,7] [habla: 1]

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
	if phase != "start":
		rc.start_run(&"normal")
	var flower := args.size() > 3 and args[3] == "marker"
	if phase == "match":
		if flower:
			rc.state.loadout.equip(AmuletDef.load_all()[&"marker"])
		rc.enter_match()
	elif phase == "shop":
		rc.enter_match()
		var m := rc.table().truco_match
		m.start_hand()
		m.award(0, m.target)
		rc.finish_match()
		rc.skip_one_more()
		# Algo en el guardarropas, para verlo en la captura.
		rc.meta.wardrobe = {"id": &"hat", "level": 2, "paid": 100, "fee": 15, "runs": 0}
	main.camera.mouse_look = false
	if args.size() > 4 and phase == "match":
		var pts := args[4].split(",")
		rc.table().truco_match.scores[0] = int(pts[0])
		rc.table().truco_match.scores[1] = int(pts[1])
	main.router.refresh()
	var choice := phase == "shop" and args.size() > 3 and args[3] in ["hand", "left"]
	if phase == "shop" and not choice:
		main.router.find_child("GoShop", true, false).pressed.emit()
		if args.size() > 3 and args[3] == "inspect":
			await create_timer(2.0).timeout
			for c in main.router.get_children():
				if c is BaseScreen and c.has_method("shop_items"):
					c.inspect(c.shop_items()[0])
	if flower:
		await create_timer(1.0).timeout
		for c in main.router.get_children():
			if c is BaseScreen and c.has_method("bloom"):
				c._on_amulet(&"marker", &"marker")
				(c.find_child("PickCard0", true, false) as Button).pressed.emit()
	if args.size() > 5 and args[5] == "1":
		_force_speech(main.router)
	await create_timer(1.2).timeout
	if args.size() > 3 and (phase != "shop" or choice):
		# Dónde queda el mouse para cada vista; back = mantenerlo en el borde derecho.
		var spots := {"hand": Vector2(0.5, 0.9), "rival": Vector2(0.5, 0.25), "left": Vector2(0.15, 0.4),
			"right": Vector2(0.85, 0.4), "back": Vector2(1.0, 0.45)}
		main.camera.forced_mouse = spots.get(args[3], Vector2(0.5, 0.9))
		await create_timer(3.0 if args[3] == "back" else 1.2).timeout
	for i in 5:
		await process_frame
	root.get_texture().get_image().save_png(out)
	if OS.get_environment("PAYE_DEBUG") == "1":
		for sub in root.find_children("*", "Node3D", true, false):
			if sub is Subtitle3D:
				var cam: Camera3D = main.camera
				print("SUB ", sub.name, " '", sub.text, "' vis=", sub.visible_glyphs(), "/", sub.glyph_count(),
					" pos=", sub.global_position, " behind=", cam.is_position_behind(sub.global_position),
					" px=", cam.unproject_position(sub.global_position), " in_tree=", sub.is_visible_in_tree(), " persistent=", sub.persistent, " age=", sub._age)
	quit()


## Hace que el rival murmure y cante algo, para ver los diálogos en la captura.
func _force_speech(node: Node) -> void:
	for c in node.get_children():
		if c is Table3D:
			var p: TablePresenter = (c as Table3D).presenter
			p.rival_line = "«Hmm… a ver qué sale.»"
			p.rival_line_id += 1
			p.rival_call = "¡Falta envido!"
			p.rival_call_id += 1
			p.rival_waiting = true
			(c as Table3D).sync()
			return
		_force_speech(c)
