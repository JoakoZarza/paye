# Payé — Paleta y prompts de concept art

## 1. La paleta

**Definila antes de texturizar.** No conviene pintar con colores "normales" y filtrar al final: el filtro de Photoshop cambia cada textura distinto y los modelos terminan sin parecer del mismo juego. Mejor:

1. Pintá o generá la textura como quieras.
2. Achicala al tamaño final (64, 128 o 256 px) con **Vecino más próximo** (*Image > Image Size > Resample: Nearest Neighbor*).
3. Pasala a la paleta: *Image > Mode > Indexed Color > Palette: Custom*, cargando [`paye.act`](paye.act), que está en esta carpeta (para GIMP, [`paye.gpl`](paye.gpl)), con **Dither: Diffusion** al 50–75%. Volvé a *RGB Color* y exportá PNG.

El juego después agrega niebla, temblor de vértices y reducción de color, así que las texturas solo tienen que respetar los colores: no hace falta ensuciarlas de más.

| # | Nombre | Hex | Para qué |
|---|---|---|---|
| 1 | Negro humo | `#0E0C0B` | Sombras, fondo, niebla lejana |
| 2 | Marrón quemado | `#2A1A12` | Madera en sombra, rincones |
| 3 | Madera vieja | `#5C3A22` | Mesa, sillas, barra |
| 4 | Cuero gastado | `#8A5A34` | Bordes iluminados, objetos de mano |
| 5 | Tungsteno | `#D9A54A` | Luz de la lámpara, brillos, oro |
| 6 | Papel de carta | `#D8C9A3` | Cartas, carteles, piel iluminada |
| 7 | Rojo vino | `#6E1A1A` | Paño, sangre seca, Ira |
| 8 | Rojo truco | `#B23A2B` | Acentos, dorso de las cartas, peligro |
| 9 | Verde botella | `#2C4232` | Botellas, Envidia, moho |
| 10 | Azul ruta de noche | `#1B2738` | Ventana, luz fría de afuera |
| 11 | Ceniza | `#6B665E` | Metales, humo, almas en pena |
| 12 | Hueso | `#B8AE98` | Dientes, calaveras, rosario |

La regla general es luz cálida adentro (la lámpara, tonos 4 a 6) contra frío afuera (tono 10), con todo lo demás hundido en marrones y negro. Cada pecado suma **un** color propio y nada más: Ira rojo, Envidia verde, Gula ocre grasoso, Pereza ceniza, Lujuria vino rosado y Soberbia tungsteno brillante, tipo dorado.

## 2. Cómo usar los prompts

- Están en **inglés** porque las IAs de imagen lo entienden mejor.
- Cada uno ya incluye el **bloque de estilo**. Si tu IA tiene un campo aparte para estilo, pegá solo el bloque ahí y sacalo del prompt.
- **Formato horizontal 16:9.** En Midjourney agregá `--ar 16:9`; en otras, elegí 1920×1080 o "landscape". Los que piden otro formato lo dicen.
- **Negative prompt** (si tu IA lo acepta), para todos:
  `photorealistic, high poly, smooth shading, 4k detail, clean modern, anime, cartoon, bright colors, saturated, text, watermark, logo, blurry face, extra fingers`

**Bloque de estilo** (es el mismo en todos):
> PS1-era low-poly 3D render, 1998 PlayStation horror game aesthetic, low-resolution pixelated textures without filtering, visible polygon edges, slight vertex jitter, dithered colors, limited palette of smoky black, burnt brown, old wood, worn leather, tungsten yellow light, card-paper beige, wine red and dark bottle green, with cold night blue only from outside, heavy fog, single warm hanging lamp as main light, deep shadows, grimy rural Argentine roadside bar at night, sinister, melancholic, uncanny, in the spirit of Buckshot Roulette and Inscryption

## 3. Prompts

### 3.1 Gameplay en primera persona (la imagen principal)
> First-person POV from a seated player at a small square wooden bar table, looking across at a creepy masked dealer sitting opposite. In the foreground at the bottom of the frame, the player's own hands hold three Spanish playing cards (baraja española: espadas, bastos, oros, copas) fanned out, slightly blurred. On the table: two cards already played face up in a row, a small worn rosary and a folding facón knife next to the player's hand, a crumpled stack of old Argentine pesos, a glass of caña. A single cone of warm light from a hanging lamp falls on the table; everything beyond the table dissolves into dark fog. Behind the dealer, a chalkboard with tally marks on the wall. The dealer leans forward with an unsettling stillness. [bloque de estilo], horizontal 16:9 composition, eye level, shallow depth of field

### 3.2 Menú principal
> Main menu concept for a horror card game called "Payé". Exterior night shot of a lonely roadside bar (boliche de ruta) in the Argentine countryside: a low brick and adobe building with a flickering tin sign, one warm window, a dirt road, a rusty bus stop sign, telephone poles fading into fog, a crossroads. Large empty dark sky on the left third for the title and menu options. A single figure-shaped silhouette in the window. [bloque de estilo], horizontal 16:9, wide static shot, still and quiet, no text

### 3.3 La mano de cartas de cerca
> Close-up first-person view looking down at the player's hands holding three worn Spanish playing cards (one 1 of espadas, one 7 of oros, one 3 of copas), old printed illustrations, yellowed paper, bent corners, dirty fingernails, a silver ring on the pinky. The wooden table below has cigarette burns and knife carvings. Warm lamp light from above, deep shadows. [bloque de estilo], horizontal 16:9, macro POV, focus on the cards

### 3.4 La mesa y los objetos vista desde arriba
> Top-down orthographic view of a square wooden bar table during a card game, arranged for gameplay readability: player's side at the bottom with three face-down card slots, opponent's side at the top, the center with three rows for played cards, a deck on the right edge, a small tray on the left with trinkets (rosary, glasses, a squashed train coin, red ribbon, marked cards, a small hand mirror, a hat), a stack of old banknotes, a chalk score tally in the corner of the table, an ashtray. Strong single light from above, vignette into black. [bloque de estilo], horizontal 16:9, flat top-down layout, game design reference sheet

### 3.5 El bar completo
> Wide interior view of a cramped, decaying roadside bar in rural Argentina at night, seen from the corner. A long wooden counter with dusty bottles and a broken mirror, a calendar from decades ago, a saint's picture with a candle, a jukebox that doesn't work, a single card table in the center under a hanging lamp, other tables empty with chairs upside down. Fog fills the room; the light ends abruptly. A door to the outside with the cold blue of the road. Nobody behind the counter, but a glass is being filled. [bloque de estilo], horizontal 16:9, wide establishing shot

### 3.6 La tienda (entre partidos)
> First-person view standing at the bar counter of a sinister roadside bar, where an old shopkeeper with no visible eyes lays out three trinkets on a dirty cloth for sale: a rosary, a folding knife, a pair of round glasses, each with a small handwritten price tag in pesos. Behind him shelves with jars, bottles, candles and votive offerings (like a Gauchito Gil shrine with red ribbons). A ledger book of debts ("fiado") open on the counter with a pencil. Warm lamp light on the counter, darkness behind. [bloque de estilo], horizontal 16:9, eye level

### 3.7 Los rivales (uno por imagen)
Para que salgan en la misma pose y se puedan comparar, todos empiezan igual:
> Character concept of a card-game dealer seated at a wooden bar table, front view, waist up, hands resting on the table near a deck of Spanish cards, lit from above by a hanging lamp, dark fog background. [bloque de estilo], horizontal 16:9, centered, character sheet with a small side view

Y se agrega la descripción de cada uno:

- **La Ira:** `the personification of Wrath: a gaunt man with cracked red-tinged skin, bulging veins, clenched broken teeth, smoke rising from his collar, knuckles split, staring with barely contained rage`
- **La Gula:** `the personification of Gluttony: a swollen figure in a stained butcher's apron, an oversized mouth stretched in a permanent grin, greasy fingers, crumbs and bones on the table, sickly ochre tones`
- **La Pereza:** `the personification of Sloth: a slumped, half-asleep figure in a moth-eaten poncho, heavy drooping eyelids, cobwebs between fingers and chair, ash-gray skin, barely holding the cards`
- **La Envidia:** `the personification of Envy: a thin figure with greenish skin and eyes that look sideways at the player's cards, long nervous fingers, a green bottle-glass tint, a forced polite smile`
- **La Lujuria:** `the personification of Lust: an elegant but wrong-looking figure in a faded wine-colored dress or suit, a porcelain mask with painted lips, too many rings, perfume haze, inviting and disturbing`
- **La Soberbia:** `the personification of Pride: a tall stiff figure in an old military gaucho outfit with tarnished gold medals and a tall hat, chin raised, looking down at the player, the only clean thing in the bar`
- **Almas en pena:** `a lost soul: a faceless figure under a dirty sheet or a blank wooden mask, translucent at the edges, holding the cards clumsily, ash-gray`
- **El Gualicho (jefe final):** `the owner of the bar and the final boss: an ancient figure made of tangled red ribbons, dried flowers and candle wax, a face like a carved wooden idol, glowing tungsten eyes, the debt ledger chained to his wrist`

### 3.8 Hoja de amuletos
> Item sheet of 12 cursed trinkets for a card game, arranged in a 4x3 grid on dark worn cloth, each lit separately: a permanent marker pen, a small spare deck of cards tied with string, a single cigarette, a glass of caña, a wooden rosary, a gaucho facón knife, round wire glasses, a battered felt hat, a small hand mirror, a deck of marked cards, a red ribbon (cinta roja), a coin flattened by a train. Low-poly game asset style, each object readable at small size. [bloque de estilo], horizontal 16:9, item reference sheet, no text

### 3.9 Cartas: estilo de cara y dorso
> Design sheet for a custom Spanish playing card deck (baraja española, 40 cards: espadas, bastos, oros, copas, numbers 1-7 and 10-12 with sota, caballo and rey), old woodcut print style, yellowed paper, faded red and ochre ink, slightly sinister faces on the figures, plus a card back design with a red geometric pattern and a small skull hidden in the ornament. Shown flat, front-facing, 6 example faces and 1 back. Low resolution print look. horizontal 16:9, design reference sheet

### 3.10 La muerte (perder el partido)
> First-person POV slumped over the card table after losing, cards scattered and fallen, the dealer standing up and pointing an old revolver at the camera, the lamp swinging and throwing moving shadows, a single drop of blood on a card. The frame tilts as if falling. [bloque de estilo], horizontal 16:9, dramatic low angle

### 3.11 El final bueno (te retirás con los $10.000.000)
> Dawn at the roadside bus stop outside the bar: an old long-distance bus with its lights on in the fog, its door open, the bar behind fading like a mirage, the first pale light of sunrise over the flat countryside. The player's shadow walks toward the bus holding a bag. Peaceful but eerie. [bloque de estilo, pero con luz fría y amanecer en lugar de la lámpara], horizontal 16:9, wide shot

### 3.12 Hoja de clima (para fijar el estilo de todo)
> Mood board for a PS1-style horror card game set in a rural Argentine roadside bar that is secretly purgatory for the greedy: a grid of 9 small frames showing the lamp-lit card table, fog outside the window at night, close-up of worn Spanish cards, bottles on the counter, a saint shrine with red ribbons, the dealer's silhouette, a chalk score tally, an empty dirt road, the bus stop sign. Consistent palette of smoky black, burnt brown, old wood, tungsten yellow, card-paper beige, wine red, bottle green and cold night blue. [bloque de estilo], horizontal 16:9, mood board grid, no text

## 4. Orden recomendado

1. **3.12 (hoja de clima)** y **3.1 (gameplay)**. Repetí hasta que una te represente: esa imagen define todo lo demás.
2. Subí esa imagen como **referencia de estilo** en cada prompt siguiente. En Midjourney es `--sref <url>`; otras IAs tienen "image reference" o "style reference". Esto ayuda más que cualquier palabra a que todo salga parecido.
3. Después: 3.4 (mesa), 3.7 (rivales), 3.9 (cartas), 3.8 (amuletos); son las que más vas a modelar.
4. Por último: 3.2, 3.5, 3.6, 3.10, 3.11.

Guardá las elegidas en `docs/concept/` con el número del prompt en el nombre (por ejemplo `3.1-gameplay.png`).
