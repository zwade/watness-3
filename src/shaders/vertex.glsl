#ifdef GL_ES
	precision lowp float;
#endif
attribute vec3 position;
attribute vec3 myInput;
uniform vec2 rotation;
uniform vec2 footLocation;
varying vec3 focus;
varying vec3 surface_loc;
varying vec3 color;
void main() {
	vec4 base_position = vec4(position.xyz, 1);
	gl_Position = vec4(position.xyz, 1);

	mat4 ud_rotation_mat = mat4(
		vec4(1, 0,             0,              0),
		vec4(0, cos(rotation.y), -sin(rotation.y), 0),
		vec4(0, sin(rotation.y), cos(rotation.y),  0),
		vec4(0, 0,             0,              1)
	);

	mat4 lr_rotation_mat = mat4(
		vec4(cos(rotation.x),  0, -sin(rotation.x), 0),
		vec4(0,              1, 0,             0),
		vec4(sin(rotation.x), 0, cos(rotation.x), 0),
		vec4(0,              0, 0,             1)
	);

	mat4 translation_mat = mat4(
		vec4(1, 0, 0, (footLocation.x - 0.5) * 1.5),
		vec4(0, 1, 0, 0),
		vec4(0, 0, 1, (footLocation.y - 0.5) * 1.5),
		vec4(0, 0, 0, 1)
	);
	vec4 full_focus = (vec4(0, 0, -1.5, 1) * lr_rotation_mat) * ud_rotation_mat;
	focus = full_focus.xyz / full_focus.w;

	vec4 result = ((base_position * translation_mat) * lr_rotation_mat) * ud_rotation_mat;
	surface_loc = result.xyz / result.w;
	color = vec3(surface_loc.z);
}
