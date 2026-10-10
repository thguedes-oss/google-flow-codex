// Ported from windowslice.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 128052b76eaa2802487cbc8940178daa54c2e91bfd0e157de69f2d6295e51449
// Original authors: gre
// License: MIT; full original notices in ../originals/windowslice.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  count: f32,
  smoothness: f32,
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
var<private> g_count: f32;
var<private> g_smoothness: f32;
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_pr: f32 = smoothstep((-g_smoothness), 0.0, (g_p.x - (g_progress * (1.0 + g_smoothness))));
var g_s: f32 = step(g_pr, fract((g_count * g_p.x)));
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_s));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_count = params.count;
g_smoothness = params.smoothness;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
