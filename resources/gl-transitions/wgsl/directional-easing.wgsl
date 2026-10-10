// Ported from directional-easing.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 20aeaac21aa4cf192ac808163aa0121f5ddf966a1c487e045a94e7ca9d7e321c
// Original authors: Max Plotnikov
// License: MIT; full original notices in ../originals/directional-easing.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  direction_x: f32,
  direction_y: f32,
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
var<private> g_direction: vec2<f32>;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_easing: f32 = sqrt(((2.0 - g_progress) * g_progress));
var g_p: vec2<f32> = (g_uv + (vec2<f32>(g_easing) * sign(g_direction)));
var g_f: vec2<f32> = fract(g_p);
return mix(getToColor(g_f), getFromColor(g_f), vec4<f32>((((step(0.0, g_p.y) * step(g_p.y, 1.0)) * step(0.0, g_p.x)) * step(g_p.x, 1.0))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_direction = vec2<f32>(params.direction_x, params.direction_y);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
