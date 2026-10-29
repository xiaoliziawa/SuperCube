#version 330
#extension GL_ARB_separate_shader_objects : require

#include <projection.glsl>
#include <fog.glsl>

vec4 projectionFragmentCoordinates;
#define gl_FragCoord projectionFragmentCoordinates
#include <oit.glsl>
#undef gl_FragCoord

#ifndef OIT_ALPHA_ONLY
#include "supercube:neonwave_scene.glsl"
layout(location = 0) out vec4 fragColor;
#endif

layout(location = 0) in vec3 localPosition;
layout(location = 1) flat in vec3 localCamera;
layout(location = 2) flat in vec3 faceNormal;
layout(location = 3) in vec3 viewPosition;
layout(location = 4) flat in vec4 projectionColor;
layout(location = 5) flat in float animationTime;
layout(location = 6) flat in float worldScale;
layout(location = 7) flat in int quality;

const float MIN_VIEW_DEPTH = 0.051;

void main() {
    if (dot(faceNormal, localCamera - localPosition) >= 0.0) {
        discard;
    }
    vec3 rayDirection = normalize(localPosition - localCamera);
    float b = dot(localCamera, rayDirection);
    float discriminant = b * b - dot(localCamera, localCamera) + NEONWAVE_SCENE_RADIUS * NEONWAVE_SCENE_RADIUS;
    if (discriminant <= 0.0) {
        discard;
    }
    float root = sqrt(discriminant);
    float entryDistance = max(-b - root, MIN_VIEW_DEPTH / worldScale);
    float exitDistance = -b + root;
    if (exitDistance <= entryDistance) {
        discard;
    }

    vec3 entryView = normalize(viewPosition) * (entryDistance * worldScale);
    vec4 clipPosition = ProjMat * vec4(entryView, 1.0);
    float depth = clipPosition.z / clipPosition.w;
    #ifndef RENDERPEARL_DEPTH_IS_ZERO_TO_ONE
    depth = depth * 0.5 + 0.5;
    #endif
    gl_FragDepth = depth;
    projectionFragmentCoordinates = vec4(gl_FragCoord.xy, depth, gl_FragCoord.w);

    float alpha = projectionColor.a * smoothstep(0.0, 1.0, root);
    if (alpha < 0.001) {
        discard;
    }
    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(depth, alpha);
    #else
    float pixelAngle = max(length(dFdx(rayDirection)), length(dFdy(rayDirection)));
    vec3 color = neonwave(localCamera, rayDirection, vec2(entryDistance, exitDistance), animationTime, quality, pixelAngle);
    vec4 result = apply_fog(vec4(color * projectionColor.rgb, alpha),
            fog_spherical_distance(entryView), fog_cylindrical_distance(entryView),
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
    #ifdef OIT_ACCUMULATE
    fragColor = sampleColorForAccumulation(result);
    #else
    fragColor = result;
    #endif
    #endif
}
