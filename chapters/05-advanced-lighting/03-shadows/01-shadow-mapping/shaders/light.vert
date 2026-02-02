#version 330 core

// Uniforms
uniform mat4 model_mat;
uniform mat4 view_mat;
uniform mat4 projection_mat;

// Ins
layout (location = 0) in vec3 in_pos;

void main()
{
    gl_Position = projection_mat * view_mat * model_mat * vec4(in_pos, 1.0);
}