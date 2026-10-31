#version 330
#extension GL_ARB_separate_shader_objects : require

#include <projection.glsl>
#include <fog.glsl>

vec4 projectionFragmentCoordinates;
#define gl_FragCoord projectionFragmentCoordinates
#include <oit.glsl>
#undef gl_FragCoord

#include "supercube:glass_cube_bounds.glsl"

#ifndef OIT_ALPHA_ONLY
#include "supercube:glass_cube_scene.glsl"
layout(location = 0) out vec4 fragColor;
#endif

layout(location = 0) in vec3 localPosition;
layout(location = 1) flat in vec3 localCamera;
layout(location = 2) flat in vec3 faceNormal;
layout(location = 3) in vec3 viewPosition;
layout(location = 4) flat in vec4 projectionColor;
layout(location = 5) flat in float animationTime;
layout(location = 6) flat in float worldScale;

const float MIN_VIEW_DEPTH = 0.051;

void main() {
    if (dot(faceNormal, localCamera - localPosition) >= 0.0) {
        discard;
    }
    vec3 rayVector = localPosition - localCamera;
    float rayLength = length(rayVector);
    if (rayLength <= 0.00001) {
        discard;
    }
    vec3 rayDirection = rayVector / rayLength;

    vec3 localEye;
    vec3 localDirection;
    glassCubeLocalRay(localCamera, rayDirection, animationTime, localEye, localDirection);

    // From outside, the cube is seen through its front face; from inside, through the back face.
    bool inside = glassCubeInside(localEye);
    float surfaceDistance;
    vec3 surfaceNormal;
    if (inside) {
        surfaceDistance = glassCubeExit(localEye, localDirection, surfaceNormal);
    } else {
        surfaceDistance = glassCubeEntry(localEye, localDirection, surfaceNormal);
    }
    if (surfaceDistance <= 0.0) {
        discard;
    }

    vec3 surfaceView = normalize(viewPosition) * (max(surfaceDistance, MIN_VIEW_DEPTH / worldScale) * worldScale);
    vec4 clipPosition = ProjMat * vec4(surfaceView, 1.0);
    float depth = clipPosition.z / clipPosition.w;
    #ifndef RENDERPEARL_DEPTH_IS_ZERO_TO_ONE
    depth = depth * 0.5 + 0.5;
    #endif
    gl_FragDepth = depth;
    projectionFragmentCoordinates = vec4(gl_FragCoord.xy, depth, gl_FragCoord.w);

    float alpha = projectionColor.a;
    if (alpha < 0.001) {
        discard;
    }
    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(depth, alpha);
    #else
    vec3 color = glassCube(localEye, localDirection, surfaceNormal, surfaceDistance, inside);
    vec4 result = apply_fog(vec4(color * projectionColor.rgb, alpha),
            fog_spherical_distance(surfaceView), fog_cylindrical_distance(surfaceView),
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
    #ifdef OIT_ACCUMULATE
    fragColor = sampleColorForAccumulation(result);
    #else
    fragColor = result;
    #endif
    #endif
}
