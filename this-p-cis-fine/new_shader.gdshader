shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 5.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 block_size = TEXTURE_PIXEL_SIZE * pixel_size;
	vec2 pixel_uv = (floor(UV / block_size) + 0.5) * block_size;
	COLOR = texture(TEXTURE, pixel_uv);
}
