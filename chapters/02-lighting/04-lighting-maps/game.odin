package main

import "core:os"
import "core:log"
import "core:math"
import "vendor:glfw"
import "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Game :: struct {
    window:                glfw.WindowHandle,
    shader_program:        u32,
    light_shader_program:  u32,
    light:                 ^Light,
    camera:                ^Camera,
    meshes:                [dynamic]Mesh,
    materials:             [dynamic]Material,
    models:                [dynamic]Model,
}


game_init :: proc(game: ^Game) {
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
    game.light_shader_program, ok = gl.load_shaders_file(VERTEX_SHADER_LIGHT, FRAGMENT_SHADER_LIGHT)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    // Enable depth testing
    gl.Enable(gl.DEPTH_TEST)
}

game_setup :: proc(game: ^Game) {
    // Load meshes
    cube_verts := [?]f32 {
        // Vertex coords:    Normals:            Texture coords:
        // Face #1
        -0.5, -0.5, -0.5,    0.0,  0.0, -1.0,    0.0, 0.0,
         0.5, -0.5, -0.5,    0.0,  0.0, -1.0,    1.0, 0.0,
         0.5,  0.5, -0.5,    0.0,  0.0, -1.0,    1.0, 1.0,
         0.5,  0.5, -0.5,    0.0,  0.0, -1.0,    1.0, 1.0,
        -0.5,  0.5, -0.5,    0.0,  0.0, -1.0,    0.0, 1.0,
        -0.5, -0.5, -0.5,    0.0,  0.0, -1.0,    0.0, 0.0,
        // Face #2
        -0.5, -0.5,  0.5,    0.0,  0.0,  1.0,    0.0, 0.0,
         0.5, -0.5,  0.5,    0.0,  0.0,  1.0,    1.0, 0.0,
         0.5,  0.5,  0.5,    0.0,  0.0,  1.0,    1.0, 1.0,
         0.5,  0.5,  0.5,    0.0,  0.0,  1.0,    1.0, 1.0,
        -0.5,  0.5,  0.5,    0.0,  0.0,  1.0,    0.0, 1.0,
        -0.5, -0.5,  0.5,    0.0,  0.0,  1.0,    0.0, 0.0,
        // Face #3
        -0.5,  0.5,  0.5,   -1.0,  0.0,  0.0,    1.0, 0.0,
        -0.5,  0.5, -0.5,   -1.0,  0.0,  0.0,    1.0, 1.0,
        -0.5, -0.5, -0.5,   -1.0,  0.0,  0.0,    0.0, 1.0,
        -0.5, -0.5, -0.5,   -1.0,  0.0,  0.0,    0.0, 1.0,
        -0.5, -0.5,  0.5,   -1.0,  0.0,  0.0,    0.0, 0.0,
        -0.5,  0.5,  0.5,   -1.0,  0.0,  0.0,    1.0, 0.0,
        // Face #4
         0.5,  0.5,  0.5,    1.0,  0.0,  0.0,    1.0, 0.0,
         0.5,  0.5, -0.5,    1.0,  0.0,  0.0,    1.0, 1.0,
         0.5, -0.5, -0.5,    1.0,  0.0,  0.0,    0.0, 1.0,
         0.5, -0.5, -0.5,    1.0,  0.0,  0.0,    0.0, 1.0,
         0.5, -0.5,  0.5,    1.0,  0.0,  0.0,    0.0, 0.0,
         0.5,  0.5,  0.5,    1.0,  0.0,  0.0,    1.0, 0.0,
         // Face #5
        -0.5, -0.5, -0.5,    0.0, -1.0,  0.0,    0.0, 1.0,
         0.5, -0.5, -0.5,    0.0, -1.0,  0.0,    1.0, 1.0,
         0.5, -0.5,  0.5,    0.0, -1.0,  0.0,    1.0, 0.0,
         0.5, -0.5,  0.5,    0.0, -1.0,  0.0,    1.0, 0.0,
        -0.5, -0.5,  0.5,    0.0, -1.0,  0.0,    0.0, 0.0,
        -0.5, -0.5, -0.5,    0.0, -1.0,  0.0,    0.0, 1.0,
        // Face #6
        -0.5,  0.5, -0.5,    0.0,  1.0,  0.0,    0.0, 1.0,
         0.5,  0.5, -0.5,    0.0,  1.0,  0.0,    1.0, 1.0,
         0.5,  0.5,  0.5,    0.0,  1.0,  0.0,    1.0, 0.0,
         0.5,  0.5,  0.5,    0.0,  1.0,  0.0,    1.0, 0.0,
        -0.5,  0.5,  0.5,    0.0,  1.0,  0.0,    0.0, 0.0,
        -0.5,  0.5, -0.5,    0.0,  1.0,  0.0,    0.0, 1.0,
    }
    mesh_new(&game.meshes, cube_verts[:])

    // Initialize materials
    material_new(
        &game.materials,
        diffuse = texture_load(DIFFUSE_TEXTURE),
        specular = texture_load(SPECULAR_TEXTURE),
        shininess = 32.0,
    )
    
    // Initialize model
    model_new(
        &game.models,
        pos      = { 0.0,  0.0, -7.0},
        mesh     = &game.meshes[0],
        material = &game.materials[0],
    )

    // Initialize light
    game.light.pos = { 0.0,  0.0, -7.0}
    game.light.scale    = { 0.2,  0.2,  0.2}
    game.light.ambient  = { 0.2, 0.2, 0.2}
    game.light.diffuse  = { 0.5, 0.5, 0.5}
    game.light.specular = { 1.0, 1.0, 1.0}
    game.light.mesh     = &game.meshes[0]
}


game_input :: proc(game: ^Game, dt: f64) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_W) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * game.camera.front }
    else if glfw.GetKey(game.window, glfw.KEY_S) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * game.camera.front }
    if glfw.GetKey(game.window, glfw.KEY_A) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    else if glfw.GetKey(game.window, glfw.KEY_D) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    if glfw.GetKey(game.window, glfw.KEY_E) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(dt) * glsl.normalize_vec3(game.camera.up) }
    else if glfw.GetKey(game.window, glfw.KEY_Q) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(dt) * glsl.normalize_vec3(game.camera.up) }
    if glfw.GetKey(game.window, glfw.KEY_UP) == glfw.PRESS { game.camera.pitch += 75.0 * f32(dt) }
    else if glfw.GetKey(game.window, glfw.KEY_DOWN) == glfw.PRESS { game.camera.pitch -= 75.0 * f32(dt) }
    if glfw.GetKey(game.window, glfw.KEY_LEFT) == glfw.PRESS { game.camera.yaw -= 75.0 * f32(dt) }
    else if glfw.GetKey(game.window, glfw.KEY_RIGHT) == glfw.PRESS { game.camera.yaw += 75.0 * f32(dt) }
    if game.camera.pitch > 89.0 { game.camera.pitch = 89.0}
    else if game.camera.pitch < -89.0 { game.camera.pitch = -89.0}
    game.camera.front = glsl.normalize_vec3({
        math.cos_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch))
    })
}


game_update :: proc(game: ^Game, dt: f64) {
    game.light.pos.x = math.sin_f32(f32(glfw.GetTime())) * 2;
    game.light.pos.y = math.cos_f32(f32(glfw.GetTime())) * 2;
}


game_render :: proc(game: ^Game) {
        // Clear screen
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        // Set projection matrix
        projectionMat := glsl.mat4Perspective(glsl.radians_f32(game.camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), 0.1, 100.0)
        // Set view matrix
        viewMat := glsl.mat4LookAt(game.camera.pos, game.camera.pos + game.camera.front, game.camera.up)
        // Render entities
        gl.UseProgram(game.shader_program)
        shader_set_mat4(game.shader_program, "projectionMat", projectionMat)
        shader_set_mat4(game.shader_program, "viewMat", viewMat)
        shader_set_vec3(game.shader_program, "viewPos", game.camera.pos)
        shader_set_vec3(game.shader_program, "lightPos", game.light.pos)
        shader_set_vec3(game.shader_program, "light.ambient", game.light.ambient)
        shader_set_vec3(game.shader_program, "light.diffuse", game.light.diffuse)
        shader_set_vec3(game.shader_program, "light.specular", game.light.specular)
        for &model in game.models {
            model_render(&model, game.shader_program)
        }
        // Render light
        gl.UseProgram(game.light_shader_program)
        shader_set_mat4(game.light_shader_program, "projectionMat", projectionMat)
        shader_set_mat4(game.light_shader_program, "viewMat", viewMat)
        light_render(game.light, game.light_shader_program)
        // Swap buffers
        glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    defer glfw.Terminate()
    defer delete(game.meshes)
    defer delete(game.materials)
    defer delete(game.models)
    gl.DeleteProgram(game.shader_program)
    for &mesh in game.meshes {
        mesh_destroy(&mesh)
    }
}