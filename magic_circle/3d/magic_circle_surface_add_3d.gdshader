shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, fog_disabled, depth_draw_never;

uniform sampler2D viewport_texture : filter_linear, repeat_disable;
uniform float intensity : hint_range(0.0, 8.0, 0.05) = 1.0;
uniform float blend_balance : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0;


void fragment() {
	vec4 viewport_color = texture(viewport_texture, UV);
	ALBEDO = viewport_color.rgb * intensity * (1.0 - blend_balance);
	ALPHA = viewport_color.a * opacity;
}
