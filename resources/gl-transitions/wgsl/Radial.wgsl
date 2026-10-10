// Ported from Radial.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 2cbfc2e12b26f59b6312cdc152df46c3648d3bdbcee5ea50bc0ef08aac1d932d
// Original authors: Xaychru
// License: MIT; full original notices in ../originals/Radial.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  smoothness: f32,
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
var<private> g_smoothness: f32;
var<private> g_PI: f32;
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_rp: vec2<f32> = ((g_p * vec2<f32>(2.0)) - vec2<f32>(1.0));
return mix(getToColor(g_p), getFromColor(g_p), vec4<f32>(smoothstep(0.0, g_smoothness, (atan2(g_rp.y, g_rp.x) - (((g_progress - 0.5) * g_PI) * 2.5)))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_smoothness = params.smoothness;
g_PI = 3.141592653589;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
