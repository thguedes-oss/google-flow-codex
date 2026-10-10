// Ported from cube.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 8b3f864fefaa8cc4d30a58c4e17654f886828a9e58789b86daa31e4f99c91c28
// Original authors: gre
// License: MIT; full original notices in ../originals/cube.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  persp: f32,
  unzoom: f32,
  reflection: f32,
  floating: f32,
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
var<private> g_persp: f32;
var<private> g_unzoom: f32;
var<private> g_reflection: f32;
var<private> g_floating: f32;
fn g_project(a_p: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;

return ((g_p * vec2<f32>(1.0, (-1.2))) + vec2<f32>(0.0, ((-g_floating) / 100.0)));
}
fn g_inBounds(a_p: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;

return (all((vec2<f32>(0.0) < g_p)) && all((g_p < vec2<f32>(1.0))));
}
fn g_bgColor(a_p: vec2<f32>, a_pfr: vec2<f32>, a_pto: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_pfr: vec2<f32> = a_pfr;
var g_pto: vec2<f32> = a_pto;

var g_c: vec4<f32> = vec4<f32>(0.0, 0.0, 0.0, 1.0);
g_pfr = g_project(g_pfr);
if (g_inBounds(g_pfr)) {
g_c += mix(vec4<f32>(0.0), getFromColor(g_pfr), vec4<f32>((g_reflection * mix(1.0, 0.0, g_pfr.y))));
}
g_pto = g_project(g_pto);
if (g_inBounds(g_pto)) {
g_c += mix(vec4<f32>(0.0), getToColor(g_pto), vec4<f32>((g_reflection * mix(1.0, 0.0, g_pto.y))));
}
return g_c;
}
fn g_xskew(a_p: vec2<f32>, a_persp: f32, a_center: f32) -> vec2<f32> {
var g_p: vec2<f32> = a_p;
var g_persp: f32 = a_persp;
var g_center: f32 = a_center;

var g_x: f32 = mix(g_p.x, (1.0 - g_p.x), g_center);
return (((vec2<f32>(g_x, ((g_p.y - ((0.5 * (1.0 - g_persp)) * g_x)) / (1.0 + ((g_persp - 1.0) * g_x)))) - vec2<f32>((0.5 - distance(g_center, 0.5)), 0.0)) * vec2<f32>(((0.5 / distance(g_center, 0.5)) * select((-1.0), 1.0, (g_center < 0.5))), 1.0)) + vec2<f32>(select(1.0, 0.0, (g_center < 0.5)), 0.0));
}
fn g_transition(a_op: vec2<f32>) -> vec4<f32> {
var g_op: vec2<f32> = a_op;

var g_uz: f32 = ((g_unzoom * 2.0) * (0.5 - distance(0.5, g_progress)));
var g_p: vec2<f32> = (vec2<f32>(((-g_uz) * 0.5)) + (vec2<f32>((1.0 + g_uz)) * g_op));
var g_fromP: vec2<f32> = g_xskew(((g_p - vec2<f32>(g_progress, 0.0)) / vec2<f32>((1.0 - g_progress), 1.0)), (1.0 - mix(g_progress, 0.0, g_persp)), 0.0);
var g_toP: vec2<f32> = g_xskew((g_p / vec2<f32>(g_progress, 1.0)), mix(pow(g_progress, 2.0), 1.0, g_persp), 1.0);
if (g_inBounds(g_fromP)) {
return getFromColor(g_fromP);
} else {
if (g_inBounds(g_toP)) {
return getToColor(g_toP);
}
}
return g_bgColor(g_op, g_fromP, g_toP);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_persp = params.persp;
g_unzoom = params.unzoom;
g_reflection = params.reflection;
g_floating = params.floating;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
