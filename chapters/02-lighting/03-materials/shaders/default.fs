#version 330 core

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 pos;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

// Uniforms
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform Material material;
uniform Light light;

// Ins
in vec3 FragPos;
in vec3 Normal;

// Outs
out vec4 FragColor;

void main()
{
    // Calculate vectors
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    // Calculate light color values
    vec3 ambient = light.ambient * material.ambient;
    vec3 diffuse = light.diffuse * (max(dot(norm, lightDir), 0.0) * material.diffuse);
    vec3 specular = light.specular * (pow(max(dot(viewDir, reflectDir), 0.0), material.shininess) * material.specular);
    // Set final color value
    FragColor = vec4(ambient + diffuse + specular, 1.0);
}