shader_type canvas_item;

uniform float sector_size;
uniform sampler2D seamless_points_tex : hint_black;
uniform vec4 test;

// Given a vector for pixel position and other for point position, gets the distance
// and returns if it's smaller than the previous provided value.
float get_closest_dist(float prev_dist, ivec2 pixel_pos, ivec2 point_pos){
	float cur_dist = distance(vec2(pixel_pos), vec2(point_pos));
	return min(prev_dist, cur_dist);
}

void fragment(){
	// vec4 color = texture(TEXTURE, UV);
	vec4 color;

	// Test for texelFetch
	ivec2 seamless_points_tex_size = textureSize(seamless_points_tex,0);
	ivec2 seamless_points_tex_pos = ivec2(vec2(seamless_points_tex_size)*UV);
	// color = texelFetch(seamless_points_tex, seamless_points_tex_pos, 0);

	// Find out which sector we're in.
	ivec2 pixel_pos = ivec2(UV * vec2(500.0)); //<-- Remove magic number
	ivec2 cur_sector = ivec2(vec2(pixel_pos) / sector_size);

	float min_dist = 1./0.;
	for (int j = -1; j < 2; j++){
		for (int i = -1; i < 2; i++){ 
			ivec2 iter_sector = cur_sector + ivec2(i,j);
			vec2 it_sector_pt_pos_raw = texelFetch(seamless_points_tex, iter_sector + ivec2(1), 0).rg;
			ivec2 it_sector_pt_pos = ivec2((it_sector_pt_pos_raw + vec2(iter_sector)) * vec2(sector_size));
			min_dist = get_closest_dist(min_dist, pixel_pos, it_sector_pt_pos);
		}
	}

	// Get the current color based in the smallest distance found to a point.
	color = vec4(vec3(1.0) * clamp(min_dist / sector_size, 0.0, 1.0), 1.0); //<-- Add a variable here to control intensity.

	// Invert color.
	color = vec4(vec3(1.0) - color.rgb, 1.0);

	COLOR = color;
}
