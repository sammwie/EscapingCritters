shader_type canvas_item;
// Level-wide visual corruption from the GDD: the town loses resolution and its
// colors drift. Sits on a CanvasLayer just above the world, so the task list,
// dialogue box and pop-ups stay sharp.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0) = 1.0;     // screen pixels per block
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform vec3 grade = vec3(1.0, 1.0, 1.0);                   // color multiplier
uniform float color_levels : hint_range(2.0, 256.0) = 256.0; // posterize

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 uv = (floor(SCREEN_UV / px) + 0.5) * px;
	vec3 c = texture(screen_texture, uv).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(g), desaturate) * grade;
	c = floor(c * color_levels) / color_levels;
	COLOR = vec4(c, 1.0);
}
