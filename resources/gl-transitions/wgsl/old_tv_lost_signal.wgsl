// Ported from old_tv_lost_signal.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 9fdf5df439eca16ff5e0aedc3765a37dd1b55a7b7a16a9991c3a41738a761e55
// Original authors: mernking (gitlab.com/Godswork)
// License: MIT; full original notices in ../originals/old_tv_lost_signal.glsl and ../LICENSE
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
fn g_hash(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

return fract((sin(dot(g_p, vec2<f32>(127.1, 311.7))) * 43758.5453));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: f32 = g_progress;
var g_strength: f32 = sin((g_p * 3.14159265));
var g_tv: vec2<f32> = g_uv;
var g_fromColor: vec4<f32> = getFromColor(g_tv);
var g_toColor: vec4<f32> = getToColor(g_tv);
var g_color: vec4<f32> = mix(g_fromColor, g_toColor, vec4<f32>(g_p));
var g_lineY: f32 = floor((g_tv.y * 120.0));
var g_noise: f32 = g_hash(vec2<f32>(g_lineY, (g_p * 20.0)));
var g_line: f32 = step(0.92, g_noise);
var g_drift: f32 = ((sin(((g_tv.y * 30.0) + (g_p * 10.0))) * 0.02) * g_strength);
var g_shiftedFrom: vec4<f32> = getFromColor((g_tv + vec2<f32>(g_drift, 0.0)));
var g_shiftedTo: vec4<f32> = getToColor((g_tv + vec2<f32>(g_drift, 0.0)));
var g_lineColor: vec4<f32> = mix(g_shiftedFrom, g_shiftedTo, vec4<f32>(g_p));
g_color = mix(g_color, g_lineColor, vec4<f32>((g_line * g_strength)));
var g_scan: f32 = (sin((g_tv.y * 900.0)) * 0.03);
g_color = vec4<f32>((g_color.x - (vec3<f32>((g_scan * g_strength))).x), (g_color.y - (vec3<f32>((g_scan * g_strength))).y), (g_color.z - (vec3<f32>((g_scan * g_strength))).z), g_color.w);
return g_color;
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
