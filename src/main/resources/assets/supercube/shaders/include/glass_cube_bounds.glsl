#ifndef SUPERCUBE_GLASS_CUBE_BOUNDS_GLSL
#define SUPERCUBE_GLASS_CUBE_BOUNDS_GLSL

// Shared by every pass, including the OIT alpha-only ones that skip the full scene.

const float GLASS_CUBE_SPIN_SPEED = 0.225;
const float GLASS_CUBE_SCENE_SCALE = 2.0;
const vec3 GLASS_CUBE_BOX_DIMS = vec3(0.75, 0.75, 1.25) * GLASS_CUBE_SCENE_SCALE;

mat3 rotz(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0));
}

float box(vec3 ro, vec3 rd, vec3 halfSize, out vec3 boxNormal, bool entering) {
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 dr = 1.0 / rd;
    vec3 n = ro * dr;
    vec3 k = halfSize * abs(dr);

    vec3 pin = -k - n;
    vec3 pout = k - n;
    float tin = max(pin.x, max(pin.y, pin.z));
    float tout = min(pout.x, min(pout.y, pout.z));
    if (tin > tout) {
        return -1.0;
    }
    if (entering) {
        boxNormal = -sign(rd) * step(pin.zxy, pin.xyz) * step(pin.yzx, pin.xyz);
    } else {
        boxNormal = sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    }
    return entering ? tin : tout;
}

// The source scene is z-up; rotate the player's ray into that space, then spin it around the vertical axis.
void glassCubeLocalRay(vec3 eye, vec3 direction, float time, out vec3 localEye, out vec3 localDirection) {
    float spinAngle = time * GLASS_CUBE_SPIN_SPEED;
    localEye = rotz(spinAngle) * vec3(eye.x, -eye.z, eye.y);
    localDirection = rotz(spinAngle) * vec3(direction.x, -direction.z, direction.y);
}

bool glassCubeInside(vec3 localEye) {
    return all(lessThan(abs(localEye), GLASS_CUBE_BOX_DIMS));
}

float glassCubeEntry(vec3 localEye, vec3 localDirection, out vec3 entryNormal) {
    return box(localEye, localDirection, GLASS_CUBE_BOX_DIMS, entryNormal, true);
}

// From inside the box only the far plane matters. Skipping the near-plane comparison avoids the
// corner pixels where floating-point error makes the slabs cross and the shared box test bails out.
float glassCubeExit(vec3 localEye, vec3 localDirection, out vec3 exitNormal) {
    vec3 rd = localDirection + 0.0001 * (1.0 - abs(sign(localDirection)));
    vec3 dr = 1.0 / rd;
    vec3 pout = GLASS_CUBE_BOX_DIMS * abs(dr) - localEye * dr;
    exitNormal = sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    return min(pout.x, min(pout.y, pout.z));
}

#endif
