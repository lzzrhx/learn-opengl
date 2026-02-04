#version 330 core

// In
in vec4 gs_pos;

// Uniform
uniform vec3 light_pos;
uniform float far_plane;

void main()
{
    gl_FragDepth = length(gs_pos.xyz - light_pos) / far_plane;
}  
