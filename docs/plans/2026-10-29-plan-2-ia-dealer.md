# Plan 2 — IA del dealer

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). Leé también la spec, `docs/DISENO.md` §5. Si algo de este plan contradice la spec, pará y avisá. **Codex no puede correr Godot en su sandbox:** escribe el código y los tests, y Claude corre `run_tests.ps1`.

**Objetivo:** un dealer que juega Truco con convicción y no con cálculo. Tiene personalidad (rasgos), humor que cambia con la partida, memoria del jugador, miente el tanto según su carácter y da pistas con una confiabilidad propia. Incluye los 3 rivales del MVP.

**Arquitectura:** clases `RefCounted` en `core/ai/`, sin nodos. `DealerBrain.choose(hand, me)` devuelve una `TrucoAction` legal de `hand.legal_actions()`. `DealerBrain.observe(events, me)` actualiza humor y memoria con los eventos del núcleo. Cada decisión importante deja una `Tell` (pista) que la pantalla mostrará. Todo el azar sale del `RandomNumberGenerator` recibido. Los rasgos de los rivales viven en `data/rivals.json`.

**Tecnologías:** Godot 4.7.2, GDScript con tipado estático, GUT 9.7.1.

**Spec:** `docs/DISENO.md` §5 (IA del dealer), §3 (reglas).

## Restricciones globales

- Mismas reglas que el Plan 1: nada en `core/` extiende `Node`; sin `randi()`/`randf()` globales; tipos explícitos en todas las firmas; un commit por tarea `feat(ia): ...`.
- **El dealer nunca lee las cartas del rival.** Solo usa `hand.cards[me]`, `hand.played` (cartas ya visibles), las declaraciones de tanto y los cantos. Las trampas que ven cartas llegan en el Plan 3 y dejan evidencia.
- `choose` siempre devuelve una acción que está en `hand.legal_actions()`. Si una regla de decisión elige algo ilegal, cae a la primera acción legal del mismo tipo o, si no hay, a la primera legal.
- Todos los números de ajuste (umbrales, deltas de humor) son constantes con nombre en la clase que los usa. Ninguno queda suelto en una fórmula.
- Textos visibles: solo claves (`&"TELL_STRONG_1"`). El texto en español vive en `data/i18n/tells.csv`.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1` (sale distinto de 0 si algo falla).

## Foco de revisión

1. **Un perfil con todos los rasgos en 0 o en 1:** el dealer sigue devolviendo acciones legales y nunca se traba. Test en la Tarea 7.
2. **Mano que llega al dealer con 4 cartas** (la manga del Plan 3): la elección de carta y la fuerza no asumen 3. Test en la Tarea 4.
3. **El mano declaró 33:** el dealer como segundo solo puede decir `SON_BUENAS`. Test en la Tarea 5.
4. **Humor fuera de rango:** confianza, tilt y sospecha siempre quedan entre 0 y 1, por más eventos que lleguen. Test en la Tarea 3.
5. **Determinismo:** misma semilla y mismas acciones del rival dan exactamente las mismas decisiones del dealer. Test en la Tarea 7.

---

## Estructura de archivos

```
core/truco/hand.gd               (modificar) lectores públicos para la IA
core/ai/rival_profile.gd         RivalProfile: rasgos fijos + carga desde JSON + escalado por ronda
core/ai/dealer_mood.gd           DealerMood: confianza, tilt, sospecha
core/ai/player_model.gd          PlayerModel: memoria de cómo juega el jugador
core/ai/hand_strength.gd         HandStrength: fuerza de truco y de envido entre 0 y 1
core/ai/tell.gd                  Tell: pista que muestra el dealer
core/ai/dealer_brain.gd          DealerBrain: decide, observa, emite pistas, junta estadísticas
data/rivals.json                 los 3 rivales del MVP
data/i18n/tells.csv              textos de las pistas (clave, es)
tests/ai/test_*.gd               un archivo por clase
tests/sim/test_ai_vs_ai.gd       partidos IA contra IA y contra jugador al azar
```

---

### Tarea 1: Lectores públicos de la mano — ejecuta Claude

**Archivos:**
- Modificar: `core/truco/hand.gd`
- Test: `tests/truco/test_hand.gd` (agregar)

**Interfaces:**
- Produce, en `TrucoHand`:
  - `func declared_tanto(p: int) -> int` (`-1` si no declaró)
  - `func truco_level() -> int`
  - `func truco_pending() -> bool`
  - `func envido_called() -> bool` (hubo cualquier canto de envido en la mano)
  - `func envido_winner() -> int` (`-1` si no hubo envido querido o no terminó la declaración)
  - `func own_tanto(p: int) -> int` (tanto de las cartas en mano + jugadas de `p`; el que llama solo debe pedir el suyo)

- [ ] **Paso 1:** test `test_lectores_publicos`: con la mano de `test_envido_responde_a_truco_en_primera`, después de `DECLARE_TANTO 33` y `SON_BUENAS`, verificar `declared_tanto(0) == 33`, `declared_tanto(1) == -1`, `truco_level() == 1`, `truco_pending() == true`, `envido_called() == true`, `envido_winner() == 0`, `own_tanto(0) == 33`.
- [ ] **Paso 2:** correr y ver que falla. **Paso 3:** implementar (solo lectura de campos existentes). **Paso 4:** correr y ver que pasa.
- [ ] **Paso 5:** commit `feat(truco): lectores públicos para la IA`.

---

### Tarea 2: Perfil de rival y datos — ejecuta Codex

**Archivos:**
- Crear: `core/ai/rival_profile.gd`, `data/rivals.json`
- Test: `tests/ai/test_rival_profile.gd`

**Interfaces:**
- Produce: `class_name RivalProfile extends RefCounted`:
  - `var id: StringName`; `var aggression: float`; `var lying: float`; `var cheating: float`; `var stubbornness: float`; `var tell_reliability: float`; `var cheat_budget: int`
  - `static func from_dict(d: Dictionary) -> RivalProfile`
  - `static func load_all(path: String = "res://data/rivals.json") -> Dictionary` (clave `StringName` id → `RivalProfile`)
  - `func scaled_for_round(round: int) -> RivalProfile` (copia; suma `ROUND_STEP := 0.03` por ronda después de la 1 a agresividad, mentira y trampa, con tope 1.0; `cheat_budget` suma `(round - 1) / BUDGET_EVERY` con división entera y `BUDGET_EVERY := 4`)

`data/rivals.json` (valores de DISENO §5.4):

```json
{
  "agresivo":  {"aggression": 0.85, "lying": 0.30, "cheating": 0.15, "stubbornness": 0.60, "tell_reliability": 0.80, "cheat_budget": 1},
  "mentiroso": {"aggression": 0.50, "lying": 0.85, "cheating": 0.25, "stubbornness": 0.40, "tell_reliability": 0.40, "cheat_budget": 1},
  "tramposo":  {"aggression": 0.45, "lying": 0.40, "cheating": 0.85, "stubbornness": 0.50, "tell_reliability": 0.65, "cheat_budget": 3}
}
```

- [ ] **Paso 1: tests**
  - `test_carga_los_tres_rivales`: `load_all()` tiene `&"agresivo"`, `&"mentiroso"`, `&"tramposo"`; `agresivo.aggression == 0.85`; `tramposo.cheat_budget == 3`.
  - `test_escalado_por_ronda`: `mentiroso.scaled_for_round(5)` tiene `lying` = `min(1.0, 0.85 + 4 * 0.03)` = 0.97 (comparar con `assert_almost_eq`, tolerancia 0.0001) y `cheat_budget == 2`; el original no cambia.
  - `test_escalado_tope_1`: `scaled_for_round(40)` deja todos los rasgos en ≤ 1.0.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar (`FileAccess.get_file_as_string` + `JSON.parse_string`). **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(ia): perfiles de rival y datos`.

---

### Tarea 3: Humor y memoria del jugador — ejecuta Codex

**Archivos:**
- Crear: `core/ai/dealer_mood.gd`, `core/ai/player_model.gd`
- Test: `tests/ai/test_dealer_mood.gd`, `tests/ai/test_player_model.gd`

**Interfaces:**
- Produce:
  - `class_name DealerMood extends RefCounted` — `var confidence: float = 0.5`; `var tilt: float = 0.0`; `var suspicion: float = 0.0`; `func on_hand_result(won: bool) -> void`; `func on_caught_lying() -> void`; `func on_caught_player_lying() -> void`; `func on_wrong_show() -> void`. Constantes: `HAND_WON_CONFIDENCE := 0.10`, `HAND_LOST_CONFIDENCE := 0.10`, `HAND_LOST_TILT := 0.15`, `HAND_WON_TILT_DECAY := 0.05`, `CAUGHT_LYING_TILT := 0.30`, `CAUGHT_LYING_CONFIDENCE := 0.15`, `CAUGHT_PLAYER_CONFIDENCE := 0.10`, `WRONG_SHOW_TILT := 0.10`. Todo se recorta a [0, 1] después de cada cambio. `suspicion` existe pero no cambia en este plan: la usan las trampas del Plan 3.
  - `class_name PlayerModel extends RefCounted` — `var shows_seen: int`; `var lies_caught: int`; `var truco_calls: int`; `var hands_seen: int`; `func lie_rate() -> float` = `(lies_caught + LIE_PRIOR_LIES) / (shows_seen + LIE_PRIOR_SHOWS)` con `LIE_PRIOR_LIES := 0.6`, `LIE_PRIOR_SHOWS := 2.0`; `func truco_call_rate() -> float` = `truco_calls / max(hands_seen, 1)`.

- [ ] **Paso 1: tests**
  - `test_ganar_sube_confianza_y_baja_tilt`: tras `on_hand_result(false)` y `on_hand_result(true)`: `confidence == 0.5`, `tilt` ≈ 0.10.
  - `test_pescado_mintiendo`: `on_caught_lying()` → `tilt` ≈ 0.30, `confidence` ≈ 0.35.
  - `test_humor_siempre_entre_0_y_1`: 50 veces `on_caught_lying()` y después 50 veces `on_hand_result(true)`: los tres valores en [0, 1].
  - `test_lie_rate_con_prior`: modelo nuevo → `lie_rate()` ≈ 0.3; con `shows_seen = 8`, `lies_caught = 6` → ≈ 0.66.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(ia): humor del dealer y memoria del jugador`.

---

### Tarea 4: Fuerza de la mano — ejecuta Claude

**Archivos:**
- Crear: `core/ai/hand_strength.gd`
- Test: `tests/ai/test_hand_strength.gd`

**Interfaces:**
- Consume: `Card.truco_rank()`, `Envido.tanto`, `TrucoHand.baza_results`.
- Produce: `class_name HandStrength extends RefCounted`:
  - `static func envido(tanto: int) -> float` = `tanto / 33.0`
  - `static func truco(cards: Array[Card], baza_results: Array[int], me: int) -> float`: promedio de `truco_rank / 14.0` de las 2 mejores cartas que quedan (o de la única), más `BAZA_WON_BONUS := 0.25` por cada baza ganada por `me` y menos `BAZA_LOST_PENALTY := 0.25` por cada baza perdida; recortado a [0, 1]. Sin cartas: 1.0 si `me` va ganando las bazas, 0.0 si no.

- [ ] **Paso 1: tests**
  - `test_envido_normaliza`: `envido(33) == 1.0`, `envido(0) == 0.0`.
  - `test_truco_mano_fuerte_y_debil`: [1 espada, 1 basto, 4 copa] > 0.9; [4 copa, 5 oro, 6 basto] < 0.25.
  - `test_truco_baza_ganada_suma`: misma mano con `[me]` en `baza_results` vale 0.25 más (recortado).
  - `test_truco_con_cuatro_cartas`: con 4 cartas usa las 2 mejores y no falla.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(ia): fuerza de truco y envido`.

---

### Tarea 5: Cerebro del dealer — ejecuta Claude

**Archivos:**
- Crear: `core/ai/tell.gd`, `core/ai/dealer_brain.gd`
- Test: `tests/ai/test_dealer_brain.gd`

**Interfaces:**
- Consume: Tareas 1 a 4.
- Produce:
  - `class_name Tell extends RefCounted` — `var category: StringName` (`&"strong"` o `&"weak"`); `var text_key: StringName`; `var icon: StringName` (`&"calm"`, `&"smug"`, `&"nervous"`, `&"angry"`); `var honest: bool`.
  - `class_name DealerBrain extends RefCounted`:
    - `func _init(p_profile: RivalProfile, p_rng: RandomNumberGenerator)`
    - `var profile: RivalProfile`; `var mood: DealerMood`; `var model: PlayerModel`; `var last_tell: Tell` (`null` si la última decisión no emitió pista)
    - `var stats: Dictionary` con claves `&"decisions"`, `&"declarations"`, `&"lies"`, `&"envido_calls"`, `&"truco_calls"`, `&"tells"`, `&"honest_tells"` (enteros)
    - `func choose(hand: TrucoHand, me: int) -> TrucoAction`
    - `func observe(events: Array[GameEvent], me: int) -> void`

**Cómo decide** (todas las constantes con nombre en `dealer_brain.gd`):

- **Rasgos efectivos:** `aggr = clamp(aggression + tilt * TILT_AGGRESSION (0.3))`; `lie = clamp(lying + tilt * TILT_LYING (0.2))`.
- **Fuerza percibida:** `perceived(x) = clamp(x + (confidence - 0.5) * CONFIDENCE_BIAS (0.4) + ruido)`, con ruido uniforme en `[-NOISE, NOISE]`, `NOISE := 0.15`. Se calcula una vez por decisión.
- **Cantar envido** (cuando es legal): si `pe ≥ ENVIDO_CALL (0.75) - aggr * 0.25` → canta; si no, con probabilidad `lie * ENVIDO_BLUFF (0.35)` canta igual (farol). Elige `FALTA_ENVIDO` si `pe ≥ 0.95` y `aggr ≥ 0.6`; `REAL_ENVIDO` si `pe ≥ 0.85`; si no, `ENVIDO`.
- **Responder envido:** subir si `pe ≥ 0.9`; querer si `pe ≥ ENVIDO_ACCEPT (0.55) - aggr * 0.15 - model.lie_rate() * 0.2`; si no, no quiero.
- **Declarar el tanto como mano:** miente con probabilidad `lie * (1 - envido(real))`. Mentira = `max(real + 1, rng.randi_range(LIE_MIN (26), LIE_MAX (32)))`, recortado a 33. Si no miente, declara `real`.
- **Declarar como segundo:** si el mano declaró 33 → `SON_BUENAS`. Si `real > declarado_del_mano` → declara `real`. Si no, con probabilidad `lie * SECOND_LIE (0.6)` miente declarando `rng.randi_range(declarado + 1, min(33, declarado + 4))`; si no, `SON_BUENAS`.
- **Pedir que muestre:** probabilidad `SHOW_BASE (0.15) + model.lie_rate() * 0.6 + (0.2 si lo declarado por el rival ≥ 31) + (0.2 si lo declarado por el rival supera el tanto propio en ≥ 5)`, con tope 0.9.
- **Cantar truco** (en su turno, si `can_raise`): si `pt ≥ TRUCO_CALL (0.7) - aggr * 0.3` → canta; si no, con probabilidad `lie * TRUCO_BLUFF (0.25)` canta igual.
- **Responder truco:** subir si `pt ≥ 0.85`; querer si `pt ≥ TRUCO_ACCEPT (0.5) - aggr * 0.2 - stubbornness * 0.1 - model.truco_call_rate() * 0.15`; irse al mazo si `pt < 0.1` y `stubbornness < 0.5`; si no, no quiero.
- **Elegir carta:** si responde a una carta del rival en la baza: la carta más baja que le gana; si ninguna gana, la más baja. Si abre la baza: con `aggr ≥ 0.6`, la más alta; si no, la del medio (la mediana por rango).
- **Irse al mazo en su turno:** solo si `pt < 0.05`, ya perdió una baza y `truco_level() ≥ 2`.

**Estadísticas:** cada `choose` suma 1 a `decisions`; cada declaración suma a `declarations` y, si el número declarado difiere del real, a `lies`; cada canto de envido o de truco suma a su contador.

**Observar** (`observe`):
- `hand_over`: `mood.on_hand_result(won)` con `won` = el dealer sumó más puntos que el rival en esa mano; `model.hands_seen += 1`.
- `lie_caught` con `player == me` → `mood.on_caught_lying()`; con `player != me` → `mood.on_caught_player_lying()` y `model.lies_caught += 1`.
- `show_demanded` con `player == me` → `model.shows_seen += 1`.
- `show_wrong` con `player == me` → `mood.on_wrong_show()`.
- `call_made` del rival con un canto de truco → `model.truco_calls += 1`.

- [ ] **Paso 1: tests** (rng con semilla fija; para probabilidades, 500 repeticiones con mano armada)
  - `test_siempre_elige_accion_legal`: en cada fase alcanzable de una mano armada, `choose` devuelve una acción que está en `legal_actions()`.
  - `test_mano_33_segundo_dice_son_buenas`: el mano declaró 33; el dealer (segundo) devuelve `SON_BUENAS`.
  - `test_nunca_miente_con_mentira_0`: perfil con `lying = 0`, tilt 0: en 500 declaraciones, `stats.lies == 0`.
  - `test_mentiroso_miente_mas_que_honesto`: perfil `lying = 0.85` vs `lying = 0.1` con tanto real 5: la tasa de mentira del primero supera a la del segundo por al menos 0.3.
  - `test_agresivo_canta_truco_mas`: `aggression = 0.9` vs `0.1` con una mano media ([3 oro, 6 copa, 11 basto]): la tasa de canto del primero es mayor.
  - `test_responde_baza_con_la_mas_baja_que_gana`: el rival jugó un 2 de oro; el dealer tiene [3 copa, 1 espada, 4 basto] → juega el 3 de copa.
  - `test_observe_pescado_mintiendo_sube_tilt`.
  - `test_tilt_aumenta_faroles`: mismo perfil con `tilt = 0` y `tilt = 1`: más faroles de envido con tilt.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(ia): cerebro del dealer`.

---

### Tarea 6: Pistas — ejecuta Claude

**Archivos:**
- Modificar: `core/ai/dealer_brain.gd`
- Crear: `data/i18n/tells.csv`
- Test: `tests/ai/test_tells.gd`

**Interfaces:**
- Produce, en `DealerBrain`: `func _make_tell(perceived: float) -> Tell` (privado), llamado en cada canto de envido o truco, en cada respuesta a un canto y en cada declaración de tanto. Deja el resultado en `last_tell`; las demás decisiones dejan `last_tell = null`.

**Reglas:**
- Categoría verdadera: `&"strong"` si `perceived ≥ TELL_STRONG (0.6)`, si no `&"weak"`.
- Con probabilidad `profile.tell_reliability`, la pista muestra la categoría verdadera (`honest = true`); si no, la opuesta (`honest = false`).
- `text_key`: elegida al azar entre `TELL_STRONG_1` a `TELL_STRONG_4` o `TELL_WEAK_1` a `TELL_WEAK_4`, según la categoría mostrada.
- `icon`: `&"angry"` si `tilt ≥ 0.5`; si no `&"smug"` si `confidence ≥ 0.7`; si no `&"nervous"` si la categoría mostrada es `weak`; si no `&"calm"`.
- Suma a `stats.tells` y, si es honesta, a `stats.honest_tells`.

`data/i18n/tells.csv` (formato de traducción CSV de Godot):

```csv
keys,es
TELL_STRONG_1,"Repartí, que hoy estoy de suerte."
TELL_STRONG_2,"Mirá que no me tiembla el pulso."
TELL_STRONG_3,"Esta mano ya la vi ganar."
TELL_STRONG_4,"Andá contando la plata."
TELL_WEAK_1,"Hmm... a ver qué sale."
TELL_WEAK_2,"No sé, no sé."
TELL_WEAK_3,"Esto se pone feo."
TELL_WEAK_4,"Dejame pensar un poco."
```

- [ ] **Paso 1: tests**
  - `test_confiabilidad_se_respeta`: perfil con `tell_reliability = 0.8`; 2.000 pistas → `honest_tells / tells` entre 0.75 y 0.85.
  - `test_icono_angry_con_tilt`: tilt 0.6 → `icon == &"angry"`.
  - `test_decision_sin_pista`: jugar una carta deja `last_tell == null`.
  - `test_csv_tiene_todas_las_claves`: el CSV contiene las 8 claves.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(ia): pistas del dealer`.

---

### Tarea 7: IA contra IA — ejecuta Codex (Claude corre y ajusta constantes)

**Archivos:**
- Test: `tests/sim/test_ai_vs_ai.gd`

**Interfaces:**
- Consume: `TrucoMatch`, `DealerBrain`, `RivalProfile.load_all()`.

- [ ] **Paso 1: tests** (semilla fija 7; un `RandomNumberGenerator` por cerebro, con semilla derivada)
  - `test_rivales_le_ganan_al_azar`: cada rival del MVP contra un jugador que elige acciones legales al azar, 200 partidos a 15: gana al menos el 70%.
  - `test_mentiroso_miente_mas_que_agresivo`: 200 partidos mentiroso contra agresivo: `lies / declarations` del mentiroso supera al del agresivo por al menos 0.15.
  - `test_agresivo_canta_mas_truco`: en los mismos partidos, `truco_calls / decisions` del agresivo es mayor que el del mentiroso.
  - `test_perfiles_extremos_no_se_traban`: perfiles con todos los rasgos en 0 y en 1, 100 partidos entre sí: ningún `illegal_action` y ninguna mano con más de 60 acciones.
  - `test_determinismo`: dos corridas con la misma semilla dan la misma secuencia de acciones del dealer en 20 partidos.
- [ ] **Paso 2:** correr (Claude). Si un test de comportamiento falla por las constantes de la Tarea 5, Claude ajusta **solo constantes**, anota cada cambio en el mensaje del commit y vuelve a correr. Si falla por un error de lógica, se corrige con un test nuevo que lo reproduzca.
- [ ] **Paso 3:** commit `test(ia): partidos IA contra IA`.

---

## Al terminar el Plan 2

- Todos los tests pasan con `run_tests.ps1`.
- Revisión independiente de toda la rama contra `docs/DISENO.md` §5, con el Foco de revisión de arriba.
- Claude reporta las tasas reales de mentira, canto y victoria de cada rival, para que Joako decida si se sienten como el diseño.
- Se escribe el Plan 3 (trampas) a partir de las interfaces reales de este plan.
