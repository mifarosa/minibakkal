shader_type spatial;
render_mode specular_disabled;

// Simple cel shading: lit / mid / shadow bands.
uniform vec4 albedo_color : source_color = vec4(1.0);

void fragment() {
	ALBEDO = albedo_color.rgb;
}

void light() {
	float nl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = step(0.05, nl) * 0.45 + step(0.5, nl) * 0.55;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
