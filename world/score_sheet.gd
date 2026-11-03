class_name ScoreSheet
extends Node3D
## La planilla en T tallada en la mesa, como se anotan los puntos del truco:
## arriba NOS y ELLOS, una raya abajo de los nombres, otra al medio, y debajo de cada
## nombre los cuadrados de cinco palitos, uno bajo el otro.

const COLUMN := 0.05
const HEADER_FONT := 64
const HEADER_PIXEL := 0.00045
const LINE_Z := 0.02
const FIRST_GROUP_Z := 0.045
const WIDTH := 0.2
const LENGTH := 0.24
const NAMES := ["NOS", "ELLOS"]
## Tamaño sobre la mesa (no toca la altura de los surcos).
const SHEET_SCALE := 0.8

var ps1 := false
var _tallies: Array[ScoreTally] = []


func _ready() -> void:
	scale = Vector3(SHEET_SCALE, 1, SHEET_SCALE)
	for i in 2:
		var x := -COLUMN if i == 0 else COLUMN
		var header := Label3D.new()
		header.name = "Header" + NAMES[i]
		header.text = NAMES[i]
		header.font_size = HEADER_FONT
		header.pixel_size = HEADER_PIXEL
		header.outline_size = 0
		header.modulate = ScoreTally.COLOR
		header.shaded = false
		header.rotation.x = -PI * 0.5
		header.position = Vector3(x, 0.0015, -0.008)
		add_child(header)
		var tally := ScoreTally.new()
		tally.name = "Tally" + NAMES[i]
		tally.ps1 = ps1
		tally.position = Vector3(x, 0, FIRST_GROUP_Z)
		add_child(tally)
		_tallies.append(tally)
	_groove(Vector3(0, 0, LINE_Z), WIDTH, 0.0)
	_groove(Vector3(0, 0, LENGTH * 0.5 - 0.015), LENGTH, PI * 0.5)


## 0 = nosotros (vos), 1 = ellos (el rival).
func tally(who: int) -> ScoreTally:
	return _tallies[who] if who < _tallies.size() else null


func set_scores(scores: Array) -> void:
	for i in mini(scores.size(), _tallies.size()):
		_tallies[i].set_points(int(scores[i]))


func _groove(pos: Vector3, length: float, angle: float) -> void:
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, ScoreTally.GROOVE.y, ScoreTally.GROOVE.x)
	line.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = ScoreTally.COLOR
	line.material_override = material
	line.position = pos
	line.rotation.y = angle
	add_child(line)
	if ps1:
		Ps1Material.apply(line)
