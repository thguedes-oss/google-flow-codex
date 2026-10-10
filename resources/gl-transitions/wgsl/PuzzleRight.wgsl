// Ported from PuzzleRight.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 3bfa51661e90fb8f0e9e9dcd4778f72e2e37fbc9eae4f58f8135b83feff02869
// Original authors: JustKirillS
// License: MIT; full original notices in ../originals/PuzzleRight.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  size_x: f32,
  size_y: f32,
  pause: f32,
  dividerWidth: f32,
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
var<private> g_size: vec2<i32>;
var<private> g_pause: f32;
var<private> g_dividerWidth: f32;
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_getDelta(a_p: vec2<f32>) -> f32 {
var g_p: vec2<f32> = a_p;

var g_rectangleSize: vec2<f32> = (vec2<f32>(1.0) / vec2<f32>(vec2<f32>(g_size)));
var g_rectanglePos: vec2<f32> = floor((vec2<f32>(vec2<f32>(g_size)) * g_p));
var g_top: f32 = (g_rectangleSize.y * (g_rectanglePos.y + 1.0));
var g_bottom: f32 = (g_rectangleSize.y * g_rectanglePos.y);
var g_left: f32 = (g_rectangleSize.x * g_rectanglePos.x);
var g_right: f32 = (g_rectangleSize.x * (g_rectanglePos.x + 1.0));
var g_minX: f32 = min(abs((g_p.x - g_left)), abs((g_p.x - g_right)));
var g_minY: f32 = min(abs((g_p.y - g_top)), abs((g_p.y - g_bottom)));
return min(g_minX, g_minY);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress < g_pause)) {
var g_currentProg: f32 = (g_progress / g_pause);
var g_a: f32 = 1.0;
if ((g_getDelta(g_uv) < g_dividerWidth)) {
g_a = (1.0 - g_currentProg);
}
return mix(vec4<f32>(0.0, 0.0, 0.0, 1.0), getFromColor(g_uv), vec4<f32>(g_a));
} else {
if ((g_progress < (1.0 - g_pause))) {
if ((g_getDelta(g_uv) < g_dividerWidth)) {
return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}
var g_currentProg: f32 = ((g_progress - g_pause) / (1.0 - (g_pause * 2.0)));
var g_rectanglePos: vec2<f32> = floor((vec2<f32>(vec2<f32>(g_size)) * g_uv));
var g_r: f32 = (g_rand(g_rectanglePos) - 0.1);
var g_cp: f32 = smoothstep(0.0, (1.0 - g_r), g_currentProg);
var g_rectangleSize: f32 = (1.0 / f32(f32(g_size.x)));
var g_delta: f32 = (g_rectanglePos.x * g_rectangleSize);
var g_offset: f32 = ((g_rectangleSize / 2.0) + g_delta);
var g_p: vec2<f32> = g_uv;
g_p.x = ((((g_p.x - g_offset) / abs((g_cp - 0.5))) * 0.5) + g_offset);
var g_a: vec4<f32> = getFromColor(g_p);
var g_b: vec4<f32> = getToColor(g_p);
var g_s: f32 = step(abs(((f32(f32(g_size.x)) * (g_uv.x - g_delta)) - 0.5)), abs((g_cp - 0.5)));
return vec4<f32>((mix(g_b, g_a, vec4<f32>(step(g_cp, 0.5))).rgb * vec3<f32>(g_s)), 1.0);
} else {
var g_currentProg: f32 = (((g_progress - 1.0) + g_pause) / g_pause);
var g_a: f32 = 1.0;
if ((g_getDelta(g_uv) < g_dividerWidth)) {
g_a = g_currentProg;
}
return mix(vec4<f32>(0.0, 0.0, 0.0, 1.0), getToColor(g_uv), vec4<f32>(g_a));
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
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
