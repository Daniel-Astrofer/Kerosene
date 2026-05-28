#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt;
uniform vec4 iColor;
uniform sampler2D uTexture;

out vec4 fragColor;

float hash2(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// 3D Noise for internal glow
float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    vec3 u = f * f * (3.0 - 2.0 * f);

    float n1 = hash2(i.xy + vec2(0.0, 0.0));
    float n2 = hash2(i.xy + vec2(1.0, 0.0));
    float n3 = hash2(i.xy + vec2(0.0, 1.0));
    float n4 = hash2(i.xy + vec2(1.0, 1.0));

    return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
}

// Crisp geometric Glass/Crystal Voronoi (calculating distance to edges for sharp facets)
vec3 voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    vec2 mg, mr;
    float md = 8.0;

    // First pass to find closest point
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(hash2(n + g));
            // Freeze animation: depend only on static noise
            o = 0.5 + 0.5 * sin(6.2831 * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if(d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }

    // Second pass to calculate distance to the cell edge (Optimized to 3x3)
    md = 8.0;
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 g = mg + vec2(float(i), float(j));
            vec2 o = vec2(hash2(n + g));
            o = 0.5 + 0.5 * sin(6.2831 * o);
            vec2 r = g + o - f;
            if(dot(mr - r, mr - r) > 0.00001) {
                md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
            }
        }
    }
    return vec3(length(mr), md, hash2(n + mg));
}

void main() {
    vec2 uv = FlutterFragCoord() / iResolution.xy;
    vec3 v = voronoi(uv * 4.0 + iTilt * 1.5);

    float edgeDist = v.y;
    float cellId = v.z;

    vec3 N = normalize(vec3(0.0, 0.0, 1.0));
    N.x += (hash2(vec2(cellId, 0.0)) - 0.5) * 0.4;
    N.y += (hash2(vec2(0.0, cellId)) - 0.5) * 0.4;

    // Branchless bevel
    float bevelMask = smoothstep(0.05, 0.0, edgeDist);
    N.xy += (v.xy - 0.5) * 1.5 * bevelMask;
    N = normalize(N);

    vec3 L = normalize(vec3((uv.x - 0.5) * 2.5 - iTilt.x * 2.5, (uv.y - 0.5) * 2.5 + iTilt.y * 3.0 + 1.2, 1.2));
    vec3 V = normalize(vec3(0.0, 0.0, 1.0));
    vec3 H = normalize(L + V);

    vec3 baseColor = iColor.rgb * 0.6;
    float fresnel = pow(1.0 - max(dot(N, V), 0.0), 4.0);
    float diff = max(dot(N, L), 0.0);
    float internalLight = smoothstep(0.0, 0.5, v.x) * 0.3 * diff;
    float spec = pow(max(dot(N, H), 0.0), 120.0) * 1.5;
    float cutHighlight = smoothstep(0.03, 0.00, edgeDist) * pow(max(dot(N, H), 0.0), 20.0);

    vec3 iridescence = vec3(
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 0.0),
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 2.0),
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 4.0)
    );

    vec3 finalColor = baseColor * diff * 0.6;
    finalColor += baseColor * internalLight;
    finalColor += vec3(fresnel) * 0.3;
    finalColor += vec3(1.0) * spec;
    finalColor += iridescence * cutHighlight * 1.5;

    // Engraved Text (Optimized & Cleared)
    vec2 texUV = vec2(uv.x, 1.0 - uv.y);
    float alphaC = texture(uTexture, texUV).a;
    float alphaR = texture(uTexture, texUV + vec2(0.002, 0.0)).a;
    float alphaB = texture(uTexture, texUV + vec2(0.0, -0.002)).a;

    // Branchless frosted glass
    float frostMask = smoothstep(0.01, 0.1, alphaC);
    finalColor = mix(finalColor, vec3(0.95), frostMask * 0.6);
    finalColor += vec3(0.12) * alphaC * max(dot(vec3(0.0, 0.0, 1.0), L), 0.0);

    float dX = alphaR - alphaC;
    float dY = alphaB - alphaC;
    float textHighlight = clamp((dX - dY) * 2.5, 0.0, 1.0);
    float textShadow = clamp((-dX + dY) * 1.8, 0.0, 1.0);

    finalColor += textHighlight * vec3(1.0) * 1.4;
    finalColor -= textShadow * 0.9;

    finalColor = finalColor * finalColor * 1.1;
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(1.0/2.2));

    fragColor = vec4(finalColor, 1.0);
}
