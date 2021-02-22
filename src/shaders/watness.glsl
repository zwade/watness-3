#ifdef GL_ES
	precision lowp float;
#endif
#define PATH_LEN 100

uniform float time;
uniform float dt;
uniform vec2 resolution;
uniform vec2 mouse;
uniform vec2 footLocation;
uniform ivec4 loopback[300];
varying vec3 surface_loc;
varying vec3 color;
varying vec3 focus;


#define PATH 0.0
#define MOUSE_LOCATION 100.0
#define PLAYER_LOCATION 102.0
#define VIEW_ANGLE 104.0
#define ACTIVE_PUZZLE 120.0
#define KEY_LEFT 200.0
#define KEY_RIGHT 201.0
#define KEY_UP 202.0
#define KEY_DOWN 203.0
#define CLICK 204.0
#define RIGHT_CLICK 205.0
#define MOUSE_DELTA 210.0

#define imin(x,y) (x < y ? x : y)
#define minmax(x, minval, maxval) (min(max(x, minval), maxval))

#define read_float(addr, scale) fromWTFloat(loopback[addr].xyz) * scale
#define read_byte(addr) loopback[addr].x
#define read_ivec2(addr) loopback[addr].xy
#define read_ivec3(addr) loopback[addr].xyz
#define read_bool(addr) (loopback[addr].x == 0 ? false : true)
#define at_addr(addr, exp) if (gl_FragCoord.y <= 1.0 && gl_FragCoord.x > addr && gl_FragCoord.x <= addr + 1.0) { gl_FragColor = exp; return; }
#define write_float(addr, value, scale) at_addr(addr, vec4(toWTFloat((value) / (scale)), 0.0))
#define write_byte(addr, value) at_addr(addr, vec4(float(value) / 255.0, 0, 0, 0))
#define write_ivec2(addr, value) at_addr(addr, vec4(float(value.xy) / 255.0, 0, 0))
#define write_ivec3(addr, value) at_addr(addr, vec4(float(value.x) / 255.0, float(value.y) / 255.0, float(value.z) / 255.0, 0))
#define write_bool(addr, value) at_addr(addr, vec4(value ? 1.0 : 0.0, 0, 0, 0))

const int width = 9;
const int height = 9;
const float radius = 0.03;
const float PI = 3.1415;
const float scale = 0.50;

const vec4 pale_yellow = vec4(1.0, 1.0, 0.8, 1.0);
const vec4 default_empty = vec4(1.0, 0.0, 0.2, 1.0);
const vec4 orange = vec4(1.0, 0.6, 0.0, 1.0);


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

float fromWTFloat(ivec3 inp) {
    return (
        float(inp.x) * 256.0 * 256.0 +
        float(inp.y) * 256.0 +
        float(inp.z)
    ) / (256.0 * 256.0 * 256.0) * 2.0;
}

vec3 toWTFloat(float x) {
    float bigboi = (x / 2.0) * 256.0 * 256.0 * 256.0;
    return vec3(
        floor(bigboi / (256.0 * 256.0)) / 256.0,
        floor(mod(bigboi, 256.0 * 256.0) / 256.0) / 256.0,
        floor(mod(bigboi, 256.0)) / 256.0
    );
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
        ivec3 next = read_ivec3(int(PATH ) + i + 1);
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
        ivec3 next = read_ivec3(int(PATH ) + i + 1);
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

    if (where == ivec2(0, 0) && read_ivec3(int(PATH)) == ivec3(255, 255, 1)) {
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

vec2 normalizeMouse() {
    float mouseX = read_float(int(MOUSE_LOCATION), 1.0);
    float mouseY = read_float(int(MOUSE_LOCATION) + 1, 1.0);
    float mouseDx = read_float(int(MOUSE_DELTA), 1.0) - 0.5;
    float mouseDy = read_float(int(MOUSE_DELTA) + 1, 1.0) - 0.5;

    vec2 mouse = (vec2(mouseX + mouseDx, mouseY + mouseDy) - 0.5) * 2.0;
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
    float baseX = read_float(int(PLAYER_LOCATION), 1.0);
    float baseY = read_float(int(PLAYER_LOCATION) + 1, 1.0);
    vec2 base = vec2(baseX, baseY);
    if (read_bool(int(KEY_UP))) {
        base.y += 0.002 * dt;
    }
    if (read_bool(int(KEY_DOWN))) {
        base.y -= 0.002 * dt;
    }
    if (read_bool(int(KEY_LEFT))) {
        base.x -= 0.002 * dt;
    }
    if (read_bool(int(KEY_RIGHT))) {
        base.x += 0.002 * dt;
    }

    return minmax(base, vec2(0, 0), vec2(1, 1));
}

vec2 normalizeRotation() {

}

void main( void ) {
    vec4 empty = default_empty;

    vec2 newMouse = normalizeMouse();
    vec2 newLocation = normalizeLocation();

    vec2 aspectRatio = vec2(resolution.x / resolution.y, 1.0);
	// vec2 position =
    //     vec2((newLocation.x - 0.5) * 20.0, 0)
    //     + (2.0 * gl_FragCoord.xy / vec2(resolution.y, resolution.y) - aspectRatio) / scale / (newLocation.y + 0.5);
    // vec2 position = (surface_loc.xy * aspectRatio) / scale;
    vec3 center = vec3(0, 0, 3);
    vec3 normal = vec3(0, 0, -1);
    vec3 viewVector = surface_loc - focus;
    vec3 normalizedView = viewVector / sqrt(dot(viewVector, viewVector));
    float projection = dot(normalizedView, normal);
    float t = (-dot(focus - center, normal)) / projection;
    vec3 pointOnPlane = focus + normalizedView * t;
    vec2 position = pointOnPlane.xy * aspectRatio;

    float distToMouse = sqrt(pow(position.x - newMouse.x, 2.0) + pow(position.y - newMouse.y, 2.0));
    // vec4 empty = vec4(color.xyz, 1); // vec4(0.9, 0.0, 0.2, 1.0);
    if (distToMouse < radius) {
        gl_FragColor = orange;
        return;
    }

    write_float(MOUSE_LOCATION, newMouse.x / 2.0 + 0.5, 1.0)
    write_float(MOUSE_LOCATION + 1.0, newMouse.y / 2.0 + 0.5, 1.0)
    write_float(PLAYER_LOCATION, newLocation.x, 1.0)
    write_float(PLAYER_LOCATION + 1.0, newLocation.y, 1.0)

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

    if (gl_FragCoord.y <= 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
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
    } else {
        gl_FragColor = empty;
    }
}