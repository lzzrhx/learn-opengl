#version 330 core
layout (triangles) in;
layout (triangle_strip, max_vertices=18) out;

// Uniform
uniform mat4 shadow_mats[6];

// Out
out vec4 gs_pos;

void main()
{
    for(int face = 0; face < 6; ++face)
    {
        gl_Layer = face;
        for(int i = 0; i < 3; ++i)
        {
            gs_pos = gl_in[i].gl_Position;
            gl_Position = shadow_mats[face] * gs_pos;
            EmitVertex();
        }    
        EndPrimitive();
    }
}
