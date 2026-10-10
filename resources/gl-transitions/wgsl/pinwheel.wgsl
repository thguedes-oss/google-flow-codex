// Ported from pinwheel.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: fb8dea2ecd066a23d683726714add1f40885e68ac124532be1d774f169b08d8d
// Original authors: Mr Speaker
// License: MIT; full original notices in ../originals/pinwheel.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  speed: f32,
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
var<private> g_speed: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_circPos: f32 = (atan2((g_p.y - 0.5), (g_p.x - 0.5)) + (g_progress * g_speed));
var g_modPos: f32 = (g_circPos - (3.1415 / 4.0) * floor(g_circPos / (3.1415 / 4.0)));
var g_signed: f32 = sign((g_progress - g_modPos));
return mix(getToColor(g_p), getFromColor(g_p), vec4<f32>(step(g_signed, 0.5)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_speed = params.speed;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
