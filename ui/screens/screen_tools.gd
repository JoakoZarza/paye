extends RefCounted
class_name ScreenTools
## Provee controles de texto y botones para las pantallas.


static func label(parent: Node, text: String, size: int = 20) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item


## Crea un botón y lo conecta a la acción indicada.
static func button(parent: Node, text: String, name: String, callback: Callable, enabled := true) -> Button:
	var item := Button.new()
	item.text = text
	item.name = name
	item.disabled = not enabled
	item.pressed.connect(callback)
	parent.add_child(item)
	return item
