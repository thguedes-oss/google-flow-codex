// Ported from SimpleZoomOut.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 5ec96c4549092157e316783aa7aeee48a2898081cf9a2aa03e46efa648e84f53
// Original authors: Tianshuo
// License: MIT; full original notices in ../originals/SimpleZoomOut.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  zoom_quickness: f32,
  fade: f32,
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
var<private> g_zoom_quickness: f32;
var<private> g_fade: bool;
fn g_zoom(a_uv: vec2<f32>, a_amount: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_amount: f32 = a_amount;

return (vec2<f32>(0.5) + ((g_uv - vec2<f32>(0.5)) * vec2<f32>((1.0 - g_amount))));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_nQuick: f32 = clamp(g_zoom_quickness, 0.2, 1.0);
return mix(getFromColor(g_uv), getToColor(g_zoom(g_uv, (1.0 - smoothstep((1.0 - g_nQuick), 1.0, g_progress)))), vec4<f32>(select(select(1.0, 0.0, (g_progress < (1.0 - g_nQuick))), smoothstep((1.0 - g_nQuick), 1.0, g_progress), g_fade)));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_zoom_quickness = params.zoom_quickness;
g_fade = (params.fade != f32(0));
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
