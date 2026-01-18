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
FRAGMENT_SHADER_LIGHT :: "./shaders/light.fs"

Game :: struct {
    window:                glfw.WindowHandle,
    shader_program: u32,
    light_shader_program:  u32,
    light:                 ^Entity,
    camera:                ^Camera,
    entities:              [dynamic]Entity,
    models:                [dynamic]Model,
}

input :: proc(game: ^Game, dt: f64) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_W) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * game.camera.front }
    else if glfw.GetKey(game.window, glfw.KEY_S) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * game.camera.front }
    if glfw.GetKey(game.window, glfw.KEY_A) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    else if glfw.GetKey(game.window, glfw.KEY_D) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
}


init :: proc(game: ^Game) {
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
    // Load shaders from file
    ok : bool
    game.shader_program, ok = gl.load_shaders_file(VERTEX_SHADER, FRAGMENT_SHADER)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.light_shader_program, ok = gl.load_shaders_file(VERTEX_SHADER, FRAGMENT_SHADER_LIGHT)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    // Enable depth testing
    gl.Enable(gl.DEPTH_TEST)
    // Enable wireframe mode
    //gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
}


exit :: proc(game: ^Game) {
    defer glfw.Terminate()
    defer delete(game.models)
    defer delete(game.entities)
    gl.DeleteProgram(game.shader_program)
    models_destroy(&game.models)
}

render :: proc(game: ^Game) {
        // Clear screen
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        // Set view matrix
        view := glsl.mat4LookAt(game.camera.pos, game.camera.pos + game.camera.front, game.camera.up)
        // Render entities
        gl.UseProgram(game.shader_program)
        shader_set_mat4(game.shader_program, "view", view)
        for &entity in game.entities {
            entity_render(&entity, game.shader_program)
        }
        // Render light
        gl.UseProgram(game.light_shader_program)
        shader_set_mat4(game.light_shader_program, "view", view)
        entity_render(game.light, game.light_shader_program)
        // Swap buffers
        glfw.SwapBuffers(game.window)
}

main :: proc() {
    // Tracking allocator and logger set up
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)

    // Program initialization
    game := &Game{
        models = make([dynamic]Model),
        camera = &Camera{
            pos   = {0.0, 0.0, 3.0},
            up    = {0, 1, 0},
            front = {0, 0, -1},
            dir   = 0,
            speed = 2.5,
            yaw   = -90,
            pitch = 0,
            fov   = 45.0,
        },
    }
    init(game)
    defer exit(game)

    // Model initialization
    cube := &Model{}
    // Set vertices
    cube_verts := [?]f32 {
        // Face #1
        -0.5, -0.5, -0.5,
         0.5, -0.5, -0.5,
         0.5,  0.5, -0.5,
         0.5,  0.5, -0.5,
        -0.5,  0.5, -0.5,
        -0.5, -0.5, -0.5,
        // Face #2
        -0.5, -0.5,  0.5,
         0.5, -0.5,  0.5,
         0.5,  0.5,  0.5,
         0.5,  0.5,  0.5,
        -0.5,  0.5,  0.5,
        -0.5, -0.5,  0.5,
        // Face #3
        -0.5,  0.5,  0.5,
        -0.5,  0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, -0.5,  0.5,
        -0.5,  0.5,  0.5,
        // Face #4
         0.5,  0.5,  0.5,
         0.5,  0.5, -0.5,
         0.5, -0.5, -0.5,
         0.5, -0.5, -0.5,
         0.5, -0.5,  0.5,
         0.5,  0.5,  0.5,
         // Face #5
        -0.5, -0.5, -0.5,
         0.5, -0.5, -0.5,
         0.5, -0.5,  0.5,
         0.5, -0.5,  0.5,
        -0.5, -0.5,  0.5,
        -0.5, -0.5, -0.5,
        // Face #6
        -0.5,  0.5, -0.5,
         0.5,  0.5, -0.5,
         0.5,  0.5,  0.5,
         0.5,  0.5,  0.5,
        -0.5,  0.5,  0.5,
        -0.5,  0.5, -0.5,
    }
    model_new(&game.models, cube_verts[:])
    model_new(&game.models, cube_verts[:])

    // Light initialization
    game.light = &Entity{ pos = {4.0, 4.0, -10.0}, model = &game.models[0] }
    
    // Entity initialization
    append(&game.entities, Entity{ pos = {0.0, 0.0, 0.0}, model = &game.models[1] })

    // Set projection matrix
    projection := glsl.mat4Perspective(glsl.radians_f32(game.camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), 0.1, 100.0)

    // Set the shader uniforms
    gl.UseProgram(game.shader_program)
    shader_set_vec3(game.shader_program, "objectColor", 1.0, 0.5, 0.3)
    shader_set_vec3(game.shader_program, "lightColor", 1.0, 1.0, 1.0)
    shader_set_mat4(game.shader_program, "projection", projection)
    gl.UseProgram(game.light_shader_program)
    shader_set_mat4(game.light_shader_program, "projection", projection)

    // Time measurement variables
    time_current: f64
    time_prev: f64
    dt: f64

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {
        time_current = glfw.GetTime()
        dt = time_current - time_prev
        time_prev = time_current
        input(game, dt)
        render(game)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }
}