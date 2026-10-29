class_name RivalProfile
extends RefCounted
## Guarda los rasgos fijos de un rival.

const ROUND_STEP: float = 0.03
const BUDGET_EVERY: int = 4

var id: StringName
var aggression: float
var lying: float
var cheating: float
var stubbornness: float
var tell_reliability: float
var cheat_budget: int


static func from_dict(d: Dictionary) -> RivalProfile:
	var profile := RivalProfile.new()
	profile.id = StringName(String(d.get("id", "")))
	profile.aggression = float(d.get("aggression", 0.0))
	profile.lying = float(d.get("lying", 0.0))
	profile.cheating = float(d.get("cheating", 0.0))
	profile.stubbornness = float(d.get("stubbornness", 0.0))
	profile.tell_reliability = float(d.get("tell_reliability", 0.0))
	profile.cheat_budget = int(d.get("cheat_budget", 0))
	return profile


static func load_all(path: String = "res://data/rivals.json") -> Dictionary:
	var profiles: Dictionary = {}
	if not FileAccess.file_exists(path):
		return profiles
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return profiles
	for rival_id: Variant in parsed:
		var values: Variant = parsed[rival_id]
		if not values is Dictionary:
			continue
		var data: Dictionary = values.duplicate()
		data["id"] = String(rival_id)
		var profile: RivalProfile = RivalProfile.from_dict(data)
		profiles[profile.id] = profile
	return profiles


func scaled_for_round(round: int) -> RivalProfile:
	var scaled := RivalProfile.new()
	scaled.id = id
	var round_count: int = maxi(round - 1, 0)
	var trait_increase: float = float(round_count) * ROUND_STEP
	scaled.aggression = minf(1.0, aggression + trait_increase)
	scaled.lying = minf(1.0, lying + trait_increase)
	scaled.cheating = minf(1.0, cheating + trait_increase)
	scaled.stubbornness = stubbornness
	scaled.tell_reliability = tell_reliability
	scaled.cheat_budget = cheat_budget + round_count / BUDGET_EVERY
	return scaled
