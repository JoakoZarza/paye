class_name BazaResolver
extends RefCounted
## Compara cartas y determina el resultado de las bazas de una mano.

const PARDA := 2
const UNDECIDED := -1


static func compare(a: Card, b: Card) -> int:
	var rank_a := a.truco_rank()
	var rank_b := b.truco_rank()
	if rank_a > rank_b:
		return 1
	if rank_a < rank_b:
		return -1
	return 0


static func hand_winner(results: Array[int], mano: int) -> int:
	if results.is_empty():
		return UNDECIDED
	if results[0] == PARDA:
		if results.size() < 2:
			return UNDECIDED
		if results[1] != PARDA:
			return results[1]
		if results.size() < 3:
			return UNDECIDED
		return mano if results[2] == PARDA else results[2]

	var first_winner := results[0]
	if results.size() < 2:
		return UNDECIDED
	if results[1] == PARDA or results[1] == first_winner:
		return first_winner
	if results.size() < 3:
		return UNDECIDED
	if results[2] == PARDA:
		return first_winner
	return results[2]
