extends BaseScreen
## Muestra el resultado de una derrota y ofrece elegir un legado o iniciar otra partida.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
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
