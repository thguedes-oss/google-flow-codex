// Ported from BowTieWithParameter.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 5c7b0e25b066bda5c4b28a0f5b7986f2840937c92077818254b930495841d2e0
// Original authors: KMojek
// License: MIT; full original notices in ../originals/BowTieWithParameter.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  adjust: f32,
  reverse: f32,
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
var<private> g_adjust: f32;
var<private> g_reverse: bool;
fn g_check(a_p1: vec2<f32>, a_p2: vec2<f32>, a_p3: vec2<f32>) -> f32 {
var g_p1: vec2<f32> = a_p1;
var g_p2: vec2<f32> = a_p2;
var g_p3: vec2<f32> = a_p3;

return (((g_p1.x - g_p3.x) * (g_p2.y - g_p3.y)) - ((g_p2.x - g_p3.x) * (g_p1.y - g_p3.y)));
}
fn g_pointInTriangle(a_pt: vec2<f32>, a_p1: vec2<f32>, a_p2: vec2<f32>, a_p3: vec2<f32>) -> bool {
var g_pt: vec2<f32> = a_pt;
var g_p1: vec2<f32> = a_p1;
var g_p2: vec2<f32> = a_p2;
var g_p3: vec2<f32> = a_p3;

var g_b1: bool = (g_check(g_pt, g_p1, g_p2) < 0.0);
var g_b2: bool = (g_check(g_pt, g_p2, g_p3) < 0.0);
var g_b3: bool = (g_check(g_pt, g_p3, g_p1) < 0.0);
return ((g_b1 == g_b2) && (g_b2 == g_b3));
}
var<private> g_height: f32;
fn g_transition_firstHalf(a_uv: vec2<f32>, a_prog: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_prog: f32 = a_prog;

if ((g_uv.y < 0.5)) {
var g_botLeft: vec2<f32> = vec2<f32>((-0.0), (g_prog - g_height));
var g_botRight: vec2<f32> = vec2<f32>(1.0, (g_prog - g_height));
var g_tip: vec2<f32> = vec2<f32>(g_adjust, g_prog);
if (g_pointInTriangle(g_uv, g_botLeft, g_botRight, g_tip)) {
return getToColor(g_uv);
}
} else {
var g_topLeft: vec2<f32> = vec2<f32>((-0.0), ((1.0 - g_prog) + g_height));
var g_topRight: vec2<f32> = vec2<f32>(1.0, ((1.0 - g_prog) + g_height));
var g_tip: vec2<f32> = vec2<f32>(g_adjust, (1.0 - g_prog));
if (g_pointInTriangle(g_uv, g_topLeft, g_topRight, g_tip)) {
return getToColor(g_uv);
}
}
return getFromColor(g_uv);
}
fn g_transition_secondHalf(a_uv: vec2<f32>, a_prog: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_prog: f32 = a_prog;

if ((g_uv.x > g_adjust)) {
var g_top: vec2<f32> = vec2<f32>((g_prog + g_height), 1.0);
var g_bot: vec2<f32> = vec2<f32>((g_prog + g_height), (-0.0));
var g_tip: vec2<f32> = vec2<f32>(mix(g_adjust, 1.0, (2.0 * (g_prog - 0.5))), 0.5);
if (g_pointInTriangle(g_uv, g_top, g_bot, g_tip)) {
return getFromColor(g_uv);
}
} else {
var g_top: vec2<f32> = vec2<f32>(((1.0 - g_prog) - g_height), 1.0);
var g_bot: vec2<f32> = vec2<f32>(((1.0 - g_prog) - g_height), (-0.0));
var g_tip: vec2<f32> = vec2<f32>(mix(g_adjust, 0.0, (2.0 * (g_prog - 0.5))), 0.5);
if (g_pointInTriangle(g_uv, g_top, g_bot, g_tip)) {
return getFromColor(g_uv);
}
}
return getToColor(g_uv);
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if (g_reverse) {
return select(g_transition_firstHalf(g_uv, (1.0 - g_progress)), g_transition_secondHalf(g_uv, (1.0 - g_progress)), (g_progress < 0.5));
} else {
return select(g_transition_secondHalf(g_uv, g_progress), g_transition_firstHalf(g_uv, g_progress), (g_progress < 0.5));
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_adjust = params.adjust;
g_reverse = (params.reverse != f32(0));
g_height = 0.5;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
