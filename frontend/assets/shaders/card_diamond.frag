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
    
    // Second pass to calculate distance to the cell edge
    md = 8.0;
    for(int j = -2; j <= 2; j++) {
        for(int i = -2; i <= 2; i++) {
            vec2 g = mg + vec2(float(i), float(j));
            vec2 o = vec2(hash2(n + g));
            o = 0.5 + 0.5 * sin(6.2831 * o);
            vec2 r = g + o - f;
            if(dot(mr - r, mr - r) > 0.00001) {
                // Distance to the edge line separating the two cells
                md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
            }
        }
    }
    // Return distance, distance to edge, and cell id
    return vec3(length(mr), md, hash2(n + mg));
}

void main() {
    vec2 uv = FlutterFragCoord() / iResolution.xy;
    
    // Create large glass facets
    // iTilt scales/moves UV to simulate parallax depth behind thick glass
    vec3 v = voronoi(uv * 4.0 + iTilt * 1.5);
    
    float edgeDist = v.y;
    float cellId = v.z;

    // Normal calculation: The geometry is flat inside a cell (facets), but sharply angled at edges.
    vec3 N = normalize(vec3(0.0, 0.0, 1.0));
    
    // Tilt the normal randomly per cell
    N.x += (hash2(vec2(cellId, 0.0)) - 0.5) * 0.4;
    N.y += (hash2(vec2(0.0, cellId)) - 0.5) * 0.4;
    
    // Add sharp geometric bevels at the Voronoi edges
    if (edgeDist < 0.05) {
        // Round/bevel the normals right at the cut
        N.x += (v.x - 0.5) * 1.5;
        N.y += (v.x - 0.5) * 1.5;
    }
    N = normalize(N);
    
    // Light calculation
    vec3 L = normalize(vec3((uv.x - 0.5) * 2.5 - iTilt.x * 2.5, (uv.y - 0.5) * 2.5 + iTilt.y * 3.0 + 1.2, 1.2));
    vec3 V = normalize(vec3(0.0, 0.0, 1.0));
    vec3 H = normalize(L + V);

    // Dark base tinted by injected color (Ruby = Red, Diamond = Blue/Cyan)
    vec3 baseColor = iColor.rgb * 0.6;
    
    // Fresnel (edges of the card reflect more environment)
    float fresnel = pow(1.0 - max(dot(N, V), 0.0), 4.0);

    // Diffuse component (represents the body of the gem/glass)
    float diff = max(dot(N, L), 0.0);
    
    // Inside a gemstone, light bounces. We simulate this by making the center of cells slightly brighter.
    float internalLight = smoothstep(0.0, 0.5, v.x) * 0.3 * diff;

    // Highly polished specular highlights
    float spec = pow(max(dot(N, H), 0.0), 120.0) * 1.5;
    
    // The metallic edges of the cuts catch very sharp light
    float cutHighlight = smoothstep(0.03, 0.00, edgeDist) * pow(max(dot(N, H), 0.0), 20.0);

    // Iridescence (rainbow effect caused by light dispersion through glass cuts)
    vec3 iridescence = vec3(
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 0.0),
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 2.0),
        0.5 + 0.5 * sin(10.0 * edgeDist + diff * 10.0 + 4.0)
    );
    
    // Compose final colors
    vec3 finalColor = baseColor * diff * 0.6;          // Core body
    finalColor += baseColor * internalLight;           // Glass internal refraction
    finalColor += vec3(fresnel) * 0.3;                 // Fresnel reflection
    finalColor += vec3(1.0) * spec;                    // Flat glass highlights
    finalColor += iridescence * cutHighlight * 1.5;    // Colorful faceted cuts

    // Engraved Text
    vec2 texUV = vec2(uv.x, 1.0 - uv.y);
    float alphaC = texture(uTexture, texUV).a;
    float alphaR = texture(uTexture, texUV + vec2(0.002, 0.0)).a;
    float alphaB = texture(uTexture, texUV + vec2(0.0, -0.002)).a;
    
    float dX = alphaR - alphaC;
    float dY = alphaB - alphaC;
    
    if (alphaC > 0.01) {
        // Frosted glass effect for engraving
        finalColor = mix(finalColor, vec3(0.95), alphaC * 0.6); // Slightly white opaque
        finalColor += vec3(0.1) * alphaC * max(dot(vec3(0.0, 0.0, 1.0), L), 0.0); // Simple ambient scatter
    }
    
    float textHighlight = max(0.0, dX * L.x + dY * L.y);
    float textShadow = max(0.0, -(dX * L.x + dY * L.y));
    
    finalColor += textHighlight * vec3(1.0) * 1.2; 
    finalColor -= textShadow * 0.8;

    // Output with contrast punch and gamma
    finalColor = finalColor * finalColor * 1.1; 
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(1.0/2.2));

    fragColor = vec4(finalColor, 1.0);
}
