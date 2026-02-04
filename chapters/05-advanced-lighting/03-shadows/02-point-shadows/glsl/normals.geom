#version 330 core
layout (triangles) in;
layout (line_strip, max_vertices = 6) out;

// Const
const float MAGNITUDE = 0.2;

// In
in vec3 vs_normal[];

// Uniform
uniform mat4 projection_mat;

void generate_line(int index)
{
    gl_Position = projection_mat * gl_in[index].gl_Position;
    EmitVertex();
    gl_Position = projection_mat * (gl_in[index].gl_Position + vec4(vs_normal[index], 0.0) * MAGNITUDE);
    EmitVertex();
    EndPrimitive();
}

void main()
{
    generate_line(0);
    generate_line(1);
    generate_line(2);
}
