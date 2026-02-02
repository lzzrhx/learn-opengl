package main

import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH          :: 1920
WINDOW_HEIGHT         :: 1080
WINDOW_TITLE          :: "gl"
GL_VERSION_MAJOR      :: 3
GL_VERSION_MINOR      :: 3
VS_DEFAULT            :: "./src/shaders/default.vert"
FS_DEFAULT            :: "./src/shaders/default.frag"
VS_LIGHT              :: "./src/shaders/light.vert"
FS_LIGHT              :: "./src/shaders/light.frag"
VS_SHADOW             :: "./src/shaders/shadow.vert"
FS_EMPTY              :: "./src/shaders/empty.frag"
VS_SCREEN             :: "./src/shaders/screen.vert"
FS_SCREEN             :: "./src/shaders/screen.frag"
DIFFUSE_TEXTURE       :: "./assets/container2.png"
SPECULAR_TEXTURE      :: "./assets/container2-specular.png"
//NUM_POINT_LIGHTS      :: 4
SHADOWMAP_SIZE        :: 2048
CLIP_NEAR             :: 0.1
CLIP_FAR              :: 100


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
        //point_lights  = new([NUM_POINT_LIGHTS]PointLight),
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

    // Time measurement variables
    time_current: f64
    time_prev: f64
    dt: f64

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {
        time_current = glfw.GetTime()
        dt = time_current - time_prev
        time_prev = time_current
        game_input(game, dt)
        game_update(game, dt)
        game_render(game)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }
   
    // Exit the program
    game_exit(game)
}
