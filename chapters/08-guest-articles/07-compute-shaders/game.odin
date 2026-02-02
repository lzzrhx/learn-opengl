package main

import "core:fmt"
import "core:strings"
import "core:os"
import "core:log"
import "core:math"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Game :: struct {
    window:         glfw.WindowHandle,
    render_texture: u32,
    sp_compute:     u32,
    sp_screen:      u32,
    vao:            u32,
    vbo:            u32,
    frame:          u32,
    time:           f64,
    prev_time:      f64,
    dt:             f64,
    fps:            int,
}


game_init :: proc(game: ^Game) {
    // GLFW and OpenGL initialization
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    if OPTION_ANTI_ALIAS { glfw.WindowHint(glfw.SAMPLES, 4) }
    game.window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
    if game.window == nil {
        log.errorf("GLFW window creation failed.")
        glfw.Terminate()
        os.exit(1)
    }
    glfw.MakeContextCurrent(game.window)
    if !OPTION_VSYNC { glfw.SwapInterval(0) }
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    // Load shaders
    ok : bool
    game.sp_screen, ok = gl.load_shaders_file(SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.sp_compute, ok = gl.load_compute_file(SHADER_COMPUTE)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }

    // Render texture setup
    gl.GenTextures(1, &game.render_texture)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.render_texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, RENDER_TEXTURE_WIDTH, RENDER_TEXTURE_HEIGHT, 0, gl.RGBA, gl.FLOAT, nil)
    gl.BindImageTexture(0, game.render_texture, 0, gl.FALSE, 0, gl.READ_ONLY, gl.RGBA32F)

    // Enable depth testing
    //gl.Enable(gl.DEPTH_TEST)
    // Enable backface culling
    gl.Enable(gl.CULL_FACE)
    // Enable gamma correction
    if OPTION_GAMMA_CORRECTION { gl.Enable(gl.FRAMEBUFFER_SRGB) }
    // Enable multisampling (anti aliasing)
    if OPTION_ANTI_ALIAS { gl.Enable(gl.MULTISAMPLE) }
}


game_setup :: proc(game: ^Game) {
    gl.GenVertexArrays(1, &game.vao)
    gl.GenBuffers(1, &game.vbo)
    gl.BindVertexArray(game.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, game.vbo)
}


game_input :: proc(game: ^Game) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
}

game_update :: proc(game: ^Game) {
    game.time = glfw.GetTime()
    game.dt = game.time - game.prev_time
    if game.dt > 0.0 && game.frame % 30 == 0 { game.fps = int(1.0 / game.dt) }
    if game.frame % 500 == 0 {
        game.frame = 0
        log.debugf("FPS: %d", game.fps)
    }
    game.prev_time = game.time
    game.frame += 1
}

game_render :: proc(game: ^Game) {
    
    // Clear screen
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    // Generate render texture using compute shader
    gl.UseProgram(game.sp_compute)
    gl.DispatchCompute(RENDER_TEXTURE_WIDTH/10, RENDER_TEXTURE_HEIGHT/10, 1)
    gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT)

    // Display render texture
    gl.UseProgram(game.sp_screen)
    shader_set_int(game.sp_screen, "render_texture", 0)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, game.render_texture)
    gl.DrawArrays(gl.TRIANGLES, 0, 3)

    // Swap buffers
    glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    gl.DeleteProgram(game.sp_screen)
    gl.DeleteProgram(game.sp_compute)
    glfw.Terminate()
}
