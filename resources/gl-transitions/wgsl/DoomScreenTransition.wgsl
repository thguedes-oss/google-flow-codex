// Ported from DoomScreenTransition.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: fa526e5c56977d85d321fd2363bc643101b294334d0619664fcfc1194f01543d
// Original authors: Zeh Fernando
// License: MIT; full original notices in ../originals/DoomScreenTransition.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  bars: f32,
  amplitude: f32,
  noise: f32,
  frequency: f32,
  dripScale: f32,
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
var<private> g_bars: i32;
var<private> g_amplitude: f32;
var<private> g_noise: f32;
var<private> g_frequency: f32;
var<private> g_dripScale: f32;
fn g_rand(a_num: i32) -> f32 {
var g_num: i32 = a_num;

return fract(((((f32(f32(g_num)) * 67123.313) - 12.0 * floor((f32(f32(g_num)) * 67123.313) / 12.0)) * sin((f32(f32(g_num)) * 10.3))) * cos(f32(f32(g_num)))));
}
fn g_wave(a_num: i32) -> f32 {
var g_num: i32 = a_num;

var g_fn: f32 = (((f32(f32(g_num)) * g_frequency) * 0.1) * f32(f32(g_bars)));
return ((((cos((g_fn * 0.5)) * cos((g_fn * 0.13))) * sin(((g_fn + 10.0) * 0.3))) / 2.0) + 0.5);
}
fn g_drip(a_num: i32) -> f32 {
var g_num: i32 = a_num;

return (sin(((f32(f32(g_num)) / f32(f32((g_bars - 1)))) * 3.141592)) * g_dripScale);
}
fn g_pos(a_num: i32) -> f32 {
var g_num: i32 = a_num;

return (select(mix(g_wave(g_num), g_rand(g_num), g_noise), g_wave(g_num), (g_noise == 0.0)) + select(g_drip(g_num), 0.0, (g_dripScale == 0.0)));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_bar: i32 = i32(i32((g_uv.x * f32(f32(g_bars)))));
var g_scale: f32 = (1.0 + (g_pos(g_bar) * g_amplitude));
var g_phase: f32 = (g_progress * g_scale);
var g_posY: f32 = (g_uv.y / vec2<f32>(1.0).y);
var g_p: vec2<f32>;
var g_c: vec4<f32>;
if (((g_phase + g_posY) < 1.0)) {
g_p = (vec2<f32>(g_uv.x, (g_uv.y + mix(0.0, vec2<f32>(1.0).y, g_phase))) / vec2<f32>(1.0).xy);
g_c = getFromColor(g_p);
} else {
g_p = (g_uv.xy / vec2<f32>(1.0).xy);
g_c = getToColor(g_p);
}
return g_c;
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_bars = i32(params.bars);
g_amplitude = params.amplitude;
g_noise = params.noise;
g_frequency = params.frequency;
g_dripScale = params.dripScale;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
