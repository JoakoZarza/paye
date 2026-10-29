class_name EnvidoBet
extends RefCounted
## Secuencia de cantos de envido de una mano y lo que vale. Ver DISENO §3.3.

enum Call { ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }

const VALUES := { Call.ENVIDO: 2, Call.REAL_ENVIDO: 3 }

var calls: Array[Call] = []


func can_add(c: Call) -> bool:
	if Call.FALTA_ENVIDO in calls:
		return false
	match c:
		Call.ENVIDO:
			return not (Call.REAL_ENVIDO in calls) and calls.count(Call.ENVIDO) < 2
		Call.REAL_ENVIDO:
			return not (Call.REAL_ENVIDO in calls)
		_:
			return true


func add(c: Call) -> void:
	assert(can_add(c), "Canto de envido ilegal en esta secuencia")
	calls.append(c)


## falta_points: lo que le falta al que va ganando para llegar al objetivo.
func points_if_accepted(falta_points: int) -> int:
	return _accepted_total(calls, falta_points)


## Lo querido hasta el canto anterior, mínimo 1.
func points_if_rejected() -> int:
	var previous := calls.slice(0, calls.size() - 1)
	return maxi(1, _accepted_total(previous, 0))


static func _accepted_total(seq: Array, falta_points: int) -> int:
	if Call.FALTA_ENVIDO in seq:
		return falta_points
	var total := 0
	for c in seq:
		total += VALUES[c]
	return total
