class_name Card3D
extends Node3D
## Representa una carta clickeable sin filtrar cartas ocultas.

signal clicked(card_index: int)

const CARD_SIZE: Vector2 = Vector2(0.063, 0.095)

var card_index: int = -1
var _card: Card
var _revealed: bool = false
var _hover_tween: Tween
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
	var back_material := StandardMaterial3D.new()
	back_material.albedo_texture = CardTextures.back()
	if back_material.albedo_texture == null:
		back_material.albedo_color = Color("#6E1A1A")
	back_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
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


func set_hover(on: bool) -> void:
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "position:y", rest_y + (0.02 if on and hoverable else 0.0), 0.15)


func _show_face() -> void:
	if _card == null or not is_inside_tree():
		return
	var texture: Texture2D = CardTextures.face(_card)
	if texture != null:
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_face.material_override = material
		_face_label.visible = false
	else:
		_face.material_override = null
		_face_label.text = "%d\n%s" % [_card.effective_number(), CardTextures.SUIT_NAMES[_card.effective_suit()]]
		_face_label.visible = true
	_face.visible = true


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
		press()
