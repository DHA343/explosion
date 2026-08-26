shader_type canvas_item;


void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float grad_u = length(vec2(
		dFdx(UV.x),
		dFdy(UV.x)
	));

	float grad_v = length(vec2(
		dFdx(UV.y),
		dFdy(UV.y)
	));

	float cap_length = 0.5 * grad_v / max(grad_u, 0.000001);

	float cap_mask = 1.0;

	// UV.y = 0 側
	if (UV.y < cap_length) {
		float x = (UV.x - 0.5) * 2.0;
		float y = (cap_length - UV.y) / max(cap_length, 0.000001);

		float d = length(vec2(x, y));
		float aa = fwidth(d);

		cap_mask *= 1.0 - smoothstep(
			1.0 - aa,
			1.0 + aa,
			d
		);
	}

	// UV.y = 1 側
	if (UV.y > 1.0 - cap_length) {
		float x = (UV.x - 0.5) * 2.0;
		float y = (
			UV.y - (1.0 - cap_length)
		) / max(cap_length, 0.000001);

		float d = length(vec2(x, y));
		float aa = fwidth(d);

		cap_mask *= 1.0 - smoothstep(
			1.0 - aa,
			1.0 + aa,
			d
		);
	}

	COLOR *= tex;
	COLOR.a *= cap_mask;
}