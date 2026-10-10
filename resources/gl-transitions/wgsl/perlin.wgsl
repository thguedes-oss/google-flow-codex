// Ported from perlin.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 14913f1110ab9fc2e0a8c08bf9cc566490e6399c1a0afb9300079dba4c0ca69a
// Original authors: Rich Harris
// License: MIT; full original notices in ../originals/perlin.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  scale: f32,
  smoothness: f32,
  seed: f32,
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
var<private> g_scale: f32;
var<private> g_smoothness: f32;
var<private> g_seed: f32;
fn g_random(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

var g_a: f32 = g_seed;
var g_b: f32 = 78.233;
var g_c: f32 = 43758.5453;
var g_dt: f32 = dot(g_co.xy, vec2<f32>(g_a, g_b));
var g_sn: f32 = (g_dt - 3.14 * floor(g_dt / 3.14));
return fract((sin(g_sn) * g_c));
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
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_from: vec4<f32> = getFromColor(g_uv);
var g_to: vec4<f32> = getToColor(g_uv);
var g_n: f32 = g_noise((g_uv * vec2<f32>(g_scale)));
var g_p: f32 = mix((-g_smoothness), (1.0 + g_smoothness), g_progress);
var g_lower: f32 = (g_p - g_smoothness);
var g_higher: f32 = (g_p + g_smoothness);
var g_q: f32 = smoothstep(g_lower, g_higher, g_n);
return mix(g_from, g_to, vec4<f32>((1.0 - g_q)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_scale = params.scale;
g_smoothness = params.smoothness;
g_seed = params.seed;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
