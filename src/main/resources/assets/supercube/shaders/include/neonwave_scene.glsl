#ifndef SUPERCUBE_NEONWAVE_SCENE_GLSL
#define SUPERCUBE_NEONWAVE_SCENE_GLSL

const float PI = 3.141592654;
const float TAU = 2.0 * PI;
const float EPSILON = 0.0001;
const int TERRAIN_OCTAVES = 5;
const vec2 TERRAIN_FREQUENCY = vec2(0.5, 0.33);
const float TERRAIN_HEIGHT_SCALE = 2.0;
const float TERRAIN_OFFSET = 1.8;
const float TERRAIN_MAX_HEIGHT = (1.9375 - TERRAIN_OFFSET) * TERRAIN_HEIGHT_SCALE;
const float TERRAIN_NORMAL_STEP = 0.015;
const float TERRAIN_SCROLL_SPEED = 0.25;
const vec3 MOON_CENTER = vec3(0.0, 1.7, 5.0);
const float MOON_RADIUS = 1.15;
const int TERRAIN_REFINEMENT_STEPS = 6;
const vec3 LIGHT_DIRECTION = normalize(vec3(0.0, -0.15, 1.0));

vec3 hsv2rgb(vec3 color) {
    const vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(color.xxx + k.xyz) * 6.0 - k.www);
    return color.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), color.y);
}

float tanhApprox(float value) {
    float squared = value * value;
    return clamp(value * (27.0 + squared) / (27.0 + 9.0 * squared), -1.0, 1.0);
}

float hash(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 point) {
    return fract(sin(vec2(dot(point, vec2(127.1, 311.7)), dot(point, vec2(269.5, 183.3)))) * 43758.5453123);
}

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 fraction = fract(point);
    vec2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
            mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), blend.x), blend.y);
}

vec2 terrainHeights(vec2 point, float time) {
    point.y += time * TERRAIN_SCROLL_SPEED;
    point *= TERRAIN_FREQUENCY;
    float high = 0.0;
    float low = 0.0;
    float amplitude = 1.0;
    for (int octave = 0; octave < TERRAIN_OCTAVES; octave++) {
        float value = amplitude * valueNoise(point);
        high += value;
        if (octave < 2) {
            low += value;
        }
        amplitude *= 0.5;
        point *= 2.0;
    }
    return (vec2(high, low) - vec2(TERRAIN_OFFSET, 2.15)) * TERRAIN_HEIGHT_SCALE;
}

bool traceTerrain(vec3 origin, vec3 direction, vec2 interval, float time, int steps, float pixelAngle,
        out vec3 hitPosition, out float hitDistance) {
    float start = interval.x;
    float end = interval.y;
    if (abs(direction.y) < EPSILON) {
        if (origin.y > TERRAIN_MAX_HEIGHT) {
            return false;
        }
    } else {
        float top = (TERRAIN_MAX_HEIGHT - origin.y) / direction.y;
        if (direction.y < 0.0) {
            start = max(start, top);
        } else {
            end = min(end, top);
        }
    }
    float slopeBound = abs(direction.y) + 1.5 * float(TERRAIN_OCTAVES) * TERRAIN_HEIGHT_SCALE
            * dot(abs(direction.xz), TERRAIN_FREQUENCY);
    if (start > end) {
        return false;
    }
    float minimumStep = (end - start) / float(max(steps - 1, 1));
    float previous = start;
    float travel = start;
    for (int stepIndex = 0; stepIndex < steps && travel <= end; stepIndex++) {
        vec3 point = origin + direction * travel;
        float distance = point.y - terrainHeights(point.xz, time).x;
        float tolerance = max(0.001, travel * pixelAngle * 0.35);
        if (distance <= tolerance) {
            float low = previous;
            float high = travel;
            for (int refinement = 0; refinement < TERRAIN_REFINEMENT_STEPS; refinement++) {
                float middle = (low + high) * 0.5;
                vec3 candidate = origin + direction * middle;
                if (candidate.y - terrainHeights(candidate.xz, time).x <= tolerance) {
                    high = middle;
                } else {
                    low = middle;
                }
            }
            hitPosition = origin + direction * high;
            hitDistance = high;
            return true;
        }
        if (travel >= end) {
            break;
        }
        previous = travel;
        travel = min(travel + max(distance * 0.9 / max(slopeBound, EPSILON), minimumStep), end);
    }
    return false;
}

vec3 terrainColor(vec3 point, float distance, float time) {
    vec2 heights = terrainHeights(point.xz, time);
    vec3 normal = normalize(vec3(heights.x - terrainHeights(point.xz + vec2(TERRAIN_NORMAL_STEP, 0.0), time).x,
            TERRAIN_NORMAL_STEP, heights.x - terrainHeights(point.xz + vec2(0.0, TERRAIN_NORMAL_STEP), time).x));
    float depthFade = exp(-0.2 * distance);
    vec3 ambient = hsv2rgb(vec3(mix(0.9, 0.6, depthFade), 0.9, mix(1.0, 0.025, depthFade)));
    vec3 glow = hsv2rgb(vec3(0.6, 0.5, tanhApprox(exp(-mix(2.0, 8.0, depthFade) * (heights.x - heights.y)))));
    float lighting = 0.28 + 0.72 * max(dot(normal, normalize(vec3(-0.4, 0.8, 0.5))), 0.0);
    float ridge = pow(1.0 - abs(normal.y), 2.0);
    float surface = exp(-max(heights.x - point.y, 0.0) * 3.0);
    return ambient * mix(0.1, lighting, surface) + (glow * 0.5 + hsv2rgb(vec3(0.61, 0.75, 0.12)) * ridge) * surface;
}

vec3 stars(vec3 direction, float time) {
    vec2 spherical = vec2(acos(clamp(direction.y, -1.0, 1.0)), atan(direction.z, direction.x));
    vec3 color = vec3(0.0);
    float latitude = max(sin(spherical.x), EPSILON);
    for (int layer = 0; layer < 6; layer++) {
        float scale = float(layer) / 5.0;
        vec2 dimension = vec2(mix(0.05, 0.003, scale) * PI);
        vec2 point = spherical + 0.5 * float(layer);
        vec2 cell = floor((point + dimension * 0.5) / dimension);
        point = mod(point + dimension * 0.5, dimension) - dimension * 0.5;
        vec2 random = hash2(cell + 127.0 + float(layer));
        point += (-1.0 + 2.0 * random) * dimension * 0.5;
        point.y *= latitude;
        float hue = fract(random.x * 1667.0);
        float intensity = fract(random.x * 1887.0);
        float visibility = fract(random.x * 2997.0);
        vec3 starColor = mix(8.0 * intensity, 0.25 * intensity * intensity, scale)
                * mix(hsv2rgb(vec3(0.85, 0.8, 1.0)), hsv2rgb(vec3(0.65, 0.5, 1.0)), hue * hue);
        float twinkle = mix(0.125, 1.0, 1.0 - smoothstep(0.99, 1.0, sin(0.25 * time + TAU * random.y)));
        if (visibility < latitude) {
            color += exp(-5000.0 / mix(2.0, 0.25, scale)
                    * max(length(point) - 0.001, 0.0)) * starColor * twinkle;
        }
    }
    return color;
}

vec3 skyColor(vec3 direction, float time) {
    float lightFacing = pow(max(dot(LIGHT_DIRECTION, direction), 0.0), 80.0);
    float lightIntensity = 0.02 * mix(1.0, 10.0, lightFacing) / (abs(direction.y + 0.055) + 0.025);
    vec3 color = stars(direction, time) * (1.0 - smoothstep(0.0, 0.5, lightIntensity)) * step(-0.055, direction.y);
    color += (1.0 - smoothstep(0.0, 0.4, direction.y)) * hsv2rgb(vec3(0.6, 0.9, 0.075));
    color += tanh(hsv2rgb(vec3(0.75, 0.8, 1.0)) * lightIntensity);
    return color;
}

vec3 moonColor(vec3 normal) {
    float diffuse = max(dot(LIGHT_DIRECTION, normal), 0.0);
    return hsv2rgb(vec3(0.75, 0.7, 1.0)) * (0.018 + diffuse * 4.0);
}

vec3 toneMap(vec3 color) {
    color = max(color, 0.0) * 0.6;
    color = clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
    return mix(1.055 * pow(color, vec3(1.0 / 2.4)) - 0.055, 12.92 * color, lessThanEqual(color, vec3(0.0031308)));
}

vec3 neonwave(vec3 origin, vec3 direction, vec2 interval, float time, int steps, float pixelAngle) {
    vec3 skyDirection = normalize(origin + direction * interval.y);
    vec3 color = skyColor(skyDirection, time);
    vec3 moonOffset = origin - MOON_CENTER;
    float moonB = dot(moonOffset, direction);
    float moonDiscriminant = moonB * moonB - dot(moonOffset, moonOffset) + MOON_RADIUS * MOON_RADIUS;
    float moonDistance = interval.y;
    bool moonHit = false;
    if (moonDiscriminant > 0.0) {
        float root = sqrt(moonDiscriminant);
        float near = -moonB - root;
        float far = -moonB + root;
        moonDistance = near >= interval.x ? near : far;
        moonHit = moonDistance >= interval.x && moonDistance < interval.y;
        if (moonHit) {
            vec3 normal = (origin + direction * moonDistance - MOON_CENTER) / MOON_RADIUS;
            color = moonColor(normal);
        }
    }
    float closestDistance = clamp(-moonB, interval.x, interval.y);
    float haloDistance = max(length(moonOffset + direction * closestDistance) / MOON_RADIUS - 1.0, 0.0);
    color += hsv2rgb(vec3(0.76, 0.75, 0.16)) * exp(-haloDistance * 12.0);

    vec3 terrainPosition;
    float terrainDistance;
    vec2 terrainInterval = vec2(interval.x, moonHit ? moonDistance : interval.y);
    if (traceTerrain(origin, direction, terrainInterval, time, steps, pixelAngle, terrainPosition, terrainDistance)) {
        float distance = terrainDistance - interval.x;
        vec3 terrain = terrainColor(terrainPosition, distance, time);
        float fog = 1.0 - exp(-0.018 * distance * distance);
        color = mix(terrain, skyColor(normalize(vec3(skyDirection.x, -0.055, skyDirection.z)), time), fog * 0.7);
    }
    return toneMap(color);
}

#endif
