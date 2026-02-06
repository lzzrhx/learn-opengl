package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"

Model :: struct {
    pos:      glsl.vec3,
    scale:    glsl.vec3,
    mesh:     ^Mesh,
    material: ^Material,
    rotate:   bool,
}

model_new :: proc(models: ^[dynamic]Model, pos: glsl.vec3, rotate: bool = false, scale: glsl.vec3 = {1.0, 1.0, 1.0}, mesh: ^Mesh, material: ^Material) {
    append(models, Model{ pos = pos, scale = scale, rotate = rotate, mesh = mesh, material = material })
}

model_render :: proc(model: ^Model, shader_program: u32, shadow_pass: bool = false) {
    // Model matrix
    model_mat: glsl.mat4 = 1
    model_mat *= glsl.mat4Translate(model.pos)
    if model.rotate {
        model_mat *= glsl.mat4Rotate({0.5, 1.0, 0.0}, f32(glfw.GetTime()) * glsl.radians_f32(20.0))
    }
    model_mat *= glsl.mat4Scale(model.scale)
    shader_set_mat4(shader_program, "model_mat", model_mat)
    if !shadow_pass {
        shader_set_mat3(shader_program, "normal_mat", glsl.mat3(glsl.inverse_transpose(model_mat)));
        //shader_set_int(shader_program, "material.diffuse", 0)
        //shader_set_int(shader_program, "material.specular", 1)
        shader_set_float(shader_program, "material.shininess", model.material.shininess)
        shader_set_vec3(shader_program, "material.color", model.material.color)
        // Set active texture (0)
        //gl.ActiveTexture(gl.TEXTURE0)
        // Bind texture object (0)
        //gl.BindTexture(gl.TEXTURE_2D, model.material.diffuse)
        // Set active texture (1)
        //gl.ActiveTexture(gl.TEXTURE1)
        // Bind texture object (1)
        //gl.BindTexture(gl.TEXTURE_2D, model.material.specular)
    }
    // Draw primitves
    gl.BindVertexArray(model.mesh.vao)
    gl.DrawElements(gl.TRIANGLES, model.mesh.num_indices, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}
