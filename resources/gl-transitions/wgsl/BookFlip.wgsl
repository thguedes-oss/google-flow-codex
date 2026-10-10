// Ported from BookFlip.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 9ad879d44c84b47f5c077030d3a6301fb2542ecc4835a5b4300a95be4e71bc74
// Original authors: hong
// License: MIT; full original notices in ../originals/BookFlip.glsl and ../LICENSE
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
fn g_nonZero(a_x: f32) -> f32 {
var g_x: f32 = a_x;

return select(g_x, select(1e-4, (-1e-4), (g_x < 0.0)), (abs(g_x) < 1e-4));
}
fn g_skewRight(a_p: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;

var g_skewX: f32 = (((g_p.x - g_progress) / g_nonZero((0.5 - g_progress))) * 0.5);
var g_skewY: f32 = ((((g_p.y - 0.5) / (0.5 + ((g_progress * (g_p.x - 0.5)) / 0.5))) * 0.5) + 0.5);
return vec2<f32>(g_skewX, g_skewY);
}
fn g_skewLeft(a_p: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;

var g_skewX: f32 = ((((g_p.x - 0.5) / g_nonZero((g_progress - 0.5))) * 0.5) + 0.5);
var g_skewY: f32 = ((((g_p.y - 0.5) / (0.5 + (((1.0 - g_progress) * (0.5 - g_p.x)) / 0.5))) * 0.5) + 0.5);
return vec2<f32>(g_skewX, g_skewY);
}
fn g_addShade() -> vec4<f32> {

var g_shadeVal: f32 = max(0.7, (abs((g_progress - 0.5)) * 2.0));
return vec4<f32>(vec3<f32>(g_shadeVal), 1.0);
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_pr: f32 = step((1.0 - g_progress), g_p.x);
if ((g_p.x < 0.5)) {
return mix(getFromColor(g_p), (getToColor(g_skewLeft(g_p)) * g_addShade()), vec4<f32>(g_pr));
} else {
return mix((getFromColor(g_skewRight(g_p)) * g_addShade()), getToColor(g_p), vec4<f32>(g_pr));
}
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
