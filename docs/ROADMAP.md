# Payé — Hoja de ruta

Diseño completo en [DISENO.md](DISENO.md). Cada plan es un documento aparte en `docs/plans/` y produce algo que funciona y se puede probar por sí solo. Un plan se escribe recién cuando el anterior está terminado, para que arranque de código real y no de suposiciones.

## Quién hace qué

| Quién | Hace | No hace |
|---|---|---|
| **Joako** | Instala Godot, juega cada entrega, decide cambios de diseño, aprueba cada plan | No escribe código |
| **Claude (Pro)** | Diseño, planes, especificación de cada tarea, núcleo del Truco, IA del dealer, economía, revisión de todo lo que entregan las otras IAs | Pantallas y código repetitivo |
| **Codex** (codex-plugin-cc, ChatGPT Free) | Tareas medianas de los planes con interfaces ya definidas; segunda revisión | Decisiones de diseño |
| **Gemini CLI / Qwen Code** | Escenas y pantallas 2D, conexión de botones, carga de JSON | Lógica del núcleo |

Cada tarea de cada plan dice quién la ejecuta. Ninguna entrega se da por buena sin que pasen sus tests y sin revisión de Claude.

## Etapa 0 — Preparación (Joako, con guía)

- [x] Instalar Godot 4.7.2 (winget) y crear la variable de usuario `GODOT` con la ruta del ejecutable de consola.
- [x] Node 24 ya instalado; Codex CLI 0.165.0 y plugin `codex@openai-codex` instalados.
- [x] Gemini CLI 0.66.0 instalado.
- [x] Iniciar sesión en Codex (`codex login`) y correr `/codex:setup`.
- [ ] Gemini CLI: el inicio de sesión falló (el plan gratis pasó a Antigravity CLI). Se resuelve en el Plan 6.
- [ ] Crear el repositorio privado `JoakoZarza/paye` en GitHub y conectarlo (lo hacemos juntos cuando llegue el momento).

## Etapa 1 — MVP 2D

| Plan | Contenido | Ejecuta | Se prueba con |
|---|---|---|---|
| 1. Núcleo del Truco ✅ | Proyecto Godot, GUT, cartas, tanto, cantos, bazas, mano, partido | Claude + Codex | Tests y simulación de 10.000 manos al azar |
| 2. IA del dealer ✅ | Rasgos, humor, puntajes, mentira del tanto, pistas, 3 rivales | Claude | Partidos IA contra IA; estadísticas de faroles por rival |
| 3. Trampas ✅ | Trampas del dealer, acusación, trampas del jugador, sospecha | Claude + Codex | Tests: toda trampa deja evidencia |
| 4. Amuletos y mazos ✅ | Sistema de modificadores, 12 amuletos, mazos Normal y Viuda | Codex, revisa Claude | Tests por amuleto |
| 5. Run y economía ✅ (con 5b y 5c) | Rondas, entrada y premio, multiplicadores, tienda, fiado, deuda, legado, muerte; diseño v2 (9 rondas con pecados y almas, la cuenta del Gualicho); economía más dura (propina, interés y retención del fiado, mejoras de amuletos, una mano más) | Claude + Codex | Simulación de miles de runs y runs completas con IA |
| 6. Pantallas 2D | Bar, mesa, apuesta, partido, acusación, tienda, muerte, final | Gemini/Qwen, revisa Claude | Joako juega runs completas |

**Fin de la Etapa 1:** Joako juega runs completas en 2D, de la entrada al bar a los $10M o a la muerte.

**Para calibrar jugando en el Plan 6:** la ventaja humana (pistas y acusaciones), lo que suma cada amuleto y si se nota la curva en V de las almas. La simulación solo puede estimarlos.

## Etapa 2 — Port 3D con modelos básicos

Reemplazar `ui/` por escenas 3D simples (mesa, lámpara, rival, cartas) que consumen los mismos eventos del núcleo. `core/` no cambia. Se planifica al terminar la Etapa 1.

## Etapa 3 — Estética y lore

Estilo PS1 (texturas sucias de baja resolución, niebla, pocos polígonos), menú, animaciones, sonido, nombres y apariencia de los rivales, frases, pistas del purgatorio, finales. Se planifica al terminar la Etapa 2.

## Etapa 4 — Post-game y contenido

Los círculos (la avaricia) y el Gualicho, Truco maldito, Noches (niveles de dificultad), logros y fichas, mazos restantes, subir la apuesta, más rivales y amuletos, inglés.
