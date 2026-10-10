// Ported from Dreamy.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: ad95fba01344f89815da3deb1c023478800af04a25c4d56f2ff291448138ae4c
// Original authors: mikolalysenko
// License: MIT; full original notices in ../originals/Dreamy.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
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
fn g_offset(a_progress: f32, a_x: f32, a_theta: f32) -> vec2<f32> {
var g_progress: f32 = a_progress;
var g_x: f32 = a_x;
var g_theta: f32 = a_theta;

var g_phase: f32 = (((g_progress * g_progress) + g_progress) + g_theta);
var g_shifty: f32 = ((0.03 * g_progress) * cos((10.0 * (g_progress + g_x))));
return vec2<f32>(f32(0), g_shifty);
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

return mix(getFromColor((g_p + g_offset(g_progress, g_p.x, 0.0))), getToColor((g_p + g_offset((1.0 - g_progress), g_p.x, 3.14))), vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
