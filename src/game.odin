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
    sp_solid:              u32,
    sp_font:               u32,
    sp_screen:             u32,
    sp_shadow:             u32,
    sp_light:              u32,
    ambient_light:         glsl.vec3,
    dir_light:             ^DirLight,
    point_lights:          ^[NUM_POINT_LIGHTS]PointLight,
    //spot_light:            ^SpotLight,
    camera:                ^Camera,
    primitives:            map[Primitive]Mesh,
    meshes:                map[string]Mesh,
    materials:             [dynamic]Material,
    //textured_materials:    [dynamic]TexturedMaterial,
    models:                [dynamic]Model,
    shadowmap_fbo:         u32,
    shadowmap:             u32,
    frame:                 u32,
    time:                  f64,
    prev_time:             f64,
    dt:                    f64,
    fps:                   int,
    font_texture:          u32,
    tex_id_shadowmap:      u32,
    tex_id_font:           u32,
}


gl_check_error :: proc(location := #caller_location) {
    if err := gl.GetError(); err != gl.NO_ERROR {
        log.errorf("OpenGL error! %s", gl.GL_Enum(err), location = location)
    }
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
    game.sp_solid, ok = gl.load_shaders_file(SHADER_SOLID_VERT, SHADER_SOLID_FRAG)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", SHADER_SOLID_VERT, SHADER_SOLID_FRAG)
        os.exit(1)
    }
    game.sp_font, ok = gl.load_shaders_file(SHADER_FONT_VERT, SHADER_FONT_FRAG)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", SHADER_FONT_VERT, SHADER_FONT_FRAG)
        os.exit(1)
    }
    game.sp_light, ok = gl.load_shaders_file(SHADER_LIGHT_VERT, SHADER_LIGHT_FRAG)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", SHADER_LIGHT_VERT, SHADER_LIGHT_FRAG)
        os.exit(1)
    }
    game.sp_shadow, ok = gl.load_shaders_file(SHADER_SHADOW_VERT, SHADER_EMPTY_FRAG)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", SHADER_SHADOW_VERT, SHADER_EMPTY_FRAG)
        os.exit(1)
    }
    game.sp_screen, ok = gl.load_shaders_file(SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
    if !ok {
        log.errorf("Shader loading failed. (%s %s)", SHADER_SCREEN_VERT, SHADER_SCREEN_FRAG)
        os.exit(1)
    }
    
    // OpenGL settings
    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    if OPTION_GAMMA_CORRECTION { gl.Enable(gl.FRAMEBUFFER_SRGB) }
    if OPTION_ANTI_ALIAS { gl.Enable(gl.MULTISAMPLE) }

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
    
    // Load font
    game.font_texture = texture_load(TEXTURE_FONT, filtering = false)

    // Set textures
    game.tex_id_font = 0;
    game.tex_id_shadowmap = 1;
    gl.ActiveTexture(gl.TEXTURE0 + game.tex_id_font)
    gl.BindTexture(gl.TEXTURE_2D, game.font_texture)
    gl.ActiveTexture(gl.TEXTURE0 + game.tex_id_shadowmap)
    gl.BindTexture(gl.TEXTURE_2D, game.shadowmap)
    gl.UseProgram(game.sp_font)
    shader_set_int(game.sp_font, "font_texture", i32(game.tex_id_font))
    gl.UseProgram(game.sp_solid)
    shader_set_int(game.sp_solid, "shadow_map", i32(game.tex_id_shadowmap))
}

game_setup :: proc(game: ^Game) {
    // Load meshes
    gltf_load(&game.meshes, "bunny", "./assets/bunny.glb")

    // Initialize materials
    material_new(
        &game.materials,
        color = {0.5, 0.5, 0.5},
        shininess = 32.0,
    )
    /*
    material_new_textured(
        &game.textured_materials,
        diffuse = texture_load(TEXTURE_DIFFUSE),
        specular = texture_load(TEXTURE_SPECULAR),
        shininess = 32.0,
    )
    */

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
        mesh     = &game.primitives[.Cube],
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
    game.point_lights[0].constant    = 1.0
    game.point_lights[0].linear      = 0.09
    game.point_lights[0].quadratic   = 0.032
    game.point_lights[0].scale       = { 0.2,  0.2,  0.2}
    game.point_lights[0].mesh        = &game.primitives[.Cube]
    game.point_lights[0].pos         = { 0.0,  0.0, -6.0}
    game.point_lights[0].diffuse     = { 0.5,  0.5,  0.5}
    game.point_lights[0].specular    = { 1.0,  1.0,  1.0}
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


game_input :: proc(game: ^Game) {
    if glfw.GetKey(game.window, glfw.KEY_ESCAPE) == glfw.PRESS { glfw.SetWindowShouldClose(game.window, true) }
    if glfw.GetKey(game.window, glfw.KEY_W) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(game.dt) * game.camera.front }
    else if glfw.GetKey(game.window, glfw.KEY_S) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(game.dt) * game.camera.front }
    if glfw.GetKey(game.window, glfw.KEY_A) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(game.dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    else if glfw.GetKey(game.window, glfw.KEY_D) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(game.dt) * glsl.normalize_vec3(glsl.cross_vec3(game.camera.front, game.camera.up)) }
    if glfw.GetKey(game.window, glfw.KEY_E) == glfw.PRESS { game.camera.pos += game.camera.speed * f32(game.dt) * glsl.normalize_vec3(game.camera.up) }
    else if glfw.GetKey(game.window, glfw.KEY_Q) == glfw.PRESS { game.camera.pos -= game.camera.speed * f32(game.dt) * glsl.normalize_vec3(game.camera.up) }
    if glfw.GetKey(game.window, glfw.KEY_UP) == glfw.PRESS { game.camera.pitch += 75.0 * f32(game.dt) }
    else if glfw.GetKey(game.window, glfw.KEY_DOWN) == glfw.PRESS { game.camera.pitch -= 75.0 * f32(game.dt) }
    if glfw.GetKey(game.window, glfw.KEY_LEFT) == glfw.PRESS { game.camera.yaw -= 75.0 * f32(game.dt) }
    else if glfw.GetKey(game.window, glfw.KEY_RIGHT) == glfw.PRESS { game.camera.yaw += 75.0 * f32(game.dt) }
    if game.camera.pitch > 89.0 { game.camera.pitch = 89.0}
    else if game.camera.pitch < -89.0 { game.camera.pitch = -89.0}
    game.camera.front = glsl.normalize_vec3({
        math.cos_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.pitch)),
        math.sin_f32(glsl.radians_f32(game.camera.yaw)) * math.cos_f32(glsl.radians_f32(game.camera.pitch))
    })
}


game_update :: proc(game: ^Game) {
    gl_check_error()
    game.time = glfw.GetTime()
    game.dt = game.time - game.prev_time
    if game.dt > 0.0 && game.frame % 30 == 0 { game.fps = int(1.0 / game.dt) }
    game.frame %= 1000
    game.prev_time = game.time
    game.frame += 1
    game.point_lights[0].pos.x = math.sin_f32(f32(glfw.GetTime())) * 2;
    game.point_lights[0].pos.y = math.cos_f32(f32(glfw.GetTime())) * 0.5 + 1;
}


game_render :: proc(game: ^Game) {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Enable(gl.DEPTH_TEST)

    // Render to shadowmap
    gl.Enable(gl.DEPTH_TEST)
    gl.Viewport(0, 0, SHADOWMAP_SIZE, SHADOWMAP_SIZE)
    gl.BindFramebuffer(gl.FRAMEBUFFER, game.shadowmap_fbo)
    gl.Clear(gl.DEPTH_BUFFER_BIT)
    shadow_projection := glsl.mat4Ortho3d(-10.0, 10.0, -10.0, 10.0, CLIP_NEAR, CLIP_FAR)
    shadow_view := glsl.mat4LookAt(game.camera.pos + {0.0, 10.0, 0.0}, game.camera.pos + {0.0, 10.0, 0.01} + game.dir_light.dir, {0.0, 1.0, 0.0})
    shadow_mat := shadow_projection * shadow_view
    gl.UseProgram(game.sp_shadow)
    shader_set_mat4(game.sp_shadow, "shadow_mat", shadow_mat)
    for &model in game.models {
        model_render(&model, game.sp_shadow)
    }

    // Render scene
    gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    // Set projection matrix
    projection_mat := glsl.mat4Perspective(glsl.radians_f32(game.camera.fov), f32(f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT)), CLIP_NEAR, CLIP_FAR)
    // Set view matrix
    view_mat := glsl.mat4LookAt(game.camera.pos, game.camera.pos + game.camera.front, game.camera.up)
    // Render entities
    gl.UseProgram(game.sp_solid)
    shader_set_mat4(game.sp_solid, "shadow_mat", shadow_mat)
    shader_set_mat4(game.sp_solid, "projection_mat", projection_mat)
    shader_set_mat4(game.sp_solid, "view_mat", view_mat)
    shader_set_vec3(game.sp_solid, "view_pos", game.camera.pos)
    shader_set_vec3(game.sp_solid, "ambient_light", game.ambient_light)
    shader_set_vec3(game.sp_solid, "dir_light.dir", game.dir_light.dir)
    shader_set_vec3(game.sp_solid, "dir_light.diffuse", game.dir_light.diffuse)
    shader_set_vec3(game.sp_solid, "dir_light.specular", game.dir_light.specular)
    //shader_set_vec3(game.sp_solid,  "spot_light.pos",            game.spot_light.pos)
    //shader_set_vec3(game.sp_solid,  "spot_light.dir",            game.spot_light.dir)
    //shader_set_vec3(game.sp_solid,  "spot_light.diffuse",        game.spot_light.diffuse)
    //shader_set_vec3(game.sp_solid,  "spot_light.specular",       game.spot_light.specular)
    //shader_set_float(game.sp_solid, "spot_light.constant",       game.spot_light.constant)
    //shader_set_float(game.sp_solid, "spot_light.linear",         game.spot_light.linear)
    //shader_set_float(game.sp_solid, "spot_light.quadratic",      game.spot_light.quadratic)
    //shader_set_float(game.sp_solid, "spot_light.cutoff",         game.spot_light.cutoff)
    //shader_set_float(game.sp_solid, "spot_light.cutoff_outer",   game.spot_light.cutoff_outer)
    shader_set_vec3(game.sp_solid,  "point_lights[0].pos",       game.point_lights[0].pos)
    shader_set_vec3(game.sp_solid,  "point_lights[0].diffuse",   game.point_lights[0].diffuse)
    shader_set_vec3(game.sp_solid,  "point_lights[0].specular",  game.point_lights[0].specular)
    shader_set_float(game.sp_solid, "point_lights[0].constant",  game.point_lights[0].constant)
    shader_set_float(game.sp_solid, "point_lights[0].linear",    game.point_lights[0].linear)
    shader_set_float(game.sp_solid, "point_lights[0].quadratic", game.point_lights[0].quadratic)
    for &model in game.models {
        model_render(&model, game.sp_solid)
    }
    // Render lights
    gl.UseProgram(game.sp_light)
    shader_set_mat4(game.sp_light, "projection_mat", projection_mat)
    shader_set_mat4(game.sp_light, "view_mat", view_mat)
    for &light in game.point_lights {
        point_light_render(&light, game.sp_light)
    }
    
    // Render font
    gl.Disable(gl.DEPTH_TEST)
    gl.UseProgram(game.sp_font)
    color_r := f32(math.sin_f64(glfw.GetTime() * 0.2))
    color_g := f32(math.sin_f64(glfw.GetTime() * 0.3))
    color_b := f32(math.sin_f64(glfw.GetTime() * 0.4))
    shader_set_vec3(game.sp_font, "font_color", {color_r, color_g, color_b})
    scale :f32 = 0.03
    font_render_int(game, game.fps, 0.0, scale)
    font_render_string(game, "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcd", 1.0, scale)

    // Render triangle that cover the entire screen
    //gl.UseProgram(game.shader_program_screen)
    //shader_set_int(game.shader_program_screen, "shadow_map", 0)
    //gl.DrawArrays(gl.TRIANGLES, 0, 3)
 
    // Swap buffers
    glfw.SwapBuffers(game.window)
}


game_exit :: proc(game: ^Game) {
    free(game.point_lights)
    gl.DeleteProgram(game.sp_solid)
    gl.DeleteProgram(game.sp_screen)
    gl.DeleteProgram(game.sp_light)
    gl.DeleteProgram(game.sp_shadow)
    gl.DeleteProgram(game.sp_font)
    for key, &mesh in game.primitives {
        mesh_destroy(&mesh)
    }
    for key, &mesh in game.meshes {
        mesh_destroy(&mesh)
    }
    delete(game.primitives)
    delete(game.meshes)
    delete(game.materials)
    delete(game.models)
    glfw.Terminate()
}
