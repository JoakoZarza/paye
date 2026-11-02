extends GutTest
## Runs completas en la vista 3D: clics en las cartas del bar y botones encima (Plan 7, Tarea 8).

const META_PATH := "user://test_meta_full_3d.json"
const BAR := preload("res://world/bar_3d.tscn")
const RUNS := 3
const MAX_STEPS := 20000
const PRIORITY: Array[String] = ["Deck_normal", "Sit", "Skip", "Next", "Retire"]
const P := RunController.Phase


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	for c in node.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is Button and not c is OptionButton and not (c as Button).disabled:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _table_of(screen: Node) -> Table3D:
	for c in screen.get_children():
		if c is Table3D:
			return c
	return null


## Una jugada en la mesa 3D: carta con clic, o el primer botón que haya.
func _table_step(screen: Node, rng: RandomNumberGenerator) -> bool:
	var table := _table_of(screen)
	var p := table.presenter
	if p.dealer_should_play():
		screen._on_dealer_timer()
		return true
	var playable: Array[int] = []
	for i in p.hand().cards[0].size() if p.hand() != null else 0:
		if p.card_action(i) != null:
			playable.append(i)
	if not playable.is_empty() and rng.randf() < 0.8:
		table.player_card(playable[rng.randi_range(0, playable.size() - 1)]).press()
		return true
	var buttons := _buttons(screen).filter(func(b: Button) -> bool:
		return not b.name.begins_with("Acc") and not b.name.begins_with("Amulet"))
	if buttons.is_empty():
		if not playable.is_empty():
			table.player_card(playable[0]).press()
			return true
		return false
	(buttons[rng.randi_range(0, buttons.size() - 1)] as Button).pressed.emit()
	return true


func _play(seed: int) -> int:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), seed, META_PATH)
	var bar: Bar3D = BAR.instantiate()
	add_child_autofree(bar)
	var router := ScreenRouter.new()
	router.world = bar
	add_child_autofree(router)
	router.setup(rc)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in MAX_STEPS:
		if rc.state != null and rc.phase in [P.DEAD, P.RETIRED, P.CONDEMNED]:
			return rc.phase
		var screen: Node = router._screen
		if router._screen_name == &"table":
			if not _table_step(screen, rng):
				return -1
			continue
		var buttons := _buttons(screen)
		if buttons.is_empty():
			return -1
		var pick: Button = null
		for wanted in PRIORITY:
			for b in buttons:
				if b.name == wanted:
					pick = b
			if pick != null:
				break
		if pick == null:
			pick = buttons[rng.randi_range(0, buttons.size() - 1)]
		pick.pressed.emit()
	return -1


func test_runs_completas_en_3d() -> void:
	for n in RUNS:
		assert_ne(_play(500 + n), -1, "la run %d se trabó en la vista 3D" % n)
