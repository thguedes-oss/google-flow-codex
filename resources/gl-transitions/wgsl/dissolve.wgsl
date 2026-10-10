// Ported from dissolve.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: b58aabb0e4cb4ae7ff4b166c9b4e5f807bdaf0020d29c87fe1eaafb9b8e5d0f5
// Original authors: hjm1fb
// License: MIT; full original notices in ../originals/dissolve.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  uLineWidth: f32,
  uSpreadClr_x: f32,
  uSpreadClr_y: f32,
  uSpreadClr_z: f32,
  uHotClr_x: f32,
  uHotClr_y: f32,
  uHotClr_z: f32,
  uPow: f32,
  uIntensity: f32,
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
var<private> g_uLineWidth: f32;
var<private> g_uSpreadClr: vec3<f32>;
var<private> g_uHotClr: vec3<f32>;
var<private> g_uPow: f32;
var<private> g_uIntensity: f32;
fn g_hash(a_p: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;

g_p = vec2<f32>(dot(g_p, vec2<f32>(127.1, 311.7)), dot(g_p, vec2<f32>(269.5, 183.3)));
return (vec2<f32>((-1.0)) + (vec2<f32>(2.0) * fract((sin(g_p) * vec2<f32>(43758.5453123)))));
}
fn g_noise(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

var g_K1: f32 = 0.366025404;
var g_K2: f32 = 0.211324865;
var g_i: vec2<f32> = floor((g_p + vec2<f32>(((g_p.x + g_p.y) * g_K1))));
var g_a: vec2<f32> = ((g_p - g_i) + vec2<f32>(((g_i.x + g_i.y) * g_K2)));
var g_m: f32 = step(g_a.y, g_a.x);
var g_o: vec2<f32> = vec2<f32>(g_m, (1.0 - g_m));
var g_b: vec2<f32> = ((g_a - g_o) + vec2<f32>(g_K2));
var g_c: vec2<f32> = ((g_a - vec2<f32>(1.0)) + vec2<f32>((2.0 * g_K2)));
var g_h: vec3<f32> = max((vec3<f32>(0.5) - vec3<f32>(dot(g_a, g_a), dot(g_b, g_b), dot(g_c, g_c))), vec3<f32>(0.0));
var g_n: vec3<f32> = ((((g_h * g_h) * g_h) * g_h) * vec3<f32>(dot(g_a, g_hash((g_i + vec2<f32>(0.0)))), dot(g_b, g_hash((g_i + g_o))), dot(g_c, g_hash((g_i + vec2<f32>(1.0))))));
return dot(g_n, vec3<f32>(70.0));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_from: vec4<f32> = getFromColor(g_uv);
var g_to: vec4<f32> = getToColor(g_uv);
var g_outColor: vec4<f32>;
var g_burn: f32;
g_burn = (0.5 + (0.5 * (((0.299 * g_from.r) + (0.587 * g_from.g)) + (0.114 * g_from.b))));
var g_show: f32 = (g_burn - g_progress);
if ((g_show < 0.001)) {
g_outColor = g_to;
} else {
var g_factor: f32 = (1.0 - smoothstep(0.0, g_uLineWidth, g_show));
var g_burnColor: vec3<f32> = mix(g_uSpreadClr, g_uHotClr, vec3<f32>(g_factor));
g_burnColor = (pow(g_burnColor, vec3<f32>(g_uPow)) * vec3<f32>(g_uIntensity));
var g_finalRGB: vec3<f32> = mix(g_from.rgb, g_burnColor, vec3<f32>((g_factor * step(0.0001, g_progress))));
g_outColor = vec4<f32>((g_finalRGB * vec3<f32>(g_from.a)), g_from.a);
}
return g_outColor;
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_uLineWidth = params.uLineWidth;
g_uSpreadClr = vec3<f32>(params.uSpreadClr_x, params.uSpreadClr_y, params.uSpreadClr_z);
g_uHotClr = vec3<f32>(params.uHotClr_x, params.uHotClr_y, params.uHotClr_z);
g_uPow = params.uPow;
g_uIntensity = params.uIntensity;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
