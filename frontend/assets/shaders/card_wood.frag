#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt;
uniform vec4 iColor; 
uniform sampler2D uTexture;

out vec4 fragColor;

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

// Eucalyptus wood: Long, smooth, low-contrast streaks, very few knots.
float eucalyptusTexture(vec2 uv) {
    // Elongated coordinates for vertical/horizontal streaking
    vec2 p = uv * vec2(1.0, 40.0); 
    p += noise(uv * vec2(2.0, 5.0)) * 1.5; // Slight wave
    
    // Very subtle, stretched rings/bands
    float band = noise(p * vec2(0.3, 0.05));
    
    // Fine, dense vertical grain
    float grain = noise(uv * vec2(8.0, 300.0));
    
    // Smooth blending
    return mix(band, grain, 0.15);
}

void main() {
    vec2 uv = FlutterFragCoord() / iResolution.xy;

    float w = eucalyptusTexture(uv);
    
    // Eucalyptus colors: soft pale beige, light blonde, almost ashen
    vec3 lightWood = vec3(0.86, 0.76, 0.61); 
    vec3 darkWood = vec3(0.70, 0.58, 0.44);   
    
    // Smooth transition
    vec3 albedo = mix(darkWood, lightWood, smoothstep(0.3, 0.7, w));
    
    // Apply user chosen multiplier color if any
    albedo *= mix(vec3(1.0), iColor.rgb, 0.2);

    // Bump map for small grains
    vec3 N = normalize(vec3(0.0, 0.0, 1.0));
    N.x += (eucalyptusTexture(uv + vec2(0.005, 0.0)) - w) * 0.3;
    N.y += (eucalyptusTexture(uv + vec2(0.0, 0.005)) - w) * 0.3;
    N = normalize(N);

    // Soft, offset lighting to prevent blowout
    vec3 L = normalize(vec3((uv.x - 0.5) * 2.0 - iTilt.x * 2.0, (uv.y - 0.5) * 2.0 + iTilt.y * 2.0 + 1.0, 1.5));
    float diff = max(dot(N, L), 0.0);
    
    // Specular highlight: Eucalyptus is often matte or smoothly polished (satin)
    vec3 V = normalize(vec3(0.0, 0.0, 1.0));
    vec3 H = normalize(L + V);
    float spec = pow(max(dot(N, H), 0.0), 10.0) * 0.15; // Low intensity, wide spread

    // Lighting composition
    vec3 finalColor = albedo * diff * 0.75 + albedo * 0.25 + vec3(1.0) * spec;
    
    // Engraving for the text
    vec2 texUV = vec2(uv.x, 1.0 - uv.y);
    float alphaC = texture(uTexture, texUV).a;
    float alphaR = texture(uTexture, texUV + vec2(0.002, 0.0)).a;
    float alphaB = texture(uTexture, texUV + vec2(0.0, -0.002)).a;
    
    float dX = alphaR - alphaC;
    float dY = alphaB - alphaC;
    
    if (alphaC > 0.05) {
        // Pyrography (burned wood) effect
        finalColor *= vec3(0.35, 0.20, 0.10); // Burnt warm dark brown
    }
    
    float edgeHighlight = max(0.0, dX * L.x + dY * L.y);
    float edgeShadow = max(0.0, -(dX * L.x + dY * L.y));
    
    finalColor += edgeHighlight * vec3(0.9, 0.8, 0.6) * 0.6;
    finalColor -= edgeShadow * 0.5;

    // Soft border shadow for premium feel
    float vignette = length(uv - 0.5) * 1.2;
    finalColor *= smoothstep(1.0, 0.4, vignette);

    // Tone mapping
    finalColor = pow(clamp(finalColor, 0.0, 1.0), vec3(1.0/1.8)); // Slightly lower gamma to keep it soft

    fragColor = vec4(finalColor, 1.0);
}
