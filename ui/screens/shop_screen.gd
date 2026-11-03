extends BaseScreen
## Tienda: arriba la plata, en el medio las ofertas, abajo tus amuletos.
## Cada botón apagado dice por qué; cada acción deja un aviso.

const RARITY_COLORS := {
	AmuletDef.Rarity.COMMON: Color(0.55, 0.53, 0.48),
	AmuletDef.Rarity.RARE: Color(0.35, 0.55, 0.85),
	AmuletDef.Rarity.LEGENDARY: Color(0.85, 0.65, 0.2),
}
const MUTED := Color(0.65, 0.63, 0.58)
const WARN := Color(0.9, 0.55, 0.4)
const GOOD := Color(0.6, 0.8, 0.5)
const ROMAN := ["", "I", "II", "III"]

var _message := ""
var _message_bad := false
## Vista 3D: primero elegís si te levantás a la barra o te quedás en la mesa.
var _at_counter := false
## Vista 3D en la barra: los amuletos apoyados (ofertas y los tuyos).
var _counter_items: Array[Node3D] = []

## Sobre la barra: ofertas en el medio, los tuyos a la izquierda y los botones de
## cambiar ofertas y volver a la derecha (en metros, respecto de la barra).
const COUNTER_TOP := 1.1
const OFFER_X := [-0.5, 0.0, 0.5, 0.25, -0.25]
const OWNED_X := [-1.15, -0.85]
const OFFER_Z := 0.12
const RIGHT_X := 0.88
const WRAP := 24


func camera_marker() -> StringName:
	return &"CamShop" if _at_counter or world == null else &"CamSeat"


func wants_backdrop() -> bool:
	return world == null


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_clear_tags()
	_clear_counter()
	if world != null and not _at_counter:
		_draw_choice()
		return
	if world != null and world.slot("bar_counter") != null:
		_draw_counter()
		return
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var s := rc.state

	var title := UiText.t("UI_SHOP_TITLE")
	if rc.shop.is_premium():
		title += " · " + UiText.t("UI_SHOP_PREMIUM")
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	box.add_child(header)
	ScreenTools.label(header, title, 28).autowrap_mode = TextServer.AUTOWRAP_OFF
	var money := ScreenTools.label(header, UiText.t("UI_SHOP_MONEY") % [s.money, s.fiado, rc.economy.entry(s.round + 1)], 20)
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_muted(ScreenTools.label(box, UiText.t("UI_SHOP_HELP"), 15))

	ScreenTools.label(box, UiText.t("UI_SHOP_OFFERS"), 22)
	var offers := HBoxContainer.new()
	offers.add_theme_constant_override("separation", 12)
	box.add_child(offers)
	var slots_full := s.loadout.equipped().size() >= Loadout.SLOTS
	for i in rc.shop.offers.size():
		_offer_card(offers, i, slots_full)
	if rc.shop.offers.is_empty():
		_muted(ScreenTools.label(offers, UiText.t("UI_SHOP_SOLD_OUT")))

	ScreenTools.label(box, UiText.t("UI_SHOP_YOURS") % [s.loadout.equipped().size(), Loadout.SLOTS], 22)
	var yours := HBoxContainer.new()
	yours.add_theme_constant_override("separation", 12)
	box.add_child(yours)
	for def in s.loadout.equipped():
		_owned_card(yours, def)
	for i in Loadout.SLOTS - s.loadout.equipped().size():
		var empty := _card(yours, MUTED)
		_muted(ScreenTools.label(empty, UiText.t("UI_SHOP_EMPTY_SLOT")))

	# Abajo y siempre a la vista: el último aviso y los botones para seguir.
	var bottom := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		bottom.add_theme_constant_override("margin_" + side, 20)
	outer.add_child(bottom)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	bottom.add_child(footer)
	if _message != "":
		var note := ScreenTools.label(footer, _message, 20)
		note.add_theme_color_override("font_color", WARN if _message_bad else GOOD)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(spacer)
	var cost := rc.economy.reroll_cost(s.round, rc.shop.rerolls)
	ScreenTools.button(footer, UiText.t("UI_SHOP_REROLL") % cost, "Reroll", _reroll, s.money >= cost)
	ScreenTools.button(footer, UiText.t("UI_SHOP_NEXT"), "Next", _next)


func _offer_card(parent: Node, i: int, slots_full: bool) -> void:
	var s := rc.state
	var def: AmuletDef = rc.shop.offers[i]
	var card := _card(parent, RARITY_COLORS[def.rarity])
	_amulet_header(card, def)
	var price := rc.shop.price_of(def, s)
	var quote := rc.shop.quote(price, s)
	ScreenTools.label(card, UiText.t("UI_SHOP_PRICE") % price, 22)
	var why := ""
	if slots_full:
		why = UiText.t("UI_SHOP_WHY_FULL")
	elif not quote["ok"]:
		why = UiText.t("UI_SHOP_WHY_MONEY")
	elif int(quote["fiado"]) > 0:
		why = UiText.t("UI_SHOP_SPLIT") % [int(quote["paid"]), int(quote["fiado"])]
	if why != "":
		ScreenTools.label(card, why, 16).add_theme_color_override("font_color", WARN)
	ScreenTools.button(card, UiText.t("UI_SHOP_BUY"), "Buy%d" % i, _buy.bind(i), quote["ok"] and not slots_full)


func _owned_card(parent: Node, def: AmuletDef) -> void:
	var s := rc.state
	var id: StringName = def.id
	var card := _card(parent, RARITY_COLORS[def.rarity])
	_amulet_header(card, def)
	var level := s.loadout.level(id)
	ScreenTools.label(card, UiText.t("UI_LEVEL_N") % ROMAN[level], 18)
	var up := rc.shop.upgrade_price(id, s)
	var why := ""
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	if up < 0:
		why = UiText.t("UI_SHOP_MAX_LEVEL")
	else:
		var quote := rc.shop.quote(up, s)
		var can := bool(quote["ok"]) and rc.shop.can_upgrade_now()
		ScreenTools.button(buttons, UiText.t("UI_SHOP_UPGRADE") % [ROMAN[level + 1], up], "Upgrade_" + String(id),
			_upgrade.bind(id), can)
		if not rc.shop.can_upgrade_now():
			why = UiText.t("UI_SHOP_WHY_UPGRADED")
		elif not quote["ok"]:
			why = UiText.t("UI_SHOP_WHY_MONEY")
	var value := rc.economy.sell_value(int(s.paid_for.get(id, 0)))
	ScreenTools.button(buttons, UiText.t("UI_SHOP_SELL") % value, "Sell_" + String(id), _sell.bind(id))
	if why != "":
		_muted(ScreenTools.label(card, why, 16))
	card.add_child(buttons)


func _amulet_header(card: Node, def: AmuletDef) -> void:
	var key := "UI_AMULET_" + String(def.id).to_upper()
	ScreenTools.label(card, UiText.t(key), 22)
	ScreenTools.label(card, UiText.t("UI_RARITY_" + AmuletDef.Rarity.keys()[def.rarity]), 16) \
		.add_theme_color_override("font_color", RARITY_COLORS[def.rarity])
	ScreenTools.label(card, UiText.t(key + "_DESC"), 16)


func _card(parent: Node, border: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14)
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	return inner


func _muted(l: Label) -> Label:
	l.add_theme_color_override("font_color", MUTED)
	return l


func _name_of(id: StringName) -> String:
	return UiText.t("UI_AMULET_" + String(id).to_upper())


func _draw_choice() -> void:
	_clear_tags()
	if world.slot("bar_counter") != null:
		world_button(UiText.t("UI_SHOP_GO"), "GoShop", _go_to_counter, world.slot("bar_counter"), Vector3(0, 1.35, 0))
		world_button(UiText.t("UI_SHOP_STAY"), "Stay", _stay, world.slot("table"), Vector3(0, 0.86, 0.15))
		return
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_top = -170
	box.offset_left = -260
	box.offset_right = 260
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := ScreenTools.label(box, UiText.t("UI_SHOP_CHOICE"), 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	ScreenTools.button(row, UiText.t("UI_SHOP_GO"), "GoShop", _go_to_counter)
	ScreenTools.button(row, UiText.t("UI_SHOP_STAY"), "Stay", _stay)


func _go_to_counter() -> void:
	_at_counter = true
	acted.emit()


## Te quedás sentado: sin tienda, pasa la ronda y se sienta el rival siguiente.
func _stay() -> void:
	if router != null:
		router.stay_seated = true
	_next()


func _buy(i: int) -> void:
	var id: StringName = rc.shop.offers[i].id
	var r := rc.buy(i)
	_message_bad = not r["ok"]
	if r["ok"]:
		_message = UiText.t("UI_SHOP_BOUGHT") % _name_of(id)
		if int(r["fiado"]) > 0:
			_message += " " + UiText.t("UI_SHOP_BOUGHT_FIADO") % int(r["fiado"])
	else:
		_message = _reason(r["reason"])
	acted.emit()


func _upgrade(id: StringName) -> void:
	var r := rc.upgrade(id)
	_message_bad = not r["ok"]
	_message = UiText.t("UI_SHOP_UPGRADED") % _name_of(id) if r["ok"] else _reason(r["reason"])
	acted.emit()


func _sell(id: StringName) -> void:
	_message_bad = false
	_message = UiText.t("UI_SHOP_SOLD") % [_name_of(id), rc.sell(id)]
	acted.emit()


func _reroll() -> void:
	_message_bad = false
	_message = UiText.t("UI_SHOP_REROLLED") if rc.reroll() else ""
	acted.emit()


func _next() -> void:
	_message = ""
	rc.next_round()
	acted.emit()


func _reason(reason: StringName) -> String:
	match reason:
		&"no_slot":
			return UiText.t("UI_SHOP_WHY_FULL")
		&"no_credit":
			return UiText.t("UI_SHOP_WHY_MONEY")
		&"already_upgraded":
			return UiText.t("UI_SHOP_WHY_UPGRADED")
	return UiText.t("UI_SHOP_FAILED")


func _exit_tree() -> void:
	_clear_counter()


func _clear_counter() -> void:
	for n in _counter_items:
		if is_instance_valid(n):
			n.queue_free()
	_counter_items.clear()


## Vista 3D: la tienda apoyada sobre la barra, con el texto escrito arriba de cada cosa.
func _draw_counter() -> void:
	var counter := world.slot("bar_counter")
	var s := rc.state
	var slots_full := s.loadout.equipped().size() >= Loadout.SLOTS
	if _message != "":
		world_label(_message, counter, Vector3(0, COUNTER_TOP + 0.55, OFFER_Z), 20) \
			.add_theme_color_override("default_color", WARN if _message_bad else GOOD)
	for i in rc.shop.offers.size():
		var def: AmuletDef = rc.shop.offers[i]
		var x: float = OFFER_X[i % OFFER_X.size()]
		_put_amulet(counter, def, Vector3(x, COUNTER_TOP, OFFER_Z))
		var price := rc.shop.price_of(def, s)
		var quote := rc.shop.quote(price, s)
		var text := _name_of(def.id) + "\n" + _wrap(UiText.t("UI_AMULET_" + String(def.id).to_upper() + "_DESC"))
		var why := ""
		if slots_full:
			why = UiText.t("UI_SHOP_WHY_FULL")
		elif not quote["ok"]:
			why = UiText.t("UI_SHOP_WHY_MONEY")
		elif int(quote["fiado"]) > 0:
			why = UiText.t("UI_SHOP_SPLIT") % [int(quote["paid"]), int(quote["fiado"])]
		world_label(text, counter, Vector3(x, COUNTER_TOP + 0.42, OFFER_Z), 16) \
			.add_theme_color_override("default_color", RARITY_COLORS[def.rarity].lerp(Color.WHITE, 0.35))
		var buy := UiText.t("UI_SHOP_BUY") + " " + UiText.t("UI_SHOP_PRICE") % price
		world_button(buy, "Buy%d" % i, _buy.bind(i), counter, Vector3(x, COUNTER_TOP + 0.1, OFFER_Z + 0.05),
			quote["ok"] and not slots_full)
		if why != "":
			world_label(_wrap(why), counter, Vector3(x, COUNTER_TOP + 0.02, OFFER_Z + 0.1), 14) \
				.add_theme_color_override("default_color", WARN)
	if rc.shop.offers.is_empty():
		world_label(UiText.t("UI_SHOP_SOLD_OUT"), counter, Vector3(0, COUNTER_TOP + 0.2, OFFER_Z), 18)
	var owned := s.loadout.equipped()
	for k in owned.size():
		var def: AmuletDef = owned[k]
		var x: float = OWNED_X[k % OWNED_X.size()]
		var id: StringName = def.id
		_put_amulet(counter, def, Vector3(x, COUNTER_TOP, OFFER_Z))
		var level := s.loadout.level(id)
		world_label(_name_of(id) + "\n" + UiText.t("UI_LEVEL_N") % ROMAN[level], counter,
			Vector3(x, COUNTER_TOP + 0.3, OFFER_Z), 16)
		var up := rc.shop.upgrade_price(id, s)
		if up >= 0:
			var can := bool(rc.shop.quote(up, s)["ok"]) and rc.shop.can_upgrade_now()
			world_button(UiText.t("UI_SHOP_UPGRADE") % [ROMAN[level + 1], up], "Upgrade_" + String(id),
				_upgrade.bind(id), counter, Vector3(x, COUNTER_TOP + 0.12, OFFER_Z + 0.05), can)
		var value := rc.economy.sell_value(int(s.paid_for.get(id, 0)))
		world_button(UiText.t("UI_SHOP_SELL") % value, "Sell_" + String(id), _sell.bind(id), counter,
			Vector3(x, COUNTER_TOP + 0.04, OFFER_Z + 0.1))
	var cost := rc.economy.reroll_cost(s.round, rc.shop.rerolls)
	world_button(UiText.t("UI_SHOP_REROLL") % cost, "Reroll", _reroll, counter,
		Vector3(RIGHT_X, COUNTER_TOP + 0.25, OFFER_Z), s.money >= cost)
	world_button(UiText.t("UI_SHOP_BACK"), "Next", _next, counter, Vector3(RIGHT_X, COUNTER_TOP + 0.08, OFFER_Z + 0.05))


## Un amuleto apoyado en la barra: su modelo amulet_<id>.glb o un cubito del color de su rareza.
func _put_amulet(counter: Node3D, def: AmuletDef, at: Vector3) -> void:
	var item := AssetSlot.new()
	item.asset_name = "amulet_" + String(def.id)
	item.placeholder_size = AmuletToken.SIZE * 1.5
	item.placeholder_color = RARITY_COLORS[def.rarity]
	item.ps1 = ps1
	item.position = counter.position + at
	world.add_child(item)
	_counter_items.append(item)


## Corta el texto en renglones de a lo sumo WRAP letras, por palabras.
static func _wrap(text: String) -> String:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" ", false):
		if line != "" and (line + " " + word).length() > WRAP:
			lines.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	if line != "":
		lines.append(line)
	return "\n".join(lines)
