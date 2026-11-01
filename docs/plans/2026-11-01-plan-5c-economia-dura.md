# Plan 5c — Economía más dura y mejoras de amuletos

> **Para quien ejecute (Claude, Codex u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). La spec es `docs/DISENO.md` versión 2.1: §5.4.1 (los pecados se conocen), §6 (una mano más), §7.3 a §7.4 (tienda, propina, fiado) y §8.1 (mejoras). Si algo de este plan contradice la spec, pará y avisá. **Codex no puede correr Godot en su sandbox:** escribe el código y los tests, y Claude corre `run_tests.ps1`.

**Objetivo:** que la plata deje de sobrar. Entran:
- la propina del bar;
- el interés y la retención del fiado;
- el chisme entre pecados y la plata que atrae trampas;
- las mejoras de amuletos (niveles I a III);
- "una mano más" después de cada victoria.

Al final, la simulación vuelve a medir la economía y Joako decide los números.

**Arquitectura:** se sigue en la rama `plan-5-run`. La revisión independiente y la unión a `main` (Tarea 7 del Plan 5b) se hacen al final de este plan, una sola vez para 5b y 5c.
- Todos los números nuevos van a `data/economy.json`.
- Los valores por nivel de cada amuleto van a `data/amulets.json`.
- `RunController` sigue siendo el único punto de entrada para la UI.

## Restricciones globales

- Las mismas de los planes anteriores: nada en `core/` extiende `Node`; sin azar global; tipos explícitos; plata en enteros; un commit por tarea.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1`.

## Decisiones de interpretación

1. **Propina:** `floori(max(0, plata − 3 × entrada) × 0,10)`. Se calcula con la plata **antes** de pagar la entrada y se cobra junto con ella. Nunca impide entrar: si tenés menos de 3 entradas, no hay propina.
2. **Interés del fiado:** en `next_round()`, `fiado = ceili(fiado × 1,10)`. Se redondea para arriba, así una deuda chica igual crece.
3. **Retención:** en las rondas 1 a 8, al cobrar, `retenido = min(fiado, floori(premio × 0,25))`. Se resta del fiado y el resto va a la plata. En la final no hay retención.
4. **Chisme:** si en el partido anterior `player_cheats_caught > 0`, el rival siguiente arranca con `mood.suspicion += 0,3`. Solo vale para el partido inmediato siguiente.
5. **Plata que atrae pecados:** solo contra pecados (no almas ni Gualicho). Al armar la mesa, presupuesto de trampas `+= min(2, plata_al_entrar / (5 × entrada))`, con división entera y calculado después de pagar la entrada y la propina. Se aplica después del multiplicador del mazo.
6. **Mejoras:**
   - Una por tienda. El precio usa la base de la rareza **sin** el +25% por compra: `floori(base × factor × cinta)`, con factor 1,5 para pasar a II y 2,5 para pasar a III.
   - Se paga con plata o fiado, con las mismas reglas que comprar, y `paid_for[id]` acumula lo pagado.
   - El legado vuelve a nivel I.
7. **Una mano más:** fase nueva `ONE_MORE`, entre cobrar y la tienda, en las rondas 1 a 8.
   - `one_more(fraction)` con `fraction ∈ {0,25; 0,5; 1,0}`. Arriesga `floori(premio_neto × fraction)`, donde el premio neto es lo que entró a la plata después de la retención.
   - Juega una mano contra el mismo rival, con una mesa nueva y su humor de cero. `finish_one_more()` resuelve igual que la mano del Gualicho: gana quien sumó más puntos en esa mano y el empate es del rival.
   - Si ganás, cobrás lo arriesgado otra vez, o sea lo recuperás por dos. Si perdés, lo perdés.
   - `skip_one_more()` pasa a la tienda.
   - No se puede morir en esa mano.

## Foco de revisión

1. La propina con plata justo en 3 entradas es 0, y con una entrada más es 10% de esa entrada.
2. El interés con fiado 0 no hace nada, y con fiado 1 lo deja en 2.
3. La retención nunca se lleva más que el fiado.
4. El chisme dura un solo partido.
5. Mejorar dos veces en la misma tienda falla sin cambiar nada.
6. "Una mano más" con premio neto 0 se salta sola.

---

### Tarea 1: Datos y niveles de amuletos — ejecuta Codex

**Archivos:** `data/economy.json`, `data/amulets.json`, `core/run/economy.gd`, `core/amulets/amulet_def.gd`, `core/amulets/loadout.gd`. Tests: `tests/run/test_economy.gd`, `tests/amulets/test_amulet_def.gd`, `tests/amulets/test_loadout.gd`.

- Claves nuevas en `economy.json`:
  - `"tip_rate": 0.10`, `"tip_free_entries": 3`
  - `"fiado_interest": 0.10`, `"fiado_retention": 0.25`
  - `"upgrade_cost": [1.5, 2.5]`
  - `"gossip_suspicion": 0.3`
  - `"greed_entries_per_cheat": 5`, `"greed_max_extra": 2`
  - `"one_more_fractions": [0.25, 0.5, 1.0]`
- `amulets.json`: cada amuleto suma `"levels": [{…nivel I…}, {…II…}, {…III…}]` con los campos que cambian según §8.1. Ejemplos: `"charges"`, `"show_chance"`, `"price_multiplier"`, `"prize_multiplier"`, `"risk_multiplier"`, `"reveal_count"`, `"reveal_suit"`, `"change_suit"`, `"choose_from"`, `"raise_too"`, `"no_suspicion"`, `"risk_step_multiplier"`.
- `AmuletDef.value(key, level)` devuelve el valor del nivel, o el del nivel I si falta.
- `Loadout`:
  - `level(id) -> int` (1 por defecto) y `upgrade(id) -> bool` (tope 3).
  - `charges_left` respeta las cargas del nivel.
  - `shop_price_multiplier()` y `prize_multiplier()` leen el nivel.
- Tests: valores por nivel, `upgrade` hasta 3 y después falla, y las cargas por nivel.

### Tarea 2: Propina, interés y retención — ejecuta Claude

**Archivos:** `core/run/economy.gd` (`tip(money, round)`), `core/run/run_state.gd` (`pay_entry` cobra la propina y devuelve lo cobrado; `apply_interest(economy)`; `collect_prize(total, economy, is_final)` devuelve `{retained, kept}`), `core/run/run_controller.gd` (eventos `entry_paid` con `tip`, `prize_paid` con `retained`; `next_round` aplica el interés y emite `fiado_interest {before, after}` si cambió). Tests: Focos 1 a 3, y actualizar `test_run_state` y `test_run_controller`.

### Tarea 3: Los pecados se conocen — ejecuta Claude

**Archivos:** `core/run/run_controller.gd`. Tests en `tests/run/test_run_controller.gd`: el chisme sube la sospecha del rival siguiente y no la del de dos rondas después (Foco 4); la plata atrae trampas con el tope de +2; un alma no recibe trampas extra.

### Tarea 4: Mejoras en la tienda y efectos por nivel — ejecuta Claude (Codex puede adelantar los efectos simples)

**Archivos:**
- `core/run/shop.gd`: `upgrade_price(id, state)`, `upgrade(id, state) -> Dictionary` con los motivos `&"max_level"`, `&"already_upgraded"`, `&"no_credit"` y `&"not_equipped"`. Lleva un registro de mejoras por apertura de tienda.
- `core/run/run_controller.gd`: el envoltorio `upgrade(id)`; el legado vuelve a nivel I.
- `core/amulets/amulet_system.gd` y `core/cheats/cheat_table.gd`: los efectos de nivel II y III de §8.1.
  - Simples, por datos: cargas, Cigarrillo, Cinta roja, Moneda, riesgo del Espejo.
  - Especiales: el Marcador cambia el palo; el Mazo aparte elige entre 2 (`use(&"spare_deck", {"card_index", "choice"})` con `preview_spare()`); el Facón también obliga a querer la subida; los Lentes muestran 2 cartas o el palo; el Sombrero muestra el palo de la más alta; el Vaso de caña no sube la sospecha; las Cartas marcadas hacen crecer el riesgo más lento.

Tests: Foco 5, un test por cada efecto especial y la venta de un amuleto mejorado.

### Tarea 5: Una mano más — ejecuta Claude

**Archivos:** `core/run/run_controller.gd` (fase `ONE_MORE`, `one_more(fraction)`, `finish_one_more()`, `skip_one_more()`; eventos `one_more_offered {stake_options}`, `one_more_won {amount}`, `one_more_lost {amount}`), `tests/run/test_one_more.gd`. Tests: ganar recupera ×2; perder no mata; el empate es del rival; con premio neto 0 se saltea (Foco 6); una fracción inválida es ilegal; no aparece en la final.

### Tarea 6: Simulación y calibración — ejecuta Claude

- `tests/sim/test_economy_sim.gd`:
  - Suma la propina, el interés, la retención y una política de mejoras: mejora si después le sigue alcanzando para la entrada siguiente.
  - Suma "una mano más" con dos políticas: nunca, o 50% cuando la plata pasa de 3 entradas. La mano se gana con 0,5.
  - Imprime la misma tabla que antes y suma la plata mediana y el fiado mediano por ronda.
- `tests/sim/test_full_run_sim.gd`: el jugador IA mejora y salta "una mano más". Ninguna run se traba.
- Claude presenta la tabla a Joako y propone números **antes de fijarlos**. El objetivo es que llegar a la ronda 8 con más de ~10 entradas de plata sea raro, y que el fiado sea una apuesta que a veces sale mal.

### Tarea 7: Revisión y unión — ejecuta Claude

- Correr toda la suite.
- Revisión independiente de toda la rama `plan-5-run` (Planes 5, 5b y 5c) contra `docs/DISENO.md` v2.1.
- Unir a `main` con el OK de Joako.
