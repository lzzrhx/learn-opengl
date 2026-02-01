#version 330 core

// Uniforms
uniform mat4 shadow_mat;
uniform mat4 model_mat;

// Ins
layout (location = 0) in vec3 in_pos;

void main() {
    gl_Position = shadow_mat * model_mat * vec4(in_pos, 1.0);
}
