// Ported from Mosaic.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 0be8036eeeb346a3896445ba30b7e517f32dfb7674a9c690e66773e1e90160f9
// Original authors: Xaychru
// License: MIT; full original notices in ../originals/Mosaic.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  endx: f32,
  endy: f32,
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
var<private> g_endx: i32;
var<private> g_endy: i32;
fn g_Rand(a_v: vec2<f32>) -> f32 {
var g_v: vec2<f32> = a_v;

return fract((sin(dot(g_v.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_Rotate(a_v: vec2<f32>, a_a: f32) -> vec2<f32> {
var g_v: vec2<f32> = a_v;
var g_a: f32 = a_a;

var g_rm: mat2x2<f32> = mat2x2<f32>(vec2<f32>(cos(g_a), (-sin(g_a))), vec2<f32>(sin(g_a), cos(g_a)));
return (g_rm * g_v);
}
fn g_CosInterpolation(a_x: f32) -> f32 {
var g_x: f32 = a_x;

return (((-cos((g_x * 3.14159265358979323))) / 2.0) + 0.5);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: vec2<f32> = ((g_uv.xy / vec2<f32>(1.0).xy) - vec2<f32>(0.5));
var g_rp: vec2<f32> = g_p;
var g_rpr: f32 = ((g_progress * 2.0) - 1.0);
var g_z: f32 = ((-((g_rpr * g_rpr) * 2.0)) + 3.0);
var g_az: f32 = abs(g_z);
g_rp *= vec2<f32>(g_az);
g_rp += mix(vec2<f32>(0.5, 0.5), vec2<f32>((f32(f32(g_endx)) + 0.5), (f32(f32(g_endy)) + 0.5)), vec2<f32>((g_CosInterpolation(g_progress) * g_CosInterpolation(g_progress))));
var g_mrp: vec2<f32> = (g_rp - vec2<f32>(1.0) * floor(g_rp / vec2<f32>(1.0)));
var g_crp: vec2<f32> = g_rp;
var g_onEnd: bool = ((i32(i32(floor(g_crp.x))) == g_endx) && (i32(i32(floor(g_crp.y))) == g_endy));
if ((!g_onEnd)) {
var g_ang: f32 = ((f32(f32(i32(i32((g_Rand(floor(g_crp)) * 4.0))))) * 0.5) * 3.14159265358979323);
g_mrp = (vec2<f32>(0.5) + g_Rotate((g_mrp - vec2<f32>(0.5)), g_ang));
}
if ((g_onEnd || (g_Rand(floor(g_crp)) > 0.5))) {
return getToColor(g_mrp);
} else {
return getFromColor(g_mrp);
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_endx = i32(params.endx);
g_endy = i32(params.endy);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
