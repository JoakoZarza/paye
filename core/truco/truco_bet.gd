class_name TrucoBet
extends RefCounted
## Nivel de truco de una mano y quién tiene el quiero. Ver DISENO §3.5.

const LEVEL_VALUES: Array[int] = [1, 2, 3, 4]
const MAX_LEVEL := 3

## 0 nada, 1 truco, 2 retruco, 3 vale cuatro.
var level: int = 0
var pending: bool = false
## -1 = cualquiera puede cantar.
var quiero_owner: int = -1
var last_caller: int = -1


## Con un canto pendiente, solo el que responde puede subir ("quiero retruco").
func can_raise(player: int) -> bool:
	if level >= MAX_LEVEL:
		return false
	if pending:
		return player != last_caller
	return quiero_owner == -1 or quiero_owner == player


## Subir con un canto pendiente implica aceptarlo primero.
func raise(player: int) -> void:
	assert(can_raise(player), "El jugador %d no puede subir el truco" % player)
	if pending:
		accept()
	level += 1
	pending = true
	last_caller = player


func accept() -> void:
	pending = false
	quiero_owner = 1 - last_caller


## Lo que vale la mano si el nivel actual se acepta (o ya fue aceptado).
func accepted_value() -> int:
	return LEVEL_VALUES[level]


## Lo que vale la mano si se rechaza el canto pendiente.
func rejected_value() -> int:
	return LEVEL_VALUES[maxi(level - 1, 0)]
