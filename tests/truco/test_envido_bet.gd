extends GutTest

func test_tabla_de_secuencias() -> void:
	_check([EnvidoBet.Call.ENVIDO], 2, 1)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.ENVIDO], 4, 2)
	_check([EnvidoBet.Call.REAL_ENVIDO], 3, 1)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.REAL_ENVIDO], 5, 2)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.ENVIDO, EnvidoBet.Call.REAL_ENVIDO], 7, 4)

func test_falta_envido() -> void:
	var b := EnvidoBet.new()
	b.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_eq(b.points_if_accepted(15), 15)
	assert_eq(b.points_if_rejected(), 1)
	var b2 := EnvidoBet.new()
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_eq(b2.points_if_rejected(), 4)

func test_secuencias_ilegales() -> void:
	var b := EnvidoBet.new()
	b.add(EnvidoBet.Call.REAL_ENVIDO)
	assert_false(b.can_add(EnvidoBet.Call.ENVIDO))
	assert_false(b.can_add(EnvidoBet.Call.REAL_ENVIDO))
	b.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_false(b.can_add(EnvidoBet.Call.FALTA_ENVIDO))
	var b2 := EnvidoBet.new()
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.ENVIDO)
	assert_false(b2.can_add(EnvidoBet.Call.ENVIDO))

func _check(seq: Array, accepted: int, rejected: int) -> void:
	var b := EnvidoBet.new()
	for c in seq:
		assert_true(b.can_add(c), "secuencia %s" % [seq])
		b.add(c)
	assert_eq(b.points_if_accepted(30), accepted, "querido %s" % [seq])
	assert_eq(b.points_if_rejected(), rejected, "no querido %s" % [seq])
