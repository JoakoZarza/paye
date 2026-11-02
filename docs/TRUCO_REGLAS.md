# Truco argentino, 2 jugadores: reglas de referencia

Referencia para el motor de juego de **Payé**. Cubre el truco argentino **mano a mano** (1 contra 1). Las **señas no se incluyen**, porque sin compañero no existen.

## Fuentes

Cada regla cita su fuente entre corchetes. Orden de autoridad usado:

| Clave | Fuente | Tipo |
|---|---|---|
| [GBA] | [Reglamento de Truco, Juegos Bonaerenses 2026 (Prov. de Buenos Aires)][gba] | Reglamento oficial de torneo provincial |
| [Rentas] | [Reglamento Truco del XXI Encuentro Nacional de Empleados de Rentas (Asoc. de Catastro y Rentas)][rentas] | Reglamento de torneo nacional. Citado por [La Capital][lacapital] como "reglamento oficial" |
| [CPCE] | [Reglamento 8º Torneo de Truco, Consejo Profesional (CABA)][cpce] | Reglamento de torneo (solo cláusulas puntuales) |
| [JdS] | [Reglamento de Truco, juegosdesalon.com][jds] | Reglamento completo de divulgación, con "expresiones valederas en campeonatos" |
| [Pagat] | [Argentinean Truco, pagat.com (John McLeod)][pagat] | Referencia internacional cuidadosa |
| [Wiki] | [Truco argentino, Wikipedia ES][wiki] | Secundaria. La propia página tiene contradicciones internas |
| [FAQ] | [laps4.com, "¿Qué pasa si me voy al mazo?"][laps4] | Baja confianza. Solo para una costumbre que ningún reglamento detalla |

**Nota sobre ASART:** los Juegos Nacionales Evita 2023 remiten al "Reglamento Oficial de la Asociación Argentina de Truco (ASART)" ([doc. nacional][nac]). El sitio de ASART (asart.com.ar) no respondió y su texto no está publicado en otro lado, así que no se pudo citar.

Convenciones del documento:
- **Mano**: el jugador que no reparte. Juega primero y gana los empates.
- **Pie**: el que reparte.
- **Baza**: cada una de las 3 rondas de cartas. Los reglamentos también la llaman "mano" (primera mano, segunda mano).
- **Tiro** o **ronda**: el reparto completo de 3 cartas. Los reglamentos también lo llaman "mano".
- **(Más común)** marca la variante recomendada como valor por defecto del motor.

---

## 1. Mazo y jerarquía de cartas

**Mazo:** baraja española de 40 cartas, sin 8, sin 9 y sin comodines [GBA 4.1][gba] [JdS §8][jds]. Palos: espadas (E), bastos (B), oros (O) y copas (C). Rangos: 1-7, 10 (sota), 11 (caballo), 12 (rey).

**Jerarquía para ganar bazas**, de mayor a menor [GBA 11.3][gba] [JdS §5, §9][jds] [Pagat][pagat] [Wiki][wiki]. Fuera de las 4 "bravas", **el palo no importa**. Cartas del mismo nivel **empatan**, y ese empate se llama parda.

| Nivel (14 = más alta) | Cartas | Cant. | Nombre |
|---|---|---|---|
| 14 | 1E | 1 | Ancho de espadas (espadilla, macho) |
| 13 | 1B | 1 | Ancho de bastos (bastillo, hembra) |
| 12 | 7E | 1 | Siete de espadas |
| 11 | 7O | 1 | Siete de oros |
| 10 | 3E, 3B, 3O, 3C | 4 | Treses |
| 9 | 2E, 2B, 2O, 2C | 4 | Doses |
| 8 | 1O, 1C | 2 | Anchos falsos |
| 7 | 12E, 12B, 12O, 12C | 4 | Reyes |
| 6 | 11E, 11B, 11O, 11C | 4 | Caballos |
| 5 | 10E, 10B, 10O, 10C | 4 | Sotas |
| 4 | 7B, 7C | 2 | Sietes falsos |
| 3 | 6 (los 4 palos) | 4 | Seis |
| 2 | 5 (los 4 palos) | 4 | Cincos |
| 1 | 4 (los 4 palos) | 4 | Cuatros |

Total: 40 cartas. Los niveles únicos (sin empate posible) son 14, 13, 12 y 11. Todos los demás pueden dar parda.

**Valor de cada carta para el tanto (envido y flor)** [JdS §6][jds] [Pagat][pagat]: del 1 al 7 vale su número. 10, 11 y 12 valen **0** (se llaman "negras"). El valor para el tanto no tiene relación con la jerarquía de bazas.

## 2. Reparto, mano y pie, turnos

- **Primer dador:** se sortea. En [GBA 4.4][gba] se da una carta boca arriba a cada uno y reparte quien saca la más alta.
- **Corte:** el dador mezcla y da a cortar al rival de su izquierda. En 2 jugadores corta el único rival. Hay un solo corte. Golpear el mazo sin cortarlo es válido [GBA 4.5-4.6][gba] [JdS §17][jds]. Cada parte del corte debe tener al menos 3 cartas [JdS §17][jds].
- **Reparto:** 3 cartas a cada jugador, **de a una y alternadas**, empezando por el mano [GBA 4.5][gba] [JdS §17][jds]. El sentido es antihorario.
- **Mano:** el que recibe primero, es decir el no-dador. **Pie:** el dador [GBA 4.5][gba].
- **Alternancia:** el reparto rota en cada tiro, así que en 2 jugadores la mano se alterna en cada tiro [GBA 4.5][gba] [Pagat][pagat].
- **Turno en la baza 1:** juega primero el mano.
- **Turno en las bazas 2 y 3:** juega primero quien ganó la baza anterior. Si la anterior fue parda, vuelve a salir el mano [JdS §14][jds] [GBA 12.1][gba] [Pagat][pagat]. Pagat lo formula como "sale de nuevo quien salió en la baza empatada", que en 2 jugadores da el mismo resultado.
- **Las cartas jugadas** quedan boca arriba delante de quien las jugó. No se recogen [JdS §14][jds].
- **No hay obligación de seguir palo** [Pagat][pagat].

## 3. Bazas: quién gana el truco

Gana la baza la carta de mayor nivel. Si las dos cartas tienen el mismo nivel, la baza es **parda** y no es de nadie [JdS §14][jds] [Pagat][pagat].

Regla general: gana el truco quien gana 2 bazas. Si hay pardas, gana **el primero en ganar una baza no parda**. Si las 3 bazas son pardas, gana **el mano** [GBA 12.1][gba] [JdS §14][jds] [Pagat][pagat] [Wiki][wiki].

| Baza 1 | Baza 2 | Baza 3 | Gana | ¿Se juega la 3ra? |
|---|---|---|---|---|
| A | A | — | A | No |
| A | B | A | A | Sí |
| A | B | B | B | Sí |
| A | B | parda | **A** (ganó la primera) | Sí |
| A | parda | — | **A** | No |
| parda | A | — | **A** ("parda la primera, gana la segunda") | No |
| parda | parda | A | A | Sí |
| parda | parda | parda | **Mano** | Sí |

- No hace falta jugar la baza 3 si alguien ganó las dos primeras, o si una de las dos primeras fue parda y la otra tiene ganador [JdS §14][jds] [Pagat][pagat].
- Si nadie cantó truco, el ganador suma **1 punto** [GBA 11.4][gba] [JdS §14][jds].

## 4. Envido

### 4.1 Cálculo del tanto

- **Dos cartas del mismo palo:** suma de sus valores + 20 [JdS §7][jds] [Pagat][pagat].
- **Tres cartas de palos distintos:** el valor de la carta más alta, de 0 a 7. Las negras valen 0 [JdS §13][jds] [GBA 7.5][gba].
- **Tres cartas del mismo palo jugando sin flor**, o con flor que no se cantó: 20 + las **dos** cartas de mayor valor de tanto [Pagat][pagat] [JdS §13][jds] [Rentas 5a][rentas].
- **Dos figuras del mismo palo:** 20 [JdS §13][jds].
- **Rango posible:** 0-7 o 20-33. El máximo, 33, es 7+6 del mismo palo [JdS §13][jds] [Pagat][pagat]. Los valores 8 a 19 no existen.

### 4.2 Cuándo se puede cantar

- Solo durante la **baza 1**, y cada jugador solo **antes de jugar su propia carta** de esa baza [GBA 7.2][gba] [JdS §13, §18][jds] [Pagat][pagat].
- Si ambos jugaron su primera carta sin cantar ("callados"), ya no hay envido [JdS §11][jds].
- Quien ya jugó su carta **no puede abrir** envido, pero **sí puede responder** a un envido del rival [JdS §11][jds] [Rentas 4d][rentas].
- No se puede cantar envido **después de haber querido el truco** [JdS §13][jds] [Rentas 5b][rentas] [Wiki][wiki].
- Según [JdS §16][jds], quien canta truco primero pierde la opción de cantar envido, porque ya inició la fase del truco. Sí puede responder a un envido del rival: "puede contestar al envido contrario" [JdS §13][jds].
- **"El envido está primero" (o "va primero"):** si un jugador canta truco en la baza 1, el rival que todavía no jugó su carta puede responder **envido**, real envido o falta envido en lugar de contestar el truco. Primero se resuelve el envido, y después el rival tiene que contestar el truco pendiente [JdS §11, §13][jds] [Rentas 4c, 5b][rentas] [Pagat][pagat].
  - Variante: [Wiki][wiki] recoge condiciones distintas, y en una de ellas el "envido está primero" vale aunque quien responde ya haya jugado su carta. **Más común:** solo si no jugó su carta.
- **Retruco y envido:** responder "quiero retruco" acepta el truco, y eso cierra el envido para quien responde. Quien cantó el truco tampoco puede abrir envido, por la regla de [JdS §16][jds]. Por eso, en la práctica, "quiero retruco" en la baza 1 cierra el envido para los dos.
- **En 2 jugadores** cualquiera de los dos puede cantar envido. La restricción de que solo cante el "pie" es una regla de juego en equipo [Wiki][wiki].

### 4.3 Cantos y respuestas

Cantos de apertura [JdS §13][jds] [GBA 7-9][gba]:
- **Envido:** vale 2.
- **Real envido:** vale 3.
- **Falta envido:** vale lo que da la fórmula del §4.5.

Respuestas posibles a un envido o un real envido [JdS §13][jds]:
- **Quiero:** acepta y cierra.
- **No quiero:** rechaza y cierra.
- **Envido, real envido o falta envido:** acepta lo anterior **implícitamente** y sube. No hace falta decir "quiero" antes de subir, a diferencia del truco [GBA 7.9][gba] [JdS §16][jds].

Reglas de encadenamiento:
- La falta envido **no se puede subir**. Solo admite quiero o no quiero [Pagat][pagat].
- Después de un real envido **no se puede responder envido**, porque el canto no puede bajar [Pagat][pagat].
- Una vez dicho "quiero", ya no se puede subir [GBA 7.8][gba].
- Si no hay respuesta, el canto cuenta como **no querido** [GBA 6.6][gba].
- **Envido-envido:** el segundo envido tiene que cantarlo el rival. Si el mismo jugador dice "envido envido", vale como un envido simple [JdS §16][jds].

Cuántas veces se puede repetir cada canto:

| Repetición | Postura | Fuentes |
|---|---|---|
| Envido repetido | Una sola vez **(más común)**. Pagat no pone límite. Sitio Andino menciona E+E+E | [Wiki][wiki] [Pagat][pagat] [Andino][andino] |
| Real envido + real envido | Permitido según Pagat (vale 6). No aparece en las tablas de [GBA][gba] ni de [Wiki][wiki]. **Recomendación:** no permitirlo | [Pagat][pagat] |
| Dos o tres reales envido (+6 / +9) | Variante regional | [Pagat][pagat] |

### 4.4 Tabla completa de puntos (cadenas legales con envido repetido una sola vez)

Regla del **no querido**: si se rechaza el **primer** canto, quien cantó suma **1**. Si se rechaza una **subida**, quien subió suma lo que valía la cadena **antes** de su último canto [JdS §13][jds] [GBA 7.9, 9.2][gba] [Wiki][wiki].

Regla del **querido**: suman los valores de la cadena. Si en la cadena hay una **falta envido**, el querido vale **solo la falta**, que reemplaza lo acumulado [Pagat][pagat] [JdS §4][jds]. **Más común:** que reemplace. Ninguna fuente suma la falta a lo acumulado.

Abreviaturas: E = envido, R = real envido, F = falta envido.

| Cadena | Querido | No querido | Fuente |
|---|---|---|---|
| E | 2 | 1 | [GBA 10][gba] |
| R | 3 | 1 | [GBA 10][gba] |
| F | falta | 1 | [GBA 9.2][gba] |
| E-E | 4 | 2 | [GBA 10][gba] |
| E-R | 5 | 2 | [GBA 10][gba] |
| E-F | falta | 2 | [Wiki][wiki] |
| R-F | falta | 3 | [JdS §13][jds] [Wiki][wiki] |
| E-E-R | 7 | 4 | [GBA 10][gba] |
| E-E-F | falta | 4 | [Wiki][wiki] |
| E-R-F | falta | 5 | [Wiki][wiki] |
| E-E-R-F | falta | 7 | [GBA 10][gba] [Wiki][wiki] |
| *Variante* R-R | 6 | 3 | [Pagat][pagat] |
| *Variante* E-R-R | 8 | 5 | Se deduce de [Pagat][pagat] |
| *Variante* E-E-R-R | 10 | 7 | Se deduce de [Pagat][pagat] |

Nota sobre la tabla de [GBA 10][gba]: el texto extraído da "E-E-R no querido = 4" y "E-E-R-F no querido = 7", lo que coincide con la regla general.

Caso límite: si al rival le falta 1 punto para ganar, el envido y el real envido **mantienen su valor normal**. El rival decide si sube a falta [GBA 7.10][gba].

### 4.5 Valor de la falta envido (las fuentes no coinciden)

P = puntos para ganar (30 o 15). L = puntaje del que va ganando. W = quien gana la falta.

| Variante | Regla | Fuentes |
|---|---|---|
| **A. "Lo que le falta al que va ganando"** **(más común en los reglamentos escritos)** | W suma P − L. Si gana el que va adelante, gana el partido | [CPCE][cpce] [JdS §4, §13][jds] [Pagat][pagat] [Rentas 5c][rentas] |
| B. "Malas y buenas", versión Wiki | Si **los dos están en malas**, W gana el partido. Si alguno está en buenas, W suma P − L | [Wiki][wiki] |
| C. "Malas y buenas", versión GBA | Si se está "en malos", W cobra lo necesario "para concluir un chico", que se lee como ganar el partido. Si se está "en buenos", W cobra **lo que le falta al contrario** de W para terminar | [GBA 9.2][gba] |
| D. "Hasta las buenas" | Si el que va adelante está en malas, vale lo que le falta para llegar a 15. Si está en buenas, lo que le falta para ganar | [Rentas 3h][rentas] |
| E. "Falta al partido" | Quien gana la falta gana el partido, aunque vaya atrás | [JdS §13][jds] ("algunos jugadores") [Andino][andino] |
| F. Variante del Litoral | Con dos faltas y los dos en malas, W gana lo que le falta al que va adelante para llegar a las buenas | [Wiki][wiki] |

- Empate en el puntaje: se usa ese puntaje común como L.
- En partido a 15, sin malas ni buenas, se aplica la variante A con P = 15.
- La falta puede valer **menos** que lo ya cantado, por ejemplo si L = 29. Por eso a veces se canta para defenderse [Pagat][pagat].
- **Recomendación para el motor:** dejar la variante como opción configurable, con A por defecto.

### 4.6 Declarar el tanto, empates y mostrar las cartas

- **Orden:** con el envido querido, el **mano canta su tanto primero** [GBA 7.6][gba] [Pagat][pagat]. Después el pie canta un número mayor o dice **"son buenas"**, y con eso pierde sin revelar su tanto [JdS §13][jds] [Pagat][pagat].
  - Variante: muchos permiten decir "son buenas" aunque se tenga más. Ninguna fuente lo prohíbe expresamente, pero [JdS §13][jds] lo presenta como la opción de quien tiene menos.
- **Empate de tanto:** gana el **mano** [GBA 7.4][gba] [JdS §13][jds] [Pagat][pagat].
- **El número dicho vale aunque sea un error:** una vez querido, cualquier número que se diga cuenta "de un modo absoluto" [GBA 6.8][gba].
- **Mostrar las cartas:** el ganador del tanto **tiene que mostrar** las cartas que lo forman antes de anotar. Se hace al final del tiro, y las cartas ya jugadas boca arriba cuentan como mostradas [JdS §13][jds] [Pagat][pagat] [Wiki][wiki].
- **Si el ganador mintió o se equivocó:** pierde el tanto, y los puntos van al rival aunque el rival tuviera menos. Esto vale incluso si con su tanto real también habría ganado [GBA 7.7][gba] [JdS §13][jds] [Wiki][wiki].
- **Si el ganador se va al mazo sin jugar ni mostrar las cartas del tanto:** los puntos del envido van al rival [GBA 7.7][gba].
- **Si el ganador no las muestra y el rival lo nota:** los puntos van al rival [Wiki][wiki].
- **Revisar las cartas del mazo:** las cartas ya mezcladas con el mazo no se pueden revisar, salvo para comprobar un envido cantado. Si la falta se prueba, el infractor pierde esos puntos a favor del denunciante. Si no se prueba, el acusado cobra **3** puntos de indemnización [GBA 6.2-6.3][gba].
- **Implementación:** el motor puede calcular el tanto automáticamente. Si se permite mentir sobre el número, conviene aplicar las reglas de arriba.

## 5. Flor (opcional, se acuerda antes de jugar)

- **Si se juega con flor:** [GBA 6.13][gba] la usa. [CPCE][cpce] juega sin flor. En [Rentas 2c][rentas], si los dos bandos no se ponen de acuerdo, se juega **sin flor**. [JdS §12][jds] dice que muchos la eliminan porque depende mucho del azar. **Recomendación:** sin flor por defecto y configurable.
- **Qué es:** 3 cartas del mismo palo. Valor: 20 + la suma de las tres, con figuras en 0. Rango 20-38, máximo 7+6+5 [JdS §12][jds] [Pagat][pagat].
  - Variante: una flor de tres figuras vale 30 [Pagat][pagat].
- **Cantarla es obligatorio** si se juega con flor. Se canta en el turno propio y antes de cualquier otro canto o de jugar la carta de la baza 1 [JdS §11, §12][jds] [Pagat][pagat] [GBA 6.14][gba].
- **Cantar flor sin tenerla** está prohibido. Quien dice "flor" sin tenerla pierde los puntos del tiro [JdS §12, §16][jds].
- **Flor y envido:** cantar flor **anula** el envido ya cantado. Con flor en juego no se disputa el envido [GBA 6.15][gba] [JdS §12][jds] [Pagat][pagat].
- **Flor y truco:** un truco ya cantado queda **en suspenso** hasta que se resuelve la flor [JdS §12][jds].
- **Orden de los cantos:** flor, después envido, después truco [JdS §11][jds] [Pagat][pagat].
- **Desempate:** la flor empatada la gana el mano [Pagat][pagat].
- **"Flor reservada":** no aparece en ninguna de las fuentes consultadas. Si se usa, tiene que ser una regla de la casa.

### 5.1 Puntos de la flor (2 jugadores)

| Situación | [GBA 6.14-6.16][gba] | [JdS §12][jds] / [Pagat][pagat] | [Wiki][wiki] |
|---|---|---|---|
| Flor sola, el rival no tiene | 3 | 3 | 3 |
| Flor contra flor (el rival dice "flor", sin contraflor) | — | 3 por flor, es decir 6 al mejor | 4 al mejor |
| "Con flor me achico" | 4 para quien cantó primero | Pagat: 3 por flor del rival + 1 = 4 | — |
| Contraflor querida ("con flor quiero") | 6 | 6 (JdS) | 6 |
| Contraflor no querida o achicada | 4 | Lo apostado y aceptado hasta ese momento | — |
| Contraflor al resto querida | **gana el partido** | Lo que le falta al líder + 3 por flor. JdS: "algunos" la juegan al partido | Lo que el rival necesita para terminar |
| Contraflor al resto no querida | 4 | — | — |

- **Respuestas a una contraflor:** con flor quiero, con flor me achico o contraflor al resto [JdS §12][jds] [Pagat][pagat].
- **Respuestas a una contraflor al resto:** solo quiero o no quiero [JdS §12][jds] [Pagat][pagat].
- **Más común, para 2 jugadores, siguiendo GBA:** flor 3, me achico 4, contraflor 6 o 4, contraflor al resto al partido o 4.
- **"Pedir flor":** al final del tiro, si se sospecha que el rival tenía flor y no la cantó, se le puede pedir.
  - Si la tenía, quien pidió suma 3 según [Pagat][pagat], o 3 más todos los tantos del tiro del rival según [JdS §12][jds].
  - Si no la tenía, el acusado suma 1 según [Pagat][pagat], o 3 o 4 según [JdS §12][jds].
  - [Andino][andino] llama "flor tapada" a no cantar la flor y la considera falta.

## 6. Truco, retruco, vale cuatro

| Canto | Querido (lo cobra quien gana las bazas) | No querido (lo cobra quien cantó) | Quién puede cantarlo |
|---|---|---|---|
| (sin canto) | 1 | — | — |
| Truco | 2 | 1 | Cualquiera de los dos |
| Retruco | 3 | 2 | Solo quien **quiso** el truco |
| Vale cuatro | 4 | 3 | Solo quien **quiso** el retruco |

Fuentes de la tabla: [GBA 11.4, 13, 14][gba] [JdS §14][jds] [Pagat][pagat] [Wiki][wiki].

- **"La palabra":** después de un quiero, solo quien dijo quiero puede subir. Quien cantó no puede volver a subir su propio canto [GBA 13.1][gba] [JdS §14][jds]. El vale cuatro es el tope y no se sube más.
- **"Quiero retruco"** es una respuesta válida en un solo acto: acepta el truco y sube [GBA 13.2][gba].
- **Subir sin decir "quiero":** decir "retruco" a secas, sin el quiero, es **ilícito** según los reglamentos [GBA 13.2][gba] [JdS §14, §16][jds] [Pagat][pagat].
  - Variante informal muy común: "retruco" solo se toma como quiero + retruco. **Recomendación:** que la interfaz ofrezca "Quiero retruco" como un solo botón.
- **Respuestas a truco o retruco:** quiero, no quiero, o subir con quiero retruco / quiero vale cuatro. En la baza 1, al truco también se puede responder con envido (ver §4.2).
- **Respuestas a vale cuatro:** solo quiero o no quiero [Wiki][wiki].
- **Cuándo se puede cantar:**
  - Los reglamentos dicen "en cualquier momento" [JdS §14][jds] [Pagat][pagat]. [JdS §14][jds] agrega que lo usual es desde la segunda baza.
  - La subida no tiene que ser inmediata: se puede querer ahora y retrucar más tarde [GBA 13.2][gba] [JdS §14][jds].
  - Convención práctica y de los juegos digitales: se canta **en el turno propio, antes de jugar la carta**. **Recomendación** para el motor: solo en el turno propio.
- **Jugar una carta no responde un canto:** con un canto pendiente, tirar una carta no equivale a quererlo [Pagat][pagat]. El motor tiene que exigir la respuesta antes de seguir.
- **Canto doble:** si se canta envido y truco a la vez ("envido mi truco"), valen los dos cantos [JdS §16][jds]. El rival puede aceptar solo una parte con "quiero y paso" o "paso y quiero" [GBA 6.9-6.10][gba] [JdS §16][jds]. **Recomendación:** que el motor no permita cantos dobles.

## 7. Irse al mazo

- **Qué es:** abandonar el tiro tirando las cartas boca abajo junto al mazo [JdS §4, §14][jds].
- **Cuándo:** en el turno propio, o como respuesta a un canto. Irse al mazo frente a un canto pendiente equivale a "no quiero" [Pagat][pagat] [FAQ][laps4].

| Situación al irse | El rival suma | Fuente |
|---|---|---|
| Sin truco cantado, con el envido ya cerrado o ya sin posibilidad | 1 | [JdS §14][jds] |
| Con truco pendiente, sin responder | 1, es decir truco no querido | [FAQ][laps4] |
| Con truco querido | 2. Con retruco querido, 3. Con vale cuatro querido, 4 | Por la regla del querido |
| Con retruco pendiente (rechazado al irse) | 2 | Por la regla del no querido |
| Con vale cuatro pendiente (rechazado al irse) | 3 | Por la regla del no querido |
| **Antes de jugar ninguna carta, sin decir nada y con el envido todavía posible** | **2**, uno por el envido y uno por el truco **(más común)** | [GBA 6.1][gba] [FAQ][laps4] |
| *Variante* de lo anterior | 1 | [JdS §14][jds], que no distingue el caso |
| Con envido cantado y sin responder | Lo del envido no querido + lo del truco | [FAQ][laps4] |
| El ganador del envido querido se va sin mostrar sus cartas | El rival cobra el envido, más el truco que corresponda | [GBA 7.7][gba] |

- **Interpretación para 2 jugadores de la regla de 2 puntos:** se aplica si el que se va todavía podía cantar envido. También se aplica, por extensión, si el rival todavía podía cantarlo: por ejemplo, si el mano se va sin jugar, el pie no llegó a tener su oportunidad de envido. Si el envido ya se cantó y se resolvió, o si ya pasó la baza 1, solo cuenta el truco.
- **Envido ya querido y resuelto:** sus puntos ya están ganados y no se pierden al irse al mazo, salvo que el ganador no muestre sus cartas.

## 8. Puntaje y fin del partido

- **Partido a 30:** 15 "malas" (los primeros 15) y 15 "buenas" (del 16 al 30) **(más común)** [JdS §2, §15][jds] [Rentas 2a][rentas] [Pagat][pagat] [Nac 3.2][nac].
- **Partido a 15:** sin malas ni buenas [Wiki][wiki]. [CPCE][cpce] lo usa en el tercer partido de desempate.
- **Partido a 40** (20 malas y 20 buenas): se usa en [GBA 4.2-4.3][gba]. Es raro.
- **"Chico":** un partido a 30. Muchos juegan al mejor de 3 chicos [JdS §2][jds] [Pagat][pagat].
- **Malas y buenas en la práctica:** solo cambian cómo se anuncia el puntaje ("5 buenas"). No afectan el juego [Pagat][pagat], salvo en el valor de la falta envido (§4.5).
- **Desde qué puntaje se está "en buenas":** las fuentes no coinciden.
  - Del 16 en adelante: 1-15 son malas [Pagat][pagat].
  - Con 15 ya se está en buenas: "cuando se ha anotado 15 tantos" [JdS §3][jds] [Wiki][wiki].
  - Solo importa para las variantes B, C y D de la falta envido. **Recomendación:** que esté en buenas quien tiene 15 o más.
- **Orden de anotación:** **flor, después envido, después truco** [Pagat][pagat] [Wiki][wiki]. Si un jugador llega al objetivo con la flor o el envido, gana, y el truco de ese tiro no cuenta.
- **Si los dos llegan al objetivo en el mismo tiro:** gana quien llega primero según el orden de anotación. Como el envido se anota antes que el truco, gana quien llegó con el envido [Wiki][wiki] [Pagat][pagat].
- **Los puntos no se topan:** se puede superar el objetivo (por ejemplo, llegar a 32).

## 9. Casos raros e irregularidades

| Caso | Regla | Fuente |
|---|---|---|
| Carta que cae boca arriba en el reparto | Se reparte de nuevo (obligatorio) | [GBA 4.7][gba] |
| *Variante* de lo anterior | Quien la recibe elige si se la queda o pide un nuevo reparto | [JdS §17][jds] |
| Cartas de más (1 o 2) | Reparte de nuevo el mismo dador | [GBA 16.1][gba] |
| Quien recibió cartas de más se calla y lo descubren | 2 tantos en contra | [GBA 16.2][gba] |
| Lo mismo, descubierto durante el tiro o al final | Se le descuentan los tantos que haya ganado | [GBA 16.3][gba] |
| Faltan cartas o el mazo está incompleto | Ninguna fuente lo trata. Propuesta: anular el tiro y repartir de nuevo con el mismo dador, por analogía con [GBA 16.1][gba] | — |
| Carta jugada | La que se suelta boca arriba y se ve en la mesa. No se puede retirar | [GBA 18.1][gba] [JdS §14][jds] |
| Carta apoyada boca abajo | No cuenta como jugada | [GBA 18.2][gba] |
| Dos cartas jugadas juntas | Vale la de abajo | [GBA 19.1][gba] |
| Cantar fuera de turno | Los cantos se hacen en el turno propio, siguiendo el orden flor, envido, truco. Las palabras reservadas obligan si el canto es legal | [JdS §11, §16][jds] [Pagat][pagat] |
| Canto dicho antes de mirar las cartas | Una vez que se tienen las 3 cartas en la mano, vistas o no, cualquier canto es válido | [GBA 17.1][gba] |
| No se puede obligar a responder | Mientras el rival no vio sus 3 cartas | [GBA 6.12][gba] |
| Cantar envido después de la baza 1, o después de haber jugado la propia carta | No vale nada | [GBA 7.2][gba] |
| Envido después de querer el truco | No se permite | [JdS §13][jds] |
| Palabras deformadas ("quiebro", "turco", "florcita") | Prohibidas. En campeonato, una forma ambigua cuenta como canto | [GBA 20.1][gba] [JdS §16][jds] |
| "No quiero ser cobarde, ¡quiero!" | Vale lo primero que se dijo: no quiero | [GBA 20.2][gba] [JdS §16][jds] |
| "Envido envido" dicho por el mismo jugador, o "envido mi falta envido" | Valen como un envido simple | [JdS §16][jds] |
| "Envido mi flor" | Vale el envido | [JdS §16][jds] |
| Falta envido cuando uno está en buenas | Depende de la variante del §4.5. Con la variante A no importa | — |
| Falta envido con L = 29 | Vale 1. Es legal cantarla aunque valga menos que un envido | [Pagat][pagat] |
| Repartir mal (no alternado, o empezando por el pie) | Ninguna fuente lo trata. Propuesta: tratarlo como mal reparto y repartir de nuevo | — |
| Truco con un 4 en la última baza | Según [Wiki][wiki] está prohibido, salvo acuerdo previo. La misma página se contradice. Regla de la casa, se puede ignorar | [Wiki][wiki] |
| Retirarse sin responder | Cuenta como no querido | [GBA 6.6][gba] |

---

## 10. Checklist para el motor del juego

Cada línea es una regla verificable. Se asume la configuración por defecto: 2 jugadores, partido a 30, sin flor, falta envido de variante A, envido repetido una sola vez y sin real envido repetido.

**Mazo y jerarquía**
- [ ] El mazo tiene exactamente 40 cartas: 4 palos × {1, 2, 3, 4, 5, 6, 7, 10, 11, 12}.
- [ ] rank(1E) > rank(1B) > rank(7E) > rank(7O) > rank(3·) > rank(2·) > rank(1O) = rank(1C) > rank(12·) > rank(11·) > rank(10·) > rank(7B) = rank(7C) > rank(6·) > rank(5·) > rank(4·).
- [ ] Hay exactamente 14 niveles de jerarquía distintos.
- [ ] 3E contra 3C da parda. 1O contra 1C da parda. 7B contra 7C da parda. 7E contra 7O no da parda.

**Reparto y turnos**
- [ ] Cada jugador recibe 3 cartas y no hay cartas repetidas.
- [ ] El no-dador es mano. El dador se alterna en cada tiro.
- [ ] En la baza 1 juega primero el mano.
- [ ] En las bazas 2 y 3 juega primero el ganador de la baza anterior. Si la anterior fue parda, juega primero el mano.

**Resultado de las bazas**
- [ ] A, A: gana A y no se juega la 3ra.
- [ ] A, B, A: gana A.
- [ ] A, B, B: gana B.
- [ ] A, B, parda: gana A.
- [ ] A, parda: gana A y no se juega la 3ra.
- [ ] parda, A: gana A y no se juega la 3ra.
- [ ] parda, parda, A: gana A.
- [ ] parda, parda, parda: gana el mano.
- [ ] Si no se cantó truco, el ganador del tiro suma 1.

**Cálculo del tanto**
- [ ] El tanto de 7E, 6E, 1B es 33.
- [ ] El tanto de 12O, 11C, 10E es 0.
- [ ] El tanto de 12O, 11O, 5C es 20.
- [ ] El tanto de 7O, 4C, 1E es 7, porque no hay palo repetido y gana la carta más alta.
- [ ] El tanto de 5B, 4B, 6B jugando sin flor es 31: 20 + 6 + 5.
- [ ] Con flor, la flor de 7E, 6E, 5E vale 38.
- [ ] El tanto calculado nunca está entre 8 y 19.

**Cuándo se canta envido**
- [ ] Solo se puede cantar envido en la baza 1.
- [ ] Un jugador que ya jugó su carta de la baza 1 no puede abrir envido, pero sí puede responder (subir, querer o no querer).
- [ ] Si los dos jugaron su carta de la baza 1, cantar envido es ilegal.
- [ ] Después de un "quiero" al truco, cantar envido es ilegal.
- [ ] Ante un truco en la baza 1, el rival que no jugó su carta puede responder envido. Después de resolver el envido, el truco sigue pendiente de respuesta.
- [ ] Quien cantó truco no puede abrir envido en ese tiro.
- [ ] "Quiero retruco" deja el envido cerrado para los dos.

**Cadena de envido**
- [ ] E-R es legal. R-E es ilegal.
- [ ] F no se puede subir: solo admite quiero o no quiero.
- [ ] Después de un "quiero" no se puede subir.
- [ ] Con envido repetido una sola vez, E-E-E es ilegal.
- [ ] Se cumplen los valores de querido y no querido de la tabla del §4.4. Por ejemplo, E-E-R querido = 7 y no querido = 4.
- [ ] Rechazar el primer canto da 1 a quien cantó. Rechazar una subida da a quien subió el valor previo de la cadena.
- [ ] Una falta querida vale falta(P, L) y reemplaza lo acumulado.
- [ ] falta(30, L) = 30 − max(puntajes). Si gana el líder, alcanza exactamente 30.
- [ ] Con un puntaje de 29 a 10, la falta vale 1.
- [ ] Si a un jugador le falta 1 punto y le cantan envido, el envido sigue valiendo 2.

**Resolución del envido**
- [ ] El mano declara primero.
- [ ] Un tanto empatado lo gana el mano.
- [ ] "Son buenas" da el envido al rival sin revelar el tanto.
- [ ] Si el ganador declaró un tanto que no tiene, los puntos van al rival.
- [ ] Si el ganador se va al mazo sin mostrar las cartas del tanto (que no estén jugadas boca arriba), los puntos van al rival.
- [ ] Los puntos del envido se anotan antes que los del truco. Si con ellos se llega a 30, el partido termina.

**Truco**
- [ ] Se cumplen los valores de querido 2/3/4 y de no querido 1/2/3.
- [ ] Solo quien dijo "quiero" puede cantar el siguiente nivel.
- [ ] Quien cantó truco no puede cantar retruco.
- [ ] Después del vale cuatro no hay más subidas.
- [ ] "Quiero retruco" equivale a quiero (truco) + retruco.
- [ ] Con un canto pendiente, no se puede jugar carta hasta responderlo.
- [ ] Quien gana las bazas cobra el nivel querido. Si un canto se rechaza, quien cantó cobra el nivel previo.

**Irse al mazo**
- [ ] Irse al mazo con un canto pendiente equivale a no quiero.
- [ ] Irse sin truco y sin envido posible da 1 punto al rival.
- [ ] Irse con truco, retruco o vale cuatro querido da 2, 3 o 4 al rival.
- [ ] Irse en la baza 1, antes de que se cierre el envido y sin haberlo cantado, da 2 al rival (variante por defecto, configurable a 1).
- [ ] Un envido ya resuelto y mostrado se conserva aunque su ganador se vaya al mazo.

**Puntaje y fin**
- [ ] El partido termina en cuanto un jugador alcanza 30 (o el objetivo configurado), sin esperar al truco.
- [ ] El orden de anotación es flor, envido, truco.
- [ ] La función isBuenas(score) devuelve true si score >= 15. Este umbral es configurable a 16 (ver §8).
- [ ] El puntaje puede superar el objetivo y no se recorta.

**Flor (solo si está activada)**
- [ ] Con flor activada, una mano de 3 cartas del mismo palo debe cantar flor antes de jugar su carta de la baza 1.
- [ ] Cantar flor anula el envido. Un truco pendiente se suspende hasta resolver la flor.
- [ ] Flor sin flor del rival vale 3. Con flor me achico, 4. Contraflor querida, 6. Contraflor al resto querida, gana el partido (variante GBA).
- [ ] La flor empatada la gana el mano.
- [ ] Cantar flor sin tenerla es ilegal.

[gba]: https://juegos.gba.gob.ar/wp-content/uploads/2026/reglamentos/especificos/deportes_adultos_mayores/truco.pdf
[rentas]: https://dgrentas.arcat.gob.ar/olimpiadas/reglamentos/truco.pdf
[cpce]: https://archivo.consejo.org.ar/deportes/files/8TORNEO_Reg.pdf
[jds]: https://www.folkloretradiciones.com.ar/reglamento%20truco.pdf
[pagat]: https://www.pagat.com/put/truco_ar.html
[wiki]: https://es.wikipedia.org/wiki/Truco_argentino
[laps4]: https://www.laps4.com/preguntas-y-respuestas/que-pasa-si-me-voy-al-mazo-en-el-truco
[andino]: https://www.sitioandino.com.ar/lifestyle/guia-definitiva-del-truco-argentino-reglamento-senas-universales-y-las-particularidades-mendoza-n5724727
[lacapital]: https://www.lacapital.com.ar/informacion-general/polemica-y-confusion-el-real-envido-del-truco-que-dice-el-reglamento-oficial-n10188277.html
[nac]: https://www.argentina.gob.ar/sites/default/files/2023/04/truco.pdf
