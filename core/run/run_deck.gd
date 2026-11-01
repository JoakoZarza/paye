class_name RunDeck
extends RefCounted
## Guarda los modificadores de una condición de mazo para la run.

var id: StringName
var prize_multiplier: float
var dealer_budget_multiplier: int
var name_key: StringName
var desc_key: StringName


static func load_all(path: String = "res://data/decks.json") -> Dictionary:
	var decks: Dictionary = {}
	if not FileAccess.file_exists(path):
		return decks
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return decks
	for deck_id: Variant in parsed:
		var values: Variant = parsed[deck_id]
		if not values is Dictionary:
			continue
		var deck := RunDeck.new()
		var key_id: String = String(deck_id).to_upper()
		deck.id = StringName(String(deck_id))
		deck.prize_multiplier = float(values.get("prize_multiplier", 1.0))
		deck.dealer_budget_multiplier = int(values.get("dealer_budget_multiplier", 1))
		deck.name_key = StringName("DECK_%s_NAME" % key_id)
		deck.desc_key = StringName("DECK_%s_DESC" % key_id)
		decks[deck.id] = deck
	return decks


func apply_to(rules: TableRules) -> void:
	rules.dealer_budget_multiplier = dealer_budget_multiplier
