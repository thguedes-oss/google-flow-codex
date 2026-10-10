// Ported from Rolls.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 30781dc66fa788977b19a549ca72cb754ccde4a6fdf990b5f082a3d5ae25f171
// Original authors: Mark Craig
// License: MIT; full original notices in ../originals/Rolls.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  p_type: f32,
  RotDown: f32,
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
var<private> g_type: i32;
var<private> g_RotDown: bool;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_theta: f32;
var g_c1: f32;
var g_s1: f32;
var g_iResolution: vec2<f32> = vec2<f32>(g_ratio, 1.0);
var g_uvi: vec2<f32>;
if ((g_type == 0)) {
g_theta = ((select((-3.14159265358979323846), 3.14159265358979323846, g_RotDown) / 2.0) * g_progress);
g_uvi.x = (1.0 - g_uv.x);
g_uvi.y = g_uv.y;
} else {
if ((g_type == 1)) {
g_theta = ((select((-3.14159265358979323846), 3.14159265358979323846, g_RotDown) / 2.0) * g_progress);
g_uvi = g_uv;
} else {
if ((g_type == 2)) {
g_theta = ((select(3.14159265358979323846, (-3.14159265358979323846), g_RotDown) / 2.0) * g_progress);
g_uvi.x = g_uv.x;
g_uvi.y = (1.0 - g_uv.y);
} else {
if ((g_type == 3)) {
g_theta = ((select(3.14159265358979323846, (-3.14159265358979323846), g_RotDown) / 2.0) * g_progress);
g_uvi = (vec2<f32>(1.0) - g_uv);
}
}
}
}
g_c1 = cos(g_theta);
g_s1 = sin(g_theta);
var g_uv2: vec2<f32>;
g_uv2.x = (((g_uvi.x * g_iResolution.x) * g_c1) - ((g_uvi.y * g_iResolution.y) * g_s1));
g_uv2.y = (((g_uvi.x * g_iResolution.x) * g_s1) + ((g_uvi.y * g_iResolution.y) * g_c1));
if (((((g_uv2.x >= 0.0) && (g_uv2.x <= g_iResolution.x)) && (g_uv2.y >= 0.0)) && (g_uv2.y <= g_iResolution.y))) {
g_uv2 /= g_iResolution;
if ((g_type == 0)) {
g_uv2.x = (1.0 - g_uv2.x);
} else {
if ((g_type == 2)) {
g_uv2.y = (1.0 - g_uv2.y);
} else {
if ((g_type == 3)) {
g_uv2 = (vec2<f32>(1.0) - g_uv2);
}
}
}
return getFromColor(g_uv2);
}
return getToColor(g_uv);
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_type = i32(params.p_type);
g_RotDown = (params.RotDown != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
