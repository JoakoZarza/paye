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
## Animaciones del modelo (si trae un AnimationPlayer). Una de fondo que se repite
## (por defecto "idle") y, encima, de a una que se reproduce una vez y vuelve a la de fondo.
## Si el modelo no tiene la animación pedida, no pasa nada.
const BLEND := 0.2
var _anim: AnimationPlayer
var _base_anim: StringName = &"idle"
var _one_shot: StringName = &""


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
	_anim = null
	_one_shot = &""
	if is_inside_tree():
		_load_asset()


func has_animation(anim: StringName) -> bool:
	return _anim != null and _anim.has_animation(anim)


## Animación de fondo, que se repite. Si el modelo no la tiene, usa "idle".
func set_loop(anim: StringName) -> void:
	_base_anim = anim
	if _one_shot == &"":
		_play_base()


## Reproduce una animación una vez y vuelve a la de fondo. false si el modelo no la tiene.
func play_once(anim: StringName) -> bool:
	if not has_animation(anim):
		return false
	_anim.get_animation(anim).loop_mode = Animation.LOOP_NONE
	_one_shot = anim
	_anim.play(anim, BLEND)
	return true


## Lo que se está reproduciendo ("" sin modelo o sin animación).
func current_animation() -> StringName:
	return StringName(_anim.current_animation) if _anim != null else &""


func _play_base() -> void:
	if _anim == null:
		return
	var anim := _base_anim if _anim.has_animation(_base_anim) else &"idle"
	if not _anim.has_animation(anim):
		return
	_anim.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	if StringName(_anim.current_animation) != anim:
		_anim.play(anim, BLEND)


func _on_anim_finished(anim: StringName) -> void:
	if anim == _one_shot:
		_one_shot = &""
		_play_base()


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found := _find_player(c)
		if found != null:
			return found
	return null


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
				_anim = _find_player(_loaded_model)
				if _anim != null:
					_anim.animation_finished.connect(_on_anim_finished)
					_play_base()
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
