@tool
class_name JitterEffect
extends RichTextEffect
## Temblor a saltos como en CloverPit: cada letra salta a un lugar al azar unas
## cuantas veces por segundo, sin moverse suave, y de vez en cuando una pega un tirón.
## Uso: [jitter amp=1.5 fps=12]texto[/jitter]

var bbcode := "jitter"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var amp := float(char_fx.env.get("amp", 1.5))
	var fps := float(char_fx.env.get("fps", 12.0))
	var step := int(char_fx.elapsed_time * fps)
	var h := hash(Vector3i(char_fx.relative_index, step, char_fx.range.x))
	var x := float(h & 0xFF) / 255.0 * 2.0 - 1.0
	var y := float((h >> 8) & 0xFF) / 255.0 * 2.0 - 1.0
	# Uno de cada treinta saltos es un tirón de tres veces más.
	if (h >> 16) % 30 == 0:
		amp *= 3.0
	char_fx.offset += Vector2(x, y) * amp
	return true
