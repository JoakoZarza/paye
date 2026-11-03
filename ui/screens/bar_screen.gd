extends BaseScreen
## Muestra la información de la ronda en el bar y permite sentarse a jugar.


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
	var s := rc.state
	var rival := rc.rival_for(s.round)
	ScreenTools.label(box, UiText.t("UI_BAR_TITLE"), 28)
	ScreenTools.label(box, UiText.t("UI_BAR_INFO") % [
		s.round, UiText.t("UI_SIN_" + String(rival.sin).to_upper()),
		rc.economy.entry(s.round), rc.economy.tip(s.money, s.round),
		rc.economy.target_points(s.round), s.money, s.fiado, s.debt,
	])
	for def in s.loadout.equipped():
		ScreenTools.label(box, "%s · %s %d" % [
			UiText.t("UI_AMULET_" + String(def.id).to_upper()),
			UiText.t("UI_LEVEL"), s.loadout.level(def.id),
		])
	var can_pay := s.can_pay_entry(rc.economy)
	ScreenTools.button(
		box, UiText.t("UI_BAR_SIT") if can_pay else UiText.t("UI_BAR_CANT_PAY"),
		"Sit", _sit,
	)


func _sit() -> void:
	rc.enter_match()
	acted.emit()


## Si te quedaste en la mesa, el rival nuevo se sienta frente a vos.
func camera_marker() -> StringName:
	return &"CamSeat" if router != null and router.stay_seated else &"CamBar"


## Vista 3D: cada dato donde va. El nombre del rival sobre su cabeza, la entrada (y la
## propina, si hay) sobre la mesa, y "Sentarse" sobre tu silla o "Jugar" sobre la mesa si
## ya estás sentado. La plata, el fiado y la deuda van en la esquina (ScreenRouter).
func _draw_world() -> void:
	var s := rc.state
	var rival := rc.rival_for(s.round)
	var table := world.slot("table")
	world_label(UiText.t("UI_SIN_" + String(rival.sin).to_upper()), world.slot("rival_head"), Vector3(0, 0.45, 0), 26)
	var texts: Array[String] = [UiText.t("UI_BAR_ENTRY") % rc.economy.entry(s.round)]
	var tip := rc.economy.tip(s.money, s.round)
	if tip > 0:
		texts.append(UiText.t("UI_BAR_TIP") % tip)
	var spots := row_spots(texts, 0.24, 0.07)
	for i in texts.size():
		world_label(texts[i], table, Vector3(0, 0.79, -0.18) + spots[i], 20)
	var can_pay := s.can_pay_entry(rc.economy)
	var text := UiText.t("UI_BAR_CANT_PAY")
	if can_pay:
		text = UiText.t("UI_BAR_PLAY") if seated() else UiText.t("UI_BAR_SIT")
	if seated():
		world_button(text, "Sit", _sit, table, Vector3(0, 0.8, 0.22))
	else:
		world_button(text, "Sit", _sit, world.slot("chair_player"), Vector3(0, 1.05, 0))


func seated() -> bool:
	return router != null and router.stay_seated


func wants_backdrop() -> bool:
	return world == null


func rival_pose() -> StringName:
	return &"waiting"
