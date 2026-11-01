class_name RunState
extends RefCounted
## Estado de una run: plata, fiado, deuda, ronda y amuletos. No sabe de Truco.
## Ver DISENO §7.4 y las decisiones de interpretación de los Planes 5 y 5b.

var money: int = 0
## Lo comprado sin plata en esta run: cobra interés por ronda, se lleva parte de
## cada premio y lo que quede se suma a la cuenta final.
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
## Propina cobrada en la última entrada pagada.
var last_tip := 0
var retired := false


func can_pay_entry(economy: Economy) -> bool:
	return money >= economy.entry(round)


## Cobra la entrada y la propina del bar (DISENO §7.3.1).
func pay_entry(economy: Economy) -> bool:
	if not can_pay_entry(economy):
		return false
	last_tip = economy.tip(money, round)
	money -= economy.entry(round) + last_tip
	return true


## Mientras debas fiado, el bar retiene parte del premio (no en la final).
## Sin economía, el premio entero es tuyo.
func collect_prize(total: int, economy: Economy = null, is_final: bool = false) -> Dictionary:
	var retained := 0
	if economy != null and not is_final:
		retained = mini(fiado, floori(float(total) * economy.fiado_retention))
	fiado -= retained
	money += total - retained
	return {"retained": retained, "kept": total - retained}


## Devuelve cuánto creció el fiado.
func apply_interest(economy: Economy) -> int:
	var before := fiado
	fiado = economy.fiado_with_interest(fiado)
	return fiado - before


## La cuenta final del bar (DISENO §6): los 10M más el fiado y la deuda arrastrada.
func bill(economy: Economy) -> int:
	return economy.debt_base + fiado + debt


func credit_available(economy: Economy) -> int:
	return maxi(0, floori(money * economy.fiado_limit) - fiado)


func die() -> void:
	alive = false
	debt += fiado
	fiado = 0
