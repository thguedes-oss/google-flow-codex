// Ported from wind.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: a6af68366cd1feb21da596e6503994da8bb052c616ec73d4346006837494a01f
// Original authors: gre
// License: MIT; full original notices in ../originals/wind.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  size: f32,
  reversed: f32,
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
var<private> g_size: f32;
var<private> g_reversed: bool;
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_x: f32 = select(g_uv.x, (1.0 - g_uv.x), g_reversed);
var g_r: f32 = g_rand(vec2<f32>(f32(0), g_uv.y));
var g_m: f32 = smoothstep(0.0, (-g_size), (((g_x * (1.0 - g_size)) + (g_size * g_r)) - (g_progress * (1.0 + g_size))));
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_m));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_size = params.size;
g_reversed = (params.reversed != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
