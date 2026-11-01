# Plan 6 — Pantallas 2D (MVP jugable)

> **Para quien ejecute (Codex, Claude u otra IA):** implementá tarea por tarea, en orden. Los pasos usan casillas (`- [ ]`). La spec es `docs/DISENO.md` v2.1 (§6 estructura, §7 economía, §8 amuletos, §12 alcance del MVP). **Codex no puede correr Godot en su sandbox:** escribe escenas, scripts y tests, y Claude corre `run_tests.ps1` y abre el juego. Si algo de este plan contradice la spec, pará y avisá.

**Objetivo:** que Joako juegue runs completas en 2D: bar, partido, una mano más, tienda, la cuenta, finales y muerte. Es la primera entrega que se juega de verdad. Sirve para calibrar lo que la simulación no puede medir: la ventaja humana, lo que suman los amuletos y la curva en V.

**Arquitectura:**
- Todo lo visual vive en `ui/`. `core/` **no cambia**; si una pantalla necesita algo que el núcleo no da, se agrega un getter de solo lectura en `core/` con su test, y nada más.
- Un solo punto de entrada: `RunController`. La mesa usa `rc.table()` (CheatTable) y `rc.systems` (AmuletSystem). Las pantallas **nunca** cambian estado del núcleo por su cuenta: llaman a esos métodos y redibujan a partir de los eventos (`Array[GameEvent]`) y del estado público.
- Una escena principal `ui/main.tscn` con un `ScreenRouter` que muestra la pantalla según `rc.phase`.
- Estética de prueba: texto y rectángulos, sin arte. Fondo oscuro, fuente legible, cartas como botones con número y palo. La estética PS1 es de la Etapa 3.
- Resolución base 1280×720, que escala.

## Restricciones globales

- GDScript con tipos explícitos, como en `core/`.
- Nada de lógica de juego en `ui/`: ni reglas, ni precios, ni azar. Si una pantalla calcula algo que el núcleo ya sabe, es un error.
- Los textos visibles en español van en `data/i18n/ui.csv` (claves `UI_*`). Ya existe `data/i18n/tells.csv` para las pistas.
- Cada pantalla tiene un test de humo en `tests/ui/`: se instancia sin errores, recibe un `RunController` real con semilla fija y sus botones llaman al método correcto.
- Comando de tests: `powershell -NoProfile -File .\run_tests.ps1`.
- Un commit por tarea.

## Decisiones de interpretación

1. **El dealer juega solo** con un `Timer`, 0,6 s por acción (ajustable en `data/ui.json`), para que se vea lo que hace. Mientras es su turno, los botones del jugador quedan apagados.
2. **Acciones del jugador:** los botones salen de `hand.legal_actions()` filtrado por el jugador 0. Nunca se arma una acción a mano, salvo jugar una carta (`PLAY_CARD` con su índice) y declarar el tanto (selector con los valores legales).
3. **La versión del rival no se anuncia** (DISENO §5.5): se muestra el pecado ("La Ira") y nunca la variante.
4. **Pistas:** se muestra `brain.last_tell` (texto de `tells.csv` más un ícono como emoji o etiqueta: tranquilo, nervioso, agrandado, enojado) apenas aparece.
5. **Acusar:** botón "Acusar" visible mientras `table.can_accuse()`. Abre un panel con las tres opciones de `Accusation.Target`. Si la opción pide carta (`HISTORY_CARD`), elegís una de las cartas jugadas.
6. **Amuletos activos:** botones con cargas restantes, prendidos según `systems.can_use(id)`. Los que piden argumentos abren un selector:
   - Marcador: carta y número; en nivel III, también palo.
   - Mazo aparte: carta; en nivel III muestra las 2 opciones de `preview_spare()`.
   - La información que dan (Lentes, Sombrero, Espejo, Cartas marcadas) aparece en un recuadro "Lo que sabés" que dura hasta que termina la mano.
7. **Guardado:** `MetaState` ya se guarda solo. Al abrir el juego, si `meta.run_in_progress`, se avisa que la run anterior se perdió y su fiado pasó a deuda.

## Foco de revisión

1. Ningún botón llama a algo ilegal: el test de cada pantalla prueba que con la fase equivocada el botón está apagado.
2. La mesa no deja ver cartas del dealer, salvo las que revela un amuleto o la trampa del cómplice.
3. Mientras juega el dealer, el jugador no puede actuar.
4. Una run completa se puede jugar de punta a punta con el teclado o el mouse. Claude la juega una vez con semilla fija antes de entregarla.

---

### Tarea 1: Esqueleto y enrutador — ejecuta Codex

**Archivos:** `project.godot` (escena principal y tamaño de ventana), `ui/main.tscn`, `ui/main.gd`, `ui/screen_router.gd`, `ui/theme.tres`, `data/ui.json`, `data/i18n/ui.csv`, `tests/ui/test_main.gd`.

- [ ] `main.gd` crea `MetaState` (`MetaState.load_from()`), `Economy.load_from()` y un `RunController` con una semilla del reloj. Expone `rc` a las pantallas.
- [ ] `ScreenRouter` tiene una pantalla por fase y la cambia después de cada llamada al controlador (método `refresh()`):

| fase | pantalla |
|---|---|
| sin run | inicio |
| `BAR` | bar |
| `MATCH`, `ONE_MORE` con apuesta, `BILL_HAND` | mesa |
| `ONE_MORE` sin apuesta | una mano más |
| `SHOP` | tienda |
| `FREE` | libre |
| `DEAD` | muerte |
| `RETIRED`, `CONDEMNED` | final |

- [ ] Por ahora cada pantalla es un cartel con su nombre y un botón para avanzar, para probar el recorrido.
- [ ] Test: el enrutador muestra la pantalla correcta para cada fase.

### Tarea 2: Inicio, bar y muerte — ejecuta Codex

**Archivos:** `ui/screens/start_screen.*`, `bar_screen.*`, `death_screen.*`, más sus tests.

- [ ] **Inicio:**
  - muestra la deuda guardada, el legado y las runs jugadas;
  - deja elegir el mazo (Normal o Viuda, con su beneficio y su costo);
  - botón "Entrar al bar" → `rc.start_run(deck)`.
- [ ] **Bar:**
  - muestra la ronda, el pecado o "un alma en pena", la entrada, la propina que se cobraría (`economy.tip`), la plata, el fiado y la deuda;
  - botón "Sentarse" → `rc.enter_match()`.
  - Si no alcanza la entrada, el botón dice "No te alcanza" y lleva a la muerte (`enter_match` ya muere solo).
- [ ] **Muerte:**
  - muestra la ronda y la deuda que pasa a la run siguiente;
  - lista `legacy_choices()` para elegir legado → `choose_legacy`;
  - botón "Otra vez".

### Tarea 3: La mesa — ejecuta Claude (es la pantalla más delicada)

**Archivos:** `ui/screens/table_screen.*`, `ui/widgets/card_button.*`, `ui/widgets/action_bar.*`, `ui/widgets/amulet_bar.*`, `ui/widgets/event_log.*`, `tests/ui/test_table_screen.gd`.

- [ ] **Qué muestra:**
  - tus cartas como botones y las del dealer boca abajo;
  - las bazas jugadas;
  - el marcador y el objetivo del partido;
  - el canto en juego;
  - el registro de eventos en palabras ("La Ira cantó truco", "Quisiste", "Te pescaron");
  - la pista del dealer y el recuadro "Lo que sabés";
  - la evidencia visible de trampas (`table.evidence()`).
- [ ] **Turnos:**
  - Al empezar cada mano llama a `rc.systems.start_hand()`, salvo en la mano única de la cuenta o de "una mano más", que el controlador ya repartió.
  - Turno del jugador: `table.player_action(a)`.
  - Turno del dealer: `table.dealer_step()` con el temporizador.
  - Al terminar la mano muestra el resultado.
  - Cuando el partido termina, llama a `rc.finish_match()`; en la cuenta, a `rc.finish_bill_hand()`; en "una mano más", a `rc.finish_one_more()`.
- [ ] Acusar y amuletos, según las decisiones 5 y 6.
- [ ] **Tests:**
  - con una semilla fija, un jugador automático juega un partido entero a través de la pantalla (apretando botones, no llamando al núcleo) y el partido termina;
  - los botones están apagados en el turno del dealer;
  - las cartas del dealer no se ven.

### Tarea 4: Después de ganar y tienda — ejecuta Codex

**Archivos:** `ui/screens/one_more_screen.*`, `shop_screen.*`, más sus tests.

- [ ] **Una mano más:**
  - muestra el premio con cada multiplicador y lo retenido por el fiado;
  - ofrece las 3 opciones de `one_more_options()` y "Seguir sin arriesgar".
- [ ] **Tienda:**
  - 3 ofertas con nombre, rareza, efecto (texto de `ui.csv`) y precio;
  - aviso "parte fiado" si `buy` usaría fiado: se calcula con lo mismo que usa la tienda (agregar en `core/run/shop.gd` un getter de solo lectura `quote(price, state) -> {paid, fiado, ok}`, con su test);
  - tus 2 amuletos con su nivel, el botón "Mejorar" (`upgrade_price`) y "Vender";
  - "Cambiar ofertas" con su costo;
  - "Seguir" → `rc.next_round()`, mostrando el interés del fiado si lo hubo.
- [ ] Tienda especial: un cartel lo avisa.

### Tarea 5: La cuenta, libre y finales — ejecuta Codex

**Archivos:** `ui/screens/bill_screen.*`, `free_screen.*`, `ending_screen.*`, más sus tests.

- [ ] **La cuenta:**
  - cobro de los $10M, la cuenta desglosada (10M + fiado + deuda), los amuletos vendidos;
  - si falta plata, el anuncio de la mano contra el Gualicho (después, la mesa).
- [ ] **Libre:** lo que te sobró, y la elección entre "Tomarte el colectivo" (`retire`) y "Pedir otra vuelta" (`condemn`).
- [ ] **Finales:** un texto corto para cada uno (bueno y avaricia, DISENO §1 y §11) y el botón "Volver al inicio".

### Tarea 6: Prueba de punta a punta — ejecuta Claude

- [ ] Claude juega una run completa con semilla fija y anota cualquier traba.
- [ ] Toda la suite en verde.
- [ ] Joako juega varias runs y anota:
  - qué rival se sintió fácil o difícil;
  - si la plata alcanzó o sobró;
  - qué amuleto usó y si valió lo que costó;
  - qué no se entendió.
- [ ] Con esas notas, Claude propone ajustes de `data/` (economía, rivales, amuletos), sin tocar código, y los aplica con el OK de Joako.
