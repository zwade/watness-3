@include "./common.glsl"

attribute vec3 position;
attribute vec3 myInput;

void main() {
    vec2 aspectRatio = vec2(1.0, resolution.x / resolution.y);
	vec4 base_position = vec4(position.xy / aspectRatio, 2, 1);
	gl_Position = vec4(position.xyz, 1);

	vec2 rotation = read_vec2(VIEW_ANGLE, 1.0) * vec2(2.0 * PI, PI) + vec2(0, 3.0 * PI / 2.0);
	vec2 footLocation = read_vec2(PLAYER_LOCATION, 1.0);

	mat4 ud_rotation_mat = mat4(
		vec4(1, 0,               0,                0),
		vec4(0, cos(rotation.y), -sin(rotation.y), 0),
		vec4(0, sin(rotation.y), cos(rotation.y),  0),
		vec4(0, 0,               0,                1)
	);

	mat4 lr_rotation_mat = mat4(
		vec4(cos(rotation.x), 0, -sin(rotation.x), 0),
		vec4(0,               1, 0,                0),
		vec4(sin(rotation.x), 0, cos(rotation.x),  0),
		vec4(0,               0, 0,                1)
	);

	mat4 translation_mat = mat4(
		vec4(1, 0, 0, (footLocation.x - 0.5) * 18.0),
		vec4(0, 1, 0, 0),
		vec4(0, 0, 1, (footLocation.y - 0.5) * 18.0),
		vec4(0, 0, 0, 1)
	);

	vec4 full_focus = ((vec4(0, 0, 0, 1) * ud_rotation_mat) * lr_rotation_mat) * translation_mat;
	focus = full_focus.xyz / full_focus.w;

	vec4 full_center = ((vec4(0, 0, 1, 1) * ud_rotation_mat) * lr_rotation_mat) * translation_mat;
	viewport_center = full_center.xyz / full_center.w;

	vec4 result = ((base_position * ud_rotation_mat) * lr_rotation_mat) * translation_mat;
	surface_loc = result.xyz / result.w;

	color = vec3(surface_loc.z);
}
