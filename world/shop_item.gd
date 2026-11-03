class_name ShopItem
extends Node3D
## Un amuleto apoyado en el mantel de la barra, con su cartelito de papel escrito a
## mano al lado (el precio, o el nivel si ya es tuyo). Clic derecho (o izquierdo) pide
## verlo de cerca: se levanta, va a la izquierda de la pantalla y levita girando.

signal inspect_requested(item: ShopItem)
signal hovered(item: ShopItem, on: bool)

const SIZE := Vector3(0.075, 0.035, 0.075)
const TAG_SIZE := Vector2(0.1, 0.055)
const TAG_COLOR := Color("#D8C9A3")
const INK := Color("#2A1A12")
const HANDWRITING_FONT := "res://assets/fonts/handwriting.ttf"
## Viéndolo de cerca: cuánto gira por segundo, cuánto sube y baja y a qué ritmo.
const SPIN := 0.9
const BOB := 0.012
const BOB_SPEED := 1.6
const MOVE_SECONDS := 0.35
## Dónde queda la luz que lo alumbra de cerca, respecto de donde flota.
const LIGHT_OFFSET := Vector3(0.12, 0.14, 0.18)

var def: AmuletDef
var owned := false
var tag_text := ""
var ps1 := false
var model: AssetSlot
var _rest: Transform3D
var _levitating := false
var _lift_at := Vector3.ZERO
var _face := Basis.IDENTITY
var _spin := 0.0
var _time := 0.0
var _tween: Tween
var _light: OmniLight3D


func setup(p_def: AmuletDef, p_tag: String, p_owned: bool, color: Color) -> void:
	def = p_def
	tag_text = p_tag
	owned = p_owned
	name = "ShopItem_" + String(def.id)
	model = AssetSlot.new()
	model.asset_name = "amulet_" + String(def.id)
	model.placeholder_size = SIZE
	model.placeholder_color = color
	model.ps1 = ps1
	add_child(model)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE + Vector3(0.03, 0.04, 0.03)
	shape.shape = box
	shape.position.y = SIZE.y * 0.5
	area.add_child(shape)
	model.add_child(area)
	area.input_event.connect(_on_input)
	area.mouse_entered.connect(func() -> void: hovered.emit(self, true))
	area.mouse_exited.connect(func() -> void: hovered.emit(self, false))
	_add_tag()


## El cartelito: un papel apoyado, torcido, con el texto en tinta.
func _add_tag() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(def.id)
	var paper := MeshInstance3D.new()
	paper.name = "Tag"
	var quad := QuadMesh.new()
	quad.size = TAG_SIZE
	paper.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_color = TAG_COLOR
	paper.material_override = material
	paper.rotation = Vector3(-PI * 0.5, rng.randf_range(-0.25, 0.25), 0)
	paper.position = Vector3(SIZE.x * 0.5 + 0.06, 0.001, SIZE.z * 0.5 + 0.015)
	add_child(paper)
	if ps1:
		Ps1Material.apply(paper)
	var ink := Label3D.new()
	ink.name = "TagText"
	ink.text = tag_text
	ink.font_size = 48
	ink.pixel_size = 0.0009
	ink.outline_size = 0
	ink.modulate = INK
	ink.shaded = false
	ink.double_sided = false
	if ResourceLoader.exists(HANDWRITING_FONT):
		ink.font = load(HANDWRITING_FONT)
	ink.position = Vector3(0, 0, 0.001)
	ink.rotation.z = rng.randf_range(-0.12, 0.12)
	paper.add_child(ink)


func inspecting() -> bool:
	return _levitating


## Se levanta hasta at (en el mundo) y queda levitando y girando.
## Se levanta hasta at (en el mundo), se pone de frente a la vista (face: la orientación
## de la cámara) y queda levitando, girando sobre su propio eje vertical.
func lift_to(at: Vector3, face := Basis.IDENTITY) -> void:
	_rest = model.global_transform
	_face = face.orthonormalized()
	_spin = 0.0
	if _tween != null:
		_tween.kill()
	_light = OmniLight3D.new()
	_light.light_color = Color("#ffd9a0")
	_light.light_energy = 1.4
	_light.omni_range = 0.5
	# Colgada del cartel, no del objeto: así no gira con él.
	add_child(_light)
	_light.global_position = at + _face * LIGHT_OFFSET
	_levitating = true
	_time = 0.0
	_lift_at = at
	if not is_inside_tree():
		model.global_transform = Transform3D(_face, at)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_blend_to.bind(_rest, Transform3D(_face, at)), 0.0, 1.0, MOVE_SECONDS)


func _blend_to(t: float, from: Transform3D, to: Transform3D) -> void:
	model.global_transform = from.interpolate_with(to, t)


## Vuelve a apoyarse donde estaba.
func put_back(instant := false) -> void:
	if not _levitating:
		return
	_levitating = false
	if _tween != null:
		_tween.kill()
	if is_instance_valid(_light):
		_light.queue_free()
	if instant or not is_inside_tree():
		model.global_transform = _rest
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_blend_to.bind(model.global_transform, _rest), 0.0, 1.0, MOVE_SECONDS)


## De frente a la vista: el eje vertical del objeto es el de la cámara.
func facing() -> Basis:
	return _face


func _process(delta: float) -> void:
	if not _levitating or (_tween != null and _tween.is_running()):
		return
	_time += delta
	_spin = fmod(_spin + SPIN * delta, TAU)
	var bob := _face.y * sin(_time * BOB_SPEED) * BOB
	model.global_transform = Transform3D(_face * Basis(Vector3.UP, _spin), _lift_at + bob)


func _on_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_LEFT]:
		inspect_requested.emit(self)
