extends GutTest

var _economy: Economy


func before_all() -> void:
	_economy = Economy.load_from()


func _state(money: int) -> RunState:
	var s := RunState.new()
	s.money = money
	return s


func test_pagar_entrada() -> void:
	var s := _state(135)
	assert_true(s.pay_entry(_economy))
	assert_eq(s.money, 35)


func test_no_alcanza_la_entrada() -> void:
	var s := _state(99)
	assert_false(s.can_pay_entry(_economy))
	assert_false(s.pay_entry(_economy))
	assert_eq(s.money, 99)


func test_cobrar_premio_paga_acreedor_y_fiado() -> void:
	var s := _state(0)
	s.debt = 300
	s.fiado = 100
	var r := s.collect_prize(600, _economy)
	assert_eq(r, {"creditor": 300, "fiado": 100, "kept": 200})
	assert_eq(s.money, 200)
	assert_eq(s.debt, 0)
	assert_eq(s.fiado, 0)


func test_premio_que_no_alcanza_no_deja_negativos() -> void:
	var s := _state(0)
	s.debt = 10000
	s.fiado = 500
	var r := s.collect_prize(600, _economy)
	assert_eq(r["creditor"], 300)
	assert_eq(r["fiado"], 300)
	assert_eq(r["kept"], 0)
	assert_eq(s.fiado, 200)
	assert_eq(s.debt, 9700)
	assert_eq(s.money, 0)


func test_credito_disponible() -> void:
	var s := _state(100)
	assert_eq(s.credit_available(_economy), 200)
	s.fiado = 150
	assert_eq(s.credit_available(_economy), 50)


func test_morir_pasa_el_fiado_a_la_deuda() -> void:
	var s := _state(0)
	s.debt = 50
	s.fiado = 120
	s.die()
	assert_false(s.alive)
	assert_eq(s.debt, 170)
	assert_eq(s.fiado, 0)


func test_fiado_al_limite_y_sin_entrada_es_muerte() -> void:
	var s := _state(100)
	s.round = 2
	s.fiado = s.credit_available(_economy)
	s.money = 0
	assert_false(s.can_pay_entry(_economy))
	s.die()
	assert_eq(s.debt, 200)
