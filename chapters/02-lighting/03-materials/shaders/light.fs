#version 330 core

//Uniforms
uniform vec3 lightColor;

// Outs
out vec4 FragColor;

void main()
{
    FragColor = vec4(lightColor, 1.0);
}