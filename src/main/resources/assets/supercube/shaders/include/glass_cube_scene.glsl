#ifndef SUPERCUBE_GLASS_CUBE_SCENE_GLSL
#define SUPERCUBE_GLASS_CUBE_SCENE_GLSL

// Adapted from "Self" by Danil (2021+), https://www.shadertoy.com/view/NslGRN
// Licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported.

#include <globals.glsl>
#include "supercube:glass_cube_bounds.glsl"

const float PI = 3.1415926;
const float IOR = 1.33;
const float PATCH_SIZE = 0.5 * GLASS_CUBE_SCENE_SCALE;
const float PATCH_BOUNDS = 1.0 * GLASS_CUBE_SCENE_SCALE;
const float EDGE_FADE_WIDTH = 0.075 * GLASS_CUBE_SCENE_SCALE;
const float EXIT_HEIGHT_CLAMP = -0.999 * GLASS_CUBE_SCENE_SCALE;
const float DEGENERATE_QUADRATIC = 0.000001;
const vec3 PATCH_TINT = vec3(1.0, 0.21, 0.11);

mat3 rotx(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));
}

mat3 roty(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));
}

vec3 fcos(vec3 x) {
    vec3 w = fwidth(x);
    float lengthW = length(w);
    if (lengthW == 0.0 || isnan(lengthW) || isinf(lengthW)) {
        vec3 average = vec3(0.0);
        for (int i = 0; i < 8; i++) {
            average += cos(x + x * float(i - 4) * (0.01 * 400.0 / float(ScreenSize.y)));
        }
        return average / 8.0;
    }
    return cos(x) * (1.0 - smoothstep(0.0, 6.2831852, w));
}

vec3 getColor(vec3 p) {
    p = abs(p);
    p *= 1.25;
    p = 0.5 * p / max(dot(p, p), DEGENERATE_QUADRATIC);

    float t = 0.13 * length(p);
    vec3 col = vec3(0.3, 0.4, 0.5);
    col += 0.12 * fcos(6.28318 * t * 1.0 + vec3(0.0, 0.8, 1.1));
    col += 0.11 * fcos(6.28318 * t * 3.1 + vec3(0.3, 0.4, 0.1));
    col += 0.10 * fcos(6.28318 * t * 5.1 + vec3(0.1, 0.7, 1.1));
    col += 0.10 * fcos(6.28318 * t * 17.1 + vec3(0.2, 0.6, 0.7));
    col += 0.10 * fcos(6.28318 * t * 31.1 + vec3(0.1, 0.6, 0.7));
    col += 0.10 * fcos(6.28318 * t * 65.1 + vec3(0.0, 0.5, 0.8));
    col += 0.10 * fcos(6.28318 * t * 115.1 + vec3(0.1, 0.4, 0.7));
    col += 0.10 * fcos(6.28318 * t * 265.1 + vec3(1.1, 1.4, 2.7));
    return clamp(col, 0.0, 1.0);
}

float patchEdgeFade(vec3 position) {
    return 1.0 - smoothstep(PATCH_BOUNDS - EDGE_FADE_WIDTH, PATCH_BOUNDS + 0.00001, length(position));
}

vec4 shadePatch(vec3 position, vec3 normal, vec3 lightDir, float edgeAlpha) {
    float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0);
    float ambient = clamp(0.5 + 0.5 * dot(normal, lightDir), 0.0, 1.0);
    vec3 shading = vec3(0.32, 0.43, 0.54) * ambient + vec3(1.0, 0.9, 0.7) * diffuse;
    vec3 color = getColor(position / GLASS_CUBE_SCENE_SCALE);
    float brightness = clamp(length(color), 0.0, 1.0);
    color = clamp(color * color * 2.0, 0.0, 1.0);
    vec4 shaded = vec4(color * shading * 1.4
            + 3.0 * (PATCH_TINT * color) * clamp(1.0 - (ambient + diffuse), 0.0, 1.0),
            min(edgeAlpha, brightness));
    shaded.rgb = clamp(2.0 * shaded.rgb * shaded.rgb, 0.0, 1.0);
    return shaded;
}

void calcColor(vec3 ro, vec3 rd, float distance, bool selfIntersect, float selfDistance,
        out vec4 layerColor, out vec4 selfColor) {
    vec3 pos = ro + rd * distance;
    layerColor = vec4(getColor(pos / GLASS_CUBE_SCENE_SCALE), patchEdgeFade(pos));
    selfColor = vec4(0.0);
    if (selfIntersect) {
        pos = ro + rd * selfDistance;
        selfColor = vec4(getColor(pos / GLASS_CUBE_SCENE_SCALE), patchEdgeFade(pos));
    }
}

bool iBilinearPatch(vec3 ro, vec3 rd, vec4 ps, vec4 ph, out float distance, out vec3 normal,
        out bool selfIntersect, out float selfDistance, out vec3 selfNormal, out float fade, out float selfFade) {
    vec3 va = vec3(0.0, 0.0, ph.x + ph.w - ph.y - ph.z);
    vec3 vb = vec3(0.0, ps.w - ps.y, ph.z - ph.x);
    vec3 vc = vec3(ps.z - ps.x, 0.0, ph.y - ph.x);
    vec3 vd = vec3(ps.xy, ph.x);
    distance = -1.0;
    selfDistance = -1.0;
    selfIntersect = false;
    fade = 1.0;
    selfFade = 1.0;
    normal = vec3(0.0, 1.0, 0.0);
    selfNormal = vec3(0.0, 1.0, 0.0);

    float tmp = 1.0 / (vb.y * vc.x);
    float a = 0.0;
    float b = 0.0;
    float c = 0.0;
    float d = va.z * tmp;
    float e = 0.0;
    float f = 0.0;
    float g = (vc.z * vb.y - vd.y * va.z) * tmp;
    float h = (vb.z * vc.x - va.z * vd.x) * tmp;
    float i = -1.0;
    float j = (vd.x * vd.y * va.z + vd.z * vb.y * vc.x) * tmp
            - (vd.y * vb.z * vc.x + vd.x * vc.z * vb.y) * tmp;

    float p = dot(vec3(a, b, c), rd.xzy * rd.xzy) + dot(vec3(d, e, f), rd.xzy * rd.zyx);
    float q = dot(vec3(2.0) * ro.xzy * rd.xyz, vec3(a, b, c)) + dot(ro.xzz * rd.zxy, vec3(d, d, e))
            + dot(ro.yyx * rd.zxy, vec3(e, f, f)) + dot(vec3(g, h, i), rd.xzy);
    float r = dot(vec3(a, b, c), ro.xzy * ro.xzy) + dot(vec3(d, e, f), ro.xzy * ro.zyx)
            + dot(vec3(g, h, i), ro.xzy) + j;

    if (abs(p) < DEGENERATE_QUADRATIC) {
        float hitDistance = -r / q;
        if (hitDistance <= 0.0) {
            return false;
        }
        distance = hitDistance;
        vec3 pos = ro + hitDistance * rd;
        if (length(pos) > PATCH_BOUNDS) {
            return false;
        }
        vec3 grad = vec3(2.0) * pos.xzy * vec3(a, b, c) + pos.zxz * vec3(d, d, e)
                + pos.yyx * vec3(f, e, f) + vec3(g, h, i);
        normal = -normalize(grad);
        return true;
    }

    float sq = q * q - 4.0 * p * r;
    if (sq < 0.0) {
        return false;
    }
    float s = sqrt(sq);
    float t0 = (-q + s) / (2.0 * p);
    float t1 = (-q - s) / (2.0 * p);
    float nearHit = min(t0 < 0.0 ? t1 : t0, t1 < 0.0 ? t0 : t1);
    float farHit = max(t0 > 0.0 ? t1 : t0, t1 > 0.0 ? t0 : t1);
    if (nearHit <= 0.0) {
        return false;
    }
    vec3 pos = ro + nearHit * rd;
    bool outside = bool(length(pos) >= PATCH_BOUNDS);
    if (outside) {
        nearHit = farHit;
        pos = ro + nearHit * rd;
    }
    if (nearHit <= 0.0) {
        return false;
    }
    if (length(pos) >= PATCH_BOUNDS) {
        return false;
    }

    if (farHit > 0.0 && !outside && length(ro + farHit * rd) < PATCH_BOUNDS) {
        selfIntersect = true;
        selfFade = s;
        selfDistance = farHit;
        vec3 selfPos = ro + selfDistance * rd;
        vec3 selfGrad = vec3(2.0) * selfPos.xzy * vec3(a, b, c) + selfPos.zxz * vec3(d, d, e)
                + selfPos.yyx * vec3(f, e, f) + vec3(g, h, i);
        selfNormal = -normalize(selfGrad);
    }

    fade = s;
    distance = nearHit;
    vec3 grad = vec3(2.0) * pos.xzy * vec3(a, b, c) + pos.zxz * vec3(d, d, e)
            + pos.yyx * vec3(f, e, f) + vec3(g, h, i);
    normal = -normalize(grad);
    return true;
}

// The three saddle sheets that fill the box. Each is the surface x * z + PATCH_SIZE * y = 0, clipped to
// a sphere of PATCH_BOUNDS and rotated about the face normal by a third of a turn.
vec4 insides(vec3 ro, vec3 rd, vec3 faceNormal, vec3 lightDir, out float farthest) {
    farthest = -1.0;
    if (abs(faceNormal.x) > 0.5) {
        rd = rd.xzy * faceNormal.x;
        ro = ro.xzy * faceNormal.x;
    } else if (abs(faceNormal.z) > 0.5) {
        lightDir *= roty(PI);
        rd = rd.yxz * faceNormal.z;
        ro = ro.yxz * faceNormal.z;
    } else if (abs(faceNormal.y) > 0.5) {
        lightDir *= rotz(-PI * 0.5);
        rd = rd * faceNormal.y;
        ro = ro * faceNormal.y;
    }

    vec4 ps = vec4(-1.0, -1.0, 1.0, 1.0) * PATCH_SIZE;
    vec4 ph = vec4(-1.0, 1.0, 1.0, -1.0) * PATCH_SIZE;

    vec4 layerColor[3] = vec4[3](vec4(0.0), vec4(0.0), vec4(0.0));
    vec3 layerDistance[3] = vec3[3](vec3(-1.0), vec3(-1.0), vec3(-1.0));
    vec4 selfColor[3] = vec4[3](vec4(0.0), vec4(0.0), vec4(0.0));
    int order[3] = int[3](0, 1, 2);

    for (int i = 0; i < 3; i++) {
        if (abs(faceNormal.x) > 0.5) {
            ro *= rotz(-PI * (1.0 / 3.0));
            rd *= rotz(-PI * (1.0 / 3.0));
        } else if (abs(faceNormal.z) > 0.5) {
            ro *= rotz(PI * (1.0 / 3.0));
            rd *= rotz(PI * (1.0 / 3.0));
        } else if (abs(faceNormal.y) > 0.5) {
            ro *= rotx(PI * (1.0 / 3.0));
            rd *= rotx(PI * (1.0 / 3.0));
        }

        float hitDistance;
        vec3 hitNormal;
        bool selfIntersect;
        float selfDistance;
        vec3 selfNormal;
        float fade;
        float selfFade;
        if (!iBilinearPatch(ro, rd, ps, ph, hitDistance, hitNormal, selfIntersect, selfDistance, selfNormal,
                fade, selfFade) || hitDistance <= 0.0) {
            continue;
        }
        vec4 color;
        vec4 colorSelf;
        calcColor(ro, rd, hitDistance, selfIntersect, selfDistance, color, colorSelf);
        if (color.a <= 0.0) {
            continue;
        }

        layerDistance[i] = vec3(hitDistance, float(selfIntersect), selfDistance);
        layerColor[i] = shadePatch(ro + rd * hitDistance, hitNormal, lightDir, color.a) * min(fade * 5.0, 1.0);

        if (selfIntersect) {
            vec4 shadedSelf = shadePatch(ro + rd * selfDistance, selfNormal, lightDir, colorSelf.a);
            shadedSelf.rgb *= min(selfFade * 5.0, 1.0);
            selfColor[i] = shadedSelf;
        }
    }

    if (layerDistance[0].x < layerDistance[1].x) {
        vec3 swapDistance = vec3(layerDistance[0]);
        layerDistance[0] = layerDistance[1];
        layerDistance[1] = swapDistance;
        int swapOrder = order[0];
        order[0] = order[1];
        order[1] = swapOrder;
    }
    if (layerDistance[1].x < layerDistance[2].x) {
        vec3 swapDistance = vec3(layerDistance[1]);
        layerDistance[1] = layerDistance[2];
        layerDistance[2] = swapDistance;
        int swapOrder = order[1];
        order[1] = order[2];
        order[2] = swapOrder;
    }
    if (layerDistance[0].x < layerDistance[1].x) {
        vec3 swapDistance = vec3(layerDistance[0]);
        layerDistance[0] = layerDistance[1];
        layerDistance[1] = swapDistance;
        int swapOrder = order[0];
        order[0] = order[1];
        order[1] = swapOrder;
    }

    farthest = max(max(layerDistance[0].x, layerDistance[1].x), layerDistance[2].x);

    float alpha = layerDistance[0].y < 0.5 ? layerColor[order[0]].a : 1.0;
    bool selfRules[3] = bool[3](
            layerDistance[0].y > 0.5 && layerDistance[1].x <= 0.0,
            layerDistance[1].y > 0.5 && layerDistance[0].x > layerDistance[1].z,
            layerDistance[2].y > 0.5 && layerDistance[1].x > layerDistance[2].z);
    for (int k = 0; k < 3; k++) {
        if (selfRules[k]) {
            vec4 colorSelf = vec4(selfColor[order[k]]);
            vec4 color = vec4(layerColor[order[k]]);
            layerColor[order[k]] = mix(vec4(0.0), mix(colorSelf, color, color.a), max(color.a, colorSelf.a));
        }
    }

    float alpha1 = layerDistance[1].y < 0.5 ? layerColor[order[1]].a
            : (layerDistance[1].z > layerDistance[0].x ? layerColor[order[1]].a : 1.0);
    float alpha2 = layerDistance[2].y < 0.5 ? layerColor[order[2]].a
            : (layerDistance[2].z > layerDistance[1].x ? layerColor[order[2]].a : 1.0);
    vec3 col = mix(mix(layerColor[order[0]].rgb, layerColor[order[1]].rgb, alpha1),
            layerColor[order[2]].rgb, alpha2);
    return vec4(col, max(max(alpha, alpha1), alpha2));
}

vec3 environmentColor(vec3 rd) {
    return mix(vec3(0.01), vec3(0.336, 0.458, 0.668), 1.0 - pow(abs(rd.z + 0.25), 1.3));
}

vec3 glassCube(vec3 localEye, vec3 localDirection, vec3 surfaceNormal, float surfaceDistance, bool inside) {
    vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0)) * rotz(0.5);
    vec3 surface = localEye + surfaceDistance * localDirection;
    vec2 borderCoordinates = surface.xy * surfaceNormal.z / GLASS_CUBE_BOX_DIMS.xy
            + surface.yz * surfaceNormal.x / GLASS_CUBE_BOX_DIMS.yz
            + surface.zx * surfaceNormal.y / GLASS_CUBE_BOX_DIMS.zx;
    float borderFade = (1.0 - smoothstep(0.915, 1.05, abs(borderCoordinates.x)))
            * (1.0 - smoothstep(0.915, 1.05, abs(borderCoordinates.y)));

    float reflectance = (IOR - 1.0) / (IOR + 1.0);
    reflectance *= reflectance;
    vec3 reflection = environmentColor(reflect(localDirection, surfaceNormal));
    vec3 refractedDirection = inside ? localDirection : refract(localDirection, surfaceNormal, 1.0 / IOR);

    float transmission = 1.0;
    vec3 exitNormal = surfaceNormal;
    vec3 exitOrigin = inside ? localEye : surface;
    if (inside) {
        glassCubeExit(localEye, -localDirection, exitNormal);
    }
    vec4 layers[2] = vec4[2](vec4(0.0), vec4(0.0));

    for (int bounce = 0; bounce < 2; bounce++) {
        vec2 faceCoordinates = exitOrigin.xy * exitNormal.z + exitOrigin.yz * exitNormal.x
                + exitOrigin.zx * exitNormal.y;
        float innerDepth = -PATCH_BOUNDS;
        if (inside && bounce == 0) {
            innerDepth += dot(GLASS_CUBE_BOX_DIMS, abs(exitNormal)) - dot(exitOrigin, exitNormal);
        }
        vec3 innerOrigin = vec3(faceCoordinates, innerDepth);
        vec3 innerDirection = refractedDirection.yzx * exitNormal.x + refractedDirection.zxy * exitNormal.y
                + refractedDirection.xyz * exitNormal.z;
        innerDirection.z = -innerDirection.z;
        float farthest;
        vec4 innerColor = insides(innerOrigin, innerDirection, exitNormal, lightDir, farthest);
        if (farthest > 0.0) {
            layers[bounce] = vec4(innerColor.rgb * transmission, innerColor.a);
        }
        if (farthest <= 0.0 || innerColor.a < 1.0) {
            float exitDistance = glassCubeExit(exitOrigin, refractedDirection, exitNormal);
            vec3 exitPoint = exitOrigin + exitDistance * refractedDirection;
            exitNormal = exitNormal.xzy;
            vec3 outDirection = refract(refractedDirection, -exitNormal, IOR);
            float fresnel = reflectance
                    + (1.0 - reflectance) * pow(max(1.0 - dot(outDirection, exitNormal), 0.0), 1.3);
            refractedDirection = reflect(refractedDirection, -exitNormal);
            exitOrigin = exitPoint;
            exitOrigin.z = max(exitOrigin.z, EXIT_HEIGHT_CLAMP);
            transmission *= fresnel;
        }
    }

    float incidence = dot(inside ? localDirection : -localDirection, surfaceNormal);
    float fresnel = reflectance
            + (1.0 - reflectance) * pow(max(1.0 - incidence, 0.0), 5.0);
    vec3 color = mix(mix(layers[1].rgb * layers[1].a, layers[0].rgb, layers[0].a) * borderFade,
            reflection, pow(fresnel, 1.5));
    return clamp(color, 0.0, 1.0);
}

#endif
