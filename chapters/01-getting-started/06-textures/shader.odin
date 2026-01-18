package main

import gl "vendor:OpenGL"

shader_set_bool :: proc(id: u32, name: cstring, value: bool) {
    gl.Uniform1i(gl.GetUniformLocation(id, name), i32(value))
}

shader_set_int :: proc(id: u32, name: cstring, value: i32) {
    gl.Uniform1i(gl.GetUniformLocation(id, name), value)
}

shader_set_float :: proc(id: u32, name: cstring, value: f32) {
    gl.Uniform1f(gl.GetUniformLocation(id, name), value)
}