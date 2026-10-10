// Ported from fadecolor.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 62f989f1a578ae1f66bf5a3588ba2072aac72d8d77589ac53808550285af1c06
// Original authors: gre
// License: MIT; full original notices in ../originals/fadecolor.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  color_x: f32,
  color_y: f32,
  color_z: f32,
  colorPhase: f32,
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
var<private> g_color: vec3<f32>;
var<private> g_colorPhase: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

return mix(mix(vec4<f32>(g_color, 1.0), getFromColor(g_uv), vec4<f32>(smoothstep((1.0 - g_colorPhase), 0.0, g_progress))), mix(vec4<f32>(g_color, 1.0), getToColor(g_uv), vec4<f32>(smoothstep(g_colorPhase, 1.0, g_progress))), vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_color = vec3<f32>(params.color_x, params.color_y, params.color_z);
g_colorPhase = params.colorPhase;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
