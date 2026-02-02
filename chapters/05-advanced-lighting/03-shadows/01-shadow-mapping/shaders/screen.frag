#version 330 core

// Uniforms
uniform sampler2D shadow_map;

// Ins
in vec3 vs_pos;

// Outs
out vec4 frag_color;

void main()
{          
    vec2 coord = vec2(gl_FragCoord.x / 1920, gl_FragCoord.y / 1080);
    float depth_value = texture(shadow_map, coord).r;
    frag_color = vec4(vec3(texture(shadow_map, coord).r), 1.0);
}
