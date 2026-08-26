shader_type canvas_item;


void vertex() {
	vec2 normalized_vertex =
		VERTEX * TEXTURE_PIXEL_SIZE;

	VERTEX = vec2(
		normalized_vertex.x * INSTANCE_CUSTOM.x,
		normalized_vertex.y * INSTANCE_CUSTOM.y
	);
}


void fragment() {
	COLOR = vec4(1.0);
}