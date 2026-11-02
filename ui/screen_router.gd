class_name ScreenRouter
extends Control
## Selecciona la pantalla para la fase actual.

const SCREENS := {
	&"start": "res://ui/screens/start_screen.tscn",
	&"bar": "res://ui/screens/bar_screen.tscn",
	&"table": "res://ui/screens/table_screen.tscn",
	&"one_more": "res://ui/screens/one_more_screen.tscn",
	&"shop": "res://ui/screens/shop_screen.tscn",
	&"free": "res://ui/screens/free_screen.tscn",
	&"death": "res://ui/screens/death_screen.tscn",
	&"ending": "res://ui/screens/ending_screen.tscn",
}

var rc: RunController
var _screen: BaseScreen
var _screen_name: StringName = &""


func setup(p_rc: RunController) -> void:
	rc = p_rc
	refresh()


func screen_for_phase() -> StringName:
	if rc == null or rc.state == null:
		return &"start"
	match rc.phase:
		RunController.Phase.BAR:
			return &"bar"
		RunController.Phase.MATCH, RunController.Phase.BILL_HAND:
			return &"table"
		RunController.Phase.ONE_MORE:
			return &"table" if rc.one_more_staked() else &"one_more"
		RunController.Phase.SHOP:
			return &"shop"
		RunController.Phase.FREE:
			return &"free"
		RunController.Phase.DEAD:
			return &"death"
		RunController.Phase.RETIRED, RunController.Phase.CONDEMNED:
			return &"ending"
	return &"start"


func refresh() -> void:
	var next_name := screen_for_phase()
	if _screen_name != next_name:
		if _screen != null:
			_screen.queue_free()
		_screen = null
		_screen_name = next_name
		var path: String = SCREENS[next_name]
		if ResourceLoader.exists(path):
			_screen = load(path).instantiate() as BaseScreen
		else:
			var placeholder := PlaceholderScreen.new()
			placeholder.configure(next_name)
			_screen = placeholder
		_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_screen)
		_screen.acted.connect(refresh)
		_screen.setup(rc)
	else:
		_screen.refresh()
