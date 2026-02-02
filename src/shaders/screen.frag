#version 330 core

// Uniforms
uniform sampler2D render_texture;

// Ins
in vec2 vs_tex_coords;

// Outs
out vec4 frag_color;

void main()
{          
    frag_color = vec4(vs_tex_coords, 1.0, 1.0);
}
