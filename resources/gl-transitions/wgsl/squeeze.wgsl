// Ported from squeeze.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: e48ac3f52c807c1af39d1e8cbf359ac76ff833a8796e88806461a888582739ab
// Original authors: gre
// License: MIT; full original notices in ../originals/squeeze.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  colorSeparation: f32,
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
var<private> g_colorSeparation: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_y: f32 = (0.5 + ((g_uv.y - 0.5) / (1.0 - g_progress)));
if (((g_y < 0.0) || (g_y > 1.0))) {
return getToColor(g_uv);
} else {
var g_fp: vec2<f32> = vec2<f32>(g_uv.x, g_y);
var g_off: vec2<f32> = (vec2<f32>(g_progress) * vec2<f32>(0.0, g_colorSeparation));
var g_c: vec4<f32> = getFromColor(g_fp);
var g_cn: vec4<f32> = getFromColor((g_fp - g_off));
var g_cp: vec4<f32> = getFromColor((g_fp + g_off));
return vec4<f32>(g_cn.r, g_c.g, g_cp.b, g_c.a);
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_colorSeparation = params.colorSeparation;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
