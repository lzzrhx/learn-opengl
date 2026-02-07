package main
import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH             :: 1920
WINDOW_HEIGHT            :: 1080
WINDOW_TITLE             :: "gl"
GL_VERSION_MAJOR         :: 4
GL_VERSION_MINOR         :: 3
SHADER_SOLID_VERT        :: "./src/glsl/solid.vert"
SHADER_SOLID_FRAG        :: "./src/glsl/solid.frag"
SHADER_LIGHT_VERT        :: "./src/glsl/light.vert"
SHADER_LIGHT_FRAG        :: "./src/glsl/light.frag"
SHADER_NORMALS_GEOM      :: "./src/glsl/normals.geom"
SHADER_SHADOW_DIR_VERT   :: "./src/glsl/shadow-dir.vert"
//SHADER_SHADOW_POINT_VERT :: "./src/glsl/shadow-point.vert"
//SHADER_SHADOW_POINT_GEOM :: "./src/glsl/shadow-point.geom"
//SHADER_SHADOW_POINT_FRAG :: "./src/glsl/shadow-point.frag"
SHADER_EMPTY_FRAG        :: "./src/glsl/empty.frag"
SHADER_SCREEN_VERT       :: "./src/glsl/screen.vert"
SHADER_SCREEN_FRAG       :: "./src/glsl/screen.frag"
SHADER_FONT_VERT         :: "./src/glsl/font.vert"
SHADER_FONT_FRAG         :: "./src/glsl/font.frag"
//TEXTURE_DIFFUSE          :: "./assets/container2.png"
//TEXTURE_SPECULAR         :: "./assets/container2-specular.png"
NUM_POINT_LIGHTS         :: 1
SHADOWMAP_SIZE           :: 4096
CLIP_NEAR                :: 0.1
CLIP_FAR                 :: 100
//POINT_SHADOW_CLIP_NEAR   :: 0.01
//POINT_SHADOW_CLIP_FAR    :: 10
DIR_SHADOW_CLIP_FAR      :: 20
OPTION_VSYNC             :: false
OPTION_ANTI_ALIAS        :: true
OPTION_GAMMA_CORRECTION  :: true
FONT_PATH                 :: "./assets/font.png"
FONT_WIDTH                :: 8
FONT_HEIGHT               :: 16
FONT_MAX_CHARS            :: 12000
FONT_SPACING              :: 2


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
