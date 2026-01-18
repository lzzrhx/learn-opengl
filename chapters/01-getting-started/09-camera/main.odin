package main

import "core:c"
import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

WINDOW_WIDTH  :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE  :: "gl"
GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3
VERTEX_SHADER :: "./shaders/vertex.vs"
FRAGMENT_SHADER :: "./shaders/fragment.fs"
CURSOR_SENSITIVITY :: 0.1

Game :: struct {
    window: glfw.WindowHandle,
    cursor_prev: glsl.vec2,
    cursor_moved: bool,
}

game := &Game{
    cursor_prev = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
}

camera := &Camera{
    pos   = {0.0, 0.0, 3.0},
    up    = {0, 1, 0},
    front = {0, 0, -1},
    dir   = 0,
    speed = 2.5,
    yaw   = -90,
    pitch = 0,
    fov   = 45.0,
}

// Set vertices
vertices := [?]f32 {
    // Positions:      // Texture coords:
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
}

// Set cube positions
cube_positions := [?]glsl.vec3{
    {0.0, 0.0, 0.0},
    {2.0, 5.0, -15.0},
    {-1.5, -2.2, -2.5},
    {-3.8, -2.0, -12.3},
    {2.4, -0.4, -3.5},
    {-1.7, 3.0, -7.5},
    {1.3, -2.0, -2.5},
    {1.5, 2.0, -2.5},
    {1.5, 0.2, -1.5},
    {-1.3, 1.0, -1.5},
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
    gl.Viewport(0, 0, width, height)
}

glfw_cursor_pos_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
    if !game.cursor_moved {
        game.cursor_prev = {f32(x), f32(y)}
        game.cursor_moved = true
    }
    delta: glsl.vec2 = {f32(x) - game.cursor_prev.x, game.cursor_prev.y - f32(y)}
    delta *= CURSOR_SENSITIVITY
    game.cursor_prev = {f32(x), f32(y)}
    camera.yaw += delta.x
    camera.pitch += delta.y
    if camera.pitch > 89.0 { camera.pitch = 89.0}
    if camera.pitch < -89.0 { camera.pitch = -89.0}
    camera.front = glsl.normalize_vec3({
        math.cos_f32(glsl.radians_f32(camera.yaw)) * math.cos_f32(glsl.radians_f32(camera.pitch)),
        math.sin_f32(glsl.radians_f32(camera.pitch)),
        math.sin_f32(glsl.radians_f32(camera.yaw)) * math.cos_f32(glsl.radians_f32(camera.pitch))
    })
}

glfw_scroll_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
    camera.fov -= f32(y)
    if camera.fov < 1.0 { camera.fov = 1.0 }
    if camera.fov > 45.0 { camera.fov = 45.0 }
}

input :: proc "c" (time_delta: f64) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(game.window, true)
    }
    if glfw.GetKey(game.window, glfw.KEY_W) == glfw.PRESS {
        camera.pos += camera.speed * f32(time_delta) * camera.front
    }
    else if glfw.GetKey(game.window, glfw.KEY_S) == glfw.PRESS {
        camera.pos -= camera.speed * f32(time_delta) * camera.front
    }
    if glfw.GetKey(game.window, glfw.KEY_A) == glfw.PRESS {
        camera.pos -= camera.speed * f32(time_delta) * glsl.normalize_vec3(glsl.cross_vec3(camera.front, camera.up))
    }
    else if glfw.GetKey(game.window, glfw.KEY_D) == glfw.PRESS {
        camera.pos += camera.speed * f32(time_delta) * glsl.normalize_vec3(glsl.cross_vec3(camera.front, camera.up))
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
    game.window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)
    if game.window == nil {
        log.errorf("GLFW window creation failed.")
        glfw.Terminate()
        os.exit(1)
    }
    glfw.MakeContextCurrent(game.window)
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    glfw.SetFramebufferSizeCallback(game.window, glfw_framebuffer_size_callback)

    // Load shaders from file
    shader_program, ok := gl.load_shaders_file(VERTEX_SHADER, FRAGMENT_SHADER)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }

    // Declare vertex array object
    vao: u32
    // Generate vertex array and store ID in the VAO variable
    gl.GenVertexArrays(1, &vao)
    // Declare vertex buffer object id
    vbo: u32
    // Generate object buffer and store ID in the VBO variable
    gl.GenBuffers(1, &vbo)
    // Bind vertex array object
    gl.BindVertexArray(vao)
    // Bind the vertex buffer to the type ARRAY_BUFFER (the buffer type used for vertex buffer objects)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    // Copy the vertices into the (currently bound) buffer memory
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(&vertices), gl.STATIC_DRAW)
    // Specify how to interpret vertex data (position)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)
    // Specify how to interpret vertex data (texture coords)
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(1)

    // Load texture (0)
    texture0: u32
    img_width, img_height, img_channels: i32
    gl.GenTextures(1, &texture0)
    gl.BindTexture(gl.TEXTURE_2D, texture0)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    img := stbi.load("../assets/container.jpg", &img_width, &img_height, &img_channels, 0)
    if img == nil {
        log.errorf("Failed to load texture image.")
        os.exit(1)
    }
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, img_width, img_height, 0, gl.RGB, gl.UNSIGNED_BYTE, img)
    gl.GenerateMipmap(gl.TEXTURE_2D)
    stbi.image_free(img)

    // Load texture (1)
    texture1: u32
    gl.GenTextures(1, &texture1)
    gl.BindTexture(gl.TEXTURE_2D, texture1)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    stbi.set_flip_vertically_on_load(1)
    img = stbi.load("../assets/awesomeface.png", &img_width, &img_height, &img_channels, 0)
    if img == nil {
        log.errorf("Failed to load texture image.")
        os.exit(1)
    }
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, img_width, img_height, 0, gl.RGBA, gl.UNSIGNED_BYTE, img)
    gl.GenerateMipmap(gl.TEXTURE_2D)
    stbi.image_free(img)

    // Enable depth testing
    gl.Enable(gl.DEPTH_TEST)

    // Enable wireframe mode
    //gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    // Hide mouse cursor and set the mouse control callback functions
    glfw.SetInputMode(game.window, glfw.CURSOR, glfw.CURSOR_DISABLED)
    glfw.SetCursorPosCallback(game.window, glfw_cursor_pos_callback)
    glfw.SetScrollCallback(game.window, glfw_scroll_callback)

    // Set the shader program
    gl.UseProgram(shader_program)

    // Set the texture units for the shader samplers
    shader_set_int(shader_program, "tex0", 0)
    shader_set_int(shader_program, "tex1", 1)

    // Time measurement variables
    time_current: f64
    time_prev: f64
    dt: f64

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {

        // Calculate deltatime
        time_current = glfw.GetTime()
        dt = time_current - time_prev
        time_prev = time_current

        // Handle input
        input(dt)

        // Clear screen
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        // Set active texture (0)
        gl.ActiveTexture(gl.TEXTURE0)
        // Bind texture object (0)
        gl.BindTexture(gl.TEXTURE_2D, texture0)
        // Set active texture (1)
        gl.ActiveTexture(gl.TEXTURE1)
        // Bind texture object (1)
        gl.BindTexture(gl.TEXTURE_2D, texture1)

        // Projection matrix
        projection: glsl.mat4 = 1
        projection *= glsl.mat4Perspective(glsl.radians_f32(camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), 0.1, 100.0)
        shader_set_mat4(shader_program, "projection", projection)
        
        // View matrix
        view: glsl.mat4 = glsl.mat4LookAt(camera.pos, camera.pos + camera.front, camera.up)
        shader_set_mat4(shader_program, "view", view)
        
        // Bind vertex array object
        gl.BindVertexArray(vao)
        // Draw all 10 cubes
        for position, i in cube_positions {
            // Model matrix
            model: glsl.mat4 = 1
            model *= glsl.mat4Translate(position)
            model *= glsl.mat4Rotate({0.5, 1.0, 0.0}, f32(glfw.GetTime()) * glsl.radians_f32(20.0) * f32(i+1))
            shader_set_mat4(shader_program, "model", model)
            // Draw primitves
            gl.DrawArrays(gl.TRIANGLES, 0, 36)
        }

        glfw.SwapBuffers(game.window)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }

    // Exit the program
    gl.DeleteVertexArrays(1, &vao)
    gl.DeleteBuffers(1, &vbo)
    gl.DeleteProgram(shader_program)
    glfw.Terminate()
}