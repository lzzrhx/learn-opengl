#version 330 core

// Uniforms
uniform mat3 normalMat;
uniform mat4 modelMat;
uniform mat4 viewMat;
uniform mat4 projectionMat;

// Ins
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;

// Outs
out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoords;

void main()
{
    gl_Position = projectionMat * viewMat * modelMat * vec4(aPos, 1.0);
    FragPos = vec3(modelMat * vec4(aPos, 1.0));
    Normal = normalMat * aNormal;
    TexCoords = aTexCoords;
}