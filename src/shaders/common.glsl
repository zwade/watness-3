#ifdef GL_ES
	precision highp float;
	precision highp int;
#endif

uniform float time;
uniform float dt;
uniform vec2 resolution;
uniform ivec4 loopback[250];

varying vec3 surface_loc;
varying vec3 color;
varying vec3 focus;
varying vec3 viewport_center;

@define PATH_LEN 100

@define PATH 0.0
@define MOUSE_LOCATION 100.0
@define PLAYER_LOCATION 102.0
@define VIEW_ANGLE 104.0
@define ACTIVE_PUZZLE 120.0
@define ACTIVE_LEVEL 121.0
@define SOLUTION1 130.0
@define SOLUTION2 136.0
@define SOLUTION3 142.0
@define COMPLETE 150.0
@define KEY_LEFT 200.0
@define KEY_RIGHT 201.0
@define KEY_UP 202.0
@define KEY_DOWN 203.0
@define CLICK 204.0
@define RIGHT_CLICK 205.0
@define MOUSE_DELTA 210.0

#define imin(x,y) (x < y ? x : y)
#define minmax(x, minval, maxval) (min(max(x, minval), maxval))

#define read_float(addr, scale) fromWTFloat(loopback[int(addr)].xyz) * scale
#define read_byte(addr) loopback[int(addr)].x
#define read_ivec2(addr) loopback[int(addr)].xy
#define read_ivec3(addr) loopback[int(addr)].xyz
#define read_bool(addr) (loopback[int(addr)].x == 0 ? false : true)
#define read_vec2(addr, scale) vec2(read_float(addr, scale), read_float(int(addr) + 1, scale))
#define at_addr(addr, exp) if (gl_FragCoord.y <= 1.0 && gl_FragCoord.x > addr && gl_FragCoord.x <= addr + 1.0) { gl_FragColor = exp; return; }
#define write_float(addr, value, scale) at_addr(addr, vec4(toWTFloat((value) / (scale)), 0.0))
#define write_byte(addr, value) at_addr(addr, vec4(float(value) / 255.0, 0, 0, 0))
#define write_ivec2(addr, value) at_addr(addr, vec4(float(value.xy) / 255.0, 0, 0))
#define write_ivec3(addr, value) at_addr(addr, vec4(float(value.x) / 255.0, float(value.y) / 255.0, float(value.z) / 255.0, 0))
#define write_bool(addr, value) at_addr(addr, vec4(value ? 1.0 : 0.0, 0, 0, 0))

#define PI 3.1415

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

































