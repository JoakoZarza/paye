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
## Parpadeo al salir del menú: cerrar, quedarse cerrado y abrir (segundos).
const BLINK_CLOSE := 0.09
const BLINK_HOLD := 0.08
const BLINK_OPEN := 0.3

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
var _hud: RichTextLabel
var _hud_plain := ""


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
		if _screen_name == &"start" and world != null:
			blink()
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
	_backdrop.color.a = _screen.backdrop_alpha()
	move_child(_backdrop, 0)
	world.set_rival_pose(_screen.rival_pose())
	# Sin fondo, la pantalla no ataja el mouse: la cámara lo sigue y los clics llegan al bar.
	if not _screen.wants_backdrop():
		_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_hud()


func _update_hud() -> void:
	if _hud == null:
		_hud = RingStyle.reading_label("", 16)
		_hud.name = "Hud"
		_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_hud.offset_left = -380
		_hud.offset_right = -16
		_hud.offset_top = 12
		_hud.modulate.a = 0.8
		add_child(_hud)
	move_child(_hud, get_child_count() - 1)
	var s := rc.state if rc != null else null
	_hud.visible = s != null and _screen.wants_hud()
	if s != null:
		_hud_plain = UiText.t("UI_HUD_MONEY") % [s.money, s.fiado, s.debt]
		_hud.text = "[right]" + RingStyle.JITTER % _hud_plain + "[/right]"


func hud_text() -> String:
	return _hud_plain


func camera_marker() -> StringName:
	return &"CamBar" if _screen == null else _screen.camera_marker()


## Un parpadeo: la pantalla se apaga un instante y vuelve.
func blink() -> void:
	var lid := ColorRect.new()
	lid.name = "Blink"
	lid.color = Color(0, 0, 0, 0)
	lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lid)
	if not is_inside_tree():
		lid.queue_free()
		return
	var t := create_tween()
	t.tween_property(lid, "color:a", 1.0, BLINK_CLOSE)
	t.tween_interval(BLINK_HOLD)
	t.tween_property(lid, "color:a", 0.0, BLINK_OPEN)
	t.tween_callback(lid.queue_free)
