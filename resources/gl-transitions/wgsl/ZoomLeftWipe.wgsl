// Ported from ZoomLeftWipe.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 6e51d2564ef6bb6f8c6addea5c53349f1c610970b91b16e6e4e9b85fd8804f3b
// Original authors: Handk
// License: MIT; full original notices in ../originals/ZoomLeftWipe.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  zoom_quickness: f32,
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
var<private> g_zoom_quickness: f32;
fn g_zoom(a_uv: vec2<f32>, a_amount: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_amount: f32 = a_amount;

if ((g_amount < 0.5)) {
return (vec2<f32>(0.5) + ((g_uv - vec2<f32>(0.5)) * vec2<f32>((1.0 - g_amount))));
} else {
return (vec2<f32>(0.5) + ((g_uv - vec2<f32>(0.5)) * vec2<f32>(g_amount)));
}
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_nQuick: f32 = clamp(g_zoom_quickness, 0.0, 0.5);
if ((g_progress < 0.5)) {
var g_c: vec4<f32> = mix(getFromColor(g_zoom(g_uv, smoothstep(0.0, g_nQuick, g_progress))), getToColor(g_uv), vec4<f32>(step(0.5, g_progress)));
return g_c;
} else {
var g_p: vec2<f32> = (g_uv.xy / vec2<f32>(1.0).xy);
var g_d: vec4<f32> = getFromColor(g_p);
var g_e: vec4<f32> = getToColor(g_p);
var g_f: vec4<f32> = mix(g_d, g_e, vec4<f32>(step((1.0 - g_p.x), ((g_progress - 0.5) * 2.0))));
return g_f;
}
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_zoom_quickness = params.zoom_quickness;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
