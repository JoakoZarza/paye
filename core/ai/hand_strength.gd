class_name HandStrength
extends RefCounted
## Fuerza de una mano entre 0 y 1, vista solo con las cartas propias.

const BAZA_WON_BONUS := 0.25
const BAZA_LOST_PENALTY := 0.25
const MAX_RANK := 14.0
const MAX_TANTO := 33.0


static func envido(tanto: int) -> float:
	return tanto / MAX_TANTO


## Promedio de las 2 mejores cartas que quedan, corregido por las bazas ya jugadas.
static func truco(cards: Array[Card], baza_results: Array[int], me: int) -> float:
	var won := baza_results.count(me)
	var lost := baza_results.count(1 - me)
	if cards.is_empty():
		return 1.0 if won > lost else 0.0
	var ranks: Array[int] = []
	for c in cards:
		ranks.append(c.truco_rank())
	ranks.sort()
	ranks.reverse()
	var best := ranks.slice(0, 2)
	var total := 0.0
	for r in best:
		total += r / MAX_RANK
	var s := total / best.size() + won * BAZA_WON_BONUS - lost * BAZA_LOST_PENALTY
	return clampf(s, 0.0, 1.0)
