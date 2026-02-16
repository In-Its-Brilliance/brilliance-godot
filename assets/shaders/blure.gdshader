shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float darken : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 ps = SCREEN_PIXEL_SIZE;
    vec4 color = vec4(0.0);
    
    // 9-tap gaussian blur
    color += texture(screen_texture, SCREEN_UV + vec2(-ps.x, -ps.y) * blur_amount) * 0.0625;
    color += texture(screen_texture, SCREEN_UV + vec2(0.0, -ps.y) * blur_amount) * 0.125;
    color += texture(screen_texture, SCREEN_UV + vec2(ps.x, -ps.y) * blur_amount) * 0.0625;
    color += texture(screen_texture, SCREEN_UV + vec2(-ps.x, 0.0) * blur_amount) * 0.125;
    color += texture(screen_texture, SCREEN_UV) * 0.25;
    color += texture(screen_texture, SCREEN_UV + vec2(ps.x, 0.0) * blur_amount) * 0.125;
    color += texture(screen_texture, SCREEN_UV + vec2(-ps.x, ps.y) * blur_amount) * 0.0625;
    color += texture(screen_texture, SCREEN_UV + vec2(0.0, ps.y) * blur_amount) * 0.125;
    color += texture(screen_texture, SCREEN_UV + vec2(ps.x, ps.y) * blur_amount) * 0.0625;
    
    // затемнение
    color.rgb *= (1.0 - darken);
    
    COLOR = color;
}