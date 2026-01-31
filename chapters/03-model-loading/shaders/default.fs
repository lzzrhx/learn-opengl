#version 330 core

struct Material {
    float     shininess;
    vec3 color;
};

struct DirLight {
    vec3 dir;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3  pos;
    vec3  diffuse;
    vec3  specular;
    float constant;
    float linear;
    float quadratic;
};

struct SpotLight {
    vec3  pos;
    vec3  dir;
    vec3  diffuse;
    vec3  specular;
    float cutoff;
    float cutoff_outer;
    float constant;
    float linear;
    float quadratic;
};

//#define NUM_POINT_LIGHTS 4

// Uniforms
uniform vec3 ambient_light;
uniform vec3 view_pos;
uniform Material material;
uniform DirLight dir_light;
//uniform SpotLight spot_light;
//uniform PointLight point_lights[NUM_POINT_LIGHTS];

// Ins
in vec3 vs_pos;
in vec3 vs_normal;
in vec2 vs_tex_coords;

// Outs
out vec4 frag_color;

vec3 calc_dir_light(DirLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color);
vec3 calc_point_light(PointLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color);
vec3 calc_spot_light(SpotLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color);

vec3 calc_dir_light(DirLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color) {
    vec3 light_dir = normalize(-light.dir);
    vec3 reflect_dir = reflect(-light_dir, normal);
    vec3 diffuse = light.diffuse * max(dot(normal, light_dir), 0.0) * diff_color;
    vec3 specular = light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess) * spec_color;
    return diffuse + specular;
}

vec3 calc_point_light(PointLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color) {
    vec3 light_dir = normalize(light.pos - vs_pos);
    vec3 reflect_dir = reflect(-light_dir, normal);
    float distance = length(light.pos - vs_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    vec3 diffuse = attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0) * diff_color);
    vec3 specular = attenuation * (light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess) * spec_color);
    return diffuse + specular;
}

vec3 calc_spot_light(SpotLight light, vec3 normal, vec3 view_dir, vec3 diff_color, vec3 spec_color) {
    vec3 color = vec3(0.0, 0.0, 0.0);
    vec3 light_dir = normalize(light.pos - vs_pos);
    float theta = dot(light_dir, normalize(-light.dir));
    if(theta > light.cutoff_outer) {
        vec3 reflect_dir = reflect(-light_dir, normal);
        float distance = length(light.pos - vs_pos);
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        float epsilon = light.cutoff - light.cutoff_outer;
        float intensity = clamp((theta - light.cutoff_outer) / epsilon, 0.0, 1.0);
        vec3 diffuse = intensity * attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0) * diff_color);
        vec3 specular = intensity * attenuation * (light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess) * spec_color);
        color = diffuse + specular;
    }
    return color;
}

void main()
{
    vec3 view_dir = normalize(view_pos - vs_pos);
    vec3 normal = normalize(vs_normal);
    //vec3 diff_color = texture(material.diffuse, vs_tex_coords).rgb;
    //vec3 spec_color = texture(material.specular, vs_tex_coords).rgb;
    vec3 diff_color = material.color;
    vec3 spec_color = material.color;
    vec3 color = (ambient_light * diff_color) + calc_dir_light(dir_light, normal, view_dir, diff_color, spec_color);// + calc_spot_light(spot_light, normal, view_dir, diff_color, spec_color);
    //for (int i = 0; i < NUM_POINT_LIGHTS; i++) { color += calc_point_light(point_lights[i], normal, view_dir, diff_color, spec_color); }
    frag_color = vec4(color, 1.0);
}
