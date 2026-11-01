# Plan 4 — Amuletos y mazos

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). Leé también la spec, `docs/DISENO.md` §8 (amuletos) y §9 (mazos). Si algo de este plan contradice la spec, pará y avisá. **Codex no puede correr Godot en su sandbox:** escribe el código y los tests, y Claude corre `run_tests.ps1`.

**Objetivo:** los 12 amuletos del MVP funcionan dentro de un partido, con sus cargas, y los mazos Normal y de la Viuda cambian las reglas de la run. La tienda, los precios y los premios en plata son del Plan 5; este plan solo expone los multiplicadores que el Plan 5 va a usar.

**Arquitectura:**
- Los amuletos son datos (`data/amulets.json`). Un `Loadout` tiene hasta 4 amuletos equipados con sus cargas.
- Un `AmuletSystem` envuelve la `CheatTable` del Plan 3: aplica los efectos activos cuando el jugador usa un amuleto y los pasivos en el momento que corresponde (al empezar la mano, al decidir si se muestra el tanto).
- Los efectos que cambian reglas de la mesa no se programan dentro de la `CheatTable`: la mesa consulta un objeto `TableRules` con banderas que el `AmuletSystem` prende y apaga.
- La run (Plan 5) es dueña del `Loadout` y del mazo elegido; acá solo se definen y se prueban.

**Tecnologías:** Godot 4.7.2, GDScript con tipado estático, GUT 9.7.1.

**Spec:** `docs/DISENO.md` §8 y §9.

## Restricciones globales

- Mismas reglas que los planes anteriores: nada en `core/` extiende `Node`; sin azar global; tipos explícitos; constantes con nombre; un commit por tarea (`feat(amuletos): ...`).
- Todo efecto de un amuleto emite un evento `amulet_used {id, ...}` (o `amulet_info` si revela algo), para que la pantalla lo muestre.
- Usar un amuleto sin cargas, sin equipar o fuera de su momento devuelve `illegal_action` y no gasta carga.
- Las cargas se reponen al empezar cada partido.
- Las trampas del jugador (Espejo, Cartas marcadas) pasan por `CheatTable.use_player_cheat`: mismo riesgo y mismas consecuencias que en el Plan 3.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1`.

## Decisiones de interpretación (la spec deja estas puntas abiertas)

1. **Marcador permanente** dice "por el resto del partido", pero las cartas se reparten de nuevo en cada mano. Se aplica a la carta durante el resto de **la mano**.
2. **Marcador y tanto 34** (pendiente del Plan 1): el marcador no puede convertir una carta en otra que ya tenés en la mano (mismo número y palo). Así nunca hay dos 7 del mismo palo, y el tanto máximo sigue siendo 33.
3. **Rosario** "anula el último canto del rival": solo se puede usar mientras un canto del dealer está esperando tu respuesta. La mano vuelve al estado de antes de ese canto.
4. **Facón** "obliga a querer tu próximo canto": se activa, y el próximo canto tuyo (envido o truco) lo responde el dealer con `QUIERO` sí o sí. Se apaga después de usarse una vez.
5. **Vaso de caña** "tu próxima declaración no se verifica": si el dealer pide mostrar tu próxima declaración, cuenta como si la hubiera aceptado. Al usarlo, la sospecha del dealer sube `GLASS_SUSPICION := 0.2`.
6. **Cigarrillo** "el dealer pide mostrar la mitad de veces cuando mentís": la mesa sabe si mentiste; cuando el dealer pide mostrar una declaración tuya mentida, con probabilidad 0.5 su pedido se convierte en `ACCEPT_TANTO`.
7. **Moneda aplastada** "×1,5 si ganás el partido sin cantar envido": cuenta solo los envidos que cantaste vos, no los que respondiste.

## Foco de revisión

1. **Amuleto activo sin cargas, o usado con la mano terminada:** `illegal_action`, sin gastar carga y sin efecto. Test en la Tarea 5.
2. **Rosario sobre un canto que subió otro canto tuyo** (vos cantaste envido, el dealer subió a real envido): vuelve a "vos cantaste envido, el dealer responde". Test en la Tarea 3.
3. **Marcador que produce una carta duplicada en tu mano:** se rechaza. Test en la Tarea 3.
4. **Facón y Rosario en la misma mano:** no se pisan; el facón sigue esperando tu próximo canto. Test en la Tarea 5.
5. **Mazo de la Viuda con un rival de presupuesto 0:** sigue en 0 (el doble de 0). Test en la Tarea 6.

---

## Estructura de archivos

```
core/amulets/amulet_def.gd      AmuletDef: datos de un amuleto
core/amulets/loadout.gd         Loadout: amuletos equipados y sus cargas
core/amulets/table_rules.gd     TableRules: banderas que consulta la mesa
core/amulets/amulet_system.gd   AmuletSystem: usa los amuletos sobre la mesa
core/run/run_deck.gd            RunDeck: mazo de condición (Normal, Viuda)
core/truco/hand.gd              (modificar) deshacer el último canto
core/cards/...                  (sin cambios)
core/cheats/cheat_table.gd      (modificar) consulta TableRules
data/amulets.json
data/decks.json
tests/amulets/test_*.gd
tests/sim/test_amulets_sim.gd
```

---

### Tarea 1: Definición de amuletos y datos — ejecuta Codex

**Archivos:**
- Crear: `core/amulets/amulet_def.gd`, `data/amulets.json`
- Test: `tests/amulets/test_amulet_def.gd`

**Interfaces:**
- Produce: `class_name AmuletDef extends RefCounted`:
  - `enum Category { CARDS, TANTO, CALLS, INFO, CHEAT, ECONOMY }`; `enum Kind { PASSIVE, ACTIVE }`; `enum Rarity { COMMON, RARE, LEGENDARY }`
  - `var id: StringName`; `var category: Category`; `var kind: Kind`; `var rarity: Rarity`; `var charges: int` (0 para pasivos); `var name_key: StringName`; `var desc_key: StringName`
  - `static func from_dict(id: String, d: Dictionary) -> AmuletDef`
  - `static func load_all(path: String = "res://data/amulets.json") -> Dictionary` (id → `AmuletDef`)

`data/amulets.json` (valores de DISENO §8; las claves de texto siguen el patrón `AMULET_<ID>_NAME` / `AMULET_<ID>_DESC`):

| id | category | kind | rarity | charges |
|---|---|---|---|---|
| `marker` | CARDS | ACTIVE | RARE | 1 |
| `spare_deck` | CARDS | ACTIVE | RARE | 2 |
| `cigarette` | TANTO | PASSIVE | COMMON | 0 |
| `cana_glass` | TANTO | ACTIVE | RARE | 1 |
| `rosary` | CALLS | ACTIVE | RARE | 1 |
| `facon` | CALLS | ACTIVE | RARE | 1 |
| `glasses` | INFO | PASSIVE | COMMON | 0 |
| `hat` | INFO | ACTIVE | LEGENDARY | 1 |
| `mirror` | CHEAT | ACTIVE | LEGENDARY | 2 |
| `marked_cards` | CHEAT | ACTIVE | RARE | 3 |
| `red_ribbon` | ECONOMY | PASSIVE | COMMON | 0 |
| `train_coin` | ECONOMY | PASSIVE | COMMON | 0 |

- [ ] **Paso 1: tests** — `test_carga_los_doce`, `test_valores_del_marcador` (RARE, ACTIVE, 1 carga, `name_key == &"AMULET_MARKER_NAME"`), `test_pasivos_tienen_cero_cargas`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(amuletos): datos de los 12 amuletos`.

---

### Tarea 2: Loadout — ejecuta Codex

**Archivos:**
- Crear: `core/amulets/loadout.gd`
- Test: `tests/amulets/test_loadout.gd`

**Interfaces:**
- Consume: `AmuletDef`.
- Produce: `class_name Loadout extends RefCounted`:
  - `const SLOTS := 4`
  - `func equip(def: AmuletDef) -> bool` (`false` si no hay espacio o ya está equipado; no se repiten amuletos)
  - `func unequip(id: StringName) -> AmuletDef` (`null` si no estaba)
  - `func has(id: StringName) -> bool`
  - `func charges_left(id: StringName) -> int`
  - `func spend(id: StringName) -> bool` (`false` si es pasivo, no está o no le quedan cargas)
  - `func reset_charges() -> void`
  - `func equipped() -> Array[AmuletDef]`
  - `func shop_price_multiplier() -> float` (0.8 con `red_ribbon`, si no 1.0; constante `RED_RIBBON_DISCOUNT := 0.2`)
  - `func prize_multiplier(player_called_envido: bool) -> float` (1.5 con `train_coin` si `player_called_envido == false`, si no 1.0; constante `TRAIN_COIN_MULTIPLIER := 1.5`)

- [ ] **Paso 1: tests** — `test_cuatro_espacios`, `test_no_repite`, `test_gastar_y_reponer_cargas`, `test_pasivo_no_gasta`, `test_cinta_roja_descuenta`, `test_moneda_multiplica_solo_sin_envido`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(amuletos): amuletos equipados y cargas`.

---

### Tarea 3: Deshacer cantos y marcar cartas — ejecuta Claude

**Archivos:**
- Modificar: `core/truco/hand.gd`
- Test: `tests/truco/test_hand.gd` (agregar)

**Interfaces:**
- Produce, en `TrucoHand`:
  - `func undo_last_call(by: int) -> bool`: si el último canto lo hizo el rival de `by` y está esperando la respuesta de `by`, la mano vuelve exactamente al estado anterior a ese canto (fase, apuesta de truco, secuencia de envido, quién cantó, a qué fase volver). Devuelve `false` y no cambia nada en cualquier otro caso. Implementación: guardar una foto del estado antes de cada canto.
  - `func can_mark(p: int, idx: int, new_number: int) -> bool`: el número es válido y la carta resultante (número nuevo, palo efectivo de la carta) no coincide con otra carta en mano de `p`.

- [ ] **Paso 1: tests**
  - `test_rosario_anula_truco`: el dealer (1) canta truco; `undo_last_call(0)` → fase `PLAYING`, `truco_level() == 0`, le toca al dealer.
  - `test_rosario_anula_la_subida_de_envido`: el jugador canta envido, el dealer sube a real envido; `undo_last_call(0)` → fase `ENVIDO_RESPONSE`, responde el dealer, la secuencia vuelve a `[ENVIDO]`.
  - `test_rosario_sin_canto_pendiente_no_hace_nada`.
  - `test_rosario_no_anula_un_canto_propio`: el jugador canta truco; `undo_last_call(0)` → `false`.
  - `test_marcar_no_duplica_una_carta`: con [7 oro, 6 oro, 4 copa], marcar el 6 como 7 → `false`; marcarlo como 5 → `true`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(amuletos): deshacer cantos y marcar cartas`.

---

### Tarea 4: Reglas de mesa — ejecuta Claude

**Archivos:**
- Crear: `core/amulets/table_rules.gd`
- Modificar: `core/cheats/cheat_table.gd`
- Test: `tests/amulets/test_table_rules.gd`

**Interfaces:**
- Produce: `class_name TableRules extends RefCounted` — `var cigarette := false`; `var skip_next_show := false`; `var force_accept_next_call := false`; `var dealer_budget_multiplier := 1`.
- Produce, en `CheatTable`:
  - `var rules := TableRules.new()`
  - `var player_called_envido := false` (se reinicia en `start_match`; se prende cuando el jugador canta envido, real envido o falta envido)
  - En `start_match`: `brain.cheat_budget *= rules.dealer_budget_multiplier`.
  - En `dealer_step`:
    - si el dealer va a responder un canto del jugador y `force_accept_next_call`, juega `QUIERO` y apaga la bandera;
    - si el dealer elige `DEMAND_SHOW` sobre una declaración del jugador y `skip_next_show`, se convierte en `ACCEPT_TANTO` y apaga la bandera;
    - si elige `DEMAND_SHOW`, el jugador mintió (`declared_tanto(jugador) > own_tanto(jugador)`) y `cigarette`, con probabilidad `CIGARETTE_CHANCE := 0.5` se convierte en `ACCEPT_TANTO`.

- [ ] **Paso 1: tests** (con `start_hand(-1, cartas, mano)` y mazos armados)
  - `test_facon_obliga_a_querer`: el jugador canta truco con mano mala; con la bandera prendida, el dealer quiere en 50 de 50 intentos; la bandera se apaga.
  - `test_vaso_anula_el_pedido_de_mostrar`.
  - `test_cigarrillo_reduce_los_pedidos`: en 400 manos donde el jugador miente, la tasa de `DEMAND_SHOW` efectivos con cigarrillo es menor que sin él.
  - `test_viuda_duplica_el_presupuesto`.
  - `test_registra_si_el_jugador_canto_envido`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(amuletos): reglas de mesa`.

---

### Tarea 5: AmuletSystem — ejecuta Claude

**Archivos:**
- Crear: `core/amulets/amulet_system.gd`
- Test: `tests/amulets/test_amulet_system.gd`

**Interfaces:**
- Consume: `CheatTable`, `Loadout`, `TableRules`, `AmuletDef`.
- Produce: `class_name AmuletSystem extends RefCounted`:
  - `func _init(p_table: CheatTable, p_loadout: Loadout, p_rng: RandomNumberGenerator)`
  - `func start_match() -> void` (repone cargas; `rules.cigarette = loadout.has(&"cigarette")`)
  - `func start_hand(...) -> Array[GameEvent]` (mismos parámetros que `CheatTable.start_hand`; después de repartir aplica los pasivos de inicio de mano)
  - `func can_use(id: StringName) -> bool`
  - `func use(id: StringName, args: Dictionary = {}) -> Array[GameEvent]`

**Efectos** (cuándo se puede usar → qué hace → evento):

| id | Cuándo | Efecto | Evento |
|---|---|---|---|
| `marker` | mano en curso, `args.card_index` y `args.number` válidos según `can_mark` | agrega un `CardModifier` (alcance `HAND`) con el número nuevo | `amulet_used` |
| `spare_deck` | mano en curso, `args.card_index` válido | cambia esa carta por una al azar de un mazo de reserva propio del sistema (40 cartas, sin las que están en la mesa) | `amulet_used {card}` |
| `cigarette` | pasivo | ver Tarea 4 | — |
| `cana_glass` | mano en curso | `rules.skip_next_show = true`; sospecha del dealer +0.2 | `amulet_used` |
| `rosary` | un canto del dealer espera respuesta del jugador | `hand.undo_last_call(jugador)` | `amulet_used` |
| `facon` | mano en curso y bandera apagada | `rules.force_accept_next_call = true` | `amulet_used` |
| `glasses` | pasivo, al empezar cada mano | revela el número de 1 carta al azar del dealer | `amulet_info {numbers: [n]}` |
| `hat` | mano en curso | revela los números de todas las cartas del dealer | `amulet_info {numbers: [...]}` |
| `mirror` | mano en curso | `table.use_player_cheat(MIRROR)` | lo que devuelva la mesa |
| `marked_cards` | mano en curso | `table.use_player_cheat(MARKED)` | lo que devuelva la mesa |
| `red_ribbon` | pasivo, de tienda | (Plan 5) | — |
| `train_coin` | pasivo, de premio | (Plan 5) | — |

- [ ] **Paso 1: tests** — uno por amuleto activo (efecto y gasto de carga), más:
  - `test_sin_cargas_es_ilegal_y_no_gasta`.
  - `test_amuleto_no_equipado_es_ilegal`.
  - `test_mano_terminada_es_ilegal`.
  - `test_lentes_revelan_un_numero_por_mano`.
  - `test_sombrero_no_revela_palos` (el evento solo tiene números).
  - `test_facon_y_rosario_no_se_pisan` (Foco de revisión 4).
  - `test_cargas_se_reponen_por_partido`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(amuletos): sistema de amuletos`.

---

### Tarea 6: Mazos de condición — ejecuta Codex

**Archivos:**
- Crear: `core/run/run_deck.gd`, `data/decks.json`
- Test: `tests/amulets/test_run_deck.gd`

**Interfaces:**
- Produce: `class_name RunDeck extends RefCounted` — `var id: StringName`; `var prize_multiplier: float`; `var dealer_budget_multiplier: int`; `var name_key: StringName`; `var desc_key: StringName`; `static func load_all(path: String = "res://data/decks.json") -> Dictionary`; `func apply_to(rules: TableRules) -> void`.

`data/decks.json`:

```json
{
  "normal": {"prize_multiplier": 1.0, "dealer_budget_multiplier": 1},
  "widow":  {"prize_multiplier": 2.0, "dealer_budget_multiplier": 2}
}
```

- [ ] **Paso 1: tests** — `test_carga_normal_y_viuda`, `test_viuda_aplica_a_las_reglas`, `test_viuda_con_presupuesto_cero` (con una `CheatTable` real: el presupuesto queda en 0).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(amuletos): mazos de condición`.

---

### Tarea 7: Simulación con amuletos — ejecuta Claude

**Archivos:**
- Test: `tests/sim/test_amulets_sim.gd`

- [ ] **Paso 1: tests** (semilla fija; jugador al azar con 4 amuletos equipados al azar que, en cada turno suyo, intenta usar uno con probabilidad 0.2)
  - `test_amuletos_al_azar_no_rompen_nada`: 300 partidos contra cada rival: ningún `illegal_action` en acciones que `can_use` aprobó, ninguna mano de más de 80 pasos, ninguna carta repetida en la mano de nadie salvo la duplicada del dealer.
  - `test_cargas_nunca_negativas`.
  - `test_amuletos_ayudan`: un jugador al azar con [sombrero, facón, espejo, rosario] le gana al agresivo más partidos que sin amuletos.
- [ ] **Paso 2:** correr. Si un test de comportamiento falla por constantes, Claude ajusta **solo constantes** y lo anota en el commit.
- [ ] **Paso 3:** commit `test(amuletos): simulación con amuletos`.

---

## Al terminar el Plan 4

- Todos los tests pasan.
- Revisión independiente contra `docs/DISENO.md` §8 y §9, con el Foco de revisión de arriba.
- Claude reporta cuánto cambia la tasa de victoria cada amuleto.
- Se escribe el Plan 5 (run y economía), que usa `Loadout`, `RunDeck` y los multiplicadores.
