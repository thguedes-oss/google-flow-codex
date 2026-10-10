// Ported from fadegrayscale.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 519806f8c9bca6fc32a441398343433dca0399cde2b72ad30ea4ec2dc5648dfc
// Original authors: gre
// License: MIT; full original notices in ../originals/fadegrayscale.glsl and ../LICENSE
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
fn g_grayscale(a_color: vec3<f32>) -> vec3<f32> {
var g_color: vec3<f32> = a_color;

return vec3<f32>((((0.2126 * g_color.r) + (0.7152 * g_color.g)) + (0.0722 * g_color.b)));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_fc: vec4<f32> = getFromColor(g_uv);
var g_tc: vec4<f32> = getToColor(g_uv);
return mix(mix(vec4<f32>(g_grayscale(g_fc.rgb), 1.0), g_fc, vec4<f32>(smoothstep((1.0 - g_intensity), 0.0, g_progress))), mix(vec4<f32>(g_grayscale(g_tc.rgb), 1.0), g_tc, vec4<f32>(smoothstep(g_intensity, 1.0, g_progress))), vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_intensity = params.intensity;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
