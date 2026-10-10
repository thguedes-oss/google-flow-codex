// Ported from Swirl.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: fbbea8a885ed8cdf913fe481ee09e8897a79fd4f7c9ec6a1f459f6010147301e
// Original authors: Sergey Kosarevsky
// License: MIT; full original notices in ../originals/Swirl.glsl and ../LICENSE
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
fn g_transition(a_UV: vec2<f32>) -> vec4<f32> {
var g_UV: vec2<f32> = a_UV;

var g_Radius: f32 = 1.0;
var g_T: f32 = g_progress;
g_UV -= vec2<f32>(0.5, 0.5);
var g_Dist: f32 = length(g_UV);
if ((g_Dist < g_Radius)) {
var g_Percent: f32 = ((g_Radius - g_Dist) / g_Radius);
var g_A: f32 = select(mix(1.0, 0.0, ((g_T - 0.5) / 0.5)), mix(0.0, 1.0, (g_T / 0.5)), (g_T <= 0.5));
var g_Theta: f32 = ((((g_Percent * g_Percent) * g_A) * 8.0) * 3.14159);
var g_S: f32 = sin(g_Theta);
var g_C: f32 = cos(g_Theta);
g_UV = vec2<f32>(dot(g_UV, vec2<f32>(g_C, (-g_S))), dot(g_UV, vec2<f32>(g_S, g_C)));
}
g_UV += vec2<f32>(0.5, 0.5);
var g_C0: vec4<f32> = getFromColor(g_UV);
var g_C1: vec4<f32> = getToColor(g_UV);
return mix(g_C0, g_C1, vec4<f32>(g_T));
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
