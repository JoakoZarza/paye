extends GutTest


func test_lie_rate_con_prior() -> void:
	var model := PlayerModel.new()
	assert_almost_eq(model.lie_rate(), 0.3, 0.0001)
	model.shows_seen = 8
	model.lies_caught = 6
	assert_almost_eq(model.lie_rate(), 0.66, 0.0001)
