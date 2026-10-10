// Ported from Bounce.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 527e83c588f03e249c3da4d610ef1c07f27c1d77c490beaea090694d852a1cb4
// Original authors: Adrian Purser
// License: MIT; full original notices in ../originals/Bounce.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  shadow_colour_x: f32,
  shadow_colour_y: f32,
  shadow_colour_z: f32,
  shadow_colour_w: f32,
  shadow_height: f32,
  bounces: f32,
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
var<private> g_shadow_colour: vec4<f32>;
var<private> g_shadow_height: f32;
var<private> g_bounces: f32;
var<private> g_PI: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_time: f32 = g_progress;
var g_stime: f32 = sin(((g_time * g_PI) / 2.0));
var g_phase: f32 = ((g_time * g_PI) * g_bounces);
var g_y: f32 = (abs(cos(g_phase)) * (1.0 - g_stime));
var g_d: f32 = (g_uv.y - g_y);
return mix(mix(getToColor(g_uv), g_shadow_colour, vec4<f32>((step(g_d, g_shadow_height) * (1.0 - mix((((g_d / g_shadow_height) * g_shadow_colour.a) + (1.0 - g_shadow_colour.a)), 1.0, smoothstep(0.95, 1.0, g_progress)))))), getFromColor(vec2<f32>(g_uv.x, (g_uv.y + (1.0 - g_y)))), vec4<f32>(step(g_d, 0.0)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_shadow_colour = vec4<f32>(params.shadow_colour_x, params.shadow_colour_y, params.shadow_colour_z, params.shadow_colour_w);
g_shadow_height = params.shadow_height;
g_bounces = params.bounces;
g_PI = 3.14159265358;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
