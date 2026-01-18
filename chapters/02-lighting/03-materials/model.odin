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
    // Bind vertex array object
    gl.BindVertexArray(model.mesh.vao)
    // Model matrix
    modelMat: glsl.mat4 = 1
    modelMat *= glsl.mat4Translate(model.pos)
    modelMat *= glsl.mat4Rotate({0.5, 1.0, 0.0}, f32(glfw.GetTime()) * glsl.radians_f32(20.0))
    modelMat *= glsl.mat4Scale(model.scale)
    shader_set_mat4(shader_program, "modelMat", modelMat)
    shader_set_mat3(shader_program, "normalMat", glsl.mat3(glsl.inverse_transpose(modelMat)));
    shader_set_vec3(shader_program, "material.ambient", model.material.ambient)
    shader_set_vec3(shader_program, "material.diffuse", model.material.diffuse)
    shader_set_vec3(shader_program, "material.specular", model.material.specular)
    shader_set_float(shader_program, "material.shininess", model.material.shininess)
    // Draw primitves
    gl.DrawArrays(gl.TRIANGLES, 0, model.mesh.tris)
}