class_name Babble
extends AudioStreamPlayer3D
## El rival no habla: balbucea una sílaba cada pocas letras del subtítulo, con un tono
## propio por rival. Si existe res://assets/audio/babble/<rival>.wav (o babble.wav)
## usa ese sonido; si no, uno generado.

const AUDIO_DIR := "res://assets/audio/babble/"
## Cada cuántas letras suena una sílaba y cuánto varía el tono entre sílabas.
const LETTERS_PER_SYLLABLE := 3
const PITCH_SPREAD := 0.18
const MIX_RATE := 22050
const SYLLABLE_SECONDS := 0.075

static var _generated: AudioStreamWAV

var base_pitch := 1.0
var _letters := 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	unit_size = 3.0
	volume_db = -6.0
	max_polyphony = 2


## Cada rival suena distinto: el tono sale del nombre.
func set_voice(rival_name: String) -> void:
	var h := absi(rival_name.hash())
	base_pitch = 0.75 + float(h % 50) / 100.0
	_letters = 0
	stream = _load_sample(rival_name)


func on_letter(ch: String) -> void:
	if ch.strip_edges() == "" or not ch.to_lower() in "aeiouáéíóúbcdfghjklmnñpqrstvwxyz":
		return
	_letters += 1
	if _letters % LETTERS_PER_SYLLABLE != 1:
		return
	pitch_scale = base_pitch * (1.0 + _rng.randf_range(-PITCH_SPREAD, PITCH_SPREAD))
	if stream != null and is_inside_tree():
		play()


static func _load_sample(rival_name: String) -> AudioStream:
	for path in [AUDIO_DIR + rival_name.to_lower() + ".wav", AUDIO_DIR + "babble.wav"]:
		if ResourceLoader.exists(path):
			return load(path)
	return generated()


## Una sílaba de mentira: dos ondas cuadradas desafinadas con un golpe al principio.
static func generated() -> AudioStreamWAV:
	if _generated != null:
		return _generated
	var n := int(MIX_RATE * SYLLABLE_SECONDS)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / MIX_RATE
		var env := minf(t / 0.008, 1.0) * pow(1.0 - float(i) / n, 2.0)
		var a := 1.0 if fmod(t * 190.0, 1.0) < 0.5 else -1.0
		var b := 1.0 if fmod(t * 283.0, 1.0) < 0.35 else -1.0
		var v := clampi(int((a * 0.55 + b * 0.35) * env * 9000.0), -32768, 32767)
		data.encode_s16(i * 2, v)
	_generated = AudioStreamWAV.new()
	_generated.format = AudioStreamWAV.FORMAT_16_BITS
	_generated.mix_rate = MIX_RATE
	_generated.data = data
	return _generated
