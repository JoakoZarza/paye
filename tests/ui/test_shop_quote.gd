extends GutTest
const META_PATH := "user://test_meta_shop_quote.json"
func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
func test_quote_matches_purchase_payment_split() -> void:
	var economy := Economy.load_from()
	var rc := RunController.new(economy, MetaState.new(), 4, META_PATH)
	rc.start_run(&"normal"); rc.state.money = 0; rc.state.fiado = 0
	rc.phase = RunController.Phase.SHOP
	rc.shop.open(rc.state)
	var def: AmuletDef = rc.shop.offers[0]
	var price := rc.shop.price_of(def, rc.state)
	var quote := rc.shop.quote(price, rc.state)
	var result := rc.buy(0)
	assert_eq(result.paid, quote.paid)
	assert_eq(result.fiado, quote.fiado)
	assert_eq(result.ok, quote.ok)
