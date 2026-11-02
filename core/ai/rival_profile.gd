class_name RivalProfile
extends RefCounted
## Guarda los rasgos fijos de un rival.

const ROUND_STEP: float = 0.03
const BUDGET_EVERY: int = 4

var id: StringName
var sin: StringName
var variant: StringName
var aggression: float
var lying: float
var cheating: float
var stubbornness: float
var tell_reliability: float
var cheat_budget: int
var cheat_weights: Dictionary = {}
var special: StringName = &""
var tilt_multiplier: float = 1.0
var noise: float = 0.15
## Probabilidad de tirar una carta cualquiera en vez de la que convenía (almas torpes).
var blunder: float = 0.0
## Qué tan atento está al tanto: reclamar al que se fue sin mostrar y acordarse de mostrar el suyo.
var attention: float = 0.5


static func from_dict(d: Dictionary) -> RivalProfile:
	var profile := RivalProfile.new()
	profile.id = StringName(String(d.get("id", "")))
	profile.sin = StringName(String(d.get("sin", "")))
	profile.variant = StringName(String(d.get("variant", "")))
	profile.aggression = float(d.get("aggression", 0.0))
	profile.lying = float(d.get("lying", 0.0))
	profile.cheating = float(d.get("cheating", 0.0))
	profile.stubbornness = float(d.get("stubbornness", 0.0))
	profile.tell_reliability = float(d.get("tell_reliability", 0.0))
	profile.cheat_budget = int(d.get("cheat_budget", 0))
	var weights: Variant = d.get("cheat_weights", {})
	if weights is Dictionary:
		for key: Variant in weights:
			profile.cheat_weights[String(key)] = float(weights[key])
	profile.special = StringName(String(d.get("special", "")))
	profile.tilt_multiplier = float(d.get("tilt_multiplier", 1.0))
	profile.noise = float(d.get("noise", 0.15))
	profile.blunder = float(d.get("blunder", 0.0))
	profile.attention = float(d.get("attention", 0.5))
	return profile


static func load_all(path: String = "res://data/rivals.json") -> Dictionary:
	var profiles: Dictionary = {}
	var parsed: Variant = _parse_file(path)
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


static func load_catalog(path: String = "res://data/rivals.json") -> Dictionary:
	var catalog: Dictionary = {}
	var parsed: Variant = _parse_file(path)
	if not parsed is Dictionary:
		return catalog
	for sin_name: Variant in parsed:
		var entries: Variant = parsed[sin_name]
		if not entries is Array:
			continue
		var profiles: Array[RivalProfile] = []
		for entry: Variant in entries:
			if not entry is Dictionary:
				continue
			var data: Dictionary = entry.duplicate(true)
			var variant_name: String = String(data.get("variant", ""))
			data["sin"] = String(sin_name)
			data["id"] = "%s_%s" % [String(sin_name), variant_name]
			profiles.append(RivalProfile.from_dict(data))
		catalog[StringName(String(sin_name))] = profiles
	return catalog


static func _parse_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text: String = FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


func duplicate_profile() -> RivalProfile:
	var copy := RivalProfile.new()
	copy.id = id
	copy.sin = sin
	copy.variant = variant
	copy.aggression = aggression
	copy.lying = lying
	copy.cheating = cheating
	copy.stubbornness = stubbornness
	copy.tell_reliability = tell_reliability
	copy.cheat_budget = cheat_budget
	copy.cheat_weights = cheat_weights.duplicate(true)
	copy.special = special
	copy.tilt_multiplier = tilt_multiplier
	copy.noise = noise
	copy.blunder = blunder
	copy.attention = attention
	return copy


func jittered(rng: RandomNumberGenerator, amount: float) -> RivalProfile:
	var copy := duplicate_profile()
	copy.aggression = clampf(aggression + rng.randf_range(-amount, amount), 0.0, 1.0)
	copy.lying = clampf(lying + rng.randf_range(-amount, amount), 0.0, 1.0)
	copy.cheating = clampf(cheating + rng.randf_range(-amount, amount), 0.0, 1.0)
	copy.stubbornness = clampf(stubbornness + rng.randf_range(-amount, amount), 0.0, 1.0)
	copy.tell_reliability = clampf(tell_reliability + rng.randf_range(-amount, amount), 0.0, 1.0)
	return copy


func scaled_for_round(round: int) -> RivalProfile:
	var scaled := duplicate_profile()
	var round_count: int = maxi(round - 1, 0)
	var trait_increase: float = float(round_count) * ROUND_STEP
	scaled.aggression = minf(1.0, aggression + trait_increase)
	scaled.lying = minf(1.0, lying + trait_increase)
	scaled.cheating = minf(1.0, cheating + trait_increase)
	scaled.stubbornness = stubbornness
	scaled.tell_reliability = tell_reliability
	scaled.cheat_budget = cheat_budget + round_count / BUDGET_EVERY
	return scaled
