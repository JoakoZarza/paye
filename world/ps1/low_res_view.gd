class_name LowResView
extends SubViewportContainer
## Muestra el mundo 3D a baja resolución, estirado sin suavizar y con la pasada
## de colores PS1. El HUD va afuera, a resolución completa (Plan 7, Tarea 6).

const POST := preload("res://world/ps1/ps1_post.gdshader")
## Por defecto 1280×720 / 2 = 640×360. Se cambia con "ps1_shrink" en data/ui.json.
const SHRINK := 2

var viewport: SubViewport


func _init() -> void:
	stretch = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	viewport = SubViewport.new()
	viewport.name = "World"
	viewport.handle_input_locally = false
	viewport.physics_object_picking = true
	add_child(viewport)


## ps1 false: resolución completa, sin pasada de colores y con bordes suavizados (estilo HD:
## figuras low poly con texturas pixeladas, ver docs/ASSETS.md).
func configure(ps1: bool, shrink := SHRINK) -> void:
	stretch_shrink = shrink if ps1 else 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if ps1 else CanvasItem.TEXTURE_FILTER_LINEAR
	if ps1:
		var post := ShaderMaterial.new()
		post.shader = POST
		material = post
	else:
		material = null
		# Resolución completa: bordes de las figuras limpios, sin dientes de sierra.
		viewport.msaa_3d = Viewport.MSAA_4X


func add_world(node: Node3D) -> void:
	viewport.add_child(node)
