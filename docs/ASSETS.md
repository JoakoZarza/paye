# Payé: lista completa de modelos, texturas y sonidos

Esta es la lista de **todo** lo que el juego puede cargar, con medidas, límites y prioridad. Sirve para Joako y para cualquier modelador que se sume: no hace falta saber Godot ni tocar código.

**Cómo funciona.** Cada archivo va en su carpeta con el **nombre exacto** de la tabla. Si el archivo está, el juego lo usa. Si no está, muestra un cubo del mismo tamaño en su lugar. El test `tests/world/test_assets_budget.gd` avisa si un modelo se pasa de triángulos, de textura o de medida. Los límites están en `world/asset_budget.json`.

**Estado hoy (2026-11-04):** no hay ningún modelo ni textura cargado. Todo se ve con cubos.

---

## 1. Estilo visual

### La idea

Figuras **low poly** con **texturas chicas pixeladas**, mostradas a **resolución completa** (HD):

- Los bordes de las figuras se ven limpios: sin dientes de sierra, sin vértices que tiemblan, sin filtro de TV vieja.
- El "pixelado" lo ponen solo las texturas, que se ven con los píxeles marcados (filtro *Nearest*, sin suavizar).
- La forma es simple y facetada: pocas caras, sin superficies redondeadas suaves.

Es el estilo de juegos como CloverPit. Los tamaños exactos de las texturas de CloverPit no son públicos; los de este documento son los de Payé. Están pensados para que se vea así.

> El juego también tiene un modo PS1 (resolución baja, vértices que tiemblan, colores reducidos). Se elige con `"ps1"` en `data/ui.json`: `false` es el modo HD. Los modelos sirven igual para los dos modos.

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
| Origen (pivote) | Abajo y al centro: el objeto queda apoyado en Y = 0. Las cabezas, en la base del cuello. |
| Sombreado | Plano (*flat shading*) o con bordes duros: que se noten las caras. |
| Materiales | Uno o dos por modelo. |
| Luces y cámaras | No incluir: se ignoran. |
| Animaciones | El juego todavía no las reproduce. Si un modelo trae alguna, no molesta. |

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
| 2 | `deck.glb` | El mazo apoyado en la mesa (pila de cartas boca abajo) | 0,063 × 0,014 × 0,095 | 100 | 64 |
| 3 | `lamp.glb` | Lámpara colgante sobre la mesa, con cable o cadena hacia arriba. Origen abajo: la pantalla queda a 1,55 m del piso | 0,4 × 0,6 × 0,4 | 500 | 128 |
| 4 | `chair_rival.glb` | Silla del rival | 0,45 × 0,9 × 0,45 | 400 | 128 |
| 5 | `chair_player.glb` | Tu silla: casi no se ve, alcanza con algo simple | 0,45 × 0,9 × 0,45 | 400 | 128 |

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

**Cuerpo del rival.** Un solo cuerpo para todos; lo que cambia es la cabeza.

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. |
|---|---|---|---|---|---|
| 11 | `rival_base.glb` | Cuerpo sentado, sin cabeza, con brazos sobre la mesa. La cabeza se pone a 1,3 m | 0,6 × 1,3 × 0,6 | 3.000 | 256 |

**Cabezas por pecado.** Origen en la base del cuello; entran en unos 0,26 × 0,3 × 0,26 m.

El juego busca primero la cabeza de la **versión** (`head_<pecado>_<versión>.glb`). Si no está, usa la del pecado (`head_<pecado>.glb`), y si tampoco está, la del alma. Conviene hacer primero las 8 cabezas de pecado. Las versiones son opcionales y se pueden sumar de a una. Las versiones usan los mismos límites que la cabeza de su pecado.

| # | Archivo (base) | Rival | Idea | Versiones opcionales (archivo extra) | Triáng. | Textura |
|---|---|---|---|---|---|---|
| 12 | `head_ira.glb` | La Ira | Rojo, venas, dientes apretados | `head_ira_estallido`, `head_ira_rencor`, `head_ira_mecha_corta` | 1.500 | 256 |
| 13 | `head_gula.glb` | La Gula | Cara hinchada, boca enorme | `head_gula_gloton`, `head_gula_atracon`, `head_gula_insaciable` | 1.500 | 256 |
| 14 | `head_pereza.glb` | La Pereza | Ojos caídos, medio dormida | `head_pereza_dormido`, `head_pereza_fiaca_tramposa`, `head_pereza_siesta` | 1.500 | 256 |
| 15 | `head_envidia.glb` | La Envidia | Verdosa, mira de reojo | `head_envidia_copiona`, `head_envidia_mirona`, `head_envidia_resentida` | 1.500 | 256 |
| 16 | `head_lujuria.glb` | La Lujuria | Seductora y perturbadora | `head_lujuria_seductora`, `head_lujuria_mentirosa`, `head_lujuria_encantadora` | 1.500 | 256 |
| 17 | `head_soberbia.glb` | La Soberbia | Corona o sombrero alto, mira desde arriba | `head_soberbia_invicto`, `head_soberbia_desden`, `head_soberbia_perfeccionista` | 1.500 | 256 |
| 18 | `head_alma.glb` | Almas en pena | Cara borrosa, sábana o máscara simple | `head_alma_novato`, `head_alma_miedoso`, `head_alma_cantor`, `head_alma_mudo` | 1.000 | 128 |
| 19 | `head_gualicho.glb` | El Gualicho (jefe final) | El dueño del bar, el más inquietante | — (una sola versión) | 2.000 | 256 |

En total: 8 cabezas base y 22 versiones opcionales.

**Otros personajes:**

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. |
|---|---|---|---|---|---|
| 20 | `bartender.glb` | El cantinero detrás de la barra, de pie. El juego lo mueve de un lado al otro | 0,5 × 1,75 × 0,25 | 2.500 | 256 |
| 21 | `accomplice.glb` | El cómplice: de pie atrás tuyo, espía tus cartas y le hace señas al rival. Solo se ve al darte vuelta cuando el rival hace esa trampa | 0,5 × 1,75 × 0,35 | 2.000 | 256 |
| 22 | `soul.glb` | Alma perdida que camina por el bar, lejos de la mesa. Hay tres en pantalla con el mismo modelo | 0,38 × 1,6 × 0,28 | 1.200 | 128 |

### P3: el bar alrededor

Con la luz de la lámpara casi no se ve: poco detalle alcanza. Texturas que se repitan.

| # | Archivo | Qué es | Medida (m) | Triáng. máx. | Textura máx. |
|---|---|---|---|---|---|
| 23 | `room.glb` | Piso, paredes y techo (una caja que se ve **desde adentro**, con huecos para la puerta y la ventana) | 8 × 3 × 8 | 1.500 | 256 |
| 24 | `bar_counter.glb` | Barra con estantes y botellas atrás. La tapa queda a 1,1 m: ahí se apoya el mantel de la tienda | 3 × 1,1 × 0,9 | 1.500 | 256 |
| 25 | `wardrobe.glb` | El guardarropas: una caja o cajón sobre la barra, a la derecha del mantel | 0,2 × 0,06 × 0,14 | 400 | 128 |
| 26 | `door.glb` | Puerta de entrada | 0,9 × 2,1 × 0,1 | 300 | 128 |
| 27 | `window.glb` | Ventana; afuera, la ruta de noche | 1,2 × 1 × 0,1 | 300 | 128 |
| 28 | `scoreboard.glb` | Pizarra en la pared | 0,6 × 0,4 × 0,05 | 200 | 128 |

### P4: amuletos

Se ven sobre la mesa, al lado de tus cartas, y en el mantel de la tienda. En la vista de cerca de la tienda flotan y giran frente a la cámara, así que se ven de todos lados. Medida: entran en **0,075 × 0,035 × 0,075 m** (pueden ser más altos si es un vaso o una botella, hasta unos 0,1 m). Cada uno tiene hasta **300 triángulos** y una textura de **64 px**.

Un modelo por amuleto sirve para sus tres niveles (I, II, III): el nivel lo muestra el juego.

| # | Archivo | Amuleto | Qué hace (para inspirarse) | Rareza |
|---|---|---|---|---|
| 29 | `amulet_marker.glb` | Marcador permanente | Cambia el número de una carta tuya | Raro |
| 30 | `amulet_spare_deck.glb` | Mazo aparte | Cambia una carta tuya por otra de la reserva | Raro |
| 31 | `amulet_cigarette.glb` | Cigarrillo | El rival pide menos veces mostrar el tanto | Común |
| 32 | `amulet_cana_glass.glb` | Vaso de caña | Declarar el tanto sin levantar sospechas | Raro |
| 33 | `amulet_rosary.glb` | Rosario | Anula el último canto del rival | Raro |
| 34 | `amulet_facon.glb` | Facón | Obliga al rival a querer tu próximo canto | Raro |
| 35 | `amulet_glasses.glb` | Lentes | Muestra cuántas cartas tiene el rival | Común |
| 36 | `amulet_hat.glb` | Sombrero | Muestra los números de las cartas del rival | Legendario |
| 37 | `amulet_mirror.glb` | Espejo | Trampa: espiar | Legendario |
| 38 | `amulet_marked_cards.glb` | Cartas marcadas | Trampa: cartas con marcas | Raro |
| 39 | `amulet_red_ribbon.glb` | Cinta roja | Plata | Común |
| 40 | `amulet_train_coin.glb` | Moneda aplastada por el tren | Plata | Común |

Los bordes de color de la tienda indican la rareza: gris común, azul raro, dorado legendario. Si el modelo acompaña con su material, mejor.

### Futuro: hoy son formas simples

El juego los dibuja con formas básicas y todavía no carga modelos para ellos. Si se modelan, hay que conectarlos en el código (es poco trabajo). Conviene hacerlos al final.

| # | Archivo sugerido | Qué es | Medida (m) | Triáng. | Textura |
|---|---|---|---|---|---|
| 41 | `bean.glb` | Poroto: se apilan en el medio de la mesa para marcar lo que vale el truco | 0,014 × 0,008 × 0,01 | 40 | 32 |
| 42 | `chip.glb` | Ficha: una por cada rival que ya le ganaste en la run | 0,032 × 0,005 × 0,032 | 60 | 32 |
| 43 | `score_sheet.glb` | Planilla de papel para anotar los puntos ("NOS / ELLOS"). El juego escribe encima | 0,2 × 0,002 × 0,24 | 20 | 128 |
| 44 | `price_tag.glb` | Cartelito de precio de cada amuleto en la tienda. El juego escribe el precio | 0,1 × 0,002 × 0,055 | 20 | 64 |
| 45 | `cloth.glb` | El mantel de la tienda sobre la barra | 1,15 × 0,005 × 0,78 | 50 | 128 |
| 46 | `money_stack.glb` | Fajo de billetes viejos (apilado según tu plata) | 0,07 × 0,02 × 0,035 | 300 | 64 |

---

## 3. Texturas, fuentes y sonido que no son modelos

| # | Archivo | Qué es | Detalle | Prioridad |
|---|---|---|---|---|
| 47 | `assets/fonts/handwriting.ttf` | Letra manuscrita para los precios de la tienda | Cualquier fuente a mano de licencia libre | P3 |
| 48 | `assets/audio/babble/babble.wav` | Una sílaba de balbuceo: la "voz" de todos | 0,05 a 0,1 s, mono. El juego le cambia el tono en cada sílaba | P3 |
| 49 | `assets/audio/babble/<rival>.wav` | Voz propia de un rival (opcional) | El nombre en minúsculas, por ejemplo `la ira.wav` | P4 |

---

## 4. Resumen para presupuestar

| Grupo | Cantidad | Prioridad |
|---|---|---|
| Mesa, mazo, lámpara, sillas | 5 modelos | P1 |
| Cartas | 41 imágenes | P1 |
| Cuerpo del rival y cabezas de pecado | 1 + 8 modelos | P2 |
| Versiones de cabezas | 22 modelos (opcionales) | P2 |
| Cantinero, cómplice, alma | 3 modelos | P2 |
| Habitación, barra, guardarropas, puerta, ventana, pizarra | 6 modelos | P3 |
| Amuletos | 12 modelos | P4 |
| Porotos, ficha, planilla, cartel, mantel, fajo | 6 modelos | Futuro |
| Fuente y sonidos | 1 fuente, 1 sonido y voces opcionales | P3 a P4 |

**Total obligatorio:** 35 modelos y 41 imágenes de cartas. Opcionales: 22 versiones de cabezas y 6 modelos futuros.

---

## 5. Antes de empezar a modelar

1. Fijar la **paleta** (sección 1) y una **hoja de estilo**: 1 o 2 imágenes del bar de noche, guardadas en `docs/concept/`. Si cada modelo sale de una persona o una IA distinta, la paleta y la densidad de pixel son lo que hace que parezcan del mismo juego.
2. Hacer primero **un modelo de prueba de cada distancia**, mirarlos en el juego y recién ahí encargar el resto. Por ejemplo: la mesa, un amuleto y la barra.

## 6. Cómo entregar cada modelo (checklist para el modelador)

- [ ] Nombre exacto de la tabla, en minúsculas, `.glb`.
- [ ] Escala aplicada, 1 unidad = 1 m, dentro de la medida de la tabla.
- [ ] Y arriba, frente hacia −Z, pivote abajo al centro (cabezas: base del cuello).
- [ ] Triángulos y textura dentro del límite.
- [ ] Textura PNG, potencia de 2, solo color, pintada sin suavizar.
- [ ] Densidad de pixel según la distancia (sección 1).
- [ ] Sin luces, cámaras ni mapas normales.

Para probar: copiar el archivo en `assets/models/`, abrir el juego y correr los tests. Si se pasa de algún límite, el test lo dice con el nombre del archivo.
