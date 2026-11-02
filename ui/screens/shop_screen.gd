extends BaseScreen
## Muestra las ofertas de la tienda y permite comprar, mejorar, vender y avanzar.


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	var s := rc.state
	ScreenTools.label(box, UiText.t("UI_SHOP_INFO") % [
		s.round, s.money, s.fiado, rc.economy.entry(s.round + 1),
	], 24)
	if rc.rival_for(s.round).sin != &"alma":
		ScreenTools.label(box, UiText.t("UI_SHOP_PREMIUM"))
	for i in rc.shop.offers.size():
		var def: AmuletDef = rc.shop.offers[i]
		var price := rc.shop.price_of(def, s)
		var quote := rc.shop.quote(price, s)
		var rarity_key: String = "UI_RARITY_" + AmuletDef.Rarity.keys()[def.rarity]
		var offer_text := "%s · %s · %s · $%d%s" % [
			UiText.t("UI_AMULET_" + String(def.id).to_upper()),
			UiText.t(rarity_key),
			UiText.t("UI_AMULET_" + String(def.id).to_upper() + "_DESC"),
			price,
			UiText.t("UI_SHOP_CREDIT") if int(quote["fiado"]) > 0 else "",
		]
		ScreenTools.label(box, offer_text)
		ScreenTools.button(
			box, UiText.t("UI_SHOP_BUY"), "Buy%d" % i, _buy.bind(i), bool(quote["ok"]),
		)
	for def in s.loadout.equipped():
		var id: StringName = def.id
		var up := rc.shop.upgrade_price(id, s)
		ScreenTools.label(box, "%s · %s %d" % [
			UiText.t("UI_AMULET_" + String(id).to_upper()),
			UiText.t("UI_LEVEL"), s.loadout.level(id),
		])
		ScreenTools.button(
			box, UiText.t("UI_SHOP_UPGRADE") % up, "Upgrade_" + String(id), _upgrade.bind(id),
			up >= 0,
		)
		ScreenTools.button(
			box, UiText.t("UI_SHOP_SELL") % rc.economy.sell_value(int(s.paid_for.get(id, 0))),
			"Sell_" + String(id), _sell.bind(id),
		)
	var cost := rc.economy.reroll_cost(s.round, rc.shop.rerolls)
	ScreenTools.button(
		box, UiText.t("UI_SHOP_REROLL") % cost, "Reroll", _reroll, s.money >= cost,
	)
	ScreenTools.button(box, UiText.t("UI_SHOP_NEXT"), "Next", _next)


func _buy(i: int) -> void:
	rc.buy(i)
	acted.emit()


func _upgrade(id: StringName) -> void:
	rc.upgrade(id)
	acted.emit()


func _sell(id: StringName) -> void:
	rc.sell(id)
	acted.emit()


func _reroll() -> void:
	rc.reroll()
	acted.emit()


func _next() -> void:
	rc.next_round()
	acted.emit()
