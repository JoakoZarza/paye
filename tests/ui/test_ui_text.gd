extends GutTest


func test_spanish_lookup_and_missing_key() -> void:
	assert_eq(UiText.t("UI_SIN_IRA"), "La Ira")
	assert_eq(UiText.t("UI_UNKNOWN_KEY"), "UI_UNKNOWN_KEY")
