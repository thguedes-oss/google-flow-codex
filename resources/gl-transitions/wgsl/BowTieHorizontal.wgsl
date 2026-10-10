// Ported from BowTieHorizontal.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: fcd134626185864b9c9dd0eb7d713f367e63afc445ace442ace6849a4700ec59
// Original authors: huynx
// License: MIT; full original notices in ../originals/BowTieHorizontal.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
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
var<private> g_bottom_left: vec2<f32>;
var<private> g_bottom_right: vec2<f32>;
var<private> g_top_left: vec2<f32>;
var<private> g_top_right: vec2<f32>;
var<private> g_center: vec2<f32>;
fn g_check(a_p1: vec2<f32>, a_p2: vec2<f32>, a_p3: vec2<f32>) -> f32 {
var g_p1: vec2<f32> = a_p1;
var g_p2: vec2<f32> = a_p2;
var g_p3: vec2<f32> = a_p3;

return (((g_p1.x - g_p3.x) * (g_p2.y - g_p3.y)) - ((g_p2.x - g_p3.x) * (g_p1.y - g_p3.y)));
}
fn g_PointInTriangle(a_pt: vec2<f32>, a_p1: vec2<f32>, a_p2: vec2<f32>, a_p3: vec2<f32>) -> bool {
var g_pt: vec2<f32> = a_pt;
var g_p1: vec2<f32> = a_p1;
var g_p2: vec2<f32> = a_p2;
var g_p3: vec2<f32> = a_p3;

var g_b1: bool;
var g_b2: bool;
var g_b3: bool;
g_b1 = (g_check(g_pt, g_p1, g_p2) < 0.0);
g_b2 = (g_check(g_pt, g_p2, g_p3) < 0.0);
g_b3 = (g_check(g_pt, g_p3, g_p1) < 0.0);
return ((g_b1 == g_b2) && (g_b2 == g_b3));
}
fn g_in_left_triangle(a_p: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;

var g_vertex1: vec2<f32>;
var g_vertex2: vec2<f32>;
var g_vertex3: vec2<f32>;
g_vertex1 = vec2<f32>(g_progress, 0.5);
g_vertex2 = vec2<f32>(0.0, (0.5 - g_progress));
g_vertex3 = vec2<f32>(0.0, (0.5 + g_progress));
if (g_PointInTriangle(g_p, g_vertex1, g_vertex2, g_vertex3)) {
return true;
}
return false;
}
fn g_in_right_triangle(a_p: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;

var g_vertex1: vec2<f32>;
var g_vertex2: vec2<f32>;
var g_vertex3: vec2<f32>;
g_vertex1 = vec2<f32>((1.0 - g_progress), 0.5);
g_vertex2 = vec2<f32>(1.0, (0.5 - g_progress));
g_vertex3 = vec2<f32>(1.0, (0.5 + g_progress));
if (g_PointInTriangle(g_p, g_vertex1, g_vertex2, g_vertex3)) {
return true;
}
return false;
}
fn g_blur_edge(a_bot1: vec2<f32>, a_bot2: vec2<f32>, a_top: vec2<f32>, a_testPt: vec2<f32>) -> f32 {
var g_bot1: vec2<f32> = a_bot1;
var g_bot2: vec2<f32> = a_bot2;
var g_top: vec2<f32> = a_top;
var g_testPt: vec2<f32> = a_testPt;

var g_lineDir: vec2<f32> = (g_bot1 - g_top);
var g_perpDir: vec2<f32> = vec2<f32>(g_lineDir.y, (-g_lineDir.x));
var g_dirToPt1: vec2<f32> = (g_bot1 - g_testPt);
var g_dist1: f32 = abs(dot(normalize(g_perpDir), g_dirToPt1));
g_lineDir = (g_bot2 - g_top);
g_perpDir = vec2<f32>(g_lineDir.y, (-g_lineDir.x));
g_dirToPt1 = (g_bot2 - g_testPt);
var g_min_dist: f32 = min(abs(dot(normalize(g_perpDir), g_dirToPt1)), g_dist1);
if ((g_min_dist < 0.005)) {
return (g_min_dist / 0.005);
} else {
return 1.0;
}

}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if (g_in_left_triangle(g_uv)) {
if ((g_progress < 0.1)) {
return getFromColor(g_uv);
}
if ((g_uv.x < 0.5)) {
var g_vertex1: vec2<f32> = vec2<f32>(g_progress, 0.5);
var g_vertex2: vec2<f32> = vec2<f32>(0.0, (0.5 - g_progress));
var g_vertex3: vec2<f32> = vec2<f32>(0.0, (0.5 + g_progress));
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_blur_edge(g_vertex2, g_vertex3, g_vertex1, g_uv)));
} else {
if ((g_progress > 0.0)) {
return getToColor(g_uv);
} else {
return getFromColor(g_uv);
}
}
} else {
if (g_in_right_triangle(g_uv)) {
if ((g_uv.x >= 0.5)) {
var g_vertex1: vec2<f32> = vec2<f32>((1.0 - g_progress), 0.5);
var g_vertex2: vec2<f32> = vec2<f32>(1.0, (0.5 - g_progress));
var g_vertex3: vec2<f32> = vec2<f32>(1.0, (0.5 + g_progress));
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(g_blur_edge(g_vertex2, g_vertex3, g_vertex1, g_uv)));
} else {
return getFromColor(g_uv);
}
} else {
return getFromColor(g_uv);
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_bottom_left = vec2<f32>(0.0, 1.0);
g_bottom_right = vec2<f32>(1.0, 1.0);
g_top_left = vec2<f32>(0.0, 0.0);
g_top_right = vec2<f32>(1.0, 0.0);
g_center = vec2<f32>(0.5, 0.5);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
