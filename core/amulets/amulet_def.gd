class_name AmuletDef
extends RefCounted
## Define los datos y las claves de texto de un amuleto.

enum Category { CARDS, TANTO, CALLS, INFO, CHEAT, ECONOMY }
enum Kind { PASSIVE, ACTIVE }
enum Rarity { COMMON, RARE, LEGENDARY }

const MAX_LEVEL := 3

var id: StringName
var category: Category
var kind: Kind
var rarity: Rarity
var charges: int
var levels: Array[Dictionary] = []
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
	var raw_levels: Variant = data.get("levels", [])
	if raw_levels is Array:
		for raw_level: Variant in raw_levels:
			if raw_level is Dictionary:
				amulet.levels.append(raw_level)
	amulet.name_key = StringName("AMULET_%s_NAME" % key_id)
	amulet.desc_key = StringName("AMULET_%s_DESC" % key_id)
	return amulet


func value(key: String, level: int, default: Variant = null) -> Variant:
	if level >= 1 and level <= levels.size() and levels[level - 1].has(key):
		return levels[level - 1][key]
	if not levels.is_empty() and levels[0].has(key):
		return levels[0][key]
	return default


static func load_all(path: String = "res://data/amulets.json") -> Dictionary:
	var amulets: Dictionary = {}
	if not FileAccess.file_exists(path):
		return amulets
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return amulets
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return amulets
	for amulet_id: Variant in parsed:
		var values: Variant = parsed[amulet_id]
		if not values is Dictionary:
			continue
		var amulet: AmuletDef = AmuletDef.from_dict(String(amulet_id), values)
		amulets[amulet.id] = amulet
	return amulets
