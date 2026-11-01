extends BaseScreen
## Muestra la información de la ronda en el bar y permite sentarse a jugar.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
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
