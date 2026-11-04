class_name Bar3D
extends Node3D
## Arma el bar a partir del catálogo de cubos provisorios.

const PLACEHOLDERS_PATH: String = "res://world/placeholders.json"
const SLOT_NAMES: Array[String] = ["table", "chair_player", "chair_rival", "rival_base", "lamp", "rival_head", "room", "bar_counter", "door", "window", "scoreboard", "accomplice"]
const MARKER_POSITIONS: Dictionary = {
	"CamSeat": Vector3(0, 1.2, 0.62), "CamBar": Vector3(1.6, 1.6, 2.6), "CamShop": Vector3(-2.9, 1.86, -0.3),
	"PlayerHand": Vector3(0, 0.99, 0.43), "DealerHand": Vector3(0, 0.95, -0.42),
	"Baza1_Player": Vector3(-0.12, 0.755, 0.08), "Baza1_Dealer": Vector3(-0.12, 0.755, -0.08),
	"Baza2_Player": Vector3(0, 0.756, 0.08), "Baza2_Dealer": Vector3(0, 0.756, -0.08),
	"Baza3_Player": Vector3(0.12, 0.757, 0.08), "Baza3_Dealer": Vector3(0.12, 0.757, -0.08),
	"Deck": Vector3(-0.36, 0.77, -0.32), "AmuletTray": Vector3(-0.3, 0.76, 0.3),
	"DealerItems": Vector3(-0.24, 0.7505, -0.16),
	"Scoreboard": Vector3(1.4, 1.8, -3.9), "TellAnchor": Vector3(0, 1.75, -0.7),
	"SpeechAnchor": Vector3(-0.45, 1.18, -0.55),
	"ScoreSheet": Vector3(0.32, 0.7505, -0.08),
	"PathStand": Vector3(0, 1.6, 1.05), "PathSide": Vector3(1.25, 1.6, 0.7), "PathLeft": Vector3(-1.3, 1.65, 0.55),
}
## Grados (x = mirar arriba/abajo, y = girar). Sin entrada: mira hacia -Z.
const MARKER_ROTATIONS: Dictionary = {
	"CamSeat": Vector2(-17, 0), "CamBar": Vector2(-18, 25), "CamShop": Vector2(-62, 90),
	# Los diálogos del rival, como un cartel un poco girado hacia vos.
	"SpeechAnchor": Vector2(6, 25),
	"PathStand": Vector2(-15, 0), "PathSide": Vector2(-10, 20), "PathLeft": Vector2(-20, 70),
}

## Se fija antes de entrar al árbol: los huecos aplican el filtro PS1 al cargar.
var ps1 := false
## La cámara del jugador, para que la mesa sepa hacia dónde mira.
var camera: CameraRig
var _slots: Dictionary = {}
var life: BarLife
var _rival_pose := &"seated"
var _rival_tween: Tween

## El rival: sentado a la mesa, parado al lado de su silla a medio sentarse (esperándote)
## o fuera de la escena. Desplazamiento y cabeceo respecto de sentado.
const RIVAL_POSES := {
	&"seated": [Vector3.ZERO, 0.0],
	&"waiting": [Vector3(0.52, 0.12, 0.08), -0.18],
}
const RIVAL_PARTS := ["rival_base", "rival_head"]
const RIVAL_SIT_SECONDS := 0.8


func _ready() -> void:
	_build()


## Baja las luces del bar mientras se mira algo de cerca (eso trae su propia luz).
func dim(on: bool, factor := 0.15) -> void:
	for light_name in ["LampLight", "DimFill", "CounterLight"]:
		var light := get_node_or_null(light_name) as Light3D
		if light == null:
			continue
		if not light.has_meta("bright"):
			light.set_meta("bright", light.light_energy)
		var bright: float = light.get_meta("bright")
		light.light_energy = bright * (factor if on else 1.0)
	var env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env != null and env.environment != null:
		if not env.has_meta("bright"):
			env.set_meta("bright", env.environment.ambient_light_energy)
		var bright_env: float = env.get_meta("bright")
		env.environment.ambient_light_energy = bright_env * (factor if on else 1.0)


func marker(node_name: String) -> Marker3D:
	return get_node_or_null(node_name) as Marker3D


func slot(node_name: String) -> AssetSlot:
	return _slots.get(node_name) as AssetSlot


func _build() -> void:
	var file := FileAccess.open(PLACEHOLDERS_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir placeholders.json")
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_error("placeholders.json inválido: %s" % parser.get_error_message())
		return
	var catalog: Dictionary = parser.data as Dictionary
	for asset_key: String in SLOT_NAMES:
		if not catalog.has(asset_key):
			continue
		var data: Dictionary = catalog[asset_key]
		var asset_slot := AssetSlot.new()
		asset_slot.name = asset_key
		asset_slot.asset_name = str(data.get("asset_name", asset_key))
		asset_slot.placeholder_size = _vector3(data["size"])
		asset_slot.placeholder_color = Color.from_string(str(data["color"]), Color.GRAY)
		asset_slot.position = _vector3(data["position"])
		asset_slot.rotation.y = deg_to_rad(float(data["rotation_y"]))
		asset_slot.placeholder_inside = bool(data.get("inside", false))
		asset_slot.ps1 = ps1
		asset_slot.visible = not bool(data.get("hidden", false))
		add_child(asset_slot)
		_slots[asset_key] = asset_slot
	life = BarLife.new()
	life.name = "BarLife"
	life.ps1 = ps1
	add_child(life)
	_add_floor()
	_add_lights()
	_add_environment()
	for marker_name: String in MARKER_POSITIONS:
		var point := Marker3D.new()
		point.name = marker_name
		point.position = MARKER_POSITIONS[marker_name]
		var turn: Vector2 = MARKER_ROTATIONS.get(marker_name, Vector2.ZERO)
		point.rotation = Vector3(deg_to_rad(turn.x), deg_to_rad(turn.y), 0)
		add_child(point)


func _vector3(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _add_floor() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(8, 0.1, 8)
	floor.mesh = mesh
	floor.position = Vector3(0, -0.05, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#282521")
	floor.material_override = material
	add_child(floor)


func _add_lights() -> void:
	var lamp_light := SpotLight3D.new()
	lamp_light.name = "LampLight"
	lamp_light.position = Vector3(0, 1.9, 0)
	lamp_light.rotation = Vector3(deg_to_rad(-90), 0, 0)
	lamp_light.light_color = Color("#ffc77a")
	lamp_light.light_energy = 2.2
	lamp_light.spot_range = 5.0
	lamp_light.spot_angle = 55.0
	add_child(lamp_light)
	var fill := OmniLight3D.new()
	fill.name = "DimFill"
	fill.position = Vector3(0, 2.4, 1.5)
	fill.light_color = Color("#8291a0")
	fill.light_energy = 0.35
	fill.omni_range = 7.0
	add_child(fill)
	# Una luz baja sobre la barra, para ver lo que se vende.
	var counter := OmniLight3D.new()
	counter.name = "CounterLight"
	counter.position = Vector3(-2.9, 2.0, -0.3)
	counter.light_color = Color("#ffc77a")
	counter.light_energy = 1.3
	counter.omni_range = 2.6
	add_child(counter)


func _add_environment() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#111316")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#52606b")
	environment.ambient_light_energy = 0.28
	environment.fog_enabled = true
	environment.fog_light_color = Color("#282a2c")
	environment.fog_density = 0.035
	environment_node.environment = environment
	add_child(environment_node)


func rival_pose() -> StringName:
	return _rival_pose


## Mueve al rival a una pose: &"seated", &"waiting" o &"away" (no está).
func set_rival_pose(pose: StringName, instant := false) -> void:
	if pose == _rival_pose:
		return
	var from := _rival_pose
	_rival_pose = pose
	if _rival_tween != null:
		_rival_tween.kill()
	for part in RIVAL_PARTS:
		var s := slot(part)
		if s == null:
			continue
		if not s.has_meta("home"):
			s.set_meta("home", s.position)
		s.visible = pose != &"away"
	if pose == &"away":
		return
	var p: Array = RIVAL_POSES[pose]
	# Aparece ya en su pose; de esperar a sentado, se sienta despacio.
	var animate := not instant and is_inside_tree() and from == &"waiting" and pose == &"seated"
	if animate:
		_rival_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for part in RIVAL_PARTS:
		var s := slot(part)
		if s == null:
			continue
		var at: Vector3 = (s.get_meta("home") as Vector3) + (p[0] as Vector3)
		if animate:
			_rival_tween.tween_property(s, "position", at, RIVAL_SIT_SECONDS)
			_rival_tween.tween_property(s, "rotation:x", float(p[1]), RIVAL_SIT_SECONDS)
		else:
			s.position = at
			s.rotation.x = p[1]
