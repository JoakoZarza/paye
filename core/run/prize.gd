class_name Prize
extends RefCounted
## Premio de un partido ganado con sus multiplicadores (DISENO §7.2). Devuelve
## cada multiplicador por separado para que la pantalla muestre de dónde salió.


static func compute(base: int, dealer_score: int, cheats_used: int, cheats_caught: int,
		player_called_envido: bool, loadout: Loadout, deck: RunDeck, economy: Economy,
		is_final: bool = false) -> Dictionary:
	var multipliers: Array[Dictionary] = []
	# El premio del torneo es fijo: sin multiplicadores (Plan 5b, decisión 3).
	if is_final:
		return {"total": base, "multipliers": multipliers}
	if dealer_score == 0:
		multipliers.append({"source": &"flawless", "value": economy.flawless_multiplier})
	if cheats_used > 0 and cheats_caught == 0:
		multipliers.append({"source": &"undetected_cheat", "value": economy.undetected_cheat_multiplier})
	var coin := loadout.prize_multiplier(player_called_envido)
	if coin != 1.0:
		multipliers.append({"source": &"train_coin", "value": coin})
	if deck.prize_multiplier != 1.0:
		multipliers.append({"source": &"deck", "value": deck.prize_multiplier})
	var total := float(base)
	for m in multipliers:
		total *= m["value"]
	return {"total": floori(total), "multipliers": multipliers}
