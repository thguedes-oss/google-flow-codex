// Ported from luminance_melt.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 3980732a493577b250f8c5ff5fe38b3aad7af6fda8c2d67ef5abf974affa99a0
// Original authors: 0gust1
// License: MIT; full original notices in ../originals/luminance_melt.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  direction: f32,
  l_threshold: f32,
  above: f32,
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
var<private> g_direction: bool;
var<private> g_l_threshold: f32;
var<private> g_above: bool;
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_mod289__vec3(a_x: vec3<f32>) -> vec3<f32> {
var g_x: vec3<f32> = a_x;

return (g_x - (floor((g_x * vec3<f32>((1.0 / 289.0)))) * vec3<f32>(289.0)));
}
fn g_mod289__vec2(a_x: vec2<f32>) -> vec2<f32> {
var g_x: vec2<f32> = a_x;

return (g_x - (floor((g_x * vec2<f32>((1.0 / 289.0)))) * vec2<f32>(289.0)));
}
fn g_permute(a_x: vec3<f32>) -> vec3<f32> {
var g_x: vec3<f32> = a_x;

return g_mod289__vec3((((g_x * vec3<f32>(34.0)) + vec3<f32>(1.0)) * g_x));
}
fn g_snoise(a_v: vec2<f32>) -> f32 {
var g_v: vec2<f32> = a_v;

var g_C: vec4<f32> = vec4<f32>(0.211324865405187, 0.366025403784439, (-0.577350269189626), 0.024390243902439);
var g_i: vec2<f32> = floor((g_v + vec2<f32>(dot(g_v, g_C.yy))));
var g_x0: vec2<f32> = ((g_v - g_i) + vec2<f32>(dot(g_i, g_C.xx)));
var g_i1: vec2<f32>;
g_i1 = select(vec2<f32>(0.0, 1.0), vec2<f32>(1.0, 0.0), (g_x0.x > g_x0.y));
var g_x12: vec4<f32> = (g_x0.xyxy + g_C.xxzz);
g_x12 = vec4<f32>((g_x12.x - (g_i1).x), (g_x12.y - (g_i1).y), g_x12.z, g_x12.w);
g_i = g_mod289__vec2(g_i);
var g_p: vec3<f32> = g_permute(((g_permute((vec3<f32>(g_i.y) + vec3<f32>(0.0, g_i1.y, 1.0))) + vec3<f32>(g_i.x)) + vec3<f32>(0.0, g_i1.x, 1.0)));
var g_m: vec3<f32> = max((vec3<f32>(0.5) - vec3<f32>(dot(g_x0, g_x0), dot(g_x12.xy, g_x12.xy), dot(g_x12.zw, g_x12.zw))), vec3<f32>(0.0));
g_m = (g_m * g_m);
g_m = (g_m * g_m);
var g_x: vec3<f32> = ((vec3<f32>(2.0) * fract((g_p * g_C.www))) - vec3<f32>(1.0));
var g_h: vec3<f32> = (abs(g_x) - vec3<f32>(0.5));
var g_ox: vec3<f32> = floor((g_x + vec3<f32>(0.5)));
var g_a0: vec3<f32> = (g_x - g_ox);
g_m *= (vec3<f32>(1.79284291400159) - (vec3<f32>(0.85373472095314) * ((g_a0 * g_a0) + (g_h * g_h))));
var g_g: vec3<f32>;
g_g.x = ((g_a0.x * g_x0.x) + (g_h.x * g_x0.y));
g_g = vec3<f32>(g_g.x, (((g_a0.yz * g_x12.xz) + (g_h.yz * g_x12.yw))).x, (((g_a0.yz * g_x12.xz) + (g_h.yz * g_x12.yw))).y);
return (130.0 * dot(g_m, g_g));
}
fn g_luminance(a_color: vec4<f32>) -> f32 {
var g_color: vec4<f32> = a_color;

return (((g_color.r * 0.299) + (g_color.g * 0.587)) + (g_color.b * 0.114));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_center: vec2<f32> = vec2<f32>(1.0, select(f32(0), f32(1), g_direction));
var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
if ((g_progress == 0.0)) {
return getFromColor(g_p);
} else {
if ((g_progress == 1.0)) {
return getToColor(g_p);
} else {
var g_x: f32 = g_progress;
var g_dist: f32 = (distance(g_center, g_p) - (g_progress * exp(g_snoise(vec2<f32>(g_p.x, 0.0)))));
var g_r: f32 = (g_x - g_rand(vec2<f32>(g_p.x, 0.1)));
var g_m: f32;
if (g_above) {
g_m = select(((g_progress * g_progress) * g_progress), 1.0, ((g_dist <= g_r) && (g_luminance(getFromColor(g_p)) > g_l_threshold)));
} else {
g_m = select(((g_progress * g_progress) * g_progress), 1.0, ((g_dist <= g_r) && (g_luminance(getFromColor(g_p)) < g_l_threshold)));
}
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_m));
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_direction = (params.direction != f32(0));
g_l_threshold = params.l_threshold;
g_above = (params.above != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
