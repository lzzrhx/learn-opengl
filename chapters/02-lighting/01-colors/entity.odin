package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Entity :: struct {
    pos:   glsl.vec3,
    model: ^Model,
}

entity_new :: proc(entities: ^[dynamic]Entity, model: ^Model, pos: glsl.vec3) {
    append(entities, Entity{ pos = pos, model = model })
}

entity_render :: proc(entity: ^Entity, shader_program: u32) {
    // Bind vertex array object
    gl.BindVertexArray(entity.model.vao)
    // Model matrix
    model: glsl.mat4 = 1
    model *= glsl.mat4Translate(entity.pos)
    model *= glsl.mat4Rotate({1.0, 1.0, 0.0}, f32(glfw.GetTime()) * glsl.radians_f32(20.0))
    shader_set_mat4(shader_program, "model", model)
    // Draw primitves
    gl.DrawArrays(gl.TRIANGLES, 0, 36)
}