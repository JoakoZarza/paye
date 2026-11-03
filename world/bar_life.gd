class_name BarLife
extends Node3D
## El bar no está vacío: el cantinero detrás de la barra repasa vasos de un lado al otro
## y unas pocas almas perdidas caminan sin rumbo por las orillas, se paran y a veces se
## quedan mirándose entre ellas. Nunca se acercan a la mesa.

const SOUL_COUNT := 3
const SOUL_SIZE := Vector3(0.38, 1.6, 0.28)
const SOUL_COLOR := Color("#2C4232")
const SOUL_SPEED := 0.32
const PAUSE := Vector2(2.0, 6.0)
## Distancia a la que dos almas que se cruzan se quedan mirando.
const MEET := 1.3
## Recorrido por las orillas del bar, lejos de la mesa.
const WAYPOINTS := [Vector3(-2.6, 0, 1.6), Vector3(-2.9, 0, -0.9), Vector3(-1.6, 0, -2.6),
	Vector3(1.9, 0, -2.5), Vector3(2.8, 0, 1.4), Vector3(1.2, 0, 3.1), Vector3(-1.0, 0, 3.2)]
const BARTENDER_AT := Vector3(0.5, 0, -3.88)
const BARTENDER_SIZE := Vector3(0.5, 1.75, 0.25)
const BARTENDER_SWAY := 0.45
const BARTENDER_PERIOD := 7.0

var ps1 := false
var bartender: AssetSlot
var souls: Array[AssetSlot] = []
var _targets: Array[Vector3] = []
var _wait: Array[float] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2718
	bartender = _figure("bartender", "Bartender", BARTENDER_SIZE, Color("#5C3A22"), BARTENDER_AT)
	bartender.rotation.y = PI
	for i in SOUL_COUNT:
		var start: Vector3 = WAYPOINTS[(i * 2) % WAYPOINTS.size()]
		var soul := _figure("soul", "Soul%d" % i, SOUL_SIZE, SOUL_COLOR, start)
		souls.append(soul)
		_targets.append(_next_target(start))
		_wait.append(_rng.randf_range(0.0, PAUSE.y))


func _figure(asset: String, node_name: String, size: Vector3, color: Color, at: Vector3) -> AssetSlot:
	var f := AssetSlot.new()
	f.name = node_name
	f.asset_name = asset
	f.placeholder_size = size
	f.placeholder_color = color
	f.ps1 = ps1
	f.position = at
	add_child(f)
	return f


## El punto vecino de la ronda (adelante o atrás): así nunca cruzan por la mesa.
func _next_target(from: Vector3) -> Vector3:
	var here := 0
	for i in WAYPOINTS.size():
		if (WAYPOINTS[i] as Vector3).distance_to(from) < (WAYPOINTS[here] as Vector3).distance_to(from):
			here = i
	var step := 1 if _rng.randf() < 0.5 else -1
	return WAYPOINTS[posmod(here + step, WAYPOINTS.size())]


func _process(delta: float) -> void:
	step(delta)


## Un paso de vida del bar (separado para los tests).
func step(delta: float) -> void:
	_time += delta
	bartender.position.x = BARTENDER_AT.x + sin(_time * TAU / BARTENDER_PERIOD) * BARTENDER_SWAY
	for i in souls.size():
		var soul := souls[i]
		if _wait[i] > 0.0:
			_wait[i] -= delta
			var other := _closest(i)
			if other != null and soul.position.distance_to(other.position) < MEET:
				_face(soul, other.position)
			continue
		var to := _targets[i] - soul.position
		to.y = 0.0
		if to.length() < 0.05:
			_wait[i] = _rng.randf_range(PAUSE.x, PAUSE.y)
			_targets[i] = _next_target(soul.position)
			continue
		var stride := minf(SOUL_SPEED * delta, to.length())
		soul.position += to.normalized() * stride
		_face(soul, soul.position + to)
		# Un leve vaivén al caminar.
		soul.rotation.z = sin(_time * 5.0 + i) * 0.03


func _closest(i: int) -> AssetSlot:
	var best: AssetSlot = null
	for j in souls.size():
		if j != i and (best == null or souls[j].position.distance_to(souls[i].position) < best.position.distance_to(souls[i].position)):
			best = souls[j]
	return best


func _face(node: Node3D, at: Vector3) -> void:
	var d := at - node.position
	if Vector2(d.x, d.z).length() > 0.01:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(d.x, d.z), 0.15)
