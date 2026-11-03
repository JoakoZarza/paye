class_name TableProps
extends Node3D
## Lo que hay sobre la mesa ademÃ¡s de las cartas y la planilla:
## - el mazo, a la derecha del que es pie (cambia de lado con cada mano);
## - porotos en el medio con lo que vale la mano cuando se cantÃ³ truco;
## - una ficha por cada rival que ya le ganaste en esta corrida, al lado de la planilla.

## Mazo: si sos mano el pie es el rival y va a su derecha (tu izquierda, lejos);
## si es mano el rival, va a tu derecha.
const DECK_WHEN_PLAYER_MANO := Vector3(-0.36, 0.7505, -0.32)
const DECK_WHEN_DEALER_MANO := Vector3(0.37, 0.7505, 0.3)
const DECK_SIZE := Vector3(0.063, 0.014, 0.095)
const DECK_MOVE_SECONDS := 0.35
const POT_SPOT := Vector3(-0.24, 0.7505, 0.04)
const BEAN_SIZE := Vector3(0.014, 0.008, 0.01)
const BEAN_COLOR := Color("#B8AE98")
const CHIPS_SPOT := Vector3(0.41, 0.7505, -0.16)
const CHIP_RADIUS := 0.016
const CHIP_HEIGHT := 0.005
const CHIP_COLOR := Color("#D9A54A")

var ps1 := false
var deck: AssetSlot
var _beans: Array[Node3D] = []
var _chips: Array[Node3D] = []
var _mano := -1
var _deck_tween: Tween


func _ready() -> void:
	deck = AssetSlot.new()
	deck.name = "Deck"
	deck.asset_name = "deck"
	deck.placeholder_size = DECK_SIZE
	deck.placeholder_color = Color("#6E1A1A")
	deck.ps1 = ps1
	deck.position = DECK_WHEN_PLAYER_MANO
	add_child(deck)


## Lugar del mazo segÃºn quiÃ©n es mano (0 = vos, 1 = el rival).
static func deck_spot(mano: int) -> Vector3:
	return DECK_WHEN_PLAYER_MANO if mano == 0 else DECK_WHEN_DEALER_MANO


func set_mano(mano: int) -> void:
	if mano == _mano:
		return
	var first := _mano < 0
	_mano = mano
	var to := deck_spot(mano)
	if _deck_tween != null:
		_deck_tween.kill()
	if first or not is_inside_tree():
		deck.position = to
		return
	_deck_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_deck_tween.tween_property(deck, "position", to, DECK_MOVE_SECONDS)


func beans() -> int:
	return _beans.size()


func chips() -> int:
	return _chips.size()


## Porotos en juego: los que vale la mano con el truco cantado; 0 = no hay truco.
func set_stake(n: int) -> void:
	while _beans.size() > n:
		_beans.pop_back().queue_free()
	while _beans.size() < n:
		var i := _beans.size()
		var rng := RandomNumberGenerator.new()
		rng.seed = 4517 + i * 131
		var bean := _piece(SphereMesh.new(), BEAN_COLOR)
		(bean.mesh as SphereMesh).radius = 0.5
		(bean.mesh as SphereMesh).height = 1.0
		bean.scale = BEAN_SIZE
		bean.position = POT_SPOT + Vector3(rng.randf_range(-0.03, 0.03), BEAN_SIZE.y * 0.5, rng.randf_range(-0.025, 0.025))
		bean.rotation.y = rng.randf_range(0, TAU)
		_beans.append(bean)


## Una ficha por rival vencido, apiladas.
func set_chips(n: int) -> void:
	while _chips.size() > n:
		_chips.pop_back().queue_free()
	while _chips.size() < n:
		var i := _chips.size()
		var mesh := CylinderMesh.new()
		mesh.top_radius = CHIP_RADIUS
		mesh.bottom_radius = CHIP_RADIUS
		mesh.height = CHIP_HEIGHT
		mesh.radial_segments = 12
		var chip := _piece(mesh, CHIP_COLOR)
		chip.position = CHIPS_SPOT + Vector3(0.001 * (i % 2), CHIP_HEIGHT * (i + 0.5), 0)
		_chips.append(chip)


func _piece(mesh: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	node.material_override = material
	add_child(node)
	if ps1:
		Ps1Material.apply(node)
	return node
