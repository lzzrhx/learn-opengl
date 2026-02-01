package main

import "core:math/linalg/glsl"

Material :: struct {
    //diffuse: u32,
    //specular: u32,
    shininess: f32,
    color: glsl.vec3,
}

material_new :: proc(materials: ^[dynamic]Material, color: glsl.vec3, shininess: f32) {
    //append(materials, Material{ diffuse = diffuse, specular = specular, shininess = shininess })
    append(materials, Material{ color = color, shininess = shininess })
}
