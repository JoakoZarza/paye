class_name CardTextures
extends RefCounted
## Busca la textura frontal de una carta española.

const CARDS_DIR: String = "res://assets/cards/"
const SUIT_NAMES: Array[String] = ["espada", "basto", "oro", "copa"]


static func face(card: Card) -> Texture2D:
	var path: String = CARDS_DIR.path_join("%s_%d.png" % [SUIT_NAMES[card.effective_suit()], card.effective_number()])
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static var _generated_back: Texture2D


## Dorso: back.png si existe; si no, uno generado con borde claro como las cartas
## españolas, para que se cuenten las cartas del rival aunque estén en la sombra.
static func back() -> Texture2D:
	var path: String = CARDS_DIR.path_join("back.png")
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if _generated_back == null:
		_generated_back = _make_back()
	return _generated_back


static func _make_back() -> Texture2D:
	var w := 32
	var h := 48
	var border := 3
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var cream := Color("#D8C9A3")
	var red := Color("#7A1E1A")
	var dark := Color("#4A1210")
	for y in h:
		for x in w:
			var edge := x < border or y < border or x >= w - border or y >= h - border
			var c := cream if edge else (dark if (x + y) % 6 == 0 or (x - y + 60) % 6 == 0 else red)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
