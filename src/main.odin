package main

import gl "vendor:OpenGL"
import "vendor:glfw"
import "core:fmt"
import "core:os"
import "core:log"
import "core:mem"

WINDOW_WIDTH  :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE  :: "gl"
GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
    gl.Viewport(0, 0, width, height)
}

input :: proc "c" (window: glfw.WindowHandle) {
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, true)
    }
}

main :: proc() {
    // Tracking allocator and logger set up
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)
    // GLFW and OpenGL initialization
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
    if window == nil {
        log.errorf("GLFW window creation failed.")
        glfw.Terminate()
        os.exit(1)
    }
    glfw.MakeContextCurrent(window)
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    glfw.SetFramebufferSizeCallback(window, glfw_framebuffer_size_callback)
    // Main Loop
    for !glfw.WindowShouldClose(window) {
        input(window)
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
    glfw.Terminate()
}