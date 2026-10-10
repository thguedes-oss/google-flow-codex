// Ported from TopBottom.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: a3bd3cb60b1ddf35d2b86cba289bf2433e12d224c07cb4649fae9f1ebbeebf95
// Original authors: zhmy
// License: MIT; full original notices in ../originals/TopBottom.glsl and ../LICENSE
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
var<private> g_black: vec4<f32>;
var<private> g_boundMin: vec2<f32>;
var<private> g_boundMax: vec2<f32>;
fn g_inBounds(a_p: vec2<f32>) -> bool {
var g_p: vec2<f32> = a_p;

return (all((g_boundMin < g_p)) && all((g_p < g_boundMax)));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_spfr: vec2<f32>;
var g_spto: vec2<f32> = vec2<f32>((-1.0));
var g_size: f32 = mix(1.0, 3.0, (g_progress * 0.2));
g_spto = (((g_uv + vec2<f32>((-0.5), (-0.5))) * vec2<f32>(g_size, g_size)) + vec2<f32>(0.5, 0.5));
g_spfr = (g_uv + vec2<f32>(0.0, (1.0 - g_progress)));
if (g_inBounds(g_spfr)) {
return getToColor(g_spfr);
} else {
if (g_inBounds(g_spto)) {
return (getFromColor(g_spto) * vec4<f32>((1.0 - g_progress)));
} else {
return g_black;
}
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_black = vec4<f32>(0.0, 0.0, 0.0, 1.0);
g_boundMin = vec2<f32>(0.0, 0.0);
g_boundMax = vec2<f32>(1.0, 1.0);
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
