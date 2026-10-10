// Ported from kaleidoscope.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 1abd2c1eed0a3b5aadcdb1023dbe05db1aa3dd2a9b31a62ba055e082bf3cc72b
// Original authors: nwoeanhinnogaehr
// License: MIT; full original notices in ../originals/kaleidoscope.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  speed: f32,
  angle: f32,
  power: f32,
  _pad0: f32,
  _pad1: f32,
  _pad2: f32,
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
var<private> g_angle: f32;
var<private> g_power: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_q: vec2<f32> = g_p;
var g_t: f32 = (pow(g_progress, g_power) * g_speed);
g_p = (g_p - vec2<f32>(0.5));
for (var g_i: i32 = 0; (g_i < 7); g_i++) {
g_p = vec2<f32>(((sin(g_t) * g_p.x) + (cos(g_t) * g_p.y)), ((sin(g_t) * g_p.y) - (cos(g_t) * g_p.x)));
g_t += g_angle;
g_p = abs(((g_p - vec2<f32>(2.0) * floor(g_p / vec2<f32>(2.0))) - vec2<f32>(1.0)));
}
_ = abs((g_p - vec2<f32>(1.0) * floor(g_p / vec2<f32>(1.0))));
return mix(mix(getFromColor(g_q), getToColor(g_q), vec4<f32>(g_progress)), mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_progress)), vec4<f32>((1.0 - (2.0 * abs((g_progress - 0.5))))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_speed = params.speed;
g_angle = params.angle;
g_power = params.power;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
