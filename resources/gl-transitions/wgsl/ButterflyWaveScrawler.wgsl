// Ported from ButterflyWaveScrawler.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 985beba91c1dd105aa4ae9df94efe22648e2028d7bae9b5e4bcc64ff2a8f2c82
// Original authors: mandubian
// License: MIT; full original notices in ../originals/ButterflyWaveScrawler.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  amplitude: f32,
  waves: f32,
  colorSeparation: f32,
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
var<private> g_amplitude: f32;
var<private> g_waves: f32;
var<private> g_colorSeparation: f32;
var<private> g_PI: f32;
fn g_compute(a_p: vec2<f32>, a_progress: f32, a_center: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;
var g_progress: f32 = a_progress;
var g_center: vec2<f32> = a_center;

var g_o: vec2<f32> = ((g_p * vec2<f32>(sin((g_progress * g_amplitude)))) - g_center);
var g_h: vec2<f32> = vec2<f32>(1.0, 0.0);
var g_theta: f32 = (acos(dot(g_o, g_h)) * g_waves);
var g_s: f32 = sin((((2.0 * g_theta) - g_PI) / 24.0));
var g_s2: f32 = (g_s * g_s);
return (((exp(cos(g_theta)) - (2.0 * cos((4.0 * g_theta)))) + ((g_s2 * g_s2) * g_s)) / 10.0);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_p: vec2<f32> = g_uv;
var g_inv: f32 = (1.0 - g_progress);
var g_disp: f32 = g_compute(g_p, g_progress, vec2<f32>(0.5, 0.5));
var g_texTo: vec4<f32> = getToColor((g_p + vec2<f32>((g_inv * g_disp))));
var g_texFrom: vec4<f32> = vec4<f32>(getFromColor((g_p + vec2<f32>(((g_progress * g_disp) * (1.0 - g_colorSeparation))))).r, getFromColor((g_p + vec2<f32>((g_progress * g_disp)))).g, getFromColor((g_p + vec2<f32>(((g_progress * g_disp) * (1.0 + g_colorSeparation))))).b, 1.0);
return ((g_texTo * vec4<f32>(g_progress)) + (g_texFrom * vec4<f32>(g_inv)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_amplitude = params.amplitude;
g_waves = params.waves;
g_colorSeparation = params.colorSeparation;
g_PI = 3.14159265358979323846264;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
