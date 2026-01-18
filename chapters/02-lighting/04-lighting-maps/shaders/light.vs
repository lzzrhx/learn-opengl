#version 330 core

// Uniforms
uniform mat4 modelMat;
uniform mat4 viewMat;
uniform mat4 projectionMat;

// Ins
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = projectionMat * viewMat * modelMat * vec4(aPos, 1.0);
}