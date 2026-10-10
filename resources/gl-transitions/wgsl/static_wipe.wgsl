// Ported from static_wipe.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 16eb1015402a7a15c44da28ebfdaa1efc3ee0f4ac6811b8dd839175538f0a932
// Original authors: Ben Lucas
// License: MIT; full original notices in ../originals/static_wipe.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  u_transitionUpToDown: f32,
  u_max_static_span: f32,
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
var<private> g_u_transitionUpToDown: bool;
var<private> g_u_max_static_span: f32;
fn g_rnd(a_st: vec2<f32>) -> f32 {
var g_st: vec2<f32> = a_st;

return fract((sin(dot(g_st.xy, vec2<f32>(f32(10), f32(70)))) * 12345.5453123));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_span: f32 = (g_u_max_static_span * pow(sin((3.14159265359 * g_progress)), 0.5));
var g_transitionEdge: f32 = select(g_uv.y, (1.0 - g_uv.y), g_u_transitionUpToDown);
var g_mixRatio: f32 = (1.0 - step(g_progress, g_transitionEdge));
var g_transitionMix: vec4<f32> = mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_mixRatio));
var g_noiseEnvelope: f32 = (smoothstep((g_progress - g_span), g_progress, g_transitionEdge) * (1.0 - smoothstep(g_progress, (g_progress + g_span), g_transitionEdge)));
var g_noise: vec4<f32> = vec4<f32>(vec3<f32>(g_rnd((g_uv * vec2<f32>((1.0 + g_progress))))), 1.0);
return mix(g_transitionMix, g_noise, vec4<f32>(g_noiseEnvelope));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_u_transitionUpToDown = (params.u_transitionUpToDown != f32(0));
g_u_max_static_span = params.u_max_static_span;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
