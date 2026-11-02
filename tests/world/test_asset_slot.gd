extends GutTest

const MODEL_PATH: String = "user://test_models/table.tscn"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MODEL_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_models"))


func test_sin_modelo_muestra_cubo_apoyado() -> void:
	var asset := AssetSlot.new()
	asset.asset_name = "inexistente_test"
	asset.placeholder_size = Vector3(2, 0.6, 1)
	add_child_autofree(asset)
	assert_false(asset.has_model())
	var cube := asset.get_node("Placeholder") as MeshInstance3D
	assert_eq((cube.mesh as BoxMesh).size, Vector3(2, 0.6, 1))
	assert_almost_eq(cube.position.y, 0.3, 0.0001)


func test_carga_una_escena_de_modelo() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_models"))
	var packed := PackedScene.new()
	var model := Node3D.new()
	model.name = "ModeloPrueba"
	assert_eq(packed.pack(model), OK)
	model.free()
	assert_eq(ResourceSaver.save(packed, MODEL_PATH), OK)
	var asset := AssetSlot.new()
	asset.asset_name = "table"
	asset.models_dir = "user://test_models/"
	asset.model_ext = ".tscn"
	add_child_autofree(asset)
	assert_true(asset.has_model())
	assert_null(asset.get_node_or_null("Placeholder"))
