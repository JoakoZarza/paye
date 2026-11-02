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


static func back() -> Texture2D:
	var path: String = CARDS_DIR.path_join("back.png")
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
