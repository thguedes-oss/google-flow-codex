// Ported from GridFlip.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: f84096ffe6fc44808189a381a4e48dfde949beabed8df110fb45e68f6557810c
// Original authors: TimDonselaar
// License: MIT; full original notices in ../originals/GridFlip.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  size_x: f32,
  size_y: f32,
  pause: f32,
  dividerWidth: f32,
  bgcolor_x: f32,
  bgcolor_y: f32,
  bgcolor_z: f32,
  bgcolor_w: f32,
  randomness: f32,
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
var<private> g_size: vec2<i32>;
var<private> g_pause: f32;
var<private> g_dividerWidth: f32;
var<private> g_bgcolor: vec4<f32>;
var<private> g_randomness: f32;
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_getDelta(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

var g_rectanglePos: vec2<f32> = floor((vec2<f32>(vec2<f32>(g_size)) * g_p));
var g_rectangleSize: vec2<f32> = vec2<f32>((1.0 / vec2<f32>(vec2<f32>(g_size)).x), (1.0 / vec2<f32>(vec2<f32>(g_size)).y));
var g_top: f32 = (g_rectangleSize.y * (g_rectanglePos.y + 1.0));
var g_bottom: f32 = (g_rectangleSize.y * g_rectanglePos.y);
var g_left: f32 = (g_rectangleSize.x * g_rectanglePos.x);
var g_right: f32 = (g_rectangleSize.x * (g_rectanglePos.x + 1.0));
var g_minX: f32 = min(abs((g_p.x - g_left)), abs((g_p.x - g_right)));
var g_minY: f32 = min(abs((g_p.y - g_top)), abs((g_p.y - g_bottom)));
return min(g_minX, g_minY);
}
fn g_getDividerSize() -> f32 {

var g_rectangleSize: vec2<f32> = vec2<f32>((1.0 / vec2<f32>(vec2<f32>(g_size)).x), (1.0 / vec2<f32>(vec2<f32>(g_size)).y));
return (min(g_rectangleSize.x, g_rectangleSize.y) * g_dividerWidth);
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

if ((g_progress < g_pause)) {
var g_currentProg: f32 = (g_progress / g_pause);
var g_a: f32 = 1.0;
if ((g_getDelta(g_p) < g_getDividerSize())) {
g_a = (1.0 - g_currentProg);
}
return mix(g_bgcolor, getFromColor(g_p), vec4<f32>(g_a));
} else {
if ((g_progress < (1.0 - g_pause))) {
if ((g_getDelta(g_p) < g_getDividerSize())) {
return g_bgcolor;
} else {
var g_currentProg: f32 = ((g_progress - g_pause) / (1.0 - (g_pause * 2.0)));
var g_q: vec2<f32> = g_p;
var g_rectanglePos: vec2<f32> = floor((vec2<f32>(vec2<f32>(g_size)) * g_q));
var g_r: f32 = (g_rand(g_rectanglePos) - g_randomness);
var g_cp: f32 = smoothstep(0.0, (1.0 - g_r), g_currentProg);
var g_rectangleSize: f32 = (1.0 / vec2<f32>(vec2<f32>(g_size)).x);
var g_delta: f32 = (g_rectanglePos.x * g_rectangleSize);
var g_offset: f32 = ((g_rectangleSize / 2.0) + g_delta);
g_p.x = ((((g_p.x - g_offset) / abs((g_cp - 0.5))) * 0.5) + g_offset);
var g_a: vec4<f32> = getFromColor(g_p);
var g_b: vec4<f32> = getToColor(g_p);
var g_s: f32 = step(abs(((vec2<f32>(vec2<f32>(g_size)).x * (g_q.x - g_delta)) - 0.5)), abs((g_cp - 0.5)));
return mix(g_bgcolor, mix(g_b, g_a, vec4<f32>(step(g_cp, 0.5))), vec4<f32>(g_s));
}
} else {
var g_currentProg: f32 = (((g_progress - 1.0) + g_pause) / g_pause);
var g_a: f32 = 1.0;
if ((g_getDelta(g_p) < g_getDividerSize())) {
g_a = g_currentProg;
}
return mix(g_bgcolor, getToColor(g_p), vec4<f32>(g_a));
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_size = vec2<i32>(i32(params.size_x), i32(params.size_y));
g_pause = params.pause;
g_dividerWidth = params.dividerWidth;
g_bgcolor = vec4<f32>(params.bgcolor_x, params.bgcolor_y, params.bgcolor_z, params.bgcolor_w);
g_randomness = params.randomness;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
