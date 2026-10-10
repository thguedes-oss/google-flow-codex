// Ported from DirectionalScaled.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 3ccff0df6ca18f1c4011ece47d4c041ac8be7eb3ec7ab707396e4f4999a9cbf9
// Original authors: Thibaut Foussard
// License: MIT; full original notices in ../originals/DirectionalScaled.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  direction_x: f32,
  direction_y: f32,
  scale: f32,
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
var<private> g_direction: vec2<f32>;
var<private> g_scale: f32;
fn g_parabola(a_x: f32) -> f32 {
var g_x: f32 = a_x;

var g_y: f32 = pow(sin((g_x * acos((-1.0)))), 1.0);
return g_y;
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_easedProgress: f32 = pow(sin(((g_progress * acos((-1.0))) / 2.0)), 3.0);
var g_p: vec2<f32> = (g_uv + (vec2<f32>(g_easedProgress) * sign(g_direction)));
var g_f: vec2<f32> = fract(g_p);
var g_s: f32 = (1.0 - ((1.0 - (1.0 / g_scale)) * g_parabola(g_progress)));
g_f = (((g_f - vec2<f32>(0.5)) * vec2<f32>(g_s)) + vec2<f32>(0.5));
var g_mixer: f32 = (((step(0.0, g_p.y) * step(g_p.y, 1.0)) * step(0.0, g_p.x)) * step(g_p.x, 1.0));
var g_col: vec4<f32> = mix(getToColor(g_f), getFromColor(g_f), vec4<f32>(g_mixer));
var g_border: f32 = (((step(0.0, g_f.x) * step(0.0, (1.0 - g_f.x))) * step(0.0, g_f.y)) * step(0.0, (1.0 - g_f.y)));
g_col *= vec4<f32>(g_border);
return g_col;
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_direction = vec2<f32>(params.direction_x, params.direction_y);
g_scale = params.scale;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
