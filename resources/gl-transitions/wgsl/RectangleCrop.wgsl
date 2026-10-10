// Ported from RectangleCrop.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 21d769de57567c4a428228181d6a619c9e5b0b066b34acc01854a40d780471f4
// Original authors: martiniti
// License: MIT; full original notices in ../originals/RectangleCrop.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  bgcolor_x: f32,
  bgcolor_y: f32,
  bgcolor_z: f32,
  bgcolor_w: f32,
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
var<private> g_bgcolor: vec4<f32>;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_s: f32 = pow((2.0 * abs((g_progress - 0.5))), 3.0);
var g_q: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_bl: vec2<f32> = step(vec2<f32>((1.0 - (2.0 * abs((g_progress - 0.5))))), (g_q + vec2<f32>(0.25)));
var g_tr: vec2<f32> = step(vec2<f32>((1.0 - (2.0 * abs((g_progress - 0.5))))), (vec2<f32>(1.25) - g_q));
var g_dist: f32 = length((1.0 - (((g_bl.x * g_bl.y) * g_tr.x) * g_tr.y)));
return mix(select(getToColor(g_uv), getFromColor(g_uv), (g_progress < 0.5)), g_bgcolor, vec4<f32>(step(g_s, g_dist)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_bgcolor = vec4<f32>(params.bgcolor_x, params.bgcolor_y, params.bgcolor_z, params.bgcolor_w);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
