// Ported from circle.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 374633d64f9fd5c7a9b948520255c90f9ab1f59ce542e5ecd5e2484e5a5efa41
// Original authors: Fernando Kuteken
// License: MIT; full original notices in ../originals/circle.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  center_x: f32,
  center_y: f32,
  backColor_x: f32,
  backColor_y: f32,
  backColor_z: f32,
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
var<private> g_center: vec2<f32>;
var<private> g_backColor: vec3<f32>;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_distance: f32 = length((g_uv - g_center));
var g_radius: f32 = (sqrt(8.0) * abs((g_progress - 0.5)));
if ((g_distance > g_radius)) {
return vec4<f32>(g_backColor, 1.0);
} else {
if ((g_progress < 0.5)) {
return getFromColor(g_uv);
} else {
return getToColor(g_uv);
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_center = vec2<f32>(params.center_x, params.center_y);
g_backColor = vec3<f32>(params.backColor_x, params.backColor_y, params.backColor_z);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
