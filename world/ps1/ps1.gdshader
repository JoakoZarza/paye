shader_type spatial;
// Material PS1: vértices que se pegan a una grilla de pantalla (tiemblan al
// moverse), texturas sin filtro y deformación afín como en la PlayStation.

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0);
uniform bool has_texture = false;
// Resolución de la grilla a la que se pegan los vértices.
uniform vec2 snap_resolution = vec2(320.0, 180.0);
// 0 = texturas correctas, 1 = deformación afín completa.
uniform float affine_strength : hint_range(0.0, 1.0) = 0.6;

varying vec3 affine_uv;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid = snap_resolution * 0.5;
	clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	POSITION = clip;
	affine_uv = vec3(UV * clip.w, clip.w);
}

void fragment() {
	vec2 uv = mix(UV, affine_uv.xy / affine_uv.z, affine_strength);
	vec4 color = albedo;
	if (has_texture) {
		color *= texture(albedo_texture, uv);
	}
	ALBEDO = color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
