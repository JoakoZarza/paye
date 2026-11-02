extends GutTest
## Filtro PS1: materiales convertidos sin perder color ni textura (Plan 7, Tarea 6).


func _box(material: Material, as_override := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	mi.mesh = box
	if as_override:
		mi.material_override = material
	else:
		box.material = material
	return mi


func test_conserva_color_y_textura() -> void:
	var src := StandardMaterial3D.new()
	src.albedo_color = Color(0.5, 0.2, 0.1)
	var tex := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGB8))
	src.albedo_texture = tex
	var out := Ps1Material.from_material(src)
	assert_eq(out.shader, Ps1Material.SHADER)
	assert_eq(out.get_shader_parameter("albedo"), Color(0.5, 0.2, 0.1))
	assert_eq(out.get_shader_parameter("albedo_texture"), tex)
	assert_true(out.get_shader_parameter("has_texture"))


func test_aplica_a_todo_el_arbol() -> void:
	var root := Node3D.new()
	var plain := _box(StandardMaterial3D.new())
	var overridden := _box(StandardMaterial3D.new(), true)
	var bare := _box(null)
	root.add_child(plain)
	plain.add_child(overridden)
	root.add_child(bare)
	Ps1Material.apply(root)
	for mi: MeshInstance3D in [plain, overridden, bare]:
		assert_true(Ps1Material.uses_ps1(mi))
	root.free()


func test_vista_baja_resolucion() -> void:
	var view := LowResView.new()
	add_child_autofree(view)
	view.configure(true)
	assert_eq(view.stretch_shrink, LowResView.SHRINK)
	assert_not_null(view.material)
	view.configure(false)
	assert_eq(view.stretch_shrink, 1)
	assert_null(view.material)
