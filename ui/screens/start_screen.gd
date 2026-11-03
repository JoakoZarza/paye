extends BaseScreen
## Muestra el estado meta y permite elegir un mazo para iniciar una partida.


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
	ScreenTools.label(box, UiText.t("UI_START_TITLE"), 28)
	var legacy := (
		UiText.t("UI_AMULET_" + String(rc.meta.legacy).to_upper())
		if rc.meta.legacy != &"" else UiText.t("UI_START_NONE")
	)
	ScreenTools.label(box, UiText.t("UI_START_META") % [
		rc.meta.debt, legacy, rc.meta.runs_played, rc.meta.best_round,
	])
	if rc.meta.run_in_progress:
		ScreenTools.label(box, UiText.t("UI_START_LOST"))
	var picker := DeckPicker.new()
	picker.picked.connect(_start)
	box.add_child(picker)


func _start(id: StringName) -> void:
	rc.start_run(id)
	acted.emit()


func _draw_world() -> void:
	var legacy := (
		UiText.t("UI_AMULET_" + String(rc.meta.legacy).to_upper())
		if rc.meta.legacy != &"" else UiText.t("UI_START_NONE")
	)
	var lines := [UiText.t("UI_BOARD_DEBT") % rc.meta.debt, UiText.t("UI_BOARD_LEGACY") % legacy]
	if rc.meta.best_round > 0:
		lines.append(UiText.t("UI_BOARD_BEST") % rc.meta.best_round)
	world_label("\n".join(lines), board(), Vector3(0, 0.2, 0.05), 20)
	if rc.meta.run_in_progress:
		world_label(wrap_text(UiText.t("UI_START_LOST"), 26), world.slot("table"), Vector3(0, 1.1, -0.3), 16)
	world_decks(_start)



func wants_backdrop() -> bool:
	return world == null
