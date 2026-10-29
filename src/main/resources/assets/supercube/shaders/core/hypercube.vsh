#version 330
#extension GL_ARB_separate_shader_objects : require

#include <dynamictransforms.glsl>
#include <projection.glsl>
#include <fog.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in vec2 UV3;

layout(location = 0) out vec2 edgeCoordinates;
layout(location = 1) flat out float edgeLength;
layout(location = 2) flat out float edgeWidth;
layout(location = 3) flat out vec4 edgeColor;
layout(location = 4) out float sphericalVertexDistance;
layout(location = 5) out float cylindricalVertexDistance;
layout(location = 6) flat out float animationPhase;

const float EPSILON = 0.00001;
const vec3 AXIS_COLORS[4] = vec3[](
    vec3(0.12, 0.82, 1.0),
    vec3(1.0, 0.22, 0.48),
    vec3(1.0, 0.72, 0.18),
    vec3(0.28, 1.0, 0.66)
);

mat2 planeRotation(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, s, -s, c);
}

vec4 rotateVertex(int index, mat2 xw, mat2 yw, mat2 zw, mat2 xz) {
    vec4 point = vec4(float(index & 1), float((index >> 1) & 1), float((index >> 2) & 1), float((index >> 3) & 1)) * 2.0 - 1.0;
    point.xw = xw * point.xw;
    point.yw = yw * point.yw;
    point.zw = zw * point.zw;
    point.xz = xz * point.xz;
    return point;
}

vec3 projectVertex(vec4 point) {
    return point.xyz * (FOUR_D_CAMERA_DISTANCE / (FOUR_D_CAMERA_DISTANCE - point.w)) * UV3.x;
}

void main() {
    int encodedCorner = int(UV0.x + 0.5);
    int firstVertex = encodedCorner >> 4;
    int axis = (encodedCorner >> 2) & 3;
    int corner = encodedCorner & 3;
    bool atEnd = bool(corner == 1 || corner == 2);
    float side = corner < 2 ? -1.0 : 1.0;

    mat2 xw = planeRotation(UV0.y);
    mat2 yw = planeRotation(UV0.y * 0.6);
    mat2 zw = planeRotation(UV0.y * 0.4);
    mat2 xz = planeRotation(UV0.y * 0.2);
    vec4 first = rotateVertex(firstVertex, xw, yw, zw, xz);
    vec4 second = rotateVertex(firstVertex ^ (1 << axis), xw, yw, zw, xz);
    vec3 center = Position + vec3(0.0, sin(UV0.y * 2.0) * HOVER_AMPLITUDE, 0.0);
    vec3 firstWorld = center + projectVertex(first);
    vec3 secondWorld = center + projectVertex(second);
    vec3 firstView = (ModelViewMat * vec4(firstWorld, 1.0)).xyz;
    vec3 secondView = (ModelViewMat * vec4(secondWorld, 1.0)).xyz;
    vec3 delta = secondView - firstView;
    float lengthView = length(delta);
    vec3 tangent = lengthView > EPSILON ? delta / lengthView : vec3(0.0, 1.0, 0.0);
    vec3 perpendicular = cross(tangent, firstView + secondView);
    if (dot(perpendicular, perpendicular) < EPSILON) {
        perpendicular = cross(tangent, abs(tangent.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0));
    }
    perpendicular = normalize(perpendicular);

    float radius = UV3.y * GLOW_RADIUS;
    vec3 endpoint = atEnd ? secondView : firstView;
    vec3 viewPosition = endpoint + tangent * (atEnd ? radius : -radius) + perpendicular * side * radius;
    gl_Position = ProjMat * vec4(viewPosition, 1.0);

    edgeCoordinates = vec2(atEnd ? lengthView + radius : -radius, side * radius);
    edgeLength = lengthView;
    edgeWidth = UV3.y;
    float depthTint = clamp((first.w + second.w) * 0.125 + 0.5, 0.0, 1.0);
    edgeColor = vec4(mix(AXIS_COLORS[axis], vec3(0.78, 0.88, 1.0), depthTint * 0.35), 1.0) * Color * ColorModulator;
    vec3 worldPosition = atEnd ? secondWorld : firstWorld;
    sphericalVertexDistance = fog_spherical_distance(worldPosition);
    cylindricalVertexDistance = fog_cylindrical_distance(worldPosition);
    animationPhase = UV0.y * 2.0 + float(axis);
}
