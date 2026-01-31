package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Model :: struct {
    pos:      glsl.vec3,
    scale:    glsl.vec3,
    mesh:     ^Mesh,
    material: ^Material,
}

model_new :: proc(models: ^[dynamic]Model, pos: glsl.vec3, mesh: ^Mesh, material: ^Material) {
    append(models, Model{ pos = pos, scale = {1.0, 1.0, 1.0}, mesh = mesh, material = material })
}

model_render :: proc(model: ^Model, shader_program: u32) {
    // Model matrix
    model_mat: glsl.mat4 = 1
    model_mat *= glsl.mat4Translate(model.pos)
    model_mat *= glsl.mat4Rotate({0.5, 1.0, 0.0}, f32(glfw.GetTime()) * glsl.radians_f32(20.0))
    model_mat *= glsl.mat4Scale(model.scale)
    shader_set_mat4(shader_program, "model_mat", model_mat)
    shader_set_mat3(shader_program, "normal_mat", glsl.mat3(glsl.inverse_transpose(model_mat)));
    shader_set_float(shader_program, "material.shininess", model.material.shininess)
    shader_set_vec3(shader_program, "material.color", model.material.color)
    // Bind vertex array object
    gl.BindVertexArray(model.mesh.vao)
    // Draw primitves
    gl.DrawElements(gl.TRIANGLES, model.mesh.num_indices, gl.UNSIGNED_INT, nil)
}
