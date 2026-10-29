# Payé — Documento de diseño

Versión 1 · 2026-10-29 · Fuente de verdad del diseño. Si el código y este documento no coinciden, se corrige uno de los dos a propósito, nunca en silencio.

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
- **Final malo / segunda llave:** elegís doble o nada → quedás atrapado → se abre el **Truco maldito** (modo sin fin, ver §11).

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

El rival suma lo que vale el truco en ese momento (1 si no se cantó; si hay un canto de truco pendiente, lo de "no querido").

### 3.8 Partido

- Objetivo: **15 puntos** para rivales comunes, **30 puntos** para jefes.
- El mano se alterna en cada mano. En la primera mano del partido el mano se sortea con la semilla de la run.
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

### 5.4 Rivales del MVP (ajustable)

| Rival | Agresividad | Mentira | Trampa | Terquedad | Confiabilidad de pistas | Presupuesto de trampas |
|---|---|---|---|---|---|---|
| Agresivo | 0,85 | 0,30 | 0,15 | 0,60 | 0,80 | 1 |
| Mentiroso | 0,50 | 0,85 | 0,25 | 0,40 | 0,40 | 1 |
| Tramposo | 0,45 | 0,40 | 0,85 | 0,50 | 0,65 | 3 |

Los rivales escalan con la ronda subiendo sus rasgos y sus presupuestos. Nombres y apariencia quedan para la Etapa 3 ("Pichado" es candidato a nombre de un rival que entra en tilt).

## 6. Estructura de la run

- Rondas 1 a 12. Cada ronda es un partido contra un rival. Jefes en las rondas 4, 8 y 12, a 30 puntos; el resto, a 15.
- Después de ganar cada partido: tienda. Después de cada jefe: tienda especial con amuletos raros y legendarios.
- Si después de la tienda no te alcanza para la entrada siguiente, morís.
- Al terminar un partido con $10.000.000 o más, aparece la opción de retirarse (final bueno) o doble o nada (Etapa 4).

## 7. Economía (ajustable)

### 7.1 Escalera base

Entrada inicial $100, multiplicada ×3 por ronda. El premio es la entrada por un factor que baja con las rondas.

| Ronda | Entrada | Factor de premio | Premio base |
|---|---|---|---|
| 1 | 100 | 6 | 600 |
| 2 | 300 | 5,5 | 1.650 |
| 3 | 900 | 5 | 4.500 |
| 4 (jefe) | 2.700 | 5 | 13.500 |
| 5 | 8.100 | 4,5 | 36.450 |
| 6 | 24.300 | 4 | 97.200 |
| 7 | 72.900 | 4 | 291.600 |
| 8 (jefe) | 218.700 | 4 | 874.800 |
| 9 | 656.100 | 3,5 | 2.296.350 |
| 10 | 1.968.300 | 3,5 | 6.889.050 |
| 11 | 5.904.900 | 3,5 | 20.667.150 |
| 12 (jefe) | 17.714.700 | 3,5 | 62.001.450 |

Plata inicial: $135. Objetivo de diseño: la escalera base sola, gastando lo mínimo en la tienda, no alcanza los $10M de forma confiable. Los multiplicadores de premio hacen la diferencia.

### 7.2 Multiplicadores de premio

Se multiplican entre sí. Fuentes:
- **Amuletos** (por ejemplo, la Moneda aplastada).
- **Condiciones del partido:** ganar sin que el rival sume puntos ×2; ganar con al menos una trampa propia no detectada ×1,5.
- **Mazos** (por ejemplo, el de la Viuda ×2).

### 7.3 Tienda

- Aparece después de cada victoria. Muestra 3 ofertas.
- Cambiar las ofertas cuesta el 10% de la entrada siguiente, +5% por cada cambio en la misma tienda.
- Vender un amuleto devuelve el 50% de lo que costó.
- 4 espacios de amuletos.
- Precio = porcentaje de la entrada siguiente: común 30%, raro 60%, legendario 120%.
- Se paga con la misma plata de la run.

### 7.4 Fiado y deuda

- **Fiado:** si no te alcanza, podés comprar fiado hasta el doble de tu plata actual.
- Si sobrevivís, el fiado se descuenta de tu premio antes de entrar al partido siguiente.
- Si morís, el fiado pendiente se suma a la **deuda**, que pasa a la run siguiente.
- **Cobro en la run siguiente:** el acreedor descuenta el 50% de cada premio hasta cubrir la deuda.
- **Sin tope de deuda**, pero si supera **$50.000** (ajustable) aparece **el acreedor** como rival especial antes de la ronda 1. Si le ganás, se borra la deuda; si perdés, la run termina.

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
- Pasan a la run siguiente: deuda, legado (1 amuleto), desbloqueos.

## 11. Post-game (Etapa 4, solo dirección)

- **Doble o nada:** se ofrece al llegar a $10M. Sus reglas exactas se definen en la Etapa 4.
- **Truco maldito:** modo sin fin. Cartas que no existen (vuelven los 8 y 9, una carta sin palo), reglas que cambian en cada mano (por ejemplo, el envido se cuenta al revés), trampas sobrenaturales del dealer a plena vista.
- **Descartado:** jugar como dealer.

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
