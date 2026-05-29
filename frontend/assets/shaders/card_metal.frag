#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt;
uniform vec4 iColor;
uniform float iMaterialId;
uniform vec2 iTextureResolution;
uniform sampler2D uTexture;

out vec4 fragColor;

float hash12(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
        mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float engraveField(vec4 sampleColor) {
    float luma = dot(sampleColor.rgb, vec3(0.299, 0.587, 0.114));
    return sampleColor.a * mix(0.42, 1.0, luma);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / iResolution.xy;
    vec2 px = vec2(1.0 / iResolution.x, 1.0 / iResolution.y);
    vec2 texel = 1.0 / max(iTextureResolution, vec2(1.0));
    vec2 centered = uv - 0.5;
    vec2 texUV = vec2(uv.x, 1.0 - uv.y);

    // Optimized noise: reduce duplicate calls
    float n1 = noise2(uv * vec2(2.0, 1.25));
    float n2 = noise2(vec2(uv.x * 1.45, uv.y * 96.0));
    float n3 = noise2(vec2(uv.x * 2.7 + 4.2, uv.y * 210.0));
    float macro = n1;
    float grain = n2 * 0.56 + n3 * 0.44;

    // Engraving: Reduced texture fetches (3 instead of 5)
    vec4 texC = texture(uTexture, texUV);
    vec4 texR = texture(uTexture, texUV + vec2(texel.x, 0.0));
    vec4 texD = texture(uTexture, texUV + vec2(0.0, -texel.y));

    float grooveFine = sin(uv.y * 980.0 + noise2(vec2(uv.x * 10.0, uv.y * 2.1)) * 6.28);
    float grooveMid = sin((uv.y + uv.x * 0.05) * 310.0 + macro * 4.0 + n3 * 1.8);
    float grooveBroad = sin((uv.y - uv.x * 0.018) * 118.0 + n2 * 2.5);
    float grooveField = grooveFine * 0.020 + grooveMid * 0.032 + grooveBroad * 0.012 + (grain - 0.5) * 0.018;
    float brushed = 0.84 + grain * 0.10 + macro * 0.032 + grooveField * 0.75;

    // Engraving logic: More efficient and clearer
    float engraveC = engraveField(texC);
    float engraveR = engraveField(texR);
    float engraveD = engraveField(texD);

    float engraveDx = engraveR - engraveC;
    float engraveDy = engraveC - engraveD;

    float engraveAA = max(max(px.x, px.y) * 1.5, 0.001);
    // Sharpened mask for better clarity
    float engraveMask = smoothstep(0.02 - engraveAA, 0.12 + engraveAA, engraveC);
    float engraveDepth = smoothstep(0.01 - engraveAA, 0.45 + engraveAA, engraveC);

    float edgeMag = abs(engraveDx) + abs(engraveDy);
    float polishedRim = smoothstep(0.01 - engraveAA, 0.12 + engraveAA, edgeMag);

    vec3 metalNormal = normalize(vec3(
        (macro - 0.5) * 0.07 + grooveBroad * 0.018 + iTilt.y * 0.04,
        grooveField * 0.78 + (grain - 0.5) * 0.20 - iTilt.x * 0.04,
        1.0
    ));
    vec3 engraveNormal = normalize(vec3(-engraveDx * 12.0, engraveDy * 12.0, 1.0));
    vec3 N = normalize(mix(metalNormal, engraveNormal, engraveMask * 0.92));

    vec3 V = normalize(vec3(0.0, 0.0, 1.0));
    vec3 L = normalize(vec3(
        -0.52 + iTilt.y * 0.92 + sin(iTime * 0.11) * 0.04,
        -0.76 - iTilt.x * 0.58,
        1.42
    ));
    vec3 H = normalize(L + V);

    float ndotl = max(dot(N, L), 0.0);
    float ndotv = max(dot(N, V), 0.0);
    float ndoth = max(dot(N, H), 0.0);
    float tangentDotH = dot(vec3(1.0, 0.0, 0.0), H);
    float anisBand = pow(1.0 - min(1.0, abs(tangentDotH)), 10.0);
    float primarySpec = pow(ndoth, 54.0) * 0.62;
    float brushedSpec = pow(ndoth, 20.0) * anisBand * 0.46;
    float fresnel = pow(1.0 - ndotv, 4.0);

    // Smooth branching replacement
    float bronzeMix = clamp(1.0 - iMaterialId, 0.0, 1.0);
    float blackMix = clamp(iMaterialId - 1.0, 0.0, 1.0);
    float whiteMix = 1.0 - bronzeMix - blackMix;

    float sweep = smoothstep(-0.55, 0.85, dot(centered, vec2(-0.75 - iTilt.y * 0.55, 0.45 + iTilt.x * 0.4)) + macro * 0.14);

    vec3 baseColor = iColor.rgb;
    vec3 coolReflection = mix(vec3(0.96, 0.91, 0.78), vec3(0.74, 0.82, 0.92), blackMix);
    vec3 warmReflection = mix(vec3(1.0, 0.94, 0.74), vec3(0.95, 0.73, 0.22), bronzeMix);
    warmReflection = mix(warmReflection, vec3(0.98, 0.92, 0.76), whiteMix * 0.45);
    vec3 envTint = mix(coolReflection, warmReflection, sweep);

    float material = mix(0.78, 1.10, brushed);
    material = mix(material, mix(0.66, 0.98, brushed), blackMix);
    material = mix(material, mix(0.90, 1.14, brushed), whiteMix * 0.70);

    vec3 finalColor = baseColor * material;
    finalColor *= mix(0.58 + ndotl * 0.42, 0.42 + ndotl * 0.30, blackMix);
    finalColor += baseColor * mix(0.12, 0.18, bronzeMix) * sweep;
    finalColor += envTint * (grooveField * 0.10 + mix(0.05, 0.03, blackMix) + fresnel * mix(0.22, 0.34, blackMix));
    finalColor += vec3(1.0) * primarySpec * mix(0.24 + grain * 0.38, 0.34 + grain * 0.44, blackMix);
    finalColor += envTint * brushedSpec * mix(0.14 + grain * 0.20, 0.20 + grain * 0.24, blackMix);

    vec3 goldCast = mix(vec3(0.46, 0.30, 0.08), vec3(1.0, 0.90, 0.62), clamp(brushed * 0.55 + sweep * 0.35 + ndotl * 0.20, 0.0, 1.0));
    goldCast = mix(goldCast, vec3(0.96, 0.91, 0.78), whiteMix * 0.35);
    finalColor = mix(finalColor, goldCast, bronzeMix * 0.24 + whiteMix * 0.12);

    float edgeFrame = smoothstep(0.62, 0.98, max(abs(centered.x) * 1.1, abs(centered.y) * 1.28));
    finalColor += vec3(1.0) * pow(edgeFrame, 5.0) * 0.04;

    // Corner Glows (Simplified)
    float cornerGlow = 1.0 - smoothstep(0.0, 0.44, length((uv - vec2(0.12, 0.08)) * vec2(1.28, 1.0)));
    cornerGlow = max(cornerGlow, 1.0 - smoothstep(0.0, 0.44, length((uv - vec2(0.88, 0.08)) * vec2(1.28, 1.0))));
    cornerGlow *= 1.0 - smoothstep(0.10, 0.42, uv.y);
    vec3 topCornerTint = mix(vec3(0.20, 0.50, 1.00), vec3(0.55, 0.34, 0.98), smoothstep(0.15, 0.85, uv.x));
    finalColor += topCornerTint * cornerGlow * 0.17;

    // Engraving highlights and shadows (Sharpened)
    vec2 light2D = normalize(vec2(-0.56, -0.83));
    float lightSlope = dot(vec2(engraveDx, engraveDy), light2D);
    float cavityShade = engraveMask * (0.18 + engraveDepth * 0.18 + (1.0 - max(dot(engraveNormal, L), 0.0)) * 0.32);
    float rimHighlight = polishedRim * smoothstep(0.002, 0.10, -lightSlope);
    float rimShadow = polishedRim * smoothstep(0.002, 0.10, lightSlope);
    float cavitySpec = pow(max(dot(engraveNormal, H), 0.0), 32.0) * polishedRim;

    vec2 mirrorAxis = normalize(vec2(0.94 + iTilt.y * 0.42, -0.34 + iTilt.x * 0.28));
    float mirrorPhase = dot(centered + vec2(engraveDx, engraveDy) * 0.20, mirrorAxis) + iTilt.y * 0.30 - iTilt.x * 0.18 + sin(iTime * 0.35) * 0.018;
    float mirrorBand = 1.0 - smoothstep(0.01, 0.12, abs(mirrorPhase));
    mirrorBand *= engraveDepth * (0.6 + polishedRim * 0.4);

    vec3 mirrorTint = mix(vec3(0.96, 0.985, 1.0), vec3(0.72, 0.80, 1.0), blackMix * 0.65 + whiteMix * 0.25);

    vec3 cavityMetal = mix(finalColor * 0.70, baseColor * mix(0.40, 0.28, blackMix), 0.62);
    cavityMetal *= 1.0 - cavityShade;
    cavityMetal += envTint * engraveDepth * 0.035;
    cavityMetal += mirrorTint * mirrorBand * (0.28 + fresnel * 0.15);

    finalColor = mix(finalColor, cavityMetal, clamp(engraveMask * 1.6, 0.0, 1.0));
    finalColor += vec3(1.0, 0.985, 0.95) * rimHighlight * mix(0.35, 0.25, blackMix);
    finalColor -= vec3(0.18, 0.17, 0.16) * rimShadow * mix(0.40, 0.28, blackMix);
    finalColor += envTint * cavitySpec * 0.16;
    finalColor += mirrorTint * mirrorBand * polishedRim * 0.12;

    fragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
