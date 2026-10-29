#version 330
#extension GL_ARB_separate_shader_objects : require

#include <dynamictransforms.glsl>
#include <projection.glsl>
#include <fog.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in vec2 UV3;
layout(location = 4) in vec4 Normal;

layout(location = 0) out vec2 beamCoordinates;
layout(location = 1) out vec3 viewPosition;
layout(location = 2) out vec3 viewNormal;
layout(location = 3) flat out vec4 beamColor;
layout(location = 4) out float sphericalVertexDistance;
layout(location = 5) out float cylindricalVertexDistance;
layout(location = 6) flat out float animationPhase;

void main() {
    vec4 position = ModelViewMat * vec4(Position, 1.0);
    gl_Position = ProjMat * position;
    beamCoordinates = UV0;
    viewPosition = position.xyz;
    viewNormal = mat3(ModelViewMat) * Normal.xyz;
    beamColor = Color * ColorModulator;
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    animationPhase = UV3.x;
}
