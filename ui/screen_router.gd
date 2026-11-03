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

## Fondo oscuro para leer las pantallas que no son la mesa sobre el bar 3D.
const BACKDROP := Color(0.03, 0.03, 0.03, 0.78)

var rc: RunController
## El bar 3D de fondo; null en la vista 2D.
var world: Bar3D
var ps1 := false
## Ganaste y elegiste quedarte en la mesa: el bar y el rival nuevo te encuentran sentado.
var stay_seated := false
var _screen: BaseScreen
var _screen_name: StringName = &""
var _backdrop: ColorRect
## Vista 3D: la plata, el fiado y la deuda en una esquina, chiquitos.
var _hud: Label


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
		_screen.world = world
		_screen.ps1 = ps1
		_screen.router = self
		if next_name == &"table":
			stay_seated = false
		add_child(_screen)
		_screen.acted.connect(refresh)
		_screen.setup(rc)
	else:
		_screen.refresh()
	_update_backdrop()


func _update_backdrop() -> void:
	if world == null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _backdrop == null:
		_backdrop = ColorRect.new()
		_backdrop.color = BACKDROP
		_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_backdrop)
	_backdrop.visible = _screen.wants_backdrop()
	move_child(_backdrop, 0)
	# Sin fondo, la pantalla no ataja el mouse: la cámara lo sigue y los clics llegan al bar.
	if not _screen.wants_backdrop():
		_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_hud()


func _update_hud() -> void:
	if _hud == null:
		_hud = Label.new()
		_hud.name = "Hud"
		_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_hud.offset_left = -360
		_hud.offset_right = -16
		_hud.offset_top = 12
		_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_hud.add_theme_font_size_override("font_size", 16)
		_hud.add_theme_color_override("font_color", RingStyle.COLOR)
		_hud.add_theme_constant_override("outline_size", 6)
		_hud.add_theme_color_override("font_outline_color", Color.BLACK)
		_hud.modulate.a = 0.75
		add_child(_hud)
	move_child(_hud, get_child_count() - 1)
	var s := rc.state if rc != null else null
	_hud.visible = s != null
	if s != null:
		_hud.text = UiText.t("UI_HUD_MONEY") % [s.money, s.fiado, s.debt]


func hud_text() -> String:
	return _hud.text if _hud != null else ""


func camera_marker() -> StringName:
	return &"CamBar" if _screen == null else _screen.camera_marker()
