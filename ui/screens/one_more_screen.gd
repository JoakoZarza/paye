extends BaseScreen
## Muestra el premio de la ronda y permite apostar para jugar una mano más o retirarse.


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


## Vista 3D: el premio en el medio de la mesa, cada apuesta en fila y "seguir" cerca tuyo.
func _draw_world() -> void:
	var table := world.slot("table")
	world_label(UiText.t("UI_ONE_MORE_TITLE") + "\n" + UiText.t("UI_ONE_MORE_PRIZE") % [rc.state.money, rc.state.fiado],
		table, Vector3(0, 0.9, -0.2), 24)
	var options := rc.one_more_options()
	var shown: Array[int] = []
	for i in options.size():
		if options[i] > 0:
			shown.append(i)
	var texts: Array[String] = []
	for i in shown:
		texts.append(UiText.t("UI_ONE_MORE_STAKE") % options[i])
	var spots := row_spots(texts, 0.22, 0.12)
	for k in shown.size():
		var i := shown[k]
		world_button(texts[k], "Stake%d" % i, _stake.bind(rc.economy.one_more_fractions[i]), table,
			Vector3(0, 0.8, 0.0) + spots[k])
	world_button(UiText.t("UI_ONE_MORE_SKIP"), "Skip", _skip, table, Vector3(0, 0.78, 0.28))


func wants_backdrop() -> bool:
	return world == null
