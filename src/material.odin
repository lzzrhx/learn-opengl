package main

import "core:math/linalg/glsl"

Material :: struct {
    shininess: f32,
    color: glsl.vec3,
}

TexturedMaterial :: struct {
    diffuse: u32,
    specular: u32,
    shininess: f32,
}

material_new :: proc(materials: ^[dynamic]Material, color: glsl.vec3, shininess: f32) {
    append(materials, Material{ color = color, shininess = shininess })
}

material_new_textured :: proc(materials: ^[dynamic]TexturedMaterial, diffuse, specular: u32, shininess: f32) {
    append(materials, TexturedMaterial{ diffuse = diffuse, specular = specular, shininess = shininess })
}

