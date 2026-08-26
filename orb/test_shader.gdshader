shader_type canvas_item;

varying vec2 capsule_size;


void vertex() {
	capsule_size = INSTANCE_CUSTOM.xy;

	VERTEX.x *= capsule_size.x;
	VERTEX.y *= capsule_size.y;
}


void fragment() {
	float capsule_length = capsule_size.x;
	float capsule_width = capsule_size.y;

	vec2 p = (UV - vec2(0.5)) * vec2(
		capsule_length,
		capsule_width
	);

	float radius = capsule_width * 0.5;

	float half_segment = max(
		(capsule_length - capsule_width) * 0.5,
		0.0
	);

	vec2 closest = vec2(
		clamp(p.x, -half_segment, half_segment),
		0.0
	);

	float distance_to_capsule =
		length(p - closest) - radius;

	float aa = fwidth(distance_to_capsule);

	float alpha = 1.0 - smoothstep(
		-aa,
		aa,
		distance_to_capsule
	);

	COLOR = vec4(
		1.0,
		1.0,
		1.0,
		alpha
	);
}