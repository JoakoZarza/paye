class_name CameraRig
extends Camera3D
## La cámara del jugador. Sentado, la cabeza sigue al mouse según en qué zona de la
## pantalla esté: sobre tus cartas casi no se mueve, en el medio mira la mesa y al
## rival, afuera se mueve más y se sacude si sacudís el mouse. Dejar el mouse en un
## borde lateral (o mantener A/D) gira el cuerpo, sin pasarse de lo que gira una
## persona. Con el clic derecho (o espacio) apretado te inclinás sobre la mesa para
## ver de cerca las cartas jugadas. Sobre un botón la cabeza se queda quieta. Entre la silla, la entrada y la barra camina rodeando la mesa.

enum Zone { CARDS, TABLE, AROUND }

const STEP_SECONDS := 0.45
const TURN_SECONDS := 0.3
## Zonas: elipses con centro y radios en fracción de pantalla. Fuera de las dos es AROUND.
const CARDS_CENTER := Vector2(0.5, 0.86)
const CARDS_RADII := Vector2(0.22, 0.32)
const TABLE_CENTER := Vector2(0.5, 0.68)
const TABLE_RADII := Vector2(0.27, 0.62)
## Grados (mirar arriba/abajo, girar) respecto de CamSeat.
const HAND_LOOK := Vector2(-16, 0)
const CARDS_RANGE := Vector2(2, 3)
const TABLE_PITCH_UP := 10.0
const TABLE_YAW := 30.0
const AROUND_PITCH_UP := 14.0
const AROUND_YAW := 50.0
## Qué tan rápido sigue la cabeza al mouse en cada zona (más alto = más suelta).
## Qué parte de la pantalla, desde tus cartas hacia arriba, lleva la mirada hasta arriba.
const UP_SPAN := 0.6
const ZONE_SPEED := { Zone.CARDS: 1.5, Zone.TABLE: 4.0, Zone.AROUND: 9.0 }
## Sacudón: cuánto empuja el mouse, el resorte que lo frena y cuánto ladea.
const WOBBLE_PUSH := 0.9
const WOBBLE_SPRING := 60.0
const WOBBLE_DAMP := 7.0
const WOBBLE_ROLL := 0.35
const WOBBLE_MAX := 10.0
## Volviendo de afuera, hay que quedarse este tiempo adentro para que se calme.
const CALM_SECONDS := 1.5
## Giro del cuerpo con el mouse en el borde: velocidad, tope y vuelta al soltar.
const EDGE_SIDE := 0.04
const TWIST_SPEED := 55.0
const TWIST_RETURN := 70.0
## Manteniendo el giro acelera hasta un 50 % más en este tiempo.
const TWIST_ACCEL := 0.5
const TWIST_RAMP := 1.2
## Inclinarse: cuánto se adelanta y baja la cabeza y hacia dónde mira (grados).
const LEAN_OFFSET := Vector3(0, -0.1, -0.24)
const LEAN_PITCH := -24.0
const LEAN_SPEED := 4.0
## Cuello y torso juntos: más que esto una persona no gira.
const MAX_YAW := 140.0
## Mirando hacia abajo y al frente se levantan las cartas.
const HAND_PITCH_BELOW := -8.0
const HAND_YAW_WITHIN := 18.0
## Caminos que rodean la mesa en lugar de atravesarla.
const ROUTES := {
	[&"CamBar", &"CamSeat"]: [&"PathSide", &"PathStand"],
	[&"CamSeat", &"CamBar"]: [&"PathStand", &"PathSide"],
	[&"CamSeat", &"CamShop"]: [&"PathStand", &"PathSide", &"PathCounter"],
	[&"CamShop", &"CamSeat"]: [&"PathCounter", &"PathSide", &"PathStand"],
	[&"CamShop", &"CamBar"]: [&"PathCounter", &"PathSide"],
	[&"CamBar", &"CamShop"]: [&"PathSide", &"PathCounter"],
}

var bar: Bar3D
var target_marker: StringName = &""
## false en los tests: el mouse real no mueve la cabeza.
var mouse_look := true
## Si x >= 0, se usa esta posición (fracción) en lugar del mouse real (capturas).
var forced_mouse := Vector2(-1, -1)

var _base: Transform3D
## Radianes: x = cabeceo, y = giro.
var _turn := Vector2.ZERO
var _turn_tween: Tween
var _walk: Tween
var _twist := 0.0
var _wobble := 0.0
var _wobble_speed := 0.0
## 1 = agitado (estuvo afuera hace poco), 0 = calmo.
var _agitation := 0.0
var _calm_time := 0.0
var _last_mouse := Vector2(-1, -1)
var _twist_hold := 0.0
## 0 = sentado derecho, 1 = inclinado sobre la mesa.
var _lean := 0.0
## true con el mouse sobre un botón: la cabeza no sigue al mouse.
var ui_hold := false


func setup(p_bar: Bar3D) -> void:
	bar = p_bar
	current = true


func seated() -> bool:
	return target_marker == &"CamSeat" and (_walk == null or not _walk.is_running())


## instant: sin caminar (al arrancar y en los tests).
func go_to(name: StringName, instant := false) -> void:
	if name == target_marker:
		return
	var marker := bar.marker(String(name))
	if marker == null:
		return
	var from := target_marker
	target_marker = name
	_twist = 0.0
	_wobble = 0.0
	_wobble_speed = 0.0
	_agitation = 0.0
	_lean = 0.0
	var wanted := _deg(HAND_LOOK) if name == &"CamSeat" else Vector2.ZERO
	if _turn_tween != null:
		_turn_tween.kill()
	if is_inside_tree() and not instant and from != &"":
		_turn_tween = create_tween()
		_turn_tween.tween_property(self, "_turn", wanted, TURN_SECONDS)
	else:
		_turn = wanted
	if _walk != null:
		_walk.kill()
	if instant or not is_inside_tree() or from == &"":
		_base = marker.global_transform
		_apply()
		return
	var stops: Array[Transform3D] = []
	for stop: StringName in ROUTES.get([from, name], []):
		var m := bar.marker(String(stop))
		if m != null:
			stops.append(m.global_transform)
	stops.append(marker.global_transform)
	_walk = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var prev := _base
	for stop in stops:
		_walk.tween_method(_blend.bind(prev, stop), 0.0, 1.0, STEP_SECONDS)
		prev = stop


func _blend(t: float, from: Transform3D, to: Transform3D) -> void:
	_base = from.interpolate_with(to, t)


static func zone_at(m: Vector2) -> Zone:
	if _inside(m, CARDS_CENTER, CARDS_RADII):
		return Zone.CARDS
	if _inside(m, TABLE_CENTER, TABLE_RADII):
		return Zone.TABLE
	return Zone.AROUND


static func _inside(m: Vector2, center: Vector2, radii: Vector2) -> bool:
	var d := (m - center) / radii
	return d.length_squared() <= 1.0


## Grados de cabeceo y giro: x = cabeceo, y = giro.
func turn_degrees() -> Vector2:
	return Vector2(rad_to_deg(_turn.x), rad_to_deg(_turn.y))


func agitated() -> bool:
	return _agitation > 0.0


## Mirando tus cartas: la cabeza baja y al frente.
func looking_at_hand() -> bool:
	if not seated() or _lean > 0.5:
		return false
	var t := turn_degrees()
	return t.x < HAND_PITCH_BELOW and absf(t.y) < HAND_YAW_WITHIN


## Un paso de la cabeza con el mouse en m (fracción de pantalla). turn: -1 izquierda,
## 1 derecha, 0 nada (teclas); el borde lateral también gira.
func look(m: Vector2, delta: float, turn := 0, lean := false) -> void:
	if not seated() or delta <= 0.0:
		return
	if _turn_tween != null and _turn_tween.is_running():
		_turn_tween.kill()
	_lean = move_toward(_lean, 1.0 if lean else 0.0, LEAN_SPEED * delta)
	if ui_hold:
		_last_mouse = Vector2(-1, -1)
		_twist_hold = 0.0
		return
	var zone := zone_at(m)
	var c := clampf((m.x - 0.5) * 2.0, -1.0, 1.0)
	var up := clampf((CARDS_CENTER.y - m.y) / UP_SPAN, 0.0, 1.0)
	var target := HAND_LOOK
	match zone:
		Zone.CARDS:
			target += Vector2(up * CARDS_RANGE.x, -c * CARDS_RANGE.y)
		Zone.TABLE:
			target = Vector2(lerpf(HAND_LOOK.x, TABLE_PITCH_UP, up), -c * TABLE_YAW)
		Zone.AROUND:
			target = Vector2(lerpf(HAND_LOOK.x, AROUND_PITCH_UP, up), -c * AROUND_YAW)

	# Afuera se agita; adentro tiene que quedarse un rato para calmarse.
	if zone == Zone.AROUND:
		_agitation = 1.0
		_calm_time = 0.0
	elif _agitation > 0.0:
		_calm_time += delta
		if _calm_time >= CALM_SECONDS:
			_agitation = move_toward(_agitation, 0.0, delta * 3.0)

	# El cuerpo gira mientras el mouse esté en el borde o se mantenga A/D.
	if turn == 0:
		if m.x <= EDGE_SIDE:
			turn = -1
		elif m.x >= 1.0 - EDGE_SIDE:
			turn = 1
	if turn != 0:
		_twist_hold += delta
		var twist_speed := TWIST_SPEED * (1.0 + TWIST_ACCEL * smoothstep(0.0, TWIST_RAMP, _twist_hold))
		var limit := MAX_YAW - AROUND_YAW
		_twist = clampf(_twist - turn * twist_speed * delta, -limit, limit)
	else:
		_twist_hold = 0.0
		_twist = move_toward(_twist, 0.0, TWIST_RETURN * delta)
	target.y = clampf(target.y + _twist, -MAX_YAW, MAX_YAW)

	# Sacudón: la velocidad horizontal del mouse empuja un resorte.
	var push := 0.0
	if _last_mouse.x >= 0.0:
		push = (m.x - _last_mouse.x) / delta
	_last_mouse = m
	_wobble_speed += (-push * WOBBLE_PUSH * _agitation * 60.0 - WOBBLE_SPRING * _wobble - WOBBLE_DAMP * _wobble_speed) * delta
	_wobble = clampf(_wobble + _wobble_speed * delta, -WOBBLE_MAX, WOBBLE_MAX)

	var speed := lerpf(ZONE_SPEED[zone], ZONE_SPEED[Zone.AROUND], _agitation)
	var k := 1.0 - exp(-speed * delta)
	_turn = _turn.lerp(_deg(target), k)


func _deg(v: Vector2) -> Vector2:
	return Vector2(deg_to_rad(v.x), deg_to_rad(v.y))


func _process(delta: float) -> void:
	if seated():
		var m := Vector2(0.5, CARDS_CENTER.y)
		if forced_mouse.x >= 0.0:
			m = forced_mouse
		elif mouse_look:
			m = _mouse_fraction(m)
		var turn := 0
		var lean := false
		if mouse_look:
			if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
				turn -= 1
			if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
				turn += 1
			lean = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_SPACE)
		look(m, delta, turn, lean)
	_apply()


func _mouse_fraction(fallback: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return fallback
	var size := vp.get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return fallback
	return (vp.get_mouse_position() / size).clamp(Vector2.ZERO, Vector2.ONE)


func _apply() -> void:
	# Girar sobre el eje vertical del mundo y cabecear sobre el propio; el ladeo viene
	# solo del sacudón.
	# Inclinado, la cabeza va hacia las bazas y se adelanta.
	var lean := smoothstep(0.0, 1.0, _lean)
	var yaw := lerpf(_turn.y, 0.0, lean) + deg_to_rad(_wobble)
	var pitch := lerpf(_turn.x, deg_to_rad(LEAN_PITCH), lean)
	var basis := Basis(Vector3.UP, yaw) * _base.basis * Basis(Vector3.RIGHT, pitch) \
		* Basis(Vector3.FORWARD, deg_to_rad(_wobble * WOBBLE_ROLL))
	var forward := Basis(Vector3.UP, _base.basis.get_euler().y)
	global_transform = Transform3D(basis, _base.origin + forward * LEAN_OFFSET * lean)


func leaning() -> bool:
	return _lean > 0.5
