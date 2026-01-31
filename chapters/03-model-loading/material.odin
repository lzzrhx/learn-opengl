package main

import "core:math/linalg/glsl"

Material :: struct {
    shininess: f32,
    color: glsl.vec3,
}

material_new :: proc(materials: ^[dynamic]Material, color: glsl.vec3, shininess: f32) {
    append(materials, Material{ color = color, shininess = shininess })
}
