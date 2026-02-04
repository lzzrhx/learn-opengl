#version 330 core

//Uniform
uniform vec3 diffuse;
uniform vec3 specular;

// Out
out vec4 out_frag_color;

void main()
{
    out_frag_color = vec4(diffuse, 1.0);
}
