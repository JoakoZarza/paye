extends BaseScreen
## Muestra el estado meta y permite elegir un mazo para iniciar una partida.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
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
