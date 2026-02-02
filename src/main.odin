package main

import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH            :: 1920
WINDOW_HEIGHT           :: 1080
WINDOW_TITLE            :: "gl"
GL_VERSION_MAJOR        :: 4
GL_VERSION_MINOR        :: 3
SHADER_SOLID_VERT       :: "./src/shaders/solid.vert"
SHADER_SOLID_FRAG       :: "./src/shaders/solid.frag"
SHADER_LIGHT_VERT       :: "./src/shaders/light.vert"
SHADER_LIGHT_FRAG       :: "./src/shaders/light.frag"
SHADER_SHADOW_VERT      :: "./src/shaders/shadow.vert"
SHADER_EMPTY_FRAG       :: "./src/shaders/empty.frag"
SHADER_SCREEN_VERT      :: "./src/shaders/screen.vert"
SHADER_SCREEN_FRAG      :: "./src/shaders/screen.frag"
TEXTURE_DIFFUSE         :: "./assets/container2.png"
TEXTURE_SPECULAR        :: "./assets/container2-specular.png"
NUM_POINT_LIGHTS        :: 1
SHADOWMAP_SIZE          :: 2048
CLIP_NEAR               :: 0.1
CLIP_FAR                :: 100
OPTION_VSYNC            :: true
OPTION_ANTI_ALIAS       :: true
OPTION_GAMMA_CORRECTION :: true


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
        primitives    = make(map[Primitive]Mesh),
        meshes        = make(map[string]Mesh),
        materials     = make([dynamic]Material),
        models        = make([dynamic]Model),
        dir_light     = &DirLight{},
        point_lights  = new([NUM_POINT_LIGHTS]PointLight),
        //spot_light    = &SpotLight{},
        camera        = &Camera{
            pos   = {0.0, 1.0, 0.0},
            up    = {0, 1, 0},
            front = {0, 0, -1},
            speed = 2.5,
            yaw   = -90,
            pitch = 0,
            fov   = 45.0,
        },
    }
    game_init(game)
    game_setup(game)

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {
        game_input(game)
        game_update(game)
        game_render(game)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }
   
    // Exit the program
    game_exit(game)
}
