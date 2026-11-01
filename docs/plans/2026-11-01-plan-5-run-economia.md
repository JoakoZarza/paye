# Plan 5 — Run y economía

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). Leé también la spec, `docs/DISENO.md` §6 (estructura de la run), §7 (economía) y §10 (progresión). Si algo de este plan contradice la spec, pará y avisá. **Codex no puede correr Godot en su sandbox:** escribe el código y los tests, y Claude corre `run_tests.ps1`.

**Objetivo:** una run completa como lógica pura: entrar al bar con $135, pagar la entrada, jugar el partido, cobrar el premio con sus multiplicadores, comprar en la tienda (con fiado), seguir de ronda, morir o retirarse con $10.000.000. La deuda y el legado pasan a la run siguiente. Una simulación de economía calibra los números de §7.

**Arquitectura:**
- Los números viven en `data/economy.json`; `Economy` los lee y responde preguntas ("¿cuánto cuesta entrar a la ronda 5?").
- `RunState` es el estado de una run (plata, fiado, deuda, ronda, amuletos). No sabe de Truco.
- `RunController` es la única entrada para las pantallas: arma la `CheatTable` y el `AmuletSystem` de cada partido, cobra la entrada, paga el premio, abre la tienda y decide muerte o retiro. Emite eventos como el resto del núcleo.
- `MetaState` guarda entre runs la deuda y el legado en un archivo JSON.
- La simulación de economía no juega Truco: usa una probabilidad de ganar cada partido para recorrer miles de runs en segundos.

**Tecnologías:** Godot 4.7.2, GDScript con tipado estático, GUT 9.7.1.

**Spec:** `docs/DISENO.md` §6, §7 y §10.

## Restricciones globales

- Mismas reglas que los planes anteriores: nada en `core/` extiende `Node`; sin azar global; tipos explícitos; constantes con nombre; un commit por tarea (`feat(run): ...`).
- **Plata en enteros.** Los multiplicadores se aplican al final y se redondea hacia abajo (`floori`).
- Todo número de §7 marcado **(ajustable)** vive en `data/economy.json`, nunca en el código.
- **Fuera del Plan 5** (DISENO §12): doble o nada, el acreedor como rival, logros, fichas y "subir la apuesta". El retiro con $10M sí entra.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1`.

## Decisiones de interpretación

1. **Rival de cada ronda:** los 3 rivales del MVP se repiten en orden (agresivo, mentiroso, tramposo), escalados con `scaled_for_round(ronda)`. Las rondas 4, 8 y 12 son jefes: el mismo rival que toca, a 30 puntos.
2. **Fiado:** podés deber hasta `2 × tu plata` en el momento de comprar (DISENO §7.4). Pagás lo que tenés y el resto va al fiado. Al ganar el partido siguiente, el fiado se descuenta del premio. Si el premio no alcanza, el resto sigue como fiado.
3. **Cobro del acreedor:** si arrancás con deuda, el 50% de cada premio va a la deuda hasta cubrirla. Se aplica antes de descontar el fiado.
4. **Trampa propia no detectada (×1,5):** cuenta si usaste al menos una trampa (Espejo o Cartas marcadas) en el partido y no te pescaron en ninguna.
5. **Retiro:** después de ganar un partido con $10.000.000 o más, la run ofrece `retire()`. Retirarse borra la deuda guardada y termina la run (final bueno). Seguir jugando está permitido.
6. **La tienda ofrece** amuletos no equipados, sin repetir dentro de las 3 ofertas, con probabilidad por rareza común 0,6, rara 0,3 y legendaria 0,1 **(ajustable)**.

## Foco de revisión

1. **Comprar fiado justo en el límite y después no poder pagar la entrada:** la run termina en muerte y el fiado pendiente pasa a la deuda. Test en la Tarea 4.
2. **Premio que no alcanza a cubrir el cobro del acreedor más el fiado:** nada queda negativo. Test en la Tarea 4.
3. **Llegar a $10M exactos:** el retiro se habilita. Test en la Tarea 6.
4. **Archivo de MetaState ausente o corrupto:** la run arranca limpia, sin deuda ni legado. Test en la Tarea 5.
5. **Morir sin amuletos:** el legado queda vacío y no falla. Test en la Tarea 6.

---

## Estructura de archivos

```
data/economy.json
core/run/economy.gd          Economy: entradas, premios, precios, constantes de §7
core/run/prize.gd            Prize: premio final con multiplicadores
core/run/shop.gd             Shop: ofertas, compra con fiado, cambio de ofertas, venta
core/run/run_state.gd        RunState: plata, fiado, deuda, ronda, amuletos
core/run/meta_state.gd       MetaState: deuda y legado entre runs (JSON)
core/run/run_controller.gd   RunController: orquesta la run para las pantallas
core/cheats/cheat_table.gd   (modificar) cuenta trampas propias no detectadas
tests/run/test_*.gd
tests/sim/test_economy_sim.gd
tests/sim/test_full_run_sim.gd
```

---

### Tarea 1: Datos de economía — ejecuta Codex

**Archivos:**
- Crear: `data/economy.json`, `core/run/economy.gd`
- Test: `tests/run/test_economy.gd`

`data/economy.json` (valores de DISENO §7):

```json
{
  "start_money": 135,
  "base_entry": 100,
  "entry_multiplier": 3,
  "prize_factors": [6, 5.5, 5, 5, 4.5, 4, 4, 4, 3.5, 3.5, 3.5, 3.5],
  "boss_rounds": [4, 8, 12],
  "points_normal": 15,
  "points_boss": 30,
  "goal": 10000000,
  "shop_offers": 3,
  "reroll_base": 0.10,
  "reroll_step": 0.05,
  "sell_ratio": 0.5,
  "rarity_price": {"COMMON": 0.3, "RARE": 0.6, "LEGENDARY": 1.2},
  "rarity_weight": {"COMMON": 0.6, "RARE": 0.3, "LEGENDARY": 0.1},
  "fiado_limit": 2.0,
  "creditor_cut": 0.5,
  "flawless_multiplier": 2.0,
  "undetected_cheat_multiplier": 1.5
}
```

**Interfaces:**
- Produce: `class_name Economy extends RefCounted`:
  - `static func load_from(path: String = "res://data/economy.json") -> Economy`
  - Un campo tipado por cada clave del JSON (mismos nombres).
  - `func entry(round: int) -> int` = `base_entry * entry_multiplier ^ (round - 1)`
  - `func base_prize(round: int) -> int` = `floori(entry(round) * prize_factors[min(round, size) - 1])` (después de la ronda 12 repite el último factor)
  - `func is_boss(round: int) -> bool`
  - `func target_points(round: int) -> int`
  - `func price(rarity: AmuletDef.Rarity, round: int) -> int` = `floori(entry(round + 1) * rarity_price[...])`
  - `func reroll_cost(round: int, rerolls_done: int) -> int` = `floori(entry(round + 1) * (reroll_base + reroll_step * rerolls_done))`
  - `func sell_value(paid: int) -> int` = `floori(paid * sell_ratio)`

- [ ] **Paso 1: tests**
  - `test_escalera_de_entradas`: ronda 1 → 100, ronda 4 → 2.700, ronda 12 → 17.714.700.
  - `test_premios_base`: ronda 1 → 600, ronda 2 → 1.650, ronda 9 → 2.296.350 (tabla de DISENO §7.1).
  - `test_jefes_y_puntos`: rondas 4, 8 y 12 son jefes a 30; la 5 es a 15.
  - `test_precio_y_cambio`: en la ronda 1, un raro cuesta `floori(300 * 0.6)` = 180; el primer cambio cuesta 30 y el segundo 45.
  - `test_ronda_13_repite_factor`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(run): datos de economía`.

---

### Tarea 2: Premio y trampas no detectadas — ejecuta Claude

**Archivos:**
- Crear: `core/run/prize.gd`
- Modificar: `core/cheats/cheat_table.gd`
- Test: `tests/run/test_prize.gd`

**Interfaces:**
- Produce, en `CheatTable`: `var player_cheats_used := 0` y `var player_cheats_caught := 0`, que se reinician en `start_match` y se cuentan en `use_player_cheat`.
- Produce: `class_name Prize extends RefCounted`:
  - `static func compute(base: int, dealer_score: int, cheats_used: int, cheats_caught: int, player_called_envido: bool, loadout: Loadout, deck: RunDeck, economy: Economy) -> Dictionary` → `{"total": int, "multipliers": Array[Dictionary]}`, donde cada multiplicador es `{"source": StringName, "value": float}` (para que la pantalla muestre de dónde salió cada parte). Fuentes: `&"flawless"` (dealer_score == 0), `&"undetected_cheat"` (cheats_used > 0 y cheats_caught == 0), `&"train_coin"` (`loadout.prize_multiplier`), `&"deck"` (`deck.prize_multiplier` si es distinto de 1).

- [ ] **Paso 1: tests**
  - `test_sin_multiplicadores`: total == base y lista vacía.
  - `test_partido_perfecto_duplica`.
  - `test_trampa_no_detectada`, `test_trampa_pescada_no_cuenta`.
  - `test_se_multiplican_entre_si`: perfecto + moneda + viuda sobre 600 → `floori(600 * 2 * 1.5 * 2)` = 3.600.
  - `test_mesa_cuenta_trampas_del_jugador` (con `CheatTable` real).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(run): premio con multiplicadores`.

---

### Tarea 3: Tienda — ejecuta Claude

**Archivos:**
- Crear: `core/run/shop.gd`
- Test: `tests/run/test_shop.gd`

**Interfaces:**
- Consume: `Economy`, `AmuletDef`, `Loadout`, `RunState` (Tarea 4: plata, fiado y ronda).
- Produce: `class_name Shop extends RefCounted`:
  - `func _init(p_economy: Economy, p_defs: Dictionary, p_rng: RandomNumberGenerator)`
  - `var offers: Array[AmuletDef]`; `var rerolls := 0`
  - `func open(state: RunState) -> void` (genera ofertas nuevas y pone `rerolls = 0`)
  - `func price_of(def: AmuletDef, state: RunState) -> int` (`economy.price` × `state.loadout.shop_price_multiplier()`, redondeado hacia abajo)
  - `func buy(index: int, state: RunState) -> Dictionary` → `{"ok": bool, "reason": StringName, "paid": int, "fiado": int}`. Razones: `&"no_slot"`, `&"no_credit"`, `&"bad_index"`.
  - `func reroll(state: RunState) -> bool` (paga con plata, sin fiado; `false` si no alcanza)
  - `func sell(id: StringName, state: RunState) -> int` (devuelve lo que cobraste; 0 si no estaba)
- `RunState` guarda lo que pagó por cada amuleto (`paid_for[id]`) para la venta.

- [ ] **Paso 1: tests**
  - `test_tres_ofertas_sin_repetir_ni_equipados`.
  - `test_comprar_con_plata`.
  - `test_comprar_fiado_dentro_del_limite`: con $100 y un precio de $250, pagás 100 y quedan 150 de fiado (límite 200).
  - `test_fiado_fuera_del_limite_falla_sin_cambiar_nada`.
  - `test_sin_espacio_falla`.
  - `test_cinta_roja_descuenta`.
  - `test_cambio_de_ofertas_cuesta_cada_vez_mas`.
  - `test_vender_devuelve_la_mitad_de_lo_pagado`.
  - `test_rarezas_respetan_los_pesos` (5.000 ofertas: proporciones a ±0,03).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(run): tienda con fiado`.

---

### Tarea 4: Estado de la run — ejecuta Claude

**Archivos:**
- Crear: `core/run/run_state.gd`
- Test: `tests/run/test_run_state.gd`

**Interfaces:**
- Produce: `class_name RunState extends RefCounted`:
  - `var money: int`; `var fiado: int`; `var debt: int`; `var round := 1`; `var loadout := Loadout.new()`; `var paid_for: Dictionary`; `var deck: RunDeck`; `var alive := true`; `var retired := false`
  - `func can_pay_entry(economy: Economy) -> bool`
  - `func pay_entry(economy: Economy) -> bool`
  - `func collect_prize(total: int, economy: Economy) -> Dictionary` → `{"creditor": int, "fiado": int, "kept": int}`: primero el acreedor se lleva `floori(total * creditor_cut)` hasta cubrir la deuda; después se descuenta el fiado de lo que queda; el resto suma a `money`. Nunca deja valores negativos.
  - `func credit_available(economy: Economy) -> int` = `max(0, floori(money * fiado_limit) - fiado)`
  - `func die() -> void` (`alive = false`; `debt += fiado`; `fiado = 0`)

- [ ] **Paso 1: tests**
  - `test_pagar_entrada`, `test_no_alcanza_la_entrada`.
  - `test_cobrar_premio_paga_acreedor_y_fiado`: deuda 300, fiado 100, premio 600 → acreedor 300, fiado 100, quedan 200.
  - `test_premio_que_no_alcanza_no_deja_negativos` (Foco 2).
  - `test_morir_pasa_el_fiado_a_la_deuda`.
  - `test_fiado_al_limite_y_sin_entrada_es_muerte` (Foco 1).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(run): estado de la run`.

---

### Tarea 5: MetaState — ejecuta Codex

**Archivos:**
- Crear: `core/run/meta_state.gd`
- Test: `tests/run/test_meta_state.gd`

**Interfaces:**
- Produce: `class_name MetaState extends RefCounted`:
  - `const DEFAULT_PATH := "user://meta.json"`
  - `var debt := 0`; `var legacy: StringName = &""`; `var runs_played := 0`; `var best_round := 0`
  - `static func load_from(path: String = DEFAULT_PATH) -> MetaState` (archivo ausente o JSON inválido → `MetaState` nuevo, sin fallar)
  - `func save_to(path: String = DEFAULT_PATH) -> bool`

- [ ] **Paso 1: tests** (con rutas en `user://test_meta_*.json` que el test borra al terminar)
  - `test_guardar_y_cargar`.
  - `test_archivo_ausente_arranca_limpio`.
  - `test_archivo_corrupto_arranca_limpio` (Foco 4).
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan (Claude corre).
- [ ] **Paso 5:** commit `feat(run): estado entre runs`.

---

### Tarea 6: RunController — ejecuta Claude

**Archivos:**
- Crear: `core/run/run_controller.gd`
- Test: `tests/run/test_run_controller.gd`

**Interfaces:**
- Consume: todo lo anterior y los Planes 1 a 4.
- Produce: `class_name RunController extends RefCounted`:
  - `enum Phase { BAR, MATCH, SHOP, DEAD, RETIRED }`
  - `func _init(p_economy: Economy, p_meta: MetaState, p_seed: int)`
  - `var phase: Phase`; `var state: RunState`; `var shop: Shop`; `var systems: AmuletSystem` (el del partido en curso)
  - `func start_run(deck_id: StringName) -> Array[GameEvent]`: plata inicial, deuda de `meta`, legado equipado (y se borra de `meta`), fase `BAR`. Emite `run_started`.
  - `func rival_for(round: int) -> RivalProfile`
  - `func enter_match() -> Array[GameEvent]`: si no alcanza la entrada → `die`. Si alcanza: paga, arma `CheatTable` + `AmuletSystem` con el rival, el objetivo de puntos y las reglas del mazo, fase `MATCH`. Emite `entry_paid`.
  - `func finish_match() -> Array[GameEvent]`: llamar cuando `truco_match.winner() != -1`. Si ganó el jugador: calcula el `Prize`, cobra, fase `SHOP`, abre la tienda y emite `prize_paid {total, multipliers, creditor, fiado, kept}`. Si perdió: `die`.
  - `func can_retire() -> bool` (fase `SHOP` y `money >= goal`)
  - `func retire() -> Array[GameEvent]`: fase `RETIRED`, `meta.debt = 0`, guarda. Emite `run_retired`.
  - `func next_round() -> Array[GameEvent]`: desde `SHOP`, ronda +1, fase `BAR`.
  - `func die(legacy_id: StringName = &"") -> Array[GameEvent]`: `state.die()`, guarda deuda, legado (vacío si no se eligió o no estaba equipado), `runs_played` y `best_round`. Fase `DEAD`. Emite `run_died`.
  - `func legacy_choices() -> Array[StringName]` (los amuletos equipados al morir)

- [ ] **Paso 1: tests**
  - `test_run_arranca_con_135_y_deuda_guardada`.
  - `test_legado_se_equipa_y_se_consume`.
  - `test_rival_por_ronda` (ronda 1 agresivo, 2 mentiroso, 3 tramposo, 4 agresivo jefe a 30 con rasgos escalados).
  - `test_ganar_cobra_y_abre_la_tienda` (terminar el partido a mano con `truco_match.award`).
  - `test_perder_es_muerte`.
  - `test_sin_entrada_es_muerte`.
  - `test_retiro_con_10_millones_exactos` (Foco 3).
  - `test_morir_sin_amuletos` (Foco 5).
  - `test_viuda_duplica_premio_y_presupuesto`.
- [ ] **Paso 2:** fallan. **Paso 3:** implementar. **Paso 4:** pasan.
- [ ] **Paso 5:** commit `feat(run): controlador de la run`.

---

### Tarea 7: Simulación de economía — ejecuta Claude

**Archivos:**
- Test: `tests/sim/test_economy_sim.gd`

Simula runs sin jugar Truco: cada partido se gana con probabilidad `p`; si se gana, el partido es perfecto con probabilidad 0,15 y hay trampa no detectada con probabilidad 0,2. La política de compra sale de una lista fija (por ejemplo: "no compra", "compra un común por ronda si le alcanza sin fiado", "compra lo que puede con fiado"). Los amuletos solo afectan la economía por la Cinta roja y la Moneda; su efecto sobre `p` se modela como +0,03 por amuleto equipado (ajustable en el test).

- [ ] **Paso 1: tests que imprimen una tabla y verifican el diseño**
  - Tabla por política y por `p` (0,5; 0,7; 0,85): porcentaje de runs que llegan a $10M, ronda promedio de muerte, plata mediana por ronda.
  - `test_escalera_sola_no_alcanza`: con `p = 0,7` y la política "no compra", menos del 10% de las runs llega a $10M (DISENO §7.1: la escalera sola no alcanza de forma confiable).
  - `test_comprar_ayuda`: con `p = 0,7`, la mejor política de compra llega a $10M más seguido que "no compra".
  - `test_ronda_del_retiro`: imprime en qué ronda se llega a $10M; si casi nunca hace falta la ronda 12, Claude lo reporta para decidir con Joako (pendiente del ROADMAP).
- [ ] **Paso 2:** correr. Si los números no cumplen el diseño, Claude propone cambios en `data/economy.json` con la tabla como evidencia y **los consulta con Joako antes de aplicarlos**.
- [ ] **Paso 3:** commit `test(run): simulación de economía`.

---

### Tarea 8: Run completa con Truco — ejecuta Claude

**Archivos:**
- Test: `tests/sim/test_full_run_sim.gd`

- [ ] **Paso 1: test** `test_runs_completas_no_se_traban`: 50 runs con el jugador de reglas simples del Plan 4 (copiado a un helper compartido) y una política de compra fija, por `RunController`, hasta morir o retirarse. Verifica: la fase siempre es válida, la plata nunca es negativa, el `MetaState` queda guardado al final, ninguna run supera 2.000 acciones.
- [ ] **Paso 2:** correr. **Paso 3:** commit `test(run): runs completas`.

---

## Al terminar el Plan 5

- Todos los tests pasan.
- Revisión independiente contra `docs/DISENO.md` §6, §7 y §10, con el Foco de revisión de arriba.
- Claude presenta a Joako la tabla de la simulación de economía y las propuestas de ajuste.
- Se escribe el Plan 6 (pantallas 2D), que solo habla con `RunController`.
