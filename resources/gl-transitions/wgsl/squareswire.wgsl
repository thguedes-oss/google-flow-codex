// Ported from squareswire.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 32f24c18612a2e5647eedad26b65a02605be7e69871403d911323a9f13cbe9e3
// Original authors: gre
// License: MIT; full original notices in ../originals/squareswire.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  squares_x: f32,
  squares_y: f32,
  direction_x: f32,
  direction_y: f32,
  smoothness: f32,
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
var<private> g_squares: vec2<i32>;
var<private> g_direction: vec2<f32>;
var<private> g_smoothness: f32;
var<private> g_center: vec2<f32>;
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_v: vec2<f32> = normalize(g_direction);
g_v /= vec2<f32>((abs(g_v.x) + abs(g_v.y)));
var g_d: f32 = ((g_v.x * g_center.x) + (g_v.y * g_center.y));
var g_offset: f32 = g_smoothness;
var g_pr: f32 = smoothstep((-g_offset), 0.0, (((g_v.x * g_p.x) + (g_v.y * g_p.y)) - ((g_d - 0.5) + (g_progress * (1.0 + g_offset)))));
var g_squarep: vec2<f32> = fract((g_p * vec2<f32>(vec2<f32>(g_squares))));
var g_squaremin: vec2<f32> = vec2<f32>((g_pr / 2.0));
var g_squaremax: vec2<f32> = vec2<f32>((1.0 - (g_pr / 2.0)));
var g_a: f32 = (((((1.0 - step(g_progress, 0.0)) * step(g_squaremin.x, g_squarep.x)) * step(g_squaremin.y, g_squarep.y)) * step(g_squarep.x, g_squaremax.x)) * step(g_squarep.y, g_squaremax.y));
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_a));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_squares = vec2<i32>(i32(params.squares_x), i32(params.squares_y));
g_direction = vec2<f32>(params.direction_x, params.direction_y);
g_smoothness = params.smoothness;
g_center = vec2<f32>(0.5, 0.5);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
