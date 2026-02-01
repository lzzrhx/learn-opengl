package main

import gl "vendor:OpenGL"
import "core:log"

Mesh :: struct {
    vao: u32,
    vbo: u32,
    ebo: u32,
    num_indices: i32,
}

Primitive :: enum {
    Plane,
    Cube,
}

mesh_new :: proc(verts: []f32, indices: []u32) -> Mesh {
    mesh := Mesh{}
    // Count number of indices
    mesh.num_indices = i32(len(indices))
    // Generate vertex array and store ID in the VAO variable
    gl.GenVertexArrays(1, &mesh.vao)
    // Generate object buffer and store ID in the VBO variable
    gl.GenBuffers(1, &mesh.vbo)
    // Generate buffer object and store ID in the EBO variable
    gl.GenBuffers(1, &mesh.ebo)
    // Bind vertex array object
    gl.BindVertexArray(mesh.vao)
    // Bind the vertex buffer to the type ARRAY_BUFFER (the buffer type used for vertex buffer objects)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    // Copy the vertices into the (currently bound) buffer memory
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(verts), raw_data(verts), gl.STATIC_DRAW)
    // Bind the element buffer to the type ELEMENT_ARRAY_BUFFER
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    // Copy the indices into the (currently bound) buffer memory
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(f32) * len(indices), raw_data(indices), gl.STATIC_DRAW)
    // Specify how to interpret vertex data (position)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    // Specify how to interpret vertex data (normals)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)
    // Specify how to interpret vertex data (texture coords)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
    gl.EnableVertexAttribArray(2)
    // Return the mesh struct
    return mesh
}

mesh_destroy :: proc(mesh: ^Mesh) {
    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ebo)
}

mesh_load_primitives :: proc(primitives: ^map[Primitive]Mesh) {
    for primitive in Primitive {
        switch primitive {
            case .Plane:
                verts := [?]f32 {
                    // Vertex coords:    Normals:            Texture coords:
                    -0.5,  0.0,  0.5,    0.0,  1.0,  0.0,    0.0, 1.0,
                     0.5,  0.0,  0.5,    0.0,  1.0,  0.0,    1.0, 1.0,
                    -0.5,  0.0, -0.5,    0.0,  1.0,  0.0,    0.0, 0.0,
                     0.5,  0.0, -0.5,    0.0,  1.0,  0.0,    1.0, 0.0,
                }
                indices := [?]u32 {
                    0, 1, 2,
                    2, 1, 3,
                }
                primitives[.Plane] = mesh_new(verts[:], indices[:])
            case .Cube:
                verts := [?]f32 {
                    // Vertex coords:    Normals:            Texture coords:
                    // Face #1
                    -0.5, -0.5, -0.5,    0.0,  0.0, -1.0,    0.0, 0.0,
                     0.5, -0.5, -0.5,    0.0,  0.0, -1.0,    1.0, 0.0,
                     0.5,  0.5, -0.5,    0.0,  0.0, -1.0,    1.0, 1.0,
                    -0.5,  0.5, -0.5,    0.0,  0.0, -1.0,    0.0, 1.0,
                    // Face #2
                    -0.5, -0.5,  0.5,    0.0,  0.0,  1.0,    0.0, 0.0,
                     0.5, -0.5,  0.5,    0.0,  0.0,  1.0,    1.0, 0.0,
                     0.5,  0.5,  0.5,    0.0,  0.0,  1.0,    1.0, 1.0,
                    -0.5,  0.5,  0.5,    0.0,  0.0,  1.0,    0.0, 1.0,
                    // Face #3
                    -0.5,  0.5,  0.5,   -1.0,  0.0,  0.0,    1.0, 0.0,
                    -0.5,  0.5, -0.5,   -1.0,  0.0,  0.0,    1.0, 1.0,
                    -0.5, -0.5, -0.5,   -1.0,  0.0,  0.0,    0.0, 1.0,
                    -0.5, -0.5,  0.5,   -1.0,  0.0,  0.0,    0.0, 0.0,
                    // Face #4
                     0.5,  0.5,  0.5,    1.0,  0.0,  0.0,    1.0, 0.0,
                     0.5,  0.5, -0.5,    1.0,  0.0,  0.0,    1.0, 1.0,
                     0.5, -0.5, -0.5,    1.0,  0.0,  0.0,    0.0, 1.0,
                     0.5, -0.5,  0.5,    1.0,  0.0,  0.0,    0.0, 0.0,
                     // Face #5
                    -0.5, -0.5, -0.5,    0.0, -1.0,  0.0,    0.0, 1.0,
                     0.5, -0.5, -0.5,    0.0, -1.0,  0.0,    1.0, 1.0,
                     0.5, -0.5,  0.5,    0.0, -1.0,  0.0,    1.0, 0.0,
                    -0.5, -0.5,  0.5,    0.0, -1.0,  0.0,    0.0, 0.0,
                    // Face #6
                    -0.5,  0.5, -0.5,    0.0,  1.0,  0.0,    0.0, 1.0,
                     0.5,  0.5, -0.5,    0.0,  1.0,  0.0,    1.0, 1.0,
                     0.5,  0.5,  0.5,    0.0,  1.0,  0.0,    1.0, 0.0,
                    -0.5,  0.5,  0.5,    0.0,  1.0,  0.0,    0.0, 0.0,
                }
                indices := [?]u32 {
                     0,  2,  1,
                     3,  2,  0,
                     4,  6,  5,
                     7,  6,  4,
                     8, 10,  9,
                    11, 10,  8,
                    12, 14, 13,
                    15, 14, 12,
                    16, 18, 17,
                    19, 18, 16,
                    20, 22, 21,
                    23, 22, 20,
                }
                primitives[.Cube] = mesh_new(verts[:], indices[:])
        }
    }
}
