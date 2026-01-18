package main

import gl "vendor:OpenGL"
import "core:log"

Model :: struct {
    vao: u32,
    vbo: u32,
}

models_destroy :: proc(models: ^[dynamic]Model) {
    for &model in models {
        model_destroy(&model)
    }
}

model_new :: proc(models: ^[dynamic]Model, verts: []f32) {
    model := Model{}
    // Generate vertex array and store ID in the VAO variable
    gl.GenVertexArrays(1, &model.vao)
    // Generate object buffer and store ID in the VBO variable
    gl.GenBuffers(1, &model.vbo)
    // Bind vertex array object
    gl.BindVertexArray(model.vao)
    // Bind the vertex buffer to the type ARRAY_BUFFER (the buffer type used for vertex buffer objects)
    gl.BindBuffer(gl.ARRAY_BUFFER, model.vbo)
    // Copy the vertices into the (currently bound) buffer memory
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(verts), raw_data(verts), gl.STATIC_DRAW)
    // Specify how to interpret vertex data (position)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    append(models, model)
}

model_destroy :: proc(model: ^Model) {
    gl.DeleteVertexArrays(1, &model.vao)
    gl.DeleteBuffers(1, &model.vbo)
}
