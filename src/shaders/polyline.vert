#version 450

layout(location = 0) in vec3 I_Point0;
layout(location = 1) in vec3 I_Point1;

layout(location = 0) out vec4 Vertex_Color;

layout(set = 0, binding = 0) uniform View {
    mat4 ViewProj;
    mat4 inverse_view;
    mat4 projection;
    vec3 world_position;
    float near;
    float far;
    float width;
    float height;
};

layout(set = 1, binding = 0) uniform Polyline {
    mat4 Model;
};

layout(set = 2, binding = 0) uniform PolylineMaterial {
    vec4 color;
    float line_width;
};

void main() {
    vec3 positions[6];
    positions[0] = vec3(0.0, -0.5, 0.0);
    positions[1] = vec3(0.0, -0.5, 1.0);
    positions[2] = vec3(0.0, 0.5, 1.0);
    positions[3] = vec3(0.0, -0.5, 0.0);
    positions[4] = vec3(0.0, 0.5, 1.0);
    positions[5] = vec3(0.0, 0.5, 0.0);

    vec3 position = positions[gl_VertexIndex];

    // algorithm based on https://wwwtyro.net/2019/11/18/instanced-lines.html
    vec4 clip0 = ViewProj * Model * vec4(I_Point0, 1);
    vec4 clip1 = ViewProj * Model * vec4(I_Point1, 1);
    
    vec4 clip = mix(clip0, clip1, position.z);

    vec2 resolution = vec2(width, height);
    vec2 screen0 = resolution * (0.5 * clip0.xy / clip0.w + 0.5);
    vec2 screen1 = resolution * (0.5 * clip1.xy / clip1.w + 0.5);

    vec2 xBasis = normalize(screen1 - screen0);
    vec2 yBasis = vec2(-xBasis.y, xBasis.x);

    #ifdef POLYLINE_PERSPECTIVE
        vec4 color = color;
        float line_width = line_width / clip.w;
        // Line thinness fade from https://acegikmo.com/shapes/docs/#anti-aliasing
        if (line_width < 1.0) {
            color.a *= line_width;
            line_width = 1.0;
        }
    #endif

    vec2 pt0 = screen0 + line_width * (position.x * xBasis + position.y * yBasis);
    vec2 pt1 = screen1 + line_width * (position.x * xBasis + position.y * yBasis);
    vec2 pt = mix(pt0, pt1, position.z);

    float depth = clip.z + line_width * 0.0001;

    gl_Position = vec4(clip.w * ((2.0 * pt) / resolution - 1.0), depth, clip.w);
    Vertex_Color = color;
}
