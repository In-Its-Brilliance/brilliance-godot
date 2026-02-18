shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec3 character_position = vec3(7.5, 0.0, 7.5);
uniform float fade_distance : hint_range(0.0, 2000.0) = 295.0;
uniform float fade_range : hint_range(1.0, 500.0) = 64.0;
uniform sampler2D texture_albedo : source_color, filter_nearest;

varying vec3 world_vertex;

void vertex() {
    world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);
    if (albedo_tex.a < 0.5) discard;

    float dist = length(character_position - world_vertex);
    float fade = 1.0 - smoothstep(fade_distance, fade_distance + fade_range, dist);

    // 4x4 Bayer dithering
    int x = int(FRAGCOORD.x) % 4;
    int y = int(FRAGCOORD.y) % 4;
    int index = x + y * 4;
    float threshold;
    if (index == 0) threshold = 0.0625;
    else if (index == 1) threshold = 0.5625;
    else if (index == 2) threshold = 0.1875;
    else if (index == 3) threshold = 0.6875;
    else if (index == 4) threshold = 0.8125;
    else if (index == 5) threshold = 0.3125;
    else if (index == 6) threshold = 0.9375;
    else if (index == 7) threshold = 0.4375;
    else if (index == 8) threshold = 0.25;
    else if (index == 9) threshold = 0.75;
    else if (index == 10) threshold = 0.125;
    else if (index == 11) threshold = 0.625;
    else if (index == 12) threshold = 1.0;
    else if (index == 13) threshold = 0.5;
    else if (index == 14) threshold = 0.875;
    else threshold = 0.375;

    if (fade < threshold) discard;

    ALBEDO = albedo_tex.rgb;
}