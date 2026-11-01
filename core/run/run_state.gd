class_name RunState
extends RefCounted
## Estado de una run: plata, fiado, deuda, ronda y amuletos. No sabe de Truco.
## Ver DISENO §7.4 y las decisiones de interpretación del Plan 5.

var money: int = 0
## Lo comprado sin plata en esta run; se descuenta del próximo premio.
var fiado: int = 0
## Deuda arrastrada de runs anteriores; la cobra el acreedor con parte de cada premio.
var debt: int = 0
var round := 1
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


## Primero cobra el acreedor, después se descuenta el fiado, el resto es tuyo.
func collect_prize(total: int, economy: Economy) -> Dictionary:
	var creditor := mini(debt, floori(total * economy.creditor_cut))
	debt -= creditor
	var rest := total - creditor
	var paid_fiado := mini(fiado, rest)
	fiado -= paid_fiado
	rest -= paid_fiado
	money += rest
	return {"creditor": creditor, "fiado": paid_fiado, "kept": rest}


func credit_available(economy: Economy) -> int:
	return maxi(0, floori(money * economy.fiado_limit) - fiado)


func die() -> void:
	alive = false
	debt += fiado
	fiado = 0
