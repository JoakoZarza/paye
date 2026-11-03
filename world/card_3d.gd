class_name Card3D
extends Node3D
## Representa una carta clickeable sin filtrar cartas ocultas.

signal clicked(card_index: int)
## Mouse encima o no, para todas las cartas (las de la mesa también).
signal hover_changed(on: bool)

const CARD_SIZE: Vector2 = Vector2(0.063, 0.095)
const PEEK_LIFT := 0.03
const BACK_GLOW := 0.45

var card_index: int = -1
var _card: Card
var _revealed: bool = false
var _hover_tween: Tween
var _move_tween: Tween
## Número y palo que muestra la cara.
var _shown := Vector2i(-1, -1)
## Altura de reposo; la mesa la actualiza cuando mueve la carta.
var rest_y: float = 0.0
## Solo las cartas de tu mano se levantan al pasar el mouse.
var hoverable: bool = true

@onready var _face: MeshInstance3D = $Face
@onready var _back: MeshInstance3D = $Back
@onready var _face_label: Label3D = $FaceLabel
@onready var _area: Area3D = $Area3D


func _ready() -> void:
	rest_y = position.y
	var quad := QuadMesh.new()
	quad.size = CARD_SIZE
	_face.mesh = quad
	_back.mesh = quad
	_face.position.z = 0.0005
	_back.position.z = -0.0005
	_back.rotation.y = PI
	_face_label.position.z = 0.001
	_face_label.double_sided = false
	var back_material := StandardMaterial3D.new()
	back_material.albedo_texture = CardTextures.back()
	if back_material.albedo_texture == null:
		back_material.albedo_color = Color("#6E1A1A")
	back_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# Brilla un poco solo: el borde claro se ve aunque el rival las tenga en la sombra.
	back_material.emission_enabled = true
	back_material.emission_texture = back_material.albedo_texture
	back_material.emission_energy_multiplier = BACK_GLOW
	back_material.set_meta(Ps1Material.SINGLE_SIDE_META, true)
	_back.material_override = back_material
	_face.visible = false
	_face_label.visible = false
	_area.input_event.connect(_on_input_event)
	_area.mouse_entered.connect(set_hover.bind(true))
	_area.mouse_exited.connect(set_hover.bind(false))
	if _card != null and _revealed:
		_show_face()


func setup_card(p_card: Card, p_card_index: int, dealer: bool, revealed: bool = true) -> void:
	card_index = p_card_index
	_revealed = revealed
	_card = null if dealer and not revealed else p_card
	if is_node_ready():
		_face.visible = false
		_face.material_override = null
		_face_label.visible = false
		_face_label.text = ""
	if is_node_ready() and _card != null and _revealed:
		_show_face()


func reveal(p_card: Card) -> void:
	_card = p_card
	_revealed = true
	_show_face()


func press() -> void:
	if _card != null:
		clicked.emit(card_index)


## Mueve la carta a su lugar; un movimiento nuevo corta al anterior y al de hover.
func move_to(pos: Vector3, rot: Vector3, seconds: float) -> void:
	rest_y = pos.y
	if _move_tween != null and _move_tween.is_running():
		_move_tween.kill()
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	if not is_inside_tree():
		position = pos
		rotation = rot
		return
	_move_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", pos, seconds)
	_move_tween.tween_property(self, "rotation", rot, seconds)


## La cara mostrada ya no coincide con la carta (el Marcador la cambió).
func face_is_stale(p_card: Card) -> bool:
	return _revealed and _shown != Vector2i(p_card.effective_number(), p_card.effective_suit())


func set_hover(on: bool) -> void:
	hover_changed.emit(on)
	if _move_tween != null and _move_tween.is_running():
		return
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "position:y", rest_y + (0.02 if on and hoverable else 0.0), 0.15)


## Levantarla un poco de la mesa para mirarla (inclinado sobre la mesa).
func peek(on: bool) -> void:
	if _move_tween != null and _move_tween.is_running():
		return
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "position:y", rest_y + (PEEK_LIFT if on else 0.0), 0.15)


func _show_face() -> void:
	if _card == null or not is_inside_tree():
		return
	_shown = Vector2i(_card.effective_number(), _card.effective_suit())
	var texture: Texture2D = CardTextures.face(_card)
	if texture != null:
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.set_meta(Ps1Material.SINGLE_SIDE_META, true)
		_face.material_override = material
		_face_label.visible = false
	else:
		var plain := StandardMaterial3D.new()
		plain.set_meta(Ps1Material.SINGLE_SIDE_META, true)
		_face.material_override = plain
		_face_label.text = "%d\n%s" % [_card.effective_number(), CardTextures.SUIT_NAMES[_card.effective_suit()]]
		_face_label.visible = true
	_face.visible = true


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
		press()
