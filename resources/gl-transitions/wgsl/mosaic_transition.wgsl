// Ported from mosaic_transition.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: a926322d7545361e1ede5143fdc5f66e77c0742b69e02acd1d627e11b98eb5b7
// Original authors: YueDev
// License: MIT; full original notices in ../originals/mosaic_transition.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  mosaicNum: f32,
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
var<private> g_mosaicNum: f32;
fn g_getMosaicUV(a_uv: vec2<f32>) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;

var g_mosaicWidth: f32 = ((2.0 / g_mosaicNum) * min(g_progress, (1.0 - g_progress)));
var g_mX: f32 = (floor((g_uv.x / g_mosaicWidth)) + 0.5);
var g_mY: f32 = (floor((g_uv.y / g_mosaicWidth)) + 0.5);
return vec2<f32>((g_mX * g_mosaicWidth), (g_mY * g_mosaicWidth));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_mosaicUV: vec2<f32> = select(g_getMosaicUV(g_uv), g_uv, (min(g_progress, (1.0 - g_progress)) == 0.0));
return mix(getFromColor(g_mosaicUV), getToColor(g_mosaicUV), vec4<f32>((g_progress * g_progress)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_mosaicNum = params.mosaicNum;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
