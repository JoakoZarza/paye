class_name RunState
extends RefCounted
## Estado de una run: plata, fiado, deuda, ronda y amuletos. No sabe de Truco.
## Ver DISENO §7.4 y las decisiones de interpretación de los Planes 5 y 5b.

var money: int = 0
## Lo comprado sin plata en esta run; se suma a la cuenta final.
var fiado: int = 0
## Deuda arrastrada de runs anteriores; se suma a la cuenta final.
var debt: int = 0
var round := 1
## Amuletos comprados en esta run: cada uno encarece la tienda. Vender no lo baja.
var purchases := 0
var loadout := Loadout.new()
## Cuánto se pagó por cada amuleto equipado (para venderlo).
var paid_for: Dictionary = {}
var deck: RunDeck
var alive := true
var retired := false


func can_pay_entry(economy: Economy) -> bool:
	return money >= economy.entry(round)


func pay_entry(economy: Economy) -> bool:
	if not can_pay_entry(economy):
		return false
	money -= economy.entry(round)
	return true


## El premio entero es tuyo: el fiado y la deuda se cobran en la cuenta final.
func collect_prize(total: int) -> void:
	money += total


## La cuenta final del bar (DISENO §6): los 10M más el fiado y la deuda arrastrada.
func bill(economy: Economy) -> int:
	return economy.debt_base + fiado + debt


func credit_available(economy: Economy) -> int:
	return maxi(0, floori(money * economy.fiado_limit) - fiado)


func die() -> void:
	alive = false
	debt += fiado
	fiado = 0
