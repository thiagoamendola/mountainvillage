shader_type canvas_item;

uniform int texture_size;

uniform sampler2D r_seamless_points_tex;
uniform int r_sector_size;
uniform float r_intensity_multiplier;
uniform float r_opacity;

uniform sampler2D g_seamless_points_tex;
uniform int g_sector_size;
uniform float g_intensity_multiplier;
uniform float g_opacity;

// Given a vector for pixel position and other for point position, gets the distance
// and returns if it's smaller than the previous provided value.
float get_closest_dist(float prev_dist, ivec2 pixel_pos, ivec2 point_pos)
{
	float cur_dist = distance(vec2(pixel_pos), vec2(point_pos));
	return min(prev_dist, cur_dist);
}

vec4 get_color_for_channel_tex(sampler2D seamless_points_tex, int sector_size, float intensity_multiplier, vec2 uv)
{
	// Test for texelFetch
	ivec2 seamless_points_tex_size = textureSize(seamless_points_tex,0);
	// ivec2 r_seamless_points_tex_pos = ivec2(vec2(seamless_points_tex_size)*uv);

	// Find out which sector we're in.
	ivec2 pixel_pos = ivec2(uv * vec2(float(texture_size)));
	ivec2 cur_sector = ivec2(vec2(pixel_pos) / float(sector_size));

	// Iterate through nearby sectors and grab the minimum distance.
	float min_dist = 1./0.;
	for (int j = -1; j < 2; j++){
		for (int i = -1; i < 2; i++){ 
			ivec2 iter_sector = cur_sector + ivec2(i,j);
			vec2 it_sector_pt_pos_raw = texelFetch(seamless_points_tex, iter_sector + ivec2(1), 0).rg;
			ivec2 it_sector_pt_pos = ivec2((it_sector_pt_pos_raw + vec2(iter_sector)) * vec2(float(sector_size)));
			min_dist = get_closest_dist(min_dist, pixel_pos, it_sector_pt_pos);
		}
	}

	// Get the current color based in the smallest distance found to a point.
	vec4 r_color = vec4(vec3(1.0) * clamp(intensity_multiplier * min_dist / float(sector_size), 0.0, 1.0), 1.0);

	// Invert color.
	return vec4(vec3(1.0) - r_color.rgb, 1.0);
}

void fragment(){
	vec4 color;

	// Calculate texture for R layer.
	vec4 r_color = get_color_for_channel_tex(r_seamless_points_tex, r_sector_size, r_intensity_multiplier, UV);
	// Calculate texture for G layer.
	vec4 g_color = get_color_for_channel_tex(g_seamless_points_tex, g_sector_size, g_intensity_multiplier, UV);

	color = vec4(r_color.rgb * r_opacity + g_color.rgb * g_opacity, 1.0);
	COLOR = color;
}
