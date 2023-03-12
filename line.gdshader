shader_type canvas_item;

uniform float activity;
uniform float position_offset;
const vec4 inactive_color = vec4(0.1, 0.1, 0.1, 0.5);
const vec4 active_color = vec4(0.7, 0.25, 0.7, 0.9);

void fragment() {
	float wave_start = VERTEX.x + position_offset;
	float wave = sin((wave_start / 10.0 - TIME)) / 2.0 + 1.0;
	COLOR = mix(inactive_color, active_color, clamp(wave * activity, 0.0, 1.0));
}
