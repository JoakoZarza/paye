class_name UiText
extends RefCounted
## Lee textos de interfaz en español bajo demanda.

const PATH := "res://data/i18n/ui.csv"
static var _texts: Dictionary = {}
static var _loaded := false


static func t(key: String, args: Array = []) -> String:
	if not _loaded:
		_load()
	var value := String(_texts.get(key, key))
	if not args.is_empty():
		value = value % args
	return value


## Plata con puntos de miles: 10000228 -> "10.000.228".
static func money(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "." + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


static func _load() -> void:
	_loaded = true
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not String(row[0]).is_empty():
			_texts[String(row[0])] = String(row[1])
