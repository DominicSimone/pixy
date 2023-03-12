shader_type canvas_item;

uniform float activity;
uniform float position_offset;
const vec4 inactive_color = vec4(0, 0, 0, 0.25);
const vec4 active_color = vec4(0.7, 0.25, 0.7, 0.9);

void fragment() {
	float wave_start = VERTEX.x + position_offset;
	float wave = sin((wave_start / 10.0 - TIME * 2.5)) / 2.0 + 0.5;
	COLOR = mix(inactive_color, active_color, wave * clamp(activity, 0.0, 1.0));
}
