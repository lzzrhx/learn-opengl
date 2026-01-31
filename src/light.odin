package main

import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

DirLight :: struct {
    dir:         glsl.vec3,
    diffuse:     glsl.vec3,
    specular:    glsl.vec3,
}

PointLight :: struct {
    pos:         glsl.vec3,
    diffuse:     glsl.vec3,
    specular:    glsl.vec3,
    constant:    f32,
    linear:      f32,
    quadratic:   f32,
    scale:       glsl.vec3,
    mesh:        ^Mesh,
}

SpotLight :: struct {
    pos:         glsl.vec3,
    dir:         glsl.vec3,
    diffuse:     glsl.vec3,
    specular:    glsl.vec3,
    cutoff:      f32,
    cutoff_outer: f32,
    constant:    f32,
    linear:      f32,
    quadratic:   f32,
}

point_light_render :: proc(light: ^PointLight, shader_program: u32) {
    // Bind vertex array object
    gl.BindVertexArray(light.mesh.vao)
    // Model matrix
    model_mat: glsl.mat4 = 1
    model_mat *= glsl.mat4Translate(light.pos)
    model_mat *= glsl.mat4Scale(light.scale)
    shader_set_mat4(shader_program, "model_mat", model_mat)
    shader_set_vec3(shader_program, "color", light.diffuse)
    // Draw primitves
    gl.DrawElements(gl.TRIANGLES, light.mesh.num_indices, gl.UNSIGNED_INT, nil)
}
