#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iTilt;
uniform vec4 iColor;
uniform sampler2D uTexture;

out vec4 fragColor;

// Domain Warping Emerald Shader
// Adapted from Inigo Quilez (IQ) Warp shader

float noise(vec2 U){
    vec2 I = floor(U);
    float v = dot(I, vec2(127.1, 311.7));
    return fract(sin(v) * 43758.5453123);
}

const mat2 mtx = mat2( 0.80,  0.60, -0.60,  0.80 );

float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000*(-1.0+2.0*noise( p )); p = mtx*p*2.02;
    f += 0.2500*(-1.0+2.0*noise( p )); p = mtx*p*2.03;
    f += 0.1250*(-1.0+2.0*noise( p )); p = mtx*p*2.01;
    f += 0.0625*(-1.0+2.0*noise( p ));
    return f/0.9375;
}

float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000*noise( p ); p = mtx*p*2.02;
    f += 0.250000*noise( p ); p = mtx*p*2.03;
    f += 0.125000*noise( p ); p = mtx*p*2.01;
    f += 0.062500*noise( p ); p = mtx*p*2.04;
    f += 0.031250*noise( p ); p = mtx*p*2.01;
    f += 0.015625*noise( p );
    return f/0.96875;
}

vec2 fbm4_2( vec2 p )
{
    return vec2( fbm4(p+vec2(1.0)), fbm4(p+vec2(6.2)) );
}

vec2 fbm6_2( vec2 p )
{
    return vec2( fbm6(p+vec2(9.2)), fbm6(p+vec2(5.7)) );
}

float func( vec2 q, out vec2 o, out vec2 n )
{
    q += 0.05*sin(vec2(0.11,0.13) + length( q )*4.0);
    q *= 0.7 + 0.2*cos(0.05);

    o = 0.5 + 0.5*fbm4_2( q );
    o += 0.02*sin(vec2(0.11,0.13)*length( o ));
    n = fbm6_2( 4.0*o );

    vec2 p = q + 2.0*n + 1.0;
    float f = 0.5 + 0.5*fbm4( 2.0*p );
    f = mix( f, f*f*f*3.5, f*abs(n.x) );
    f *= 1.0-0.5*pow( 0.5+0.5*sin(8.0*p.x)*sin(8.0*p.y), 8.0 );
    return f;
}

float funcs( in vec2 q )
{
    vec2 t1, t2;
    return func(q,t1,t2);
}

void main()
{
    vec2 fragCoord = FlutterFragCoord();
    // Normalizing coordinates
    vec2 q = (2.0*fragCoord-iResolution.xy)/iResolution.y*1.5;

    // Parallax logic using iTilt - NO iTime for static cards
    q += iTilt * 0.8;

    vec2 o, n;
    float f = func(q, o, n);

    // Emerald Gem colors (Deep Greens and Whites)
    vec3 col = vec3(0.0, 0.25, 0.15); // Deep emerald
    col = mix( col, vec3(0.1, 0.5, 0.3), f ); // Lighter emerald
    col = mix( col, vec3(0.8, 1.0, 0.9), dot(n,n) ); // Crystal highlights
    col = mix( col, vec3(0.5, 1.0, 0.7), 0.5*o.y*o.y ); // Inner light green
    col = mix( col, vec3(0.0, 0.4, 0.3), 0.5*smoothstep(1.2,1.3,abs(n.y)+abs(n.x)) );
    col *= f*2.0;

    // Normal and Lighting calculation
    vec2 ex = vec2( 2.0 / iResolution.x, 0.0 );
    vec2 ey = vec2( 0.0, 2.0 / iResolution.y );
    vec3 nor = normalize( vec3( funcs(q+ex) - f, ex.x, funcs(q+ey) - f ) );

    vec3 lig = normalize( vec3( 0.9, -0.2, -0.4 ) );
    float dif = clamp( 0.3+0.7*dot( nor, lig ), 0.0, 1.0 );

    vec3 bdrf;
    bdrf  = vec3(0.85,0.95,0.90)*(nor.y*0.5+0.5); // Environmental light
    bdrf += vec3(0.15,0.30,0.10)*dif; // Diffuse bounce

    col *= bdrf;
    col = vec3(1.0)-col;
    col = col*col;
    col *= vec3(1.1, 1.4, 1.1); // Green brilliance bias

    // Wallet Text Texture pass (Optimized with depth)
    vec2 p_uv = fragCoord / iResolution.xy;
    vec2 tex_uv = vec2(p_uv.x, 1.0 - p_uv.y);
    float alphaC = texture(uTexture, tex_uv).a;
    float alphaR = texture(uTexture, tex_uv + vec2(0.002, 0.0)).a;
    float alphaB = texture(uTexture, tex_uv + vec2(0.0, -0.002)).a;

    // Branchless text engraving with highlights
    float burnMask = smoothstep(0.05, 0.15, alphaC);
    col = mix(col, vec3(0.95, 1.0, 0.98), burnMask * 0.7);

    float dX = alphaR - alphaC;
    float dY = alphaB - alphaC;
    float textHighlight = clamp((dX - dY) * 1.5, 0.0, 1.0);
    float textShadow = clamp((-dX + dY) * 1.0, 0.0, 1.0);

    col += textHighlight * vec3(1.0) * 0.8;
    col -= textShadow * 0.6;

    // Vignette
	col *= 0.5 + 0.5 * sqrt(16.0*p_uv.x*p_uv.y*(1.0-p_uv.x)*(1.0-p_uv.y));

	fragColor = vec4( col, 1.0 );
}
