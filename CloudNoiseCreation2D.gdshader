shader_type canvas_item;

uniform float sector_size;
//uniform sampler2d seamless_points_tex;
uniform vec4 test;

//// 
//float get_closest_dist(prev_dist, pixel_pos, point_pos){
//  float cur_dist = length(pixel_pos, point_pos)
//  return min(prev_dist, cur_dist)
//}

void fragment(){
//	vec4 color = texture(SCREEN_TEXTURE,SCREEN_UV);

	// vec4 color = get_closest_point(color);
	COLOR = test;
}
