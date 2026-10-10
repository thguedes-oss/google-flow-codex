// Ported from ZoomInCircles.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: c042e9846b3aca993f4102c13c7aa32f92306bd13b7b3c98be3cbff93173ec0c
// Original authors: dycm8009
// License: MIT; full original notices in ../originals/ZoomInCircles.glsl and ../LICENSE
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
fn g_zoom(a_uv: vec2<f32>, a_amount: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_amount: f32 = a_amount;

return (vec2<f32>(0.5) + ((g_uv - vec2<f32>(0.5)) * vec2<f32>(g_amount)));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_ratio2: vec2<f32> = vec2<f32>(1.0, (1.0 / g_ratio));
var g_r: vec2<f32> = (vec2<f32>(2.0) * ((vec2<f32>(g_uv.xy) - vec2<f32>(0.5)) * g_ratio2));
var g_pro: f32 = (g_progress / 0.8);
var g_z: f32 = (g_pro * 0.2);
var g_t: f32 = 0.0;
if ((g_pro > 1.0)) {
g_z = (0.2 + ((g_pro - 1.0) * 5.0));
g_t = clamp(((g_progress - 0.8) / 0.07), 0.0, 1.0);
}
if ((length(g_r) < (0.5 + g_z))) {

} else {
if ((length(g_r) < (0.8 + (g_z * 1.5)))) {
g_uv = g_zoom(g_uv, (1.0 - (0.15 * g_pro)));
g_t = (g_t * 0.5);
} else {
if ((length(g_r) < (1.2 + (g_z * 2.5)))) {
g_uv = g_zoom(g_uv, (1.0 - (0.2 * g_pro)));
g_t = (g_t * 0.2);
} else {
g_uv = g_zoom(g_uv, (1.0 - (0.25 * g_pro)));
}
}
}
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_t));
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
