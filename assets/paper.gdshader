shader_type canvas_item;
// 纸纹 + 极淡暗角：细颗粒，不能出现块状色差。
uniform vec4 paper_color : source_color = vec4(0.957, 0.945, 0.918, 1.0);
uniform float grain_strength : hint_range(0.0, 0.03) = 0.008;
uniform float vignette_strength : hint_range(0.0, 0.2) = 0.05;

float hash21(vec2 p) {
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 23.45);
	return fract(p.x * p.y);
}

// 平滑值噪声：双线性插值，避免出现方块
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec3 c = paper_color.rgb;
	vec2 px = UV * vec2(1600.0, 900.0);
	// 细颗粒（每像素级）
	float fine = hash21(px) - 0.5;
	// 纸张纤维（低频平滑）
	float fiber = vnoise(UV * vec2(60.0, 34.0)) - 0.5;
	// 极低频不匀
	float blotch = vnoise(UV * vec2(6.0, 4.0)) - 0.5;
	c += fine * grain_strength * 0.9 + fiber * grain_strength * 1.6 + blotch * grain_strength * 1.2;
	// 暗角
	vec2 uv = UV - 0.5;
	c -= dot(uv, uv) * vignette_strength;
	COLOR = vec4(c, 1.0);
}
