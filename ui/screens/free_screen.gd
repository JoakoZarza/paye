extends BaseScreen
## Muestra el estado de la deuda y permite retirarse o condenarse.


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
	ScreenTools.label(box, UiText.t("UI_FREE_PAID"), 28)
	ScreenTools.label(box, UiText.t("UI_FREE_LEFT") % rc.state.money)
	ScreenTools.button(box, UiText.t("UI_FREE_RETIRE"), "Retire", _retire)
	ScreenTools.button(box, UiText.t("UI_FREE_CONDEMN"), "Condemn", _condemn)


func _retire() -> void:
	rc.retire()
	acted.emit()


func _condemn() -> void:
	rc.condemn()
	acted.emit()


func _draw_world() -> void:
	world_label(UiText.t("UI_FREE_PAID") + "\n" + UiText.t("UI_FREE_LEFT") % rc.state.money, board(),
		Vector3(0, 0.2, 0.05), 20)
	world_button(UiText.t("UI_FREE_RETIRE"), "Retire", _retire, world.slot("window"), Vector3(0, 0.6, 0))
	world_button(UiText.t("UI_FREE_CONDEMN"), "Condemn", _condemn, world.slot("bar_counter"), Vector3(0, 1.3, 0.1))



func wants_backdrop() -> bool:
	return world == null


func rival_pose() -> StringName:
	return &"away"
