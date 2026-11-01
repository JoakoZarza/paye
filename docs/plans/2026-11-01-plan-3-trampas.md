# Plan 3 — Trampas

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). Leé también la spec, `docs/DISENO.md` §4. Si algo de este plan contradice la spec, pará y avisá. **Codex no puede correr Godot en su sandbox:** escribe el código y los tests, y Claude corre `run_tests.ps1`.

**Objetivo:** el dealer hace trampa (manga, carta duplicada, cómplice) y toda trampa deja evidencia. El jugador acusa señalando la evidencia, con premio si acierta y castigo si se equivoca. El jugador también puede hacer trampa (Espejo, Cartas marcadas) con riesgo de que lo pesquen. La sospecha del dealer conecta todo.

**Arquitectura:**
- El dealer deja de recibir la `TrucoHand` completa. Recibe una `HandView` de solo lectura que expone solo lo que ese jugador puede ver; las cartas del rival aparecen solo si una trampa se las dio.
- Una nueva `CheatTable` en `core/cheats/` envuelve un `TrucoMatch` y un `DealerBrain`. Es la única entrada que van a usar la run y las pantallas: reparte, decide y aplica las trampas del dealer, hace jugar al dealer, recibe las acciones y acusaciones del jugador, y emite eventos de pistas y evidencia.
- `TrucoHand` y `TrucoMatch` solo ganan los ganchos mínimos: agregar o reemplazar cartas, terminar una mano por acusación y sumar puntos de castigo.

**Tecnologías:** Godot 4.7.2, GDScript con tipado estático, GUT 9.7.1.

**Spec:** `docs/DISENO.md` §4 (trampas y acusación), §5 (sospecha del dealer).

## Restricciones globales

- Mismas reglas que los Planes 1 y 2: nada en `core/` extiende `Node`; sin azar global; tipos explícitos; constantes con nombre; un commit por tarea (`feat(trampas): ...`).
- **Regla de oro (DISENO §4):** ninguna trampa del dealer es invisible. Mientras una trampa afecta el juego, su evidencia tiene que estar disponible en `CheatTable.evidence()`.
- **El dealer nunca ve cartas ocultas del rival** salvo con la trampa del cómplice, y solo mientras el cómplice está visible.
- Máximo una trampa del dealer por mano.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1`.

## Foco de revisión

1. **Acusar dos veces en la misma mano, o acusar con la mano ya terminada:** la segunda acusación es ilegal y no suma ni resta nada. Test en la Tarea 6.
2. **La carta duplicada nunca llega a jugarse** (la mano termina antes): no hay evidencia, pero tampoco hubo ventaja. Acusar la carta es un error. Test en la Tarea 5.
3. **La trampa de la manga cuando el mazo no tiene cartas:** no se hace la trampa y no se gasta presupuesto. Test en la Tarea 5.
4. **Acusación correcta durante la declaración del tanto o la decisión de mostrar:** la mano termina igual y los puntos se reparten según §4.2. Test en la Tarea 3.
5. **Presupuesto en 0:** el dealer nunca hace trampa, por más alta que sea su tendencia. Test en la Tarea 5.

---

## Estructura de archivos

```
core/truco/hand_view.gd        HandView: lo que un jugador puede ver de la mano
core/truco/hand.gd             (modificar) agregar/reemplazar cartas, terminar por acusación
core/truco/match.gd            (modificar) mazo accesible, puntos de castigo
core/ai/dealer_brain.gd        (modificar) usa HandView; decide si hace trampa; aprovecha al cómplice
core/cheats/cheat.gd           Cheat: una trampa activa del dealer y su evidencia
core/cheats/accusation.gd      Accusation: a qué apunta el jugador
core/cheats/cheat_table.gd     CheatTable: orquesta partido, dealer, trampas y acusaciones
tests/cheats/test_*.gd
tests/sim/test_cheats_sim.gd
```

---

### Tarea 1: HandView — ejecuta Claude

**Archivos:**
- Crear: `core/truco/hand_view.gd`
- Modificar: `core/ai/dealer_brain.gd`, sus tests y `tests/sim/test_ai_vs_ai.gd` (pasar `HandView` en lugar de `TrucoHand`)
- Test: `tests/truco/test_hand_view.gd`

**Interfaces:**
- Produce: `class_name HandView extends RefCounted`:
  - `func _init(p_hand: TrucoHand, p_me: int)`
  - `var me: int`; `var known_opponent_cards: Array[Card] = []` (vacía salvo trampa)
  - Lectores: `my_cards() -> Array[Card]`, `played(p: int) -> Array[Card]`, `baza_results() -> Array[int]`, `phase() -> TrucoHand.Phase`, `mano() -> int`, `current_player() -> int`, `legal_actions() -> Array[TrucoAction]`, `truco_level() -> int`, `declared_tanto(p: int) -> int`, `my_tanto() -> int`, `opponent_card_count() -> int`.
  - No existe ningún lector de las cartas en mano del rival ni de su tanto real.
- Cambia: `DealerBrain.choose(view: HandView) -> TrucoAction` y `DealerBrain.pick_card(view: HandView) -> int` (el `me` sale de la vista).

- [ ] **Paso 1: tests**
  - `test_vista_no_expone_cartas_del_rival`: `HandView` no tiene ningún método que devuelva `hand.cards[1 - me]` (se verifica con `has_method` sobre una lista de nombres prohibidos: `opponent_cards`, `cards`, `opponent_tanto`) y `known_opponent_cards` arranca vacía.
  - `test_vista_refleja_la_mano`: los lectores devuelven lo mismo que los campos de `TrucoHand` para `me`.
  - `test_opponent_card_count`: devuelve cuántas cartas le quedan al rival, sin revelarlas.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar y migrar `DealerBrain` y sus tests. **Paso 4:** pasan los tests nuevos y todos los del Plan 2.
- [ ] **Paso 5:** commit `feat(trampas): vista de la mano para el dealer`.

---

### Tarea 2: Ganchos en la mano y el partido — ejecuta Claude

**Archivos:**
- Modificar: `core/truco/hand.gd`, `core/truco/match.gd`
- Test: `tests/truco/test_hand.gd`, `tests/truco/test_match.gd` (agregar)

**Interfaces:**
- Produce, en `TrucoHand`:
  - `func add_card(p: int, card: Card) -> void`
  - `func replace_card(p: int, idx: int, card: Card) -> void`
  - `func total_cards(p: int) -> int` (en mano + jugadas)
  - `func force_end(winner: int, cheater: int) -> Array[GameEvent]`: el ganador suma lo que vale el truco en ese momento (`rejected_value` si hay un canto pendiente, si no `accepted_value`; mínimo 1). El tramposo pierde los puntos de envido de esta mano. Si el envido fue querido y el ganador provisional es el ganador de la acusación, suma el envido sin verificación. La fase pasa a `OVER` y emite `hand_over`. Ilegal si la mano ya terminó (devuelve `illegal_action`).
- Produce, en `TrucoMatch`:
  - `var deck: Deck` (el mazo de la mano en curso; antes era local)
  - `func award(p: int, points: int) -> Array[GameEvent]` (suma con tope en el objetivo, emite `match_over` si corresponde)
  - `func finish_forced_hand() -> Array[GameEvent]`: suma los puntos de una mano terminada con `force_end`, con la misma regla que `apply` (envido primero).

- [ ] **Paso 1: tests**
  - `test_force_end_paga_el_truco_y_quita_el_envido`: el dealer (1) ganó un envido no querido (1 punto), hay un truco querido (2); el jugador 0 acusa bien → `truco_points == [2, 0]`, `envido_points == [0, 0]`.
  - `test_force_end_con_truco_pendiente_paga_lo_asegurado`: truco cantado sin responder → el ganador suma 1.
  - `test_force_end_durante_declaracion`: con el envido querido y el mano declarando, `force_end(0, 1)` termina la mano en `OVER` sin pasar por `SHOW_DECISION`.
  - `test_force_end_en_mano_terminada_es_ilegal`.
  - `test_award_suma_con_tope_y_termina`: a 15, con 13 a 0, `award(0, 3)` deja 15 y emite `match_over`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(trampas): ganchos de la mano y el partido`.

---

### Tarea 3: Trampas y acusaciones como datos — ejecuta Codex

**Archivos:**
- Crear: `core/cheats/cheat.gd`, `core/cheats/accusation.gd`
- Test: `tests/cheats/test_cheat.gd`

**Interfaces:**
- Produce:
  - `class_name Cheat extends RefCounted` — `enum Kind { SLEEVE, DUPLICATE, ACCOMPLICE }`; `var kind: Kind`; `var card_key: String = ""` (la carta duplicada); `var evidence_visible: bool = false`; `static func make(p_kind: Kind, p_card_key: String = "") -> Cheat`.
  - `class_name Accusation extends RefCounted` — `enum Target { DEALER_HAND, HISTORY_CARD, ACCOMPLICE }`; `var target: Target`; `var card_key: String = ""`; `static func make(p_target: Target, p_card_key: String = "") -> Accusation`; `func matches(c: Cheat) -> bool`: `DEALER_HAND` ↔ `SLEEVE`; `HISTORY_CARD` ↔ `DUPLICATE` con el mismo `card_key` y `c.evidence_visible`; `ACCOMPLICE` ↔ `ACCOMPLICE`.

- [ ] **Paso 1: tests** — `test_cada_acusacion_matchea_su_trampa` (las tres parejas), `test_duplicada_sin_evidencia_no_matchea`, `test_carta_equivocada_no_matchea`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(trampas): trampas y acusaciones`.

---

### Tarea 4: Decisión de trampa del dealer — ejecuta Claude

**Archivos:**
- Modificar: `core/ai/dealer_brain.gd`, `core/ai/dealer_mood.gd`
- Test: `tests/ai/test_dealer_cheating.gd`

**Interfaces:**
- Produce, en `DealerBrain`:
  - `var cheat_budget: int` (se carga de `profile.cheat_budget` en `start_match()`)
  - `func decide_cheat(available: Array[Cheat.Kind]) -> int`: devuelve un `Cheat.Kind` o `-1`. Hace trampa con probabilidad `profile.cheating * CHEAT_RATE (0.35) * (1 - mood.suspicion * SUSPICION_DETER (0.8))`, solo si `cheat_budget > 0` y `available` no está vacía; elige al azar entre las disponibles; resta 1 al presupuesto.
  - Con el cómplice (`view.known_opponent_cards` no vacía), la fuerza de truco pasa a ser `KNOWN_WIN (0.9)` si su mejor carta supera la mejor del rival y `KNOWN_LOSE (0.2)` si no; el tanto del rival se calcula con `Envido.tanto(known_opponent_cards)` y quiere el envido solo si el suyo es mayor.
- Produce, en `DealerMood`: `func on_accused() -> void` (sospecha +`ACCUSED_SUSPICION (0.25)`), `func on_caught_player_cheating() -> void` (sospecha +`CAUGHT_PLAYER_SUSPICION (0.3)`, tilt +`CAUGHT_PLAYER_TILT (0.2)`), `func on_caught_cheating() -> void` (tilt +`CAUGHT_CHEATING_TILT (0.35)`, confianza −0.15). Todo recortado a [0, 1].

- [ ] **Paso 1: tests**
  - `test_presupuesto_cero_nunca_hace_trampa`: `cheating = 1`, presupuesto 0 → 1.000 llamadas devuelven `-1`.
  - `test_presupuesto_se_gasta`: presupuesto 2 y `cheating = 1` → como mucho 2 trampas en 1.000 llamadas.
  - `test_sospecha_frena_trampas`: con presupuesto infinito simulado (reponerlo en cada llamada), la tasa con sospecha 1.0 es menor que con 0.0 en al menos un 50%.
  - `test_complice_cambia_la_decision_de_truco`: con el cómplice mostrando que el rival tiene el ancho de espada, un dealer con mano media no quiere el truco en 100 de 100 intentos.
  - `test_humor_de_trampas_en_rango`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(trampas): el dealer decide hacer trampa`.

---

### Tarea 5: CheatTable, trampas del dealer — ejecuta Claude

**Archivos:**
- Crear: `core/cheats/cheat_table.gd`
- Test: `tests/cheats/test_cheat_table.gd`

**Interfaces:**
- Produce: `class_name CheatTable extends RefCounted`:
  - `func _init(p_match: TrucoMatch, p_brain: DealerBrain, p_dealer: int, p_rng: RandomNumberGenerator)`
  - `var active_cheat: Cheat` (`null` si no hay)
  - `func start_match() -> void` (llama a `brain.start_match()`)
  - `func start_hand() -> Array[GameEvent]`
  - `func is_dealer_turn() -> bool`
  - `func dealer_step() -> Array[GameEvent]`
  - `func player_action(a: TrucoAction) -> Array[GameEvent]`
  - `func evidence() -> Array[Cheat]` (las trampas activas con evidencia visible)

**Reglas:**
- `start_hand`: reparte con `match.start_hand()`, pregunta `brain.decide_cheat(disponibles)` y aplica:
  - **SLEEVE** (disponible si `match.deck.remaining() > 0`): `hand.add_card(dealer, deck.draw(1)[0])`. Evidencia visible desde el inicio (el dealer tiene 4 cartas). Emite `cheat_tell {kind}` con probabilidad `SLEEVE_TELL_CHANCE (0.6)`.
  - **ACCOMPLICE** (siempre disponible): la vista del dealer recibe las cartas del jugador. Evidencia visible desde el inicio; emite siempre `cheat_tell {kind}` (la figura detrás del jugador).
  - **DUPLICATE** (siempre disponible para decidir): queda planeada. En el primer turno del dealer en que ya se jugó una carta de rango ≥ `DUPLICATE_MIN_RANK (10)` en esta mano, reemplaza su carta más baja por una copia (`Card.new` con el mismo palo y número) de la carta jugada más alta; `card_key` queda fijado. La evidencia se vuelve visible cuando el dealer juega la copia. No emite pista en vivo.
- Cada evento que devuelve `start_hand`, `dealer_step` o `player_action` lo observa el cerebro.
- `dealer_step`: si `is_dealer_turn()`, aplica la duplicada si corresponde, arma la `HandView` (con `known_opponent_cards` si hay cómplice), pide `brain.choose`, aplica y devuelve los eventos. Si no es su turno, devuelve `illegal_action`.
- Al terminar la mano, `active_cheat` vuelve a `null`.

- [ ] **Paso 1: tests**
  - `test_manga_deja_cuatro_cartas_y_evidencia`.
  - `test_manga_sin_mazo_no_se_hace` (vaciar `match.deck` antes de decidir; presupuesto intacto).
  - `test_complice_da_cartas_y_evidencia`.
  - `test_duplicada_aparece_al_jugarse` (sin evidencia antes de que el dealer juegue la copia; con evidencia después).
  - `test_duplicada_no_jugada_no_es_evidencia`.
  - `test_presupuesto_cero_mano_limpia`: 200 manos con `cheating = 1` y presupuesto 0 → `active_cheat` siempre `null`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(trampas): trampas del dealer en la mesa`.

---

### Tarea 6: Acusaciones — ejecuta Claude

**Archivos:**
- Modificar: `core/cheats/cheat_table.gd`
- Test: `tests/cheats/test_accusation_flow.gd`

**Interfaces:**
- Produce, en `CheatTable`:
  - `const WRONG_ACCUSATION_POINTS := 3`
  - `func can_accuse() -> bool` (mano en curso y todavía no se acusó en esta mano)
  - `func accuse(acc: Accusation) -> Array[GameEvent]`

**Reglas (DISENO §4.2):**
- Acierto (`acc.matches(active_cheat)` y evidencia visible): `hand.force_end(player, dealer)`, `match.finish_forced_hand()`, `brain.mood.on_caught_cheating()`, `brain.mood.on_accused()`. Emite `accusation_right {kind}`.
- Error: `match.award(dealer, WRONG_ACCUSATION_POINTS)`, `brain.mood.on_accused()`, y el cerebro observa un `show_wrong` del jugador (le sube el tilt). Emite `accusation_wrong`. La mano sigue.
- Una sola acusación por mano; acusar sin poder devuelve `illegal_action`.

- [ ] **Paso 1: tests**
  - `test_acusar_la_manga_gana_la_mano`.
  - `test_acusar_al_complice_gana_la_mano`.
  - `test_acusar_la_duplicada_jugada_gana_la_mano`.
  - `test_acusar_sin_trampa_paga_tres`.
  - `test_segunda_acusacion_es_ilegal` (ni suma ni resta).
  - `test_acusar_con_la_mano_terminada_es_ilegal`.
  - `test_acusar_durante_la_declaracion` (Foco de revisión 4).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(trampas): acusaciones`.

---

### Tarea 7: Trampas del jugador — ejecuta Claude

**Archivos:**
- Modificar: `core/cheats/cheat_table.gd`
- Test: `tests/cheats/test_player_cheats.gd`

**Interfaces:**
- Produce, en `CheatTable`:
  - `enum PlayerCheat { MIRROR, MARKED }`
  - `func use_player_cheat(kind: PlayerCheat) -> Array[GameEvent]`. Si no lo pescan, emite `player_cheat_info`: `MIRROR` → `{cards: <cartas en mano del dealer>}`; `MARKED` → `{best_rank: <rango más alto del dealer>}`. Si lo pescan: `hand.force_end(dealer, player)`, `match.finish_forced_hand()`, `brain.mood.on_caught_player_cheating()`, emite `player_caught`.
  - Riesgo de que lo pesquen: `base * (1 + mood.suspicion)`, con `MIRROR_RISK := 0.25` y `MARKED_RISK := 0.10 + 0.10 * usos_de_MARKED_en_el_partido`, tope 0.95.
  - Las cargas por partido y qué amuleto habilita cada trampa son del Plan 4. Acá cualquier llamada es válida mientras haya una mano en curso.

- [ ] **Paso 1: tests**
  - `test_espejo_revela_la_mano`.
  - `test_marcadas_revela_el_rango_mas_alto`.
  - `test_riesgo_sube_con_la_sospecha`: 2.000 usos con sospecha 0 contra 2.000 con sospecha 1 (reiniciando la mano): la tasa de pescado del segundo es mayor.
  - `test_marcadas_cada_vez_mas_riesgosa`.
  - `test_pescado_pierde_la_mano`: el dealer suma lo que vale el truco y sube su sospecha y su tilt.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(trampas): trampas del jugador`.

---

### Tarea 8: Simulación con trampas — ejecuta Claude

**Archivos:**
- Test: `tests/sim/test_cheats_sim.gd`

- [ ] **Paso 1: tests** (semilla fija; el jugador es al azar y, si `can_accuse()`, acusa con una probabilidad fija apuntando a la evidencia visible si la hay, o a cualquier cosa si no)
  - `test_toda_trampa_deja_evidencia`: 500 partidos tramposo contra azar; cada vez que una trampa del dealer cambió el juego (manga y cómplice desde el inicio; duplicada desde que se jugó la copia), `evidence()` la contenía en ese momento.
  - `test_presupuesto_por_partido_se_respeta`: el tramposo nunca supera su `cheat_budget` en un partido.
  - `test_tramposo_hace_mas_trampa`: cantidad de trampas por partido del tramposo mayor que la del agresivo.
  - `test_acusador_atento_gana_mas`: un jugador al azar que siempre acusa bien la evidencia visible le gana al tramposo más partidos que uno que nunca acusa.
- [ ] **Paso 2:** correr. Si un test de comportamiento falla por constantes, Claude ajusta **solo constantes** y lo anota en el commit.
- [ ] **Paso 3:** commit `test(trampas): simulación con trampas`.

---

## Al terminar el Plan 3

- Todos los tests pasan.
- Revisión independiente contra `docs/DISENO.md` §4, con el Foco de revisión de arriba.
- Claude reporta cuántas trampas hace cada rival por partido y cuánto cambia el resultado acusar bien.
- Se escribe el Plan 4 (amuletos y mazos), que conecta el Espejo y las Cartas marcadas con `use_player_cheat`.
