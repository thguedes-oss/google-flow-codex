// Ported from burn0.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: d572b6d93c74292c14c1feb3cf55eccfc03ffb98a6bfa3b0900162295f6aa0e9
// Original authors: liubailin2020@gmail.com
// License: MIT; full original notices in ../originals/burn0.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  burnColor_x: f32,
  burnColor_y: f32,
  burnColor_z: f32,
  _pad0: f32,
  _pad1: f32,
  _pad2: f32,
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
var<private> g_burnColor: vec3<f32>;
fn g_random(a_st: vec2<f32>) -> f32 {
var g_st: vec2<f32> = a_st;

return fract((sin(dot(g_st.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453123));
}
fn g_noise(a_st: vec2<f32>) -> f32 {
var g_st: vec2<f32> = a_st;

var g_i: vec2<f32> = floor(g_st);
var g_f: vec2<f32> = fract(g_st);
var g_a: f32 = g_random(g_i);
var g_b: f32 = g_random((g_i + vec2<f32>(1.0, 0.0)));
var g_c: f32 = g_random((g_i + vec2<f32>(0.0, 1.0)));
var g_d: f32 = g_random((g_i + vec2<f32>(1.0, 1.0)));
var g_u: vec2<f32> = ((g_f * g_f) * (vec2<f32>(3.0) - (vec2<f32>(2.0) * g_f)));
return ((mix(g_a, g_b, g_u.x) + (((g_c - g_a) * g_u.y) * (1.0 - g_u.x))) + (((g_d - g_b) * g_u.x) * g_u.y));
}
fn g_fbm(a_st: vec2<f32>) -> f32 {
var g_st: vec2<f32> = a_st;

var g_value: f32 = 0.0;
var g_amplitude: f32 = 0.5;
for (var g_i: i32 = 0; (g_i < 4); g_i++) {
g_value += (g_amplitude * g_noise(g_st));
g_st *= vec2<f32>(2.0);
g_amplitude *= 0.5;
}
return g_value;
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_from: vec4<f32> = getFromColor(g_uv);
var g_to: vec4<f32> = getToColor(g_uv);
var g_n: f32 = g_fbm((g_uv * vec2<f32>(4.0)));
var g_l: f32 = smoothstep(g_progress, (g_progress + 0.05), g_n);
var g_edge: f32 = (((1.0 - g_l) * g_l) * 5.0);
return (mix(g_to, g_from, vec4<f32>(g_l)) + (vec4<f32>(g_burnColor, 0.0) * vec4<f32>(g_edge)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_burnColor = vec3<f32>(params.burnColor_x, params.burnColor_y, params.burnColor_z);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
