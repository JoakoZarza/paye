class_name Ps1Material
extends RefCounted
## Pasa los materiales de un modelo al shader PS1, conservando color y textura,
## para que los modelos de Joako no necesiten nada especial (Plan 7, Tarea 6).

const SHADER := preload("res://world/ps1/ps1.gdshader")

## Grilla de los vértices: la misma resolución que la vista baja.
static var snap_resolution := Vector2(640, 360)


static func from_material(source: Material) -> ShaderMaterial:
	var out := ShaderMaterial.new()
	out.shader = SHADER
	out.set_shader_parameter("snap_resolution", snap_resolution)
	if source is BaseMaterial3D:
		var base := source as BaseMaterial3D
		out.set_shader_parameter("albedo", base.albedo_color)
		if base.albedo_texture != null:
			out.set_shader_parameter("albedo_texture", base.albedo_texture)
			out.set_shader_parameter("has_texture", true)
	elif source is ShaderMaterial and (source as ShaderMaterial).shader == SHADER:
		return source as ShaderMaterial
	return out


## Cambia el material de todas las superficies de los MeshInstance3D bajo node.
static func apply(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		# material_override le gana a los materiales por superficie: se convierte ese.
		if mesh_instance.material_override != null:
			mesh_instance.material_override = from_material(mesh_instance.material_override)
		elif mesh_instance.mesh != null:
			for i in mesh_instance.mesh.get_surface_count():
				var current := mesh_instance.get_active_material(i)
				mesh_instance.set_surface_override_material(i, from_material(current))
	for child in node.get_children():
		apply(child)


static func uses_ps1(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance.mesh == null:
		return true
	for i in mesh_instance.mesh.get_surface_count():
		var m := mesh_instance.get_active_material(i)
		if not (m is ShaderMaterial and (m as ShaderMaterial).shader == SHADER):
			return false
	return true
