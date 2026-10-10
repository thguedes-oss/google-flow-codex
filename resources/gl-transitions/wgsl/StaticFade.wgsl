// Ported from StaticFade.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 18e1473fe42466eac3bee113b9d373c789dc603bad900e866399877006465495
// Original authors: Ben Lucas
// License: MIT; full original notices in ../originals/StaticFade.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  n_noise_pixels: f32,
  static_luminosity: f32,
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
var<private> g_n_noise_pixels: f32;
var<private> g_static_luminosity: f32;
fn g_rnd(a_st: vec2<f32>) -> f32 {
var g_st: vec2<f32> = a_st;

return fract((sin(dot(g_st.xy, vec2<f32>(10.5302340293, 70.23492931))) * 12345.5453123));
}
fn g_staticNoise(a_st: vec2<f32>, a_offset: f32, a_luminosity: f32) -> vec4<f32> {
var g_st: vec2<f32> = a_st;
var g_offset: f32 = a_offset;
var g_luminosity: f32 = a_luminosity;

var g_staticR: f32 = (g_luminosity * g_rnd((g_st * vec2<f32>((g_offset * 2.0), (g_offset * 3.0)))));
var g_staticG: f32 = (g_luminosity * g_rnd((g_st * vec2<f32>((g_offset * 3.0), (g_offset * 5.0)))));
var g_staticB: f32 = (g_luminosity * g_rnd((g_st * vec2<f32>((g_offset * 5.0), (g_offset * 7.0)))));
return vec4<f32>(g_staticR, g_staticG, g_staticB, 1.0);
}
fn g_staticIntensity(a_t: f32) -> f32 {
var g_t: f32 = a_t;

var g_transitionProgress: f32 = abs((2.0 * (g_t - 0.5)));
var g_transformedThreshold: f32 = ((1.2 * (1.0 - g_transitionProgress)) - 0.1);
return min(1.0, g_transformedThreshold);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_baseMix: f32 = step(0.5, g_progress);
var g_transitionMix: vec4<f32> = mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_baseMix));
var g_uvStatic: vec2<f32> = (floor((g_uv * vec2<f32>(g_n_noise_pixels))) / vec2<f32>(g_n_noise_pixels));
var g_staticColor: vec4<f32> = g_staticNoise(g_uvStatic, g_progress, g_static_luminosity);
var g_staticThresh: f32 = g_staticIntensity(g_progress);
var g_staticMix: f32 = step(g_rnd(g_uvStatic), g_staticThresh);
return mix(g_transitionMix, g_staticColor, vec4<f32>(g_staticMix));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_n_noise_pixels = params.n_noise_pixels;
g_static_luminosity = params.static_luminosity;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
