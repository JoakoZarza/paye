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


func test_cobrar_premio_es_todo_tuyo() -> void:
	var s := _state(10)
	s.debt = 300
	s.fiado = 100
	s.collect_prize(600)
	assert_eq(s.money, 610)
	assert_eq(s.debt, 300)
	assert_eq(s.fiado, 100)


func test_cuenta_final() -> void:
	var s := _state(0)
	assert_eq(s.bill(_economy), 10000000)
	s.debt = 300
	s.fiado = 100
	assert_eq(s.bill(_economy), 10000400)

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


func test_entrada_cobra_propina() -> void:
	var s := _state(20000)
	s.round = 6
	assert_true(s.pay_entry(_economy))
	assert_eq(s.last_tip, 1400)
	assert_eq(s.money, 16600)


func test_retencion_del_fiado() -> void:
	var s := _state(0)
	s.fiado = 100
	assert_eq(s.collect_prize(1000, _economy), {"retained": 100, "kept": 900}, "nunca más que el fiado")
	assert_eq(s.fiado, 0)
	s.fiado = 1000
	assert_eq(s.collect_prize(1000, _economy)["retained"], 250)
	assert_eq(s.fiado, 750)
	assert_eq(s.money, 1650)


func test_la_final_no_retiene() -> void:
	var s := _state(0)
	s.fiado = 500
	assert_eq(s.collect_prize(10000000, _economy, true)["retained"], 0)
	assert_eq(s.fiado, 500)


func test_interes_al_pasar_de_ronda() -> void:
	var s := _state(0)
	assert_eq(s.apply_interest(_economy), 0)
	s.fiado = 200
	assert_eq(s.apply_interest(_economy), 20)
	assert_eq(s.fiado, 220)
