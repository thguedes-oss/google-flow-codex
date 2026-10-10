// Ported from parametric_glitch.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: ca3130de774ed1e7df36d31730a2d84a7ff59812749897e3b1531e2cbeeeeb32
// Original authors: Yoni Maltsman @friendlyspinach
// License: MIT; full original notices in ../originals/parametric_glitch.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  ampx: f32,
  ampy: f32,
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
var<private> g_ampx: f32;
var<private> g_ampy: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_from: vec4<f32> = getFromColor(g_uv);
var g_to: vec4<f32> = getToColor(g_uv);
var g_r: f32 = g_from.r;
var g_g: f32 = g_from.g;
var g_b: f32 = g_from.b;
var g_sphere: f32 = ((((g_r * g_r) + (g_g * g_g)) + (g_b * g_b)) - 1.0);
var g_spiralX: f32 = cos((g_sphere - (g_uv.x / (g_progress + 0.01))));
var g_spiralY: f32 = sin((g_sphere - (g_uv.y / (g_progress + 0.01))));
var g_st: vec2<f32> = g_uv;
g_st.x = fract(((g_ampx * g_st.x) * g_spiralX));
g_st.y = fract(((g_ampy * g_st.y) * g_spiralY));
var g_diff: vec2<f32> = (g_uv - g_st);
g_from = getFromColor((g_uv + (vec2<f32>(g_progress) * g_diff)));
return mix(g_from, g_to, vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_ampx = params.ampx;
g_ampy = params.ampy;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
