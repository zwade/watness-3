uniform vec2 mouse;
uniform vec2 footLocation;

const int width = 10;
const int height = 10;
const float radius = 0.03;
const float scale = 0.50;

const vec4 pale_yellow = vec4(1.0, 1.0, 0.8, 1.0);
const vec4 default_empty = vec4(1.0, 0.0, 0.2, 1.0);
const vec4 orange = vec4(1.0, 0.6, 0.0, 1.0);
const vec4 cyan = vec4(0, 0.67, 0.76, 1.0);
const vec4 foliage = vec4(0.22, 0.56, 0.24, 1.0);
const vec4 cursor = vec4(1, 1, 1, 0.8);

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

bool rayIntersectsPlane(vec3 ray, vec3 center, vec3 xAxis, vec3 yAxis, out vec2 where) {
    vec3 normal = cross(xAxis, yAxis);
    vec3 viewVector = ray - focus;
    vec3 normalizedView = viewVector / sqrt(dot(viewVector, viewVector));
    float projection = dot(normalizedView, normal);
    float t = (-dot(focus - center, normal)) / projection;
    vec3 pointOnPlane = focus + normalizedView * t;
    float xComponent = dot(pointOnPlane, xAxis) / dot(xAxis, xAxis);
    float yComponent = dot(pointOnPlane, yAxis) / dot(yAxis, yAxis);

    if (t > 0.0 && xComponent >= -1.0 && xComponent <= 1.0 && yComponent >= -1.0 && yComponent <= 1.0) {
        where = vec2(xComponent, yComponent);
        return true;
    }
    return false;
}

void drawPuzzle(vec2 position) {
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
    } else {
        gl_FragColor = default_empty;
    }
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
            base += 0.01 * forwardProjection.xy;
        }
        if (read_bool(KEY_DOWN)) {
            base -= 0.01 * forwardProjection.xy;
        }
        if (read_bool(KEY_LEFT)) {
            base -= 0.01 * sideProjection.xy;
        }
        if (read_bool(KEY_RIGHT)) {
            base += 0.01 * sideProjection.xy;
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

    vec2 where;
    vec3 center = vec3(0, 0, 3);
    vec3 xAxis = vec3(1, 0, 0);
    vec3 yAxis = vec3(0, 1, 0);

    if (read_bool(CLICK) && rayIntersectsPlane(viewport_center, center, xAxis, yAxis, where)) {
        activePuzzle = 1;
    }

    if (read_bool(RIGHT_CLICK) && activePuzzle != 0) {
        activePuzzle = 0;
    }

    write_byte(ACTIVE_PUZZLE, activePuzzle);

    if (gl_FragCoord.y <= 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    if (rayIntersectsPlane(surface_loc, center, xAxis, yAxis, where)) {
        where = where * 1.1;
        float distToMouse = sqrt(pow(where.x - newMouse.x, 2.0) + pow(where.y - newMouse.y, 2.0));
        if (distToMouse < radius) {
            gl_FragColor = orange;
        } else {
            drawPuzzle(where);
        }
    } else if (rayIntersectsPlane(surface_loc, vec3(0, -2.0, 0), vec3(0, 0, 10), vec3(10, 0, 0), where)) {
        gl_FragColor = foliage;
    } else if (rayIntersectsPlane(surface_loc, vec3(0, 100, 50), vec3(0, 7, -7), vec3(10, 0, 0), where)) {
        gl_FragColor = orange;
    } else {
        gl_FragColor = cyan;
    }

    if (activePuzzle == 0 && dist(gl_FragCoord.xy, resolution / 2.0) < 4.0) {
        gl_FragColor = vec4(gl_FragColor.rgb * (1.0 - cursor.a) + cursor.rgb * cursor.a, 1.0);
    }

}