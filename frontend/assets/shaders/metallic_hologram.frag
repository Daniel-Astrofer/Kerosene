#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt; 
uniform vec4 iColor; 

out vec4 fragColor;

// --- High quality hash (better distribution, less banding) ---
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// --- Smooth value noise (cubic interpolation) ---
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Cubic Hermite curve for smooth interpolation (no grid artifacts)
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash2(i + vec2(0.0, 0.0));
    float b = hash2(i + vec2(1.0, 0.0));
    float c = hash2(i + vec2(0.0, 1.0));
    float d = hash2(i + vec2(1.0, 1.0));
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// --- Brushed Metal Texture ---
// Real brushed metal = extremely fine horizontal grain in reflectivity
// NOT dark scratches, but subtle luminance modulation
float brushedMetal(vec2 uv) {
    float grain = 0.0;
    
    // Layer 1: Primary horizontal grain (fine)
    // High Y frequency creates thin horizontal bands
    // Low X frequency makes them stretch horizontally (like real brush strokes)
    grain += noise(uv * vec2(3.0, 400.0)) * 0.5;
    
    // Layer 2: Medium detail grain
    grain += noise(uv * vec2(5.0, 800.0)) * 0.25;
    
    // Layer 3: Fine micro-grain (adds crispness)
    grain += noise(uv * vec2(8.0, 1500.0)) * 0.125;
    
    // Layer 4: Ultra-fine shimmer detail
    grain += noise(uv * vec2(12.0, 2500.0)) * 0.0625;
    
    // Normalize
    grain /= 0.9375;
    
    return grain;
}

void main() {
    vec2 uv = FlutterFragCoord() / iResolution.xy;
    
    // --- Brushed Metal Base ---
    float metal = brushedMetal(uv);
    
    // Map to a SUBTLE luminance range centered around 1.0
    // Real brushed metal is mostly bright with very subtle horizontal variation
    // Range [0.85, 1.05] gives a premium, non-pixelated look
    float brushed = 0.85 + metal * 0.20;

    // --- Dynamic Specular Highlight ---
    float lightPos = (uv.x + uv.y) * 2.0 + iTilt.x * 4.0 - iTilt.y * 2.0;
    
    // Broad highlight band
    float highlight = sin(lightPos * 3.5) * 0.5 + 0.5;
    highlight = pow(highlight, 4.0);
    
    // Secondary narrower highlight  
    float secondaryHighlight = sin(lightPos * 7.0 + 1.5) * 0.5 + 0.5;
    secondaryHighlight = pow(secondaryHighlight, 9.0) * 0.4;

    // --- Diffuse lighting gradient based on tilt ---
    float diffuse = clamp((uv.y + iTilt.y * 0.5) * 0.6 + 0.4, 0.0, 1.0);
    
    // --- Combine lighting ---
    float lighting = diffuse * 0.5 + highlight * 0.7 + secondaryHighlight * 0.4;
    
    // Anisotropic reflection: the grain modulates the specular response
    // This is what makes brushed metal look anisotropic under light
    float anisotropicReflection = highlight * metal * 0.8;
    
    float finalLight = lighting * brushed + anisotropicReflection * 0.3;
    
    // --- Apply base metal color ---
    vec3 finalColor = iColor.rgb * finalLight;
    
    // Bright ambient base (metal is inherently reflective)
    finalColor += iColor.rgb * 0.35;
    
    // --- Gamma correction ---
    fragColor = vec4(pow(clamp(finalColor, 0.0, 1.0), vec3(1.0 / 2.2)), iColor.a);
}
