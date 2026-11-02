extends Control
## Punto de entrada que crea el estado persistente y el controlador. En la vista
## 3D carga el bar una sola vez y pone las pantallas encima (Plan 7, Tarea 5).

const UI_JSON := "res://data/ui.json"
const BAR_SCENE := "res://world/bar_3d.tscn"

var rc: RunController
var router: ScreenRouter
var bar: Bar3D
var camera: CameraRig


func _ready() -> void:
	var meta := MetaState.load_from()
	var economy := Economy.load_from()
	rc = RunController.new(economy, meta, int(Time.get_unix_time_from_system()))
	var config: Dictionary = get_meta("force_view") if has_meta("force_view") else load_config()
	router = ScreenRouter.new()
	if String(config.get("view", "2d")) == "3d":
		_build_world(bool(config.get("ps1", true)), int(config.get("ps1_shrink", LowResView.SHRINK)))
	router.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(router)
	router.setup(rc)


func _build_world(ps1: bool, shrink: int) -> void:
	shrink = maxi(shrink, 1)
	Ps1Material.snap_resolution = Vector2(1280, 720) / shrink
	var view := LowResView.new()
	view.configure(ps1, shrink)
	add_child(view)
	bar = (load(BAR_SCENE) as PackedScene).instantiate() as Bar3D
	bar.ps1 = ps1
	view.add_world(bar)
	if ps1:
		Ps1Material.apply(bar)
	camera = CameraRig.new()
	bar.add_child(camera)
	camera.setup(bar)
	bar.camera = camera
	router.world = bar
	router.ps1 = ps1


func _process(_delta: float) -> void:
	if camera != null:
		camera.go_to(router.camera_marker())


static func load_config() -> Dictionary:
	if not FileAccess.file_exists(UI_JSON):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(UI_JSON)) != OK or not json.data is Dictionary:
		return {}
	return json.data
