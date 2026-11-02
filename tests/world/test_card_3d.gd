extends GutTest


func test_carta_oculta_no_revela_datos_hasta_mostrarse() -> void:
	var card_3d := load("res://world/card_3d.tscn").instantiate() as Card3D
	card_3d.setup_card(Card.new(Card.Suit.ESPADA, 1), 2, true, false)
	add_child_autofree(card_3d)
	assert_null(card_3d._card)
	assert_false((card_3d.get_node("Face") as MeshInstance3D).visible)
	assert_false((card_3d.get_node("FaceLabel") as Label3D).visible)
	assert_null((card_3d.get_node("Face") as MeshInstance3D).material_override)
	card_3d.reveal(Card.new(Card.Suit.ESPADA, 1))
	assert_true((card_3d.get_node("Face") as MeshInstance3D).visible)


func test_sin_png_muestra_numero_y_palo_efectivos() -> void:
	var card := Card.new(Card.Suit.COPA, 7)
	var modifier := CardModifier.new()
	modifier.new_number = 3
	assert_true(card.add_modifier(modifier))
	var card_3d := load("res://world/card_3d.tscn").instantiate() as Card3D
	card_3d.setup_card(card, 0, false)
	add_child_autofree(card_3d)
	var label := card_3d.get_node("FaceLabel") as Label3D
	assert_true(label.visible)
	assert_eq(label.text, "3\ncopa")


func test_click_emite_indice_de_mano() -> void:
	var card_3d := load("res://world/card_3d.tscn").instantiate() as Card3D
	card_3d.setup_card(Card.new(Card.Suit.ORO, 5), 1, false)
	add_child_autofree(card_3d)
	watch_signals(card_3d)
	card_3d.press()
	assert_signal_emitted_with_parameters(card_3d, "clicked", [1])
