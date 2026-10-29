#version 330
#extension GL_ARB_separate_shader_objects : require

#include <fog.glsl>
#include <oit.glsl>

layout(location = 0) in vec2 edgeCoordinates;
layout(location = 1) flat in float edgeLength;
layout(location = 2) flat in float edgeWidth;
layout(location = 3) flat in vec4 edgeColor;
layout(location = 4) in float sphericalVertexDistance;
layout(location = 5) in float cylindricalVertexDistance;
layout(location = 6) flat in float animationPhase;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

void main() {
    float beyondEndpoint = max(max(-edgeCoordinates.x, edgeCoordinates.x - edgeLength), 0.0);
    float distanceToEdge = length(vec2(beyondEndpoint, edgeCoordinates.y));
    float antialias = max(fwidth(distanceToEdge), edgeWidth * 0.05);
    float core = 1.0 - smoothstep(edgeWidth - antialias, edgeWidth + antialias, distanceToEdge);
    float normalizedDistance = distanceToEdge / edgeWidth;
    float halo = exp(-normalizedDistance * normalizedDistance * 0.5)
            * (1.0 - smoothstep(GLOW_RADIUS - 1.0, GLOW_RADIUS, normalizedDistance));
    float pulse = 0.85 + 0.15 * sin(animationPhase - edgeCoordinates.x * 6.0);
    float fogVisibility = 1.0 - total_fog_value(sphericalVertexDistance, cylindricalVertexDistance,
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd);
    float coreIntensity = core * 0.8;
    float haloIntensity = halo * 0.24;
    float intensity = coreIntensity + haloIntensity;
    float alpha = min(0.99, intensity * edgeColor.a * pulse * fogVisibility);
    #ifdef HYPERCUBE_CORE_PASS
    alpha *= coreIntensity / max(intensity, 0.00001);
    #elif defined(HYPERCUBE_GLOW_PASS)
    alpha *= haloIntensity / max(intensity, 0.00001);
    #endif
    if (alpha < 0.001) {
        discard;
    }

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, alpha);
    #else
    vec4 color = vec4(mix(edgeColor.rgb, vec3(1.0), core * 0.7), alpha);
        #ifdef OIT_ACCUMULATE
        fragColor = sampleColorForAccumulation(color);
        #else
        fragColor = color;
        #endif
    #endif
}
