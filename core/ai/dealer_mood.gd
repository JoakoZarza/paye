class_name DealerMood
extends RefCounted
## Mantiene el humor y la confianza del dealer.

const HAND_WON_CONFIDENCE: float = 0.10
const HAND_LOST_CONFIDENCE: float = 0.10
const HAND_LOST_TILT: float = 0.15
const HAND_WON_TILT_DECAY: float = 0.15
const CAUGHT_LYING_TILT: float = 0.30
const CAUGHT_LYING_CONFIDENCE: float = 0.15
const CAUGHT_PLAYER_CONFIDENCE: float = 0.10
const WRONG_SHOW_TILT: float = 0.10
const ACCUSED_SUSPICION: float = 0.25
const CAUGHT_PLAYER_SUSPICION: float = 0.30
const CAUGHT_PLAYER_TILT: float = 0.20
const CAUGHT_CHEATING_TILT: float = 0.35
const CAUGHT_CHEATING_CONFIDENCE: float = 0.15

var confidence: float = 0.5
var tilt: float = 0.0
var suspicion: float = 0.0


func on_hand_result(won: bool) -> void:
	if won:
		confidence += HAND_WON_CONFIDENCE
		tilt -= HAND_WON_TILT_DECAY
	else:
		confidence -= HAND_LOST_CONFIDENCE
		tilt += HAND_LOST_TILT
	_clamp_values()


func on_caught_lying() -> void:
	tilt += CAUGHT_LYING_TILT
	confidence -= CAUGHT_LYING_CONFIDENCE
	_clamp_values()


func on_caught_player_lying() -> void:
	confidence += CAUGHT_PLAYER_CONFIDENCE
	_clamp_values()


func on_wrong_show() -> void:
	tilt += WRONG_SHOW_TILT
	_clamp_values()


func _clamp_values() -> void:
	confidence = clampf(confidence, 0.0, 1.0)
	tilt = clampf(tilt, 0.0, 1.0)
	suspicion = clampf(suspicion, 0.0, 1.0)


## El jugador lo acusó (bien o mal): mira más.
func on_accused() -> void:
	suspicion += ACCUSED_SUSPICION
	_clamp_values()


func on_caught_player_cheating() -> void:
	suspicion += CAUGHT_PLAYER_SUSPICION
	tilt += CAUGHT_PLAYER_TILT
	_clamp_values()


func on_caught_cheating() -> void:
	tilt += CAUGHT_CHEATING_TILT
	confidence -= CAUGHT_CHEATING_CONFIDENCE
	_clamp_values()
