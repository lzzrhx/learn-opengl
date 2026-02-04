#version 330 core

// In
layout (location = 0) in vec3 in_pos;

// Uniform
uniform mat4 shadow_mat;
uniform mat4 model_mat;

void main() {
    gl_Position = shadow_mat * model_mat * vec4(in_pos, 1.0);
}
