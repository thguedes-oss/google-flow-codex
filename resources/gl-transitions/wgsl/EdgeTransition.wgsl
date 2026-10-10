// Ported from EdgeTransition.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 2849ced1825813d4895168f0e314c5812ebf122297c7d600fcd14065f0b85080
// Original authors: Woohyun Kim
// License: MIT; full original notices in ../originals/EdgeTransition.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  edge_thickness: f32,
  edge_brightness: f32,
};

struct VertexInput {
 @location(0) position: vec2<f32>,
 @location(1) tex_coords: vec2<f32>,
 @location(2) color: vec4<f32>,
};
struct VertexOutput {
 @builtin(position) clip_position: vec4<f32>,
 @location(0) tex_coords: vec2<f32>,
};
@vertex fn vs_main(input: VertexInput) -> VertexOutput {
 var out: VertexOutput;
 out.clip_position=vec4<f32>(input.position,0.0,1.0);
 out.tex_coords=input.tex_coords;
 return out;
}
@group(0) @binding(0) var t_from: texture_2d<f32>;
@group(0) @binding(1) var t_to: texture_2d<f32>;
@group(0) @binding(2) var s_sampler: sampler;
@group(0) @binding(3) var<uniform> params: Params;
// GL coordinates are bottom-up. Both boundary conversions preserve native orientation.
fn getFromColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_from,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}
fn getToColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_to,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}

var<private> g_progress: f32;
var<private> g_ratio: f32;
var<private> g_edge_thickness: f32;
var<private> g_edge_brightness: f32;
fn g_detectEdgeColor(a_c: array<vec3<f32>, 9>) -> vec4<f32> {
var g_c: array<vec3<f32>, 9> = a_c;

var g_dx: vec3<f32> = (((vec3<f32>(2.0) * abs((g_c[7] - g_c[1]))) + abs((g_c[2] - g_c[6]))) + abs((g_c[8] - g_c[0])));
var g_dy: vec3<f32> = (((vec3<f32>(2.0) * abs((g_c[3] - g_c[5]))) + abs((g_c[6] - g_c[8]))) + abs((g_c[0] - g_c[2])));
var g_delta: f32 = length(((vec3<f32>(0.25) * (g_dx + g_dy)) * vec3<f32>(0.5)));
return vec4<f32>((vec3<f32>(clamp((g_edge_brightness * g_delta), 0.0, 1.0)) * g_c[4]), 1.0);
}
fn g_getFromEdgeColor(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_c: array<vec3<f32>, 9>;
for (var g_i: i32 = 0; (g_i < 3); g_i += 1) {
for (var g_j: i32 = 0; (g_j < 3); g_j += 1) {
var g_color: vec4<f32> = getFromColor((g_uv + (vec2<f32>(g_edge_thickness) * vec2<f32>(f32((g_i - 1)), f32((g_j - 1))))));
g_c[((3 * g_i) + g_j)] = g_color.rgb;
}
}
return g_detectEdgeColor(g_c);
}
fn g_getToEdgeColor(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_c: array<vec3<f32>, 9>;
for (var g_i: i32 = 0; (g_i < 3); g_i += 1) {
for (var g_j: i32 = 0; (g_j < 3); g_j += 1) {
var g_color: vec4<f32> = getToColor((g_uv + (vec2<f32>(g_edge_thickness) * vec2<f32>(f32((g_i - 1)), f32((g_j - 1))))));
g_c[((3 * g_i) + g_j)] = g_color.rgb;
}
}
return g_detectEdgeColor(g_c);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_start: vec4<f32> = mix(getFromColor(g_uv), g_getFromEdgeColor(g_uv), vec4<f32>(clamp((2.0 * g_progress), 0.0, 1.0)));
var g_end: vec4<f32> = mix(g_getToEdgeColor(g_uv), getToColor(g_uv), vec4<f32>(clamp((2.0 * (g_progress - 0.5)), 0.0, 1.0)));
return mix(g_start, g_end, vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_edge_thickness = params.edge_thickness;
g_edge_brightness = params.edge_brightness;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
