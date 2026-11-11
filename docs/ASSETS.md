# Payé: lista completa de modelos, texturas y sonidos

Esta es la lista de **todo** lo que el juego puede cargar, con medidas, límites y prioridad. Sirve para Joako y para cualquier modelador que se sume: no hace falta saber Godot ni tocar código.

**Cómo funciona.** Cada archivo va en su carpeta con el **nombre exacto** de la tabla. Si el archivo está, el juego lo usa. Si no está, muestra un cubo del mismo tamaño en su lugar. El test `tests/world/test_assets_budget.gd` avisa si un modelo se pasa de triángulos, de textura o de medida. Los límites están en `world/asset_budget.json`.

**Estado hoy (2026-11-11):** cargados `table`, `chair_player`, `chair_rival`, `deck` y `lamp` (sin textura todavía). El resto se ve con cubos.

---

## 1. Estilo visual

### La idea

Figuras **low poly** con **texturas chicas pixeladas**, mostradas a **resolución completa** (HD):

- Los bordes de las figuras se ven limpios: sin dientes de sierra, sin vértices que tiemblan, sin filtro de TV vieja.
- El "pixelado" lo ponen solo las texturas, que se ven con los píxeles marcados (filtro *Nearest*, sin suavizar).
- La forma es simple y facetada: pocas caras, sin superficies redondeadas suaves.

Es el estilo de juegos como CloverPit. Los tamaños exactos de las texturas de CloverPit no son públicos; los de este documento son los de Payé. Están pensados para que se vea así.

> El juego también tiene un modo PS1 (resolución baja, vértices que tiemblan, colores reducidos). El juego arranca en HD (`"ps1": false` en `data/ui.json`); con `true` vuelve el modo PS1. Los modelos sirven igual para los dos modos.

### La regla de oro: el mismo tamaño de pixel en todo

Lo que hace que todo parezca del mismo juego es que **un pixel de textura se vea más o menos del mismo tamaño en pantalla en todos los objetos**. Esto vale a la distancia a la que se ven normalmente. Por eso los objetos que se miran de cerca llevan más píxeles por metro que los que quedan lejos:

| Distancia a la cámara | Ejemplos | Densidad | 1 pixel de textura ≈ |
|---|---|---|---|
| Muy cerca (en la mano, sobre la mesa, vista de cerca de la tienda) | cartas, amuletos, mazo, guardarropas | 800 a 1.000 px/m | 1 mm |
| Cerca (alrededor de la mesa) | mesa, sillas, rival, lámpara | 250 a 300 px/m | 4 mm |
| Lejos (el resto del bar) | habitación, barra, puerta, ventana, almas, cantinero | 64 a 128 px/m | 1 a 1,5 cm |

Ejemplos:
- **Amuleto** de 7 cm: textura de 64 px (64 / 0,07 ≈ 900 px/m).
- **Mesa** de 0,9 m: la tapa entra en 256 px (≈ 280 px/m).
- **Pared** de 8 m: no lleva una textura de 8 m. Lleva una de 128 px que se repite cada metro (128 px/m).

Las **cartas** son la excepción: 128 × 192 px para una carta de 6,3 cm. Se miran muy de cerca y tienen que leerse.

### Reglas de textura

| Regla | Valor |
|---|---|
| Tamaños | Potencias de 2: 32, 64, 128, 256. Rectangulares valen (64 × 128). Las cartas, 128 × 192. |
| Formato | PNG. |
| Qué llevan | Solo color (*albedo*). Sin mapas normales, de rugosidad ni de metal. |
| Cómo se pintan | A mano o reducidas sin suavizar (en GIMP o Photoshop, interpolación "Ninguna" o "Vecino más cercano"). Sombras y desgaste **pintados** en la textura, con pocos colores por zona. |
| Paleta | La del juego: madera `#5C3A22`, sombra `#2A1A12`, papel `#D8C9A3`, oro viejo `#D9A54A`, gris `#6B665E`, rojo mazo `#6E1A1A`, verde alma `#2C4232`, noche `#1B2738`. Se pueden sumar tonos, pero cerca de estos. |
| Repetición | Paredes, piso y madera grande: texturas que se repiten (*tileables*). |

### Reglas de modelo

| Regla | Valor |
|---|---|
| Formato | `.glb` (glTF binario). Blender, Meshy, Tripo y la mayoría de las IAs exportan así. |
| Escala | 1 unidad = 1 metro. Aplicar la escala antes de exportar (Blender: *Ctrl+A → All Transforms*). |
| Orientación | Y hacia arriba. El frente mira hacia −Z, hacia la cámara del jugador. |
| Origen (pivote) | Abajo y al centro: el objeto queda apoyado en Y = 0. |
| Sombreado | Plano (*flat shading*) o con bordes duros: que se noten las caras. |
| Materiales | Uno o dos por modelo. Si un modelo no trae material ni textura, el juego lo pinta del color de su cubo provisorio (madera, sombra, etc.) hasta que la tenga. |
| Luces y cámaras | No incluir: se ignoran. |
| Animaciones | Dentro del `.glb`, con los nombres exactos de la sección de personajes. En el lugar (el juego mueve al personaje). |

**Si se hace con IA:** suelen salir con 20.000 a 100.000 triángulos y texturas de 2.048 px.
1. En Blender, bajar los triángulos con el modificador *Decimate* hasta el límite de la tabla, o mejor retopologizar a mano.
2. Reducir la textura sin suavizar hasta el tamaño de la tabla.
3. Revisar el pivote y la escala.

---

## 2. Lista completa

Prioridad: **P1** = sin esto no se siente el juego · **P2** = los personajes · **P3** = el bar alrededor · **P4** = detalle · **Futuro** = el juego todavía no lo carga, pero conviene tenerlo previsto.

Medidas: ancho × alto × fondo, en metros. Es la caja en la que tiene que entrar; el test acepta hasta un 50 % de diferencia por eje.

### P1: la mesa y lo que se toca

Carpeta `assets/models/`, salvo las cartas.

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. |
|---|---|---|---|---|---|
| 1 | `table.glb` | Mesa de bar vieja, de madera, cuadrada. La tapa queda a 0,75 m | 0,9 × 0,75 × 0,9 | 800 | 256 |
| 2 | `deck.glb` | El mazo apoyado en la mesa (pila de cartas boca abajo) | 0,063 × 0,014 × 0,095 | 250 | 64 |
| 3 | `lamp.glb` | Lámpara colgante sobre la mesa, con cable o cadena hacia arriba. Origen abajo: la pantalla queda a 1,55 m del piso. El cable puede ser largo: lo que pasa el techo (1,45 m arriba del origen) no se ve | 0,4 × 2 × 0,4 | 600 | 128 |
| 4 | `chair_rival.glb` | Silla del rival | 0,6 × 0,9 × 0,6 | 600 | 128 |
| 5 | `chair_player.glb` | Tu silla: casi no se ve, alcanza con algo simple | 0,6 × 0,9 × 0,6 | 600 | 128 |

**Cartas:** van en `assets/cards/`. No son modelos: el juego las arma sobre un plano.

| # | Archivo | Qué es | Tamaño |
|---|---|---|---|
| 6 | `espada_1.png` … `espada_7.png`, `espada_10.png`, `espada_11.png`, `espada_12.png` | Las 10 cartas de espada | 128 × 192 px |
| 7 | `basto_*.png` | Las 10 de basto (mismos números) | 128 × 192 px |
| 8 | `oro_*.png` | Las 10 de oro | 128 × 192 px |
| 9 | `copa_*.png` | Las 10 de copa | 128 × 192 px |
| 10 | `back.png` | Dorso (uno solo para todo el mazo) | 128 × 192 px |

Son 41 imágenes. Tienen que leerse de un vistazo: número grande y palo claro. Se puede partir de un mazo español de dominio público escaneado y reducirlo, o dibujarlas en pixel art.

### P2: los personajes

**Rivales.** Cada rival es un **modelo de cuerpo entero propio**, con su rig y sus animaciones. No se arma con piezas: el juego carga un archivo por rival.

El juego busca primero el modelo de la **versión** (`rival_<pecado>_<versión>.glb`). Si no está, usa el del pecado (`rival_<pecado>.glb`), y si tampoco está, el del alma (`rival_alma.glb`). Conviene hacer primero los 8 modelos de pecado. Las versiones son opcionales y se pueden sumar de a una. Pueden ser el mismo cuerpo con otra ropa, otra cara u otro color, o un personaje distinto. Usan los mismos límites que su pecado.

Cómo se ubica:
- **Origen:** en el piso, debajo del centro del asiento de su silla.
- **Frente:** hacia −Z, mirándote.
- **Pose base:** sentado (asiento a unos 0,45 m), con los antebrazos sobre la mesa (tapa a 0,75 m, a unos 0,35 m adelante del origen).
- **Cartas:** el juego pone las cartas del rival en el aire frente a su pecho, a la altura de la mesa. Las manos tienen que quedar cerca, como si las agarrara.

| # | Archivo (base) | Rival | Idea | Versiones opcionales (archivo extra) | Triáng. | Textura |
|---|---|---|---|---|---|---|
| 11 | `rival_ira.glb` | La Ira | Rojo, venas, dientes apretados | `rival_ira_estallido`, `rival_ira_rencor`, `rival_ira_mecha_corta` | 5.000 | 512 |
| 12 | `rival_gula.glb` | La Gula | Hinchado, boca enorme | `rival_gula_gloton`, `rival_gula_atracon`, `rival_gula_insaciable` | 5.000 | 512 |
| 13 | `rival_pereza.glb` | La Pereza | Ojos caídos, medio dormido, desparramado en la silla | `rival_pereza_dormido`, `rival_pereza_fiaca_tramposa`, `rival_pereza_siesta` | 5.000 | 512 |
| 14 | `rival_envidia.glb` | La Envidia | Verdosa, mira de reojo | `rival_envidia_copiona`, `rival_envidia_mirona`, `rival_envidia_resentida` | 5.000 | 512 |
| 15 | `rival_lujuria.glb` | La Lujuria | Seductora y perturbadora | `rival_lujuria_seductora`, `rival_lujuria_mentirosa`, `rival_lujuria_encantadora` | 5.000 | 512 |
| 16 | `rival_soberbia.glb` | La Soberbia | Corona o sombrero alto, mira desde arriba | `rival_soberbia_invicto`, `rival_soberbia_desden`, `rival_soberbia_perfeccionista` | 5.000 | 512 |
| 17 | `rival_alma.glb` | Almas en pena (las primeras rondas) | Figura borrosa, sábana o máscara simple | `rival_alma_novato`, `rival_alma_miedoso`, `rival_alma_cantor`, `rival_alma_mudo` | 4.000 | 512 |
| 18 | `rival_gualicho.glb` | El Gualicho (jefe final) | El dueño del bar, el más inquietante | — (una sola versión) | 6.000 | 512 |

Medida de cada rival sentado: entra en unos **0,6 × 1,4 × 0,7 m** (el test acepta hasta un 50 % de diferencia por eje). En total: 8 rivales base y 22 versiones opcionales.

**Animaciones de los rivales.** Van dentro del `.glb`, con estos **nombres exactos** en minúsculas. Solo `idle` es obligatoria. Si falta otra, el juego sigue con `idle` y no se rompe. Las de fondo se repiten solas; las de una vez vuelven a la de fondo al terminar.

| Animación | Tipo | Cuándo la usa el juego | Duración sugerida |
|---|---|---|---|
| `idle` | de fondo | Sentado esperando, respirando, mirándote. **Obligatoria** | 2 a 4 s (en loop) |
| `think` | de fondo | Es su turno y está pensando qué tirar | 2 a 4 s (en loop) |
| `waiting` | de fondo | En el bar, antes de que te sientes: de pie al lado de su silla, en el lugar | 2 a 4 s (en loop) |
| `sit` | una vez | Pasa de estar de pie a sentado cuando te sentás. El juego lo desliza hasta la silla en 0,8 s: la animación, en el lugar | 0,8 s |
| `play_card` | una vez | Tira una carta a la mesa | 0,5 a 0,8 s |
| `talk` | una vez | Dice algo (murmura, provoca) | 1 a 1,5 s |
| `call` | una vez | Canta: truco, envido, quiero, etc. Más enfático que `talk` | 0,8 a 1,2 s |
| `gain_points` | una vez | Se anota puntos: festeja a su manera | 1 a 1,5 s |
| `lose_points` | una vez | Te anotás puntos vos: se molesta | 1 a 1,5 s |
| `tell_calm` | una vez | Su gesto de "tranquilo" (las pistas de su humor) | 1 a 2 s |
| `tell_nervous` | una vez | Su gesto de nervios: toca la mesa, se acomoda | 1 a 2 s |
| `tell_smug` | una vez | Su gesto de confiado: sonrisa, se tira para atrás | 1 a 2 s |
| `tell_angry` | una vez | Su gesto de enojo | 1 a 2 s |

Los cuatro `tell_*` son lo más importante después de `idle`: son las pistas que el jugador aprende a leer, así que cada rival tiene que hacerlos **a su manera** y que se distingan bien.

**Otros personajes:**

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. | Animaciones |
|---|---|---|---|---|---|---|
| 19 | `bartender.glb` | El cantinero detrás de la barra, de pie. El juego lo desliza de un lado al otro | 0,5 × 1,75 × 0,25 | 2.500 | 256 | `idle` (repasando un vaso, en loop) |
| 20 | `accomplice.glb` | El cómplice: de pie atrás tuyo, espía tus cartas y le hace señas al rival. Solo se ve al darte vuelta cuando el rival hace esa trampa | 0,5 × 1,75 × 0,35 | 2.000 | 256 | `idle` (espiando y haciendo señas, en loop) |
| 21 | `soul.glb` | Alma perdida que deambula por el bar, lejos de la mesa. Hay tres en pantalla con el mismo modelo | 0,38 × 1,6 × 0,28 | 1.200 | 128 | `walk` (caminar en el lugar, en loop) e `idle` (parada) |

Todos los personajes con rig: un solo esqueleto por modelo, animaciones "en el lugar" (sin desplazar el origen: el juego los mueve), a 30 cuadros por segundo.

### P3: el bar alrededor

Con la luz de la lámpara casi no se ve: poco detalle alcanza. Texturas que se repitan.

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. |
|---|---|---|---|---|---|
| 22 | `room.glb` | Piso, paredes y techo (una caja que se ve **desde adentro**, con huecos para la puerta y la ventana) | 8 × 3 × 8 | 1.500 | 256 |
| 23 | `bar_counter.glb` | Barra con estantes y botellas atrás. La tapa queda a 1,1 m: ahí se apoya el mantel de la tienda | 3 × 1,1 × 0,9 | 1.500 | 256 |
| 24 | `wardrobe.glb` | El guardarropas: una caja o cajón sobre la barra, a la derecha del mantel | 0,2 × 0,06 × 0,14 | 400 | 128 |
| 25 | `door.glb` | Puerta de entrada | 0,9 × 2,1 × 0,1 | 300 | 128 |
| 26 | `window.glb` | Ventana; afuera, la ruta de noche | 1,2 × 1 × 0,1 | 300 | 128 |
| 27 | `scoreboard.glb` | Pizarra en la pared | 0,6 × 0,4 × 0,05 | 200 | 128 |

### P4: amuletos

Se ven sobre la mesa, al lado de tus cartas, y en el mantel de la tienda. En la vista de cerca de la tienda flotan y giran frente a la cámara, así que se ven de todos lados. Medida: entran en **0,075 × 0,035 × 0,075 m** (pueden ser más altos si es un vaso o una botella, hasta unos 0,1 m). Cada uno tiene hasta **300 triángulos** y una textura de **64 px**.

Un modelo por amuleto sirve para sus tres niveles (I, II, III): el nivel lo muestra el juego.

| # | Archivo | Amuleto | Qué hace (para inspirarse) | Rareza |
|---|---|---|---|---|
| 28 | `amulet_marker.glb` | Marcador permanente | Cambia el número de una carta tuya | Raro |
| 29 | `amulet_spare_deck.glb` | Mazo aparte | Cambia una carta tuya por otra de la reserva | Raro |
| 30 | `amulet_cigarette.glb` | Cigarrillo | El rival pide menos veces mostrar el tanto | Común |
| 31 | `amulet_cana_glass.glb` | Vaso de caña | Declarar el tanto sin levantar sospechas | Raro |
| 32 | `amulet_rosary.glb` | Rosario | Anula el último canto del rival | Raro |
| 33 | `amulet_facon.glb` | Facón | Obliga al rival a querer tu próximo canto | Raro |
| 34 | `amulet_glasses.glb` | Lentes | Muestra cuántas cartas tiene el rival | Común |
| 35 | `amulet_hat.glb` | Sombrero | Muestra los números de las cartas del rival | Legendario |
| 36 | `amulet_mirror.glb` | Espejo | Trampa: espiar | Legendario |
| 37 | `amulet_marked_cards.glb` | Cartas marcadas | Trampa: cartas con marcas | Raro |
| 38 | `amulet_red_ribbon.glb` | Cinta roja | Plata | Común |
| 39 | `amulet_train_coin.glb` | Moneda aplastada por el tren | Plata | Común |

Los bordes de color de la tienda indican la rareza: gris común, azul raro, dorado legendario. Si el modelo acompaña con su material, mejor.

### Futuro: hoy son formas simples

El juego los dibuja con formas básicas y todavía no carga modelos para ellos. Si se modelan, hay que conectarlos en el código (es poco trabajo). Conviene hacerlos al final.

| # | Archivo sugerido | Qué es | Medida (m) | Triáng. | Textura |
|---|---|---|---|---|---|
| 40 | `bean.glb` | Poroto: se apilan en el medio de la mesa para marcar lo que vale el truco | 0,014 × 0,008 × 0,01 | 40 | 32 |
| 41 | `chip.glb` | Ficha: una por cada rival que ya le ganaste en la run | 0,032 × 0,005 × 0,032 | 60 | 32 |
| 42 | `score_sheet.glb` | Planilla de papel para anotar los puntos ("NOS / ELLOS"). El juego escribe encima | 0,2 × 0,002 × 0,24 | 20 | 128 |
| 43 | `price_tag.glb` | Cartelito de precio de cada amuleto en la tienda. El juego escribe el precio | 0,1 × 0,002 × 0,055 | 20 | 64 |
| 44 | `cloth.glb` | El mantel de la tienda sobre la barra | 1,15 × 0,005 × 0,78 | 50 | 128 |
| 45 | `money_stack.glb` | Fajo de billetes viejos (apilado según tu plata) | 0,07 × 0,02 × 0,035 | 300 | 64 |

---

## 3. Texturas, fuentes y sonido que no son modelos

| # | Archivo | Qué es | Detalle | Prioridad |
|---|---|---|---|---|
| 46 | `assets/fonts/handwriting.ttf` | Letra manuscrita para los precios de la tienda | Cualquier fuente a mano de licencia libre | P3 |
| 47 | `assets/audio/babble/babble.wav` | Una sílaba de balbuceo: la "voz" de todos | 0,05 a 0,1 s, mono. El juego le cambia el tono en cada sílaba | P3 |
| 48 | `assets/audio/babble/<rival>.wav` | Voz propia de un rival (opcional) | El nombre en minúsculas, por ejemplo `la ira.wav` | P4 |

---

## 4. Resumen para presupuestar

| Grupo | Cantidad | Prioridad |
|---|---|---|
| Mesa, mazo, lámpara, sillas | 5 modelos | P1 |
| Cartas | 41 imágenes | P1 |
| Rivales de cuerpo entero, con rig y 13 animaciones (solo `idle` obligatoria) | 8 modelos | P2 |
| Versiones de rivales | 22 modelos (opcionales) | P2 |
| Cantinero, cómplice, alma (con rig) | 3 modelos | P2 |
| Habitación, barra, guardarropas, puerta, ventana, pizarra | 6 modelos | P3 |
| Amuletos | 12 modelos | P4 |
| Porotos, ficha, planilla, cartel, mantel, fajo | 6 modelos | Futuro |
| Fuente y sonidos | 1 fuente, 1 sonido y voces opcionales | P3 a P4 |

**Total obligatorio:** 34 modelos y 41 imágenes de cartas. Opcionales: 22 versiones de rivales y 6 modelos futuros.

---

## 5. Antes de empezar a modelar

1. Fijar la **paleta** (sección 1) y una **hoja de estilo**: 1 o 2 imágenes del bar de noche, guardadas en `docs/concept/`. Si cada modelo sale de una persona o una IA distinta, la paleta y la densidad de pixel son lo que hace que parezcan del mismo juego.
2. Hacer primero **un modelo de prueba de cada distancia**, mirarlos en el juego y recién ahí encargar el resto. Por ejemplo: la mesa, un amuleto y la barra.

## 6. Cómo entregar cada modelo (checklist para el modelador)

- [ ] Nombre exacto de la tabla, en minúsculas, `.glb`.
- [ ] El objeto en el centro de la escena (0, 0, 0) al exportar. Si está corrido en Blender, sale corrido en el juego.
- [ ] Escala aplicada, 1 unidad = 1 m, dentro de la medida de la tabla.
- [ ] Y arriba, frente hacia −Z, pivote abajo al centro (rivales: en el piso, bajo el asiento de su silla).
- [ ] Triángulos y textura dentro del límite.
- [ ] Textura PNG, potencia de 2, solo color, pintada sin suavizar.
- [ ] Densidad de pixel según la distancia (sección 1).
- [ ] Sin luces, cámaras ni mapas normales.
- [ ] Personajes: un esqueleto, animaciones en el lugar con los nombres exactos, al menos `idle`.

Para probar: copiar el archivo en `assets/models/`, abrir el juego y correr los tests. Si se pasa de algún límite, el test lo dice con el nombre del archivo.
