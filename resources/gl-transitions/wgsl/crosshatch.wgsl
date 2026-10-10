// Ported from crosshatch.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 8066e3d78c79a6be454bae058ff69d3fef87596d562826bddc638a461e1d032c
// Original authors: pthrasher
// License: MIT; full original notices in ../originals/crosshatch.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  center_x: f32,
  center_y: f32,
  threshold: f32,
  fadeEdge: f32,
  _pad0: f32,
  _pad1: f32,
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
var<private> g_center: vec2<f32>;
var<private> g_threshold: f32;
var<private> g_fadeEdge: f32;
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_dist: f32 = (distance(g_center, g_p) / g_threshold);
var g_r: f32 = (g_progress - min(g_rand(vec2<f32>(g_p.y, 0.0)), g_rand(vec2<f32>(0.0, g_p.x))));
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(mix(0.0, mix(step(g_dist, g_r), 1.0, smoothstep((1.0 - g_fadeEdge), 1.0, g_progress)), smoothstep(0.0, g_fadeEdge, g_progress))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_center = vec2<f32>(params.center_x, params.center_y);
g_threshold = params.threshold;
g_fadeEdge = params.fadeEdge;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
