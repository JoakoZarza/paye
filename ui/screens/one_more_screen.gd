extends BaseScreen
## Muestra el premio de la ronda y permite apostar para jugar una mano más o retirarse.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	ScreenTools.label(box, UiText.t("UI_ONE_MORE_TITLE"), 28)
	ScreenTools.label(box, UiText.t("UI_ONE_MORE_PRIZE") % [rc.state.money, rc.state.fiado])
	var options := rc.one_more_options()
	for i in options.size():
		if options[i] <= 0:
			continue
		ScreenTools.button(
			box, UiText.t("UI_ONE_MORE_STAKE") % options[i], "Stake%d" % i,
			_stake.bind(rc.economy.one_more_fractions[i]),
		)
	ScreenTools.button(box, UiText.t("UI_ONE_MORE_SKIP"), "Skip", _skip)


func _stake(fraction: float) -> void:
	rc.one_more(fraction)
	acted.emit()


func _skip() -> void:
	rc.skip_one_more()
	acted.emit()


func camera_marker() -> StringName:
	return &"CamSeat"
