// Ported from TVStatic.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 2390cfce750fdf52efa2361fbefa20d15883e9c702f6b49ee4472b3fe4c9f3bf
// Original authors: Brandon Anzaldi
// License: MIT; full original notices in ../originals/TVStatic.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  offset: f32,
  _pad0: f32,
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
var<private> g_offset: f32;
fn g_noise(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

var g_a: f32 = 12.9898;
var g_b: f32 = 78.233;
var g_c: f32 = 43758.5453;
var g_dt: f32 = dot((g_co.xy * vec2<f32>(g_progress)), vec2<f32>(g_a, g_b));
var g_sn: f32 = (g_dt - 3.14 * floor(g_dt / 3.14));
return fract((sin(g_sn) * g_c));
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

if ((g_progress < g_offset)) {
return getFromColor(g_p);
} else {
if ((g_progress > (1.0 - g_offset))) {
return getToColor(g_p);
} else {
return vec4<f32>(vec3<f32>(g_noise(g_p)), 1.0);
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_offset = params.offset;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
