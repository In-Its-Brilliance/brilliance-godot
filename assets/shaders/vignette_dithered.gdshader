shader_type canvas_item;

uniform float darken_amount : hint_range(0.0, 1.0) = 0.6;
uniform float vignette_strength : hint_range(0.0, 3.0) = 1.5;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 center = UV - 0.5;
    float dist = length(center) * vignette_strength;
    
    float darkness = smoothstep(vignette_start, 1.0, dist) * darken_amount;
    
    COLOR = vec4(0.0, 0.0, 0.0, darkness);
}