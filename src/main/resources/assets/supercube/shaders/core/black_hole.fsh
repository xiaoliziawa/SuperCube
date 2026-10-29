#version 330
#extension GL_ARB_separate_shader_objects : require

#include <projection.glsl>
#include <globals.glsl>
#include <fog.glsl>

vec4 projectionFragmentCoordinates;
// OIT needs the ray-sphere depth, rather than the proxy cube's depth.
#define gl_FragCoord projectionFragmentCoordinates
#include <oit.glsl>
#undef gl_FragCoord

#ifndef OIT_ALPHA_ONLY
#include "supercube:black_hole_scene.glsl"
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
const int INTERIOR_PIXEL_SAMPLES = 2;
const vec2 PIXEL_SAMPLES[4] = vec2[4](vec2(-0.375, -0.125), vec2(0.375, 0.125),
        vec2(-0.125, 0.375), vec2(0.125, -0.375));

void main() {
    if (dot(faceNormal, localCamera - localPosition) >= 0.0) {
        discard;
    }

    vec3 rayVector = localPosition - localCamera;
    vec3 rayDirection = normalize(rayVector);
    float cameraDistanceSquared = dot(localCamera, localCamera);
    float b = dot(localCamera, rayDirection);
    float discriminant = b * b - cameraDistanceSquared + BLACK_HOLE_SCENE_RADIUS * BLACK_HOLE_SCENE_RADIUS;
    if (discriminant <= 0.0) {
        discard;
    }
    float root = sqrt(discriminant);
    if (-b + root <= 0.0) {
        discard;
    }

    float entryDistance = max(-b - root, MIN_VIEW_DEPTH / worldScale);
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
    vec3 pixelX = dFdx(rayVector);
    vec3 pixelY = dFdy(rayVector);
    int samples = quality & ((1 << BLACK_HOLE_QUALITY_STEP_SHIFT) - 1);
    int steps = (quality & ((1 << BLACK_HOLE_DISK_BRIGHTNESS_SHIFT) - 1)) >> BLACK_HOLE_QUALITY_STEP_SHIFT;
    float diskBrightness = float(quality >> BLACK_HOLE_DISK_BRIGHTNESS_SHIFT);
    bool insideProjection = cameraDistanceSquared < BLACK_HOLE_SCENE_RADIUS * BLACK_HOLE_SCENE_RADIUS;
    int diskSamples = insideProjection ? INTERIOR_DISK_SAMPLES : MAX_DISK_SAMPLES;
    if (insideProjection) {
        samples = min(samples, INTERIOR_PIXEL_SAMPLES);
    }
    vec2 sampleCenter = samples == 1 ? PIXEL_SAMPLES[0]
            : samples == 3 ? (PIXEL_SAMPLES[0] + PIXEL_SAMPLES[1] + PIXEL_SAMPLES[2]) / 3.0 : vec2(0.0);
    vec3 color = vec3(0.0);
    for (int sampleIndex = 0; sampleIndex < samples; sampleIndex++) {
        vec2 jitter = PIXEL_SAMPLES[sampleIndex] - sampleCenter;
        Ray ray = Ray(localCamera, normalize(rayVector + jitter.x * pixelX + jitter.y * pixelY));
        color += radiance(ray, animationTime, ScreenSize.x, steps, diskBrightness, diskSamples);
    }
    color = color / float(samples) * projectionColor.rgb;
    vec3 worldPosition = rayDirection * (entryDistance * worldScale);
    vec4 result = apply_fog(vec4(color, alpha), fog_spherical_distance(worldPosition), fog_cylindrical_distance(worldPosition),
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
    #ifdef OIT_ACCUMULATE
    fragColor = sampleColorForAccumulation(result);
    #else
    fragColor = result;
    #endif
    #endif
}
