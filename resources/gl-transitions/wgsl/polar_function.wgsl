// Ported from polar_function.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 2c871b5ed66346789de03721d1eb20df3ba097341330d667cd37c53d43e3e1b0
// Original authors: Fernando Kuteken
// License: MIT; full original notices in ../originals/polar_function.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  segments: f32,
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
var<private> g_segments: i32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_angle: f32 = (atan2((g_uv.y - 0.5), (g_uv.x - 0.5)) - (0.5 * 3.14159265359));
var g_normalized: f32 = ((g_angle + (1.5 * 3.14159265359)) * (2.0 * 3.14159265359));
var g_radius: f32 = ((cos((f32(f32(g_segments)) * g_angle)) + 4.0) / 4.0);
var g_difference: f32 = length((g_uv - vec2<f32>(0.5, 0.5)));
if ((g_difference > (g_radius * g_progress))) {
return getFromColor(g_uv);
} else {
return getToColor(g_uv);
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_segments = i32(params.segments);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
