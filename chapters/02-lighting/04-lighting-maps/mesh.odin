package main

import gl "vendor:OpenGL"
import "core:log"

Mesh :: struct {
    vao: u32,
    vbo: u32,
    tris: i32,
}

mesh_new :: proc(meshes: ^[dynamic]Mesh, verts: []f32) {
    mesh := Mesh{}
    mesh.tris = i32(len(verts) / 8)
    // Generate vertex array and store ID in the VAO variable
    gl.GenVertexArrays(1, &mesh.vao)
    // Generate object buffer and store ID in the VBO variable
    gl.GenBuffers(1, &mesh.vbo)
    // Bind vertex array object
    gl.BindVertexArray(mesh.vao)
    // Bind the vertex buffer to the type ARRAY_BUFFER (the buffer type used for vertex buffer objects)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    // Copy the vertices into the (currently bound) buffer memory
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(verts), raw_data(verts), gl.STATIC_DRAW)
    // Specify how to interpret vertex data (position)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    // Specify how to interpret vertex data (normals)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)
    // Specify how to interpret vertex data (texture coords)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
    gl.EnableVertexAttribArray(2)
    append(meshes, mesh)
}

mesh_destroy :: proc(mesh: ^Mesh) {
    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
}
