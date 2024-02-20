shader_type spatial;
render_mode unshaded;

const int sampleChecks = 10;
// const float stepSize = 0.01;

uniform sampler3D noise_texture : hint_black_albedo;
uniform vec3 bound_min;
uniform vec3 bound_max;

// DEBUG SETTINGS
uniform bool slice_mode;
uniform float slice;

// Returns a tuple with: distance to hit box and distance to leave box.
vec2 rayBoxDst(vec3 rayOrigin, vec3 rayDir, vec3 boundMin, vec3 boundMax) {
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

// Read 3D texture and retrieve density data for current voxel
float sampleDensity (vec3 position) {
	float cloudScale = 1.0;
	float cloudOffset = 0.0;
	float densityThreshold = 0.6;
	float densityMultiplier = 5.0;
	vec3 uvw = position + cloudScale * 10.0 + cloudOffset;
	float textureValue = texture(noise_texture, uvw).r;
	float density = max(0, textureValue - densityThreshold) * densityMultiplier; 
	return density;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Get linear depth from depth texture
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	// Normalized Device Coordinates
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	// Depth needs to be linearized by multiplying by inverse projection matrix
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0); 
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = CAMERA_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	// Get world coordinates for fragment direction
	vec3 cameraPos = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 fragDir = normalize(world_position - cameraPos);

	if (!slice_mode) {
		// DEFAULT MODE
		// Apply raymarching
		vec2 rayBoxInfo = rayBoxDst(cameraPos, fragDir, bound_min, bound_max);
		float dstToBox = rayBoxInfo.x;
		float dstToInsideBox = rayBoxInfo.y;
		bool didRayHitBox = dstToInsideBox > 0.0 && dstToBox < linear_depth;
		if (didRayHitBox) {	
			color.rgb = vec3(0.0, 0.0, 0.0);

			float totalDensity = 0.0;
			float stepSize = dstToInsideBox / float(sampleChecks);

			for (int i; i < sampleChecks; i++) {
				vec3 currentPosition = cameraPos + fragDir * (float(i) * stepSize);
				totalDensity += sampleDensity(currentPosition) * stepSize;
			}

			float transmittance = exp(-totalDensity);

			color = vec4(vec3(1.0, 0.0, 0.0), 1.0 - transmittance);
		}
	} else {
		// SLICE MODE
		// Apply raymarching for just a slice of the cube's base
		vec3 sliceVec = vec3(bound_max.x, bound_min.y + 0.01, bound_max.z); 
		vec2 rayBoxInfo = rayBoxDst(cameraPos, fragDir, bound_min, sliceVec);
		float dstToBox = rayBoxInfo.x;
		float dstToInsideBox = rayBoxInfo.y;
		bool didRayHitBox = dstToInsideBox > 0.0 && dstToBox < linear_depth;
		if (didRayHitBox) {
			// What do I need to do?
			// > Get the real world position of the first box voxel I get
			// > Convert that voxel into an XZ coordinate ignoring Y (so we can sort of print a 2D texture in the 3D volume)
			// > Use that ZX coordinate to read the texture's first slice XY

			// Get the position of the hit voxel
			// vec3 voxelPosition = cameraPos + fragDir * dstToBox; // SEEMS TO BE WRONG
			// t = realDstToBox
			// t = (P0 * N + d) / (V * N)
			// t = (cameraPos * world.up + d) / (fragDir * world.up)

			// Forget change of coordinate for now. Box is align with global coordinate 
			// vec2 voxelPosInSlice = vec2(((bound_max.z - bound_min.z) / (voxelPosition.z - bound_min.z)), ((bound_max.x - bound_min.x) / (voxelPosition.x - bound_min.x)));
			// voxelPosInSlice.xy *= vec2(bound_max.z - bound_min.z, bound_max.x - bound_min.x);

			// CONCLUSION: I can't trust in my voxelPosition. Needing to fix the perspective issue first

//			color = vec4(vec3(1.0, 0.0, 0.0), 1.0*voxelPosInSlice.x);
		}
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
