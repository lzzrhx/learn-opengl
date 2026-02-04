#version 330 core

// In
layout (location = 0) in vec3 in_pos;
layout (location = 1) in vec3 in_normal;
layout (location = 2) in vec2 in_tex_coords;

// Uniform
uniform mat3 normal_mat;
uniform mat4 model_mat;
uniform mat4 view_mat;
uniform mat4 projection_mat;
uniform mat4 shadow_mat;

// Out
out vec3 vs_pos;
out vec3 vs_normal;
out vec2 vs_tex_coords;
out vec4 vs_shadow_pos;

void main()
{
    gl_Position = projection_mat * view_mat * model_mat * vec4(in_pos, 1.0);
    vs_pos = vec3(model_mat * vec4(in_pos, 1.0));
    vs_normal = normal_mat * in_normal;
    vs_tex_coords = in_tex_coords;
    vs_shadow_pos = shadow_mat * vec4(vs_pos, 1.0);
}
