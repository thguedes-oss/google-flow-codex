// Ported from Revolve_Left.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: 1653efd36293ce0371396bac077a845384963d9b260fd9e9e91dd1a6ccb09de3
// Original authors: bread
// License: MIT; full original notices in ../originals/Revolve_Left.glsl and ../LICENSE
struct Params {
  progress: f32,
  ratio: f32,
  center_x: f32,
  center_y: f32,
  direction: f32,
  maxRotation: f32,
  peakZoom: f32,
  swirl: f32,
  barrel: f32,
  motionBlur: f32,
  switchStart: f32,
  switchEnd: f32,
  shadow: f32,
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
var<private> g_center: vec2<f32>;
var<private> g_direction: f32;
var<private> g_maxRotation: f32;
var<private> g_peakZoom: f32;
var<private> g_swirl: f32;
var<private> g_barrel: f32;
var<private> g_motionBlur: f32;
var<private> g_switchStart: f32;
var<private> g_switchEnd: f32;
var<private> g_shadow: f32;
fn g_sat(a_x: f32) -> f32 {
var g_x: f32 = a_x;

return clamp(g_x, 0.0, 1.0);
}
fn g_ease(a_x: f32) -> f32 {
var g_x: f32 = a_x;

g_x = g_sat(g_x);
return ((g_x * g_x) * (3.0 - (2.0 * g_x)));
}
fn g_revolveEnvelope(a_t: f32) -> f32 {
var g_t: f32 = a_t;

var g_rise: f32 = g_ease(((g_t - 0.10) / 0.33));
var g_fall: f32 = (1.0 - g_ease(((g_t - 0.43) / 0.29)));
return (g_rise * g_fall);
}
fn g_rotate2(a_p: vec2<f32>, a_a: f32) -> vec2<f32> {
var g_p: vec2<f32> = a_p;
var g_a: f32 = a_a;

var g_s: f32 = sin(g_a);
var g_c: f32 = cos(g_a);
return vec2<f32>(((g_c * g_p.x) - (g_s * g_p.y)), ((g_s * g_p.x) + (g_c * g_p.y)));
}
fn g_warpUv(a_uv: vec2<f32>, a_t: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_t: f32 = a_t;

var g_e: f32 = g_revolveEnvelope(g_t);
var g_p: vec2<f32> = (g_uv - g_center);
g_p.x *= g_ratio;
var g_r: f32 = length(g_p);
var g_edgeSpin: f32 = (g_maxRotation * g_e);
var g_coreSpin: f32 = ((g_swirl * g_e) * pow((1.0 - g_sat((g_r / 0.96))), 1.55));
var g_visibleAngle: f32 = (g_direction * (g_edgeSpin + g_coreSpin));
g_p = g_rotate2(g_p, (-g_visibleAngle));
var g_sc: f32 = (1.0 + ((g_peakZoom - 1.0) * pow(g_e, 0.85)));
g_p /= vec2<f32>(g_sc);
var g_rr: f32 = length(g_p);
g_p *= vec2<f32>((1.0 + ((((g_barrel * g_e) * g_rr) * g_rr) * 2.8)));
g_p.x /= g_ratio;
return clamp((g_p + g_center), vec2<f32>(0.001), vec2<f32>(0.999));
}
fn g_sampleRevolve(a_uv: vec2<f32>, a_t: f32) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;
var g_t: f32 = a_t;

var g_p: vec2<f32> = g_warpUv(g_uv, g_t);
var g_reveal: f32 = smoothstep(g_switchStart, g_switchEnd, g_t);
return mix(getFromColor(g_p), getToColor(g_p), vec4<f32>(g_reveal));
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

if ((g_progress <= 0.0)) {
return getFromColor(g_uv);
}
if ((g_progress >= 1.0)) {
return getToColor(g_uv);
}
var g_e: f32 = g_revolveEnvelope(g_progress);
var g_span: f32 = ((0.060 * g_motionBlur) * g_e);
var g_color: vec4<f32> = vec4<f32>(0.0);
var g_total: f32 = 0.0;
for (var g_i: i32 = (-8); (g_i <= 8); g_i++) {
var g_x: f32 = (f32(f32(g_i)) / 8.0);
var g_w: f32 = (1.0 - abs(g_x));
g_w = ((g_w * g_w) + 0.01);
var g_t: f32 = g_sat((g_progress + (g_x * g_span)));
g_color += (g_sampleRevolve(g_uv, g_t) * vec4<f32>(g_w));
g_total += g_w;
}
g_color /= vec4<f32>(g_total);
var g_q: vec2<f32> = (g_uv - vec2<f32>(0.5));
g_q.x *= g_ratio;
var g_vignette: f32 = (1.0 - ((g_shadow * g_e) * smoothstep(0.35, 0.95, length(g_q))));
g_color = vec4<f32>((g_color.x * (vec3<f32>(g_vignette)).x), (g_color.y * (vec3<f32>(g_vignette)).y), (g_color.z * (vec3<f32>(g_vignette)).z), g_color.w);
return g_color;
}
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
g_progress = params.progress;
g_ratio = params.ratio;
g_center = vec2<f32>(params.center_x, params.center_y);
g_direction = params.direction;
g_maxRotation = params.maxRotation;
g_peakZoom = params.peakZoom;
g_swirl = params.swirl;
g_barrel = params.barrel;
g_motionBlur = params.motionBlur;
g_switchStart = params.switchStart;
g_switchEnd = params.switchEnd;
g_shadow = params.shadow;
let uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}
