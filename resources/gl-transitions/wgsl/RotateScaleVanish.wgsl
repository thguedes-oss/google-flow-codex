// Ported from RotateScaleVanish.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: c9db1f08501f5479bf8f74e6d5dd7607b55ef53b4e1c946c52e3ce0788ccbb01
// Original authors: Mark Craig
// License: MIT; full original notices in ../originals/RotateScaleVanish.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  FadeInSecond: f32,
  ReverseEffect: f32,
  ReverseRotation: f32,
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
var<private> g_FadeInSecond: bool;
var<private> g_ReverseEffect: bool;
var<private> g_ReverseRotation: bool;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_iResolution: vec2<f32> = vec2<f32>(g_ratio, 1.0);
var g_t: f32 = select(g_progress, (1.0 - g_progress), g_ReverseEffect);
var g_theta: f32 = select(((-6.283185307179586476925286766559) * g_t), (6.283185307179586476925286766559 * g_t), g_ReverseRotation);
var g_c1: f32 = cos(g_theta);
var g_s1: f32 = sin(g_theta);
var g_rad: f32 = max(0.00001, (1.0 - g_t));
var g_xc1: f32 = ((g_uv.x - 0.5) * g_iResolution.x);
var g_yc1: f32 = ((g_uv.y - 0.5) * g_iResolution.y);
var g_xc2: f32 = (((g_xc1 * g_c1) - (g_yc1 * g_s1)) / g_rad);
var g_yc2: f32 = (((g_xc1 * g_s1) + (g_yc1 * g_c1)) / g_rad);
var g_uv2: vec2<f32> = vec2<f32>((g_xc2 + (g_iResolution.x / 2.0)), (g_yc2 + (g_iResolution.y / 2.0)));
var g_col3: vec4<f32>;
var g_ColorTo: vec4<f32> = select(getToColor(g_uv), getFromColor(g_uv), g_ReverseEffect);
if (((((g_uv2.x >= 0.0) && (g_uv2.x <= g_iResolution.x)) && (g_uv2.y >= 0.0)) && (g_uv2.y <= g_iResolution.y))) {
g_uv2 /= g_iResolution;
g_col3 = select(getFromColor(g_uv2), getToColor(g_uv2), g_ReverseEffect);
} else {
g_col3 = select(g_ColorTo, vec4<f32>(0.0, 0.0, 0.0, 1.0), g_FadeInSecond);
}
return ((vec4<f32>((1.0 - g_t)) * g_col3) + (vec4<f32>(g_t) * g_ColorTo));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_FadeInSecond = (params.FadeInSecond != f32(0));
g_ReverseEffect = (params.ReverseEffect != f32(0));
g_ReverseRotation = (params.ReverseRotation != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
