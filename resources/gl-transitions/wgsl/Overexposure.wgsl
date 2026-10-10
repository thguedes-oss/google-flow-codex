// Ported from Overexposure.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: fbae3411c39af59e0b0fa6536c9a9797c6be0702a7e69303c7db8bc087efe26c
// Original authors: Ben Zhang
// License: MIT; full original notices in ../originals/Overexposure.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  strength: f32,
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
var<private> g_strength: f32;
var<private> g_PI: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_from: vec4<f32> = getFromColor(g_uv);
var g_to: vec4<f32> = getToColor(g_uv);
var g_from_m: f32 = ((1.0 - g_progress) + (sin((g_PI * g_progress)) * g_strength));
var g_to_m: f32 = (g_progress + (sin((g_PI * g_progress)) * g_strength));
return vec4<f32>((((g_from.r * g_from.a) * g_from_m) + ((g_to.r * g_to.a) * g_to_m)), (((g_from.g * g_from.a) * g_from_m) + ((g_to.g * g_to.a) * g_to_m)), (((g_from.b * g_from.a) * g_from_m) + ((g_to.b * g_to.a) * g_to_m)), mix(g_from.a, g_to.a, g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_strength = params.strength;
g_PI = 3.141592653589793;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
