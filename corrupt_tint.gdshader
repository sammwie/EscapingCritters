shader_type canvas_item;
// Per-character corruption look from the GDD: colors partly invert and
// desaturate on their own, separate from the level-wide glitch overlay.
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float flicker_speed = 7.0;

void fragment() {
	vec4 c = COLOR; // texture * modulate
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 inv = vec3(1.0) - c.rgb;
	vec3 corrupt = mix(vec3(g), inv, 0.45) * vec3(1.2, 0.72, 0.78);
	float f = step(0.955, fract(sin(floor(TIME * flicker_speed) * 43758.5453)));
	corrupt = mix(corrupt, inv, f * 0.85);
	COLOR = vec4(mix(c.rgb, corrupt, amount), c.a);
}
