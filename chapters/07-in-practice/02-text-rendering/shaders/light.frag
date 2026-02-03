#version 330 core

//Uniforms
uniform vec3 diffuse;
uniform vec3 specular;

// Outs
out vec4 FragColor;

void main()
{
    FragColor = vec4(diffuse, 1.0);
}
