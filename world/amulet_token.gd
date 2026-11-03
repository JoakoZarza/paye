class_name AmuletToken
extends Node3D
## Un amuleto apoyado en la mesa. Si se puede usar, se levanta al pasar el mouse y
## un clic lo usa. Carga res://assets/models/amulet_<id>.glb o muestra un cubito.

signal pressed(id: StringName, needs: StringName)

const SIZE := Vector3(0.05, 0.025, 0.05)
const ON := Color("#D9A54A")
const OFF := Color("#6B665E")
const LIFT := 0.015

var id: StringName
var needs: StringName
var enabled := false
var _slot: AssetSlot
var _label: Label3D
var _hover_tween: Tween


func setup(info: Dictionary, ps1: bool) -> void:
	id = info["id"]
	needs = info.get("needs", &"")
	enabled = bool(info["enabled"])
	name = "Amulet3D_" + String(id)
	_slot = AssetSlot.new()
	_slot.asset_name = "amulet_" + String(id)
	_slot.placeholder_size = SIZE
	_slot.placeholder_color = ON if enabled else OFF
	_slot.ps1 = ps1
	add_child(_slot)
	_label = Label3D.new()
	_label.text = String(info["text"]).replace(" · ", "\n")
	_label.font_size = 28
	_label.pixel_size = 0.0007
	_label.outline_size = 8
	_label.modulate = RingStyle.COLOR if enabled else RingStyle.DISABLED
	_label.rotation.x = -PI * 0.35
	_label.position = Vector3(0, 0.01, SIZE.z * 0.5 + 0.03)
	add_child(_label)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE + Vector3(0.02, 0.03, 0.06)
	shape.shape = box
	shape.position = Vector3(0, SIZE.y * 0.5, 0.02)
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(_on_input)
	area.mouse_entered.connect(_hover.bind(true))
	area.mouse_exited.connect(_hover.bind(false))


func press() -> void:
	if enabled:
		pressed.emit(id, needs)


func _hover(on: bool) -> void:
	if not enabled:
		return
	_label.modulate = RingStyle.HOVER if on else RingStyle.COLOR
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(_slot, "position:y", LIFT if on else 0.0, 0.12)


func _on_input(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		press()
