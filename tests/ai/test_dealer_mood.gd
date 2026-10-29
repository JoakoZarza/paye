extends GutTest


func test_ganar_sube_confianza_y_baja_tilt() -> void:
	var mood := DealerMood.new()
	mood.on_hand_result(false)
	mood.on_hand_result(true)
	assert_almost_eq(mood.confidence, 0.5, 0.0001)
	assert_almost_eq(mood.tilt, 0.10, 0.0001)


func test_pescado_mintiendo() -> void:
	var mood := DealerMood.new()
	mood.on_caught_lying()
	assert_almost_eq(mood.tilt, 0.30, 0.0001)
	assert_almost_eq(mood.confidence, 0.35, 0.0001)


func test_humor_siempre_entre_0_y_1() -> void:
	var mood := DealerMood.new()
	for _i: int in range(50):
		mood.on_caught_lying()
	for _i: int in range(50):
		mood.on_hand_result(true)
	assert_true(mood.confidence >= 0.0 and mood.confidence <= 1.0)
	assert_true(mood.tilt >= 0.0 and mood.tilt <= 1.0)
	assert_true(mood.suspicion >= 0.0 and mood.suspicion <= 1.0)
