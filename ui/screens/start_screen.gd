extends BaseScreen
## Muestra el estado meta y permite elegir un mazo para iniciar una partida.


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


## Vista 3D: el único menú que no es parte del bar. A la izquierda el título y los mazos;
## a la derecha lo que arrastrás de antes. Detrás, un velo negro y el bar esperando.
func _draw_world() -> void:
	var panel := VBoxContainer.new()
	panel.name = "MenuPanel"
	panel.anchor_left = 0.04
	panel.anchor_right = 0.3
	panel.anchor_top = 0.24
	panel.anchor_bottom = 0.9
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	panel.add_child(RingStyle.reading_label(UiText.t("UI_GAME_TITLE"), 56))
	var decks := RunDeck.load_all().values()
	for deck: RunDeck in decks:
		var key := "UI_DECK_" + String(deck.id).to_upper()
		var b := ScreenTools.button(panel, UiText.t(key + "_NAME"), "Deck_" + String(deck.id), _start.bind(deck.id))
		RingStyle.shakify(b)
		b.add_theme_font_size_override("font_size", 30)
		panel.add_child(RingStyle.reading_label(wrap_text(UiText.t(key + "_DESC"), 30), 16))
	if rc.meta.run_in_progress:
		var lost := RingStyle.reading_label(wrap_text(UiText.t("UI_START_LOST"), 30), 16)
		lost.add_theme_color_override("default_color", Color(0.9, 0.55, 0.4))
		panel.add_child(lost)
	var legacy := (
		UiText.t("UI_AMULET_" + String(rc.meta.legacy).to_upper())
		if rc.meta.legacy != &"" else UiText.t("UI_START_NONE")
	)
	var lines := [UiText.t("UI_BOARD_DEBT") % rc.meta.debt, UiText.t("UI_BOARD_LEGACY") % legacy]
	if rc.meta.best_round > 0:
		lines.append(UiText.t("UI_BOARD_BEST") % rc.meta.best_round)
	var info := RingStyle.reading_label("\n".join(lines), 22)
	info.name = "MenuInfo"
	info.anchor_left = 0.76
	info.anchor_right = 0.97
	info.anchor_top = 0.34
	info.anchor_bottom = 0.52
	add_child(info)


func backdrop_alpha() -> float:
	return 0.5 if world != null else 0.78


func rival_pose() -> StringName:
	return &"away"

## En el menú el velo es parte del diseño: separa el menú del bar.
func wants_backdrop() -> bool:
	return true
