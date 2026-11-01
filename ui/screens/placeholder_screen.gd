class_name PlaceholderScreen
extends BaseScreen
## Pantalla temporal para recorrer las fases.

var screen_name: StringName


func configure(p_name: StringName) -> void:
	screen_name = p_name


func refresh() -> void:
	for child: Node in get_children():
		child.queue_free()
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(layout)
	var title := Label.new()
	title.text = UiText.t(_title_key())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	if screen_name == &"table":
		return
	var button := Button.new()
	button.text = "Avanzar"
	button.custom_minimum_size.y = 40
	button.pressed.connect(_advance)
	layout.add_child(button)


func _title_key() -> String:
	var titles := {
		&"start": "UI_START_TITLE", &"bar": "UI_BAR_TITLE", &"table": "UI_TABLE_TITLE",
		&"one_more": "UI_ONE_MORE_TITLE", &"shop": "UI_SHOP_TITLE", &"free": "UI_FREE_TITLE",
		&"death": "UI_DEATH_TITLE", &"ending": "UI_ENDING_TITLE",
	}
	return String(titles.get(screen_name, String(screen_name)))


func _advance() -> void:
	match screen_name:
		&"start":
			rc.start_run(&"normal")
		&"bar":
			rc.enter_match()
		&"one_more":
			rc.skip_one_more()
		&"shop":
			rc.next_round()
		&"free":
			rc.retire()
		&"death", &"ending":
			if rc.phase in RunController.ENDED:
				rc = RunController.new(rc.economy, rc.meta, int(Time.get_unix_time_from_system()))
	acted.emit()
