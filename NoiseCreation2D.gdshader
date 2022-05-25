shader_type spatial;

uniform float sector_size;
uniform vec2 seamless_points[2];



void fragment(){
//	vec4 color = texture(SCREEN_TEXTURE,SCREEN_UV);

	vec4 color = get_closest_point(color);
	COLOR = color;
}
