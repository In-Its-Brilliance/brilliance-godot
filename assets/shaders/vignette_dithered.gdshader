shader_type canvas_item;
render_mode unshaded;

uniform float darken_amount : hint_range(0.0, 1.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.3;  // сила виньетки

float random(vec2 seed, float pmin, float pmax) {
    return pmin + fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453123) * (pmax - pmin);
}

void fragment() {
    vec4 start_color = COLOR;
    
    // расстояние от центра (0 в центре, ~0.707 в углах)
    vec2 center = UV - 0.5;
    float dist = length(center) * vignette_strength;
    
    // плавное затемнение к краям
    float darkness = smoothstep(0.0, 1.0, dist) * darken_amount;
    
    // дизеринг для сглаживания бандинга
    darkness += random(UV, -0.5, 0.5) / 255.0;
    
    COLOR = vec4(start_color.rgb * (1.0 - darkness), start_color.a);
}