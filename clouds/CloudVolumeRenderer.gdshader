shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_texture : hint_black_albedo;
uniform vec3 boundMin;
uniform vec3 boundMax;

vec2 rayBoxDst(vec3 rayOrigin, vec3 rayDir) {
    vec3 t0 = (boundMin - rayOrigin) / rayDir;
    vec3 t1 = (boundMax - rayOrigin) / rayDir;
    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);

    float dstA = max(max(tmin.x, tmin.y), tmin.z);
    float dstB = max(max(tmax.x, tmax.y), tmax.z);

    // 1: (0 <= dstA <= dstB) intersect from outside
    // 2: (dstA <= 0 <= dstB) intersect from inside
    // 3: (dstA > dstB) ray misses

    float dstToBox = max(0, dstA);
    float dstToInsideBox = max(0, dstB - dstToBox);

    return vec2(dstToBox, dstToInsideBox);
}

float sampleDensity (vec3 position) {
    return 1.0;
}


void fragment() {
    vec3 cameraPos = (CAMERA_MATRIX * vec4(0.0,0.0,0.0,1.0)).xyz;
    vec3 vertexPos = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 cameraDir = normalize(vertexPos - cameraPos);

    vec2 rayBoxInfo = rayBoxDst(cameraPos, cameraDir);
    float dstToBox = rayBoxInfo.x;
    float dstToInsideBox = rayBoxInfo.y;

    int NUM_STEPS = 5;
    float stepSize = dstToInsideBox / float(NUM_STEPS);
    float dstLimit = dstToInsideBox;

    // Get total density
    float totalDensity = 0.0;
    float distanceTravelled = 0.0;
//    while (distanceTravelled < dstLimit) {
    for (int i=0; i<NUM_STEPS; i++) {
//        vec3 curPos = cameraPos + cameraDir * (dstToBox + distanceTravelled);
		vec3 curPos;
        totalDensity += sampleDensity(curPos);
        distanceTravelled += stepSize;
    }

    // Compute color with exponential density

    // float transmittance = exp(-totalDensity);
    // float transmittance = exp(-dstToInsideBox/.0010); 
    float transmittance = min(1.0, totalDensity); 
    ALBEDO = vec3(transmittance);
//    ALBEDO = vec3(totalDensity);



    // I might need to use a screen shader bc being inside the cloud will not trigger fragment?



//	ALBEDO = vec3(0.1, 0.3, 0.5);
//	ALBEDO = vec3(1.0) - ALBEDO;

//	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
//	depth = depth*50.0 - 49.0;
//	ALBEDO = vec3(depth);



}
