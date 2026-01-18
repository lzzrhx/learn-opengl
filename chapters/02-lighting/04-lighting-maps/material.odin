package main

import "core:math/linalg/glsl"

Material :: struct {
    diffuse: u32,
    specular: u32,
    shininess: f32,
}

material_new :: proc(materials: ^[dynamic]Material, diffuse: u32, specular: u32, shininess: f32) {
    append(materials, Material{ diffuse = diffuse, specular = specular, shininess = shininess })
}