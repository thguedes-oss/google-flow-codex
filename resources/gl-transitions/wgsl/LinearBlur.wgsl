// Ported from LinearBlur.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 67ff5b194878f35d5afd4a4feada8c8e5b36a0c36deab76d032b19f80e9352f2
// Original authors: gre
// License: MIT; full original notices in ../originals/LinearBlur.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  intensity: f32,
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
var<private> g_intensity: f32;
var<private> g_passes: i32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_c1: vec4<f32> = vec4<f32>(0.0);
var g_c2: vec4<f32> = vec4<f32>(0.0);
var g_disp: f32 = (g_intensity * (0.5 - distance(0.5, g_progress)));
for (var g_xi: i32 = 0; (g_xi < g_passes); g_xi++) {
var g_x: f32 = ((f32(f32(g_xi)) / f32(f32(g_passes))) - 0.5);
for (var g_yi: i32 = 0; (g_yi < g_passes); g_yi++) {
var g_y: f32 = ((f32(f32(g_yi)) / f32(f32(g_passes))) - 0.5);
var g_v: vec2<f32> = vec2<f32>(g_x, g_y);
var g_d: f32 = g_disp;
g_c1 += getFromColor((g_uv + (vec2<f32>(g_d) * g_v)));
g_c2 += getToColor((g_uv + (vec2<f32>(g_d) * g_v)));
}
}
g_c1 /= vec4<f32>(f32(f32((g_passes * g_passes))));
g_c2 /= vec4<f32>(f32(f32((g_passes * g_passes))));
return mix(g_c1, g_c2, vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_intensity = params.intensity;
g_passes = 6;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
