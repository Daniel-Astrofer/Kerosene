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

// Smooth value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i + vec2(0.0,0.0)), hash2(i + vec2(1.0,0.0)), u.x),
               mix(hash2(i + vec2(0.0,1.0)), hash2(i + vec2(1.0,1.0)), u.x), u.y);
}

// Fine horizontal streaks for brushed metal (maximized detail)
float brushedMetal(vec2 uv) {
    float grain = 0.0;
    // High-frequency noise for micro-scratches
    grain += noise(uv * vec2(1.5, 120.0)) * 0.5;
    grain += noise(uv * vec2(3.0, 300.0)) * 0.3;
    grain += noise(uv * vec2(6.0, 750.0)) * 0.2;
    return grain;
}

void main() {
    vec2 uv = FlutterFragCoord() / iResolution.xy;

    // Base metal pattern
    float metal = brushedMetal(uv);
    
    // Instead of deep black shadows, make the grooves subtle variations in reflectance
    float brushed = 0.85 + metal * 0.15; 

    // Simulate microfacets from brush strokes (grooves bend light up and down)
    vec3 N = normalize(vec3(0.0, (metal - 0.5) * 0.25, 1.0));

    // Move light source physically upwards and slightly left to avoid a center "hotspot"
    vec3 L = normalize(vec3(0.3 - iTilt.x * 1.5, 0.7 + iTilt.y * 1.5, 1.5));
    vec3 V = normalize(vec3(0.0, 0.0, 1.0)); 
    vec3 H = normalize(L + V);

    // Diffuse lighting (softened)
    float diff = max(dot(N, L), 0.0) * 0.6 + 0.4;

    // Fast anisotropic highlight (ward-like)
    vec3 tangent = vec3(1.0, 0.0, 0.0); 
    float dotTH = dot(tangent, H);
    float spec = sqrt(max(0.0, 1.0 - dotTH * dotTH));
    // Reduced intensity to avoid blowing out the middle
    spec = pow(max(0.0, spec), 80.0) * 0.8;

    // Environmental reflection
    float envReflection = smoothstep(0.3, 0.8, noise(uv * 2.0 + vec2(iTilt.x, iTilt.y) * 2.0));
    envReflection *= 0.25;

    // Base color - darkened to prevent blowout since metal depends on specular for brightness
    vec3 albedo = iColor.rgb * 0.65; 

    vec3 finalColor = albedo * diff * brushed;       // Diffuse step
    finalColor += albedo * envReflection;            // Environment glow
    // Specular highlight heavily modulated by the metal grooves for crisp lines
    finalColor += vec3(1.0) * spec * (0.2 + metal * 0.8); 

    // Reactive Engraving
    vec2 texUV = vec2(uv.x, 1.0 - uv.y);
    float alphaC = texture(uTexture, texUV).a;
    float alphaR = texture(uTexture, texUV + vec2(0.002, 0.0)).a;
    float alphaB = texture(uTexture, texUV + vec2(0.0, -0.002)).a;
    
    float dX = alphaR - alphaC;
    float dY = alphaB - alphaC;
    
    if (alphaC > 0.01) {
        // Subtle carving instead of deep black
        finalColor *= 0.6;
    }
    
    // Crisp edges for the carving
    float edgeHighlight = max(0.0, dX * L.x + dY * L.y);
    float edgeShadow = max(0.0, -(dX * L.x + dY * L.y));
    
    finalColor += edgeHighlight * vec3(0.5);
    finalColor -= edgeShadow * 0.5;

    // Tone Mapping - No double gamma correction to avoid total whiteness
    finalColor = clamp(finalColor, 0.0, 1.0);

    fragColor = vec4(finalColor, 1.0);
}
