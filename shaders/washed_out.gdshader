shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float saturation : hint_range(0.0, 1.0) = 0.2;
uniform float contrast : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec3 original = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	float luminance = dot(original, vec3(0.2126, 0.7152, 0.0722));
	vec3 faded = mix(vec3(luminance), original, saturation);
	faded = (faded - vec3(0.5)) * contrast + vec3(0.5);
	COLOR = vec4(faded, 1.0);
}
