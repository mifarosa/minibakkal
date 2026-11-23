shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

// Inverted-hull outline. Extrudes radially from the mesh origin, so it works for the
// flat-shaded primitives used here (box/capsule/sphere/cylinder centered on the origin).
uniform float thickness = 0.08;
uniform vec4 outline_color : source_color = vec4(0.06, 0.04, 0.04, 1.0);

void vertex() {
	VERTEX += normalize(VERTEX) * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
