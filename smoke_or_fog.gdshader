shader_type canvas_item;

// License: CC0
// Author: Ultipuk, https://ultipuk.xyz
// Source: https://godotshaders.com/shader/smoke-or-fog
// Based on "Wind of change" by FatumR: https://www.shadertoy.com/view/ldBSDd

uniform int octaves: hint_range(0, 16) = 4;
uniform sampler2D color_gradient: hint_default_white;
uniform float speed_1: hint_range(0.0, 4.0) = 0.4;
uniform float speed_2: hint_range(0.0, 4.0) = 0.15;
uniform float smoke_persistance: hint_range(0.0, 8.0) = 2.5;
uniform float smoke_amplitude: hint_range(0.0, 4.0) = 0.55;
uniform float smoke_starting_offset: hint_range(0.0, 2.0) = 0.02;

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float rand2(vec2 co) {
	return fract(cos(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise_simple(vec2 vl) {
	float min_step = 1.0;

	vec2 grid = floor(vl);
	vec2 grid_pnt_1 = grid;
	vec2 grid_pnt_2 = vec2(grid.x, grid.y + min_step);
	vec2 grid_pnt_3 = vec2(grid.x + min_step, grid.y);
	vec2 grid_pnt_4 = vec2(grid_pnt_3.x, grid_pnt_2.y);

	float s = rand2(grid);
	float t = rand2(grid_pnt_3);
	float u = rand2(grid_pnt_2);
	float v = rand2(grid_pnt_4);

	float x1 = smoothstep(0.0, 1.0, fract(vl.x));
	float interp_x1 = mix(s, t, x1);
	float interp_x2 = mix(u, v, x1);
	float y = smoothstep(0.0, 1.0, fract(vl.y));

	return mix(interp_x1, interp_x2, y);
}

float fractal_noise(vec2 vl) {
	float amplitude = smoke_amplitude;
	float result = smoke_starting_offset;
	vec2 p = vl;

	for (int i = 0; i < octaves; i++) {
		result += amplitude * value_noise_simple(p);
		amplitude /= smoke_persistance;
		p *= smoke_persistance;
	}

	return result;
}

float complex_fbm(vec2 p) {
	float slow = TIME * speed_1;
	float fast = TIME * speed_2;
	vec2 offset_1 = vec2(slow, 0.0);
	vec2 offset_2 = vec2(sin(fast) * 0.1, 0.0);

	return fractal_noise(
		p + offset_1 + fractal_noise(
			p + fractal_noise(
				p + 2.0 * fractal_noise(
					p - offset_2
				)
			)
		)
	);
}

void fragment() {
	float fbm = complex_fbm(UV);
	COLOR = texture(color_gradient, vec2(fbm));
}
