// Ported from swap.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 50e5f74bae4bad14f60e0a65691b560809ef3586b4eca4046c249941fa9e4625
// Original authors: gre
// License: MIT; full original notices in ../originals/swap.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  reflection: f32,
  perspective: f32,
  depth: f32,
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
var<private> g_reflection: f32;
var<private> g_perspective: f32;
var<private> g_depth: f32;
var<private> g_black: vec4<f32>;
var<private> g_boundMin: vec2<f32>;
var<private> g_boundMax: vec2<f32>;
fn g_inBounds(a_p: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;

return (all((g_boundMin < g_p)) && all((g_p < g_boundMax)));
}
fn g_project(a_p: vec2<f32>) -> vec2<f32> {
var g_p: vec2<f32> = a_p;

return ((g_p * vec2<f32>(1.0, (-1.2))) + vec2<f32>(0.0, (-0.02)));
}
fn g_bgColor(a_p: vec2<f32>, a_pfr: vec2<f32>, a_pto: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_pfr: vec2<f32> = a_pfr;
var g_pto: vec2<f32> = a_pto;

var g_c: vec4<f32> = g_black;
g_pfr = g_project(g_pfr);
if (g_inBounds(g_pfr)) {
g_c += mix(g_black, getFromColor(g_pfr), vec4<f32>((g_reflection * mix(1.0, 0.0, g_pfr.y))));
}
g_pto = g_project(g_pto);
if (g_inBounds(g_pto)) {
g_c += mix(g_black, getToColor(g_pto), vec4<f32>((g_reflection * mix(1.0, 0.0, g_pto.y))));
}
return g_c;
}
fn g_transition(a_p: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;

var g_pfr: vec2<f32>;
var g_pto: vec2<f32> = vec2<f32>((-1.0));
var g_size: f32 = mix(1.0, g_depth, g_progress);
var g_persp: f32 = (g_perspective * g_progress);
g_pfr = (((g_p + vec2<f32>((-0.0), (-0.5))) * vec2<f32>((g_size / (1.0 - (g_perspective * g_progress))), (g_size / (1.0 - ((g_size * g_persp) * g_p.x))))) + vec2<f32>(0.0, 0.5));
g_size = mix(1.0, g_depth, (1.0 - g_progress));
g_persp = (g_perspective * (1.0 - g_progress));
g_pto = (((g_p + vec2<f32>((-1.0), (-0.5))) * vec2<f32>((g_size / (1.0 - (g_perspective * (1.0 - g_progress)))), (g_size / (1.0 - ((g_size * g_persp) * (0.5 - g_p.x)))))) + vec2<f32>(1.0, 0.5));
if ((g_progress < 0.5)) {
if (g_inBounds(g_pfr)) {
return getFromColor(g_pfr);
}
if (g_inBounds(g_pto)) {
return getToColor(g_pto);
}
}
if (g_inBounds(g_pto)) {
return getToColor(g_pto);
}
if (g_inBounds(g_pfr)) {
return getFromColor(g_pfr);
}
return g_bgColor(g_p, g_pfr, g_pto);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_reflection = params.reflection;
g_perspective = params.perspective;
g_depth = params.depth;
g_black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
g_boundMin = vec2<f32>(0.0, 0.0);
g_boundMax = vec2<f32>(1.0, 1.0);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
