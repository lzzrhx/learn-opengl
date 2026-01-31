package main

import "core:math/linalg/glsl"

Camera :: struct {
    pos:   glsl.vec3,
    up:    glsl.vec3,
    front: glsl.vec3,
    speed: f32,
    yaw:   f32,
    pitch: f32,
    fov:   f32,
}