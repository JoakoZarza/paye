# Payé — Lista de modelos y texturas

Para Joako. Cada modelo va en `assets/models/` con el **nombre exacto** de la tabla. Si el archivo está, el juego lo usa; si no, muestra un cubo gris del mismo tamaño. No hace falta tocar código. El test `tests/world/test_assets_budget.gd` avisa si un modelo se pasa de polígonos o de textura.

## Reglas para todos los modelos

| Regla | Valor |
|---|---|
| Formato | `.glb` (glTF binario). Blender, Meshy, Tripo y la mayoría de las IAs exportan así. |
| Escala | 1 unidad = 1 metro. |
| Orientación | Y hacia arriba. El frente del objeto mira hacia −Z (hacia la cámara del jugador). |
| Origen (pivote) | Abajo y al centro: el objeto queda apoyado en el piso o en la mesa en Y = 0. |
| Texturas | PNG de 64×64, 128×128 o 256×256 (las cartas, 128×192). Sin mapas normales ni de rugosidad: solo color. |
| Materiales | Uno o dos por modelo. El juego les pone encima el filtro PS1 (vértices que tiemblan, niebla, colores reducidos), así que no hace falta "envejecerlos". |
| Luces y cámaras | No incluir: se ignoran. |

**Si lo hacés con IA:** los modelos suelen salir con 20.000 a 100.000 triángulos y texturas de 2048 px. En Blender: modificador *Decimate* hasta el límite de la tabla, y después achicar la textura (en GIMP o Photoshop, sin suavizar). Revisá que el pivote quede abajo y al centro y aplicá la escala (*Ctrl+A → All Transforms*) antes de exportar.

## Prioridad 1: con esto ya se siente 3D

| Archivo | Qué es | Medida aproximada (ancho × alto × fondo) | Triángulos máx. | Textura máx. |
|---|---|---|---|---|
| `table.glb` | Mesa de bar vieja, de madera, cuadrada o redonda | 0,9 × 0,75 × 0,9 m | 800 | 256 |
| `chair_player.glb` | Tu silla (casi no se ve, alcanza con algo simple) | 0,45 × 0,9 × 0,45 m | 400 | 128 |
| `chair_rival.glb` | Silla del rival | 0,45 × 0,9 × 0,45 m | 400 | 128 |
| `rival_base.glb` | Cuerpo sentado del rival, sin cabeza (para poder cambiarla por pecado) | 0,6 × 1,3 × 0,6 m | 3.000 | 256 |
| `lamp.glb` | Lámpara colgante sobre la mesa, con cable o cadena | 0,4 × 0,6 × 0,4 m | 500 | 128 |

**Cartas** (en `assets/cards/`, no son modelos: el juego las arma con un plano):

| Archivo | Qué es | Tamaño |
|---|---|---|
| `espada_1.png` … `espada_12.png` | Las 10 de espada (1 a 7, 10, 11, 12) | 128×192 px |
| `basto_*.png`, `oro_*.png`, `copa_*.png` | Igual para los otros palos | 128×192 px |
| `back.png` | Dorso | 128×192 px |

Son 41 imágenes. Se puede partir de un mazo español de dominio público escaneado y bajarle la resolución, o generarlas con IA siguiendo un mismo estilo.

## Prioridad 2: los rivales

Cabezas o máscaras que se ponen sobre `rival_base.glb`. Origen en la base del cuello.

| Archivo | Rival | Idea (de DISENO §5) | Triángulos máx. | Textura máx. |
|---|---|---|---|---|
| `head_ira.glb` | La Ira | Rojo, venas, dientes apretados | 1.500 | 256 |
| `head_gula.glb` | La Gula | Cara hinchada, boca enorme | 1.500 | 256 |
| `head_pereza.glb` | La Pereza | Ojos caídos, medio dormida | 1.500 | 256 |
| `head_envidia.glb` | La Envidia | Verdosa, ojos que miran de reojo | 1.500 | 256 |
| `head_lujuria.glb` | La Lujuria | Seductora y perturbadora | 1.500 | 256 |
| `head_soberbia.glb` | La Soberbia | Corona o sombrero alto, mirada desde arriba | 1.500 | 256 |
| `head_alma.glb` | Almas en pena | Cara borrosa, sábana o máscara simple (sirve para las 4) | 1.000 | 128 |
| `head_gualicho.glb` | El Gualicho | El dueño del bar, el más inquietante | 2.000 | 256 |
| `accomplice.glb` | El cómplice | Figura parada atrás tuyo que espía tus cartas y le hace señas al rival. Se ve solo al mirar para atrás cuando el rival hace esa trampa. Cuerpo entero, de pie, 0,5 × 1,75 × 0,35 m | 2.000 | 256 |

## Prioridad 3: el bar alrededor

Con la niebla y la luz de la lámpara casi no se ven: poco detalle alcanza.

| Archivo | Qué es | Medida aproximada | Triángulos máx. | Textura máx. |
|---|---|---|---|---|
| `room.glb` | Piso, paredes y techo del bar (una caja con huecos para puerta y ventana) | 8 × 3 × 8 m | 1.500 | 256 |
| `bar_counter.glb` | Barra con estantes y botellas | 3 × 1,1 × 0,6 m | 1.500 | 256 |
| `door.glb` | Puerta de entrada | 0,9 × 2,1 × 0,1 m | 300 | 128 |
| `window.glb` | Ventana (afuera, la ruta de noche) | 1,2 × 1 × 0,1 m | 300 | 128 |
| `scoreboard.glb` | Pizarra para anotar los puntos, en la pared | 0,6 × 0,4 × 0,05 m | 200 | 128 |

## Prioridad 4: amuletos y plata

Se ven sobre la mesa, al lado de tus cartas. Chicos: entre 5 y 20 cm. Hasta 300 triángulos y textura de 64 cada uno.

| Archivo | Amuleto |
|---|---|
| `amulet_marker.glb` | Marcador permanente |
| `amulet_spare_deck.glb` | Mazo aparte |
| `amulet_cigarette.glb` | Cigarrillo |
| `amulet_cana_glass.glb` | Vaso de caña |
| `amulet_rosary.glb` | Rosario |
| `amulet_facon.glb` | Facón |
| `amulet_glasses.glb` | Lentes |
| `amulet_hat.glb` | Sombrero |
| `amulet_mirror.glb` | Espejo |
| `amulet_marked_cards.glb` | Cartas marcadas |
| `amulet_red_ribbon.glb` | Cinta roja |
| `amulet_train_coin.glb` | Moneda aplastada por el tren |
| `money_stack.glb` | Fajo de billetes viejos (el juego lo apila según la plata) |

## Concept art

No lo usa el juego directamente, pero ayuda a que todo tenga el mismo estilo. Conviene guardarlo en `docs/concept/` y fijar primero una **paleta** (6 a 10 colores) y una **hoja de clima** del bar de noche, antes de modelar. Si cada modelo sale de una IA distinta, la paleta es lo que hace que parezcan del mismo juego.

## Sonido

- `assets/audio/babble/babble.wav`: una sílaba de balbuceo (0,05–0,1 s, mono). Opcional `<rival>.wav` por rival, con el nombre en minúsculas (por ejemplo `la ira.wav`). El juego le cambia el tono en cada sílaba; mientras no exista usa uno generado.
