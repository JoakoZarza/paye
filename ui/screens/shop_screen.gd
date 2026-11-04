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

## El mantel sobre la barra: ofertas atrás, lo tuyo adelante a la izquierda y los
## botones de cambiar ofertas y volver adelante a la derecha (metros, respecto de la barra).
const COUNTER_TOP := 1.1
const CLOTH_SIZE := Vector2(1.15, 0.78)
const OFFER_X := [-0.36, 0.0, 0.36]
const OWNED_X := [-0.18, 0.18]
## Afuera del mantel, a cada costado sobre la barra.
const SIDE_X := 0.85
## El guardarropas: una caja sobre la barra, adelante a la derecha del mantel.
const WARDROBE_AT := Vector3(0.78, 0, 0.27)
const WARDROBE_SIZE := Vector3(0.2, 0.06, 0.14)
const BACK_Z := -0.17
const FRONT_Z := 0.16
const RIGHT_X := 0.36
const WRAP := 24
## Viendo un objeto de cerca: dónde flota (respecto de la cámara) y cuánto se apaga el bar.
## Dónde flota (fracción de pantalla: el medio de la mitad izquierda) y a qué distancia.
const INSPECT_SCREEN := Vector2(0.25, 0.5)
const INSPECT_DEPTH := 0.5
const DIM := 0.15
## Panel de detalles: un tamaño por nivel de lectura (nombre, qué hace, precio, datos chicos)
## y el aire que separa lo que se lee de lo que se aprieta.
const DETAIL_TITLE := 36
const DETAIL_BODY := 22
const DETAIL_PRICE := 30
const DETAIL_SMALL := 16
const DETAIL_GAP := 40
## El botón principal (comprar, mejorar, retirar) manda sobre todo lo demás que se aprieta.
const DETAIL_ACTION := 30
const CATEGORY_NAMES := {
	AmuletDef.Category.CARDS: "Cartas", AmuletDef.Category.TANTO: "Tanto",
	AmuletDef.Category.CALLS: "Cantos", AmuletDef.Category.INFO: "Información",
	AmuletDef.Category.CHEAT: "Trampa", AmuletDef.Category.ECONOMY: "Plata",
}

var _inspected: ShopItem
var _hover_label: Control
var _details: Control


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
	# Antes del primer partido venís del bar directo a la barra: no hay nada que elegir.
	if rc.pre_round():
		_at_counter = true
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
	var money := ScreenTools.label(header, UiText.t("UI_SHOP_MONEY") % [s.money, s.fiado, rc.economy.entry(s.round + (0 if rc.pre_round() else 1))], 20)
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

	var w := rc.wardrobe()
	if w.is_empty() or not AmuletDef.load_all().has(w["id"]):
		_muted(ScreenTools.label(box, UiText.t("UI_WARDROBE_EMPTY"), 18))
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var text: String = UiText.t("UI_WARDROBE") + ": " + _name_of(w["id"]) + " " + ROMAN[int(w["level"])]
		ScreenTools.label(row, text, 18)
		var fee := int(w["fee"])
		var can := s.loadout.equipped().size() < Loadout.SLOTS and not s.loadout.has(w["id"]) \
			and bool(rc.shop.quote(fee, s)["ok"])
		ScreenTools.button(row, UiText.t("UI_WARDROBE_TAKE") % fee, "Retrieve", _retrieve, can)

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
	ScreenTools.label(card, UiText.t("UI_SHOP_PRICE") % UiText.money(price), 22)
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
	_store_button(buttons, id, false)
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
		# Mirando al frente la barra no se ve: un indicador al borde de la pantalla
		# avisa que está para ese lado y se apaga cuando la ves. Solo avisa; el cartel para ir
		# es el de la barra.
		var hint := OffscreenHint.new()
		hint.name = "GoShopHint"
		hint.target = world.slot("bar_counter")
		hint.offset = Vector3(0, COUNTER_TOP, 0)
		hint.camera = world.camera
		add_child(hint)
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
		&"wardrobe_full":
			return UiText.t("UI_WARDROBE_FULL")
		&"already_equipped":
			return UiText.t("UI_WARDROBE_SAME")
	return UiText.t("UI_SHOP_FAILED")


func _exit_tree() -> void:
	_clear_counter()


func _clear_counter() -> void:
	_end_inspect(true)
	for n in _counter_items:
		if is_instance_valid(n):
			n.queue_free()
	_counter_items.clear()


## Vista 3D: la tienda es un mantel sobre la barra visto desde arriba. Atrás las
## ofertas, adelante lo tuyo; cada cosa con su cartelito escrito a mano. Clic derecho
## sobre un objeto lo muestra de cerca con todos sus datos, y ahí se compra o se vende.
func _draw_counter() -> void:
	var counter := world.slot("bar_counter")
	var s := rc.state
	var top := counter.position + Vector3(0, COUNTER_TOP, 0)
	var flat := Basis(Vector3.UP, counter.rotation.y)
	_add_cloth(top, counter.rotation.y)
	# Cinco lugares: tres ofertas atrás y tus dos lugares adelante (los vacíos, marcados).
	for i in rc.shop.offers.size():
		var def: AmuletDef = rc.shop.offers[i]
		var price := rc.shop.price_of(def, s)
		var at := top + flat * Vector3(OFFER_X[i % OFFER_X.size()], 0, BACK_Z)
		var item := _put_item(def, "$" + UiText.money(price), false, at, counter.rotation.y)
		item.set_meta("offer", i)
	if rc.shop.offers.is_empty():
		world_label(UiText.t("UI_SHOP_SOLD_OUT"), counter, Vector3(0, COUNTER_TOP, BACK_Z), 18)
	var owned := s.loadout.equipped()
	for k in Loadout.SLOTS:
		var at := top + flat * Vector3(OWNED_X[k % OWNED_X.size()], 0, FRONT_Z)
		if k < owned.size():
			_put_item(owned[k], ROMAN[s.loadout.level(owned[k].id)], true, at, counter.rotation.y)
		else:
			_add_empty_spot(at, counter.rotation.y)
	# A la izquierda del mantel, sobre la barra: tu plata. A la derecha: los botones.
	var money: Array[String] = [UiText.t("UI_SHOP_CASH") % s.money]
	if s.fiado > 0:
		money.append(UiText.t("UI_SHOP_OWED") % s.fiado)
	money.append(UiText.t("UI_SHOP_NEXT_ENTRY") % rc.economy.entry(s.round + (0 if rc.pre_round() else 1)))
	world_label("\n".join(money), counter, Vector3(-SIDE_X, COUNTER_TOP, 0), 20).name = "ShopMoney"
	if _message != "":
		world_label(_wrap(_message), counter, Vector3(-SIDE_X, COUNTER_TOP, 0.3), 16) \
			.add_theme_color_override("default_color", WARN if _message_bad else GOOD)
	_draw_wardrobe(counter, top, flat)
	var cost := rc.economy.reroll_cost(s.round, rc.shop.rerolls)
	world_button(UiText.t("UI_SHOP_REROLL") % cost, "Reroll", _reroll, counter,
		Vector3(SIDE_X, COUNTER_TOP, -0.22), s.money >= cost)
	world_button(UiText.t("UI_SHOP_BACK"), "Next", _next, counter, Vector3(SIDE_X, COUNTER_TOP, -0.06))


## La caja del guardarropas; si tiene algo, el amuleto arriba con su cartel "guardado".
func _draw_wardrobe(counter: Node3D, top: Vector3, flat: Basis) -> void:
	var at := top + flat * WARDROBE_AT
	var box := AssetSlot.new()
	box.name = "WardrobeBox"
	box.asset_name = "wardrobe"
	box.placeholder_size = WARDROBE_SIZE
	box.placeholder_color = Color("#3B2616")
	box.ps1 = ps1
	box.position = at
	box.rotation.y = counter.rotation.y
	world.add_child(box)
	_counter_items.append(box)
	var w := rc.wardrobe()
	if w.is_empty() or not AmuletDef.load_all().has(w["id"]):
		world_label(UiText.t("UI_WARDROBE_EMPTY"), counter, WARDROBE_AT + Vector3(0, COUNTER_TOP + 0.08, -0.1), 16) \
			.name = "WardrobeLabel"
		return
	var def: AmuletDef = AmuletDef.load_all()[w["id"]]
	var item := _put_item(def, ROMAN[int(w["level"])], false, at + Vector3(0, WARDROBE_SIZE.y, 0), counter.rotation.y)
	item.set_meta("wardrobe", true)
	var label := UiText.t("UI_WARDROBE")
	if int(w["fee"]) > 0:
		label += "\n" + UiText.t("UI_WARDROBE_OWED") % int(w["fee"])
	world_label(label, counter, WARDROBE_AT + Vector3(0, COUNTER_TOP + 0.08, -0.1), 16).name = "WardrobeLabel"


## En la barra la plata se ve sobre la barra, no en la esquina.
func wants_hud() -> bool:
	return world == null or not _at_counter


## El mantel oscuro sobre la barra.
func _add_cloth(top: Vector3, yaw: float) -> void:
	var cloth := MeshInstance3D.new()
	cloth.name = "ShopCloth"
	var quad := QuadMesh.new()
	quad.size = CLOTH_SIZE
	cloth.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#1E1B18")
	material.roughness = 1.0
	cloth.material_override = material
	cloth.rotation = Vector3(-PI * 0.5, yaw, 0)
	cloth.position = top + Vector3(0, 0.001, 0)
	world.add_child(cloth)
	if ps1:
		Ps1Material.apply(cloth)
	_counter_items.append(cloth)


## Un lugar tuyo vacío: un recuadro apenas marcado en el mantel.
func _add_empty_spot(at: Vector3, yaw: float) -> void:
	var spot := MeshInstance3D.new()
	spot.name = "EmptySpot"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	spot.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#2E2A25")
	spot.material_override = material
	spot.rotation = Vector3(-PI * 0.5, yaw, 0)
	spot.position = at + Vector3(0, 0.002, 0)
	world.add_child(spot)
	_counter_items.append(spot)


func _put_item(def: AmuletDef, tag: String, is_owned: bool, at: Vector3, yaw := 0.0) -> ShopItem:
	var item := ShopItem.new()
	item.ps1 = ps1
	item.position = at + Vector3(0, 0.002, 0)
	item.rotation.y = yaw
	world.add_child(item)
	item.setup(def, tag, is_owned, RARITY_COLORS[def.rarity])
	item.inspect_requested.connect(inspect)
	item.hovered.connect(_on_item_hover)
	_counter_items.append(item)
	return item


func shop_items() -> Array[ShopItem]:
	var out: Array[ShopItem] = []
	for n in _counter_items:
		if n is ShopItem and is_instance_valid(n):
			out.append(n)
	return out


# --- Ver de cerca ---

## Levanta el objeto a la izquierda de la pantalla, oscurece el bar y a la derecha
## escribe todo lo que hay que saber de él, con los botones para comprarlo o venderlo.
func inspect(item: ShopItem) -> void:
	if _inspected == item:
		return
	_end_inspect(true)
	_inspected = item
	_on_item_hover(item, false)
	var cam := world.camera
	var at := item.global_position + Vector3(0, 0.25, 0)
	if cam != null and cam.is_inside_tree():
		var view := cam.get_viewport().get_visible_rect().size
		at = cam.project_position(view * INSPECT_SCREEN, INSPECT_DEPTH)
	item.lift_to(at, cam.global_basis if cam != null else Basis.IDENTITY)
	_dim(true)
	for t in _tags:
		(t[0] as Control).modulate.a = 0.0
	_draw_details(item)


func inspected() -> ShopItem:
	return _inspected


func close_inspect() -> void:
	_end_inspect(false)


func _end_inspect(instant: bool) -> void:
	if _inspected == null:
		return
	if is_instance_valid(_inspected):
		_inspected.put_back(instant)
	_inspected = null
	_dim(false)
	for t in _tags:
		if is_instance_valid(t[0]):
			(t[0] as Control).modulate.a = 1.0
	if is_instance_valid(_details):
		_details.queue_free()
	_details = null


## Baja las luces del bar mientras se mira un objeto (él trae su propia luz).
func _dim(on: bool) -> void:
	world.dim(on, DIM)


## "Medio premio", "un premio"…: el precio comparado con el premio de esta ronda.
const PRIZE_SHARES := [[0.25, "UI_SHARE_QUARTER"], [0.5, "UI_SHARE_HALF"], [1.0, "UI_SHARE_ONE"],
	[1.5, "UI_SHARE_ONE_HALF"], [2.0, "UI_SHARE_TWO"], [3.0, "UI_SHARE_THREE"]]


func prize_share(price: int) -> String:
	var prize := maxi(1, rc.economy.base_prize(rc.state.round))
	var ratio := float(price) / float(prize)
	var best: Array = PRIZE_SHARES[0]
	for option in PRIZE_SHARES:
		if absf(ratio - float(option[0])) < absf(ratio - float(best[0])):
			best = option
	return UiText.t(best[1])


func _draw_details(item: ShopItem) -> void:
	var s := rc.state
	var def := item.def
	var key := "UI_AMULET_" + String(def.id).to_upper()
	_details = VBoxContainer.new()
	_details.name = "Details"
	_details.anchor_left = 0.52
	_details.anchor_right = 0.95
	_details.anchor_top = 0.15
	_details.anchor_bottom = 0.9
	_details.add_theme_constant_override("separation", 4)
	add_child(_details)
	var stored := item.has_meta("wardrobe")
	var level := s.loadout.level(def.id) if item.owned else (int(rc.wardrobe().get("level", 1)) if stored else 0)
	# Se lee en este orden: qué es, qué hace, los datos chicos y, separado, lo que cuesta y
	# el botón. Cada nivel tiene su tamaño y su brillo; lo obvio no se escribe.
	var display_name: String = UiText.t(key) + ("  " + ROMAN[level] if level > 0 else "")
	var title := RingStyle.reading_label(display_name, DETAIL_TITLE)
	title.name = "DetailName"
	title.add_theme_color_override("default_color", RARITY_COLORS[def.rarity].lerp(Color.WHITE, 0.3))
	_details.add_child(title)
	var what := RingStyle.reading_label(_wrap_wide(UiText.t(key + "_DESC")), DETAIL_BODY)
	what.name = "DetailWhat"
	_details.add_child(what)
	var uses := UiText.t("UI_DETAIL_ACTIVE") % def.charges if def.kind == AmuletDef.Kind.ACTIVE \
		else UiText.t("UI_DETAIL_PASSIVE")
	var meta := RingStyle.reading_label(" · ".join([
		UiText.t("UI_RARITY_" + AmuletDef.Rarity.keys()[def.rarity]), CATEGORY_NAMES.get(def.category, ""), uses]),
		DETAIL_SMALL)
	meta.name = "DetailMeta"
	meta.add_theme_color_override("default_color", MUTED)
	_details.add_child(meta)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, DETAIL_GAP)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details.add_child(gap)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	_details.add_child(row)
	if stored:
		_wardrobe_details(row)
	elif not item.owned:
		var i: int = item.get_meta("offer", -1)
		var price := rc.shop.price_of(def, s)
		var quote := rc.shop.quote(price, s)
		var slots_full := s.loadout.equipped().size() >= Loadout.SLOTS
		var price_label := RingStyle.reading_label(UiText.t("UI_SHOP_PRICE") % UiText.money(price), DETAIL_PRICE)
		price_label.name = "DetailPrice"
		row.add_child(price_label)
		# El precio comparado con lo que acabás de ganar: se entiende de un vistazo.
		var share := RingStyle.reading_label(prize_share(price), DETAIL_SMALL)
		share.name = "PrizeShare"
		share.add_theme_color_override("default_color", MUTED)
		row.add_child(share)
		var why := ""
		if slots_full:
			why = UiText.t("UI_SHOP_WHY_FULL")
		elif not quote["ok"]:
			why = UiText.t("UI_SHOP_WHY_MONEY")
		elif int(quote["fiado"]) > 0:
			why = UiText.t("UI_SHOP_SPLIT") % [int(quote["paid"]), int(quote["fiado"])]
		_warn(row, why)
		_main_action(ScreenTools.button(row, UiText.t("UI_SHOP_BUY"), "Buy%d" % i, _buy_inspected.bind(i),
			quote["ok"] and not slots_full))
	else:
		var id: StringName = def.id
		var up := rc.shop.upgrade_price(id, s)
		if up >= 0:
			var can := bool(rc.shop.quote(up, s)["ok"]) and rc.shop.can_upgrade_now()
			if not rc.shop.can_upgrade_now():
				_warn(row, UiText.t("UI_SHOP_WHY_UPGRADED"))
			_main_action(ScreenTools.button(row, UiText.t("UI_SHOP_UPGRADE") % [ROMAN[level + 1], up],
				"Upgrade_" + String(id), _upgrade_inspected.bind(id), can))
		var value := rc.economy.sell_value(int(s.paid_for.get(id, 0)))
		RingStyle.shakify(ScreenTools.button(row, UiText.t("UI_SHOP_SELL") % value, "Sell_" + String(id),
			_sell_inspected.bind(id)))
		_store_button(row, id, true)
	# Salir es lo de menos: más chico y apagado.
	var close := ScreenTools.button(row, UiText.t("UI_DETAIL_CLOSE"), "CloseDetails", close_inspect)
	RingStyle.shakify(close)
	_quiet(close)


## Un aviso corto (por qué no se puede, o cuánto va al fiado), justo arriba del botón.
func _warn(parent: Container, why: String) -> void:
	if why == "":
		return
	var warn := RingStyle.reading_label(_wrap_wide(why), DETAIL_SMALL)
	warn.name = "DetailWarn"
	warn.add_theme_color_override("default_color", WARN)
	parent.add_child(warn)


## El botón principal: más grande, con un poco de aire arriba.
func _main_action(b: Button) -> void:
	RingStyle.shakify(b)
	b.add_theme_font_size_override("font_size", DETAIL_ACTION)
	var label := b.get_node_or_null("Shaky") as RichTextLabel
	if label != null:
		label.add_theme_font_size_override("normal_font_size", DETAIL_ACTION)
	b.custom_minimum_size.y = DETAIL_ACTION + 22


## Botón secundario: letra más chica y apagada (se dora igual al pasar el mouse).
func _quiet(b: Button) -> void:
	b.add_theme_font_size_override("font_size", DETAIL_SMALL + 2)
	var label := b.get_node_or_null("Shaky") as RichTextLabel
	if label != null:
		label.add_theme_font_size_override("normal_font_size", DETAIL_SMALL + 2)
		if not b.disabled:
			label.add_theme_color_override("default_color", MUTED)
			b.mouse_exited.connect(func() -> void: label.add_theme_color_override("default_color", MUTED))


## Guardado: cuánto se debe, cuánto aguanta y el botón para retirarlo.
func _wardrobe_details(row: Container) -> void:
	var s := rc.state
	var w := rc.wardrobe()
	var fee := int(w["fee"])
	var left := rc.wardrobe_runs_left()
	var lines: Array[String] = [UiText.t("UI_WARDROBE_HELP")]
	if fee > 0:
		lines.append(UiText.t("UI_WARDROBE_OWED") % fee)
	lines.append(UiText.t("UI_WARDROBE_LAST") if left <= 1 else UiText.t("UI_WARDROBE_LEFT") % (left - 1))
	for line in lines:
		var l := RingStyle.reading_label(_wrap_wide(line), DETAIL_SMALL)
		l.add_theme_color_override("default_color", MUTED)
		row.add_child(l)
	var why := ""
	if s.loadout.equipped().size() >= Loadout.SLOTS:
		why = UiText.t("UI_SHOP_WHY_FULL")
	elif s.loadout.has(w["id"]):
		why = UiText.t("UI_WARDROBE_SAME")
	elif not rc.shop.quote(fee, s)["ok"]:
		why = UiText.t("UI_SHOP_WHY_MONEY")
	_warn(row, why)
	_main_action(ScreenTools.button(row, UiText.t("UI_WARDROBE_TAKE") % fee, "Retrieve",
		_retrieve_inspected, why == ""))


## "Dejarlo en el guardarropas": apagado si ya hay algo guardado.
func _store_button(parent: Container, id: StringName, shaky: bool) -> void:
	var fee := rc.economy.wardrobe_round_fee(rc.state.round)
	var b := ScreenTools.button(parent, UiText.t("UI_WARDROBE_STORE") % fee, "Store_" + String(id),
		_store_inspected.bind(id) if shaky else _store.bind(id), rc.wardrobe().is_empty())
	if not rc.wardrobe().is_empty():
		b.tooltip_text = UiText.t("UI_WARDROBE_FULL")
	if shaky:
		RingStyle.shakify(b)


func _store(id: StringName) -> void:
	var r := rc.store_amulet(id)
	_message_bad = not r["ok"]
	_message = UiText.t("UI_WARDROBE_STORED") % _name_of(id) if r["ok"] else _reason(r["reason"])
	acted.emit()


func _retrieve() -> void:
	var id: StringName = rc.wardrobe().get("id", &"")
	var r := rc.retrieve_amulet()
	_message_bad = not r["ok"]
	_message = UiText.t("UI_WARDROBE_TAKEN") % _name_of(id) if r["ok"] else _reason(r["reason"])
	acted.emit()


func _store_inspected(id: StringName) -> void:
	_end_inspect(true)
	_store(id)


func _retrieve_inspected() -> void:
	_end_inspect(true)
	_retrieve()


func _buy_inspected(i: int) -> void:
	_end_inspect(true)
	_buy(i)


func _upgrade_inspected(id: StringName) -> void:
	_end_inspect(true)
	_upgrade(id)


func _sell_inspected(id: StringName) -> void:
	_end_inspect(true)
	_sell(id)


func _unhandled_input(event: InputEvent) -> void:
	if _inspected == null:
		return
	var mb := event as InputEventMouseButton
	var key := event as InputEventKey
	if (mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT) or \
			(key != null and key.pressed and key.keycode == KEY_ESCAPE):
		close_inspect()
		get_viewport().set_input_as_handled()


static func _wrap_wide(text: String) -> String:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" ", false):
		if line != "" and (line + " " + word).length() > 40:
			lines.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	if line != "":
		lines.append(line)
	return "\n".join(lines)


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


## El rival que le ganaste se fue; mientras elegís todavía está sentado.
func rival_pose() -> StringName:
	return &"away" if _at_counter else &"seated"


## Al pasar el mouse sobre un objeto se escribe su nombre arriba.
func _on_item_hover(item: ShopItem, on: bool) -> void:
	if is_instance_valid(_hover_label):
		for t in _tags.duplicate():
			if t[0] == _hover_label:
				_tags.erase(t)
		_hover_label.queue_free()
	_hover_label = null
	if not on or _inspected != null or not is_instance_valid(item):
		return
	_hover_label = world_label(_name_of(item.def.id), item.model, Vector3(0, 0.1, 0), 20)


func hover_text() -> String:
	return "" if not is_instance_valid(_hover_label) else _name_of(_hovered_id())


func _hovered_id() -> StringName:
	for t in _tags:
		if t[0] == _hover_label and t[1].get_parent() is ShopItem:
			return (t[1].get_parent() as ShopItem).def.id
	return &""
