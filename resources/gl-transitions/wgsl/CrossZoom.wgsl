// Ported from CrossZoom.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: a30adba2a78deac0ac114a30ea285e972fdd7d488ed0cde90e15bc0eef333e84
// Original authors: rectalogic
// License: MIT; full original notices in ../originals/CrossZoom.glsl and ../LICENSE
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
fn g_Linear_ease(a_begin: f32, a_change: f32, a_duration: f32, a_time: f32) -> f32 {
var g_begin: f32 = a_begin;
var g_change: f32 = a_change;
var g_duration: f32 = a_duration;
var g_time: f32 = a_time;

return (((g_change * g_time) / g_duration) + g_begin);
}
fn g_Exponential_easeInOut(a_begin: f32, a_change: f32, a_duration: f32, a_time: f32) -> f32 {
var g_begin: f32 = a_begin;
var g_change: f32 = a_change;
var g_duration: f32 = a_duration;
var g_time: f32 = a_time;

if ((g_time == 0.0)) {
return g_begin;
} else {
if ((g_time == g_duration)) {
return (g_begin + g_change);
}
}
g_time = (g_time / (g_duration / 2.0));
if ((g_time < 1.0)) {
return (((g_change / 2.0) * pow(2.0, (10.0 * (g_time - 1.0)))) + g_begin);
}
return (((g_change / 2.0) * ((-pow(2.0, ((-10.0) * (g_time - 1.0)))) + 2.0)) + g_begin);
}
fn g_Sinusoidal_easeInOut(a_begin: f32, a_change: f32, a_duration: f32, a_time: f32) -> f32 {
var g_begin: f32 = a_begin;
var g_change: f32 = a_change;
var g_duration: f32 = a_duration;
var g_time: f32 = a_time;

return ((((-g_change) / 2.0) * (cos(((g_PI * g_time) / g_duration)) - 1.0)) + g_begin);
}
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_crossFade(a_uv: vec2<f32>, a_dissolve: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_dissolve: f32 = a_dissolve;

return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_dissolve));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_texCoord: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_center: vec2<f32> = vec2<f32>(g_Linear_ease(0.25, 0.5, 1.0, g_progress), 0.5);
var g_dissolve: f32 = g_Exponential_easeInOut(0.0, 1.0, 1.0, g_progress);
var g_strength: f32 = g_Sinusoidal_easeInOut(0.0, g_strength, 0.5, g_progress);
var g_color: vec4<f32> = vec4<f32>(0.0);
var g_total: f32 = 0.0;
var g_toCenter: vec2<f32> = (g_center - g_texCoord);
var g_offset: f32 = g_rand(g_uv);
for (var g_t: f32 = 0.0; (g_t <= 40.0); g_t += 1.0) {
var g_percent: f32 = ((g_t + g_offset) / 40.0);
var g_weight: f32 = (4.0 * (g_percent - (g_percent * g_percent)));
g_color += (g_crossFade((g_texCoord + ((g_toCenter * vec2<f32>(g_percent)) * vec2<f32>(g_strength))), g_dissolve) * vec4<f32>(g_weight));
g_total += g_weight;
}
return (g_color / vec4<f32>(g_total));
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
