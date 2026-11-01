class_name RivalCatalog
extends RefCounted
## Elige con la semilla la versión de cada rival de la run y le aplica la
## variación. Todo se decide al crearlo, así la run es reproducible.

const RUN_ORDER: Array[StringName] = [&"ira", &"alma", &"gula", &"pereza", &"alma",
	&"envidia", &"lujuria", &"alma", &"soberbia"]
const JITTER: float = 0.05
const GUALICHO: StringName = &"gualicho"
const ALMA: StringName = &"alma"

var _rivals: Array[RivalProfile] = []
var _gualicho: RivalProfile


func _init(p_catalog: Dictionary, p_rng: RandomNumberGenerator) -> void:
	var almas: Array = (p_catalog.get(ALMA, []) as Array).duplicate()
	for sin in RUN_ORDER:
		var pick: RivalProfile
		if sin == ALMA:
			pick = almas.pop_at(p_rng.randi_range(0, almas.size() - 1))
		else:
			var versions: Array = p_catalog.get(sin, [])
			pick = versions[p_rng.randi_range(0, versions.size() - 1)]
		_rivals.append(pick.jittered(p_rng, JITTER))
	var gualichos: Array = p_catalog.get(GUALICHO, [])
	_gualicho = (gualichos[0] as RivalProfile).duplicate_profile()


## Rival de la ronda (1 a rounds()); null fuera de rango.
func rival_for(round: int) -> RivalProfile:
	if round < 1 or round > _rivals.size():
		return null
	return _rivals[round - 1]


func gualicho() -> RivalProfile:
	return _gualicho


func rounds() -> int:
	return RUN_ORDER.size()
