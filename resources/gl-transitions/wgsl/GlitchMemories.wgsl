// Ported from GlitchMemories.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 27cca2daf0ca247eb371a852da3cc455f1c764ada992bc5d33061a155614308f
// Original authors: Gunnar Roth
// License: MIT; full original notices in ../originals/GlitchMemories.glsl and ../LICENSE
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
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_block: vec2<f32> = floor((g_p.xy / vec2<f32>(f32(16))));
var g_uv_noise: vec2<f32> = (g_block / vec2<f32>(f32(64)));
g_uv_noise += (floor((vec2<f32>(g_progress) * vec2<f32>(1200.0, 3500.0))) / vec2<f32>(f32(64)));
var g_dist: vec2<f32> = select(vec2<f32>(0.0), (((fract(g_uv_noise) - vec2<f32>(0.5)) * vec2<f32>(0.3)) * vec2<f32>((1.0 - g_progress))), (g_progress > 0.0));
var g_red: vec2<f32> = (g_p + (g_dist * vec2<f32>(0.2)));
var g_green: vec2<f32> = (g_p + (g_dist * vec2<f32>(0.3)));
var g_blue: vec2<f32> = (g_p + (g_dist * vec2<f32>(0.5)));
return vec4<f32>(mix(getFromColor(g_red), getToColor(g_red), vec4<f32>(g_progress)).r, mix(getFromColor(g_green), getToColor(g_green), vec4<f32>(g_progress)).g, mix(getFromColor(g_blue), getToColor(g_blue), vec4<f32>(g_progress)).b, 1.0);
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
