// Ported from DreamyZoom.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 0ae348c409a29220ef5320db063c8ebd71757bafff533a72a852250328d01bb9
// Original authors: Zeh Fernando
// License: MIT; full original notices in ../originals/DreamyZoom.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  rotation: f32,
  scale: f32,
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
var<private> g_rotation: f32;
var<private> g_scale: f32;
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_phase: f32 = select(((g_progress - 0.5) * 2.0), (g_progress * 2.0), (g_progress < 0.5));
var g_angleOffset: f32 = select(mix(((-g_rotation) * 0.03926990816987241548078304229099), 0.0, g_phase), mix(0.0, (g_rotation * 0.03926990816987241548078304229099), g_phase), (g_progress < 0.5));
var g_newScale: f32 = select(mix(g_scale, 1.0, g_phase), mix(1.0, g_scale, g_phase), (g_progress < 0.5));
var g_center: vec2<f32> = vec2<f32>(f32(0), f32(0));
var g_assumedCenter: vec2<f32> = vec2<f32>(0.5, 0.5);
var g_p: vec2<f32> = (((g_uv.xy - vec2<f32>(0.5, 0.5)) / vec2<f32>(g_newScale)) * vec2<f32>(g_ratio, 1.0));
var g_angle: f32 = (atan2(g_p.y, g_p.x) + g_angleOffset);
var g_dist: f32 = distance(g_center, g_p);
g_p.x = (((cos(g_angle) * g_dist) / g_ratio) + 0.5);
g_p.y = ((sin(g_angle) * g_dist) + 0.5);
var g_c: vec4<f32> = select(getToColor(g_p), getFromColor(g_p), (g_progress < 0.5));
return (g_c + vec4<f32>(select(mix(1.0, 0.0, g_phase), mix(0.0, 1.0, g_phase), (g_progress < 0.5))));
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_rotation = params.rotation;
g_scale = params.scale;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
