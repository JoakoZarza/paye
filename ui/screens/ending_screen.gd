extends BaseScreen
## Muestra el desenlace de la partida y permite elegir un mazo para empezar otra.


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
	var key := "UI_ENDING_GOOD" if rc.phase == RunController.Phase.RETIRED else "UI_ENDING_GREED"
	ScreenTools.label(box, UiText.t(key), 24)
	var picker := DeckPicker.new()
	picker.picked.connect(_start)
	box.add_child(picker)


func _start(id: StringName) -> void:
	rc.start_run(id)
	acted.emit()


func _draw_world() -> void:
	var good := rc.phase == RunController.Phase.RETIRED
	var key := "UI_ENDING_GOOD" if good else "UI_ENDING_GREED"
	var anchor := world.slot("window") if good else world.slot("bar_counter")
	world_label(wrap_text(UiText.t(key), 30), anchor, Vector3(0, 0.6, 0) if good else Vector3(0, 1.5, 0.1), 20)
	world_decks(_start)



func wants_backdrop() -> bool:
	return world == null


func rival_pose() -> StringName:
	return &"away"
