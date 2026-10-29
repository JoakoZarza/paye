class_name CardModifier
extends RefCounted
## Cambio temporal del número o el palo de una carta (amuletos, trampas).
## -1 en new_number o new_suit significa "no cambia".

enum Scope { HAND, MATCH }

var new_number: int = -1
var new_suit: int = -1
var scope: Scope = Scope.HAND
var source: StringName = &""
