shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, shadows_disabled;

uniform vec4 shallow_color : source_color = vec4(0.2, 0.5, 0.75, 0.35);
uniform vec4 mid_color : source_color = vec4(0.08, 0.3, 0.7, 0.7);
uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.55, 0.95);
uniform float depth_distance : hint_range(0.0, 100.0) = 30.0;
uniform float depth_curve : hint_range(0.1, 10.0) = 8.0;
uniform float depth_offset : hint_range(0.0, 1.0) = 0.1;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
    float depth_raw = texture(depth_texture, SCREEN_UV).r;

    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    float scene_depth = -view_pos.z;
    float water_depth = -VERTEX.z;

    float depth_diff = max(scene_depth - water_depth - depth_offset, 0.0);
    float t = clamp(depth_diff / depth_distance, 0.0, 1.0);

    float depth_factor = 1.0 - exp(-depth_curve * t);

    vec4 water_color;
    if (depth_factor < 0.5) {
        water_color = mix(shallow_color, mid_color, depth_factor * 2.0);
    } else {
        water_color = mix(mid_color, deep_color, (depth_factor - 0.5) * 2.0);
    }

    vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
    ALBEDO = mix(screen_color, water_color.rgb, water_color.a);
    ALPHA = 1.0;

    ROUGHNESS = 0.05;
    METALLIC = 0.1;
}