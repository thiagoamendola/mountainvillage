shader_type canvas_item;
render_mode unshaded;

uniform sampler3D noise_texture : hint_black_albedo;
uniform vec3 boundMin;
uniform vec3 boundMax;

uniform vec3 cameraPos;
uniform vec3 cameraDirZ;
uniform vec3 cameraDirX;
uniform vec3 cameraDirY;


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

bool insideBox(vec3 target) {
	vec3 bMin = min(boundMin, boundMax);
	vec3 bMax = max(boundMin, boundMax);
	return (target.x > bMin.x && target.x < bMax.x) &&
			(target.y > bMin.y && target.y < bMax.y) &&
			(target.z > bMin.z && target.z < bMax.z);
}

float sampleDensity (vec3 position) {
	return 1.0;
}

// REMOVE?
vec3 getDirection(vec3 rO, vec3 lk, vec2 uv, float z) {
	vec3 f = normalize(lk - rO);
	vec3 r = cross(vec3(0., 1., 0.), f);
	vec3 u = cross(f, r);
	vec3 c = rO + f * z;
	return (c + uv.x * r + uv.y * u) - rO; 
}


void vertex() {

}


// THIS PROB DOESN'T WORK FOR GODOT. MAYBE THE PERSPECTIVE CALC IS DONE DIFFERENTLY? 
/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * fragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
	vec2 xy = fragCoord - size / 2.0;
	float z = size.y / tan(radians(fieldOfView) / 1.5);
	return normalize(vec3(xy, -z));
}

void fragment() {
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgba;

	// Get world coordinates for fragment direction
	vec2 imageRes = 1.0 / SCREEN_PIXEL_SIZE.xy;
	vec3 fragRayDirRaw = rayDirection(90.0, imageRes, FRAGCOORD.xy);
	// color.rgb = vec3(abs(fragRayDir.xy), 0.0); // Useful to see the ray direction diff. SEEMS PARTIALLY WRONG
	mat3 cameraToWorldMatrix;
	cameraToWorldMatrix[0] = cameraDirX;
	cameraToWorldMatrix[1] = cameraDirY;
	cameraToWorldMatrix[2] = cameraDirZ;
	vec3 fragRayDir = cameraToWorldMatrix * fragRayDirRaw;

	//---
	// Min angle between vectors
	vec3 expectedVec = vec3(0., 0., -1.);
	float angleDiff = degrees(acos(dot(normalize(cameraDirZ), expectedVec)));
//	color.rgb = color.rgb * vec3(angleDiff/180.0); // Direction is CORRECT
	
	
	 
	vec2 rayBoxInfo = rayBoxDst(cameraPos, fragRayDir);
//	vec2 rayBoxInfo = rayBoxDst(cameraPos, -cameraDirZ); // Test default direction. IT WORKS
	float dstToBox = rayBoxInfo.x;
	float dstToInsideBox = rayBoxInfo.y;

	bool rayHitBox = dstToInsideBox > 0.0;
	if (rayHitBox) {
		color.rgb = vec3(1.0, 0.0, 0.0);
	}
	if (dstToBox > 0.) {
//		color.rgb = vec3(0.0, 1.0, 0.0);
		// Triggering when Z>0 (Looking backwards)
	}

// ----------

	// float zoom = 0.8;
	// vec2 uv = UV * 2.0 - 1.0;
	// uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y; // Correct aspect ratio
	// vec3 r0 = cameraPos;
	// // HOW TO RELATE zoom WITH fov???
	// vec3 rd = normalize(vec3(uv*zoom, 1.0));

	// vec3 normCameraDir = cameraDir;

	// color.rgb = vec3(1.0-max(abs(uv.x), abs(uv.y)));

	// Get rd into camera_dir


//	vec3 camera_position = vec3(0.0, 0.0, -5.0);
//	vec3 ro = camera_position;
//	vec3 rd = vec3(uv, 1.0);
	
//	---------
	
//	vec2 uv = UV - .5;
//	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
//	uv.y = - uv.y;
//
//	vec3 dr = getDirection(normCameraDir, vec3(0., 2., 0.), uv, 1.0);

	// -----------------


	// color.rgb = vec3(0.0);
	
	// Check if space is making sense
	if (insideBox(cameraPos)) {
		color.rgb = vec3(0.0); // bounding box location is CORRECT
	}


	COLOR = color;
}

