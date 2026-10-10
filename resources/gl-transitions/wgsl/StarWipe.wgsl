// Ported from StarWipe.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 304c8cd4848b74c032a8a51907916af4b2f5f2d7ef9dd19a2b26752f3180c448
// Original authors: Ben Lucas
// License: MIT; full original notices in ../originals/StarWipe.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  border_thickness: f32,
  star_rotation: f32,
  border_color_x: f32,
  border_color_y: f32,
  border_color_z: f32,
  border_color_w: f32,
  star_center_x: f32,
  star_center_y: f32,
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
var<private> g_border_thickness: f32;
var<private> g_star_rotation: f32;
var<private> g_border_color: vec4<f32>;
var<private> g_star_center: vec2<f32>;
fn g_rotate(a_v: vec2<f32>, a_theta: f32) -> vec2<f32> {
var g_v: vec2<f32> = a_v;
var g_theta: f32 = a_theta;

var g_cosTheta: f32 = cos(g_theta);
var g_sinTheta: f32 = sin(g_theta);
return vec2<f32>(((g_cosTheta * g_v.x) - (g_sinTheta * g_v.y)), ((g_sinTheta * g_v.x) + (g_cosTheta * g_v.y)));
}
fn g_inStar(a_uv: vec2<f32>, a_center: vec2<f32>, a_radius: f32) -> bool {
var g_uv: vec2<f32> = a_uv;
var g_center: vec2<f32> = a_center;
var g_radius: f32 = a_radius;

var g_uv_centered: vec2<f32> = (g_uv - g_center);
g_uv_centered = g_rotate(g_uv_centered, (g_star_rotation * 1.2566370614359172));
var g_theta: f32 = (atan2(g_uv_centered.y, g_uv_centered.x) + 3.141592653589793);
var g_uv_rotated: vec2<f32> = g_rotate(g_uv_centered, ((-1.2566370614359172) * (floor((g_theta / 1.2566370614359172)) + 0.5)));
var g_slope: f32 = 0.3;
if ((g_uv_rotated.y > 0.0)) {
return ((g_radius + (g_uv_rotated.x * g_slope)) > g_uv_rotated.y);
} else {
return (((-g_radius) - (g_uv_rotated.x * g_slope)) < g_uv_rotated.y);
}
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_progressScaled: f32 = ((((2.0 * g_border_thickness) + 1.0) * g_progress) - g_border_thickness);
if (g_inStar(g_uv, g_star_center, g_progressScaled)) {
return getToColor(g_uv);
} else {
if (g_inStar(g_uv, g_star_center, (g_progressScaled + g_border_thickness))) {
return g_border_color;
} else {
return getFromColor(g_uv);
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_border_thickness = params.border_thickness;
g_star_rotation = params.star_rotation;
g_border_color = vec4<f32>(params.border_color_x, params.border_color_y, params.border_color_z, params.border_color_w);
g_star_center = vec2<f32>(params.star_center_x, params.star_center_y);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
