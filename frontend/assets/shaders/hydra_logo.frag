#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_resolution; // Viewport resolution (width, height)
uniform float u_time;      // Time for sequential animation

out vec4 fragColor;

// Colors
const vec4 COL_CHEVRON = vec4(1.0, 1.0, 1.0, 1.0);     // White
const vec4 COL_DOT = vec4(0.25, 0.75, 1.0, 1.0);      // Sky Blue
const vec4 COL_GLOW = vec4(0.25, 0.75, 1.0, 0.8);     // Glow color

// Sharp Tapered Chevron SDF
// Points DOWN, arms meeting at top center
float sdfChevronSharp(vec2 p, float len, float thickness, float angle) {
    p.x = abs(p.x);
    
    // Direction of the chevron arms (pointing UP and out)
    vec2 dir = vec2(sin(angle), cos(angle));
    
    // Project P onto the arm segment
    float h = clamp(dot(p, dir), 0.0, len);
    float d = length(p - dir * h);
    
    // Tapering: thickness is full at the meeting point (top), 0 at the tips
    float taper = 1.0 - (h / len);
    float currentThick = thickness * (0.2 + 0.8 * taper); // 20% thickness at tips
    
    return d - currentThick;
}

// SDF for central Dot
float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

void main() {
    vec2 st = FlutterFragCoord() / u_resolution.xy;
    vec2 p = st * 2.0 - 1.0;
    p.y = -p.y; // Correct Y orientation
    
    // Normalize aspect ratio
    float aspect = u_resolution.x / u_resolution.y;
    p.x *= aspect;

    // --- SEQUENTIAL ANIMATION LOGIC ---
    float t = u_time * 0.8;
    
    float chevIntro = smoothstep(0.0, 1.5, t); 
    float dotIntro = smoothstep(1.5, 2.5, t);  
    float glowIntro = smoothstep(2.5, 3.5, t); 
    
    // Positions
    vec2 dotPos = vec2(0.0, 0.35);
    vec2 chevPos = vec2(0.0, -0.25); // Vertex at the bottom
    
    // Parameters
    float circleRadius = 0.08 * dotIntro;
    float armLength = 0.75 * chevIntro;
    float armThick = 0.045 * chevIntro; // Thinner for elegance
    float armAngle = 1.03; // Radians (~59 degrees) to match original sharpness=0.6

    // Distances
    float dDot = sdfCircle(p - dotPos, circleRadius);
    float dChev = sdfChevronSharp(p - chevPos, armLength, armThick, armAngle);

    // Rendering masks
    float aa = 2.5 / u_resolution.y;
    float maskDot = 1.0 - smoothstep(-aa, aa, dDot);
    float maskChev = 1.0 - smoothstep(-aa, aa, dChev);
    
    // Glows
    float dotGlowSize = 0.2 + 0.1 * sin(u_time * 2.0);
    float glowDotVal = exp(-max(0.0, dDot) * (15.0 - 5.0 * glowIntro)) * 0.7 * glowIntro;
    float glowChevVal = exp(-max(0.0, dChev) * 35.0) * 0.3 * chevIntro;

    vec4 finalCol = vec4(0.0);
    
    // White Chevron first (Pointy tips)
    finalCol = mix(finalCol, COL_CHEVRON, maskChev);
    finalCol.rgb += COL_CHEVRON.rgb * glowChevVal * (1.0 - maskChev);
    finalCol.a = max(finalCol.a, clamp(maskChev + glowChevVal, 0.0, 1.0));

    // Blue Dot second
    if (dotIntro > 0.0) {
        finalCol = mix(finalCol, COL_DOT, maskDot);
        finalCol.rgb += COL_GLOW.rgb * glowDotVal * (1.0 - maskDot);
        finalCol.a = max(finalCol.a, clamp(maskDot + glowDotVal, 0.0, 1.0));
    }

    // Subtle global shimmer
    finalCol.rgb *= 0.95 + 0.05 * sin(u_time * 1.5);

    fragColor = finalCol;
}
