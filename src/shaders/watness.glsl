@include "./common.glsl"

uniform vec2 mouse;
uniform vec2 footLocation;
uniform sampler2D introImage;
uniform sampler2D treeImage;
uniform sampler2D shrubImage;

const float radius = 0.03;
const float scale = 0.50;

const vec4 paleYellow = vec4(1.0, 1.0, 0.8, 1.0);
const vec4 defaultEmpty = vec4(1.0, 0.0, 0.2, 1.0);
const vec4 orange = vec4(1.0, 0.6, 0.0, 1.0);
const vec4 cyan = vec4(0, 0.67, 0.76, 1.0);
const vec4 foliage = vec4(0.22, 0.56, 0.24, 1.0);
const vec4 foliageShadow = vec4(0.11, 0.37, 0.13, 1.0);
const vec4 gray600 = vec4(0.38, 0.49, 0.55, 1.0);
const vec4 gray900 = vec4(0.15, 0.20, 0.22, 1.0);
const vec4 cursor = vec4(1, 1, 1, 0.8);
const vec4 shadow = vec4(0, 0, 0, 0.8);
const vec4 darkGreen = vec4(0.11, 0.37, 0.13, 1.0);
const vec4 darkOrange900 = vec4(0.76, 0.21, 0.05, 1.0);
const vec4 orange900 = vec4(0.90, 0.32, 0.0, 1.0);
const vec4 lightOrange900 = vec4(1.0, 0.44, 0.0, 1.0);
const vec4 yellow900 = vec4(0.96, 0.5, 0.09, 1.0);
const vec4 blue800 = vec4(0.16, 0.21, 0.58, 1.0);
const vec4 brown600 = vec4(0.43, 0.30, 0.25, 1.0); // 6D4C41

#define MAX_SIZE 12

struct Plane {
    int id;
    vec3 center;
    vec3 xAxis;
    vec3 yAxis;
    int shape;
};

struct GameState {
    bool puzzleActive;
    bool puzzleSolved;
};

int iabs(int x) {
    return x >= 0 ? x : -x;
}

float dist(vec2 a, vec2 b) {
    vec2 diff = a - b;
    return sqrt(dot(diff, diff));
}

float dist(vec3 a, vec3 b) {
    vec3 diff = a - b;
    return sqrt(dot(diff, diff));
}

float round(float a) {
    return floor(a + 0.5);
}

vec4 blend(vec4 base, vec4 overlay) {
    return vec4(base.rgb * (1.0 - overlay.a) + overlay.rgb * overlay.a, 1.0);
}

float modExp (float b, float e, float m) {
    float base = mod(b, m);
    float result = 1.0;
    for (int i = 0; i < 8; i++) {
        if (mod(e, 2.0) == 1.0) {
            result = mod(result * base, m);
        }
        base = mod(base * base, m);
        e = floor(e / 2.0);
    }
    return result;
}

int hash(float value, float maxVal) {
    float modRes = modExp(1021.0, value + 12.0, 4093.0);
    return int(floor(modRes * maxVal / 4093.0));
}

bool isNode(vec2 position, int size, out ivec2 where) {
    for (int i = 0; i < MAX_SIZE; i++) {
	    for (int j = 0; j < MAX_SIZE; j++) {
            if (i >= size || j >= size) continue;

	        vec2 loc = vec2(
	            (-float(size - 1) + 2.0 * float(i)) / float(size - 1),
	            (-float(size - 1) + 2.0 * float(j)) / float(size - 1));
	        float dist = sqrt(pow(position.x - loc.x, 2.0) + pow(position.y - loc.y, 2.0));
	        if (dist < radius) {
	            where.x = i;
	            where.y = j;
	            return true;
	        }
	    }
	}
	return false;
}

bool isVEdge(vec2 position, int size, out ivec2 where) {
    for (int i = 0; i < MAX_SIZE; i++) {
	    for (int j = 0; j < MAX_SIZE - 1; j++) {
            if (i >= size || j >= size - 1) continue;

	        vec2 top = vec2(
	            (-float(size - 1) + 2.0 * float(i)) / float(size - 1),
	            (-float(size - 1) + 2.0 * float(j)) / float(size - 1));
	        vec2 bottom = vec2(
	            (-float(size - 1) + 2.0 * float(i)) / float(size - 1),
	            (-float(size - 1) + 2.0 * float(j + 1)) / float(size - 1));

	        if (
	            abs(position.x - top.x) < radius &&
	            position.y > top.y &&
	            position.y < bottom.y
	        ) {
	            where.x = i;
	            where.y = j;
	            return true;
	        }
	    }
	}
	return false;
}

bool isHEdge(vec2 position, int size, out ivec2 where) {
    for (int i = 0; i < MAX_SIZE - 1; i++) {
	    for (int j = 0; j < MAX_SIZE; j++) {
            if (i >= size - 1 || j >= size) continue;

	        vec2 left = vec2(
	            (-float(size - 1) + 2.0 * float(i)) / float(size - 1),
	            (-float(size - 1) + 2.0 * float(j)) / float(size - 1));
	        vec2 right = vec2(
	            (-float(size - 1) + 2.0 * float(i + 1)) / float(size - 1),
	            (-float(size - 1) + 2.0 * float(j)) / float(size - 1));

	        if (
	            abs(position.y - left.y) < radius &&
	            position.x > left.x &&
	            position.x < right.x
	        ) {
	            where.x = i;
	            where.y = j;
	            return true;
	        }
	    }
	}
	return false;
}

bool nodeIsOnPath(ivec2 where, int size) {
    for (int i = 0; i < PATH_LEN; i ++) {
        ivec3 loc = read_ivec3(int(PATH) + i);
        if (loc == ivec3(255, 255, 1)) {
            return false;
        }
        if (loc.xy == where) {
            return true;
        }
    }
    return false;
}

bool vEdgeIsOnPath(ivec2 where, int size) {
    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 loc = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);
        if (next == ivec3(255, 255, 1)) {
            return false;
        }
        if (loc.x == next.x && loc.x == where.x && imin(loc.y, next.y) == where.y) {
            return true;
        }
    }
    return false;
}

bool hEdgeIsOnPath(ivec2 where, int size) {
    for (int i = 0; i < PATH_LEN - 1; i ++) {
        ivec3 loc = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);
        if (next == ivec3(255, 255, 1)) {
            return false;
        }
        if (loc.y == next.y && loc.y == where.y && imin(loc.x, next.x) == where.x) {
            return true;
        }
    }
    return false;
}

bool isValidNextSegment(ivec2 where, int size) {
    if (where.x < 0 || where.y < 0 || where.x >= size || where.y >= size) {
        return false;
    }

    if (where == ivec2(0, 0) && read_ivec3(PATH) == ivec3(255, 255, 1)) {
        return true;
    }

    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 current = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);
        if (next == ivec3(255, 255, 1)) {
            return iabs(current.x - where.x) + iabs(current.y - where.y) == 1;
        }

        if (current.xy == where) {
            return false;
        }
    }
}

float rayIntersectsPlane(vec3 start, vec3 end, Plane plane, out vec2 planarPosition, out vec3 worldPosition) {
    vec3 normal = cross(plane.xAxis, plane.yAxis);
    vec3 ray = end - start;
    vec3 normalizedView = ray / sqrt(dot(ray, ray));
    float projection = dot(normalizedView, normal);
    float t = (-dot(start - plane.center, normal)) / projection;
    vec3 pointOnPlane = start + normalizedView * t;
    vec3 distanceFromCenter = pointOnPlane - plane.center;
    float xComponent = dot(distanceFromCenter, plane.xAxis) / dot(plane.xAxis, plane.xAxis);
    float yComponent = dot(distanceFromCenter, plane.yAxis) / dot(plane.yAxis, plane.yAxis);

    if (t > 0.0) {
        if (
            (plane.shape == 1 && xComponent >= -1.0 && xComponent <= 1.0 && yComponent >= -1.0 && yComponent <= 1.0)
            || (plane.shape == 2 && dist(vec2(xComponent, yComponent), vec2(0)) < 1.0)
        ) {
            planarPosition = vec2(xComponent, yComponent);
            worldPosition = pointOnPlane;
            return t;
        }
    }
    return -1.0;
}

bool rayIntersectsCylinder(vec3 trueStart, vec3 trueEnd, vec3 center, float radius, float height, out float theta, out float y, out float t) {
    float minT = dist(trueEnd, trueStart);
    vec3 trueRay = (trueEnd - trueStart) / dist(trueEnd, trueStart);
    vec2 start = trueStart.xz - center.xz;
    vec2 end = trueEnd.xz - center.xz;
    vec2 ray = (end - start) / dist(end, start);

    float a = dot(ray, ray);
    float b = 2.0 * dot(start, ray);
    float c = dot(start, start) - radius * radius;

    if (4.0 * a * c > b * b) {
        return false;
    }

    float groundTs[2];
    groundTs[0] = (-b + sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
    groundTs[1] = (-b - sqrt(b * b - 4.0 * a * c)) / (2.0 * a);

    float ts[2];
    ts[0] = groundTs[0] / sqrt(1.0 - trueRay.y * trueRay.y);
    ts[1] = groundTs[1] / sqrt(1.0 - trueRay.y * trueRay.y);

    float bestTheta;
    float bestY;
    float bestT = -1.0;

    for (int i = 0; i < 2; i++) {
        float currentT = ts[i];
        vec3 position = trueStart + trueRay * currentT;
        float currentTheta = (atan(position.z - center.z, position.x - center.x) + PI) / (2.0 * PI);
        float currentY = (position.y - center.y + height) / (2.0 * height);

        if (currentT >= 0.0 && (bestT < 0.0 || currentT < bestT) && currentY >= 0.0 && currentY <= 1.0) {
            bestTheta = currentTheta;
            bestY = currentY;
            bestT = currentT;
        }
    }

    if (bestT > 0.0) {
        y = bestY;
        theta = bestTheta;
        t = bestT;
        return true;
    }

    return false;
}

float findIntersection(vec3 start, vec3 end, Plane planes[6], out vec2 planarPosition, out vec3 worldPosition, out int id) {
    float bestDist = -1.0;
    id = -1;
    for (int i = 0; i < 6; i++) {
        vec2 pp;
        vec3 wp;
        float dist = rayIntersectsPlane(start, end, planes[i], pp, wp);
        if (dist > 0.0 && (bestDist < 0.0 || dist < bestDist)) {
            bestDist = dist;
            id = planes[i].id;
            planarPosition = pp;
            worldPosition = wp;
        }
    }
    return bestDist;
}

int decodePath(int index, int len) {
    float offset = 0.0;
    float result = 0.0;
    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 current = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);

        if (next == ivec3(255, 255, 1)) {
            return int(result);
        }

        if (mod(float(i), float(len)) == float(index)) {
            float val;
            ivec3 diff = next - current;
            if (diff == ivec3(1, 0, 0)) {
                val = 0.0;
            } else if (diff == ivec3(-1, 0, 0)) {
                val = 1.0;
            } else if (diff == ivec3(0, 1, 0)) {
                val = 2.0;
            } else if (diff == ivec3(0, -1, 0)) {
                val = 3.0;
            }

            result = mod(result + val * pow(2.0, offset), 16.0);
            offset = mod(offset + 1.0, 2.0);
        }
    }
}

bool checkLevel3(int size) {
    ivec2 leftTurns[14];
    leftTurns[0] = ivec2(2, 6);
    leftTurns[1] = ivec2(2, 4);
    leftTurns[2] = ivec2(1, 3);
    leftTurns[3] = ivec2(1, 1);
    leftTurns[4] = ivec2(4, 1);
    leftTurns[5] = ivec2(6, 8);
    leftTurns[6] = ivec2(6, 6);
    leftTurns[7] = ivec2(5, 5);
    leftTurns[8] = ivec2(5, 3);
    leftTurns[9] = ivec2(8, 3);
    leftTurns[10] = ivec2(9, 10);
    leftTurns[11] = ivec2(9, 4);
    leftTurns[12] = ivec2(10, 4);
    leftTurns[13] = ivec2(11, 7);
    ivec2 rightTurns[14];
    rightTurns[0] = ivec2(0, 7);
    rightTurns[1] = ivec2(2, 7);
    rightTurns[2] = ivec2(3, 6);
    rightTurns[3] = ivec2(3, 4);
    rightTurns[4] = ivec2(2, 3);
    rightTurns[5] = ivec2(4, 9);
    rightTurns[6] = ivec2(6, 9);
    rightTurns[7] = ivec2(7, 8);
    rightTurns[8] = ivec2(7, 6);
    rightTurns[9] = ivec2(6, 5);
    rightTurns[10] = ivec2(8, 11);
    rightTurns[11] = ivec2(10, 11);
    rightTurns[12] = ivec2(10, 10);
    rightTurns[13] = ivec2(10, 7);

    int leftIdx = 0;
    int rightIdx = 0;

    for (int i = 1; i < PATH_LEN - 1; i++) {
        ivec3 previous = read_ivec3(int(PATH) + i - 1);
        ivec3 current = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);

        if (next == ivec3(255, 255, 1)) {
            return false;
        }

        if (next == ivec3(size - 1, size - 1, 1) && leftIdx == 14 && rightIdx == 14) {
            return true;
        }

        vec3 forward = vec3(next - current);
        vec3 back = vec3(previous - current);
        vec3 dir = cross(forward, back);

        if (dir.z != 0.0) {
            for (int index = 0; index < 14; index++) {
                if (dir.z < -0.5) {
                    if (rightIdx >= 14) return false;
                    if (index == rightIdx) {
                        if (rightTurns[index] != current.xy) return false;
                        rightIdx ++;
                        break;
                    }
                }

                if (dir.z > 0.5) {
                    if (leftIdx >= 14) return false;
                    if (index == leftIdx) {
                        if (leftTurns[index] != current.xy) return false;
                        leftIdx ++;
                        break;
                    }
                }
            }
        }
    }

    return false;
}

bool checkLevel2(int size) {
    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 current = read_ivec3(int(PATH) + i);
        if (current == ivec3(255, 255, 1)) {
            return false;
        }
        if (current == ivec3(size - 1, size - 1, 1)) {
            return true;
        }
        int value = hash(float(current.y * size + current.x), 2.0);
        if (value != 1) {
            return false;
        }
    }

    return true;
}

bool checkLevel1(int size) {
    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 current = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);
        if (current == ivec3(255, 255, 1)) {
            return false;
        }
        if (current == ivec3(size - 1, size - 1, 1)) {
            return true;
        }


        float pointX = (float(current.x) + float(next.x)) / (2.0 * float(size));
        float pointY = (float(current.y) + float(next.y)) / (2.0 * float(size));
        vec4 data = texture2D(introImage, vec2(pointX, pointY));

        if (data.a >= 1.0) {
            return false;
        }
    }

    return false;
}

vec4 drawPuzzle(vec2 position, vec2 newMouse, int size, bool isSolved) {
    position *= 1.1;
    float distToMouse = sqrt(pow(position.x - newMouse.x, 2.0) + pow(position.y - newMouse.y, 2.0));

    if (distToMouse < radius) {
        return orange;
    }

    ivec2 where;
    if (isNode(position, size, where)) {
        if (nodeIsOnPath(where, size)) {
            return orange;
        }

        return paleYellow;
    }

    if (isVEdge(position, size, where)) {
        if (vEdgeIsOnPath(where, size)) {
            return orange;
        }

        if (isHEdge(position, size, where) && hEdgeIsOnPath(where, size)) {
            return orange;
        }

        return paleYellow;
    }

    if (isHEdge(position, size, where)) {
        if (hEdgeIsOnPath(where, size)) {
            return orange;
        }

        return paleYellow;
    }

    if (isSolved) {
        return foliage;
    }

    return defaultEmpty;
}

vec2 normalizeMouse(int size) {
    if (read_byte(ACTIVE_PUZZLE) == 0) {
        return vec2(-1, -1);
    }

    vec2 mouseLocation = read_vec2(MOUSE_LOCATION, 1.0);
    vec2 mouseDelta = read_vec2(MOUSE_DELTA, 1.0) - 0.5;

    vec2 mouse = (mouseLocation + mouseDelta - 0.5) * 2.0;
    vec2 bounded = minmax(mouse, vec2(-1, -1), vec2(1, 1));
    vec2 normalized = (bounded + vec2(1, 1)) / 2.0;
    vec2 haligned = vec2(
        round(normalized.x * float(size - 1)) / float(size - 1),
        normalized.y
    );
    vec2 valigned = vec2(
        normalized.x,
        round(normalized.y * float(size - 1)) / float(size - 1)
    );

    if (dist(haligned, normalized) < dist(valigned, normalized)) {
        return haligned * 2.0 - vec2(1, 1);
    } else {
        return valigned * 2.0 - vec2(1, 1);
    }
}

vec2 normalizeLocation() {
    vec2 base = read_vec2(PLAYER_LOCATION, 1.0);

    if (read_byte(ACTIVE_PUZZLE) == 0) {
        vec3 viewVector = viewport_center - focus;
        vec3 unnormalizedForwardProjection = vec3(viewVector.x, viewVector.z, 0);
        vec3 forwardProjection =
            unnormalizedForwardProjection / sqrt(
                dot(unnormalizedForwardProjection, unnormalizedForwardProjection)
            );
        vec3 sideProjection = cross(forwardProjection, vec3(0, 0, 1));

        float speed = 0.0005;
        if (read_bool(KEY_UP)) {
            base += speed * forwardProjection.xy * dt;
        }
        if (read_bool(KEY_DOWN)) {
            base -= speed * forwardProjection.xy * dt;
        }
        if (read_bool(KEY_LEFT)) {
            base -= speed * sideProjection.xy * dt;
        }
        if (read_bool(KEY_RIGHT)) {
            base += speed * sideProjection.xy * dt;
        }
    }

    return minmax(base, vec2(0, 0), vec2(1, 1));
}

vec2 normalizeRotation() {
    vec2 rotation = read_vec2(VIEW_ANGLE, 1.0) * vec2(2.0 * PI, PI);
    if (read_byte(ACTIVE_PUZZLE) == 0) {
        vec2 mouseDelta = read_vec2(MOUSE_DELTA, 1.0) - 0.5;
        rotation = rotation - mouseDelta;
    }
    rotation.x = mod(rotation.x + 2.0 * PI, 2.0 * PI);
    rotation.y = minmax(rotation.y, 0.0, PI);
    return rotation;
}

vec4 drawFoliage(vec2 worldPosition) {
    vec2 actual = (worldPosition * 1000.0);
    vec2 quantized = vec2(floor(actual.x), floor(actual.y));
    int color = hash(quantized.y + quantized.x * 8.0, 4.0);
    float blendVal = dist(quantized + 0.5, actual);
    vec4 base;

    if (color == 0) {
        base = darkOrange900;
    } else if (color == 1) {
        base = orange900;
    } else if (color == 2) {
        base = lightOrange900;
    } else {
        base = yellow900;
    }

    return base;
}

vec3 reflect(vec3 ray, Plane plane) {
    vec3 normalized = normalize(ray);
    vec3 xNormalized = normalize(plane.xAxis);
    vec3 yNormalized = normalize(plane.yAxis);
    vec3 nNormalized = normalize(cross(plane.xAxis, plane.yAxis));

    return
        dot(normalized, xNormalized) * xNormalized +
        dot(normalized, yNormalized) * yNormalized -
        dot(normalized, nNormalized) * nNormalized;
}

GameState renderLevel3(vec2 newMouse) {
    bool puzzleActive = read_bool(ACTIVE_PUZZLE);
    bool isSolved = checkLevel3(12);

    vec2 planarPosition;
    vec3 worldPosition;
    float angle;
    float height;
    float t;

    Plane puzzle = Plane(0, vec3(0, -2.01, 30), vec3(-6, 0, 0), vec3(0, 0, 6), 1);
    Plane dock = Plane(1, vec3(0, -2, -10), vec3(10, 0, 0), vec3(0, 0, 20), 1);
    Plane dock2 = Plane(2, vec3(0, -2, 40), vec3(10, 0, 0), vec3(0, 0, 20), 1);
    Plane lake = Plane(3, vec3(0, -10.0, 3), vec3(0, 0, 30), vec3(30, 0, 0), 2);
    Plane shore = Plane(4, vec3(0, -10.1, 3), vec3(0, 0, 100), vec3(100, 0, 0), 2);
    Plane wall = Plane(5, vec3(0, 0, -10), vec3(0, 15, 0), vec3(15, 0, 0), 1);

    float timeOfDay = time / 5.0;

    Plane lightSource = Plane(
        4,
        vec3(0, 300.0 * sin(timeOfDay), 300.0 * cos(timeOfDay)),
        vec3(0, 42.0 * sin(timeOfDay + PI / 2.0), 42.0 * cos(timeOfDay + PI / 2.0)),
        vec3(42, 0, 0),
        1
    );

    Plane renderables[6];

    renderables[0] = puzzle;
    renderables[1] = dock;
    renderables[2] = dock2;
    renderables[3] = lake;
    renderables[4] = shore;
    renderables[5] = wall;

    Plane puzzles[6];
    puzzles[0] = puzzle;

    int found = -1;

    float blendVal = (cos(timeOfDay - PI / 2.0) + 1.0) / 2.0;

    gl_FragColor = cyan;
    float foundDistance = findIntersection(
        focus,
        surface_loc,
        renderables,
        planarPosition,
        worldPosition,
        found
    );

    if (foundDistance >= 0.0) {
        if (found == 0) {
            gl_FragColor = drawPuzzle(planarPosition, newMouse, 12, isSolved);
        } else if (found == 1 || found == 2) {
            gl_FragColor = brown600;
        } else if (found == 3) {
            vec3 wp = worldPosition;
            vec3 reflection = reflect(wp - focus, lake);
            vec4 foundColor = vec4(0, 0, 0, 0);

            if (rayIntersectsCylinder(
                wp,
                wp + reflection,
                vec3(0, -9, 3),
                31.0,
                1.0,
                angle,
                height,
                t
            )) {
                foundColor = texture2D(shrubImage, vec2(mod(angle, 1.0/80.0) * 80.0, 1.0 - height));
            }

            Plane reflectables[6];
            reflectables[0] = puzzle;
            reflectables[2] = dock2;

            if (findIntersection(wp, wp + reflection, reflectables, planarPosition, worldPosition, found) >= 0.0) {
                if (found == 0) {
                    foundColor = blend(drawPuzzle(planarPosition, newMouse, 12, isSolved), foundColor);
                }
                if (found == 2) {
                    foundColor = blend(brown600, foundColor);
                }
            }

            gl_FragColor = blend(blue800, vec4(foundColor.rgb, foundColor.a / 2.0));
        } else if (found == 4) {
            gl_FragColor = paleYellow;
        } else if (found == 5) {
            gl_FragColor = gray600;
        }
    }

    if (rayIntersectsCylinder(
        focus,
        surface_loc,
        vec3(0, -9, 3),
        31.0,
        1.0,
        angle,
        height,
        t
    )) {
        if (t < foundDistance) {
            gl_FragColor = blend(gl_FragColor, texture2D(shrubImage, vec2(mod(angle, 1.0/80.0) * 80.0, 1.0 - height)));
        }
    }

    if (!puzzleActive && dist(gl_FragCoord.xy, resolution / 2.0) < 4.0) {
        gl_FragColor = blend(gl_FragColor, cursor);
    }

    if (read_bool(CLICK) && rayIntersectsPlane(focus, viewport_center, puzzle, planarPosition, worldPosition) >= 0.0) {
        puzzleActive = true;
    }

    return GameState(puzzleActive, isSolved);
}

GameState renderLevel2(vec2 newMouse) {
    bool puzzleActive = read_bool(ACTIVE_PUZZLE);
    bool isSolved = checkLevel2(8);

    vec2 planarPosition;
    vec3 worldPosition;
    float angle;
    float height;
    float t;

    Plane puzzle = Plane(0, vec3(0, 0.5, 7), vec3(2, 0, 0), vec3(0, 2, 0), 1);
    Plane tree = Plane(1, vec3(-2, 3, 12), vec3(3.75, 0, 0), vec3(0, 5, 0), 1);
    Plane ground = Plane(3, vec3(0, -2.0, 0), vec3(0, 0, 100), vec3(100, 0, 0), 1);

    float timeOfDay = time / 5.0;

    Plane lightSource = Plane(
        2,
        vec3(0, 300.0 * sin(timeOfDay), 300.0 * cos(timeOfDay)),
        vec3(0, 42.0 * sin(timeOfDay + PI / 2.0), 42.0 * cos(timeOfDay + PI / 2.0)),
        vec3(42, 0, 0),
        2
    );

    Plane renderables[6];

    renderables[0] = puzzle;
    renderables[2] = lightSource;
    renderables[3] = ground;

    Plane puzzles[6];
    puzzles[0] = puzzle;

    int found = -1;

    float blendVal = (cos(timeOfDay - PI / 2.0) + 1.0) / 2.0;

    gl_FragColor = cyan;
    float foundDistance = findIntersection(
        focus,
        surface_loc,
        renderables,
        planarPosition,
        worldPosition,
        found
    );

    if (foundDistance >= 0.0) {
        if (found == 0) {
            gl_FragColor = drawPuzzle(planarPosition, newMouse, 8, isSolved);
        } else if (found == 2) {
            gl_FragColor = paleYellow;
        } else if (found == 3) {
            gl_FragColor = drawFoliage(planarPosition);
            vec3 currentWP = worldPosition;

            if (rayIntersectsCylinder(
                currentWP,
                lightSource.center,
                vec3(0, 2, 0),
                31.0,
                4.0,
                angle,
                height,
                t
            )) {
                vec4 value = texture2D(treeImage, vec2(mod(angle, 1.0/20.0) * 40.0, 1.0 - height));
                gl_FragColor = blend(gl_FragColor, vec4(shadow.rgb, shadow.a * value.a));
            }


            if (rayIntersectsPlane(
                currentWP,
                lightSource.center,
                puzzle,
                planarPosition,
                worldPosition
            ) >= 0.0) {
                gl_FragColor = blend(gl_FragColor, shadow);
            }
        }
    }

    float treeDistance;
    bool treeIntersects =
        rayIntersectsCylinder(
            focus,
            surface_loc,
            vec3(0, 2, 0),
            31.0,
            4.0,
            angle,
            height,
            treeDistance
        );

    if (treeIntersects && (foundDistance < 0.0 || treeDistance < foundDistance)) {
        vec4 treeColor = texture2D(treeImage,  vec2(mod(angle, 1.0/20.0) * 40.0, 1.0 - height));
        gl_FragColor = blend(gl_FragColor, treeColor);
    }

    gl_FragColor =
        gl_FragColor * (0.25 + 3.0 * blendVal / 4.0) +
        vec4(0, 0, 0, 1.0) * (0.75 - 3.0 * blendVal / 4.0);


    if (!puzzleActive && dist(gl_FragCoord.xy, resolution / 2.0) < 4.0) {
        gl_FragColor = blend(gl_FragColor, cursor);
    }

    if (read_bool(CLICK) && rayIntersectsPlane(focus, viewport_center, puzzle, planarPosition, worldPosition) >= 0.0) {
        puzzleActive = true;
    }

    return GameState(puzzleActive, isSolved);
}

GameState renderLevel1(vec2 newMouse) {
    bool puzzleActive = read_bool(ACTIVE_PUZZLE);
    bool isSolved = checkLevel1(8);

    vec2 planarPosition;
    vec3 worldPosition;

    Plane puzzle = Plane(0, vec3(0, 0.5, 7), vec3(2, 0, 0), vec3(0, 2, 0), 1);
    Plane lightSource = Plane(1, vec3(0, 7, -9), vec3(0, 1, 1), vec3(10, 0, 0), 1);

    Plane renderables[6];
    renderables[0] = puzzle;
    renderables[1] = lightSource;

    Plane puzzles[6];
    puzzles[0] = puzzle;

    Plane boxes[6];
    boxes[0] = Plane(0, vec3(0, -2.0, 0), vec3(0, 0, 10), vec3(10, 0, 0), 1);
    boxes[1] = Plane(1, vec3(10, 3, 0), vec3(0, 5, 0), vec3(0, 0, 10), 1);
    boxes[2] = Plane(2, vec3(0, 3, 10), vec3(10, 0, 0), vec3(0, 5, 0), 1);
    boxes[3] = Plane(3, vec3(0, 3, -10), vec3(10, 0, 0), vec3(0, 5, 0), 1);
    boxes[4] = Plane(4, vec3(-10, 3, 0), vec3(0, 5, 0), vec3(0, 0, 10), 1);
    boxes[5] = Plane(5, vec3(0, 8, 0), vec3(0, 0, 10), vec3(10, 0, 0), 1);

    int found = -1;

    gl_FragColor = cyan;
    if (findIntersection(
        focus,
        surface_loc,
        renderables,
        planarPosition,
        worldPosition,
        found) > 0.0
    ) {
        if (found == 0) {
            gl_FragColor = drawPuzzle(planarPosition, newMouse, 8, isSolved);
        } else if (found == 1) {
            gl_FragColor = paleYellow;
        }
    } else {
        if (findIntersection(
            focus,
            surface_loc,
            boxes,
            planarPosition,
            worldPosition,
            found) >= 0.0
        ) {
            if (found == 0 || found == 5) {
                gl_FragColor = gray600;
            } if (found == 2) {
                gl_FragColor = texture2D(introImage, (vec2(1, -1) * planarPosition + 1.0) / 2.0);
            } else {
                gl_FragColor = gray900;
            }

            float dx = (abs(planarPosition.x) - 0.99) * 100.0;
            float dy = (abs(planarPosition.y) - 0.99) * 100.0;
            if (dx > 0.0 || dy > 0.0) {
                float amount = max(dx, dy);
                gl_FragColor = blend(gl_FragColor, shadow);
            }

            if (findIntersection(
                worldPosition,
                lightSource.center,
                puzzles,
                planarPosition,
                worldPosition,
                found) >= 0.0
            ) {
                gl_FragColor = blend(gl_FragColor, shadow);
            }
        }
    }


    if (!puzzleActive && dist(gl_FragCoord.xy, resolution / 2.0) < 4.0) {
        gl_FragColor = blend(gl_FragColor, cursor);
    }

    if (read_bool(CLICK) && rayIntersectsPlane(focus, viewport_center, puzzle, planarPosition, worldPosition) >= 0.0) {
        puzzleActive = true;
    }

    return GameState(puzzleActive, isSolved);
}

void main() {
    vec4 empty = defaultEmpty;

    int puzzle = read_byte(ACTIVE_LEVEL);
    int size;


    if (puzzle == 0) size = 8;
    if (puzzle == 1) size = 8;
    if (puzzle == 2 ) size = MAX_SIZE;

    vec2 newMouse = normalizeMouse(size);
    vec2 newLocation = normalizeLocation();
    vec2 rotation = normalizeRotation();
    bool puzzleActive = read_bool(ACTIVE_PUZZLE);

    GameState state;
    if (puzzle == 0) state = renderLevel1(newMouse);
    if (puzzle == 1) state = renderLevel2(newMouse);
    if (puzzle == 2) state = renderLevel3(newMouse);

    write_float(MOUSE_LOCATION, newMouse.x / 2.0 + 0.5, 1.0)
    write_float(MOUSE_LOCATION + 1.0, newMouse.y / 2.0 + 0.5, 1.0)
    write_float(PLAYER_LOCATION, newLocation.x, 1.0)
    write_float(PLAYER_LOCATION + 1.0, newLocation.y, 1.0)
    write_float(VIEW_ANGLE, rotation.x, 2.0 * PI)
    write_float(VIEW_ANGLE + 1.0, rotation.y, PI)

    int next_segment = 0;
    for (int i = 0; i < PATH_LEN; i++) {
        ivec3 loc = read_ivec3(int(PATH) + i);
        if (loc == ivec3(255, 255, 1)) {
            next_segment = i;
            break;
        }
    }
    for (int i = 0; i < PATH_LEN; i++) {
        ivec3 loc = read_ivec3(int(PATH) + i);

        if (loc.z == 0) {
            write_ivec3(PATH + float(i), ivec3(255, 255, 1))
        } else if (i == 0) {
            write_ivec3(PATH + float(i), ivec3(0, 0, 1));
        } else if (state.puzzleActive) {
            if (i == next_segment) {
                ivec2 nextNode;
                if (!state.puzzleSolved && isNode(newMouse, size, nextNode) && isValidNextSegment(nextNode, size)) {
                    write_ivec3(PATH + float(i), ivec3(nextNode.xy, 1))
                }
            }
        } else if (!state.puzzleSolved) {
            write_ivec3(PATH + float(i), ivec3(255, 255, 1));
        }

        write_ivec3(PATH + float(i), ivec3(loc.xy, 1))
    }

    for (int i = 0; i < 6; i++) {
        if (puzzle == 0 && state.puzzleSolved) {
            write_byte(SOLUTION1 + float(i), decodePath(i, 6));
        }

        if (puzzle == 1 && state.puzzleSolved) {
            write_byte(SOLUTION2 + float(i), decodePath(i, 6));
        }

        if (puzzle == 2 && state.puzzleSolved) {
            write_byte(SOLUTION3 + float(i), decodePath(i, 6));
        }

        write_byte(SOLUTION1 + float(i), read_byte(int(SOLUTION1) + i));
        write_byte(SOLUTION2 + float(i), read_byte(int(SOLUTION2) + i));
        write_byte(SOLUTION3 + float(i), read_byte(int(SOLUTION3) + i));
    }

    vec3 worldPosition;
    vec2 planarPosition;
    Plane exit = Plane(0, vec3(0, 0, -10), vec3(0, 3, 0), vec3(2, 0, 0), 1);
    if (state.puzzleSolved && rayIntersectsPlane(focus, surface_loc, exit, planarPosition, worldPosition) >= 0.0) {
        gl_FragColor = blend(gl_FragColor, vec4(1, 1, 1, 0.95));
    }

    if (state.puzzleSolved && dist(viewport_center, exit.center) < 2.0) {
        puzzle = puzzle + 1;
    }

    if (read_bool(RIGHT_CLICK)) {
        state.puzzleActive = false;
    }

    write_bool(ACTIVE_PUZZLE, state.puzzleActive);
    write_byte(ACTIVE_LEVEL, puzzle);
    write_bool(COMPLETE, (puzzle == 3));

    if (gl_FragCoord.y <= 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
}