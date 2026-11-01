class_name PlayerModel
extends RefCounted
## Resume la conducta observada del jugador.

const LIE_PRIOR_LIES: float = 0.6
const LIE_PRIOR_SHOWS: float = 2.0
## Prior de "quiere la mitad de las veces" para las tasas de aceptación.
const ACCEPT_PRIOR: float = 1.0
const ACCEPT_PRIOR_OFFERS: float = 2.0

var shows_seen: int
var lies_caught: int
var truco_calls: int
var hands_seen: int
## Cantos del dealer que el jugador tuvo que contestar, y cuántos quiso.
var truco_offers: int
var truco_accepts: int
var envido_offers: int
var envido_accepts: int


func lie_rate() -> float:
	return (float(lies_caught) + LIE_PRIOR_LIES) / (float(shows_seen) + LIE_PRIOR_SHOWS)


func truco_call_rate() -> float:
	return minf(float(truco_calls) / float(maxi(hands_seen, 1)), 1.0)


func truco_accept_rate() -> float:
	return (float(truco_accepts) + ACCEPT_PRIOR) / (float(truco_offers) + ACCEPT_PRIOR_OFFERS)


func envido_accept_rate() -> float:
	return (float(envido_accepts) + ACCEPT_PRIOR) / (float(envido_offers) + ACCEPT_PRIOR_OFFERS)
