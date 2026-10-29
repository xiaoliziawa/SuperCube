#ifndef SUPERCUBE_BLACK_HOLE_SCENE_GLSL
#define SUPERCUBE_BLACK_HOLE_SCENE_GLSL

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

const float PI = 3.1415926;
const float TWO_PI = 6.2831852;
const float EPSILON = 0.00001;
const float BLACK_HOLE_RADIUS = 0.1;
const float RING_INNER_RADIUS = BLACK_HOLE_RADIUS + 0.8;
const float RING_OUTER_RADIUS = 6.0;
const float RING_THICKNESS = 0.15;
const float GRAVITY = 0.50;
const float REFERENCE_CAMERA_DISTANCE = 8.0;
const float REFERENCE_MARCH_START = 2.5;
const float REFERENCE_MARCH_STEPS = 64.0;
const float REFERENCE_MARCH_STEP = 0.285;
const float DISK_SAMPLE_LENGTH = 0.04;
const int MAX_DISK_SAMPLES = 8;
const int INTERIOR_DISK_SAMPLES = 4;
const float NOISE_TEXTURE_SIZE = 256.0;

struct Ray {
    vec3 origin;
    vec3 dir;
};

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    vec2 uv = p.xy + vec2(37.0, 17.0) * p.z + f.xy;
    vec2 rg = textureLod(Sampler0, (uv + 0.5) / NOISE_TEXTURE_SIZE, 0.0).yx;
    return -1.0 + 2.0 * mix(rg.x, rg.y, f.z);
}

float map5(vec3 p) {
    vec3 q = p;
    float f = 0.5 * noise(q);
    q *= 2.02;
    f += 0.25 * noise(q);
    q *= 2.03;
    f += 0.125 * noise(q);
    q *= 2.01;
    f += 0.0625 * noise(q);
    q *= 2.02;
    f += 0.03125 * noise(q);
    return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

float tri(float x) {
    return abs(fract(x) - 0.5);
}

vec3 hash33(vec3 p) {
    p = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p += dot(p.yzx, p.xyz + vec3(21.5351, 14.3137, 15.3219));
    return fract(vec3(p.x * p.z * 95.4337, p.x * p.y * 97.597, p.y * p.z * 93.8365));
}

vec3 stars(vec3 p, float resolution) {
    vec3 color = vec3(0.0);
    float res = resolution * 0.85 * radians(50.0);
    p.x += (tri(p.z * 50.0) + tri(p.y * 50.0)) * 0.006;
    p.y += (tri(p.z * 50.0) + tri(p.x * 50.0)) * 0.006;
    p.z += (tri(p.x * 50.0) + tri(p.y * 50.0)) * 0.006;

    for (int layer = 0; layer < 3; layer++) {
        vec3 q = fract(p * (0.15 * res)) - 0.5;
        vec3 id = floor(p * (0.15 * res));
        float random = hash33(id).z;
        float star = 1.0 - smoothstep(-0.2, 0.4, length(q));
        star *= step(random, 0.005 + float(layer) * 0.014);
        color += star * (mix(vec3(1.0, 0.75, 0.5), vec3(0.85, 0.9, 1.0), random * 30.0) * 0.5 + 0.5);
        p *= 1.15;
    }
    return color * color * 1.5;
}

vec3 getBgColor(vec3 direction, float resolution) {
    float rho = max(length(direction), EPSILON);
    float phi = asin(clamp(direction.y / rho, -1.0, 1.0));
    float theta = atan(direction.z, direction.x);
    vec3 background = textureLod(Sampler1, vec2(phi / PI, theta / TWO_PI), 0.0).xyz * 0.3;
    return background.bgr * 0.4 + stars(direction, resolution) * 2.0;
}

void getCloudColorAndDensity(vec3 p, float time, out vec4 color, out float density) {
    color = vec4(0.0);
    density = 0.0;
    if (abs(p.y) >= RING_THICKNESS) {
        return;
    }
    float rho = (length(p) - RING_INNER_RADIUS) / (RING_OUTER_RADIUS - RING_INNER_RADIUS);
    if (rho <= 0.0 || rho >= 1.0) {
        return;
    }

    float cloudX = sqrt(rho);
    float cloudY = (p.y + RING_THICKNESS) / (2.0 * RING_THICKNESS);
    float cloudZ = atan(p.z, p.x) / TWO_PI;
    float blending = rho > 0.2 ? 1.0 - (rho - 0.2) / (0.8 * rho) : rho * 5.0;
    blending *= cloudY > 0.5 ? 1.0 - (cloudY - 0.5) * 2.0 : cloudY * 2.0;
    vec3 moving = vec3(time * 0.5, 0.0, time * rho * 0.1);
    vec3 localCoord = vec3(cloudX * rho * rho, -0.02 * cloudY, cloudZ);
    density = blending * map5((localCoord + moving) * 100.0);
    color = 5.0 * mix(vec4(1.0, 0.9, 0.4, rho * density), vec4(1.0, 0.3, 0.1, rho * density), rho);
}

void integrateDisk(vec3 position, vec3 direction, float stepLength, int maxSamples, float time,
        inout vec3 emission, inout float transmittance) {
    float start = 0.0;
    float end = stepLength;
    if (abs(direction.y) > EPSILON) {
        // Clip the segment to the thin disk so coarse ray steps cannot skip it.
        vec2 intersections = (vec2(-RING_THICKNESS, RING_THICKNESS) - position.y) / direction.y;
        start = max(min(intersections.x, intersections.y), 0.0);
        end = min(max(intersections.x, intersections.y), stepLength);
        if (end <= start) {
            return;
        }
    } else if (abs(position.y) >= RING_THICKNESS) {
        return;
    }

    int samples = int(clamp(ceil((end - start) / DISK_SAMPLE_LENGTH), 1.0, float(maxSamples)));
    float sampleLength = (end - start) / float(samples);
    for (int sampleIndex = 0; sampleIndex < samples; sampleIndex++) {
        vec3 point = position + direction * (start + (float(sampleIndex) + 0.5) * sampleLength);
        float density;
        vec4 ringColor;
        getCloudColorAndDensity(point, time, ringColor, density);
        ringColor *= sampleLength;
        float tau = density * (1.0 - ringColor.w) * sampleLength;
        transmittance *= exp(-tau);
        emission += transmittance * density * ringColor.rgb;
    }
}

vec3 radiance(Ray ray, float time, float resolution, int steps, float diskBrightness, int diskSamples) {
    vec3 sum = vec3(0.0);
    float marchingStep = REFERENCE_MARCH_STEP * REFERENCE_MARCH_STEPS / float(steps);
    float marchingStart = max(length(ray.origin) - REFERENCE_CAMERA_DISTANCE + REFERENCE_MARCH_START, 0.0);
    Ray currentRay = Ray(ray.origin + ray.dir * marchingStart, ray.dir);
    float transmittance = 1.0;
    vec2 diskBoundsSquared = vec2(max(RING_INNER_RADIUS - marchingStep, 0.0), RING_OUTER_RADIUS + marchingStep);
    diskBoundsSquared *= diskBoundsSquared;
    float captureDistanceSquared = BLACK_HOLE_RADIUS + marchingStep;
    captureDistanceSquared *= captureDistanceSquared;
    float cloudTime = time * 0.1;

    for (int i = 0; i < steps && transmittance > 0.001; i++) {
        vec3 p = currentRay.origin;
        float distanceSquared = dot(p, p);
        if (distanceSquared <= BLACK_HOLE_RADIUS * BLACK_HOLE_RADIUS) {
            return clamp(sum * diskBrightness, 0.0, 1.0);
        }
        vec3 gravity = -p * inversesqrt(distanceSquared) * (GRAVITY / distanceSquared);
        vec3 nextDirection = currentRay.dir + marchingStep * gravity;
        float directionLengthSquared = dot(nextDirection, nextDirection);
        if (directionLengthSquared <= EPSILON) {
            return clamp(sum * diskBrightness, 0.0, 1.0);
        }
        currentRay.dir = nextDirection * inversesqrt(directionLengthSquared);
        if (distanceSquared <= captureDistanceSquared) {
            // A whole segment can cross the core between two marching positions.
            vec3 closestPoint = p + currentRay.dir * clamp(-dot(p, currentRay.dir), 0.0, marchingStep);
            if (dot(closestPoint, closestPoint) <= BLACK_HOLE_RADIUS * BLACK_HOLE_RADIUS) {
                return clamp(sum * diskBrightness, 0.0, 1.0);
            }
        }
        if (distanceSquared >= diskBoundsSquared.x && distanceSquared <= diskBoundsSquared.y) {
            integrateDisk(p, currentRay.dir, marchingStep, diskSamples, cloudTime, sum, transmittance);
        }
        currentRay.origin += currentRay.dir * marchingStep;
    }
    return clamp(getBgColor(currentRay.dir, resolution) * transmittance + sum * diskBrightness, 0.0, 1.0);
}

#endif
