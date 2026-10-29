#include <dynamictransforms.glsl>
#include <projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in vec2 UV3;

layout(location = 0) out vec3 localPosition;
layout(location = 1) flat out vec3 localCamera;
layout(location = 2) flat out vec3 faceNormal;
layout(location = 3) out vec3 viewPosition;
layout(location = 4) flat out vec4 projectionColor;
layout(location = 5) flat out float animationTime;
layout(location = 6) flat out float worldScale;
layout(location = 7) flat out int quality;

void main() {
    int encodedCorner = int(UV0.x + 0.5);
    int face = encodedCorner >> 2;
    int corner = encodedCorner & 3;
    int axis = face >> 1;
    float direction = (face & 1) == 0 ? -1.0 : 1.0;
    vec2 coordinates = vec2(corner == 0 || corner == 3 ? -1.0 : 1.0, corner < 2 ? -1.0 : 1.0);
    vec3 normal = vec3(0.0);
    normal[axis] = direction;
    vec3 right = axis == 0 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 up = cross(normal, right);
    localPosition = (normal + right * coordinates.x + up * coordinates.y) * PROJECTION_SCENE_RADIUS;

    vec3 centerView = (ModelViewMat * vec4(Position, 1.0)).xyz;
    localCamera = -transpose(mat3(ModelViewMat)) * centerView / UV3.x;
    viewPosition = centerView + mat3(ModelViewMat) * (localPosition * UV3.x);
    gl_Position = ProjMat * vec4(viewPosition, 1.0);
    faceNormal = normal;
    projectionColor = Color * ColorModulator;
    animationTime = UV0.y;
    worldScale = UV3.x;
    quality = int(UV3.y + 0.5);
}
