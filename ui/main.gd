extends Control
## Punto de entrada que crea el estado persistente y el controlador.

var rc: RunController


func _ready() -> void:
	var meta := MetaState.load_from()
	var economy := Economy.load_from()
	rc = RunController.new(economy, meta, int(Time.get_unix_time_from_system()))
	var router := ScreenRouter.new()
	router.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(router)
	router.setup(rc)
