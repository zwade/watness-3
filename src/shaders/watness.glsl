uniform vec2 mouse;
uniform vec2 footLocation;
uniform sampler2D introImage;

const int width = 8;
const int height = 8;
const float radius = 0.03;
const float scale = 0.50;

const vec4 pale_yellow = vec4(1.0, 1.0, 0.8, 1.0);
const vec4 default_empty = vec4(1.0, 0.0, 0.2, 1.0);
const vec4 orange = vec4(1.0, 0.6, 0.0, 1.0);
const vec4 cyan = vec4(0, 0.67, 0.76, 1.0);
const vec4 foliage = vec4(0.22, 0.56, 0.24, 1.0);
const vec4 foliageShadow = vec4(0.11, 0.37, 0.13, 1.0);
const vec4 gray600 = vec4(0.38, 0.49, 0.55, 1.0);
const vec4 gray900 = vec4(0.15, 0.20, 0.22, 1.0);
const vec4 cursor = vec4(1, 1, 1, 0.8);
const vec4 shadow = vec4(0, 0, 0, 0.8);

struct Plane {
    int id;
    vec3 center;
    vec3 xAxis;
    vec3 yAxis;
};

int iabs(int x) {
    return x >= 0 ? x : -x;
}

float dist(vec2 a, vec2 b) {
    vec2 diff = a - b;
    return sqrt(dot(diff, diff));
}

float round(float a) {
    return floor(a + 0.5);
}

vec4 blend(vec4 base, vec4 overlay) {
    return vec4(base.rgb * (1.0 - overlay.a) + overlay.rgb * overlay.a, 1.0);
}

bool is_node(vec2 position, out ivec2 where) {
    for (int i = 0; i < width; i++) {
	    for (int j = 0; j < height; j++) {
	        vec2 loc = vec2(
	            (-float(width - 1) + 2.0 * float(i)) / float(width - 1),
	            (-float(height - 1) + 2.0 * float(j)) / float(height - 1));
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

bool is_v_edge(vec2 position, out ivec2 where) {
    for (int i = 0; i < width; i++) {
	    for (int j = 0; j < height - 1; j++) {
	        vec2 top = vec2(
	            (-float(width - 1) + 2.0 * float(i)) / float(width - 1),
	            (-float(height - 1) + 2.0 * float(j)) / float(height - 1));
	        vec2 bottom = vec2(
	            (-float(width - 1) + 2.0 * float(i)) / float(width - 1),
	            (-float(height - 1) + 2.0 * float(j + 1)) / float(height - 1));

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

bool is_h_edge(vec2 position, out ivec2 where) {
    for (int i = 0; i < width - 1; i++) {
	    for (int j = 0; j < height; j++) {
	        vec2 left = vec2(
	            (-float(width - 1) + 2.0 * float(i)) / float(width - 1),
	            (-float(height - 1) + 2.0 * float(j)) / float(height - 1));
	        vec2 right = vec2(
	            (-float(width - 1) + 2.0 * float(i + 1)) / float(width - 1),
	            (-float(height - 1) + 2.0 * float(j)) / float(height - 1));

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

bool node_is_on_path(ivec2 where) {
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

bool v_edge_is_on_path(ivec2 where) {
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

bool h_edge_is_on_path(ivec2 where) {
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

bool is_valid_next_segment(ivec2 where) {
    if (where.x < 0 || where.y < 0 || where.x >= width || where.y >= height) {
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

    if (t > 0.0 && xComponent >= -1.0 && xComponent <= 1.0 && yComponent >= -1.0 && yComponent <= 1.0) {
        planarPosition = vec2(xComponent, yComponent);
        worldPosition = pointOnPlane;
        return t;
    }
    return -1.0;
}

bool findIntersection(vec3 start, vec3 end, Plane planes[6], out vec2 planarPosition, out vec3 worldPosition, out int id) {
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
    return bestDist > 0.0;
}

bool checkLevel1() {
    for (int i = 0; i < PATH_LEN - 1; i++) {
        ivec3 current = read_ivec3(int(PATH) + i);
        ivec3 next = read_ivec3(int(PATH) + i + 1);
        if (current == ivec3(255, 255, 1)) {
            return false;
        }
        if (current == ivec3(width - 1, height - 1, 1)) {
            return true;
        }


        float pointX = (float(current.x) + float(next.x)) / (2.0 * float(width));
        float pointY = (float(current.y) + float(next.y)) / (2.0 * float(height));
        vec4 data = texture2D(introImage, vec2(pointX, pointY));

        if (data.a >= 1.0) {
            return false;
        }
    }

    return false;
}
bool drawPuzzle(vec2 position, vec2 newMouse) {
    bool isSolved = checkLevel1();

    position *= 1.1;
    float distToMouse = sqrt(pow(position.x - newMouse.x, 2.0) + pow(position.y - newMouse.y, 2.0));

    if (distToMouse < radius) {
        gl_FragColor = orange;
        return true;
    }

    ivec2 where;
    if (is_node(position, where)) {
        if (node_is_on_path(where)) {
            gl_FragColor = orange;
        } else {
            gl_FragColor = pale_yellow;
        }
    } else if (is_v_edge(position, where)) {
        if (v_edge_is_on_path(where)) {
            gl_FragColor = orange;
        } else {
            if (is_h_edge(position, where) && h_edge_is_on_path(where)) {
                gl_FragColor = orange;
            } else {
                gl_FragColor = pale_yellow;
            }
        }
    } else if (is_h_edge(position, where)) {
        if (h_edge_is_on_path(where)) {
            gl_FragColor = orange;
        } else {
            gl_FragColor = pale_yellow;
        }
    } else if (isSolved) {
        gl_FragColor = foliage;
    } else {
        gl_FragColor = default_empty;

    }

    return true;
}

vec2 normalizeMouse() {
    if (read_byte(ACTIVE_PUZZLE) == 0) {
        return vec2(-1, -1);
    }

    vec2 mouseLocation = read_vec2(MOUSE_LOCATION, 1.0);
    vec2 mouseDelta = read_vec2(MOUSE_DELTA, 1.0) - 0.5;

    vec2 mouse = (mouseLocation + mouseDelta - 0.5) * 2.0;
    vec2 bounded = minmax(mouse, vec2(-1, -1), vec2(1, 1));
    vec2 normalized = (bounded + vec2(1, 1)) / 2.0;
    vec2 haligned = vec2(
        round(normalized.x * float(width - 1)) / float(width - 1),
        normalized.y
    );
    vec2 valigned = vec2(
        normalized.x,
        round(normalized.y * float(height - 1)) / float(height - 1)
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

        if (read_bool(KEY_UP)) {
            base += 0.001 * forwardProjection.xy * dt;
        }
        if (read_bool(KEY_DOWN)) {
            base -= 0.001 * forwardProjection.xy * dt;
        }
        if (read_bool(KEY_LEFT)) {
            base -= 0.001 * sideProjection.xy * dt;
        }
        if (read_bool(KEY_RIGHT)) {
            base += 0.001 * sideProjection.xy * dt;
        }
    }

    return minmax(base, vec2(0, 0), vec2(1, 1));
}

vec2 normalizeRotation() {
    vec2 rotation = read_vec2(VIEW_ANGLE, 2.0 * PI);
    if (read_byte(ACTIVE_PUZZLE) == 0) {
        vec2 mouseDelta = read_vec2(MOUSE_DELTA, 1.0) - 0.5;
        rotation = rotation - mouseDelta;
    }
    rotation = mod(rotation + 2.0 * PI, 2.0 * PI);
    return rotation;
}


int renderLevel1(vec2 newMouse) {
    int activePuzzle = read_byte(ACTIVE_PUZZLE);

    vec2 planarPosition;
    vec3 worldPosition;

    Plane puzzle = Plane(0, vec3(0, 0.5, 7), vec3(2, 0, 0), vec3(0, 2, 0));
    Plane lightSource = Plane(1, vec3(0, 7, -9), vec3(0, 1, 1), vec3(10, 0, 0));

    Plane renderables[6];
    renderables[0] = puzzle;
    renderables[1] = lightSource;

    Plane puzzles[6];
    puzzles[0] = puzzle;

    Plane boxes[6];
    boxes[0] = Plane(0, vec3(0, -2.0, 0), vec3(0, 0, 10), vec3(10, 0, 0));
    boxes[1] = Plane(1, vec3(10, 3, 0), vec3(0, 5, 0), vec3(0, 0, 10));
    boxes[2] = Plane(2, vec3(0, 3, 10), vec3(10, 0, 0), vec3(0, 5, 0));
    boxes[3] = Plane(3, vec3(0, 3, -10), vec3(10, 0, 0), vec3(0, 5, 0));
    boxes[4] = Plane(4, vec3(-10, 3, 0), vec3(0, 5, 0), vec3(0, 0, 10));
    boxes[5] = Plane(5, vec3(0, 8, 0), vec3(0, 0, 10), vec3(10, 0, 0));

    int found = -1;

    gl_FragColor = cyan;
    if (findIntersection(
        focus,
        surface_loc,
        renderables,
        planarPosition,
        worldPosition,
        found)
    ) {
        if (found == 0) {
            drawPuzzle(planarPosition, newMouse);
        } else if (found == 1) {
            gl_FragColor = pale_yellow;
        }
    } else {
        if (findIntersection(
            focus,
            surface_loc,
            boxes,
            planarPosition,
            worldPosition,
            found)
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
                found
            )) {
                gl_FragColor = blend(gl_FragColor, shadow);
            }
        }
    }


    if (activePuzzle == 0 && dist(gl_FragCoord.xy, resolution / 2.0) < 4.0) {
        gl_FragColor = blend(gl_FragColor, cursor);
    }

    if (read_bool(CLICK) && rayIntersectsPlane(focus, viewport_center, puzzle, planarPosition, worldPosition) >= 0.0) {
        activePuzzle = 1;
    }

    return activePuzzle;
}

void main() {
    vec4 empty = default_empty;

    vec2 newMouse = normalizeMouse();
    vec2 newLocation = normalizeLocation();
    vec2 rotation = normalizeRotation();
    int activePuzzle = read_byte(ACTIVE_PUZZLE);

    write_float(MOUSE_LOCATION, newMouse.x / 2.0 + 0.5, 1.0)
    write_float(MOUSE_LOCATION + 1.0, newMouse.y / 2.0 + 0.5, 1.0)
    write_float(PLAYER_LOCATION, newLocation.x, 1.0)
    write_float(PLAYER_LOCATION + 1.0, newLocation.y, 1.0)
    write_float(VIEW_ANGLE, rotation.x, 2.0 * PI)
    write_float(VIEW_ANGLE + 1.0, rotation.y, 2.0 * PI)

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
        }
        if (i == next_segment) {
            ivec2 nextNode;
            if (is_node(newMouse, nextNode) && is_valid_next_segment(nextNode)) {
                write_ivec3(PATH + float(i), ivec3(nextNode.xy, 1))
            }
        }

        write_ivec3(PATH + float(i), ivec3(loc.xy, 1))
    }

    activePuzzle = renderLevel1(newMouse);

    if (read_bool(RIGHT_CLICK)) {
        activePuzzle = 0;
    }

    write_byte(ACTIVE_PUZZLE, activePuzzle);

    if (gl_FragCoord.y <= 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
}