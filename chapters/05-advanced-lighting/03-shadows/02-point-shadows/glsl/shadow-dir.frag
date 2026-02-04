#version 330 core

#define BIAS 0.05

void main() {
    gl_FragDepth = gl_FrontFacing ? gl_FragCoord.z + BIAS : gl_FragCoord.z;
}
