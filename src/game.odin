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
    window:                glfw.WindowHandle,
    shader_program:        u32,
    shader_program_light:  u32,
    shader_program_shadow: u32,
    shader_program_screen: u32,
    ambient_light:         glsl.vec3,
    //point_lights:          ^[NUM_POINT_LIGHTS]PointLight,
    dir_light:             ^DirLight,
    //spot_light:            ^SpotLight,
    camera:                ^Camera,
    primitives:            map[Primitive]Mesh,
    meshes:                map[string]Mesh,
    materials:             [dynamic]Material,
    models:                [dynamic]Model,
    shadowmap_fbo:         u32,
    shadowmap:             u32,
}


game_init :: proc(game: ^Game) {
    // GLFW and OpenGL initialization
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.SAMPLES, 4)
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
    game.shader_program, ok = gl.load_shaders_file(VS_DEFAULT, FS_DEFAULT)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.shader_program_light, ok = gl.load_shaders_file(VS_LIGHT, FS_LIGHT)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.shader_program_shadow, ok = gl.load_shaders_file(VS_SHADOW, FS_EMPTY)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    game.shader_program_screen, ok = gl.load_shaders_file(VS_SCREEN, FS_SCREEN)
    if !ok {
        log.errorf("Shader loading failed.")
        os.exit(1)
    }
    // Enable depth testing
    gl.Enable(gl.DEPTH_TEST)
    // Enable backface culling
    gl.Enable(gl.CULL_FACE)
    // Enable gamma correction
    gl.Enable(gl.FRAMEBUFFER_SRGB)
    // Enable multisampling (anti aliasing)
    gl.Enable(gl.MULTISAMPLE)
    // Enable blending
    //gl.Enable(gl.BLEND)
    //gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    // Shadowmap setup
    gl.GenFramebuffers(1, &game.shadowmap_fbo)
    gl.GenTextures(1, &game.shadowmap)
    gl.BindTexture(gl.TEXTURE_2D, game.shadowmap)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, SHADOWMAP_SIZE, SHADOWMAP_SIZE, 0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
    border_color := [?]f32 { 1.0, 1.0, 1.0, 1.0 }
    gl.TexParameterfv(gl.TEXTURE_2D, gl.TEXTURE_BORDER_COLOR, raw_data(border_color[:]))
    gl.BindFramebuffer(gl.FRAMEBUFFER, game.shadowmap_fbo)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, game.shadowmap, 0)
    gl.DrawBuffer(gl.NONE)
    gl.ReadBuffer(gl.NONE)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    
    // Load primitive meshes
    mesh_load_primitives(&game.primitives);
}

game_setup :: proc(game: ^Game) {

    // Load meshes
    gltf_load(&game.meshes, "bunny", "./assets/bunny.glb")

    // Initialize materials
    material_new(
        &game.materials,
        //diffuse = texture_load(DIFFUSE_TEXTURE),
        //specular = texture_load(SPECULAR_TEXTURE),
        color = {0.5, 0.5, 0.5},
        shininess = 32.0,
    )

    // Initialize models
    model_new(
        &game.models,
        pos      = {-2.0,  1.0, -7.0},
        mesh     = &game.meshes["bunny"],
        material = &game.materials[0],
    )
    model_new(
        &game.models,
        pos      = { 0.0,  1.0, -7.0},
        mesh     = &game.meshes["bunny"],
        material = &game.materials[0],
        rotate   = true,
    )
    model_new(
        &game.models,
        pos      = { 2.0,  1.0, -7.0},
        mesh     = &game.meshes["bunny"],
        material = &game.materials[0],
    )
    model_new(
        &game.models,
        pos      = { 2.0, 0.0, 0.0},
        scale    = {100.0, 100.0, 100.0},
        mesh     = &game.primitives[.Plane],
        material = &game.materials[0],
    )


    // Initialize lights
    game.ambient_light         = { 0.1,  0.1,  0.1}
    game.dir_light.dir         = { 0.0, -1.0,  0.0}
    game.dir_light.diffuse     = { 0.8,  0.8,  0.8}
    game.dir_light.specular    = { 1.0,  1.0,  1.0}
    //for light, i in game.point_lights {
    //    game.point_lights[i].constant    = 1.0
    //    game.point_lights[i].linear      = 0.09
    //    game.point_lights[i].quadratic   = 0.032
    //    game.point_lights[i].scale       = { 0.2,  0.2,  0.2}
    //    game.point_lights[i].mesh        = &game.primitives[.Cube]
    //}
    //game.point_lights[0].pos         = { 0.0,  0.0, -6.0}
    //game.point_lights[0].diffuse     = { 0.5,  0.5,  0.5}
    //game.point_lights[0].specular    = { 1.0,  1.0,  1.0}
    //game.point_lights[1].pos         = { 0.0,  0.0, -6.0}
    //game.point_lights[1].diffuse     = { 0.5,  0.5,  0.5}
    //game.point_lights[1].specular    = { 1.0,  1.0,  1.0}
    //game.point_lights[2].pos         = { 4.5,  0.0, -6.0}
    //game.point_lights[2].diffuse     = { 0.5,  0.0,  0.0}
    //game.point_lights[2].specular    = { 1.0,  0.0,  0.0}
    //game.point_lights[3].pos         = {-4.5,  0.0, -6.0}
    //game.point_lights[3].diffuse     = { 0.5,  0.0,  0.0}
    //game.point_lights[3].specular    = { 1.0,  0.0,  0.0}
    //game.spot_light.pos          = { 0.0,  0.0,  0.0}
    //game.spot_light.dir          = { 0.0,  0.0, -1.0}
    //game.spot_light.diffuse      = { 0.2,  0.2,  0.2}
    //game.spot_light.specular     = { 1.0,  1.0,  1.0}
    //game.spot_light.constant     = 1.0
    //game.spot_light.linear       = 0.09
    //game.spot_light.quadratic    = 0.032
    //game.spot_light.cutoff       = math.cos_f32(glsl.radians_f32(12.5))
    //game.spot_light.cutoff_outer = math.cos_f32(glsl.radians_f32(17.5))
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
    //game.point_lights[0].pos.x = math.sin_f32(f32(glfw.GetTime())) * 2;
    //game.point_lights[0].pos.y = math.cos_f32(f32(glfw.GetTime())) * 2;
    //game.point_lights[1].pos.y = math.sin_f32(f32(glfw.GetTime())) * 2;
    //game.point_lights[1].pos.z = math.cos_f32(f32(glfw.GetTime())) * 2 - 7.0;
    //game.point_lights[2].pos.y = math.sin_f32(f32(glfw.GetTime()));
    //game.point_lights[3].pos.y = math.sin_f32(f32(glfw.GetTime()));
    //game.spot_light.pos = game.camera.pos
    //game.spot_light.dir = game.camera.front
}


game_render :: proc(game: ^Game) {
        
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)

    // Render to shadowmap
    gl.Enable(gl.DEPTH_TEST)
    gl.Viewport(0, 0, SHADOWMAP_SIZE, SHADOWMAP_SIZE)
    gl.BindFramebuffer(gl.FRAMEBUFFER, game.shadowmap_fbo)
    gl.Clear(gl.DEPTH_BUFFER_BIT)
    
    //near_plane: f32 = 1.0
    //far_plane: f32 = 7.5
    shadow_projection := glsl.mat4Ortho3d(-10.0, 10.0, -10.0, 10.0, CLIP_NEAR, CLIP_FAR)
    shadow_view := glsl.mat4LookAt(game.camera.pos + {0.0, 10.0, 0.0}, game.camera.pos + {0.0, 10.0, 0.01} + game.dir_light.dir, {0.0, 1.0, 0.0})
    shadow_mat := shadow_projection * shadow_view
    
    gl.UseProgram(game.shader_program_shadow)
    shader_set_mat4(game.shader_program_shadow, "shadow_mat", shadow_mat)
    
    for &model in game.models {
        model_render(&model, game.shader_program_shadow)
    }

    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    //gl.UseProgram(game.shader_program_screen)
    //shader_set_int(game.shader_program_screen, "shadow_map", 0)
    //gl.DrawArrays(gl.TRIANGLES, 0, 3)

    // Set projection matrix
    projection_mat := glsl.mat4Perspective(glsl.radians_f32(game.camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), CLIP_NEAR, CLIP_FAR)
    // Set view matrix
    view_mat := glsl.mat4LookAt(game.camera.pos, game.camera.pos + game.camera.front, game.camera.up)
    // Render entities
    gl.UseProgram(game.shader_program)
    shader_set_int(game.shader_program, "shadow_map", 0)
    shader_set_mat4(game.shader_program, "shadow_mat", shadow_mat)
    shader_set_mat4(game.shader_program, "projection_mat", projection_mat)
    shader_set_mat4(game.shader_program, "view_mat", view_mat)
    shader_set_vec3(game.shader_program, "view_pos", game.camera.pos)
    shader_set_vec3(game.shader_program, "ambient_light", game.ambient_light)
    shader_set_vec3(game.shader_program, "dir_light.dir", game.dir_light.dir)
    shader_set_vec3(game.shader_program, "dir_light.diffuse", game.dir_light.diffuse)
    shader_set_vec3(game.shader_program, "dir_light.specular", game.dir_light.specular)
    //shader_set_vec3(game.shader_program,  "spot_light.pos",            game.spot_light.pos)
    //shader_set_vec3(game.shader_program,  "spot_light.dir",            game.spot_light.dir)
    //shader_set_vec3(game.shader_program,  "spot_light.diffuse",        game.spot_light.diffuse)
    //shader_set_vec3(game.shader_program,  "spot_light.specular",       game.spot_light.specular)
    //shader_set_float(game.shader_program, "spot_light.constant",       game.spot_light.constant)
    //shader_set_float(game.shader_program, "spot_light.linear",         game.spot_light.linear)
    //shader_set_float(game.shader_program, "spot_light.quadratic",      game.spot_light.quadratic)
    //shader_set_float(game.shader_program, "spot_light.cutoff",         game.spot_light.cutoff)
    //shader_set_float(game.shader_program, "spot_light.cutoff_outer",   game.spot_light.cutoff_outer)
    //shader_set_vec3(game.shader_program,  "point_lights[0].pos",       game.point_lights[0].pos)
    //shader_set_vec3(game.shader_program,  "point_lights[0].diffuse",   game.point_lights[0].diffuse)
    //shader_set_vec3(game.shader_program,  "point_lights[0].specular",  game.point_lights[0].specular)
    //shader_set_float(game.shader_program, "point_lights[0].constant",  game.point_lights[0].constant)
    //shader_set_float(game.shader_program, "point_lights[0].linear",    game.point_lights[0].linear)
    //shader_set_float(game.shader_program, "point_lights[0].quadratic", game.point_lights[0].quadratic)
    //shader_set_vec3(game.shader_program,  "point_lights[1].pos",       game.point_lights[1].pos)
    //shader_set_vec3(game.shader_program,  "point_lights[1].diffuse",   game.point_lights[1].diffuse)
    //shader_set_vec3(game.shader_program,  "point_lights[1].specular",  game.point_lights[1].specular)
    //shader_set_float(game.shader_program, "point_lights[1].constant",  game.point_lights[1].constant)
    //shader_set_float(game.shader_program, "point_lights[1].linear",    game.point_lights[1].linear)
    //shader_set_float(game.shader_program, "point_lights[1].quadratic", game.point_lights[1].quadratic)
    //shader_set_vec3(game.shader_program,  "point_lights[2].pos",       game.point_lights[2].pos)
    //shader_set_vec3(game.shader_program,  "point_lights[2].diffuse",   game.point_lights[2].diffuse)
    //shader_set_vec3(game.shader_program,  "point_lights[2].specular",  game.point_lights[2].specular)
    //shader_set_float(game.shader_program, "point_lights[2].constant",  game.point_lights[2].constant)
    //shader_set_float(game.shader_program, "point_lights[2].linear",    game.point_lights[2].linear)
    //shader_set_float(game.shader_program, "point_lights[2].quadratic", game.point_lights[2].quadratic)
    //shader_set_vec3(game.shader_program,  "point_lights[3].pos",       game.point_lights[3].pos)
    //shader_set_vec3(game.shader_program,  "point_lights[3].diffuse",   game.point_lights[3].diffuse)
    //shader_set_vec3(game.shader_program,  "point_lights[3].specular",  game.point_lights[3].specular)
    //shader_set_float(game.shader_program, "point_lights[3].constant",  game.point_lights[3].constant)
    //shader_set_float(game.shader_program, "point_lights[3].linear",    game.point_lights[3].linear)
    //shader_set_float(game.shader_program, "point_lights[3].quadratic", game.point_lights[3].quadratic)
    for &model in game.models {
        model_render(&model, game.shader_program)
    }
    // Render light
    //gl.UseProgram(game.light_shader_program)
    //shader_set_mat4(game.light_shader_program, "projection_mat", projection_mat)
    //shader_set_mat4(game.light_shader_program, "view_mat", view_mat)
    //for &light in game.point_lights {
    //    point_light_render(&light, game.light_shader_program)
    //}
    // Swap buffers
    glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    defer glfw.Terminate()
    defer delete(game.primitives)
    defer delete(game.meshes)
    defer delete(game.materials)
    defer delete(game.models)
    //free(game.point_lights)
    gl.DeleteProgram(game.shader_program)
    gl.DeleteProgram(game.shader_program_light)
    gl.DeleteProgram(game.shader_program_shadow)
    gl.DeleteProgram(game.shader_program_screen)
    for key, &mesh in game.primitives {
        mesh_destroy(&mesh)
    }
    for key, &mesh in game.meshes {
        mesh_destroy(&mesh)
    }
}
