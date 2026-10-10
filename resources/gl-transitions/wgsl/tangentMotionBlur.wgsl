// Ported from tangentMotionBlur.glsl at b2dfdcfbec079af4a05306d32b9366aa495c5155
// Source SHA-256: ba9a577e37b2712bf900bfb79a144cf3d7c2faaf9de7a02c78184e03877de5b3
// Original authors: chenkai
// License: MIT; full original notices in ../originals/tangentMotionBlur.glsl and ../LICENSE
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
fn g_rand(a_co: vec2<f32>) -> f32 {
var g_co: vec2<f32> = a_co;

return fract((sin(dot(g_co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453));
}
fn g_motionBlurFrom(a__st: vec2<f32>, a_speed: vec2<f32>) -> vec4<f32> {
var g__st: vec2<f32> = a__st;
var g_speed: vec2<f32> = a_speed;

var g_texCoord: vec2<f32> = (g__st.xy / vec2<f32>(1.0).xy);
var g_color: vec3<f32> = vec3<f32>(0.0);
var g_total: f32 = 0.0;
var g_offset: f32 = g_rand(g__st);
for (var g_t: f32 = 0.0; (g_t <= 20.0); g_t += 1.0) {
var g_percent: f32 = ((g_t + g_offset) / 20.0);
var g_weight: f32 = (4.0 * (g_percent - (g_percent * g_percent)));
var g_newuv: vec2<f32> = (g_texCoord + (g_speed * vec2<f32>(g_percent)));
g_newuv = fract(g_newuv);
g_color += (getFromColor(g_newuv).rgb * vec3<f32>(g_weight));
g_total += g_weight;
}
return vec4<f32>((g_color / vec3<f32>(g_total)), 1.0);
}
fn g_motionBlurTo(a__st: vec2<f32>, a_speed: vec2<f32>) -> vec4<f32> {
var g__st: vec2<f32> = a__st;
var g_speed: vec2<f32> = a_speed;

var g_texCoord: vec2<f32> = (g__st.xy / vec2<f32>(1.0).xy);
var g_color: vec3<f32> = vec3<f32>(0.0);
var g_total: f32 = 0.0;
var g_offset: f32 = g_rand(g__st);
for (var g_t: f32 = 0.0; (g_t <= 20.0); g_t += 1.0) {
var g_percent: f32 = ((g_t + g_offset) / 20.0);
var g_weight: f32 = (4.0 * (g_percent - (g_percent * g_percent)));
var g_newuv: vec2<f32> = (g_texCoord + (g_speed * vec2<f32>(g_percent)));
g_newuv = fract(g_newuv);
g_color += (getToColor(g_newuv).rgb * vec3<f32>(g_weight));
g_total += g_weight;
}
return vec4<f32>((g_color / vec3<f32>(g_total)), 1.0);
}
fn g_A(a_aA1: f32, a_aA2: f32) -> f32 {
var g_aA1: f32 = a_aA1;
var g_aA2: f32 = a_aA2;

return ((1.0 - (3.0 * g_aA2)) + (3.0 * g_aA1));
}
fn g_B(a_aA1: f32, a_aA2: f32) -> f32 {
var g_aA1: f32 = a_aA1;
var g_aA2: f32 = a_aA2;

return ((3.0 * g_aA2) - (6.0 * g_aA1));
}
fn g_C(a_aA1: f32) -> f32 {
var g_aA1: f32 = a_aA1;

return (3.0 * g_aA1);
}
fn g_GetSlope(a_aT: f32, a_aA1: f32, a_aA2: f32) -> f32 {
var g_aT: f32 = a_aT;
var g_aA1: f32 = a_aA1;
var g_aA2: f32 = a_aA2;

return (((((3.0 * g_A(g_aA1, g_aA2)) * g_aT) * g_aT) + ((2.0 * g_B(g_aA1, g_aA2)) * g_aT)) + g_C(g_aA1));
}
fn g_CalcBezier(a_aT: f32, a_aA1: f32, a_aA2: f32) -> f32 {
var g_aT: f32 = a_aT;
var g_aA1: f32 = a_aA1;
var g_aA2: f32 = a_aA2;

return (((((g_A(g_aA1, g_aA2) * g_aT) + g_B(g_aA1, g_aA2)) * g_aT) + g_C(g_aA1)) * g_aT);
}
fn g_GetTForX(a_aX: f32, a_mX1: f32, a_mX2: f32) -> f32 {
var g_aX: f32 = a_aX;
var g_mX1: f32 = a_mX1;
var g_mX2: f32 = a_mX2;

var g_aGuessT: f32 = g_aX;
for (var g_i: i32 = 0; (g_i < 4); g_i += 1) {
var g_currentSlope: f32 = g_GetSlope(g_aGuessT, g_mX1, g_mX2);
if ((g_currentSlope == 0.0)) {
return g_aGuessT;
}
var g_currentX: f32 = (g_CalcBezier(g_aGuessT, g_mX1, g_mX2) - g_aX);
g_aGuessT -= (g_currentX / g_currentSlope);
}
return g_aGuessT;
}
fn g_KeySpline(a_aX: f32, a_mX1: f32, a_mY1: f32, a_mX2: f32, a_mY2: f32) -> f32 {
var g_aX: f32 = a_aX;
var g_mX1: f32 = a_mX1;
var g_mY1: f32 = a_mY1;
var g_mX2: f32 = a_mX2;
var g_mY2: f32 = a_mY2;

if (((g_mX1 == g_mY1) && (g_mX2 == g_mY2))) {
return g_aX;
}
return g_CalcBezier(g_GetTForX(g_aX, g_mX1, g_mX2), g_mY1, g_mY2);
}
fn g_normpdf(a_x: f32) -> f32 {
var g_x: f32 = a_x;

var g_d: f32 = (g_x - 0.5);
return exp((((-20.0) * g_d) * g_d));
}
fn g_rotateUv(a_uv: vec2<f32>, a_angle: f32, a_anchor: vec2<f32>, a_zDirection: f32) -> vec2<f32> {
var g_uv: vec2<f32> = a_uv;
var g_angle: f32 = a_angle;
var g_anchor: vec2<f32> = a_anchor;
var g_zDirection: f32 = a_zDirection;

g_uv = (g_uv - g_anchor);
var g_s: f32 = sin(g_angle);
var g_c: f32 = cos(g_angle);
var g_m: mat2x2<f32> = mat2x2<f32>(vec2<f32>(g_c, (-g_s)), vec2<f32>(g_s, g_c));
g_uv = (g_m * g_uv);
g_uv += g_anchor;
return g_uv;
}
fn g_transition(a_uv: vec2<f32>) -> vec4<f32> {
var g_uv: vec2<f32> = a_uv;

var g_myst: vec2<f32> = g_uv;
var g_animationTime: f32 = g_progress;
var g_easingTime: f32 = g_KeySpline(g_animationTime, 0.68, 0.01, 0.17, 0.98);
var g_blur: f32 = g_normpdf(g_easingTime);
var g_r: f32 = 0.0;
var g_rotation: f32 = ((180.0 / 180.0) * 3.14159);
if ((g_easingTime <= 0.5)) {
g_r = (g_rotation * g_easingTime);
} else {
g_r = ((-g_rotation) + (g_rotation * g_easingTime));
}
var g_mystCurrent: vec2<f32> = g_myst;
g_mystCurrent.y *= (1.0 / g_ratio);
g_mystCurrent = g_rotateUv(g_mystCurrent, g_r, vec2<f32>(1.0, 0.0), (-1.0));
g_mystCurrent.y *= g_ratio;
var g_timeInterval: f32 = (0.0167 * 2.0);
if ((g_easingTime <= 0.5)) {
g_r = (g_rotation * (g_easingTime + g_timeInterval));
} else {
g_r = ((-g_rotation) + (g_rotation * (g_easingTime + g_timeInterval)));
}
var g_mystNext: vec2<f32> = g_myst;
g_mystNext.y *= (1.0 / g_ratio);
g_mystNext = g_rotateUv(g_mystNext, g_r, vec2<f32>(1.0, 0.0), (-1.0));
g_mystNext.y *= g_ratio;
var g_speed: vec2<f32> = ((((g_mystNext - g_mystCurrent) / vec2<f32>(g_timeInterval)) * vec2<f32>(g_blur)) * vec2<f32>(0.5));
if ((g_easingTime <= 0.5)) {
return g_motionBlurFrom(g_mystCurrent, g_speed);
} else {
return g_motionBlurTo(g_mystCurrent, g_speed);
}
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
