// Ported from HSVfade.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 8640a0b40c67eb6999b8e619a514316e5d037440dfae9889e971f49e4833289d
// Original authors: nwoeanhinnogaehr
// License: MIT; full original notices in ../originals/HSVfade.glsl and ../LICENSE
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
fn g_hsv2rgb(a_c: vec3<f32>) -> vec3<f32> {
var g_c: vec3<f32> = a_c;

var g_K: vec4<f32> = vec4<f32>(1.0, (2.0 / 3.0), (1.0 / 3.0), 3.0);
var g_p: vec3<f32> = abs(((fract((g_c.xxx + g_K.xyz)) * vec3<f32>(6.0)) - g_K.www));
return (vec3<f32>(g_c.z) * mix(g_K.xxx, clamp((g_p - g_K.xxx), vec3<f32>(0.0), vec3<f32>(1.0)), vec3<f32>(g_c.y)));
}
fn g_rgb2hsv(a_c: vec3<f32>) -> vec3<f32> {
var g_c: vec3<f32> = a_c;

var g_K: vec4<f32> = vec4<f32>(0.0, ((-1.0) / 3.0), (2.0 / 3.0), (-1.0));
var g_p: vec4<f32> = mix(vec4<f32>(g_c.bg, g_K.wz), vec4<f32>(g_c.gb, g_K.xy), vec4<f32>(step(g_c.b, g_c.g)));
var g_q: vec4<f32> = mix(vec4<f32>(g_p.xyw, g_c.r), vec4<f32>(g_c.r, g_p.yzx), vec4<f32>(step(g_p.x, g_c.r)));
var g_d: f32 = (g_q.x - min(g_q.w, g_q.y));
return vec3<f32>(abs((g_q.z + ((g_q.w - g_q.y) / ((6.0 * g_d) + 0.001)))), (g_d / (g_q.x + 0.001)), g_q.x);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_a: vec3<f32> = g_rgb2hsv(getFromColor(g_uv).rgb);
var g_b: vec3<f32> = g_rgb2hsv(getToColor(g_uv).rgb);
var g_m: vec3<f32> = mix(g_a, g_b, vec3<f32>(g_progress));
return vec4<f32>(g_hsv2rgb(g_m), 1.0);
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
