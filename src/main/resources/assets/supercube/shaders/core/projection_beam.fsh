#version 330
#extension GL_ARB_separate_shader_objects : require

#include <fog.glsl>
#include <oit.glsl>

layout(location = 0) in vec2 beamCoordinates;
layout(location = 1) in vec3 viewPosition;
layout(location = 2) in vec3 viewNormal;
layout(location = 3) flat in vec4 beamColor;
layout(location = 4) in float sphericalVertexDistance;
layout(location = 5) in float cylindricalVertexDistance;
layout(location = 6) flat in float animationPhase;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

const float TAU = 6.28318530718;

void main() {
    float height = clamp(beamCoordinates.y, 0.0, 1.0);
    float facing = abs(dot(normalize(viewNormal), normalize(viewPosition + vec3(0.0, 0.0, 0.00001))));
    float silhouetteFade = smoothstep(0.0, 0.45, facing);
    float heightFade = smoothstep(0.0, 0.04, height) * (1.0 - smoothstep(0.35, 1.0, height));
    float rays = pow(0.5 + 0.5 * sin(beamCoordinates.x * TAU * 12.0 - animationPhase * 0.4), 10.0);
    float sweep = pow(0.5 + 0.5 * sin(height * TAU * 4.0 - animationPhase * 4.0), 8.0);
    float intensity = (0.35 + rays * 0.3 + sweep * 0.15) * mix(1.0, 0.35, height);
    float fogVisibility = 1.0 - total_fog_value(sphericalVertexDistance, cylindricalVertexDistance,
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd);
    float alpha = min(0.99, beamColor.a * silhouetteFade * heightFade * intensity * fogVisibility);
    if (alpha < 0.001) {
        discard;
    }

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, alpha);
    #else
    vec3 tint = mix(vec3(0.18, 0.72, 1.0), vec3(0.3, 1.0, 0.78), height);
    vec4 color = vec4(tint * beamColor.rgb, alpha);
        #ifdef OIT_ACCUMULATE
        fragColor = sampleColorForAccumulation(color);
        #else
        fragColor = color;
        #endif
    #endif
}
