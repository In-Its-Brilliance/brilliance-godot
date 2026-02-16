shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    
    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(outline_color * min(outline, 1.0), color, color.a);
}