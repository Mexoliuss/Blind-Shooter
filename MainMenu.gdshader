shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = 0.15;
uniform float density : hint_range(0.0, 2.0) = 1.0;
uniform vec4 smoke_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Ruido simple basado en hash (rápido y liviano)
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Suma varias capas de ruido a distintas escalas (fractal noise)
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// Movemos dos capas de ruido en direcciones distintas para dar sensación de volumen
	vec2 motion1 = uv * 3.0 + vec2(t, t * 0.5);
	vec2 motion2 = uv * 4.0 - vec2(t * 0.7, t * 0.3);

	float n1 = fbm(motion1);
	float n2 = fbm(motion2);

	float smoke = (n1 * 0.6 + n2 * 0.4) * density;
	smoke = clamp(smoke, 0.0, 1.0);

	vec4 final_color = mix(bg_color, smoke_color, smoke);
	COLOR = final_color;
}