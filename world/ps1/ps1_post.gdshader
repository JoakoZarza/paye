shader_type canvas_item;
// Pasada final sobre el mundo a baja resolución: pocos colores por canal con
// tramado ordenado (dithering), como la salida de video de la PlayStation.

uniform float color_levels = 24.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.8;

const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 5.0));

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	ivec2 cell = ivec2(mod(floor(UV / TEXTURE_PIXEL_SIZE), 4.0));
	float threshold = (BAYER[cell.x][cell.y] + 0.5) / 16.0 - 0.5;
	vec3 c = color.rgb + threshold * dither_strength / color_levels;
	COLOR = vec4(floor(c * color_levels + 0.5) / color_levels, color.a);
}
