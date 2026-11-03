class_name ScoreTally
extends Node3D
## Una columna de la planilla de puntos tallada en la mesa: cada punto un palito,
## cuatro forman un cuadrado y el quinto lo cruza en diagonal; los cuadrados van uno
## debajo del otro. Los nuevos se graban con un tirón corto, como hechos a cuchillo.

const SIDE := 0.034
const GROOVE := Vector2(0.0035, 0.0015)
const GROUP_GAP := 0.018
const CARVE_SECONDS := 0.18
const COLOR := Color("#1E120B")

var ps1 := false
var _sticks: Array[MeshInstance3D] = []
var _material: StandardMaterial3D


func _init() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = COLOR
	_material.roughness = 1.0


func points() -> int:
	return _sticks.size()


## Deja tallados n puntos. Si bajan (partido nuevo), se borra y se empieza de cero.
func set_points(n: int) -> void:
	n = maxi(n, 0)
	if n < _sticks.size():
		for s in _sticks:
			s.queue_free()
		_sticks.clear()
	while _sticks.size() < n:
		_carve(_sticks.size())


## [centro, largo, ángulo sobre la mesa] del palito i.
static func stick_shape(i: int) -> Array:
	var group := i / 5
	var origin := Vector3(0, 0, group * (SIDE + GROUP_GAP))
	var h := SIDE * 0.5
	match i % 5:
		0:
			return [origin + Vector3(-h, 0, 0), SIDE, PI * 0.5]
		1:
			return [origin + Vector3(0, 0, -h), SIDE, 0.0]
		2:
			return [origin + Vector3(h, 0, 0), SIDE, PI * 0.5]
		3:
			return [origin + Vector3(0, 0, h), SIDE, 0.0]
	return [origin, SIDE * sqrt(2.0), PI * 0.25]


func _carve(i: int) -> void:
	var shape := stick_shape(i)
	var stick := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	# Un poco irregulares, como a mano.
	var rng := RandomNumberGenerator.new()
	rng.seed = i * 7919 + 17
	mesh.size = Vector3(float(shape[1]) * rng.randf_range(0.92, 1.06), GROOVE.y, GROOVE.x)
	stick.mesh = mesh
	stick.material_override = _material
	stick.position = shape[0] + Vector3(rng.randf_range(-0.002, 0.002), 0, rng.randf_range(-0.002, 0.002))
	stick.rotation.y = float(shape[2]) + rng.randf_range(-0.06, 0.06)
	add_child(stick)
	if ps1:
		Ps1Material.apply(stick)
	_sticks.append(stick)
	if is_inside_tree():
		stick.scale = Vector3(0.05, 1, 1)
		create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) \
			.tween_property(stick, "scale", Vector3.ONE, CARVE_SECONDS)
