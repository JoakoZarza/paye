extends GutTest

func test_valores() -> void:
	var t := TrucoBet.new()
	assert_eq(t.accepted_value(), 1)
	t.raise(0)
	assert_eq(t.rejected_value(), 1)
	t.accept()
	assert_eq(t.accepted_value(), 2)
	t.raise(1)
	assert_eq(t.rejected_value(), 2)
	t.accept()
	t.raise(0)
	assert_eq(t.rejected_value(), 3)
	t.accept()
	assert_eq(t.accepted_value(), 4)
	assert_false(t.can_raise(1))

func test_solo_sube_quien_tiene_el_quiero() -> void:
	var t := TrucoBet.new()
	t.raise(0)
	t.accept()
	assert_false(t.can_raise(0))
	assert_true(t.can_raise(1))

func test_no_se_sube_con_canto_pendiente() -> void:
	var t := TrucoBet.new()
	t.raise(0)
	assert_true(t.pending)
	assert_false(t.can_raise(0))
