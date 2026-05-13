shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float edge_width : hint_range(0.001, 0.1) = 0.007;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    float dx = min(abs(local_pos.x - 0.5005), abs(local_pos.x + 0.5005));
    float dy = min(abs(local_pos.y - 0.5005), abs(local_pos.y + 0.5005));
    float dz = min(abs(local_pos.z - 0.5005), abs(local_pos.z + 0.5005));

    float d0 = min(dx, min(dy, dz));
    float d2 = max(dx, max(dy, dz));
    float d1 = dx + dy + dz - d0 - d2;

    if (d0 > edge_width || d1 > edge_width) {
        discard;
    }

    vec2 screen_uv = FRAGCOORD.xy / VIEWPORT_SIZE;
    vec3 screen_color = texture(screen_tex, screen_uv).rgb;
    float luma = dot(screen_color, vec3(0.299, 0.587, 0.114));
    ALBEDO = luma > 0.5 ? vec3(0.2) : vec3(0.8);
    ALPHA = 0.4;
}