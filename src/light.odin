package main

import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

Light :: struct {
    pos:      glsl.vec3,
    scale:    glsl.vec3,
    ambient:  glsl.vec3,
    diffuse:  glsl.vec3,
    specular: glsl.vec3,
    mesh:     ^Mesh,
}

light_render :: proc(light: ^Light, shader_program: u32) {
    // Bind vertex array object
    gl.BindVertexArray(light.mesh.vao)
    // Model matrix
    modelMat: glsl.mat4 = 1
    modelMat *= glsl.mat4Translate(light.pos)
    modelMat *= glsl.mat4Scale(light.scale)
    shader_set_mat4(shader_program, "modelMat", modelMat)
    shader_set_vec3(shader_program, "lightColor", light.specular)
    // Draw primitves
    gl.DrawArrays(gl.TRIANGLES, 0, light.mesh.tris)
}