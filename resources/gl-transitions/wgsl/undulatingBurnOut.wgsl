// Ported from undulatingBurnOut.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 69e7d3e5edd4609c5aa3bdac2a1d2c4572bb7b13d77c6662939781a61e7b9567
// Original authors: pthrasher
// License: MIT; full original notices in ../originals/undulatingBurnOut.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  smoothness: f32,
  center_x: f32,
  center_y: f32,
  color_x: f32,
  color_y: f32,
  color_z: f32,
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
var<private> g_center: vec2<f32>;
var<private> g_color: vec3<f32>;
var<private> g_M_PI: f32;
fn g_quadraticInOut(a_t: f32) -> f32 {
var g_t: f32 = a_t;

var g_p: f32 = ((2.0 * g_t) * g_t);
return select((((-g_p) + (4.0 * g_t)) - 1.0), g_p, (g_t < 0.5));
}
fn g_getGradient(a_r: f32, a_dist: f32) -> f32 {
var g_r: f32 = a_r;
var g_dist: f32 = a_dist;

var g_d: f32 = (g_r - g_dist);
return mix(smoothstep((-g_smoothness), 0.0, (g_r - (g_dist * (1.0 + g_smoothness)))), ((-1.0) - step(0.005, g_d)), (step((-0.005), g_d) * step(g_d, 0.01)));
}
fn g_getWave(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

var g__p: vec2<f32> = (g_p - g_center);
var g_rads: f32 = atan2(g__p.y, g__p.x);
var g_degs: f32 = (degrees(g_rads) + 180.0);
var g_range: vec2<f32> = vec2<f32>(0.0, (g_M_PI * 30.0));
var g_domain: vec2<f32> = vec2<f32>(0.0, 360.0);
var g_ratio: f32 = ((g_M_PI * 30.0) / 360.0);
g_degs = (g_degs * g_ratio);
var g_x: f32 = g_progress;
var g_magnitude: f32 = mix(0.02, 0.09, smoothstep(0.0, 1.0, g_x));
var g_offset: f32 = mix(40.0, 30.0, smoothstep(0.0, 1.0, g_x));
var g_ease_degs: f32 = g_quadraticInOut(sin(g_degs));
var g_deg_wave_pos: f32 = ((g_ease_degs * g_magnitude) * sin((g_x * g_offset)));
return ((g_x - (max(g_smoothness, 0.01) * (1.0 - smoothstep(0.0, 0.1, g_x)))) + g_deg_wave_pos);
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_dist: f32 = distance(g_center, g_p);
var g_m: f32 = g_getGradient(g_getWave(g_p), g_dist);
var g_cfrom: vec4<f32> = getFromColor(g_p);
var g_cto: vec4<f32> = getToColor(g_p);
return mix(mix(g_cfrom, g_cto, vec4<f32>(g_m)), mix(g_cfrom, vec4<f32>(g_color, 1.0), vec4<f32>(0.75)), vec4<f32>(step(g_m, (-2.0))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_smoothness = params.smoothness;
g_center = vec2<f32>(params.center_x, params.center_y);
g_color = vec3<f32>(params.color_x, params.color_y, params.color_z);
g_M_PI = 3.14159265358979323846;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
