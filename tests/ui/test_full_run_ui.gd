extends GutTest
## Runs completas por las pantallas, apretando botones (Plan 6, Tarea 6).

const META_PATH := "user://test_meta_full_ui.json"
const RUNS := 8
const MAX_PRESSES := 20000
const PRIORITY: Array[String] = ["Deck_normal", "Sit", "Skip", "Next", "Retire"]
const P := RunController.Phase

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


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


func _by_name(buttons: Array[Button], wanted: String) -> Button:
	for b in buttons:
		if b.name == wanted:
			return b
	return null


## Devuelve la fase en la que terminó, o -1 si se trabó.
## final: empieza directo en la Soberbia con plata de sobra, para llegar a la cuenta.
## smart: en la mesa elige como un jugador IA medio y aprieta el botón que corresponde.
func _play(seed: int, final := false, smart: DealerBrain = null) -> int:
	var rc := RunController.new(_economy, MetaState.new(), seed, META_PATH)
	if final:
		rc.start_run(&"normal")
		rc.state.round = 9
		rc.state.money = 20000
		rc.state.fiado = 15000
	var router := ScreenRouter.new()
	add_child_autofree(router)
	router.setup(rc)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in MAX_PRESSES:
		if rc.state != null and rc.phase in [P.DEAD, P.RETIRED, P.CONDEMNED]:
			return rc.phase
		var screen: Node = router._screen
		if router._screen_name == &"table" and rc.table().is_dealer_turn() and not screen._hand_finished():
			screen._on_dealer_timer()
			continue
		var buttons := _buttons(screen)
		if buttons.is_empty():
			return -1
		var pick: Button = null
		if router._screen_name == &"shop" and rng.randf() < 0.5:
			pick = _by_name(buttons, "Buy0")
		if pick == null and router._screen_name != &"table":
			for wanted in PRIORITY:
				pick = _by_name(buttons, wanted)
				if pick != null:
					break
		if pick == null and smart != null and router._screen_name == &"table":
			pick = _smart_button(screen, smart, buttons)
		if pick == null:
			var playable := buttons.filter(func(b: Button) -> bool:
				return not b.name.begins_with("Acc") and not b.name.begins_with("Amulet"))
			if playable.is_empty():
				playable = buttons
			pick = playable[rng.randi_range(0, playable.size() - 1)]
		pick.pressed.emit()
	return -1


func test_runs_completas_por_las_pantallas() -> void:
	var endings := {}
	for n in RUNS:
		var end := _play(100 + n)
		assert_ne(end, -1, "la run %d se trabó en las pantallas" % n)
		endings[end] = endings.get(end, 0) + 1
	gut.p("finales por las pantallas: %s" % str(endings))


func test_la_final_y_la_cuenta_por_las_pantallas() -> void:
	var endings := {}
	for n in 30:
		var end := _play(300 + n, true, _player_brain(900 + n))
		assert_ne(end, -1, "la final %d se trabó en las pantallas" % n)
		endings[end] = endings.get(end, 0) + 1
	assert_true(endings.has(P.RETIRED), "ninguna llegó a retirarse: %s" % str(endings))
	gut.p("finales desde la Soberbia: %s" % str(endings))


func _player_brain(seed: int) -> DealerBrain:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var brain := DealerBrain.new(RivalProfile.from_dict({"id": "jugador", "aggression": 0.5, "lying": 0.3,
		"cheating": 0.0, "stubbornness": 0.5, "tell_reliability": 0.5, "cheat_budget": 0}), rng)
	brain.start_match()
	return brain


func _smart_button(screen: Node, brain: DealerBrain, buttons: Array[Button]) -> Button:
	var cont := _by_name(buttons, "Continue")
	if cont != null:
		return cont
	var hand: TrucoHand = screen.rc.table().truco_match.hand
	var a := brain.choose(HandView.new(hand, 0))
	match a.type:
		TrucoAction.Type.PLAY_CARD:
			return _by_name(buttons, "Card%d" % a.card_index)
		TrucoAction.Type.DECLARE_TANTO:
			var picker: OptionButton = screen.find_child("TantoPicker", true, false)
			picker.select(picker.get_item_index(a.value))
			return _by_name(buttons, "Declare")
	return _by_name(buttons, "Act_%s" % TrucoAction.Type.keys()[a.type])