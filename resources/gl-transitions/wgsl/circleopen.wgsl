// Ported from circleopen.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: f50be414d91a67965db1733abc664a2340ccbc215531bc263511bd206a1c93f7
// Original authors: gre
// License: MIT; full original notices in ../originals/circleopen.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  smoothness: f32,
  opening: f32,
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
var<private> g_smoothness: f32;
var<private> g_opening: bool;
var<private> g_center: vec2<f32>;
var<private> g_SQRT_2: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_x: f32 = select((1.0 - g_progress), g_progress, g_opening);
var g_m: f32 = smoothstep((-g_smoothness), 0.0, ((g_SQRT_2 * distance(g_center, g_uv)) - (g_x * (1.0 + g_smoothness))));
return mix(getFromColor(g_uv), getToColor(g_uv), vec4<f32>(select(g_m, (1.0 - g_m), g_opening)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_smoothness = params.smoothness;
g_opening = (params.opening != f32(0));
g_center = vec2<f32>(0.5, 0.5);
g_SQRT_2 = 1.414213562373;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
