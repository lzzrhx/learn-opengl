package main
import "core:log"
import "core:mem"
import "vendor:glfw"


WINDOW_WIDTH             :: 1920
WINDOW_HEIGHT            :: 1080
WINDOW_TITLE             :: "gl"
GL_VERSION_MAJOR         :: 4
GL_VERSION_MINOR         :: 3
SHADER_FONT_VERT         :: "./src/glsl/font.vert"
SHADER_FONT_FRAG         :: "./src/glsl/font.frag"
OPTION_VSYNC             :: false
OPTION_ANTI_ALIAS        :: false
OPTION_GAMMA_CORRECTION  :: false
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
    game := &Game{}
    game_init(game)

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
