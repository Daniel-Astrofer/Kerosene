#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform float uIsDelayed;

out vec4 fragColor;

// --- CONFIGURAÇÃO ---
const float DOTS = 8.0; 
const vec3 LIGHTS_COLOR = vec3(0.3, 0.6, 1.0); 
const vec3 CIRCLE_COLOR = vec3(0.4, 0.7, 1.0);
const vec3 BOOMERANG_COLOR = vec3(1.0, 1.0, 1.0);
const vec4 CLEAR_COLOR = vec4(0.0, 0.0, 0.0, 0.0); 

// --- FUNÇÕES AUXILIARES DE DESENHO (SDFs) ---

float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

// Boomerang/V shape using line segment SDFs for sharp tips
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// V-shape built from two angled line segments with thickness
float sdfVShape(vec2 p) {
    // The V tip is at top center (flipped)
    vec2 tip = vec2(0.0, 0.55);
    // Left arm goes down-left
    vec2 leftTip = vec2(-1.15, -0.35);
    // Right arm goes down-right
    vec2 rightTip = vec2(1.15, -0.35);
    
    // Distance to left arm segment
    float dLeft = sdSegment(p, tip, leftTip);
    // Distance to right arm segment  
    float dRight = sdSegment(p, tip, rightTip);
    
    // Take the minimum distance (union of both arms)
    float d = min(dLeft, dRight);
    
    // Variable thickness: thicker at the tips, thinner at the vertex
    // Use the Y coordinate to control thickness (flipped)
    float thickness = mix(0.02, 0.12, smoothstep(0.55, -0.35, p.y));
    
    return d - thickness;
}

// --- FUNÇÃO PRINCIPAL DE RENDERIZAÇÃO ---

void main()
{
    vec2 fragCoord = FlutterFragCoord();
    vec2 p = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // Scale down the symbol to 1/3 of the screen
    vec2 sp = p * 3.0;
    
    vec4 symbol_col = CLEAR_COLOR;

    // Efeito de Pontos de Luz (Metaballs)
    float f = 0.0;
    for(float i = 1.0; i <= DOTS; i++)
    {
        float s = sin(0.7 * iTime + (i * 0.5) * iTime) * 0.2;
        float c = cos(0.2 * iTime + (i * 0.5) * iTime) * 0.2;
        f += 0.01 / abs(length(p * 0.75 + vec2(c, s)));
    }
    
    // Dynamic color based on delay
    vec3 baseLightsColor = vec3(0.3, 0.6, 1.0); // Cyan/Blue
    vec3 warningColor = vec3(1.0, 0.0, 0.2);     // Vibrant Red
    vec3 currentLightsColor = mix(baseLightsColor, warningColor, uIsDelayed);
    
    vec3 lights_col_f = currentLightsColor * f;

    // Background Glow
    float bgGlow = 0.05 / (length(p) + 0.5);
    vec3 bg_col = currentLightsColor * bgGlow;

    // Mistura Final
    vec3 final_rgb = bg_col + lights_col_f;
    float final_alpha = (bgGlow * 2.0) + (f * 0.2);
    
    fragColor = vec4(final_rgb, final_alpha);
}
