extends BaseScreen
## Muestra el desenlace de la partida y permite elegir un mazo para empezar otra.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	var key := "UI_ENDING_GOOD" if rc.phase == RunController.Phase.RETIRED else "UI_ENDING_GREED"
	ScreenTools.label(box, UiText.t(key), 24)
	var picker := DeckPicker.new()
	picker.picked.connect(_start)
	box.add_child(picker)


func _start(id: StringName) -> void:
	rc.start_run(id)
	acted.emit()
