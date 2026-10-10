// Ported from CrazyParametricFun.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 116645084d197df4a50a737bcfaa126d76f6289aff59dccce9bf28929284379d
// Original authors: mandubian
// License: MIT; full original notices in ../originals/CrazyParametricFun.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  a: f32,
  b: f32,
  amplitude: f32,
  smoothness: f32,
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
var<private> g_a: f32;
var<private> g_b: f32;
var<private> g_amplitude: f32;
var<private> g_smoothness: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_dir: vec2<f32> = (g_p - vec2<f32>(0.5));
var g_dist: f32 = length(g_dir);
var g_x: f32 = (((g_a - g_b) * cos(g_progress)) + (g_b * cos((g_progress * ((g_a / g_b) - 1.0)))));
var g_y: f32 = (((g_a - g_b) * sin(g_progress)) - (g_b * sin((g_progress * ((g_a / g_b) - 1.0)))));
var g_offset: vec2<f32> = ((g_dir * vec2<f32>(sin((((g_progress * g_dist) * g_amplitude) * g_x)), sin((((g_progress * g_dist) * g_amplitude) * g_y)))) / vec2<f32>(g_smoothness));
return mix(getFromColor((g_p + g_offset)), getToColor(g_p), vec4<f32>(smoothstep(0.2, 1.0, g_progress)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_a = params.a;
g_b = params.b;
g_amplitude = params.amplitude;
g_smoothness = params.smoothness;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
