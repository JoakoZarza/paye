# Plan 1 — Núcleo del Truco

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`) para marcar avance. Leé también la spec: las reglas están en `docs/DISENO.md` §3. Si algo de este plan contradice la spec, pará y avisá; no elijas vos.

**Objetivo:** reglas completas del Truco argentino 1 contra 1 sin flor (cartas, tanto, cantos, bazas, mano y partido) como lógica pura testeada, sin pantallas.

**Arquitectura:** clases `RefCounted` con `class_name` en `core/truco/`, sin nodos ni escenas. La mano y el partido reciben acciones (`TrucoAction`) y devuelven listas de eventos (`GameEvent`); las futuras pantallas 2D y 3D solo leen esos eventos. Todo el azar entra por un `RandomNumberGenerator` con semilla.

**Tecnologías:** Godot 4 (última estable 4.x), GDScript con tipado estático, GUT 9.x para tests.

**Spec:** `docs/DISENO.md` (§3 reglas, §13 arquitectura).

## Restricciones globales

- Nada en `core/` puede extender `Node` ni usar `get_tree()`, `print` para lógica, `randi()`/`randf()` globales ni `Array.shuffle()`. El azar sale solo del `RandomNumberGenerator` que se recibe.
- GDScript con tipos explícitos en todas las firmas.
- Jugadores = enteros `0` y `1`. En la run, `0` es el jugador humano y `1` el dealer, pero el núcleo no lo sabe.
- Las manos pueden tener más de 3 cartas (la trampa de la manga, Plan 3). Nada puede asumir `size() == 3`.
- Mazo de 40 cartas: números 1–7 y 10–12, palos espada, basto, oro, copa.
- Comando de tests (Windows, con la ruta del ejecutable de Godot en la variable `GODOT`):
  `& $env:GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- Un commit por tarea, con mensajes en español, formato `feat(truco): ...`.

## Foco de revisión

1. **Marcador que produce una carta inexistente** (un 8 o un 9): el modificador se rechaza y la carta conserva su número válido. Test en la Tarea 1.
2. **Falta envido a 0 a 0 en un partido a 15:** vale 15 y el partido termina en esa mano, antes de contar el truco. Tests en las Tareas 3 y 7.
3. **Tres bazas pardas:** gana el mano. Test en la Tarea 5.
4. **Irse al mazo con un truco pendiente de respuesta:** el rival suma el valor de "no querido", no el de "querido". Test en la Tarea 6.
5. **Cantar envido después de haber jugado tu carta en primera:** es ilegal. Cantar envido como respuesta a un truco en primera sí es legal. Tests en la Tarea 6.

---

## Estructura de archivos

```
project.godot
addons/gut/                    (GUT, sin modificar)
core/truco/card.gd             Card: carta con modificadores, rango y valor de tanto
core/truco/card_modifier.gd    CardModifier: cambio de número/palo con alcance
core/truco/deck.gd             Deck: 40 cartas, mezcla con semilla, reparto
core/truco/envido.gd           Envido: cálculo del tanto
core/truco/envido_bet.gd       EnvidoBet: secuencia de cantos de envido y sus puntos
core/truco/truco_bet.gd        TrucoBet: niveles de truco, quién tiene el quiero
core/truco/baza_resolver.gd    BazaResolver: comparación de cartas y ganador por pardas
core/truco/truco_action.gd     TrucoAction: acciones que puede hacer un jugador
core/truco/game_event.gd       GameEvent: eventos que emite el núcleo
core/truco/hand.gd             TrucoHand: máquina de estados de una mano
core/truco/match.gd            TrucoMatch: partido a 15 o 30
tests/truco/test_*.gd          un archivo de test por clase
tests/sim/test_random_play.gd  simulación de 10.000 manos
```

---

### Tarea 0: Proyecto Godot y GUT — ejecuta Codex

**Archivos:**
- Crear: `project.godot`, `addons/gut/` (GUT 9.x desde su repositorio oficial `bitwes/Gut`, la versión que soporte la Godot instalada), `tests/test_smoke.gd`

**Interfaces:**
- Produce: un proyecto que abre en Godot y un comando de tests que funciona.

- [ ] **Paso 1:** crear `project.godot` con `config/name="Payé"` y el plugin GUT habilitado.
- [ ] **Paso 2:** escribir `tests/test_smoke.gd`:

```gdscript
extends GutTest

func test_smoke() -> void:
	assert_eq(1 + 1, 2)
```

- [ ] **Paso 3:** correr el comando de tests. Esperado: `1 passed`.
- [ ] **Paso 4:** commit `feat(base): proyecto Godot con GUT`.

---

### Tarea 1: Carta, modificador y mazo — ejecuta Claude

**Archivos:**
- Crear: `core/truco/card.gd`, `core/truco/card_modifier.gd`, `core/truco/deck.gd`
- Test: `tests/truco/test_card.gd`, `tests/truco/test_deck.gd`

**Interfaces:**
- Produce:
  - `class_name CardModifier extends RefCounted` — `enum Scope { HAND, MATCH }`; `var new_number: int = -1`; `var new_suit: int = -1`; `var scope: Scope`; `var source: StringName`.
  - `class_name Card extends RefCounted` — `enum Suit { ESPADA, BASTO, ORO, COPA }`; `var suit: Suit`; `var number: int`; `var modifiers: Array[CardModifier]`; `func _init(p_suit: Suit, p_number: int)`; `static func is_valid_number(n: int) -> bool`; `func add_modifier(m: CardModifier) -> bool` (devuelve `false` y no lo agrega si `new_number` no es válido); `func clear_modifiers(scope: CardModifier.Scope) -> void`; `func effective_number() -> int`; `func effective_suit() -> Suit`; `func truco_rank() -> int`; `func envido_value() -> int`; `func key() -> String` (por ejemplo `"1_ESPADA"`, sobre los valores base).
  - `class_name Deck extends RefCounted` — `static func full_deck() -> Array[Card]`; `func _init(rng: RandomNumberGenerator)`; `func shuffle() -> void`; `func draw(n: int) -> Array[Card]`; `func remaining() -> int`.

- [ ] **Paso 1: escribir los tests**

```gdscript
extends GutTest

func test_rangos_de_la_jerarquia() -> void:
	assert_eq(Card.new(Card.Suit.ESPADA, 1).truco_rank(), 14)
	assert_eq(Card.new(Card.Suit.BASTO, 1).truco_rank(), 13)
	assert_eq(Card.new(Card.Suit.ESPADA, 7).truco_rank(), 12)
	assert_eq(Card.new(Card.Suit.ORO, 7).truco_rank(), 11)
	assert_eq(Card.new(Card.Suit.COPA, 3).truco_rank(), 10)
	assert_eq(Card.new(Card.Suit.ORO, 2).truco_rank(), 9)
	assert_eq(Card.new(Card.Suit.COPA, 1).truco_rank(), 8)
	assert_eq(Card.new(Card.Suit.ORO, 1).truco_rank(), 8)
	assert_eq(Card.new(Card.Suit.BASTO, 12).truco_rank(), 7)
	assert_eq(Card.new(Card.Suit.BASTO, 11).truco_rank(), 6)
	assert_eq(Card.new(Card.Suit.BASTO, 10).truco_rank(), 5)
	assert_eq(Card.new(Card.Suit.COPA, 7).truco_rank(), 4)
	assert_eq(Card.new(Card.Suit.BASTO, 7).truco_rank(), 4)
	assert_eq(Card.new(Card.Suit.ESPADA, 6).truco_rank(), 3)
	assert_eq(Card.new(Card.Suit.ESPADA, 5).truco_rank(), 2)
	assert_eq(Card.new(Card.Suit.ESPADA, 4).truco_rank(), 1)

func test_valor_de_tanto() -> void:
	assert_eq(Card.new(Card.Suit.ORO, 7).envido_value(), 7)
	assert_eq(Card.new(Card.Suit.ORO, 12).envido_value(), 0)
	assert_eq(Card.new(Card.Suit.ORO, 10).envido_value(), 0)

func test_modificador_cambia_rango() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 7
	m.new_suit = Card.Suit.ESPADA
	m.scope = CardModifier.Scope.MATCH
	assert_true(c.add_modifier(m))
	assert_eq(c.truco_rank(), 12)
	assert_eq(c.key(), "4_COPA")

func test_modificador_invalido_se_rechaza() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 8
	assert_false(c.add_modifier(m))
	assert_eq(c.effective_number(), 4)

func test_limpiar_modificadores_de_mano() -> void:
	var c := Card.new(Card.Suit.COPA, 4)
	var m := CardModifier.new()
	m.new_number = 5
	m.scope = CardModifier.Scope.HAND
	c.add_modifier(m)
	c.clear_modifiers(CardModifier.Scope.HAND)
	assert_eq(c.effective_number(), 4)
```

```gdscript
extends GutTest

func test_mazo_completo_tiene_40_cartas_unicas() -> void:
	var cards := Deck.full_deck()
	assert_eq(cards.size(), 40)
	var keys := {}
	for c in cards:
		keys[c.key()] = true
	assert_eq(keys.size(), 40)

func test_misma_semilla_mismo_orden() -> void:
	var a := _draw_all(1234)
	var b := _draw_all(1234)
	assert_eq(a, b)
	assert_ne(a, _draw_all(999))

func test_draw_descuenta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var d := Deck.new(rng)
	d.shuffle()
	assert_eq(d.draw(3).size(), 3)
	assert_eq(d.remaining(), 37)

func _draw_all(s: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var d := Deck.new(rng)
	d.shuffle()
	var out: Array[String] = []
	for c in d.draw(40):
		out.append(c.key())
	return out
```

- [ ] **Paso 2:** correr los tests. Esperado: fallan porque `Card` no existe.
- [ ] **Paso 3:** implementar. El rango sale de la tabla de DISENO §3.1 aplicada a `effective_number()`/`effective_suit()`; si hay varios modificadores, gana el último agregado. La mezcla es Fisher-Yates con `rng.randi_range`.
- [ ] **Paso 4:** correr los tests. Esperado: todos pasan.
- [ ] **Paso 5:** commit `feat(truco): cartas, modificadores y mazo con semilla`.

---

### Tarea 2: Cálculo del tanto — ejecuta Codex

**Archivos:**
- Crear: `core/truco/envido.gd`
- Test: `tests/truco/test_envido.gd`

**Interfaces:**
- Consume: `Card.envido_value()`, `Card.effective_suit()`.
- Produce: `class_name Envido extends RefCounted` — `static func tanto(cards: Array[Card]) -> int`.

- [ ] **Paso 1: escribir los tests** (helper `_c(suit, n)` que construye una `Card`):

```gdscript
func test_dos_del_mismo_palo() -> void:
	assert_eq(Envido.tanto([_c(ORO, 7), _c(ORO, 6), _c(COPA, 1)]), 33)

func test_figuras_valen_cero() -> void:
	assert_eq(Envido.tanto([_c(ORO, 12), _c(ORO, 11), _c(COPA, 1)]), 20)

func test_sin_palo_repetido_toma_la_mas_alta() -> void:
	assert_eq(Envido.tanto([_c(ORO, 5), _c(COPA, 7), _c(BASTO, 12)]), 7)

func test_tres_del_mismo_palo_usa_las_dos_mas_altas() -> void:
	assert_eq(Envido.tanto([_c(ORO, 3), _c(ORO, 6), _c(ORO, 5)]), 31)

func test_cuatro_cartas_por_la_manga() -> void:
	assert_eq(Envido.tanto([_c(ORO, 1), _c(COPA, 7), _c(COPA, 6), _c(BASTO, 4)]), 33)

func test_todo_figuras_de_distinto_palo() -> void:
	assert_eq(Envido.tanto([_c(ORO, 12), _c(COPA, 11), _c(BASTO, 10)]), 0)
```

- [ ] **Paso 2:** correr. Esperado: falla.
- [ ] **Paso 3:** implementar según DISENO §3.2 (usa valores efectivos).
- [ ] **Paso 4:** correr. Esperado: pasan.
- [ ] **Paso 5:** commit `feat(truco): cálculo del tanto`.

---

### Tarea 3: Apuestas de envido y truco — ejecuta Claude

**Archivos:**
- Crear: `core/truco/envido_bet.gd`, `core/truco/truco_bet.gd`
- Test: `tests/truco/test_envido_bet.gd`, `tests/truco/test_truco_bet.gd`

**Interfaces:**
- Produce:
  - `class_name EnvidoBet extends RefCounted` — `enum Call { ENVIDO, REAL_ENVIDO, FALTA_ENVIDO }`; `var calls: Array[Call]`; `func can_add(c: Call) -> bool`; `func add(c: Call) -> void`; `func points_if_accepted(falta_points: int) -> int`; `func points_if_rejected() -> int`.
  - `class_name TrucoBet extends RefCounted` — `var level: int` (0 nada, 1 truco, 2 retruco, 3 vale cuatro); `var pending: bool`; `var quiero_owner: int` (`-1` = cualquiera puede cantar); `var last_caller: int`; `func can_raise(player: int) -> bool`; `func raise(player: int) -> void`; `func accept() -> void`; `func accepted_value() -> int`; `func rejected_value() -> int`.

- [ ] **Paso 1: escribir los tests** (tabla de DISENO §3.3 y §3.5):

```gdscript
# test_envido_bet.gd
func test_tabla_de_secuencias() -> void:
	_check([EnvidoBet.Call.ENVIDO], 2, 1)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.ENVIDO], 4, 2)
	_check([EnvidoBet.Call.REAL_ENVIDO], 3, 1)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.REAL_ENVIDO], 5, 2)
	_check([EnvidoBet.Call.ENVIDO, EnvidoBet.Call.ENVIDO, EnvidoBet.Call.REAL_ENVIDO], 7, 4)

func test_falta_envido() -> void:
	var b := EnvidoBet.new()
	b.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_eq(b.points_if_accepted(15), 15)
	assert_eq(b.points_if_rejected(), 1)
	var b2 := EnvidoBet.new()
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_eq(b2.points_if_rejected(), 4)

func test_secuencias_ilegales() -> void:
	var b := EnvidoBet.new()
	b.add(EnvidoBet.Call.REAL_ENVIDO)
	assert_false(b.can_add(EnvidoBet.Call.ENVIDO))
	b.add(EnvidoBet.Call.FALTA_ENVIDO)
	assert_false(b.can_add(EnvidoBet.Call.FALTA_ENVIDO))
	var b2 := EnvidoBet.new()
	b2.add(EnvidoBet.Call.ENVIDO)
	b2.add(EnvidoBet.Call.ENVIDO)
	assert_false(b2.can_add(EnvidoBet.Call.ENVIDO))
```

```gdscript
# test_truco_bet.gd
func test_valores() -> void:
	var t := TrucoBet.new()
	assert_eq(t.accepted_value(), 1)
	t.raise(0)
	assert_eq(t.rejected_value(), 1)
	t.accept()
	assert_eq(t.accepted_value(), 2)
	t.raise(1)
	assert_eq(t.rejected_value(), 2)
	t.accept()
	t.raise(0)
	assert_eq(t.rejected_value(), 3)
	t.accept()
	assert_eq(t.accepted_value(), 4)
	assert_false(t.can_raise(1))

func test_solo_sube_quien_tiene_el_quiero() -> void:
	var t := TrucoBet.new()
	t.raise(0)
	t.accept()
	assert_false(t.can_raise(0))
	assert_true(t.can_raise(1))
```

- [ ] **Paso 2:** correr. Esperado: falla.
- [ ] **Paso 3:** implementar. "No querido" = lo querido hasta el canto anterior, mínimo 1 (DISENO §3.3). En `TrucoBet.accept()`, `quiero_owner` pasa a ser el que aceptó (el rival de `last_caller`).
- [ ] **Paso 4:** correr. Esperado: pasan.
- [ ] **Paso 5:** commit `feat(truco): apuestas de envido y truco`.

---

### Tarea 4: Acciones y eventos — ejecuta Codex

**Archivos:**
- Crear: `core/truco/truco_action.gd`, `core/truco/game_event.gd`
- Test: `tests/truco/test_action_event.gd`

**Interfaces:**
- Produce:
  - `class_name TrucoAction extends RefCounted` — `enum Type { PLAY_CARD, ENVIDO, REAL_ENVIDO, FALTA_ENVIDO, TRUCO, RETRUCO, VALE_CUATRO, QUIERO, NO_QUIERO, DECLARE_TANTO, SON_BUENAS, DEMAND_SHOW, ACCEPT_TANTO, MAZO }`; `var type: Type`; `var player: int`; `var card_index: int = -1`; `var value: int = -1`; `static func make(p_type: Type, p_player: int, p_card_index: int = -1, p_value: int = -1) -> TrucoAction`; `func equals(o: TrucoAction) -> bool`.
  - `class_name GameEvent extends RefCounted` — `var type: StringName`; `var data: Dictionary`; `static func make(p_type: StringName, p_data: Dictionary = {}) -> GameEvent`. Tipos usados en este plan: `&"hand_started"`, `&"card_played"`, `&"baza_won"`, `&"call_made"`, `&"call_accepted"`, `&"call_rejected"`, `&"tanto_declared"`, `&"son_buenas"`, `&"envido_won"`, `&"show_demanded"`, `&"lie_caught"`, `&"show_wrong"`, `&"mazo"`, `&"hand_over"`, `&"match_over"`.

- [ ] **Paso 1:** test: `make` guarda los campos; `equals` compara `type`, `player`, `card_index` y `value`.
- [ ] **Paso 2:** correr y ver que falla. **Paso 3:** implementar. **Paso 4:** correr y ver que pasa.
- [ ] **Paso 5:** commit `feat(truco): acciones y eventos`.

---

### Tarea 5: Resolución de bazas — ejecuta Codex

**Archivos:**
- Crear: `core/truco/baza_resolver.gd`
- Test: `tests/truco/test_baza_resolver.gd`

**Interfaces:**
- Consume: `Card.truco_rank()`.
- Produce: `class_name BazaResolver extends RefCounted` — `const PARDA := 2`; `const UNDECIDED := -1`; `static func compare(a: Card, b: Card) -> int` (`1` si gana `a`, `-1` si gana `b`, `0` parda); `static func hand_winner(results: Array[int], mano: int) -> int` (`results` contiene 0, 1 o `PARDA` por baza jugada; devuelve 0, 1 o `UNDECIDED`).

- [ ] **Paso 1: escribir los tests** (reglas de DISENO §3.6):

```gdscript
func test_gana_dos_primeras() -> void:
	assert_eq(BazaResolver.hand_winner([0, 0], 1), 0)

func test_una_y_una_decide_tercera() -> void:
	assert_eq(BazaResolver.hand_winner([0, 1], 0), BazaResolver.UNDECIDED)
	assert_eq(BazaResolver.hand_winner([0, 1, 1], 0), 1)

func test_primera_parda_decide_segunda() -> void:
	assert_eq(BazaResolver.hand_winner([BazaResolver.PARDA, 1], 0), 1)

func test_primera_ganada_segunda_parda() -> void:
	assert_eq(BazaResolver.hand_winner([1, BazaResolver.PARDA], 0), 1)

func test_tercera_parda_gana_el_de_primera() -> void:
	assert_eq(BazaResolver.hand_winner([1, 0, BazaResolver.PARDA], 0), 1)

func test_tres_pardas_gana_el_mano() -> void:
	var p := BazaResolver.PARDA
	assert_eq(BazaResolver.hand_winner([p, p, p], 1), 1)

func test_dos_pardas_decide_tercera() -> void:
	var p := BazaResolver.PARDA
	assert_eq(BazaResolver.hand_winner([p, p], 0), BazaResolver.UNDECIDED)
	assert_eq(BazaResolver.hand_winner([p, p, 0], 1), 0)
```

- [ ] **Paso 2:** correr y ver que falla. **Paso 3:** implementar. **Paso 4:** correr y ver que pasa.
- [ ] **Paso 5:** commit `feat(truco): resolución de bazas y pardas`.

---

### Tarea 6: Máquina de estados de la mano — ejecuta Claude

**Archivos:**
- Crear: `core/truco/hand.gd`
- Test: `tests/truco/test_hand.gd`

**Interfaces:**
- Consume: todas las clases de las Tareas 1 a 5.
- Produce: `class_name TrucoHand extends RefCounted`:
  - `enum Phase { PLAYING, ENVIDO_RESPONSE, TANTO_DECLARATION, TRUCO_RESPONSE, SHOW_DECISION, OVER }`
  - `func _init(p_cards: Array, p_mano: int, p_falta_points: int)` — `p_cards[0]` y `p_cards[1]` son `Array[Card]`.
  - `var phase: Phase`; `var mano: int`; `var played: Array` (por jugador, `Array[Card]` en orden de juego); `var baza_results: Array[int]`.
  - `func current_player() -> int`
  - `func legal_actions() -> Array[TrucoAction]` (las del jugador actual)
  - `func apply(a: TrucoAction) -> Array[GameEvent]` (una acción ilegal no cambia nada y devuelve `[GameEvent.make(&"illegal_action")]`)
  - `func is_over() -> bool`
  - `var envido_points: Array[int]` y `var truco_points: Array[int]` (tamaño 2; se completan al terminar).

**Comportamiento que fija este plan:**
- Empieza el mano. En `PLAYING`, el jugador actual puede jugar cualquier carta de su mano, cantar envido (si corresponde), cantar truco (si `TrucoBet.can_raise`) o irse al mazo.
- El envido es legal solo en la primera baza, si el jugador todavía no jugó carta y nadie cantó envido antes en esa mano. Respondiendo a un truco pendiente en primera, el envido es legal y el truco queda en espera hasta resolver el envido.
- En `ENVIDO_RESPONSE`: QUIERO, NO_QUIERO o un canto que suba (`EnvidoBet.can_add`).
- En `TANTO_DECLARATION`: primero el mano declara con `DECLARE_TANTO` (`value` entre 0 y 33; fuera de rango es ilegal). Después el otro responde `SON_BUENAS` o `DECLARE_TANTO` con un valor mayor. El mayor gana; si hay empate, gana el mano.
- En `SHOW_DECISION` (al terminar la mano si hubo envido querido): el perdedor del envido elige `DEMAND_SHOW` o `ACCEPT_TANTO`. Si pide mostrar y el ganador mintió (tanto real menor al declarado y menor al tanto real del perdedor), los puntos del envido pasan al perdedor y este suma +1 de multa. Si el ganador dijo la verdad, el que pidió le paga +1. Las multas son constantes `LIE_PENALTY := 1` y `WRONG_SHOW_PENALTY := 1`.
- `MAZO`: el rival suma `rejected_value()` si hay un truco pendiente, si no `accepted_value()`. La mano pasa a `SHOW_DECISION` si hubo envido querido; si no, a `OVER`.
- Una baza se cierra cuando los dos jugaron. Empieza la siguiente baza quien ganó la anterior; si fue parda, el mano.

- [ ] **Paso 1: escribir los tests** (cartas armadas a mano, sin mazo):
  - `test_mano_simple_gana_quien_gana_dos_bazas`: jugador 0 con 1 de espada, 1 de basto y 4 de copa contra 4, 5 y 6. Juegan las dos primeras sin cantos. `truco_points == [1, 0]`, `is_over()`.
  - `test_truco_querido_vale_2`.
  - `test_truco_no_querido_vale_1_y_termina`.
  - `test_mazo_con_truco_pendiente_paga_no_querido`: el jugador 1 canta truco, el jugador 0 quiere y canta retruco, y el jugador 1 se va al mazo. El jugador 0 suma 2, no 3.
  - `test_envido_ilegal_despues_de_jugar_carta`: el mano juega carta; `ENVIDO` no está en sus acciones legales en esa mano.
  - `test_envido_responde_a_truco_en_primera`: el jugador 0 canta truco en primera; el jugador 1 tiene `ENVIDO` en sus acciones legales; tras resolver el envido, la fase vuelve a `TRUCO_RESPONSE`.
  - `test_tanto_fuera_de_rango_es_ilegal`: `DECLARE_TANTO` con 34 devuelve `illegal_action`.
  - `test_mentira_pescada`: con el jugador 0 de mano, el mano declara 33 con tanto real 20, el otro declara 25 con real 25, el mano gana provisoriamente, al final el otro pide mostrar: `envido_points == [0, 2 + 1]` en un envido simple.
  - `test_pedir_mostrar_y_era_verdad`: el ganador dijo la verdad; el perdedor pide mostrar; el ganador suma los 2 del envido más 1.
  - `test_empate_de_tanto_gana_el_mano`.
- [ ] **Paso 2:** correr y ver que fallan. **Paso 3:** implementar. **Paso 4:** correr y ver que pasan.
- [ ] **Paso 5:** commit `feat(truco): máquina de estados de la mano`.

---

### Tarea 7: Partido — ejecuta Claude

**Archivos:**
- Crear: `core/truco/match.gd`
- Test: `tests/truco/test_match.gd`

**Interfaces:**
- Consume: `Deck`, `TrucoHand`, `TrucoAction`, `GameEvent`.
- Produce: `class_name TrucoMatch extends RefCounted`:
  - `func _init(p_target: int, p_rng: RandomNumberGenerator)` — `p_target` es 15 o 30.
  - `var scores: Array[int]`; `var hand: TrucoHand`; `var mano: int`.
  - `func falta_points() -> int` (`target - max(scores)`)
  - `func start_hand() -> Array[GameEvent]` (mezcla, reparte 3 y 3, crea la `TrucoHand`, emite `hand_started` con el mano)
  - `func apply(a: TrucoAction) -> Array[GameEvent]` (pasa la acción a la mano; al terminar la mano suma primero `envido_points`, comprueba si alguien llegó al objetivo, después suma `truco_points`)
  - `func winner() -> int` (`-1` si sigue)

- [ ] **Paso 1: escribir los tests**
  - `test_primer_mano_sorteado_con_semilla`: misma semilla, mismo mano.
  - `test_mano_alterna`.
  - `test_falta_envido_a_cero_gana_el_partido`: a 15, 0 a 0, falta envido querido y ganado por el jugador 1; `winner() == 1` aunque el jugador 0 gane las bazas, y se emite `match_over`.
  - `test_envido_suma_antes_que_truco`: con 13 a 13 a 15, el jugador 0 gana el envido (2) y el jugador 1 gana el truco; `winner() == 0`.
  - `test_puntaje_no_supera_al_terminar`: al terminar, el puntaje del ganador queda en el objetivo como máximo (`min(score, target)`).
- [ ] **Paso 2:** correr y ver que fallan. **Paso 3:** implementar. **Paso 4:** correr y ver que pasan.
- [ ] **Paso 5:** commit `feat(truco): partido a 15 y 30`.

---

### Tarea 8: Simulación al azar — ejecuta Codex

**Archivos:**
- Test: `tests/sim/test_random_play.gd`

**Interfaces:**
- Consume: `TrucoMatch`, `TrucoHand.legal_actions()`.

- [ ] **Paso 1:** escribir `test_diez_mil_manos_al_azar`: con semilla fija 42, jugar partidos a 15 y a 30 eligiendo siempre una acción legal al azar (con un `RandomNumberGenerator` propio) hasta completar 10.000 manos. Verificar en cada paso:
  - si la mano no terminó, `legal_actions()` no está vacía;
  - ninguna mano supera las 60 acciones;
  - ninguna carta se juega dos veces en una mano;
  - los puntos sumados por mano están entre 1 y `4 + falta_points + 1 + LIE_PENALTY` (cota superior: truco más envido más multa);
  - nunca aparece `illegal_action` (solo se juegan acciones legales).
- [ ] **Paso 2:** correr. Esperado: pasa en menos de 60 segundos. Si falla, el mensaje tiene que incluir el número de mano y la semilla para poder reproducirlo.
- [ ] **Paso 3:** commit `test(truco): simulación de 10.000 manos`.

---

## Al terminar el Plan 1

- Todos los tests pasan con el comando de las restricciones globales.
- Claude revisa todo el código del plan contra `docs/DISENO.md` §3.
- Se escribe el Plan 2 (IA del dealer) a partir de las interfaces reales de este plan.
