#version 330 core

struct Material {
//    sampler2D diffuse;
//    sampler2D specular;
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

// Const
#define NUM_POINT_LIGHTS 1

// In
in vec3 vs_pos;
in vec3 vs_normal;
in vec2 vs_tex_coords;
in vec4 vs_dir_shadow_pos;

// Uniform
uniform sampler2D shadow_map_dir;
uniform samplerCube shadow_map_point;
uniform float far_plane;
uniform vec3 ambient_light;
uniform vec3 view_pos;
uniform Material material;
uniform DirLight dir_light;
//uniform SpotLight spot_light;
uniform PointLight point_lights[NUM_POINT_LIGHTS];

// Out
out vec4 out_frag_color;

void main()
{
    vec3 normal = normalize(vs_normal);
    vec3 view_dir = normalize(view_pos - vs_pos);
    vec3 diff_color = material.color; //texture(material.diffuse, vs_tex_coords).rgb;
    vec3 spec_color = vec3(1.0); //texture(material.specular, vs_tex_coords).rgb;

    // Lights
    vec3 spec_light = vec3(0.0);
    vec3 diff_light = ambient_light;
    vec3 diff_light_dir = vec3(0.0);
    vec3 diff_light_point = vec3(0.0);
    { // Directional light
        vec3 light_dir = normalize(-dir_light.dir);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        diff_light_dir = dir_light.diffuse * max(dot(normal, light_dir), 0.0);
        spec_light += dir_light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
    }
    // Point light(s)
    for (int i = 0; i < NUM_POINT_LIGHTS; i++) {
        PointLight light = point_lights[i];
        vec3 light_dir = normalize(light.pos - vs_pos);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        float distance = length(light.pos - vs_pos);
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        diff_light_point += attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0));
        spec_light += attenuation * (light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess));
    }
    /*{ // Spot light
        SpotLight light = spot_light;
        vec3 light_dir = normalize(light.pos - vs_pos);
        float theta = dot(light_dir, normalize(-light.dir));
        if(theta > light.cutoff_outer) {
            vec3 reflect_dir = normalize(light_dir + view_dir);
            float distance = length(light.pos - vs_pos);
            float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
            float epsilon = light.cutoff - light.cutoff_outer;
            float intensity = clamp((theta - light.cutoff_outer) / epsilon, 0.0, 1.0);
            diff_light += intensity * attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0));
            spec_light += intensity * attenuation * (light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess));
        }
    }*/
    diff_light = diff_light + diff_light_dir + diff_light_point;

    // Shadows
    float shadow = 0.0;
    { // Directional shadow
        float shadow_light = diff_light_point.x + diff_light_point.y + diff_light_point.z;
        vec3 shadow_coords = (vs_dir_shadow_pos.xyz / vs_dir_shadow_pos.w) * 0.5 + 0.5;
        float current_depth = shadow_coords.z;
        float closest_depth = texture(shadow_map_dir, shadow_coords.xy).r;
        float shadow_bias = max(0.05 * (1.0 - dot(normal, normalize(-dir_light.dir))), 0.005);
        shadow += current_depth - shadow_bias > closest_depth && shadow_coords.z <= 1.0 ? 1.0 - shadow_light * 2 : 0.0;
    }
    // Point shadow(s)
    for (int i = 0; i < NUM_POINT_LIGHTS; i++) {
        float shadow_light = diff_light_dir.x + diff_light_dir.y + diff_light_dir.z;
        vec3 frag_to_light = vs_pos - point_lights[i].pos;
        float closest_depth = texture(shadow_map_point, frag_to_light).r * far_plane;
        float current_depth = length(frag_to_light);
        float shadow_bias = max(0.05 * (1.0 - dot(normal, normalize(point_lights[i].pos - vs_pos))), 0.005);
        shadow += current_depth - shadow_bias > closest_depth && current_depth < far_plane ? 1.0 - shadow_light : 0.0;
    }

    // Output final color
    out_frag_color = vec4((diff_light * diff_color + spec_light * spec_color) * (1.0 - clamp(shadow - ((ambient_light.x + ambient_light.y + ambient_light.z) / 3), 0.0, 1.0)), 1.0);
}
