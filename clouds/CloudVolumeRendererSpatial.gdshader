shader_type spatial;
render_mode unshaded;

const int sampleChecks = 10;
// const float stepSize = 0.01;

uniform sampler3D noise_texture : hint_black_albedo;
uniform vec3 boundMin;
uniform vec3 boundMax;

vec2 rayBoxDst(vec3 rayOrigin, vec3 rayDir) {
	vec3 t0 = (boundMin - rayOrigin) / rayDir;
	vec3 t1 = (boundMax - rayOrigin) / rayDir;
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);

	float dstA = max(max(tmin.x, tmin.y), tmin.z);
	float dstB = min(tmax.x, min(tmax.y, tmax.z));

	// 1: (0 <= dstA <= dstB) intersect from outside
	// 2: (dstA <= 0 <= dstB) intersect from inside
	// 3: (dstA > dstB) ray misses

	float dstToBox = max(0, dstA);
	float dstToInsideBox = max(0, dstB - dstToBox);

	return vec2(dstToBox, dstToInsideBox);
}

float sampleDensity (vec3 position) {
	return 0.5;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Get linear depth from depth texture
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0; // Normalized Device Coordinates
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0); // Depth needs to be linearized by multiplying by inverse projection matrix
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = CAMERA_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	// Get world coordinates for fragment direction
	vec3 cameraPos = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 fragDir = normalize(world_position - cameraPos);

	// Apply raymarching
	vec2 rayBoxInfo = rayBoxDst(cameraPos, fragDir);
	float dstToBox = rayBoxInfo.x;
	float dstToInsideBox = rayBoxInfo.y;
	bool rayHitBox = dstToInsideBox > 0.0 && dstToBox < linear_depth;
	if (rayHitBox) {	
		// color.rgb = vec3(1.0, 0.0, 0.0);

		//
		float totalDensity = 0.0;
		float stepSize = dstToInsideBox / float(sampleChecks);

		for (int i; i < sampleChecks; i++) {
			vec3 currentPosition = cameraPos + fragDir * (float(i) * stepSize);
			totalDensity += sampleDensity(currentPosition) * stepSize;
		}

		color = vec4(vec3(1.0, 0.0, 0.0), totalDensity);
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
