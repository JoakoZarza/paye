extends BaseScreen
## Muestra el estado de la deuda y permite retirarse o condenarse.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
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
