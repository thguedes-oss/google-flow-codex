// Ported from Box.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 9e5221d3645d90c85ce9abfe5193d3c947fcacc2428b6a22d75d240806b4ece5
// Original authors: lql
// License: MIT; full original notices in ../originals/Box.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  rectIn: f32,
  location: f32,
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
var<private> g_rectIn: i32;
var<private> g_location: i32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: f32 = select(g_progress, (1.0 - g_progress), (g_rectIn == 1));
var g_x1: f32;
var g_y1: f32;
var g_x2: f32;
var g_y2: f32;
if ((g_location == 0)) {
g_y1 = (0.5 * (1.0 - g_p));
g_x1 = g_y1;
g_y2 = (1.0 - g_x1);
g_x2 = g_y2;
} else {
g_x1 = select((1.0 - g_p), 0.0, ((g_location == 1) || (g_location == 2)));
g_y1 = select(0.0, (1.0 - g_p), ((g_location == 1) || (g_location == 3)));
g_x2 = select(1.0, g_p, ((g_location == 1) || (g_location == 2)));
g_y2 = select(g_p, 1.0, ((g_location == 1) || (g_location == 3)));
}
var g_in_rect: f32 = (((step(g_x1, g_uv.x) * step(g_uv.x, g_x2)) * step(g_y1, g_uv.y)) * step(g_uv.y, g_y2));
g_in_rect = select(g_in_rect, (1.0 - g_in_rect), (g_rectIn == 1));
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_in_rect));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_rectIn = i32(params.rectIn);
g_location = i32(params.location);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
