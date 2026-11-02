extends GutTest

const BUDGET_PATH: String = "res://world/asset_budget.json"
const MODELS_DIR: String = "res://assets/models/"
const CARDS_DIR: String = "res://assets/cards/"


func test_presupuesto_de_modelos_y_cartas() -> void:
	var budget_file := FileAccess.open(BUDGET_PATH, FileAccess.READ)
	assert_not_null(budget_file, "No se encontró world/asset_budget.json")
	var parser := JSON.new()
	assert_eq(parser.parse(budget_file.get_as_text()), OK, "El presupuesto JSON no es válido")
	var config: Dictionary = parser.data as Dictionary
	var model_files: PackedStringArray = DirAccess.get_files_at(MODELS_DIR)
	var model_count: int = 0
	for path: String in model_files:
		if not path.ends_with(".glb"):
			continue
		model_count += 1
		_check_model(path, config["models"])
	if model_count == 0:
		pass_test("Todavía no hay modelos para medir")
	_check_card_textures(config)


func _check_model(file_name: String, limits: Dictionary) -> void:
	var asset_name: String = file_name.trim_suffix(".glb")
	if not limits.has(asset_name):
		fail_test("%s no tiene límites en asset_budget.json" % file_name)
		return
	var scene: PackedScene = load(MODELS_DIR.path_join(file_name)) as PackedScene
	if scene == null:
		fail_test("No se pudo importar %s como escena" % file_name)
		return
	var root: Node3D = scene.instantiate() as Node3D
	if root == null:
		fail_test("%s no tiene una raíz 3D" % file_name)
		return
	var stats: Dictionary = {"triangles": 0, "textures": []}
	_collect_mesh_stats(root, stats)
	var limit: Dictionary = limits[asset_name]
	var triangle_count: int = int(stats["triangles"])
	assert_lte(triangle_count, int(limit["triangles"]), "%s tiene %s triángulos; el máximo es %s" % [file_name, triangle_count, limit["triangles"]])
	for dimensions: Vector2i in stats["textures"]:
		assert_true(dimensions.x <= int(limit["texture"]) and dimensions.y <= int(limit["texture"]), "%s tiene una textura %sx%s px; el máximo es %s" % [file_name, dimensions.x, dimensions.y, limit["texture"]])
	if limit.has("size"):
		_check_model_bounds(root, file_name, limit)
	root.free()


func _collect_mesh_stats(node: Node, stats: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface: int in range(mesh_instance.mesh.get_surface_count()):
				var arrays: Array = mesh_instance.mesh.surface_get_arrays(surface)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				stats["triangles"] = int(stats["triangles"]) + (indices.size() if not indices.is_empty() else vertices.size()) / 3
				var material: Material = mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D:
					var texture: Texture2D = (material as StandardMaterial3D).albedo_texture
					if texture != null:
						var image: Image = texture.get_image()
						if image != null:
							(stats["textures"] as Array).append(Vector2i(image.get_width(), image.get_height()))
	for child: Node in node.get_children():
		_collect_mesh_stats(child, stats)


func _check_model_bounds(root: Node3D, file_name: String, limit: Dictionary) -> void:
	var bounds: AABB
	var has_bounds: bool = false
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_nodes(root, meshes)
	for mesh_node: MeshInstance3D in meshes:
		var mesh_bounds: AABB = _transform_to(root, mesh_node) * mesh_node.get_aabb()
		if not has_bounds:
			bounds = mesh_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(mesh_bounds)
	if not has_bounds:
		fail_test("%s no contiene mallas para medir" % file_name)
		return
	var expected: Array = limit["size"]
	for axis: int in range(3):
		var actual: float = bounds.size[axis]
		var target: float = float(expected[axis])
		assert_true(absf(actual - target) <= maxf(target * 0.5, 0.05), "%s mide %.2f m en eje %d; se esperaba cerca de %.2f m" % [file_name, actual, axis, target])
	assert_true(absf(bounds.position.y) <= 0.05, "%s no está apoyado en Y=0 (base en %.2f m)" % [file_name, bounds.position.y])


## Transformación de node hasta el padre de root, incluida la escala de la raíz
## (el modelo no está en el árbol de escena).
func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var current: Node = node
	while current != null:
		if current is Node3D:
			t = (current as Node3D).transform * t
		if current == root:
			break
		current = current.get_parent()
	return t


func _collect_mesh_nodes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		meshes.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_mesh_nodes(child, meshes)


func _check_card_textures(config: Dictionary) -> void:
	var entries: PackedStringArray = DirAccess.get_files_at(CARDS_DIR)
	for file_name: String in entries:
		if not file_name.ends_with(".png"):
			continue
		var texture: Texture2D = load(CARDS_DIR.path_join(file_name)) as Texture2D
		if texture == null:
			fail_test("No se pudo leer la textura %s" % file_name)
			continue
		var image: Image = texture.get_image()
		assert_eq(Vector2i(image.get_width(), image.get_height()), Vector2i(config["card_size"][0], config["card_size"][1]), "%s debe medir exactamente 128×192 px" % file_name)
