// Ported from StereoViewer.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 41ad611fde7308f72e3c045f6624b30c55ed2615cbf2a3114d6a848a1a0dd5e5
// Original authors: Ted Schundler
// License: BSD 2 Clause; full original notices in ../originals/StereoViewer.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  zoom: f32,
  corner_radius: f32,
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
var<private> g_zoom: f32;
var<private> g_corner_radius: f32;
var<private> g_black: vec4<f32>;
var<private> g_c00: vec2<f32>;
var<private> g_c01: vec2<f32>;
var<private> g_c11: vec2<f32>;
var<private> g_c10: vec2<f32>;
fn g_in_corner(a_p: vec2<f32>, a_corner: vec2<f32>, a_radius: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;
var g_corner: vec2<f32> = a_corner;
var g_radius: vec2<f32> = a_radius;

var g_axis: vec2<f32> = ((g_c11 - g_corner) - g_corner);
g_p = (g_p - (g_corner + (g_axis * g_radius)));
g_p *= (g_axis / g_radius);
return ((((g_p.x > 0.0) && (g_p.y > (-1.0))) || ((g_p.y > 0.0) && (g_p.x > (-1.0)))) || (dot(g_p, g_p) < 1.0));
}
fn g_test_rounded_mask(a_p: vec2<f32>, a_corner_size: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;
var g_corner_size: vec2<f32> = a_corner_size;

return (((g_in_corner(g_p, g_c00, g_corner_size) && g_in_corner(g_p, g_c01, g_corner_size)) && g_in_corner(g_p, g_c10, g_corner_size)) && g_in_corner(g_p, g_c11, g_corner_size));
}
fn g_screen(a_a: vec4<f32>, a_b: vec4<f32>) -> vec4<f32> {
var g_a: vec4<f32> = a_a;
var g_b: vec4<f32> = a_b;

return (vec4<f32>(1.0) - ((vec4<f32>(1.0) - g_a) * (vec4<f32>(1.0) - g_b)));
}
fn g_unscreen(a_c: vec4<f32>) -> vec4<f32> {
var g_c: vec4<f32> = a_c;

return (vec4<f32>(1.0) - sqrt((vec4<f32>(1.0) - g_c)));
}
fn g_sample_with_corners_from(a_p: vec2<f32>, a_corner_size: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_corner_size: vec2<f32> = a_corner_size;

g_p = (((g_p - vec2<f32>(0.5)) / vec2<f32>(g_zoom)) + vec2<f32>(0.5));
if ((!g_test_rounded_mask(g_p, g_corner_size))) {
return g_black;
}
return g_unscreen(getFromColor(g_p));
}
fn g_sample_with_corners_to(a_p: vec2<f32>, a_corner_size: vec2<f32>) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_corner_size: vec2<f32> = a_corner_size;

g_p = (((g_p - vec2<f32>(0.5)) / vec2<f32>(g_zoom)) + vec2<f32>(0.5));
if ((!g_test_rounded_mask(g_p, g_corner_size))) {
return g_black;
}
return g_unscreen(getToColor(g_p));
}
fn g_simple_sample_with_corners_from(a_p: vec2<f32>, a_corner_size: vec2<f32>, a_zoom_amt: f32) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_corner_size: vec2<f32> = a_corner_size;
var g_zoom_amt: f32 = a_zoom_amt;

g_p = (((g_p - vec2<f32>(0.5)) / vec2<f32>(((1.0 - g_zoom_amt) + (g_zoom * g_zoom_amt)))) + vec2<f32>(0.5));
if ((!g_test_rounded_mask(g_p, g_corner_size))) {
return g_black;
}
return getFromColor(g_p);
}
fn g_simple_sample_with_corners_to(a_p: vec2<f32>, a_corner_size: vec2<f32>, a_zoom_amt: f32) -> vec4<f32> {
var g_p: vec2<f32> = a_p;
var g_corner_size: vec2<f32> = a_corner_size;
var g_zoom_amt: f32 = a_zoom_amt;

g_p = (((g_p - vec2<f32>(0.5)) / vec2<f32>(((1.0 - g_zoom_amt) + (g_zoom * g_zoom_amt)))) + vec2<f32>(0.5));
if ((!g_test_rounded_mask(g_p, g_corner_size))) {
return g_black;
}
return getToColor(g_p);
}
fn g_rotate2d(a_angle: f32, a_ratio: f32) -> mat3x3<f32> {
var g_angle: f32 = a_angle;
var g_ratio: f32 = a_ratio;

var g_s: f32 = sin(g_angle);
var g_c: f32 = cos(g_angle);
return mat3x3<f32>(vec3<f32>(g_c, g_s, 0.0), vec3<f32>((-g_s), g_c, 0.0), vec3<f32>(0.0, 0.0, 1.0));
}
fn g_translate2d(a_x: f32, a_y: f32) -> mat3x3<f32> {
var g_x: f32 = a_x;
var g_y: f32 = a_y;

return mat3x3<f32>(vec3<f32>(1.0, 0.0, f32(0)), vec3<f32>(0.0, 1.0, f32(0)), vec3<f32>((-g_x), (-g_y), 1.0));
}
fn g_scale2d(a_x: f32, a_y: f32) -> mat3x3<f32> {
var g_x: f32 = a_x;
var g_y: f32 = a_y;

return mat3x3<f32>(vec3<f32>(g_x, 0.0, f32(0)), vec3<f32>(0.0, g_y, f32(0)), vec3<f32>(f32(0), f32(0), 1.0));
}
fn g_get_cross_rotated(a_p3: vec3<f32>, a_angle: f32, a_corner_size: vec2<f32>, a_ratio: f32) -> vec4<f32> {
var g_p3: vec3<f32> = a_p3;
var g_angle: f32 = a_angle;
var g_corner_size: vec2<f32> = a_corner_size;
var g_ratio: f32 = a_ratio;

g_angle = (g_angle * g_angle);
g_angle /= 2.4;
var g_center_and_scale: mat3x3<f32> = (g_translate2d((-0.5), (-0.5)) * g_scale2d(1.0, g_ratio));
var g_unscale_and_uncenter: mat3x3<f32> = (g_scale2d(1.0, (1.0 / g_ratio)) * g_translate2d(0.5, 0.5));
var g_slide_left: mat3x3<f32> = g_translate2d((-2.0), 0.0);
var g_slide_right: mat3x3<f32> = g_translate2d(2.0, 0.0);
var g_rotate: mat3x3<f32> = g_rotate2d(g_angle, g_ratio);
var g_op_a: mat3x3<f32> = ((((g_center_and_scale * g_slide_right) * g_rotate) * g_slide_left) * g_unscale_and_uncenter);
var g_op_b: mat3x3<f32> = ((((g_center_and_scale * g_slide_left) * g_rotate) * g_slide_right) * g_unscale_and_uncenter);
var g_a: vec4<f32> = g_sample_with_corners_from((g_op_a * g_p3).xy, g_corner_size);
var g_b: vec4<f32> = g_sample_with_corners_from((g_op_b * g_p3).xy, g_corner_size);
return g_screen(g_a, g_b);
}
fn g_get_cross_masked(a_p3: vec3<f32>, a_angle: f32, a_corner_size: vec2<f32>, a_ratio: f32) -> vec4<f32> {
var g_p3: vec3<f32> = a_p3;
var g_angle: f32 = a_angle;
var g_corner_size: vec2<f32> = a_corner_size;
var g_ratio: f32 = a_ratio;

g_angle = (1.0 - g_angle);
g_angle = (g_angle * g_angle);
g_angle /= 2.4;
var g_img: vec4<f32>;
var g_center_and_scale: mat3x3<f32> = (g_translate2d((-0.5), (-0.5)) * g_scale2d(1.0, g_ratio));
var g_unscale_and_uncenter: mat3x3<f32> = (g_scale2d((1.0 / g_zoom), (1.0 / (g_zoom * g_ratio))) * g_translate2d(0.5, 0.5));
var g_slide_left: mat3x3<f32> = g_translate2d((-2.0), 0.0);
var g_slide_right: mat3x3<f32> = g_translate2d(2.0, 0.0);
var g_rotate: mat3x3<f32> = g_rotate2d(g_angle, g_ratio);
var g_op_a: mat3x3<f32> = ((((g_center_and_scale * g_slide_right) * g_rotate) * g_slide_left) * g_unscale_and_uncenter);
var g_op_b: mat3x3<f32> = ((((g_center_and_scale * g_slide_left) * g_rotate) * g_slide_right) * g_unscale_and_uncenter);
var g_mask_a: bool = g_test_rounded_mask((g_op_a * g_p3).xy, g_corner_size);
var g_mask_b: bool = g_test_rounded_mask((g_op_b * g_p3).xy, g_corner_size);
if ((g_mask_a || g_mask_b)) {
g_img = g_sample_with_corners_to(g_p3.xy, g_corner_size);
return g_screen(select(g_black, g_img, g_mask_a), select(g_black, g_img, g_mask_b));
} else {
return g_black;
}
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_a: f32;
var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_p3: vec3<f32> = vec3<f32>(g_p.xy, 1.0);
var g_corner_size: vec2<f32> = vec2<f32>((g_corner_radius / g_ratio), g_corner_radius);
if ((g_progress <= 0.0)) {
return getFromColor(g_p);
} else {
if ((g_progress < 0.1)) {
g_a = (g_progress / 0.1);
return g_simple_sample_with_corners_from(g_p, (g_corner_size * vec2<f32>(g_a)), g_a);
} else {
if ((g_progress < 0.48)) {
g_a = ((g_progress - 0.1) / 0.38);
return g_get_cross_rotated(g_p3, g_a, g_corner_size, g_ratio);
} else {
if ((g_progress < 0.9)) {
return g_get_cross_masked(g_p3, ((g_progress - 0.52) / 0.38), g_corner_size, g_ratio);
} else {
if ((g_progress < 1.0)) {
g_a = ((1.0 - g_progress) / 0.1);
return g_simple_sample_with_corners_to(g_p, (g_corner_size * vec2<f32>(g_a)), g_a);
} else {
return getToColor(g_p);
}
}
}
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_zoom = params.zoom;
g_corner_radius = params.corner_radius;
g_black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
g_c00 = vec2<f32>(0.0, 0.0);
g_c01 = vec2<f32>(0.0, 1.0);
g_c11 = vec2<f32>(1.0, 1.0);
g_c10 = vec2<f32>(1.0, 0.0);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
