extends GutTest


func test_action_make_guarda_campos_y_equals_los_compara() -> void:
	var action := TrucoAction.make(TrucoAction.Type.PLAY_CARD, 1, 2, 7)
	assert_eq(action.type, TrucoAction.Type.PLAY_CARD)
	assert_eq(action.player, 1)
	assert_eq(action.card_index, 2)
	assert_eq(action.value, 7)
	assert_true(action.equals(TrucoAction.make(TrucoAction.Type.PLAY_CARD, 1, 2, 7)))
	assert_false(action.equals(TrucoAction.make(TrucoAction.Type.PLAY_CARD, 0, 2, 7)))
	assert_false(action.equals(TrucoAction.make(TrucoAction.Type.PLAY_CARD, 1, 1, 7)))
	assert_false(action.equals(TrucoAction.make(TrucoAction.Type.PLAY_CARD, 1, 2, 6)))
	assert_false(action.equals(TrucoAction.make(TrucoAction.Type.TRUCO, 1, 2, 7)))


func test_game_event_make_guarda_campos() -> void:
	var event := GameEvent.make(&"card_played", {"player": 1, "card_index": 2})
	assert_eq(event.type, &"card_played")
	assert_eq(event.data, {"player": 1, "card_index": 2})
