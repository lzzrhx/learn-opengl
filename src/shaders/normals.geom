#version 330 core

// Const
const float MAGNITUDE = 0.2;

// In
layout (triangles) in;
in vs_normal; 

// Uniform
uniform mat4 projection_mat;

//Out
layout (line_strip, max_vertices = 6) out;

void generate_line(int index)
{
    gl_Position = projection * gl_in[index].gl_Position;
    EmitVertex();
    gl_Position = projection * (gl_in[index].gl_Position + vec4(gs_in[index].normal, 0.0) * MAGNITUDE);
    EmitVertex();
    EndPrimitive();
}

void main()
{
    generate_line(0);
    generate_line(1);
    generate_line(2);
}
