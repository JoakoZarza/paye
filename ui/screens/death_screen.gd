extends BaseScreen
## Muestra el resultado de una derrota y ofrece elegir un legado o iniciar otra partida.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_clear_tags()
	if world != null:
		_draw_world()
		return
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	ScreenTools.label(box, UiText.t("UI_DEATH_TITLE"), 28)
	ScreenTools.label(box, UiText.t("UI_DEATH_INFO") % [rc.state.round, rc.state.debt])
	for id in rc.legacy_choices():
		ScreenTools.button(
			box, UiText.t("UI_AMULET_" + String(id).to_upper()),
			"Legacy_" + String(id), _legacy.bind(id),
		)
	var picker := DeckPicker.new()
	picker.picked.connect(_start)
	box.add_child(picker)


func _legacy(id: StringName) -> void:
	rc.choose_legacy(id)
	acted.emit()


func _start(id: StringName) -> void:
	rc.start_run(id)
	acted.emit()


func _draw_world() -> void:
	world_label(UiText.t("UI_DEATH_TITLE") + "\n" + UiText.t("UI_DEATH_INFO").replace(" · ", "\n") % [rc.state.round, rc.state.debt],
		board(), Vector3(0, 0.2, 0.05), 20)
	var choices := rc.legacy_choices()
	for i in choices.size():
		var id: StringName = choices[i]
		var x := (i - (choices.size() - 1) * 0.5) * 0.5
		world_button(UiText.t("UI_AMULET_" + String(id).to_upper()), "Legacy_" + String(id), _legacy.bind(id),
			world.slot("bar_counter"), Vector3(x, 1.25, 0.1))
	world_decks(_start)



func wants_backdrop() -> bool:
	return world == null


func rival_pose() -> StringName:
	return &"away"
