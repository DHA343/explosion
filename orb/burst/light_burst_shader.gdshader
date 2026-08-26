shader_type canvas_item;

group_uniforms Appearance;
uniform vec4 particle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_softness : hint_range(0.0, 20.0, 0.1) = 1.0;

group_uniforms;

varying vec3 shape_data;


void vertex() {
	shape_data = INSTANCE_CUSTOM.xyz;

	float quad_length = shape_data.x;
	float tail_width = shape_data.y;
	float head_width = shape_data.z;

	float max_width = max(
		max(tail_width, head_width),
		0.0001
	);

	VERTEX.x *= max(quad_length, 0.0001);
	VERTEX.y *= max_width;
}


void fragment() {
	float quad_length = max(shape_data.x, 0.0001);
	float tail_width = max(shape_data.y, 0.0001);
	float head_width = max(shape_data.z, 0.0001);

	float tail_radius = tail_width * 0.5;
	float head_radius = head_width * 0.5;

	float max_width = max(
		tail_width,
		head_width
	);

	vec2 p = (
		UV - vec2(0.5)
	) * vec2(
		quad_length,
		max_width
	);

	float segment_length = max(
		quad_length
		- tail_radius
		- head_radius,
		0.0
	);

	float tail_center_x =
		-quad_length * 0.5
		+ tail_radius;

	float head_center_x =
		quad_length * 0.5
		- head_radius;

	float distance_to_shape;

	if (segment_length < 0.0001) {
		float center_x =
			(tail_center_x + head_center_x)
			* 0.5;

		float radius_value = max(
			tail_radius,
			head_radius
		);

		distance_to_shape =
			length(
				p - vec2(center_x, 0.0)
			)
			- radius_value;
	} else if (p.x < tail_center_x) {
		distance_to_shape =
			length(
				p - vec2(tail_center_x, 0.0)
			)
			- tail_radius;
	} else if (p.x > head_center_x) {
		distance_to_shape =
			length(
				p - vec2(head_center_x, 0.0)
			)
			- head_radius;
	} else {
		float body_t = clamp(
			(p.x - tail_center_x)
			/ segment_length,
			0.0,
			1.0
		);

		float body_radius = mix(
			tail_radius,
			head_radius,
			body_t
		);

		distance_to_shape =
			abs(p.y)
			- body_radius;
	}

	float aa = fwidth(distance_to_shape);
	float softness = max(
		aa,
		edge_softness
	);

	float alpha = 1.0 - smoothstep(
		-softness,
		softness,
		distance_to_shape
	);

	COLOR = vec4(
		particle_color.rgb,
		particle_color.a * alpha
	);
}
