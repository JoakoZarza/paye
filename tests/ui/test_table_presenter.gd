extends GutTest
## El presentador alcanza para jugar la mesa sin ninguna vista (Plan 7, Tarea 1).

const META_PATH := "user://test_meta_presenter.json"
const MAX_STEPS := 3000


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))


func _presenter(seed := 4) -> TablePresenter:
	var rc := RunController.new(Economy.load_from(), MetaState.new(), seed, META_PATH)
	rc.start_run(&"normal")
	rc.enter_match()
	var p := TablePresenter.new(rc)
	p.start()
	return p


## Juega con la primera opción que haya: carta, canto o declarar.
func _step(p: TablePresenter, rng: RandomNumberGenerator) -> void:
	if p.dealer_should_play():
		p.dealer_step()
		return
	if p.in_show_decision():
		p.accept_and_continue()
		return
	var cards := range(p.hand().cards[0].size()).filter(func(i: int) -> bool: return p.card_action(i) != null)
	if not cards.is_empty():
		p.act(p.card_action(cards[rng.randi_range(0, cards.size() - 1)]))
		return
	var values := p.tanto_values()
	if not values.is_empty():
		p.declare(values[0])
		return
	var calls := p.call_buttons()
	if not calls.is_empty():
		p.act(calls[rng.randi_range(0, calls.size() - 1)]["action"])


func test_se_juega_un_partido_entero_solo_con_el_presentador() -> void:
	var p := _presenter()
	var left := [false]
	p.left_table.connect(func() -> void: left[0] = true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in MAX_STEPS:
		if left[0]:
			break
		if p.hand_finished():
			p.continue_hand()
			continue
		_step(p, rng)
	assert_true(left[0], "el partido terminó y el presentador avisó que se deja la mesa")
	assert_ne(p.rc.phase, RunController.Phase.MATCH)


func test_cuenta_los_eventos_y_escribe_el_registro() -> void:
	var p := _presenter()
	var seen: Array[int] = [0]
	p.events_applied.connect(func(events: Array[GameEvent]) -> void: seen[0] += events.size())
	while not p.player_can_act():
		p.dealer_step()
	p.act(p.card_action(0))
	assert_gt(seen[0], 0)
	assert_false(p.log_lines.is_empty())


func test_sin_tu_turno_no_hay_acciones() -> void:
	var p := _presenter()
	while p.player_can_act():
		p.act(p.card_action(0))
	if p.dealer_should_play():
		assert_true(p.player_legal().is_empty())
		assert_null(p.card_action(0))
