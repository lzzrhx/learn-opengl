#version 330 core

vec2 coords[3] = vec2[3](
    vec2(-1.0, -1.0),
    vec2( 3.0, -1.0),
    vec2(-1.0,  3.0)
);

out vec3 vs_pos;

void main() {
    gl_Position = vec4(coords[gl_VertexID], 0.0, 1.0);
    vs_pos = vec3(coords[gl_VertexID], 0.0);
}
