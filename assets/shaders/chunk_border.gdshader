shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform float depth_bias = 0.001;

void vertex() {
    vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    POSITION = PROJECTION_MATRIX * view;

    // Bias depth toward the camera without moving the line on screen.
    view.z += depth_bias;
    vec4 biased = PROJECTION_MATRIX * view;
    POSITION.z = biased.z / biased.w * POSITION.w;
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = 1.0;
}
