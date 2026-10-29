#version 330
#extension GL_ARB_separate_shader_objects : require

#include <dynamictransforms.glsl>
#include <projection.glsl>
#include <fog.glsl>

vec4 projectionFragmentCoordinates;
#define gl_FragCoord projectionFragmentCoordinates
#include <oit.glsl>
#undef gl_FragCoord

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

layout(location = 0) in vec3 localPosition;
layout(location = 1) flat in vec3 localCamera;
layout(location = 2) flat in vec3 faceNormal;
layout(location = 3) flat in vec3 centerView;
layout(location = 4) flat in vec4 projectionColor;
layout(location = 5) flat in float animationTime;
layout(location = 6) flat in float worldScale;

const float PI = 3.14159265359;
const float ORIENTATION_X = 0.955316618;
const float ORIENTATION_Y = 0.785398163;
const float CELL_SPACING = 0.6;
const float CELL_HALF_SIZE = 0.55;
const float SURFACE_EPSILON = 0.0005;
const float NORMAL_EPSILON = 0.001;

mat2 rot(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, sine, -sine, cosine);
}

float box(vec3 point, vec3 bounds) {
    vec3 q = abs(point) - bounds;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

vec3 cubeSpace(vec3 point) {
    point.yz *= rot(-ORIENTATION_X);
    point.xz *= rot(ORIENTATION_Y);
    return point;
}

vec2 cubeDistance(vec3 point, float time) {
    point = cubeSpace(point);
    float animation = mod(time * 3.0, PI * 9.0);
    float rotations[16];
    for (int index = 0; index < 16; index++) {
        float stepIndex = float(index) * 0.5;
        float direction = index < 8 ? 1.0 : -1.0;
        rotations[index] = direction * PI * smoothstep(stepIndex * PI, (stepIndex + 0.5) * PI, animation);
    }

    point.xz *= rot(rotations[15] * step(0.6, point.y));
    point.xy *= rot(rotations[14] * step(0.6, point.z));
    point.yz *= rot(rotations[13] * step(0.6, point.x));
    point.xz *= rot(rotations[12] * step(0.6, -point.y));
    point.xy *= rot(rotations[11] * step(0.6, -point.z));
    point.yz *= rot(rotations[10] * step(0.6, -point.x));
    point.xz *= rot(rotations[9] * step(0.6, point.y));
    point.xy *= rot(rotations[8] * step(0.6, point.z));
    point.xy *= rot(rotations[7] * step(0.6, point.z));
    point.xz *= rot(rotations[6] * step(0.6, point.y));
    point.yz *= rot(rotations[5] * step(0.6, -point.x));
    point.xy *= rot(rotations[4] * step(0.6, -point.z));
    point.xz *= rot(rotations[3] * step(0.6, -point.y));
    point.yz *= rot(rotations[2] * step(0.6, point.x));
    point.xy *= rot(rotations[1] * step(0.6, point.z));
    point.xz *= rot(rotations[0] * step(0.6, point.y));

    float material = 0.0;
    if (point.x > 1.73) material = 1.0;
    else if (point.y > 1.73) material = 2.0;
    else if (point.z > 1.73) material = 3.0;
    else if (point.x < -1.73) material = 4.0;
    else if (point.z < -1.73) material = 5.0;
    else if (point.y < -1.73) material = 6.0;
    point = abs(point) - vec3(CELL_SPACING);
    point = abs(point) - vec3(CELL_SPACING);
    return vec2(box(point, vec3(CELL_HALF_SIZE)) - 0.03, material);
}

vec2 marchCube(vec3 origin, vec3 direction, float maxDistance, float time, out vec3 hitPosition) {
    float distanceTravelled = 0.0;
    for (int stepIndex = 0; stepIndex < 300; stepIndex++) {
        if (distanceTravelled > maxDistance) {
            break;
        }
        vec3 point = origin + direction * distanceTravelled;
        vec2 distanceMaterial = cubeDistance(point, time);
        if (abs(distanceMaterial.x) < SURFACE_EPSILON) {
            hitPosition = point;
            return vec2(distanceTravelled, distanceMaterial.y);
        }
        distanceTravelled += distanceMaterial.x * 0.5;
    }
    return vec2(-1.0);
}

vec3 cubeNormal(vec3 point, float time) {
    vec2 offset = vec2(NORMAL_EPSILON, 0.0);
    return normalize(vec3(
            cubeDistance(point + offset.xyy, time).x - cubeDistance(point - offset.xyy, time).x,
            cubeDistance(point + offset.yxy, time).x - cubeDistance(point - offset.yxy, time).x,
            cubeDistance(point + offset.yyx, time).x - cubeDistance(point - offset.yyx, time).x));
}

void main() {
    if (dot(faceNormal, localCamera - localPosition) >= 0.0) {
        discard;
    }

    vec3 rayVector = localPosition - localCamera;
    float rayLength = length(rayVector);
    if (rayLength <= SURFACE_EPSILON) {
        discard;
    }
    vec3 rayDirection = rayVector / rayLength;
    vec3 hitPosition;
    vec2 hit = marchCube(localCamera, rayDirection, rayLength, animationTime, hitPosition);
    if (hit.x < 0.0) {
        discard;
    }

    vec3 hitView = centerView + mat3(ModelViewMat) * (hitPosition * worldScale);
    vec4 clipPosition = ProjMat * vec4(hitView, 1.0);
    float depth = clipPosition.z / clipPosition.w;
    #ifndef RENDERPEARL_DEPTH_IS_ZERO_TO_ONE
    depth = depth * 0.5 + 0.5;
    #endif
    gl_FragDepth = depth;
    projectionFragmentCoordinates = vec4(gl_FragCoord.xy, depth, gl_FragCoord.w);

    vec3 normal = cubeNormal(hitPosition, animationTime);
    float facing = max(dot(normal, -rayDirection), 0.0);
    float edge = pow(1.0 - facing, 2.0);
    vec3 materialColor = vec3(0.08, 0.75, 0.12);
    if (hit.y == 1.0) materialColor = vec3(0.92, 0.04, 0.04);
    else if (hit.y == 2.0) materialColor = vec3(0.96, 0.96, 0.92);
    else if (hit.y == 3.0) materialColor = vec3(0.05, 0.22, 0.95);
    else if (hit.y == 4.0) materialColor = vec3(1.0, 0.32, 0.03);
    else if (hit.y == 5.0) materialColor = vec3(0.02, 0.62, 0.12);
    else if (hit.y == 6.0) materialColor = vec3(1.0, 0.84, 0.02);
    materialColor = mix(materialColor, vec3(1.0), edge * 0.08);
    float alpha = min(0.98, projectionColor.a * (0.94 + edge * 0.04));
    if (alpha < 0.001) {
        discard;
    }

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(depth, alpha);
    #else
    vec4 result = apply_fog(vec4(materialColor * projectionColor.rgb, alpha),
            fog_spherical_distance(hitPosition * worldScale), fog_cylindrical_distance(hitPosition * worldScale),
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
        #ifdef OIT_ACCUMULATE
        fragColor = sampleColorForAccumulation(result);
        #else
        fragColor = result;
        #endif
    #endif
}
