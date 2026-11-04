# Assets 3D

Guardá los modelos `.glb` en `models/`, las cartas PNG en `cards/` y otras texturas en `textures/`. Los nombres, medidas, prioridades, límites y el estilo de texturas están en `docs/ASSETS.md` (límites también en `world/asset_budget.json`).

Al importar cartas y texturas, elegí filtro **Nearest** y desactivá mipmaps. Para modelos glTF, desactivá la importación de luces y cámaras. Godot guarda estas opciones en el archivo `.import` de cada recurso; revisalas al incorporar cada archivo nuevo. El test `tests/world/test_assets_budget.gd` revisa triángulos, dimensiones, apoyo y tamaño de las imágenes de cartas.
