// Ported from colorphase.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 464c552944723e9d62bcd0bdcaeca67523e4b7c85a3a5591bc062e0056a5fd34
// Original authors: gre
// License: MIT; full original notices in ../originals/colorphase.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  fromStep_x: f32,
  fromStep_y: f32,
  fromStep_z: f32,
  fromStep_w: f32,
  toStep_x: f32,
  toStep_y: f32,
  toStep_z: f32,
  toStep_w: f32,
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
var<private> g_fromStep: vec4<f32>;
var<private> g_toStep: vec4<f32>;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_a: vec4<f32> = getFromColor(g_uv);
var g_b: vec4<f32> = getToColor(g_uv);
return mix(g_a, g_b, smoothstep(g_fromStep, g_toStep, vec4<f32>(g_progress)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_fromStep = vec4<f32>(params.fromStep_x, params.fromStep_y, params.fromStep_z, params.fromStep_w);
g_toStep = vec4<f32>(params.toStep_x, params.toStep_y, params.toStep_z, params.toStep_w);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
