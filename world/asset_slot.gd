class_name AssetSlot
extends Node3D
## Carga un modelo o muestra su cubo provisorio.

@export var asset_name: String = ""
@export var placeholder_size: Vector3 = Vector3.ONE
@export var placeholder_color: Color = Color(0.45, 0.45, 0.45)
## Cubo que se ve desde adentro (la habitación).
@export var placeholder_inside: bool = false
var models_dir: String = "res://assets/models/"
var model_ext: String = ".glb"
## Con el filtro PS1, el modelo (o el cubo) usa su material.
var ps1 := false

var _loaded_model: Node3D
var _placeholder: MeshInstance3D


func _ready() -> void:
	_load_asset()


## Cambia de modelo: prueba cada nombre en orden y usa el primero que exista; si
## ninguno existe, el cubo provisorio. No hace nada si ya muestra ese mismo.
func set_asset(names: Array[String]) -> void:
	var pick: String = names[0] if not names.is_empty() else ""
	for n in names:
		if ResourceLoader.exists(models_dir.path_join(n + model_ext)):
			pick = n
			break
	if pick == asset_name and (_loaded_model != null or _placeholder != null):
		return
	asset_name = pick
	for c in [_loaded_model, _placeholder]:
		if c != null:
			remove_child(c)
			c.queue_free()
	_loaded_model = null
	_placeholder = null
	if is_inside_tree():
		_load_asset()


func has_model() -> bool:
	return _loaded_model != null


func _load_asset() -> void:
	var path: String = models_dir.path_join(asset_name + model_ext)
	if not asset_name.is_empty() and ResourceLoader.exists(path):
		var packed: PackedScene = load(path) as PackedScene
		if packed != null:
			_loaded_model = packed.instantiate() as Node3D
			if _loaded_model != null:
				add_child(_loaded_model)
				_apply_nearest(_loaded_model)
	if _loaded_model == null:
		_make_placeholder()
	if ps1:
		Ps1Material.apply(self)


func _make_placeholder() -> void:
	_placeholder = MeshInstance3D.new()
	_placeholder.name = "Placeholder"
	var box := BoxMesh.new()
	box.size = placeholder_size
	_placeholder.mesh = box
	_placeholder.position.y = placeholder_size.y * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = placeholder_color
	if placeholder_inside:
		material.cull_mode = BaseMaterial3D.CULL_FRONT
	_placeholder.material_override = material
	add_child(_placeholder)


func _apply_nearest(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface: int in range(mesh_instance.mesh.get_surface_count()):
				var material: Material = mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D:
					(material as StandardMaterial3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for child: Node in node.get_children():
		_apply_nearest(child)
