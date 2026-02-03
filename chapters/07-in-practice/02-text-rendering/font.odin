package main

import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

font_render_int :: proc(game: ^Game, m: int, y: f32, scale: f32) {
    font_mat: glsl.mat4
    font_scale: glsl.vec3 = {scale, scale, scale}
    for i, n := int_num_digits(m), m; n > 0; {
        font_mat = 1
        font_mat *= glsl.mat4Translate({-1.0+scale, 1.0-scale, 0.0} + {f32(i-1)*scale, y*1.5*scale, 0.0})
        font_mat *= glsl.mat4Scale(font_scale)
        shader_set_mat4(game.sp_font, "font_mat", font_mat)
        shader_set_int(game.sp_font, "character", i32(16 + n%10))
        gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
        n /= 10
        i -= 1
    }
}

font_render_string :: proc(game: ^Game, txt: string, y: f32, scale: f32) {
    font_mat: glsl.mat4
    font_scale: glsl.vec3 = {scale, scale, scale}
    for r, i in txt {
        n := u32(r)
        n = (n < 32 || n > 127) ? 63 - 32 : n - 32
        if n > 0 {
            font_mat = 1
            font_mat *= glsl.mat4Translate({-1.0+scale, 1.0-scale, 0.0} + {f32(i)*scale, -y*1.5*scale, 0.0})
            font_mat *= glsl.mat4Scale(font_scale)
            shader_set_mat4(game.sp_font, "font_mat", font_mat)
            shader_set_int(game.sp_font, "character", i32(n))
            gl.DrawArrays(gl.TRIANGLE_FAN, 0, 4)
        }
    }
}
