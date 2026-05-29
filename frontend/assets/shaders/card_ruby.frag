#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt;
uniform vec4 iColor;
uniform sampler2D uTexture;

out vec4 fragColor;

#define MAX_ITERATIONS 48
#define MAX_DISTANCE  10.0

#define LIGHT_DIR normalize(vec3(0.5, 0.8, 0.5) + vec3(iTilt.x, iTilt.y, 0.0))
#define LIGHT_COL vec3(1.0)
#define LIGHT_AMB 0.35

#define EPSILON 0.005
#define SHADOW_BIAS 0.02

// Simple hash-based noise for heightmap instead of iChannel1
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float dstScene(vec3 p) {
    // Heightfield logic from user
    // iChannel1 texture replaced by iColor-based noise + uTexture alpha
    float h = noise(p.xz * 4.0) * 0.015;
    h += texture(uTexture, p.xz * 0.5 + 0.5).a * 0.01;
    float d = p.y - h;
   	return d;
}

float raymarch(vec3 ori, vec3 dir, int iter) {
    float t = 0.;
    for(int i = 0; i < MAX_ITERATIONS; i++) {
        if(i >= iter)
            break;
        vec3  p = ori + dir * t;
        float d = dstScene(p);
        if(d < EPSILON || t > MAX_DISTANCE)
            break;
        t += d * 0.75;
    }
    return t;
}

vec3 calcNormal(vec3 p, float t) {
	vec2 e = vec2(EPSILON * t, 0.);
    vec3 n = vec3(dstScene(p + e.xyy) - dstScene(p - e.xyy),
                  dstScene(p + e.yxy) - dstScene(p - e.yxy),
                  dstScene(p + e.yyx) - dstScene(p - e.yyx));
    return normalize(n);
}

vec3 calcLighting(vec3 col, vec3 p, vec3 n, vec3 r, float sh, float sp) {
    float d = max(dot(LIGHT_DIR, n), 0.);
    float s = 0.0;
    float sd = 1.0;

    // Shadow pass
    if(raymarch(p + LIGHT_DIR * SHADOW_BIAS, LIGHT_DIR, 32) < MAX_DISTANCE)
        sd = 0.0;

    if(sh > 0.0)
        s = pow(max(dot(LIGHT_DIR, r), 0.0), sh) * sp;

    d *= sd;
    s *= sd;

    return (col * (LIGHT_AMB + LIGHT_COL * d)) + (LIGHT_COL * s);
}

vec3 shade(vec3 ori, vec3 dir) {
    float  t = raymarch(ori, dir, MAX_ITERATIONS);
    vec3 col = iColor.rgb * 0.3; // Deep background ruby

    if(t < MAX_DISTANCE) {
        vec3 p = ori + dir * t;
        vec3 n = calcNormal(p, t);
        vec3 r = normalize(reflect(dir, n));

        // Sampling Card Info for pattern (Optimized)
        vec2 texP = p.xz * 0.5 + 0.5;
        float alphaC = texture(uTexture, texP).a;
        float alphaR = texture(uTexture, texP + vec2(0.002, 0.0)).a;
        float alphaB = texture(uTexture, texP + vec2(0.0, -0.002)).a;

        vec3 baseCol = mix(iColor.rgb, vec3(1.0, 0.95, 0.95), clamp(alphaC * 0.4, 0.0, 1.0));

        float dX = alphaR - alphaC;
        float dY = alphaB - alphaC;
        float textHighlight = clamp((dX - dY) * 2.0, 0.0, 1.0);
        float textShadow = clamp((-dX + dY) * 1.5, 0.0, 1.0);

        col = calcLighting(baseCol, p, n, r, mix(10.0, 60.0, alphaC), mix(0.4, 1.0, alphaC));
        col += textHighlight * vec3(1.0) * 0.7;
        col -= textShadow * 0.5;
    }
    return col;
}

void main() {
	vec2 uv = (FlutterFragCoord() / iResolution.xy) - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    // View Orientation
    vec3 ori = vec3(0.0, 0.5, 0.0);
    vec3 dir = vec3(uv, 1.0);
    // User's dir.yz = rot2D(dir.yz, 90.)
    float s = sin(1.5708), c = cos(1.5708);
    float y = dir.y * c + dir.z * s;
    float z = -dir.y * s + dir.z * c;
    dir.y = y;
    dir.z = z;

    // Apply tilt to orientation for depth parallax
    ori.xz += iTilt * 0.3;

	fragColor = vec4(shade(ori, normalize(dir)), 1.0);
}
