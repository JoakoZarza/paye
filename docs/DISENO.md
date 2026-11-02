# Payé — Documento de diseño

Versión 2.1 · 2026-11-01 (pecados capitales, 9 rondas, la cuenta final; 2.1: economía más dura y mejoras de amuletos) · Fuente de verdad del diseño. Si el código y este documento no coinciden, se corrige uno de los dos a propósito, nunca en silencio.

Los números marcados con **(ajustable)** son valores iniciales. Se calibran con la simulación de economía (ver [ROADMAP.md](ROADMAP.md), Plan 5) y viven en archivos de datos, no en el código.

---

## 1. Concepto

Roguelike de Truco argentino 1 contra 1. Estética y tensión de Buckshot Roulette; estructura de economía y amuletos de CloverPit. El Truco es un juego de personas: premia al mentiroso, al tramposo y al vivo más que al que tiene buenas cartas. La IA del rival juega con convicción, no con cálculo, y a veces hace trampa. El jugador también puede hacerla.

**Meta de la run:** juntar $10.000.000 y retirarse. **Regla:** ganar o morir. Perder un partido = te disparan = fin de la run.

## 2. Lore (se aplica recién en la Etapa 3)

- **Premisa visible:** tenés una deuda grande. Vas a un torneo de Truco a dos pueblos, te dormís en el colectivo, te bajás en la ruta y entrás a un bar de mala muerte. Una mesa, una lámpara, un rival tétrico. Entrada $100; tenés $135.
- **Verdad oculta:** el personaje está muerto. El bar es un purgatorio de la avaricia. No hay a quién pagarle. Los dealers son almas que en su momento eligieron el doble o nada. El acreedor es el dueño del bar. Morir y reiniciar es el loop del purgatorio; la deuda que pasa de una run a otra son los pecados acumulados.
- **Revelación gradual:** pistas a lo largo de las runs (el colectivo nunca para, los dealers repiten frases de antiguos jugadores, la deuda muestra cifras imposibles).
- **Final bueno:** llegás a $10M y te retirás → salís del bar, parada, subís al colectivo, el bar se desvanece por la ventana → créditos. Renunciar a la avaricia te libera.
- **Final malo / segunda llave:** pagás la cuenta y, en vez de retirarte, elegís **seguir** → firmás la condena: te convertís en la **avaricia**, el séptimo pecado → se abre el **Truco maldito** (modo sin fin, ver §11).

## 3. Reglas del Truco

Truco argentino, 2 jugadores, mazo español de 40 cartas (sin 8 ni 9), **sin flor** (la flor existe solo como modificador de mazo o amuleto).

### 3.1 Jerarquía para las bazas (de mayor a menor)

| Rango | Cartas |
|---|---|
| 14 | 1 de espada |
| 13 | 1 de basto |
| 12 | 7 de espada |
| 11 | 7 de oro |
| 10 | todos los 3 |
| 9 | todos los 2 |
| 8 | 1 de copa, 1 de oro |
| 7 | todos los 12 |
| 6 | todos los 11 |
| 5 | todos los 10 |
| 4 | 7 de copa, 7 de basto |
| 3 | todos los 6 |
| 2 | todos los 5 |
| 1 | todos los 4 |

### 3.2 Tanto (envido)

- Valor de carta para el tanto: su número; 10, 11 y 12 valen 0.
- Dos o más cartas del mismo palo: 20 + la suma de las dos más altas de ese palo.
- Sin palos repetidos: el valor de la carta más alta.
- Rango posible: 0 a 33.
- Empate de tantos: gana el mano.

### 3.3 Cantos de envido

Se puede cantar solo durante la primera baza, antes de que quien canta haya jugado su carta. Si se canta truco en primera, el rival puede responder con envido antes de contestar el truco ("el envido está primero").

| Secuencia | Querido | No querido |
|---|---|---|
| Envido | 2 | 1 |
| Envido + Envido | 4 | 2 |
| Real Envido | 3 | 1 |
| Envido + Real Envido | 5 | 2 |
| Envido + Envido + Real Envido | 7 | 4 |
| Falta Envido (después de cualquier secuencia) | lo que le falta al que va ganando para llegar al objetivo | lo querido de la secuencia anterior, o 1 si no había |

Regla general del "no quiero": vale lo que valía la secuencia hasta el canto anterior, mínimo 1.

### 3.4 Declaración del tanto y la mentira

1. Con el envido querido, el mano declara un número de 0 a 33. Puede mentir.
2. El otro responde "son buenas" (concede) o declara un número mayor. También puede mentir.
3. El que declaró más alto gana el envido **provisoriamente**.
4. Al terminar la mano, el perdedor elige: aceptar o **pedir que muestre**.
   - Pide mostrar y el ganador mintió (su tanto real es menor que el declarado y menor que el del rival): los puntos del envido pasan al rival, y el rival suma además **+1 de multa** (ajustable).
   - Pide mostrar y el ganador dijo la verdad: el que pidió paga **+1 punto al rival** (ajustable).
   - No pide mostrar: queda como se declaró.
5. Si la mano terminó por irse al mazo, la verificación ocurre igual.

### 3.5 Truco

| Canto | Querido | No querido |
|---|---|---|
| Sin cantar | 1 | — |
| Truco | 2 | 1 |
| Retruco | 3 | 2 |
| Vale cuatro | 4 | 3 |

Solo puede subir el que aceptó el último canto ("tiene el quiero").

### 3.6 Bazas y pardas

Mejor de 3 bazas. Empate de rango = parda.
- Primera parda: gana quien gane la segunda; si la segunda también es parda, decide la tercera; si las tres son pardas, gana el mano.
- Primera ganada y segunda parda: gana quien ganó la primera.
- Primera ganada por uno y segunda ganada por el otro: decide la tercera; si la tercera es parda, gana quien ganó la primera.

### 3.7 Irse al mazo

El rival suma lo que vale el truco en ese momento (1 si no se cantó; si hay un canto de truco pendiente, lo de "no querido"). Irse en la primera baza sin que se haya cantado envido también da 1: algunos reglamentos dan 2 por el envido que se podía cantar, pero Joako eligió 1 (ver [TRUCO_REGLAS.md](TRUCO_REGLAS.md)).

Si te vas al mazo **habiendo ganado el envido**, no mostraste tu tanto: **el envido lo cobra el rival**. Para no perderlo, el ganador del envido puede **mostrar el tanto** en su turno (botón "Mostrar el tanto") y después irse: si no mintió cobra el envido; si mintió, el envido y el castigo son del rival. La IA muestra antes de irse solo si no mintió.

### 3.8 Partido

- Objetivo: **15 puntos** para rivales comunes, **30 puntos** para jefes.
- El mano se alterna en cada mano. En la primera mano del partido **se tira una moneda** (con la semilla de la run) y el juego lo muestra.
- Gana el primero en llegar al objetivo. Los puntos de envido se suman antes que los del truco.

## 4. Trampas y acusación

**Regla de oro:** ninguna trampa es invisible. Toda trampa deja evidencia verificable; algunas además tienen una pista en vivo.

### 4.1 Trampas del dealer (MVP)

| Trampa | Pista en vivo | Evidencia |
|---|---|---|
| Carta de la manga | gesto breve al recibir cartas | el dealer tiene 4 cartas en la mano |
| Carta duplicada | ninguna | una carta que ya salió aparece de nuevo en el historial |
| El cómplice | una figura detrás tuyo hace una seña | el cómplice está visible mientras dura la mano |

### 4.2 Acusación

- Se acusa **señalando la evidencia**: una carta del historial, la mano del dealer o el cómplice. No hay botón genérico.
- **Acierto:** la mano termina. El acusador suma lo que vale el truco en ese momento (mínimo 1) y el tramposo pierde el envido que haya ganado en esa mano.
- **Error:** el rival suma **+3 puntos** (ajustable).

### 4.3 Trampas del jugador

Solo mediante amuletos de categoría Trampa (Espejo, Cartas marcadas). Cada uso tiene un riesgo de que el dealer te pesque, que crece con su sospecha.
- **Te pescan:** perdés la mano (el rival suma lo que vale el truco, mínimo 1) y el dealer sube su sospecha y su tilt por el resto del partido.

## 5. IA del dealer

Utilidad por acción + personalidad + humor + ruido. Nunca juega óptimo y nunca ve tus cartas salvo con una trampa que deja evidencia.

### 5.1 Estado

- **Rasgos fijos (0 a 1):** agresividad, tendencia a mentir, tendencia a la trampa, terquedad.
- **Estado variable:**
  - confianza: sube con rachas ganadoras y baja al perder.
  - tilt: sube al perder manos, al ser pescado o al recibir acusaciones fallidas en su contra.
  - sospecha: cuánto cree que el jugador lo mira; sube con las acusaciones y cuando pesca al jugador.
  - presupuesto de trampas: cantidad máxima por partido.
- **Memoria del jugador:** cuántas veces mentiste el tanto y cuántas veces quisiste el truco y el envido.

### 5.2 Decisión

Para cada acción legal se calcula un puntaje:
`puntaje = fuerza_percibida × peso_del_rasgo + ajuste_por_humor + ruido`.
La fuerza percibida es la fuerza real distorsionada por la confianza y el tilt. Se elige la acción de mayor puntaje. Hacer trampa es una acción más, limitada por el presupuesto y frenada por la sospecha.

### 5.3 Pistas (tells)

En cada decisión importante el dealer emite una pista: una línea de texto y un ícono de humor en el MVP. Cada rival tiene una **confiabilidad**: la probabilidad de que la pista refleje su mano real. Los jefes pueden dar pistas falsas a propósito.

### 5.4 Rivales: los pecados capitales (ajustable)

Los rivales son 6 de los 7 pecados capitales. El séptimo, la **avaricia, es el jugador**. Entre ellos aparecen **almas en pena**: IA simple, sin trampas ni trucos, que funcionan como respiro.

| Ronda | Rival | Cómo juega | Trampa preferida | Dificultad |
|---|---|---|---|---|
| 1 | Ira | Agresiva, canta todo; entra en tilt rápido ("Pichado") y, enojada, hace trampa a lo bruto | Manga | Alta |
| 2 | Alma en pena | Juega simple, casi al azar | — | Baja |
| 3 | Gula | Sube todo (envido-envido-real, retruco); se atraganta y se la puede explotar | Manga | Media |
| 4 | Pereza | Casi no canta, quiere todo por no pensar | Cómplice | Baja (piso de la V) |
| 5 | Alma en pena | Respiro | — | Baja |
| 6 | Envidia | Quiere lo tuyo: copia tus cartas | Duplicada, cómplice | Media-alta |
| 7 | Lujuria | Seduce y engaña: pistas casi siempre falsas, miente mucho el tanto | Cómplice | Alta |
| 8 | Alma en pena | Último respiro antes del final | — | Media |
| 9 | Soberbia | Jefe final a 30 puntos: terquedad máxima, nunca se va al mazo, confianza altísima, trampas sutiles; si lo humillás, se desmorona | Duplicada | Máxima |

**Curva en V:** arranca dura (rival exigente y plata justa), se afloja en el medio cuando el jugador ya se adaptó, y se pone brutal al final. Los rasgos exactos de cada pecado viven en `data/rivals.json`. Nombres y apariencia definitivos: Etapa 3.

### 5.4.1 Los pecados se conocen

- **El chisme:** si en un partido te pescan haciendo trampa, el rival siguiente arranca con **+0,3 de sospecha** (ajustable). Dura solo ese partido.
- **La plata atrae pecados:** al empezar un partido contra un pecado, su presupuesto de trampas sube **+1 por cada 5 entradas** de plata que lleves, con tope de **+2** (ajustable). Las almas no hacen trampa, así que no les afecta.

### 5.5 Versiones de cada rival

Para que la run no se pueda memorizar, cada pecado tiene **3 versiones** y hay **4 almas en pena**. La semilla de la run elige una versión por ronda. La versión **no se anuncia**: se descubre jugando. Además, en cada run los rasgos de la versión varían un poco (±0,05). ⚙️ = regla especial en el código.

| Pecado | A | B | C |
|---|---|---|---|
| Ira | **Estallido**: el tilt le sube el doble; manga | **Rencor** ⚙️: el tilt no le baja en el partido; cuanto más pierde, más trampa | **Mecha corta**: agresividad máxima desde el arranque; pistas muy confiables |
| Gula | **Glotón**: sube todo el envido | **Atracón**: sube todo el truco, hasta vale cuatro | **Insaciable** ⚙️: nunca le dice "no quiero" a un envido |
| Pereza | **Dormido**: casi nunca canta, quiere todo | **Fiaca tramposa**: usa el cómplice seguido | **Siesta** ⚙️: juega mal al principio del partido y se despierta al final |
| Envidia | **Copiona**: carta duplicada | **Mirona**: cómplice; quiere solo si sabe que gana | **Resentida** ⚙️: más agresiva cuando vos vas ganando |
| Lujuria | **Seductora**: pistas falsas casi siempre | **Mentirosa**: miente el tanto al extremo | **Encantadora** ⚙️: pistas verdaderas al principio, te traiciona en el momento clave |
| Soberbia | **Invicto**: nunca se va al mazo, quiere todo | **Desdén**: canta falta envido con cualquier mano | **Perfeccionista**: trampas sutiles con la duplicada; si lo pescás, se desmorona |

**Almas en pena:** Novato (juega casi al azar), Miedoso (se va al mazo fácil), Cantor (canta sin cartas), Mudo (nunca canta). Más adelante se pueden sumar más.

Combinaciones de rivales por run: 3⁶ × 4³ = **46.656**, sin contar cartas, tienda y trampas.

## 6. Estructura de la run

- **9 rondas**, un partido por ronda. Todas a 15 puntos salvo la Soberbia, a 30.
- Después de ganar cada partido: tienda. Después de cada pecado: tienda especial con amuletos raros y legendarios.
- Si después de la tienda no te alcanza para la entrada siguiente, morís.
- **Una mano más** (opcional, después de cobrar y antes de la tienda; no en la final): arriesgás una parte del premio que acabás de cobrar (25%, 50% o 100%) en una sola mano contra el mismo rival. Gana quien sume más puntos en esa mano; el empate es del rival. Si ganás, recuperás lo arriesgado por dos; si perdés, lo perdés, pero no morís.
- **El premio de la Soberbia es el premio del torneo: $10.000.000.** Las rondas 1 a 8 dan premios chicos que sirven para pagar entradas y comprar amuletos.
- **La deuda a pagar** es $10.000.000 (la deuda inicial del personaje) **+ el fiado acumulado + la deuda arrastrada de runs anteriores.**
- **Al ganarle a la Soberbia** se salda la cuenta con toda tu plata:
  - Si alcanza: volvés a la vida. Si sobra plata, aparece la tentación: **retirarte** (final bueno) o **seguir** (la avaricia, ver §11).
  - Si no alcanza: evento **"La cuenta"** con el dueño del bar. Primero vende tus amuletos a mitad de precio. Si todavía falta, te juega **una sola mano** por la diferencia: si ganás, quedás pagado; si perdés, morís y la diferencia pasa como deuda a la run siguiente.

## 7. Economía (ajustable)

### 7.1 Escalera base

Las entradas y los premios de las rondas 1 a 8 crecen de a poco (del orden de miles a cientos de miles) y siguen la curva en V: las almas en pena cuestan y pagan menos. Los números exactos se calibran con la simulación de economía y viven en `data/economy.json`.

Plata inicial: $135. Entrada de la ronda 1: $100.

### 7.2 Multiplicadores de premio

Se multiplican entre sí. Fuentes:
- **Amuletos** (por ejemplo, la Moneda aplastada).
- **Condiciones del partido:** ganar sin que el rival sume puntos ×2; ganar con al menos una trampa propia no detectada ×1,5.
- **Mazos** (por ejemplo, el de la Viuda ×2).

### 7.3 Tienda

- Aparece después de cada victoria. Muestra 3 ofertas.
- Cambiar las ofertas cuesta el 10% de la entrada siguiente, +5% por cada cambio en la misma tienda.
- Vender un amuleto devuelve el 50% de lo que costó.
- **2 espacios de amuletos.**
- Precio = porcentaje de la entrada siguiente: común 90%, raro 180%, legendario 360%.
- **Cada amuleto comprado en la run encarece los siguientes un 25%** (ajustable).
- Se paga con la misma plata de la run.
- **Mejorar un amuleto** (§8.1): una mejora por tienda.

### 7.3.1 La propina del bar

Al pagar cada entrada, el bar cobra además **el 10% de la plata que tengas por encima de 3 entradas** (ajustable). Ejemplo: entrada de 2.000 y 20.000 en el bolsillo: pagás 2.000 + 10% de (20.000 − 6.000) = 3.400. Con menos de 3 entradas no hay propina, así que nunca te deja sin poder entrar. Castiga juntar plata sin usarla: es la avaricia.

### 7.4 Fiado y deuda

- **Fiado:** si no te alcanza, podés comprar fiado hasta el doble de tu plata actual. El fiado siempre te deja reservada la entrada siguiente.
- **El fiado no se descuenta de los premios: se suma a la cuenta final** que pagás al ganarle a la Soberbia (§6).
- **Interés:** lo que debés de fiado crece un **10% por ronda** (ajustable), al pasar a la ronda siguiente.
- **Retención:** mientras debas fiado, el bar se queda con **el 25% de cada premio** (ajustable) y lo aplica al fiado. El premio de la Soberbia no tiene retención: el fiado que quede se cobra en la cuenta final.
- Vender un amuleto paga primero el fiado.
- Si morís, el fiado pendiente se suma a la **deuda arrastrada**, que sube la cuenta final de la run siguiente.
- Retirarse habiendo pagado la cuenta borra toda la deuda.
- **El dueño del bar** es quien cobra la cuenta. Como rival especial cuando la deuda arrastrada es enorme: Etapa 4.

### 7.5 Legado

Al morir elegís **1 amuleto** que pasa a la run siguiente.

### 7.6 Subir la apuesta (después del MVP)

Canto "¡me juego el doble!": una vez por partido; duplica el premio del partido y también lo que perdés si perdés.

## 8. Amuletos

P = pasivo. A = activo con cargas por partido (entre paréntesis).

| Amuleto | Categoría | Tipo | Rareza | Efecto |
|---|---|---|---|---|
| Marcador permanente | Cartas | A (1) | Raro | Le cambiás el número a una carta tuya por el resto del partido. Solo números válidos del mazo (1–7, 10–12). |
| Mazo aparte | Cartas | A (2) | Raro | Cambiás una carta tuya por otra al azar de un mazo de reserva. |
| Cigarrillo | Tanto | P | Común | Cuando mentís el tanto, el dealer pide mostrar la mitad de veces. |
| Vaso de caña | Tanto | A (1) | Raro | Tu próxima declaración del tanto no se verifica; el dealer sube su sospecha. |
| Rosario | Cantos | A (1) | Raro | Anulás el último canto del rival. |
| Facón | Cantos | A (1) | Raro | El rival está obligado a querer tu próximo canto. |
| Lentes | Información | P | Común | Al empezar cada mano ves el número (no el palo) de 1 carta del rival. |
| Sombrero | Información | A (1) | Legendario | Ves los números (no los palos) de todas las cartas del rival. |
| Espejo | Trampa | A (2) | Legendario | Ves la mano completa del rival. Riesgo de que te pesque. |
| Cartas marcadas | Trampa | A (3) | Raro | Sabés cuál es la carta más alta del rival. El riesgo crece con cada uso. |
| Cinta roja | Economía | P | Común | −20% en los precios de la tienda. |
| Moneda aplastada por el tren | Economía | P | Común | Premio ×1,5 si ganás el partido sin cantar envido. |

El Anillo del meñique queda como amuleto desbloqueable futuro.

### 8.1 Mejoras (niveles I a III)

- En la tienda, **una mejora por visita**. Nivel II: **1,5 ×** el precio base; nivel III: **2,5 ×** (ajustable). El precio sigue a la entrada siguiente y la Cinta roja lo descuenta. Mejorar no sube el contador del +25% (solo las compras lo suben).
- Vender devuelve el 50% de **todo** lo pagado (compra + mejoras). El legado vuelve a nivel I.

| Amuleto | I | II | III |
|---|---|---|---|
| Marcador permanente | 1 carga | 2 cargas | 2 cargas y también cambia el palo |
| Mazo aparte | 2 cargas | 3 cargas | 3 cargas y elegís entre 2 cartas de la reserva |
| Cigarrillo | piden mostrar 50% | 35% | 20% |
| Vaso de caña | 1 carga, sube la sospecha | 2 cargas | 2 cargas sin subir la sospecha |
| Rosario | 1 carga | 2 cargas | 3 cargas |
| Facón | 1 carga | 2 cargas | 2 cargas y también obliga a querer la subida |
| Lentes | número de 1 carta | número de 2 cartas | número y palo de 1 carta |
| Sombrero | 1 carga | 2 cargas | 2 cargas y además el palo de su carta más alta |
| Espejo | 2 cargas | 2 cargas, riesgo −30% | 3 cargas, riesgo −30% |
| Cartas marcadas | 3 cargas | 4 cargas, el riesgo sube más lento | 5 cargas |
| Cinta roja | −20% | −30% | −40% |
| Moneda aplastada | ×1,5 | ×1,75 | ×2 |

## 9. Mazos de condición

Se eligen al empezar la run. Cada uno da un beneficio y un costo.

| Mazo | Beneficio | Costo | MVP |
|---|---|---|---|
| Normal | — | — | Sí |
| De la viuda | Premio ×2 | El dealer tiene el doble de presupuesto de trampas | Sí |
| Gastado | Ves 1 carta del rival por mano | El rival ve 1 tuya | No |
| Con flor | Se juega con flor | El dealer también la tiene y miente con ella | No |
| Sin anchos | El envido vale el doble | No hay ancho de espada ni de basto | No |
| Del diablo | Empezás con $500 | Empezás con $1.000 de deuda | No |

## 10. Progresión entre runs

- **Logros** (por ejemplo, "le ganaste al Tramposo", "pescaste 3 trampas") agregan amuletos y mazos al pool.
- **Fichas** según cuántas rondas aguantaste. Su uso concreto se define en la Etapa 4.
- **Noches (niveles de dificultad, estilo Balatro):** retirarte desbloquea la noche siguiente, que suma una regla más dura a las anteriores. Dirección, con ejemplos ajustables: noche 2, propina del 15%; noche 3, las almas sin torpeza; noche 4, entradas +25%; noche 5, sin legado al morir; noche 6, interés del fiado al 20%; noche 7, la Soberbia a 30 con el doble de trampas; noche 8, la cuenta suma 10% de interés sobre la deuda arrastrada. Se implementa con la progresión entre runs (después del Plan 6).
- Pasan a la run siguiente: deuda, legado (1 amuleto), desbloqueos.

## 11. Post-game (Etapa 4, solo dirección)

- **Seguir después de pagar (la avaricia):** en el MVP es solo un final escrito (la condena eterna). En la Etapa 4 se vuelve jugable como **los círculos** (dirección elegida; se pueden explorar otras):
  - Un círculo son 7 rondas: los 6 pecados en **versión maldita**, en orden aleatorio, y al final **el Gualicho**, el dueño del bar.
  - Cada círculo suma una **maldición permanente** del Truco maldito; se acumulan.
  - Las almas en pena ya no son respiro: son las otras almas condenadas, sombras en las otras mesas.
  - No hay retiro: se juega hasta perder. Puntaje = círculos aguantados y plata juntada.
  - **Final verdadero escondido:** ganarle al Gualicho en el **séptimo círculo** rompe el hechizo del bar (la "segunda llave"). Qué pasa exactamente se define en la Etapa 3.
- **El Gualicho:** nombre del dueño del bar. Cobra "La cuenta" al final de la run normal (§6) y cierra cada círculo del post-game.
- **Truco maldito:** modo sin fin. Cartas que no existen (vuelven los 8 y 9, una carta sin palo), reglas que cambian en cada mano (por ejemplo, el envido se cuenta al revés), trampas sobrenaturales del dealer a plena vista.
- **Descartado:** jugar como dealer.

## 11.1 Ideas para más adelante (sin decidir)

- **Monedas en la mesa:** tirar una o dos monedas (o apuestas del folclore, sin salir de la mesa) para sumar puntos, anular un canto, ganar o perder plata. Por ejemplo, un amuleto o una regla de un pecado.
- **Un ayudante IA** que juegue por vos contrarrestando la IA del rival: como modo de práctica, o como amuleto que da consejos.

## 12. Alcance del MVP 2D (Etapa 1)

**Entra:** pantallas simples de bar, mesa y apuesta; Truco completo sin flor; mentira del tanto con verificación; 3 rivales con IA y pistas de texto; las 3 trampas del dealer con acusación; trampas del jugador por amuletos; tienda con los 12 amuletos; fiado, deuda, legado; economía completa hasta $10M; sistema de mazos con Normal y Viuda; muerte y reinicio.

**Queda afuera:** lore y pistas del purgatorio, sonido, animaciones, doble o nada, segunda llave, logros y fichas, subir la apuesta, el acreedor como rival.

## 13. Arquitectura técnica

- **Motor:** Godot 4 (última versión estable 4.x), GDScript.
- **Núcleo puro:** toda la lógica (Truco, IA, economía, run) en clases `RefCounted` sin nodos ni escenas, en `core/`. No conoce la pantalla.
- **Presentación:** escenas en `ui/` que mandan acciones al núcleo y reciben una lista de eventos. Pasar a 3D es reemplazar `ui/` sin tocar `core/`.
- **Datos:** amuletos, rivales, mazos y economía en archivos JSON en `data/`, editables sin tocar código.
- **Azar:** todo sale de un `RandomNumberGenerator` con semilla guardada en la run. Una semilla reproduce una partida exacta.
- **Tests:** GUT (Godot Unit Test), corriendo sin pantalla.
- **Textos:** todo texto visible pasa por claves traducibles desde el día uno (español rioplatense primero, inglés después).
- **Plataforma:** PC (Steam).
