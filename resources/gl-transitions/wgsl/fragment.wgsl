// Ported from fragment.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 7e119f40247737b0b703fc1d79a2fb5d72aa96b910584086b1d73c865100a93b
// Original authors: lbl
// License: MIT; full original notices in ../originals/fragment.glsl and ../LICENSE
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
fn g_random(a_par: vec2<f32>) -> f32 {
var g_par: vec2<f32> = a_par;

return fract((sin(dot(g_par.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_random2(a_par: vec2<f32>) -> vec2<f32> {
var g_par: vec2<f32> = a_par;

var g_rand: f32 = g_random(g_par);
return vec2<f32>(g_rand, g_random((g_par + vec2<f32>(g_rand))));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_duration: f32 = 8.0;
var g_time: f32 = (g_progress * g_duration);
var g_point: array<vec2<f32>, 10>;
for (var g_i: i32 = 0; (g_i < 10); g_i++) {
g_point[g_i] = g_random2(vec2<f32>(f32(f32(g_i))));
}
var g_col: vec4<f32> = getToColor(g_uv);
for (var g_i: i32 = 0; (g_i < 10); g_i++) {
var g_dir: vec2<f32> = normalize(g_random2(vec2<f32>(f32(f32(g_i)), (f32(f32(g_i)) + 11.0))));
var g_v: f32 = ((1.0 + (g_random(g_dir) * 0.5)) * 0.2);
var g_ofst: vec2<f32> = ((g_dir * vec2<f32>(clamp((g_time - 0.5), 0.0, g_duration))) * vec2<f32>(g_v));
var g_U: vec2<f32> = (g_uv - g_ofst);
if (((((g_U.x < 0.0) || (g_U.x > 1.0)) || (g_U.y < 0.0)) || (g_U.y > 1.0))) {
continue;
}
var g_dist_i: f32 = distance(g_U, g_point[g_i]);
var g_closest: bool = true;
for (var g_j: i32 = 0; (g_j < 10); g_j++) {
if ((distance(g_U, g_point[g_j]) < g_dist_i)) {
g_closest = false;
break;
}
}
if (g_closest) {
g_col = getFromColor(g_U);
break;
}
}
return g_col;
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
