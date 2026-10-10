// Ported from WaterDrop.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 35c80cdb1b528c3da5e5a993c4133dd0fef4d8c288909fb0d8daca4e4c74ef2b
// Original authors: Paweł Płóciennik
// License: MIT; full original notices in ../originals/WaterDrop.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  amplitude: f32,
  speed: f32,
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
var<private> g_amplitude: f32;
var<private> g_speed: f32;
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_dir: vec2<f32> = (g_p - vec2<f32>(0.5));
var g_dist: f32 = length(g_dir);
if ((g_dist > g_progress)) {
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_progress));
} else {
var g_offset: vec2<f32> = (g_dir * vec2<f32>(sin(((g_dist * g_amplitude) - (g_progress * g_speed)))));
return mix(getFromColor((g_p + g_offset)), getToColor(g_p), vec4<f32>(g_progress));
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_amplitude = params.amplitude;
g_speed = params.speed;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
