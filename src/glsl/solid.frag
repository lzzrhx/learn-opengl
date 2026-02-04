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
in vec4 vs_shadow_pos;

// Uniform
uniform sampler2D shadow_map;
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
    //vec3 diff_color = texture(material.diffuse, vs_tex_coords).rgb;
    //vec3 spec_color = texture(material.specular, vs_tex_coords).rgb;
    vec3 diff_color = material.color;
    vec3 spec_color = vec3(1.0);
    vec3 spec_light = vec3(0.0);

    // Ambient light
    vec3 diff_light = ambient_light;

    { // Directional light
        vec3 light_dir = normalize(-dir_light.dir);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        diff_light += dir_light.diffuse * max(dot(normal, light_dir), 0.0);
        spec_light += dir_light.specular * pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
    }

    // Point light(s)
    for (int i = 0; i < NUM_POINT_LIGHTS; i++) {
        PointLight light = point_lights[i];
        vec3 light_dir = normalize(light.pos - vs_pos);
        vec3 reflect_dir = normalize(light_dir + view_dir);
        float distance = length(light.pos - vs_pos);
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        diff_light += attenuation * (light.diffuse * max(dot(normal, light_dir), 0.0));
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

    // Shadow
    vec3 shadow_coords = (vs_shadow_pos.xyz / vs_shadow_pos.w) * 0.5 + 0.5;
    float shadow_bias = max(0.05 * (1.0 - dot(normal, normalize(-dir_light.dir))), 0.005);
    float shadow = shadow_coords.z - shadow_bias > texture(shadow_map, shadow_coords.xy).r && shadow_coords.z <= 1.0 ? max(0.0, 1.0 - pow((diff_light.x + diff_light.y, + diff_light.z) * 0.9, 2)) : 0.0;

    // Output final color
    out_frag_color = vec4((diff_light * diff_color + spec_light * spec_color) * (1.0 - shadow), 1.0);
}
