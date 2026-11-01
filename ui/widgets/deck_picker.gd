class_name DeckPicker
extends VBoxContainer
signal picked(deck_id: StringName)

func _ready() -> void:
	for value: Variant in RunDeck.load_all().values():
		var deck: RunDeck = value
		var button := Button.new()
		button.name = "Deck_" + String(deck.id)
		button.text = "%s — %s" % [UiText.t("UI_DECK_" + String(deck.id).to_upper() + "_NAME"),
			UiText.t("UI_DECK_" + String(deck.id).to_upper() + "_DESC")]
		button.pressed.connect(_pick.bind(deck.id))
		add_child(button)

func _pick(deck_id: StringName) -> void:
	picked.emit(deck_id)
