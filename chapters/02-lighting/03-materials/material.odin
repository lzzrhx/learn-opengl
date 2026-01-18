package main

import "core:math/linalg/glsl"

Material :: struct {
    ambient: glsl.vec3,
    diffuse: glsl.vec3,
    specular: glsl.vec3,
    shininess: f32,
}

material_new :: proc(materials: ^[dynamic]Material, ambient: glsl.vec3, diffuse: glsl.vec3, specular: glsl.vec3, shininess: f32) {
    append(materials, Material{ ambient = ambient, diffuse = diffuse, specular = specular, shininess = shininess })
}