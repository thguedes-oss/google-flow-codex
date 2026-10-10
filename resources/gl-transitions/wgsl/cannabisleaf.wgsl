// Ported from cannabisleaf.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 75a23e58ad84d604a2c46c7acc97463d5434efe9658a929e7397d7592dd58b18
// Original authors: @Flexi23
// License: MIT; full original notices in ../originals/cannabisleaf.glsl and ../LICENSE
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
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress == 0.0)) {
return getFromColor(g_uv);
}
var g_leaf_uv: vec2<f32> = (((g_uv - vec2<f32>(0.5)) / vec2<f32>(10.0)) / vec2<f32>(pow(g_progress, 3.5)));
g_leaf_uv.y += 0.35;
var g_r: f32 = 0.18;
var g_o: f32 = atan2(g_leaf_uv.y, g_leaf_uv.x);
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>((1.0 - step(((1.0 - length(g_leaf_uv)) + ((((g_r * (1.0 + sin(g_o))) * (1.0 + (0.9 * cos((8.0 * g_o))))) * (1.0 + (0.1 * cos((24.0 * g_o))))) * (0.9 + (0.05 * cos((200.0 * g_o)))))), 1.0))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
