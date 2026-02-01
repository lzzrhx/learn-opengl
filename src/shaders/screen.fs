#version 330 core

// Uniforms
uniform sampler2D shadow_map;

// Outs
out vec4 frag_color;

// Ins
in vec2 vs_tex_coords;

void main()
{             
    float depth_value = texture(shadow_map, vs_tex_coords).r;
    frag_color = vec4(vec3(depth_value), 1.0);
}
