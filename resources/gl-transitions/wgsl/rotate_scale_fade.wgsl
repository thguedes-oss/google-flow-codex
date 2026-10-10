// Ported from rotate_scale_fade.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 4484386f72f9d955851feea332d4c449c70e9e25de4cbcefda6e6764c6709144
// Original authors: Fernando Kuteken
// License: MIT; full original notices in ../originals/rotate_scale_fade.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  center_x: f32,
  center_y: f32,
  rotations: f32,
  scale: f32,
  backColor_x: f32,
  backColor_y: f32,
  backColor_z: f32,
  backColor_w: f32,
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
var<private> g_center: vec2<f32>;
var<private> g_rotations: f32;
var<private> g_scale: f32;
var<private> g_backColor: vec4<f32>;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_difference: vec2<f32> = (g_uv - g_center);
var g_dir: vec2<f32> = normalize(g_difference);
var g_dist: f32 = length(g_difference);
var g_angle: f32 = (((2.0 * 3.14159265359) * g_rotations) * g_progress);
var g_c: f32 = cos(g_angle);
var g_s: f32 = sin(g_angle);
var g_currentScale: f32 = mix(g_scale, 1.0, (2.0 * abs((g_progress - 0.5))));
var g_rotatedDir: vec2<f32> = vec2<f32>(((g_dir.x * g_c) - (g_dir.y * g_s)), ((g_dir.x * g_s) + (g_dir.y * g_c)));
var g_rotatedUv: vec2<f32> = (g_center + ((g_rotatedDir * vec2<f32>(g_dist)) / vec2<f32>(g_currentScale)));
if (((((g_rotatedUv.x < 0.0) || (g_rotatedUv.x > 1.0)) || (g_rotatedUv.y < 0.0)) || (g_rotatedUv.y > 1.0))) {
return g_backColor;
}
return mix(getFromColor(g_rotatedUv), getToColor(g_rotatedUv), vec4<f32>(g_progress));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_center = vec2<f32>(params.center_x, params.center_y);
g_rotations = params.rotations;
g_scale = params.scale;
g_backColor = vec4<f32>(params.backColor_x, params.backColor_y, params.backColor_z, params.backColor_w);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
