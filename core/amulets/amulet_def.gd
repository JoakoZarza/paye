class_name AmuletDef
extends RefCounted
## Define los datos y las claves de texto de un amuleto.

enum Category { CARDS, TANTO, CALLS, INFO, CHEAT, ECONOMY }
enum Kind { PASSIVE, ACTIVE }
enum Rarity { COMMON, RARE, LEGENDARY }

var id: StringName
var category: Category
var kind: Kind
var rarity: Rarity
var charges: int
var name_key: StringName
var desc_key: StringName


static func from_dict(amulet_id: String, data: Dictionary) -> AmuletDef:
	var amulet := AmuletDef.new()
	var key_id: String = amulet_id.to_upper()
	amulet.id = StringName(amulet_id)
	amulet.category = Category.get(String(data.get("category", "")), Category.CARDS)
	amulet.kind = Kind.get(String(data.get("kind", "")), Kind.PASSIVE)
	amulet.rarity = Rarity.get(String(data.get("rarity", "")), Rarity.COMMON)
	amulet.charges = int(data.get("charges", 0))
	amulet.name_key = StringName("AMULET_%s_NAME" % key_id)
	amulet.desc_key = StringName("AMULET_%s_DESC" % key_id)
	return amulet


static func load_all(path: String = "res://data/amulets.json") -> Dictionary:
	var amulets: Dictionary = {}
	if not FileAccess.file_exists(path):
		return amulets
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return amulets
	for amulet_id: Variant in parsed:
		var values: Variant = parsed[amulet_id]
		if not values is Dictionary:
			continue
		var amulet: AmuletDef = AmuletDef.from_dict(String(amulet_id), values)
		amulets[amulet.id] = amulet
	return amulets
