class_name PlayerModel
extends RefCounted
## Resume la conducta observada del jugador.

const LIE_PRIOR_LIES: float = 0.6
const LIE_PRIOR_SHOWS: float = 2.0

var shows_seen: int
var lies_caught: int
var truco_calls: int
var hands_seen: int


func lie_rate() -> float:
	return (float(lies_caught) + LIE_PRIOR_LIES) / (float(shows_seen) + LIE_PRIOR_SHOWS)


func truco_call_rate() -> float:
	return float(truco_calls) / float(maxi(hands_seen, 1))
