extends GutTest
## Runs completas en la vista 3D, apretando lo que hay en el mundo: cartas, cantos,
## carteles del bar, el mantel de la tienda y el guardarropas. Atrapa pantallas sin
## salida y una cámara que no vuelve a moverse.

const META_PATH := "user://test_meta_full_3d.json"
const BAR := preload("res://world/bar_3d.tscn")
const RUNS := 4
const MAX_STEPS := 20000
const P := RunController.Phase
const SKIP_PREFIX: Array[String] = ["Acc", "Amulet", "Cancel"]

var _economy: Economy
var _animate_was := true
var _screens_seen := {}


func before_all() -> void:
	_economy = Economy.load_from()
	_animate_was = Table3D.animate_deals
	Table3D.animate_deals = false


func after_all() -> void:
	Table3D.animate_deals = _animate_was


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is Button and not (c as Button).disabled:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _named(buttons: Array[Button], wanted: String) -> Button:
	for b in buttons:
		if b.name == wanted:
			return b
	return null


func _table3d(screen: Node) -> Table3D:
	for c in screen.get_children():
		if c is Table3D:
			return c
	return null


## Devuelve la fase en la que terminó, o -1 si se trabó.
func _play(seed: int, meta := MetaState.new()) -> int:
	var rc := RunController.new(_economy, meta, seed, META_PATH)
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var cam := CameraRig.new()
	cam.mouse_look = false
	bar.add_child(cam)
	cam.setup(bar)
	bar.camera = cam
	var router := ScreenRouter.new()
	router.world = bar
	add_child_autofree(router)
	router.setup(rc)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var last_screen := &""
	for i in MAX_STEPS:
		if rc.state != null and rc.phase in [P.DEAD, P.RETIRED, P.CONDEMNED]:
			return rc.phase
		cam.go_to(router.camera_marker(), true)
		var screen: Node = router._screen
		if router._screen_name != last_screen:
			last_screen = router._screen_name
			_screens_seen[last_screen] = int(_screens_seen.get(last_screen, 0)) + 1
			if last_screen != &"table":
				assert_false(cam.ui_hold, "la cámara quedó trabada al entrar a %s" % last_screen)
			elif rc.phase == P.MATCH:
				# Ventaja para llegar a la tienda: el azar casi nunca le gana a la IA.
				var m := rc.table().truco_match
				m.scores[0] = maxi(m.scores[0], m.target - 2)
		if router._screen_name == &"table":
			if not _table_step(screen, rng):
				return -1
			continue
		var buttons := _buttons(screen)
		if buttons.is_empty():
			return -1
		var pick := _pick_outside(router, screen, buttons, rng)
		pick.pressed.emit()
	return -1


## Bar, tienda y demás: lo importante primero, a veces probar la tienda y el guardarropas.
func _pick_outside(router: ScreenRouter, screen: Node, buttons: Array[Button], rng: RandomNumberGenerator) -> Button:
	if router._screen_name == &"shop":
		var go := _named(buttons, "GoShop")
		if go != null:
			return go if rng.randf() < 0.8 else _named(buttons, "Stay")
		if screen.inspected() == null and rng.randf() < 0.5 and not screen.shop_items().is_empty():
			var items: Array = screen.shop_items()
			screen.inspect(items[rng.randi_range(0, items.size() - 1)])
			buttons = _buttons(screen)
		var details := buttons.filter(func(b: Button) -> bool:
			return b.name.begins_with("Buy") or b.name.begins_with("Store") or b.name == "Retrieve")
		if not details.is_empty() and rng.randf() < 0.7:
			return details[rng.randi_range(0, details.size() - 1)]
		var close := _named(buttons, "CloseDetails")
		if close != null:
			return close
	for wanted in ["Deck_normal", "Sit", "Skip", "Next", "Retire"]:
		var b := _named(buttons, wanted)
		if b != null:
			return b
	return buttons[rng.randi_range(0, buttons.size() - 1)]


## Un paso en la mesa: el rival, mostrar, una carta tuya o un canto.
func _table_step(screen: Node, rng: RandomNumberGenerator) -> bool:
	var table := _table3d(screen)
	if table == null:
		return false
	var p := table.presenter
	if p.dealer_should_play() and not screen._hand_finished():
		screen._on_dealer_timer()
		return true
	if p.in_show_decision():
		var cont := screen.find_child("Continue", true, false) as Button
		if cont == null:
			return false
		cont.pressed.emit()
		return true
	var playable: Array[int] = []
	if not p.hand_finished():
		for idx in p.hand().cards[0].size():
			if p.card_action(idx) != null:
				playable.append(idx)
	var buttons := _buttons(screen).filter(func(b: Button) -> bool:
		for prefix in SKIP_PREFIX:
			if b.name.begins_with(prefix):
				return false
		return true)
	if not playable.is_empty() and (buttons.is_empty() or rng.randf() < 0.6):
		table.player_card(playable[rng.randi_range(0, playable.size() - 1)]).press()
		return true
	if buttons.is_empty():
		return false
	(buttons[rng.randi_range(0, buttons.size() - 1)] as Button).pressed.emit()
	return true


func test_runs_completas_en_3d() -> void:
	var endings := {}
	for n in RUNS:
		var end := _play(500 + n)
		assert_ne(end, -1, "la run 3D %d se trabó" % n)
		endings[end] = endings.get(end, 0) + 1
	gut.p("finales en 3D: %s, pantallas: %s" % [str(endings), str(_screens_seen)])
	assert_true(_screens_seen.has(&"shop"), "alguna run llegó a la tienda")


func test_run_3d_con_algo_en_el_guardarropas() -> void:
	var meta := MetaState.new()
	meta.wardrobe = {"id": &"hat", "level": 2, "paid": 120, "fee": 0, "runs": 0}
	assert_ne(_play(777, meta), -1, "la run con guardarropas se trabó")
