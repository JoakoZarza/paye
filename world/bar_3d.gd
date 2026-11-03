class_name Bar3D
extends Node3D
## Arma el bar a partir del catálogo de cubos provisorios.

const PLACEHOLDERS_PATH: String = "res://world/placeholders.json"
const SLOT_NAMES: Array[String] = ["table", "chair_player", "chair_rival", "rival_base", "lamp", "rival_head", "room", "bar_counter", "door", "window", "scoreboard", "accomplice"]
const MARKER_POSITIONS: Dictionary = {
	"CamSeat": Vector3(0, 1.2, 0.62), "CamBar": Vector3(1.6, 1.6, 2.6), "CamShop": Vector3(0, 1.55, -2.3),
	"PlayerHand": Vector3(0, 0.99, 0.43), "DealerHand": Vector3(0, 0.95, -0.42),
	"Baza1_Player": Vector3(-0.12, 0.755, 0.08), "Baza1_Dealer": Vector3(-0.12, 0.755, -0.08),
	"Baza2_Player": Vector3(0, 0.756, 0.08), "Baza2_Dealer": Vector3(0, 0.756, -0.08),
	"Baza3_Player": Vector3(0.12, 0.757, 0.08), "Baza3_Dealer": Vector3(0.12, 0.757, -0.08),
	"Deck": Vector3(-0.36, 0.77, -0.32), "AmuletTray": Vector3(-0.3, 0.76, 0.3),
	"DealerItems": Vector3(-0.24, 0.7505, -0.16),
	"Scoreboard": Vector3(1.4, 1.8, -3.9), "TellAnchor": Vector3(0, 1.75, -0.7),
	"SpeechAnchor": Vector3(-0.5, 1.05, -0.5),
	"ScoreSheet": Vector3(0.27, 0.7505, -0.1),
	"PathStand": Vector3(0, 1.6, 1.05), "PathSide": Vector3(1.25, 1.6, 0.7), "PathCounter": Vector3(0.9, 1.6, -1.6),
}
## Grados (x = mirar arriba/abajo, y = girar). Sin entrada: mira hacia -Z.
const MARKER_ROTATIONS: Dictionary = {
	"CamSeat": Vector2(-17, 0), "CamBar": Vector2(-18, 25), "CamShop": Vector2(-20, 0),
	"PathStand": Vector2(-15, 0), "PathSide": Vector2(-10, 20), "PathCounter": Vector2(-12, 10),
}

## Se fija antes de entrar al árbol: los huecos aplican el filtro PS1 al cargar.
var ps1 := false
## La cámara del jugador, para que la mesa sepa hacia dónde mira.
var camera: CameraRig
var _slots: Dictionary = {}


func _ready() -> void:
	_build()


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
